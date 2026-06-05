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
 *   6-02-26:   Replaced hardcoded CompanyID = 10 with Company table lookup on                *
 *              CompanyCD = 'Peerless-AV' for environment portability.                        *
 *   6-05-26:   Removed class-based pricing UNION leg. View now returns customer-specific      *
 *              pricing only (ARSalesPrice.PriceType = 'C'). Tightened TSPriceGroup join.     *
 *                                                                                              *
 ***********************************************************************************************/
CREATE OR ALTER VIEW [dbo].[vw_PRL_Account_Pricing] AS

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
JOIN [dbo].[InventoryItem] ON  InventoryItem.CompanyID       = BAccount.CompanyID
JOIN [dbo].[TSPriceGroup]  ON  TSPriceGroup.CompanyID        = BAccount.CompanyID
                           AND TSPriceGroup.RecID             = InventoryItem.UsrPriceGroupID
JOIN [dbo].[ARSalesPrice]  ON  ARSalesPrice.CompanyID        = BAccount.CompanyID
                           AND ARSalesPrice.CustomerID        = BAccount.BAccountID
                           AND ARSalesPrice.InventoryID       = InventoryItem.InventoryID
                           AND ARSalesPrice.PriceType         = 'C'
                           AND ARSalesPrice.EffectiveDate     = (
                                   SELECT MAX(Z.EffectiveDate)
                                   FROM [dbo].[ARSalesPrice] Z
                                   WHERE Z.CompanyID        = ARSalesPrice.CompanyID
                                     AND Z.InventoryID      = ARSalesPrice.InventoryID
                                     AND Z.CustomerID       = ARSalesPrice.CustomerID
                                     AND Z.EffectiveDate    <= GETDATE()
                               )
WHERE BAccount.CompanyID = (
          SELECT CompanyID FROM [dbo].[Company]
          WHERE CompanyCD = 'Peerless-AV'
            AND CompanyID > 0
      )
  AND (ARSalesPrice.ExpirationDate >= GETDATE() OR ARSalesPrice.ExpirationDate IS NULL)