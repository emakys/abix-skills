# Financial Reporting FI — S/4HANA

## Financial Statement Version (FSV)

SPRO Path: `Financial Accounting > General Ledger > Business Transactions > Closing > Reporting > Define Financial Statement Versions`

Tcode: **OB58** (define), **FSE2** (edit), **FSE3** (display)

### FSV Structure

```
Financial Statement Version (e.g., ZIFRS)
├── Assets
│   ├── Current Assets
│   │   ├── Cash and Cash Equivalents (1000000-1099999)
│   │   ├── Accounts Receivable (1100000-1199999)
│   │   └── Inventories (1200000-1299999)
│   └── Non-Current Assets
│       ├── Fixed Assets (1500000-1599999)
│       └── Intangible Assets (1600000-1699999)
├── Liabilities
│   ├── Current Liabilities
│   │   ├── Accounts Payable (2100000-2199999)
│   │   └── Short-term Debt (2200000-2299999)
│   └── Non-Current Liabilities
│       └── Long-term Debt (2500000-2599999)
├── Equity
│   ├── Share Capital (3000000-3099999)
│   └── Retained Earnings (3100000-3199999)
├── Revenue (4000000-4999999)
└── Expenses
    ├── COGS (5000000-5999999)
    ├── Operating Expenses (6000000-6999999)
    └── Financial Expenses (7000000-7999999)
```

### Node Types

| Type | Descripcion | Uso |
|------|-------------|-----|
| Total node | Subtotal heading | Groups accounts |
| Text node | Label only | Section headers |
| Account range | From-To accounts | Leaf level |
| Functional area node | By functional area | Cost of sales method |

### Multiple FSVs

| FSV | Proposito | Estandar |
|-----|-----------|----------|
| ZIFRS | International reporting | IFRS/IAS |
| ZLOCAL | Local GAAP | Country-specific |
| ZMGMT | Management reporting | Internal structure |
| ZTAX | Tax reporting | Tax authority format |

## Standard FI Reports

### General Ledger Reports

| Tcode | Descripcion | Notas |
|-------|-------------|-------|
| FAGLB03 | GL account balances (new GL) | Primary in S/4HANA |
| FBL3N | GL line items | Drilldown to documents |
| FS10N | GL balance display | Quick balance check |
| S_ALR_78012547 | Financial statements | Uses FSV |
| F.01 | ABAP list financial statements | Classic |
| S_PL0_86000030 | GL account balances (drilldown) | Flexible |

### Accounts Payable Reports

| Tcode | Descripcion | Notas |
|-------|-------------|-------|
| FBL1N | Vendor line items | Open/cleared/all |
| FK10N | Vendor balance display | Balance by period |
| S_ALR_78012078 | Vendor balances | ALR format |
| S_ALR_78012076 | Vendor open items | Due date analysis |
| S_ALR_78012103 | Vendor evaluation | Payment behavior |

### Accounts Receivable Reports

| Tcode | Descripcion | Notas |
|-------|-------------|-------|
| FBL5N | Customer line items | Open/cleared/all |
| FD10N | Customer balance display | Balance by period |
| S_ALR_78012066 | Customer balances | ALR format |
| S_ALR_78012064 | Customer open items | Aging analysis |
| S_ALR_78012068 | Customer evaluation | DSO analysis |

### Asset Accounting Reports

| Tcode | Descripcion | Notas |
|-------|-------------|-------|
| AW01N | Asset explorer | Drilldown per asset |
| S_ALR_87011963 | Asset balances | By asset class |
| S_ALR_87011964 | Asset acquisitions | Period report |
| S_ALR_87011965 | Asset retirements | Period report |
| S_ALR_87011966 | Depreciation forecast | Projected |

## MCP SQL — Trial Balance

```sql
-- Trial balance por periodo
SELECT RACCT,
       SUM(CASE WHEN DRCRK = 'S' THEN HSL ELSE 0 END) AS DEBIT,
       SUM(CASE WHEN DRCRK = 'H' THEN HSL ELSE 0 END) AS CREDIT,
       SUM(HSL) AS BALANCE
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER BETWEEN '001' AND '{period}'
  AND RLDNR = '0L'
GROUP BY RACCT
ORDER BY RACCT
```

## MCP SQL — Profit and Loss by Profit Center

```sql
-- PnL por centro de beneficio
SELECT PRCTR, RACCT, TXT50,
       SUM(HSL) AS AMOUNT
FROM ACDOCA AS A
LEFT JOIN SKA1 AS B ON A.RACCT = B.SAKNR AND B.KTOPL = '{chart_of_accounts}'
WHERE A.RCOMP = '{company_code}'
  AND A.GJAHR = '{year}'
  AND A.POPER BETWEEN '001' AND '{period}'
  AND A.RACCT BETWEEN '{pnl_from}' AND '{pnl_to}'
  AND A.RLDNR = '0L'
GROUP BY A.PRCTR, A.RACCT, B.TXT50
ORDER BY A.PRCTR, A.RACCT
```

## MCP SQL — Balance Sheet Summary

```sql
-- Resumen de balance general
SELECT CASE
         WHEN RACCT BETWEEN '1000000' AND '1999999' THEN 'ASSETS'
         WHEN RACCT BETWEEN '2000000' AND '2999999' THEN 'LIABILITIES'
         WHEN RACCT BETWEEN '3000000' AND '3999999' THEN 'EQUITY'
       END AS BS_CATEGORY,
       SUM(HSL) AS BALANCE
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER BETWEEN '001' AND '{period}'
  AND RLDNR = '0L'
  AND RACCT BETWEEN '1000000' AND '3999999'
GROUP BY CASE
           WHEN RACCT BETWEEN '1000000' AND '1999999' THEN 'ASSETS'
           WHEN RACCT BETWEEN '2000000' AND '2999999' THEN 'LIABILITIES'
           WHEN RACCT BETWEEN '3000000' AND '3999999' THEN 'EQUITY'
         END
ORDER BY BS_CATEGORY
```

## MCP SQL — Account Movements (Period Detail)

```sql
-- Movimientos de cuenta por periodo
SELECT POPER, RACCT, BELNR, BUZEI,
       BUDAT, BLART, DRCRK, HSL, RWCUR, TSL,
       SGTXT, USNAM
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND RACCT = '{gl_account}'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND RLDNR = '0L'
ORDER BY BUDAT, BELNR
```

## Drilldown Reporting (FGI0 / FGI4)

| Tcode | Descripcion |
|-------|-------------|
| FGI0 | Create drilldown report |
| FGI1 | Change drilldown report |
| FGI4 | Execute drilldown report |
| FGIB | Background execution |

Characteristics available: Company code, GL account, Profit center, Cost center, Segment, Functional area, Business area, Trading partner.

## Report Painter/Writer

| Tcode | Descripcion |
|-------|-------------|
| GRR1 | Create Report Painter report |
| GRR2 | Change report |
| GRR3 | Display report |
| GR31 | Create report group |
| GR55 | Generate report from template |

Library **0FL** = FI General Ledger. Key figures: balance, debit, credit, cumulative balance.

## S/4HANA Embedded Analytics

### Key CDS Views for Financial Reporting

| CDS View | Descripcion | Fiori App |
|----------|-------------|-----------|
| I_GLAccountLineItem | GL line items | F0708 |
| I_JournalEntry | Journal entries | F0710 |
| I_TrialBalance | Trial balance | F2217 |
| I_OperatingExpense | OpEx analysis | — |
| I_ProfitCenterHierarchy | PC hierarchy | — |
| I_CostCenter | Cost center master | — |
| C_TrialBalance | Consumption: trial balance | F1685 |
| C_JournalEntryItemBrowser | Consumption: journal entries | F3380 |

### Fiori KPI Tiles

| Tile | Descripcion | App ID |
|------|-------------|--------|
| Current Payables | AP outstanding | F0711A |
| Current Receivables | AR outstanding | F0711B |
| Cash Position | Bank balance | F1555 |
| Days Payable Outstanding | DPO | F0712A |
| Days Sales Outstanding | DSO | F0712B |
| Overdue Payables | Aging AP | F0713A |
| Overdue Receivables | Aging AR | F0713B |

## Segment Reporting

Enabled automatically in S/4HANA via:
- Document splitting (SPRO: `Financial Accounting > General Ledger > Business Transactions > Document Splitting`)
- Profit center derivation rules
- Each segment gets balanced financial statements
- CDS view: `I_GLAccountLineItem` filtered by SEGMENT field

## Key Financial KPIs

| KPI | Formula | Query Basis |
|-----|---------|-------------|
| DSO | (AR / Revenue) x Days | ACDOCA: KOART=D / KOART=S revenue accounts |
| DPO | (AP / COGS) x Days | ACDOCA: KOART=K / COGS accounts |
| Current Ratio | Current Assets / Current Liabilities | FSV nodes |
| Quick Ratio | (Cash + AR) / Current Liabilities | FSV nodes |
| Working Capital | Current Assets - Current Liabilities | FSV nodes |
| Gross Margin | (Revenue - COGS) / Revenue | PnL accounts |
| EBITDA | Operating Income + Depreciation | PnL + AFAB postings |

## MCP SQL — DSO Calculation

```sql
-- Calculo de DSO (Days Sales Outstanding)
SELECT
  SUM(CASE WHEN KOART = 'D' AND AUGDT = '00000000' THEN HSL ELSE 0 END) AS AR_BALANCE,
  SUM(CASE WHEN RACCT BETWEEN '{revenue_from}' AND '{revenue_to}' THEN ABS(HSL) ELSE 0 END) AS REVENUE,
  CASE
    WHEN SUM(CASE WHEN RACCT BETWEEN '{revenue_from}' AND '{revenue_to}' THEN ABS(HSL) ELSE 0 END) > 0
    THEN SUM(CASE WHEN KOART = 'D' AND AUGDT = '00000000' THEN HSL ELSE 0 END) /
         SUM(CASE WHEN RACCT BETWEEN '{revenue_from}' AND '{revenue_to}' THEN ABS(HSL) ELSE 0 END) * 365
    ELSE 0
  END AS DSO
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND RLDNR = '0L'
```

## Legal Consolidation — S/4HANA Group Reporting

| Component | Descripcion | Tcode |
|-----------|-------------|-------|
| FINCS | Group Reporting (replaces EC-CS) | — |
| Consolidation units | Company code mapping | SPRO |
| Elimination rules | IC elimination, equity | SPRO |
| Consolidation monitor | Status tracking | Fiori |
| Data collection | Flexible upload or real-time | FINCS |

## Tables for Financial Reporting

| Table | Descripcion | Key Fields |
|-------|-------------|------------|
| ACDOCA | Universal journal (primary) | RCOMP, RACCT, POPER, GJAHR, HSL |
| BKPF | Document header | BUKRS, BELNR, GJAHR, BLART |
| BSEG | Document line item (compat) | BUKRS, BELNR, GJAHR, BUZEI |
| FAGLFLEXT | GL totals (compat) | RRCTY, RLDNR, RACCT |
| SKA1 | GL master (CoA level) | KTOPL, SAKNR, BILKT |
| SKB1 | GL master (CoCd level) | BUKRS, SAKNR, MWSKZ |
| T011 | FSV header | VERSN |
| T011P | FSV items | VERSN, ERGSL, VONKT, BISKT |
