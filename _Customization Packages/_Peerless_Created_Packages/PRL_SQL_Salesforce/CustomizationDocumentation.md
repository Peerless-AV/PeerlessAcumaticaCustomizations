# Acumatica To Salesforce Sync

**Created:** 2026-04-08  
**Updated:** 2026-04-08  
**Author:** Dan Zabinski  

---

## Overview

This project contains the SQL views and supporting scripts used to synchronize customer and account data from **Acumatica** (ERP) into **Salesforce (SFDC)**. It is maintained by the BTG (IT) Team at Peerless and is intended for internal development and integration use.

The core approach uses SQL views deployed inside Acumatica customization projects. Each view selects fields flagged for sync in the ACCOUNT-2026 field mapping document, reads across all active Acumatica companies (tenants) within a single shared database, and constructs a composite unique key that serves as the external ID for upsert operations into Salesforce.

---

## Architecture

### Data Flow

```
Acumatica SQL Database
        │
        ▼
  SQL Views (this repo)
        │
        ▼
  Integration Layer (ETL / middleware)
        │
        ▼
  Salesforce (SFDC)
```

### Multi-Company Strategy

Acumatica stores all company (tenant) data in a **single shared database**, isolating records via a `CompanyID` column present on every table. Each view in this project:

- Reads from `[dbo].[Company]` to retrieve all active companies
- Joins all source tables on `CompanyID` to ensure proper tenant isolation
- Constructs a **composite external key** in the format `CompanyID|AcctCD` which maps to the `Account_Number__c` External ID field in Salesforce, guaranteeing uniqueness across all companies during upsert operations

---

## Repository Structure

```
/
├── README.md                                   # This file
└── views/
    └── vw_SFDC_Account_Acumatica_AllTenants.sql    # Account sync view
```

---

## Views

### `vw_SFDC_Account_Acumatica_AllTenants`

**Purpose:** Surfaces all Account-level fields flagged `Sync from Acumatica = Yes` in the ACCOUNT-2026 mapping tab for publishing into the Salesforce Account object.

**Source Tables:**

| Table | Purpose |
|---|---|
| `[dbo].[Company]` | Active company/tenant registry |
| `[dbo].[Customer]` | Core customer master record |
| `[dbo].[CustomerBalance]` | Customer credit balance data |
| `[dbo].[SalesPersonGroup]` | Salesperson role assignments (pivoted) |
| `[dbo].[CSAnswers]` | Custom attribute values (PROGROUP, BILLING, SOREPFIRM, AREXPDATE) |

**Key Fields Produced:**

| SFDC Field | Acumatica Source | Notes |
|---|---|---|
| `Account_Number__c` (External ID) | `Customer.AcctCD` | Part of composite upsert key |
| `Name` | `Customer.AcctName` | |
| `ACU_CUSTOMER_CLASS__c` | `Customer.CustomerClassID` | |
| `ACU_CUSTOMER_STATUS__c` | `Customer.Status` | |
| `ACU_TIER__c` | `Customer.usrTier` | |
| `ACU_CREDIT_LIMIT__c` | `Customer.CreditLimit` | |
| `ACU_CREDIT_REMAIN__c` | `Customer.RemainingCreditLimit` | |
| `Acu_Customer_Credit_Rule__c` | `Customer.CreditRule` | |
| `ACU_CREDIT_TERMS__c` | `Customer.TermsID` | |
| `Remaining_Credit__c` | `CustomerBalance.RemainingCreditLimit` | |
| `ACU_ACCOUNT_OWNER__c` | `SalesPersonGroup` (Account Owner role) | String; OwnerId lookup resolved in ETL |
| `Acu_Customer_Commission_Receiver__c` | `SalesPersonGroup` (Commission Receiver role) | |
| `Acu_Customer_Coordinator__c` | `SalesPersonGroup` (Coordinator role) | |
| `ACU_Customer_Inside_Sales_Rep__c` | `SalesPersonGroup` (Inside Sales role) | |
| `ACU_Customer_Key_Director__c` | `SalesPersonGroup` (Key Director role) | |
| `ACU_Customer_Key_Manager__c` | `SalesPersonGroup` (Key Manager role) | |
| `Acu_Customer_Sales_Operations__c` | `SalesPersonGroup` (Sales Operations role) | |
| `ACU_CUSTOMER_POSTYPE__c` | `CSAnswers` (PROGROUP attribute) | |
| `ACU_PRO_ACCOUNT_GROUP__c` | `CSAnswers` (PROGROUP attribute) | Shares source with POSTYPE |
| `ACU_PRO_ACCOUNT_TYPE__c` | `CSAnswers` (BILLING attribute) | |
| `ACU_Outside_Rep_Firms` | `CSAnswers` (SOREPFIRM attribute) | |
| `Expired_Date__c` | `CSAnswers` (AREXPDATE attribute) | |
| `BillingStreet / City / State / PostalCode / Country` | `Customer.Address` | |

---

## Deployment

These views are deployed as part of an **Acumatica Customization Project**. All table references use `[dbo].[TableName]` with no database prefix, as the scripts execute within the context of the Acumatica database.

To deploy:
1. Open your Acumatica Customization Project in the Acumatica Customization Editor
2. Add the SQL script under the **SQL Scripts** section of the project
3. Publish the customization

---

## Integration Notes

- **Upsert Key:** The `ExternalKey` column (`CompanyID|AcctCD`) should be used as the upsert key in your integration/ETL layer, mapped to `Account_Number__c` in Salesforce
- **Account Owner:** `ACU_ACCOUNT_OWNER__c` surfaces a name string; the ETL layer must resolve this to a Salesforce User ID before populating the `OwnerId` lookup field
- **PROGROUP Dual-Use:** Both `ACU_CUSTOMER_POSTYPE__c` and `ACU_PRO_ACCOUNT_GROUP__c` source from the same `PROGROUP` attribute. If picklist values differ between the two SFDC fields, apply a CASE transform in the ETL layer
- **Remaining Credit:** Two fields source credit data from different tables (`Customer` vs `CustomerBalance`); confirm with stakeholders which is authoritative for each SFDC field

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
