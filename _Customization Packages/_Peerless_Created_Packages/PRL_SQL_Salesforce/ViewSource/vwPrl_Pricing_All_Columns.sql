/************************************************************************************************
 *                                                                                              *
 *   View:      vw_Prl_Pricing_All_Columns                                                     *
 *   Author:    BTG IT / Peerless-AV                                                           *
 *                                                                                              *
 *   7-30-24:   Created to list prices based on part number, if on a price list.               *
 *   5-28-26:   Modified sub-selects and main join to return only the most recent effective    *
 *              price record with EffectiveDate <= today, preventing multiple-row errors        *
 *              as pricing model has matured with future-dated entries.                         *
 *   5-28-26:   Reformatted as Acumatica SQL view. Column aliases use PascalCase with no       *
 *              underscores per Acumatica BQL DAC binding requirements.                        *
 *   6-02-26:   Replaced hardcoded CompanyID = 10 with Company table lookup on                *
 *              CompanyCD = 'Peerless-AV' for environment portability across DEV/Test/QA/Prod. *
 *                                                                                              *
 ***********************************************************************************************/
CREATE or ALTER VIEW [dbo].[vw_Prl_Pricing_All_Columns] AS

SELECT
    InventoryItem.CompanyID                                                    AS CompanyID,
    InventoryItem.InventoryCD                                                  AS InventoryCD,
    InventoryItem.InventoryID                                                  AS InventoryID,
    InventoryItem.Descr                                                        AS Descr,
    InventoryItem.BasePrice                                                    AS BasePrice,
    InventoryItem.CountryOfOrigin                                              AS CountryOfOrigin,
    TSPriceGroup.PriceGroupCode                                                AS PriceGroupCode,

    ARSalesPrice.SalesPrice                                                    AS Dealer,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'PART'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS Part,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DIST'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS Dist,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'SPEC'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS Spec,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DEALCI'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS DealCI,

    (SELECT TOP 1 B.SalesPrice
     FROM [dbo].[ARSalesPrice] B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DISTCI'
       AND B.EffectiveDate    <= GETDATE()
     ORDER BY B.EffectiveDate DESC)                                            AS DistCI

FROM [dbo].[InventoryItem]
JOIN [dbo].[TSPriceGroup]  ON  InventoryItem.UsrPriceGroupID = TSPriceGroup.RecID
                           AND InventoryItem.CompanyID        = TSPriceGroup.CompanyID
JOIN [dbo].[ARSalesPrice]  ON  InventoryItem.InventoryID      = ARSalesPrice.InventoryID
                           AND InventoryItem.CompanyID        = ARSalesPrice.CompanyID
                           AND ARSalesPrice.CustPriceClassID  = 'DEAL'
                           AND ARSalesPrice.EffectiveDate      = (
                                   SELECT MAX(C.EffectiveDate)
                                   FROM [dbo].[ARSalesPrice] C
                                   WHERE C.CompanyID        = InventoryItem.CompanyID
                                     AND C.InventoryID      = InventoryItem.InventoryID
                                     AND C.CustPriceClassID = 'DEAL'
                                     AND C.EffectiveDate    <= GETDATE()
                               )
WHERE TSPriceGroup.PriceGroupCode IN ('CORE','ET','KIOSK','DS','E-TAIL','RETAIL','SHADE','HOSP','NEPTUNE')
  AND InventoryItem.CompanyID = (
          SELECT CompanyID FROM [dbo].[Company]
          WHERE CompanyCD = 'Peerless-AV' and CompanyID > 0
      )