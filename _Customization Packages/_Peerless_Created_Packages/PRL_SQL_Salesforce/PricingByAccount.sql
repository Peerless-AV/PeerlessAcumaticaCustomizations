/****************************************************************************
 *																			*
 * 7-30-2024:  SQL will pull pricing by account, listing all products with  *
 *             price groups, and then all account specific pricing.         *
 *																			*
 * 8-29-2024:  Updated to correct for customer pricing including date logic *
 ***************************************************************************/
select TSCustomerPriceGroup.CompanyID, TSCustomerPriceGroup.Description as "Customer Name", BAccount.AcctCD as "Customer", TSCustomerpriceGroup.PriceClassID as "Customer Price Class", InventoryItem.InventoryCD as "Part Number", InventoryItem.Descr as "Description", TSPriceGroup.PriceGroupDescription as "Product Group", TSPriceGroup.PriceGroupCode as "Price Group", arsalesprice.SalesPrice as "Price"
, (CASE InventoryItem.ItemStatus
		when 'AC' then 'Active'
		when 'NS' then 'No Sale'
		when 'NP' then 'No Purchase'
		when 'NR' then 'No Request'
		when 'IN' then 'Inactive'
		when 'DE' then 'Marked for Deletion'
   End)as "Item Status"
, ARSalesPrice.ExpirationDate
, (select B.SalesPrice from ARSalesPrice B where B.CompanyID = ARSalesPrice.CompanyID and ARSalesPrice.InventoryID = B.InventoryID and B.CustPriceClassID = 'MAPCA' and B.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and Z.CustPriceClassID = 'MAPCA')) AS "MAP CA"
, (select B.SalesPrice from ARSalesPrice B where B.CompanyID = ARSalesPrice.CompanyID and ARSalesPrice.InventoryID = B.InventoryID and B.CustPriceClassID = 'MAPUS' and B.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and Z.CustPriceClassID = 'MAPUS')) AS "MAP NA"
, InventoryItem.BasePrice
, ARSalesPrice.EffectiveDate
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='PMUPC'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Universal Product Code"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IECOO'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Country Of Origin"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE1LENG'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Length (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE2WIDH'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Width (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE3HGHT'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Height (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IEPGWGT'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Ship Weight (lb)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='PMRTN'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Returnable / Cancellable"
from TSCustomerPriceGroup, BAccount, TSPriceGroup, InventoryItem, ARSalesPrice
where TSCustomerPriceGroup.CompanyID = 10
and TSCustomerPriceGroup.CompanyID = BAccount.CompanyID
and TSCustomerPriceGroup.Description = BAccount.AcctName
and TSCustomerPriceGroup.CompanyID = TSPriceGroup.CompanyID
and TSCustomerPriceGroup.PriceGroupID = TSPriceGroup.RecID
and inventoryitem.CompanyID = TSCustomerPriceGroup.CompanyID
and InventoryItem.usrPriceGroupID = TSCustomerPriceGroup.PriceGroupID
--and BAccount.AcctCD in ('KNI499759')
and InventoryItem.InventoryID = ARSalesPrice.InventoryID
and ARSalesprice.CompanyID = TSCustomerPriceGroup.CompanyID
and arsalesprice.CustPriceClassID = TSCustomerPriceGroup.PriceClassID
and arsalesprice.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and Z.CustPriceClassID = arsalesprice.CustPriceClassID)
and (arsalesprice.ExpirationDate >= '2024-10-01' or arsalesprice.expirationdate is null)
--and InventoryItem.InventoryCD = 'SF640'
Union
select BAccount.CompanyID, BAccount.AcctName, BAccount.AcctCD, 'Customer Pricing', InventoryItem.InventoryCD, InventoryItem.Descr, TSPriceGroup.PriceGroupDescription, TSPriceGroup.PriceGroupCode as "Price Group", arsalesprice.SalesPrice
, (CASE InventoryItem.ItemStatus
		when 'AC' then 'Active'
		when 'NS' then 'No Sale'
		when 'NP' then 'No Purchase'
		when 'NR' then 'No Request'
		when 'IN' then 'Inactive'
		when 'DE' then 'Marked for Deletion'
   End)
, ARSalesPrice.ExpirationDate
, (select C.SalesPrice from ARSalesPrice C where C.CompanyID = ARSalesPrice.CompanyID and ARSalesPrice.InventoryID = C.InventoryID and C.CustPriceClassID = 'MAPCA' and c.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and Z.CustPriceClassID = 'MAPCA')) AS "MAP CA"
, (select C.SalesPrice from ARSalesPrice C where C.CompanyID = ARSalesPrice.CompanyID and ARSalesPrice.InventoryID = C.InventoryID and C.CustPriceClassID = 'MAPUS' and c.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and Z.CustPriceClassID = 'MAPUS')) AS "MAP CA"
, InventoryItem.BasePrice
, ARSalesPrice.EffectiveDate
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='PMUPC'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Universal Product Code"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IECOO'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Country Of Origin"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE1LENG'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Length (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE2WIDH'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Width (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IE3HGHT'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Height (in)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='IEPGWGT'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Ship Weight (lb)"
,(select CSAnswers.Value as UPC from InventoryItem itm left join CSAnswers on itm.CompanyID=CSAnswers.CompanyID and itm.NoteID = CSAnswers.RefNoteID  and CSAnswers.AttributeID='PMRTN'
	where itm.CompanyID =inventoryitem.CompanyID and itm.InventoryID=inventoryitem.InventoryID ) as "Returnable / Cancellable"
from BAccount, TSPriceGroup, InventoryItem, ARSalesPrice
where BAccount.CompanyID = 10
and ARsalesPrice.CompanyID = BAccount.CompanyID
and ARSalesPrice.CustomerID = BAccount.BAccountID
and BAccount.CompanyID = TSPriceGroup.CompanyID
and inventoryitem.CompanyID = BAccount.CompanyID
--and BAccount.AcctCD in ('KNI499759')
and InventoryItem.InventoryID = ARSalesPrice.InventoryID
--and InventoryItem.InventoryCD = 'SF640'
and inventoryItem.UsrPriceGroupID = TSPriceGroup.RecID
and arsalesprice.pricetype = 'C'
and (arsalesprice.ExpirationDate >= '2024-10-01' or arsalesprice.expirationdate is null)
and arsalesprice.EffectiveDate = (select max(Z.effectiveDate) from ARSalesPrice Z where Z.CompanyID = ARSalesPrice.CompanyID and Z.InventoryID = ARSalesPrice.InventoryID and arsalesprice.customerID = z.CustomerID)