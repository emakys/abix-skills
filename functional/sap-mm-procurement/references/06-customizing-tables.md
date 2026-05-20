# Tablas de Customizing MM

## Estructura organizativa
| Tabla | Que configura | Transaccion IMG | Query MCP |
|-------|--------------|-----------------|-----------|
| T001 | Sociedades | OX02 | SELECT BUKRS,BUTXT,WAERS,LAND1 FROM T001 |
| T001W | Centros/Plantas | OX10 | SELECT WERKS,NAME1,BUKRS FROM T001W |
| T001L | Almacenes | OX09 | SELECT WERKS,LGORT,LGOBE FROM T001L |
| T024E | Org. compras | SPRO | SELECT EKORG,EKOTX FROM T024E |
| T024 | Grupos compra | SPRO | SELECT EKGRP,EKNAM FROM T024 |
| T024W | Asign centro-org compras | OX17 | SELECT EKORG,WERKS FROM T024W |

## Tipos de documento
| Tabla | Que configura | Transaccion IMG | Query MCP |
|-------|--------------|-----------------|-----------|
| T161 | Tipos doc compras | OME2 | SELECT BSART,BSTYP,NUMKI FROM T161 |
| T161T | Textos tipos doc | — | SELECT BSART,BATXT FROM T161T WHERE SPRAS='E' |
| T163 | Categorias de posicion | OMEC | SELECT PSTYP,PTEXT FROM T163 WHERE SPRAS='E' |
| T163K | Categorias imputacion | OMEK | SELECT KNTTP,KNTTX FROM T163K WHERE SPRAS='E' |

## Release strategy (liberacion)
| Tabla | Que configura | Transaccion IMG |
|-------|--------------|-----------------|
| T16FC | Grupos de liberacion | SPRO |
| T16FD | Codigos de liberacion | SPRO |
| T16FS | Release strategies | SPRO |
| T16FG | Clases de documento para release | SPRO |
| T16FB | Indicadores de liberacion | SPRO |

### Queries para release
```sql
-- Release strategies configuradas
SELECT FRGSX, FRGXT FROM T16FS WHERE SPRAS = 'E'

-- Grupos de liberacion
SELECT FRGCO, FRGCT FROM T16FC WHERE SPRAS = 'E'

-- Codigos por grupo
SELECT FRGCO, FRGC1, FRGC1T FROM T16FD
JOIN T16FCT ON T16FD.FRGCO = T16FCT.FRGCO
WHERE T16FCT.SPRAS = 'E'
```

## Precios y condiciones
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T683S | Esquemas de calculo | M/06 |
| T685 | Tipos de condicion | M/06 |
| T681F | Secuencias de acceso | M/07 |
| A017 | Cond. proveedor+material | ME11 |
| A018 | Cond. proveedor+grupo material | ME11 |
| KONH | Cabecera condicion | |
| KONP | Posicion condicion | |

## Determinacion de cuentas
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T030 | Cuentas automaticas | OBYC |
| T025 | Grupos valoracion | OMWD |
| T001K | Areas valoracion | — |
| MBEW | Clase valoracion material | MM02 |

### Queries
```sql
-- Configuracion OBYC
SELECT KTOPL, KTOSL, BKLAS, KONTS FROM T030
WHERE KTOPL = '{plan_cuentas}'
AND KTOSL IN ('BSX','WRX','PRD','GBB','KON','FRL')

-- Grupos de valoracion
SELECT BKLAS, BKBEZ FROM T025 WHERE BKLAS = '{clase_valoracion}' AND SPRAS = 'E'
```

## Verificacion facturas
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T169G | Tolerancias factura | OMR6/OMRM |
| T169P | Limites tolerancia precio | OMR6 |
| T169F | Config bloqueo factura | OMRM |

## Movimientos de mercancias
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T156 | Tipos movimiento | OMJJ |
| T156B | Config tipos movimiento | OMJJ |
| T156W | Asign cuenta por TM | OMJJ |
| T157H | Textos tipo movimiento | — |

## MRP
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T399D | Parametros MRP por centro | OMDU |
| T438M | Tipos MRP | OPPR |
| T399X | Parametros planificacion | OMDU |
| T441R | Tamano lote | OMDO |

## Condiciones de pago
| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| T052 | Condiciones de pago | OBB8 |
| T052U | Textos condiciones pago | — |

### Query
```sql
SELECT T052.ZTERM, T052U.TEXT1, T052.ZTAG1, T052.ZPRZ1
FROM T052 JOIN T052U ON T052.ZTERM = T052U.ZTERM
WHERE T052U.SPRAS = 'E'
```
