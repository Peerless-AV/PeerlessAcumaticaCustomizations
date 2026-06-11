"""
sync_products.py
Acumatica → Salesforce Product2 Sync (US Tenant — OData via PRL_SFDC_PART_ODATA GI)

Author:  BTG IT Team — Peerless AV
Created: 2026-06-10
"""

import os
import csv
import requests
import logging
from datetime import datetime
from dotenv import load_dotenv
from simple_salesforce import Salesforce, SalesforceError

load_dotenv()

# ----------------------------------------------------------------
# Config
# ----------------------------------------------------------------
DRY_RUN     = True   # Set to False to write to Salesforce
TEST_MODE   = False  # Set to True to limit to TEST_PART_NUMBER only
TEST_PART   = "LEDUNVS-4X3"

GI_NAME     = "PRL_SFDC_PART_ODATA"
BATCH_SIZE  = 200

TIMESTAMP   = datetime.now().strftime("%Y%m%d_%H%M%S")
LOG_FILE    = f"sync_products_{TIMESTAMP}.log"
CSV_FILE    = f"sync_products_{TIMESTAMP}.csv"
UNMATCHED_FILE = f"sync_products_unmatched_{TIMESTAMP}.csv"

# ----------------------------------------------------------------
# Logging
# ----------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)

# ----------------------------------------------------------------
# ItemStatus → IsActive mapping (GI returns spelled-out values)
# ----------------------------------------------------------------
ACTIVE_STATUSES = {"Active", "No Purchases", "No Request"}

# ----------------------------------------------------------------
# ItemClass → Category__c mapping
# Values are RTRIM'd before lookup
# ----------------------------------------------------------------
CATEGORY_MAP = {
    # KIOSK
    "BPE  STAND"           : "KIOSK",
    "KIOSKCUSTM"           : "KIOSK",
    "KIOSKSTAND"           : "KIOSK",
    "KIOSKSTANDINDOR"      : "KIOSK",
    "KIOSKSTANDINDORGROUN" : "KIOSK",
    "KIOSKSTANDINDORWALL"  : "KIOSK",
    "KIOSKSTANDOUTDR"      : "KIOSK",
    "KIOSKSTANDOUTDRGROUN" : "KIOSK",
    "VLTA"                 : "KIOSK",
    "VLTA CUSTM"           : "KIOSK",
    "VLTA STAND"           : "KIOSK",
    # LED
    "DS   CUSTM"           : "LED",
    "DS   STAND"           : "LED",
    "LED"                  : "LED",
    "LED  CUSTM"           : "LED",
    "LED  CUSTMACC"        : "LED",
    "LED  CUSTMDED"        : "LED",
    "LED  CUSTMLEDF"       : "LED",
    "LED  CUSTMLEDFS"      : "LED",
    "LED  CUSTMSUBF"       : "LED",
    "LED  CUSTMTK"         : "LED",
    "LED  CUSTMUNV"        : "LED",
    "LED  STAND"           : "LED",
    "LED  STANDACC"        : "LED",
    "LED  STANDACC  LED"   : "LED",
    "LED  STANDACC  LEDTK" : "LED",
    "LED  STANDDED"        : "LED",
    "LED  STANDLEDF"       : "LED",
    "LED  STANDLEDFS"      : "LED",
    "LED  STANDSUBF"       : "LED",
    "LED  STANDTK"         : "LED",
    "LED  STANDUNV"        : "LED",
    # DVLED
    "DVLED"                : "DVLED",
    "DVLEDCUSTM     MAHLO" : "DVLED",
    # TV
    "ET   STAND"           : "TV",
    "ET   STANDNEPTN"      : "TV",
    "ET   STANDULTVW"      : "TV",
    "ET   STANDXTRME"      : "TV",
    # MOUNT
    "FPSS"                 : "MOUNT",
    "FPSS CUSTM"           : "MOUNT",
    "FPSS STAND"           : "MOUNT",
    "FPSS STANDETAIL"      : "MOUNT",
    "FPSS STANDPMNT"       : "MOUNT",
    "FPSS STANDSMRT"       : "MOUNT",
    "FPSS STANDSMRXT"      : "MOUNT",
    "FPSS STANDTRVUE"      : "MOUNT",
    "HOSP CUSTM"           : "MOUNT",
    "HOSP STAND"           : "MOUNT",
    "PSS"                  : "MOUNT",
    "PSS  CUSTM"           : "MOUNT",
    "PSS  STAND"           : "MOUNT",
    "PSS  STANDPJF2"       : "MOUNT",
    "PSS  STANDPJR"        : "MOUNT",
    "PSS  STANDPRG"        : "MOUNT",
    "PSS  STANDPRGS"       : "MOUNT",
}

# ----------------------------------------------------------------
# Preflight
# ----------------------------------------------------------------
def preflight():
    required = [
        "ACU_BASE_URL_PROD", "ACU_USERNAME", "ACU_PASSWORD",
        "SF_USERNAME", "SF_PASSWORD", "SF_DOMAIN"
    ]
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        raise EnvironmentError(f"Missing .env values: {', '.join(missing)}")
    log.info("Preflight passed.")

# ----------------------------------------------------------------
# Acumatica OData fetch
# ----------------------------------------------------------------
def fetch_acumatica():
    base_url = os.getenv("ACU_BASE_URL_PROD")
    auth     = (os.getenv("ACU_USERNAME"), os.getenv("ACU_PASSWORD"))
    headers  = {"Accept": "application/json"}
    url      = f"{base_url}/{GI_NAME}"
    records  = []
    page     = 0

    log.info(f"Fetching from Acumatica: {url}")

    while url:
        resp = requests.get(url, auth=auth, headers=headers)
        if resp.status_code != 200:
            raise ConnectionError(f"Acumatica OData error {resp.status_code}: {resp.text[:300]}")

        data  = resp.json()
        batch = data.get("value", [])
        records.extend(batch)
        page += 1
        log.info(f"  Page {page}: {len(batch)} records (total: {len(records)})")
        url = data.get("@odata.nextLink", None)

    log.info(f"Acumatica fetch complete — {len(records)} total records.")
    return records

# ----------------------------------------------------------------
# Connect to Salesforce
# ----------------------------------------------------------------
def connect_salesforce():
    try:
        sf = Salesforce(
            username=os.getenv("SF_USERNAME"),
            password=os.getenv("SF_PASSWORD"),
            security_token=os.getenv("SF_SECURITY_TOKEN", ""),
            domain=os.getenv("SF_DOMAIN", "login")
        )
        log.info(f"Connected to Salesforce: {sf.sf_instance}")
        return sf
    except Exception as e:
        raise ConnectionError(f"Salesforce connection failed: {e}")

# ----------------------------------------------------------------
# Build existing Salesforce product map keyed on ProductCode
# ----------------------------------------------------------------
def build_sf_product_map(sf):
    log.info("Querying existing Salesforce Product2 records...")
    result  = sf.query_all(
        "SELECT Id, ProductCode, Name, Description, IsActive, "
        "QuantityUnitOfMeasure, StockKeepingUnit, "
        "US_Description__c, US_Price_Group_Name__c, "
        "ACU_Item_Status__c, ACU_PMPLCM__c, "
        "Sales_Part_Status__c, ACU_Authorization_Required__c, "
        "Category__c, Part_Number__c "
        "FROM Product2"
    )
    product_map = {
        r["ProductCode"]: r
        for r in result["records"]
        if r.get("ProductCode")
    }
    log.info(f"Found {len(product_map)} existing Product2 records in Salesforce.")
    return product_map

# ----------------------------------------------------------------
# Transform one Acumatica record → Salesforce payload
# ----------------------------------------------------------------
def transform(acu_record):
    part_number  = (acu_record.get("PartNumber") or "").strip()
    description  = (acu_record.get("Description") or "").strip()
    item_status  = (acu_record.get("ItemStatus") or "").strip()
    sales_unit   = (acu_record.get("SalesUnit") or "").strip()
    authorization = str(acu_record.get("Authorization") or "False").strip()
    price_group  = (acu_record.get("PriceGroup") or "").strip()
    plcm         = (acu_record.get("ProductLifeCycleManagement") or "").strip()
    item_class   = (acu_record.get("ItemClass") or "").strip()

    is_active    = "True" if item_status in ACTIVE_STATUSES else "False"
    category     = CATEGORY_MAP.get(item_class, None)

    return {
        "Name"                        : part_number,
        "ProductCode"                 : part_number,
        "StockKeepingUnit"            : part_number,
        "Part_Number__c"              : part_number,
        "Description"                 : description,
        "US_Description__c"           : description,
        "IsActive"                    : is_active == "True",
        "QuantityUnitOfMeasure"       : sales_unit,
        "ACU_Item_Status__c"          : item_status,
        "Sales_Part_Status__c"        : item_status,
        "ACU_Authorization_Required__c": authorization == "True",
        "US_Price_Group_Name__c"      : price_group,
        "ACU_PMPLCM__c"              : plcm or None,
        "Category__c"                 : category,
    }

# ----------------------------------------------------------------
# Diff — determine action for each record
# ----------------------------------------------------------------
def determine_action(sf_payload, sf_existing):
    if sf_existing is None:
        return "INSERT"

    changed_fields = []
    for key, new_val in sf_payload.items():
        if key in ("Name", "ProductCode", "StockKeepingUnit", "Part_Number__c"):
            continue  # key fields — not change indicators
        old_val = sf_existing.get(key)
        # Normalize for comparison
        if isinstance(new_val, bool):
            old_val = str(old_val).lower() == "true" if old_val is not None else False
        elif new_val is None and old_val is None:
            continue
        if str(new_val) != str(old_val):
            changed_fields.append(key)

    if changed_fields:
        return f"UPDATE ({', '.join(changed_fields)})"
    return "NO CHANGE"

# ----------------------------------------------------------------
# Write dry run CSV
# ----------------------------------------------------------------
def write_dry_run_csv(results):
    fieldnames = [
        "Action", "PartNumber", "Name", "Description",
        "IsActive", "ItemStatus", "SalesUnit",
        "Authorization", "PriceGroup", "PLCM", "Category",
        "SF_Id"
    ]
    with open(CSV_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)
    log.info(f"Dry run CSV written: {CSV_FILE}")

# ----------------------------------------------------------------
# Write unmatched item class CSV
# ----------------------------------------------------------------
def write_unmatched_csv(unmatched):
    if not unmatched:
        return
    with open(UNMATCHED_FILE, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["PartNumber", "ItemClass"])
        writer.writeheader()
        writer.writerows(unmatched)
    log.info(f"Unmatched item classes written: {UNMATCHED_FILE} ({len(unmatched)} records)")

# ----------------------------------------------------------------
# Batch upsert to Salesforce
# ----------------------------------------------------------------
def upsert_batch(sf, batch):
    results = sf.bulk.Product2.upsert(batch, "ProductCode", batch_size=BATCH_SIZE)
    success = sum(1 for r in results if r.get("success"))
    errors  = [r for r in results if not r.get("success")]
    log.info(f"  Batch upsert: {success} succeeded, {len(errors)} failed.")
    for e in errors:
        log.error(f"  UPSERT ERROR: {e}")

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
def main():
    mode_label = "DRY RUN" if DRY_RUN else "LIVE"
    log.info(f"=== sync_products.py starting — {mode_label} ===")

    preflight()

    # Fetch Acumatica
    acu_records = fetch_acumatica()

    if TEST_MODE:
        acu_records = [r for r in acu_records if (r.get("PartNumber") or "").strip() == TEST_PART]
        log.info(f"TEST MODE — filtered to part: {TEST_PART} ({len(acu_records)} record(s))")

    # Connect Salesforce
    sf = connect_salesforce()
    sf_map = build_sf_product_map(sf)

    # Process
    dry_run_rows  = []
    unmatched     = []
    to_upsert     = []

    inserts    = 0
    updates    = 0
    no_changes = 0

    for acu in acu_records:
        part_number = (acu.get("PartNumber") or "").strip()
        if not part_number:
            continue

        payload     = transform(acu)
        sf_existing = sf_map.get(part_number)
        action      = determine_action(payload, sf_existing)

        # Track unmatched item classes
        item_class = (acu.get("ItemClass") or "").strip()
        if item_class and payload.get("Category__c") is None:
            unmatched.append({"PartNumber": part_number, "ItemClass": item_class})

        # Dry run row
        dry_run_rows.append({
            "Action"       : action,
            "PartNumber"   : part_number,
            "Name"         : payload["Name"],
            "Description"  : payload["Description"],
            "IsActive"     : payload["IsActive"],
            "ItemStatus"   : payload["ACU_Item_Status__c"],
            "SalesUnit"    : payload["QuantityUnitOfMeasure"],
            "Authorization": payload["ACU_Authorization_Required__c"],
            "PriceGroup"   : payload["US_Price_Group_Name__c"],
            "PLCM"         : payload["ACU_PMPLCM__c"],
            "Category"     : payload["Category__c"],
            "SF_Id"        : sf_existing["Id"] if sf_existing else "",
        })

        if action == "NO CHANGE":
            no_changes += 1
        elif action.startswith("UPDATE"):
            updates += 1
            if not DRY_RUN:
                payload["Id"] = sf_existing["Id"]
                to_upsert.append(payload)
        else:  # INSERT
            inserts += 1
            if not DRY_RUN:
                to_upsert.append(payload)

    # Summary
    log.info(f"\n--- Summary ---")
    log.info(f"  Total processed : {len(dry_run_rows)}")
    log.info(f"  Inserts         : {inserts}")
    log.info(f"  Updates         : {updates}")
    log.info(f"  No change       : {no_changes}")
    log.info(f"  Unmatched class : {len(unmatched)}")

    # Write dry run CSV always
    write_dry_run_csv(dry_run_rows)
    write_unmatched_csv(unmatched)

    # Live upsert
    if not DRY_RUN and to_upsert:
        log.info(f"Upserting {len(to_upsert)} records to Salesforce...")
        for i in range(0, len(to_upsert), BATCH_SIZE):
            batch = to_upsert[i:i + BATCH_SIZE]
            log.info(f"  Batch {i // BATCH_SIZE + 1}: {len(batch)} records")
            upsert_batch(sf, batch)
        log.info("Upsert complete.")
    elif DRY_RUN:
        log.info("DRY RUN — no writes to Salesforce. Review CSV before setting DRY_RUN = False.")

    log.info(f"=== sync_products.py complete ===")

if __name__ == "__main__":
    main()