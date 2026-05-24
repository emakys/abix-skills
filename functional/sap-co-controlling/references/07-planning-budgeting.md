# Planificacion y Presupuesto CO

## Niveles de planificacion

| Nivel | Objeto | TCode | Fiori |
|-------|--------|-------|-------|
| Centro coste — costes primarios | CSKS | KP06 | F2723 |
| Centro coste — actividades/tarifas | CSKS | KP26 | F2723 |
| Centro coste — cifras estadisticas | CSKS | KP46 | — |
| Orden interna | AUFK | KPF6 | — |
| Orden interna — presupuesto | AUFK | KO22 | — |
| CO-PA | Segmentos PA | KEPM | — |

## Plan vs Presupuesto

| Concepto | Plan | Presupuesto |
|----------|------|-------------|
| Proposito | Estimacion de costes esperados | Limite de gasto autorizado |
| Obligatorio | No | Opcional (por tipo orden) |
| Control activo | No bloquea contabilizacion | Puede bloquear (KP 045) |
| Granularidad | Por clase coste y periodo | Total o anual |
| Transaccion | KP06 / KPF6 | KO22 / KO24 |

## Consulta MCP — Plan vs Real

```sql
SELECT RCNTR, KSTAR, VRESSION,
       SUM(CASE WHEN POPER = '001' THEN HSL END) AS PER01,
       SUM(CASE WHEN POPER = '002' THEN HSL END) AS PER02,
       SUM(CASE WHEN POPER = '003' THEN HSL END) AS PER03,
       SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND RCNTR = '{cc}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND VRESSION IN ('000', '0')
GROUP BY RCNTR, KSTAR, VRESSION
ORDER BY KSTAR, VRESSION
```

## Reglas de planificacion

1. La version 0 es la version plan principal (obligatoria)
2. La version 000 es siempre la version real (no editable)
3. El plan se copia entre versiones con KP97 (CC) o KO14 (ordenes)
4. El presupuesto tiene 3 niveles de control: sin control, warning, error

### SPRO Path
`SPRO > Controlling > Contabilidad centros coste > Planificacion > Definir versiones (OKEQ)`
`SPRO > Controlling > Ordenes CO > Presupuesto > Definir perfil presupuesto`
