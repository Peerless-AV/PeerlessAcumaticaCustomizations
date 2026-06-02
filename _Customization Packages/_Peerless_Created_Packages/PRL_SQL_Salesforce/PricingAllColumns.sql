/************************************************************************************************
 *                                                                                              *
 *   7-30-24:    Created to list prices based on part number, if on a price list.              *
 *   5-28-26:    Modified sub-selects and main join to return only the most recent effective   *
 *               price record with EffectiveDate <= today, preventing multiple-row sub-select errors *
 *               as pricing model has matured with future-dated entries.                       *
 *                                                                                              *
 ***********************************************************************************************/
SELECT
    InventoryItem.CompanyID        AS "CompanyID",
    InventoryItem.InventoryCD,
    InventoryItem.InventoryID,
    InventoryItem.Descr,
    InventoryItem.BasePrice,
    InventoryItem.CountryOfOrigin,
    TSPriceGroup.PriceGroupCode,
    ARSalesPrice.SalesPrice        AS "Dealer",
    (SELECT TOP 1 B.SalesPrice
     FROM ARSalesPrice B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'PART'
       AND B.EffectiveDate          <= GETDATE()
     ORDER BY B.EffectiveDate DESC)  AS "Part",
    (SELECT TOP 1 B.SalesPrice
     FROM ARSalesPrice B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DIST'
       AND B.EffectiveDate          <= GETDATE()
     ORDER BY B.EffectiveDate DESC)  AS "Dist",
    (SELECT TOP 1 B.SalesPrice
     FROM ARSalesPrice B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'SPEC'
       AND B.EffectiveDate          <= GETDATE()
     ORDER BY B.EffectiveDate DESC)  AS "Spec",
      (SELECT TOP 1 B.SalesPrice
     FROM ARSalesPrice B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DEALCI'
       AND B.EffectiveDate          <= GETDATE()
     ORDER BY B.EffectiveDate DESC)  AS "DealCI",
      (SELECT TOP 1 B.SalesPrice
     FROM ARSalesPrice B
     WHERE B.CompanyID        = InventoryItem.CompanyID
       AND B.InventoryID      = InventoryItem.InventoryID
       AND B.CustPriceClassID = 'DISTCI'
       AND B.EffectiveDate          <= GETDATE()
     ORDER BY B.EffectiveDate DESC)  AS "DistCI"
FROM InventoryItem
JOIN TSPriceGroup  ON  InventoryItem.UsrPriceGroupID = TSPriceGroup.RecID
                   AND InventoryItem.CompanyID        = TSPriceGroup.CompanyID
JOIN ARSalesPrice  ON  InventoryItem.InventoryID      = ARSalesPrice.InventoryID
                   AND InventoryItem.CompanyID        = ARSalesPrice.CompanyID
                   AND ARSalesPrice.CustPriceClassID  = 'DEAL'
                   AND ARSalesPrice.EffectiveDate           = (
                           SELECT MAX(C.EffectiveDate)
                           FROM ARSalesPrice C
                           WHERE C.CompanyID        = InventoryItem.CompanyID
                             AND C.InventoryID      = InventoryItem.InventoryID
                             AND C.CustPriceClassID = 'DEAL'
                             AND C.EffectiveDate          <= GETDATE())
WHERE TSPriceGroup.PriceGroupCode IN ('CORE','ET','KIOSK','DS','E-TAIL','RETAIL','SHADE','HOSP','NEPTUNE')
  AND InventoryItem.CompanyID   = '10'
  --AND InventoryItem.InventoryCD = 'NT553'
