# Intercompany Accounting FI — S/4HANA

## Overview

Intercompany (IC) transactions occur between different company codes within the same corporate group. SAP handles these through cross-company code postings, automatic clearing accounts, and reconciliation tools.

## Cross-Company Code Posting

### How It Works

When posting a document that spans two or more company codes, SAP automatically:
1. Creates separate documents in each company code
2. Posts to intercompany clearing accounts (receivable in one CC, payable in other)
3. Links documents via common reference number

### Document Flow

```
FB01 with 2 Company Codes:
  CC 1000: Debit Expense 400000    1,000 EUR
  CC 2000: Credit Vendor 100123    1,000 EUR

SAP generates:
  Doc in CC 1000: Debit  400000   1,000  (expense)
                  Credit IC-AP    1,000  (clearing → CC 2000)
  Doc in CC 2000: Debit  IC-AR    1,000  (clearing → CC 1000)
                  Credit 100123   1,000  (vendor)
```

## Configuration — Intercompany Clearing Accounts (OBY6)

SPRO Path: `Financial Accounting > General Ledger > Business Transactions > Prepare Cross-Company Code Transactions`

Tcode: **OBY6**

| Parameter | Descripcion |
|-----------|-------------|
| Clearing Company Code | CC pair (1000/2000) |
| Clearing account debit | IC Receivable account |
| Clearing account credit | IC Payable account |
| Posting key debit | 40 (standard) |
| Posting key credit | 50 (standard) |

### Account Pair Matrix

| From CC | To CC | Debit Acct (IC-AR) | Credit Acct (IC-AP) |
|---------|-------|-------------------|---------------------|
| 1000 | 2000 | 1910000 | 2910000 |
| 1000 | 3000 | 1910000 | 2910000 |
| 2000 | 1000 | 1920000 | 2920000 |
| 2000 | 3000 | 1920000 | 2920000 |
| 3000 | 1000 | 1930000 | 2930000 |
| 3000 | 2000 | 1930000 | 2930000 |

### MCP SQL — Intercompany Clearing Account Config

```sql
-- Cuentas de compensacion intercompany
SELECT BUKRS, BRGBU, SKONT1, SKONT2
FROM T030A
WHERE BUKRS = '{company_code}'
ORDER BY BRGBU
```

## Intercompany Scenarios

### 1. Cross-Company Code Expense Allocation

```
Scenario: CC 1000 pays rent for shared office, CC 2000 shares 40%
Posting (FB01):
  CC 1000: Debit Rent Expense      600 (60%)
  CC 2000: Debit Rent Expense      400 (40%)
  CC 1000: Credit Bank            1000
```

### 2. Intercompany Billing (SD)

| Step | Descripcion | Tcode |
|------|-------------|-------|
| 1 | Sales order in selling CC | VA01 |
| 2 | Delivery from supplying plant | VL01N |
| 3 | Billing to external customer | VF01 |
| 4 | Intercompany billing | VF01 (IV doc type) |

SPRO Path: `Sales and Distribution > Billing > Intercompany Billing`

### 3. Intercompany Stock Transfer Order (STO)

| Step | Descripcion | Tcode |
|------|-------------|-------|
| 1 | Create STO (purchase order) | ME21N (UB doc type) |
| 2 | Delivery from supplying plant | VL01N |
| 3 | Goods receipt at receiving plant | MIGO |
| 4 | Intercompany invoice | MIRO or automatic |

### 4. Cross-Charges via CO

| Method | Tcode | Descripcion |
|--------|-------|-------------|
| Assessment | KSV5 | Distribute by % or statistical key figure |
| Distribution | KSU5 | Allocate primary costs |
| Direct activity allocation | KB21N | Based on activity type and rate |

## Document Splitting for Intercompany

SPRO Path: `Financial Accounting > General Ledger > Business Transactions > Document Splitting`

In S/4HANA, document splitting ensures each company code produces a balanced set of entries in ACDOCA:
- Splitting characteristics: Profit center, Segment, Business area
- Zero-balance rule per splitting characteristic
- Intercompany postings derive partner profit center / segment automatically

### MCP SQL — Cross-Company Code Postings

```sql
-- Asientos cross-company code
SELECT RCOMP, RACCT, BELNR, BUZEI,
       DRCRK, HSL, PRCTR, SEGMENT,
       RASSC AS TRADING_PARTNER,
       BUDAT, BLART, SGTXT
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND RASSC <> ''
  AND RLDNR = '0L'
ORDER BY BELNR, BUZEI
```

## Intercompany Reconciliation (ICR)

SPRO Path: `Financial Accounting > General Ledger > Periodic Processing > Intercompany Reconciliation`

### ICR Configuration

| Component | Descripcion |
|-----------|-------------|
| Reconciliation group | Defines which CCs reconcile together |
| Matching rules | By reference, amount, date, assignment |
| Tolerance | Amount/percentage threshold for auto-match |
| Reconciliation accounts | IC clearing accounts to monitor |

### ICR Process (FBICR)

```
FBICR → Intercompany Reconciliation Monitor

1. SELECT: Company codes, period, reconciliation group
2. MATCH: System matches IC postings between CC pairs
   - Same reference number
   - Same amount (opposite signs)
   - Within date tolerance
3. REVIEW: Unmatched items highlighted
4. ADJUST: Post correcting entries for differences
5. REPORT: Reconciliation status report
```

### MCP SQL — Unreconciled Intercompany Items

```sql
-- Partidas intercompany no reconciliadas
SELECT A.RCOMP AS CC_SENDER,
       A.RASSC AS CC_RECEIVER,
       A.RACCT, A.BELNR, A.BUZEI,
       A.HSL AS AMOUNT_SENDER,
       A.BUDAT, A.SGTXT
FROM ACDOCA AS A
WHERE A.RCOMP = '{company_code}'
  AND A.GJAHR = '{year}'
  AND A.RASSC <> ''
  AND A.AUGDT = '00000000'
  AND A.RACCT IN ('{ic_ar_account}', '{ic_ap_account}')
  AND A.RLDNR = '0L'
ORDER BY A.RASSC, A.BUDAT
```

### MCP SQL — IC Balance Comparison Between Company Codes

```sql
-- Comparacion de saldos IC entre dos sociedades
SELECT RCOMP, RASSC, RACCT,
       SUM(HSL) AS IC_BALANCE
FROM ACDOCA
WHERE GJAHR = '{year}'
  AND POPER BETWEEN '001' AND '{period}'
  AND RLDNR = '0L'
  AND ((RCOMP = '{cc1}' AND RASSC = '{cc2}')
    OR (RCOMP = '{cc2}' AND RASSC = '{cc1}'))
  AND RACCT IN ('{ic_ar_account}', '{ic_ap_account}')
GROUP BY RCOMP, RASSC, RACCT
ORDER BY RCOMP, RACCT
```

## Central Finance (CFIN)

### Architecture

```
Source System(s)              Central S/4HANA
┌──────────────┐             ┌──────────────┐
│ ECC / S/4    │── SLT ──>  │ CFIN System  │
│ System A     │  (real-time) │ ACDOCA       │
└──────────────┘             │ (replicated) │
┌──────────────┐             │              │
│ ECC / S/4    │── SLT ──>  │              │
│ System B     │             └──────────────┘
└──────────────┘
```

### Key Components

| Component | Descripcion | Tcode/App |
|-----------|-------------|-----------|
| SLT | SAP Landscape Transformation | LTRS |
| AIF | Application Integration Framework | /AIF/IFMON |
| CFINDEF | Central Finance definition | CFINDEF |
| Mapping | Account/CC/PC mapping rules | SPRO CFIN |
| Monitor | Replication status | CFIN cockpit |

### CFIN Configuration Steps

1. Define source systems in CFINDEF
2. Configure SLT replication for BKPF/BSEG or ACDOCA
3. Map chart of accounts (source → central)
4. Map company codes, cost centers, profit centers
5. Define error handling in AIF
6. Start initial load, then switch to real-time

### MCP SQL — CFIN Replicated Documents

```sql
-- Documentos replicados via Central Finance
SELECT RCOMP, RACCT, BELNR, GJAHR, POPER,
       HSL, AWTYP, BUDAT,
       RCOMP_CFIN AS SOURCE_CC
FROM ACDOCA
WHERE RCOMP = '{central_cc}'
  AND GJAHR = '{year}'
  AND AWTYP = 'CFIN'
ORDER BY BUDAT DESC
```

## Elimination Entries for Consolidation

| Type | Descripcion | Example |
|------|-------------|---------|
| IC Revenue/Expense | Eliminate IC sales/purchases | DR IC Revenue / CR IC COGS |
| IC Receivables/Payables | Eliminate IC balances | DR IC-AP / CR IC-AR |
| IC Profit in Inventory | Unrealized profit on IC stock | DR Revenue / CR Inventory |
| IC Dividends | Eliminate IC dividend income | DR Dividend Income / CR Investment |
| Equity Elimination | Investment vs equity | DR Equity / CR Investment |

### S/4HANA Group Reporting

SPRO Path: `Financial Accounting > Financial Accounting Global Settings > Group Reporting`

- Replaces classic EC-CS consolidation
- Uses ACDOCA as source (no separate consolidation tables)
- Automatic IC elimination rules
- Real-time consolidation possible

## Common Errors and Solutions

| Error | Causa | Solucion |
|-------|-------|----------|
| "Clearing account not defined" | OBY6 missing for CC pair | Configure in OBY6 |
| Unbalanced IC document | Missing splitting rule | Check document splitting config |
| IC items not matching | Different reference numbers | Standardize reference format |
| CFIN replication failed | AIF mapping error | Check /AIF/IFMON for details |
| Wrong trading partner | RASSC not derived | Check partner derivation rules |
| IC elimination incomplete | Missing IC accounts | Add accounts to reconciliation group |
| Cross-CC posting blocked | Period closed in one CC | Open period in OB52 for both CCs |

## Key Tables

| Table | Descripcion | Key Fields |
|-------|-------------|------------|
| ACDOCA | Universal journal | RCOMP, RASSC (trading partner) |
| T030A | IC clearing accounts | BUKRS, BRGBU, SKONT1, SKONT2 |
| BKPF | Document header | BUKRS, BELNR, BSTAT |
| FINCS_ELIM | Elimination entries | Group reporting |
| T000 | Client/system info | MANDT |
| TKA01 | Controlling area | KOKRS |

## Diagnostic Checklist

```
1. OBY6 configured for all CC pairs? → Check T030A
2. IC clearing accounts exist in both CCs? → FS00 in each CC
3. Document splitting active? → SPRO doc splitting config
4. Trading partner (RASSC) populated in postings? → ACDOCA query
5. IC open items balanced between CCs? → IC balance comparison query
6. Reconciliation group defined? → SPRO ICR config
7. CFIN replication active? → LTRS / CFINDEF status
8. Period open in ALL involved CCs? → T001B check
```
