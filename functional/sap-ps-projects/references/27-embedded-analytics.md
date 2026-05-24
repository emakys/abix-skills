# Embedded Analytics PS — SAP Project System

## Indice
1. Arquitectura de Analytics en S/4HANA
2. CDS Analytical Queries para PS
3. KPIs de Proyecto en Analytics
4. Varianzas y Control Presupuestario
5. Custom Analytical Queries
6. Integracion con SAP Analytics Cloud (SAC)
7. Real-Time Reporting sobre ACDOCA
8. Dashboards KPI de Proyecto
9. Herramientas y Transacciones
10. Buenas Practicas

---

## 1. Arquitectura de Analytics en S/4HANA

### 1.1 Stack de Analytics

```
┌─────────────────────────────────────────────────────┐
│                  CAPA DE PRESENTACION               │
│  Fiori Analytical Apps | SAC Dashboard | Report Writer│
├─────────────────────────────────────────────────────┤
│                  CAPA DE QUERY                      │
│  CDS Analytical Queries (2C_*) | Query Designer     │
│  OData Services | InA (Info Access) Protocol        │
├─────────────────────────────────────────────────────┤
│                  CAPA SEMANTICA (CDS Views)          │
│  Consumption Views (C_*) | Interface Views (I_*)    │
│  Extension Views | Basic Interface Views             │
├─────────────────────────────────────────────────────┤
│                  CAPA DE DATOS                       │
│  ACDOCA | RPSCO | BPGE | BPJA | PRPS | PROJ | AFVC  │
└─────────────────────────────────────────────────────┘
```

### 1.2 Tipos de Objetos CDS para Analytics

| Tipo | Prefijo | Descripcion | Uso |
|------|---------|-------------|-----|
| Basic Interface View | `I_` | Datos basicos de tabla | Base para otras views |
| Composite Interface View | `I_` | Join de multiples tablas | Logica de negocio |
| Consumption View | `C_` | Para consumo directo | OData, Fiori |
| Analytical Query | `2C_` | Query analitica (multidim) | SAC, Report Designer |
| Projection View | `P_` | Subset de campos | Seguridad, performance |

### 1.3 Annotations Clave para Analytics

```abap
@Analytics.query: true              " Define una Analytical Query
@Analytics.dataCategory: #CUBE     " Vista cubo OLAP
@Analytics.dataCategory: #DIMENSION " Dimension
@Analytics.dataCategory: #FACT     " Tabla de hechos

@Aggregation.default: #SUM         " Suma por defecto
@Aggregation.default: #AVG         " Media
@Aggregation.default: #MIN         " Minimo

@Semantics.amount.currencyCode: 'Currency'  " Campo importe
@Semantics.quantity.unitOfMeasure: 'Unit'   " Campo cantidad
@Semantics.fiscal.year: true               " Ejercicio fiscal
@Semantics.fiscal.period: true             " Periodo fiscal
```

---

## 2. CDS Analytical Queries para PS

### 2.1 Queries Estandar Entregadas por SAP

| Query | Descripcion | KPIs |
|-------|-------------|------|
| `2C_PS_PROJECT_COST_ANALYSIS` | Analisis costes proyecto | Plan, Actual, Varianza |
| `2C_PS_PROJECT_BUDGET_ANALYSIS` | Analisis presupuesto | Budget, Consumed, Available |
| `2C_PS_PROJECT_EARNED_VALUE` | Valor ganado (EVM) | PV, EV, AC, CPI, SPI |
| `2C_PS_PROJ_REVENUE_ANALYSIS` | Analisis ingresos (CPM) | Revenue plan, actual, WIP |
| `2C_PS_PORTFOLIO_OVERVIEW` | Vision portfolio | # proyectos, budget total |
| `2C_PS_WBS_COST_DETAILS` | Costes detalle WBS | Por elemento de coste, periodo |
| `2C_PS_COMMITMENT_ANALYSIS` | Compromisos abiertos | Por proveedor, material |
| `2C_PS_NETWORK_SCHEDULE` | Programacion redes | Fechas, duracion, atraso |

### 2.2 Estructura de una CDS Analytical Query

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Project Cost Analysis'
@Analytics.query: true
@VDM.viewType: #CONSUMPTION

define view entity 2C_PS_PROJECT_COST_ANALYSIS
  as select from C_ProjectPlanVsActual
{
  " === DIMENSIONES ===
  @AnalyticsDetails.query.display: #TEXT
  @Consumption.filter: { selectionType: #INTERVAL, mandatory: false }
  CompanyCode,

  @AnalyticsDetails.query.display: #TEXT
  ProjectID,

  @AnalyticsDetails.query.display: #TEXT
  WBSElement,

  @Semantics.fiscal.year: true
  FiscalYear,

  @Semantics.fiscal.period: true
  FiscalPeriod,

  @AnalyticsDetails.query.display: #TEXT
  CostElement,

  " === MEDIDAS (KFIGURAS CLAVE) ===
  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'Currency'
  PlannedCost,

  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'Currency'
  ActualCost,

  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'Currency'
  BudgetAmount,

  " === CIFRAS CALCULADAS ===
  @DefaultAggregation: #FORMULA
  PlannedCost - ActualCost as CostVariance,

  @DefaultAggregation: #FORMULA
  case when PlannedCost <> 0
    then ( ActualCost / PlannedCost ) * 100
    else 0
  end as CompletionPercent,

  Currency
}
```

### 2.3 CDS View Intermedia para EVM

```abap
" Vista de Valor Ganado como base para queries
define view entity C_ProjectEarnedValueBase
  as select from I_WBSElement as wbs
  join I_ProjectBudget as bud on wbs.WBSElementInternalID = bud.WBSElementInternalID
  join I_WBSActualCostByPeriod as act on wbs.WBSElementInternalID = act.WBSElementInternalID
{
  key wbs.ProjectInternalID,
  key wbs.WBSElementInternalID,
  wbs.WBSElement,
  wbs.ProjectID,
  act.FiscalYear,
  act.FiscalPeriod,

  " Budget at Completion
  bud.TotalBudget                           as BAC,

  " Earned Value = BAC x % completado
  bud.TotalBudget * wbs.ProgressPercent / 100  as EV,

  " Planned Value = BAC x % planificado
  bud.TotalBudget * wbs.PlannedProgressPercent / 100 as PV,

  " Actual Cost
  act.ActualCostInTransactionCurrency       as AC,

  " KPIs derivados
  case when act.ActualCostInTransactionCurrency <> 0
    then ( bud.TotalBudget * wbs.ProgressPercent / 100 )
         / act.ActualCostInTransactionCurrency
    else 1
  end as CPI,

  case when ( bud.TotalBudget * wbs.PlannedProgressPercent / 100 ) <> 0
    then ( bud.TotalBudget * wbs.ProgressPercent / 100 )
         / ( bud.TotalBudget * wbs.PlannedProgressPercent / 100 )
    else 1
  end as SPI,

  wbs.CompanyCode,
  act.TransactionCurrency as Currency
}
```

---

## 3. KPIs de Proyecto en Analytics

### 3.1 KPIs Financieros

| KPI | Formula | Umbral VERDE | Umbral AMBAR | Umbral ROJO |
|-----|---------|--------------|--------------|-------------|
| Budget Utilization % | Actual/Budget*100 | <80% | 80-100% | >100% |
| Cost Variance (CV) | EV - AC | CV > 0 | -5% a 0% | CV < -5% |
| Cost Performance Index (CPI) | EV/AC | >1.0 | 0.9-1.0 | <0.9 |
| Forecast at Completion (EAC) | BAC/CPI | EAC < BAC | EAC = BAC | EAC > BAC |
| Variance at Completion (VAC) | BAC - EAC | >0 | 0 | <0 |
| To-Complete PI (TCPI) | (BAC-EV)/(BAC-AC) | <1.1 | 1.1-1.2 | >1.2 |

### 3.2 KPIs de Cronograma

| KPI | Formula | VERDE | AMBAR | ROJO |
|-----|---------|-------|-------|------|
| Schedule Variance (SV) | EV - PV | SV > 0 | -5% | SV < -10% |
| Schedule Performance (SPI) | EV/PV | >1.0 | 0.9-1.0 | <0.9 |
| Days Ahead/Behind | Calculado | >0 | 0 a -5 | <-5 |
| Milestone Completion | % hitos on time | >95% | 80-95% | <80% |

### 3.3 KPIs Operativos

| KPI | Descripcion | Fuente |
|-----|-------------|--------|
| Open Commitments | Valor de pedidos abiertos | RPSCO WRTTP=40 |
| Billed vs Plan | Facturado vs plan de facturacion | SD-PS |
| WIP Value | Trabajo en proceso sin facturar | CO-PA RA |
| Resource Utilization | % de horas confirmadas vs planificadas | AFVC/CATA |
| Issue Count | Numero de incidencias abiertas | Custom |
| Change Request Count | Solicitudes de cambio | Custom |

---

## 4. Varianzas y Control Presupuestario

### 4.1 Tipos de Varianza en PS

```
VARIANZA DE COSTE (Cost Variance):
  CV = EV - AC
  Negativo = por encima del presupuesto
  Positivo = por debajo del presupuesto

VARIANZA DE CRONOGRAMA (Schedule Variance):
  SV = EV - PV
  Negativo = atrasado
  Positivo = adelantado

VARIANZA DE PRESUPUESTO (Budget Variance):
  BV = Budget - Actual - Commitment
  Negativo = exceso de presupuesto
```

### 4.2 Analisis de Varianzas en ACDOCA

```sql
-- Varianza de costes por proyecto y elemento
SELECT
    proj.PSPID                                  AS Proyecto,
    prps.POSID                                  AS WBS,
    acd.KSTAR                                   AS ElementeCoste,
    SUM(CASE WHEN acd.WRTTP = '01' THEN acd.HSL ELSE 0 END) AS Planificado,
    SUM(CASE WHEN acd.WRTTP = '10' THEN acd.HSL ELSE 0 END) AS Real,
    SUM(CASE WHEN acd.WRTTP = '01' THEN acd.HSL ELSE 0 END)
        - SUM(CASE WHEN acd.WRTTP = '10' THEN acd.HSL ELSE 0 END)
                                                AS Varianza,
    CASE
        WHEN SUM(CASE WHEN acd.WRTTP = '01' THEN acd.HSL ELSE 0 END) <> 0
        THEN ABS(
            ( SUM(CASE WHEN acd.WRTTP = '10' THEN acd.HSL ELSE 0 END)
              / SUM(CASE WHEN acd.WRTTP = '01' THEN acd.HSL ELSE 0 END) )
            * 100 - 100
        )
        ELSE 0
    END                                         AS VarianzaPct
FROM RPSCO AS acd
JOIN PRPS ON acd.OBJNR = PRPS.OBJNR
JOIN PROJ ON PRPS.PSPHI = PROJ.PSPNR
WHERE acd.GJAHR = '2024'
    AND acd.VERSN = '000'
    AND acd.WRTTP IN ('01', '10')
GROUP BY proj.PSPID, prps.POSID, acd.KSTAR
HAVING ABS(
    SUM(CASE WHEN acd.WRTTP = '10' THEN acd.HSL ELSE 0 END)
    - SUM(CASE WHEN acd.WRTTP = '01' THEN acd.HSL ELSE 0 END)
) > 1000  -- Solo varianzas > 1.000 EUR
ORDER BY ABS(Varianza) DESC
```

### 4.3 Control de Presupuesto Real-Time

```sql
-- Estado presupuestario en tiempo real
SELECT
    prps.POSID,
    bpge.WLGES          AS PresupuestoTotal,
    bpge.WLIBFR         AS PresupuestoLiberado,
    COALESCE(act.Real, 0)     AS CostesReales,
    COALESCE(obl.Compromisos, 0) AS Compromisos,
    bpge.WLIBFR
        - COALESCE(act.Real, 0)
        - COALESCE(obl.Compromisos, 0)   AS Disponible,
    CASE
        WHEN bpge.WLIBFR > 0 THEN
            (COALESCE(act.Real, 0) / bpge.WLIBFR) * 100
        ELSE 0
    END AS PorcentajeUtilizado,
    CASE
        WHEN bpge.WLIBFR > 0 AND
             (COALESCE(act.Real,0) + COALESCE(obl.Compromisos,0)) > bpge.WLIBFR
        THEN 'ROJO'
        WHEN bpge.WLIBFR > 0 AND
             (COALESCE(act.Real,0) + COALESCE(obl.Compromisos,0)) > bpge.WLIBFR * 0.9
        THEN 'AMBAR'
        ELSE 'VERDE'
    END AS Semaforo
FROM PRPS
JOIN BPGE ON PRPS.OBJNR = BPGE.OBJNR AND BPGE.VORGA = 'KOBU'
LEFT JOIN (
    SELECT PSPNR, SUM(HSL) AS Real
    FROM ACDOCA WHERE GJAHR = '2024' AND PSPNR <> ''
    GROUP BY PSPNR
) AS act ON PRPS.PSPNR = act.PSPNR
LEFT JOIN (
    SELECT OBJNR, SUM(WKBTR) AS Compromisos
    FROM RPSCO WHERE WRTTP = '40' AND GJAHR = '2024'
    GROUP BY OBJNR
) AS obl ON PRPS.OBJNR = obl.OBJNR
WHERE PRPS.PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
ORDER BY PorcentajeUtilizado DESC
```

---

## 5. Custom Analytical Queries

### 5.1 Crear Custom Query via CDS (Developer)

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Z: Project Cost Control Custom'
@Analytics.query: true
@VDM.viewType: #CONSUMPTION

define view entity ZC_PS_COST_CONTROL_QUERY
  as select from ZC_PS_COST_BASE  " Custom base view
{
  " Dimensiones de navegacion
  @AnalyticsDetails.query.display: #KEY_TEXT
  @Consumption.filter: { selectionType: #SINGLE, mandatory: true }
  ProjectID,

  @AnalyticsDetails.query.display: #TEXT
  @Consumption.filter: { selectionType: #MULTIPLE, mandatory: false }
  WBSElement,

  @AnalyticsDetails.query.display: #TEXT
  @Consumption.filter: { selectionType: #MULTIPLE, mandatory: false }
  CostElementGroup,

  @Semantics.fiscal.year: true
  @Consumption.filter: { selectionType: #INTERVAL, mandatory: false }
  FiscalYear,

  " Medidas principales
  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'ProjectCurrency'
  PlannedCostTotal,

  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'ProjectCurrency'
  ActualCostYTD,

  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'ProjectCurrency'
  CommitmentTotal,

  @DefaultAggregation: #SUM
  @Semantics.amount.currencyCode: 'ProjectCurrency'
  ReleasedBudget,

  " KPIs calculados
  @DefaultAggregation: #FORMULA
  ReleasedBudget - ActualCostYTD - CommitmentTotal as AvailableBudget,

  @DefaultAggregation: #FORMULA
  case when ReleasedBudget > 0
    then ( ActualCostYTD / ReleasedBudget ) * 100
    else 0
  end as BudgetUtilizationPct,

  ProjectCurrency
}
```

### 5.2 Crear Query via Query Designer (Sin ABAP)

**Transaccion:** `RSRT` → Query Designer
**O via Fiori:** "Query Browser" app

**Pasos:**
```
1. RSRT → "New Query"
2. Seleccionar InfoProvider: "2C_PS_PROJECT_COST_ANALYSIS"
3. Arrastrar dimensiones al area de filas/columnas
4. Arrastrar KPIs al area de datos
5. Definir filtros por defecto
6. Crear formulas personalizadas (Calculated Key Figures)
7. Guardar con nombre Z_
8. Publicar
```

---

## 6. Integracion con SAP Analytics Cloud (SAC)

### 6.1 Conexion Live a S/4HANA

**Tipo de conexion:** SAP S/4HANA Live Connection
**Protocolo:** SAP HANA Info Access (InA)

**Configuracion en S/4HANA:**
```
Transaccion: RSRT2 → Enable for external access
O via: /n/iwbep/fiori_usage → activar CDS Views para InA

Datos requeridos por SAC:
  - Host: https://s4host.empresa.com
  - OData endpoint: /sap/opu/odata/sap/
  - Usuario: tipo de comunicacion (no dialog)
  - SSO configurado (SAP Cloud Connector si on-prem)
```

### 6.2 Modelo en SAC para PS

```
1. SAC → Modelos → Nuevo Modelo
2. Tipo: "Live Data Connection"
3. Fuente: S/4HANA (la conexion creada)
4. Query: 2C_PS_PROJECT_COST_ANALYSIS
5. Dimensiones importadas automaticamente
6. Medidas importadas automaticamente
7. Guardar modelo "PS_Project_Costs"
```

### 6.3 Dashboard SAC para Proyectos

**Componentes tipicos de un dashboard PS en SAC:**

```
┌──────────────────────────────────────────────────────┐
│  PORTFOLIO OVERVIEW                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
│  │ 42       │ │ 38.5M    │ │ 31.2M    │ │ 81%    │  │
│  │ Proyectos│ │ Budget   │ │ Actual   │ │ Util % │  │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘  │
├──────────────────────────────────────────────────────┤
│  ● Budget Trend por Mes (Bar + Line)                 │
│  ● Top 10 Proyectos por Varianza (Waterfall)         │
├─────────────────────────┬────────────────────────────┤
│  Estado Proyectos       │  CPI vs SPI Scatter        │
│  Verde: 28  (67%)       │  ·  ·  ·                   │
│  Ambar: 10  (24%)       │    ·· ·                    │
│  Rojo:   4  ( 9%)       │  ·       ·                 │
└─────────────────────────┴────────────────────────────┘
```

### 6.4 Smart Predict en SAC para Proyectos

SAC Smart Predict puede usarse para:
- Forecast automatico de costes finales (EAC)
- Prediccion de retrasos en cronograma
- Deteccion de anomalias en consumo de presupuesto
- Clasificacion de proyectos en riesgo

```
SAC → Smart Predict → Regression
  Objetivo: ActualCostAtCompletion
  Variables: CPI, SPI, ProgressPercent, BudgetSize, ProjectType
  Entrenamiento: historico 3 anos
  Prediccion: proyectos en ejecucion actual
```

---

## 7. Real-Time Reporting sobre ACDOCA

### 7.1 Queries Directas ACDOCA-PS

```sql
-- Costes reales PS por periodo (tiempo real)
SELECT
    acd.GJAHR                   AS Ejercicio,
    acd.POPER                   AS Periodo,
    prps.POSID                  AS WBS,
    acd.KSTAR                   AS ElementeCoste,
    SUM(acd.HSL)                AS ImporteLC,
    SUM(acd.WSL)                AS ImporteTx,
    acd.WAERS                   AS Moneda,
    COUNT(*)                    AS NumDocumentos
FROM ACDOCA AS acd
INNER JOIN PRPS ON acd.PSPNR = PRPS.PSPNR
WHERE
    acd.RBUKRS = '1000'
    AND acd.GJAHR = '2024'
    AND acd.PSPNR <> ''
    AND acd.KTOPL = 'INT'
GROUP BY
    acd.GJAHR, acd.POPER, prps.POSID, acd.KSTAR, acd.WAERS
ORDER BY
    acd.GJAHR, acd.POPER, prps.POSID
```

### 7.2 Documentos Origen (Auditoria)

```sql
-- Drill-through a documentos individuales
SELECT
    acd.BELNR                   AS DocumentoFI,
    acd.GJAHR,
    acd.BUZEI                   AS Posicion,
    acd.BUDAT                   AS FechaContab,
    prps.POSID                  AS WBS,
    acd.KSTAR                   AS ElementeCoste,
    acd.HSL                     AS Importe,
    acd.WAERS                   AS Moneda,
    acd.AWTYP                   AS TipoReferencia,
    acd.AWKEY                   AS ClaveReferencia,
    acd.USNAM                   AS Usuario,
    bkpf.BLART                  AS ClaseDocumento,
    bkpf.BKTXT                  AS TextoCabecera
FROM ACDOCA AS acd
LEFT JOIN BKPF ON acd.RBUKRS = BKPF.BUKRS
    AND acd.BELNR = BKPF.BELNR
    AND acd.GJAHR = BKPF.GJAHR
INNER JOIN PRPS ON acd.PSPNR = PRPS.PSPNR
WHERE
    acd.RBUKRS = '1000'
    AND prps.POSID = 'INV-2024-001.001'
    AND acd.GJAHR = '2024'
ORDER BY acd.BUDAT DESC
```

---

## 8. Dashboards KPI de Proyecto

### 8.1 Estructura de Dashboard Ejecutivo

**Nivel 1: Portfolio View (Ejecutivos)**
```
KPIs:
  - # Proyectos activos / en riesgo / atrasados
  - Presupuesto total comprometido vs disponible
  - % proyectos en verde/ambar/rojo
  - EAC total vs BAC total
  - Cash flow forecast 12 meses

Graficos:
  - Treemap: proyectos por tamaño y color RAG
  - Burndown chart: portfolio budget
  - Timeline: proximos hitos criticos
```

**Nivel 2: Program View (Program Managers)**
```
KPIs:
  - CPI medio del programa
  - SPI medio del programa
  - # Issues criticos abiertos
  - Milestones this month

Graficos:
  - CPI vs SPI scatter por proyecto
  - Waterfall: varianzas de coste
  - Gantt de hitos programa
```

**Nivel 3: Project View (Project Managers)**
```
KPIs:
  - Budget: consumed / remaining / forecast
  - Schedule: on time / delayed days
  - Progress: % complete (physical vs cost)
  - Team utilization: %

Graficos:
  - S-Curve (PV, EV, AC over time)
  - WBS cost breakdown (stacked bar)
  - Commitment aging (bar)
  - Resource utilization (heatmap)
```

### 8.2 S-Curve (Curva S)

La curva S es el grafico fundamental de EVM:

```
Coste
  ^
  |                         BAC ─────────────
  |                    EAC ·················
  |            EV  ███████
  |        AC  ████████
  |    PV  ████████████
  |
  └────────────────────────────────────> Tiempo
       hoy
```

**Query para S-Curve:**
```sql
SELECT
    GJAHR,
    POPER,
    SUM(PV_Acum)  AS PlannedValue,
    SUM(EV_Acum)  AS EarnedValue,
    SUM(AC_Acum)  AS ActualCost
FROM (
    " PV acumulado por periodo
    SELECT GJAHR, POPER, SUM(PlanCost) AS PV_Acum, 0 AS EV_Acum, 0 AS AC_Acum
    FROM RPSCO WHERE WRTTP = '01' AND PSPNR IN (...)
    GROUP BY GJAHR, POPER
    UNION ALL
    " AC acumulado
    SELECT GJAHR, POPER, 0, 0, SUM(HSL) AS AC_Acum
    FROM ACDOCA WHERE PSPNR IN (...)
    GROUP BY GJAHR, POPER
)
GROUP BY GJAHR, POPER
ORDER BY GJAHR, POPER
```

---

## 9. Herramientas y Transacciones

| Transaccion / App | Descripcion | Uso |
|-------------------|-------------|-----|
| `RSRT` | Report Designer / Query Browser | Crear/ejecutar queries |
| `RSRT2` | BEx Query Designer (legacy) | Compatibilidad |
| `/IWBEP/FIORI_USAGE` | Activar CDS Views para InA/SAC | Configuracion |
| `CJE0` | Actualizar datos de resumen PS | Batch analytics |
| `S_ALR_87013532` | Plan/Actual/Variance | Reporting clasico |
| `CN41N` | Project Structure Report (nuevo) | Vista jerarquica |
| SAC | SAP Analytics Cloud | Dashboards avanzados |
| Fiori Analytical Apps | Apps embebidas en S/4 | Uso diario PM |
| `SM37` | Monitor de jobs batch | Programar analytics |

---

## 10. Buenas Practicas

### 10.1 Rendimiento de Queries

```
1. Usar ALWAYS CDS Views, no tablas directas (excepto debug)
2. Filtrar siempre por: Sociedad + Ejercicio (elimina 90%+ de datos)
3. Evitar SELECT * → especificar campos necesarios
4. Para grandes volumenes (>1M registros): usar background jobs
5. Materializar resultados en tablas Z si la query tarda >5 seg
6. Actualizar datos de resumen (CJE0) periodicamente para CN41N
```

### 10.2 Estructura de Queries Custom

```
Regla de nomenclatura:
  - View base: ZI_PS_{NOMBRE}        " Interface/Basic
  - View consumo: ZC_PS_{NOMBRE}     " Consumption
  - Query analitica: Z2C_PS_{NOMBRE} " Analytical Query

Separacion de responsabilidades:
  - ZI_*: solo logica de join y calculo
  - ZC_*: adaptar para consumo (annotations)
  - Z2C_*: definir dimensiones y medidas
```

### 10.3 Seguridad en Analytics

```
Autorizar acceso a datos via:
  1. Authorization Objects de PS (C_PRPS_KOK, C_PROJ_KOK)
  2. Data Access Control (DAC) en CDS Views
  3. Restriction Types en Business Roles

No usar: queries sin @AccessControl.authorizationCheck
```

---

*Referencia: SAP S/4HANA 2023 | Embedded Analytics | SAP Analytics Cloud*
*CDS View Reference: help.sap.com → ABAP CDS → Analytical Annotations*
