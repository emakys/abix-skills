# Transacciones PM

## Ubicaciones Tecnicas

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IL01 | Crear ubicacion tecnica | F2651 |
| IL02 | Modificar ubicacion tecnica | |
| IL03 | Visualizar ubicacion tecnica | F2651 |
| IL04 | Crear estructura ubicacion | |
| IL05 | Lista ubicaciones | |
| IL06 | Lista ubicaciones (multi-nivel) | |
| IL07 | Lista ubicaciones funcional | |
| IL11 | Crear mascara edicion | |

## Equipos

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IE01 | Crear equipo | |
| IE02 | Modificar equipo | |
| IE03 | Visualizar equipo | F2650 |
| IE05 | Lista equipos (por tipo) | |
| IE07 | Lista equipos funcional | |
| IE4N | Instalacion/desinstalacion equipo | |
| IE08 | Reemplazo equipo | |

## BOM de Mantenimiento

| TCode | Descripcion |
|-------|-------------|
| IB01 | Crear BOM equipo |
| IB02 | Modificar BOM equipo |
| IB03 | Visualizar BOM equipo |
| IB05 | Lista BOM equipo |
| IB11 | Crear BOM ubicacion |
| IB12 | Modificar BOM ubicacion |

## Avisos de Mantenimiento

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IW21 | Crear aviso | F1580 |
| IW22 | Modificar aviso | F2626 |
| IW23 | Visualizar aviso | F2653 |
| IW24 | Crear aviso con referencia | |
| IW25 | Lista tareas avisos | |
| IW28 | Lista avisos (seleccion) | |
| IW29 | Lista avisos (multi-nivel) | |
| IW30 | Avisos por objeto tecnico | |
| IW64 | Avisos completados | |
| IW65 | Avisos por equipo/ubicacion | |
| IW67 | Analisis costes avisos | |
| IW68 | Avisos → ordenes (masivo) | |

## Ordenes de Mantenimiento

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IW31 | Crear orden | F2649 |
| IW32 | Modificar orden | F1596 |
| IW33 | Visualizar orden | F2652 |
| IW34 | Crear orden con referencia | |
| IW36 | Crear orden desde aviso | |
| IW37N | Lista ordenes ampliada | |
| IW38 | Lista ordenes (seleccion) | F1596 |
| IW39 | Lista ordenes (multi-nivel) | |
| IW40 | Visualizar operaciones | |
| IW66 | Analisis costes orden | |
| IW67 | Plan vs Real costes | |
| IW70 | Estructura orden (grafico) | |
| IW72 | Lista componentes (repuestos) | |
| IW73 | Lista reservas materiales | |

## Confirmaciones

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IW41 | Confirmacion individual | F3438 |
| IW42 | Confirmacion colectiva | |
| IW44 | Cancelar confirmacion | |
| IW45 | Visualizar confirmacion | |
| IW47 | Confirmacion con seleccion | |
| IW49 | Lista confirmaciones | |

## Liberacion y Status

| TCode | Descripcion |
|-------|-------------|
| IW32 | Liberar orden (→ Funciones → Liberar) |
| IW38 | Liberacion masiva (seleccionar → Liberar) |
| CO02 | Status management (via orden) |

## Planes de Mantenimiento

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| IP01 | Crear plan | F3675 |
| IP02 | Modificar plan | |
| IP03 | Visualizar plan | |
| IP04 | Crear posicion | |
| IP05 | Modificar posicion | |
| IP10 | Programar plan individual | |
| IP11 | Crear/modificar estrategia | |
| IP12 | Visualizar estrategia | |
| IP15 | Lista estrategias | |
| IP16 | Lista planes | |
| IP17 | Lista posiciones | |
| IP19 | Lista llamadas | |
| IP24 | Planes para objeto tecnico | |
| IP30 | Programacion masiva | |
| IP42 | Monitoreo de planes | |

## Hojas de Ruta / Task Lists

| TCode | Descripcion |
|-------|-------------|
| IA01 | Crear hoja ruta equipo |
| IA02 | Modificar hoja ruta equipo |
| IA03 | Visualizar hoja ruta equipo |
| IA05 | Lista hojas ruta equipo |
| IA06 | Crear hoja ruta ubicacion |
| IA11 | Crear hoja ruta general |
| IA12 | Modificar hoja ruta general |
| IA13 | Visualizar hoja ruta general |
| IA15 | Lista hojas ruta general |

## Puntos de Medida y Contadores

| TCode | Descripcion |
|-------|-------------|
| IK01 | Crear punto de medida |
| IK02 | Modificar punto de medida |
| IK03 | Visualizar punto de medida |
| IK07 | Lista puntos de medida |
| IK11 | Crear documento medicion |
| IK12 | Modificar documento medicion |
| IK17 | Lista documentos medicion |

## Puestos de Trabajo

| TCode | Descripcion |
|-------|-------------|
| IR01 | Crear puesto trabajo |
| IR02 | Modificar puesto trabajo |
| IR03 | Visualizar puesto trabajo |

## Catalogos

| TCode | Descripcion |
|-------|-------------|
| QS41 | Crear grupo codigos |
| QS42 | Modificar grupo codigos |
| QS43 | Visualizar grupo codigos |
| QS51 | Crear codigos |
| QS61 | Crear seleccion codigos |

## Reporting (PMIS)

| TCode | Descripcion | Fiori |
|-------|-------------|-------|
| MCI1 | Analisis ubicaciones tecnicas | |
| MCI2 | Analisis fabricante | |
| MCI3 | Analisis avisos por ubicacion | |
| MCI5 | Analisis de danos (MTBF) | F3303 |
| MCI7 | Analisis de costes mantenimiento | F3545 |
| MCJB | Analisis ordenes PM | F3304 |
| MCJC | Analisis de fallas | |

## Liquidacion y Cierre

| TCode | Descripcion |
|-------|-------------|
| KO88 | Liquidacion individual |
| KO8G | Liquidacion colectiva |
| OIBN | Rangos numeros PM |

## Customizing (SPRO directo)

| TCode | Descripcion |
|-------|-------------|
| OIOA | Config centro planificacion mantto |
| OIP1 | Grupos planificador |
| OIQA | Tipos de aviso |
