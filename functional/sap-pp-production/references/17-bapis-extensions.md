# BAPIs, Extensiones y Exits PP

## BAPIs principales PP

### Ordenes de produccion

| BAPI | Descripcion |
|------|-------------|
| BAPI_PRODORD_CREATE | Crear orden produccion |
| BAPI_PRODORD_CHANGE | Modificar orden produccion |
| BAPI_PRODORD_GET_DETAIL | Leer detalle orden |
| BAPI_PRODORD_CLOSE | Cerrar orden (TECO) |
| BAPI_PRODORD_RELEASE | Liberar orden |
| BAPI_PRODORDCONF_CREATE_HDR | Crear confirmacion (cabecera) |
| BAPI_PRODORDCONF_CREATE_ACT | Crear confirmacion (actividades) |
| BAPI_PRODORDCONF_CANCEL | Anular confirmacion |
| BAPI_PRODORDCONF_GET_HDR_DATA | Leer confirmaciones |

### BOM

| BAPI | Descripcion |
|------|-------------|
| CSAP_MAT_BOM_CREATE | Crear BOM material |
| CSAP_MAT_BOM_MAINTAIN | Modificar BOM |
| CSAP_MAT_BOM_READ | Leer BOM |
| CSAP_MAT_BOM_DELETE | Borrar BOM |
| BAPI_BOM_ITEM_CHANGE | Cambiar posiciones |
| CS_BOM_EXPL_MAT_V2 | Explotar BOM multi-nivel |

### Routing

| BAPI | Descripcion |
|------|-------------|
| BAPI_ROUTING_CREATE | Crear routing |
| BAPI_ROUTING_CHANGE | Modificar routing |
| BAPI_ROUTING_GET | Leer routing |
| BAPI_ROUTING_DELETE | Borrar routing |

### MRP / Planificacion

| BAPI | Descripcion |
|------|-------------|
| BAPI_MATERIAL_STOCK_REQ_LIST | Leer lista stock/necesidades (MD04) |
| BAPI_PLANNEDORDER_CREATE | Crear orden previsional |
| BAPI_PLANNEDORDER_CHANGE | Modificar previsional |
| BAPI_PLANNEDORDER_DELETE | Borrar previsional |
| MD_SET_ACTION_PLAF | Convertir previsional |

### Movimientos

| BAPI | Descripcion |
|------|-------------|
| BAPI_GOODSMVT_CREATE | Crear movimiento mercancias |
| BAPI_GOODSMVT_CANCEL | Anular movimiento |

## User Exits PP

### Ordenes produccion

| Exit | Programa | Descripcion |
|------|----------|-------------|
| PPCO0001 | SAPLCOBT | Creacion orden produccion |
| PPCO0002 | SAPLCOBT | Liberacion orden |
| PPCO0003 | SAPLCOBT | Verificacion disponibilidad |
| PPCO0004 | SAPLCOZV | Confirmacion |
| PPCO0005 | SAPLCORU | Confirmacion — extension datos |
| PPCO0007 | SAPLCOBT | Cambios en orden |
| PPCO0012 | SAPLCOBT | Status orden |
| PPCO0017 | SAPLCOBT | Cierre tecnico |

### BOM

| Exit | Programa | Descripcion |
|------|----------|-------------|
| PCSD0001 | SAPLCSDI | Modificar BOM |
| PCSD0002 | SAPLCSDI | Chequeos BOM |

### MRP

| Exit | Programa | Descripcion |
|------|----------|-------------|
| M61X0001 | SAPLMD0F | MRP — user exit |
| PPIO0009 | SAPLM61X | MRP — procesamiento |

## BAdIs PP (S/4HANA)

### Ordenes

| BAdI | Descripcion |
|------|-------------|
| WORKORDER_UPDATE | Modificacion orden produccion |
| WORKORDER_CONFIRM | Confirmacion orden |
| WORKORDER_GOODSMVT | Movimiento mercancias orden |
| ORDER_SCHEDULING | Scheduling orden |
| PROD_ORDER_CREATE | Creacion orden |
| PROD_ORDER_RELEASE | Liberacion orden |

### MRP

| BAdI | Descripcion |
|------|-------------|
| MD_CHANGE_MRP_DATA | Modificar datos MRP |
| MD_ADD_ELEMENTS | Agregar elementos MRP |
| MD_REDUCE_STOCK | Reducir stock para MRP |
| MD_PLANNING_RESULT | Post-procesamiento MRP |

### BOM / Routing

| BAdI | Descripcion |
|------|-------------|
| BOM_UPDATE | Actualizacion BOM |
| ROUTING_UPDATE | Actualizacion routing |
| CS_BOM_EXPLOSION | Explosion BOM |

## CDS Views PP (S/4HANA)

### Ordenes produccion

| CDS View | Descripcion |
|----------|-------------|
| I_ProductionOrder | Orden produccion |
| I_ProductionOrderItem | Posicion orden |
| I_ProductionOrderOperation | Operacion orden |
| I_ProductionOrderComponent | Componente orden |
| I_ProductionOrderConfirmation | Confirmacion |
| I_ProductionOrderStatus | Status |

### MRP

| CDS View | Descripcion |
|----------|-------------|
| I_MRPElement | Elementos MRP |
| I_PlannedOrder | Orden previsional |
| I_MaterialStockTimeSeries | Serie temporal stock |

### Datos maestros

| CDS View | Descripcion |
|----------|-------------|
| I_BillOfMaterial | BOM |
| I_BillOfMaterialItem | Posiciones BOM |
| I_ProductionRouting | Routing |
| I_ProductionRoutingOperation | Operacion routing |
| I_WorkCenter | Puesto trabajo |

## Programas clave PP

| Programa | Descripcion | Uso |
|----------|-------------|-----|
| SAPLCOBT | Orden produccion (dialogo) | Exit point |
| SAPLCOZV | Confirmacion | Exit point |
| SAPLM61X | MRP engine | Exit point |
| SAPLCSDI | BOM maintenance | Exit point |
| RKKKS_ORDER_WIP | Calculo WIP | Job cierre |
| RKKKS_ORDER_VARIANCE | Desviaciones | Job cierre |
| SAPRCO88 | Settlement | Job cierre |

## Enhancement Spots S/4

| Enhancement Spot | Descripcion |
|------------------|-------------|
| ES_SAPLCOBT | Orden produccion |
| ES_SAPLCOZV | Confirmaciones |
| ES_MRP | MRP processing |
| ES_BOM | BOM maintenance |
