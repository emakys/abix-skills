# Reporting — SAP RE-FX

## 1. Reportes Centrales del Ciclo RE-FX

| Reporte | Propósito | Fuente de datos |
|---|---|---|
| Cartera de contratos vigentes / por vencer | Visibilidad de todo el portafolio contractual, con alertas de vencimiento próximo | `VICNCN` |
| Análisis de vacancia y ocupación | Tasa de vacancia por Business Entity/Building/tipo de uso | `VIBDOB` + `VICNCN` |
| Reporte de liquidación de gastos comunes por inquilino | Detalle de costo prorrateado y comparación vs anticipos | Resultado de la liquidación (`RESC`) |
| Reporte IFRS 16 por contrato lease-in | ROU asset, pasivo, gasto financiero, amortización | `ANLA`/`ACDOCA` + detalle de contrato |
| Reporte de ajuste de renta ejecutado vs pendiente | Seguimiento de la ejecución del calendario de ajustes | `VICNCND` (histórico de condiciones) |
| Reporte de rentabilidad por objeto/Business Entity | Ingreso por renta vs costo operativo/depreciación | `ACDOCA` (todas las dimensiones) |

## 2. Dimensiones Típicas de Análisis

- Por Business Entity / Building / Rental Object
- Por tipo de uso (oficina, retail, industrial, residencial)
- Por inquilino/Business Partner
- Por tipo de contrato (lease-out vs lease-in)
- Por periodo, con drill-down a documento origen

## 3. Consultas MCP Útiles (GetSqlQuery)

### Renta facturada del periodo por Business Entity

```sql
SELECT rbukrs, sum(hsl) as renta_total
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
  AND racct = '{cuenta_ingreso_renta}'
GROUP BY rbukrs
```

### Contratos próximos a vencer (90 días)

```sql
SELECT vertrag, vertnr, venddat
FROM vicncn
WHERE venddat BETWEEN CURRENT_DATE AND CURRENT_DATE + 90
ORDER BY venddat
```

### Tasa de ocupación aproximada por Building

```sql
SELECT
  count(*) as total_objetos,
  sum(case when meinh in (select vertrag from vicncn where vbegdat <= current_date and venddat >= current_date) then 1 else 0 end) as objetos_ocupados
FROM vibdob
WHERE gebaeude = '{building}'
```

## 4. Herramientas de Reporting Disponibles

- Reportes estándar del menú de aplicación RE-FX (cartera, vencimientos, gastos comunes)
- Fiori apps analíticas sobre CDS Views de RE-FX (ver `24-fiori-apps.md` y `27-embedded-analytics.md`)
- Report Painter/Writer clásico sobre objetos CO/RE-FX para reporting a medida
- Consultas MCP directas (`GetSqlQuery`) para diagnóstico ad-hoc y validación rápida durante soporte

## 5. Buenas Prácticas de Reporting

1. Diseñar el reporte de liquidación de gastos comunes pensando en que el inquilino debe poder
   entenderlo sin contexto adicional — incluir el detalle mínimo de tipo de gasto, factor de
   reparto y comparación con anticipos.
2. Automatizar la reconciliación entre renta facturada y contratos/condiciones vigentes como parte
   del checklist de cierre, detectando discrepancias antes de que se acumulen.
3. Mantener un dashboard de vencimientos próximos visible para el equipo de gestión de portafolio,
   con anticipación suficiente para negociar renovaciones.
4. Para reporting IFRS 16, coordinar con el equipo de FI el formato exigido por la nota a los
   estados financieros — suele requerir desgloses específicos (vencimientos del pasivo por tramos
   de tiempo) no cubiertos automáticamente por reportes operativos de RE-FX.
