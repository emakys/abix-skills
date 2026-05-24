# Stock Management (Quants)

## El Concepto de Quant

En SAP EWM S/4HANA 2023, el **quant** es la unidad fundamental de gestión de stock. Un quant representa una cantidad disponible de un producto en una ubicación (bin) específica, con un conjunto de atributos que lo hacen único en esa posición.

Un quant se identifica de forma unívoca por la combinación de:
- **Almacén** (warehouse number)
- **Bin** (ubicación física)
- **Producto** (material)
- **Lote** (batch, si el material es gestionado por lote)
- **Tipo de stock** (stock type: disponible, bloqueado, QI, etc.)
- **Categoría de stock** (stock category: devoluciones, etc.)
- **Propietario** (en escenarios de stock externo o VMI)
- **Derecho** (entitlement, en escenarios de terceros)

La tabla principal es `/SCWM/AQUA` — **Available Quantity per Bin** (cantidad disponible por ubicación).

### Relación Quant-Bin-Producto

```
Bin A-01-001
  └── Quant 1: Producto MAT_A, Lote L001, Stock Type: F (Disponible), Qty: 50 EA
  └── Quant 2: Producto MAT_A, Lote L002, Stock Type: F (Disponible), Qty: 30 EA
  └── Quant 3: Producto MAT_A, Lote L001, Stock Type: B (Bloqueado),  Qty: 10 EA

Bin A-01-002
  └── Quant 4: Producto MAT_B, Stock Type: Q (QI Inspection), Qty: 100 EA
```

Cada fila en `/SCWM/AQUA` es un quant independiente. La cantidad en el quant es la cantidad **disponible** para movimientos en EWM, que puede diferir del stock MM cuando hay movimientos en curso.

## Tipos de Stock

| Tipo de Stock | Código | Descripción |
|---------------|--------|-------------|
| Disponible (Unrestricted) | `F` | Libre para picking, consumo, venta |
| Inspección de Calidad | `Q` | En revisión QM; no disponible para picking hasta aprobación |
| Bloqueado | `B` | Retenido manualmente o por sistema; no disponible |
| Devolución de Cliente | `R` | Stock recibido como devolución; puede requerir revisión |
| En Tránsito | `T` | En movimiento entre almacenes (stock in transit) |
| Consignación | `K` | Stock propiedad del proveedor (vendor-owned) |
| Proyecto | `P` | Reservado para un proyecto específico |

Los tipos de stock se configuran en: IMG > EWM > Cross-Process Settings > Stock > Define Stock Types

## Categorías de Stock

Las **categorías de stock** (stock categories) ofrecen una capa adicional de clasificación que se combina con el tipo de stock:

- `A`: Stock normal (sin categoría especial)
- `S`: Stock de seguridad
- `E`: Stock específico de cliente (make-to-order)
- `W`: Stock de devolución en proceso de revisión

La combinación `Tipo + Categoría` determina la disponibilidad real del stock para distintos procesos.

## Cambios de Tipo de Stock (Posting Changes)

Un **posting change** es una operación que cambia el tipo de stock de un quant sin mover físicamente el material. Se ejecuta como una tarea de almacén de tipo "posting change" (movimiento interno especial).

Casos de uso:
- Liberar stock de QI a disponible (tras aprobación del lote en QM)
- Bloquear stock disponible (ante sospecha de defecto)
- Cambiar devolución a disponible (tras inspección y aprobación)
- Devolver stock bloqueado a disponible (tras resolución de incidencia)

Transacción: `/SCWM/PCOG` — Posting Change Order (Orden de Cambio de Tipo de Stock)

El flujo:
1. Crear posting change order indicando: almacén, bin/quant origen, nuevo tipo de stock, cantidad
2. EWM crea WT de tipo posting change
3. El recurso confirma la WT (o se confirma automáticamente si está configurado así)
4. El quant se actualiza con el nuevo tipo de stock
5. MM-IM recibe la actualización vía MATDOC (en Embedded EWM)

## Movimientos Ad-Hoc

Los **movimientos ad-hoc** permiten mover stock entre bins sin una entrega o WT de proceso formal:

Transacción: `/SCWM/ADHU` (para HUs) o `/SCWM/ADHOC` (para quants)

Se crean directamente indicando:
- Producto, lote, cantidad
- Bin origen
- Bin destino
- Motivo del movimiento (movement reason)

Los movimientos ad-hoc generan WTs que deben ser confirmadas. Son auditables y se reflejan en los logs de movimiento (`/SCWM/ORDIM_C`).

## Transferencias de Stock Dentro del Almacén

Las **transferencias internas** mueven stock de un bin a otro sin cambiar el tipo de stock ni el propietario:

- **Redistribución manual**: supervisor mueve stock a otro bin (optimización de ocupación)
- **Reposición desde reserva a picking**: bins de picking se reabastecen desde bins de bulk
- **Consolidación de pallets**: juntar quants parciales en un bin para liberar ubicaciones

Estas transferencias se pueden iniciar desde `/SCWM/MONA` (monitor de tareas) seleccionando el quant y eligiendo "Create WT" con un nuevo bin destino.

## Vista de Stock por Bin y Producto

### Por Bin
Transacción: `/SCWM/LS24` — Muestra todos los quants de un bin con: producto, lote, tipo de stock, cantidad, HU asignada.

### Por Producto
Transacción: `/SCWM/LS26` — Lista todos los bins que contienen un producto: ubicación, cantidad, tipo de stock, lote.

### Vista Global de Stock
Transacción: `/SCWM/LS11` — Muestra stock agregado por producto en el almacén (sin detalle de bin).

### En Fiori
App: **Manage Warehouse Stock** — disponible en S/4HANA 2023, permite filtrar por almacén, producto, tipo de stock, lote.

## Desconsolidación (Deconsolidation)

La **desconsolidación** (deconsolidation) divide una HU (Handling Unit) o un quant en partes menores:

- Recepción de pallets mixtos que se separan por producto
- División de una caja en unidades individuales
- Separación de lotes dentro de una misma HU

Proceso: `/SCWM/DECON` — Se indica la HU origen y se distribuyen los productos/cantidades a nuevas HUs o bins.

## Consolidación (Consolidation)

La **consolidación** agrupa múltiples HUs o quants en uno solo:

- Juntar cajas parciales del mismo producto y lote en una caja o pallet completo
- Optimizar el uso del espacio en bins
- Preparar cargas de exportación consolidadas

Proceso: `/SCWM/CONS` o desde el Warehouse Monitor > nodo Internal > Consolidation tasks.

## Determinación de Stock Disponible

Cuando EWM necesita determinar qué stock tomar para una tarea de picking o transferencia, ejecuta la **stock removal strategy** configurada para el storage type:

1. Filtra quants con tipo de stock disponible (`F`) y categoría correcta
2. Aplica reglas FEFO/FIFO/LIFO según configuración del producto o storage type
3. Verifica que no haya bloqueos de inventario o retenciones activas
4. Considera la HU de la WT anterior si hay interleaving activo
5. Retorna el quant y la cantidad a tomar

La disponibilidad en EWM puede diferir temporalmente de MM-IM durante movimientos en curso (WT creada pero no confirmada).

## Tablas Relevantes

| Tabla | Contenido |
|-------|-----------|
| `/SCWM/AQUA` | Quants: stock disponible por bin/producto/lote/tipo |
| `/SCWM/LQUA` | Vista de quants con datos de ubicación (legado, aún presente) |
| `/SCWM/ORDIM_O` | WTs abiertas (stock en movimiento) |
| `/SCWM/ORDIM_C` | WTs confirmadas (historial de movimientos) |
| `/SCWM/T_STOCK_TYPE` | Tipos de stock configurados |
| `/SCWM/PCOG` | Posting change orders activas |
| `MATDOC` | Documentos de material MM (en S/4HANA — integración con AQUA) |
| `/SCWM/AQUA_ORD` | Cantidades reservadas por WTs activas |

## Consultas via MCP (SAP ADT Tools)

```
-- Ver estructura de la tabla de quants
GetObjectSource: object_type=TABL, name=/SCWM/AQUA

-- Buscar clase de gestión de stock
SearchObject: type=CLAS, name=/SCWM/CL_QUANT*

-- Buscar función de posting change
SearchObject: type=FUGR, name=/SCWM/POSTING*

-- Ver BAdI de determinación de stock disponible
SearchObject: type=ENHO, name=*STOCK_REMOVAL*

-- Buscar reports de stock EWM
SearchObject: type=PROG, name=/SCWM/R_STOCK*

-- Leer tabla de tipos de stock
GetObjectSource: object_type=TABL, name=/SCWM/T_STOCK_TYPE
```

### Clases y BAdIs Clave

- `/SCWM/CL_QUANT_MANAGER`: Clase principal de gestión de quants (crear, modificar, dividir)
- `/SCWM/CL_STOCK_REMOVAL`: Lógica de stock removal y determinación de disponibilidad
- `/SCWM/CL_POSTING_CHANGE`: Gestión de cambios de tipo de stock
- BAdI `/SCWM/EX_STOCK_REMOVAL_STRAT`: Extension de estrategia de extracción de stock
- BAdI `/SCWM/EX_QUANT_SPLIT`: Lógica personalizada al dividir quants
- BAdI `/SCWM/EX_STOCK_TYPE_CHANGE`: Validación personalizada de cambios de tipo de stock

## Escenarios Especiales

### Stock Negativo
EWM no permite stock negativo en bins. Si una WT generaría negatividad, se bloquea la confirmación y genera una excepción. El supervisor debe investigar la diferencia antes de continuar.

### Diferencias de Inventario
Al confirmar una WT con diferencia (cantidad real ≠ cantidad de la WT), EWM crea automáticamente un **inventory difference document** que puede desencadenar un recuento físico parcial o un ajuste directo según la configuración de tolerancias.

### Stock en Tránsito (SIT)
Cuando se transfiere stock entre dos almacenes EWM, el stock sale del almacén origen y queda en estado "en tránsito" hasta ser recibido en el almacén destino. El SIT es visible en `/SCWM/LS26` con tipo `T`.

## Transacciones Relevantes

| Transacción | Función |
|-------------|---------|
| `/SCWM/LS24` | Stock por bin (quants de una ubicación) |
| `/SCWM/LS26` | Stock por producto (todos los bins) |
| `/SCWM/LS11` | Vista global de stock del almacén |
| `/SCWM/PCOG` | Crear/gestionar posting change orders |
| `/SCWM/ADHOC` | Movimiento ad-hoc de quants |
| `/SCWM/ADHU` | Movimiento ad-hoc de HUs |
| `/SCWM/DECON` | Desconsolidación de HUs/quants |
| `/SCWM/CONS` | Consolidación de quants/HUs |
| `/SCWM/MONA` | Monitor de tareas (para movimientos manuales) |
