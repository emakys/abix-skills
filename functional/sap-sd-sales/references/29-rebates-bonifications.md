# Rebates y Bonificaciones SD

## Concepto

Rebates son descuentos retroactivos basados en volumen acumulado durante un periodo.
Se acuerdan con el cliente al inicio del periodo y se liquidan al final.

```
Acuerdo: "Si compras > 1000 pzas en 2024, te damos 5% retroactivo"
    |
    +-- Cada factura acumula volumen (accrual)
    |   Factura 1: 200 pzas → accrual $100
    |   Factura 2: 300 pzas → accrual $150
    |   ...
    |
    +-- Liquidacion parcial o final
        Settlement → Credit memo request → Credit memo (G2)
        Reversa de accrual en FI
```

## Tipos de Acuerdo de Rebate

| Tipo | Descripcion | Base |
|------|-------------|------|
| 0001 | Group rebate | Grupo de materiales |
| 0002 | Material rebate | Material individual |
| 0003 | Customer hierarchy rebate | Jerarquia de clientes |
| 0004 | Independent of sales volume | Fijo (no depende de volumen) |
| 0005 | Material group rebate | Por grupo materiales MATKL |

## Transacciones

| TCode | Accion |
|-------|--------|
| VB01 | Crear acuerdo de rebate |
| VB02 | Modificar acuerdo |
| VB03 | Visualizar acuerdo |
| VBO1 | Crear condiciones rebate |
| VBO2 | Modificar condiciones |
| VBO3 | Visualizar condiciones |
| VB(D | Liquidacion parcial |
| VB(F | Liquidacion final |
| VB(R | Activar rebates por org ventas |

## Condition Types para Rebates

| Tipo | Descripcion | Calculo |
|------|-------------|---------|
| BO01 | Group rebate | % sobre valor grupo |
| BO02 | Material rebate | % sobre valor material |
| BO03 | Customer hierarchy | % sobre jerarquia |
| BO04 | Volume independent | Monto fijo |
| BO05 | Material group | % sobre grupo material |

## Proceso Completo

### 1. Activar rebates
```
SPRO → SD → Billing → Rebate Processing:
  a) Activate rebates per sales org: VB(R → org 1000 → activo
  b) Activate per billing type: F2 → rebate-relevant = X
  c) Condition type groups para rebates
  d) Settlement calendar (periodos de liquidacion)
```

### 2. Crear acuerdo (VB01)
```
Datos header:
  - Tipo acuerdo: 0002 (material rebate)
  - Cliente: 1000
  - Validez: 01.01.2024 — 31.12.2024
  - Status: A (abierto)

Condiciones:
  - Tipo: BO02
  - Material: MAT001
  - Escala:
    > 500 pzas → 3%
    > 1000 pzas → 5%
    > 2000 pzas → 7%
  - Accrual key: ERB (provision rebate)
```

### 3. Acumulacion automatica
```
Cada vez que se factura (VF01) con billing type rebate-relevant:
  - SAP acumula volumen en el acuerdo
  - Genera asiento de accrual:
    D: 810000 Descuento rebate (gasto) — ERB
    C: 270000 Provision rebate (pasivo) — ERB
  - Tablas: VBOX (accruals), S136 (estadisticas rebate)
```

### 4. Liquidacion parcial (VB(D)
```
Durante el periodo, se pueden hacer liquidaciones parciales:
  - VB(D → seleccionar acuerdo → ejecutar
  - Genera: Credit Memo Request (CR)
  - CR se factura como G2 (nota credito)
  - Reversa parcial del accrual
  - Pago al cliente o reduccion de deuda
```

### 5. Liquidacion final (VB(F)
```
Al fin del periodo:
  - VB(F → seleccionar acuerdo → ejecutar
  - Genera: CR por el saldo restante
  - Reversa TOTAL del accrual
  - Status acuerdo: B (liquidado)
  - Si volumen real < escala minima: no hay rebate
```

## Account Keys para Rebates

| AccKey | Cuenta | Descripcion |
|--------|--------|-------------|
| ERB | 810000 | Gasto rebate (accrual) |
| ERB | 270000 | Provision rebate (accrual contra) |
| ERL | 800000 | Revenue (ajuste en settlement) |

### Asiento de accrual (por factura)
```
D: 810000 Gasto rebate           $50 (ERB)
C: 270000 Provision rebate       $50 (ERB)
```

### Asiento de settlement (nota credito G2)
```
D: 270000 Provision rebate       $500 (reversa accrual)
C: 810000 Gasto rebate           $500 (reversa accrual)
D: 800000 Revenue adjustment     $500
C: 140000 AR cliente             $500
```

## Retroactive Rebates (Backdating)

```
Si el acuerdo se crea DESPUES de que ya hay facturas:
  - VB01 con fecha inicio anterior a hoy
  - SAP recalcula accruals retroactivamente
  - Actualiza provision para facturas ya emitidas
  - Config: permitir backdating en tipo acuerdo
```

## S/4HANA: Settlement Management

```
Alternativa moderna a rebates clasicos:
  - Transaction: /SAPSLL/MENU_LEGAL o SM app
  - Mas flexible: multiples condiciones por acuerdo
  - Mejor integracion con analytics
  - Workflow de aprobacion integrado
  - Soporte para acuerdos complejos multi-nivel

Config: SPRO → SD → Billing → Settlement Management
```

## Tablas principales

| Tabla | Contenido |
|-------|-----------|
| VBAK/VBAP | Acuerdo de rebate (tipo doc = BON) |
| VBOX | Accruals de rebate (detalle) |
| KONH/KONP | Condiciones del acuerdo |
| S136 | Estadisticas rebate (LIS) |
| KONV | Condiciones en factura (accrual line) |

## Queries MCP

```sql
-- Acuerdos de rebate abiertos
SELECT VBELN, AUART, KUNNR, GUEBG, GUEEN, NETWR FROM VBAK
WHERE AUART IN ('0001','0002','0003','0004','0005')
AND GBSTK <> 'C' AND VKORG = '{org}'

-- Accruals acumulados por acuerdo
SELECT VBELN, POSNR, VBOBJ, VBSTA, BONBA FROM VBOX
WHERE VBELN = '{acuerdo}'

-- Condiciones de un acuerdo
SELECT KNUMH, KSCHL, KBETR, KONWA, DATAB, DATBI FROM KONP
JOIN KONH ON KONP.KNUMH = KONH.KNUMH
WHERE KONH.KNUMH IN (SELECT KNUMV FROM VBAK WHERE VBELN = '{acuerdo}')

-- Volumen facturado para cliente en periodo (base para rebate)
SELECT VBRP.MATNR, SUM(VBRP.FKIMG) as QTY, SUM(VBRP.NETWR) as VALOR
FROM VBRP JOIN VBRK ON VBRP.VBELN = VBRK.VBELN
WHERE VBRK.KUNAG = '{cliente}' AND VBRK.FKART = 'F2' AND VBRK.FKSTO = ''
AND VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
GROUP BY VBRP.MATNR

-- Settlements realizados
SELECT VBELN, AUART, KUNNR, NETWR, ERDAT FROM VBAK
WHERE AUART = 'CR' AND VBAK.VGBEL IN
  (SELECT VBELN FROM VBAK WHERE AUART IN ('0001','0002','0003') AND VKORG = '{org}')
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| Rebate not accrued | Billing type no es rebate-relevant | VB(R activar |
| Settlement amount = 0 | Sin volumen acumulado | Verificar facturas del periodo |
| Acuerdo vencido | Fecha fin superada | VB02 extender validez |
| Credit memo > accrual | Liquidacion excede provision | Verificar escalas y volumen real |
| Retroactive failed | Backdating no permitido | Config tipo acuerdo → permitir |
