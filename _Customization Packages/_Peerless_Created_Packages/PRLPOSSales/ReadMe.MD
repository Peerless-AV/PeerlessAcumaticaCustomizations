# PRL_POS_System Customization Project

**Author:** Dan Zabinski  
**Creation Date:** 2025-11-11  
**Last Updated:** 2025-11-19 14:02 CST  
**Customization Name:** PRL_POS_Sales  

---

## 📜 Version History

| Date       | Author       | Version | Notes                                                  |
|------------|--------------|---------|--------------------------------------------------------|
| 2025-11-11 | Dan Zabinski | 1.0     | Initial scaffold: DAC, schema, indexes, doc           |
| 2025-11-11 | Dan Zabinski | 1.1     | Added Task Index aligned to planner protocol          |
| 2025-11-11 | Dan Zabinski | 1.01    | New Screen Required for import scenario               |
| 2025-11-13 | Dan Zabinski | 1.2     | DAC published cleanly, schema verified, index script regenerated |
| 2025-11-19 | Dan Zabinski | 1.3     | Screen `PRL301000` built and published; cleanup protocol verified |

---

## 📌 Purpose

The goal of this customization is to integrate Monthly POS results from the sales automation program into Acumatica for year-over-year tracking and dashboarding.

- **Phase 1:** Import results from Excel files into Acumatica  
- **Phase 2:** Direct import from the POS database  
- **Outcome:** Store normalized POS data for reporting, Generic Inquiries, and dashboards

---

## 🧾 Programming Specifics

- **New DAC Script Under Code:** `PRLSales`  
- **Database Schema Created:** `PRL_POS_Sales`  
- **Indexes Deployed for Searching:**  
  - `IX_PRL_POS_Sales_Customer_SaleDate`  
  - `IX_PRL_POS_Sales_PiiPartNumber`  
  - `IX_PRL_POS_Sales_PeriodDate`  
- **New Screen:**  
  - **Screen ID:** `DZ.00.00.01`  
  - **Screen Name:** `POS Entry`  
  - **Graph:** `PRLSalesEntry` (bound to DAC `PRLSales`)  

---

## 🔧 Technical Notes

- **DAC Attributes:**  
  - `[PXCacheName("POS Sales")]` applied for UI-friendly naming  
  - Primary key defined with `[PXDBIdentity(IsKey = true)]`  
  - Standard audit fields (`CreatedByID`, `LastModifiedByID`, `tstamp`) included  

- **Database Script Priority:**  
  - Schema creation script set to **Priority 1**  
  - Index creation scripts set to **Priority 2+** to ensure table exists before indexes are applied  

- **Publishing Protocol:**  
  - Use **Publish with Cleanup** when deploying new DACs or schema changes to ensure all scripts re-run  
  - Index scripts wrapped with `IF NOT EXISTS` for idempotency  

---

## 📊 Integration Points

- **Import Scenario:** Planned `PRL_POSLoadImport` for Excel-based ingestion  
- **Generic Inquiry:** Planned `POS_Sales_GI` for reporting by Customer, Part, Period  
- **Dashboard:** Optional `POS_SalesDashboard` for year-over-year visualization  

---

## 🧱 Future Phases

- **Phase 2:** Direct POS database integration  
- **Phase 3:** Dashboard enhancements (trend charts, geographic distribution)  
- **Phase 4:** Governance-ready audit trail for distributor data  

---

## 🧠 Reflections / Adjustments

- DAC-first approach ensures Acumatica-native integration  
- Index strategy checkpointed for reproducibility and performance tuning  
- Documentation scaffolded in Markdown for easy updates and printable outputs  
- `CompanyID` injection conflict resolved by removing `[PXDefault(typeof(AccessInfo.CompanyID))]`  
- Verified that DAC regeneration requires schema sync, not just table drop  

---

# 📋 Task Index (Planner Protocol Aligned)

## 🔧 Priority Tasks

| #  | Task Description                                         | Status   | Priority | Notes                                      |
|----|----------------------------------------------------------|----------|----------|--------------------------------------------|
| 1  | Create DAC `PRLSales` and publish schema `PRL_POS_Sales`| ✅ Done  | High     | Published successfully (Phase 1 start)     |
| 2  | Deploy indexes (`Customer+SaleDate`, `PiiPartNumber`, `PeriodDate`) | ✅ Done | High | Wrapped with `IF NOT EXISTS`               |
| 11 | Build New Screen `PRL301000` with Graph `PRLSalesEntry` | ✅ Done  | High     | Required for Import Scenario `PRL_POS_Import` |

## 🗂️ Secondary Tasks

| # | Task Description                          | Status   | Priority | Notes                        |
|---|-------------------------------------------|----------|----------|------------------------------|
| 3 | Build Import Scenario `PRL_POSLoadImport` | ⏳ Pending | Medium   | Excel-based ingestion        |
| 4 | Create Generic Inquiry `POS_Sales_GI`     | ⏳ Pending | Medium   | Reporting by Customer, Part, Period |

## 🧪 Experiments / Explorations

| # | Task Description                      | Status   | Priority | Notes                        |
|---|---------------------------------------|----------|----------|------------------------------|
| 5 | Test Publish with Cleanup protocol    | ✅ Done  | Medium   | Confirm reproducibility      |

## 🧱 Infrastructure / Ops

| # | Task Description                                      | Status   | Priority | Notes                                |
|---|-------------------------------------------------------|----------|----------|--------------------------------------|
| 6 | Set Database Script Priority (Schema=1, Indexes=2+)   | ✅ Done  | High     | Ensures correct execution order      |
| 9 | Plan Phase 2 direct POS DB integration                | ⏳ Pending | Medium   | Future milestone                     |

## 🧾 Documentation / Artifacts

| # | Task Description                          | Status   | Priority | Notes                        |
|---|-------------------------------------------|----------|----------|------------------------------|
| 7 | Scaffold Markdown project file            | ✅ Done  | High     | Living document for updates  |
| 10| Add governance-ready audit trail notes    | ⏳ Pending | Low      | For Phase 4                  |

## 🧠 Reflections / Adjustments

| # | Task Description                          | Status   | Priority | Notes                        |
|---|-------------------------------------------|----------|----------|------------------------------|
| 8 | Review DAC-first vs. SQL script approach  | ✅ Done  | Medium   | DAC-first confirmed as best practice |

---