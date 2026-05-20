# S/4HANA 2023 — Embedded Analytics FI

## Concepto

```
Analitica en tiempo real directamente en S/4HANA, sin extraer a BW:
- CDS Views analiticas sobre ACDOCA (datos live)
- Fiori KPI tiles en Launchpad
- Drilldown desde KPI → lista → documento individual
- Custom CDS views via Key User tools
- Integracion SAP Analytics Cloud (SAC) para dashboards avanzados
```

## CDS Views Analiticas — Finance

### Journal Entry & GL

| CDS View | Descripcion | Tipo |
|----------|-------------|------|
| I_JournalEntry | Cabecera asiento contable | Basic |
| I_JournalEntryItem | Posiciones asiento contable | Basic |
| I_JournalEntryItemBasic | Journal entry items (API) | Basic |
| I_GLAccountLineItem | Partidas individuales GL | Analytical |
| I_GLAccountLineItemRawData | GL raw data sin agregacion | Basic |
| I_GLAccountBalance | Saldos GL por periodo | Analytical |
| I_TrialBalance | Balance de comprobacion | Analytical |
| I_OperatingExpense | Gastos operativos | Analytical |
| I_GLAccountYearBalance | Saldo anual GL | Analytical |
| C_TrialBalance | Consumption view trial balance | Consumption |
| C_JournalEntryItemBrowser | Browser de asientos | Consumption |

### Accounts Payable

| CDS View | Descripcion | Tipo |
|----------|-------------|------|
| I_SupplierLineItem | Partidas proveedor | Analytical |
| I_SupplierOpenItem | Partidas abiertas proveedor | Analytical |
| I_SupplierDaysSalesOutstanding | DPO proveedor | Analytical |
| I_APAgingReport | Aging AP | Analytical |
| C_PayablesByDueDateOvw | Payables by due date | Consumption |

### Accounts Receivable

| CDS View | Descripcion | Tipo |
|----------|-------------|------|
| I_CustomerLineItem | Partidas cliente | Analytical |
| I_CustomerOpenItem | Partidas abiertas cliente | Analytical |
| I_CustomerDaysSalesOutstanding | DSO cliente | Analytical |
| I_ARAgingReport | Aging AR | Analytical |
| C_ReceivablesByDueDateOvw | Receivables by due date | Consumption |

### Asset Accounting

| CDS View | Descripcion | Tipo |
|----------|-------------|------|
| I_FixedAsset | Datos maestros activo | Basic |
| I_FixedAssetBalance | Saldos activos | Analytical |
| I_FixedAssetAcquisition | Adquisiciones | Analytical |
| I_FixedAssetDepreciation | Depreciacion | Analytical |

### Cash & Treasury

| CDS View | Descripcion | Tipo |
|----------|-------------|------|
| I_CashFlowItem | Items cash flow | Analytical |
| I_BankAccountBalance | Saldos cuentas bancarias | Analytical |

## Fiori KPI Tiles — Finance

### Tiles predefinidos

| Tile | KPI | Refresh |
|------|-----|---------|
| Current Payables | Total AP pendiente | Real-time |
| Current Receivables | Total AR pendiente | Real-time |
| Overdue Payables | AP vencido | Real-time |
| Overdue Receivables | AR vencido | Real-time |
| Cash Position | Posicion liquidez | Real-time |
| Days Payable Outstanding | DPO | Daily |
| Days Sales Outstanding | DSO | Daily |
| Revenue This Period | Ingresos periodo | Real-time |
| Operating Expenses | Gastos operativos | Real-time |
| Net Income | Resultado neto | Real-time |
| Depreciation This Period | Depreciacion periodo | Daily |
| Bank Account Balances | Saldos bancarios | Real-time |

### Configuracion de tiles

```
1. Fiori Launchpad Designer (/UI2/FLPD_CONF)
2. Seleccionar catalogo financiero (SAP_FIN_BC_*)
3. Agregar tiles al grupo del usuario
4. Configurar parametros: sociedad, periodo, moneda
5. Asignar a rol/usuario

Tipos de tile:
  - Static: valor fijo
  - Dynamic: CDS query con refresh automatico
  - News: ultimos documentos creados
  - KPI: indicador con umbral (verde/amarillo/rojo)
```

## Financial Dashboards

### Dashboard CFO (F3045A Financial Overview Page)

```
Componentes:
  - Revenue trend (12 meses)
  - Expense breakdown por categoria
  - Cash position evolution
  - AR/AP aging comparison
  - Top 10 customers by outstanding
  - Top 10 vendors by payables
  - Budget vs actual
  - Intercompany balances
```

### Dashboard Controller

```
Componentes:
  - Trial balance comparison (current vs prior year)
  - Close status por sociedad
  - Journal entry volume trends
  - Unusual postings (amount > threshold)
  - Period comparison P&L
  - Balance sheet waterfall
```

## SAP Analytics Cloud (SAC) Integration

```
Conexion directa S/4HANA → SAC:
  1. Live Data Connection: CDS views expuestas como datasource
  2. Import Connection: extraccion periodica para historicos
  3. Planning: SAC planning → writeback a S/4 (via API)

Modelos financieros en SAC:
  - Financial Planning & Analysis (FP&A)
  - Cash flow forecasting
  - What-if scenarios
  - Predictive analytics (ML-based)
  - Consolidation reporting
```

## Custom Analytics — Key User

### Crear query analitica custom

```
1. Key User → Custom Analytical Queries
2. Seleccionar CDS view base (ej: I_JournalEntryItem)
3. Definir dimensiones (sociedad, cuenta, profit center, periodo)
4. Definir medidas (HSL sum, count documents)
5. Definir filtros fijos (ej: solo ledger 0L)
6. Publicar como tile o report
```

### Crear CDS view custom

```
1. Key User → Custom CDS Views
2. Seleccionar tabla/vista base
3. Agregar joins (ej: ACDOCA + SKA1 para textos cuenta)
4. Definir campos seleccionados
5. Agregar campos calculados
6. Publicar
7. Usar como base para query analitica o tile
```

## KPIs Financieros — Formulas

| KPI | Formula | CDS Base |
|-----|---------|----------|
| DSO | (AR Outstanding / Revenue) × Days | I_CustomerDaysSalesOutstanding |
| DPO | (AP Outstanding / COGS) × Days | I_SupplierDaysSalesOutstanding |
| Current Ratio | Current Assets / Current Liabilities | I_GLAccountBalance |
| Quick Ratio | (Cash + AR) / Current Liabilities | I_GLAccountBalance |
| Working Capital | Current Assets - Current Liabilities | I_GLAccountBalance |
| EBITDA | Revenue - Expenses + Depreciation + Amortization | I_OperatingExpense |
| Gross Margin | (Revenue - COGS) / Revenue | I_JournalEntryItem |
| Net Margin | Net Income / Revenue | I_JournalEntryItem |

## Queries MCP para Analytics

```sql
-- Trial balance por periodo
SELECT RACCT, SUM(CASE WHEN DRCRK='S' THEN HSL ELSE 0 END) as DEBIT,
       SUM(CASE WHEN DRCRK='H' THEN HSL ELSE 0 END) as CREDIT,
       SUM(HSL) as BALANCE
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}' AND POPER <= '{periodo}'
AND RLDNR = '0L'
GROUP BY RACCT
ORDER BY RACCT

-- P&L por profit center
SELECT PRCTR, RACCT, SUM(HSL) as TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}' AND RLDNR = '0L'
AND RACCT BETWEEN '400000' AND '899999'
GROUP BY PRCTR, RACCT
ORDER BY PRCTR, RACCT

-- Aging receivables
SELECT KUNNR, BELNR, BUDAT, DMBTR,
  CASE
    WHEN DATEDIFF(CURRENT_DATE, ZFBDT) <= 30 THEN '0-30'
    WHEN DATEDIFF(CURRENT_DATE, ZFBDT) <= 60 THEN '31-60'
    WHEN DATEDIFF(CURRENT_DATE, ZFBDT) <= 90 THEN '61-90'
    ELSE '90+'
  END as AGING_BUCKET
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND KOART = 'D' AND AUGDT = ''
AND RLDNR = '0L'

-- Monthly revenue trend
SELECT POPER, SUM(HSL) as REVENUE
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}' AND RLDNR = '0L'
AND RACCT BETWEEN '800000' AND '899999'
GROUP BY POPER
ORDER BY POPER

-- Journal entry volume by user
SELECT USNAM, COUNT(DISTINCT BELNR) as DOC_COUNT, SUM(ABS(HSL)) as TOTAL_AMOUNT
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}' AND RLDNR = '0L'
AND POPER = '{periodo}'
GROUP BY USNAM
ORDER BY DOC_COUNT DESC
```

## Comparacion: SIS/Report Painter vs Embedded Analytics

| Aspecto | Clasico (Report Painter) | Embedded Analytics |
|---------|------------------------|-------------------|
| Datos | Tablas de totales | ACDOCA live |
| Latencia | Batch (despues de cierre) | Real-time |
| UI | SAP GUI | Fiori |
| Custom | GRR1/GR31 (complejo) | Key User (low-code) |
| Drilldown | Limitado | Completo hasta doc |
| Mobile | No | Si (responsive) |
| Sharing | Print/email | URL/dashboard |
| ML/AI | No | SAC predictive |
