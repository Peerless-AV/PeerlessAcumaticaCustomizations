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

## Package Documentation Section

### Aug 2024 Package Deployment

#### TSSOProfitMarginCalculation[005].zip

Fix / correction to the logic that calculates the margin on a sales order.  Fixes issue in UK, as well as ensure both standard cost items and FIFO costs items calculate properly in US tenant.

#### CBIZ.PL.LocationSort.zip

This customization sets the default sort order on the look up screens for location numbers, sorting by qty avaialble decending on all screens.

#### CBIZ.PL.OBSReport[002]

Initial delivery of the OBS report requested by Stephen K.  

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