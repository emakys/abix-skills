# Catalogo de Transacciones PP

## Datos maestros

| TCode | Descripcion | Area |
|-------|-------------|------|
| MM01 | Crear material (vistas PP) | Material master |
| MM02 | Modificar material | Material master |
| MM03 | Visualizar material | Material master |
| CS01 | Crear BOM | BOM |
| CS02 | Modificar BOM | BOM |
| CS03 | Visualizar BOM | BOM |
| CS05 | Modificar BOM grupo | BOM |
| CS11 | BOM multi-nivel | BOM |
| CS12 | BOM multi-nivel qty | BOM |
| CS13 | BOM resumida | BOM |
| CS14 | BOM comparativa | BOM |
| CS15 | Where-used BOM | BOM |
| CS20 | Mass change BOM | BOM |
| CA01 | Crear routing | Routing |
| CA02 | Modificar routing | Routing |
| CA03 | Visualizar routing | Routing |
| CA11 | Crear reference operation set | Routing |
| CA21 | Crear rate routing | Routing |
| CA80 | Listado routings | Routing |
| C201 | Crear master recipe | PP-PI |
| C202 | Modificar master recipe | PP-PI |
| C223 | Version fabricacion | Version |
| CR01 | Crear puesto trabajo | Work center |
| CR02 | Modificar puesto trabajo | Work center |
| CR03 | Visualizar puesto trabajo | Work center |
| CR05 | Lista puestos trabajo | Work center |
| CR60 | Display capacidad | Work center |

## MRP / Planificacion

| TCode | Descripcion | Area |
|-------|-------------|------|
| MD01 | MRP total centro | MRP |
| MD01N | MRP Live (S/4) | MRP |
| MD02 | MRP material individual | MRP |
| MD03 | MRP individual online | MRP |
| MD04 | Lista stock/necesidades | MRP |
| MD05 | Lista MRP individual | MRP |
| MD06 | Lista MRP colectiva | MRP |
| MD07 | Lista MRP general | MRP |
| MD11 | Crear orden previsional | MRP |
| MD12 | Modificar previsional | MRP |
| MD13 | Visualizar previsional | MRP |
| MD16 | Convertir previsional colectivo | MRP |
| MD20 | Crear programacion MRP | MRP |
| MD61 | Crear PIR | Demand |
| MD62 | Modificar PIR | Demand |
| MD63 | Visualizar PIR | Demand |
| MD73 | Evaluacion PIR | Demand |
| MD74 | Reorganizar PIR | Demand |
| MDBT | MRP background | MRP |

## Ordenes produccion

| TCode | Descripcion | Area |
|-------|-------------|------|
| CO01 | Crear orden produccion | Order |
| CO02 | Modificar orden | Order |
| CO03 | Visualizar orden | Order |
| CO04 | Lista ordenes (tree) | Order |
| CO05N | Liberar colectivo | Order |
| CO07 | Crear orden sin material | Order |
| CO08 | Crear con referencia | Order |
| CO40 | Convertir previsional individual | Order |
| CO41 | Convertir previsional colectivo | Order |
| COHV | Mass processing | Order |
| COOIS | Lista informativa ordenes | Order |

## Confirmaciones

| TCode | Descripcion | Area |
|-------|-------------|------|
| CO11N | Confirmacion individual | Confirmation |
| CO11 | Confirmacion (vieja) | Confirmation |
| CO12 | Confirmacion colectiva hora | Confirmation |
| CO13 | Anulacion confirmacion | Confirmation |
| CO14 | Visualizar confirmacion | Confirmation |
| CO15 | Confirmacion con GR | Confirmation |
| CO16 | Confirmacion con backflush | Confirmation |
| CO24 | Lista faltantes | Confirmation |

## Ordenes proceso (PP-PI)

| TCode | Descripcion | Area |
|-------|-------------|------|
| COR1 | Crear orden proceso | Process order |
| COR2 | Modificar orden proceso | Process order |
| COR3 | Visualizar orden proceso | Process order |
| COR5 | Liberar colectivo | Process order |
| COR6N | Confirmacion proceso | Process order |
| COR8 | Convertir previsional | Process order |
| CORK | Lista ordenes proceso | Process order |

## Repetitive Manufacturing

| TCode | Descripcion | Area |
|-------|-------------|------|
| MF50 | Tabla planificacion | REM |
| MFBF | Backflush REM | REM |
| MF42N | Backflush masivo | REM |
| MF12 | Lista backflush | REM |
| MF60 | Planning table | REM |
| KKF6N | Product cost collector | REM |

## Capacidad

| TCode | Descripcion | Area |
|-------|-------------|------|
| CM01 | Carga puesto trabajo | Capacity |
| CM02 | Lista carga | Capacity |
| CM04 | Backlog | Capacity |
| CM05 | Carga por orden | Capacity |
| CM07 | Vista general | Capacity |
| CM21 | Perfil carga | Capacity |
| CM25 | Pool capacidades | Capacity |
| CM50 | Lista capacidad | Capacity |

## Movimientos y stock

| TCode | Descripcion | Area |
|-------|-------------|------|
| MIGO | Movimiento mercancias | Goods movement |
| MB52 | Stock por almacen | Stock |
| MMBE | Resumen stock | Stock |
| COGI | Errores movimiento automatico | Error handling |
| MB51 | Lista documentos material | Stock |

## Cierre periodo

| TCode | Descripcion | Area |
|-------|-------------|------|
| KKAO | Calculo WIP colectivo | Period close |
| KKAX | Calculo WIP individual | Period close |
| CO43 | Overhead produccion | Period close |
| KKS1 | Calculo desviaciones colectivo | Period close |
| KKS2 | Calculo desviaciones individual | Period close |
| CO88 | Settlement colectivo | Period close |
| KO88 | Settlement individual | Period close |

## Configuracion (SPRO shortcuts)

| TCode | Descripcion | Area |
|-------|-------------|------|
| OPJH | Tipo orden produccion | Config |
| OPL8 | Parametros planificacion MRP | Config |
| OMD0 | MRP controller | Config |
| OPMX | Scheduling parameters | Config |
| OPK3 | Motivos chatarra | Config |
| SCAL | Calendario fabrica | Config |
