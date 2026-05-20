# Foreign Currency Valuation — FI

## Overview

Foreign currency valuation adjusts the local currency value of open items and GL balances denominated in foreign currencies to reflect current exchange rates at period-end or year-end. This is required by accounting standards (IFRS/IAS 21, US GAAP ASC 830) to report monetary items at closing rates.

In S/4HANA, **FAGL_FCV** is the primary transaction for foreign currency valuation, replacing the classic F.05.

---

## What Gets Valuated

| Item Type | Valuated? | Source | Example |
|-----------|-----------|--------|---------|
| Open AR items in foreign currency | Yes | Customer subledger | Invoice in USD, company code in EUR |
| Open AP items in foreign currency | Yes | Vendor subledger | Invoice in GBP, company code in EUR |
| GL balances in foreign currency | Yes | GL account balance | USD bank account in EUR company |
| Cleared items | No | Already realized | — |
| Items in local currency | No | No FX exposure | — |
| Statistical items (noted) | No | No real balance | — |

---

## Exchange Rate Configuration

### Exchange Rate Types

| Type | Description | Typical Use |
|------|-------------|-------------|
| M | Standard rate (average/ECB) | Standard translation, valuation |
| G | Buying rate (bank buying) | Asset valuation |
| B | Selling rate (bank selling) | Liability valuation |
| P | Budgeted/planned rate | Planning/budgeting |

### Key Transactions

| TCode | Purpose | Table |
|-------|---------|-------|
| OB08 | Maintain exchange rates | TCURR |
| OB07 | Define exchange rate types | TCURR |
| OB22 | Define exchange rate type for valuation | — |
| TCURR | Exchange rate table | Direct/indirect quotation |
| TCURF | Conversion factors | Prefix factors for rates |

### MCP SQL — Exchange Rates Lookup

```sql
-- Current exchange rates for a currency pair
SELECT KURST, FCURR, TCURR, GDATU, UKURS, FFACT, TFACT
FROM TCURR
WHERE FCURR = '{from_currency}'
  AND TCURR = '{to_currency}'
  AND KURST = 'M'
ORDER BY GDATU DESC
FETCH FIRST 10 ROWS ONLY
```

```sql
-- All exchange rates maintained for a key date (inverted date format)
SELECT KURST, FCURR, TCURR, GDATU, UKURS
FROM TCURR
WHERE GDATU <= '{inverted_date}'
  AND KURST = 'M'
  AND TCURR = '{local_currency}'
ORDER BY FCURR, GDATU DESC
```

---

## Valuation Methods (OB59)

| Method | Description | Behavior |
|--------|-------------|----------|
| **Lowest value principle** | Only post losses | Gains ignored, losses posted |
| **Strict lowest value** | Losses posted, gains only up to acquisition | Conservative approach |
| **Always valuate** | Post both gains and losses | Full mark-to-market |
| **Revaluate to acquisition** | Reset to original booking rate | Used for specific instruments |

### Valuation Areas

| Area | Purpose | Ledger |
|------|---------|--------|
| 0001 | Leading ledger valuation | 0L |
| 1001 | IFRS valuation | 2L (if multi-ledger) |
| 2001 | Tax valuation | 3L (if multi-ledger) |

---

## FAGL_FCV — Parameters and Execution

### Selection Parameters

| Parameter | Description | Typical Value |
|-----------|-------------|---------------|
| Company Code | BUKRS | Required |
| Key Date | Valuation date | Period-end date (e.g., 2026-03-31) |
| Valuation Area | Area from OB59 | 0001 |
| GL Account Range | Accounts to valuate | Leave blank for all |
| Customer Range | Customer accounts | Leave blank for all |
| Vendor Range | Vendor accounts | Leave blank for all |
| Valuation Method | From OB59 | Always valuate (typical) |
| Exchange Rate Type | M, G, B | M (standard) |
| Posting Period | Target period | Current period |
| Reversal Posting Date | First day next period | Auto-reverse |

### Execution Modes

| Mode | Description | Use |
|------|-------------|-----|
| Test Run | Simulate, no postings | Always run first |
| Batch Input | Create batch session | For review before posting |
| Direct Posting | Post immediately | Production run |
| Reset | Delete previous valuation run | Correct errors |

---

## Posting Logic

### Unrealized FX Gain (foreign currency appreciated)

```
Debit:  Balance Sheet Adjustment Account (BS)     [KDF account from OB09]
Credit: Unrealized FX Gain (P&L)                  [KDF account from OB09]
```

### Unrealized FX Loss (foreign currency depreciated)

```
Debit:  Unrealized FX Loss (P&L)                  [KDF account from OB09]
Credit: Balance Sheet Adjustment Account (BS)      [KDF account from OB09]
```

### Reversal (first day of next period)

```
Reverse the above entries automatically
```

### Realized FX Differences (during clearing: F-28, F-53, F-32)

```
Automatically posted using KDB key from OB09
Debit/Credit: Realized FX Gain/Loss (P&L)
```

---

## Account Determination — OB09

| Key | Description | Account Type |
|-----|-------------|-------------|
| KDB | Realized exchange rate differences | P&L (gain and loss accounts) |
| KDF | Unrealized exchange rate differences | P&L (gain and loss accounts) + BS adjustment |
| UMB | Balance sheet adjustment account | BS account for valuation postings |

### Configuration Table: T030H

| Field | Description |
|-------|-------------|
| KTOSL | Transaction key (KDB, KDF) |
| BUKRS | Company code |
| KTOPL | Chart of accounts |
| HKONT | GL account assigned |

### MCP SQL — Account Determination for FX

```sql
SELECT KTOSL, BUKRS, KTOPL, KOMOK, HKONT
FROM T030H
WHERE BUKRS = '{company_code}'
  AND KTOSL IN ('KDB', 'KDF')
ORDER BY KTOSL, KOMOK
```

---

## Parallel Currencies in S/4HANA

### ACDOCA Currency Fields

| Field | Description | Currency Key Field |
|-------|-------------|-------------------|
| RHCUR / HSL | Local currency amount | RWCUR (company code currency) |
| RKCUR / KSL | Group currency amount | Controlling area currency |
| ROCUR / OSL | Object currency amount | Object/cost center currency |
| RTCUR / TSL | Transaction currency amount | Document currency |
| RHCUR_2 / HSL2 | 2nd local currency | If configured |
| RHCUR_3 / HSL3 | 3rd local currency | If configured |

### MCP SQL — FX Exposure by Currency (Open Items)

```sql
-- Open items in foreign currency with current local currency value
SELECT a.WAERS AS DOC_CURRENCY,
       a.KOART AS ACCT_TYPE,
       COUNT(*) AS ITEM_COUNT,
       SUM(a.WRBTR) AS TOTAL_DOC_CCY,
       SUM(a.DMBTR) AS TOTAL_LOCAL_CCY,
       SUM(a.WRBTR) / NULLIF(SUM(a.DMBTR), 0) AS AVG_RATE
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART IN ('D', 'K')
  AND a.AUGBL = ''
  AND a.WAERS <> '{local_currency}'
  AND a.RLDNR = '0L'
GROUP BY a.WAERS, a.KOART
ORDER BY TOTAL_LOCAL_CCY DESC
```

```sql
-- GL accounts with foreign currency balances
SELECT a.RACCT, a.WAERS,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.WRBTR ELSE -a.WRBTR END) AS BALANCE_DOC_CCY,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS BALANCE_LOCAL_CCY
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.KOART = 'S'
  AND a.WAERS <> '{local_currency}'
  AND a.RLDNR = '0L'
  AND a.GJAHR = '{fiscal_year}'
GROUP BY a.RACCT, a.WAERS
HAVING SUM(CASE WHEN a.SHKZG = 'S' THEN a.WRBTR ELSE -a.WRBTR END) <> 0
ORDER BY a.RACCT
```

---

## Valuation History and Audit

### MCP SQL — FX Valuation Postings (Document Type SA)

```sql
-- Valuation documents posted by FAGL_FCV
SELECT a.BELNR, a.GJAHR, a.BUDAT, a.BLDAT, a.RACCT,
       a.WAERS, a.WRBTR, a.DMBTR, a.SHKZG,
       a.KUNNR, a.LIFNR, a.USNAM
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.BLART = 'SA'
  AND a.BKTXT LIKE '%VALUATION%'
  AND a.MONAT = '{period}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
ORDER BY a.BELNR, a.BUZEI
```

```sql
-- FX gain/loss P&L impact by period
SELECT a.MONAT, a.RACCT,
       SUM(CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END) AS FX_RESULT_LC
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.RACCT IN ('{fx_gain_acct}', '{fx_loss_acct}')
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
GROUP BY a.MONAT, a.RACCT
ORDER BY a.MONAT, a.RACCT
```

---

## Diagnostics and Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "No exchange rate found" | Rate not maintained for key date | OB08: enter rate for currency pair and date |
| "Valuation area not defined" | OB59 config missing | Define valuation area in OB59 |
| "Account determination missing" | KDF/KDB not configured | OB09: assign accounts for FX keys |
| Reversal not posted | Reversal date in closed period | Open target period (OB52) before running |
| Double valuation | Previous run not reset | Reset previous run, then re-execute |
| Wrong valuation method | Gains posted when only losses expected | OB59: verify method (lowest value vs always) |
| Zero valuation difference | Rate same as booking rate | Expected — no posting needed |
| Parallel currency mismatch | Group currency rate missing | Maintain rate for group currency in OB08 |

### Pre-Run Checklist

| Check | TCode | What to Verify |
|-------|-------|---------------|
| Exchange rates maintained | OB08 | All currency pairs for key date |
| Posting period open | OB52 | Current + next period (for reversal) |
| Account determination | OB09 | KDF and KDB accounts assigned |
| Valuation area | OB59 | Method and area configured |
| Previous run | FAGL_FCV | No duplicate run for same key date |
| Test run | FAGL_FCV | Execute test run first, review log |

---

## Related Transactions

| TCode | Description |
|-------|-------------|
| FAGL_FCV | Foreign currency valuation (S/4HANA) |
| F.05 | Foreign currency valuation (classic, deprecated) |
| OB08 | Maintain exchange rates |
| OB09 | Account determination for FX differences |
| OB59 | Define valuation methods |
| OB22 | Exchange rate type for valuation |
| S_ALR_87012326 | FX valuation log report |
| FAGL_FC_TRANS | Foreign currency translation (group reporting) |
