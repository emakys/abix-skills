# Contabilizaciones Automaticas FI

## Resumen

Las contabilizaciones automaticas en SAP FI permiten que el sistema determine automaticamente las cuentas de mayor para operaciones recurrentes: integracion MM-FI (OBYC), impuestos, descuentos por pronto pago, diferencias de tipo de cambio y diferencias de pago (OB40). La logica se basa en reglas de determinacion de cuentas configuradas en tablas T030*.

---

## OBYC — Claves de Operacion para Integracion MM-FI

### Claves Principales

| Clave | Descripcion | Cuenta Tipica | Uso |
|-------|-------------|---------------|-----|
| BSX | Contabilizacion de stock | Cuenta de existencias | Entrada de mercancias a precio medio movil (MAP) |
| WRX | Compensacion GR/IR | Cuenta puente GR/IR | Contrapartida en entrada de mercancias vs factura |
| GBB | Cuenta de contrapartida | Varias (por modificador) | Contrapartida general en movimientos de mercancias |
| PRD | Diferencias de precio | Cuenta de diferencias | Desviacion entre precio estandar y precio real |
| KON | Consignacion | Cuenta de consignacion | Stock en consignacion del proveedor |
| FR1 | Liquidacion de fletes 1 | Cuenta de flete | Flete en entrada de mercancias |
| FR2 | Liquidacion de fletes 2 | Cuenta de flete | Flete en verificacion de factura |
| FR3 | Liquidacion de fletes 3 | Cuenta de flete | Provision de flete |
| UPF | Costes de entrega no planificados | Cuenta de gastos | Costes adicionales en entrada de mercancias |
| DIF | Diferencias de inventario | Cuenta de diferencias | Ajustes por inventario fisico |
| AUM | Transferencia entre centros | Cuenta de transferencia | Traspaso de materiales entre centros |
| KBS | Cuenta de compensacion compras | Cuenta de compensacion | Pedidos de compra con imputacion |

### Modificadores de Cuenta en GBB

| Modificador | Descripcion | Escenario |
|-------------|-------------|-----------|
| VAX | Consumo general | Salida de mercancias a consumo |
| VBR | Consumo interno | Consumo para ordenes internas |
| AUA | Liquidacion de ordenes | Entrada por liquidacion de orden de produccion |
| BSA | Contabilizacion inicial | Carga inicial de stock |
| VNG | Desguace | Salida por desguace de material |
| ZOB | Sin pedido de compra | Entrada sin referencia a pedido |
| AUF | Entrega a orden | Consumo para ordenes de fabricacion |

### SPRO Path — OBYC
```
SPRO → Gestion de materiales → Valoracion y asignacion de ctas →
  Determinacion de cuentas → Determinacion de cuentas sin asistente →
  Configurar contabilizacion automatica (OBYC)
```

---

## OB40 — Determinacion de Cuentas para Contabilizaciones Automaticas FI

### Claves de Operacion Principales

| Clave | Descripcion | Ambito |
|-------|-------------|--------|
| MWS | Impuesto soportado/repercutido | Cuentas de IVA |
| SKE | Descuento pronto pago (gasto) | Metodo bruto |
| SKT | Descuento pronto pago (ingreso) | Metodo bruto |
| KDB | Diferencia tipo de cambio realizada | Cobros/pagos en moneda extranjera |
| KDF | Diferencia tipo de cambio no realizada | Valoracion FAGL_FCV |
| ZDI | Diferencia de pago | Diferencias menores en cobros/pagos |
| GS1 | Provision gastos | Provision de gastos periodica |
| ANL | Contabilizacion de activos fijos | Determinacion automatica AA |

### Logica de Determinacion de Cuentas

```
Plan de cuentas + Clave de operacion + Area de valoracion + Modificador de cuenta
                          ↓
                   Tabla T030 / T030R
                          ↓
                   Cuenta de mayor asignada
```

**Prioridad de busqueda:**
1. Plan de cuentas + Clave + Area valoracion + Modificador
2. Plan de cuentas + Clave + Area valoracion
3. Plan de cuentas + Clave

### SPRO Path — OB40
```
SPRO → Gestion financiera → Parametrizaciones basicas de gestion financiera →
  Contabilidad principal → Operaciones empresariales →
  Definir determinacion de ctas p.contab.automaticas (OB40)
```

---

## Metodo Bruto vs Neto — Descuento por Pronto Pago

| Aspecto | Metodo Bruto | Metodo Neto |
|---------|--------------|-------------|
| Registro factura | Importe total | Importe total |
| Cuenta de gasto | Total | Total menos descuento |
| Al pagar con descuento | SKE: gasto descuento / SKT: ingreso | Solo ajuste menor |
| Clave OB40 | SKE, SKT activas | Generalmente no se usan |
| Uso tipico | Alemania, Europa Central | LATAM, USA |

---

## Diferencias de Tipo de Cambio

### Realizadas (KDB) — Al momento del pago/cobro

```sql
-- MCP Query: Diferencias de tipo de cambio realizadas en un periodo
SELECT RLDNR, RBUKRS, RACCT, RHCUR, HSL, KTOPL, BSTAT,
       BUDAT, BELNR, AWTYP
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT IN (SELECT SAESSION FROM T030 WHERE KTOSL = 'KDB')
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND BSTAT = ''
ORDER BY BUDAT DESC
```

### No Realizadas (KDF) — Valoracion de partidas abiertas (FAGL_FCV)

```sql
-- MCP Query: Diferencias de tipo de cambio no realizadas
SELECT RLDNR, RBUKRS, RACCT, RHCUR, HSL, TSL,
       BUDAT, BELNR, BLART
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND BLART = 'SA'
  AND RACCT IN (SELECT SAESSION FROM T030 WHERE KTOSL = 'KDF')
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
ORDER BY BUDAT DESC
```

---

## GR/IR Clearing — Compensacion Entrada Mercancias / Factura

### Cuenta WRX — Flujo

```
Entrada de mercancias (MIGO):
  D: BSX (Stock)          100
  C: WRX (GR/IR Clearing) 100

Factura logistica (MIRO):
  D: WRX (GR/IR Clearing) 100
  C: Proveedor             100

→ Saldo WRX = 0 (compensado)
```

### Reagrupacion de GR/IR (F.19)

```sql
-- MCP Query: Saldo GR/IR pendiente de compensar
SELECT RBUKRS, RACCT, LIFNR, RHCUR,
       SUM(HSL) AS SALDO_HSL,
       COUNT(*) AS NUM_PARTIDAS
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{grir_account}'
  AND BUDAT <= '{key_date}'
GROUP BY RBUKRS, RACCT, LIFNR, RHCUR
HAVING SUM(HSL) <> 0
ORDER BY ABS(SUM(HSL)) DESC
```

### SPRO Path — GR/IR
```
SPRO → Gestion de materiales → Verificacion de facturas logisticas →
  Compensacion GR/IR → Mantener cuentas de compensacion (F.19)
```

---

## Tablas de Configuracion

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T030 | Contabilizaciones automaticas | KTOPL, KTOSL, KOMOK, SAESSION |
| T030R | Reglas de contabilizacion | KTOSL, BWMOD |
| T030K | Determinacion cuentas por area valoracion | BWKEY, KTOSL |
| T030H | Cuentas de contabilizacion automatica (cabecera) | KTOPL, KTOSL |
| T030B | Condiciones de registro | KTOSL, BWMOD, KOMOK |
| T001 | Sociedades | BUKRS, KTOPL |

---

## Consultas de Verificacion

```sql
-- MCP Query: Verificar asignacion de cuenta para clave de operacion
SELECT KTOPL, KTOSL, KOMOK, SAESSION, KOESSION
FROM T030
WHERE KTOPL = '{chart_of_accounts}'
  AND KTOSL = '{transaction_key}'
ORDER BY KOMOK

-- MCP Query: Contabilizaciones automaticas por cuenta en un periodo
SELECT RACCT, BLART, DRCRK, RHCUR,
       SUM(HSL) AS TOTAL_HSL,
       COUNT(*) AS NUM_DOCS
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{gl_account}'
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND BSTAT = ''
GROUP BY RACCT, BLART, DRCRK, RHCUR
ORDER BY BLART
```

---

## Transacciones Relevantes

| Transaccion | Descripcion |
|-------------|-------------|
| OBYC | Contabilizaciones automaticas MM |
| OB40 | Contabilizaciones automaticas FI |
| OMWB | Asignacion de cuentas GR/IR |
| F.19 | Reagrupacion de GR/IR |
| FAGL_FCV | Valoracion en moneda extranjera |
| MR11 | Compensacion GR/IR (mantenimiento) |
| OBYA | Sociedades para consolidacion |

---

## Errores Comunes y Diagnostico

| Error | Causa | Solucion |
|-------|-------|----------|
| Cuenta no encontrada para clave BSX | Falta asignacion en OBYC para clase valoracion | Mantener OBYC con area valoracion y tipo material |
| Diferencia de precio no contabilizada | Cuenta PRD no asignada o material a MAP | Verificar metodo de valoracion del material y OBYC |
| Saldo GR/IR no cuadra | Facturas sin entrada de mercancias | Ejecutar F.19 para reagrupacion |
| Contabilizacion automatica sin cuenta | Modificador de cuenta no configurado | Verificar T030 con el modificador correcto |
| Error en descuento por pronto pago | Cuentas SKE/SKT no asignadas en OB40 | Mantener OB40 con las claves correspondientes |
