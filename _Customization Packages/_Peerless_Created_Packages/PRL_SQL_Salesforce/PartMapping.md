# Product Field Mapping — Salesforce ↔ Acumatica
**Created:** 2026-05-14  
**Updated:** 2026-05-15  
**Author:** BTG IT Team — Peerless AV  
**Project:** Acumatica To Salesforce Sync  

---

## Instructions
Fill in the **Acumatica Field / Source** column with the corresponding Acumatica field name or SQL expression.  
Use the **Notes** column for transform logic, flags, or questions.  
Mark fields as `SKIP` in Acumatica column if they should not be synced.

---

## Section 1 — Core / Standard Fields

> Sample row: `LEDUNVS-4X3` (DVLED Universal Wall Mount)

| Salesforce Field         | Sample Data                  | Acumatica Field / Source | Notes                          |
|--------------------------|------------------------------|--------------------------|--------------------------------|
| `Id`                     | `01tPW00000IHUnJYAX`         | SKIP                               | SFDC internal ID — do not sync from Acu |
| `Name`                   | `LEDUNVS-4X3`                | `InventoryItem.InventoryCD`        | RTRIM applied                   |
| `ProductCode`            | `LEDUNVS-4X3`                | `InventoryItem.InventoryCD`        | RTRIM applied                   |
| `Description`            | `4X3 Universal wall mount for latching dvLED displays up to 610 X 343 mm` | `InventoryItem.Descr` | US tenant — maps to USDescriptionc as well |
| `IsActive`               | `True`                       | `InventoryItem.ItemStatus`         | `True` if AC, NP, or NR — else `False` |
| `Family`                 | *(empty)*                    |                                    | Pending — source TBD            |
| `StockKeepingUnit`       | *(empty)*                    | `InventoryItem.InventoryCD`        | Same as Name / ProductCode      |
| `Type`                   | *(empty)*                    | SKIP                               | No Acumatica equivalent         |
| `QuantityUnitOfMeasure`  | *(empty)*                    | `InventoryItem.SalesUnit`          | e.g. EA                         |
| `CurrencyIsoCode`        | `USD`                        | SKIP                               | Managed by SFDC                 |

---

## Section 2 — Multi-Tenant Fields (US / UK / MX)

These are the cross-tenant joined fields. Acumatica source will be per-tenant query.

> Sample row: `LEDUNVS-4X3` (DVLED Universal Wall Mount)

| Salesforce Field         | Sample Data                  | Acumatica Field / Source (US) | Acumatica Field / Source (UK) | Acumatica Field / Source (MX) | Notes |
|--------------------------|------------------------------|-------------------------------|-------------------------------|-------------------------------|-------|
| `US_Description__c`      | `LAPTOP TRAY AND ARM...`     | `InventoryItem.Descr`         | —                             | —                             | US tenant row  |
| `US_Product_Family__c`   | *(empty)*                    |                               | —                             | —                             | Pending        |
| `US_Price_Group_Name__c` | `DVLED`                      |                               | —                             | —                             | Pending        |
| `UK_Description__c`      | `LAPTOP TRAY AND ARM...`     | —                             | `InventoryItem.Descr`         | —                             | UK tenant row  |
| `UK_Product_Family__c`   | *(empty)*                    | —                             |                               | —                             | Pending        |
| `UK_Price_Group_Name__c` | *(empty)*                    | —                             |                               | —                             | Pending        |
| `UK_Price_Group__c`      | *(empty)*                    | —                             |                               | —                             | SFDC lookup ID |
| `UK_Sub_Categories__c`   | *(empty)*                    | —                             |                               | —                             | Pending        |
| `MX_Description__c`      | `LAPTOP TRAY AND ARM...`     | —                             | —                             | `InventoryItem.Descr`         | MX tenant row  |
| `MX_Product_Family__c`   | *(empty)*                    | —                             | —                             |                               | Pending        |

---

## Section 3 — Custom / Peerless Fields

> Sample row: `LEDUNVS-4X3` (DVLED Universal Wall Mount)

| Salesforce Field                | Sample Data              | Acumatica Field / Source | Notes                          |
|---------------------------------|--------------------------|--------------------------|--------------------------------|
| `Part_Number__c`                | `LEDUNVS-4X3`            | `InventoryItem.InventoryCD`      | RTRIM applied — same as Name/ProductCode |
| `Do_Not_Use__c`                 | `False`                  |                                  |                                |
| `ACU_Item_Status__c`            | *(empty)*                | `InventoryItem.ItemStatus`       | Direct map — AC, NS, NP, NR, IN, DE |
| `ACU_PMPLCM__c`                 | *(empty)*                |                                  | Attribute join TBD             |
| `ACU_Authorization_Required__c` | `False`                  | `InventoryItem.UsrAuthorization` | `1` = True, NULL or `0` = False |
| `Sales_Part_Status__c`          | `No Request`             | `InventoryItem.ItemStatus`       | Direct map — no interpretation |
| `Special_Note__c`               | *(empty)*                |                                  |                                |
| `MOQ__c`                        | *(empty)*                |                                  | Minimum Order Quantity — TBD   |
| `Price_Group__c`                | `a1T2K000003aiHZUAY`     |                                  | SFDC lookup ID — TBD           |
| `Category__c`                   | `DVLED`                  | `INItemClass.ItemClassCD`        | CASE translation via join — US first, fallback UK then MX. Values: DVLED, LED, MOUNT, KIOSK, TV, NULL |
| `ID_18_Ch__c`                   | `01tPW00000IHUnJYAX`     | SKIP                             | 18-char SFDC ID — no Acu equivalent |

---

## Section 4 — System / Audit Fields (likely SKIP)

| Salesforce Field       | Sample Data                        | Sync? | Notes                              |
|------------------------|------------------------------------|-------|------------------------------------|
| `CreatedDate`          | `2026-04-20T16:15:18.000+0000`     | SKIP  | Managed by SFDC                    |
| `CreatedById`          | `005PW00000gcFXKYA2`               | SKIP  | Managed by SFDC                    |
| `LastModifiedDate`     | `2026-04-20T16:15:18.000+0000`     | SKIP  | Managed by SFDC                    |
| `LastModifiedById`     | `005PW00000gcFXKYA2`               | SKIP  | Managed by SFDC                    |
| `SystemModstamp`       | `2026-04-20T18:49:38.000+0000`     | SKIP  | Managed by SFDC                    |
| `LastViewedDate`       | *(empty)*                          | SKIP  | Managed by SFDC                    |
| `LastReferencedDate`   | *(empty)*                          | SKIP  | Managed by SFDC                    |
| `IsDeleted`            | `False`                            | SKIP  | Managed by SFDC                    |
| `IsArchived`           | `False`                            | SKIP  | Managed by SFDC                    |
| `ExternalDataSourceId` | *(empty)*                          | SKIP  |                                    |
| `ExternalId`           | *(empty)*                          | SKIP  |                                    |
| `DisplayUrl`           | *(empty)*                          | SKIP  |                                    |
| `ConfigureDuringSale`  | `Allowed`                          | SKIP  |                                    |
| `SpecificationType`    | *(empty)*                          | SKIP  |                                    |

---

## Section 5 — CPQ / SBQQ Fields (SKIP unless told otherwise)

All `SBQQ__*` fields are Salesforce CPQ (Steelbrick) quote configuration fields.  
These are managed entirely within Salesforce and have no Acumatica equivalent.

| Salesforce Field                        | Sync? |
|-----------------------------------------|-------|
| `SBQQ__AssetAmendmentBehavior__c`       | SKIP  |
| `SBQQ__AssetConversion__c`              | SKIP  |
| `SBQQ__BatchQuantity__c`                | SKIP  |
| `SBQQ__BillingFrequency__c`             | SKIP  |
| `SBQQ__BillingType__c`                  | SKIP  |
| `SBQQ__BlockPricingField__c`            | SKIP  |
| `SBQQ__ChargeType__c`                   | SKIP  |
| `SBQQ__Component__c`                    | SKIP  |
| `SBQQ__CompoundDiscountRate__c`         | SKIP  |
| `SBQQ__ConfigurationEvent__c`           | SKIP  |
| `SBQQ__ConfigurationFieldSet__c`        | SKIP  |
| `SBQQ__ConfigurationFields__c`          | SKIP  |
| `SBQQ__ConfigurationFormTitle__c`       | SKIP  |
| `SBQQ__ConfigurationType__c`            | SKIP  |
| `SBQQ__ConfigurationValidator__c`       | SKIP  |
| `SBQQ__ConfiguredCodePattern__c`        | SKIP  |
| `SBQQ__ConfiguredDescriptionPattern__c` | SKIP  |
| `SBQQ__CostEditable__c`                 | SKIP  |
| `SBQQ__CostSchedule__c`                 | SKIP  |
| `SBQQ__CustomConfigurationPage__c`      | SKIP  |
| `SBQQ__CustomConfigurationRequired__c`  | SKIP  |
| `SBQQ__CustomerCommunityAvailability__c`| SKIP  |
| `SBQQ__DefaultPricingTable__c`          | SKIP  |
| `SBQQ__DefaultQuantity__c`              | SKIP  |
| `SBQQ__DescriptionLocked__c`            | SKIP  |
| `SBQQ__DiscountCategory__c`             | SKIP  |
| `SBQQ__DiscountSchedule__c`             | SKIP  |
| `SBQQ__DynamicPricingConstraint__c`     | SKIP  |
| `SBQQ__ExcludeFromMaintenance__c`       | SKIP  |
| `SBQQ__ExcludeFromOpportunity__c`       | SKIP  |
| `SBQQ__ExternallyConfigurable__c`       | SKIP  |
| `SBQQ__GenerateContractedPrice__c`      | SKIP  |
| `SBQQ__HasConfigurationAttributes__c`   | SKIP  |
| `SBQQ__HasConsumptionSchedule__c`       | SKIP  |
| `SBQQ__Hidden__c`                       | SKIP  |
| `SBQQ__HidePriceInSearchResults__c`     | SKIP  |
| `SBQQ__IncludeInMaintenance__c`         | SKIP  |
| `SBQQ__NewQuoteGroup__c`                | SKIP  |
| `SBQQ__NonDiscountable__c`              | SKIP  |
| `SBQQ__NonPartnerDiscountable__c`       | SKIP  |
| `SBQQ__OptionLayout__c`                 | SKIP  |
| `SBQQ__OptionSelectionMethod__c`        | SKIP  |
| `SBQQ__Optional__c`                     | SKIP  |
| `SBQQ__PriceEditable__c`                | SKIP  |
| `SBQQ__PricingMethodEditable__c`        | SKIP  |
| `SBQQ__PricingMethod__c`                | SKIP  |
| `SBQQ__ProductPictureID__c`             | SKIP  |
| `SBQQ__QuantityEditable__c`             | SKIP  |
| `SBQQ__QuantityScale__c`                | SKIP  |
| `SBQQ__ReconfigurationDisabled__c`      | SKIP  |
| `SBQQ__RenewalProduct__c`               | SKIP  |
| `SBQQ__SortOrder__c`                    | SKIP  |
| `SBQQ__Specifications__c`               | SKIP  |
| `SBQQ__SubscriptionBase__c`             | SKIP  |
| `SBQQ__SubscriptionCategory__c`         | SKIP  |
| `SBQQ__SubscriptionPercent__c`          | SKIP  |
| `SBQQ__SubscriptionPricing__c`          | SKIP  |
| `SBQQ__SubscriptionTarget__c`           | SKIP  |
| `SBQQ__SubscriptionTerm__c`             | SKIP  |
| `SBQQ__SubscriptionType__c`             | SKIP  |
| `SBQQ__TaxCode__c`                      | SKIP  |
| `SBQQ__Taxable__c`                      | SKIP  |
| `SBQQ__TermDiscountLevel__c`            | SKIP  |
| `SBQQ__TermDiscountSchedule__c`         | SKIP  |
| `SBQQ__UpgradeCredit__c`                | SKIP  |
| `SBQQ__UpgradeRatio__c`                 | SKIP  |
| `SBQQ__UpgradeSource__c`                | SKIP  |
| `SBQQ__UpgradeTarget__c`                | SKIP  |

---

## Change Log

| Date       | Author   | Change                        |
|------------|----------|-------------------------------|
| 2026-05-14 | BTG IT   | Initial draft — SFDC fields catalogued, Acumatica columns pending |
| 2026-05-15 | BTG IT   | Confirmed: IsActive, ACUItemStatusc, SalesPartStatusc, ACUAuthorizationRequiredc |
| 2026-05-15 | BTG IT   | Section 1 filled in — Name, ProductCode, Description, SKU, QuantityUnitOfMeasure confirmed; Type and CurrencyIsoCode marked SKIP |
| 2026-05-15 | BTG IT   | Section 2 descriptions confirmed via three-tenant pivot view |
| 2026-05-15 | BTG IT   | Category__c confirmed — INItemClass join with CASE translation; Part_Number__c confirmed; ID_18_Ch__c marked SKIP |