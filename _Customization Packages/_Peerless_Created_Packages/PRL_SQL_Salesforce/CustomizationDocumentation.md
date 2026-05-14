# Acumatica To Salesforce Sync

**Created:** 2026-04-08  
**Updated:** 2026-05-14  
**Author:** Dan Zabinski  

---

## Overview

This project contains the SQL views and supporting Python scripts used to synchronize customer and account data from **Acumatica** (ERP) into **Salesforce (SFDC)**. It is maintained by the BTG (IT) Team at Peerless and is intended for internal development and integration use.

The core approach uses SQL views deployed inside Acumatica customization projects. Each view selects fields flagged for sync in the ACCOUNT-2026 field mapping document, reads across all active Acumatica companies (tenants) within a single shared database, and constructs a composite unique key that serves as the external ID for update operations into Salesforce.

> **Current Status:** Account sync is staged for final testing. Both the Acumatica OData connection and the Salesforce connection have been validated. The sync script is ready to run against a single test account (`ANV254900`) before full production rollout.

---

## Architecture

### Data Flow

```
Acumatica SQL Database
        │
        ▼
  SQL View (vw_SFDC_Account_Acumatica_AllTenants)
        │
        ▼
  Acumatica Generic Inquiry (PRL_SFDC_Account_Sync)
  exposed via OData endpoint
        │
        ▼
  Python Sync Script (sync_accounts.py)
  scheduled via Windows Task Scheduler
        │
        ▼
  Salesforce (SFDC) — Account object updated
```

### Sync Rules

- **Updates only.** Records originate in Salesforce. The sync script never inserts new Accounts.
- **Match key:** Salesforce `Account_Number__c` matched against Acumatica `AccountNumberc` (OData property name for `AcctCD`).
- **No match = skip and log.** If no Salesforce Account is found for an Acumatica record, it is logged and skipped without error.
- **All three tenants** (US, UK, MX) are included in the view and GI output.

### Multi-Company Strategy

Acumatica stores all company (tenant) data in a **single shared database**, isolating records via a `CompanyID` column present on every table. The view:

- Reads from `[dbo].[Company]` using `CompanyCD` name matching to identify the three tenants
- Constructs a **composite external key** in the format `CompanyID|AcctCD` for internal reference
- The `AccountNumberc` field (raw `AcctCD`) is used as the Salesforce match key

---

## Repository Structure

```
/
├── README.md                                         # This file
├── .env.example                                      # Environment variable template
├── requirements.txt                                  # Python dependencies
├── sync_accounts.py                                  # Main account sync script
├── test_acu_connection.py                            # Acumatica OData connection test
├── test_sf_connection.py                             # Salesforce connection test
└── views/
    └── vw_SFDC_Account_Acumatica_AllTenants.sql      # Account sync SQL view
```

---

## Environment Setup

### Prerequisites

- Python 3.x installed on the Windows server
- Access to Acumatica (OData endpoint enabled, user with GI access)
- Access to Salesforce (production or sandbox)

### First-Time Setup

1. Clone the repository to the target Windows server
2. Install Python dependencies:
   ```
   pip install -r requirements.txt
   ```
3. Copy `.env.example` to `.env` in the same directory:
   ```
   copy .env.example .env
   ```
4. Open `.env` and replace all placeholder values with actual credentials (see `.env.example` for key names)
5. Set `ACU_ENV` to the target environment (`dev`, `test`, `qa`, or `prod`)

### Environment Variables

| Variable | Description |
|---|---|
| `ACU_ENV` | Active environment: `dev`, `test`, `qa`, or `prod` |
| `ACU_BASE_URL_DEV` | Acumatica OData base URL for local DEV |
| `ACU_BASE_URL_TEST` | Acumatica OData base URL for System Test |
| `ACU_BASE_URL_QA` | Acumatica OData base URL for QA |
| `ACU_BASE_URL_PROD` | Acumatica OData base URL for Production |
| `ACU_USERNAME` | Acumatica username |
| `ACU_PASSWORD` | Acumatica password |
| `SF_USERNAME` | Salesforce username |
| `SF_PASSWORD` | Salesforce password |
| `SF_SECURITY_TOKEN` | Salesforce security token (leave blank if IP is trusted) |
| `SF_DOMAIN` | `login` for production, `test` for sandbox |

### Environment URLs

| Environment | OData Base URL |
|---|---|
| DEV (local) | `http://localhost/2024r2dev/odata/peerless-av` |
| Test | `https://testbtg.peerless-avbtg.com/2024testbtg/odata/peerless-av` |
| QA | `https://acumatica.peerless-avbtg.com/2024r2QA/odata/peerless-av` |
| Production | `https://peerless-av.acumatica.com/odata/peerless-av` |

---

## Testing & Validation

Run these scripts in order before enabling full sync.

### Step 1 — Test Acumatica OData Connection

```
python test_acu_connection.py
```

Validates connectivity to Acumatica OData and returns the first 5 records from `PRL_SFDC_Account_Sync`. Confirms the GI is published and your user has OData access.

**Note:** The Acumatica user must have the appropriate role assigned to access the GI via OData. Add the role to the Acumatica customization package when deploying.

### Step 2 — Test Salesforce Connection

```
python test_sf_connection.py
```

Validates Salesforce authentication and retrieves test account `ANV254900` by `Account_Number__c`. Confirms the match key field exists and is queryable.

### Step 3 — Run Account Sync (Test Mode)

```
python sync_accounts.py
```

With `TEST_MODE = True` (default), the script filters to account `ANV254900` only. Verify the log output shows the expected fields updated in Salesforce before flipping to full sync.

### Step 4 — Full Sync

When test results are confirmed:
1. Open `sync_accounts.py`
2. Set `TEST_MODE = False`
3. Run the script

---

## Sync Script Details (`sync_accounts.py`)

### What It Does

1. Loads credentials and environment from `.env`
2. Pulls Account records from Acumatica via the `PRL_SFDC_Account_Sync` OData endpoint
3. For each record, queries Salesforce for a matching Account by `Account_Number__c`
4. If found, updates the Salesforce Account with mapped field values
5. If not found, logs a skip — no insert is performed
6. Writes a timestamped log file (`sync_accounts_YYYYMMDD_HHMMSS.log`) to the script directory

### Field Mapping

Fields synced are those flagged `Sync from Acumatica = Yes` in `NEWSF MAPPING FOR ACUCAT2026.xlsx`, tab `ACCOUNT-2026`.

| Acumatica OData Field | Salesforce Field | Notes |
|---|---|---|
| `Name` | `Name` | |
| `Acucustomerclassc` | `ACU_CUSTOMER_CLASS__c` | |
| `Acucustomerstatusc` | `ACU_CUSTOMER_STATUS__c` | |
| `Acutierc` | `ACU_TIER__c` | |
| `Acucreditlimitc` | `ACU_CREDIT_LIMIT__c` | |
| `Acucreditremainc` | `ACU_CREDIT_REMAIN__c` | |
| `AcuCustomerCreditRulec` | `Acu_Customer_Credit_Rule__c` | |
| `Acucredittermsc` | `ACU_CREDIT_TERMS__c` | |
| `RemainingCreditc` | `Remaining_Credit__c` | |
| `AcuCustomerCoordinatorc` | `Acu_Customer_Coordinator__c` | |
| `ACUCustomerKeyDirectorc` | `ACU_Customer_Key_Director__c` | |
| `ACUCustomerKeyManagerc` | `ACU_Customer_Key_Manager__c` | |
| `AcuCustomerSalesOperationsc` | `Acu_Customer_Sales_Operations__c` | |
| `ACUCustomerInsideSalesRepc` | `ACU_Customer_Inside_Sales_Rep__c` | |
| `AcuCustomerCommissionReceiverc` | `Acu_Customer_Commission_Receiver__c` | |
| `Acucustomerpostypec` | `ACU_CUSTOMER_POSTYPE__c` | |
| `Acuproaccountgroupc` | `ACU_PRO_ACCOUNT_GROUP__c` | Shares source with POSTYPE |
| `Acuproaccounttypec` | `ACU_PRO_ACCOUNT_TYPE__c` | |
| `ACUOutsideRepFirms` | `ACU_Outside_Rep_Firms` | |
| `ExpiredDatec` | `Expired_Date__c` | |
| `BillingStreet` | `BillingStreet` | |
| `BillingCity` | `BillingCity` | |
| `BillingState` | `BillingState` | |
| `BillingPostalCode` | `BillingPostalCode` | |
| `BillingCountry` | `BillingCountry` | |

### Skipped / Deferred Fields

| Field | Reason |
|---|---|
| `Acuaccountownerc` | Salesforce `OwnerId` is a User lookup. Resolving salesperson name → SF User ID requires an additional lookup step. Deferred to future build. |
| `BillingStreet2` | No direct Salesforce compound address equivalent. |
| `AccountNumberc` | Used as the match key only. Not updated. |
| `ExternalKey` | Internal composite key (`CompanyID\|AcctCD`). Not synced to Salesforce. |
| `TenantCode` | Internal tenant identifier. Not synced to Salesforce. |

---

## Acumatica GI / OData Notes

- **GI Name:** `PRL_SFDC_Account_Sync`
- **OData entity path:** `{base_url}/PRL_SFDC_Account_Sync`
- The GI must be published and have **Expose via OData** checked in Acumatica
- The sync user must have the appropriate **Access Rights** role assigned to the GI
- This role assignment should be included in the Acumatica customization package

---

## Views

### `vw_SFDC_Account_Acumatica_AllTenants`

**Purpose:** Surfaces all Account-level fields flagged `Sync from Acumatica = Yes` in the ACCOUNT-2026 mapping tab. Feeds the `PRL_SFDC_Account_Sync` Generic Inquiry.

**Source Tables:**

| Table | Purpose |
|---|---|
| `[dbo].[Company]` | Active company/tenant registry |
| `[dbo].[Customer]` | Core customer master record |
| `[dbo].[BAccount]` | Business account (name, status, NoteID) |
| `[dbo].[Address]` | Billing address |
| `[dbo].[ARBalances]` | Customer credit balance data |
| `[dbo].[CustSalesPeople]` | Salesperson role assignments (pivoted) |
| `[dbo].[SalesPerson]` | Salesperson display name reference |
| `[dbo].[CSAnswers]` | Custom attribute values (PROGROUP, BILLING, SOREPFIRM, AREXPDATE) |

---

## Deployment

Views are deployed as part of an **Acumatica Customization Project**. All table references use `[dbo].[TableName]` with no database prefix.

To deploy:
1. Open your Acumatica Customization Project in the Acumatica Customization Editor
2. Add the SQL script under the **SQL Scripts** section
3. Add the GI access role to the customization package
4. Publish the customization

---

## Integration Notes

- **Account Owner:** `Acuaccountownerc` surfaces a name string. The ETL layer must resolve this to a Salesforce User ID before populating `OwnerId`. Deferred to a future build.
- **PROGROUP Dual-Use:** Both `ACU_CUSTOMER_POSTYPE__c` and `ACU_PRO_ACCOUNT_GROUP__c` source from the same `PROGROUP` attribute. If picklist values differ between the two SFDC fields, apply a CASE transform in the view or script.
- **Remaining Credit:** Two fields source credit data from different tables (`Customer` vs `ARBalances`). Confirm with stakeholders which is authoritative for each SFDC field.
- **Future — Acumatica-Native Option:** A future build option exists to move the sync logic into an Acumatica customization (C# Graph/Action with outbound HTTP calls to Salesforce), eliminating the middleware script. Shelved pending timing and environment confirmation of outbound HTTP support in the hosted instance.

---

## Field Mapping Reference

The authoritative field mapping document is:

**`NEWSF MAPPING FOR ACUCAT2026.xlsx`** → Tab: `ACCOUNT-2026`

Fields included in this project are those where the **`Sync from Acumatica`** column = `Yes`.

---

## Change Log

| Date | Version | Author | Description |
|---|---|---|---|
| 2026-04-08 | 1.0 | Dan Zabinski | Initial creation of `vw_SFDC_Account_Acumatica_AllTenants` view based on ACCOUNT-2026 mapping |
| 2026-05-14 | 1.1 | Dan Zabinski | Added Python middleware sync layer. Acumatica OData and Salesforce connections validated. Account sync staged for final testing against `ANV254900`. Added `sync_accounts.py`, `test_acu_connection.py`, `test_sf_connection.py`, `.env.example`, `requirements.txt`. Updated architecture, deployment, and field mapping documentation. |
