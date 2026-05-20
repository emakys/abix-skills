# Escenarios Especiales SD — End-to-End

## 1. Third-Party Processing (Venta a Terceros)

### Concepto
El cliente hace el pedido a nuestra empresa, pero el proveedor envía directamente al cliente. Nosotros hacemos de intermediario comercial sin tocar la mercancía físicamente.

### Flujo de documentos

```
VA01 (OR / item cat TAS)
  └─> Requisicion de compra (PR) automatica en MM (BANF)
        └─> ME21N / ME59N: Pedido de compra (PO)
              └─> MIGO: Confirmacion de recepcion (estadística / sin movimiento físico)
                    └─> MIRO: Factura proveedor (LIV)
                          └─> VF01: Factura al cliente (F2)

Nota: NO hay entrega SD propia. NO hay GI propio.
```

### Categorias de posicion y lineas de reparto

```
Item category TAS:
  PSTYP = 5  (Third-party)
  Billing relevance: A (basado en GR del proveedor)
  Create PO automatically: X

Schedule line category CS:
  Movement type: — (sin movimiento)
  Purchase order type: NB
  Item category MM: 5 (third-party)

Config SPRO:
  SD → Ventas → Posiciones → Determinar categorias de posicion
    OR + BANS (grupo cat pos terceros) → TAS
  SD → Ventas → Posiciones → Lineas de reparto → Determinar cat linea reparto
    TAS + MRP = CS
```

### Determinacion de precio / costo

```
En factura F2:
  KBETR (precio al cliente) = precio de lista SD
  Costo = precio del proveedor (desde PO)
  Margen = precio SD - precio proveedor

La PR generada lleva el precio del proveedor desde INFO record (MM).
El precio del cliente viene del condition type PR00 en SD.
```

### Tablas relevantes

| Tabla | Descripcion | Campos clave |
|-------|-------------|-------------|
| VBAK | Pedido de ventas OR | AUART='OR', VBELN |
| VBAP | Posicion TAS | PSTYP='5', BANFN (numero PR) |
| EBAN | Requisicion de compra | BANFN, BNFPO, VBELN (pedido SD) |
| EKKO | Cabecera PO | EBELN, BSART='NB' |
| EKPO | Posicion PO | EBELN, EBELP, VBELN (pedido SD), EDRSP |
| MKPF/MSEG | Doc material (GR estadistico) | BWART sin movimiento real |
| RBKP/RSEG | Factura proveedor (LIV) | BELNR, EBELN (referencia PO) |
| VBRK/VBRP | Factura cliente | FKART='F2' |

### Queries MCP — Third-Party

```sql
-- Pedidos third-party sin factura de proveedor
SELECT
  VBAK.VBELN AS PEDIDO_SD,
  VBAP.POSNR,
  VBAP.MATNR,
  VBAP.KWMENG AS CANTIDAD,
  EKKO.EBELN AS PEDIDO_COMPRA,
  EKPO.EBELP,
  EKPO.NETPR AS PRECIO_PROVEEDOR
FROM VBAK
  INNER JOIN VBAP ON VBAP.VBELN = VBAK.VBELN AND VBAP.PSTYP = '5'
  INNER JOIN EBAN ON EBAN.VBELN = VBAK.VBELN
  INNER JOIN EKPO ON EKPO.BANFN = EBAN.BANFN
  INNER JOIN EKKO ON EKKO.EBELN = EKPO.EBELN
WHERE
  VBAK.VKORG = '{org}'
  AND NOT EXISTS (
    SELECT 1 FROM RSEG WHERE RSEG.EBELN = EKKO.EBELN
  )

-- Facturacion pendiente de pedidos TAS (GR confirmado pero no facturado a cliente)
SELECT
  VBAK.VBELN, VBAP.POSNR, VBAP.MATNR, VBAP.KWMENG, VBAK.KUNNR
FROM VBAK
  INNER JOIN VBAP ON VBAP.VBELN = VBAK.VBELN AND VBAP.FKREL = 'A'
WHERE
  VBAK.AUART = 'OR'
  AND NOT EXISTS (SELECT 1 FROM VBFA WHERE VBFA.VBELV = VBAK.VBELN AND VBFA.VBTYP_N = 'M')
```

### Errores comunes

```
"No purchase requisition generated": verificar config item cat TAS, campo EBSTK
"GR quantity mismatch": MIGO GR estadistico debe coincidir con cantidad PO
"Billing blocked - no GR": tipo factura F2 con relevancia GR requiere MIGO previo
```

---

## 2. Individual Purchase Order (TAB)

### Concepto
Similar a third-party pero la mercancía llega a nuestro almacén primero y luego hacemos la entrega SD al cliente. El stock queda asignado al pedido de ventas.

### Flujo de documentos

```
VA01 (OR / item cat TAB)
  └─> PR automatica (igual que TAS)
        └─> ME21N: PO con categoria posicion S (sales order stock)
              └─> MIGO: GR a stock de pedido de ventas (mvt 101 + stock E)
                    └─> VL01N: Entrega SD (del stock asignado)
                          └─> VL02N: GI (mvt 601 desde stock E)
                                └─> VF01: Factura F2

Stock especial: E (ventas → orden de ventas)
```

### Diferencia clave vs TAS

```
TAS: proveedor → cliente directo (sin entrega SD)
TAB: proveedor → nuestro almacen → cliente (CON entrega SD)

TAB tiene:
  PSTYP = 0 (estandar, con entrega)
  Requiere GR a stock de pedido → MARD-BWART 101 con KZEAR/VBELN
  Entrega referencia al stock E del pedido de ventas
```

### Config

```
Item category TAB:
  PSTYP = 0 (estandar con entrega)
  Billing relevance: A (basado en GI)
  Create PO automatically: X
  Special stock indicator: E

Schedule line category CB:
  Movement type: 601 (GI a cliente)
  Account assignment: E (ventas)
```

---

## 3. Consignment (Consignacion en cliente)

### Concepto
Enviamos stock a las instalaciones del cliente pero el stock sigue siendo nuestro hasta que el cliente lo consume. Hay 4 procesos separados.

### Los 4 procesos de consignacion

```
FILL-UP (KB → KBN):
  Enviamos stock a consignacion del cliente
  Doc type: KB (Konsignationsauffuellung)
  Delivery type: LKB
  GI movement: 631 (a stock consignacion W)
  SIN factura (el cliente no debe nada aun)

ISSUE (KE → KEN):
  Cliente notifica que consumio X unidades
  Doc type: KE (Konsignationsentnahme)
  SIN entrega (el stock ya esta en cliente)
  GI movement: 633 (consumo de stock W)
  Genera factura F2 (el cliente ahora debe el valor)

RETURN (KR → KRN):
  Cliente devuelve stock de consignacion (sin haber consumido)
  Doc type: KR (Konsignationsruecklieferung)
  Delivery type: LKR
  GI movement: 634 (devolucion stock W a stock libre)
  SIN factura (no habia factura previa por este stock)

PICKUP (KA → KAN):
  Nosotros retiramos stock de consignacion del cliente
  Doc type: KA (Konsignationsabholung)
  Delivery type: LKA
  GI movement: 632 (retiro stock W a stock libre)
  SIN factura
```

### Stock especial W (consignacion en cliente)

```
MARD no aplica para stock W
Stock especial W en tabla MSKU:
  MATNR  Material
  WERKS  Centro
  LGORT  Almacen
  KUNNR  Cliente (especial)
  LABST  Stock libre (consignacion)

Vista: MB52 con stock especial W
O directo: MSKU WHERE SOBKZ = 'W' AND KUNNR = '{cliente}'
```

### Flujo contable consignacion

```
Fill-up (631): Stock propio → Stock W (sin cambio en P&L, solo reclasificacion balance)
  D: Inventario consignacion (cta especial)
  C: Inventario propio

Issue (633): Stock W → Consumo cliente → Factura
  D: Costo ventas
  C: Inventario consignacion
  D: AR cliente
  C: Ingresos por ventas

Return (634): Inversa del fill-up (sin P&L)
Pickup (632): Inversa del fill-up (sin P&L)
```

### Tablas relevantes

| Tabla | Descripcion |
|-------|-------------|
| MSKU | Stock especial por cliente (stock W) |
| MARD | Stock almacen (stock propio, no W) |
| VBAK | Pedidos KB/KE/KR/KA |
| LIKP | Entregas consignacion (LKB/LKR/LKA) |
| MSEG | Documentos de movimiento (631/632/633/634) |

### Queries MCP — Consignacion

```sql
-- Stock de consignacion por cliente y material
SELECT
  MSKU.KUNNR,
  KNA1.NAME1,
  MSKU.MATNR,
  MARA.MAKTX,
  MSKU.WERKS,
  MSKU.LABST AS STOCK_CONSIGNACION,
  MSKU.EINME AS UNIDAD
FROM MSKU
  INNER JOIN KNA1 ON KNA1.KUNNR = MSKU.KUNNR
  INNER JOIN MARA ON MARA.MATNR = MSKU.MATNR
WHERE
  MSKU.SOBKZ = 'W'
  AND MSKU.LABST > 0
  AND MSKU.WERKS = '{centro}'
ORDER BY MSKU.KUNNR, MSKU.MATNR

-- Movimientos de consignacion por periodo
SELECT
  MSEG.MBLNR, MSEG.ZEILE, MSEG.BWART,
  CASE MSEG.BWART
    WHEN '631' THEN 'Fill-up'
    WHEN '632' THEN 'Pickup'
    WHEN '633' THEN 'Issue (facturado)'
    WHEN '634' THEN 'Return'
  END AS TIPO_MOVIMIENTO,
  MSEG.MATNR, MSEG.MENGE, MSEG.MEINS,
  MSEG.KUNNR AS CLIENTE_CONSIG,
  MKPF.BUDAT
FROM MSEG
  INNER JOIN MKPF ON MKPF.MBLNR = MSEG.MBLNR AND MKPF.MJAHR = MSEG.MJAHR
WHERE
  MSEG.BWART IN ('631','632','633','634')
  AND MSEG.WERKS = '{centro}'
  AND MKPF.BUDAT BETWEEN '{desde}' AND '{hasta}'
ORDER BY MKPF.BUDAT DESC

-- Issues pendientes de facturacion (KE sin factura)
SELECT
  VBAK.VBELN, VBAK.KUNNR, VBAK.ERDAT, VBAP.MATNR, VBAP.KWMENG
FROM VBAK
  INNER JOIN VBAP ON VBAP.VBELN = VBAK.VBELN
WHERE
  VBAK.AUART = 'KE'
  AND NOT EXISTS (
    SELECT 1 FROM VBFA WHERE VBFA.VBELV = VBAK.VBELN AND VBFA.VBTYP_N = 'M'
  )
```

---

## 4. Make-to-Order (MTO) — Fabricacion por Pedido

### Concepto
Cada pedido de cliente genera una orden de producción individual. El stock producido queda asignado exclusivamente a ese pedido (stock especial E). No se puede usar para otro pedido.

### Flujo de documentos

```
VA01 (OR / item cat TAK)
  └─> MRP crea PlOrd (orden planificada) asignada al pedido SD
        └─> CO08 / MD04: Convertir a orden de produccion (PP)
              └─> Produccion → confirmaciones CO11N
                    └─> MIGO: GR a stock E (mvt 101E)
                          └─> VL01N: Entrega (desde stock E)
                                └─> VL02N: GI (mvt 601E desde stock E)
                                      └─> VF01: Factura F2
```

### Config MTO

```
Item category TAK:
  Special stock: E (ventas/pedido)
  Planificacion: individual (no colectiva)
  Requirements type: KE (MTO)

Requirements class (via config):
  ABRUF = E (individual requirements)
  Account assignment category: E

SPRO → SD → Config basica → OVZ9:
  Estrategia planificacion: 20 (MTO sin ensamblaje final)
  o 82 (MTO con ensamblaje final)

MM03 → vista MRP1: Estrategia planificacion = 20 en el material
```

### Stock especial E

```
Stock E (sales order stock) visible en:
  MMBE → pestaña "Ventas" o stock especial
  MB52 → stock especial E

Tabla MSKA:
  MATNR  Material
  WERKS  Centro
  SOBKZ = 'E'  (ventas)
  KDAUF  Pedido de ventas
  KDPOS  Posicion pedido ventas
  LABST  Stock disponible

Disponibilidad ATP: ONLY para ese pedido. Otros pedidos NO pueden usar este stock.
```

### Queries MCP — MTO

```sql
-- Stock MTO por pedido de ventas
SELECT
  MSKA.KDAUF AS PEDIDO_SD,
  MSKA.KDPOS AS POSICION,
  MSKA.MATNR,
  MSKA.WERKS,
  MSKA.LABST AS STOCK_DISPONIBLE,
  MSKA.INSME AS STOCK_CONTROL_CALIDAD,
  VBAK.KUNNR,
  KNA1.NAME1
FROM MSKA
  INNER JOIN VBAK ON VBAK.VBELN = MSKA.KDAUF
  INNER JOIN KNA1 ON KNA1.KUNNR = VBAK.KUNNR
WHERE
  MSKA.SOBKZ = 'E'
  AND MSKA.WERKS = '{centro}'
  AND MSKA.LABST > 0

-- Pedidos MTO con orden produccion asociada
SELECT
  VBAK.VBELN AS PEDIDO_SD,
  VBAP.POSNR,
  VBAP.MATNR,
  AUFK.AUFNR AS ORDEN_PRODUCCION,
  AUFK.GSTRI AS INICIO_REAL,
  AUFK.GETRI AS FIN_PREVISTO,
  AUFK.FTRMI AS FECHA_ENTREGA_PP
FROM VBAK
  INNER JOIN VBAP ON VBAP.VBELN = VBAK.VBELN
  INNER JOIN AUFK ON AUFK.KDAUF = VBAK.VBELN AND AUFK.KDPOS = VBAP.POSNR
WHERE
  VBAK.VKORG = '{org}'
  AND AUFK.AUART = 'PP01'
ORDER BY AUFK.FTRMI ASC
```

---

## 5. Intercompany Sales (Venta Intercompania)

### Concepto
La organización de ventas 1000 vende al cliente, pero la entrega física la hace la planta de la organización de ventas 2000 (diferente sociedad del grupo). Se generan dos facturas: una al cliente y una entre sociedades.

### Flujo de documentos

```
VA01 en Org. Ventas 1000, planta 2000
  └─> VL01N: Entrega desde planta de org 2000
        └─> VL02N: GI (movimiento desde planta 2000)
              ├─> VF01: F2 → Factura al CLIENTE (org ventas 1000)
              │         Booking en sociedad 1000
              └─> VF01: IV → Factura INTERCOMPANY (de org 2000 a org 1000)
                        Booking: soc 2000 debita a soc 1000
```

### Config intercompany

```
SPRO → SD → Facturacion → Facturacion intercompania:
  1. Asignar plantas a org de ventas interna
     Planta 2000 → Org ventas interna 2000
  2. Definir tipo de factura intercompany: IV
  3. Asignar tipo IV a tipo F2 (copy control VTFL)
  4. Cuenta de determinacion: cta ingresos intercompany (diferente a cta externa)

Copy control especial:
  VTFL: Entrega → IV
  Rutina de copia: 014 (intercompany billing)

Pricing intercompany:
  Condition type PI01 (precio intercompany, normalmente costo de transferencia)
  Determination: planta vendedora → org compradora
```

### Tablas relevantes

```
VBRK-FKART = 'F2'  Factura al cliente (soc 1000)
VBRK-FKART = 'IV'  Factura intercompany (soc 2000 → soc 1000)
VBRK-VKORG          Org de ventas de cada factura
BSEG-BUKRS          Sociedad del asiento contable
```

### Queries MCP — Intercompany

```sql
-- Facturas intercompany con su factura de cliente correspondiente
SELECT
  F2.VBELN AS FACTURA_CLIENTE,
  F2.VKORG AS ORG_VENTAS_CLIENTE,
  F2.KUNNR AS CLIENTE,
  F2.NETWR AS VALOR_CLIENTE,
  IV.VBELN AS FACTURA_IC,
  IV.VKORG AS ORG_VENTAS_IC,
  IV.NETWR AS VALOR_IC,
  F2.NETWR - IV.NETWR AS MARGEN_IC
FROM VBRK F2
  INNER JOIN VBFA ON VBFA.VBELV = F2.VBELN AND VBFA.VBTYP_N = 'M'
  INNER JOIN VBRK IV ON IV.VBELN = VBFA.VBELN AND IV.FKART = 'IV'
WHERE
  F2.FKART = 'F2'
  AND F2.VKORG = '{org_vendedora}'
  AND F2.FKDAT BETWEEN '{desde}' AND '{hasta}'
```

---

## 6. Cash Sale (Venta al Contado)

### Concepto
Venta en mostrador o punto de venta. El pedido, la entrega y la factura se crean simultáneamente (o casi). El pago es inmediato.

### Flujo de documentos

```
VA01 → Doc type BV
  └─> Entrega BV creada AUTOMATICAMENTE al grabar
        └─> GI AUTOMATICO
              └─> Factura BV creada AUTOMATICAMENTE
                    └─> Pago inmediato (caja/efectivo)

Todo ocurre en una sola transaccion (o secuencia inmediata).
```

### Config Cash Sale

```
VOV8 → Tipo doc BV (Barverkauf):
  Tipo entrega: BV
  Crear entrega: X (inmediata)
  Tipo factura inmediata: BV
  Interlocutor comercial: cliente de ventas mostrador (one-time customer)
  Bloqueo entrega: ' ' (sin bloqueo)
  Bloqueo facturacion: ' ' (sin bloqueo)

Particularidades:
  - Puede usar cliente generico "mostrador" (KUNNR fijo)
  - Precio se ingresa manualmente o desde condicion
  - No requiere verificacion de credito
  - Documento de pago se crea en FI simultaneamente
```

### Queries MCP — Cash Sales

```sql
SELECT
  VBAK.VBELN, VBAK.ERDAT, VBAK.KUNNR,
  VBAK.NETWR, VBAK.WAERK,
  VBRK.VBELN AS FACTURA, VBRK.NETWR AS VALOR_FACTURADO
FROM VBAK
  LEFT JOIN VBFA ON VBFA.VBELV = VBAK.VBELN AND VBFA.VBTYP_N = 'M'
  LEFT JOIN VBRK ON VBRK.VBELN = VBFA.VBELN
WHERE VBAK.AUART = 'BV'
  AND VBAK.ERDAT BETWEEN '{desde}' AND '{hasta}'
ORDER BY VBAK.ERDAT DESC
```

---

## 7. Rush Order (Pedido Urgente)

### Concepto
Como un pedido estándar, pero la entrega se crea inmediatamente al grabar el pedido. La factura se emite después (diferencia con Cash Sale donde la factura también es inmediata).

### Flujo de documentos

```
VA01 → Doc type SO (Schnellauftrag)
  └─> Entrega creada AUTOMATICAMENTE al grabar
        └─> VL02N: GI manual (cuando se envía)
              └─> VF01: Factura posterior (como pedido estandar)
```

### Config Rush Order

```
VOV8 → Tipo doc SO:
  Tipo entrega: LF (estandar)
  Crear entrega: X (inmediata al grabar pedido)
  Tipo factura: F2 (estandar, posterior al GI)
  Verificacion disponibilidad: inmediata
  Bloqueo facturacion: ' ' (sin bloqueo)

Diferencia BV vs SO:
  BV: entrega + GI + factura inmediatos (mostrador)
  SO: entrega inmediata, pero GI y factura posteriores (urgente pero envio diferido)
```

---

## 8. Free of Charge Delivery (Envio Gratuito)

### Concepto
Envío de mercancía sin cargo al cliente. Usado para muestras, reposiciones por garantía, o promociones. Genera movimiento de stock (GI mvt 601) pero NO genera revenue.

### Flujo de documentos

```
VA01 → Doc type FD (Free of Charge)
  └─> VL01N: Entrega FD
        └─> VL02N: GI mvt 601 (impacto en stock e inventario)
              └─> Sin factura (billing relevance = C / no billing)

Impacto contable:
  D: Costo mercancia vendida (muestra/regalo)
  C: Inventario
  Sin asiento de revenue (KUNNR no debe nada)
```

### Config Free of Charge

```
VOV8 → Tipo doc FD:
  Relevancia de facturacion: ' ' (sin factura)
  o Item cat TANN con FKREL = ' '

Item category TANN:
  Billing relevance: C (no billing)
  Precio: ' ' (sin precio o precio cero)
  Disponibilidad: verificada

Casos de uso tipicos:
  - TANN: Free of charge (sin precio, sin factura)
  - TATX: Text item (solo descripcion, sin logistica)
  - CBCM: Customer consignment (muestra)

Cuenta contable destino: cuenta de muestras/regalos (centro de costo)
Config en VKOA: account determination para FD → cuenta P&L de muestras
```

### Queries MCP — Free of Charge

```sql
-- Envios gratuitos por periodo y cliente (costo por regalos/muestras)
SELECT
  VBAK.VBELN, VBAK.KUNNR, KNA1.NAME1,
  VBAP.MATNR, VBAP.KWMENG,
  MSEG.DMBTR AS COSTO_STOCK,
  MKPF.BUDAT AS FECHA_GI
FROM VBAK
  INNER JOIN VBAP ON VBAP.VBELN = VBAK.VBELN AND VBAP.PSTYP = '0'
  INNER JOIN VBFA ON VBFA.VBELV = VBAK.VBELN AND VBFA.VBTYP_N = 'J'
  INNER JOIN LIKP ON LIKP.VBELN = VBFA.VBELN
  INNER JOIN LIPS ON LIPS.VBELN = LIKP.VBELN
  INNER JOIN VBFA F2 ON F2.VBELV = LIKP.VBELN AND F2.VBTYP_N = '8'
  INNER JOIN MSEG ON MSEG.VBELN = LIKP.VBELN AND MSEG.BWART = '601'
  INNER JOIN MKPF ON MKPF.MBLNR = MSEG.MBLNR
  INNER JOIN KNA1 ON KNA1.KUNNR = VBAK.KUNNR
WHERE VBAK.AUART = 'FD'
  AND MKPF.BUDAT BETWEEN '{desde}' AND '{hasta}'
ORDER BY MKPF.BUDAT DESC
```

---

## 9. Cross-Company Stock Transfer Order (STO Intercompania)

### Concepto
Transferencia de stock entre plantas de distintas sociedades. Involucra un proceso de compra (MM) y un proceso de venta (SD) entre las dos entidades legales.

### Flujo de documentos

```
ME21N → STO (NB/UB) en sociedad compradora, referencia planta suministradora
  └─> VL10B / VL01N: Entrega SD (tipo NL) desde planta suministradora
        └─> VL02N: GI desde planta suministradora (mvt 641 o 643)
              └─> MIGO: GR en planta receptora (mvt 101)
                    └─> VF01: Factura intercompany (IV o ZSTO)
                          └─> MIRO: Verificacion factura en soc compradora
```

### Movimientos de mercancias STO

```
601 → GI planta suministradora a cliente (estandar SD a ext)
641 → GI STO intercompany a transito
643 → GI STO intercompany sin transito (directo)
101 → GR en planta receptora (del transito o directo)
```

### Config STO

```
SPRO → MM → Gestion de compras → Pedido de traslado:
  1. Definir planta suministradora
  2. Asignar org de ventas a planta (para la parte SD)
  3. Tipo de documento: NB (estandar) o UB (traslado entre centros)
  4. Tipo de entrega: NL (Nachlieferung / replenishment)
  5. Tipo de factura: IV o ZSTO (intercompany)

Config SD necesaria:
  - Org de ventas asignada a planta suministradora
  - Copy control para NL → IV
  - Item category TAB o NLCC (segun config)
```

### Queries MCP — STO

```sql
-- STOs pendientes de GR en destino
SELECT
  EKKO.EBELN AS STO,
  EKKO.EKORG AS ORG_COMPRAS,
  EKPO.WERKS AS PLANTA_DESTINO,
  EKPO.MATNR,
  EKPO.MENGE AS CANTIDAD_PEDIDA,
  EKPO.WEMNG AS CANTIDAD_RECIBIDA,
  EKPO.MENGE - EKPO.WEMNG AS PENDIENTE,
  LIKP.VBELN AS ENTREGA_NL,
  LIKP.WBSTK AS ESTADO_GI
FROM EKKO
  INNER JOIN EKPO ON EKPO.EBELN = EKKO.EBELN AND EKPO.ELIKZ = ' '
  LEFT JOIN VBFA ON VBFA.VBELV = EKKO.EBELN AND VBFA.VBTYP_N = 'J'
  LEFT JOIN LIKP ON LIKP.VBELN = VBFA.VBELN AND LIKP.LFART = 'NL'
WHERE
  EKKO.BSART IN ('NB', 'UB')
  AND EKPO.WERKS = '{planta_destino}'
  AND EKPO.MENGE > EKPO.WEMNG
ORDER BY EKKO.BEDAT ASC
```

---

## 10. BOM in Sales (Lista de Materiales en Ventas)

### Concepto
Venta de un producto que tiene una estructura (lista de materiales / BOM). El producto padre (header) se vende y el sistema explota automáticamente sus componentes. El pricing puede estar en el header, en los componentes, o en ambos.

### Flujo de documentos

```
VA01 → Material con BOM (CS01/CS02)
  └─> Sistema explota BOM automaticamente
        Header item: TAQ (Stueckliste-Hauptposition)
        Sub-items:   TAE (Stueckliste-Einzelposition)
              └─> VL01N: Entrega (solo items con entrega relevante)
                    └─> VL02N: GI (solo de componentes reales)
                          └─> VF01: Factura (segun pricing level)
```

### Categorias de posicion BOM

```
TAQ (header BOM):
  Structure scope: B (Einzelpositionen / explode BOM)
  Pricing: X (precio en header, subitems sin precio)
  Delivery relevance: ' ' (no, la entrega va en componentes)
  Billing relevance: ' ' o 'A' segun config

TAE (sub-item BOM):
  Entrega relevante: X
  Pricing: ' ' (precio en header)
  GI relevante: X
  Billing relevance: depende de si precio en comp o header

TAN (alternativa si precio en componentes):
  Permite pricing individual por componente
```

### Tipos de BOM en ventas

```
1. Pricing en HEADER (más común):
   TAQ header: precio total
   TAE componentes: cantidad, entrega, GI (sin precio individual)
   Uso: paquetes con precio fijo, kits

2. Pricing en COMPONENTES:
   TAQ header: solo referencia (sin precio)
   TAN componentes: precio individual por pieza
   Uso: venta de repuestos/accesorios donde cada uno tiene precio

3. Mixto:
   Header con precio base + surcharges en componentes
   Condition types diferentes por nivel
```

### Config BOM in Sales

```
VOV7 → Item category TAQ:
  Structure scope: B (explotar BOM)
  Pricing: X (precio en header)
  Reten factura: ' '

CS01/CS02: Crear BOM de ventas (tipo 5 = ventas)
  Alternativa BOM: 01
  Tipo uso: 5 (SD)
  Componentes: materiales con categoria posicion 0 (estandar)

SPRO → SD → Config basica → Posiciones → BOM:
  Determinar categoria posicion sub-items: TAE
  Explotar BOM en: Creacion pedido (inmediato)

MM03 → vista SD:
  Lista de materiales / Tipo BOM: 5 (para el material padre)
```

### Tablas relevantes BOM

| Tabla | Descripcion | Campos clave |
|-------|-------------|-------------|
| VBAP | Posiciones pedido | UEPOS (posicion superior para TAE) |
| STKO | Cabecera BOM | STLNR, STLAL (alternativa), STLAN=5 |
| STPO | Posiciones BOM | STLNR, POSNR, IDNRK (componente), MENGE |
| STPU | BOM de uso | STLNR → asignacion al material padre |

### Queries MCP — BOM in Sales

```sql
-- Pedidos con BOM explotado (header + componentes)
SELECT
  VBAK.VBELN,
  VBAP_H.POSNR AS POS_HEADER,
  VBAP_H.MATNR AS MATERIAL_PADRE,
  VBAP_H.NETWR AS PRECIO_TOTAL,
  VBAP_C.POSNR AS POS_COMP,
  VBAP_C.MATNR AS COMPONENTE,
  VBAP_C.KWMENG AS CANTIDAD_COMP,
  VBAP_C.PSTYP AS TIPO_POS_COMP
FROM VBAK
  INNER JOIN VBAP VBAP_H ON VBAP_H.VBELN = VBAK.VBELN AND VBAP_H.PSTYP = '0'
  INNER JOIN VBAP VBAP_C ON VBAP_C.VBELN = VBAK.VBELN
    AND VBAP_C.UEPOS = VBAP_H.POSNR
    AND VBAP_C.PSTYP <> VBAP_H.PSTYP
WHERE
  VBAK.VKORG = '{org}'
  AND VBAK.ERDAT BETWEEN '{desde}' AND '{hasta}'
ORDER BY VBAK.VBELN, VBAP_H.POSNR, VBAP_C.POSNR

-- BOM de ventas para un material
SELECT
  STPO.IDNRK AS COMPONENTE,
  MARA.MAKTX AS DESCRIPCION,
  STPO.MENGE,
  STPO.MEINS,
  STPO.POSNR
FROM STKO
  INNER JOIN STPO ON STPO.STLNR = STKO.STLNR AND STPO.STLAL = STKO.STLAL
  INNER JOIN MARA ON MARA.MATNR = STPO.IDNRK
WHERE
  STKO.MATNR = '{material_padre}'
  AND STKO.STLAN = '5'
  AND STKO.STLAL = '01'
  AND STPO.LGKZ = ' '
ORDER BY STPO.POSNR
```

---

## Tabla Resumen — Comparativa de Escenarios Especiales

| Escenario | Doc Type | Item Cat | Entrega SD | GI propio | Factura | Stock especial |
|-----------|----------|----------|-----------|-----------|---------|---------------|
| Third-Party | OR | TAS | NO | NO | F2 (post GR prov) | — |
| Ind. PO | OR | TAB | SI | SI | F2 | E (pedido) |
| Consign. Fill-up | KB | KBN | SI (LKB) | 631 | NO | W (cliente) |
| Consign. Issue | KE | KEN | NO | 633 | F2 | W (cliente) |
| MTO | OR | TAK | SI | SI (601E) | F2 | E (pedido) |
| Intercompany | OR | TAN | SI (intercomp) | 601 | F2 + IV | — |
| Cash Sale | BV | BVN | SI (auto) | SI (auto) | BV (auto) | — |
| Rush Order | SO | TAN | SI (auto) | Manual | F2 (posterior) | — |
| Free of Charge | FD | TANN | SI | 601 | NO | — |
| STO IC | (NB) | — | SI (NL) | 641/643 | IV | Transito |
| BOM | OR | TAQ/TAE | SI (comp) | SI (comp) | F2 (header) | — |

---

## Configuracion SPRO — Rutas criticas por escenario

```
Third-Party / TAB:
  SD → Ventas → Posiciones → Determinar categorias posicion (TAS, TAB)
  SD → Ventas → Posiciones → Lineas reparto → Determinar (CS, CB)

Consignacion:
  SD → Config basica → Datos maestros → Definir tipos doc ventas → KB/KE/KR/KA
  SD → Ventas → Posiciones → Consignacion → item cats KBN/KEN/KRN/KAN

MTO:
  PP → Planif. necesidades → Estrategia planificacion (20/82)
  SD → Ventas → Posiciones → VOV7 → TAK → Special stock E

Intercompany:
  SD → Facturacion → Facturacion intercompania → Asignar plantas a org ventas interna
  SD → Facturacion → Tipos factura → IV (definir)

Cash Sale / Rush Order:
  SD → Ventas → Doc ventas → Cabecera → VOV8 → BV/SO

BOM in Sales:
  SD → Config basica → Posiciones → Lista materiales en ventas
  LO → Lista materiales → Tipos de uso → 5 (SD)
```

---

## Errores comunes por escenario

### Third-Party (TAS)

```
"No PR generated on save": verificar campo BSTNK en item cat TAS y config de creacion PR
"Billing blocked - awaiting GR": normal — VF01 solo disponible tras GR en MIGO
"Info record not found": ME11 para crear info record proveedor/material
```

### Consignacion

```
"Special stock W not available": cliente aun no tiene fill-up previo — primero KB
"GI movement 633 blocked": verificar config movement type en OMJJ para stock W
"Duplicate fill-up": verificar saldo stock W antes de nuevo KB
```

### MTO

```
"Sales order stock not available": PP no ha completado produccion — verificar CO03
"ATP check fails for E stock": normal para MTO, el ATP solo aplica al pedido especifico
"Strategy group mismatch": MM03 estrategia planificacion debe ser 20/82 para generar necesidad E
```

### BOM in Sales

```
"BOM not found for material": CS02 — BOM tipo uso 5 (SD) debe existir y estar activo
"Sub-items not created": verificar VOV7 TAQ → Structure scope = B (no A ni espacio)
"Pricing on components missing": si precio en comps, verificar item cat TAN con pricing activo
"GI partial only": solo los TAE con relevancia entrega generan GI. TAQ nunca genera GI
```
