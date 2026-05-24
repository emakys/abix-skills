# Ordenes de Produccion

## Tablas principales

| Tabla | Descripcion |
|-------|-------------|
| AUFK | Cabecera orden (general, compartida con CO) |
| AFKO | Cabecera orden produccion (datos PP) |
| AFPO | Posiciones orden produccion |
| AFVC | Operaciones orden |
| AFVV | Valores estandar operaciones |
| AFFL | Secuencias orden |
| RESB | Reservas (componentes) |
| JEST | Status orden |
| JSTO | Status objeto |

## AFKO — Cabecera orden produccion

```sql
SELECT AUFNR, AUART, PLNBEZ, GAMNG, GMEIN, GSTRP, GLTRP,
       FHESSION, STLBEZ, STLNR, STLAL, PLNNR, PLNAL,
       DESSION, FEESSION, AUFPL, RSNUM
FROM AFKO
WHERE AUFNR = '{orden}'
```

| Campo | Descripcion |
|-------|-------------|
| AUFNR | Numero orden |
| AUART | Tipo orden (PP01, PP02, PP03) |
| PLNBEZ | Material a fabricar |
| GAMNG | Cantidad orden |
| GMEIN | Unidad medida |
| GSTRP | Fecha inicio programada |
| GLTRP | Fecha fin programada |
| STLNR | Numero BOM |
| STLAL | Alternativa BOM |
| PLNNR | Numero routing |
| PLNAL | Alternativa routing |
| AUFPL | Numero plan (→ AFVC) |
| RSNUM | Numero reserva (→ RESB) |
| DESSION | Fecha de liberacion |

## AFPO — Posiciones orden

```sql
SELECT AUFNR, POSNR, MATNR, PSMNG, WEMNG, AMESSION, ELIKZ,
       LTRMI, DAESSION, KDAUF, KDPOS
FROM AFPO
WHERE AUFNR = '{orden}'
```

| Campo | Descripcion |
|-------|-------------|
| POSNR | Posicion |
| MATNR | Material producido |
| PSMNG | Cantidad orden |
| WEMNG | Cantidad entregada (GR) |
| AMESSION | Cantidad rechazada |
| ELIKZ | Indicador entrega final |
| KDAUF | Pedido venta (MTO) |
| KDPOS | Posicion pedido venta |

## AFVC — Operaciones orden

```sql
SELECT AUFNR, VORNR, LTXA1, ARBID, STEUS, ANESSION,
       VGW01, VGW02, VGW03, VGE01, VGE02, VGE03,
       ISMNW01, ISMNW02, ISMNW03, PESSION
FROM AFVC
WHERE AUFPL = '{aufpl}'
ORDER BY VORNR
```

| Campo | Descripcion |
|-------|-------------|
| VORNR | Numero operacion |
| LTXA1 | Texto operacion |
| ARBID | ID puesto trabajo |
| STEUS | Clave control |
| VGW01-06 | Valores estandar (plan) |
| ISMNW01-06 | Valores reales (confirmados) |
| PESSION | Operacion confirmada parcialmente |

## RESB — Reservas (componentes)

```sql
SELECT RSNUM, RSPOS, MATNR, WERKS, LGORT, BDMNG, ENMNG,
       ERFMG, BWART, VORNR, XWAOK, KZEAR, DUMPS
FROM RESB
WHERE AUFNR = '{orden}'
ORDER BY RSPOS
```

| Campo | Descripcion |
|-------|-------------|
| RSPOS | Posicion reserva |
| MATNR | Material componente |
| BDMNG | Cantidad necesaria |
| ENMNG | Cantidad retirada |
| ERFMG | Cantidad entrada (si co-product) |
| BWART | Tipo movimiento (261=GI, 101=GR) |
| VORNR | Operacion asignada |
| XWAOK | Backflush indicator |
| KZEAR | Indicador completamente retirado |

## Status de orden — JEST

```sql
SELECT OBJNR, STAT, INACT FROM JEST
WHERE OBJNR = 'OR{orden}' AND INACT = ''
```

### Status sistema principales

| Status | Codigo | Descripcion |
|--------|--------|-------------|
| CRTD | I0001 | Creada |
| REL | I0002 | Liberada |
| PCNF | I0009 | Parcialmente confirmada |
| CNF | I0010 | Confirmada |
| PDLV | I0045 | Parcialmente entregada |
| DLV | I0046 | Entregada (GR completa) |
| TECO | I0045 | Cierre tecnico |
| CLSD | I0046 | Cerrada (business complete) |
| LKD | I0043 | Bloqueada |

### Flujo de status

```
CRTD → REL → PCNF → CNF → PDLV → DLV → TECO → CLSD
         │              │         │
         └── LKD        └── TECO  └── TECO (directo)
```

## Tipos de orden produccion

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| PP01 | Orden produccion estandar | Fabricacion discreta |
| PP02 | Orden proceso | PP-PI |
| PP03 | Orden reproceso | Rework |
| PP04 | Orden subcontratacion produccion | Operacion externa |
| PP10 | Orden repetitiva | Repetitive manufacturing |

## Creacion de ordenes

### Desde orden previsional (CO40/CO41)
1. MRP genera orden previsional
2. CO40 (individual) o CO41 (colectivo) convierte a orden produccion
3. Copia BOM, routing, datos de la previsional

### Manual (CO01)
1. Indicar material, centro, cantidad, fechas
2. Sistema explota BOM y routing
3. Scheduling calcula fechas operaciones

### Desde pedido venta (MTO)
1. Pedido venta con estrategia 20/50
2. MRP genera orden previsional con referencia KDAUF/KDPOS
3. Conversion a orden produccion mantiene vinculo

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| CO01 | Crear orden produccion |
| CO02 | Modificar orden |
| CO03 | Visualizar orden |
| CO05N | Liberar colectivo |
| CO07 | Crear orden sin material |
| CO08 | Crear orden con referencia |
| CO40 | Convertir previsional (individual) |
| CO41 | Convertir previsional (colectivo) |
| COHV | Mass processing ordenes |
| COOIS | Lista informativa ordenes |

## Consultas MCP diagnostico

```sql
-- Orden y su status
SELECT A.AUFNR, A.AUART, A.PLNBEZ, A.GAMNG, A.GSTRP, A.GLTRP,
       J.STAT
FROM AFKO A
INNER JOIN JEST J ON J.OBJNR = CONCAT('OR', A.AUFNR)
WHERE A.AUFNR = '{orden}' AND J.INACT = ''

-- Componentes pendientes
SELECT RSPOS, MATNR, BDMNG, ENMNG, (BDMNG - ENMNG) AS PENDIENTE
FROM RESB
WHERE AUFNR = '{orden}' AND KZEAR = ''

-- Operaciones con avance
SELECT VORNR, LTXA1, VGW01, VGW02, ISMNW01, ISMNW02
FROM AFVC
WHERE AUFPL = '{aufpl}'
ORDER BY VORNR
```
