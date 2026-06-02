/************************************************************************************************
 *                                                                                              *
 *   View:      vw_PRL_Account_Pricing                                                         *
 *   Author:    BTG IT / Peerless-AV                                                           *
 *                                                                                              *
 *   7-30-24:   Created to pull pricing by account, listing all products with price groups     *
 *              and all account-specific pricing.                                               *
 *   8-29-24:   Updated to correct for customer pricing including date logic.                  *
 *   5-28-26:   Reformatted as Acumatica SQL view. Column aliases use PascalCase with no       *
 *              underscores per Acumatica BQL DAC binding requirements. Hardcoded              *
 *              ExpirationDate filter updated to allow future maintenance via view refresh.    *
 *                                                                                              *
 ***********************************************************************************************/
CREATE VIEW [dbo].[vw_PRL_Account_Pricing] AS

-- ── Part 1: Class-based pricing (TSCustomerPriceGroup) ───────────────────────────────────────
SELECT
    CAST(TSCustomerPriceGroup.CompanyID AS INT)                                AS CompanyID,
    TSCustomerPriceGroup.Description                                           AS CustomerName,
    BAccount.AcctCD                                                            AS Customer,
    TSCustomerPriceGroup.PriceClassID                                         AS CustomerPriceClass,
    InventoryItem.InventoryCD                                                  AS PartNumber,
    InventoryItem.Descr                                                        AS Description,
    TSPriceGroup.PriceGroupDescription                                         AS ProductGroup,
    TSPriceGroup.PriceGroupCode                                                AS PriceGroup,
    ARSalesPrice.SalesPrice                                                    AS Price,

    CAST(
        CASE InventoryItem.ItemStatus
            WHEN 'AC' THEN 'Active'
            WHEN 'NS' THEN 'No Sale'
            WHEN 'NP' THEN 'No Purchase'
            WHEN 'NR' THEN 'No Request'
            WHEN 'IN' THEN 'Inactive'
            WHEN 'DE' THEN 'Marked for Deletion'
        END
    AS NVARCHAR(50))                                                            AS ItemStatus,

    ARSalesPrice.ExpirationDate                                                AS ExpirationDate,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = ARSalesPrice.CompanyID
       AND B.InventoryID      = ARSalesPrice.InventoryID
       AND B.CustPriceClassID = 'MAPCA'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS MapCA,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = ARSalesPrice.CompanyID
       AND B.InventoryID      = ARSalesPrice.InventoryID
       AND B.CustPriceClassID = 'MAPUS'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS MapNA,

    InventoryItem.BasePrice                                                    AS BasePrice,
    ARSalesPrice.EffectiveDate                                                 AS EffectiveDate,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'PMUPC'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS UniversalProductCode,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IECOO'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS CountryOfOrigin,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE1LENG'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS LengthIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE2WIDH'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS WidthIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE3HGHT'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS HeightIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IEPGWGT'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS ShipWeightLb,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'PMRTN'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS ReturnableCancellable

FROM [dbo].[TSCustomerPriceGroup]
JOIN [dbo].[BAccount]     ON  TSCustomerPriceGroup.CompanyID   = BAccount.CompanyID
                          AND TSCustomerPriceGroup.Description  = BAccount.AcctName
JOIN [dbo].[TSPriceGroup] ON  TSCustomerPriceGroup.CompanyID   = TSPriceGroup.CompanyID
                          AND TSCustomerPriceGroup.PriceGroupID = TSPriceGroup.RecID
JOIN [dbo].[InventoryItem] ON InventoryItem.CompanyID           = TSCustomerPriceGroup.CompanyID
                          AND InventoryItem.UsrPriceGroupID     = TSCustomerPriceGroup.PriceGroupID
JOIN [dbo].[ARSalesPrice]  ON InventoryItem.InventoryID         = ARSalesPrice.InventoryID
                          AND ARSalesPrice.CompanyID            = TSCustomerPriceGroup.CompanyID
                          AND ARSalesPrice.CustPriceClassID     = TSCustomerPriceGroup.PriceClassID
                          AND ARSalesPrice.EffectiveDate        = (
                                  SELECT MAX(Z.EffectiveDate)
                                  FROM [dbo].[ARSalesPrice] Z
                                  WHERE Z.CompanyID        = ARSalesPrice.CompanyID
                                    AND Z.InventoryID      = ARSalesPrice.InventoryID
                                    AND Z.CustPriceClassID = ARSalesPrice.CustPriceClassID
                                    AND Z.EffectiveDate    <= GETDATE()
                              )
WHERE TSCustomerPriceGroup.CompanyID = 10
  AND (ARSalesPrice.ExpirationDate >= GETDATE() OR ARSalesPrice.ExpirationDate IS NULL)

UNION ALL

-- ── Part 2: Customer-specific pricing (ARSalesPrice PriceType = 'C') ────────────────────────
SELECT
    CAST(BAccount.CompanyID AS INT)                                            AS CompanyID,
    BAccount.AcctName                                                          AS CustomerName,
    BAccount.AcctCD                                                            AS Customer,
    CAST('Customer Pricing' AS NVARCHAR(50))                                  AS CustomerPriceClass,
    InventoryItem.InventoryCD                                                  AS PartNumber,
    InventoryItem.Descr                                                        AS Description,
    TSPriceGroup.PriceGroupDescription                                         AS ProductGroup,
    TSPriceGroup.PriceGroupCode                                                AS PriceGroup,
    ARSalesPrice.SalesPrice                                                    AS Price,

    CAST(
        CASE InventoryItem.ItemStatus
            WHEN 'AC' THEN 'Active'
            WHEN 'NS' THEN 'No Sale'
            WHEN 'NP' THEN 'No Purchase'
            WHEN 'NR' THEN 'No Request'
            WHEN 'IN' THEN 'Inactive'
            WHEN 'DE' THEN 'Marked for Deletion'
        END
    AS NVARCHAR(50))                                                            AS ItemStatus,

    ARSalesPrice.ExpirationDate                                                AS ExpirationDate,

    (SELECT TOP 1 C.SalesPrice
     FROM [dbo].[ARSalesPrice] C
     WHERE C.CompanyID        = ARSalesPrice.CompanyID
       AND C.InventoryID      = ARSalesPrice.InventoryID
       AND C.CustPriceClassID = 'MAPCA'
       AND C.EffectiveDate    <= GETDATE()
     ORDER BY C.EffectiveDate DESC)                                            AS MapCA,

    (SELECT TOP 1 C.SalesPrice
     FROM [dbo].[ARSalesPrice] C
     WHERE C.CompanyID        = ARSalesPrice.CompanyID
       AND C.InventoryID      = ARSalesPrice.InventoryID
       AND C.CustPriceClassID = 'MAPUS'
       AND C.EffectiveDate    <= GETDATE()
     ORDER BY C.EffectiveDate DESC)                                            AS MapNA,

    InventoryItem.BasePrice                                                    AS BasePrice,
    ARSalesPrice.EffectiveDate                                                 AS EffectiveDate,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'PMUPC'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS UniversalProductCode,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IECOO'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS CountryOfOrigin,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE1LENG'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS LengthIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE2WIDH'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS WidthIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IE3HGHT'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS HeightIn,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'IEPGWGT'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS ShipWeightLb,

    (SELECT TOP 1 CSAnswers.Value
     FROM [dbo].[InventoryItem] itm
     LEFT JOIN [dbo].[CSAnswers] ON itm.CompanyID = CSAnswers.CompanyID
                                AND itm.NoteID    = CSAnswers.RefNoteID
                                AND CSAnswers.AttributeID = 'PMRTN'
     WHERE itm.CompanyID   = InventoryItem.CompanyID
       AND itm.InventoryID = InventoryItem.InventoryID)                        AS ReturnableCancellable

FROM [dbo].[BAccount]
JOIN [dbo].[TSPriceGroup]  ON  BAccount.CompanyID              = TSPriceGroup.CompanyID
JOIN [dbo].[InventoryItem] ON  InventoryItem.CompanyID         = BAccount.CompanyID
                           AND InventoryItem.UsrPriceGroupID   = TSPriceGroup.RecID
JOIN [dbo].[ARSalesPrice]  ON  ARSalesPrice.CompanyID          = BAccount.CompanyID
                           AND ARSalesPrice.CustomerID         = BAccount.BAccountID
                           AND InventoryItem.InventoryID       = ARSalesPrice.InventoryID
                           AND ARSalesPrice.PriceType          = 'C'
                           AND ARSalesPrice.EffectiveDate      = (
                                   SELECT MAX(Z.EffectiveDate)
                                   FROM [dbo].[ARSalesPrice] Z
                                   WHERE Z.CompanyID   = ARSalesPrice.CompanyID
                                     AND Z.InventoryID = ARSalesPrice.InventoryID
                                     AND Z.CustomerID  = ARSalesPrice.CustomerID
                                     AND Z.EffectiveDate <= GETDATE()
                               )
WHERE BAccount.CompanyID = 10
  AND (ARSalesPrice.ExpirationDate >= GETDATE() OR ARSalesPrice.ExpirationDate IS NULL)