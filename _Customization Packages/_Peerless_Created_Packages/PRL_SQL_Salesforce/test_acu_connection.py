"""
test_acu_connection.py
Acumatica OData Connection Test
--------------------------------
Validates connectivity to the Acumatica OData endpoint for the
PRL_SFDC_Account_Sync Generic Inquiry across environments.

Usage:
    python test_acu_connection.py

Set ACU_ENV in your .env file to switch environments:
    dev | test | qa | prod
"""

import os
import sys
import requests
from dotenv import load_dotenv

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

BASE_URL  = BASE_URL_MAP.get(ENV)
USERNAME  = os.getenv("ACU_USERNAME")
PASSWORD  = os.getenv("ACU_PASSWORD")

GI_NAME   = "PRL_SFDC_Account_Sync"
TOP_N     = 5   # Number of records to preview

# -------------------------------------------------------
# Pre-flight checks
# -------------------------------------------------------
def preflight():
    errors = []
    if not BASE_URL:
        errors.append(f"  - ACU_BASE_URL_{ENV.upper()} is not set in .env")
    if not USERNAME or USERNAME == "<acu_user>":
        errors.append("  - ACU_USERNAME is not set or still a placeholder")
    if not PASSWORD or PASSWORD == "<acu_pass>":
        errors.append("  - ACU_PASSWORD is not set or still a placeholder")
    if errors:
        print("[PREFLIGHT FAILED] Fix the following before running:\n")
        for e in errors:
            print(e)
        sys.exit(1)

# -------------------------------------------------------
# Test connection
# -------------------------------------------------------
def test_connection():
    url = f"{BASE_URL}/{GI_NAME}"
    params = {
        "$top": TOP_N,
        "$format": "json"
    }

    print(f"\n{'='*60}")
    print(f"  Acumatica OData Connection Test")
    print(f"{'='*60}")
    print(f"  Environment : {ENV.upper()}")
    print(f"  Base URL    : {BASE_URL}")
    print(f"  GI Endpoint : {url}")
    print(f"  Username    : {USERNAME}")
    print(f"{'='*60}\n")

    try:
        response = requests.get(
            url,
            params=params,
            auth=(USERNAME, PASSWORD),
            timeout=30
        )

        print(f"  HTTP Status : {response.status_code}")

        if response.status_code == 200:
            data = response.json()
            records = data.get("value", [])
            print(f"  Records returned (top {TOP_N}): {len(records)}\n")

            if records:
                print("  --- Field names from first record ---")
                for key in records[0].keys():
                    print(f"    {key}: {records[0][key]}")
                print(f"\n  [SUCCESS] Connection to {ENV.upper()} is working.\n")
            else:
                print("  [WARNING] Connected successfully but no records returned.")
                print("  Check that the GI has data and is published/exposed via OData.\n")

        elif response.status_code == 401:
            print("\n  [FAILED] 401 Unauthorized - Check your ACU_USERNAME and ACU_PASSWORD.\n")
        elif response.status_code == 404:
            print(f"\n  [FAILED] 404 Not Found - Verify the GI name '{GI_NAME}' is correct")
            print(f"  and that it is published and exposed via OData in this environment.\n")
        else:
            print(f"\n  [FAILED] Unexpected response:")
            print(f"  {response.text[:500]}\n")

    except requests.exceptions.ConnectionError:
        print(f"\n  [FAILED] Could not connect to: {BASE_URL}")
        print("  Check that the Acumatica instance is running and the URL is correct.\n")
    except requests.exceptions.Timeout:
        print("\n  [FAILED] Request timed out. The server may be slow or unreachable.\n")
    except Exception as e:
        print(f"\n  [FAILED] Unexpected error: {e}\n")


# -------------------------------------------------------
# Entry point
# -------------------------------------------------------
if __name__ == "__main__":
    preflight()
    test_connection()
