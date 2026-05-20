# Data Migration FI — S/4HANA

## Overview

FI data migration involves transferring master data, balances, and open items from a legacy system into SAP S/4HANA. The primary tool in S/4HANA is the **Migration Cockpit (LTMC)**, which provides pre-built migration objects with Excel/XML templates, field mapping, validation, and simulation.

---

## Migration Approaches

| Approach | Tool | Best For | Complexity |
|----------|------|----------|------------|
| **Migration Cockpit** | LTMC / Fiori F4684 | Standard migrations, S/4HANA native | Low-Medium |
| **LSMW** | LSMW | Legacy migrations, batch input | Medium |
| **Custom ABAP + BAPIs** | SE38 + BAPIs | Complex transformations | High |
| **SAP Data Services** | BODS | Large volumes, ETL-heavy | High |
| **SAP S/4HANA Migration Object Modeler** | LTMOM | Custom migration objects | Medium |

---

## S/4HANA Migration Cockpit (LTMC)

### Key Features

| Feature | Description |
|---------|-------------|
| Pre-built objects | 300+ migration objects for all SAP modules |
| Excel templates | Download, fill, upload — field-level validation |
| Simulation mode | Validate data without posting |
| Error handling | Detailed log per record, reprocessing |
| Parallel execution | Multi-threaded for large volumes |
| Fiori app | "Migrate Your Data" (F4684) — web-based alternative to LTMC |

### Execution Steps

```
1. LTMC → Create migration project
2. Select migration objects (e.g., FIN_GL_ACCBAL)
3. Download Excel template
4. Fill template with legacy data
5. Upload filled template
6. Run simulation (test mode)
7. Review errors → fix data → re-upload
8. Execute migration (production mode)
9. Verify posted data
```

---

## Migration Objects — Financial Accounting

### Master Data Objects

| Object ID | Description | Key Fields | Dependencies |
|-----------|-------------|------------|--------------|
| FIN_GL_ACCOUNT | GL Account Master | Chart of accounts, account number, account group, texts | Chart of accounts must exist |
| BUSINESS_PARTNER | Customer/Vendor Master (BP) | BP number, roles (FLCU00/FLVN00), addresses, bank data | BP number ranges, account groups |
| BANK_MASTER | Bank Master Data | Bank country, bank key, bank name, SWIFT | Country must exist |
| PROFIT_CENTER | Profit Center Master | Controlling area, profit center, hierarchy | Controlling area configured |
| COST_CENTER | Cost Center Master | Controlling area, cost center, hierarchy, category | Controlling area, cost element |

### Balances and Open Items

| Object ID | Description | Key Fields | Dependencies |
|-----------|-------------|------------|--------------|
| FIN_GL_ACCBAL | GL Account Balances | Company code, account, fiscal year, period, balance | GL accounts created |
| FIN_CUSTOPITM | Customer Open Items | Customer, document number, amount, due date, currency | BP created with customer role |
| FIN_VENDOPITM | Vendor Open Items | Vendor, document number, amount, due date, currency | BP created with vendor role |
| ASSET_MASTER | Asset Master Data | Company code, asset class, cost center, useful life | Asset classes configured |
| ASSET_BALANCE | Asset Balances | Asset number, depreciation area, acquisition value, accumulated depreciation | Asset masters created |
| FIN_ACDOCA_INIT | ACDOCA Initial Load | All ACDOCA fields for historical data | GL accounts, cost objects |

### S/4HANA Specific Considerations

| Topic | ECC | S/4HANA |
|-------|-----|---------|
| Customer/Vendor master | KNA1/KNB1/LFA1/LFB1 | Business Partner (BUT000/BP) |
| Material ledger | Optional | Mandatory (active) |
| GL tables | GLT0, BSEG, BSAS | ACDOCA (Universal Journal) |
| New Asset Accounting | Optional | Mandatory |
| Credit Management | FD32 | UKM (Fiori) |

---

## BAPIs for Custom Migration Programs

### Document Posting

| BAPI | Purpose | Key Parameters |
|------|---------|---------------|
| BAPI_ACC_DOCUMENT_POST | Post FI documents (opening balances) | DOCUMENTHEADER, ACCOUNTGL, CURRENCYAMOUNT |
| BAPI_ACC_DOCUMENT_CHECK | Validate without posting | Same as above |
| BAPI_ACC_DOCUMENT_REV_POST | Reverse posted document | REVERSAL structure |

### Master Data

| BAPI | Purpose | Key Parameters |
|------|---------|---------------|
| BAPI_BUPA_CREATE_FROM_DATA | Create Business Partner | CENTRALDATA, ADDRESSDATA, ROLES |
| BAPI_BUPA_ROLE_ADD_2 | Add role to BP | PARTNER, PARTNERROLE |
| BAPI_FIXEDASSET_CREATE | Create fixed asset | GENERALDATA, DEPRECIATIONAREAS |
| BAPI_ASSET_ACQUISITION_POST | Post asset acquisition | AMOUNT, ASSET_NO, DOCUMENT_HEADER |

### Sample BAPI Call — Opening Balance

```abap
DATA: ls_header   TYPE bapiache09,
      lt_gl       TYPE TABLE OF bapiacgl09,
      lt_currency TYPE TABLE OF bapiaccr09,
      lt_return   TYPE TABLE OF bapiret2.

ls_header-comp_code   = '1000'.
ls_header-doc_date    = '20260101'.
ls_header-pstng_date  = '20260101'.
ls_header-doc_type    = 'SA'.
ls_header-username    = sy-uname.

" Debit line (asset/expense/balance)
APPEND VALUE #( itemno_acc = '001' gl_account = '0000100000'
                profit_ctr = 'PC001' ) TO lt_gl.
APPEND VALUE #( itemno_acc = '001' currency = 'EUR'
                amt_doccur = '50000.00' ) TO lt_currency.

" Credit line (opening balance equity)
APPEND VALUE #( itemno_acc = '002' gl_account = '0000390000' ) TO lt_gl.
APPEND VALUE #( itemno_acc = '002' currency = 'EUR'
                amt_doccur = '-50000.00' ) TO lt_currency.

CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
  EXPORTING documentheader = ls_header
  TABLES   accountgl      = lt_gl
           currencyamount = lt_currency
           return         = lt_return.
```

---

## Cutover Sequence

### Recommended Order

| Phase | Step | Objects | Prerequisite |
|-------|------|---------|--------------|
| 1 | Org structure | Company codes, plants, sales orgs | Customizing complete |
| 2 | Master data — foundation | GL accounts, banks, profit/cost centers | Org structure |
| 3 | Master data — partners | Business Partners (customer + vendor roles) | Account groups, number ranges |
| 4 | Master data — assets | Asset masters | Asset classes, depreciation areas |
| 5 | Opening balances — GL | GL account balances by period | GL accounts created |
| 6 | Opening balances — assets | Acquisition values + accumulated depreciation | Asset masters created |
| 7 | Open items — AR | Customer open invoices/credit memos | BPs with customer role |
| 8 | Open items — AP | Vendor open invoices/credit memos | BPs with vendor role |
| 9 | Bank reconciliation | Outstanding checks, deposits in transit | House banks configured |
| 10 | Verification | Reconciliation vs source system | All above completed |

---

## Validation Checks Post-Migration

### MCP SQL — Balance Verification

```sql
-- Trial balance after migration (GL totals)
SELECT a.RACCT,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE 0 END) AS TOTAL_DEBIT,
       SUM(CASE WHEN a.SHKZG = 'H' THEN a.DMBTR ELSE 0 END) AS TOTAL_CREDIT,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS BALANCE
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
GROUP BY a.RACCT
ORDER BY a.RACCT
```

```sql
-- Subledger vs GL reconciliation (AR)
SELECT 'GL_RECON' AS SOURCE,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS BALANCE
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.RACCT = '{ar_recon_account}'
  AND a.RLDNR = '0L'
  AND a.GJAHR = '{fiscal_year}'
UNION ALL
SELECT 'SUBLEDGER' AS SOURCE,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS BALANCE
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART = 'D'
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
```

```sql
-- Count migrated documents by type
SELECT a.BLART, COUNT(DISTINCT a.BELNR || a.GJAHR) AS DOC_COUNT,
       MIN(a.BUDAT) AS EARLIEST, MAX(a.BUDAT) AS LATEST
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
  AND a.USNAM = '{migration_user}'
GROUP BY a.BLART
ORDER BY DOC_COUNT DESC
```

```sql
-- Duplicate document check
SELECT a.BELNR, a.GJAHR, a.BUKRS, COUNT(*) AS LINE_COUNT
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
  AND a.USNAM = '{migration_user}'
GROUP BY a.BELNR, a.GJAHR, a.BUKRS
HAVING COUNT(*) > 20
ORDER BY LINE_COUNT DESC
```

### Reconciliation Checklist

| Check | Method | Expected Result |
|-------|--------|-----------------|
| Trial balance totals | Compare SAP vs legacy | Debits = Credits, totals match |
| AR subledger vs GL recon | SQL above | Zero difference |
| AP subledger vs GL recon | Same pattern with KOART='K' | Zero difference |
| Asset register vs GL | RABEST (asset balances) vs GL | Totals match per dep area |
| Open items count | FBL1N/FBL5N item count | Matches legacy count |
| Open items aging | FBL5N aged | Aging buckets match legacy |
| Retained earnings | Balance of 390xxx account | Matches legacy equity |
| Tax balances | RFUMSV00 | Tax carried forward matches |
| Bank balances | FF7A / GL balance | Matches bank statements |

---

## Common Migration Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Business partner already exists" | Duplicate BP number | Check number range, use external numbering carefully |
| "Account group not allowed" | Wrong account group for BP role | Verify FLCU00/FLVN00 role mapping |
| "Posting period not open" | Period locked in OB52 | Open migration period for doc type |
| "Currency amount rounding" | Decimal mismatch | Check currency decimal places (TCURX) |
| "Cost center required" | P&L account without cost object | Add cost center/profit center to template |
| "Document type not defined" | Migration doc type missing | FBN1: create doc type + number range |
| "Depreciation area mismatch" | Asset balance for non-existent dep area | Verify asset class has all dep areas |
| "Retained earnings not defined" | OB53 not configured | Define retained earnings account in OB53 |
| "Tax code invalid" | Tax code not maintained | FTXP: create tax code for migration |
| "Fiscal year variant" | Posting date vs fiscal year mismatch | Verify fiscal year variant (OB29) |

---

## Post-Migration Activities

| Activity | TCode | Purpose |
|----------|-------|---------|
| Balance carryforward | FAGLGVTR | Carry forward GL balances to new year |
| Asset year change | AJRW | Fiscal year change for assets |
| Open item management | FBL1N/FBL5N | Verify all open items display correctly |
| Payment program test | F110 | Test automatic payments with migrated data |
| Dunning test | F150 | Test dunning with migrated customer data |
| Reporting validation | S_ALR_87012284 | Balance sheet, P&L verification |
| Lock migration user | SU01 | Disable migration user after go-live |
