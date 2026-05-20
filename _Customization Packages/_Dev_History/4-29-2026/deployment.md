# 📦 Package Release Document (PRD #4)
**Date Created:** 2026-05-04  
**Last Updated:** 2026-05-20 10:03 CDT

### Acumatica 2024 R2 — Deployment Release Notes

---

## 1. Release Overview
- **Release Version Targeted:** Acumatica 2024 R2 (24.210.0019)
- **Build Number:**  
- **Deployment Date:**  
- **Deployed By:**  
- **Related Work Items / Tickets:**  

---

## 2. Included Packages

| #  | Package Name                         | Notes | DZ Personal | TestBTG       | QA             | PROD           |
|----|--------------------------------------|--------|-------------|----------------|----------------|----------------|
| 1  | InterastarCEMT v2.42.2026.0424.0     |        |             | ✔️ Installed    | ✔️ Installed    | ✔️ Installed    |
| 2  | CloudInfoFEV242.2026.0428.3          |        |             | ✔️ Installed    | ✔️ Installed    | ✔️ Installed    |

---

## 3. Changes in This Release

### 3.1 Functional Changes
-  

### 3.2 Technical Changes
-  

### 3.3 Database / DAC Changes
-  

### 3.4 UI / Screen Changes
-  

### 3.5 Integration Changes
-  

---

## 4. Pre-Deployment Checklist

- [ ] All packages compiled successfully  
- [ ] No schema conflicts  
- [ ] No missing DAC fields  
- [ ] Import scenarios validated  
- [ ] Generic inquiries validated  
- [ ] Dashboards validated  
- [ ] Webhooks / API endpoints tested  
- [ ] Backup taken (if PROD)  

---

## 5. Deployment Steps Executed

1.  
2.  
3.  
4.  
5.  
6.  

---

## 6. Post-Deployment Validation

### 6.1 Functional Validation
-  

### 6.2 Technical Validation
-  

### 6.3 Data Validation
-  

---

## 7. Issues, Deltas, or Anomalies

| # | Issue / Observation | Impact | Resolution / Next Steps |
|---|---------------------|--------|--------------------------|
| 1 |                     |        |                          |

---

## 8. Documentation Updates Required
-  

---

## 9. Notes for Next Release

- **2026-05-04 10:20 CDT** — PRD #4 created as the next release cycle following emergency PRD #3.
- **2026-05-20 10:03 CDT** — 5/18 Deployment Instructions:  
  - Start lockout  
  - Uncheck **InterastarCEMT**, **InterastarDD**, **CloudInfoFE** → Save → Deploy to all tenants  
  - Upload and confirm **CloudInfoFE** and **InterastarCEMT** match GitHub versions  
  - Check **CloudInfoFE** and **InterastarCEMT** → Deploy to MX → Check “Execute all DB scripts”  
  - Check **InterastarDD** → Deploy to MX  
  - Remove lockout  
  - Restart and clear cache  

---

## 10. Attachments / Artifacts

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
