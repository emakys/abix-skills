# Facturacion (Billing)

## Proceso

```
Entrega con PGI (o pedido directo)
    |
    +-- Crear factura (VF01 individual / VF04 colectivo)
    |   |
    |   +-- Determinacion tipo factura (copy control)
    |   +-- Pricing re-determinado o copiado (segun config)
    |   +-- Determinacion de cuentas (VKOA)
    |   +-- Release to accounting (FI posting)
    |       D: Cuentas por cobrar (AR) → cliente
    |       C: Ingreso por ventas → cuenta de ingreso
    |       D/C: Impuestos
    |       D/C: Descuentos, fletes, etc.
    |
    +-- Output: impresion/email factura (NACE → V3)
```

## Transacciones principales

| TCode | Accion |
|-------|--------|
| VF01 | Crear factura individual |
| VF02 | Modificar factura |
| VF03 | Visualizar factura |
| VF04 | Facturacion colectiva (worklist) |
| VF11 | Cancelar factura |
| VF21 | Crear invoice list |
| VF26 | Invoice list colectiva |
| VF31 | Output de factura |
| VFX3 | Facturas bloqueadas |
| V.23 | Lista facturas |

## Tipos de factura

| Tipo | Nombre | Referencia | Efecto FI |
|------|--------|-----------|-----------|
| F2 | Factura estandar | Entrega LF | D: AR, C: Revenue |
| F8 | Factura pro-forma | Pedido/Entrega | Sin efecto FI |
| G2 | Nota credito | CR (credit memo req) | D: Revenue, C: AR |
| L2 | Nota debito | DR (debit memo req) | D: AR, C: Revenue |
| RE | Factura devolucion | RE (return) + LR | D: Revenue, C: AR |
| S1 | Cancelacion factura | Factura F2 | Reversa del asiento |
| IV | Intercompany billing | Entrega intercompany | D: Interco AR, C: Interco Revenue |
| LR | Invoice list | Facturas | Agrupa facturas por cliente |
| BV | Cash sale invoice | BV (cash sale) | D: Caja, C: Revenue |

## Tabla VBRK — Cabecera factura
| Campo | Descripcion |
|-------|-------------|
| VBELN | Numero factura |
| FKART | Tipo factura |
| VKORG | Org ventas |
| VTWEG | Canal |
| SPART | Sector |
| KUNRG | Pagador (payer) |
| KUNAG | Solicitante |
| NETWR | Valor neto |
| WAERK | Moneda |
| FKDAT | Fecha factura |
| ERDAT | Fecha creacion |
| FKSTO | Cancelada (X=si) |
| RFBSK | Status contabilizacion (C=contabilizado) |
| KNUMV | Numero condicion (pricing) |
| BELNR | Doc contable generado |
| BUKRS | Sociedad |

## Tabla VBRP — Posiciones factura
| Campo | Descripcion |
|-------|-------------|
| POSNR | Posicion |
| FKIMG | Cantidad facturada |
| NETWR | Valor neto posicion |
| MATNR | Material |
| ARKTX | Texto |
| WERKS | Centro |
| AUBEL | Doc referencia (pedido) |
| VGBEL | Entrega referencia |
| VGPOS | Posicion entrega referencia |
| PRSDT | Fecha pricing |
| KURSK | Tipo cambio |

## Determinacion de cuentas (VKOA)

```
Determina QUE cuentas FI se usan para cada linea de la factura.

Factores:
  Application: V (ventas)
  Condition type: ERL (ingreso), ERS (descuento), etc.
  Chart of accounts (plan cuentas)
  Sales org
  Account key (del esquema de pricing)
  Customer account assignment group (KNVV-KTGRD o KNA1-KTOKD)
  Material account assignment group (MVKE-KTGRM)

Transaccion: VKOA
Config: SPRO → SD → Basic Functions → Account Assignment →
  Revenue Account Determination (OV/RN + VKOA)

Tablas de condicion internas:
  KOFI: tabla condicion con CO-PA activo (Profitability Analysis)
  KOFK: tabla condicion sin CO-PA (solo cuentas GL)
  → SAP usa KOFI si operating concern esta asignado, sino KOFK

Doc FI generado: tipo documento RV (transferencia automatica SD→FI)
```

### Claves de cuenta (Account Keys) tipicas
| AccKey | Descripcion | Cuenta tipica |
|--------|-------------|--------------|
| ERL | Ingresos por ventas | 800000 |
| ERS | Descuentos ventas | 810000 |
| ERF | Flete facturado | 820000 |
| ERB | Rebate provision | 830000 |
| MWS | Impuesto ventas | 175000 |
| ERC | Coste ventas (COGS) | 890000 |
| ERU | Ingresos no realizados | 270000 |

### Asiento contable tipico (factura F2)
```
D: 140000 AR Cuentas por cobrar (cliente)     $1,160
C: 800000 ERL Ingreso por ventas               $1,000
C: 175000 MWS IVA por pagar                      $160
```

### Con COGS (si configurado en esquema pricing)
```
D: 140000 AR cliente                            $1,160
C: 800000 Ingreso ventas                        $1,000
C: 175000 IVA                                     $160
D: 890000 Coste ventas (COGS)                     $600
C: 300000 Stock material                           $600
   (el COGS se registra en PGI, no en factura, excepto config especial)
```

## Queries MCP

```sql
-- Facturas por cliente
SELECT VBRK.VBELN, VBRK.FKART, VBRK.FKDAT, VBRK.NETWR, VBRK.WAERK,
       VBRK.RFBSK, VBRK.FKSTO, VBRK.BELNR
FROM VBRK WHERE VBRK.KUNAG = '{cliente}' AND VBRK.VKORG = '{org}'
AND VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
ORDER BY VBRK.FKDAT DESC

-- Facturas pendientes de contabilizacion
SELECT VBELN, FKART, KUNAG, NETWR, RFBSK FROM VBRK
WHERE RFBSK <> 'C' AND FKSTO = '' AND VKORG = '{org}'

-- Facturas canceladas
SELECT VBELN, FKART, KUNAG, NETWR, FKDAT FROM VBRK
WHERE FKSTO = 'X' AND VKORG = '{org}'

-- Detalle posiciones con material
SELECT VBRP.VBELN, VBRP.POSNR, VBRP.MATNR, VBRP.ARKTX,
       VBRP.FKIMG, VBRP.NETWR, VBRP.AUBEL, VBRP.VGBEL
FROM VBRP WHERE VBRP.VBELN = '{factura}'

-- Doc contable generado por factura
SELECT VBRK.VBELN, VBRK.BELNR, VBRK.BUKRS, VBRK.NETWR
FROM VBRK WHERE VBRK.VBELN = '{factura}'

-- Determinacion cuentas configurada
SELECT KTOPL, VKORG, KTGRD, KTGRM, KVSL1, SAKN1 FROM VKOA
WHERE KTOPL = '{plan_cuentas}' AND VKORG = '{org}'
```

## Errores comunes billing

| Error | Causa | Fix |
|-------|-------|-----|
| VF 052 | Billing block activo | VA02 quitar bloqueo FAKSK |
| VF 058 | Doc already billed | Entrega ya facturada | Verificar VBFA |
| VF 057 | No billing-relevant items | Ningun item es facturable | Revisar FKREL en copy control |
| Account not determined | VKOA incompleto | VKOA asignar cuentas |
| Tax error | Codigo impuesto invalido | FTXP verificar |
| Release to accounting failed | Error en asiento FI | Revisar log (SLG1) |
