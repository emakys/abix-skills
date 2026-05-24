# Tablas de Customizing PM

## Estructura Organizativa

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T001W | Centros/plantas (SWERK,IWERK) | WERKS, SWERK, IWERK, NAME1 |
| T024I | Grupos planificador | INGRP, INNAM, IWERK |
| CRHD | Puestos de trabajo (cabecera) | OBJID, ARBPL, WERKS, OBJTY |
| CRCO | Asignacion puesto trabajo → CC | OBJID, KOSTL, LESSION |

## Tipos de Orden y Aviso

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T003O | Tipos de orden PM | AUART, AUTYP |
| T003P | Parametros tipo orden | AUART, REFNR |
| TQ80 | Tipos de aviso | QMART |
| TQ80T | Textos tipo aviso | QMART, SPRAS, QMARTX |

## Catalogos

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| QPCD | Codigos de catalogo | KATESSION, CESSION |
| QPCT | Textos codigos catalogo | KATESSION, CESSION, SPRAS |
| QPGR | Grupos de codigo | KATESSION, CODEGRUPPE |
| QPGT | Textos grupos codigo | KATESSION, CODEGRUPPE, SPRAS |
| TQ72 | Perfil catalogo | ARTPR |

## Prioridades

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T356 | Prioridades | PRIESSION |
| T356T | Textos prioridad | PRIESSION, SPRAS |

## Estrategias y Planes

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T351 | Estrategias mantenimiento | STESSION |
| T351P | Paquetes de estrategia | STESSION, PAESSION |
| T351G | Textos estrategia | STESSION, SPRAS |
| MPLA | Planes de mantenimiento | WARPL |
| MPOS | Posiciones de plan | WARPL, POINT |
| MHIS | Historial de llamadas | WARPL, LESSION |

## Claves de Control

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T430 | Claves de control operacion | STEUS |
| T430T | Textos clave control | STEUS, SPRAS |

## Status

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| TJ02 | Status de sistema | ISTAT |
| TJ02T | Textos status sistema | ISTAT, SPRAS |
| TJ30 | Status de usuario | STSMA, ESTAT |
| TJ30T | Textos status usuario | STSMA, ESTAT, SPRAS |
| JEST | Status actuales objeto | OBJNR, STAT, INACT |
| JSTO | Perfil status de objeto | OBJNR, STSMA |

## Equipos y Ubicaciones

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T370K | Tipos ubicacion tecnica | ILESSION |
| T370T | Categorias equipo | EQTYP |
| T370A | Estructura ubicacion tecnica | ILESSION |
| T370B | Mascara ubicacion tecnica | ILESSION |

## Rangos de Numeros

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| NRIV | Rangos de numeros | OBJECT, NRRANGENR, FROMNUMBER, TONUMBER |

Objetos de rango: PM_AUFNR (ordenes), IH_EQUNR (equipos), IL_TPLNR (ubicaciones), PM_QMNUM (avisos)

## Determinacion de Cuentas

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T399X | Parametros liquidacion | AUART |
| TKA02 | Asignacion sociedad → area CO | BUKRS, KOKRS |

## Queries MCP

```
-- Tipos de orden PM
GetSqlQuery("SELECT AUART,TXT FROM T003O JOIN T003OT ON T003O.AUART=T003OT.AUART WHERE T003OT.SPRAS='E' AND T003O.AUART LIKE 'PM%'")

-- Tipos de aviso
GetSqlQuery("SELECT QMART,QMARTX FROM TQ80T WHERE SPRAS='E'")

-- Prioridades
GetSqlQuery("SELECT PRIESSION,TXT FROM T356T WHERE SPRAS='E'")

-- Estrategias
GetSqlQuery("SELECT STESSION,ESSION FROM T351G WHERE SPRAS='E'")

-- Paquetes de una estrategia
GetSqlQuery("SELECT PAESSION,NESSION,MENESSION,EINESSION FROM T351P WHERE STESSION='{estrategia}'")

-- Claves de control
GetSqlQuery("SELECT STEUS,TXT FROM T430T WHERE SPRAS='E'")

-- Grupos planificador
GetSqlQuery("SELECT INGRP,INNAM FROM T024I WHERE IWERK='{centro}'")

-- Status sistema
GetSqlQuery("SELECT ISTAT,TXT04,TXT30 FROM TJ02T WHERE SPRAS='E'")
```
