# Warehouse Orders (WO)

## Concepto

La Warehouse Order (WO) es una agrupación lógica de Warehouse Tasks (WTs) asignada a un único recurso (operario, carretilla, robot) para su ejecución. Es la unidad de trabajo que se entrega al operario de almacén.

Una WO puede contener una o varias WTs, siempre del mismo tipo de proceso y para el mismo recurso.

## Relación WO - WT

```
Warehouse Order (WHO)
├── Warehouse Task 1 (ORDIM_O)
├── Warehouse Task 2 (ORDIM_O)
└── Warehouse Task N (ORDIM_O)
```

- Una WO agrupa WTs para optimizar el recorrido del operario.
- Una WT pertenece a una sola WO.
- Una WO se asigna a un solo recurso.

## Tabla principal: /SCWM/WHO

```
Campos clave:
- LGNUM   : Número de almacén
- WHO     : Número de Warehouse Order
- RSRC    : Recurso asignado (operario/equipo)
- QUEUE   : Cola de trabajo
- NSTAT   : Estado del sistema
- USTAT   : Estado de usuario
- PROCTY  : Tipo de proceso
- PRIORITY: Prioridad
- FLGWHO  : Flag tipo WO (normal/replenishment/etc.)
- CREA_DT : Fecha de creación
- CREA_TM : Hora de creación
```

Relación WO-WT: tabla `/SCWM/WHO_ORDIM`

## Estados de una WO

| Estado | Descripción |
|--------|-------------|
| Sin asignar | Creada, sin recurso asignado |
| Asignada | Recurso asignado, pendiente de inicio |
| En proceso | El recurso ha comenzado la ejecución |
| Completada | Todas las WTs confirmadas |
| Cancelada | Anulada (WTs devueltas al pool) |

## Reglas de Creación de WOs

La creación de WOs se configura mediante **Warehouse Order Creation Rules** en `/SCWM/QURULE`.

Parámetros configurables:
- **Máximo de WTs por WO:** limita el tamaño de la orden.
- **Máximo de peso/volumen por WO:** control de capacidad del recurso.
- **Criterios de agrupación:** por zona, ruta, producto, prioridad.
- **Tipo de proceso:** cada tipo tiene sus propias reglas.
- **Cola de destino:** a qué cola se envía la WO creada.

La creación puede ser:
- **Inmediata:** al liberar la wave o confirmar recepción.
- **Por demanda:** cuando el recurso solicita trabajo.
- **Programada:** job background en intervalos definidos.

## Tipos de WO

| Tipo | Descripción |
|------|-------------|
| Normal | Picking o putaway estándar |
| Reabastecimiento | Reposición de bins de picking |
| Inventario | Conteo de stock |
| Traslado | Movimiento interno sin referencia logística |
| Producción | Suministro/retiro de órdenes de producción |

## Colas (Queues)

Las colas son contenedores organizativos de WOs pendientes.

- Configuración en `/SCWM/QUCONT` (contenido de cola) y `/SCWM/QUDEF` (definición).
- Cada cola puede tener prioridad, restricción de recurso y horario.
- Un recurso se suscribe a una o varias colas.
- El sistema asigna la WO de mayor prioridad disponible al recurso que solicita trabajo.

Tipos de cola comunes:
- Cola de picking por zona
- Cola de putaway
- Cola de reabastecimiento
- Cola por tipo de equipo (carretilla elevadora, apiladora, manual)

## Asignación de Recursos

Un **recurso** en EWM puede ser:
- Un usuario (operario con terminal RF).
- Un equipo de manutención (carretilla, traspaleta).
- Un sistema automatizado (AGV, conveyor).

La asignación se realiza:
- **Manualmente:** el supervisor asigna desde `/SCWM/MON`.
- **Automáticamente:** el operario solicita trabajo desde su terminal RF y el sistema le asigna la WO más prioritaria de su cola.
- **Por excepción:** reasignación cuando un recurso queda inactivo.

## Ordenamiento de WTs dentro de la WO

El sistema ordena las WTs dentro de una WO para optimizar el recorrido:

- **Por zona y sección:** agrupa picks de la misma área.
- **Por ruta de picking:** secuencia de bins en orden de pasillo.
- **Por prioridad:** items urgentes primero.
- **Por peso:** items más pesados al inicio (para picking en carro).

Configuración en el perfil de ordenamiento `/SCWM/WOSOR`.

## División (Splitting) de WOs

Una WO puede dividirse si:
- Se detecta que la carga supera la capacidad del recurso.
- Un item no está disponible y debe separarse.
- Se requiere asignar parte del trabajo a otro recurso.

Splitting manual: transacción `/SCWM/WOSPLIT` o desde el monitor.
Splitting automático: configurado en reglas de creación.

## Completado de una WO

Una WO se completa cuando todas sus WTs están confirmadas.
- El sistema libera el recurso para recibir una nueva WO.
- Los documentos de referencia (deliveries) se actualizan.
- Si hay WTs canceladas, la WO se completa con excepciones.

## Monitor de WOs

Transacción `/SCWM/MON` → sección "Warehouse Orders":
- Vista de WOs por estado, recurso, cola, tipo de proceso.
- Drill-down a WTs individuales.
- Acciones: asignar recurso, cancelar WO, forzar completado.

Transacción `/SCWM/WHOVIEW` — vista específica de WOs.

## Consultas MCP relevantes

```
// WOs abiertas sin recurso asignado en almacén ZW01
ReadTable: /SCWM/WHO WHERE LGNUM = 'ZW01' AND RSRC = '' AND NSTAT <> 'C'

// WOs asignadas a un recurso específico
ReadTable: /SCWM/WHO WHERE LGNUM = 'ZW01' AND RSRC = 'RF-USER01' AND NSTAT = 'B'

// WTs pertenecientes a una WO específica
ReadTable: /SCWM/WHO_ORDIM WHERE LGNUM = 'ZW01' AND WHO = '000000001234'

// WOs por cola y prioridad
ReadTable: /SCWM/WHO WHERE LGNUM = 'ZW01' AND QUEUE = 'PICK-ZONE-A' ORDER BY PRIORITY ASCENDING

// WOs completadas hoy
ReadTable: /SCWM/WHO WHERE LGNUM = 'ZW01' AND NSTAT = 'C' AND CREA_DT = SY-DATUM
```

## Notas de implementación S/4HANA 2023

- BAdI `/SCWM/EX_WHO_PROCESS` permite lógica custom en creación, asignación y completado de WOs.
- Para ABAP custom de creación de WOs: función `/SCWM/WHO_CREATE`.
- La integración con sistemas de despacho de recursos (WMS voice, light-directed) se hace via API de cola.
- En S/4HANA 2023, las WOs soportan asignación a robots AGV via SAP EWM Integration for Automated Warehouses.
