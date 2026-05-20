# Special GL Transactions (Operaciones Especiales)

## Overview

Special GL (General Ledger) transactions are postings made to subledger accounts (customers/vendors) that are tracked separately from normal line items. A **Special GL Indicator** (single character A-Z, 0-9) redirects the posting from the standard reconciliation account to an alternative reconciliation account.

This mechanism enables tracking of down payments, guarantees, bills of exchange, and other financial instruments without mixing them with regular open items.

---

## Types of Special GL Transactions

| Type | Posting | Balance Sheet Impact | Examples |
|------|---------|---------------------|----------|
| **Noted Items** | Statistical only | None — memo entry | Down payment requests (F-47, F-37) |
| **Free Offsetting** | Real posting | Alternative recon account | Down payments (F-48, F-29), guarantees |
| **Statistical Postings** | Statistical only | Noted on account | Sureties, guarantees received/given |

### Key Characteristics

| Characteristic | Noted Items | Free Offsetting | Statistical |
|---------------|-------------|-----------------|-------------|
| Updates GL balances | No | Yes | No |
| Requires offsetting entry | No | Yes | No |
| Appears in account balance | Display only | Yes | Display only |
| Clears against invoices | No | Yes (F-54/F-39) | No |
| Posting keys | 09/19/29/39 | 09/19/29/39 | 09/19/29/39 |

---

## Down Payment Process — Vendor (Accounts Payable)

### Step-by-Step Flow

| Step | TCode | Description | Posting Key | Special GL | Debit | Credit |
|------|-------|-------------|-------------|------------|-------|--------|
| 1 | F-47 | Down payment request | 39 | A | — | — (noted item) |
| 2 | F-48 | Post down payment | 29 | A | Vendor (alt recon) | Bank |
| 3 | MIRO/FB60 | Invoice received | 31/50 | — | Expense/Asset | Vendor (std recon) |
| 4 | F-54 | Clear DP against invoice | — | A | Vendor (std recon) | Vendor (alt recon) |

### ACDOCA Entries for Vendor Down Payment (F-48)

```
Line 1: KOART=K, KONTO=vendor, UMSKZ='A', SHKZG='S' (debit vendor alt recon)
Line 2: KOART=S, KONTO=bank_acct, SHKZG='H' (credit bank)
```

### MCP SQL — Outstanding Vendor Down Payments

```sql
-- Down payments posted but not yet cleared (vendor)
SELECT a.LIFNR, a.BELNR, a.GJAHR, a.BUDAT, a.UMSKZ,
       a.WRBTR, a.WAERS, a.DMBTR, a.PSWSL
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART = 'K'
  AND a.UMSKZ = 'A'
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
ORDER BY a.LIFNR, a.BUDAT
```

```sql
-- Summary of vendor down payments by vendor
SELECT a.LIFNR, a.WAERS,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.WRBTR ELSE -a.WRBTR END) AS OPEN_DP_AMOUNT,
       COUNT(*) AS DP_COUNT
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART = 'K'
  AND a.UMSKZ = 'A'
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
GROUP BY a.LIFNR, a.WAERS
HAVING SUM(CASE WHEN a.SHKZG = 'S' THEN a.WRBTR ELSE -a.WRBTR END) <> 0
ORDER BY OPEN_DP_AMOUNT DESC
```

---

## Down Payment Process — Customer (Accounts Receivable)

### Step-by-Step Flow

| Step | TCode | Description | Posting Key | Special GL | Debit | Credit |
|------|-------|-------------|-------------|------------|-------|--------|
| 1 | F-37 | Down payment request | 09 | A | — | — (noted item) |
| 2 | F-29 | Post down payment | 19 | A | Bank | Customer (alt recon) |
| 3 | VF01/FB70 | Invoice created | 01/50 | — | Customer (std recon) | Revenue |
| 4 | F-39 | Clear DP against invoice | — | A | Customer (alt recon) | Customer (std recon) |

### MCP SQL — Outstanding Customer Down Payments

```sql
SELECT a.KUNNR, a.BELNR, a.GJAHR, a.BUDAT, a.UMSKZ,
       a.WRBTR, a.WAERS, a.DMBTR
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART = 'D'
  AND a.UMSKZ = 'A'
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
ORDER BY a.KUNNR, a.BUDAT
```

---

## Bills of Exchange (Letras de Cambio)

| Operation | TCode | Posting Key | Special GL | Description |
|-----------|-------|-------------|------------|-------------|
| Post BoE Receivable | F-36 | 09 | W | Customer pays with bill of exchange |
| Reverse BoE Receivable | F-33 | 01 | W | Dishonored bill |
| Post BoE Payable | F-40 | 39 | W | Issue bill of exchange to vendor |
| Present BoE at Bank | — | — | B | Discount BoE at bank |

### Special GL Indicators for Bills of Exchange

| Indicator | Account Type | Description | Alt Recon Account |
|-----------|-------------|-------------|-------------------|
| W | D (Customer) | Bills of exchange receivable | BoE receivable account |
| B | D (Customer) | Bills sent to bank for collection | BoE at bank account |
| W | K (Vendor) | Bills of exchange payable | BoE payable account |

---

## Configuration (SPRO)

### SPRO Path

```
Financial Accounting (New) > Accounts Receivable and Accounts Payable >
  Business Transactions > Down Payments Made/Received >
    Define Alternative Reconciliation Account for Down Payments
```

### Key Configuration Transactions

| TCode | Purpose | Table |
|-------|---------|-------|
| OBYR | Define special GL indicators | T074 |
| OBXY | Assign alt recon acct (customers) | T074 |
| OBXR | Assign alt recon acct (vendors) | T074 |
| OB40 | Account determination for tax on DP | — |
| OBBV | Define tax category for DP | — |

### Configuration Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| T074 | Special GL indicator definitions | SHBKZ, KOART, UMSKZ |
| T074T | Special GL indicator texts | SHBKZ, KOART, UMSKZ, SPRAS |
| T074U | Properties (noted/real/statistical) | SHBKZ, KOART, UMSKZ |
| SKA1/SKB1 | Alt reconciliation accounts | SAKNR, BUKRS |

---

## ACDOCA Fields for Special GL

| Field | Description | Values |
|-------|-------------|--------|
| UMSKZ | Special GL indicator | A, B, W, F, etc. |
| KOART | Account type | D=Customer, K=Vendor |
| AUGBL | Clearing document | Blank = open item |
| AUGDT | Clearing date | Date of clearing |
| ZUONR | Assignment field | Used for DP reference |

### MCP SQL — All Special GL Balances by Indicator

```sql
SELECT a.UMSKZ, a.KOART,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE 0 END) AS DEBIT_LC,
       SUM(CASE WHEN a.SHKZG = 'H' THEN a.DMBTR ELSE 0 END) AS CREDIT_LC,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS BALANCE_LC,
       COUNT(*) AS ITEM_COUNT
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.UMSKZ <> ''
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
GROUP BY a.UMSKZ, a.KOART
ORDER BY a.KOART, a.UMSKZ
```

---

## Diagnostics and Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "Special GL indicator not defined" | UMSKZ not configured in T074 | OBYR: create indicator for account type |
| "No alternative recon account" | Alt account not assigned | OBXY/OBXR: assign account per indicator |
| DP clearing fails | Amounts don't match or partial | Use F-54/F-39 with partial clearing |
| DP request not visible | Noted item not in standard report | Use FBL1N/FBL5N with "Noted items" checkbox |
| Tax on down payment wrong | Tax category not configured | OBBV: define tax handling for DP |
| DP shows in aging report | Not excluded from aging | Check report variant — exclude UMSKZ items |

### MCP SQL — Verify Special GL Configuration

```sql
-- Check configured special GL indicators
SELECT SHBKZ, KOART, UMSKZ
FROM T074
WHERE KOART IN ('D', 'K')
ORDER BY KOART, UMSKZ
```

```sql
-- Noted items still outstanding (should be zero at year-end)
SELECT a.KOART, a.UMSKZ, a.BELNR, a.GJAHR, a.BUDAT,
       a.KUNNR, a.LIFNR, a.WRBTR, a.WAERS
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.UMSKZ IN ('A','F')
  AND a.AUGBL = ''
  AND a.RLDNR = '0L'
  AND a.GJAHR = '{fiscal_year}'
ORDER BY a.KOART, a.UMSKZ, a.BUDAT
```

---

## Reporting Transactions

| TCode | Report | Special GL Support |
|-------|--------|--------------------|
| FBL1N | Vendor line items | Filter by UMSKZ |
| FBL5N | Customer line items | Filter by UMSKZ |
| F.09 | Customer list of DP | Specific to down payments |
| F.19 | Vendor list of DP | Specific to down payments |
| S_ALR_87012172 | DP aging (customer) | Down payment analysis |
| S_ALR_87012082 | DP aging (vendor) | Down payment analysis |
| FAGLL03H | GL line items (new) | UMSKZ visible in layout |
