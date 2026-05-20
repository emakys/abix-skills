# Transacciones FI — Referencia Completa

Referencia exhaustiva de transacciones SAP FI organizadas por submódulo.
Incluye equivalente Fiori donde aplica.

---

## General Ledger (GL)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| FB01 | Contabilizar documento (general) | F0717 - Post General Journal Entry |
| FB02 | Modificar documento contable | F0718 - Manage Journal Entries |
| FB03 | Visualizar documento contable | F0718 - Manage Journal Entries |
| FB05 | Contabilizar con compensación | — |
| FB08 | Anular documento contable | F2761 - Manage Journal Entries (reverse) |
| FB09 | Modificar datos de línea de documento | — |
| FB50 | Contabilizar asiento de mayor | F0717 - Post General Journal Entry |
| FBL3N | Partidas individuales de cuenta de mayor | F0710 - Display Line Items |
| FS00 | Gestión centralizada de cuentas de mayor | F1526 - Manage G/L Account Master Data |
| FSP0 | Cuenta de mayor a nivel de plan de cuentas | — |
| FSS0 | Cuenta de mayor a nivel de sociedad | — |
| FS10N | Saldos de cuenta de mayor | F0711 - Display G/L Account Balances |
| FAGLB03 | Visualizar saldos GL (New GL) | F0711 |
| FAGLGVTR | Traspaso de saldos GL | — |
| F.01 | Listado RFBILA00 (balance/PL) | — |
| F.05 | Saldos extranjeros — valoración | — |
| FBD1 | Registrar documento periódico | — |
| FBD3 | Visualizar documento periódico | — |
| F.14 | Cuadre FC/ML (balance) | — |
| FBS1 | Contabilizar documento preliminar | — |
| F.81 | Ajuste de cuentas de mayor GR/IR | — |

### MCP — Consulta GL en ACDOCA

```sql
-- Partidas de mayor por sociedad y periodo
SELECT RCLNT, RLDNR, RBUKRS, GJAHR, BELNR, BUZEI, BSCHL, HKONT,
       RACCT, RHCUR, HSL, TSL, BUDAT, BLDAT, BLART, USNAM
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND GJAHR = '{fiscal_year}'
  AND POPER = '{period}'
  AND RLDNR = '0L'
ORDER BY BELNR, BUZEI
```

---

## Accounts Payable (AP)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| FB60 | Contabilizar factura de acreedor | F0859 - Create Supplier Invoice |
| FB65 | Contabilizar abono de acreedor | F0859 (credit memo) |
| F-43 | Contabilizar factura acreedor (clásica) | — |
| F-44 | Compensar acreedor | — |
| F-47 | Solicitud de anticipo acreedor | — |
| F-48 | Contabilizar anticipo acreedor | — |
| F-53 | Contabilizar pago a acreedor | — |
| F-54 | Compensar acreedor (con diferencias) | — |
| F-58 | Pago con cheque impreso | — |
| FBL1N | Partidas individuales de acreedor | F0413 - Display Supplier Line Items |
| FK10N | Saldos de acreedor | F0414 - Display Supplier Balances |
| F110 | Programa de pagos automáticos | F0735 - Schedule Payment Proposals |
| FBZP | Configuración del programa de pagos | — |
| MR8M | Anular factura logística (MIRO) | — |
| MIRO | Verificación de facturas logística | F1918 - Create Supplier Invoice (MM) |

### MCP — Consulta AP en ACDOCA

```sql
-- Partidas abiertas de acreedor
SELECT RBUKRS, LIFNR, BELNR, BUZEI, BUDAT, BLDAT, BLART,
       HSL, TSL, AUGDT, AUGBL, BSCHL, ZUONR, SGTXT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KOART = 'K'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
ORDER BY LIFNR, BUDAT
```

---

## Accounts Receivable (AR)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| FB70 | Contabilizar factura de deudor | F1564 - Post Outgoing Invoices |
| FB75 | Contabilizar abono de deudor | — |
| F-22 | Contabilizar factura deudor (clásica) | — |
| F-26 | Solicitud anticipo de deudor | — |
| F-27 | Contabilizar anticipo deudor | — |
| F-28 | Cobro de deudor | — |
| F-29 | Contabilizar cobro con cheque | — |
| F-30 | Contabilizar cobro con letra | — |
| F-32 | Compensar deudor | — |
| F-37 | Compensar deudor con diferencias | — |
| F-39 | Clearing manual de deudor | — |
| FBL5N | Partidas individuales de deudor | F0416 - Display Customer Line Items |
| FD10N | Saldos de deudor | F0417 - Display Customer Balances |
| FD32 | Gestión de límite de crédito | F3282 - Manage Credit Limit |
| F150 | Programa de reclamación (dunning) | F2917 - Schedule Dunning Runs |
| FBMP | Pagos masivos | — |

### MCP — Consulta AR en ACDOCA

```sql
-- Antigüedad de saldos de deudor
SELECT RBUKRS, KUNNR, BELNR, BUZEI, BUDAT, FAEDT, BLART,
       HSL, TSL, AUGDT, AUGBL, ZUONR, SGTXT,
       DATEDIFF(CURRENT_DATE, FAEDT) AS DAYS_OVERDUE
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KOART = 'D'
  AND AUGDT IS NULL
  AND RLDNR = '0L'
ORDER BY KUNNR, FAEDT
```

---

## Asset Accounting (AA)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| AS01 | Crear dato maestro de activo fijo | F2740 - Manage Fixed Assets |
| AS02 | Modificar dato maestro de activo fijo | F2740 |
| AS03 | Visualizar dato maestro de activo fijo | F2740 |
| AS05 | Bloquear activo fijo | — |
| AS06 | Crear subnúmero de activo | — |
| ABZON | Adquisición por entrada de mercancía | — |
| AB01 | Contabilizar movimiento de activo | — |
| ABAON | Baja por enajenación con deudor | F4575 - Post Asset Retirement |
| ABT1N | Transferencia entre sociedades | — |
| ABUMN | Transferencia dentro de sociedad | F4573 - Post Asset Transfer |
| ABNAN | Post-capitalización | — |
| ABN1 | Baja sin ingreso (desguace) | — |
| AFAB | Ejecución de amortización | F2739 - Schedule Depreciation Runs |
| AFAR | Recálculo de amortización | — |
| AFBP | Planificación de amortización | — |
| AJAB | Cambio de ejercicio de activos | — |
| AJRW | Cambio de ejercicio fiscal AA | — |
| AW01N | Asset Explorer | F2741 - Asset Explorer |
| AR01 | Crear clase de activo | — |
| AR02 | Modificar clase de activo | — |
| OAOA | Asignar plan de valoración a sociedad | — |
| AO90 | Cuentas de mayor para clases de activos | — |
| OADB | Áreas de valoración por clase de activo | — |

---

## Bank Accounting (BK)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| FI12 | Gestión de bancos propios | F1649 - Manage House Banks |
| FF67 | Entrada manual de extracto bancario | F1603 - Process Bank Statements |
| FF63 | Configuración de extracto electrónico | — |
| FF_5 | Posición de tesorería | F0861 - Cash Position |
| FEBA | Postprocesar extracto bancario | — |
| FBCJ | Libro de caja | F3845 - Manage Cash Journal |
| FLB1 | Aviso de pago por EDI | — |
| FLB2 | Importar extracto bancario (MT940) | — |

---

## Tax (TX)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| FTXP | Gestionar indicadores de impuesto | — |
| OBYZ | Asignar esquema de cálculo a país | — |
| OB40 | Asignar cuentas de impuesto | — |
| OBWI | Retención de impuestos ampliada | — |
| J_1EWHT_CERT | Certificados de retención | — |

---

## Configuration (CFG)

| TCode | Descripción | Área |
|-------|-------------|------|
| OB52 | Abrir/cerrar periodos contables | Periodos |
| OBA7 | Tipos de documento | Documentos |
| OBC4 | Grupos de status de campo | Campo |
| OB41 | Claves de contabilización | Campo |
| FBN1 | Rangos de número de documento FI | Numeración |
| OB13 | Asignar variante de ejercicio fiscal | Ejercicio |
| OBR2 | Asignar variante de periodos | Periodos |
| OB29 | Grupos de tolerancia de empleados | Tolerancias |
| OBD2 | Crear grupo de cuentas deudor | Maestros |
| OBD3 | Crear grupo de cuentas acreedor | Maestros |
| OBD4 | Asignar grupo cuentas a sociedad | Maestros |
| OBA0 | Variante de ejercicio fiscal | Ejercicio |
| OBA3 | Grupos de tolerancia de compensación | Tolerancias |
| OBY6 | Crear/copiar sociedad | Estructura |
| OB53 | Crear plan de cuentas | Maestros |
| OB58 | Asignar cuentas de diferencia cambio | Divisas |
| OBYC | Cuentas de mayor automáticas MM | Integración MM |
| VKOA | Determinación de cuentas SD | Integración SD |

---

## Reporting (RPT)

| TCode | Descripción | Fiori App |
|-------|-------------|-----------|
| S_ALR_78012547 | Balance de sumas y saldos | F0708 - Trial Balance |
| S_ALR_78012078 | Informe de antigüedad AP | F2220 - Aged Payables |
| S_ALR_78012066 | Informe de antigüedad AR | F2219 - Aged Receivables |
| S_ALR_78012357 | Reporte de activos fijos | F2741 - Asset Reports |
| GRR1 | Crear report financiero (Report Painter) | — |
| FGI0 | Planificación financiera | — |

---

## SPRO Paths — Navegación rápida

```
SPRO → Financial Accounting →
  ├── Financial Accounting Global Settings
  │   ├── Company Code → OBY6
  │   ├── Fiscal Year → OBA0, OB13
  │   ├── Posting Periods → OB52, OBR2
  │   ├── Document → OBA7, FBN1
  │   ├── Field Status → OBC4
  │   └── Tolerance Groups → OB29, OBA3
  ├── General Ledger Accounting
  │   ├── Master Data → FS00, OB53
  │   ├── Document Splitting → FAGL_SPLIT_CUST
  │   └── Parallel Accounting → FINSC_LEDGER
  ├── Accounts Payable
  │   ├── Payment Program → FBZP
  │   └── Automatic Payments → F110 config
  ├── Accounts Receivable
  │   ├── Credit Management → FD32, UKM
  │   └── Dunning → F150 config
  ├── Asset Accounting
  │   ├── Depreciation Areas → OADB
  │   ├── Asset Classes → AR01, AO90
  │   └── Depreciation → AFAB config
  └── Bank Accounting
      ├── House Banks → FI12
      └── Bank Statements → FF63
```
