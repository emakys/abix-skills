# Outbound Processing (Proceso de Salida de Mercancias)

## Flujo Completo de Salida en EWM

```
Pedido de Ventas (Sales Order) / Orden de Transferencia
    ↓
Entrega de Salida (Outbound Delivery) → Creada en SD/MM
    ↓
Distribucion a EWM (automatica en Embebido)
    ↓
Creacion de Wave (agrupacion de entregas)
    ↓
Liberacion de Wave → Generacion de Warehouse Tasks (WT) de Picking
    ↓
Picking (recogida en ubicaciones)
    ↓
Packing / Embalaje (consolidacion en HUs)
    ↓
Staging / Zona de Expedicion (consolidacion por muelle)
    ↓
Loading / Carga en vehiculo
    ↓
Contabilizacion PGI (Post Goods Issue) → actualiza stock MM
    ↓
Facturacion (SD)
```

## 1. Pedido de Ventas y Documento Origen

### Origenes de Entrega de Salida
- Pedido de ventas SD (VA01/VA02) → tipo de entrega LF.
- Orden de traslado MM (MIGO, movimiento 641) → traslados entre plantas.
- Devolucion a proveedor → entrega tipo LR.
- Orden de produccion PP → suministro de componentes.
- Orden de proyecto PS → salida de materiales.

### Datos Clave en el Pedido
- Planta y almacen de expedicion → determina el Warehouse Number EWM.
- Fecha de entrega deseada → EWM planifica wave y recursos.
- Ruta de transporte → puede influir en consolidacion de entregas en wave.
- Condicion de expedicion (Incoterms) → impacta en punto de transferencia de riesgo.

## 2. Entrega de Salida (Outbound Delivery)

### Creacion
- Manual: `VL01N` (con referencia a pedido de ventas).
- Automatica: run de creacion de entregas `VL10` / `VL10A` (por fecha de entrega).
- En S/4HANA Fiori: "Create Outbound Delivery" (F0841).

### Tablas de Entrega de Salida
| Tabla | Descripcion |
|---|---|
| `LIKP` | Cabecera de entrega (numero, cliente, fecha de entrega) |
| `LIPS` | Posiciones de entrega (material, cantidad, planta/almacen) |
| `/SCWM/PDITEM` | Extension EWM de la posicion |
| `/SCWM/PRDO` | Documento de entrega salida en EWM (cabecera) |
| `/SCWM/PRDO_ITEM` | Posiciones del documento de entrega salida EWM |

### Estados de Entrega Salida
- Estado de picking (`KOSTK`): A (no iniciado), B (parcialmente), C (completo).
- Estado PGI (`WBSTK`): A (no contabilizado), C (GI contabilizado).
- Estado de actividad almacen (`WBSTA`): A/B/C.

## 3. Distribucion a EWM

### EWM Embebido (S/4HANA 2023)
- Automatica al guardar la entrega de salida en SD.
- EWM recibe la entrega como documento `/SCWM/PRDO`.
- El documento EWM muestra la entrega en estado "abierta" hasta que se inicia el picking.

## 4. Wave Management (Gestion de Oleadas)

### Concepto de Wave
- Agrupacion logica de entregas de salida para procesamiento conjunto.
- Objetivo: optimizar rutas de picking, balancear carga, respetar ventanas de tiempo de envio.
- Tipos de wave: manual, automatica (por regla de wave), con liberacion programada.

### Creacion y Configuracion de Wave
- Transaccion: `/SCWM/WAVE` (gestion de waves).
- Reglas de wave (`/SCWM/WVRUL`): criteros de agrupacion (ruta, fecha, zona de almacen, carrier).
- Una wave puede contener N entregas; una entrega pertenece a una sola wave.
- Campos clave de wave: `WAVEID`, `WSTAT` (estado), `WVTYP` (tipo), `WVDAT` (fecha planificada).

### Liberacion de Wave (Wave Release)
- Al liberar la wave: EWM genera automaticamente las Warehouse Tasks de picking.
- Determinacion de ubicacion fuente: aplica estrategia de stock removal (FIFO, FEFO, etc.).
- Asignacion de tareas a operarios/equipos segun Activity Area y Work Center.
- Posible activacion de reposicion (replenishment) si stock en zona pick es insuficiente.

## 5. Picking

### Tipos de Picking
| Tipo | Descripcion |
|---|---|
| Picking individual (discrete) | 1 operario, 1 entrega, recorre el almacen |
| Picking por oleada (wave picking) | N entregas agrupadas, un pase por el almacen |
| Cluster picking | 1 operario recoge para N entregas simultaneamente |
| Batch picking | Picking total por material → luego clasificacion |
| Pick-by-Voice | Instrucciones por voz (headset) |
| Pick-by-Light | Senalizacion luminosa en ubicaciones |
| Pick-by-Robot | Automatizacion (AS/RS, AMR) via MFS |

### Warehouse Task de Picking
| Campo | Descripcion |
|---|---|
| `TANUM` | Numero de WT |
| `BWLVS` | Tipo de movimiento (picking = tipo especifico config) |
| `VLTYP/VLPLA` | Storage Type/Bin fuente (donde esta el stock) |
| `NLTYP/NLPLA` | Storage Type/Bin destino (zona de consolidacion) |
| `MATNR/CHARG` | Material y lote a recoger |
| `QUAN/MEINS` | Cantidad y unidad de medida |
| `VLENR` | HU fuente (si aplica) |
| `NLENR` | HU destino (HU de picking) |

Tabla de WTs abiertas: `/SCWM/ORDIM_O`. Confirmadas: `/SCWM/ORDIM_C`.

### Confirmacion de Picking
- Via RF scanner: operario escanea ubicacion + material + cantidad + HU destino.
- Diferencias de picking: cantidad real != cantidad requerida → pick denial o pick short.
- Transaccion: `/SCWM/ACTCONF` (confirmacion masiva de WTs).

## 6. Pick Denial y Short Picking

### Pick Denial (Rechazo de Tarea)
- Operario no puede completar la tarea (ubicacion vacia, producto danado).
- Accion: denegar tarea → el sistema busca ubicacion alternativa o genera excepcion.
- Tipos de excepcion (`/SCWM/EXCTYP`): configurables en customizing.

### Short Picking (Recogida Parcial)
- Se recoge menos de la cantidad requerida.
- EWM puede completar la entrega con lo disponible (entrega parcial) o bloquear PGI.
- Configuracion: `Partial Delivery` a nivel de entrega y posicion (campo `LFIMG` vs `LGMNG`).

## 7. Packing / Embalaje

### Proceso de Embalaje en EWM
- El material recogido se consolida en HUs de envio (cajas, palets).
- Puesto de trabajo de embalaje (`/SCWM/PACK`) o integrado en confirmacion de picking.
- Se asigna material de embalaje (packaging material) a la HU.
- Se generan etiquetas de HU (labels) con codigo de barras / QR.

### HU (Handling Unit) de Envio
- HU jerarquica: item → caja → palet.
- Datos registrados: peso real, volumen, contenido detallado por posicion.
- La HU queda asociada a la entrega de salida.
- Tabla: `HUALPHA` / `VEKP` (cabecera HU), `VEPO` (posiciones HU).

## 8. Staging (Zona de Expedicion)

- Una vez empaquetadas, las HUs se mueven a la zona de staging (Storage Type STAGE o GI).
- WT de staging: desde zona de picking/packing → zona de muelle asignado.
- Las HUs se consolidan por puerta/muelle y se preparan para carga.
- Transaccion: `/SCWM/MON` → pestana "Outbound" → estado "Staged".

## 9. Loading (Carga en Vehiculo)

- El camion llega al muelle asignado (Yard Management).
- WT de carga: desde zona de staging → unidad de transporte (TU).
- Confirmacion de carga: escaneo de HUs al cargar en el vehiculo.
- Tras carga completa: la entrega pasa a estado "Cargado" (`WBSTA = B` para carga).

## 10. Contabilizacion PGI (Post Goods Issue)

- Ultimo paso del proceso de salida.
- Contabiliza la salida de mercancia en MM (movimiento 601 para LF, 647 para traslado).
- Resultado: stock reducido en MM, documento material creado (`MATDOC`).
- En EWM Embebido: el PGI puede dispararse automaticamente desde EWM al confirmar la carga, o manualmente desde VL02N/Fiori.
- Tras PGI: SD crea factura (VF01/Billing due list).

## Backorder Processing (Gestion de Pedidos Pendientes)

### Concepto
- Entregas que no pudieron ser completamente surtidas por falta de stock.
- EWM genera excepcion o bloquea la entrega parcial.
- El planificador revisa backorders y decide: esperar reposicion, surtir parcialmente, cancelar.

### Transacciones
- `/SCWM/BACKORDER`: monitor de backorders en EWM.
- Fiori: "Manage Backorders" (S/4HANA 2023).

## Entregas Parciales (Partial Delivery)

- Configuracion a nivel de posicion de pedido: indicador de entrega parcial (`ANTLF`).
- Si se permite entrega parcial: EWM puede confirmar PGI con cantidad inferior a la pedida.
- La entrega queda abierta para el remanente → puede darse en una segunda entrega.

## Transacciones Clave — Outbound

| Transaccion | Descripcion |
|---|---|
| `/SCWM/PRDO` | Monitor de Entregas de Salida EWM |
| `/SCWM/WAVE` | Gestion de Waves (creacion, liberacion, monitor) |
| `/SCWM/WHTSK` | Gestion de Warehouse Tasks |
| `/SCWM/ACTCONF` | Confirmacion masiva de WTs |
| `/SCWM/PACK` | Puesto de trabajo de embalaje |
| `/SCWM/MON` | Monitor general (vista Outbound) |
| `VL01N` | Crear entrega de salida |
| `VL02N` | Modificar entrega salida / contabilizar PGI |
| `VL10A` | Run de creacion masiva de entregas |
| `VF01` | Crear factura (SD) |
| `VF04` | Lista de facturacion pendiente |

## Consultas MCP Recomendadas

```
// Ver entregas de salida EWM abiertas
tool: ReadTable
params: {
  table_name: "/SCWM/PRDO",
  fields: ["LGNUM","QDNR","VSTEL","KUNNR","WADAT","ROUTE","STAT_GEN","WBSTA"],
  where: "LGNUM = '0001' AND STAT_GEN <> 'C'",
  max_rows: 100
}

// Ver posiciones de entregas de salida
tool: ReadTable
params: {
  table_name: "/SCWM/PRDO_ITEM",
  fields: ["LGNUM","QDNR","POSNR","MATNR","VSOLM","VSOLA","MEINS","CHARG","WSTAT"],
  where: "LGNUM = '0001' AND QDNR = '<delivery_number>'",
  max_rows: 50
}

// Ver Warehouse Tasks de picking abiertas
tool: ReadTable
params: {
  table_name: "/SCWM/ORDIM_O",
  fields: ["LGNUM","TANUM","TOPOS","BWLVS","VLTYP","VLPLA","NLTYP","NLPLA","MATNR","QUAN","MEINS","NLENR"],
  where: "LGNUM = '0001'",
  max_rows: 200
}

// Ver waves activas
tool: ReadTable
params: {
  table_name: "/SCWM/WAVE",
  fields: ["LGNUM","WAVEID","WVTYP","WSTAT","WVDAT","WVTIM","ANZKO"],
  where: "LGNUM = '0001' AND WSTAT <> 'C'",
  max_rows: 50
}

// Ver historial de WTs de salida confirmadas
tool: ReadTable
params: {
  table_name: "/SCWM/ORDIM_C",
  fields: ["LGNUM","TANUM","TOPOS","BWLVS","VLTYP","VLPLA","MATNR","QUAN","MEINS","UNAME","BIDOC","TDATE"],
  where: "LGNUM = '0001' AND BIDOC = '<delivery_number>'",
  max_rows: 100
}
```

## Notas S/4HANA 2023 — EWM Embebido

- La app Fiori "Outbound Delivery Monitor" (F2688) reemplaza a `/SCWM/PRDO` para usuarios de negocio.
- Wave Management tiene app Fiori dedicada "Manage Waves" disponible desde S/4HANA 2022.
- En S/4HANA 2023, la integracion con TM (Transportation Management) permite asignar transportistas y rutas directamente en la wave.
- El picking robotizado (via AMRs — Autonomous Mobile Robots) se integra a traves de la interfaz EWM-MFS (Material Flow System) o via API REST de EWM (disponible en S/4HANA 2023 Public Cloud).
- Para escenarios de Omnichannel (e-commerce + tienda fisica): EWM soporta ATP (Available-to-Promise) granular por ubicacion de almacen.
- La confirmacion de carga (Loading Confirmation) puede integrarse con TM para actualizar el estado del envio en tiempo real al transportista.
- PGI automatico configurable en customizing EWM: se dispara al confirmar la ultima WT de carga sin intervencion manual.
