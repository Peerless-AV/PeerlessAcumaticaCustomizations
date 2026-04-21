# CBIZSalesOrderSummaryView Customization Project

**Author:** CBIZ / Dan Zabinski  
**Creation Date:** 2026-04-21  
**Last Updated:** 2026-04-21 09:44 CDT  
**Customization Name:** CBIZSalesOrderSummaryView  

---

## 📜 Version History

| Date       | Author        | Version | Notes                                                                 |
|------------|---------------|---------|-----------------------------------------------------------------------|
| 2023-04-01 | CBIZ          | 1.0     | Initial creation                                                      |
| 2026-04-17 | Dan Zabinski  | 1.0.1   | Correcting bug in return logic                                        |
| 2026-04-21 | Dan Zabinski  | 1.1     | Investigating NewOrderTotal field accuracy for same-day fulfillment   |

---

## 📌 Purpose

This customization provides a SQL view (`CBIZSalesOrdersSummaryView`) that aggregates daily sales order activity from the `SOOrder` table, segmented by company. It is designed to power dashboards and reporting with key daily metrics including new order counts, open order totals, new order totals, and cancelled order totals.

- **Primary Use:** Daily sales operations dashboard and reporting
- **Data Source:** `SOOrder` table, filtered per company via `CompanyID`
- **Effective Date Logic:** Uses the prior business day as the reporting date; if yesterday was Sunday, rolls back to Friday

### v1.1 Scope

Update `NewOrderTotal` to ensure it reflects the full value of all orders placed on the effective date, regardless of fulfillment or invoicing status. Current implementation uses `CuryOpenOrderTotal`, which decreases as orders are shipped or invoiced — meaning same-day fulfillment causes underreporting of the day's new order value. The candidate replacement field is `CuryOrderTotal`, which represents the original full order value and is not affected by fulfillment activity.

---

## 🧾 Programming Specifics

- **Object Type:** SQL View  
- **View Name:** `CBIZSalesOrdersSummaryView`  
- **Database:** `2024R2DEV`  
- **Schema:** `dbo`  
- **Source Table:** `SOOrder`  

**Columns Produced:**

| Column                | Type          | Description                                                        |
|-----------------------|---------------|--------------------------------------------------------------------|
| `CompanyID`           | int           | Acumatica tenant company identifier                                |
| `ShipmentDate`        | datetime      | Effective reporting date (prior business day)                      |
| `NewOrderCount`       | int           | Count of orders created on the effective date                      |
| `OpenOrderTotal`      | decimal(19,4) | Sum of open order balances for all non-closed orders               |
| `NewOrderTotal`       | decimal(19,4) | Sum of order totals for orders created on the effective date       |
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

### v1.1 — NewOrderTotal Field Accuracy Investigation (2026-04-21)

**Symptom:** Following the v1.0.1 hotfix deployment, a spreadsheet-based validation of April 20, 2026 data revealed a ~$32K discrepancy between the calculated `NewOrderTotal` ($549,276.78) and the value returned by the deployed view ($516,810.36).

**Root Cause (Suspected):** `NewOrderTotal` currently uses `CuryOpenOrderTotal` as its source field. This field represents the remaining unbilled/unshipped balance on an order and decreases as fulfillment activity occurs. For orders that are placed and partially or fully shipped or invoiced on the same day, `CuryOpenOrderTotal` will already be reduced by the time the view executes, causing `NewOrderTotal` to understate the true value of orders entered on that day.

**Candidate Fix:** Replace `CuryOpenOrderTotal` with `CuryOrderTotal` in the `NewOrderTotal` subquery. `CuryOrderTotal` represents the original full order value and is not affected by fulfillment or invoicing activity, making it a more accurate measure of what was ordered on a given day. `OpenOrderTotal` would retain `CuryOpenOrderTotal` as that field remains the correct measure of outstanding open balance.

**Status:** Under investigation. Validation testing to be performed in `2024R2DEV` before any production change. Testing should include identification of orders placed and fulfilled on the same day to confirm the field behavior difference and quantify the real-world impact.

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
- `CuryOpenOrderTotal` and `CuryOrderTotal` serve different business purposes — open balance vs. original order value — and field selection should be intentional based on what each metric is meant to represent  

---