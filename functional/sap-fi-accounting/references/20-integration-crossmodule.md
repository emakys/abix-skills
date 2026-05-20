# Integración Cross-Module FI

Cómo SAP FI se integra con cada módulo principal del sistema.
Incluye tablas de referencia, eventos, tipos de documento y diagnóstico MCP.

---

## FI <> CO (Controlling)

### Integración en S/4HANA

En S/4HANA, FI y CO comparten la tabla universal ACDOCA. Ya no existen tablas
separadas CO (COEP, COBK). Toda contabilización FI genera automáticamente
la línea CO correspondiente.

| Aspecto | Detalle |
|---------|---------|
| Tabla común | ACDOCA (Universal Journal) |
| Cost element | = Cuenta de mayor (automático en S/4) |
| Reconciliación | Ya no es necesaria FI-CO (misma tabla) |
| Asignación CO | Profit center obligatorio via document splitting |
| Ledger | 0L = Leading, extensión para parallel accounting |

### Flujos de integración

| Evento CO | Resultado FI | TCode |
|-----------|-------------|-------|
| Settlement de orden CO | Documento FI tipo AB | KO88 |
| Distribución/Reparto ciclo | Líneas en ACDOCA | KSV5/KSU5 |
| Accrual Engine | Periodificaciones en GL | ACE |
| Internal order planning | No impacta FI (solo CO) | KO12 |
| Cost center reposting | Líneas en ACDOCA | KB61 |

### MCP — Diagnóstico FI-CO

```sql
-- Verificar asignaciones CO en documentos FI
SELECT RBUKRS, BELNR, BUZEI, RACCT, RCNTR, PRCTR, RFAREA,
       RCOMP, RASSC, RBUSA, RSEGMENT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND RLDNR = '0L'
  AND RCNTR IS NOT NULL
ORDER BY BELNR, BUZEI

-- Documentos de settlement CO → FI
SELECT RBUKRS, BELNR, GJAHR, BUZEI, RACCT, HSL, BUDAT,
       AUFNR, KSTAR
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND AUFNR = '{internal_order}'
  AND RLDNR = '0L'
```

### SPRO Path

```
SPRO → Controlling → General Controlling →
  ├── Organization → Maintain Controlling Area (OKKP)
  ├── Assign Company Code to Controlling Area
  └── Activate components (cost centers, orders, profitability)

SPRO → Financial Accounting → General Ledger →
  └── Document Splitting → Define zero-balance for profit center
```

---

## FI <> MM (Materials Management)

### Determinación de Cuentas (OBYC)

| Clave OBYC | Descripción | Cuenta típica |
|-------------|-------------|---------------|
| BSX | Cambio en stock (inventory) | 300000 (stock) |
| WRX | GR/IR clearing account | 191100 |
| GBB | Offsetting entry for inventory | Varios por movement type |
| PRD | Price differences | 490000 |
| KON | Consignment payables | 211000 |
| UPF | Unplanned delivery costs | 491000 |
| KBS | Account for PO accrual | 192000 |
| FRL | Freight clearing | 192100 |

### Flujos de integración

| Evento MM | Doc. FI | Tipo Doc | Cuentas |
|-----------|---------|----------|---------|
| Entrada de mercancía (MIGO 101) | Sí | WE | BSX (Debe) / WRX (Haber) |
| Devolución a proveedor (MIGO 122) | Sí | WE | BSX (Haber) / WRX (Debe) |
| Factura logística (MIRO) | Sí | RE | WRX (Debe) / Vendor (Haber) |
| Diferencia de precio (MIRO) | Sí | RE | PRD (Debe/Haber) |
| Traslado de stock (MIGO 301) | Sí | WL | BSX (Debe) / BSX (Haber) |
| Consumo a centro coste (MIGO 201) | Sí | WA | GBB (Debe) / BSX (Haber) |
| Anulación de factura (MR8M) | Sí | KG | Reverso de MIRO |

### MCP — Diagnóstico FI-MM

```sql
-- GR/IR abiertos (sin matchear)
SELECT RBUKRS, LIFNR, EBELN, EBELP, BELNR, BUZEI,
       HSL, BUDAT, AUGDT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{grir_account}'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
ORDER BY EBELN, EBELP

-- Diferencias de precio por material
SELECT MATNR, RBUKRS, BELNR, BUZEI, HSL, BUDAT, BSCHL
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{prd_account}'
  AND GJAHR = '{year}'
  AND RLDNR = '0L'
ORDER BY MATNR, BUDAT
```

### SPRO Path

```
SPRO → Materials Management → Valuation and Account Assignment →
  └── Account Determination →
      ├── OBYC → Configure Automatic Postings
      ├── Valuation class → Account assignment
      └── Movement type → Account assignment modifier
```

---

## FI <> SD (Sales & Distribution)

### Determinación de Cuentas (VKOA)

| Clave cuenta | Descripción | Cuenta típica |
|--------------|-------------|---------------|
| ERL | Revenue | 800000 (ventas) |
| ERS | Sales deductions | 810000 |
| ERF | Revenue (freight) | 820000 |
| MWS | Tax on sales | Cuenta impuestos |
| EXP | Export revenue | 801000 |
| SKE | Cash discount granted | 850000 |
| FRE | Freight revenue | 820000 |

### Flujos de integración

| Evento SD | Doc. FI | Tipo Doc | Cuentas |
|-----------|---------|----------|---------|
| Facturación (VF01) | Sí | RV | Deudor (Debe) / ERL (Haber) |
| Abono (VF01 tipo G2) | Sí | RV | ERL (Debe) / Deudor (Haber) |
| Cash discount | Al compensar | DZ | SKE (Debe) / Deudor (Haber) |
| Intercompany billing | Sí | RV | IC accounts |

### Crédito — Flujo SD-FI

```
Pedido de venta (VA01)
│
├─ Credit check activo? (OVA8/UKM)
│  ├─ NO → Pedido procede sin chequeo
│  └─ SÍ ↓
│
├─ ¿Saldo abierto AR + pedido > límite?
│  ├─ NO → Pedido liberado
│  └─ SÍ ↓
│
├─ Pedido bloqueado por crédito
│  ├─ VKM1 → Liberar pedido manualmente
│  ├─ FD32 → Aumentar límite de crédito
│  └─ UKM_COND → Reglas automáticas (S/4)
```

### MCP — Diagnóstico FI-SD

```sql
-- Revenue por periodo desde billing
SELECT RBUKRS, KUNNR, RACCT, POPER,
       SUM(HSL) AS REVENUE, COUNT(*) AS DOC_COUNT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND GJAHR = '{year}'
  AND BLART = 'RV'
  AND RLDNR = '0L'
GROUP BY RBUKRS, KUNNR, RACCT, POPER
ORDER BY POPER

-- Saldo abierto de cliente (para credit check)
SELECT KUNNR, SUM(HSL) AS OPEN_AMOUNT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KOART = 'D'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
GROUP BY KUNNR
HAVING SUM(HSL) > 0
ORDER BY OPEN_AMOUNT DESC
```

---

## FI <> HR (Human Resources / Payroll)

### Flujos de integración

| Evento HR | Doc. FI | Tipo Doc | Cuentas |
|-----------|---------|----------|---------|
| Nómina (PC00_MNN_CIPE) | Sí | Custom | Gasto salario / Banco / Retenciones |
| Travel expenses (PR05) | Sí | Custom | Gasto viaje / Empleado payable |
| Benefits posting | Sí | Custom | Gasto beneficios / Provisiones |
| Bonus/Provisions | Sí | Custom | Gasto / Provisión |

### Mapping Wage Type → GL Account

| Concepto | Wage type (ejemplo) | Cuenta GL típica |
|----------|---------------------|-------------------|
| Salario bruto | 1000 | 620000 (gasto nómina) |
| IRPF retención | 3010 | 475000 (HP acreedora IRPF) |
| Seguridad social empresa | 3020 | 642000 (gasto SS) |
| Seguridad social empleado | 3021 | 476000 (org. SS acreedora) |
| Neto a pagar | /559 | 465000 (remuneraciones pte.) |
| Banco nómina | /560 | 572000 (banco) |

### SPRO Path

```
SPRO → Financial Accounting → FI Global Settings →
  └── Company Code → Payroll Accounting →
      ├── Define accounts for posting payroll results
      ├── T030 → symbolic accounts → GL mapping
      └── Assign employee grouping to company code
```

---

## FI <> PP (Production Planning)

### Flujos de integración

| Evento PP | Doc. FI | Tipo Doc | Cuentas |
|-----------|---------|----------|---------|
| Consumo material (backflush) | Sí | WA | GBB/BSX via MM |
| Activity confirmation (CO11N) | Sí | — | Via CO → ACDOCA |
| WIP calculation (KKAO) | Sí | SA | WIP account / P&L offset |
| Variance calculation (KKS1) | Sí | SA | Variance accounts |
| Settlement (KO88) | Sí | AB | Cost of goods manufactured |
| Scrap posting | Sí | WA | Scrap account |

### MCP — Diagnóstico FI-PP

```sql
-- Costes de órdenes de producción en FI
SELECT RBUKRS, AUFNR, RACCT, KSTAR, SUM(HSL) AS TOTAL_COST,
       COUNT(*) AS POSTINGS
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND AUFNR LIKE '{order_prefix}%'
  AND GJAHR = '{year}'
  AND RLDNR = '0L'
GROUP BY RBUKRS, AUFNR, RACCT, KSTAR
ORDER BY AUFNR, RACCT
```

---

## FI <> PM/PS (Plant Maintenance / Project System)

### Flujos de integración

| Evento PM/PS | Doc. FI | Tipo Doc | Cuentas |
|--------------|---------|----------|---------|
| Orden PM - materiales | Sí (via MM) | WA | Mant. account / BSX |
| Orden PM - servicios | Sí | RE | Mant. account / Vendor |
| PM settlement (KO88) | Sí | AB | Asset or cost center |
| WBS element posting | Sí | — | Via CO → ACDOCA |
| PS settlement (CJ88) | Sí | AB | Asset (capitalization) |
| Investment measure → Asset | Sí | AA | AuC (asset under constr.) |

### Investment Management (IM)

```
Programa de inversión (IM01)
├─ Posición de inversión (IM11)
│  └─ Medida de inversión = Orden interna o Elemento PEP
│     ├─ Costes se acumulan en AuC (asset under construction)
│     ├─ Al completar: capitalización (AIAB/AIBU)
│     └─ AuC se transfiere a activo definitivo (ABUMN)
```

### MCP — Diagnóstico FI-PM/PS

```sql
-- Costes acumulados en proyecto/WBS
SELECT RBUKRS, PS_PSP_PNR, RACCT, SUM(HSL) AS TOTAL,
       MIN(BUDAT) AS FIRST_POST, MAX(BUDAT) AS LAST_POST
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND PS_PSP_PNR IS NOT NULL
  AND GJAHR = '{year}'
  AND RLDNR = '0L'
GROUP BY RBUKRS, PS_PSP_PNR, RACCT
ORDER BY PS_PSP_PNR
```

---

## FI <> Treasury (TR)

### Flujos de integración

| Área TR | Relación FI | TCode |
|---------|-------------|-------|
| Cash Management | Posición de caja desde GL/AP/AR | FF7A |
| Cash Forecast | Previsión desde partidas abiertas | FF7B |
| Bank Accounting | Extracto bancario → documentos FI | FF67/FEBA |
| Payment Program | F110 genera pagos → banco/tesorería | F110 |
| In-House Cash | Netting intercompany | IHC |
| Loan Management | Préstamos → intereses → FI | CML |

### Bank Statement Processing

```
Extracto bancario recibido (MT940/CAMT.053)
│
├─ Importar: FLB2 (file) o automático (interfaz)
│
├─ Interpretar: reglas de asignación
│  ├─ Nota de referencia → match con factura
│  ├─ BIC/IBAN → match con acreedor/deudor
│  └─ Importe → match con partida abierta
│
├─ Contabilizar: FF67/FEBA
│  ├─ Cobro → compensar partida AR (F-28 automático)
│  ├─ Pago → compensar partida AP (F-53 automático)
│  ├─ Cargos bancarios → cuenta de gasto
│  └─ Sin match → cuenta de diferencias (manual)
│
└─ Resultado: documentos FI generados automáticamente
```

### MCP — Diagnóstico Treasury

```sql
-- Posición de caja (saldos de cuentas bancarias)
SELECT RACCT, RHCUR, SUM(HSL) AS BALANCE
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT BETWEEN '{bank_acct_from}' AND '{bank_acct_to}'
  AND RLDNR = '0L'
GROUP BY RACCT, RHCUR

-- Pagos realizados por banco
SELECT HBKID, HKTID, COUNT(*) AS PAY_COUNT, SUM(HSL) AS PAY_TOTAL
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND BLART = 'KZ'
  AND GJAHR = '{year}'
  AND POPER = '{period}'
  AND RLDNR = '0L'
GROUP BY HBKID, HKTID
```

---

## Tabla Resumen — Integración Cross-Module

| Módulo | Trigger | Doc FI | Tipo | Config clave | Reconciliación |
|--------|---------|--------|------|--------------|----------------|
| CO | Settlement/Allocation | ACDOCA | AB | KO88/KSV5 | Automática (S/4) |
| MM | GR/IR/Invoice | ACDOCA | WE/RE | OBYC | F.19, MR11 |
| SD | Billing | ACDOCA | RV | VKOA | FBL5N vs VFX3 |
| HR | Payroll run | ACDOCA | Custom | T030 | PC00_MNN_CIPE log |
| PP | Settlement/WIP | ACDOCA | AB/SA | KO88/KKAO | Orden vs GL |
| PM | Settlement | ACDOCA | AB | KO88 | Orden vs GL |
| PS | Settlement | ACDOCA | AB | CJ88 | WBS vs GL |
| TR | Bank statement | ACDOCA | — | FF67/FEBA | FF7A vs GL |
| AA | Acquisition/Depr | ACDOCA | AA/AF | AO90 | AB08 |

---

## Problemas Comunes de Integración

| Problema | Módulos | Diagnóstico | Solución |
|----------|---------|-------------|----------|
| GR/IR no cuadra | FI-MM | F.19, FBL3N en cuenta WRX | Compensar o reclasificar |
| Revenue no coincide con billing | FI-SD | VFX3 vs FBL3N en cuenta ERL | Verificar VKOA, billing status |
| Nómina no cuadra | FI-HR | Comparar log CIPE vs FBL3N | Reversar y re-ejecutar posting |
| Settlement no contabiliza | FI-CO/PP | Verificar regla de liquidación | KO02 → regla de settlement |
| Depreciation missing | FI-AA | AFAB log, verificar vida útil | AFAR recálculo |
| Intercompany no balancea | FI-FI | FAGLB03 por sociedad partner | Verificar IC accounts |
| Document splitting error | FI-CO | FAGL_SPLIT_CUST | Verificar reglas de splitting |
| Currency rounding | FI-MM/SD | Céntimos en cuenta de redondeo | Verificar OB59 |
