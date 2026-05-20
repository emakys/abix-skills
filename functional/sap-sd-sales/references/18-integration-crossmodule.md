# Integracion Cross-Module SD

## SD → FI (Finanzas)

La integracion SD-FI es automatica al liberar una factura a contabilidad (release to accounting). El sistema genera un documento FI de forma sincrona.

### Determinacion de cuentas (VKOA)
- **ERL** — Revenue account (ingresos por ventas)
- **ERS** — Sales deductions (descuentos comerciales)
- **ERF** — Freight revenue (ingresos por flete)
- **MWS** — Tax account (impuestos)
- **KBS** — Account-assigned items (asignacion a cuenta de costos)
- **EVV** — Cash clearing (ventas al contado)

### Asiento tipico factura F2
```
D: 140000  Cuentas por cobrar (AR)      importe total
C: 800000  Revenue (ERL)                base imponible
C: 175000  Tax payable (MWS)            impuesto
C: 810000  Descuentos (ERS)             si aplica
C: 820000  Flete facturado (ERF)        si aplica
```

### Condiciones de pago y vencimiento
- ZTERM en VBKD (pedido) / VBRK (factura) → se copia a partida FI (BSEG-ZTERM)
- El sistema calcula FAEDT (fecha vencimiento) segun terminos
- Dias de descuento por pronto pago se trasladan a BSEG-ZBD1T, BSEG-ZBD2T

### Dunning (F150)
- Usa partidas abiertas en BSID (vista FI de AR)
- Nivel de dunning por cliente: KNKK-MAHNS
- Historial: MHNK

### Tablas clave FI relevantes para SD
| Tabla | Descripcion |
|-------|-------------|
| BKPF | Header documento FI |
| BSEG | Items documento FI (classic) |
| ACDOCA | Universal Journal (S/4HANA) — reemplaza BSEG para totales |
| BSID | Partidas abiertas cliente (AR open items) |
| BSAD | Partidas compensadas cliente (cleared items) |
| VBRK | Header factura SD — campo BELNR enlaza a BKPF |

### Reconciliacion SD-FI
```
VBRK.VBELN (factura SD)
  → VBRK.BELNR (numero doc FI)
    → BKPF.BELNR + BKPF.BUKRS + BKPF.GJAHR
      → BSEG / ACDOCA (items contables)
```

---

## SD → CO (Controlling)

### CO-PA (Profitability Analysis)
Cada factura SD liberada genera automaticamente un registro en CO-PA (tabla CE1xxxx, donde xxxx es el operating concern).

**Caracteristicas (dimensions) tipicamente mapeadas desde SD:**
| Campo SD | Caracteristica CO-PA |
|----------|---------------------|
| KUNNR (sold-to) | KNDNR |
| KUNAG (payer) | KNDNR (segun config) |
| MATNR | ARTNR |
| VKORG | VKORG |
| VTWEG | VTWEG |
| SPART | SPART |
| LAND1 (pais cliente) | LAND1 |
| KDGRP (customer group) | KDGRP |
| MATKL (material group) | MATKL |
| BZIRK (sales district) | BZIRK |

**Valores (value fields) tipicamente mapeados:**
- Ingresos brutos (NETWR)
- Descuentos (condiciones negativas)
- Flete
- COGS (desde PGI, movimiento 601 → precio estandar)

**Transacciones config:**
- KEA0 — Definir operating concern
- KE4I — Asignar campos SD a caracteristicas CO-PA
- KE4U — Asignar condiciones de precio a value fields CO-PA
- KE30 — Reporte CO-PA (drill-down)

### Cost Centers e Internal Orders en SD
- Si un item de pedido tiene asignacion de cuenta (account assignment category), los costos van a centro de costo u orden interna
- VBAP-KNTTP = account assignment category
- VBAP-KOSTL = cost center / VBAP-AUFNR = internal order

---

## SD → MM

### Transfer of Requirements (TOR) — Planificacion de necesidades
Al confirmar un pedido SD, se crea una necesidad en MRP:
- VBEP — Schedule lines del pedido (ETENR, ETTYP, EDATU, BMENG)
- MRP lee VBEP como demanda independiente
- Tipo de necesidad: VS (sales order requirement) en tabla MDTB

### ATP Check (Available-to-Promise)
- Lee stock disponible: MARD (unrestricted), MCHB (batch)
- Considera: stock + entradas planificadas - salidas planificadas
- Resultado: fecha confirmada en VBEP-EDATU, cantidad en VBEP-BMENG
- Checking rule (MTVFP en customizing): define que elementos incluir en ATP

### PGI (Post Goods Issue) → Movimiento de mercancias
- VL02N → Post Goods Issue → genera MATDOC (S/4HANA) / MKPF+MSEG (classic)
- Movimiento 601: entrega a cliente (stock → COGS)
- Movimiento 602: devolucion de entrega (reversal)
- Movimiento 651: devolucion de cliente con inspeccion QM

### STO (Stock Transfer Order)
- Pedido tipo UB entre plantas de la misma sociedad o sociedades distintas
- Usa ambos modulos: SD para entrega, MM para pedido y entrada de mercancias
- Flujo: ME21N (PO) → VL10B (delivery) → VL02N PGI → MIGO GR

### Third-Party (Dropship)
- Item category TAS en pedido SD
- Genera automaticamente purchase requisition (EBAN) via MRP o directo
- Flujo: VA01 → EBAN → ME21N (PO) → MIGO (GR) → VF01 (billing based on GR qty)
- Tablas: VBAP-BSTNK → EBAN-BANFN → EKPO-EBELN

---

## SD → PP (Produccion)

### Make-to-Order (MTO)
- Account assignment category E en item pedido (VBAP-KNTTP = 'E')
- Stock especial por pedido SD (special stock indicator E)
- Pedido SD genera necesidad individual → MRP crea planned order → production order
- Tablas: RESB (reservas PP), AUFK (production orders), COSP/COSS (costos PP)

### Explosion de BOM en pedido
- Si material tiene BOM y estrategia MTO, explosion al crear pedido
- CS15 — Where-used list BOM
- STPO — Items BOM

### ATP con ordenes de produccion
- Checking rule puede incluir: planned orders, production orders, purchase orders
- MRP area permite planificacion granular

---

## SD → WM / EWM

### WM (Warehouse Management)
- Al crear entrega (VL01N), sistema puede crear transfer order en WM (LT0A)
- Staging area ← picking area
- Shipping point → warehouse number (config SPRO)
- Tablas: LTAK (TO header), LTAP (TO items), LGPLA (storage bins)

### EWM (Extended Warehouse Management)
- Entrega SD crea outbound delivery order en EWM
- Warehouse tasks generadas automaticamente
- Pick → Pack → Stage → Load → PGI

---

## SD → QM (Quality Management)

### Certificado de Analisis (COA)
- Adjunto a entrega como output type
- Batch-level quality certificates
- Config: QC21 (certificate profile)

### Quality Notifications desde SD
- Reclamacion de cliente (VA01 con tipo RE) puede generar Q notification
- QM01 — Create quality notification
- Enlace: VBAK-VBELN → QMEL-QMNUM

### Inspeccion en devolucion
- Movimiento 651 (devolucion cliente) puede generar inspection lot QM
- Config: activar inspection type 06 (goods receipt from customer)

---

## SD → TM (Transportation Management)

### Shipment Documents
- VT01N — Crear shipment agrupando entregas
- Freight cost determination automatica
- Route determination: desde → hasta, medio de transporte, Incoterms
- Tablas: VTTK (shipment header), VTTP (shipment items = deliveries)

### Route Determination (SD nativo)
- TVRO — Routes
- Determinacion: shipping point + zone of departure + shipping conditions + zone of destination
- VBAK-ROUTE / LIKP-ROUTE

---

## Queries MCP cross-module

### Documento FI generado por factura SD
```sql
SELECT T1.VBELN, T1.BELNR, T1.BUKRS, T1.GJAHR, T2.BUDAT, T2.XBLNR, T2.WAERS
FROM VBRK AS T1
JOIN BKPF AS T2
  ON T1.BELNR = T2.BELNR
  AND T1.BUKRS = T2.BUKRS
  AND T1.GJAHR = T2.GJAHR
WHERE T1.VBELN = '{factura}'
```

### Items contables de una factura (S/4HANA)
```sql
SELECT BELNR, GJAHR, BUZEI, HKONT, DMBTR, SHKZG, SGTXT, KOSTL, PRCTR
FROM ACDOCA
WHERE RBUKRS = '{bukrs}'
  AND BELNR = '{belnr_fi}'
  AND GJAHR = '{gjahr}'
ORDER BY BUZEI
```

### Partidas abiertas cliente — AR aging
```sql
SELECT KUNNR, BELNR, BUZEI, GJAHR, BLDAT, ZFBDT, DMBTR, WAERS, MWSKZ
FROM BSID
WHERE KUNNR = '{cliente}'
  AND BUKRS = '{sociedad}'
ORDER BY ZFBDT
```

### Movimiento de mercancias del PGI de una entrega
```sql
SELECT VBELN_IM, ZEILE_IM, BWART, MENGE, MEINS, MATNR, WERKS, LGORT,
       MBLNR, MJAHR, ZEILE, WAERS, DMBTR
FROM MATDOC
WHERE VBELN_IM = '{delivery}'
  AND BWART = '601'
```

### Demanda MRP generada por pedido SD (schedule lines)
```sql
SELECT VBELN, POSNR, ETENR, ETTYP, EDATU, BMENG, LMENG, WADAT
FROM VBEP
WHERE VBELN = '{pedido}'
  AND BMENG > LMENG
ORDER BY POSNR, ETENR
```

### Reconciliacion factura SD → documento FI → partidas AR
```sql
SELECT V.VBELN    AS FACTURA_SD,
       V.FKDAT    AS FECHA_FACTURA,
       V.KUNNR    AS CLIENTE,
       V.NETWR    AS IMPORTE_NETO,
       V.BELNR    AS DOC_FI,
       B.BUDAT    AS FECHA_CONTAB,
       S.BUZEI    AS POSICION_FI,
       S.DMBTR    AS IMPORTE,
       S.SHKZG    AS DB_CR,
       S.HKONT    AS CUENTA_GL
FROM VBRK AS V
JOIN BKPF AS B
  ON V.BELNR = B.BELNR AND V.BUKRS = B.BUKRS AND V.GJAHR = B.GJAHR
JOIN BSID AS S
  ON B.BELNR = S.BELNR AND B.BUKRS = S.BUKRS AND B.GJAHR = S.GJAHR
WHERE V.FKDAT BETWEEN '{fecha_ini}' AND '{fecha_fin}'
  AND V.BUKRS = '{bukrs}'
  AND V.FKSTO <> 'X'
ORDER BY V.VBELN, S.BUZEI
```

### Purchase requisitions generadas por pedido SD (third-party)
```sql
SELECT E.BANFN, E.BNFPO, E.MATNR, E.MENGE, E.MEINS, E.AFNAM,
       V.VBELN AS PEDIDO_SD, V.POSNR
FROM EBAN AS E
JOIN VBAP AS V
  ON E.VBELN = V.VBELN AND E.VBELP = V.POSNR
WHERE V.VBELN = '{pedido}'
  AND E.LOEKZ = ''
```

### CO-PA: ingresos y descuentos por cliente (CE1xxxx)
```sql
-- Sustituir CE1{OC} con el operating concern real, ej: CE1IDEA
SELECT KNDNR, ARTNR, VKORG, SUM(VV010) AS REVENUE, SUM(VV020) AS DISCOUNT
FROM CE1{OC}
WHERE GJAHR = '{anio}'
  AND PERDE = '{periodo}'
GROUP BY KNDNR, ARTNR, VKORG
ORDER BY SUM(VV010) DESC
```

### Inventario disponible para ATP
```sql
SELECT MATNR, WERKS, LGORT, LABST, EINME, SPEME, UMLME
FROM MARD
WHERE MATNR = '{material}'
  AND WERKS = '{planta}'
  AND LGORT <> ''
```

### Shipments que contienen una entrega
```sql
SELECT T1.TKNUM, T1.TRAID, T1.VSTEL, T1.ROUTE, T1.TDLNR,
       T2.VBELN AS ENTREGA
FROM VTTK AS T1
JOIN VTTP AS T2 ON T1.TKNUM = T2.TKNUM
WHERE T2.VBELN = '{entrega}'
```

---

## Mapeo de campos clave entre modulos

| Campo SD | Tabla SD | Tabla FI/CO | Campo FI/CO | Descripcion |
|----------|----------|-------------|-------------|-------------|
| VBELN (billing) | VBRK | BKPF | XBLNR | Referencia doc FI |
| BELNR | VBRK | BKPF | BELNR | Numero doc contable |
| KUNNR | VBRK | BSID | KUNNR | Cliente en AR |
| NETWR | VBRK | ACDOCA | DMBTR | Importe neto |
| FKDAT | VBRK | BKPF | BUDAT | Fecha contabilizacion |
| ZTERM | VBRK | BSEG | ZTERM | Condicion de pago |
| MATNR | VBAP | MATDOC | MATNR | Material en GI |
| VBELN (delivery) | LIKP | MATDOC | VBELN_IM | Entrega en doc material |

---

## Flujo end-to-end con modulos involucrados

```
VA01 Pedido SD
  |
  ├── MM: ATP check (MARD, MCHB)
  ├── MM: Transfer of Requirements → VBEP → MRP
  ├── PP: Planned order (si MTO)
  |
VL01N Entrega
  |
  ├── WM/EWM: Transfer order (picking)
  ├── QM: Inspection lot (si configurado)
  |
VL02N Post Goods Issue
  |
  ├── MM: MATDOC mvt 601 (stock salida)
  ├── CO: COGS posting
  |
VF01 Factura
  |
  ├── FI: Documento contable (BKPF/ACDOCA)
  ├── FI: Partida abierta cliente (BSID)
  └── CO-PA: Registro rentabilidad (CE1xxxx)
```
