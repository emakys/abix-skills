# Operaciones de Cierre FI — S/4HANA

## Monthly Period-End Closing Checklist

| Step | Descripcion | Tcode | Timing |
|------|-------------|-------|--------|
| 1 | Post recurring entries | FBD1 (crear), F.14 (ejecutar) | Day 1 |
| 2 | Post accruals/deferrals | FBS1 (crear), F.81 (reversar) | Day 1 |
| 3 | GR/IR clearing reclassification | F.19 | Day 2 |
| 4 | Foreign currency valuation | FAGL_FCV | Day 2-3 |
| 5 | Regroup receivables/payables | FAGL_FC_TRANSLATION / F101 | Day 3 |
| 6 | Depreciation run | AFAB | Day 3 |
| 7 | CO allocations | KSU5, KSV5, KB21N | Day 4 |
| 8 | Reconcile CO-FI | KALC / FAGLCO33 | Day 4 |
| 9 | Financial statements review | S_ALR_78012547 / FAGLB03 | Day 5 |
| 10 | Close period | OB52 | Day 5 |

## Year-End Closing — Additional Steps

| Step | Descripcion | Tcode | Notas |
|------|-------------|-------|-------|
| 1 | Balance carryforward GL | FAGLGVTR | Ejecutar antes de cerrar periodo 12 |
| 2 | Balance carryforward AP | F.07 (vendor) | Arrastrar saldos abiertos |
| 3 | Balance carryforward AR | F.07 (customer) | Arrastrar saldos abiertos |
| 4 | Asset fiscal year change | AJRW | Abrir nuevo ejercicio AA |
| 5 | Asset year-end close | AJAB | Cerrar ejercicio AA anterior |
| 6 | Retained earnings posting | Automatic via OB53 | Cuenta de resultados acumulados |
| 7 | PnL reset to zero | Automatic FAGLGVTR | Saldos PnL van a retained earnings |
| 8 | Tax reporting finalization | S_ALR_87012357 | Declaraciones anuales |

### Retained Earnings Account (OB53)

SPRO Path: `Financial Accounting > General Ledger > Master Data > G/L Accounts > Preparations > Define Retained Earnings Account`

- One account per PnL account type (X = expenses, N = revenues)
- Balance sheet account type: equity
- FAGLGVTR uses this to zero out PnL and post net result

## Recurring Documents (FBD1 / F.14)

```
Flujo:
  FBD1 → Crear documento modelo recurrente
       → Definir: first run date, last run date, interval (monthly/quarterly)
       → Posting key, account, amount
  F.14 → Ejecutar batch → genera documentos reales
  FBD3 → Visualizar documento recurrente
  FBD5 → Listar documentos recurrentes
```

### MCP SQL — Recurring Documents Pending Execution

```sql
-- Documentos recurrentes pendientes de ejecucion
SELECT BUKRS, BELNR, GJAHR, BLART, BUDAT, CPUDT, USNAM
FROM BKPF
WHERE BUKRS = '{company_code}'
  AND TCODE = 'F.14'
  AND GJAHR = '{year}'
  AND MONAT = '{period}'
ORDER BY BUDAT DESC
```

## Accruals and Deferrals

| Metodo | Tcode | Descripcion |
|--------|-------|-------------|
| Manual reversal doc | FBS1 | Crear doc con fecha de reversa |
| Batch reversal | F.81 | Reversar accruals en masa |
| Accrual Engine (ACE) | ACACACTREE01 | S/4HANA: engine automatizado |

### Accrual Engine (S/4HANA)

SPRO Path: `Financial Accounting > Financial Accounting Global Settings > Accrual Engine`

- Accrual objects linked to contracts or purchase orders
- Automatic posting and reversal based on accrual method
- Integration with Revenue Recognition (IFRS 15)

## Foreign Currency Valuation (FAGL_FCV)

SPRO Path: `Financial Accounting > General Ledger > Periodic Processing > Valuate > Foreign Currency Valuation`

| Parameter | Descripcion |
|-----------|-------------|
| Valuation method | Standard (SPRO: OB59) |
| Exchange rate type | M (average), G (buying), B (selling) |
| Valuation date | Period end date |
| Posting date | Period end date |
| Reversal date | First day of next period |
| Account determination | KDF (exchange rate diff) via OBA1 |

### MCP SQL — Foreign Currency Open Items

```sql
-- Partidas abiertas en moneda extranjera para valuacion
SELECT RCOMP, RACCT, RHCUR, RWCUR, TSL, HSL, KSL,
       DRCRK, BUDAT, BELNR, BUZEI
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND POPER = '{period}'
  AND GJAHR = '{year}'
  AND RWCUR <> RHCUR
  AND AUGDT = '00000000'
ORDER BY RACCT, RWCUR
```

## GR/IR Clearing Reclassification (F.19)

Purpose: Reclassify GR/IR balance to proper BS accounts at period end.

| Scenario | Reclassify To |
|----------|---------------|
| GR posted, IR pending | Accrued liabilities |
| IR posted, GR pending | Prepaid assets |

### MCP SQL — Uncleared GR/IR Items

```sql
-- Partidas GR/IR no compensadas
SELECT RACCT, RCOMP, LIFNR, BELNR, BUZEI,
       HSL, TSL, BUDAT, SGTXT
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND RACCT IN ('{grir_account}')
  AND AUGDT = '00000000'
  AND GJAHR = '{year}'
ORDER BY RACCT, LIFNR
```

## Period Lock (OB52)

SPRO Path: `Financial Accounting > Financial Accounting Global Settings > Document > Posting Periods > Open and Close Posting Periods`

### Table T001B — Posting Period Variants

| Campo | Descripcion |
|-------|-------------|
| RPTS | Variant |
| BKONT | Account type (+, A, D, K, M, S) |
| VONBR | From account |
| BISBR | To account |
| FRPE1 | From period 1 |
| BIPE1 | To period 1 |
| FRPE2 | From period 2 (special) |
| BIPE2 | To period 2 (special) |

Account types: `+` = all, `A` = assets, `D` = customers, `K` = vendors, `M` = materials, `S` = GL accounts.

### MCP SQL — Current Open Periods

```sql
-- Periodos abiertos actuales
SELECT RPTS, BKONT, VONBR, BISBR,
       FRPE1, BIPE1, FRPE2, BIPE2,
       FRBU1, BIBU1, FRBU2, BIBU2
FROM T001B
WHERE RPTS = '{period_variant}'
ORDER BY BKONT, VONBR
```

## Depreciation Run (AFAB)

| Parameter | Descripcion |
|-----------|-------------|
| Company code | BUKRS |
| Fiscal year | GJAHR |
| Posting period | MONAT |
| Reason for posting | 01=planned, 04=unplanned |
| Test run | Always run test first |
| List assets | Show details |

### MCP SQL — Depreciation Posted per Period

```sql
-- Depreciacion registrada por periodo
SELECT RACCT, POPER, GJAHR,
       SUM(HSL) AS TOTAL_DEPRECIATION,
       COUNT(*) AS NUM_POSTINGS
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND AWTYP = 'ANLA'
ORDER BY RACCT, POPER
```

## CO-FI Reconciliation

| Tcode | Descripcion |
|-------|-------------|
| KALC | Real-time reconciliation CO-FI |
| FAGLCO33 | Reconciliation ledger (new GL) |
| COSS/COSP | CO actual postings |
| FAGLFLEXT | GL totals (S/4: replaced by ACDOCA) |

### MCP SQL — CO-FI Differences Check

```sql
-- Verificar diferencias CO-FI por centro de costo
SELECT RCNTR, RACCT, POPER,
       SUM(HSL) AS FI_AMOUNT,
       SUM(KSL) AS CO_AMOUNT,
       SUM(HSL) - SUM(KSL) AS DIFFERENCE
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND RCNTR <> ''
GROUP BY RCNTR, RACCT, POPER
HAVING SUM(HSL) <> SUM(KSL)
ORDER BY RCNTR
```

## S/4HANA Financial Close Cockpit

- App: **Manage Closing Tasks** (F2723)
- Template-based task lists for monthly/quarterly/yearly close
- Dependency management between tasks
- Status tracking and notifications
- Integration with ABAP jobs for automated steps

## Diagnostic Checklist — Common Closing Issues

| Issue | Causa | Solucion |
|-------|-------|----------|
| Period already closed | OB52 locked | Reopen in OB52 temporarily |
| Carryforward fails | Prior year not closed | Run AJAB first for AA |
| FCV differences | Wrong exchange rate type | Check OB08 rates for period end |
| GR/IR imbalance | Missing invoices | Run ME2M to find pending GRs |
| Depreciation not posting | Area not active | Check OADB config |
| Recurring doc error | Expired validity date | Extend in FBD2 |
| Accrual not reversed | F.81 not executed | Run F.81 for prior period |
| CO-FI difference | Statistical posting | Verify cost element type |

## Key Tables Reference

| Table | Descripcion | Uso en cierre |
|-------|-------------|---------------|
| ACDOCA | Universal journal | All FI postings |
| BKPF | Document header | Period, doc type |
| T001B | Period variants | Open/close periods |
| FAGLFLEXT | GL totals (compat) | Trial balance |
| ANLP | Depreciation posted | AA reconciliation |
| COSP/COSS | CO actuals | CO-FI reconciliation |
| T009B | Fiscal year periods | Period definitions |
