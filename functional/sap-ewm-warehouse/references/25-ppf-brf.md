# PPF y BRF+ (Rules Engine)

## Post Processing Framework (PPF)

### Concepto y Rol en EWM

El **Post Processing Framework (PPF)** es un framework genérico de SAP que permite ejecutar acciones automáticas o manuales cuando ocurren eventos en documentos de negocio. En SAP EWM S/4HANA 2023, el PPF se utiliza para automatizar tareas operativas relacionadas con entregas, tareas de almacén, órdenes de embalaje y otros documentos EWM.

El PPF funciona como un motor de disparadores condicionados:
- **Condición**: define cuándo se activa la acción (ej. "cuando una WT es confirmada")
- **Acción**: define qué se ejecuta (ej. "imprimir etiqueta", "confirmar automáticamente la entrega")

### Arquitectura PPF

```
Documento EWM (ej. Outbound Delivery Order)
        |
        v
Evento PPF (ej. SAVE, CONFIRMATION, STATUS_CHANGE)
        |
        v
Evaluación de condiciones PPF
  ├── Condición 1: tipo de proceso = PICKING → Acción: Auto-confirm delivery
  ├── Condición 2: país destino = DE → Acción: Imprimir customs form
  └── Condición 3: always → Acción: Send IDoc to TM
        |
        v
Ejecución de acciones (síncrona o asíncrona vía job)
```

### Tipos de Condición PPF en EWM

Las condiciones determinan si una acción se ejecuta. En EWM se usan dos mecanismos:

1. **Condiciones clásicas PPF** (ABAP-based): función ABAP que retorna verdadero/falso
2. **Condiciones BRF+** (preferido en S/4HANA 2023): función BRF+ que evalúa reglas de negocio en una decision table

La combinación PPF-condición-BRF+ permite que usuarios de negocio mantengan las reglas sin modificar código ABAP.

### Acciones PPF Estándar en EWM

| Acción PPF | Trigger | Descripción |
|------------|---------|-------------|
| Auto-confirm Delivery | WT confirmada | Confirma automáticamente la entrega de salida al confirmar la última WT |
| Auto-print Label | Creación de HU | Imprime etiqueta de HU al crearla (GS Labels, etc.) |
| Auto-release Wave | Condición de tiempo | Libera automáticamente una wave cuando se cumple la hora/condición |
| Send Goods Issue | WT de carga confirmada | Ejecuta el Post Goods Issue (PGI) en MM automáticamente |
| Create Transport Unit | Cierre de carga | Crea unidad de transporte para la expedición |
| Print Packing List | Cierre de HU | Imprime lista de empaque al cerrar HU |
| Auto-confirm WT | Creación de WT | Confirma la WT automáticamente (para movimientos sin confirmación RF) |
| Notify QM | WT de GR confirmada | Envía notificación a QM para crear lote de inspección |

### Configuración de Condiciones PPF

Transacción: `/SCWM/PPFCOND` o via IMG > EWM > Interfaces > PPF > Define Action Conditions

Pasos para configurar una condición:
1. Crear función BRF+ o ABAP que evalúe la condición
2. Asignar la función a una condición PPF (nombre, descripción, clase de condición)
3. Asociar la condición a una acción PPF en el perfil de acción
4. Asignar el perfil de acción al tipo de documento EWM

### Ejecución: Síncrona vs. Asíncrona

- **Síncrona (Immediate)**: la acción se ejecuta en el mismo contexto de la transacción que disparó el evento. Adecuada para acciones rápidas (auto-confirmar, cambiar estado).
- **Asíncrona (via Application Log)**: la acción se encola y ejecuta por un job en background. Adecuada para impresión, envío de mensajes externos, integraciones.
- **Manual**: el usuario puede disparar la acción manualmente desde la pantalla del documento (botón "Process").

## BRF+ (Business Rule Framework Plus)

### Concepto y Ventajas en EWM

**BRF+** (Business Rules Framework Plus, transacción `BRF+`) es el motor de reglas de negocio de SAP, completamente integrado en S/4HANA 2023. Permite definir lógica de negocio compleja mediante **tablas de decisión** (decision tables), expresiones y funciones, sin necesidad de programación ABAP.

En EWM, BRF+ sustituye progresivamente a la customización ABAP en áreas de:
- Determinación de estrategia de putaway
- Estrategia de stock removal (extracción)
- Selección de wave templates
- Determinación de tipo de proceso de almacén (WPT)
- Impresión de etiquetas y documentos
- Condiciones para acciones PPF

### Conceptos Clave de BRF+

| Concepto | Descripción |
|----------|-------------|
| Application | Agrupador de elementos BRF+ (por área de negocio o módulo) |
| Function | Punto de entrada; recibe parámetros de entrada y retorna un resultado |
| Ruleset | Conjunto de reglas asociadas a una función; las reglas se evalúan en orden |
| Rule | Condición + acción (si se cumple la condición, ejecutar esta acción/valor) |
| Decision Table | Tabla de múltiples columnas de entrada y salida; la fila que coincida determina el resultado |
| Expression | Valor calculado (puede ser constante, campo de contexto, resultado de otra función) |

### BRF+ para Determinación de Putaway

Cuando se recibe un producto en el almacén, EWM ejecuta la **putaway determination** para decidir el bin destino. Con BRF+, esta lógica se expresa en una decision table:

```
Ejemplo: Decision Table para Putaway Strategy

| Product Group | Stock Type | Temperature Zone | → Putaway Strategy |
|---------------|------------|------------------|-------------------|
| FRESH         | F          | COLD             | NEARER_BIN         |
| BULK          | F          | AMBIENT          | NEXT_EMPTY_BIN     |
| HAZMAT        | *          | *                | FIXED_BIN          |
| *             | Q          | *                | QI_ZONE            |
| *             | *          | *                | STANDARD           |
```

La función BRF+ recibe como contexto: producto, tipo de almacenamiento, lote, tipo de stock, zona de temperatura. Retorna la estrategia de putaway a aplicar.

### BRF+ para Stock Removal (Estrategia de Extracción)

Similar al putaway, la extracción de stock puede regirse por BRF+:

```
Ejemplo: Decision Table para Stock Removal

| Product Group | Expiry Control | Customer Priority | → Removal Strategy |
|---------------|----------------|-------------------|--------------------|
| PHARMA        | X              | *                 | FEFO_STRICT        |
| FRESH         | X              | HIGH              | FEFO_PRIO          |
| STANDARD      |                | HIGH              | FIFO               |
| *             |                | *                 | LIFO               |
```

### BRF+ para Wave Templates

La selección automática del wave template para una entrega de salida puede realizarse vía BRF+:

```
Decision Table Wave Template Selection:

| Shipping Condition | Carrier | Priority | → Wave Template |
|--------------------|---------|----------|-----------------|
| EXPRESS            | *       | HIGH     | WT_EXPRESS      |
| STANDARD           | DHL     | *        | WT_DHL_STD      |
| STANDARD           | *       | *        | WT_GENERIC      |
```

### BRF+ para Impresión de Etiquetas

La determinación de qué etiqueta imprimir (y en qué impresora) para una HU o entrega puede configurarse en BRF+:

```
Decision Table Label Determination:

| Document Type  | Country | Product Hazmat | → Form       | → Printer      |
|----------------|---------|----------------|--------------|----------------|
| OUTB_DELIVERY  | DE      | X              | HAZMAT_LABEL | LASER_DOCK_A   |
| OUTB_DELIVERY  | US      | *              | FCC_LABEL    | LASER_DOCK_A   |
| HU_PALLET      | *       | *              | PALLET_LABEL | ZEBRA_PACKING  |
```

### Módulos de Función BRF+ en EWM

BRF+ se invoca desde ABAP mediante la clase `/BRF/FUNCTION` o el FM `FDT_PROCESS_FUNCTION`. En EWM existen clases estándar que delegan en BRF+:

- `/SCWM/CL_SRULE_BRF`: Clase base para stock removal rules via BRF+
- `/SCWM/CL_PUT_STRAT_BRF`: Clase base para putaway strategy via BRF+
- `/SCWM/CL_WAVE_TEMPL_BRF`: Selección de wave template via BRF+

El ID de la función BRF+ se parametriza en la customización EWM correspondiente (IMG), por lo que no hay código ABAP que mantener cuando cambian las reglas.

### Ejemplos de Decision Tables

#### Ejemplo 1: Zona de Putaway por Temperatura

```
Tabla de decisión: /SCWM/PUT_ZONE_DETERMINATION

Entradas:
  - /SCWM/DT_PRODUCT.TEMPERATURE_CONDITIONS (valor del maestro de materiales)
  - /SCWM/DT_DELIVERY.INBOUND_TYPE

Salida:
  - /SCWM/DT_RESULT.WAREHOUSE_ZONE

Filas:
  FROZEN  | * → ZONE_FROZEN
  CHILLED | * → ZONE_CHILLED
  *       | CROSS_DOCK → ZONE_XDOCK
  *       | * → ZONE_AMBIENT
```

#### Ejemplo 2: WPT por Tipo de Entrega y Urgencia

```
Tabla de decisión: /SCWM/WPT_DETERMINATION_OUT

Entradas:
  - SHIPPING_CONDITIONS (de la entrega SD)
  - ROUTE

Salida:
  - WAREHOUSE_PROCESS_TYPE

Filas:
  EXPRESS | ROUTE_A → 2020 (Express Picking)
  EXPRESS | *       → 2015 (Priority Picking)
  *       | *       → 2010 (Standard Picking)
```

## Configuración de PPF + BRF+ Integrados

### Pasos para Configurar una Acción PPF con Condición BRF+

1. **Crear función BRF+** en transacción `BRF+`:
   - Nueva application (si no existe para EWM)
   - Nueva function con parámetros de entrada (datos del documento EWM)
   - Crear ruleset + decision table
   - Activar y probar la función

2. **Crear condición PPF** que llame a la función BRF+:
   - IMG > EWM > PPF > Define Conditions
   - Tipo de condición: `BRF+`
   - Parametrizar el ID de la función BRF+

3. **Configurar perfil de acción PPF**:
   - Seleccionar la acción (ej. `AUTO_PRINT`)
   - Asignar la condición BRF+ creada
   - Definir timing (immediate/background)

4. **Asignar perfil de acción al documento**:
   - Para entregas: en el tipo de documento de entrega EWM
   - Para WTs: en el tipo de proceso de almacén (WPT)
   - Para HUs: en el tipo de HU

5. **Simular/probar**:
   - En `BRF+` > Test Function: probar con valores de entrada reales
   - En el documento EWM: verificar que la acción se ejecuta correctamente

## Tablas Relevantes

| Tabla | Contenido |
|-------|-----------|
| `PPFTTRIGG` | Triggers PPF por tipo de documento |
| `PPFTCOND` | Condiciones PPF definidas |
| `PPFTACTION` | Acciones PPF disponibles |
| `FDT_FUNCTION` | Funciones BRF+ (metadata) |
| `FDT_RULE` | Reglas definidas en BRF+ |
| `/SCWM/T_PPF_ACTP` | Perfiles de acción PPF para documentos EWM |

## Consultas via MCP (SAP ADT Tools)

```
-- Ver clases de integración PPF-EWM
SearchObject: type=CLAS, name=/SCWM/CL_PPF*

-- Buscar clase de condición BRF+ en EWM
SearchObject: type=CLAS, name=/SCWM/CL_BRF*

-- Ver enhancement spots PPF en EWM
SearchObject: type=ENHS, name=/SCWM/ES_PPF*

-- Buscar funciones de grupo PPF
SearchObject: type=FUGR, name=/SCWM/PPF*

-- Ver clase base para stock removal BRF+
GetClass: class_name=/SCWM/CL_SRULE_BRF

-- Buscar BAdI de condiciones PPF
SearchObject: type=ENHO, name=*PPF_COND*

-- Listar funciones BRF+ de EWM (via ABAP)
SearchObject: type=CLAS, name=/SCWM/CL_WAVE_TEMPL_BRF
```

### Clases y BAdIs Clave

- `/SCWM/CL_PPF_ACTION_HANDLER`: Manejador genérico de acciones PPF en EWM
- `/SCWM/CL_PPF_COND_BRF`: Evaluador de condiciones PPF via BRF+
- `/SCWM/CL_SRULE_BRF`: Base para stock removal strategy via BRF+
- `/SCWM/CL_PUT_STRAT_BRF`: Base para putaway strategy via BRF+
- BAdI `/SCWM/EX_PPF_ACTION`: Extension de acciones PPF personalizadas
- BAdI `/SCWM/EX_PPF_CONDITION`: Extension de condiciones PPF personalizadas

## Transacciones Relevantes

| Transacción | Función |
|-------------|---------|
| `BRF+` o `BRFPLUS` | Workbench principal de BRF+ (crear/editar funciones y decision tables) |
| `/SCWM/PPFCOND` | Configuración de condiciones PPF en EWM |
| `/SCWM/PPFACT` | Configuración de acciones PPF en EWM |
| `SPPFCADM` | Administración general de PPF (transacción base SAP) |
| `SPPFP` | Procesar acciones PPF pendientes (background) |
| `FDT_EXPR` | Workbench de expresiones BRF+ |
| `FDT_RULE` | Workbench de reglas BRF+ |

## Mejores Prácticas

1. **Preferir BRF+ sobre ABAP** para condiciones de negocio: facilita el mantenimiento por usuarios funcionales y no requiere transporte de código cuando cambian las reglas (solo las tablas de decisión).

2. **Naming conventions** para elementos BRF+:
   - Application: `Z_EWM_<AREA>` (ej. `Z_EWM_PUTAWAY`)
   - Function: `Z_EWM_<PROCESO>_DETERM` (ej. `Z_EWM_WPT_DETERM`)
   - Decision Table: `Z_DT_<FUNCIÓN>` (ej. `Z_DT_WPT_DETERM`)

3. **Versionado de decision tables**: BRF+ soporta versiones activas/inactivas. Siempre crear una nueva versión antes de modificar una tabla productiva.

4. **Testing**: usar la función "Test" en BRF+ con valores reales antes de activar en productivo. Documentar los casos de prueba en los comentarios de la versión.

5. **PPF asíncrono para acciones pesadas**: impresión, IDocs, llamadas externas deben configurarse como background para no bloquear transacciones interactivas.

6. **Monitor de errores PPF**: revisar `/SCWM/PPFLOG` o `SPPFP` para detectar acciones PPF que fallaron en background y requieren reprocesamiento.
