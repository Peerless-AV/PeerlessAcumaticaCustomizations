# 📦 Package Release Document (PRD #1)
**Date Created:** 2026-01-06  
**Last Updated:** 2026-01-09 10:12 CST  

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
*(Each package must be deployed to Local, DEV, and PROD. Track status per environment.)*

| # | Package Name                           | Notes                                                         | Local | DEV | PROD |
|---|----------------------------------------|---------------------------------------------------------------|-------|-----|------|
| 1 | RadleyWebServiceEndPoint2024R2[003]    |                                                               | [ ]   | [ ] | [ ]  |
| 2 | CBIZ.PL.EPR                            |                                                               | [ ]   | [ ] | [ ]  |
| 3 | PRLPOSSales                            |                                                               | [ ]   | [ ] | [ ]  |
| 4 | PRLUpdateReportMenu                    |                                                               | [ ]   | [ ] | [ ]  |
| 5 | fayeEndPoint                           | Created in DEV – Peerless-AV and copied to BTG Management     | [ ]   | [ ] | [ ]  |

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

1.  
2.  
3.  

---

## 🔍 6. Post-Deployment Validation

### 6.1 Functional Validation
-  

### 6.2 Technical Validation
- **2026-01-07 13:21 CST** — **DZ Reminder:** Double check new field from Laura under Radley API.

### 6.3 Data Validation
- **2026-01-07 12:37 CST** — For the FayeWebEndPoint, I have confirmed in DEV (Peerless‑AV) that the endpoint is returning the field `usrStockLevel`. I also confirmed that in my Local environment, the field was not present prior to deployment of the package. After deploying the package locally as planned, the field appeared as expected.

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

- **2026-01-06 18:08 CST** — GIT repo created, and packages collected for deployment. Next steps: deploy to a clean Local environment.  
- **2026-01-07 12:24 CST** — Added FayeEndPoint package, refreshing the endpoint from DEV to pass StockLevel field.  
- **2026-01-09 10:07 CST** — Freshworks documentation updated. Release created for packages, available at:  
  https://peerless-av.freshservice.com/a/releases/9?current_tab=details

---

## 🗂️ 10. Attachments / Artifacts

- Screenshots  
- Logs  
- Exported packages  
- SQL scripts  
- Before/after comparisons  