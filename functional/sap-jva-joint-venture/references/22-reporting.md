# Reporting — SAP JVA

## 1. Reportes Centrales del Ciclo JVA

| Reporte | Propósito | Fuente de datos |
|---|---|---|
| Statement / extracto por partner | Detalle de costo distribuido, overhead y ajustes de un periodo | `GJUBI` |
| Historial de corridas de cutback | Control de estado (prueba/producción/reversión) por venture/periodo | `GJHIST` |
| Reconciliación GJUBI vs ACDOCA | Verifica que el costo 100% booked cuadra con lo distribuido | `ACDOCA` + `GJUBI` |
| Reporte de exposición de cash calls pendientes | Cash calls emitidos vs reconciliados contra cutback real | Anticipos FI + `GJUBI` |
| Ejecutado vs Autorizado de AFE | Seguimiento presupuestario de proyectos/órdenes JV-relevantes | PS/CO (presupuesto vs real) |
| Reporte de auditoría de partner | Trazabilidad completa costo origen → cutback → billing | `ACDOCA` + `GJUBI` + documentos FI |

## 2. Dimensiones Típicas de Análisis

- Por Venture
- Por Equity Group / Partner
- Por Recovery Indicator (billable vs non-billable vs overhead)
- Por periodo (mensual, con drill-down a documento origen)
- Por objeto CO (centro de coste, orden, WBS)

## 3. Consultas MCP Útiles (GetSqlQuery)

### Resumen de costo distribuido por venture y partner (periodo)

```sql
SELECT venture, partner, sum(wkgbtr) as monto
FROM gjubi
WHERE gjahr = '{year}'
  AND monat = '{periodo}'
GROUP BY venture, partner
ORDER BY venture, partner
```

### Comparación costo 100% (ACDOCA) vs distribuido (GJUBI) por venture

```sql
-- Costo 100% — requiere cruzar objetos CO del venture (csks/aufk) con ACDOCA
SELECT sum(hsl) as costo_100
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND gjahr = '{year}'
  AND rldnr = '0L'

-- Total distribuido
SELECT sum(wkgbtr) as total_distribuido
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
```

### Overhead recovery acumulado del año por venture

```sql
SELECT venture, sum(wkgbtr) as overhead_total
FROM gjubi
WHERE gjahr = '{year}'
  AND recind IN ('{lista_ri_overhead}')
GROUP BY venture
```

## 4. Herramientas de Reporting Disponibles

- Reportes estándar del menú de aplicación JVA (statements, resúmenes de cutback)
- Report Painter/Writer clásico sobre objetos CO/JVA para reporting a medida
- CDS Views custom sobre `GJUBI`/`ACDOCA` para embedded analytics moderno (ver
  `27-embedded-analytics.md`)
- Consultas MCP directas (`GetSqlQuery`) para diagnóstico ad-hoc y validación rápida durante
  soporte AMS

## 5. Buenas Prácticas de Reporting

1. Diseñar el reporte de statement pensando en que el partner debe poder reconciliarlo sin
   contexto adicional del operador — incluir siempre el detalle mínimo descrito en
   `13-partner-audits-statements.md`.
2. Automatizar la reconciliación GJUBI vs ACDOCA como parte del checklist de cierre, no como
   ejercicio manual ad-hoc.
3. Mantener un dashboard de exposición de cash calls pendientes visible para el equipo de cierre
   antes de cada corte de mes.
