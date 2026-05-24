# Reporting y Analytics QM

## Reportes Estandar

### Lotes de Inspeccion
| TCode | Reporte | Descripcion |
|-------|---------|-------------|
| QA33 | Inspection lot list | Lista lotes con filtros |
| QA32 | Change usage decision | UD masiva |
| QA14 | Lots for usage decision | Lotes pendientes UD |
| QGR1 | Quality analysis | Analisis estadistico |
| QGR2 | Quality analysis collective | Multi-material |

### Avisos de Calidad
| TCode | Reporte | Descripcion |
|-------|---------|-------------|
| QM10 | Notifications by material | Por material |
| QM11 | Notifications by vendor | Por proveedor |
| QM12 | Notifications by customer | Por cliente |
| QM13 | Multi-criteria selection | Multi-criterio |
| QM19 | Notifications for closing | Pendientes cierre |

### SPC
| TCode | Reporte | Descripcion |
|-------|---------|-------------|
| QGC1 | Control chart display | Grafico control |
| QGC2 | Control chart evaluation | Evaluacion grafico |
| QGP1 | Calculate control limits | Limites control |

## KPIs de Calidad

### Indicadores Operativos
| KPI | Formula | Target tipico |
|-----|---------|---------------|
| First Pass Yield | Lotes accepted / total lotes | > 95% |
| Rejection Rate | Lotes rejected / total lotes | < 5% |
| Inspection Cycle Time | Fecha UD - fecha creacion lote | < 2 dias |
| Overdue Inspections | Lotes sin UD > X dias | 0 |
| Open Notifications | Avisos abiertos | Tendencia ↓ |

### Indicadores Proveedor
| KPI | Formula | Target |
|-----|---------|--------|
| Vendor Quality Score | Promedio ponderado UD | > 80 |
| Vendor Rejection Rate | Lotes rejected tipo 01 / total | < 3% |
| Certificate Compliance | Certs recibidos / requeridos | 100% |
| Response Time Q3 | Dias cierre aviso Q3 | < 15 dias |

### Indicadores Costes
| KPI | Formula | Target |
|-----|---------|--------|
| Cost of Poor Quality | Scrap + retrabajo + garantia | < 2% revenue |
| Inspection Cost | Horas inspeccion × tarifa | Tendencia ↓ |
| Return Rate | Devoluciones / entregas | < 1% |

## Consultas SQL para Reporting

```sql
-- Tasa de rechazo por material (periodo)
SELECT q.MATNR, q.WERK,
  COUNT(*) AS total_lotes,
  SUM(CASE WHEN v.VCODE LIKE 'R%' THEN 1 ELSE 0 END) AS rejected,
  ROUND(SUM(CASE WHEN v.VCODE LIKE 'R%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_reject
FROM QALS q
LEFT JOIN QAVE v ON q.PRUEFLOS = v.PRUEFLOS
WHERE q.WERK = '{centro}' AND q.ERDAT BETWEEN '{desde}' AND '{hasta}'
GROUP BY q.MATNR, q.WERK
ORDER BY pct_reject DESC

-- Tiempo ciclo inspeccion (dias promedio)
SELECT q.MATNR, q.ART,
  AVG(DATS_DAYS_BETWEEN(q.ERDAT, v.VDATUM)) AS avg_dias
FROM QALS q
JOIN QAVE v ON q.PRUEFLOS = v.PRUEFLOS
WHERE q.WERK = '{centro}' AND q.ERDAT >= '{desde}'
GROUP BY q.MATNR, q.ART

-- Avisos abiertos por tipo y antigüedad
SELECT q.QMART,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(q.ERDAT, CURRENT_DATE) <= 7 THEN 1 ELSE 0 END) AS "0-7d",
  SUM(CASE WHEN DATS_DAYS_BETWEEN(q.ERDAT, CURRENT_DATE) BETWEEN 8 AND 30 THEN 1 ELSE 0 END) AS "8-30d",
  SUM(CASE WHEN DATS_DAYS_BETWEEN(q.ERDAT, CURRENT_DATE) > 30 THEN 1 ELSE 0 END) AS ">30d"
FROM QMEL q
WHERE q.ISTAT NOT IN ('E0005', 'E0010')  -- no cerrado
GROUP BY q.QMART

-- Top defectos por frecuencia
SELECT f.FEGRP, f.FECOD, COUNT(*) AS count
FROM QMFE f
JOIN QMEL q ON f.QMNUM = q.QMNUM
WHERE q.ERDAT >= '{desde}' AND q.WERK = '{centro}'
GROUP BY f.FEGRP, f.FECOD
ORDER BY count DESC

-- Quality score por proveedor
SELECT q.LIFNR, q.MATNR,
  AVG(CASE WHEN v.VCODE LIKE 'A%' THEN 100
           WHEN v.VCODE LIKE 'R%' THEN 0
           ELSE 50 END) AS quality_score
FROM QALS q
JOIN QAVE v ON q.PRUEFLOS = v.PRUEFLOS
WHERE q.ART = '01' AND q.ERDAT >= '{desde}'
GROUP BY q.LIFNR, q.MATNR
```

## Variant Reports

### QA33 — Variantes Utiles
| Variante | Filtro | Uso |
|----------|--------|-----|
| PENDING_UD | Sin UD, > 3 dias | Seguimiento diario |
| REJECTED_MTD | Rejected, mes actual | Review semanal |
| BY_VENDOR | Tipo 01, por proveedor | Eval. proveedor |
| OVERDUE | Sin UD, > 5 dias | Escalacion |

### QM13 — Variantes Utiles
| Variante | Filtro | Uso |
|----------|--------|-----|
| OPEN_Q2 | Q2 abiertos | Customer complaints |
| OPEN_Q3 | Q3 abiertos | Vendor complaints |
| CRITICAL | Prioridad 1-2, abiertos | Escalacion |
| FOR_CLOSE | Tareas completas, sin cerrar | Cierre masivo |

## Pareto Analysis (Defectos)

```
Metodologia:
1. QM13 → exportar defectos a Excel
2. Agrupar por codigo defecto (FECOD)
3. Ordenar descendente por frecuencia
4. Calcular % acumulado
5. Identificar 20% de causas = 80% de defectos
6. Acciones correctivas en top causas
```

## Dashboards Recomendados

### Dashboard Operativo (Diario)
```
┌─────────────────┬──────────────────┐
│ Lotes pendientes│ Avisos abiertos  │
│ UD (QA14)       │ por tipo (QM13)  │
├─────────────────┼──────────────────┤
│ Lotes overdue   │ Lotes rejected   │
│ > 3 dias        │ hoy              │
└─────────────────┴──────────────────┘
```

### Dashboard Gerencial (Mensual)
```
┌─────────────────┬──────────────────┐
│ First Pass Yield│ Cost of Quality  │
│ tendencia 12m   │ por categoria    │
├─────────────────┼──────────────────┤
│ Top 5 defectos  │ Vendor ranking   │
│ Pareto          │ quality score    │
└─────────────────┴──────────────────┘
```
