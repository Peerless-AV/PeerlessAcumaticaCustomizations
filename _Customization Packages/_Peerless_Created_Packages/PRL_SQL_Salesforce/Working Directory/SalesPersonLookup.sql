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