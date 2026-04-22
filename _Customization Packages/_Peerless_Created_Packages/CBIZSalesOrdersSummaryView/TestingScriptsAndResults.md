# CBIZSalesOrdersSummaryView — v1.1 Test Tracking

**Environment:** 2024R2DEV (localhost)  
**Test Objective:** Validate `NewOrderTotal` field change from `CuryOpenOrderTotal` to `CuryOrderTotal`  
**Tester:** Dan Zabinski  
**Started:** 2026-04-21  

---

## 🔑 Key Findings (Pre-Test Investigation)

### Field Mapping — `Unbilled Amount` ≠ `CuryOpenOrderTotal`

During baseline setup, the following was confirmed through direct DB query:

| Source | Order Count | OpenOrderTotal |
|---|---|---|
| Acumatica Screen | 3,072 | $7,315,069.52 |
| DB Query (`SUM(CuryOpenOrderTotal)`) | 3,072 | $7,315,069.52 ✅ |
| Spreadsheet (`Unbilled Amount`) | 3,072 | $7,189,139.07 ⚠️ |

- **Order counts are identical** across all three sources — no missing records
- **`CuryOpenOrderTotal` ties exactly to the Acumatica screen** — confirmed as the correct field
- **`Unbilled Amount` in the export is a different field** — it does not map to `CuryOpenOrderTotal`
- The spreadsheet export does not contain `CuryOpenOrderTotal` as a column and therefore **cannot be used to validate `OpenOrderTotal`** directly

### Status Code Mapping (Confirmed via SSMS)

| UI Label | DB Status Code |
|---|---|
| On Hold | H |
| Open | N |
| Shipping | S |
| Back Order | B |
| Completed | C |
| Canceled | L |

- The view's `Status <> 'C'` correctly excludes **Completed** orders only
- **Canceled** orders (`'L'`) remain in the pool but carry `CuryOpenOrderTotal = 0`, contributing nothing to the total
- `Unbilled Amount` on cancelled orders is **not zeroed out** — partially shipped then cancelled orders retain their unshipped balance in this field, causing spreadsheet-based calcs to overstate `OpenOrderTotal`

### Validation Tool Conclusion

| Column | Spreadsheet Valid? | DB Query Required? |
|---|---|---|
| NewOrderCount | ✅ Yes | Optional |
| OpenOrderTotal | ❌ No — field mismatch | ✅ Yes |
| NewOrderTotal | ⚠️ Partial — pending v1.1 investigation | ✅ Preferred |
| CancelledOrderTotal | ✅ Yes — ties exactly | Optional |

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

| Column | Acumatica Screen | DB Query | Spreadsheet Calc | Match (Screen vs DB)? |
|---|---|---|---|---|
| NewOrderCount | 0 | — | 0 | ✅ |
| OpenOrderTotal | 7,315,069.52 | 7,315,069.52 | 7,189,139.07 | ✅ |
| NewOrderTotal | 0.00 | — | 0.00 | ✅ |
| CancelledOrderTotal | 0.00 | — | 0.00 | ✅ |

#### Notes

- Dev environment has no order activity on 4/20/2026 — NewOrderCount, NewOrderTotal, and CancelledOrderTotal are all zero, as expected
- `OpenOrderTotal` now confirmed tied via direct DB query — screen and DB match exactly
- Spreadsheet `OpenOrderTotal` understates by ~$126K due to `Unbilled Amount` ≠ `CuryOpenOrderTotal` — spreadsheet will not be used for `OpenOrderTotal` validation going forward
- This iteration serves as the baseline — all future iterations will note changes relative to these numbers

---

## 📋 Iteration Log Summary

| Iteration | Date | Change Applied | NewOrderCount | OpenOrderTotal (Screen vs DB) | NewOrderTotal | CancelledOrderTotal |
|---|---|---|---|---|---|---|
| 1 — Baseline | 2026-04-21 | None | 0 ✅ | $7,315,069.52 ✅ | 0.00 ✅ | 0.00 ✅ |

---

## 🔬 What We Are Testing

| # | Hypothesis | Status |
|---|---|---|
| 1 | `CuryOrderTotal` is a more accurate field than `CuryOpenOrderTotal` for `NewOrderTotal` | 🔲 Pending |
| 2 | Same-day fulfilled orders cause `CuryOpenOrderTotal` to understate `NewOrderTotal` | 🔲 Pending |
| 3 | `OpenOrderTotal` delta was a field mapping issue, not timing | ✅ Confirmed — `Unbilled Amount` ≠ `CuryOpenOrderTotal` |

---

## 📝 Test Scenarios Planned

| # | Scenario | Purpose |
|---|---|---|
| A | Enter a new order in dev, do not fulfill — compare `CuryOpenOrderTotal` vs `CuryOrderTotal` | Confirm fields match when no fulfillment occurs |
| B | Enter a new order in dev, fulfill same day — compare `CuryOpenOrderTotal` vs `CuryOrderTotal` | Confirm `CuryOpenOrderTotal` drops while `CuryOrderTotal` holds |
| C | Deploy v1.1 change, re-run baseline | Confirm `NewOrderTotal` reflects full order value post-change |

---

## 🛠️ Validation Queries

### OpenOrderTotal — DB Validation
```sql
SELECT 
    COUNT(*) AS OrderCount,
    SUM(CuryOpenOrderTotal) AS TotalCuryOpenOrderTotal
FROM SOOrder
WHERE CompanyID = 10
AND Status <> 'C'
AND OrderType NOT IN ('QT', 'RC', 'BL')
```

### NewOrderTotal — DB Validation (current vs candidate field)
```sql
SELECT 
    COUNT(*) AS OrderCount,
    SUM(CuryOpenOrderTotal) AS CurrentNewOrderTotal,
    SUM(CuryOrderTotal) AS CandidateNewOrderTotal
FROM SOOrder
WHERE CompanyID = 10
AND CAST(CreatedDateTime AS date) = CAST(DATEADD(day, -1, GETDATE()) AS date)
AND OrderType NOT IN ('QT', 'RC', 'BL')
```

### CancelledOrderTotal — DB Validation
```sql
SELECT 
    COUNT(*) AS OrderCount,
    SUM(CuryOrderTotal) AS TotalCancelledOrderTotal
FROM SOOrder
WHERE CompanyID = 10
AND CAST(LastModifiedDateTime AS date) = CAST(DATEADD(day, -1, GETDATE()) AS date)
AND OrderType NOT IN ('QT', 'RC', 'BL')
AND Cancelled = 1
```

---