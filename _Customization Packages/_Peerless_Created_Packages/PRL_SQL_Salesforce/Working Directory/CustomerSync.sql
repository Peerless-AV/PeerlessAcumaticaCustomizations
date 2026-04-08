select * from BAccount where BACCOUNTID = 17301;

select * from Customer WHERE BACCOUNTID = 17301;

--dz MAPPING QUERY



    SELECT
        c.CompanyID,
        ba.AcctCD,                         -- IFS / ACU Account Number  → Account_Number__c
        ba.AcctName,                       -- Account Name              → Name
        c.CustomerClassID,                -- ACU Customer Class        → ACU_CUSTOMER_CLASS__c
        c.CreditLimit,                    -- ACU Customer Credit Limit → ACU_CREDIT_LIMIT__c
        null as "RemainingCreditLimit", --c.RemainingCreditLimit,           -- ACU Credit Available      → ACU_CREDIT_REMAIN__c
        c.CreditRule,                     -- ACU Customer Credit Rule  → Acu_Customer_Credit_Rule__c
        c.TermsID,                        -- ACU Customer Credit Terms → ACU_CREDIT_TERMS__c
        ba.Status,                         -- ACU Customer Status       → ACU_CUSTOMER_STATUS__c
        c.usrTier,                        -- ACU Customer Tier         → ACU_TIER__c
        -- Billing Address (composite)     → BillingAddress in SFDC
        Adr.AddressLine1,
        Adr.AddressLine2,
        Adr.City,
        Adr.State,
        Adr.PostalCode,
        Adr.CountryID
    FROM [dbo].[Customer] c, [dbo].[BAccount] ba, [dbo].[Address] Adr
    WHERE c.DeletedDatabaseRecord = 0     -- exclude soft-deleted records
    AND c.BAccountID = ba.BAccountID
    AND c.CompanyID = ba.CompanyID
    AND c.CompanyID = Adr.CompanyID
    AND c.DefBillAddressID = Adr.AddressID
