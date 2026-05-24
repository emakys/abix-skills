# BAPIs y Extensibilidad CO

## BAPIs principales

### Centros de coste
| BAPI | Descripcion |
|------|-------------|
| BAPI_COSTCENTER_CREATEMULTIPLE | Crear centros de coste |
| BAPI_COSTCENTER_CHANGEMULTIPLE | Modificar centros de coste |
| BAPI_COSTCENTER_GETLIST | Listar centros de coste |
| BAPI_COSTCENTER_GETDETAIL1 | Detalle de un centro de coste |

### Profit Centers
| BAPI | Descripcion |
|------|-------------|
| BAPI_PROFITCENTER_CREATE | Crear profit center |
| BAPI_PROFITCENTER_CHANGE | Modificar profit center |
| BAPI_PROFITCENTER_GETLIST | Listar profit centers |

### Ordenes internas
| BAPI | Descripcion |
|------|-------------|
| BAPI_INTERNALORDER_CREATE | Crear orden interna |
| BAPI_INTERNALORDER_CHANGE | Modificar orden interna |
| BAPI_INTERNALORDER_GETLIST | Listar ordenes |
| BAPI_INTERNALORDER_GETDETAIL | Detalle orden |
| BAPI_INTERNALORDER_GETSTATUS | Status orden |

### Contabilizaciones CO
| BAPI | Descripcion |
|------|-------------|
| BAPI_ACC_ACTIVITY_ALLOC_POST | Contabilizar actividad interna |
| BAPI_ACC_STAT_KEY_FIG_POST | Contabilizar cifra estadistica |
| BAPI_ACC_MANUAL_ALLOC_POST | Contabilizar reparto manual |

## BAdIs CO (S/4HANA)

| BAdI | Descripcion |
|------|-------------|
| ACC_DOCUMENT | Modify accounting document (universal) |
| FCOM_DERIVATION | Derivacion campos en contabilizacion CO |
| FCOM_DOCUMENT | Modificar documento CO |
| SETTLEMENT_BADI | Logica customizada en liquidacion |
| COPA_DERIVATION | Derivacion de caracteristicas CO-PA |
| COPA_VALUATION | Valoracion CO-PA |
| COST_COMPONENT | Componentes de coste custom |
| ML_PRICE_DETERMINATION | Material Ledger precio |

## User Exits clasicos (ECC)

| Exit | Descripcion | Area |
|------|-------------|------|
| COOM0001-0007 | Ordenes CO | Ordenes |
| COPA0001-0008 | CO-PA derivation/valuation | CO-PA |
| COPCP001-003 | Product costing | Costing |

## Consulta MCP — Buscar enhancements

```
SearchObject("BADI_*FCOM*")
SearchObject("BAPI_COSTCENTER*")
SearchObject("BAPI_INTERNALORDER*")
GetEnhancements("SAPLKO01")
GetEnhancements("SAPLKMA2")
```
