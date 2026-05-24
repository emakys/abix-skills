# Tablas de Customizing PP

## Datos maestros

| Tabla | Descripcion |
|-------|-------------|
| MARC | Material-Centro (MRP, scheduling, procurement) |
| MARD | Stock por almacen |
| MAST | Asignacion material-BOM |
| STKO | Cabecera BOM |
| STPO | Posiciones BOM |
| STAS | Sub-items BOM |
| PLKO | Cabecera routing |
| PLPO | Operaciones routing |
| PLFL | Secuencias routing |
| PLAS | Asignacion material-routing |
| PLMZ | Asignacion componentes-operaciones |
| CRHD | Cabecera puesto de trabajo |
| CRCO | Asignacion CC puesto trabajo |
| CRTX | Textos puesto trabajo |
| KAKO | Capacidad puesto trabajo |
| MKAL | Versiones fabricacion |

## Ordenes

| Tabla | Descripcion |
|-------|-------------|
| AUFK | Cabecera orden (general) |
| AFKO | Cabecera orden produccion |
| AFPO | Posiciones orden produccion |
| AFVC | Operaciones orden |
| AFVV | Valores estandar operaciones orden |
| AFFL | Secuencias orden |
| RESB | Reservas (componentes) |
| AFRU | Confirmaciones |
| JEST | Status objeto |
| JSTO | Status object header |

## MRP

| Tabla | Descripcion |
|-------|-------------|
| MDKP | Cabecera lista MRP |
| MDTB | Elementos MRP (lineas MD04) |
| MDVM | Parametros planificacion |
| MDFD | Fechas MRP |
| PLAF | Ordenes previsionales |
| PBIM | PIR (necesidades independientes) |
| T460A | Areas MRP |

## Movimientos

| Tabla | Descripcion |
|-------|-------------|
| MATDOC | Documentos material (S/4HANA) |
| MKPF | Cabecera doc material (ECC) |
| MSEG | Posiciones doc material (ECC) |
| COGI | Errores movimientos automaticos |

## Customizing — Ordenes

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T003O | Tipos de orden | Prod > Shop Floor Control > Define Order Types |
| T399X | Parametros tipo orden | Order Types parameters |
| T003 | Tipos documento (general) | — |
| NRIV | Rangos numeros | Prod > Shop Floor Control > Number Ranges |
| T430 | Motivos chatarra | Prod > Shop Floor Control > Define Scrap Reasons |

## Customizing — MRP

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T438M | Parametros planificacion MRP | Prod > MRP > Scope of Planning |
| T439A | Grupos MRP | Prod > MRP > MRP Groups |
| T457E | Tipos tamano lote | Prod > MRP > Lot Size |
| T441V | Claves horizonte planificacion | Prod > MRP > Planning Horizon |
| T441W | Periodo planificacion | Prod > MRP > Planning Period |
| T460A | Areas MRP | Prod > MRP > MRP Areas |
| MDLL | Parametros MRP Live | Prod > MRP > MRP Live |

## Customizing — Scheduling

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TC24 | Formulas scheduling | Prod > Basic Data > Scheduling Formulas |
| T436A | Margenes flotantes | Prod > Scheduling > Floats |
| T436B | Tiempos interoperacion | Prod > Scheduling > Interoperation Times |
| T430 | Claves de control | Prod > Routings > Control Keys |

## Customizing — Confirmaciones

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T430 | Claves control operaciones | Prod > Routing > Control Keys |
| T496A | Parametros confirmacion | Prod > Shop Floor > Confirmation > Parameters |
| T496M | Milestone confirmacion | Prod > Shop Floor > Confirmation > Milestone |
| T430 | Motivos chatarra/desvio | Prod > Shop Floor > Scrap/Deviation Reasons |

## Customizing — BOM

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T415 | Tipos posicion BOM | Prod > Basic Data > BOM > Item Categories |
| T416 | Usos BOM | Prod > Basic Data > BOM > Usage |
| T417 | Status BOM | Prod > Basic Data > BOM > Status |

## Customizing — Disponibilidad

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T441V | Grupos verificacion | Prod > MRP > Availability Check |
| TVSAK | Control disponibilidad ventas | SD > Availability Check |
| T441W | Alcance verificacion | Prod > MRP > Availability Check Scope |

## Customizing — Capacidad

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TC24 | Formulas | Prod > Capacity > Formulas |
| T77PR | Perfiles capacidad | Prod > Capacity > Profiles |

## Tablas de control

| Tabla | Descripcion |
|-------|-------------|
| T001W | Centros (calendario, valoracion) |
| TNIW | Parametros centro produccion |
| T024D | Grupos planificadores MRP |
| T024F | Grupos planificadores produccion |
