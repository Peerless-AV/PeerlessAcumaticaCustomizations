import os
import requests
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

# ----------------------------------------------------------------
# Config
# ----------------------------------------------------------------
BASE_URL    = os.getenv("ACU_BASE_URL_PROD")
USERNAME    = os.getenv("ACU_USERNAME")
PASSWORD    = os.getenv("ACU_PASSWORD")
GI_NAME     = "PRL_SFDC_PART_ODATA"
ODATA_PATH  = f"/{GI_NAME}"
OUTPUT_FILE = "acumatica_products_raw.csv"

# ----------------------------------------------------------------
# Fetch with Basic Auth + pagination
# ----------------------------------------------------------------
def fetch_all_records():
    url     = f"{BASE_URL}{ODATA_PATH}"
    auth    = (USERNAME, PASSWORD)
    headers = {"Accept": "application/json"}
    records = []
    page    = 0

    print(f"Connecting to: {url}")

    while url:
        response = requests.get(url, auth=auth, headers=headers)

        if response.status_code != 200:
            print(f"Error {response.status_code}: {response.text[:500]}")
            break

        data     = response.json()
        batch    = data.get("value", [])
        records.extend(batch)
        page    += 1
        print(f"  Page {page}: {len(batch)} records (total so far: {len(records)})")

        # OData next page link
        url = data.get("@odata.nextLink", None)

    return records

# ----------------------------------------------------------------
# Main
# ----------------------------------------------------------------
def main():
    records = fetch_all_records()

    if not records:
        print("No records returned.")
        return

    df = pd.DataFrame(records)

    print(f"\nTotal records: {len(df)}")
    print(f"Columns ({len(df.columns)}):")
    for col in df.columns:
        sample = df[col].dropna().iloc[0] if not df[col].dropna().empty else "N/A"
        print(f"  {col}: {sample}")

    df.to_csv(OUTPUT_FILE, index=False)
    print(f"\nSaved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()