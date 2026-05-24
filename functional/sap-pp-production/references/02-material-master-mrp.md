# Maestro de Materiales — Vistas PP/MRP

## Vistas relevantes para PP

| Vista | Tabla | TCode | Contenido |
|-------|-------|-------|-----------|
| MRP 1 | MARC | MM02 | Tipo MRP, planificador, tamano lote |
| MRP 2 | MARC | MM02 | Tipo aprovisionamiento, GR processing time, safety stock |
| MRP 3 | MARC | MM02 | Estrategia planificacion, horizonte, availability check |
| MRP 4 | MARC | MM02 | Area MRP, BOM explosion, selection method |
| Work Scheduling | MARC | MM02 | Scheduler, in-house production time, setup/interop |
| General Plant | MARC | MM02 | Procurement type, batch management |
| Costing 1 | MBEW | MM02 | Precio estandar, actual costing |

## MARC — Campos MRP criticos

```sql
SELECT MATNR, WERKS, DISMM, DISPO, DISLS, BESKZ, SOBSL,
       PLIFZ, DZEIT, RGEKZ, MAABC, EISBE, MINBE,
       STRGR, VRMOD, VINT1, VINT2,
       SBDKZ, LAGPR, ALTSL, FEESSION, STLAL
FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

### Campos MRP 1

| Campo | Descripcion | Valores tipicos |
|-------|-------------|-----------------|
| DISMM | Tipo MRP | PD, VB, VM, ND, V1, V2 |
| DISPO | Planificador MRP | 001-999 |
| DISLS | Tamano de lote | EX, FX, TB, WB, MB, SP |
| BSTFE | Cantidad fija lote | Numero (si DISLS=FX) |
| BSTMI | Lote minimo | Cantidad |
| BSTMA | Lote maximo | Cantidad |
| BSTRF | Valor redondeo | Cantidad |

### Campos MRP 2

| Campo | Descripcion | Valores tipicos |
|-------|-------------|-----------------|
| BESKZ | Tipo aprovisionamiento | E (in-house), F (external), X (both) |
| SOBSL | Special procurement | 30 (subcontrat), 40 (transfer), 50 (prod otro centro) |
| LGPRO | Production storage location | Almacen GR produccion |
| LGFSB | External procurement SL | Almacen para compras |
| PLIFZ | Planned delivery time | Dias (compras) |
| WEBAZ | GR processing time | Dias |
| EISBE | Safety stock | Cantidad |
| MINBE | Reorder point | Cantidad (para VB/VM) |

### Campos MRP 3

| Campo | Descripcion | Valores tipicos |
|-------|-------------|-----------------|
| STRGR | Strategy group | 10 (MTS-net), 20 (MTO), 40 (MTS-gross) |
| VRMOD | Consumption mode | 1 (backward), 2 (forward), 3 (backward-forward) |
| VINT1 | Backward consumption period | Dias |
| VINT2 | Forward consumption period | Dias |
| MTVFP | Availability check group | 01, 02, KP |

### Campos Work Scheduling

| Campo | Descripcion |
|-------|-------------|
| FEESSION | Production scheduler | Planificador de produccion |
| DZEIT | In-house production time | Dias para fabricacion |
| BEESSION | Setup time | Tiempo preparacion |
| TRESSION | Interoperation time | Tiempo entre operaciones |

## Estrategias de planificacion (Strategy Group - STRGR)

| Estrategia | STRGR | Tipo | Descripcion |
|------------|-------|------|-------------|
| MTS Net Req | 10 | MTS | PIR consumidas por pedidos venta |
| MTS Gross | 11 | MTS | PIR no consumidas |
| MTO | 20 | MTO | Produccion contra pedido venta |
| Planning w/ final assembly | 40 | MTS | PIR + montaje final por pedido |
| Make-to-Order prod | 50 | MTO | Orden prod individual por pedido |
| Planning w/o final assembly | 70 | MTS | Solo componentes planificados |

## MARD — Stock por almacen

```sql
SELECT MATNR, WERKS, LGORT, LABST, INSME, SPEME, UMLME, EINME
FROM MARD
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

| Campo | Descripcion |
|-------|-------------|
| LABST | Stock libre utilizacion |
| INSME | Stock en control calidad |
| SPEME | Stock bloqueado |
| UMLME | Stock en transito (transferencia) |
| EINME | Stock total entrada |

## Consultas MCP diagnostico

```sql
-- Material sin vista MRP (causa error CO 045)
SELECT MATNR, WERKS, DISMM FROM MARC WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- Materiales de un planificador
SELECT MATNR, DISMM, DISLS, BESKZ FROM MARC WHERE WERKS = '{centro}' AND DISPO = '{planif}'

-- Stock total por centro
SELECT MATNR, WERKS, SUM(LABST) AS LIBRE, SUM(INSME) AS QM, SUM(SPEME) AS BLOQ
FROM MARD WHERE WERKS = '{centro}' GROUP BY MATNR, WERKS
```
