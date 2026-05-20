# Árboles de Decisión FI

Diagramas de decisión para escenarios comunes en SAP FI.
Formato ASCII con rutas de decisión claras.

---

## 1. Tipo de Documento (BLART)

```
¿Qué operación contable?
│
├─ Factura de proveedor
│  ├─ Con pedido (PO) ──────────────── RE (vía MIRO)
│  └─ Sin pedido ───────────────────── KR (FB60)
│     └─ Abono de proveedor ────────── KG (FB65)
│
├─ Factura de cliente
│  ├─ Desde facturación SD ─────────── RV (VF01 automático)
│  └─ Manual ───────────────────────── DR (FB70)
│     └─ Abono de cliente ──────────── DG (FB75)
│
├─ Asiento de mayor manual ─────────── SA (FB50/FB01)
│
├─ Pago
│  ├─ Pago a proveedor
│  │  ├─ Automático (F110) ─────────── KZ
│  │  └─ Manual (F-53) ────────────── ZP (o custom)
│  ├─ Cobro de cliente
│  │  ├─ Automático ────────────────── DZ
│  │  └─ Manual (F-28) ────────────── DZ
│  └─ Transferencia bancaria ───────── custom (ZB, etc.)
│
├─ Compensación ────────────────────── AB (FB05)
│
├─ Activos fijos
│  ├─ Adquisición ──────────────────── AA (AB01/ABZON)
│  ├─ Baja ─────────────────────────── AA (ABAON/ABN1)
│  ├─ Transferencia ────────────────── AA (ABUMN)
│  └─ Amortización ─────────────────── AF (AFAB automático)
│
├─ Anticipo (Down payment)
│  ├─ Solicitud proveedor ──────────── KA (F-47)
│  ├─ Pago anticipo proveedor ──────── KZ (F-48)
│  ├─ Solicitud cliente ────────────── DA (F-37)
│  └─ Cobro anticipo cliente ──────── DZ (F-29)
│
└─ Nómina ──────────────────────────── custom (HR posting)
```

### Tabla de referencia — Tipos de documento

| BLART | Descripción | Origen | Tipos de cuenta |
|-------|-------------|--------|-----------------|
| SA | GL document | Manual | S (GL) |
| KR | Vendor invoice | Manual | S, K |
| KG | Vendor credit memo | Manual | S, K |
| KZ | Vendor payment | Auto/Manual | S, K |
| DR | Customer invoice | Manual | S, D |
| DG | Customer credit memo | Manual | S, D |
| DZ | Customer payment | Auto/Manual | S, D |
| RE | Invoice - gross (MIRO) | MM | S, K |
| RV | Billing document | SD | S, D |
| AA | Asset posting | AA | S, A |
| AF | Depreciation | AFAB | S, A |
| AB | Clearing document | Manual | S, D, K |

---

## 2. Clave de Contabilización (BSCHL)

```
¿Qué tipo de cuenta?
│
├─ Cuenta de Mayor (GL)
│  ├─ Débito ──────── 40
│  └─ Crédito ─────── 50
│
├─ Acreedor (Vendor)
│  ├─ Factura (crédito) ───── 31
│  ├─ Abono (débito) ─────── 21
│  ├─ Pago (débito) ──────── 25
│  └─ Anticipo
│     ├─ Solicitud ────────── 39 (Special GL = F)
│     └─ Pago ─────────────── 29 (Special GL = A)
│
├─ Deudor (Customer)
│  ├─ Factura (débito) ────── 01
│  ├─ Abono (crédito) ─────── 11
│  ├─ Cobro (crédito) ─────── 15
│  └─ Anticipo
│     ├─ Solicitud ────────── 09 (Special GL = F)
│     └─ Cobro ────────────── 19 (Special GL = A)
│
└─ Activo Fijo (Asset)
   ├─ Adquisición (débito) ── 70
   ├─ Baja (crédito) ──────── 75
   └─ Transferencia ───────── 70 (destino) + 75 (origen)
```

### Regla de intersección Posting Key + Field Status

```
Resultado = MAX(Field Status de la cuenta, Field Status de la posting key)

Prioridad: Suppress < Optional < Required

EXCEPCIÓN: Suppress + Required = ERROR (F5 801)
```

---

## 3. Diagnóstico de Problemas de Pago (F110)

```
El pago NO aparece en la propuesta F110
│
├─ ¿El acreedor tiene partidas abiertas?
│  ├─ NO → No hay nada que pagar. Verificar en FBL1N
│  └─ SÍ ↓
│
├─ ¿Las partidas están vencidas según fecha de ejecución?
│  ├─ NO → Ajustar fecha "Next p/date" en F110 o esperar vencimiento
│  └─ SÍ ↓
│
├─ ¿El acreedor tiene método de pago asignado?
│  ├─ NO → FK02 → Datos de pago → asignar método (ZWELS)
│  └─ SÍ ↓
│
├─ ¿El método de pago está configurado en F110 parámetros?
│  ├─ NO → Agregar método de pago en los parámetros de ejecución
│  └─ SÍ ↓
│
├─ ¿El acreedor tiene datos bancarios válidos?
│  ├─ NO → FK02 → Datos bancarios → mantener IBAN/banco
│  └─ SÍ ↓
│
├─ ¿Hay bloqueo de pago en la partida o acreedor?
│  ├─ SÍ → Quitar bloqueo: FB02 (partida) o FK02 (maestro)
│  └─ NO ↓
│
├─ ¿El importe supera el máximo del método de pago?
│  ├─ SÍ → FBZP → ajustar máximo o split en pagos parciales
│  └─ NO ↓
│
├─ ¿El banco propio tiene saldo suficiente?
│  ├─ NO → Asignar otro banco o aumentar límite
│  └─ SÍ ↓
│
└─ Verificar log detallado de F110 → Proposal → Log
   → Identificar mensaje exacto de rechazo
```

### MCP — Diagnóstico de pago

```sql
-- Partidas abiertas del acreedor con vencimiento
SELECT RBUKRS, LIFNR, BELNR, BUZEI, BUDAT, FAEDT, HSL, ZLSCH, ZLSPR
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND LIFNR = '{vendor}'
  AND KOART = 'K'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
ORDER BY FAEDT

-- Verificar bloqueos de pago en partidas
SELECT BELNR, BUZEI, ZLSPR
FROM BSIK
WHERE BUKRS = '{company_code}'
  AND LIFNR = '{vendor}'
  AND ZLSPR <> ''
```

---

## 4. Cierre de Periodo Contable

```
¿Qué área cerrar?
│
├─ General Ledger
│  ├─ 1. Ejecutar valoración moneda extranjera (FAGL_FCV)
│  ├─ 2. Reclasificar GR/IR (F.19/F.13)
│  ├─ 3. Ejecutar periodificaciones (FBS1/F.81)
│  ├─ 4. Reconciliar GL vs subledgers (FAGLB03 vs FBL1N/FBL5N)
│  ├─ 5. Verificar saldos intercompany
│  └─ 6. Cerrar periodo GL en OB52
│
├─ Accounts Payable
│  ├─ 1. Procesar facturas pendientes (FB60/MIRO)
│  ├─ 2. Ejecutar pagos pendientes (F110)
│  ├─ 3. Verificar partidas abiertas (FBL1N)
│  ├─ 4. Reconciliar con GL (saldo AP = saldo cuenta reconc.)
│  └─ 5. Cerrar periodo AP en OB52
│
├─ Accounts Receivable
│  ├─ 1. Contabilizar cobros pendientes (F-28)
│  ├─ 2. Ejecutar dunning (F150)
│  ├─ 3. Verificar partidas abiertas (FBL5N)
│  ├─ 4. Evaluar provisiones de morosos
│  ├─ 5. Reconciliar con GL
│  └─ 6. Cerrar periodo AR en OB52
│
├─ Asset Accounting
│  ├─ 1. Contabilizar adquisiciones/bajas pendientes
│  ├─ 2. Ejecutar amortización (AFAB)
│  ├─ 3. Verificar errores en log de amortización
│  ├─ 4. Reconciliar AA con GL (AB08)
│  └─ 5. Cerrar periodo AA en OB52
│
└─ Cierre de ejercicio (anual adicional)
   ├─ 1. Ejecutar todos los cierres mensuales de periodo 12
   ├─ 2. Contabilizar asientos de ajuste (periodos especiales 13-16)
   ├─ 3. Ejecutar traspaso de saldos (FAGLGVTR)
   ├─ 4. Cambio de ejercicio de activos (AJAB)
   ├─ 5. Cerrar periodos especiales (OB52)
   └─ 6. Abrir nuevo ejercicio
```

---

## 5. Reconciliación GL vs Subledger

```
Diferencia entre saldo GL y subledger
│
├─ ¿Hay contabilizaciones directas a cuenta de reconciliación?
│  ├─ SÍ → Reclasificar a cuenta GL normal.
│  │       Activar bloqueo en FS00 (XOPVW = 'X' impide posting directo)
│  └─ NO ↓
│
├─ ¿Hay document splitting activo?
│  ├─ SÍ → Verificar reglas de splitting (FAGL_SPLIT_CUST)
│  │       → ¿Splitting genera líneas en cuentas inesperadas?
│  └─ NO ↓
│
├─ ¿Hay diferencias de moneda paralela?
│  ├─ SÍ → Verificar tipos de cambio en TCURR
│  │       → Ejecutar FAGL_FCV para revaluar
│  └─ NO ↓
│
├─ ¿Hay documentos en estado "parked" (preliminar)?
│  ├─ SÍ → Los parked documents NO actualizan subledger
│  │       → Contabilizar o eliminar
│  └─ NO ↓
│
└─ Verificar periodos especiales y asientos de ajuste
   → Comparar con FAGLB03 filtrando por ledger 0L
```

### MCP — Reconciliación

```sql
-- Saldo de cuenta de reconciliación vs suma de subledger
-- GL side:
SELECT RACCT, SUM(HSL) AS GL_BALANCE
FROM ACDOCA
WHERE RBUKRS = '{company_code}' AND GJAHR = '{year}'
  AND RACCT = '{recon_account}' AND RLDNR = '0L'
GROUP BY RACCT

-- Subledger side (AP):
SELECT SUM(HSL) AS AP_BALANCE
FROM ACDOCA
WHERE RBUKRS = '{company_code}' AND GJAHR = '{year}'
  AND KOART = 'K' AND RLDNR = '0L'
```

---

## 6. Valoración de Moneda Extranjera

```
¿Cuándo ejecutar FAGL_FCV?
│
├─ ¿Fin de mes/trimestre/año?
│  ├─ SÍ → Ejecutar valoración
│  └─ NO → Solo si hay reporting intermedio requerido
│
├─ ¿Qué cuentas valorar?
│  ├─ Balance sheet accounts en moneda extranjera
│  │  ├─ Cuentas bancarias FC
│  │  ├─ Partidas abiertas AP/AR en FC
│  │  └─ Préstamos en FC
│  └─ NO valorar: P&L accounts (excepto si norma local requiere)
│
├─ ¿Qué método de valoración?
│  ├─ Lowest value principle (conservador) → para activos
│  ├─ Strict lowest value → activos + pasivos separados
│  └─ Always valuate → todos al tipo de cambio de cierre
│
└─ ¿Cómo contabiliza?
   ├─ Diferencia → cuenta de diferencia de cambio (P&L)
   ├─ Reset al inicio del siguiente periodo (método de anulación)
   └─ Delta posting (solo diferencia vs valoración anterior)
```

---

## 7. Reconciliación GR/IR

```
Saldo en cuenta WRX (GR/IR clearing)
│
├─ ¿Hay recepciones de mercancía sin factura?
│  ├─ SÍ → Normal si factura está en tránsito
│  │       → Verificar antigüedad: si > 30 días, investigar
│  └─ NO ↓
│
├─ ¿Hay facturas sin recepción de mercancía?
│  ├─ SÍ → Factura contabilizada antes del GR
│  │       → Verificar con MM: ¿se espera el GR?
│  └─ NO ↓
│
├─ ¿Hay diferencias de precio (PRD)?
│  ├─ SÍ → Verificar si es precio estándar vs real
│  │       → MR11 para analizar diferencias
│  └─ NO ↓
│
├─ Ejecutar F.19 para reclasificación a cierre
│  ├─ GR sin IR → reclasificar a "accrued liabilities"
│  └─ IR sin GR → reclasificar a "prepaid expenses"
│
└─ Limpiar partidas compensables
   → MR11 (mantenimiento de saldo GR/IR)
   → F.13 (compensación automática)
```

---

## 8. Nueva Cuenta de Mayor

```
¿Crear cuenta nueva?
│
├─ ¿Balance o P&L?
│  ├─ Balance Sheet → group range B* (ej. 100000-399999)
│  └─ P&L → group range P* (ej. 400000-899999)
│
├─ ¿Grupo de cuentas?
│  ├─ Balance: activos, pasivos, patrimonio
│  └─ P&L: ingresos, gastos, costes
│
├─ ¿Cuenta de reconciliación?
│  ├─ SÍ → Asignar tipo: D (deudor), K (acreedor), A (activo)
│  │       → NO permitir contabilización directa
│  └─ NO → Cuenta normal de mayor
│
├─ ¿Gestión de partidas abiertas?
│  ├─ SÍ → Para cuentas transitorias, clearing, anticipos
│  │       → Marcar XOPVW en FS00
│  └─ NO → Para cuentas acumulativas (mayoría)
│
├─ ¿Moneda?
│  ├─ Moneda local → dejar en blanco (hereda de sociedad)
│  ├─ Moneda fija → especificar (USD, EUR, etc.)
│  └─ Todas las monedas → permitir posting en cualquier moneda
│
├─ ¿Field status group?
│  │ (OBC4 → determina qué campos son obligatorios/opcionales/ocultos)
│  ├─ G001 → General (cost element)
│  ├─ G004 → Balance sheet (sin cost element)
│  ├─ G005 → Cash/bank accounts
│  └─ Custom → según necesidad
│
└─ Crear:
   1. FSP0 → Nivel plan de cuentas (descripción, tipo)
   2. FSS0 → Nivel sociedad (field status, moneda, impuestos)
   3. O bien FS00 centralizado (ambos niveles)
```
