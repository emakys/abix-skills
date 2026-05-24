# Reporting y Analytics PS — SAP Project System

## Indice
1. Reports Estandar S_ALR (Classic)
2. Project Information System (CN41-CN47)
3. CDS Views Analiticas PS
4. Fiori Apps de Reporting
5. KPIs de Proyecto
6. Report Painter PS
7. Queries ACDOCA para PS
8. Dashboards y Monitoring

---

## 1. Reports Estandar S_ALR

### Serie S_ALR_87013531 — Proyectos

| Transaccion | Descripcion | Uso Principal |
|-------------|-------------|---------------|
| S_ALR_87013531 | Structure overview | Vision jerarquica del proyecto |
| S_ALR_87013532 | Plan/Actual/Variance (WBS) | Comparativa plan vs real WBS |
| S_ALR_87013533 | Plan/Actual/Variance (Orders) | Comparativa plan vs real ordenes |
| S_ALR_87013534 | Actual/Commitment/Assigned | Costes reales + compromisos |
| S_ALR_87013535 | Project actual costs | Costes reales detallados |
| S_ALR_87013536 | Budget/Actual/Commitment | Control presupuestario |
| S_ALR_87013537 | Hierarchical costs | Costes con suma jerarquica |
| S_ALR_87013538 | Progress analysis | Avance del proyecto (EV) |
| S_ALR_87013539 | Project results | Resultados con RA |
| S_ALR_87013540 | Cost element report | Desglose por elemento de coste |
| S_ALR_87013541 | Line item report | Items individuales de contabilizacion |
| S_ALR_87013542 | Commitment report | Solo compromisos (pedidos abiertos) |
| S_ALR_87013543 | Payment report | Pagos asociados al proyecto |

### Parametros Comunes

**Criterios de seleccion:**
- Proyecto (PSPID): ID o rango
- WBS Element (PSPNR): interno
- Perfil de informe
- Fecha clave (Key date)
- Moneda de informe

**Variantes:**
- Guardar variante con `/VARIANTE` en campo de nombre
- Variantes globales: prefijo `/`
- Variantes de usuario: sin prefijo

---

### 1.1 S_ALR_87013532 — Plan/Actual/Variance (WBS) — DETALLE

**Descripcion:** Report principal de control de costes a nivel WBS. Muestra costes planificados, reales, varianza y presupuesto.

**Campos mostrados:**
| Campo | Descripcion |
|-------|-------------|
| Plan total | Coste planificado total (version 0) |
| Actual | Coste real acumulado |
| Variance | Plan - Actual |
| Variance % | % desviacion sobre plan |
| Budget | Presupuesto aprobado |
| Available | Presupuesto disponible = Budget - Actual - Commitment |
| Commitment | Compromisos abiertos (pedidos) |

**Drilldown:** Doble clic → lineas individuales (FI documents)

---

### 1.2 S_ALR_87013536 — Budget/Actual/Commitment — DETALLE

**Descripcion:** Control presupuestario completo. Fundamental para verificar excesos.

**Logica de calculo:**
```
Presupuesto disponible = Presupuesto total
                       - Costes reales
                       - Compromisos (pedidos abiertos)
                       - Planes previos (si aplica)
```

**Columnas clave:**
- Budget Released: Presupuesto liberado (puede ser parcial)
- Actual Costs: Costes contabilizados
- Commitments: Pedidos de compra abiertos
- Assigned: Actual + Commitment
- Available: Budget - Assigned

---

## 2. Project Information System (CN41-CN47)

### Transacciones CN

| Transaccion | Descripcion | Notas |
|-------------|-------------|-------|
| CN41 | Structure overview (WBS) | Vista jerarquica |
| CN41N | Structure overview (nuevo) | Version mejorada |
| CN42 | Costs (WBS) | Costes planificados/reales |
| CN42N | Costs (nuevo) | Con drilldown mejorado |
| CN43 | Dates (WBS) | Fechas planificadas/reales |
| CN44 | Progress analysis | Avance fisico |
| CN45 | Resources | Capacidades planificadas |
| CN46 | Payments | Entradas y salidas de pago |
| CN47 | Documents | Documentos vinculados |

### 2.1 CN41N — Structure Overview (Nuevo)

**Funcionalidades:**
- Vista jerarquica con expansion/colapso
- Columnas configurables (hasta 20 columnas)
- Exportacion a Excel
- Filtros dinamicos por campo
- Integracion con Fiori Launchpad

**Perfiles de informacion:**
- Se configuran en SPRO → Project Information System
- Permiten preconfigurar las columnas visibles
- Perfil = combinacion de campos + opciones de visualizacion

**Niveles de informacion:**
```
Nivel 1: Proyecto (PSPID)
Nivel 2: WBS nivel 1
Nivel 3: WBS nivel 2
...
Nivel n: Actividades de red
```

---

### 2.2 Perfiles de Resumen (Summarization)

**Transaccion:** `CJE0` — Actualizar datos de resumen
**Transaccion:** `CJE1` — Resetear datos de resumen

Los datos de resumen se calculan periodicamente y permiten reports rapidos sobre grandes volumenes de proyectos.

**Configuracion:**
```
SPRO → Project System → Information System →
  Summarization → Define Summarization Profiles
```

---

## 3. CDS Views Analiticas PS

### 3.1 Views de Proyectos (Released)

| CDS View | Descripcion | Uso |
|----------|-------------|-----|
| `I_Project` | Datos maestros proyecto | Fiori apps, OData |
| `I_WBSElement` | Datos maestros WBS | Fiori apps, OData |
| `I_WBSElementByProcessingStatus` | WBS por status | Filtrado por status |
| `I_ProjectVersion` | Versiones de proyecto | Comparativa versiones |
| `I_ProjectPeriodCost` | Costes por periodo | Periodico |
| `C_ProjectPlanVsActual` | Plan vs Real proyecto | Dashboard costes |
| `C_WBSElementPlanVsActual` | Plan vs Real WBS | Control presupuesto |
| `I_ProjElementCostObject` | WBS como objeto de coste | Integracion CO |
| `I_ProjectOrder` | Ordenes de proyecto (redes) | Redes y actividades |
| `I_PSOrderItem` | Items de orden PS | Actividades detalle |

### 3.2 Views de Costes

| CDS View | Descripcion |
|----------|-------------|
| `I_ProjectActualCost` | Costes reales por proyecto |
| `I_ProjectBudget` | Presupuesto por proyecto |
| `I_ProjectBudgetDistrib` | Distribucion de presupuesto |
| `I_ProjectCommitment` | Compromisos de proyecto |
| `I_WBSActualCostByPeriod` | Costes reales WBS por periodo |
| `C_ProjectBudgetAvailability` | Disponibilidad presupuestaria |

### 3.3 Query sobre CDS View — Ejemplo

```sql
-- Costes plan vs real por proyecto
SELECT
    proj.ProjectID,
    proj.ProjectDescription,
    wbs.WBSElement,
    wbs.WBSDescription,
    pva.PlannedCost,
    pva.ActualCost,
    pva.PlannedCost - pva.ActualCost AS Variance,
    CASE
        WHEN pva.PlannedCost > 0
        THEN (pva.ActualCost / pva.PlannedCost) * 100
        ELSE 0
    END AS CompletionPercent
FROM I_Project AS proj
JOIN I_WBSElement AS wbs
    ON proj.ProjectInternalID = wbs.ProjectInternalID
JOIN C_WBSElementPlanVsActual AS pva
    ON wbs.WBSElementInternalID = pva.WBSElementInternalID
WHERE proj.ProjectType = 'PS01'
    AND proj.ProjectStatus <> 'DLTD'
ORDER BY proj.ProjectID, wbs.WBSElement
```

**Uso con MCP GetSqlQuery:**
```json
{
  "tool": "GetSqlQuery",
  "params": {
    "sql": "SELECT TOP 100 ProjectID, WBSElement, ActualCost FROM C_WBSElementPlanVsActual WHERE ProjectID LIKE 'INV-%'"
  }
}
```

---

## 4. Fiori Apps de Reporting PS

### 4.1 Apps Analiticas

| App | App ID | Descripcion | Tipo |
|-----|--------|-------------|------|
| My Projects | F1234 | Proyectos del usuario | Transactional |
| Project Cost Overview | F2344 | Vision costes proyecto | Analytical |
| Project Budget Overview | F2345 | Control presupuestario | Analytical |
| Monitor Projects | F3245 | Monitor estado proyectos | Analytical |
| Project Variance Analysis | F2346 | Analisis varianzas | Analytical |
| Project Earned Value | F2347 | Valor ganado (EV) | Analytical |
| WBS Cost Details | F2348 | Costes WBS detallados | Analytical |
| Project Financial Control | F5567 | Control financiero | Analytical |

### 4.2 Project Cost Overview — Detalle

**Business Role:** SAP_BR_PROJECT_MANAGER
**OData Service:** `C_PROJECTPLANVSACTUAL_CDS`
**CDS View:** `C_ProjectPlanVsActual`

**KPIs mostrados:**
- Total planned cost
- Total actual cost
- Variance (amount + %)
- Budget utilization (%)
- Remaining budget

**Drill-down:** Proyecto → WBS → Elemento de coste → Documento FI

---

### 4.3 Monitor Projects — Detalle

**Business Role:** SAP_BR_PROJECT_MANAGER, SAP_BR_PROGRAM_MANAGER
**OData Service:** `C_PROJECTMONITOR_CDS`
**CDS View:** `I_ProjectByProcessingStatus`

**Columnas configurables:**
- Project ID / Description
- System status / User status
- Start / End dates
- % Complete (progress)
- Actual cost / Budget
- Traffic light (RAG status)

---

## 5. KPIs de Proyecto (Earned Value Management)

### 5.1 Conceptos Fundamentales EVM

| Acronimo | Nombre | Descripcion | Formula |
|----------|--------|-------------|---------|
| PV | Planned Value | Valor del trabajo planificado | Budget x % planificado |
| EV | Earned Value | Valor del trabajo completado | Budget x % completado real |
| AC | Actual Cost | Coste real incurrido | Suma de costes reales |
| BAC | Budget at Completion | Presupuesto total | Presupuesto aprobado |
| SV | Schedule Variance | Varianza de cronograma | EV - PV |
| CV | Cost Variance | Varianza de coste | EV - AC |
| SPI | Schedule Performance Index | Indice eficiencia cronograma | EV / PV |
| CPI | Cost Performance Index | Indice eficiencia costes | EV / AC |
| EAC | Estimate at Completion | Estimado al completar | BAC / CPI |
| ETC | Estimate to Complete | Estimado para completar | EAC - AC |
| TCPI | To-Complete Performance Index | Indice rendimiento requerido | (BAC-EV)/(BAC-AC) |
| VAC | Variance at Completion | Varianza final estimada | BAC - EAC |

### 5.2 Interpretacion de KPIs

**SPI (Schedule Performance Index):**
```
SPI > 1.0 → Adelantado respecto al plan
SPI = 1.0 → En cronograma
SPI < 1.0 → Atrasado respecto al plan (ALERTA)
SPI < 0.8 → Atraso critico (ACCION INMEDIATA)
```

**CPI (Cost Performance Index):**
```
CPI > 1.0 → Por debajo del coste planificado (eficiente)
CPI = 1.0 → En coste
CPI < 1.0 → Por encima del coste (ALERTA)
CPI < 0.8 → Sobrecoste critico (ACCION INMEDIATA)
```

**EAC (Estimate at Completion) — Variantes:**
```
EAC = BAC / CPI                    → Rendimiento futuro igual al actual
EAC = AC + (BAC - EV)              → Trabajo restante al coste planificado
EAC = AC + (BAC - EV) / CPI       → Trabajo restante al rendimiento actual
EAC = AC + ETC (bottom-up)        → Reestimacion manual del restante
```

### 5.3 Calculo en SAP PS

**Configuracion del avance (Progress Analysis):**
```
SPRO → Project System → Progress → Define Progress Analysis Profile
```
**Transaccion:** `CJ38` (actualizar progreso)

**Metodos de avance en SAP:**
| Metodo | Descripcion | Uso |
|--------|-------------|-----|
| Manual | Porcentaje introducido manualmente | Proyectos simples |
| Degree of processing | % confirmacion de actividades | Proyectos con redes |
| Milestone technique | Basado en hitos completados | Proyectos por fases |
| Quantity proportional | Proporcional a cantidad confirmada | Proyectos productivos |
| Cost proportional | Proporcional a costes reales/plan | Rapido, menos preciso |

---

## 6. Report Painter PS

### 6.1 Biblioteca de Informes PS

**Biblioteca standard:** `6P1` (Project System)
**Transaccion:** `GRR1` — Crear report con Report Painter
**Transaccion:** `GRR2` — Modificar report
**Transaccion:** `GR55` — Ejecutar grupo de reports

### 6.2 Caracteristicas Disponibles en Biblioteca 6P1

**Caracteristicas (filas):**
| Campo | Descripcion |
|-------|-------------|
| PSPID | ID de proyecto |
| POSID | ID de elemento WBS |
| KSTAR | Elemento de coste |
| KOSTL | Centro de coste |
| LSTAR | Tipo de actividad |

**Cifras clave (columnas):**
| Campo | Descripcion |
|-------|-------------|
| PPKOST | Coste planificado |
| ISTKOST | Coste real |
| BUDGKOST | Presupuesto |
| OBLIGO | Compromisos |
| VERFKOST | Disponible |

### 6.3 Creacion de Report Personalizado

```
1. GRR1 → Seleccionar biblioteca 6P1
2. Definir filas: POSID (WBS), KSTAR (elemento coste)
3. Definir columnas:
   - Coste plan (version 0, periodo total)
   - Coste real (periodo actual YTD)
   - Varianza (formula: col1 - col2)
   - % Avance (manual o EV)
4. Parametros de seleccion: PSPID
5. Opciones de layout: jerarquico, sumatorias
6. Asignar al grupo de reports
```

---

## 7. Queries ACDOCA para PS

### 7.1 Costes Reales por Proyecto

```sql
-- Costes reales acumulados por proyecto y elemento de coste
SELECT
    acd.PSPNR,            -- WBS Element (interno)
    prps.POSID,           -- WBS Element ID (externo)
    prps.POST1,           -- Descripcion WBS
    acd.KSTAR,            -- Elemento de coste
    acd.GJAHR,            -- Ejercicio
    acd.POPER,            -- Periodo
    SUM(acd.HSL) AS ActualCost_LC,  -- Moneda local
    SUM(acd.WSL) AS ActualCost_TC,  -- Moneda transaccion
    acd.WAERS             -- Moneda
FROM ACDOCA AS acd
JOIN PRPS ON acd.PSPNR = PRPS.PSPNR
WHERE
    acd.RBUKRS = '1000'   -- Sociedad
    AND acd.GJAHR = '2024'
    AND acd.PSPNR <> ''   -- Solo documentos con WBS
    AND acd.KTOPL = 'INT' -- Plan de cuentas
GROUP BY
    acd.PSPNR, prps.POSID, prps.POST1,
    acd.KSTAR, acd.GJAHR, acd.POPER, acd.WAERS
ORDER BY prps.POSID, acd.GJAHR, acd.POPER
```

### 7.2 Budget vs Actual vs Commitment

```sql
-- Control presupuestario por WBS
SELECT
    prps.POSID,
    prps.POST1,
    bpja.GJAHR,
    bpja.WLGES AS Budget,       -- Presupuesto total
    bpja.WLIBFR AS Released,    -- Presupuesto liberado
    COALESCE(act.ActualCost, 0) AS ActualCost,
    COALESCE(cmt.Commitment, 0) AS Commitment,
    bpja.WLIBFR
        - COALESCE(act.ActualCost, 0)
        - COALESCE(cmt.Commitment, 0) AS Available
FROM PRPS
JOIN BPJA ON PRPS.PSPNR = BPJA.OBJNR
    AND BPJA.VORGA = 'KOBU'     -- Presupuesto
LEFT JOIN (
    SELECT PSPNR, GJAHR, SUM(HSL) AS ActualCost
    FROM ACDOCA
    WHERE PSPNR <> ''
    GROUP BY PSPNR, GJAHR
) AS act ON PRPS.PSPNR = act.PSPNR AND BPJA.GJAHR = act.GJAHR
LEFT JOIN (
    SELECT PSPNR, GJAHR, SUM(WKBTR) AS Commitment
    FROM RPSCO
    WHERE WRTTP = '40'          -- Tipo valor: compromisos
    GROUP BY PSPNR, GJAHR
) AS cmt ON PRPS.PSPNR = cmt.PSPNR AND BPJA.GJAHR = cmt.GJAHR
WHERE PRPS.PSPHI = (
    SELECT PSPNR FROM PROJ WHERE PSPID = 'PR-2024-001'
)
ORDER BY PRPS.POSID
```

### 7.3 Compromisos Abiertos

```sql
-- Pedidos abiertos imputados a proyecto
SELECT
    ekpo.EBELN,           -- Pedido
    ekpo.EBELP,           -- Posicion
    ekpo.MATNR,           -- Material
    ekpo.TXZ01,           -- Descripcion
    ekpo.MENGE,           -- Cantidad pedida
    ekpo.NETPR,           -- Precio neto
    ekpo.MENGE * ekpo.NETPR AS ValorTotal,
    ekko.WAERS,           -- Moneda
    prps.POSID,           -- WBS Element
    ekko.AEDAT            -- Fecha de creacion
FROM EKPO
JOIN EKKO ON EKPO.EBELN = EKKO.EBELN
JOIN PRPS ON EKPO.PS_PSP_PNR = PRPS.PSPNR
WHERE
    ekko.BSART IN ('NB', 'ZNB')  -- Tipos pedido
    AND ekpo.LOEKZ = ''           -- No borradas
    AND ekpo.ELIKZ = ''           -- No suministro completo
    AND prps.POSID LIKE 'PR-2024%'
ORDER BY ekko.AEDAT DESC
```

### 7.4 Liquidaciones del Periodo

```sql
-- Liquidaciones realizadas en el periodo
SELECT
    prps.POSID AS WBSOrigin,
    cobrb.OBJNR AS ReceiverObject,
    cobrb.KONTY AS ReceiverType,
    acdoca.GJAHR,
    acdoca.POPER,
    SUM(acdoca.HSL) AS SettledAmount
FROM ACDOCA
JOIN PRPS ON ACDOCA.PSPNR = PRPS.PSPNR
JOIN COBRB ON PRPS.PSPNR = COBRB.PSPNR
WHERE
    ACDOCA.RBUKRS = '1000'
    AND ACDOCA.GJAHR = '2024'
    AND ACDOCA.BEKNZ = 'S'      -- Debit (settlement)
    AND ACDOCA.AWTYP = 'BKPF'
GROUP BY
    prps.POSID, cobrb.OBJNR, cobrb.KONTY,
    acdoca.GJAHR, acdoca.POPER
ORDER BY acdoca.GJAHR, acdoca.POPER
```

---

## 8. Dashboards y Monitoring

### 8.1 Project Cockpit (S/4HANA)

**Descripcion:** Dashboard ejecutivo integrado para vision 360° del proyecto.

**Componentes:**
- Status semaforo (RAG)
- KPIs financieros (plan/actual/budget)
- Timeline con hitos
- Issues y riesgos abiertos
- Documentos adjuntos
- Equipo de proyecto

**Acceso:** Fiori Launchpad → "Project Cockpit" o app F4850

### 8.2 Embedded Analytics Dashboard

**Apps de analisis embebido:**
| App | KPI Principal | Frecuencia |
|-----|---------------|------------|
| Portfolio Overview | % proyectos en budget | Semanal |
| Cost Variance Report | CPI por proyecto | Mensual |
| Schedule Performance | SPI por proyecto | Semanal |
| Budget Consumption | % utilizado | Continuo |
| Cash Flow Forecast | ETC por periodo | Mensual |

### 8.3 Definicion de KPIs Semaforo

**Logica RAG (Red/Amber/Green):**

```
VERDE  (On Track):
  - CPI >= 0.95 Y SPI >= 0.95
  - Budget utilizado <= 90%
  - Sin issues criticos abiertos

AMBAR  (At Risk):
  - 0.85 <= CPI < 0.95 O 0.85 <= SPI < 0.95
  - 90% < Budget utilizado <= 100%
  - Issues criticos en progreso

ROJO   (Off Track):
  - CPI < 0.85 O SPI < 0.85
  - Budget utilizado > 100%
  - Issues criticos sin asignar
```

### 8.4 Scheduled Reports

**Transaccion:** `SM36` — Planificar jobs de background
**Jobs recomendados para PS:**

| Job | Transaccion | Frecuencia | Output |
|-----|-------------|------------|--------|
| Budget control | S_ALR_87013536 | Diario | Email a PM |
| Progress update | CJ38 | Semanal | Log |
| Cost accruals | CJAB | Mensual | Spool |
| Settlement run | CJ8G | Mensual | Log |
| Summarization | CJE0 | Semanal | Actualiza datos resumen |

---

## Referencia de Tablas RPSCO (Costes PS)

La tabla `RPSCO` es el almacen de costes y presupuesto de PS:

| Campo WRTTP | Descripcion |
|-------------|-------------|
| 01 | Plan total |
| 04 | Plan por periodo |
| 10 | Real |
| 20 | Real (estadistico) |
| 40 | Compromisos |
| 41 | Compromisos de pedidos |
| 43 | Compromisos de contratos |
| 60 | Budget |
| 61 | Budget suplementario |
| 65 | Budget devuelto |

**Nota S/4HANA:** RPSCO sigue existiendo como tabla de totalessacumulados. Los documentos individuales estan en ACDOCA.

---

*Referencia: SAP S/4HANA 2023 | Project System Reporting Guide*
*Compatible con S/4HANA 2020, 2021, 2022, 2023*
