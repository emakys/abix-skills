# Tablas de Customizing SD — Referencia Completa

## Estructura Organizativa SD

| Tabla | Que configura | Transaccion IMG | Query MCP |
|-------|--------------|-----------------|-----------|
| TVKO | Organizaciones de ventas | OVX5 | SELECT VKORG,VKBUR,BUKRS FROM TVKO |
| TVKOZ | Asign. org.ventas a sociedad | OVX3 | SELECT VKORG,BUKRS FROM TVKOZ |
| TVTW | Canales de distribucion | OVXI | SELECT VTWEG,VTWET FROM TVTW WHERE SPRAS='E' |
| TVTA | Areas de ventas | OVXG | SELECT VKORG,VTWEG,SPART FROM TVTA |
| TSPA | Divisiones | OVXB | SELECT SPART,VTEXT FROM TSPA WHERE SPRAS='E' |
| TVBUR | Oficinas de ventas | OVXF | SELECT VKBUR,BEZEI FROM TVBUR WHERE SPRAS='E' |
| TVKGR | Grupos de vendedores | OVXG | SELECT VKGRP,BEZEI FROM TVKGR WHERE SPRAS='E' |

### Queries de estructura organizativa
```sql
-- Area de ventas completa con textos
SELECT A.VKORG, O.VTEXT AS ORG_VENTAS,
       A.VTWEG, TW.VTWET AS CANAL,
       A.SPART, SP.VTEXT AS DIVISION
FROM TVTA A
JOIN TVKOT O ON A.VKORG = O.VKORG AND O.SPRAS = 'E'
JOIN TVTWT TW ON A.VTWEG = TW.VTWEG AND TW.SPRAS = 'E'
JOIN TSPAT SP ON A.SPART = SP.SPART AND SP.SPRAS = 'E'
WHERE A.VKORG = '{org_ventas}'

-- Clientes asignados a area de ventas
SELECT KUNNR, VKORG, VTWEG, SPART FROM KNVV
WHERE VKORG = '{org_ventas}' AND VTWEG = '{canal}' AND SPART = '{division}'
```

---

## Tipos de Documento de Ventas (TVAK)

| Tabla | Que configura | Transaccion | Query MCP |
|-------|--------------|-------------|-----------|
| TVAK | Tipos de pedido de cliente | VOV8 | SELECT AUART,BEZEI FROM TVAK WHERE SPRAS='E' |
| TVAKX | Config. cabecera por tipo doc | VOV8 | SELECT AUART,AUFSD,SOBKZ,FAKSP FROM TVAK |

### Campos clave de TVAK
| Campo | Descripcion | Valores tipicos |
|-------|-------------|-----------------|
| AUART | Tipo de pedido | OR, ZOR, RE, CR, DR |
| AUTYP | Categoria doc ventas | 0=pedido, 1=oferta, 5=contrato |
| NUMKI | Rango numeracion cabecera | Ej: 01, 02 |
| FAKSP | Bloqueo facturacion | Espacio = sin bloqueo |
| SOBKZ | Indicador pedido especial | E=consignacion, W=stock cliente |
| AUFSD | Bloqueo entrega | Espacio = sin bloqueo |
| KALSM | Esquema calculo | Ej: RVAA01 |
| KTGRD | Grupo estadistica doc | Para SIS |
| PRSDT | Criterio fecha precio | A=fecha pedido, B=fecha entrega |
| LIFSK | Bloqueo entrega cabecera | Espacio = sin bloqueo |
| SPGR2 | Motivo rechazo propuesto | |

```sql
-- Todos los tipos de pedido con configuracion critica
SELECT AUART, BEZEI, AUTYP, NUMKI, FAKSP, SOBKZ, AUFSD, KALSM, PRSDT
FROM TVAK T JOIN TVAKT TX ON T.AUART = TX.AUART
WHERE TX.SPRAS = 'E'
ORDER BY AUART

-- Config de un tipo especifico
SELECT * FROM TVAK WHERE AUART = '{tipo_doc}'
```

---

## Tipos de Entrega (TVLK)

| Tabla | Que configura | Transaccion | Query MCP |
|-------|--------------|-------------|-----------|
| TVLK | Tipos de entrega | OVLK | SELECT LFART,BEZEI FROM TVLKT WHERE SPRAS='E' |
| TVLKT | Textos tipos entrega | OVLK | SELECT LFART,BEZEI FROM TVLKT WHERE SPRAS='E' |

### Campos clave de TVLK
| Campo | Descripcion |
|-------|-------------|
| LFART | Tipo de entrega (LF, ZLF, LR...) |
| LFTYP | Categoria documento entrega |
| NUMKI | Rango numeracion |
| VBTYP | Tipo documento SD (J=entrega) |
| TRMKZ | Relevante para transporte |
| PAPKZ | Uso relevante papel |

```sql
-- Tipos de entrega configurados
SELECT LK.LFART, LT.BEZEI, LK.LFTYP, LK.NUMKI, LK.TRMKZ
FROM TVLK LK JOIN TVLKT LT ON LK.LFART = LT.LFART
WHERE LT.SPRAS = 'E'
```

---

## Tipos de Factura (TVFK)

| Tabla | Que configura | Transaccion | Query MCP |
|-------|--------------|-------------|-----------|
| TVFK | Tipos de factura | VOFA | SELECT FKART,FKTYP,VBTYP FROM TVFK |
| TVFKT | Textos tipos factura | VOFA | SELECT FKART,BEZEI FROM TVFKT WHERE SPRAS='E' |

### Campos clave de TVFK
| Campo | Descripcion | Valores tipicos |
|-------|-------------|-----------------|
| FKART | Tipo factura | F2, ZF2, RE, G2, L2, S1 |
| FKTYP | Categoria factura | M=normal, O=pro-forma, S=abono |
| VBTYP | Tipo documento SD | M=factura, N=abono, O=cargo |
| NUMKI | Rango numeracion | |
| SFAKN | Factura colectiva | X=si |
| TRKKZ | Contabilizacion individual | |
| XRECH | Tipo de factura (antigua) | |

```sql
-- Tipos de factura con categoria
SELECT FK.FKART, FT.BEZEI, FK.FKTYP, FK.VBTYP, FK.NUMKI, FK.SFAKN
FROM TVFK FK JOIN TVFKT FT ON FK.FKART = FT.FKART
WHERE FT.SPRAS = 'E'
ORDER BY FK.FKART
```

---

## Categorias de Posicion (TVEP / T184)

### TVEP — Definicion de categorias de posicion
| Campo | Descripcion |
|-------|-------------|
| PSTYV | Categoria de posicion (TAN, TAB, TANN, TAX...) |
| PTEXT | Descripcion |
| LFREL | Relevante para entrega |
| FKREL | Relevante para facturacion |
| AGREL | Copia a oferta |
| SLREL | Linea programa relevante |
| RGSDA | Verificacion ATP |

```sql
-- Categorias de posicion definidas
SELECT PSTYV, PTEXT, LFREL, FKREL, RGSDA, AGREL
FROM TVEP WHERE SPRAS = 'E'
ORDER BY PSTYV

-- Config. detallada de una categoria
SELECT * FROM TVEP WHERE PSTYV = '{cat_pos}' AND SPRAS = 'E'
```

### T184 — Determinacion de categoria de posicion

**Clave de determinacion:** AUTYP (categ.doc) + MTPOS (grupo categ.material) + UEPOS (uso) + PSTYV (categ.pos.nivel sup.)

```sql
-- Determinacion completa de categorias de posicion
SELECT T.AUTYP, T.MTPOS, T.UEPOS, T.PSHIER, T.PSTYV, T.MTVFP
FROM T184 T
WHERE T.AUTYP = '{categ_doc}'   -- 0=pedido, 1=oferta, etc.
AND T.MTPOS = '{grupo_mat}'      -- NORM, LUMF, DIEN, LEIS...
ORDER BY T.AUTYP, T.MTPOS, T.UEPOS

-- Para un tipo de pedido especifico (via TVAK.AUTYP)
SELECT AUTYP FROM TVAK WHERE AUART = '{tipo_pedido}'
-- Luego usar ese AUTYP en T184

-- Verificar por que no se determino categoria
SELECT * FROM T184
WHERE AUTYP = '{autyp}'
AND MTPOS IN ('{mtpos}', ' ')
AND UEPOS IN ('{uepos}', ' ')
ORDER BY MTPOS DESC, UEPOS DESC
```

### T184L — Determinacion cat. posicion entrega

```sql
SELECT * FROM T184L
WHERE LFART = '{tipo_entrega}'
AND MTPOS = '{grupo_cat_mat}'
```

---

## Categorias de Posicion de Entrega (TVLV)

| Campo | Descripcion |
|-------|-------------|
| LPOSI | Categoria posicion entrega (TAN, TAB...) |
| LTEXT | Descripcion |
| LGBEL | Relevante contabilizacion |
| PCKPF | Relevante picking |
| HUBEF | Gestion unidades manipulacion |

```sql
SELECT LPOSI, LTEXT, LGBEL, PCKPF
FROM TVLV WHERE SPRAS = 'E'
ORDER BY LPOSI
```

---

## Categorias de Linea de Reparto (T188)

### T188 — Determinacion de categoria de linea de reparto

**Clave:** PSTYV (categ.pos) + DISMM (tipo MRP) + LIFKZ (cat.especial stock) + SOBKZ (pedido especial)

```sql
-- Determinacion de lineas de reparto
SELECT * FROM T188
WHERE PSTYV = '{cat_pos}'
AND DISMM IN ('{mrp_type}', ' ')
ORDER BY PSTYV, DISMM DESC

-- Lineas de reparto configuradas para una categoria de posicion
SELECT T.PSTYV, T.DISMM, T.LIFKZ, T.ETTYP
FROM T188 T
WHERE T.PSTYV = '{cat_pos}'
```

### TVEP (ETTYP) — Config linea de reparto
```sql
-- Categorias de linea de reparto (ETTYP)
SELECT ETTYP, ETEXT, BPFLK, VLPRS
FROM TVEZ WHERE SPRAS = 'E'
```

---

## Esquemas de Calculo / Pricing (T683S, T685, T682)

### T683S — Determinacion del esquema de calculo

**Clave:** KAPPL (aplicacion) + KALSM (esquema) + KVEWE (uso)

```sql
-- Esquemas de calculo SD activos
SELECT KALSM, KALSMB FROM T683S
WHERE KAPPL = 'V'
GROUP BY KALSM, KALSMB

-- Uso del esquema (OVKK)
SELECT KSP.VKORG, KSP.VTWEG, KSP.SPART, KSP.KDKGR, KSP.KALSM
FROM T683V KSP
WHERE KSP.KAPPL = 'V'
AND KSP.VKORG = '{org_ventas}'
ORDER BY KSP.KDKGR
```

### OVKK (T683V) — Determinacion del esquema por area de ventas

**Clave de determinacion:** Org.ventas + Canal + Division + Proced.precio doc. + Proced.precio cliente (KNVV.KALKS)

```sql
-- Determinacion esquema de calculo (OVKK)
SELECT V.VKORG, V.VTWEG, V.SPART, V.KDKGR, V.KALSM, V.KVEWE
FROM T683V V
WHERE V.KAPPL = 'V'
AND V.VKORG = '{org_ventas}'
AND V.VTWEG = '{canal}'
AND V.SPART IN ('{division}', '  ')
ORDER BY V.SPART DESC, V.KDKGR DESC

-- Procedimiento de precio cliente (campo relevante de KNVV)
SELECT KUNNR, VKORG, VTWEG, SPART, KALKS AS PROC_PRECIO_CLIENTE
FROM KNVV
WHERE KUNNR = '{cliente}' AND VKORG = '{org_ventas}'
```

### T685 — Tipos de condicion

| Campo | Descripcion |
|-------|-------------|
| KSCHL | Clave tipo condicion (PR00, K007, MWST...) |
| KOAID | Clase de condicion (A=precio, B=descuento, C=recargo, D=impuesto) |
| KZBZG | Base de calculo |
| KRECH | Tipo de calculo (A=porcentaje, B=importe fijo, C=cantidad) |
| MANDT | Mandante |

```sql
-- Tipos de condicion SD
SELECT KSCHL, VTEXT, KOAID, KZBZG, KRECH
FROM T685 T JOIN T685T TT ON T.KSCHL = TT.KSCHL
WHERE TT.SPRAS = 'E' AND T.KAPPL = 'V'
ORDER BY T.KSCHL

-- Detalle de un tipo de condicion
SELECT * FROM T685 WHERE KSCHL = '{tipo_cond}' AND KAPPL = 'V'
```

### T682 — Secuencias de acceso

```sql
-- Secuencias de acceso SD
SELECT A.KAPPL, A.KOZGF, A.VTEXT
FROM T682 A JOIN T682T AT ON A.KAPPL = AT.KAPPL AND A.KOZGF = AT.KOZGF
WHERE AT.SPRAS = 'E' AND A.KAPPL = 'V'
ORDER BY A.KOZGF

-- Pasos de una secuencia de acceso
SELECT KOZGF, STEWI, KOTABNR AS TABLA_COND, FEPOS AS CAMPO_CLAVE
FROM T682I
WHERE KAPPL = 'V' AND KOZGF = '{seq_acceso}'
ORDER BY STEWI
```

---

## Puntos de Expedicion (TVST)

| Tabla | Que configura | Transaccion | Query MCP |
|-------|--------------|-------------|-----------|
| TVST | Puntos de expedicion | OVXD | SELECT VSTEL,VTEXT FROM TVST WHERE SPRAS='E' |
| T001W | Asign. punto exp. a centro | OVL2 | SELECT WERKS,VSTEL FROM T001W |

### Determinacion del punto de expedicion
**Clave:** Centro + Condicion expedicion (KZAZU del material) + Condicion carga (TRAGR del material)

```sql
-- Config determinacion punto expedicion
SELECT WERKS, KZAZU AS COND_EXP, TRAGR AS COND_CARGA, VSTEL AS PUNTO_EXP
FROM TVSTZ
WHERE WERKS = '{centro}'

-- Punto expedicion del material (MM02 -> ventas)
SELECT MATNR, WERKS, VSTEL, TRAGR, KZAZU FROM MVKE
WHERE MATNR = '{material}' AND VKORG = '{org_ventas}'
```

---

## Condiciones de Expedicion (VSBED)

```sql
-- Condiciones de expedicion configuradas
SELECT VSBED, VTEXT FROM TVSBT WHERE SPRAS = 'E'

-- Asignacion cliente - condicion expedicion
SELECT KUNNR, VSBED FROM KNVV
WHERE KUNNR = '{cliente}' AND VKORG = '{org_ventas}'
```

---

## Determinacion de Rutas

| Tabla | Que configura | Transaccion |
|-------|--------------|-------------|
| TROD | Rutas definidas | OVR1 |
| TRODT | Textos de rutas | OVR1 |
| TRODF | Determinacion de rutas | OVR2 |

```sql
-- Rutas configuradas
SELECT ROUTE, BEZEI FROM TRODT WHERE SPRAS = 'E'

-- Determinacion de ruta
SELECT ALAND, VSBED, AZONE, LZONE, ROUTE
FROM TRODF
WHERE ALAND = '{pais_partida}'
AND VSBED = '{cond_exp}'
ORDER BY AZONE, LZONE
```

---

## Datos de Cliente (KNVV) — Campos Relevantes para Customizing

KNVV contiene datos de venta del cliente por area de ventas.

| Campo KNVV | Descripcion | Customizing relacionado |
|------------|-------------|------------------------|
| KDGRP | Grupo de clientes | T151 — grupos de clientes |
| KALKS | Proced. precio cliente | T683V OVKK — esquema calculo |
| VERSG | Grupo estadistica | Para SIS reporting |
| KTGRD | Grupo deter. cuentas | T681A — determinacion revenue account |
| VSBED | Condicion expedicion | TVSBT — puntos expedicion |
| WAERS | Moneda del cliente | |
| ZTERM | Condiciones de pago | T052 |
| INCO1 | Incoterms (parte 1) | T052T |
| INCO2 | Incoterms (parte 2) | |
| KLABC | Clasificacion ABC cliente | |
| LPRIO | Prioridad entrega | |
| PLTYP | Tipo plan entregas | |
| MEGRU | Grupo unidad medida | |
| KVGR1-5 | Grupos estadistica cliente 1-5 | Para determinacion condiciones |

```sql
-- Datos ventas de un cliente por area de ventas
SELECT KUNNR, VKORG, VTWEG, SPART,
       KDGRP, KALKS, KTGRD, VSBED,
       ZTERM, INCO1, WAERS, KVGR1, KVGR2
FROM KNVV
WHERE KUNNR = '{cliente}'
AND VKORG = '{org_ventas}'

-- Clientes por grupo de clientes
SELECT K.KUNNR, KA.NAME1, K.KDGRP, K.KALKS, K.KTGRD
FROM KNVV K JOIN KNA1 KA ON K.KUNNR = KA.KUNNR
WHERE K.KDGRP = '{grupo}' AND K.VKORG = '{org}'
ORDER BY K.KUNNR
```

---

## Motivos de Pedido (TVSB)

```sql
-- Motivos de pedido configurados
SELECT AUGRU, BEZEI FROM TVSBT WHERE SPRAS = 'E'

-- Pedidos por motivo
SELECT VBELN, AUART, AUGRU FROM VBAK WHERE AUGRU = '{motivo}'
```

---

## Categoria de Documento de Ventas (TVSA)

```sql
-- Categorias de documento de ventas
SELECT AUTYP, BEZEI FROM TVSAT WHERE SPRAS = 'E'
-- 0=Pedido, 1=Oferta, 2=Solicitud oferta, 3=Contrato, 4=Plan entregas, 5=Pedido devolucion...
```

---

## Grupos de Material (MARA / MVke relevante)

| Campo | Tabla | Descripcion | Customizing |
|-------|-------|-------------|-------------|
| MTPOS_MARA | MARA | Grupo categ.material | Usado en T184 det.cat.pos |
| MVGR1-5 | MVKE | Grupos estadistica material 1-5 | Para condiciones precio |
| KONDM | MVKE | Grupo condicion material | Para pricing |
| TRAGR | MVKE | Grupo condicion transporte | Para det. punto exp. |
| KZAZU | MVKE | Condicion de expedicion | Para det. punto exp. |

```sql
-- Grupos estadistica de material para condiciones
SELECT MATNR, VKORG, VTWEG, KONDM, MVGR1, MVGR2, TRAGR, KZAZU
FROM MVKE
WHERE MATNR = '{material}' AND VKORG = '{org_ventas}'
```

---

## Resumen: Tabla de Determinaciones en SD

| Que se determina | Tablas clave | Transaccion config |
|-----------------|--------------|-------------------|
| Categoria posicion | T184 | VOV4 |
| Cat. posicion entrega | T184L | OVLP |
| Linea de reparto | T188 | VOV6 |
| Punto de expedicion | TVSTZ | OVL2 |
| Ruta | TRODF | OVR2 |
| Esquema calculo precio | T683V | OVKK |
| Grupo deter. cuentas | KOFI (tabla condicion) | VKOA |
| Partner (interlocutores) | TPAUM | VOPA |

```sql
-- Verificacion global de config por tipo de pedido
SELECT AK.AUART, AK.AUTYP, AK.KALSM, AK.NUMKI, AK.FAKSP
FROM TVAK AK WHERE AK.AUART = '{tipo}'
UNION ALL
SELECT 'T184_ENTRIES' AS INFO, COUNT(*) AS CNT, ' ',' ',' '
FROM T184 WHERE AUTYP = (SELECT AUTYP FROM TVAK WHERE AUART = '{tipo}')
```
