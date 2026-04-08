-- ============================================================
-- VIEW: vw_SFDC_Account_Acumatica_AllTenants
-- PURPOSE: Selects all Account fields flagged "Sync from Acumatica = Yes"
--          from the ACCOUNT-2026 mapping tab.
--          Reads across ALL Acumatica tenants and builds a composite
--          unique key (TenantID + AcctCD) for publishing into Salesforce.
--
-- SOURCE TABLES (Acumatica single-database, multi-company schema):
--   Customer           - Core customer master (one row per customer per company)
--   CustomerBalance    - Credit balance data (one row per customer per company)
--   CSAnswers          - Attribute values (PROGROUP, BILLING, SOREPFIRM, AREXPDATE)
--   SalesPersonGroup   - Salesperson role assignments (one row per role per customer)
--
-- COMPOSITE KEY STRATEGY:
--   ExternalKey = CompanyID + '|' + AcctCD
--   This key maps to Account_Number__c (External ID) in Salesforce,
--   ensuring cross-company uniqueness when upserting via the SFDC integration.
--
-- NOTES:
--   - Single database deployment: all table references use [dbo].[TableName] only.
--   - Acumatica isolates tenants via CompanyID on every table; the [dbo].[Company]
--     table is the tenant catalog. All CTEs carry CompanyID throughout.
--   - SalespersonGroup role assignments use MAX() + CASE to pivot multiple
--     salesperson role rows into a single customer row.
--   - CustomerBalance may have multiple rows per customer; only the most recent
--     open balance record is used (see subquery cb).
--   - Attribute fields (PROGROUP, BILLING, SOREPFIRM, AREXPDATE) are pulled
--     from CSAnswers; adjust AttributeID values to match your Acumatica setup.
-- ============================================================
 
CREATE OR ALTER VIEW [dbo].[vw_SFDC_Account_Acumatica_AllTenants]
AS
 
WITH
 
-- ----------------------------------------------------------------
-- 1. Pull all active companies from the Acumatica company catalog.
--    [dbo].[Company] is the built-in Acumatica tenant registry.
--  DAZ - Verified
-- ----------------------------------------------------------------
Tenants AS (
    SELECT
        CompanyID,
        CompanyCD      -- Human-readable company code (optional, useful for debugging)
    FROM [dbo].[Company]
    WHERE CompanyID in (6,8,10)
),
 
-- ----------------------------------------------------------------
-- 2. Core Customer master - one row per customer per company.
-- ----------------------------------------------------------------
CustomerBase AS (
    SELECT
        c.CompanyID,
        c.AcctCD,                         -- IFS / ACU Account Number  → Account_Number__c
        c.AcctName,                       -- Account Name              → Name
        c.CustomerClassID,                -- ACU Customer Class        → ACU_CUSTOMER_CLASS__c
        c.CreditLimit,                    -- ACU Customer Credit Limit → ACU_CREDIT_LIMIT__c
        c.RemainingCreditLimit,           -- ACU Credit Available      → ACU_CREDIT_REMAIN__c
        c.CreditRule,                     -- ACU Customer Credit Rule  → Acu_Customer_Credit_Rule__c
        c.TermsID,                        -- ACU Customer Credit Terms → ACU_CREDIT_TERMS__c
        c.Status,                         -- ACU Customer Status       → ACU_CUSTOMER_STATUS__c
        c.usrTier,                        -- ACU Customer Tier         → ACU_TIER__c
        -- Billing Address (composite)     → BillingAddress in SFDC
        c.BillingAddressLine1,
        c.BillingAddressLine2,
        c.BillingCity,
        c.BillingState,
        c.BillingPostalCode,
        c.BillingCountry
    FROM [dbo].[Customer] c
    WHERE c.DeletedDatabaseRecord = 0     -- exclude soft-deleted records
),
 
-- ----------------------------------------------------------------
-- 3. CustomerBalance - latest open balance per customer per company.
--    Used for: Remaining Credit → Remaining_Credit__c
-- ----------------------------------------------------------------
CustomerBalanceCTE AS (
    SELECT
        cb.CompanyID,
        cb.CustomerID,                    -- FK to Customer.AcctCD
        cb.RemainingCreditLimit AS BalanceRemainingCreditLimit
    FROM [dbo].[CustomerBalance] cb
    WHERE cb.DeletedDatabaseRecord = 0
),
 
-- ----------------------------------------------------------------
-- 4. Pivot SalespersonGroup roles into individual columns.
--    Each customer may have multiple rows in SalesPersonGroup,
--    one per SalespersonRole value. We pivot them here.
--    Roles pulled from mapping:
--      'Account Owner'     → ACU_ACCOUNT_OWNER__c  (also OwnerId lookup)
--      'Commission Receiver' → Acu_Customer_Commission_Receiver__c
--      'Coordinator'       → Acu_Customer_Coordinator__c
--      'Inside Sales'      → ACU_Customer_Inside_Sales_Rep__c
--      'Key Director'      → ACU_Customer_Key_Director__c
--      'Key Manager'       → ACU_Customer_Key_Manager__c
--      'Sales Operations'  → Acu_Customer_Sales_Operations__c
-- ----------------------------------------------------------------
SalespersonRoles AS (
    SELECT
        sg.CompanyID,
        sg.CustomerID,
        MAX(CASE WHEN sg.SalespersonRole = 'Account Owner'        THEN sg.SalespersonName END) AS AccountOwner,
        MAX(CASE WHEN sg.SalespersonRole = 'Commission Receiver'  THEN sg.SalespersonName END) AS CommissionReceiver,
        MAX(CASE WHEN sg.SalespersonRole = 'Coordinator'          THEN sg.SalespersonName END) AS Coordinator,
        MAX(CASE WHEN sg.SalespersonRole = 'Inside Sales'         THEN sg.SalespersonName END) AS InsideSales,
        MAX(CASE WHEN sg.SalespersonRole = 'Key Director'         THEN sg.SalespersonName END) AS KeyDirector,
        MAX(CASE WHEN sg.SalespersonRole = 'Key Manager'          THEN sg.SalespersonName END) AS KeyManager,
        MAX(CASE WHEN sg.SalespersonRole = 'Sales Operations'     THEN sg.SalespersonName END) AS SalesOperations
    FROM [dbo].[SalesPersonGroup] sg
    WHERE sg.DeletedDatabaseRecord = 0
    GROUP BY
        sg.CompanyID,
        sg.CustomerID
),
 
-- ----------------------------------------------------------------
-- 5. Attribute fields from CSAnswers (Acumatica custom attributes).
--    AttributeID values must match what is configured in your
--    Acumatica instance. Update these string literals as needed.
--    Fields:
--      PROGROUP    → ACU_CUSTOMER_POSTYPE__c / ACU_PRO_ACCOUNT_GROUP__c
--      BILLING     → ACU_PRO_ACCOUNT_TYPE__c
--      SOREPFIRM   → ACU_Outside_Rep_Firms
--      AREXPDATE   → Expired_Date__c
-- ----------------------------------------------------------------
CustomerAttributes AS (
    SELECT
        ca.CompanyID,
        ca.EntityCD,                      -- FK to Customer.AcctCD
        MAX(CASE WHEN ca.AttributeID = 'PROGROUP'   THEN ca.Value END) AS AttributePROGROUP,
        MAX(CASE WHEN ca.AttributeID = 'BILLING'    THEN ca.Value END) AS AttributeBILLING,
        MAX(CASE WHEN ca.AttributeID = 'SOREPFIRM'  THEN ca.Value END) AS AttributeSOREPFIRM,
        MAX(CASE WHEN ca.AttributeID = 'AREXPDATE'  THEN TRY_CAST(ca.Value AS DATE) END) AS AttributeARExPDATE
    FROM [dbo].[CSAnswers] ca
    WHERE ca.DeletedDatabaseRecord = 0
      AND ca.AttributeID IN ('PROGROUP', 'BILLING', 'SOREPFIRM', 'AREXPDATE')
    GROUP BY
        ca.CompanyID,
        ca.EntityCD
)
 
-- ================================================================
-- FINAL SELECT - one row per customer per tenant
-- ================================================================
SELECT
 
    -- ----------------------------------------------------------
    -- COMPOSITE EXTERNAL KEY (CompanyID|AcctCD)
    --   Maps to Account_Number__c (External ID, Unique) in SFDC.
    --   Use this as the upsert key in your integration layer.
    -- ----------------------------------------------------------
    CONCAT(t.CompanyID, '|', c.AcctCD)          AS ExternalKey,           -- Composite upsert key for SFDC
    t.CompanyID                                  AS CompanyID,             -- Acumatica company identifier
    t.CompanyCD                                  AS CompanyCode,           -- Human-readable company code
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: Account_Number__c  (External ID)
    --   Source: Customer.AcctCD
    -- ----------------------------------------------------------
    c.AcctCD                                    AS Account_Number__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: Name
    --   Source: Customer.AcctName
    -- ----------------------------------------------------------
    c.AcctName                                  AS Name,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_CLASS__c
    --   Source: Customer.CustomerClassID
    --   Picklist: APAC, BUSDV, CASH, DEFAULT, DIST, HOUSE,
    --             ICMX, ICUK, INTRL, MAHALO, PRO, RET, SAMPLE
    -- ----------------------------------------------------------
    c.CustomerClassID                           AS ACU_CUSTOMER_CLASS__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_STATUS__c
    --   Source: Customer.Status
    --   Picklist: Active, On Hold, Credit Hold, One-Time, Inactive
    -- ----------------------------------------------------------
    c.Status                                    AS ACU_CUSTOMER_STATUS__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_TIER__c
    --   Source: Customer.usrTier
    --   Picklist: Diamond, Elite, Standard
    -- ----------------------------------------------------------
    c.usrTier                                   AS ACU_TIER__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_LIMIT__c
    --   Source: Customer.CreditLimit
    --   Type: Number(16,2)
    -- ----------------------------------------------------------
    CAST(c.CreditLimit AS DECIMAL(16,2))        AS ACU_CREDIT_LIMIT__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_REMAIN__c  (Credit Available)
    --   Source: Customer.RemainingCreditLimit
    --   Type: Number(16,2)
    -- ----------------------------------------------------------
    CAST(c.RemainingCreditLimit AS DECIMAL(16,2)) AS ACU_CREDIT_REMAIN__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: Acu_Customer_Credit_Rule__c
    --   Source: Customer.CreditRule
    --   Picklist: Days Past Due, Credit Limit,
    --             Limit and Days Past Due, Disabled
    -- ----------------------------------------------------------
    c.CreditRule                                AS Acu_Customer_Credit_Rule__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_TERMS__c
    --   Source: Customer.TermsID
    -- ----------------------------------------------------------
    c.TermsID                                   AS ACU_CREDIT_TERMS__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: Remaining_Credit__c
    --   Source: CustomerBalance.RemainingCreditLimit
    --   Type: Number(16,2)
    --   NOTE: Pulled from CustomerBalance (separate from
    --         Customer.RemainingCreditLimit above). Map to
    --         whichever is authoritative per your integration.
    -- ----------------------------------------------------------
    CAST(cb.BalanceRemainingCreditLimit AS DECIMAL(16,2)) AS Remaining_Credit__c,
 
    -- ----------------------------------------------------------
    -- SFDC SALESPERSON GROUP FIELDS
    --   Source: SalesPersonGroup (pivoted by role)
    -- ----------------------------------------------------------
    sg.AccountOwner                             AS ACU_ACCOUNT_OWNER__c,
    sg.CommissionReceiver                       AS Acu_Customer_Commission_Receiver__c,
    sg.Coordinator                              AS Acu_Customer_Coordinator__c,
    sg.InsideSales                              AS ACU_Customer_Inside_Sales_Rep__c,
    sg.KeyDirector                              AS ACU_Customer_Key_Director__c,
    sg.KeyManager                               AS ACU_Customer_Key_Manager__c,
    sg.SalesOperations                          AS Acu_Customer_Sales_Operations__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_POSTYPE__c  (DIST Account Type)
    --   Source: Customer.AttributePROGROUP
    --   NOTE: PROGROUP drives both POSTYPE and PRO_ACCOUNT_GROUP
    --         in SFDC; apply picklist mapping in your ETL layer
    --         if the values differ between the two SF fields.
    -- ----------------------------------------------------------
    ca.AttributePROGROUP                        AS ACU_CUSTOMER_POSTYPE__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_PRO_ACCOUNT_GROUP__c
    --   Source: Customer.AttributePROGROUP
    --   Picklist: Dealer / Integrator, Distributor, End User,
    --             Original Equipment Manufacturer, Reseller
    -- ----------------------------------------------------------
    ca.AttributePROGROUP                        AS ACU_PRO_ACCOUNT_GROUP__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_PRO_ACCOUNT_TYPE__c
    --   Source: Customer.AttributeBILLING
    --   Picklist: Bill To, Ship To, POS Bill To, POS Ship To
    -- ----------------------------------------------------------
    ca.AttributeBILLING                         AS ACU_PRO_ACCOUNT_TYPE__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_Outside_Rep_Firms
    --   Source: Customer.AttributeSOREPFIRM
    --   Type: Long Text Area
    -- ----------------------------------------------------------
    ca.AttributeSOREPFIRM                       AS ACU_Outside_Rep_Firms,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: Expired_Date__c
    --   Source: Customer.Attribute - AREXPDATE
    --   Type: Date
    -- ----------------------------------------------------------
    ca.AttributeARExPDATE                       AS Expired_Date__c,
 
    -- ----------------------------------------------------------
    -- SFDC FIELD: BillingAddress (composite address object)
    --   Source: Customer.Address (multiple columns)
    --   These are passed to the SFDC BillingAddress compound field.
    -- ----------------------------------------------------------
    c.BillingAddressLine1                       AS BillingStreet,
    c.BillingCity                               AS BillingCity,
    c.BillingState                              AS BillingState,
    c.BillingPostalCode                         AS BillingPostalCode,
    c.BillingCountry                            AS BillingCountry
 
FROM CustomerBase c
 
-- Join to Company catalog to get CompanyCD and iterate all companies
INNER JOIN Tenants t
    ON c.CompanyID = t.CompanyID
 
-- LEFT JOIN CustomerBalance (not all customers have a balance record)
LEFT JOIN CustomerBalanceCTE cb
    ON  cb.CompanyID   = c.CompanyID
    AND cb.CustomerID  = c.AcctCD
 
-- LEFT JOIN pivoted SalespersonGroup roles
LEFT JOIN SalespersonRoles sg
    ON  sg.CompanyID   = c.CompanyID
    AND sg.CustomerID  = c.AcctCD
 
-- LEFT JOIN custom attribute values
LEFT JOIN CustomerAttributes ca
    ON  ca.CompanyID  = c.CompanyID
    AND ca.EntityCD   = c.AcctCD
 
;
GO
 
 
-- ============================================================
-- USAGE NOTES
-- ============================================================
-- 1. UPSERT KEY in Salesforce:
--      Use ExternalKey (CompanyID|AcctCD) mapped to Account_Number__c
--      (configured as External ID + Unique in SFDC).
--      This guarantees that accounts from different companies
--      never collide during upsert operations.
--
-- 2. PROGROUP DUAL-USE:
--      Both ACU_CUSTOMER_POSTYPE__c and ACU_PRO_ACCOUNT_GROUP__c
--      source from AttributePROGROUP. If your SFDC fields carry
--      different picklist values, apply a CASE transformation
--      in your integration/ETL layer rather than here in the view.
--
-- 3. ACCOUNT OWNER (OwnerId Lookup):
--      The OwnerId field in SFDC is a Lookup(User). The view
--      surfaces the salesperson name string (ACU_ACCOUNT_OWNER__c).
--      Your integration layer must resolve this to a SFDC User ID
--      via a separate User lookup before populating OwnerId.
--
-- 4. REMAINING CREDIT (dual source):
--      Customer.RemainingCreditLimit  → ACU_CREDIT_REMAIN__c
--      CustomerBalance.RemainingCreditLimit → Remaining_Credit__c
--      Confirm with business stakeholders which source is
--      authoritative for each SFDC field.
--
-- 5. COMPANY ISOLATION:
--      All CTEs carry CompanyID throughout so results are always
--      company-scoped even though the view returns all companies.
--      Add a WHERE clause when querying for a single company:
--        SELECT * FROM vw_SFDC_Account_Acumatica_AllTenants
--        WHERE CompanyID = 2;
-- ============================================================