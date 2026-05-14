"""
test_sf_connection.py
Salesforce Connection Test
---------------------------
Validates connectivity to Salesforce and retrieves a single
Account record by Account_Number__c to confirm the match key
is working before any sync operations are run.

Usage:
    python test_sf_connection.py
"""

import os
import sys
from dotenv import load_dotenv
from simple_salesforce import Salesforce, SalesforceAuthenticationFailed

# -------------------------------------------------------
# Load environment variables
# -------------------------------------------------------
load_dotenv()

SF_USERNAME       = os.getenv("SF_USERNAME")
SF_PASSWORD       = os.getenv("SF_PASSWORD")
SF_SECURITY_TOKEN = os.getenv("SF_SECURITY_TOKEN", "")
SF_DOMAIN         = os.getenv("SF_DOMAIN", "login")

TEST_ACCOUNT_NUMBER = "ANV254900"

# -------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------
def preflight():
    errors = []
    if not SF_USERNAME or SF_USERNAME == "<sf_username>":
        errors.append("  - SF_USERNAME is not set or still a placeholder")
    if not SF_PASSWORD or SF_PASSWORD == "<sf_password>":
        errors.append("  - SF_PASSWORD is not set or still a placeholder")
    if errors:
        print("[PREFLIGHT FAILED] Fix the following before running:\n")
        for e in errors:
            print(e)
        sys.exit(1)

# -------------------------------------------------------
# Test connection
# -------------------------------------------------------
def test_connection():
    print(f"\n{'='*60}")
    print(f"  Salesforce Connection Test")
    print(f"{'='*60}")
    print(f"  Username        : {SF_USERNAME}")
    print(f"  Domain          : {SF_DOMAIN}")
    print(f"  Test Account #  : {TEST_ACCOUNT_NUMBER}")
    print(f"{'='*60}\n")

    # --- Connect ---
    try:
        sf = Salesforce(
            username=SF_USERNAME,
            password=SF_PASSWORD,
            security_token=SF_SECURITY_TOKEN,
            domain=SF_DOMAIN
        )
        print(f"  [OK] Connected to: {sf.sf_instance}\n")
    except SalesforceAuthenticationFailed as e:
        print(f"\n  [FAILED] Authentication failed: {e}")
        print("  Check SF_USERNAME, SF_PASSWORD, and SF_SECURITY_TOKEN in .env\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n  [FAILED] Unexpected error during connection: {e}\n")
        sys.exit(1)

    # --- Query test account ---
    try:
        soql = f"""
            SELECT Id, Name, Account_Number__c, Phone, BillingStreet,
                   BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
            WHERE Account_Number__c = '{TEST_ACCOUNT_NUMBER}'
            LIMIT 1
        """
        result = sf.query(soql)
        records = result.get("records", [])

        if not records:
            print(f"  [WARNING] No Account found with Account_Number__c = '{TEST_ACCOUNT_NUMBER}'")
            print("  Confirm the value exists in Salesforce and the field API name is correct.\n")
            return

        record = records[0]
        print(f"  [OK] Account found. Current field values:\n")
        for key, value in record.items():
            if key != "attributes":
                print(f"    {key}: {value}")

        print(f"\n  [SUCCESS] Salesforce connection and account lookup working.\n")

    except Exception as e:
        print(f"\n  [FAILED] Query error: {e}\n")


# -------------------------------------------------------
# Entry point
# -------------------------------------------------------
if __name__ == "__main__":
    preflight()
    test_connection()
