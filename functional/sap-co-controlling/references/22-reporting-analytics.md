# Reporting y Analytics CO

## Reportes estandar SAP GUI

### Centro de Coste

| TCode | Descripcion |
|-------|-------------|
| S_ALR_87013611 | Cost Centers: Plan/Actual |
| S_ALR_87013612 | Cost Centers: Plan/Actual/Variance |
| S_ALR_87013614 | Cost Centers: Actual/Plan/Commitment |
| KSB1 | Partidas individuales CC |

### Ordenes Internas

| TCode | Descripcion |
|-------|-------------|
| S_ALR_87012993 | Ordenes: Plan/Actual |
| S_ALR_87012996 | Ordenes: Presupuesto/Actual/Compromiso |
| KOB1 | Partidas individuales orden |

### CO-PA y Product Costing

| TCode | Descripcion |
|-------|-------------|
| KE30 | Ejecutar reporte CO-PA |
| KE24 | Partidas individuales CO-PA |
| CK13N | Visualizar estimacion de costes |
| CKM3N | Cockpit Material Ledger |

## Fiori Apps CO — Reporting

| App ID | Nombre | Area |
|--------|--------|------|
| F3066 | Display Cost Center Costs | CC actual |
| F2723 | Cost Center — Plan/Actual | CC plan vs real |
| F3814 | Display Cost Center Line Items | CC partidas |
| F3737 | Profit Center — Actual | PC actual |
| F1603 | Internal Order — Plan/Actual | Orden plan vs real |
| F2709 | Display Line Items | Universal Journal |
| F5765 | Profitability Analysis | CO-PA multidimensional |
| F5889 | Margin Analysis | Margen contribucion |
| F4012 | Contribution Margin | Margen por dimensiones |
| F0710 | Manage Product Cost Estimates | Calculo costes |
| F0711 | Display Cost Estimate | Detalle calculo |
| F2839 | Material Price Analysis | Material Ledger |

## CDS Analytical Queries (S/4HANA)

| CDS View | Descripcion |
|----------|-------------|
| C_COSTCENTERACTUALCOSTQRY | CC costes reales |
| C_COSTCENTERPLANACTUALQRY | CC plan vs real |
| C_PROFITCENTERACTUALCOSTQRY | PC costes reales |
| C_INTERNALORDERACTUALCOSTQRY | Orden costes reales |
| I_JOURNALENTRY | Universal Journal base |

## Consulta MCP — Datos para reportes

```sql
-- Resumen mensual CC por clase coste
SELECT RCNTR, KSTAR, POPER,
       SUM(CASE WHEN VRESSION = '000' THEN HSL ELSE 0 END) AS ACTUAL,
       SUM(CASE WHEN VRESSION = '0' THEN HSL ELSE 0 END) AS PLAN
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND RCNTR IN ('{cc1}', '{cc2}')
GROUP BY RCNTR, KSTAR, POPER
ORDER BY RCNTR, KSTAR, POPER

-- Top 10 clases de coste por CC
SELECT KSTAR, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND RCNTR = '{cc}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND VRESSION = '000'
GROUP BY KSTAR
ORDER BY SUM(HSL) DESC
```
