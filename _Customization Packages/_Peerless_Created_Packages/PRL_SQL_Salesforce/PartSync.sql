CREATE OR ALTER VIEW [dbo].[PRL_SFDC_Part_Sync] AS

WITH

-- ----------------------------------------------------------------
-- 1. Resolve tenant companies via CompanyCD
-- ----------------------------------------------------------------
Tenants AS (
    SELECT
        CompanyID,
        CASE CompanyCD
            WHEN 'Peerless-AV'     THEN 'US'
            WHEN 'Peerless-AV LTD' THEN 'UK'
            WHEN 'Peerless-AV MX'  THEN 'MX'
        END AS TenantCode
    FROM [dbo].[Company]
    WHERE CompanyCD IN ('Peerless-AV', 'Peerless-AV LTD', 'Peerless-AV MX')
    AND CompanyID > 0
),

-- ----------------------------------------------------------------
-- 2. One CTE per tenant pulling confirmed fields only
-- ----------------------------------------------------------------
US AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.InventoryID,
        i.Descr                 AS USDescriptionc,
        i.ItemStatus            AS ACUItemStatusc,
        i.SalesUnit             AS QuantityUnitOfMeasure
    FROM [dbo].[InventoryItem] i
    JOIN Tenants t ON t.CompanyID = i.CompanyID
    WHERE t.TenantCode = 'US'
    AND i.DeletedDatabaseRecord = 0
),

UK AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.Descr                 AS UKDescriptionc
    FROM [dbo].[InventoryItem] i
    JOIN Tenants t ON t.CompanyID = i.CompanyID
    WHERE t.TenantCode = 'UK'
    AND i.DeletedDatabaseRecord = 0
),

MX AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.Descr                 AS MXDescriptionc
    FROM [dbo].[InventoryItem] i
    JOIN Tenants t ON t.CompanyID = i.CompanyID
    WHERE t.TenantCode = 'MX'
    AND i.DeletedDatabaseRecord = 0
)

-- ----------------------------------------------------------------
-- 3. Pivot to one row per part, tenants joined by InventoryCD
--    COALESCE on InventoryCD handles parts that exist in UK or MX
--    but not in US
-- ----------------------------------------------------------------
SELECT
    -- Identity / composite key
    CAST(
        COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)
    AS NVARCHAR(100))                                               AS ExternalKey,

    -- Part number (same value, three SFDC targets)
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS PartNumberc,
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS ProductCode,
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS Name,

    -- Descriptions per tenant
    us.USDescriptionc,
    uk.UKDescriptionc,
    mx.MXDescriptionc,

    -- US-sourced fields (authoritative for global fields)
    us.ACUItemStatusc,
    us.QuantityUnitOfMeasure

    -- Pending / To Be Added
    -- ACUAuthorizationRequiredc        (source TBD)
    -- USProductFamilyc / Family        (source TBD)
    -- UKProductFamilyc                 (UK join TBD)
    -- MXProductFamilyc                 (MX join TBD)
    -- ACUPMPLCMc                       (attribute join TBD)
    -- MOQc                             (source TBD)
    -- IsActive                         (source TBD)
    -- SalesPartStatusc                 (source TBD)

FROM US us
FULL OUTER JOIN UK uk ON uk.InventoryCD = us.InventoryCD
FULL OUTER JOIN MX mx ON mx.InventoryCD = us.InventoryCD