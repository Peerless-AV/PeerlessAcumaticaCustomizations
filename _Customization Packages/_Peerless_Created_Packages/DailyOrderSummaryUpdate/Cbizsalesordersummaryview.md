# CBIZSalesOrderSummaryView Customization Project

**Author:** CBIZ / Dan Zabinski  
**Creation Date:** 2023-04-01  
**Last Updated:** 2026-04-17 09:07 CDT  
**Customization Name:** CBIZSalesOrderSummaryView  

---

## 📜 Version History

| Date       | Author        | Version | Notes                                      |
|------------|---------------|---------|--------------------------------------------|
| 2023-04-01 | CBIZ          | 1.0     | Initial creation                           |
| 2026-04-17 | Dan Zabinski  | 1.0.1   | Correcting bug in return logic             |

---

## 📌 Purpose

This customization provides a SQL view (`CBIZSalesOrdersSummaryView`) that aggregates daily sales order activity from the `SOOrder` table, segmented by company. It is designed to power dashboards and reporting with key daily metrics including new order counts, open order totals, new order totals, and cancelled order totals.

- **Primary Use:** Daily sales operations dashboard and reporting
- **Data Source:** `SOOrder` table, filtered per company via `CompanyID`
- **Effective Date Logic:** Uses the prior business day as the reporting date; if yesterday was Sunday, rolls back to Friday

---

## 🧾 Programming Specifics

- **Object Type:** SQL View  
- **View Name:** `CBIZSalesOrdersSummaryView`  
- **Database:** `2024R2DEV`  
- **Schema:** `dbo`  
- **Source Table:** `SOOrder`  

**Columns Produced:**

| Column             | Type              | Description                                                        |
|--------------------|-------------------|--------------------------------------------------------------------|
| `CompanyID`        | int               | Acumatica tenant company identifier                                |
| `ShipmentDate`     | datetime          | Effective reporting date (prior business day)                      |
| `NewOrderCount`    | int               | Count of orders created on the effective date                      |
| `OpenOrderTotal`   | decimal(19,4)     | Sum of open order balances for all non-closed orders               |
| `NewOrderTotal`    | decimal(19,4)     | Sum of open order balances for orders created on the effective date |
| `CancelledOrderTotal` | decimal(19,4) | Sum of order totals for orders cancelled on the effective date     |

---

## 🔧 Technical Notes

- **Effective Date Calculation:**  
  - If yesterday (`DATEADD(day, -1, GETDATE())`) falls on Sunday, the effective date is set to Friday (`DATEADD(day, -3, GETDATE())`)  
  - Otherwise, effective date = yesterday  

- **Excluded Order Types (applied consistently across all calculations):**  
  - `QT` — Quotes: not revenue-bearing orders  
  - `RC` — Returns: credits against revenue, not new sales  
  - `BL` — Blanket Orders: framework orders without direct monetary value  
  - Exclusion is enforced via `OrderType NOT IN ('QT', 'RC', 'BL')` on all subqueries  

- **Status Filtering:**  
  - `OpenOrderTotal` excludes orders with `Status = 'C'` (Closed/Cancelled)  
  - `CancelledOrderTotal` targets orders where `Cancelled = 1` and `Status <> 'C'`  

- **CompanyID Scoping:**  
  - All subqueries are correlated to the outer `SOOrder` row via `CompanyID` to support multi-tenant Acumatica environments  

---

## 🐛 Bug History

### v1.0.1 — Return Order Logic Correction (2026-04-17)

**Symptom:** `NewOrderTotal` returned a negative value for the first time since deployment.

**Root Cause:** The original view subtracted RC (Return) order totals in a second subquery leg across both `OpenOrderTotal` and `NewOrderTotal`. However, RC orders were already excluded from the first subquery leg via `OrderType <> 'RC'`. This resulted in RC values being subtracted without ever having been added — effectively double-removing them. For three years, daily RC values were small enough (median ~$229) that the result remained positive and the bug went unnoticed. On 2026-04-16, RC001908 (Bluestar DBA United Radio, $249,905.52) exceeded the day's new order total (~$185K), causing the first observed negative result.

**Fix Applied:** Removed the RC subtraction subquery from both `OpenOrderTotal` and `NewOrderTotal`. Updated `NewOrderCount` to also exclude `RC` and `BL` for consistency. All exclusions are now handled uniformly via `OrderType NOT IN ('QT', 'RC', 'BL')` on the primary subquery only.

---

## 📊 Integration Points

- **Consuming Reports/Dashboards:** Daily sales operations reporting; company-level shipment summary  
- **Generic Inquiries:** Any GI or report referencing this view for open order pipeline visibility  

---

## 🧱 Future Considerations

- Consider adding `BL` (Blanket Order) handling review if partial releases against blankets should contribute to `OpenOrderTotal` in the future  
- Consider parameterizing the effective date logic if on-demand historical date ranges are needed  
- Monitor large RC orders as a leading indicator for anomalous reporting days  

---

## 🧠 Reflections / Adjustments

- The two-subquery subtraction pattern is a common anti-pattern when the exclusion is already handled upstream — worth auditing other views in the package for the same structure  
- The bug being latent for ~3 years underscores the value of data-range regression testing on financial views, particularly for edge cases involving large single-transaction outliers  
- Consistent `NOT IN ('QT', 'RC', 'BL')` rule should be treated as a standard for all `SOOrder`-based views in this customization package  

---