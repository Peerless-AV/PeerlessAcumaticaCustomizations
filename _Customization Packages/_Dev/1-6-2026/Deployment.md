# 📦 **Package Release Document (PRD #1)**  
**Date Created:** 2026‑01‑06  
**Last Updated:** 2026‑02‑11 09:08 CST**  

### Acumatica 2024 R2 — Deployment Release Notes

---

## 🧭 1. Release Overview
- **Release Version Targeted:** Acumatica 2024 R2 (24.210.0019)  
- **Build Number:** 1‑6‑2026  
- **Deployment Date:** 2026‑01‑06  
- **Deployed By:** Dan Zale  
- **Related Work Items / Tickets:**  

---

## 🧱 2. Included Packages  
*(Updated — all packages now marked as deployed in QA)*

| # | Package Name                           | Notes                                                         | DZ Personal | TestBTG | QA | PROD |
|---|----------------------------------------|---------------------------------------------------------------|-------------|---------|----|------|
| 1 | RadleyWebServiceEndPoint2024R2[003]    |                                                               | ✔️          | ✔️      | ✔️  | [ ]  |
| 2 | CBIZ.PL.EPR                            |                                                               | ✔️          | ✔️      | ✔️  | [ ]  |
| 3 | PRLPOSSales                            |                                                               | ✔️          | ✔️      | ✔️  | [ ]  |
| 4 | PRLUpdateReportMenu                    |                                                               | ✔️          | ✔️      | ✔️  | [ ]  |
| 5 | fayeEndPoint                           | Created in DEV – Peerless‑AV and copied to BTG Management     | ✔️          | ✔️      | ✔️  | [ ]  |
| 6 | CBIZ.UpdateItemAttributesTab[001]      | Fixes a bug introduced by a recent upgrade in Edge            | ✔️          | ✔️      | ✔️  | [ ]  |
| 7 | **InterestarCEMT**                     | **Replacing version which is not working**                    | ✔️          | ✔️      | ✔️  | [ ]  |

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

1. In 2024R2TESTBTG — Installed the baseline packages from the live site. This first pass is only the current production packages, no new ones.  
2. In 2024R2TESTBTG — The baseline packages without MX packages installed first. Site completed and deploy ran as expected.  
3. In 2024R2TESTBTG — Interestar and cloud info packages deployed to only MX and MX‑Test. Deployment stopped at “Starting the website.”  
4. In DZLOCAL — New packages deployed. MX packages will be deployed after first‑pass deployment and testing.  
5. **In 2024R2TESTBTG — 2026‑01‑28 17:03 CST — Deployed InterestarCEMT to MX tenants. Copied delivery from N drive to GitHub, replaced the highlighted project with the new version, uploaded, deployed to MX tenants, and restarted.**

---

## 🔍 6. Post‑Deployment Validation

### 6.1 Functional Validation
-  

### 6.2 Technical Validation
- **2026‑01‑07 13:21 CST** — DZ Reminder: Double check new field from Laura under Radley API.

### 6.3 Data Validation
- **2026‑01‑07 12:37 CST** — FayeWebEndPoint returns `usrStockLevel` in DEV. After deploying locally, the field appeared as expected.

---

## ⚠️ 7. Issues, Deltas, or Anomalies

| # | Issue / Observation | Impact | Resolution / Next Steps |
|---|---------------------|--------|--------------------------|
| 1 |                     |        |                          |
| 2 | **CloudInfoFE level** | N/A | Discuss with Interestar and Jun why CloudInfoFE would not be leveled before all other MX packages |

---

## 📘 8. Documentation Updates Required

-  

---

## 🧠 9. Notes for Next Release

- **2026‑01‑06 18:08 CST** — GIT repo created; packages collected for deployment.  
- **2026‑01‑07 12:24 CST** — Added FayeEndPoint package; refreshed endpoint from DEV to pass StockLevel.  
- **2026‑01‑09 10:07 CST** — Freshworks documentation updated; release created.  
- **2026‑01‑16 21:27 CST** — Installed baseline setup on DZ laptop for Local DEV.  
- **2026‑01‑17 16:27 CST** — DZ Personal environment loaded; baseline testing completed.  
- **2026‑01‑18 09:12 CST** — SQL DB built on TESTBTG; ARM64 compile slower but stable.  
- **2026‑01‑20 12:43 CST** — Built 2024R2TESTBTG environment; deployed production packages; turned over to team.  
- **2026‑01‑28 17:39 CST** — Deployment of the new InterestarCEMT package failed with an error. Log in email.  
- **2026‑02‑05 08:14 CST** — Deployed InterestarCEMT to DZ Personal; deployment halts at “Starting website,” consistent with MX patch behavior. Will repeat in TESTBTG and loop Jun in.  
- **2026‑02‑06 06:37 CST** — MX packages presenting the same error, halting at “Starting website.” Confirmed with Jun. Beginning to build MX packages into Release 1 one at a time; first pass required deploying InterestarCEMT and CloudInfoFE together. Deployment passed fully.  
- **2026‑02‑06 07:30 CST** — During installation of **InterastarVistaPreviaFactura**, the “Starting website” halt presented again.  
- **2026‑02‑06 07:42 CST** — Uploaded packages to **2024R2DEV** and will begin deploying non‑MX packages first.  
- **2026‑02‑06 10:50 CST** — In TESTBTG, the following Interestar packages are not deployed due to halting at “Starting website”: **InterastarDD1**, **InterastarDIOT**, **InterastarVistaPreviaFactura**.

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

