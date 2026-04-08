-- ============================================================
-- VIEW: vw_SFDC_Account_Acumatica_AllTenants
-- PURPOSE: Selects all Account fields flagged "Sync from Acumatica = Yes"
--          from the ACCOUNT-2026 mapping tab.
--          Reads across ALL Acumatica tenants and builds a composite
--          unique key (TenantID + AcctCD) for publishing into Salesforce.
--
-- SOURCE TABLES (Acumatica single-database, multi-company schema):
--   Customer           - Core customer master (one row per customer per company)
--   ARBalances         - Credit balance data (one row per customer per company)
--   CSAnswers          - Attribute values (PROGROUP, BILLING, SOREPFIRM, AREXPDATE)
--   CustSalesPeople    - Salesperson role assignments (multi-row per customer)
--   SalesPerson        - Salesperson reference table (SalespersonID → Descr)
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
--   - SalespersonRoles pivots CustSalesPeople into one row per BAccountID,
--     resolving SalesPersonID to display name via SalesPerson.Descr.
--   - ARBalances BalanceRemainingCreditLimit is currently stubbed as NULL
--     pending balance source confirmation.
--   - Attribute fields (PROGROUP, BILLING, SOREPFIRM, AREXPDATE) are pulled
--     from CSAnswers; adjust AttributeID values to match your Acumatica setup.
--   - BillingAddress columns sourced from Adr.AddressLine1/2, City, State,
--     PostalCode, CountryID as exposed by the CustomerBase CTE.
-- ============================================================

CREATE OR ALTER VIEW [dbo].[vw_SFDC_Account_Acumatica_AllTenants]
AS

WITH

-- ----------------------------------------------------------------
-- 1. Pull all active companies from the Acumatica company catalog.
--    [dbo].[Company] is the built-in Acumatica tenant registry.
--    DAZ - Verified
-- ----------------------------------------------------------------
Tenants AS (
    SELECT
        CompanyID,
        CompanyCD      -- Human-readable company code (optional, useful for debugging)
    FROM [dbo].[Company]
    WHERE CompanyID IN (6, 8, 10)
),

-- ----------------------------------------------------------------
-- 2. Core Customer master - one row per customer per company.
--    NOTE: RemainingCreditLimit is stubbed NULL per DAZ update;
--          address columns use raw Acumatica field names from
--          [dbo].[Address] (AddressLine1/2, City, State,
--          PostalCode, CountryID).
--    BAccountID is carried through to support the SalespersonRoles join.
-- ----------------------------------------------------------------
CustomerBase AS (
    SELECT
        c.CompanyID,
        ba.BAccountID,                      -- FK → CustSalesPeople.BAccountID
        ba.AcctCD,                          -- IFS / ACU Account Number  → Account_Number__c
        ba.AcctName,                        -- Account Name              → Name
        ba.NoteID,                          -- FK → CSAnswers.RefNoteID
        c.CustomerClassID,                  -- ACU Customer Class        → ACU_CUSTOMER_CLASS__c
        c.CreditLimit,                      -- ACU Customer Credit Limit → ACU_CREDIT_LIMIT__c
        NULL AS RemainingCreditLimit,       -- ACU Credit Available      → ACU_CREDIT_REMAIN__c (stubbed)
        c.CreditRule,                       -- ACU Customer Credit Rule  → Acu_Customer_Credit_Rule__c
        c.TermsID,                          -- ACU Customer Credit Terms → ACU_CREDIT_TERMS__c
        ba.Status,                          -- ACU Customer Status       → ACU_CUSTOMER_STATUS__c
        c.usrTier,                          -- ACU Customer Tier         → ACU_TIER__c
        -- Billing Address (raw column names from [dbo].[Address])
        Adr.AddressLine1,
        Adr.AddressLine2,
        Adr.City,
        Adr.State,
        Adr.PostalCode,
        Adr.CountryID
    FROM  [dbo].[Customer]  c
    JOIN  [dbo].[BAccount]  ba  ON  ba.BAccountID = c.BAccountID
                                AND ba.CompanyID   = c.CompanyID
    JOIN  [dbo].[Address]   Adr ON  Adr.AddressID  = c.DefBillAddressID
                                AND Adr.CompanyID   = c.CompanyID
    WHERE c.DeletedDatabaseRecord = 0       -- exclude soft-deleted records
),

-- ----------------------------------------------------------------
-- 3. CustomerBalance - latest open balance per customer per company.
--    BalanceRemainingCreditLimit is currently NULL (stubbed).
--    Replace with the authoritative ARBalances column when confirmed.
-- ----------------------------------------------------------------
CustomerBalanceCTE AS (
    SELECT
        cb.CompanyID,
        cb.CustomerID,                      -- FK join key → Customer.AcctCD
        NULL AS BalanceRemainingCreditLimit  -- Remaining Credit → Remaining_Credit__c (stubbed)
    FROM [dbo].[ARBalances] cb
),

-- ----------------------------------------------------------------
-- 4. Salesperson role pivot - one row per BAccountID per company.
--    Joins CustSalesPeople → SalesPerson to resolve SalesPersonID
--    to display name (Descr), then pivots usrSalesPersonGroup codes
--    into individual role columns.
--
--    Role code mapping:
--      AO = Account Owner
--      CO = Coordinator
--      KD = Key Director
--      KM = Key Manager
--      SO = Sales Operations
--      IS = Inside Sales
--      CR = Commission Receiver  ← confirm code against live data
-- ----------------------------------------------------------------
SalespersonRoles AS (
    SELECT
        csp.CompanyID,
        csp.BAccountID,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'AO' THEN sp.Descr END) AS AccountOwner,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'CO' THEN sp.Descr END) AS Coordinator,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'KD' THEN sp.Descr END) AS KeyDirector,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'KM' THEN sp.Descr END) AS KeyManager,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'SO' THEN sp.Descr END) AS SalesOperations,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'IS' THEN sp.Descr END) AS InsideSales,
        MAX(CASE WHEN csp.usrSalesPersonGroup = 'CR' THEN sp.Descr END) AS CommissionReceiver
    FROM [dbo].[CustSalesPeople] csp
    JOIN [dbo].[SalesPerson] sp
        ON  sp.SalespersonID = csp.SalesPersonID
        AND sp.CompanyID     = csp.CompanyID
    WHERE csp.CompanyID IN (6, 8, 10)
    GROUP BY
        csp.CompanyID,
        csp.BAccountID
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
        ca.RefNoteID,                       -- FK to BAccount.NoteID
        MAX(CASE WHEN ca.AttributeID = 'PROGROUP'  THEN ca.Value END)                    AS AttributePROGROUP,
        MAX(CASE WHEN ca.AttributeID = 'BILLING'   THEN ca.Value END)                    AS AttributeBILLING,
        MAX(CASE WHEN ca.AttributeID = 'SOREPFIRM' THEN ca.Value END)                    AS AttributeSOREPFIRM,
        MAX(CASE WHEN ca.AttributeID = 'AREXPDATE' THEN TRY_CAST(ca.Value AS DATE) END)  AS AttributeARExPDATE
    FROM [dbo].[CSAnswers] ca
    WHERE ca.AttributeID IN ('PROGROUP', 'BILLING', 'SOREPFIRM', 'AREXPDATE')
    GROUP BY
        ca.CompanyID,
        ca.RefNoteID
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
    CONCAT(t.CompanyID, '|', c.AcctCD)              AS ExternalKey,

    t.CompanyID                                      AS CompanyID,
    t.CompanyCD                                      AS CompanyCode,

    -- ----------------------------------------------------------
    -- SFDC FIELD: Account_Number__c  (External ID)
    --   Source: BAccount.AcctCD
    -- ----------------------------------------------------------
    c.AcctCD                                         AS Account_Number__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: Name
    --   Source: BAccount.AcctName
    -- ----------------------------------------------------------
    c.AcctName                                       AS Name,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_CLASS__c
    --   Source: Customer.CustomerClassID
    --   Picklist: APAC, BUSDV, CASH, DEFAULT, DIST, HOUSE,
    --             ICMX, ICUK, INTRL, MAHALO, PRO, RET, SAMPLE
    -- ----------------------------------------------------------
    c.CustomerClassID                                AS ACU_CUSTOMER_CLASS__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_STATUS__c
    --   Source: BAccount.Status
    --   Picklist: Active, On Hold, Credit Hold, One-Time, Inactive
    -- ----------------------------------------------------------
    c.Status                                         AS ACU_CUSTOMER_STATUS__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_TIER__c
    --   Source: Customer.usrTier
    --   Picklist: Diamond, Elite, Standard
    -- ----------------------------------------------------------
    c.usrTier                                        AS ACU_TIER__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_LIMIT__c
    --   Source: Customer.CreditLimit
    --   Type: Number(16,2)
    -- ----------------------------------------------------------
    CAST(c.CreditLimit AS DECIMAL(16, 2))            AS ACU_CREDIT_LIMIT__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_REMAIN__c  (Credit Available)
    --   Source: Customer.RemainingCreditLimit (currently NULL/stubbed)
    --   Type: Number(16,2)
    -- ----------------------------------------------------------
    CAST(c.RemainingCreditLimit AS DECIMAL(16, 2))   AS ACU_CREDIT_REMAIN__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: Acu_Customer_Credit_Rule__c
    --   Source: Customer.CreditRule
    --   Picklist: Days Past Due, Credit Limit,
    --             Limit and Days Past Due, Disabled
    -- ----------------------------------------------------------
    c.CreditRule                                     AS Acu_Customer_Credit_Rule__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CREDIT_TERMS__c
    --   Source: Customer.TermsID
    -- ----------------------------------------------------------
    c.TermsID                                        AS ACU_CREDIT_TERMS__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: Remaining_Credit__c
    --   Source: ARBalances.BalanceRemainingCreditLimit (currently NULL/stubbed)
    --   Type: Number(16,2)
    -- ----------------------------------------------------------
    CAST(cb.BalanceRemainingCreditLimit AS DECIMAL(16, 2)) AS Remaining_Credit__c,

    -- ----------------------------------------------------------
    -- SFDC SALESPERSON ROLE FIELDS
    --   Source: SalespersonRoles (pivoted from CustSalesPeople
    --           joined to SalesPerson for display name).
    --   NOTE: Commission Receiver code 'CR' needs confirmation
    --         against live CustSalesPeople data.
    -- ----------------------------------------------------------
    sg.AccountOwner                                  AS ACU_ACCOUNT_OWNER__c,
    sg.Coordinator                                   AS Acu_Customer_Coordinator__c,
    sg.KeyDirector                                   AS ACU_Customer_Key_Director__c,
    sg.KeyManager                                    AS ACU_Customer_Key_Manager__c,
    sg.SalesOperations                               AS Acu_Customer_Sales_Operations__c,
    sg.InsideSales                                   AS ACU_Customer_Inside_Sales_Rep__c,
    sg.CommissionReceiver                            AS Acu_Customer_Commission_Receiver__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_CUSTOMER_POSTYPE__c  (DIST Account Type)
    --   Source: CSAnswers.AttributePROGROUP
    -- ----------------------------------------------------------
    ca.AttributePROGROUP                             AS ACU_CUSTOMER_POSTYPE__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_PRO_ACCOUNT_GROUP__c
    --   Source: CSAnswers.AttributePROGROUP
    --   Picklist: Dealer / Integrator, Distributor, End User,
    --             Original Equipment Manufacturer, Reseller
    -- ----------------------------------------------------------
    ca.AttributePROGROUP                             AS ACU_PRO_ACCOUNT_GROUP__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_PRO_ACCOUNT_TYPE__c
    --   Source: CSAnswers.AttributeBILLING
    --   Picklist: Bill To, Ship To, POS Bill To, POS Ship To
    -- ----------------------------------------------------------
    ca.AttributeBILLING                              AS ACU_PRO_ACCOUNT_TYPE__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: ACU_Outside_Rep_Firms
    --   Source: CSAnswers.AttributeSOREPFIRM
    --   Type: Long Text Area
    -- ----------------------------------------------------------
    ca.AttributeSOREPFIRM                            AS ACU_Outside_Rep_Firms,

    -- ----------------------------------------------------------
    -- SFDC FIELD: Expired_Date__c
    --   Source: CSAnswers.AttributeARExPDATE
    --   Type: Date
    -- ----------------------------------------------------------
    ca.AttributeARExPDATE                            AS Expired_Date__c,

    -- ----------------------------------------------------------
    -- SFDC FIELD: BillingAddress (compound address object)
    --   Source: Address table columns as aliased in CustomerBase.
    -- ----------------------------------------------------------
    c.AddressLine1                                   AS BillingStreet,
    c.AddressLine2                                   AS BillingStreet2,
    c.City                                           AS BillingCity,
    c.State                                          AS BillingState,
    c.PostalCode                                     AS BillingPostalCode,
    c.CountryID                                      AS BillingCountry

FROM CustomerBase c

-- Join to Company catalog to get CompanyCD and iterate all tenants
INNER JOIN Tenants t
    ON  t.CompanyID = c.CompanyID

-- LEFT JOIN CustomerBalance (not all customers have a balance record)
LEFT JOIN CustomerBalanceCTE cb
    ON  cb.CompanyID  = c.CompanyID
    AND cb.CustomerID = c.BAccountID

-- LEFT JOIN pivoted salesperson roles via BAccountID
LEFT JOIN SalespersonRoles sg
    ON  sg.CompanyID   = c.CompanyID
    AND sg.BAccountID  = c.BAccountID

-- LEFT JOIN custom attribute values via BAccount.NoteID
LEFT JOIN CustomerAttributes ca
    ON  ca.CompanyID = c.CompanyID
    AND ca.RefNoteID = c.NoteID

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
--      The OwnerId field in SFDC is a Lookup(User). Your integration
--      layer must resolve ACU_ACCOUNT_OWNER__c (salesperson display
--      name) to a SFDC User ID via a separate User lookup before
--      populating OwnerId.
--
-- 4. REMAINING CREDIT (dual source - both currently NULL/stubbed):
--      Customer.RemainingCreditLimit        → ACU_CREDIT_REMAIN__c
--      ARBalances.BalanceRemainingCreditLimit → Remaining_Credit__c
--      Confirm with business stakeholders which source is
--      authoritative and replace the NULL stubs accordingly.
--
-- 5. COMPANY ISOLATION:
--      All CTEs carry CompanyID throughout so results are always
--      company-scoped. Add a WHERE clause when querying one company:
--        SELECT * FROM vw_SFDC_Account_Acumatica_AllTenants
--        WHERE CompanyID = 6;
--
-- 6. COMMISSION RECEIVER ROLE CODE:
--      The 'CR' code used in the SalespersonRoles pivot for
--      CommissionReceiver is a placeholder. Verify the actual
--      usrSalesPersonGroup value in [dbo].[CustSalesPeople] and
--      update the CASE expression accordingly.
--
-- 7. CUSTOMERATTRIBUTES JOIN:
--      CSAnswers.RefNoteID links to BAccount.NoteID. BAccount.NoteID
--      is now carried directly through CustomerBase, so the join
--      is a clean direct equality — no correlated subquery needed.
-- ============================================================