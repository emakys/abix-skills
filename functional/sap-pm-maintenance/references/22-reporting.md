# Reporting y Analytics PM — Plant Maintenance

Guía completa del sistema de información de mantenimiento (PMIS), análisis de órdenes y avisos, KPIs de mantenimiento, y herramientas analíticas en SAP S/4HANA 2023.

---

## 1. Plant Maintenance Information System (PMIS)

El PMIS es el sistema de información logístico para PM, basado en la infraestructura LIS (Logistics Information System). Agrega datos de órdenes, notificaciones y objetos técnicos en estructuras de información predefinidas.

### 1.1 Estructuras de Información PMIS

| Transacción | Estructura | Descripción |
|-------------|-----------|-------------|
| MCI1 | S061 | Análisis de objetos técnicos (equipos/ubicaciones) |
| MCI2 | S062 | Análisis de fabricantes de equipos |
| MCI3 | S063 | Análisis de daños (causa, tipo, actividad) |
| MCI4 | S065 | Análisis de posición de objeto |
| MCI5 | S066 | Análisis de clase de trabajo |
| MCI6 | S067 | Análisis de planificadores de mantenimiento |
| MCI7 | S070 | Análisis de ubicaciones técnicas |

### 1.2 Uso de MCI1 — Análisis de Objetos Técnicos

**Transacción:** MCI1

**Características de selección:**
- Equipo / Ubicación técnica
- Clase de actividad de mantenimiento
- Período (mes/trimestre/año)
- Planta de mantenimiento

**Indicadores clave disponibles:**
| Indicador | Descripción | Cálculo |
|-----------|-------------|---------|
| Número de averías | Count de órdenes tipo avería | ANLZA |
| Duración de avería | Suma de tiempos de parada | ANLZT |
| Costes de mantenimiento | Suma de costes reales | ANLKOS |
| MTBF | Tiempo medio entre fallos | (Tiempo operación) / (N averías) |
| MTTR | Tiempo medio de reparación | (Tiempo parada) / (N averías) |

### 1.3 Drill-Down en PMIS

El PMIS permite análisis jerárquico:
```
Planta → Sección de planta → Equipo → Orden → Posición de aviso
```

**Funciones disponibles:**
- Comparación período anterior
- Gráficos de barras/líneas
- Exportación a Excel (botón "Hoja de cálculo")
- Clasificación ABC por coste/avería
- Varianza % respecto a período anterior

---

## 2. MTBF y MTTR — Indicadores de Fiabilidad

### 2.1 MTBF (Mean Time Between Failures — Tiempo Medio Entre Fallos)

**Definición:** Tiempo promedio de operación entre dos averías consecutivas del mismo equipo.

**Fórmula:**
```
MTBF = (Tiempo total de operación) / (Número de averías)
```

**Fuente de datos SAP:**
- Tiempo de operación: Diferencia entre fecha fin avería anterior y fecha inicio avería actual
- Número de averías: Órdenes PM con indicador de avería activo (campo AUFK-IGAUF)

**Query SQL (GetSqlQuery):**
```sql
SELECT
  EQUNR,
  COUNT(*) AS NUM_AVERIAS,
  SUM(AUSZT) AS TIEMPO_PARADA_TOTAL,
  AVG(AUSZT) AS MTTR_PROMEDIO
FROM AUFK
INNER JOIN AFIH ON AUFK.AUFNR = AFIH.AUFNR
WHERE AUFK.AUART IN ('PM01') -- Tipo orden correctivo
  AND AFIH.EQUNR IS NOT NULL
  AND AUFK.ERDAT BETWEEN '20240101' AND '20241231'
  AND AUFK.LOEKZ = ' ' -- No borrado
GROUP BY AFIH.EQUNR
ORDER BY NUM_AVERIAS DESC
```

### 2.2 MTTR (Mean Time To Repair — Tiempo Medio de Reparación)

**Definición:** Tiempo promedio desde la detección de la avería hasta la restauración del equipo al estado operativo.

**Fórmula:**
```
MTTR = (Suma de tiempos de avería) / (Número de averías)
```

**Tiempo de avería SAP:** Campo AFIH-AUSZT (duración de parada en horas)

**Transacción para captura:** En la orden PM, pestaña "Datos de avería":
- Fecha/hora inicio avería (AFIH-STRNO/STRNO)
- Fecha/hora fin avería (AFIH-ENDNO/ENDNO)
- Duración calculada automáticamente en AFIH-AUSZT

### 2.3 Disponibilidad Técnica

**Fórmula:**
```
Disponibilidad (%) = ((Tiempo total - Tiempo parada) / Tiempo total) × 100
```

**Ejemplo:**
```
Tiempo total período: 720 horas (30 días × 24h)
Tiempo parada por averías: 18 horas
Disponibilidad = ((720 - 18) / 720) × 100 = 97.5%
```

---

## 3. Analisis de Ordenes — IW38 / IW39

### 3.1 IW38 — Lista de Órdenes de Mantenimiento (Con Modificación)

**Criterios de selección principales:**
| Criterio | Campo | Descripción |
|----------|-------|-------------|
| Tipo de orden | AUART | PM01, PM02, etc. |
| Estado del sistema | STAT | CREA, LIBL, RÜCK, ABGS |
| Planta | IWERK | Planta de mantenimiento |
| Equipo | EQUNR | Número de equipo |
| Fecha de inicio | GSTRP | Rango fecha inicio básica |
| Centro de coste | KOSTL | Para análisis de costes |
| Clase de trabajo | ARBPL | Puesto de trabajo |

**Funciones IW38:**
- Liberación masiva de órdenes (seleccionar + botón Liberar)
- Cierre técnico masivo
- Modificación masiva de datos (fecha, prioridad, responsable)
- Exportación a Excel con ALV

### 3.2 IW39 — Lista de Órdenes (Solo Visualización)

Mismas opciones de selección que IW38, pero sin posibilidad de modificación. Adecuada para perfiles de solo lectura (supervisores, auditores).

**Variantes de visualización útiles:**
- Con costes planificados vs reales
- Con materiales planificados vs consumidos
- Con estado de confirmación por operación

### 3.3 IW67 — Análisis de Costes de Órdenes

**Transacción:** IW67

**Descripción:** Lista de costes reales y planificados por orden PM, con desglose por clase de coste.

**Criterios clave:** Tipo de orden, planta, período de contabilización, estado (solo liquidadas/todas).

**Vista de desglose:**
```
Orden: 000004000001
  Mano de obra interna:    1.250 EUR
  Materiales:                890 EUR
  Servicios externos:      2.100 EUR
  Gastos generales:          312 EUR
  TOTAL REAL:              4.552 EUR
  TOTAL PLAN:              4.000 EUR
  DESVIACIÓN:               +552 EUR (+13.8%)
```

---

## 4. Analisis de Avisos — IW28 / IW29

### 4.1 IW28 — Lista de Avisos (Con Modificación)

**Transacción:** IW28

**Criterios de selección:**
| Criterio | Campo | Descripción |
|----------|-------|-------------|
| Tipo de aviso | QMART | M1, M2, M3 |
| Estado | STAT | OFFEN, ISAB, RÜCK |
| Equipo | EQUNR | Número de equipo |
| Fecha de aviso | QMDAT | Rango fecha |
| Prioridad | PRIOK | 1-4 |
| Grupo planificador | INGRP | Planificador responsable |

**Monitoreo de tiempos de respuesta:**
IW28 permite configurar semáforos de alerta según los tiempos de respuesta definidos en customizing:
- Verde: dentro del plazo
- Amarillo: próximo a vencer
- Rojo: vencido

### 4.2 IW29 — Lista de Avisos (Solo Visualización)

**Uso típico:** Análisis de tendencias de averías, revisión de avisos por equipo/período, preparación de reuniones de mantenimiento.

**Query MCP equivalente (GetSqlQuery):**
```sql
SELECT
  Q.QMNUM,
  Q.QMART,
  Q.QMTXT,
  Q.EQUNR,
  Q.TPLNR,
  Q.QMDAT,
  Q.PRIOK,
  Q.STAT,
  Q.RKMNG
FROM QMEL Q
WHERE Q.QMART IN ('M1', 'M2')
  AND Q.QMDAT >= '20240101'
  AND Q.WERKS = '1000'
ORDER BY Q.QMDAT DESC
```

---

## 5. Reportes Estandar PM Adicionales

### 5.1 Listado de Objetos Técnicos

| Transacción | Descripción |
|-------------|-------------|
| IE05 | Lista de equipos con selección ampliada |
| IH06 | Lista de ubicaciones técnicas |
| IH08 | Estructura de equipo en árbol |
| IH12 | Equipos instalados en ubicación |
| IP24 | Listado de planes de mantenimiento |
| IP19 | Vista de trabajo del planificador (Workplace) |

### 5.2 Análisis de Costes

| Transacción | Descripción |
|-------------|-------------|
| IW67 | Costes reales de órdenes PM |
| KO8G | Liquidación masiva de órdenes |
| KOB1 | Informe de objetos de coste (órdenes) |
| KKBC_ORD | Informe de costes por orden interna |
| S_ALR_87013611 | Análisis de órdenes CO con estructura |

### 5.3 Análisis de Planes de Mantenimiento

| Transacción | Descripción |
|-------------|-------------|
| IP10 | Hoja de mantenimiento / Vista planificador |
| IP15 | Lista de llamamientos planificados |
| IP16 | Lista de llamamientos realizados |
| IP17 | Lista de avisos de mantenimiento |
| IP30 | Monitor de vencimientos de planes |

---

## 6. CDS Views Analiticas para PM

### 6.1 CDS Views Estándar S/4HANA

| CDS View | Descripción | Uso |
|----------|-------------|-----|
| I_MaintenanceOrder | Cabecera de órdenes PM | Base reporting órdenes |
| I_MaintenanceOrderItem | Operaciones de orden | Análisis mano de obra |
| I_MaintenanceOrderComponent | Componentes de orden | Análisis materiales |
| I_Equipment | Datos maestros equipo | Base reporting equipos |
| I_FunctionalLocation | Datos maestros ubicación | Base reporting ubicaciones |
| I_MaintenanceNotification | Cabecera avisos | Base reporting avisos |
| I_MaintenancePlan | Planes de mantenimiento | Análisis planificación |
| C_MaintenanceOrderQuery | Query analítica órdenes | Fiori/Embedded Analytics |
| C_EquipmentQuery | Query analítica equipos | Fiori/Embedded Analytics |

### 6.2 Ejemplo: Query sobre I_MaintenanceOrder

```sql
-- CDS View I_MaintenanceOrder (tabla subyacente: AUFK + AFIH)
SELECT
  MO.MaintenanceOrder,
  MO.MaintenanceOrderType,
  MO.Equipment,
  MO.FunctionalLocation,
  MO.MaintenancePlant,
  MO.MaintOrdBasicStartDate,
  MO.MaintOrdBasicEndDate,
  MO.SystemStatus,
  MO.TotalActualCosts,
  MO.TotalPlannedCosts
FROM I_MaintenanceOrder AS MO
WHERE MO.MaintenancePlant = '1000'
  AND MO.MaintenanceOrderType = 'PM01'
  AND MO.MaintOrdBasicStartDate >= '2024-01-01'
```

### 6.3 Ejemplo: Análisis de Costes con ACDOCA

```sql
-- Costes reales de mantenimiento por equipo (Universal Journal)
SELECT
  AFIH.EQUNR AS EQUIPO,
  SUM(ACDOCA.HSL) AS COSTE_TOTAL,
  ACDOCA.BLART AS TIPO_DOC,
  ACDOCA.KSTAR AS CLASE_COSTE
FROM ACDOCA
INNER JOIN AUFK ON ACDOCA.AUFNR = AUFK.AUFNR
INNER JOIN AFIH ON AUFK.AUFNR = AFIH.AUFNR
WHERE AUFK.AUART IN ('PM01', 'PM02', 'PM03')
  AND ACDOCA.GJAHR = '2024'
  AND ACDOCA.BUKRS = '1000'
GROUP BY AFIH.EQUNR, ACDOCA.BLART, ACDOCA.KSTAR
ORDER BY COSTE_TOTAL DESC
```

---

## 7. Fiori Apps de Reporting PM

| App ID | Nombre | Descripción | Tipo |
|--------|--------|-------------|------|
| F0429 | Monitor de Órdenes de Mantenimiento | Visión general KPIs órdenes | SAP Fiori Elements |
| F1610A | Analizar Órdenes de Mantenimiento | Análisis multidimensional costes/tiempos | Analytical |
| F1611A | Analizar Notificaciones de Mantenimiento | Tendencias y análisis de avisos | Analytical |
| F3473 | Análisis de Equipo | KPIs de disponibilidad por equipo | Analytical |
| F2855 | Costes de Mantenimiento por Centro | Dashboard costes por planta | Analytical |
| F3246 | OEE por Línea de Producción | Overall Equipment Effectiveness | KPI |
| F1612A | Análisis de Planes de Mantenimiento | Cumplimiento de planes preventivos | Analytical |

---

## 8. KPIs de Mantenimiento

### 8.1 Indicadores de Fiabilidad

| KPI | Fórmula | Unidad | Benchmark |
|-----|---------|--------|-----------|
| MTBF | Tiempo operación / N averías | Horas | > 500h (industria) |
| MTTR | Tiempo parada / N averías | Horas | < 4h (crítico) |
| Disponibilidad | (Toper - Tparada) / Toper × 100 | % | > 95% |
| Tasa de fallo | 1 / MTBF | Fallos/hora | < 0.002 |

### 8.2 Indicadores de Costes

| KPI | Fórmula | Descripción |
|-----|---------|-------------|
| Coste por hora de operación | Coste total / Horas operación | Eficiencia coste |
| Ratio coste preventivo/correctivo | Coste prev / Coste correc × 100 | Balance mantenimiento |
| Coste mantenimiento / Valor activo | Coste anual / Valor reposición × 100 | Ratio RAV |
| Desviación presupuesto | (Real - Plan) / Plan × 100 | Control presupuestario |

### 8.3 Indicadores de Gestión

| KPI | Fórmula | Descripción |
|-----|---------|-------------|
| % Mantenimiento planificado | Órdenes prev / Total órdenes × 100 | Proactividad |
| Backlog de mantenimiento | Horas pendientes / Capacidad semanal | Semanas de trabajo |
| Tasa de cumplimiento PM | Órdenes PM completadas / Planificadas × 100 | Ejecución preventivo |
| Tiempo respuesta medio | Suma (trespuesta) / N avisos | Reactividad |
| Órdenes pendientes de confirmación | Count órdenes LIBL sin confirmar | Gestión cierre |

### 8.4 Dashboard Sugerido — Reunión Mensual Mantenimiento

```
┌─────────────────────────────────────────────────┐
│         CUADRO DE MANDO MANTENIMIENTO            │
│              Enero 2024 — Planta 1000            │
├──────────────┬──────────────┬───────────────────┤
│ Disponib.    │ MTBF         │ MTTR              │
│ 97.3%  ▲    │ 342h  ▲     │ 2.8h  ▼           │
├──────────────┼──────────────┼───────────────────┤
│ Coste total  │ vs Plan      │ % Prev/Correc     │
│ 45.200 EUR   │ -3.2%  ▼    │ 68% / 32%         │
├──────────────┼──────────────┼───────────────────┤
│ Órdenes      │ Avisos       │ Backlog           │
│ 127 total    │ 89 cerradas  │ 3.2 semanas       │
│ 98 cerradas  │ 12 pendient. │                   │
└──────────────┴──────────────┴───────────────────┘
```

---

## 9. Custom Queries para Reporting

### 9.1 Reporte de Averías por Equipo (Año Actual)

```sql
SELECT
  E.EQUNR,
  E.EQKTX AS DESCRIPCION_EQUIPO,
  E.TPLNR AS UBICACION,
  E.BEBER AS SECCION_PLANTA,
  COUNT(A.AUFNR) AS NUM_AVERIAS,
  SUM(AI.AUSZT) AS HORAS_PARADA,
  SUM(AI.AUSZT) / NULLIF(COUNT(A.AUFNR), 0) AS MTTR,
  MIN(AI.STRMIT) AS PRIMERA_AVERIA,
  MAX(AI.STRMIT) AS ULTIMA_AVERIA
FROM EQUI E
LEFT JOIN AFIH AI ON E.EQUNR = AI.EQUNR
LEFT JOIN AUFK A ON AI.AUFNR = A.AUFNR
WHERE A.AUART = 'PM01'
  AND YEAR(A.ERDAT) = YEAR(CURRENT_DATE)
  AND A.LOEKZ = ' '
GROUP BY E.EQUNR, E.EQKTX, E.TPLNR, E.BEBER
HAVING COUNT(A.AUFNR) > 0
ORDER BY NUM_AVERIAS DESC
```

### 9.2 Cumplimiento de Mantenimiento Preventivo

```sql
SELECT
  MP.WARPL AS PLAN_MANT,
  MP.WPTXT AS DESCRIPCION_PLAN,
  MP.EQUNR AS EQUIPO,
  MP.TPLNR AS UBICACION,
  COUNT(MPC.AUFNR) AS ORDENES_GENERADAS,
  SUM(CASE WHEN AUFK.RÜCKMENGE > 0 THEN 1 ELSE 0 END) AS ORDENES_CONFIRMADAS,
  ROUND(SUM(CASE WHEN AUFK.RÜCKMENGE > 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(MPC.AUFNR), 0), 1) AS PCT_CUMPLIMIENTO
FROM MPLA MP
INNER JOIN MPOS MPC ON MP.WARPL = MPC.WARPL
INNER JOIN AUFK ON MPC.AUFNR = AUFK.AUFNR
WHERE YEAR(AUFK.ERDAT) = YEAR(CURRENT_DATE)
  AND MP.IWERK = '1000'
GROUP BY MP.WARPL, MP.WPTXT, MP.EQUNR, MP.TPLNR
ORDER BY PCT_CUMPLIMIENTO ASC
```

### 9.3 Backlog de Órdenes Abiertas

```sql
SELECT
  A.AUART AS TIPO_ORDEN,
  A.IWERK AS PLANTA,
  AI.EQUNR AS EQUIPO,
  A.AUFNR AS ORDEN,
  A.KTEXT AS TEXTO_ORDEN,
  A.ERDAT AS FECHA_CREACION,
  A.GSTRP AS FECHA_INICIO_BASICA,
  DAYS_BETWEEN(CURRENT_DATE, A.GSTRP) AS DIAS_VENCIDO,
  A.PRIOK AS PRIORIDAD
FROM AUFK A
INNER JOIN AFIH AI ON A.AUFNR = AI.AUFNR
WHERE A.AUART IN ('PM01', 'PM02', 'PM03', 'PM04')
  AND A.IWERK = '1000'
  AND A.LOEKZ = ' '
  AND A.GSTRP < CURRENT_DATE
  AND NOT EXISTS (
    SELECT 1 FROM JEST J
    WHERE J.OBJNR = A.OBJNR
      AND J.STAT IN ('I0009', 'I0045', 'I0046') -- Confirmado, Liquidado TH, Cerrado TH
      AND J.INACT = ' '
  )
ORDER BY DIAS_VENCIDO DESC, A.PRIOK ASC
```

---

*Referencia: SAP S/4HANA 2023 — Plant Maintenance Information System*
*SAP Help: help.sap.com/docs/SAP_S4HANA_ON-PREMISE/plant-maintenance*
