## Purpose:
Customization has been written to be deployed with the AIS customization for MDO.  The original customization was not written
in a way to provide friendly reporting.  This package creates several SQL views for the purpose of reporting values by stock / purchased item

### 9/19/2024

Initial release.  Deploying 4 SQL views to enhance the ability to create GI's for the purpose of using the calculated overhead value from the original package.

#### Dependancies:

AISCostOverheadAllocation[002] -- Provided by CBIZ.  Version deployed 9-18-2024.  


##### SQL Views Create Statements, placed in package:

DROP VIEW IF EXISTS dbo.PRLAISOvrHeadValue
GO

CREATE VIEW [dbo].[PRLAISOvrHeadValue]
AS
select CompanyID, OverheadID, OverheadCD, Descr, Sum(Overhead) OverHead, sum(Freight) Freight, sum(Tariff) Tariff 
from(
select CompanyID,
	   OverheadID,
	   OverheadCD,
	   Descr,
	   OvhValue as Overhead,
	   Null    as Freight,
	   Null	   as Tariff
from   [dbo].[AISINOverhead]
where  Element = 'V'
union
select CompanyID,
	   OverheadID,
	   OverheadCD,
	   Descr,
	   Null,
	   OvhValue,
	   Null
from   [dbo].[AISINOverhead]
where  Element = 'F'
union
select CompanyID,
       OverheadID,
	   OverheadCD,
	   Descr,
	   Null,
	   null,
	   OvhValue
from   [dbo].[AISINOverhead]
where  Element = 'T') as OverHeadVW
group by companyID, OverHeadID, overheadCD, Descr


DROP VIEW IF EXISTS dbo.PRLOverheadByPart
GO

CREATE VIEW [dbo].[PRLOverheadByPart] as
Select A.CompanyID, A.InventoryCD, A.usrAISOverheadID, MAX(B.OverheadCD) OverheadCD
  From dbo.InventoryItem A, dbo.PRLAISOvrHeadValue B
 Where a.UsrAISOverheadID = B.OverheadID
   and a.CompanyID = b.CompanyID
Group by a.companyID, a.InventoryCD, a.UsrAISOverheadID


DROP VIEW IF EXISTS dbo.PRLOverheadCalculatedValuesByPart
GO

create view [dbo].[PRLOverheadCalculatedValuesByPart] as
select CompanyID,
	   InventoryCD,
	   UsrAISMaterialCost,
	   OverheadCD,
	   OverheadCalc,
	   OverheadValue,
	   TariffCalc,
	   TariffValue,
	   FreightCalc,
	   FreightValue,
	   case when OverheadValue is null then null
			when OverheadCalc = 'P' then UsrAISMaterialCost * OverheadValue
			when overheadCalc = 'V' then UsrAISMaterialCost + OverheadValue
			else null
	   end as OverheadCalculatedValue,
   	   case when TariffValue is null then null
			when TariffCalc = 'P' then UsrAISMaterialCost * TariffValue
			when TariffCalc = 'V' then UsrAISMaterialCost + TariffValue
			else null
	   end as TariffCalculatedValue,
   	   case when FreightValue is null then null
			when FreightCalc = 'P' then UsrAISMaterialCost * FreightValue
			when FreightCalc = 'V' then UsrAISMaterialCost + FreightValue
			else null
	   end as FreightCalculatedValue
	   from prlOverheadValuesByPart


DROP VIEW IF EXISTS dbo.PRLOverheadValuesByPart
GO

create view [dbo].[PRLOverheadValuesByPart] as
select a.CompanyID, a.InventoryCD, a.UsrAISMaterialCost, b.OverheadCD, 
(select c.Ovhtype from PRLAISOvrHeadValue c where c.CompanyID = a.companyID and c.OverheadCD = b.overheadcd and c.overhead is not null) as OverheadCalc,
(select d.OverHead from PRLAISOvrHeadValue d where d.CompanyID = a.companyID and d.OverheadCD = b.overheadcd and d.overhead is not null) as OverheadValue,
(select e.ovhtype from PRLAISOvrHeadValue e where e.CompanyID = a.companyID and e.OverheadCD = b.overheadcd and e.Tariff is not null) as TariffCalc,
(select f.Tariff from PRLAISOvrHeadValue f where f.CompanyID = a.companyID and f.OverheadCD = b.overheadcd and f.Tariff is not null) as TariffValue,
(select g.ovhtype from PRLAISOvrHeadValue g where g.CompanyID = a.companyID and g.OverheadCD = b.overheadcd and g.Freight is not null) as FreightCalc,
(select h.Freight from PRLAISOvrHeadValue h where h.CompanyID = a.companyID and h.OverheadCD = b.overheadcd and h.Freight is not null) as FreightValue
from dbo.InventoryItem a, dbo.PRLOverheadByPart b
where a.companyID = b.companyID and a.UsrAISOverheadID = b.usrAISOverheadID