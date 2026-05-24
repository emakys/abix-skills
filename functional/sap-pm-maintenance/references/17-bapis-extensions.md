# BAPIs, Exits y Extensibilidad PM

## BAPIs Principales

### Ordenes de Mantenimiento
| BAPI | Descripcion |
|------|-------------|
| BAPI_ALM_ORDER_MAINTAIN | Crear/modificar orden PM (completa) |
| BAPI_ALM_ORDER_GET_DETAIL | Leer detalle orden |
| BAPI_ALM_ORDER_RELEASE | Liberar orden |
| BAPI_ALM_ORDER_CLOSE | Cierre tecnico |
| BAPI_ALM_ORDEROPER_GET_LIST | Lista operaciones |
| BAPI_ALM_ORDERCOMP_GET_LIST | Lista componentes |
| BAPI_ALM_CONF_CREATE | Crear confirmacion |
| BAPI_ALM_CONF_CANCEL | Cancelar confirmacion |

### Avisos
| BAPI | Descripcion |
|------|-------------|
| BAPI_ALM_NOTIF_CREATE | Crear aviso |
| BAPI_ALM_NOTIF_SAVE | Grabar aviso |
| BAPI_ALM_NOTIF_CLOSE | Cerrar aviso |
| BAPI_ALM_NOTIF_GET_DETAIL | Leer detalle aviso |
| BAPI_ALM_NOTIF_DATA_MODIFY | Modificar aviso |
| BAPI_ALM_NOTIF_LIST | Lista avisos |

### Equipos
| BAPI | Descripcion |
|------|-------------|
| BAPI_EQUI_CREATE | Crear equipo |
| BAPI_EQUI_CHANGE | Modificar equipo |
| BAPI_EQUI_GETDETAIL | Leer detalle equipo |
| BAPI_EQUI_GETLIST | Lista equipos |
| BAPI_EQUI_INSTALL | Instalar equipo en ubicacion |
| BAPI_EQUI_DISMANTLE | Desinstalar equipo |

### Ubicaciones Tecnicas
| BAPI | Descripcion |
|------|-------------|
| BAPI_FUNCLOC_CREATE | Crear ubicacion tecnica |
| BAPI_FUNCLOC_CHANGE | Modificar ubicacion |
| BAPI_FUNCLOC_GETDETAIL | Leer detalle ubicacion |
| BAPI_FUNCLOC_GETLIST | Lista ubicaciones |

### Planes de Mantenimiento
| BAPI | Descripcion |
|------|-------------|
| BAPI_ALM_MPLAN_CREATE | Crear plan mantenimiento |
| BAPI_ALM_MPLAN_CHANGE | Modificar plan |
| BAPI_ALM_MPLAN_GET_DETAIL | Leer detalle plan |

### Mediciones
| BAPI | Descripcion |
|------|-------------|
| BAPI_MEASUR_CREATE | Crear documento medicion |
| BAPI_MEASUR_GETLIST | Lista mediciones |

## User Exits

### Ordenes PM (SAPLCOIH)
| Exit | Descripcion |
|------|-------------|
| IWO10001 | Verificacion al crear orden |
| IWO10002 | Verificacion al modificar orden |
| IWO10003 | Verificacion al liberar orden |
| IWO10004 | Datos adicionales de orden |
| IWO10005 | Verificacion cierre tecnico |
| IWO10007 | Determinacion valores default |

### Avisos (SAPLIQS0)
| Exit | Descripcion |
|------|-------------|
| QQMA0001 | Verificacion crear aviso |
| QQMA0002 | Verificacion modificar aviso |
| QQMA0006 | Datos adicionales aviso |
| QQMA0014 | Verificacion completar aviso |

### Equipos
| Exit | Descripcion |
|------|-------------|
| IEQM0001 | Verificacion crear/modificar equipo |
| IEQM0002 | Verificacion instalar/desinstalar |
| IEQM0003 | Determinacion datos default |

## BAdIs S/4HANA

| BAdI | Descripcion |
|------|-------------|
| WORKORDER_INFOSYSTEM | Ampliacion informacion orden |
| EQUI_MODIFY | Modificacion equipo |
| FUNCLOC_MODIFY | Modificacion ubicacion tecnica |
| PM_ORDER_RELEASE | Validacion en liberacion |
| PM_NOTIFICATION_CREATE | Ampliacion creacion aviso |
| MAINTENANCE_PLAN_CALL | Logica llamada de plan |

## Custom Fields & Logic (S/4HANA Key User)

Para extensiones simples sin codigo:
1. Manage Custom Fields → agregar campo a objeto PM (orden, aviso, equipo)
2. Manage Custom Logic → agregar validaciones/determinaciones
3. Disponible para: orden PM, aviso, equipo, ubicacion tecnica

## RAP APIs (S/4HANA 2023)

| API | Tipo | Descripcion |
|-----|------|-------------|
| API_MAINTENANCEORDER_SRV | OData v2 | CRUD ordenes PM |
| API_MAINTENANCENOTIFICATION | OData v2 | CRUD avisos |
| API_EQUIPMENT_SRV | OData v2 | CRUD equipos |
| I_MaintenanceOrderTP | RAP BO | Business Object orden PM |

## Queries MCP para Extension Points

```
-- Buscar exits de PM
SearchObject("IWO1*")
SearchObject("QQMA*")
SearchObject("IEQM*")

-- Buscar BAdIs
GetEnhancements("SAPLCOIH")
GetEnhancements("SAPLIQS0")

-- Buscar clases relevantes
SearchObject("CL_PM_ORDER*")
SearchObject("CL_ISU_PM*")
```
