# Queues y Resources

## Concepto de Cola (Queue)

En SAP EWM S/4HANA 2023, una **cola** (queue) es el mecanismo principal de distribución de trabajo entre recursos del almacén. Las tareas de almacén (Warehouse Tasks, WT) se asignan a colas, y los recursos (usuarios RF, montacargas) toman trabajo de las colas según su habilitación y asignación.

Las colas permiten:
- Segmentar el trabajo por zona, proceso o prioridad
- Balancear la carga entre recursos disponibles
- Controlar el flujo de trabajo sin asignación manual de tareas

Una tarea solo puede pertenecer a **una cola a la vez**. La determinación de cola ocurre al crear la WT y puede recalcularse.

## Tipos de Cola

### Colas de Entrada (Inbound Queues)
- Asociadas al procesamiento de entregas de entrada
- Tareas: putaway, confirmación de GR, desconsolidación
- Se activan cuando llegan entregas esperadas o inesperadas

### Colas de Salida (Outbound Queues)
- Asociadas a picking, packing, staging y carga
- Se alimentan principalmente desde waves
- Permiten separar picking de packing en colas distintas

### Colas Internas (Internal Queues)
- Para movimientos internos: reposición, redistribución, slotting
- Independientes del flujo inbound/outbound

### Colas de Excepción
- Tareas con errores o que requieren intervención manual
- Los supervisores revisan y resuelven desde estas colas

## Reglas de Determinación de Cola

La determinación de cola se configura en:
IMG > EWM > Cross-Process Settings > Warehouse Task > Define Queue Determination

La determinación evalúa en orden:
1. Tipo de movimiento (movement type)
2. Tipo de proceso de almacén (warehouse process type, WPT)
3. Zona de origen/destino
4. Tipo de almacenamiento origen/destino
5. Tipo de recurso requerido

Se puede extender con el BAdI `/SCWM/EX_QUEUE_DET` para lógica personalizada.

### Ejemplo de Determinación
- WPT = 1010 (Putaway estándar) + Storage Type = HIGH_RACK → Cola "PUTAWAY_HR"
- WPT = 2010 (Picking) + Zona = PICKING_ZONE_A → Cola "PICK_A"
- WPT = 9000 (Excepción) → Cola "EXCEP"

## Tipos de Recursos

### Usuarios RF (Radio Frequency Users)
- Cada usuario que usa un dispositivo RF (handheld, forklift terminal) es un recurso
- Se registran en `/SCWM/RSRC` como tipo `USRF`
- Deben estar logueados en la sesión RF activa para recibir tareas

### Montacargas / Equipos (Equipment Resources)
- Vehículos identificados como recursos del tipo `VH` (vehicle)
- Pueden tener capacidad de carga máxima configurada
- En almacenes automatizados: transportadores (conveyors) como recursos tipo `AUTO`

### Puestos de Trabajo (Work Centers)
- Estaciones fijas (packing, control de calidad, etiquetado)
- Tipo `WKCT`

## Asignación de Recursos a Colas

Los recursos se habilitan para trabajar en colas específicas mediante **Queue-Resource Assignment**:

Ruta: `/SCWM/RSRC` > Modificar recurso > Pestana Queues

Un recurso puede estar habilitado para múltiples colas con distintas prioridades. Cuando el recurso solicita trabajo, el sistema busca en todas sus colas habilitadas y retorna la tarea de mayor prioridad.

La asignación también puede ser dinámica mediante el BAdI `/SCWM/EX_RSRC_QUEUE_SELECT`.

## Calificación de Recursos (Resource Qualification)

Los recursos pueden tener **calificaciones** (qualifications) que determinan qué tipos de tarea pueden realizar:

- Conducir montacargas de gran altura
- Manejo de mercancía peligrosa (HAZMAT)
- Operación de zona refrigerada
- Picking de artículos pesados (>50 kg)

Las calificaciones se asignan al recurso en `/SCWM/RSRC` y se exigen en la configuración del tipo de proceso o del producto.

Configuración de calificaciones: IMG > EWM > Resources > Define Resource Qualifications

## Monitor de Colas

Transacción: `/SCWM/MONQ`

Muestra por cada cola:
- Número de tareas pendientes
- Recursos actualmente trabajando en ella
- Tiempo promedio de espera
- Tareas bloqueadas o con excepción

Desde el monitor se puede:
- Mover tareas de una cola a otra (resolución de cuellos de botella)
- Asignar recursos adicionales a una cola
- Ver detalle de cada tarea pendiente

## Balanceo de Carga (Workload Balancing)

EWM ofrece mecanismos automáticos de balanceo:

1. **Round-Robin**: las tareas se distribuyen equitativamente entre recursos habilitados
2. **Priority-Based**: recursos con mayor prioridad reciben tareas primero
3. **Zone-Based**: los recursos toman tareas de la zona donde ya están trabajando (minimiza desplazamiento)
4. **Interleaving**: en un mismo viaje, el recurso realiza una tarea de salida y una de entrada (optimiza recorridos)

El interleaving se configura por tipo de recurso y zona, y depende de que haya tareas disponibles en ambas direcciones.

## Gestión de Prioridades en Colas

Cada tarea en una cola tiene una prioridad numérica (1-99, menor = más urgente). La prioridad se calcula al crear la WT y puede actualizarse por:

- Cambio en la fecha requerida de la entrega
- Marcado manual de urgencia por supervisor
- Reglas BRF+ de re-priorización automática
- Escalación automática por antigüedad en cola

La re-priorización masiva se puede ejecutar con `/SCWM/RPR` (Report de Repriorización de Colas).

## Tablas Relevantes

| Tabla | Contenido |
|-------|-----------|
| `/SCWM/QUEUE` | Definición de colas del almacén |
| `/SCWM/RSRC` | Maestro de recursos |
| `/SCWM/RSRC_QUEUE` | Asignación recurso-cola con prioridad |
| `/SCWM/RSRC_QUAL` | Calificaciones por recurso |
| `/SCWM/T_QUEUE_DET` | Reglas de determinación de cola |
| `/SCWM/ORDIM_O` | Tareas abiertas (incluye campo QUEUE) |
| `/SCWM/T_RSRC_TYPE` | Tipos de recurso configurados |

## Consultas via MCP (SAP ADT Tools)

```
-- Ver definición de tabla de colas
GetObjectSource: object_type=TABL, uri=/sap/bc/adt/ddic/tables/%2FSCWM%2FQUEUE

-- Buscar clase de determinación de cola
SearchObject: type=CLAS, name=/SCWM/CL_QUEUE*

-- Ver BAdI de determinación de cola
SearchObject: type=ENHO, name=*QUEUE_DET*

-- Leer función de asignación de recurso
SearchObject: type=FUGR, name=/SCWM/RSRC*

-- Buscar reports de gestión de colas
SearchObject: type=PROG, name=/SCWM/R_QUEUE*
```

### Clases y BAdIs Clave

- `/SCWM/CL_QUEUE_DETERMINATION`: Lógica estándar de determinación de cola
- `/SCWM/CL_RSRC_MANAGER`: Gestión del ciclo de vida de recursos RF
- BAdI `/SCWM/EX_QUEUE_DET`: Extension de determinación de cola (método `DETERMINE_QUEUE`)
- BAdI `/SCWM/EX_RSRC_QUEUE_SELECT`: Selección dinámica de colas por recurso
- BAdI `/SCWM/EX_WT_PRIORITY`: Cálculo personalizado de prioridad de tarea

## Transacciones Relacionadas

| Transacción | Función |
|-------------|---------|
| `/SCWM/MONQ` | Monitor de colas en tiempo real |
| `/SCWM/MONR` | Monitor de recursos activos |
| `/SCWM/RSRC` | Mantenimiento de recursos |
| `/SCWM/QUEUE` | Configuración de colas |
| `/SCWM/RPR` | Re-priorización masiva de tareas en cola |
| `/SCWM/RFUI` | Login de usuario RF (inicio de sesión en dispositivo) |

## Configuración Paso a Paso

1. **Definir tipos de recursos**: IMG > EWM > Resources > Define Resource Types
2. **Crear recursos**: `/SCWM/RSRC` — asignar tipo, zona habitual, calificaciones
3. **Definir colas**: IMG > EWM > Cross-Process Settings > Queue > Define Queues — nombre, descripción, almacén
4. **Asignar recursos a colas**: en maestro de recurso, pestaña Queues — cola + prioridad
5. **Configurar determinación**: IMG > Define Queue Determination — WPT + tipo de almacenamiento → cola
6. **Activar interleaving** (opcional): IMG > EWM > Resources > Interleaving — por tipo de recurso y zona
7. **Verificar en monitor**: `/SCWM/MONQ` + `/SCWM/MONR`
