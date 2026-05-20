# Pedido de Venta (Sales Order)

## Transacciones principales
| TCode | Accion |
|-------|--------|
| VA01 | Crear pedido venta |
| VA02 | Modificar pedido |
| VA03 | Visualizar pedido |
| VA05 | Lista pedidos |
| VA11 | Crear consulta (inquiry) |
| VA21 | Crear oferta (quotation) |
| VA41 | Crear contrato marco |
| VA42 | Modificar contrato |
| VA45 | Lista contratos |

## Tipos de documento de venta

| Tipo | Nombre | Particularidad |
|------|--------|---------------|
| OR | Pedido estandar | El mas comun, OTC completo |
| SO | Rush Order | Entrega inmediata, factura posterior |
| BV | Cash Sale | Entrega + factura inmediata |
| RE | Return | Devolucion del cliente |
| CR | Credit Memo Request | Solicitud nota credito |
| DR | Debit Memo Request | Solicitud nota debito |
| FD | Free of Charge | Entrega gratuita (muestras) |
| QT | Quotation | Oferta/cotizacion |
| IN | Inquiry | Consulta sin compromiso |
| KM | Quantity Contract | Contrato por cantidad |
| WK1 | Value Contract | Contrato por valor |
| CF | Consignment Fill-up | Llenar stock consignacion |
| CI | Consignment Issue | Venta de consignacion |
| CR2 | Consignment Return | Devolucion consignacion |
| CB | Consignment Pickup | Retiro consignacion |
| TAO | Make-to-Order | Fabricacion bajo pedido |

## Tabla VBAK — Cabecera pedido
| Campo | Descripcion |
|-------|-------------|
| VBELN | Numero pedido |
| AUART | Tipo documento |
| VKORG | Org ventas |
| VTWEG | Canal distribucion |
| SPART | Sector |
| KUNNR | Solicitante (sold-to) |
| KUNAG | Destinatario mercancias (ship-to) |
| NETWR | Valor neto |
| WAERK | Moneda |
| AUDAT | Fecha documento |
| VDATU | Fecha entrega solicitada |
| KNUMV | Numero condicion pricing |
| CMGST | Overall credit status |
| ABSTK | Rejection reason |
| LIFSK | Delivery block |
| FAKSK | Billing block |

## Tabla VBAP — Posiciones
| Campo | Descripcion |
|-------|-------------|
| POSNR | Numero posicion |
| MATNR | Material |
| ARKTX | Texto breve |
| KWMENG | Cantidad pedido |
| VRKME | Unidad venta |
| NETWR | Valor neto posicion |
| NETPR | Precio neto |
| WERKS | Centro suministrador |
| LGORT | Almacen |
| PSTYV | Categoria posicion |
| ABGRU | Motivo rechazo |
| ROUTE | Ruta |
| VSTEL | Puesto expedicion |
| LFMNG | Cantidad entregada |
| FKREL | Relevante para facturacion |

## Tabla VBEP — Repartos (Schedule Lines)
| Campo | Descripcion |
|-------|-------------|
| ETENR | Numero reparto |
| EDATU | Fecha entrega |
| WMENG | Cantidad confirmada |
| BMENG | Cantidad confirmada (ATP) |
| LMENG | Cantidad entregada |
| ETTYP | Categoria reparto |

## Determinaciones automaticas en el pedido

### Item Category Determination (OVLP)
```
Tipo doc venta (AUART)
  + Grupo tipo posicion material (MARA-MTPOS_MARA)
  + Usage (uso) [opcional]
  + Higher-level item category [para sub-items]
  = Categoria posicion (PSTYV)

Ejemplo:
  OR + NORM + ' ' + ' ' = TAN (Normal)
  OR + BANS + ' ' + ' ' = TAO (Make-to-Order)
  RE + NORM + ' ' + ' ' = REN (Return normal)
```

### Schedule Line Category Determination (OVLK)
```
Categoria posicion (PSTYV) + MRP type (MARC-DISMM)
  = Categoria reparto (ETTYP)

Ejemplo:
  TAN + PD = CP (con verificacion disponibilidad + transfer requirement)
  TAN + ND = CN (sin verificacion disponibilidad)
```

### Shipping Point Determination
```
Condicion expedicion (VSBED de KNVV o MVKE)
  + Grupo carga (MARA-LADGR)
  + Centro (WERKS)
  = Puesto expedicion (VSTEL)

Config: SPRO → SD → Shipping → Shipping Point Determination
```

### Route Determination
```
Pais destino + Zona transporte destino
  + Pais origen + Puesto expedicion
  + Grupo transporte (MARA-TRAGR)
  = Ruta (ROUTE)

Config: SPRO → SD → Shipping → Routes → Route Determination
```

## Incompletion Log

```
Verifica que todos los campos obligatorios estan completos antes de grabar.

Config: SPRO → SD → Basic Functions → Log of Incomplete Items →
  Define Incompletion Procedures → Assign to Doc/Item/Schedule/Partner

Grupos de incompletitud:
  - Header: cliente, condicion pago, incoterms
  - Item: material, cantidad, centro, pricing
  - Schedule line: fecha entrega, cantidad
  - Partner: sold-to, ship-to, bill-to, payer

Tablas: V50A (campos incompletos por procedimiento)
```

## Queries MCP para diagnostico

```sql
-- Pedidos abiertos (sin entrega completa)
SELECT VBAK.VBELN, VBAK.AUART, VBAK.KUNNR, VBAK.NETWR, VBAK.WAERK,
       VBAP.POSNR, VBAP.MATNR, VBAP.KWMENG, VBAP.LFMNG,
       (VBAP.KWMENG - VBAP.LFMNG) as PENDIENTE
FROM VBAK JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
WHERE VBAK.VKORG = '{org}' AND VBAP.ABGRU = '' AND VBAP.LFMNG < VBAP.KWMENG
AND VBAK.AUART IN ('OR','SO','BV')

-- Pedidos bloqueados
SELECT VBELN, AUART, KUNNR, NETWR, LIFSK, FAKSK, CMGST
FROM VBAK WHERE VKORG = '{org}'
AND (LIFSK <> '' OR FAKSK <> '' OR CMGST IN ('B','C','D'))

-- Flujo de documento completo
SELECT VBELV, POSNV, VBELN, POSNN, VBTYP_N, RFMNG, RFWRT
FROM VBFA WHERE VBELV = '{pedido}'
ORDER BY ERDAT, ERZET
-- VBTYP_N: C=order, J=delivery, M=invoice, K=credit memo

-- Condiciones de precio de un pedido
SELECT KPOSN, KSCHL, KBETR, KWERT, WAERS, KRECH
FROM KONV WHERE KNUMV = '{knumv_del_pedido}'
ORDER BY KPOSN, STUNR
```
