IF OBJECT_ID('dbo.CBIZSalesOrdersSummaryView', 'V') IS NULL
    EXEC('CREATE VIEW [dbo].[CBIZSalesOrdersSummaryView] AS SELECT 1 AS placeholder')
GO
ALTER VIEW [dbo].[CBIZSalesOrdersSummaryView]
AS
SELECT SO.CompanyID,

  -- Effective date: skip Sunday, use Friday instead
  CAST(CASE 
    WHEN DATENAME(dw, DATEADD(day, -1, GETDATE())) = 'Sunday' 
    THEN CAST(DATEADD(day, -3, GETDATE()) AS date) 
    ELSE CAST(DATEADD(day, -1, GETDATE()) AS date) 
  END AS datetime) AS [ShipmentDate],

  -- New order count: created yesterday, exclude QT/RC/BL
  CAST((
    SELECT COUNT(OrderNbr) 
    FROM SOOrder NO 
    WHERE CAST(NO.CreatedDateTime AS date) = CASE 
        WHEN DATENAME(dw, DATEADD(day, -1, GETDATE())) = 'Sunday' 
        THEN CAST(DATEADD(day, -3, GETDATE()) AS date) 
        ELSE CAST(DATEADD(day, -1, GETDATE()) AS date) END
    AND NO.OrderType NOT IN ('QT', 'RC', 'BL')
    AND NO.CompanyID = SO.CompanyID
  ) AS INT) AS [NewOrderCount],

  -- Open order total: all open orders created <= yesterday, exclude QT/RC/BL
  CAST(ISNULL((
    SELECT SUM(CuryOpenOrderTotal) 
    FROM SOOrder OO 
    WHERE CAST(OO.CreatedDateTime AS date) <= CASE 
        WHEN DATENAME(dw, DATEADD(day, -1, GETDATE())) = 'Sunday' 
        THEN CAST(DATEADD(day, -3, GETDATE()) AS date) 
        ELSE CAST(DATEADD(day, -1, GETDATE()) AS date) END
    AND OO.OrderType NOT IN ('QT', 'RC', 'BL')
    AND OO.Status <> 'C'
    AND OO.CompanyID = SO.CompanyID
  ), 0) AS decimal(19,4)) AS [OpenOrderTotal],

  -- New order total: created yesterday, exclude QT/RC/BL
  CAST(ISNULL((
    SELECT SUM(CuryOpenOrderTotal) 
    FROM SOOrder NT 
    WHERE CAST(NT.CreatedDateTime AS date) = CASE 
        WHEN DATENAME(dw, DATEADD(day, -1, GETDATE())) = 'Sunday' 
        THEN CAST(DATEADD(day, -3, GETDATE()) AS date) 
        ELSE CAST(DATEADD(day, -1, GETDATE()) AS date) END
    AND NT.OrderType NOT IN ('QT', 'RC', 'BL')
    AND NT.CompanyID = SO.CompanyID
  ), 0) AS decimal(19,4)) AS [NewOrderTotal],

  -- Cancelled order total: last modified yesterday, exclude QT/RC/BL, status not closed, cancelled flag set
  CAST(ISNULL((
    SELECT SUM(CuryOrderTotal) 
    FROM SOOrder C 
    WHERE CAST(C.LastModifiedDateTime AS date) = CASE 
        WHEN DATENAME(dw, DATEADD(day, -1, GETDATE())) = 'Sunday' 
        THEN CAST(DATEADD(day, -3, GETDATE()) AS date) 
        ELSE CAST(DATEADD(day, -1, GETDATE()) AS date) END
    AND C.OrderType NOT IN ('QT', 'RC', 'BL')
    AND C.Status <> 'C'
    AND C.Cancelled = 1
    AND C.CompanyID = SO.CompanyID
  ), 0) AS decimal(19,4)) AS [CancelledOrderTotal]

FROM SOOrder SO
GROUP BY SO.CompanyID
GO