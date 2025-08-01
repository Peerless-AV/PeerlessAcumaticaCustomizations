# PeerlessAcumaticaCustomizations

Use:  Simple write up of customizations and deployments for Peerless-AV Acumatica.  The baseline
list of customzations in Acumatica consist of items loaded prior to August, 2024.  The folders in
the repository will work as follows:

### _Released Folder

The _Released folder will contain all packages currently deployed to the live system 

### _Dev Folder

The _Dev folder will contain only those packages that are new, deployed to the DEV environment.
Dev is used to ensure anything delivered to Peerless-AV does not compramize, or break any 
functionality.  Once released to Live, the file will be moved from _Dev to _Released.

### _Reports Folder

Updated report designer reports will be kept here.  Versions of these reports are also deployed
in acumatica.  Not all reports are deployed to all production tenants, so the folders are organized by
tenants.  Peerless-AV, Peerless-AV MX and Peerless-AV LTD tenants are documented, respective TEST tenants are NOT.

### _Export_Scenarios Folder
### _Import_Scenarios Folder

Export and import scenarios in Acumatica can be saved as XML format and imported into alternat tenants.  There are a few
scenarios used by Peerless-AV by departmental users.  These are documented and should go through change control, to keep
users informed of any differences.  Not all scenarios are deployed to all production tenants, so the folders are organized by
tenants.  Peerless-AV, Peerless-AV MX and Peerless-AV LTD tenants are documented, respective TEST tenants are NOT.

### _Generic_Inquieries

GI's are used in all departments, to analize data and create excel documents.  major changes to GI's should be kept here, and 
popular ones used in work instructions should go through change control.  Not all GI's are deployed to all production tenants, so the folders are organized by
tenants.  Peerless-AV, Peerless-AV MX and Peerless-AV LTD tenants are documented, respective TEST tenants are NOT.

## Package Documentation Section

### Aug 2024 Package Deployment

#### TSSOProfitMarginCalculation[005].zip

Fix / correction to the logic that calculates the margin on a sales order.  Fixes issue in UK, as well as ensure both standard cost items and FIFO costs items calculate properly in US tenant.

#### CBIZ.PL.LocationSort.zip

This customization sets the default sort order on the look up screens for location numbers, sorting by qty avaialble decending on all screens.  

#### CBIZ.PL.SalesRegion.zip

Delivery which will allow Peerless-AV to define the sales regions by state and zip code, used for reporting purposes.

#### IIGCONTAINERMGMT   

Liz delivered an update due to an issue reported by Luke in the UK.  The issue was preventing Luke from processing containers.

#### CBIZRadleyMerge[003] -- Replacing CBIZRadleyMerge[002]

Fixed Confirm Shipment action error when process from Process Shipments screen.

#### CBIZ.ShippingInst[007] -- Replacing CBIZ.ShippingInst[006]

ixed Shipment Date doesnt change issue if the shipment is confirmed from Process Shipments screen.

### End August 2024 List

### Aug-2024-HotFix-QCRecord Delete

8-26-2024:  Eworkplace apps delivered a hotfix to delete production entries in the QC module, so we can process records and move forward with
building the system.

### End Aug-2024-HotFix-QCRecord Delete


### Aug-2024-Package-A Deployment

8-15-2024 - Started new deployment group.  This group will include updating documentation on new folders for delivered GI's, Import / Export Scenarios and report updates.  Buidling folder structure for these objects based on production tenants.

8-20-2024 -- Rebuilt packages in DEV environment after a refresh of Peerless-AV - TEST.  The rebuild required a reboot of the server.

#### CBIZ.PL.OBSReport[002]

Initial delivery of the OBS report requested by Stephen K.  8/15/2024, this packaged failed deployment in previous group due
to compatibility issue with AIS cost package.  

#### TSSOProfitMarginCalculation[006]

Update to resolve an issue with calculating margin in the UK with different warehouses

#### AISCostOverheadAllocation[001]

Updated from origial version, showing package and code in visual studio, and correcting the calculate button to include multiple overhead values.

### End Aug-2024-Package-A

### Sep-2024 Release-A

8-26-2024: Updated this package, moving the budget actual package here as it is not approved for production release.  This package will remain in DEV

#### CBIZ.PL.AccountCompareBudget

Functionality added to show budget on account summary page.  Kris is asking for additional drill downs.  Prior to sending to CBIZ, DZ confirming okay to deploy as is, and work on drill down in second phase.

8-26-2024: Updated this package, moving to future because the current build is not approved for production release.  This package will remain in DEV

#### EWPAQMS[23.106.0050][23.147.74][01]

New Quality module to correct the issue with raising purchase requisitions -- and generating quality alerts from the purchase requisitions.  

#### InterastarDD 
#### CloudInfoFEMT 
    Update to CloudInfoFEMT -- June has corrected one of the variables used in the APX code to keep compatiblity with the QMS package -9-5-2028

Two packages for the MX Customization delivered by Alma to update the functionality in MX

#### CBIZ.PL.MRPCalculation

Update to MRP logic, allowing for a check box to remove order types from the calculation MRP uses.  Peerless-AV's example would be to remove Volta
orders from MRP so they are calculated manually.

#### CBIZ.PL.OBSReport[003]

Fixed report so parameters in the report will not affect live settings in the system.

#### CBIZ.PL.InvAllocationDetail - Adding Sales Order Status to Allocation Details

on the Allocation Details screen, a column for sales order status should be added, displaying the status of any sales order

### End Sep-2024 Release-A

### Sep-18-2024B Release 
Scheduled for 9/18/2024

#### CBIZ.PL.ItemStatus - Change for item statuses

The Item Status No Purchase should include a requirement that NO production orders can be created for a part in this status.  Additionally,
the status No Request should be setup the exact same way.

#### SOAttributesCBIZ[004] - Update for Tier Fucntionality on cusotmer orders

The tier of the customer was not coping down to the orders properly. 

#### InterastarDD && CloudInfoFEMT && InterastarCEMT

Correcting issues with the creation and transmission of the XML stamp to the government.

#### AISCostOverheadAllocation[002]

Correcting the spelling of Tariff.

### End Sep-18-2024B

### Oct-2024A

#### PRL.AISOverheadView

Package created by Peerless (DANZ50OF), to deploy SQL views and a GI to view the base information for the MDO customization

#### PRL.AMBOMCost_Single_Entry

Package created by Peerless (DANZ50OF), to deploy SQL view limiting the result set of AMBOMCost to a single entry per bomID / Revision.

#### CBIZRadleyMerge[004]

Update required for amazon label specifications

#### CBIZ.PL.AccountDetail

Update to account detail screen, adding project information

### End Oct-2024A

### Oct-2024B

#### IIGCONTAINERMGMT[R60]

Fix to add warehouse on the GI's as part of the container management module.

#### CBIZ.ShippingInst[009]

<laura, do you know what this update to shipping instructions included?>

#### CBIZ.PL.SAR[002]

Sales requested functionality which will allow Peerless to import historical sales data
and process information regarding monthly sales within Acumatica for accurate reporting purposes

#### IIGCONTAINERMGMT [60]

Update to container management package allowing UK to process information correctly as requested.

#### CloudInfoFEMT Update

Updated functionality from cloud info to correct processing in MX

#### PRLEDIEndpointDeployment

Upon noticing the EDI endpoint is not available in all tenants, this package has been created by peerless
and will be carried forward.

#### This one is a hotfix IIGChangeContainerStatusToClose1

This will update a containter that needs to be closed in the UK tenant.

### END Oct-2024B

### Oct-25-2024

The following two packages will need to be deployed 10/25 in the evening

#### PRL.AISOverheadView

Adding index field tot he main view for material overhead report export

#### CBIZ.PL.SaleaReportDataView[005]

Adding logic for including the assigned sales region in each line of sales.

### End Oct-25-2024

### 11-14-2024

Note:  Levels of MX packages changed:  No files to import, only data changes on the customization
       project levels:

       CloudInfoFEMT moved to 20000
       InterastarDD moved to 20010
       InterastarCEMT moved to 20020
       InterastarDIOT moved to 20030

#### CBIZRadleyMerge[006]

Need update for packages description

#### CBIZ.PL.SAR[003]

Added functionality to allow posting to all dates regardless of period closure, and allow for
additional field and drop down columns to sort out goal information.

### End 11-14-2024

### 2-3-2025

#### CBIZ.PL.APInvoiceDiff.zip

Delivery of package to supply a difference column on the AP invoice screen, as requested by
accounting.

#### CBIZ.PL.SaleaReportDataView[008].zip

Update to views for calculating the SAR and SAR detail reports

#### Interastar_Vista_Previa_Facture.zip

Logic includes preview of invoices with XML stame for Mexico tenants

#### InterastarCEMT.zip

Requiered update for stamping to work as requested by MX office

#### PXLotSerialNbrAttributeExtPkgCBIZ.zip

Update to include pedimento numbers in the XML stamping.

#### CBIZ.EDISoLineCustomFields[004].zip

Required to add the new preview button deployed in vista previa package above.

### End 2-3-2025

### 03-05-2025  

#### CBIZ.PL.EPR 

New customization package to deploy fields required for the EPR initative.  This
package will allow weights to be entered, in LBS for each of the fields that make
up the EPR reporting initative.

### End 03-05-2025

### Future Known Packages


### End -- Future Known Packages