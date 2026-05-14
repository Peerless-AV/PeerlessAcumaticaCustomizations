"""
sync_accounts.py
Acumatica → Salesforce Account Sync
-------------------------------------
Reads Account data from Acumatica via OData (PRL_SFDC_Account_Sync GI)
and updates matching Salesforce Account records using Account_Number__c
as the match key.

Rules:
  - UPDATE ONLY. No inserts. Records originate in Salesforce.
  - If no matching SF Account found for an ACU record, skip and log it.
  - TEST_MODE limits sync to a single hardcoded account for validation.

Usage:
    python sync_accounts.py

Set ACU_ENV in .env to switch environments: dev | test | qa | prod
Set TEST_MODE = False below when ready for full sync.
"""

import os
import sys
import logging
from datetime import datetime
from dotenv import load_dotenv
import requests
from simple_salesforce import Salesforce, SalesforceAuthenticationFailed

# -------------------------------------------------------
# CONFIG
# -------------------------------------------------------
TEST_MODE            = True
TEST_ACCOUNT_NUMBER  = "AVI059155"   # Hardcoded test account

LOG_FILE             = f"sync_accounts_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# -------------------------------------------------------
# Logging setup
# -------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
log = logging.getLogger(__name__)

# -------------------------------------------------------
# Load environment variables
# -------------------------------------------------------
load_dotenv()

ENV = os.getenv("ACU_ENV", "dev").strip().lower()

BASE_URL_MAP = {
    "dev":  os.getenv("ACU_BASE_URL_DEV"),
    "test": os.getenv("ACU_BASE_URL_TEST"),
    "qa":   os.getenv("ACU_BASE_URL_QA"),
    "prod": os.getenv("ACU_BASE_URL_PROD"),
}

ACU_BASE_URL = BASE_URL_MAP.get(ENV)
ACU_USERNAME = os.getenv("ACU_USERNAME")
ACU_PASSWORD = os.getenv("ACU_PASSWORD")

SF_USERNAME       = os.getenv("SF_USERNAME")
SF_PASSWORD       = os.getenv("SF_PASSWORD")
SF_SECURITY_TOKEN = os.getenv("SF_SECURITY_TOKEN", "")
SF_DOMAIN         = os.getenv("SF_DOMAIN", "login")

GI_NAME = "PRL_SFDC_Account_Sync"

# -------------------------------------------------------
# Field mapping: ACU OData property name → Salesforce field API name
# Casing sourced directly from live OData feed (PRL_SFDC_Account_Sync).
#
# SKIPPED FIELDS (require special handling):
#   Acuaccountownerc  → ACU_ACCOUNT_OWNER__c / OwnerId
#                        OwnerId is a SF User lookup; resolving
#                        salesperson name → SF User ID needs extra step.
#   AccountNumberc    → Account_Number__c  (match key only, not updated)
#   ExternalKey       → internal composite key, not synced to SF
#   TenantCode        → internal, not synced
# -------------------------------------------------------
FIELD_MAP = {
    # ACU OData property name           : SF Field API Name
    "Name"                              : "Name",
    "Acucustomerclassc"                 : "ACU_CUSTOMER_CLASS__c",
    "Acucustomerstatusc"                : "ACU_CUSTOMER_STATUS__c",
    "Acutierc"                          : "ACU_TIER__c",
    "Acucreditlimitc"                   : "ACU_CREDIT_LIMIT__c",
    "Acucreditremainc"                  : "ACU_CREDIT_REMAIN__c",
    "AcuCustomerCreditRulec"            : "Acu_Customer_Credit_Rule__c",
    "Acucredittermsc"                   : "ACU_CREDIT_TERMS__c",
    "RemainingCreditc"                  : "Remaining_Credit__c",
    "AcuCustomerCoordinatorc"           : "Acu_Customer_Coordinator__c",
    "ACUCustomerKeyDirectorc"           : "ACU_Customer_Key_Director__c",
    "ACUCustomerKeyManagerc"            : "ACU_Customer_Key_Manager__c",
    "AcuCustomerSalesOperationsc"       : "Acu_Customer_Sales_Operations__c",
    "ACUCustomerInsideSalesRepc"        : "ACU_Customer_Inside_Sales_Rep__c",
    "AcuCustomerCommissionReceiverc"    : "Acu_Customer_Commission_Receiver__c",
    "Acucustomerpostypec"               : "ACU_CUSTOMER_POSTYPE__c",
    "Acuproaccountgroupc"               : "ACU_PRO_ACCOUNT_GROUP__c",
    "Acuproaccounttypec"                : "ACU_PRO_ACCOUNT_TYPE__c",
    "ACUOutsideRepFirms"                : "ACU_Outside_Rep_Firms",
    "ExpiredDatec"                      : "Expired_Date__c",
}

# Billing address — SF accepts as flat fields on Account object.
# BillingStreet2 has no SF compound equivalent; excluded intentionally.
BILLING_ADDRESS_MAP = {
    "BillingStreet"     : "BillingStreet",
    "BillingCity"       : "BillingCity",
    "BillingState"      : "BillingState",
    "BillingPostalCode" : "BillingPostalCode",
    "BillingCountry"    : "BillingCountry",
}

# -------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------
def preflight():
    errors = []
    if not ACU_BASE_URL:
        errors.append(f"  - ACU_BASE_URL_{ENV.upper()} is not set in .env")
    if not ACU_USERNAME or ACU_USERNAME == "<acu_user>":
        errors.append("  - ACU_USERNAME is not set or still a placeholder")
    if not ACU_PASSWORD or ACU_PASSWORD == "<acu_pass>":
        errors.append("  - ACU_PASSWORD is not set or still a placeholder")
    if not SF_USERNAME:
        errors.append("  - SF_USERNAME is not set")
    if not SF_PASSWORD:
        errors.append("  - SF_PASSWORD is not set")
    if errors:
        log.error("PREFLIGHT FAILED. Fix the following before running:")
        for e in errors:
            log.error(e)
        sys.exit(1)

# -------------------------------------------------------
# Step 1: Pull records from Acumatica OData
# -------------------------------------------------------
def fetch_acumatica_records():
    url = f"{ACU_BASE_URL}/{GI_NAME}"
    params = {"$format": "json"}

    if TEST_MODE:
        # AccountNumberc is the OData property name for AcctCD
        params["$filter"] = f"AccountNumberc eq '{TEST_ACCOUNT_NUMBER}'"
        log.info(f"TEST_MODE enabled — filtering to AccountNumberc = {TEST_ACCOUNT_NUMBER}")

    log.info(f"Fetching Acumatica records from: {url}")

    try:
        response = requests.get(
            url,
            params=params,
            auth=(ACU_USERNAME, ACU_PASSWORD),
            timeout=60
        )
        response.raise_for_status()
        records = response.json().get("value", [])
        log.info(f"Acumatica returned {len(records)} record(s)")
        return records
    except requests.exceptions.HTTPError as e:
        log.error(f"Acumatica HTTP error: {e} — {response.text[:300]}")
        sys.exit(1)
    except Exception as e:
        log.error(f"Acumatica fetch error: {e}")
        sys.exit(1)

# -------------------------------------------------------
# Step 2: Connect to Salesforce
# -------------------------------------------------------
def connect_salesforce():
    try:
        sf = Salesforce(
            username=SF_USERNAME,
            password=SF_PASSWORD,
            security_token=SF_SECURITY_TOKEN,
            domain=SF_DOMAIN
        )
        log.info(f"Connected to Salesforce: {sf.sf_instance}")
        return sf
    except SalesforceAuthenticationFailed as e:
        log.error(f"Salesforce authentication failed: {e}")
        sys.exit(1)
    except Exception as e:
        log.error(f"Salesforce connection error: {e}")
        sys.exit(1)

# -------------------------------------------------------
# Step 3: Look up SF Account by Account_Number__c
# -------------------------------------------------------
def lookup_sf_account(sf, acct_cd):
    soql = f"SELECT Id, Name, Account_Number__c FROM Account WHERE Account_Number__c = '{acct_cd}' LIMIT 1"
    try:
        result = sf.query(soql)
        records = result.get("records", [])
        return records[0] if records else None
    except Exception as e:
        log.error(f"SF lookup error for AccountNumberc={acct_cd}: {e}")
        return None

# -------------------------------------------------------
# Step 4: Build SF update payload from ACU record
# -------------------------------------------------------
def build_update_payload(acu_record):
    payload = {}

    # Standard field map
    for acu_field, sf_field in FIELD_MAP.items():
        if acu_field in acu_record and acu_record[acu_field] is not None:
            payload[sf_field] = acu_record[acu_field]

    # Billing address fields
    for acu_field, sf_field in BILLING_ADDRESS_MAP.items():
        if acu_field in acu_record and acu_record[acu_field] is not None:
            payload[sf_field] = acu_record[acu_field]

    return payload

# -------------------------------------------------------
# Step 5: Update SF Account
# -------------------------------------------------------
def update_sf_account(sf, sf_id, payload, acct_cd):
    try:
        sf.Account.update(sf_id, payload)
        log.info(f"  [UPDATED] AccountNumberc={acct_cd} | SF Id={sf_id} | Fields={list(payload.keys())}")
        return True
    except Exception as e:
        log.error(f"  [ERROR] AccountNumberc={acct_cd} | SF Id={sf_id} | {e}")
        return False

# -------------------------------------------------------
# Main sync loop
# -------------------------------------------------------
def run_sync():
    log.info("=" * 60)
    log.info("  Acumatica -> Salesforce Account Sync")
    log.info(f"  Environment : {ENV.upper()}")
    log.info(f"  Test Mode   : {TEST_MODE}")
    log.info(f"  Log File    : {LOG_FILE}")
    log.info("=" * 60)

    preflight()

    acu_records = fetch_acumatica_records()
    sf = connect_salesforce()

    updated = 0
    skipped = 0
    errors  = 0

    for acu_record in acu_records:
        acct_cd = acu_record.get("AccountNumberc", "").strip()

        if not acct_cd:
            log.warning("  [SKIP] Record missing AccountNumberc — skipping")
            skipped += 1
            continue

        sf_account = lookup_sf_account(sf, acct_cd)

        if not sf_account:
            log.warning(f"  [SKIP] No SF Account found for AccountNumberc={acct_cd}")
            skipped += 1
            continue

        payload = build_update_payload(acu_record)

        if not payload:
            log.warning(f"  [SKIP] AccountNumberc={acct_cd} — no mappable fields in ACU record")
            skipped += 1
            continue

        success = update_sf_account(sf, sf_account["Id"], payload, acct_cd)
        if success:
            updated += 1
        else:
            errors += 1

    log.info("=" * 60)
    log.info(f"  Sync complete — Updated: {updated} | Skipped: {skipped} | Errors: {errors}")
    log.info("=" * 60)


# -------------------------------------------------------
# Entry point
# -------------------------------------------------------
if __name__ == "__main__":
    run_sync()
