# Errores Comunes FI — Diagnóstico y Solución

Referencia de errores frecuentes en SAP FI con causa raíz, resolución paso a paso
y consultas MCP para diagnóstico.

---

## General Ledger (GL)

### F5 155 — Account does not exist in chart of accounts

| Campo | Detalle |
|-------|---------|
| Mensaje | "Account {X} does not exist in chart of accounts {Y}" |
| Causa | La cuenta no está creada en el plan de cuentas o no está extendida a la sociedad |
| Resolución | 1. FS00 → verificar existencia en plan de cuentas (FSP0) 2. Extender a sociedad (FSS0) 3. Verificar grupo de cuentas correcto |

```sql
-- MCP: Verificar existencia de cuenta en plan de cuentas
SELECT SAKNR, KTOKS, XBILK, GVTYP, XLOEV
FROM SKA1
WHERE KTOPL = '{chart_of_accounts}' AND SAKNR = '{account}'

-- Verificar extensión a sociedad
SELECT SAKNR, BUKRS, WAERS, MWSKZ, MITKZ, XOPVW
FROM SKB1
WHERE BUKRS = '{company_code}' AND SAKNR = '{account}'
```

### F5 312 — Posting period is not open

| Campo | Detalle |
|-------|---------|
| Mensaje | "Posting period {X}.{Y} is not open" |
| Causa | El periodo contable está cerrado en OB52 para el tipo de cuenta |
| Resolución | 1. OB52 → verificar variante de periodos 2. Abrir periodo para tipo de cuenta (S=GL, D=Deudor, K=Acreedor, A=Activos, +/M=todos) 3. Verificar periodo especial si aplica |

```sql
-- MCP: Verificar periodos abiertos
SELECT BUKRS, RESSION, KONTO, BU_PERIOD_FROM, BU_PERIOD_TO,
       BU_PERIOD_FROM2, BU_PERIOD_TO2, GJAHR, GJAHR2
FROM T001B
WHERE BUKRS = '{company_code}'
ORDER BY RESSION
```

### F5 003 — Balance in transaction currency

| Campo | Detalle |
|-------|---------|
| Mensaje | "Balance in transaction currency" |
| Causa | Las sumas de débito y crédito no cuadran; diferencias de redondeo en moneda del documento |
| Resolución | 1. Verificar importes de cada posición 2. Revisar tipo de cambio aplicado 3. Ajustar diferencia de céntimos en línea de redondeo |

### FB 309 — Document type does not allow account type

| Campo | Detalle |
|-------|---------|
| Mensaje | "Document type {X} does not allow account type {Y}" |
| Causa | El tipo de documento no tiene permitido el tipo de cuenta (GL/Vendor/Customer/Asset) |
| Resolución | OBA7 → tipo de documento → marcar tipos de cuenta permitidos (Sachkonten, Debitoren, Kreditoren, Anlagen) |

```sql
-- MCP: Verificar tipos de cuenta permitidos por tipo de documento
SELECT BLART, KOPTS_K, KOPTS_D, KOPTS_S, KOPTS_A, KOPTS_M
FROM T003
WHERE BLART = '{doc_type}'
```

### F5 801 — Field status conflict

| Campo | Detalle |
|-------|---------|
| Mensaje | "Field status definition: field {X} has incompatible status" |
| Causa | Conflicto entre field status de la cuenta (OBC4) y la clave de contabilización (OB41). Un campo es "obligatorio" en uno y "oculto" en otro |
| Resolución | 1. OBC4 → verificar grupo de status de campo de la cuenta 2. OB41 → verificar field status de la clave de contabilización 3. El intersecto debe ser compatible: obligatorio > opcional > oculto. Obligatorio + oculto = error |

---

## Accounts Payable (AP)

### FP 051 — Payment method not valid

| Campo | Detalle |
|-------|---------|
| Mensaje | "Payment method {X} is not valid for country {Y}" |
| Causa | Método de pago no configurado en FBZP para el país/sociedad o no asignado en dato maestro del acreedor |
| Resolución | 1. FBZP → All company codes → verificar métodos de pago 2. FBZP → Payment methods in country → verificar configuración 3. FK02 → Vista de pagos → verificar método de pago permitido |

```sql
-- MCP: Verificar métodos de pago del acreedor
SELECT LIFNR, BUKRS, ZWELS, HBKID, XPORE, UZAWE
FROM LFB1
WHERE LIFNR = '{vendor}' AND BUKRS = '{company_code}'
```

### FZ 007 — No valid bank data for payment

| Campo | Detalle |
|-------|---------|
| Mensaje | "No bank data/payment details available for vendor {X}" |
| Causa | Banco no mantenido en dato maestro de acreedor o datos bancarios incompletos |
| Resolución | 1. FK02 → Datos bancarios → verificar IBAN/cuenta 2. FI12 → verificar banco propio configurado 3. FBZP → verificar ranking de bancos propios |

```sql
-- MCP: Verificar datos bancarios del acreedor
SELECT LIFNR, BANKS, BANKL, BANKN, BKONT, KOINH, IBAN
FROM LFBK
WHERE LIFNR = '{vendor}'
```

### FP 350 — Amount below minimum for payment method

| Campo | Detalle |
|-------|---------|
| Mensaje | "Amount {X} is below minimum amount for payment method {Y}" |
| Causa | El importe a pagar es inferior al mínimo configurado en FBZP |
| Resolución | FBZP → Payment methods in country → verificar importe mínimo/máximo del método de pago |

### FB 827 — Duplicate invoice

| Campo | Detalle |
|-------|---------|
| Mensaje | "Duplicate invoice: company code {X} vendor {Y} reference {Z}" |
| Causa | Ya existe una factura con la misma referencia, sociedad y acreedor. Control de duplicados activo en LFB1-REPRF |
| Resolución | 1. Verificar si realmente es duplicado (FBL1N) 2. Si no es duplicado: FK02 → desactivar temporalmente chequeo de duplicados (no recomendado) 3. Usar referencia diferente |

```sql
-- MCP: Buscar documentos duplicados
SELECT RBUKRS, LIFNR, BELNR, GJAHR, XBLNR, BLDAT, HSL
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND LIFNR = '{vendor}'
  AND XBLNR = '{reference}'
  AND RLDNR = '0L'
  AND KOART = 'K'
```

### F-44 Error — Clearing differences

| Campo | Detalle |
|-------|---------|
| Mensaje | "Amount of open items greater than tolerance for user/group" |
| Causa | La diferencia entre partidas a compensar excede la tolerancia configurada |
| Resolución | 1. OBA3 → verificar grupo de tolerancia 2. Ajustar tolerancia o contabilizar diferencia (cargo/abono) 3. Verificar si aplica descuento por pronto pago |

---

## Accounts Receivable (AR)

### F2 064 — Credit limit exceeded

| Campo | Detalle |
|-------|---------|
| Mensaje | "Credit limit of customer {X} exceeded by {Y}" |
| Causa | El pedido o factura supera el límite de crédito del deudor |
| Resolución | 1. FD32 → verificar/ampliar límite de crédito 2. UKM_COND → gestión de crédito SAP Credit Management 3. Liberar pedido bloqueado en VKM1/VKM3 |

```sql
-- MCP: Verificar saldo abierto del deudor vs límite de crédito
SELECT RBUKRS, KUNNR, SUM(HSL) AS OPEN_BALANCE
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KUNNR = '{customer}'
  AND KOART = 'D'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
GROUP BY RBUKRS, KUNNR
```

### F5 201 — Customer blocked for posting

| Campo | Detalle |
|-------|---------|
| Mensaje | "Customer {X} is blocked for posting in company code {Y}" |
| Causa | El deudor tiene bloqueo de contabilización activo |
| Resolución | FD02 → Datos de sociedad → desmarcar indicador de bloqueo de contabilización (SPERR) |

### FB 741 — Clearing difference too high

| Campo | Detalle |
|-------|---------|
| Mensaje | "Amount of clearing difference too high" |
| Causa | La diferencia de compensación supera el grupo de tolerancia (OBA3) |
| Resolución | 1. OBA3 → ajustar tolerancia 2. Contabilizar diferencia como descuento, cargo por demora o pérdida/ganancia por tipo de cambio |

### FP 012 — Dunning procedure not assigned

| Campo | Detalle |
|-------|---------|
| Mensaje | "No dunning procedure assigned to customer {X}" |
| Causa | El procedimiento de reclamación no está en el dato maestro del deudor |
| Resolución | FD02 → pestaña Correspondencia → asignar procedimiento de dunning (KNB1-MAHNA) |

---

## Asset Accounting (AA)

### AA 687 — Depreciation area not defined for asset class

| Campo | Detalle |
|-------|---------|
| Mensaje | "Depreciation area {X} not defined in asset class {Y}" |
| Causa | La clase de activo no tiene configurada el área de valoración |
| Resolución | OADB → asignar área de valoración a la clase de activo → definir clave de amortización, vida útil, % de salvamento |

```sql
-- MCP: Verificar áreas de valoración de una clase de activo
SELECT ANLKL, AFESSION, AFABER, NDJAR, NDPER, SCHRW
FROM T096
WHERE ANLKL = '{asset_class}'
ORDER BY AFESSION
```

### AA 350 — Fiscal year already closed

| Campo | Detalle |
|-------|---------|
| Mensaje | "Fiscal year {X} is already closed for company code {Y}" |
| Causa | El cambio de ejercicio de activos (AJAB) ya se ejecutó para ese año |
| Resolución | 1. Verificar en AJRW si se puede reabrir 2. Contabilizar en el ejercicio correcto 3. Si es necesario, reversar AJAB (solo con nota SAP) |

### AA 632 — Asset locked by depreciation run

| Campo | Detalle |
|-------|---------|
| Mensaje | "Asset {X} is locked by depreciation run" |
| Causa | Una ejecución de amortización AFAB está en proceso o quedó bloqueada |
| Resolución | 1. AFAB → verificar estado de la ejecución 2. SM12 → verificar locks del activo 3. Si la ejecución falló: AFAB en modo de reinicio |

---

## Tax

### FF 713 — Tax code not defined

| Campo | Detalle |
|-------|---------|
| Mensaje | "Tax code {X} not defined for tax procedure {Y}" |
| Causa | El indicador de impuesto no existe en el esquema de cálculo asignado al país |
| Resolución | 1. FTXP → crear indicador de impuesto 2. OBYZ → verificar esquema de cálculo asignado al país 3. Verificar país de la sociedad |

```sql
-- MCP: Verificar indicadores de impuesto configurados
SELECT KALSM, MWSKZ, TEXT1, MWART, XINACT
FROM T007S
WHERE KALSM = '{tax_procedure}' AND SPRAS = 'E'
ORDER BY MWSKZ
```

### FF 730 — Tax account not configured

| Campo | Detalle |
|-------|---------|
| Mensaje | "Tax account not configured for tax code {X}" |
| Causa | No hay cuenta de mayor asignada al indicador de impuesto |
| Resolución | OB40 → asignar cuenta de mayor de impuesto al indicador → verificar que la cuenta exista y esté extendida |

### MWST 015 — Tax jurisdiction invalid

| Campo | Detalle |
|-------|---------|
| Mensaje | "Tax jurisdiction code {X} invalid" |
| Causa | Código de jurisdicción fiscal no mantenido (aplica principalmente en USA) |
| Resolución | OBCO → verificar/crear código de jurisdicción fiscal → asignar porcentajes |

---

## Errores Generales

### F5 035 — Negative posting not allowed

| Campo | Detalle |
|-------|---------|
| Mensaje | "Negative posting not allowed for account {X}" |
| Causa | El tipo de documento o cuenta no permite contabilizaciones negativas |
| Resolución | 1. OBA7 → marcar "Negative posting allowed" en tipo de documento 2. OB41 → verificar clave de contabilización con indicador de negativo |

### FB 401 — Currency mismatch

| Campo | Detalle |
|-------|---------|
| Mensaje | "Currency {X} different from account currency {Y}" |
| Causa | La moneda del documento no coincide con la moneda de la cuenta (cuenta en moneda fija) |
| Resolución | 1. FS00 → verificar moneda de la cuenta 2. Contabilizar en la moneda correcta 3. Si la cuenta debe ser multimoneda: cambiar indicador de moneda |

### F5 219 — Posting key does not match account type

| Campo | Detalle |
|-------|---------|
| Mensaje | "Posting key {X} does not match account type {Y}" |
| Causa | Clave de contabilización para GL (40/50) usada con cuenta de deudor/acreedor o viceversa |
| Resolución | Usar clave correcta: GL=40/50, Vendor=21/31, Customer=01/11, Asset=70/75 |

### MESSAGE_TYPE_X — Document parking errors

| Campo | Detalle |
|-------|---------|
| Mensaje | Varios mensajes de error en parking de documentos |
| Causa | Datos incompletos que en posting normal serían error pero en parking deberían permitirse |
| Resolución | 1. Verificar config de parking: campos obligatorios mínimos 2. Verificar BAdI BADI_FDCB_SUBACC01 para reglas custom |

---

## MCP — Consultas de Diagnóstico General

```sql
-- Documentos con errores de contabilización (tabla de log)
SELECT BUKRS, BELNR, GJAHR, MSGTY, MSGID, MSGNO, MSGV1, MSGV2
FROM ACCHD_LOG
WHERE BUKRS = '{company_code}'
  AND GJAHR = '{fiscal_year}'
  AND MSGTY IN ('E', 'A')
ORDER BY BELNR

-- Verificar documentos anulados
SELECT RBUKRS, BELNR, GJAHR, STBLG, STJAH, BUDAT, BLART, USNAM
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND STBLG IS NOT NULL
  AND RLDNR = '0L'
  AND GJAHR = '{fiscal_year}'

-- Documentos bloqueados (locks)
SELECT MANDT, GARG, GNAME, GUNAME
FROM ENQT
WHERE GNAME LIKE '%BKPF%'
```

---

## Resumen Rápido de Resolución

| Error | Acción inmediata | TCode de config |
|-------|-----------------|-----------------|
| F5 155 | Crear/extender cuenta | FS00/FSP0/FSS0 |
| F5 312 | Abrir periodo | OB52 |
| FB 309 | Permitir tipo de cuenta | OBA7 |
| F5 801 | Alinear field status | OBC4 + OB41 |
| FP 051 | Config método de pago | FBZP |
| FZ 007 | Mantener banco acreedor | FK02 + FI12 |
| F2 064 | Ampliar crédito | FD32/UKM |
| AA 687 | Config área valoración | OADB |
| FF 713 | Crear indicador impuesto | FTXP |
| FF 730 | Asignar cuenta impuesto | OB40 |
