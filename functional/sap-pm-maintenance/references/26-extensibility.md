# Extensibilidad PM en S/4HANA

## Key User Extensibility (Tier 1 — Sin codigo)

### Custom Fields
- Agregar campos a: Orden PM, Aviso, Equipo, Ubicacion tecnica
- App: Manage Custom Fields (F1734)
- Automaticamente visible en Fiori apps y OData

### Custom Logic
- Validaciones y determinaciones sin ABAP
- App: Manage Custom Logic (F1735)
- Triggers: al crear, al modificar, al liberar

### Ejemplo: Campo "Criticidad" en equipo
1. Manage Custom Fields → Equipment → agregar ZZ_CRITICALITY (dropdown: A/B/C)
2. Manage Custom Logic → al crear orden: si equipo criticidad A → prioridad automatica 1

## BAdIs Clasicos (Tier 2)

| BAdI | Descripcion | Uso |
|------|-------------|-----|
| WORKORDER_INFOSYSTEM | Ampliar ALV ordenes | Agregar columnas custom a IW38 |
| EQUI_MODIFY | Modificar datos equipo | Validaciones custom al grabar |
| FUNCLOC_MODIFY | Modificar datos ubicacion | Validaciones custom |
| PM_ORDER_RELEASE | Validacion en liberacion | Checks adicionales al liberar |
| PM_NOTIFICATION_CREATE | Ampliacion creacion aviso | Datos default, validaciones |
| MAINTENANCE_PLAN_CALL | Logica de llamada plan | Modificar generacion ordenes |
| PM_ORDER_COMPLETION | Logica al completar orden | Verificaciones pre-TECO |

## User Exits (Tier 2)

| Exit | Programa | Descripcion |
|------|----------|-------------|
| IWO10001 | SAPLCOIH | Verificacion crear orden |
| IWO10002 | SAPLCOIH | Verificacion modificar orden |
| IWO10003 | SAPLCOIH | Verificacion liberar orden |
| IWO10004 | SAPLCOIH | Datos adicionales orden |
| IWO10005 | SAPLCOIH | Verificacion cierre tecnico |
| QQMA0001 | SAPLIQS0 | Verificacion crear aviso |
| QQMA0002 | SAPLIQS0 | Verificacion modificar aviso |
| IEQM0001 | SAPLITO0 | Verificacion equipo |

## RAP APIs (Tier 3 — ABAP Cloud)

### Business Objects PM
| RAP BO | Descripcion |
|--------|-------------|
| I_MaintenanceOrderTP | Orden PM transaccional |
| I_MaintenanceNotificationTP | Aviso PM transaccional |
| I_EquipmentTP | Equipo transaccional |

### Ejemplo extension RAP
```abap
" Agregar validacion custom a orden PM via ABAP Cloud
CLASS zcl_maint_order_val DEFINITION.
  METHODS validate_order FOR VALIDATE ON SAVE
    IMPORTING keys FOR MaintenanceOrder~validateOrder.
ENDCLASS.
```

## Side-by-Side (Tier 4 — BTP)

- CAP application conectada a PM via APIs OData
- Business Events: reaccionar a eventos PM (orden creada, TECO, etc.)
- IoT data → BTP → generar avisos/ordenes via API
- Custom dashboards en SAP Build Work Zone

## Guia de Decision

```
¿Que tipo de extension?
├── Campo adicional simple → Key User (Custom Fields)
├── Validacion/determinacion simple → Key User (Custom Logic)
├── Logica compleja en mismo sistema → BAdI / User Exit
├── API/integracion externa → RAP / OData API
└── App externa con logica independiente → BTP Side-by-Side
```
