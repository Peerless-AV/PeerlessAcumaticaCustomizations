# CBIZSalesOrdersSummaryView — v1.1 Test Tracking

**Environment:** 2024R2DEV (localhost)  
**Test Objective:** Validate `NewOrderTotal` field change from `CuryOpenOrderTotal` to `CuryOrderTotal`  
**Tester:** Dan Zabinski  
**Started:** 2026-04-21  

---

## 🧪 Test Iterations

---

### Iteration 1 — Baseline (No Changes)

**Date:** 2026-04-21  
**Spreadsheet Downloaded:** 21 Apr 2026 10:01 AM CDT  
**View State:** v1.0.1 deployed (RC bug fix only, no v1.1 changes yet)  
**Shipment Date Reported:** 4/20/2026  
**Row Count in Export:** 56,979  

#### Results

| Column | Acumatica Screen | Spreadsheet Calc | Delta | Match? |
|---|---|---|---|---|
| NewOrderCount | 0 | 0 | 0 | ✅ |
| OpenOrderTotal | 7,315,069.52 | 7,355,668.56 | +40,599.04 | ⚠️ |
| NewOrderTotal | 0.00 | 0.00 | 0.00 | ✅ |
| CancelledOrderTotal | 0.00 | 0.00 | 0.00 | ✅ |

#### Notes

- Dev environment has no order activity on 4/20/2026, so NewOrderCount, NewOrderTotal, and CancelledOrderTotal are all zero — expected.
- OpenOrderTotal has a ~$40K delta between screen and spreadsheet. Likely attributable to field mapping (`Unbilled Amount` vs `CuryOpenOrderTotal`) and/or minor timing difference between export and view execution. This delta will be tracked across iterations to determine if it is consistent (mapping issue) or variable (timing issue).
- This iteration serves as the baseline — all future iterations will note changes relative to these numbers.

---

## 📋 Iteration Log Summary

| Iteration | Date | Change Applied | NewOrderCount | OpenOrderTotal | NewOrderTotal | CancelledOrderTotal |
|---|---|---|---|---|---|---|
| 1 — Baseline | 2026-04-21 | None | 0 ✅ | ⚠️ ~$40K delta | 0.00 ✅ | 0.00 ✅ |

---

## 🔬 What We Are Testing

| # | Hypothesis | Status |
|---|---|---|
| 1 | `CuryOrderTotal` is a more accurate field than `CuryOpenOrderTotal` for `NewOrderTotal` | 🔲 Pending |
| 2 | Same-day fulfilled orders cause `CuryOpenOrderTotal` to understate `NewOrderTotal` | 🔲 Pending |
| 3 | `OpenOrderTotal` delta (~$40K) is consistent across iterations, indicating a field mapping issue rather than timing | 🔲 Pending |

---

## 📝 Test Scenarios Planned

| # | Scenario | Purpose |
|---|---|---|
| A | Enter a new order in dev, do not fulfill — compare both fields | Confirm fields match when no fulfillment occurs |
| B | Enter a new order in dev, fulfill same day — compare both fields | Confirm `CuryOpenOrderTotal` drops while `CuryOrderTotal` holds |
| C | Deploy v1.1 change, re-run baseline | Confirm `NewOrderTotal` reflects full order value post-change |

---