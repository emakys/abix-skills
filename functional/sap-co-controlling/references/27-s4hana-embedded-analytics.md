# S/4HANA 2023 — Embedded Analytics CO

## Arquitectura

```
Transactional Data (ACDOCA)
    |
    v
CDS Views (I_* → C_*)
    |
    v
Fiori Analytical Apps / KPI Tiles / SAC Live Connection
```

## CDS Views analiticas CO

### Cost Center Accounting

| CDS View | Descripcion |
|----------|-------------|
| I_CostCenterActualCost | CC costes reales base |
| C_CostCenterActualCostQry | CC costes reales (query) |
| C_CostCenterPlanActualQry | CC plan vs real |
| I_CostCenterHierarchy | Jerarquia CC |

### Profit Center Accounting

| CDS View | Descripcion |
|----------|-------------|
| I_ProfitCenterActualCost | PC costes reales base |
| C_ProfitCenterActualCostQry | PC costes reales (query) |
| C_ProfitCenterPlanActualQry | PC plan vs real |

### Internal Orders

| CDS View | Descripcion |
|----------|-------------|
| I_InternalOrderActualCost | Orden costes reales base |
| C_InternalOrderActualCostQry | Orden costes reales (query) |
| C_InternalOrderBudgetActualQry | Orden presupuesto vs real |

### CO-PA / Margin Analysis

| CDS View | Descripcion |
|----------|-------------|
| C_ProfitabilityAnalysisQry | CO-PA multidimensional |
| C_MarginAnalysisQry | Margen contribucion |

## KPI Tiles para Fiori Launchpad

| KPI | Descripcion | CDS Source |
|-----|-------------|-----------|
| Cost Center Variance | Desviacion plan/real CC | C_CostCenterPlanActualQry |
| Budget Utilization | % consumo presupuesto | C_InternalOrderBudgetActualQry |
| Profit Center P&L | P&L por PC | C_ProfitCenterActualCostQry |
| Margin % | Margen contribucion % | C_MarginAnalysisQry |

## SAP Analytics Cloud (SAC)

### Modelos CO en SAC

| Modelo | Fuente | Tipo |
|--------|--------|------|
| Cost Center Analysis | C_CostCenterActualCostQry | Live |
| Profit Center P&L | C_ProfitCenterActualCostQry | Live |
| Order Analysis | C_InternalOrderActualCostQry | Live |
| Margin Analysis | C_MarginAnalysisQry | Live |

### SAC Planning write-back

```
SAC Planning Model
    → Define dimensions (CC, PC, cost element, version)
    → Users input plan data
    → Write-back to S/4HANA ACDOCA (version plan)
    → Available in S/4 reports
```
