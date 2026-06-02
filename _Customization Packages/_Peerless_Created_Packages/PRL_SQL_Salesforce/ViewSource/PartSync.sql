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
-- 2. US tenant
-- ----------------------------------------------------------------
US AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.InventoryID,
        i.Descr                 AS USDescriptionc,
        i.ItemStatus            AS ACUItemStatusc,
        i.SalesUnit             AS QuantityUnitOfMeasure,
        CASE WHEN i.ItemStatus IN ('AC', 'NP', 'NR') THEN 'True' ELSE 'False' END
                                AS IsActive,
        i.ItemStatus            AS SalesPartStatusc,
        CASE WHEN i.UsrAuthorization = 1 THEN 'True' ELSE 'False' END
                                AS ACUAuthorizationRequiredc,
        CASE RTRIM(ic.ItemClassCD)
            WHEN 'BPE  STAND'              THEN 'KIOSK'
            WHEN 'KIOSKCUSTM'              THEN 'KIOSK'
            WHEN 'KIOSKSTAND'              THEN 'KIOSK'
            WHEN 'KIOSKSTANDINDOR'         THEN 'KIOSK'
            WHEN 'KIOSKSTANDINDORGROUN'    THEN 'KIOSK'
            WHEN 'KIOSKSTANDINDORWALL'     THEN 'KIOSK'
            WHEN 'KIOSKSTANDOUTDR'         THEN 'KIOSK'
            WHEN 'KIOSKSTANDOUTDRGROUN'    THEN 'KIOSK'
            WHEN 'VLTA'                    THEN 'KIOSK'
            WHEN 'VLTA CUSTM'              THEN 'KIOSK'
            WHEN 'VLTA STAND'              THEN 'KIOSK'
            WHEN 'DS   CUSTM'              THEN 'LED'
            WHEN 'DS   STAND'              THEN 'LED'
            WHEN 'LED'                     THEN 'LED'
            WHEN 'LED  CUSTM'              THEN 'LED'
            WHEN 'LED  CUSTMACC'           THEN 'LED'
            WHEN 'LED  CUSTMDED'           THEN 'LED'
            WHEN 'LED  CUSTMLEDF'          THEN 'LED'
            WHEN 'LED  CUSTMLEDFS'         THEN 'LED'
            WHEN 'LED  CUSTMSUBF'          THEN 'LED'
            WHEN 'LED  CUSTMTK'            THEN 'LED'
            WHEN 'LED  CUSTMUNV'           THEN 'LED'
            WHEN 'LED  STAND'              THEN 'LED'
            WHEN 'LED  STANDACC'           THEN 'LED'
            WHEN 'LED  STANDACC  LED'      THEN 'LED'
            WHEN 'LED  STANDACC  LEDTK'    THEN 'LED'
            WHEN 'LED  STANDDED'           THEN 'LED'
            WHEN 'LED  STANDLEDF'          THEN 'LED'
            WHEN 'LED  STANDLEDFS'         THEN 'LED'
            WHEN 'LED  STANDSUBF'          THEN 'LED'
            WHEN 'LED  STANDTK'            THEN 'LED'
            WHEN 'LED  STANDUNV'           THEN 'LED'
            WHEN 'DVLED'                   THEN 'DVLED'
            WHEN 'DVLEDCUSTM     MAHLO'    THEN 'DVLED'
            WHEN 'ET   STAND'              THEN 'TV'
            WHEN 'ET   STANDNEPTN'         THEN 'TV'
            WHEN 'ET   STANDULTVW'         THEN 'TV'
            WHEN 'ET   STANDXTRME'         THEN 'TV'
            WHEN 'FPSS'                    THEN 'MOUNT'
            WHEN 'FPSS CUSTM'              THEN 'MOUNT'
            WHEN 'FPSS STAND'              THEN 'MOUNT'
            WHEN 'FPSS STANDETAIL'         THEN 'MOUNT'
            WHEN 'FPSS STANDPMNT'          THEN 'MOUNT'
            WHEN 'FPSS STANDSMRT'          THEN 'MOUNT'
            WHEN 'FPSS STANDSMRXT'         THEN 'MOUNT'
            WHEN 'FPSS STANDTRVUE'         THEN 'MOUNT'
            WHEN 'HOSP CUSTM'              THEN 'MOUNT'
            WHEN 'HOSP STAND'              THEN 'MOUNT'
            WHEN 'PSS'                     THEN 'MOUNT'
            WHEN 'PSS  CUSTM'              THEN 'MOUNT'
            WHEN 'PSS  STAND'              THEN 'MOUNT'
            WHEN 'PSS  STANDPJF2'          THEN 'MOUNT'
            WHEN 'PSS  STANDPJR'           THEN 'MOUNT'
            WHEN 'PSS  STANDPRG'           THEN 'MOUNT'
            WHEN 'PSS  STANDPRGS'          THEN 'MOUNT'
            ELSE NULL
        END                     AS CategoryC
    FROM [dbo].[InventoryItem] i
    JOIN [dbo].[INItemClass] ic ON ic.ItemClassID = i.ItemClassID
                                AND ic.CompanyID   = i.CompanyID
    JOIN Tenants t              ON t.CompanyID     = i.CompanyID
    WHERE t.TenantCode = 'US'
    AND i.DeletedDatabaseRecord = 0
),

-- ----------------------------------------------------------------
-- 3. UK tenant — CategoryC placeholder pending UK mapping
-- ----------------------------------------------------------------
UK AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.Descr                 AS UKDescriptionc,
        CAST(NULL AS NVARCHAR(50)) AS CategoryC  -- UK mapping TBD
    FROM [dbo].[InventoryItem] i
    JOIN [dbo].[INItemClass] ic ON ic.ItemClassID = i.ItemClassID
                                AND ic.CompanyID   = i.CompanyID
    JOIN Tenants t              ON t.CompanyID     = i.CompanyID
    WHERE t.TenantCode = 'UK'
    AND i.DeletedDatabaseRecord = 0
),

-- ----------------------------------------------------------------
-- 4. MX tenant — CategoryC placeholder pending MX mapping
-- ----------------------------------------------------------------
MX AS (
    SELECT
        RTRIM(i.InventoryCD)    AS InventoryCD,
        i.Descr                 AS MXDescriptionc,
        CAST(NULL AS NVARCHAR(50)) AS CategoryC  -- MX mapping TBD
    FROM [dbo].[InventoryItem] i
    JOIN [dbo].[INItemClass] ic ON ic.ItemClassID = i.ItemClassID
                                AND ic.CompanyID   = i.CompanyID
    JOIN Tenants t              ON t.CompanyID     = i.CompanyID
    WHERE t.TenantCode = 'MX'
    AND i.DeletedDatabaseRecord = 0
)

-- ----------------------------------------------------------------
-- 5. Pivot to one row per part
-- ----------------------------------------------------------------
SELECT
    -- Identity
    CAST(
        COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)
    AS NVARCHAR(100))                                               AS ExternalKey,

    -- Part number (three SFDC targets, same value)
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS PartNumberc,
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS ProductCode,
    COALESCE(us.InventoryCD, uk.InventoryCD, mx.InventoryCD)       AS Name,

    -- Descriptions per tenant
    us.USDescriptionc,
    uk.UKDescriptionc,
    mx.MXDescriptionc,

    -- US-sourced global fields
    us.ACUItemStatusc,
    us.SalesPartStatusc,
    us.IsActive,
    us.QuantityUnitOfMeasure,
    us.ACUAuthorizationRequiredc,

    -- Category — US first, fall back to UK then MX
    COALESCE(us.CategoryC, uk.CategoryC, mx.CategoryC)             AS CategoryC

    -- Pending / To Be Added
    -- USProductFamilyc / Family        (source TBD)
    -- UKProductFamilyc                 (UK join TBD)
    -- MXProductFamilyc                 (MX join TBD)
    -- ACUPMPLCMc                       (attribute join TBD)
    -- MOQc                             (source TBD)

FROM US us
FULL OUTER JOIN UK uk ON uk.InventoryCD = us.InventoryCD
FULL OUTER JOIN MX mx ON mx.InventoryCD = us.InventoryCD