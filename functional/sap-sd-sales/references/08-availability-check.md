# Verificacion de Disponibilidad (ATP)

## Concepto

ATP (Available-to-Promise) verifica si hay stock suficiente para confirmar
la cantidad y fecha de entrega solicitada por el cliente.

```
Cliente pide 100 piezas para el 15/06
    |
    +-- ATP verifica:
    |   Stock actual: 80
    |   PO pendiente GR 10/06: +50
    |   Otros pedidos confirmados: -30
    |   = Disponible al 15/06: 100 ✓
    |
    +-- Resultado:
        Confirmado: 100 pzas para 15/06
        O parcial: 80 pzas para 05/06, 20 pzas para 12/06
```

## Tipos de verificacion

| Tipo | Nombre | Que considera |
|------|--------|---------------|
| 01 | Individual customer order | Solo stock + entradas planificadas |
| 02 | With MRP check | Stock + MRP (planned orders, POs, prod orders) |
| KP | No check | Sin verificacion (siempre confirma) |
| A | SD delivery | ATP en entrega |
| B | SD order with replenishment lead time | Con lead time reposicion |

## Configuracion

### Paso 1: Checking Group en material (MARC-MTVFP)
```
MM02 → vista MRP3 o General Plant
  Availability check group: 01 (individual) o 02 (with MRP)

Define el SCOPE del check:
  Que elementos considera (stock, POs, prod orders, reservas, etc.)
```

### Paso 2: Checking Rule por transaccion
```
SPRO → SD → Basic Functions → Availability Check →
  Availability Check with ATP Logic or Against Planning →
  Define Checking Rules (OVZG)

Regla por tipo doc:
  OR (pedido estandar) → checking rule A
  LF (entrega) → checking rule B

Checking rule define:
  - Replenishment lead time check
  - Check scope
  - Includes/excludes
```

### Paso 3: Scope of Check (OVZ2)
```
Checking group (01) + Checking rule (A) → Scope:

  Include/Exclude:
    [X] Stock
    [X] Purchase Orders
    [X] Purchase Requisitions
    [X] Production Orders
    [X] Planned Orders
    [X] Reservations
    [X] Sales Orders (otros pedidos)
    [X] Deliveries
    [ ] Dependent requirements
    [ ] Shipping notifications

  Replenishment lead time: 10 days (si no hay stock, cuantos dias para reponer)
```

### Paso 4: Asignar al tipo de documento de venta
```
SPRO → SD → Basic Functions → Availability Check →
  Availability Check with ATP Logic →
  Define Procedure per Sales Document Type

Tipo doc OR → checking rule A → check activado
Tipo doc BV → checking rule A → check activado
Tipo doc FD → sin check (free of charge)
```

## Resultado del ATP en el pedido

```
VBEP (schedule lines) campos:
  EDATU: Fecha de entrega confirmada
  WMENG: Cantidad pedida
  BMENG: Cantidad confirmada por ATP
  LMENG: Cantidad ya entregada
  ETTYP: Categoria reparto

Si BMENG < WMENG → confirmacion parcial
Si BMENG = 0 → no confirmado (backorder)
```

## Transfer of Requirements (TOR)

```
Cuando se confirma un pedido, ATP crea un "requirement" que:
  - Reserva el stock para este pedido
  - Se ve en MRP como demanda
  - Otros pedidos no pueden usar ese stock

Config: Categoria reparto (ETTYP) determina si genera TOR:
  CP: Con TOR + reserva (normal)
  CN: Sin TOR (sin reserva, sin ATP check)
  BN: Sin TOR (para BV cash sale)
```

## Backorder Processing (V_RA)

```
V_RA: Reasignar stock a pedidos pendientes
SM_V: Seleccion interactiva

Cuando llega nuevo stock:
  1. V_RA selecciona pedidos con BMENG < WMENG
  2. Reasigna stock segun prioridad (fecha, cliente, etc.)
  3. Actualiza confirmaciones (VBEP-BMENG)

Util cuando: stock limitado, multiples pedidos, priorizar clientes VIP
```

## Advanced ATP (AATP) — S/4HANA 2023

```
Funcionalidades adicionales sobre ATP clasico:
  - Multi-plant ATP (buscar stock en otros centros)
  - Product allocation (cuotas por cliente/region)
  - Backorder processing con reglas de prioridad
  - Alternative products (sustitucion automatica)
  - ATP con embedded analytics

Config: SPRO → Production → Advanced ATP
Requiere: aATP add-on activado en S/4HANA
```

## Queries MCP

```sql
-- Stock disponible para ATP
SELECT MATNR, WERKS, LABST, INSME, SPEME FROM MARD
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Pedidos confirmados (demanda)
SELECT VBAK.VBELN, VBAP.POSNR, VBAP.MATNR, VBAP.WERKS,
       VBEP.EDATU, VBEP.WMENG, VBEP.BMENG
FROM VBAK
JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
JOIN VBEP ON VBAP.VBELN = VBEP.VBELN AND VBAP.POSNR = VBEP.POSNR
WHERE VBAP.MATNR = '{material}' AND VBAP.WERKS = '{centro}'
AND VBAP.ABGRU = '' AND VBEP.BMENG > VBEP.LMENG

-- Pedidos no confirmados (backorders)
SELECT VBAK.VBELN, VBAP.MATNR, VBEP.WMENG, VBEP.BMENG
FROM VBAK JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
JOIN VBEP ON VBAP.VBELN = VBEP.VBELN AND VBAP.POSNR = VBEP.POSNR
WHERE VBEP.BMENG < VBEP.WMENG AND VBEP.BMENG > 0
AND VBAP.WERKS = '{centro}'

-- Stock + oferta + demanda de un material (situacion completa)
SELECT 'STOCK' as TIPO, LABST as QTY, '' as DOC FROM MARD
WHERE MATNR = '{mat}' AND WERKS = '{centro}'
UNION
SELECT 'PO' as TIPO, MENGE as QTY, EBELN as DOC FROM EKPO
WHERE MATNR = '{mat}' AND WERKS = '{centro}' AND ELIKZ = ''
UNION
SELECT 'SO' as TIPO, BMENG as QTY, VBELN as DOC FROM VBEP
JOIN VBAP ON VBEP.VBELN = VBAP.VBELN AND VBEP.POSNR = VBAP.POSNR
WHERE VBAP.MATNR = '{mat}' AND VBAP.WERKS = '{centro}' AND BMENG > LMENG
```

## Errores comunes ATP

| Error | Causa | Fix |
|-------|-------|-----|
| Not confirmed (BMENG=0) | Sin stock | Verificar stock, crear PO |
| Partial confirmation | Stock insuficiente | Confirmar parcial o esperar |
| No ATP check | Checking group vacio | MM02 → MRP3 asignar |
| Schedule line not created | Categoria reparto no determinada | OVLK config |
