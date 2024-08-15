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

### Aug-2024-Package-A Deployment

8-15-2024 - Started new deployment group.  This group will include updating documentation on new folders for delivered GI's, Import / Export Scenarios and report updates.  Buidling folder structure for these objects based on production tenants.

#### CBIZ.PL.OBSReport[002]

Initial delivery of the OBS report requested by Stephen K.  8/15/2024, this packaged failed deployment in previous group due
to compatibility issue with AIS cost package.  

### End Aug-2024-Package-A