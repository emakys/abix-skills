# Productos EWM (Maestro de Materiales)

## Extension del Maestro de Materiales para EWM

En EWM Embebido (S/4HANA 2023), el maestro de materiales de MM (tabla MARA/MARM) se extiende con vistas y tablas adicionales especificas de EWM. El material en EWM se denomina "Product" y tiene su propia representacion interna.

### Tabla Principal de Extension EWM
- **`/SCWM/MARM`**: Extension de unidades de medida para EWM. Complementa a la tabla estandar MARM (MM).
  - Campos adicionales: indicadores de manejo en almacen, datos de embalaje por UM, dimensiones fisicas extendidas.
- **`/SCWM/MATID`**: ID interno de producto EWM. Mapea `MATNR` (MM) a `MATID` (GUID interno EWM).
  - Necesario porque EWM usa GUIDs para rendimiento en operaciones masivas.

### Vistas del Maestro de Materiales Relevantes para EWM
| Vista MM | Datos EWM Relevantes |
|---|---|
| Almacenamiento general (MRP 1/2) | Clase de valoracion, tipo de aprovisionamiento |
| Almacenamiento (por planta/almacen) | Temperatura, clase de almacenamiento, indicador WM |
| Datos basicos 1 | Peso bruto, peso neto, volumen, unidad de medida base |
| Clasificacion | Clases y caracteristicas para estrategias de almacen |
| Gestion de lotes | Activacion de gestion por lotes |
| Numeros de serie | Perfil de numero de serie |

## Datos de Embalaje y Unidades de Medida

### Jerarquia de Unidades de Medida
EWM gestiona la jerarquia completa de UM para optimizar almacenamiento y picking:

```
PAL (Paleta)    → 10 CJA
CJA (Caja)      → 12 UN
UN  (Unidad)    → UM base
```

### Datos de Dimension por UM (tabla MARM + /SCWM/MARM)
| Campo | Descripcion |
|---|---|
| `EAN11` | Codigo de barras (EAN/UPC) por UM |
| `BRGEW` | Peso bruto por UM |
| `NTGEW` | Peso neto por UM |
| `VOLUM` | Volumen por UM |
| `LAENG` | Longitud |
| `BREIT` | Ancho |
| `HOEHE` | Altura |
| `MEABM` | Unidad de dimension (CM, M, IN) |

### Unidad de Medida de Almacenamiento (Storage UoM)
- Campo `ALTME` en registro de almacen (tabla LGPLA view): UM en la que se gestiona el stock en almacen.
- Puede diferir de la UM base: ej. comprar en KG pero almacenar en CAJA.
- EWM realiza conversion automatica en tareas de warehouse.

## Indicadores de Tipo de Almacenamiento

### Indicadores de Almacen (Warehouse Indicator)
Configurados en la vista de almacen del maestro de materiales:

| Indicador | Descripcion |
|---|---|
| Clase de almacenamiento (`LGKLA`) | Determina en que Storage Types puede almacenarse |
| Indicador de seccion (`LGBER_IND`) | Para determinacion de seccion de almacen |
| Clase de temperatura | Requisito de temperatura del material |
| Indicador de mercancias peligrosas | Clase de peligro para restriccion de ubicaciones |
| Gestion por HU obligatoria | El material debe moverse siempre en HU |
| Cantidad de bultos max por HU | Limite de unidades por unidad de manejo |

### Clase de Almacenamiento (Storage Class)
- Tabla: `/SCWM/T325` (Storage Class).
- Cada clase tiene Storage Types permitidos → determina donde puede almacenarse el material.
- Ejemplo: Clase `001` (standard) → puede ir a RACK, BULK, PICK. Clase `002` (peligroso) → solo zona HAZMAT.

## Mercancias Peligrosas (Hazmat)

### Clasificacion en Maestro de Materiales
- Vista "Mercancias Peligrosas" (pestaña adicional, requiere activacion).
- Clase de peligro ADR/IATA/IMDG (campo `HZMAT_CLASS`).
- Numero UN (`UN_NUMBER`), grupo de embalaje (`PACK_GROUP`).
- Codigo de segregacion para almacenamiento conjunto/separado.

### Impacto en EWM
- La estrategia de determinacion de ubicacion verifica compatibilidad de clase de peligro.
- Ubicaciones con zona Hazmat incompatible son excluidas automaticamente.
- Documentacion de transporte: etiquetas de peligro generadas automaticamente al crear envio.

## Gestion de Lotes (Batch Management)

### Activacion en Maestro de Materiales
- Vista "Clasificacion" + vista "Almacenamiento": activar `Gestion de lotes` (campo `XCHPF` en MARA).
- Nivel de lote: planta (MARA) o cliente (cliente especifico).

### Datos de Lote Relevantes para EWM
- Fecha de caducidad (SLED/BBD): usada en estrategia FEFO de stock removal.
- Clasificacion de lote: caracteristicas de clase para estrategias avanzadas.
- Estado de control de calidad: lote bloqueado para uso → EWM restringe picking.
- Tabla de lotes: `MCH1` (lote a nivel cliente), `MCHA` (lote a nivel planta).

## Numeros de Serie (Serial Number Management)

### Perfil de Numero de Serie (Campo `SERNP` en MARA)
| Perfil | Comportamiento EWM |
|---|---|
| `SERN` | Solo en GR/GI (no en movimientos internos) |
| `SEREC` | En todos los movimientos de almacen |
| `AUTO` | Asignacion automatica de numeros de serie |

### Impacto en Tareas de Warehouse
- Con numero de serie activo: cada unidad individual requiere escaneo en confirmacion de WT.
- Tabla de seguimiento: `SER09` (asignacion SN a entrega), `OBJK` (master de numeros de serie).

## Inspeccion de Calidad (Quality Inspection Flag)

### Indicador de Control de Calidad en EWM
- Materiales con QM activo (campo `QMPUR` en vista Compras, `QMATA` en vista Calidad).
- Al recibir GR, el sistema puede crear orden de inspeccion QM (tipo `01` o `05`).
- Stock en inspeccion (`Unrestricted` vs `Quality Inspection` stock).
- En EWM: el quant puede tener estado de calidad `Q` (en inspeccion) → no disponible para picking hasta liberacion.

## Datos de Slotting (Asignacion Optimizada de Ubicaciones)

### Slotting en EWM
Tabla: `/SCWM/MATID` + tablas de resultado de slotting (`/SCWM/SLOT*`).

- **Velocidad de rotacion (velocity)**: A (alta), B (media), C (baja) — calculada de historial de movimientos.
- **Zona de picking asignada**: resultado del slotting define Storage Type/Section optimo para el material.
- **Ubicacion fija propuesta**: slotting propone bin fijo para materiales de alta rotacion.
- **Capacidad de replenishment**: cuando stock en zona pick cae por debajo de minimo → WT de reposicion automatica.

### Proceso de Slotting
1. Ejecutar analisis de movimientos (`/SCWM/SLOTTING`).
2. Clasificar materiales por velocidad (ABC analysis).
3. Asignar zonas optimas de almacenamiento.
4. Activar resultado → afecta estrategia de putaway.

## Consultas MCP Recomendadas

```
// Ver extension EWM del maestro de materiales
tool: ReadTable
params: {
  table_name: "/SCWM/MARM",
  fields: ["MATID","MEINH","BRGEW","NTGEW","VOLUM","LAENG","BREIT","HOEHE"],
  where: "MATID = '<guid>'",
  max_rows: 20
}

// Mapeo MATNR → MATID interno EWM
tool: ReadTable
params: {
  table_name: "/SCWM/MATID",
  fields: ["MATID","MATNR","MANDT"],
  where: "MATNR = 'MATERIAL001'",
  max_rows: 10
}

// Ver quants de un material en almacen
tool: ReadTable
params: {
  table_name: "/SCWM/QUANT",
  fields: ["LGNUM","LGTYP","LGPLA","MATID","CHARG","QUAN","MEINS","BESTQ","CAT"],
  where: "LGNUM = '0001' AND MATID = '<guid>'",
  max_rows: 100
}

// Datos de lote con fecha de caducidad
tool: ReadTable
params: {
  table_name: "MCH1",
  fields: ["MATNR","CHARG","WERKS","VFDAT","HSDAT","LWEDT"],
  where: "MATNR = 'MATERIAL001'",
  max_rows: 50
}
```

## Notas S/4HANA 2023 — EWM Embebido

- La creacion/modificacion del maestro de materiales en S/4HANA usa la app Fiori "Maintain Material" o MM01/MM02.
- En EWM Embebido, la sincronizacion del maestro de materiales desde MM a EWM es automatica (no hay RFC). El `MATID` se genera al crear el material.
- Para migracion masiva de datos de maestro EWM (pesos, dimensiones por UM), usar LSMW con BAPI `BAPI_MATERIAL_SAVEDATA`.
- El Slotting App Fiori esta disponible desde S/4HANA 2022 (F3622 "Slotting").
- Mercancias peligrosas requiere activacion del modulo SAP Dangerous Goods Management (DG) en S/4HANA.
