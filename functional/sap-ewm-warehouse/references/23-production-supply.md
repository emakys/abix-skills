# Production Supply (PP Integration)

## Visión General

La integración entre SAP EWM y SAP PP (Production Planning) en S/4HANA 2023 permite gestionar el suministro de materiales a la línea de producción directamente desde el almacén. EWM recibe las demandas de producción, crea las tareas de almacén (WT) necesarias y controla el movimiento físico de materiales desde el stock hacia las áreas de staging o alimentación directa a producción.

Esta integración opera en el contexto de **Embedded EWM** (EWM dentro del sistema S/4HANA), donde PP y EWM comparten la misma base de datos pero tienen sus propios procesos y documentos.

## Production Supply Areas (PSA)

El **Production Supply Area (PSA)** es el concepto central de la integración EWM-PP. Define el punto físico o virtual donde los materiales son entregados a producción.

Características de un PSA:
- Representa una zona de staging intermedia o una alimentación directa
- Está vinculada a uno o más centros de trabajo de PP (work centers)
- Tiene asignada una estrategia de suministro (push, pull, pick-to-zero)
- Pertenece a un área de almacén (warehouse activity area)
- Define los bins de staging donde se deposita el material

Configuración: IMG > EWM > Interfaces > Extended Warehouse Management > Production Integration > Define Production Supply Areas

### Datos del PSA

| Campo | Descripción |
|-------|-------------|
| PSA ID | Identificador del área de suministro |
| Warehouse Number | Almacén EWM |
| Storage Type | Tipo de almacenamiento de staging (ej. STAG) |
| Section | Sección dentro del tipo de almacenamiento |
| Supply Strategy | PUSH / PULL / PICK_TO_ZERO |
| Staging Bin | Bin físico de entrega a producción |
| Linked Work Centers | Centros de trabajo de PP que consume este PSA |

## Estrategias de Staging

### PUSH (Suministro Anticipado)
- EWM envía material a staging **antes** de que PP lo solicite
- Basado en el plan de producción (planned orders) y el horario de producción
- El material queda disponible en el bin de staging para que producción lo tome
- Adecuado para materiales de alto consumo y producción estable

### PULL (Suministro Bajo Demanda)
- PP genera una **solicitud de material a producción** cuando la línea necesita el material
- EWM recibe la solicitud y crea la WT de picking/staging en ese momento
- Más flexible, menos inventario en staging, pero requiere tiempo de respuesta del almacén

### PICK-TO-ZERO (Suministro Completo del Lote)
- EWM suministra el contenido completo de un lote o unidad de manejo (HU)
- Se usa cuando la producción consume HUs completos (pallets, cajas maestras)
- Minimiza el splitting y el manejo de HUs parciales

## Demanda Ad-Hoc desde Órdenes de Producción

Cuando PP crea una **orden de producción** con necesidades de material, EWM recibe automáticamente una **producción material request (PMR)**:

1. PP libera orden de producción o planned order
2. El sistema genera un documento de demanda EWM (Production Order → PMR)
3. EWM determina el PSA y la estrategia de suministro
4. Se crea la WT de picking desde la ubicación de stock al bin de staging del PSA
5. El recurso RF confirma la entrega del material
6. PP recibe confirmación de disponibilidad en staging

La PMR contiene: material, cantidad, unidad de medida, fecha requerida, PSA destino, orden de producción de referencia.

## Integración con Kanban

SAP EWM soporta el esquema de suministro **Kanban** en integración con PP-Kanban:

- Cuando una tarjeta Kanban se activa (se escaneó el bin vacío), PP genera la señal Kanban
- EWM recibe la señal y crea una WT de reposición del bin Kanban
- El almacén repone el bin desde el supermercado o almacén central
- Al confirmar la WT, el sistema actualiza el estado de la tarjeta Kanban a "lleno"

Requiere configuración de: circuito Kanban en PP + PSA con estrategia PULL + bin Kanban mapeado.

## Flujo Completo: Production Material Request → WT

```
Orden PP (liberada)
        |
        v
PMR generada en EWM
        |
        v
Determinación PSA (según material + orden + planta)
        |
        v
Determinación estrategia (PUSH/PULL/PICK_TO_ZERO)
        |
        v
Búsqueda de stock (stock removal strategy del PSA)
        |
        v
WT creada (origen: bin stock → destino: bin staging PSA)
        |
        v
Asignación a cola de suministro a producción
        |
        v
Confirmación de WT por recurso RF
        |
        v
Material disponible en staging → PP consume
```

## Áreas de Staging

Los **bins de staging** son ubicaciones intermedias entre el almacén y la línea de producción. Características:

- Pertenecen a un storage type específico (ej. `/SCWM/ST STAG` con prefijo `STAG`)
- Pueden tener capacidad limitada (evitar saturación del staging)
- El material se mantiene en staging hasta ser retirado por producción o devuelto al almacén
- Se pueden monitorear en `/SCWM/MONS` o desde el Warehouse Monitor nodo Internal

## Devolución desde Producción

Cuando producción tiene material sobrante o rechazado, el flujo es inverso:

1. PP crea movimiento de devolución (reversal de consumo)
2. EWM recibe la devolución y crea WT de putaway
3. Origen: bin de staging o área de producción
4. Destino: ubicación en almacén según estrategia de putaway
5. Si el material fue dañado: se puede cambiar el stock type a "bloqueado" durante el movimiento

Transacción de devolución: `/SCWM/PROD_RETURN` o desde la entrega de devolución de producción.

## WIP Storage Type (Work-In-Process)

El tipo de almacenamiento WIP (`/SCWM/ST_WIP` o similar) representa el área bajo responsabilidad de producción:

- El stock en WIP ya no está bajo control del almacén
- Los movimientos dentro del WIP los gestiona PP
- EWM solo interviene para la entrada al WIP (staging) y la salida (devolución)
- El WIP storage type tiene la configuración `Managed by Production = X`

## Integración con PP/DS (Demand-Driven Supply)

En S/4HANA 2023 con Demand-Driven MRP activo:

- EWM recibe las demandas buffer de PP/DS como PMRs
- Las estrategias de suministro se adaptan a los buffers DDMRP
- La visibilidad de stock en staging influye en el cálculo de la posición neta del buffer
- Los alertas de buffer rojo generan urgencia en las WTs de suministro

## Control de Flujo de Material

El **material flow control (MFC)** permite sincronizar el suministro EWM con el ritmo de la línea de producción:

- Define la frecuencia de suministro por material/línea (cada X minutos o lotes)
- Agrupa demandas en ventanas de tiempo para optimizar los viajes del almacén
- Calcula la cantidad óptima de suministro basándose en el consumo histórico

Configuración: IMG > EWM > Production Integration > Material Flow Control

## Tablas Relevantes

| Tabla | Contenido |
|-------|-----------|
| `/SCWM/T_PSA` | Definición de Production Supply Areas |
| `/SCWM/T_PSA_MAT` | Asignación material-PSA |
| `/SCWM/T_PSA_WC` | Centros de trabajo asignados al PSA |
| `/SCWM/PRDO_PP` | Demandas de producción abiertas en EWM |
| `/SCWM/T_SUPPLY_STRAT` | Configuración de estrategias de suministro |
| `RESB` | Reservas PP (referenciadas en PMR) |
| `AUFK` | Órdenes de producción PP |

## Consultas via MCP (SAP ADT Tools)

```
-- Ver clase de integración PP-EWM
SearchObject: type=CLAS, name=/SCWM/CL_PP*

-- Buscar función de creación de PMR
SearchObject: type=FUGR, name=/SCWM/PROD*

-- Ver BAdIs de suministro a producción
SearchObject: type=ENHO, name=*PROD_SUPPLY*

-- Leer tabla de PSA
GetObjectSource: object_type=TABL, name=/SCWM/T_PSA

-- Buscar report de suministro a producción
SearchObject: type=PROG, name=/SCWM/R_PROD*
```

### Clases y BAdIs Clave

- `/SCWM/CL_PP_INTEGRATION`: Clase principal de integración PP-EWM
- `/SCWM/CL_PSA_DETERMINATION`: Determina el PSA para una demanda de producción
- BAdI `/SCWM/EX_PP_PROD_SUPPLY`: Extension del proceso de suministro a producción
- BAdI `/SCWM/EX_PSA_DETERMINATION`: Determinación alternativa de PSA
- BAdI `/SCWM/EX_KANBAN_TRIGGER`: Lógica personalizada al recibir señal Kanban

## Transacciones Relevantes

| Transacción | Función |
|-------------|---------|
| `/SCWM/PROD_SUPPLY` | Gestión de demandas de suministro a producción |
| `/SCWM/PROD_RETURN` | Devolución de material desde producción |
| `/SCWM/PSA` | Mantenimiento de Production Supply Areas |
| `/SCWM/MONPROD` | Monitor de suministro a producción |
| `MD04` | Lista de necesidades/stock PP (referencia) |
| `CO01` / `CO02` | Creación / modificación de órdenes PP |

## Configuración Paso a Paso

1. **Activar integración PP-EWM**: IMG > EWM > Interfaces > Production Integration > Activate Integration
2. **Crear tipos de almacenamiento staging y WIP**: con los indicadores correspondientes
3. **Definir PSA**: asignar almacén, tipo de almacenamiento, bins, estrategia
4. **Asignar centros de trabajo a PSA**: mapping PP work center → PSA
5. **Configurar estrategia de suministro**: PUSH/PULL/PICK_TO_ZERO por PSA o material
6. **Asignar materiales a PSA** (opcional): si la determinación no es automática
7. **Activar Kanban** (si aplica): configurar circuito en PP + vincular bin Kanban al PSA
8. **Crear colas de suministro a producción**: para los recursos que atienden la línea
9. **Probar con orden de producción**: verificar creación de PMR → WT → confirmación
