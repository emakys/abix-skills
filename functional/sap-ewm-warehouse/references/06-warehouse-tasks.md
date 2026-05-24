# Warehouse Tasks (WT)

## Concepto

La Warehouse Task (WT) es la unidad de trabajo más pequeña en SAP EWM. Representa el movimiento físico de una cantidad de producto desde un bin de origen hasta un bin de destino dentro del almacén.

## Estructura de una WT

| Campo | Descripción |
|-------|-------------|
| Warehouse Number | Número de almacén (ej. ZW01) |
| WT Number | Número único de tarea (12 caracteres) |
| Bin de Origen | Ubicación desde donde se mueve el stock |
| Bin de Destino | Ubicación hacia donde se mueve el stock |
| Producto | Número de material |
| Cantidad Abierta | Cantidad pendiente de confirmar |
| Cantidad Confirmada | Cantidad ya procesada |
| Unidad de Medida | UoM de la tarea |
| Tipo de WT | Categoría de la tarea |
| Estado | Estado actual de la tarea |

## Estados de una WT

| Estado | Código | Descripción |
|--------|--------|-------------|
| Abierta | A | Creada, pendiente de procesamiento |
| En Proceso | B | Asignada a un recurso, en ejecución |
| Confirmada | C | Movimiento físico completado |
| Cancelada | D | Anulada antes de confirmación |

## Tipos de WT

- **Putaway (entrada):** Movimiento desde zona de recepción hacia bins de almacenamiento.
- **Picking (salida):** Extracción de producto desde bins de almacenamiento hacia zona de staging de salida.
- **Reabastecimiento:** Movimiento desde bins de reserva hacia bins de picking activo.
- **Interna:** Movimientos internos (traslados, reorganización, inventario).
- **Retiro de producción:** Suministro de materiales a órdenes de producción.
- **Regreso a almacén:** Retorno de material no usado desde producción.

## Tabla principal: /SCWM/ORDIM_O

Tabla de WTs abiertas (activas) en EWM.

```
Campos clave:
- LGNUM   : Número de almacén
- TANUM   : Número de WT
- TAPOS   : Posición de la WT
- MATNR   : Número de material
- VLTYP   : Tipo de storage type de origen
- VLPLA   : Bin de origen
- NLTYP   : Tipo de storage type de destino
- NLPLA   : Bin de destino
- VSOLA   : Cantidad solicitada
- ANFME   : Cantidad confirmada
- MEINS   : Unidad de medida
- TASTA   : Estado de la WT
- PROCTY  : Tipo de proceso (tipo de WT)
- LGPLA   : Bin actual (si está en movimiento)
```

Tabla de WTs confirmadas: `/SCWM/ORDIM_C`

## Creación de WTs

### Automática
- Al confirmar una inbound delivery (putaway automático).
- Al crear una warehouse order desde una outbound delivery.
- Por reglas de reabastecimiento (demand-based o level-based).
- Por liberación de oleadas (wave release).
- Por órdenes de producción integradas con EWM.

### Manual
- Transacción `/SCWM/WTCR` — Creación manual de WT.
- Útil para traslados internos, correcciones de stock, preparación de inventario.
- Se especifican: almacén, bin origen, bin destino, material, cantidad.

## Confirmación de WTs

### RF (Radio Frequency)
- El operario escanea bins y productos con terminal RF.
- Transacción `/SCWM/RF` (monitor de tareas RF).
- Confirmación paso a paso: origen → picking → destino.
- Soporta confirmación parcial y diferencias.

### Fiori
- App "Confirm Warehouse Tasks" (F3851).
- App "Manage Warehouse Tasks" (F3850).
- Escaneo con cámara o lector Bluetooth.
- Interfaz optimizada para dispositivos móviles.

### GUI / SAP EWM Cockpit
- Transacción `/SCWM/ADHU` — Monitor de unidades de manejo.
- Transacción `/SCWM/MON` — Monitor de almacén (sección WTs).
- Selección masiva y confirmación en batch.

## Confirmación Parcial

- Se puede confirmar una cantidad menor a la solicitada.
- EWM crea una WT residual con la cantidad pendiente.
- Útil cuando el bin de origen tiene menos stock del esperado.
- La diferencia puede disparar un proceso de excepción configurable.

## Cancelación de WTs

- Solo posible si la WT está en estado "Abierta" o "En Proceso" (según config).
- Transacción `/SCWM/WTCA` o desde el monitor `/SCWM/MON`.
- Si ya hay stock en el bin intermedio, se genera una WT de retorno automática.
- Cancelación masiva disponible para operaciones de mantenimiento.

## Consultas MCP relevantes

```
// Leer WTs abiertas para un bin de origen específico
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND VLPLA = 'BIN-001'

// Leer WTs de una outbound delivery
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND RDOCCAT = 'OBD' AND RDOCNO = '0080012345'

// WTs confirmadas hoy por usuario
ReadTable: /SCWM/ORDIM_C WHERE LGNUM = 'ZW01' AND PROCDATE = SY-DATUM AND PROCBY = 'RFUSER01'

// Estado de WTs de una wave específica
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND WAVEKEY = '000000001'
```

## Flujo típico de una WT de picking

```
Outbound Delivery
    └─► Wave Assignment
            └─► Wave Release
                    └─► WT Creation (ORDIM_O, estado A)
                            └─► WO Creation (agrupación de WTs)
                                    └─► Asignación a recurso (estado B)
                                            └─► Confirmación RF/Fiori (estado C → ORDIM_C)
                                                    └─► Stock en staging bin
```

## Notas de implementación S/4HANA 2023

- Las WTs se crean en memoria (buffer) antes de persistirse; usar función `/SCWM/TO_COMPL` para forzar commit.
- El campo `PROCTY` determina el tipo de proceso y controla la determinación de estrategia.
- Para ABAP custom: usar BAdI `/SCWM/EX_TO_PROCESS` para lógica adicional en creación/confirmación.
- En S/4HANA embedded EWM, la integración con MM se realiza automáticamente via posting change.
