# Extensibilidad PP — S/4HANA

## Key User Extensibility (sin ABAP)

### Custom Fields

Campos custom disponibles en:
- Production Order (header, operations)
- BOM Items
- Routing Operations
- Planned Orders
- Confirmations

### Proceso
1. App Fiori "Custom Fields and Logic" (F1734)
2. Agregar campo (nombre, tipo, longitud)
3. Publicar → aparece en Fiori apps
4. Opcional: Custom Logic (BAdI key user) para validaciones

### Custom Logic (Key User BAdIs)

| Area | BAdI | Descripcion |
|------|------|-------------|
| Production Order | WORKORDER_UPDATE | Validar/modificar datos orden |
| Confirmation | WORKORDER_CONFIRM | Logica en confirmacion |
| Goods Movement | WORKORDER_GOODSMVT | Logica en GI/GR |
| Scheduling | ORDER_SCHEDULING | Ajustar scheduling |

## BAdIs ABAP (Developer Extensibility)

### Ordenes de produccion

| BAdI | Descripcion | Uso tipico |
|------|-------------|------------|
| WORKORDER_UPDATE | Crear/modificar orden | Validaciones custom, defaulting |
| WORKORDER_CONFIRM | Confirmacion | Validar cantidades, datos adicionales |
| WORKORDER_GOODSMVT | Movimientos orden | Logica adicional en GI/GR |
| PROD_ORDER_CREATE | Creacion orden | Valores default, validacion |
| PROD_ORDER_RELEASE | Liberacion | Verificaciones adicionales |
| ORDER_SCHEDULING | Scheduling | Ajustar fechas/duraciones |
| PRODUCTION_ORDER_STATUS | Cambio status | Acciones en cambio status |

### MRP

| BAdI | Descripcion | Uso tipico |
|------|-------------|------------|
| MD_CHANGE_MRP_DATA | Datos MRP | Modificar parametros MRP |
| MD_ADD_ELEMENTS | Elementos MRP | Agregar elementos custom |
| MD_REDUCE_STOCK | Reduccion stock | Ajustar stock disponible |
| MD_PLANNING_RESULT | Post-MRP | Procesamiento resultado MRP |
| MD_PLANNED_ORDER_CREATE | Crear previsional | Valores custom en previsional |

### BOM

| BAdI | Descripcion | Uso tipico |
|------|-------------|------------|
| BOM_UPDATE | Actualizar BOM | Validaciones custom BOM |
| CS_BOM_EXPLOSION | Explosion BOM | Filtrar/agregar componentes |
| BOM_ITEM_CHECK | Check posicion | Validar componentes |

### Routing

| BAdI | Descripcion | Uso tipico |
|------|-------------|------------|
| ROUTING_UPDATE | Actualizar routing | Validaciones operaciones |
| ROUTING_OPERATION_CHECK | Check operacion | Validar tiempos, puesto |

## APIs Released for Cloud (ABAP Environment)

### OData V4 APIs

| API | Descripcion | Operaciones |
|-----|-------------|-------------|
| API_PRODUCTION_ORDER | Ordenes produccion | CRUD + Release + TECO |
| API_PRODUCTION_ORDER_CONFIRMATION | Confirmaciones | Create + Cancel |
| API_PLANNED_ORDER | Ordenes previsionales | CRUD + Convert |
| API_BILL_OF_MATERIAL | BOM | CRUD |
| API_PRODUCTION_ROUTING | Routing | CRUD |
| API_MATERIAL_STOCK | Stock | Read |

### Communication Scenarios

| Scenario | Descripcion |
|----------|-------------|
| SAP_COM_0420 | Production Order Integration |
| SAP_COM_0421 | Production Confirmation Integration |
| SAP_COM_0530 | MRP Integration |
| SAP_COM_0105 | Material Stock Integration |

## CDS Views Released (C1)

### Para extension/reporting

| CDS View | Descripcion | Extensible |
|----------|-------------|------------|
| I_ProductionOrder | Orden produccion | Si (extend view) |
| I_ProductionOrderItem | Posicion orden | Si |
| I_ProductionOrderOperation | Operacion | Si |
| I_ProductionOrderConfirmation | Confirmacion | Si |
| I_PlannedOrder | Previsional | Si |
| I_BillOfMaterial | BOM | Si |
| I_BillOfMaterialItem | Posicion BOM | Si |
| I_ProductionRouting | Routing | Si |

### Extension de CDS Views
```sql
extend view I_ProductionOrder with ZX_ProductionOrder {
  -- custom fields
  _Extension.YY1_CustomField as CustomField
}
```

## Enhancement Spots (classic)

| Enhancement Spot | Programa | Area |
|------------------|----------|------|
| ES_SAPLCOBT | SAPLCOBT | Orden produccion |
| ES_SAPLCOZV | SAPLCOZV | Confirmaciones |
| ES_MRP | SAPLM61X | MRP |
| ES_BOM | SAPLCSDI | BOM maintenance |
| ES_ROUTING | SAPLCAPL | Routing |

## Patron recomendado S/4HANA

```
1. Key User Extensibility (campos + logica simple)
   ↓ Si no es suficiente
2. BAdI Developer Extensibility (logica compleja)
   ↓ Si necesita integracion
3. API OData + Events (integracion externa)
   ↓ Solo si necesario
4. Classic Enhancement (user exits, implicit enhancements)
```
