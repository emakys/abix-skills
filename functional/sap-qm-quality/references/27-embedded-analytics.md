# Embedded Analytics QM

## CDS Analytical Framework

### Arquitectura
```
Fiori Tile (KPI) → OData → CDS Consumption (C_) → CDS Composite (I_) → Tablas QM
                                                                        ↓
                                                              QALS, QAVE, QMEL, QMFE, QASR
```

### CDS Views Analiticas Estandar

| View | Tipo | Descripcion |
|------|------|-------------|
| I_InspectionLot | Basic | Datos lote |
| I_InspectionLotWithStatus | Basic | Lote + status system |
| I_QualityNotification | Basic | Aviso calidad |
| I_QualityNotificationItem | Basic | Items defecto |
| C_InspectionLotAnalysis | Cube | Analisis multidimensional lotes |
| C_QltyNotifnAnalysis | Cube | Analisis avisos |
| C_InspLotResultAnalysis | Cube | Analisis resultados |

## KPI Tiles Estandar

### Inspection Lot KPIs
| KPI | Calculo | Threshold |
|-----|---------|-----------|
| Open Inspection Lots | COUNT WHERE status != CLOSE | Amarillo > 20, Rojo > 50 |
| Overdue Lots | COUNT WHERE dias_sin_UD > 5 | Amarillo > 5, Rojo > 10 |
| Rejection Rate | Rejected / Total * 100 | Amarillo > 3%, Rojo > 5% |
| First Pass Yield | Accepted_1st / Total * 100 | Amarillo < 97%, Rojo < 95% |
| Avg Inspection Time | AVG(UD_date - Create_date) | Amarillo > 2d, Rojo > 5d |

### Notification KPIs
| KPI | Calculo | Threshold |
|-----|---------|-----------|
| Open Notifications | COUNT WHERE status = open | Amarillo > 10, Rojo > 25 |
| Overdue Tasks | COUNT WHERE task_due < today | Amarillo > 3, Rojo > 10 |
| Avg Resolution Time | AVG(close_date - create_date) | Amarillo > 15d, Rojo > 30d |
| Repeat Defects | Same defect code, same material, 90d | Rojo > 0 |

## Queries Custom

### Query: Rejection Trend (12 meses)
```sql
-- CDS View para tendencia de rechazo mensual
@AbapCatalog.sqlViewName: 'ZV_QM_REJTRND'
@Analytics.dataCategory: #CUBE
define view ZI_QM_RejectionTrend
  as select from qals as q
  left outer join qave as v on q.prueflos = v.prueflos
{
  key q.prueflos,
  q.matnr,
  q.werk,
  q.art,
  @Semantics.calendar.yearMonth: true
  concat(q.erdat_year, q.erdat_month) as year_month,

  @DefaultAggregation: #SUM
  1 as total_lots,

  @DefaultAggregation: #SUM
  case when v.vcode like 'A%' then 1 else 0 end as accepted,

  @DefaultAggregation: #SUM
  case when v.vcode like 'R%' then 1 else 0 end as rejected
}
```

### Query: Defect Pareto
```sql
@AbapCatalog.sqlViewName: 'ZV_QM_DEFPAR'
@Analytics.dataCategory: #CUBE
define view ZI_QM_DefectPareto
  as select from qmfe as f
  inner join qmel as q on f.qmnum = q.qmnum
  left outer join qpcd as c on f.fegrp = c.codegruppe
                             and f.fecod = c.code
                             and c.katession = '1'
{
  key f.qmnum,
  key f.feession,
  q.qmart,
  q.matnr,
  q.werk,
  f.fegrp,
  f.fecod,
  c.kurztext as defect_text,

  @DefaultAggregation: #SUM
  1 as defect_count,

  @Semantics.quantity.unitOfMeasure: 'meins'
  @DefaultAggregation: #SUM
  f.rkmng as defect_qty,
  f.meession as meins
}
```

### Query: Vendor Quality Scorecard
```sql
@AbapCatalog.sqlViewName: 'ZV_QM_VNDSCO'
@Analytics.dataCategory: #CUBE
define view ZI_QM_VendorScorecard
  as select from qals as q
  inner join qave as v on q.prueflos = v.prueflos
{
  key q.prueflos,
  q.lifnr,
  q.matnr,
  q.werk,

  @Semantics.calendar.yearMonth: true
  concat(q.erdat_year, q.erdat_month) as year_month,

  @DefaultAggregation: #SUM
  1 as total_lots,

  @DefaultAggregation: #SUM
  case when v.vcode like 'A%' then 100 else 0 end as quality_points,

  @DefaultAggregation: #SUM
  case when v.vcode like 'R%' then 1 else 0 end as rejections
}
```

## Fiori Analytical Apps

### Quality Overview Page (OVP)
```
Configuracion OVP:
┌──────────────────────────────────────────────┐
│ Quality Overview                              │
├──────────────┬───────────────────────────────┤
│ KPI Card     │ KPI Card                      │
│ Open Lots    │ Rejection Rate               │
│ [42]         │ [2.3%] ↓                     │
├──────────────┼───────────────────────────────┤
│ List Card    │ Chart Card                    │
│ Overdue Lots │ Rejection Trend (12m)        │
│ - MAT-001   │ ┌─────────────────┐          │
│ - MAT-002   │ │ ▃▅▂▃▄▂▃▅▃▂▃▂  │          │
│ - MAT-003   │ └─────────────────┘          │
├──────────────┼───────────────────────────────┤
│ Table Card   │ Chart Card                    │
│ Open Notifs  │ Top 5 Defects (Pareto)       │
│ Q1: 5        │ ┌─────────────────┐          │
│ Q2: 3        │ │ ████▌           │          │
│ Q3: 8        │ │ ███▌            │          │
│              │ │ ██▌             │          │
│              │ └─────────────────┘          │
└──────────────┴───────────────────────────────┘
```

### Smart Business KPI Modeler
```
Pasos crear KPI tile custom:
1. KPI Workspace (app) → Create KPI
2. Seleccionar CDS view (C_ o Z custom)
3. Definir medida (SUM, AVG, COUNT)
4. Definir filtros
5. Definir thresholds (verde/amarillo/rojo)
6. Crear evaluacion → tile
7. Asignar a catalogo/grupo Fiori
```

## Alertas y Notificaciones

### Situation Handling (S/4HANA)
```
Situations QM:
- Lote sin UD > X dias → alerta a quality engineer
- Rejection rate > threshold → alerta a quality manager
- Aviso prioridad 1 creado → notificacion inmediata
- Task overdue → escalacion a supervisor
```

### Configuracion
```
1. Define situation type (SPRO)
2. Define trigger (CDS view + condicion)
3. Define anchor object (lote, aviso)
4. Define recipients (rol, usuario, regla)
5. Define actions (abrir app, workflow)
```

## Integration con SAP Analytics Cloud (SAC)

### Live Connection
```
SAC → Live connection a S/4HANA
  → CDS views QM expuestas via InA protocol
  → Dashboards interactivos
  → Planning (targets calidad)
  → Predictive (tendencias)
```

### Modelos SAC Recomendados
| Modelo | Fuente | Uso |
|--------|--------|-----|
| Quality KPIs | C_InspectionLotAnalysis | Dashboard ejecutivo |
| Defect Analysis | ZI_QM_DefectPareto | Pareto interactivo |
| Vendor Quality | ZI_QM_VendorScorecard | Comparacion proveedores |
| Cost of Quality | ACDOCA + ordenes QM | Costes calidad |
