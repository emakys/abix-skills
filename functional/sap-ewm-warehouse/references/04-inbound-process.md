# Inbound Processing (Proceso de Entrada de Mercancias)

## Flujo Completo de Entrada en EWM

```
Pedido de Compra (PO)
    ↓
Aviso de Entrega (ASN) [opcional]
    ↓
Entrega de Entrada (Inbound Delivery) → Creada en MM/SD
    ↓
Distribucion a EWM (automatica en Embebido)
    ↓
Descarga / Unloading (muelle → zona GR)
    ↓
Deconsolidacion (apertura de palets/cajas)
    ↓
Inspeccion de Calidad [si aplica]
    ↓
Creacion de Warehouse Task (WT) de Putaway
    ↓
Confirmacion de WT (ubicacion definitiva)
    ↓
Contabilizacion GR (Good Receipt) → actualiza stock MM
```

## 1. Pedido de Compra (Purchase Order)

- Creado en MM (ME21N) o en S/4HANA via Fiori "Create Purchase Order".
- Define: proveedor, material, cantidad, planta, almacen de destino.
- El campo "Almacen" en la posicion del PO determina el Warehouse Number EWM al que se distribuira la entrega.
- Tipos de PO relevantes: estandar (NB), subcontratacion (30), consignacion (K), stock especial.

## 2. Aviso de Entrega / ASN (Advanced Shipping Notification)

- Comunicacion del proveedor sobre envio inminente.
- En S/4HANA: creado via EDI (mensaje 856 ANSI X12 / DESADV EDIFACT) o manualmente.
- Genera la Entrega de Entrada (Inbound Delivery) con referencia al PO.
- Permite a EWM preparar recursos (muelle, zona GR) con antelacion.
- Tabla: `LIKP` (cabecera entrega) con indicador de tipo de entrega EL (Inbound).

## 3. Entrega de Entrada (Inbound Delivery)

### Creacion
- Automatica desde ASN via EDI.
- Manual: transaccion `VL31N` (crear entrega entrada con referencia a PO).
- En S/4HANA Fiori: "Create Inbound Delivery" (F0842).

### Tablas de Entrega
| Tabla | Descripcion |
|---|---|
| `LIKP` | Cabecera de entrega (numero, proveedor, fecha) |
| `LIPS` | Posiciones de entrega (material, cantidad, planta) |
| `/SCWM/PDITEM` | Extension EWM de posicion de entrega |
| `/SCWM/PACKING` | Datos de embalaje (HUs planificadas) |

### Estados de Entrega Relevantes
- Estado de actividad de almacen (`WBSTA`): A (no procesado), B (parcialmente procesado), C (completamente procesado).
- Estado de contabilizacion (`WBSTK`): A (no contabilizado), C (GR contabilizado).

## 4. Distribucion a EWM

### EWM Embebido (S/4HANA 2023)
- La distribucion es automatica al guardar/crear la entrega de entrada en MM/SD.
- No hay RFC; la entrega es directamente visible en EWM como `Expected Goods Receipt` (EGR).
- La entrega crea un documento EWM interno (`/SCWM/PRDI` — Inbound Delivery EWM).

### Tabla EWM de Entrega de Entrada
- **`/SCWM/PRDI`**: Documento de entrega de entrada en EWM (cabecera).
- **`/SCWM/PRDI_ITEM`**: Posiciones del documento de entrega EWM.
- **`/SCWM/PRDT`**: Textos de documentos de entrega.

## 5. Descarga / Unloading

### Proceso en EWM
- El camion llega al muelle (Door).
- En EWM: asignar muelle (`/SCWM/VLBL` — Yard Management) o directamente en monitor.
- Crear Warehouse Task de "Unloading": mueve HUs desde muelle a zona GR (Storage Type RECV o GR).
- Confirmacion del WT de unloading → HUs fisicamente en zona de recepcion.

### Transacciones
| Transaccion | Descripcion |
|---|---|
| `/SCWM/PRDI` | Monitor de Entregas de Entrada EWM |
| `/SCWM/MON` | Monitor general → pestana "Inbound Deliveries" |
| `/SCWM/WHTSK` | Gestion de Warehouse Tasks |

## 6. Deconsolidacion (Deconsolidation)

- Apertura de palets / cajas para verificar contenido (comparar con ASN).
- En EWM: proceso de "Deconsolidation" en puesto de trabajo dedicado.
- Si hay diferencias respecto al ASN: ajuste de cantidades en la entrega EWM.
- Resultado: HUs individuales identificadas y etiquetadas para putaway.
- Transaccion: `/SCWM/CONS` (Consolidation/Deconsolidation workstation).

## 7. Inspeccion de Calidad (Quality Inspection)

### Integracion EWM-QM
- Si el material tiene QM activo: al confirmar GR se crea Orden de Inspeccion (tipo `01` para GR de PO).
- Stock pasa a estado "En inspeccion" (`CAT = Q` en `/SCWM/QUANT`).
- El material no puede salir del almacen hasta liberacion del lote por QM.

### Flujo
1. GR contabilizado → Orden de inspeccion QM creada automaticamente.
2. Inspector registra resultados en QM (QA32 / Fiori "Record Inspection Results").
3. Decision de uso: liberado (unrestricted), bloqueado, devuelto a proveedor.
4. EWM actualiza categoria de stock del quant automaticamente.

### Inspeccion en el Almacen con EWM
- EWM puede generar WT hacia puesto de trabajo de QI antes de putaway definitivo.
- Configurado en "Quality Inspection Workstation" en customizing EWM.

## 8. Creacion de Warehouse Task (WT) de Putaway

### Generacion de WT
- Automatica (tras confirmacion de deconsolidacion) o manual desde monitor.
- El sistema determina ubicacion destino segun estrategia de putaway configurada.
- Resultado: WT con fuente (zona GR) y destino (ubicacion de rack o almacen activo).

### Datos de la Warehouse Task
| Campo | Descripcion |
|---|---|
| `TANUM` | Numero de Warehouse Task |
| `TOPOS` | Posicion de la tarea |
| `LGNUM` | Warehouse Number |
| `BWLVS` | Tipo de movimiento EWM |
| `NLTYP/NLPLA` | Storage Type/Bin de destino |
| `VLENR` | HU a mover |
| `NTANF/NTENZ` | Fecha/hora de inicio/fin planificada |

Tabla: `/SCWM/ORDIM_C` (tareas confirmadas) / `/SCWM/ORDIM_O` (tareas abiertas).

## 9. Confirmacion de WT

- El operario de almacen confirma la tarea via RF (escaner), Fiori app o transaccion.
- Confirmacion registra: ubicacion real de destino (si difiere de propuesta), cantidad real, HU.
- Tras confirmacion: el quant se registra en la ubicacion destino (`/SCWM/QUANT`).
- Transacciones: `/SCWM/ACTCONF` (confirmacion masiva), RF Menu.

## 10. Contabilizacion de GR (Goods Receipt Posting)

- Una vez confirmadas todas las WTs de una entrega: GR disponible para contabilizar.
- En EWM Embebido: la contabilizacion GR (movimiento 101 en MM) se dispara desde EWM o desde la entrega en VL31N.
- Resultado: stock ingresa en MM como "libre utilizacion" (unrestricted), se actualiza valoracion.
- Numero de material document creado (tabla `MSEG` / `MATDOC` en S/4HANA).

## Recepciones No Planificadas (Unplanned GR)

- Mercancias que llegan sin PO ni ASN previo.
- Transaccion: `/SCWM/GR` — crear GR ad-hoc directamente en EWM.
- EWM crea entrega de entrada "anonima" y solicita datos del material al operario.
- Tambien posible via Fiori "Post Goods Receipt without Reference".

## Procesamiento de Devoluciones (Returns)

### Devolucion a Proveedor (Return to Vendor)
- Orden de devolucion en MM (ME21N con tipo RE) o desde PO original.
- Entrega de salida generada (tipo LR — Returns Delivery).
- EWM gestiona el picking de los articulos a devolver y crea WT de salida.
- Confirmacion GI (movimiento 122) actualiza stock.

### Devoluciones de Cliente (Customer Returns)
- Entrega de entrada de devolucion (tipo LR en SD).
- EWM recibe la devolucion: inspeccion de calidad, decision (restocking, scrap, devolucion).
- Si restocking: WT de putaway a ubicacion correspondiente.

## Transacciones Clave — Inbound

| Transaccion | Descripcion |
|---|---|
| `/SCWM/PRDI` | Monitor Inbound Deliveries EWM |
| `/SCWM/MON` | Monitor general de almacen |
| `/SCWM/TO01` | Crear Warehouse Task manualmente |
| `/SCWM/ACTCONF` | Confirmacion masiva de WTs |
| `/SCWM/CONS` | Puesto de trabajo Deconsolidacion |
| `/SCWM/GR` | GR no planificado |
| `VL31N` | Crear entrega entrada (MM/SD) |
| `VL32N` | Modificar entrega entrada |
| `MIGO` | Contabilizar GR manualmente |
| `MB51` | Listado de documentos de material |

## Consultas MCP Recomendadas

```
// Ver entregas de entrada EWM abiertas
tool: ReadTable
params: {
  table_name: "/SCWM/PRDI",
  fields: ["LGNUM","QDNR","VSTEL","VKORG","WADAT","STAT_GEN"],
  where: "LGNUM = '0001' AND STAT_GEN <> 'C'",
  max_rows: 100
}

// Ver posiciones de entregas de entrada
tool: ReadTable
params: {
  table_name: "/SCWM/PRDI_ITEM",
  fields: ["LGNUM","QDNR","POSNR","MATNR","VSOLM","VSOLA","MEINS","WSTAT"],
  where: "LGNUM = '0001' AND QDNR = '<delivery_number>'",
  max_rows: 50
}

// Ver Warehouse Tasks de entrada abiertas
tool: ReadTable
params: {
  table_name: "/SCWM/ORDIM_O",
  fields: ["LGNUM","TANUM","TOPOS","BWLVS","VLTYP","VLPLA","NLTYP","NLPLA","VLENR","MATNR"],
  where: "LGNUM = '0001' AND BWLVS = '0001'",
  max_rows: 100
}

// Ver Warehouse Tasks confirmadas (historial)
tool: ReadTable
params: {
  table_name: "/SCWM/ORDIM_C",
  fields: ["LGNUM","TANUM","TOPOS","BWLVS","NLTYP","NLPLA","MATNR","QUAN","MEINS","UNAME","BIDOC"],
  where: "LGNUM = '0001' AND BIDOC = '<delivery_number>'",
  max_rows: 100
}
```

## Notas S/4HANA 2023 — EWM Embebido

- En S/4HANA 2023, el proceso de GR esta integrado con el Business Partner (proveedor) y los POs de Sourcing.
- La app Fiori "Inbound Delivery Monitor" (F2689) reemplaza a `/SCWM/PRDI` para usuarios de negocio.
- Expected Goods Receipt (EGR): EWM puede mostrar entregas esperadas incluso antes de que lleguen al almacen, permitiendo preparacion de recursos.
- La integracion con Transportation Management (TM) en S/4HANA permite sincronizar paradas de camion con la gestion de muelles EWM (Yard Management).
- Para escenarios de Cross-Docking: EWM soporta cross-docking planificado (PO → SO directo sin putaway) y oportunista.
