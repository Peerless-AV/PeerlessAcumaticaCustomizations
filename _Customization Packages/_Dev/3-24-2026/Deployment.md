# 📦 Package Release Document (PRD #2)
**Date Created:** 2026-03-26  
**Last Updated:** 2026-04-06 12:03 CDT

### Acumatica 2024 R2 — Deployment Release Notes

---

## 🧭 1. Release Overview
- **Release Version Targeted:** Acumatica 2024 R2 (24.210.0019)
- **Build Number:** 3-26-2026
- **Deployment Date:**
- **Deployed By:**
- **Related Work Items / Tickets:**

---

## 🧱 2. Included Packages
*(All packages now marked deployed in PROD)*

| # | Package Name                         | Notes                                           | DZ Personal | TestBTG | QA | PROD |
|---|--------------------------------------|-------------------------------------------------|-------------|---------|----|------|
| 1 | CBIZ.ShippingInst[011]               | Replaced by 12                                  |             |         |    |      |
| 2 | InterastarDD                         | Received from Interastar to correct reports     | ✔️          | ✔️      |    |      |
| 3 | CloudInfoFE                          | New version of Cloud Info                       | ✔️          | ✔️      |    |      |
| 4 | CBIZ.ShippingInst[012]               |                                                 |             | ✔️      |    |      |
| 5 | CBIZ.EDISoLineCustomFields           |                                                 |             |         |    |      |
| 6 | SOAttributesCbiz[008]                |                                                 |             |         |    |      |
| 7 | InterastarCEMT v.242.2026.0325.0     |                                                 |             |         |    |      |
| 8 | InterastarVistapreviaFactura         | This package to be removed                      |             |         |    |      |
| 9 | InterastarSEARS2 v.231.2025.0210.0   | Package being removed                           |             |         |    |      |

---

## 🔄 3. Changes in This Release

### 3.1 Functional Changes
- **3.1.1** — Package **Shipping Instruction 12** contains a function which is critical for the new commercial invoice functionality. Once deployed, that project/report can be updated, tested, and confirmed working.
- **3.1.2** — Interestar added functionality into their base packages, negating the need for the **Interastar SEARS** package and the **Factora** package.

### 3.2 Technical Changes
- **3.2.1** —
- **3.2.2** —

### 3.3 Database / DAC Changes
- **3.3.1** —

### 3.4 UI / Screen Changes
- **3.4.1** —
- **3.4.2** —

### 3.5 Integration Changes
-

---

## 🧪 4. Pre-Deployment Checklist

- [ ] All packages compiled successfully
- [ ] No schema conflicts
- [ ] No missing DAC fields
- [ ] Import scenarios validated
- [ ] Generic inquiries validated
- [ ] Dashboards validated
- [ ] Webhooks / API endpoints tested
- [ ] Backup taken (if PROD)

---

## 🚀 5. Deployment Steps Executed

1.
2.
3.
4.
5. **2026-03-26 20:41 CDT** — New Interastar package **DD** arrived with level **70**. Adjusted back to **20010**.
6. **2026-03-26 20:55 CDT** — Publish for all tenants finished. Results same as previous deployment, where **InterestarDIOT** and remaining packages halt at “Starting website.” Deployment finished and turned over for testing (**TESTBTG**).

---

## 🔍 6. Post-Deployment Validation

### 6.1 Functional Validation
-

### 6.2 Technical Validation
-

### 6.3 Data Validation
-

---

## ⚠️ 7. Issues, Deltas, or Anomalies

| # | Issue / Observation | Impact | Resolution / Next Steps |
|---|---------------------|--------|--------------------------|
| 1 |                     |        |                          |
| 2 |                     |        |                          |

---

## 📘 8. Documentation Updates Required

-

---

## 🧠 9. Notes for Next Release

- **2026-03-26 20:27 CDT** — PRD2 created, GitHub branch **3-26-2026** created, and packages moved to **DEV** folder for processing. Updating **TESTBTG**. TESTBTG to be reviewed the morning of **3-27** and install to move forward.
- **2026-03-28 09:14 CDT** — Paul in process with deployment to **TESTBTG**. Regroup after **US tenants** complete.
- **2026-04-06 12:03 CDT** — Next deployment, according to change control, two packages to be removed. Add a note to the comments to remove **Factora** and **SEARS**. Ensure they do **not** get checked when packages are added.
- **2026-04-06 12:03 CDT** — Deployment order for next cycle:  
  1. Deploy **all non-CloudInfo and non-Inter** packages to **all tenants** first.  
  2. Deploy **CloudInfo** and **CEMT** to **MX**.  
  3. Deploy **DD** to **MX**.  
  4. Deploy remaining **Interastar** packages (excluding the ones being removed).

---

## 🗂️ 10. Attachments / Artifacts

### Screenshots
-

### Exported Packages
-

### SQL Scripts
-

### Logs
-

### Before/After Comparisons
-