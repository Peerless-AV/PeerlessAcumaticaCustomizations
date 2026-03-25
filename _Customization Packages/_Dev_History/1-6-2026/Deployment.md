Understood, Grand Admiral Zale. I’ve closed out the release cleanly.

### ✅ **All packages are now marked as deployed in PROD**  
Section 2 has been updated so every package shows a ✔️ in the PROD column.

Below is your **fully regenerated, final Markdown PRD**, reflecting the completed deployment and all prior updates.

---

# 📦 **Package Release Document (PRD #1)**  
**Date Created:** 2026‑01‑06  
**Last Updated:** 2026‑03‑24 09:17 CDT**  

### Acumatica 2024 R2 — Deployment Release Notes

---

## 🧭 1. Release Overview
- **Release Version Targeted:** Acumatica 2024 R2 (24.210.0019)  
- **Build Number:** 1‑6‑2026  
- **Deployment Date:** **2026‑03‑16**  
- **Deployed By:** Dan Zale  
- **Related Work Items / Tickets:**  

---

## 🧱 2. Included Packages  
*(All packages now marked deployed in PROD)*

| # | Package Name                           | Notes                                                         | DZ Personal | TestBTG | QA | PROD |
|---|----------------------------------------|---------------------------------------------------------------|-------------|---------|----|------|
| 1 | RadleyWebServiceEndPoint2024R2[003]    |                                                               | ✔️          | ✔️      | ✔️  | ✔️  |
| 2 | PRLPOSSales                            |                                                               | ✔️          | ✔️      | ✔️  | ✔️  |
| 3 | PRLUpdateReportMenu                    |                                                               | ✔️          | ✔️      | ✔️  | ✔️  |
| 4 | fayeEndPoint                           | Created in DEV – Peerless‑AV and copied to BTG Management     | ✔️          | ✔️      | ✔️  | ✔️  |
| 5 | CBIZ.UpdateItemAttributesTab[001]      | Fixes a bug introduced by a recent upgrade in Edge            | ✔️          | ✔️      | ✔️  | ✔️  |
| 6 | **InterestarCEMT**                     | **Replacing version which is not working**                    | ✔️          | ✔️      | ✔️  | ✔️  |

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

## 🧪 4. Pre‑Deployment Checklist

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

1. In 2024R2TESTBTG — Installed the baseline packages from the live site.  
2. In 2024R2TESTBTG — Baseline packages without MX packages installed first; deployment succeeded.  
3. In 2024R2TESTBTG — Interestar + CloudInfo packages deployed to MX tenants; halted at “Starting the website.”  
4. In DZLOCAL — New packages deployed; MX packages deferred until after first‑pass testing.  
5. **2026‑03‑16 22:49 CDT — Deployment to PROD finished (BTG Management completed).**

---

## 🔍 6. Post‑Deployment Validation

### 6.1 Functional Validation
- **2026‑03‑11 14:52 CDT** — Tested **PRLUpdateReportMenu**. After successful deployments and confirming each deployment completed fully, the package deployed as expected in all tenants. Ready for final testing once other issues are resolved.

### 6.2 Technical Validation
- **2026‑01‑07 13:21 CST** — Reminder: Double check new field from Laura under Radley API.

### 6.3 Data Validation
- **2026‑01‑07 12:37 CST** — FayeWebEndPoint returns `usrStockLevel` in DEV; field appeared after deployment.

---

## ⚠️ 7. Issues, Deltas, or Anomalies

| # | Issue / Observation | Impact | Resolution / Next Steps |
|---|---------------------|--------|--------------------------|
| 1 |                     |        |                          |
| 2 | **CloudInfoFE level** | N/A | Discuss with Interestar and Jun why CloudInfoFE would not be leveled before other MX packages |

---

## 📘 8. Documentation Updates Required

-  

---

## 🧠 9. Notes for Next Release

- **2026‑01‑06 18:08 CST** — GIT repo created; packages collected for deployment.  
- **2026‑01‑07 12:24 CST** — Added FayeEndPoint package; refreshed endpoint from DEV.  
- **2026‑01‑09 10:07 CST** — Freshworks documentation updated; release created.  
- **2026‑01‑16 21:27 CST** — Installed baseline setup on DZ laptop for Local DEV.  
- **2026‑01‑17 16:27 CST** — DZ Personal environment loaded; baseline testing completed.  
- **2026‑01‑18 09:12 CST** — SQL DB built on TESTBTG; ARM64 compile slower but stable.  
- **2026‑01‑20 12:43 CST** — Built 2024R2TESTBTG environment; deployed production packages.  
- **2026‑01‑28 17:39 CST** — Deployment of new InterestarCEMT package failed; see email log.  
- **2026‑02‑05 08:14 CST** — InterestarCEMT halts at “Starting website” in DZ Personal; repeating in TESTBTG.  
- **2026‑02‑06 06:37 CST** — MX packages halting at “Starting website.” First pass required bundling InterestarCEMT + CloudInfoFE. Deployment passed fully.  
- **2026‑02‑06 07:30 CST** — VistaPreviaFactura halted at “Starting website.”  
- **2026‑02‑06 07:42 CST** — Uploaded packages to 2024R2DEV; deploying non‑MX packages first.  
- **2026‑02‑06 10:50 CST** — TESTBTG unable to deploy DD1, DIOT, VistaPreviaFactura due to “Starting website” halt.  
- **2026‑03‑02 09:06 CST** — Initial deploy finished. Adding MX packages for MX tenant; deployment started.  
- **2026‑03‑02 10:05 CST** — Deployment froze as expected. Concluding QA deployment. Restarting server, refreshing cache, and coordinating group login for testing.  
- **2026‑03‑11 14:52 CDT** — Release packages in the following order for TESTBTG and QA: all UK and US packages, then CloudInfo + InterestarCEMT, then InterastarDD1 and Sears.

---

## 🗂️ 10. Attachments / Artifacts

### Screenshots
- Compilation log and deployment halt at “Starting the website” (2026‑01‑20 22:04 CST)

### Exported Packages
-  

### SQL Scripts
-  

### Logs
-  

### Before/After Comparisons
-  

---

PRD #1 is now **fully closed out** and ready for archival or handoff.
