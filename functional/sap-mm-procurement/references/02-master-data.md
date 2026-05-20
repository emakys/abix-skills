# Datos Maestros MM

## Material Master (MM01/MM02/MM03)

### Vistas relevantes para compras
| Vista | Datos | Obligatoria para compras |
|-------|-------|:-----------------------:|
| Datos base 1 | Unidad medida base, grupo materiales | Si |
| Datos base 2 | Textos | No |
| Compras | Grupo compra, unidad pedido, tiempo entrega | Si |
| MRP 1-4 | Tipo MRP, punto pedido, stock seguridad | Si (si usa MRP) |
| Contabilidad 1 | Precio, control precio (S/V), cuenta | Si |
| Centro (General Plant) | Perfil comprobacion disponibilidad | Recomendado |
| Almacen | Stock inicial | No |

### Tipos de material estandar (MARA-MTART)
| Tipo | Descripcion | Control precio tipico |
|------|-------------|----------------------|
| ROH | Materia prima | V (precio movil) |
| HALB | Semielaborado | S (precio estandar) |
| FERT | Producto terminado | S (precio estandar) |
| HIBE | Material auxiliar | V |
| DIEN | Servicio | — (sin stock) |
| NLAG | Material sin gestion stock | — |
| HAWA | Mercancia comercial | V |
| UNBW | Material no valorado | — |
| ERSA | Repuesto | V |

### Control de precio (MBEW-VPRSV)
| Indicador | Tipo | Comportamiento |
|-----------|------|----------------|
| **S** | Precio estandar (STPRS) | Fijo; diferencias van a cuenta PRD (OBYC) |
| **V** | Precio movil MAP (VERPR) | Se actualiza con cada GR y factura |

> Regla general: materia prima y comercial → **V** (MAP). Producto terminado → **S** (estandar).
> S/4HANA permite split valuation y material ledger para ambos tipos.

### Tablas de material
| Tabla | Nivel | Contenido |
|-------|-------|-----------|
| MARA | Mandante | Datos generales material |
| MAKT | Mandante | Textos material |
| MARC | Centro | Datos MRP, compras a nivel centro |
| MARD | Almacen | Stock por almacen |
| MBEW | Area valoracion | Precio, control precio |
| MVKE | Org ventas | Datos ventas (si aplica) |

### Queries MCP
```sql
-- Material completo con precio y stock
SELECT MARA.MATNR, MAKT.MAKTX, MARC.WERKS, MARC.EKGRP, MARC.DISMM,
       MBEW.VPRSV, MBEW.VERPR, MBEW.STPRS, MARD.LABST
FROM MARA
JOIN MAKT ON MARA.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'E'
LEFT JOIN MARC ON MARA.MATNR = MARC.MATNR
LEFT JOIN MBEW ON MARA.MATNR = MBEW.MATNR AND MARC.WERKS = MBEW.BWKEY
LEFT JOIN MARD ON MARA.MATNR = MARD.MATNR AND MARC.WERKS = MARD.WERKS
WHERE MARA.MATNR = '{material}'

-- Materiales sin vista de compras en un centro
SELECT MARA.MATNR, MAKT.MAKTX FROM MARA
JOIN MAKT ON MARA.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'E'
WHERE MARA.MATNR NOT IN (SELECT MATNR FROM MARC WHERE WERKS = '{centro}')
AND MARA.MTART IN ('ROH','HALB','FERT')
```

## Proveedor / Business Partner

### ECC (LFA1) vs S/4HANA (BP)
| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Transaccion | MK01/XK01 | BP |
| Tabla general | LFA1 | BUT000 |
| Tabla org compras | LFM1 | — (roles BP) |
| Tabla sociedad | LFB1 | — (roles BP) |
| Grupo cuenta | LFA1-KTOKK | BUT000-BU_GROUP |
| Integracion | Vendor = Vendor | Vendor = BP con rol FLVN00 |

### Tablas proveedor
| Tabla | Nivel | Contenido |
|-------|-------|-----------|
| LFA1/BUT000 | Mandante | Datos generales proveedor |
| LFM1 | Org compras | Datos compras (condiciones pago, incoterms) |
| LFB1 | Sociedad | Datos contables (cuenta asociada, grupo tesoreria) |
| LFBK | Mandante | Datos bancarios |
| WYT3 | Mandante | Funciones interlocutor (partner functions) |

### Queries MCP
```sql
-- Proveedor con extensiones
SELECT LFA1.LIFNR, LFA1.NAME1, LFA1.LAND1, LFA1.KTOKK,
       LFM1.EKORG, LFM1.ZTERM, LFM1.INCO1,
       LFB1.BUKRS, LFB1.AKONT
FROM LFA1
LEFT JOIN LFM1 ON LFA1.LIFNR = LFM1.LIFNR
LEFT JOIN LFB1 ON LFA1.LIFNR = LFB1.LIFNR
WHERE LFA1.LIFNR = '{proveedor}'

-- Proveedores sin extension org compras
SELECT LIFNR, NAME1 FROM LFA1
WHERE LIFNR NOT IN (SELECT LIFNR FROM LFM1 WHERE EKORG = '{org_compras}')
AND KTOKK IN ('0001','KRED')
```

## Info Record (ME11/ME12/ME13)

### Estructura
| Tabla | Nivel | Contenido |
|-------|-------|-----------|
| EINA | Mandante | Datos generales (proveedor+material) |
| EINE | Org compras | Precio, condiciones, plazo entrega |
| A017 | Condicion | Condicion de precio PB00 |
| KONH/KONP | Condicion | Registro condicion detalle |

### Queries MCP
```sql
-- Info record completo
SELECT EINA.INFNR, EINA.MATNR, EINA.LIFNR,
       EINE.EKORG, EINE.WERKS, EINE.NETPR, EINE.PEINH, EINE.WAERS
FROM EINA
JOIN EINE ON EINA.INFNR = EINE.INFNR
WHERE EINA.MATNR = '{material}' AND EINA.LIFNR = '{proveedor}'
```

## Source List (ME01) y Quota Arrangement (MEQ1)

- **Source list** (EORD): define proveedores validos por material/centro/periodo
- **Quota arrangement** (EQUK/EQUP): distribuye % de compra entre proveedores
- MRP usa source list para generar solicitudes con proveedor asignado
- Si T161-SRCLIST = 'X', source list es obligatorio para ese tipo de pedido
