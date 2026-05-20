# Copy Control (Control de Copia)

## Concepto

Copy control define COMO se copian datos de un documento a otro en el flujo OTC.
Controla que campos se copian, que se recalculan, y que verificaciones se hacen.

```
Oferta (QT) → Pedido (OR) → Entrega (LF) → Factura (F2)
     VTAA          VTLA           VTFL          VTFF
  (doc→doc)     (doc→delivery)  (delivery→billing)
```

## Transacciones de Copy Control

| TCode | Flujo | Descripcion |
|-------|-------|-------------|
| VTAA | Sales doc → Sales doc | Oferta→Pedido, Pedido→Pedido |
| VTLA | Sales doc → Delivery | Pedido→Entrega |
| VTFL | Delivery → Billing | Entrega→Factura |
| VTFF | Sales doc → Billing | Pedido→Factura (sin entrega) |
| VTAF | Billing → Sales doc | Factura→Nota credito/debito |
| VTFA | Sales doc → Sales doc | Pedido→Devolucion |

## VTAA — Sales Doc → Sales Doc

```
Ejemplo: Oferta QT → Pedido OR

Header level:
  - Target: OR (pedido estandar)
  - Source: QT (oferta)
  - Copying requirements: rutina 001 (check validez oferta)
  - Data transfer routine: rutina 001 (copiar datos header)
  - Pricing: B (copiar pricing) o G (re-determinar)

Item level:
  - Target item category: TAN
  - Source item category: AGN (oferta normal)
  - Copy quantity: A (completa) o B (parcial)
  - Pricing: B (copiar)
```

## VTLA — Sales Doc → Delivery

```
Ejemplo: Pedido OR → Entrega LF

Header level:
  - Target: LF (entrega estandar)
  - Source: OR (pedido)
  - Delivery type determination
  - Check: verificar bloqueo entrega

Item level:
  - Target item category: DLN (delivery item normal)
  - Source: TAN (sales order item normal)
  - Quantity: copiar cantidad del pedido
  - Verificar ATP en entrega
```

## VTFL — Delivery → Billing

```
Ejemplo: Entrega LF → Factura F2

Header level:
  - Target: F2 (factura)
  - Source: LF (entrega)
  - Billing type determination

Item level:
  - Target: Billing item
  - Source: DLN (delivery item)
  - Pricing: D (re-determinar desde condiciones de pedido original)
  - Quantity: LFIMG (cantidad entregada)
  - Invoice split criteria

FKREL (billing relevance):
  A: Billing relevant — delivery related (usa VTFL)
  B: Billing relevant — order related (usa VTFF, sin entrega)
  C: Not billing relevant
  D: Billing relevant — pro-forma
  F: Order-related billing (servicio, sin entrega)
  G: Delivery-related, proportional to GI qty
```

## Invoice Split (Division de facturas)

```
Una entrega puede generar multiples facturas si los criterios de split difieren:

Criterios de split tipicos (configurables):
  - Payer (RG) diferente
  - Condicion de pago diferente
  - Incoterms diferentes
  - Fecha facturacion diferente
  - Moneda diferente

Config: SPRO → SD → Billing → Invoice Split →
  Assign Copy Control (criterios en VTFL/VTFF)

Ejemplo: Pedido con 3 posiciones, 2 payers distintos
  → 2 facturas separadas
```

## Rutinas de Copy Control

### Copying Requirements (condiciones previas)
```
Verifican si la copia es permitida antes de ejecutar:

Rutina 001: Check reference (oferta vigente)
Rutina 002: Check header data complete
Rutina 003: Check delivery complete
Rutina 301: Billing block check
Custom: VOFM → Requirements → crear rutina Z

Si la rutina devuelve FALSE → no se copia (error)
```

### Data Transfer Routines (rutinas de transferencia)
```
Definen QUE datos se copian y COMO:

Rutina 001: Standard header copy
Rutina 002: Standard item copy
Rutina 011: Billing document header
Custom: VOFM → Data Transfer → crear rutina Z

Ejemplo custom:
  Copiar campo Z del pedido a la factura
  → Crear rutina en VOFM → asignar en VTFL
```

### Pricing in Copy Control
| Opcion | Significado |
|--------|------------|
| A | Copy pricing unchanged |
| B | Copy pricing and redetermine (recheck) |
| C | Re-price completely (nuevo calculo) |
| D | Copy pricing from preceding doc (standard for billing) |
| G | Re-price based on current date (nuevo pricing date) |

## Document Flow (VBFA)

```
Copy control genera registros en VBFA que permiten trazar el flujo:

VBFA campos:
  VBELV: Doc precedente (origen)
  POSNV: Posicion precedente
  VBELN: Doc siguiente (destino)
  POSNN: Posicion siguiente
  VBTYP_N: Tipo doc destino (C=order, J=delivery, M=invoice, etc.)
  RFMNG: Cantidad referenciada
  RFWRT: Valor referenciado

Ejemplo flujo completo:
  QT 20000001 → OR 5000001 → LF 80000001 → F2 90000001
```

## Queries MCP

```sql
-- Flujo completo de un documento
SELECT VBELV, POSNV, VBELN, POSNN, VBTYP_N, RFMNG, RFWRT, ERDAT
FROM VBFA WHERE VBELV = '{doc}'
UNION
SELECT VBELV, POSNV, VBELN, POSNN, VBTYP_N, RFMNG, RFWRT, ERDAT
FROM VBFA WHERE VBELN = '{doc}'
ORDER BY ERDAT

-- Entregas pendientes de facturacion (copy control VTFL)
SELECT LIKP.VBELN, LIKP.KUNNR, LIKP.WADAT_IST
FROM LIKP WHERE LIKP.WBSTK = 'C' AND LIKP.FKSTK <> 'C'

-- Pedidos no referenciados (sin entrega creada)
SELECT VBAK.VBELN, VBAK.AUART, VBAP.POSNR, VBAP.KWMENG
FROM VBAK JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
WHERE VBAP.ABGRU = ''
AND NOT EXISTS (SELECT 1 FROM VBFA WHERE VBFA.VBELV = VBAK.VBELN AND VBFA.VBTYP_N = 'J')
AND VBAK.VKORG = '{org}'
```
