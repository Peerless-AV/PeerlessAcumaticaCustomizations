# 📦 Package Release Document (PRD #1)
**Date Created:** 2026-01-06  
**Last Updated:** 2026-01-20 16:12 CST  

### Acumatica 2024 R2 — Deployment Release Notes

---

## 🧭 1. Release Overview
- **Release Version Targeted:** Acumatica 2024 R2 (24.210.0019)  
- **Build Number:** 1-6-2026  
- **Deployment Date:** 2026-01-06  
- **Deployed By:** Dan Zale  
- **Related Work Items / Tickets:**  

---

## 🧱 2. Included Packages  
*(Each package must be deployed to DZ Personal, TestBTG, QA, and PROD. Track status per environment.)*

| # | Package Name                           | Notes                                                         | DZ Personal | TestBTG | QA | PROD |
|---|----------------------------------------|---------------------------------------------------------------|-------------|---------|----|------|
| 1 | RadleyWebServiceEndPoint2024R2[003]    |                                                               | [ ]         | [ ]     | [ ] | [ ]  |
| 2 | CBIZ.PL.EPR                            |                                                               | [ ]         | [ ]     | [ ] | [ ]  |
| 3 | PRLPOSSales                            |                                                               | [ ]         | [ ]     | [ ] | [ ]  |
| 4 | PRLUpdateReportMenu                    |                                                               | [ ]         | [ ]     | [ ] | [ ]  |
| 5 | fayeEndPoint                           | Created in DEV – Peerless‑AV and copied to BTG Management     | [ ]         | [ ]     | [ ] | [ ]  |
| 6 | CBIZ.UpdateItemAttributesTab[001]      | Fixes a bug introduced by a recent upgrade in Edge            | [ ]         | [ ]     | [ ] | [ ]  |

---

## 🔄 3. Changes in This Release

### 3.1 Functional Changes
- **3.1.1** — New POS Record Updating  
- **3.1.2** — Adding logic for EPR data requirements to Stock Item  

### 3.2 Technical Changes
- **3.2.1** — New Field on Faye End Point  
- **3.2.2** — New Field on Radley End Point  

### 3.3 Database / DAC Changes
- **3.3.1** — New DAC for POS functionality support records and standard Acumatica functionality  

### 3.4 UI / Screen Changes
- **3.4.1** — New screen for POS Record Updating  
- **3.4.2** — New tab on Stock Item for EPR functionality  

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

1. In 2024R2TESTBTG — Installed the baseline packages from the live site. This first pass is only the current production packages, no new ones.  
2. In 2024R2TESTBTG — The baseline packages without MX packages installed first. Site completed and deploy ran as expected.  
3. In 2024R2TESTBTG — Interestar and cloud info packages deployed to only MX and MX - Test. Deployment stopped like it always does, at starting website. See screenshot below.

---

## 🔍 6. Post-Deployment Validation

### 6.1 Functional Validation
-  

### 6.2 Technical Validation
- **2026-01-07 13:21 CST** — **DZ Reminder:** Double check new field from Laura under Radley API.

### 6.3 Data Validation
- **2026-01-07 12:37 CST** — For the FayeWebEndPoint, confirmed in DEV (Peerless‑AV) that the endpoint returns `usrStockLevel`. Local environment did not contain the field prior to deployment; after deploying the package locally, the field appeared as expected.

---

## ⚠️ 7. Issues, Deltas, or Anomalies

| # | Issue / Observation | Impact | Resolution / Next Steps |
|---|---------------------|--------|--------------------------|
| 1 |                     |        |                          |

---

## 📘 8. Documentation Updates Required

-  

---

## 🧠 9. Notes for Next Release

- **2026‑01‑06 18:08 CST** — GIT repo created, and packages collected for deployment. Next steps: deploy to a clean Local environment.  
- **2026‑01‑07 12:24 CST** — Added FayeEndPoint package, refreshing the endpoint from DEV to pass StockLevel field.  
- **2026‑01‑09 10:07 CST** — Freshworks documentation updated. Release created for packages.  
- **2026‑01‑16 21:27 CST** — Installed baseline setup on DZ laptop for Local DEV. First restore using the backup provided by Acumatica.  
- **2026‑01‑17 16:27 CST** — DZ Personal environment loaded using backup provided by Acumatica. Light baseline testing completed. TESTBTG machine prepared with backup and prerequisites.  
- **2026‑01‑18 09:12 CST** — Built SQL database on TESTBTG machine. Local machine build completed. ARM64 compile takes longer, but overall speed appears improved. Continued testing will confirm. ETA for TESTBTG readiness is Monday.  
- **2026‑01‑20 12:43 CST** — Built 2024R2TESTBTG environment and deployed current production packages for baseline testing. Turning over to team for review.

---

## 🗂️ 10. Attachments / Artifacts

### 📸 Screenshots
- Screenshot of compilation log and deployment halt at “Starting the website” (2026‑01‑20 22:04 CST)

### 📦 Exported Packages
-  

### 🧾 SQL Scripts
-  

### 📊 Logs
-  

### 🔍 Before/After Comparisons
-  