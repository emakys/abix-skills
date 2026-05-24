# Embedded Analytics PP — S/4HANA

## CDS Views Analiticas

### Production Orders

| CDS View | Descripcion | Metricas |
|----------|-------------|----------|
| C_ProdOrderByMatlGrp | Ordenes por grupo material | Qty, status, on-time |
| C_ProdOrderByWorkCenter | Ordenes por puesto trabajo | Carga, completion rate |
| C_ProdOrderConfirmation | Confirmaciones | Yield, scrap, tiempos |
| C_ProdOrderCostAnalysis | Costes orden | Plan vs actual por componente |
| C_ProdOrderVarianceAnalysis | Desviaciones | Price, qty, lot, scrap variance |
| C_ProdOrderWIP | WIP | WIP amount by order/period |

### MRP

| CDS View | Descripcion | Metricas |
|----------|-------------|----------|
| C_MRPExceptionMessage | Mensajes excepcion | Count by type/material |
| C_MaterialCoverage | Cobertura material | Days of supply, shortages |
| C_PlannedOrderOverview | Previsionales | Qty, dates, conversion rate |

### Capacity

| CDS View | Descripcion | Metricas |
|----------|-------------|----------|
| C_CapacityUtilization | Utilizacion capacidad | Load %, available, required |
| C_CapacityOverload | Sobrecargas | Overloaded work centers |

### Quality

| CDS View | Descripcion | Metricas |
|----------|-------------|----------|
| C_ProdOrderScrapAnalysis | Merma produccion | Scrap rate, reasons, trend |
| C_ProdOrderYieldAnalysis | Rendimiento | Yield %, by material/WC |

## KPI Tiles (Fiori Launchpad)

### Tiles principales PP

| KPI | Descripcion | Target tipico |
|-----|-------------|---------------|
| Production Order Completion Rate | % ordenes completadas a tiempo | >95% |
| Scrap Rate | % merma vs produccion total | <2% |
| MRP Exception Count | Mensajes excepcion pendientes | <50 |
| Capacity Utilization | % utilizacion capacidad | 80-90% |
| On-Time Delivery from Production | Entregas a tiempo | >98% |
| COGI Pending Items | Errores pendientes | 0 |
| Planned vs Actual Production | Cumplimiento plan | >95% |

### Configuracion tiles
1. Fiori Launchpad Designer
2. Agregar tile con semantic object
3. Configurar: CDS View + filtros + threshold (rojo/amarillo/verde)

## Queries con ACDOCA para PP

### Coste real por orden
```sql
SELECT AUFNR, KSTAR, SUM(HSL) AS COSTE
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND AUFNR = '{orden}'
AND GJAHR = '{year}' AND RLDNR = '0L'
GROUP BY AUFNR, KSTAR
```

### WIP acumulado por periodo
```sql
SELECT POPER, SUM(HSL) AS WIP
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND AUFNR LIKE '{prefix}%'
AND GJAHR = '{year}' AND KSTAR BETWEEN '790000' AND '799999'
GROUP BY POPER ORDER BY POPER
```

### Varianzas por categoria
```sql
SELECT AUFNR, KSTAR, SUM(HSL) AS VARIANCE
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND AUFNR = '{orden}'
AND GJAHR = '{year}' AND RLDNR = '0L'
AND KSTAR IN ('{variance_accounts}')
GROUP BY AUFNR, KSTAR
```

### Consumo de materiales
```sql
SELECT MATNR, SUM(MENGE) AS QTY, SUM(DMBTR) AS VALOR
FROM MATDOC
WHERE AUFNR = '{orden}' AND BWART = '261'
GROUP BY MATNR
```

## SAP Analytics Cloud (SAC) Integration

### Live Connection
- CDS Views analiticas expuestas via OData
- SAC conecta directamente a S/4HANA
- Datos en tiempo real sin replicacion

### Planning Integration
- SAC planning para demand forecasting
- Datos de plan se escriben en S/4 via API
- Reemplaza SOP (MC87) en escenarios avanzados

### Stories recomendadas PP

| Story | Contenido | Audiencia |
|-------|-----------|-----------|
| Production Dashboard | KPIs, ordenes, capacidad | Plant manager |
| MRP Overview | Cobertura, excepciones, shortages | MRP controller |
| Cost Analysis | Real vs plan, varianzas | Controller produccion |
| Quality/Scrap | Tendencia merma, Pareto causas | Quality manager |
| Capacity Monitor | Utilizacion, cuellos botella | Production planner |

## Report Painter / Writer (legacy)

| Libreria | Descripcion |
|----------|-------------|
| 8A2 | Ordenes produccion (KKBC) |
| 8A3 | Product cost collectors |

Nota: En S/4HANA, preferir Fiori apps y CDS Views sobre Report Painter.
