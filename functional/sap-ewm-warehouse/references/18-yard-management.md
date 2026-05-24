# Yard Management (YM)

## Visión General de Yard Management en EWM

Yard Management (YM) en SAP EWM gestiona los movimientos de trailers, camiones y vehículos dentro del patio (yard) de un centro de distribución o almacén. Cubre desde la llegada del vehículo al portón hasta su posicionamiento en una puerta de carga/descarga y su posterior salida.

En S/4HANA 2023, YM está integrado con EWM y con SAP Transportation Management (TM), permitiendo una coordinación end-to-end desde la planificación del transporte hasta la ejecución en el patio.

---

## Estructura del Patio (Yard Structure)

### Jerarquía de estructura
```
Warehouse Number (/SCWM/)
  └── Yard (patio)
        ├── Yard Zone (zona del patio)
        │     ├── Yard Section (sección)
        │     │     └── Yard Spot (posición de estacionamiento)
        └── Door (puerta de carga/descarga)
```

### Tipos de zonas del patio
| Tipo de zona | Descripción |
|---|---|
| **Staging zone** | Zona de espera general para trailers sin asignar |
| **Inbound zone** | Zona para trailers de recepción de mercancía |
| **Outbound zone** | Zona para trailers de despacho de mercancía |
| **Refrigerated zone** | Zona especial para vehículos refrigerados |
| **Hazmat zone** | Zona para vehículos con materiales peligrosos |
| **Drop lot** | Zona de trailers vacíos disponibles |

### Configuración en /SCWM/CUSTOMIZING
- Yard number: identificador del patio.
- Asignación de yard al warehouse number.
- Definición de zones, sections y spots.
- Capacidad máxima por zona.
- Tipos de vehículo permitidos por zona.

---

## Tipos de Vehículos

Configuración en /SCWM/YM_VEHTYPE:

| Tipo | Descripción |
|---|---|
| **Trailer completo (FTL)** | Semi-trailer estándar de 53 pies |
| **Camión rígido** | Vehículo sin trailer separable |
| **Contenedor** | Contenedor ISO 20'/40' sobre chasis |
| **Refrigerado** | Trailer con unidad de refrigeración |
| **Flatbed** | Plataforma abierta para cargas especiales |
| **Cisterna** | Para líquidos o graneles |

Cada tipo de vehículo tiene:
- Dimensiones (largo, ancho, alto).
- Restricciones de zona (qué zonas puede ocupar).
- Tiempo estándar de check-in/check-out.
- Compatibilidad con tipos de puerta.

---

## Proceso de Check-In

El check-in es la entrada del vehículo al sistema EWM al llegar al patio:

### Pasos del proceso
1. **Llegada**: Conductor llega al portón de entrada.
2. **Registro en portería**: Guardia o sistema registra el vehículo.
3. **Check-in en EWM** (/SCWM/YMCHECKIN):
   - Número de placa / ID del trailer.
   - Tipo de vehículo.
   - Transportista (carrier).
   - Shipment number o delivery number relacionado (si aplica).
   - Sello del trailer.
4. **Asignación de spot**: Sistema asigna posición en el patio (manual o automática).
5. **Tarea de patio creada**: Se genera una Yard Task para mover el trailer.

### Integración con TM
Si hay integración con SAP TM:
- El vehículo llega vinculado a un **freight order**.
- EWM recibe la notificación de llegada desde TM.
- La delivery de TM se vincula automáticamente al check-in de EWM.

---

## Proceso de Check-Out

El check-out registra la salida del vehículo del patio:

1. **Completar carga/descarga**: Todas las tareas de almacén asociadas deben estar confirmadas.
2. **Cierre de delivery**: GR/GI (goods receipt/goods issue) completado.
3. **Check-out en EWM** (/SCWM/YMCHECKOUT):
   - Verificación de que no hay tareas pendientes para el vehículo.
   - Registro de sello final (outbound).
   - Hora de salida.
4. **Liberación del spot**: La posición en el patio queda disponible.
5. **Notificación a TM**: Actualización del estado del freight order.

---

## Asignación de Puertas (Door Assignment)

La asignación de puertas conecta el trailer con la puerta de muelle donde se hará la carga o descarga:

### Tipos de asignación
1. **Manual**: Supervisor asigna la puerta manualmente en /SCWM/YMDOOR.
2. **Automática**: Sistema asigna según reglas de optimización (zona, tipo de entrega, disponibilidad).
3. **Pre-asignada**: La puerta se asigna antes de que llegue el vehículo (appointment-based).

### Criterios de asignación automática
- Tipo de entrega (inbound/outbound).
- Temperatura requerida (si hay puertas refrigeradas).
- Zona de picking/staging asignada a la delivery.
- Disponibilidad de puerta (no ocupada por otro trailer).
- Tipo de vehículo vs. capacidad de la puerta.

### Configuración de puertas
/SCWM/CUSTOMIZING → Doors:
- Asignación de puerta al warehouse number.
- Tipo de puerta (inbound, outbound, cross-dock, universal).
- Temperatura (ambient, refrigerado, congelado).
- Dimensiones máximas de vehículo admitido.
- Zona del almacén que atiende (staging area asociada).

---

## Yard Task (Tarea de Patio)

Una Yard Task es la instrucción de mover un trailer de un spot a otro dentro del patio (o desde el portón hasta una puerta):

### Tipos de yard task
| Tipo | Descripción |
|---|---|
| **Check-in move** | Mover trailer del portón al spot asignado |
| **Door assignment move** | Mover trailer del spot a la puerta de muelle |
| **Spot-to-spot move** | Reubicar trailer entre spots |
| **Check-out move** | Mover trailer de puerta al portón de salida |

### Ejecución de yard tasks
Las yard tasks son ejecutadas por:
- **Yard jockey / hostler**: Conductor de tractor de patio.
- Puede confirmarse en RF, Fiori o transacción SAP.

### Estados de una yard task
```
Created → Assigned (a recurso) → In Process → Confirmed/Completed
```

---

## Programación de Citas (Appointment Scheduling)

El módulo de citas permite pre-programar la llegada y asignación de vehículos:

### Funcionalidades
- Crear slots de tiempo para carga y descarga.
- Asignar puerta y hora a transportistas externos.
- Portal de auto-registro para conductores.
- Alertas por llegada tardía o anticipada.
- Integración con TM Freight Order.

### Configuración
/SCWM/YMAPPOINTMENT:
- Definir ventanas horarias disponibles por puerta.
- Duración estándar de carga/descarga por tipo de vehículo.
- Reglas de buffer entre citas.
- Notificaciones automáticas al transportista.

---

## Yard Monitor

El Yard Monitor (/SCWM/YMMONITOR) es la pantalla central de control del patio:

### Información visible
- Mapa visual del patio con posición de cada trailer.
- Estado de cada spot (ocupado, libre, bloqueado).
- Estado de cada puerta (libre, ocupada, en proceso de carga/descarga).
- Yard tasks pendientes y en proceso.
- Vehículos esperando check-in.
- Tiempos de permanencia por vehículo (dwell time).

### Fiori app equivalente (S/4HANA 2023)
- **Yard Management Overview** (F3600): Vista de mapa del patio, gestión de puertas y spots en tiempo real.
- **Manage Yard** (F3601): Crear y gestionar yard tasks, check-in/out.

---

## Integración con Transportation Management (TM)

La integración EWM-TM en S/4HANA 2023 es nativa (misma instancia en Embedded):

### Flujo integrado
```
TM: Freight Order planificado
  → TM: Freight Order confirmado con ETA
  → EWM YM: Notificación de llegada esperada
  → EWM YM: Check-in al llegar
  → EWM YM: Asignación de puerta
  → EWM: Procesamiento de delivery (GR/GI)
  → EWM YM: Check-out
  → TM: Confirmación de entrega completada
```

### Datos que fluyen TM → EWM YM
- Número de freight order / shipment.
- Carrier y tipo de vehículo.
- ETA (estimated time of arrival).
- Deliveries incluidas en el viaje.
- Temperatura requerida para el transporte.

---

## Consultas MCP relevantes para Yard Management

### Consultar vehículos actualmente en el patio
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMVEH
  fields: [LGNUM, YARD_NUM, VEH_ID, PLATE_NUM, VEH_TYPE, SPOT_ID, DOOR_ID, STATUS, CHECKIN_TS]
  where: LGNUM = '[WH]' AND STATUS NOT IN ('CHECKED_OUT')
  order_by: CHECKIN_TS DESC
```

### Consultar spots disponibles en el patio
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMSPOT
  fields: [LGNUM, YARD_NUM, ZONE_ID, SPOT_ID, SPOT_TYPE, STATUS, VEH_ID]
  where: LGNUM = '[WH]' AND STATUS = 'FREE'
```

### Consultar puertas y su estado
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMDOOR
  fields: [LGNUM, DOOR_ID, DOOR_TYPE, STATUS, VEH_ID, LAST_UPDATED]
  where: LGNUM = '[WH]'
```

### Consultar yard tasks pendientes
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMTASK
  fields: [LGNUM, TASK_ID, TASK_TYPE, VEH_ID, SPOT_FROM, SPOT_TO, DOOR_TO, STATUS, RSRC]
  where: LGNUM = '[WH]' AND STATUS IN ('A', 'I')
  order_by: CREATED_TS ASC
```

### Consultar citas programadas para el día
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMAPPT
  fields: [LGNUM, APPT_ID, CARRIER, VEH_TYPE, DOOR_ID, APPT_DATE, APPT_TIME, APPT_END_TIME, STATUS]
  where: LGNUM = '[WH]' AND APPT_DATE = '[DATE]'
  order_by: APPT_TIME ASC
```

### Calcular tiempo de permanencia (dwell time) de vehículos
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMVEH
  fields: [LGNUM, VEH_ID, PLATE_NUM, CHECKIN_TS, CHECKOUT_TS, SPOT_ID, DOOR_ID]
  where: LGNUM = '[WH]' AND CHECKIN_TS >= '[TIMESTAMP_FROM]'
```

### Buscar movimientos de un trailer específico
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/YMLOG
  fields: [LGNUM, VEH_ID, EVENT_TYPE, SPOT_FROM, SPOT_TO, DOOR_ID, UNAME, EVENT_TS]
  where: LGNUM = '[WH]' AND VEH_ID = '[VEHICLE_ID]'
  order_by: EVENT_TS ASC
```
