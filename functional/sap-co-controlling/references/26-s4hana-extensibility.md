# S/4HANA 2023 — Extensibilidad CO

## Key User Extensibility (sin codigo)

### Custom Fields en CO

| Area | Donde agregar | App Fiori |
|------|--------------|-----------|
| Centro de coste | Campos adicionales en CSKS | Custom Fields and Logic (F1481) |
| Profit center | Campos adicionales en CEPC | Custom Fields and Logic (F1481) |
| Orden interna | USER0-USER11 (standard) + custom | Custom Fields and Logic (F1481) |
| Journal Entry | Campos extension en ACDOCA | Custom Fields and Logic (F1481) |

## Developer Extensibility (con codigo)

### BAdIs CO principales (Released for S/4)

| BAdI | Descripcion | Uso |
|------|-------------|-----|
| ACC_DOCUMENT | Modify accounting document | Derivaciones FI+CO |
| FCOM_DERIVATION | CO field derivation | Derivar campos CO |
| FCOM_DOCUMENT | CO document processing | Modificar doc CO |
| SETTLEMENT_BADI | Settlement customization | Logica settlement |
| COPA_DERIVATION | CO-PA characteristic derivation | Derivar PA chars |
| COPA_VALUATION | CO-PA valuation | Valoracion custom |
| COST_COMPONENT | Cost component customization | Componentes coste |
| ML_PRICE_DETERMINATION | Material Ledger pricing | Precio ML custom |

### Released APIs (Whitelisted)

| API | Tipo | Descripcion |
|-----|------|-------------|
| I_CostCenter_API | OData v4 | CRUD centros de coste |
| I_ProfitCenter_API | OData v4 | CRUD profit centers |
| I_InternalOrder_API | OData v4 | CRUD ordenes internas |
| I_JournalEntry_API | OData v4 | Lectura Universal Journal |
| I_CostEstimate_API | OData v4 | Lectura calculos coste |

### CDS Views Released

| CDS View | Descripcion |
|----------|-------------|
| I_CostCenter | Centro de coste master |
| I_ProfitCenter | Profit center master |
| I_InternalOrder | Orden interna master |
| I_JournalEntry | Universal Journal |
| I_CostEstimate | Estimacion de costes |
| C_CostCenterActualCostQry | CC costes reales (query) |
| C_ProfitCenterActualCostQry | PC costes reales (query) |

## Consulta MCP — Buscar BAdIs disponibles

```
SearchObject("BADI_*FCOM*")
SearchObject("BADI_*COPA*")
SearchObject("BADI_*SETTLEMENT*")
GetEnhancements("SAPLKMA2")
GetEnhancements("SAPLKO01")
```
