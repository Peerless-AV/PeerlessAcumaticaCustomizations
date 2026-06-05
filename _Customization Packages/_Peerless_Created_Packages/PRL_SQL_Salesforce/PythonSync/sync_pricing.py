"""
sync_pricing.py
Peerless-AV | BTG IT

Pulls pricing data from Acumatica OData views and upserts records to Salesforce:
  - vw_Prl_Pricing_All_Columns  → Price_List_Entry__c  (one row per part, pivoted by price class)
  - vw_PRL_Account_Pricing      → SBQQ__ContractedPrice__c  (Customer Pricing rows only)

Lookups resolved at runtime from Salesforce:
  - Price_List__c  (keyed on Name = CustPriceClassID code)
  - Product2       (keyed on Part_Number__c = InventoryCD)
  - Account        (keyed on Account_Number__c = AcctCD)

Outputs per run (always written):
  - sync_pricing_<TIMESTAMP>.csv
  - sync_pricing_<TIMESTAMP>.md

Set DRY_RUN = True to preview without writing to Salesforce.
Script will prompt for confirmation before any live writes.

Author:   BTG IT / Peerless-AV
Created:  2026-05-28
Updated:  2026-06-02
"""

import os
import sys
import requests
import pandas as pd
from dotenv import load_dotenv
from simple_salesforce import Salesforce, SalesforceAuthenticationFailed
from datetime import datetime

load_dotenv()

SCRIPT_NAME = os.path.basename(sys.argv[0])
RUN_TIME    = datetime.now()
TIMESTAMP   = RUN_TIME.strftime("%Y%m%d_%H%M%S")

DRY_RUN     = True   # ← flip to False when ready to commit

# ── Price classes to unpack from vw_Prl_Pricing_All_Columns ──────────────────
# Each entry: (OData column name from view, CustPriceClassID / Price_List__c Name)
PRICE_CLASS_COLUMNS = [
    ("Dealer", "DEAL"),
    ("Part",   "PART"),
    ("Dist",   "DIST"),
    ("Spec",   "SPEC"),
    ("DealCI", "DEALCI"),
    ("DistCI", "DISTCI"),
]

# ── Acumatica OData config ────────────────────────────────────────────────────
# Environment is controlled by ACU_ENV in .env: dev | test | qa | prod
ENV = os.getenv("ACU_ENV", "prod").strip().lower()

BASE_URL_MAP = {
    "dev":  os.getenv("ACU_BASE_URL_DEV"),
    "test": os.getenv("ACU_BASE_URL_TEST"),
    "qa":   os.getenv("ACU_BASE_URL_QA"),
    "prod": os.getenv("ACU_BASE_URL_PROD"),
}

ACU_BASE_URL = BASE_URL_MAP.get(ENV)
ACU_USERNAME = os.getenv("ACU_USERNAME")
ACU_PASSWORD = os.getenv("ACU_PASSWORD")

# ── Salesforce config ─────────────────────────────────────────────────────────
SF_USERNAME       = os.getenv("SF_USERNAME")
SF_PASSWORD       = os.getenv("SF_PASSWORD")
SF_SECURITY_TOKEN = os.getenv("SF_SECURITY_TOKEN", "")
SF_DOMAIN         = os.getenv("SF_DOMAIN", "login")

# ── Pre-flight checks ─────────────────────────────────────────────────────────
def preflight():
    errors = []
    if not ACU_BASE_URL:
        errors.append(f"  - ACU_BASE_URL_{ENV.upper()} is not set in .env")
    if not ACU_USERNAME:
        errors.append("  - ACU_USERNAME is not set in .env")
    if not ACU_PASSWORD:
        errors.append("  - ACU_PASSWORD is not set in .env")
    if not SF_USERNAME:
        errors.append("  - SF_USERNAME is not set in .env")
    if not SF_PASSWORD:
        errors.append("  - SF_PASSWORD is not set in .env")
    if errors:
        print("PREFLIGHT FAILED. Fix the following before running:")
        for e in errors:
            print(e)
        sys.exit(1)

# ── Salesforce connection ─────────────────────────────────────────────────────
def connect_salesforce():
    try:
        sf = Salesforce(
            username=SF_USERNAME,
            password=SF_PASSWORD,
            security_token=SF_SECURITY_TOKEN,
            domain=SF_DOMAIN
        )
        print(f"Salesforce connected: {sf.sf_instance}")
        return sf
    except SalesforceAuthenticationFailed as e:
        print(f"Salesforce authentication failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Salesforce connection error: {e}")
        sys.exit(1)

# ─────────────────────────────────────────────────────────────────────────────
# Acumatica OData fetch — Basic Auth, matches sync_accounts.py pattern
# ─────────────────────────────────────────────────────────────────────────────
def acu_fetch_view(view_name):
    """
    Fetch all rows from an Acumatica OData view using Basic Auth.
    Pages through @odata.nextLink automatically.
    Returns a list of dicts.
    """
    url    = f"{ACU_BASE_URL}/{view_name}"
    rows   = []
    params = {"$format": "json"}

    print(f"  Fetching {view_name} from: {url}")

    while url:
        try:
            resp = requests.get(
                url,
                params=params,
                auth=(ACU_USERNAME, ACU_PASSWORD),
                timeout=60
            )
            resp.raise_for_status()
        except requests.exceptions.HTTPError as e:
            print(f"  Acumatica HTTP error fetching {view_name}: {e} — {resp.text[:300]}")
            sys.exit(1)
        except Exception as e:
            print(f"  Acumatica fetch error for {view_name}: {e}")
            sys.exit(1)

        data   = resp.json()
        rows  += data.get("value", [])
        url    = data.get("@odata.nextLink")
        params = {}   # nextLink already includes params

    print(f"  {view_name}: {len(rows)} rows fetched")
    return rows


# ─────────────────────────────────────────────────────────────────────────────
# Salesforce lookup helpers
# ─────────────────────────────────────────────────────────────────────────────
def build_price_list_map(sf):
    """Returns {Name: Id} for all Price_List__c records."""
    result = sf.query_all("SELECT Id, Name FROM Price_List__c")
    m = {r["Name"]: r["Id"] for r in result["records"]}
    print(f"  Price lists loaded: {len(m)}")
    return m


def chunked_query(sf, soql_template, values, chunk_size=200):
    """
    Splits a large IN-clause query into chunks to avoid SOQL URI length limits.
    soql_template must contain exactly one {} placeholder for the IN list.
    Returns a flat list of all records across all chunks.
    """
    records = []
    for i in range(0, len(values), chunk_size):
        chunk   = values[i:i + chunk_size]
        in_list = "\', \'".join(chunk)
        result  = sf.query_all(soql_template.format(in_list))
        records.extend(result["records"])
    return records


def build_product_map(sf, inventory_cds):
    """Returns {Part_Number__c: Id} for matched Product2 records."""
    records = chunked_query(
        sf,
        "SELECT Id, Part_Number__c FROM Product2 WHERE Part_Number__c IN (\'{}\')",
        list(inventory_cds)
    )
    m = {r["Part_Number__c"]: r["Id"] for r in records}
    print(f"  Products matched: {len(m)} of {len(inventory_cds)} unique SKUs")
    return m


def build_account_map(sf, acct_cds):
    """Returns {Account_Number__c: Id} for matched Account records."""
    records = chunked_query(
        sf,
        "SELECT Id, Account_Number__c FROM Account WHERE Account_Number__c IN (\'{}\')",
        list(acct_cds)
    )
    m = {r["Account_Number__c"]: r["Id"] for r in records}
    print(f"  Accounts matched: {len(m)} of {len(acct_cds)} unique account CDs")
    return m


def build_ple_map(sf):
    """Returns {Product_Price_List_Combo__c: {id, current_price}} for all Price_List_Entry__c."""
    result = sf.query_all(
        "SELECT Id, Product_Price_List_Combo__c, Price_List_Price__c FROM Price_List_Entry__c"
    )
    m = {
        r["Product_Price_List_Combo__c"]: {
            "id":            r["Id"],
            "current_price": r["Price_List_Price__c"]
        }
        for r in result["records"]
        if r["Product_Price_List_Combo__c"]
    }
    print(f"  Existing Price_List_Entry__c records: {len(m)}")
    return m


def build_contract_map(sf):
    """
    Returns {{AcctCD}-{InventoryCD}: {id, current_price}} for all SBQQ__ContractedPrice__c.
    Combo key built in-memory from Account_Number__c + Part_Number__c lookups.
    Requires a reverse lookup pass after fetching all records.
    """
    result = sf.query_all(
        "SELECT Id, SBQQ__Account__c, SBQQ__Product__c, SBQQ__Price__c "
        "FROM SBQQ__ContractedPrice__c "
        "WHERE IsDeleted = false"
    )
    # Build a map keyed on SF ID pair — resolved to combo key after account/product maps are built
    # Returns raw records for post-processing in main()
    records = result["records"]
    print(f"  Existing SBQQ__ContractedPrice__c records: {len(records)}")
    return records


# ─────────────────────────────────────────────────────────────────────────────
# Phase A: Price_List_Entry__c from vw_Prl_Pricing_All_Columns
# ─────────────────────────────────────────────────────────────────────────────
def process_price_list_entries(acu_rows, price_list_map, product_map, ple_map):
    """
    Unpivots the wide pricing view into one row per (InventoryCD, PriceClass).
    Price_List__c Name is built as {PriceGroupCode}{PriceClassCode} (e.g. COREDEAL, ETDIST).
    Returns (rows_log, insert_batch, update_batch).
    """
    rows          = []
    insert_batch  = []
    update_batch  = []

    for r in acu_rows:
        inventory_cd   = str(r.get("InventoryCD", "")).strip()
        price_group    = str(r.get("PriceGroupCode", "")).strip()
        currency       = "USD"   # All-columns view is US tenant only
        product_sf_id  = product_map.get(inventory_cd)

        for col_name, price_code in PRICE_CLASS_COLUMNS:
            new_price = r.get(col_name)
            if new_price is None:
                continue   # price class not populated for this part — skip

            # Price_List__c Name = PriceGroupCode + PriceClassCode (e.g. COREDEAL, ETDIST)
            pl_name   = f"{price_group}{price_code}"
            combo_key = f"{inventory_cd} - {pl_name} - {currency}"
            pl_sf_id  = price_list_map.get(pl_name)
            existing  = ple_map.get(combo_key)

            failures = []
            if not pl_sf_id:
                failures.append(f"Price List '{pl_name}' not found in Price_List__c")
            if not product_sf_id:
                failures.append(f"InventoryCD '{inventory_cd}' not found in Product2.Part_Number__c")

            if failures:
                action = "SKIP"
            elif existing:
                action = "UPDATE"
                update_batch.append({
                    "Id":                  existing["id"],
                    "Price_List_Price__c": new_price
                })
            else:
                action = "INSERT"
                insert_batch.append({
                    "Price_List__c":               pl_sf_id,
                    "Product__c":                  product_sf_id,
                    "Price_List_Price__c":         new_price,
                    "CurrencyIsoCode":             currency,
                    "Product_Price_List_Combo__c": combo_key,
                    "Active__c":                   True
                })

            rows.append({
                "Object":           "Price_List_Entry__c",
                "ComboKey":         combo_key,
                "PriceListSFID":    pl_sf_id or "MISSING",
                "ProductSFID":      product_sf_id or "MISSING",
                "AccountSFID":      "",
                "ExistingRecordID": existing["id"] if existing else "",
                "CurrentPrice":     existing["current_price"] if existing else "",
                "NewPrice":         new_price,
                "Action":           action,
                "SFResult":         "",
                "FailureReason":    " | ".join(failures) if failures else ""
            })

    return rows, insert_batch, update_batch


# ─────────────────────────────────────────────────────────────────────────────
# Phase B: SBQQ__ContractedPrice__c from vw_PRL_Account_Pricing
# ─────────────────────────────────────────────────────────────────────────────
def build_contract_combo_map(sf_records, account_map, product_map):
    """
    Resolves raw SBQQ__ContractedPrice__c SF records into an in-memory combo map.
    Builds reverse lookups from SF ID back to AcctCD / InventoryCD using the
    account_map and product_map (inverted), then keys on {AcctCD}-{InventoryCD}.
    """
    # Invert the lookup maps: SF ID → code
    acct_id_to_cd    = {v: k for k, v in account_map.items()}
    product_id_to_cd = {v: k for k, v in product_map.items()}

    m = {}
    for r in sf_records:
        acct_sf_id    = r.get("SBQQ__Account__c")
        product_sf_id = r.get("SBQQ__Product__c")
        if not acct_sf_id or not product_sf_id:
            continue
        acct_cd    = acct_id_to_cd.get(acct_sf_id)
        product_cd = product_id_to_cd.get(product_sf_id)
        if not acct_cd or not product_cd:
            continue
        combo_key = f"{acct_cd}-{product_cd}"
        m[combo_key] = {
            "id":            r["Id"],
            "current_price": r.get("SBQQ__Price__c")
        }
    print(f"  Resolved SBQQ__ContractedPrice__c combo map: {len(m)} entries")
    return m


def process_contract_pricing(acu_rows, product_map, account_map, contract_map):
    """
    Maps account pricing view rows (Customer Pricing only) to
    SBQQ__ContractedPrice__c upserts.
    Returns (rows_log, insert_batch, update_batch).
    """
    rows          = []
    insert_batch  = []
    update_batch  = []

    for r in acu_rows:
        # Only process customer-specific pricing rows
        price_class = str(r.get("CustomerPriceClass", "")).strip()
        if price_class != "Customer Pricing":
            continue

        inventory_cd   = str(r.get("PartNumber", "")).strip()
        acct_cd        = str(r.get("Customer", "")).strip()
        new_price      = r.get("Price")
        effective_date = r.get("EffectiveDate")
        expiry_date    = r.get("ExpirationDate")
        currency       = "USD"

        if new_price is None:
            continue

        combo_key     = f"{acct_cd}-{inventory_cd}"
        product_sf_id = product_map.get(inventory_cd)
        account_sf_id = account_map.get(acct_cd)
        existing      = contract_map.get(combo_key)

        failures = []
        if not product_sf_id:
            failures.append(f"InventoryCD '{inventory_cd}' not found in Product2.Part_Number__c")
        if not account_sf_id:
            failures.append(f"AcctCD '{acct_cd}' not found in Account.Account_Number__c")

        if failures:
            action = "SKIP"
        elif existing:
            action = "UPDATE"
            update_batch.append({
                "Id":                    existing["id"],
                "SBQQ__Price__c":        new_price,
                "SBQQ__EffectiveDate__c": effective_date,
                "SBQQ__ExpirationDate__c": expiry_date
            })
        else:
            action = "INSERT"
            insert_batch.append({
                "SBQQ__Account__c":        account_sf_id,
                "SBQQ__Product__c":        product_sf_id,
                "SBQQ__Price__c":          new_price,
                "SBQQ__EffectiveDate__c":  effective_date,
                "SBQQ__ExpirationDate__c": expiry_date,
                "CurrencyIsoCode":         currency
            })

        rows.append({
            "Object":           "SBQQ__ContractedPrice__c",
            "ComboKey":         combo_key,
            "PriceListSFID":    "",
            "ProductSFID":      product_sf_id or "MISSING",
            "AccountSFID":      account_sf_id or "MISSING",
            "ExistingRecordID": existing["id"] if existing else "",
            "CurrentPrice":     existing["current_price"] if existing else "",
            "NewPrice":         new_price,
            "Action":           action,
            "SFResult":         "",
            "FailureReason":    " | ".join(failures) if failures else ""
        })

    return rows, insert_batch, update_batch


# ─────────────────────────────────────────────────────────────────────────────
# Bulk write helper
# ─────────────────────────────────────────────────────────────────────────────
def bulk_write(sf, sf_object, insert_batch, update_batch, df_log):
    """Executes bulk inserts and updates; writes results back into df_log."""
    success_inserts = 0
    success_updates = 0
    error_count     = 0

    obj_rows = df_log[df_log["Object"] == sf_object]

    if insert_batch:
        print(f"\n  Bulk INSERT {sf_object} ({len(insert_batch)} records)...")
        results  = getattr(sf.bulk, sf_object).insert(insert_batch, batch_size=200)
        idx_list = obj_rows[obj_rows["Action"] == "INSERT"].index.tolist()
        for i, result in enumerate(results):
            idx = idx_list[i]
            if result.get("success"):
                df_log.at[idx, "SFResult"] = result["id"]
                success_inserts += 1
            else:
                df_log.at[idx, "SFResult"]      = "ERROR"
                df_log.at[idx, "FailureReason"] = str(result.get("errors", "Unknown error"))
                df_log.at[idx, "Action"]        = "ERROR"
                error_count += 1
                print(f"    ✗ {df_log.at[idx, 'ComboKey']}  ERROR: {result.get('errors')}")

    if update_batch:
        print(f"\n  Bulk UPDATE {sf_object} ({len(update_batch)} records)...")
        results  = getattr(sf.bulk, sf_object).update(update_batch, batch_size=200)
        idx_list = obj_rows[obj_rows["Action"] == "UPDATE"].index.tolist()
        for i, result in enumerate(results):
            idx = idx_list[i]
            if result.get("success"):
                df_log.at[idx, "SFResult"] = "UPDATED"
                success_updates += 1
            else:
                df_log.at[idx, "SFResult"]      = "ERROR"
                df_log.at[idx, "FailureReason"] = str(result.get("errors", "Unknown error"))
                df_log.at[idx, "Action"]        = "ERROR"
                error_count += 1
                print(f"    ✗ {df_log.at[idx, 'ComboKey']}  ERROR: {result.get('errors')}")

    return success_inserts, success_updates, error_count


# ─────────────────────────────────────────────────────────────────────────────
# MD report writer
# ─────────────────────────────────────────────────────────────────────────────
def write_md(sf, md_file, mode_label, df_log, csv_file, summary_rows):
    with open(md_file, "w") as f:
        f.write("# Pricing Sync Report\n\n")
        f.write("## Run Metadata\n\n")
        f.write("| Field | Value |\n|---|---|\n")
        f.write(f"| Script | `{SCRIPT_NAME}` |\n")
        f.write(f"| Run Timestamp | {RUN_TIME.strftime('%Y-%m-%d %H:%M:%S')} |\n")
        f.write(f"| ACU Environment | `{ENV.upper()}` |\n")
        f.write(f"| SF Instance | `{sf.sf_instance}` |\n")
        f.write(f"| SF User | `{SF_USERNAME}` |\n")
        f.write(f"| Mode | **{mode_label}** |\n\n")

        f.write("## Summary\n\n")
        f.write("| Object | Action | Count |\n|---|---|---|\n")
        for obj, label, count in summary_rows:
            f.write(f"| {obj} | {label} | {count} |\n")
        f.write(f"\nFull row-by-row log: `{csv_file}`\n\n")

        skips = df_log[df_log["Action"] == "SKIP"]
        if len(skips) > 0:
            f.write(f"## Skip Details ({len(skips)} records)\n\n")
            f.write("| Object | Combo Key | Failure Reason |\n|---|---|---|\n")
            for _, r in skips.iterrows():
                f.write(f"| {r['Object']} | `{r['ComboKey']}` | {r['FailureReason']} |\n")
            f.write("\n")

        errors = df_log[df_log["Action"] == "ERROR"]
        if len(errors) > 0:
            f.write(f"## Errors ({len(errors)} records)\n\n")
            f.write("| Object | Combo Key | Error |\n|---|---|---|\n")
            for _, r in errors.iterrows():
                f.write(f"| {r['Object']} | `{r['ComboKey']}` | {r['FailureReason']} |\n")
            f.write("\n")


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("  Acumatica -> Salesforce Pricing Sync")
    print(f"  Environment : {ENV.upper()}")
    print(f"  Dry Run     : {DRY_RUN}")
    print("=" * 60)

    # ── 0. Pre-flight ─────────────────────────────────────────────────────────
    preflight()

    # ── 1. Connect to Salesforce ──────────────────────────────────────────────
    sf = connect_salesforce()

    # ── 2. Pull data from Acumatica ───────────────────────────────────────────
    print("\nFetching Acumatica view data...")
    all_columns_rows   = acu_fetch_view("vw_Prl_Pricing_All_Columns")
    account_price_rows = acu_fetch_view("vw_PRL_Account_Pricing")

    # ── 3. Build Salesforce lookup maps ───────────────────────────────────────
    print("\nBuilding Salesforce lookup maps...")
    price_list_map = build_price_list_map(sf)

    all_inventory_cds = list({
        str(r.get("InventoryCD", "")).strip() for r in all_columns_rows
    } | {
        str(r.get("PartNumber", "")).strip() for r in account_price_rows
    })
    product_map = build_product_map(sf, all_inventory_cds)

    all_acct_cds = list({
        str(r.get("Customer", "")).strip() for r in account_price_rows
    })
    account_map  = build_account_map(sf, all_acct_cds)
    ple_map           = build_ple_map(sf)
    contract_raw      = build_contract_map(sf)
    contract_map      = build_contract_combo_map(contract_raw, account_map, product_map)

    # ── 4. Build record sets ──────────────────────────────────────────────────
    print("\nBuilding Price_List_Entry__c records...")
    ple_rows, ple_inserts, ple_updates = process_price_list_entries(
        all_columns_rows, price_list_map, product_map, ple_map
    )

    print("Building SBQQ__ContractedPrice__c records...")
    cp_rows, cp_inserts, cp_updates = process_contract_pricing(
        account_price_rows, product_map, account_map, contract_map
    )

    all_rows = ple_rows + cp_rows
    df_log   = pd.DataFrame(all_rows)

    # ── 5. Summary counts ─────────────────────────────────────────────────────
    def counts(obj):
        sub = df_log[df_log["Object"] == obj]
        return (
            (sub["Action"] == "INSERT").sum(),
            (sub["Action"] == "UPDATE").sum(),
            (sub["Action"] == "SKIP").sum(),
        )

    ple_i, ple_u, ple_s = counts("Price_List_Entry__c")
    cp_i,  cp_u,  cp_s  = counts("SBQQ__ContractedPrice__c")
    total_skips          = ple_s + cp_s

    # ── 6. Console preview ────────────────────────────────────────────────────
    print(f"\nPreview (first 10 actionable rows):")
    for _, r in df_log[df_log["Action"] != "SKIP"].head(10).iterrows():
        print(f"  [{r['Action']}]  {r['Object']}  {r['ComboKey']}  |  {r['CurrentPrice']} → {r['NewPrice']}")

    if total_skips > 0:
        print(f"\nSKIPs ({total_skips}):")
        for _, r in df_log[df_log["Action"] == "SKIP"].iterrows():
            print(f"  {r['Object']}  {r['ComboKey']}  |  {r['FailureReason']}")

    # ── 7. CSV output ─────────────────────────────────────────────────────────
    csv_file = f"sync_pricing_{TIMESTAMP}.csv"
    df_log.to_csv(csv_file, index=False)
    print(f"\nCSV log : {csv_file}")

    md_file      = f"sync_pricing_{TIMESTAMP}.md"
    summary_rows = [
        ("Price_List_Entry__c", "Would INSERT" if DRY_RUN else "Inserted", ple_i),
        ("Price_List_Entry__c", "Would UPDATE" if DRY_RUN else "Updated",  ple_u),
        ("Price_List_Entry__c", "Skipped",                                 ple_s),
        ("SBQQ__ContractedPrice__c", "Would INSERT" if DRY_RUN else "Inserted", cp_i),
        ("SBQQ__ContractedPrice__c", "Would UPDATE" if DRY_RUN else "Updated",  cp_u),
        ("SBQQ__ContractedPrice__c", "Skipped",                                 cp_s),
    ]

    # ── 8. Dry run exit ───────────────────────────────────────────────────────
    if DRY_RUN:
        write_md(sf, md_file, "DRY RUN — no records were written", df_log, csv_file, summary_rows)
        print(f"MD log  : {md_file}")
        print(f"\n{'='*60}")
        print(f"DRY RUN COMPLETE — no records were written")
        print(f"{'='*60}")
        print(f"  Price_List_Entry__c  →  INSERT: {ple_i}  UPDATE: {ple_u}  SKIP: {ple_s}")
        print(f"  SBQQ__ContractedPrice__c  →  INSERT: {cp_i}   UPDATE: {cp_u}   SKIP: {cp_s}")
        sys.exit(0)

    # ── 9. Live run confirmation ──────────────────────────────────────────────
    total_inserts = ple_i + cp_i
    total_updates = ple_u + cp_u
    confirm = input(
        f"\nType YES to apply {total_inserts} insert(s) and {total_updates} update(s) "
        f"across Price_List_Entry__c and SBQQ__ContractedPrice__c: "
    ).strip()
    if confirm != "YES":
        print("Aborted — no records written.")
        sys.exit(0)

    # ── 10. Bulk writes ───────────────────────────────────────────────────────
    ple_si, ple_su, ple_err = bulk_write(sf, "Price_List_Entry__c",       ple_inserts, ple_updates, df_log)
    cp_si,  cp_su,  cp_err  = bulk_write(sf, "SBQQ__ContractedPrice__c",  cp_inserts,  cp_updates,  df_log)

    total_errors = ple_err + cp_err

    # Rewrite CSV with SF results populated
    df_log.to_csv(csv_file, index=False)

    live_summary = [
        ("Price_List_Entry__c", "Inserted", ple_si),
        ("Price_List_Entry__c", "Updated",  ple_su),
        ("Price_List_Entry__c", "Skipped",  ple_s),
        ("Price_List_Entry__c", "Errors",   ple_err),
        ("SBQQ__ContractedPrice__c", "Inserted", cp_si),
        ("SBQQ__ContractedPrice__c", "Updated",  cp_su),
        ("SBQQ__ContractedPrice__c", "Skipped",  cp_s),
        ("SBQQ__ContractedPrice__c", "Errors",   cp_err),
    ]
    write_md(sf, md_file, "LIVE RUN — records written to Salesforce", df_log, csv_file, live_summary)

    print(f"\n{'='*60}")
    print(f"LIVE RUN COMPLETE")
    print(f"{'='*60}")
    print(f"  Price_List_Entry__c  →  Inserted: {ple_si}  Updated: {ple_su}  Skipped: {ple_s}  Errors: {ple_err}")
    print(f"  SBQQ__ContractedPrice__c  →  Inserted: {cp_si}   Updated: {cp_su}   Skipped: {cp_s}   Errors: {cp_err}")
    print(f"\nCSV log : {csv_file}")
    print(f"MD log  : {md_file}")

    if total_errors:
        sys.exit(1)


if __name__ == "__main__":
    main()