# CO-PA — Profitability Analysis

## Dos variantes de CO-PA

| Aspecto | Costing-based (clasico) | Account-based (S/4 default) |
|---------|------------------------|----------------------------|
| Tabla | CE1xxxx, CE2xxxx, CE3xxxx | ACDOCA |
| Valoracion | A valores de coste | A valores contables |
| Reconciliacion con FI | Necesaria | Automatica (misma tabla) |
| S/4HANA 2023 | Disponible pero legacy | **Recomendado / Default** |
| Nombre S/4 | CO-PA clasico | Margin Analysis |

### Cambio critico S/4HANA

En S/4HANA 2023, **Margin Analysis (account-based CO-PA)** es el default:
- Usa ACDOCA directamente (no tablas CE*)
- Los "value fields" se reemplazan por cuentas GL
- No requiere reconciliacion FI↔CO-PA
- Soporta Fiori apps de analisis de margen (F5889)

## Caracteristicas tipicas del segmento PA

| Caracteristica | Campo ACDOCA | Descripcion |
|----------------|-------------|-------------|
| Cliente | KUNNR | Customer |
| Material | MATNR | Product |
| Org ventas | VKORG | Sales organization |
| Canal | VTWEG | Distribution channel |
| Sector | SPART | Division |
| Grupo cliente | KDGRP | Customer group |
| Grupo material | MATKL | Material group |
| Centro beneficio | PRCTR | Profit center |

### Consulta MCP — Margin Analysis

```sql
-- Margen por cliente (S/4HANA account-based)
SELECT KUNNR, RACCT, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND KUNNR <> ''
AND RACCT BETWEEN '800000' AND '899999'
GROUP BY KUNNR, RACCT
ORDER BY KUNNR

-- Contribution margin por org ventas
SELECT VKORG, VTWEG,
       SUM(CASE WHEN RACCT BETWEEN '800000' AND '809999' THEN HSL ELSE 0 END) AS REVENUE,
       SUM(CASE WHEN RACCT BETWEEN '890000' AND '899999' THEN HSL ELSE 0 END) AS COGS
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND VKORG <> ''
GROUP BY VKORG, VTWEG
```

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| KE21N | Contabilizacion manual CO-PA | — |
| KE24 | Partidas individuales real | — |
| KE30 | Reportes CO-PA | F5765 |
| KEPM | Planificacion CO-PA | — |
| KEU5 | Transfer CO-PA periodica | — |

### SPRO Path
`SPRO > Controlling > Cuenta resultados > Estructuras > Definir estructura operativa (KEA0)`
`SPRO > Controlling > Cuenta resultados > Flujos de valores reales > Activar CO-PA (KEKE)`
