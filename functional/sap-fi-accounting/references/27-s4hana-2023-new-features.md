# S/4HANA 2023 — New Features FI

## 1. Universal Journal (ACDOCA) — Core

```
Single source of truth para todas las contabilizaciones financieras:
- Elimina reconciliacion entre GL, subledger, CO
- Integracion real-time CO-FI (no reconciliacion periodica)
- Hasta 10 monedas paralelas por ledger
- Extension ledgers para ajustes locales
- Material Ledger integrado
```

## 2. Business Partner (BP) Obligatorio

```
Reemplaza KNA1 (cliente) y LFA1 (proveedor) standalone:
- BUT000 como tabla central
- Roles: FLCU00 (customer) + FLVN00 (vendor)
- CVI (Customer-Vendor Integration) para migracion
- Transaccion BP reemplaza XK01/MK01 y XD01/FD01
- Un BP puede ser cliente Y proveedor simultaneamente
```

## 3. New Asset Accounting

```
Totalmente integrado en ACDOCA:
- No hay tablas AA separadas para contabilizaciones
- Valoracion paralela nativa por area depreciacion por ledger
- Contabilizacion real-time (no periodica al GL)
- Migracion desde classic AA: RASFIN_MIGRATION
- APC values y depreciation en ACDOCA (no ANLC/ANLP)
```

## 4. Document Splitting Mejorado

```
IMPORTANTE: New GL esta activo por diseno en S/4HANA.
Document Splitting es OPCIONAL y debe activarse explicitamente antes del go-live.
Activacion posterior en produccion puede causar inconsistencias.

Capacidades cuando esta activo:
- Balance sheet por profit center y segmento
- Cuentas zero-balance para splitting
- Asignacion pasiva para items sin asignar
- Simulacion online disponible
- Splitting rules configurables por tipo cuenta GL
- Business Transaction Variants para control granular
- Default Profit Center para balance sheet accounts via FAGL3KEH

Activacion:
  SPRO → Financial Accounting → General Ledger → Business Transactions →
    Document Splitting → Activate Document Splitting
  → Definir splitting rules ANTES del go-live
  → Asignar profit center default via FAGL3KEH para cuentas balance sheet
```

## 5. Central Finance (CFIN)

```
Replicar journals de multiples sistemas fuente:
- Reporting centralizado sin data warehouse
- Pago centralizado y procurement centralizado
- AIF mapping para armonizacion y monitoreo de errores
- CFINDEF cockpit
- Replicacion real-time via SLT (System Landscape Transformation)
- Soporte para multiples ERPs fuente (SAP + non-SAP)

Arquitectura replicacion:
  Source ERP → SLT (trigger-based) → RFC → S/4 CFIN Interface → AIF → ACDOCA
  - SLT registra triggers en tablas fuente
  - AIF procesa, monitorea y maneja errores
  - Errores visibles en AIF Monitor (transaccion /AIF/IFMON)

Novedades S/4HANA 2023:
  - Application engine 'XML, bgRFC runtime' soportado (solo desde 2023)
  - AIF serialization mejorada (postings en orden correcto)
  - Fiori apps para CFIN: cockpit y monitoreo
  - Soporte S/4HANA Cloud Public Edition como source system
```

## 6. Advanced Payment Management

| Feature | Descripcion |
|---------|-------------|
| Payment Factory | Pagos centralizados cross-company code |
| Payment Approval | Workflow aprobacion via Fiori |
| BCM | Bank Communication Management |
| SWIFT/SEPA/ACH | Integracion bancaria nativa |
| Payment Monitoring | Dashboard tiempo real |

## 7. Financial Close Cockpit

```
Gestion estructurada del cierre financiero:
- Task list management con dependencias
- Status tracking y monitoreo en tiempo real
- Integracion con apps de cierre (FAGL_FCV, AFAB, F.19, etc.)
- Parallel execution donde sea posible
- Audit trail completo
- Fiori apps: F2654 (Overview), F2655 (Manage Tasks)
```

## 8. Credit Management (FIN-FSCM-CR)

```
UKM reemplaza FD32 clasico:
- Calculo exposicion crediticia en tiempo real
- Basado en Business Partner (no customer)
- Integracion con SD credit check
- Scoring basado en reglas BRF+
- Dashboards Fiori para monitoreo
- Multiple credit segments
- App: F4549 Manage Customer Credit Exposure
```

## 9. Accrual Engine (ACE)

```
Gestion automatizada de accruals/deferrals:
- Accruals basados en contrato
- Reemplaza manual FBS1/F.81 para accruals recurrentes
- Integracion con Universal Journal
- Calculo automatico, posting y reversal
- Soporte multi-ledger
- App: F3737 Manage Accruals
```

## 10. Embedded Analytics

```
Analitica en tiempo real sin extraccion a BW:
- CDS Views analiticas (I_JournalEntry, I_TrialBalance, etc.)
- KPIs en Fiori Launchpad tiles
- Custom analytical queries via Key User tools
- SAP Analytics Cloud (SAC) conexion directa
- Virtual Data Model para finanzas
- Drilldown desde KPI hasta documento individual
```

## 11. Flexible Workflow

```
Workflows basados en BRF+:
- Aprobacion de asientos contables
- Aprobacion de pagos
- Control presupuestario y liberacion
- Fiori My Inbox integracion
- Configuracion sin codigo (BRF+ rules)
- Escalation y delegation nativas
```

## 12. Tax Reporting Cockpit

```
Compliance fiscal centralizado:
- Reporting especifico por pais
- SAF-T (Standard Audit File for Tax) soporte
- Tax determination con motores externos
- Integracion con Vertex, Thomson Reuters
- E-invoicing / factura electronica
- Tax Declaration Framework
```

## 13. Group Reporting (FIN-CS)

```
Reemplaza EC-CS para consolidacion:
- Consolidacion integrada en S/4HANA (componente FIN-CS)
- Eliminacion intercompany automatica
- Currency translation con tasas por unidad de consolidacion (nuevo 2023)
- Data collection desde multiples fuentes
- Real-time consolidation
- Fiori-based reporting
- EC-CS end of maintenance: 31 diciembre 2025

Novedades S/4HANA 2023:
- Consolidation unit names extendidos a 18 caracteres (antes 6)
- Reference nodes en global hierarchies (reusar nodos entre jerarquias)
- Realignment mejorado para preparation ledger
- Data check al cargar correction data
- Spot rates por unidad de consolidacion en currency translation
- BAdI para seleccionar exchange rate especifico en currency translation
- Manage Workflows for Group Journal Entries (dual control principle)
- Tool de migracion de Financial Consolidation → Group Reporting
```

## 14. Cash Management Enhanced

```
Gestion de tesoreria mejorada:
- Cash Position real-time (F2030)
- Liquidity Forecast (F2031)
- Bank Account Management centralizado
- Cash pooling y netting
- Integracion con payment program
- SAP Multi-Bank Connectivity
```

## 15. Validation Result App (2023)

```
App para validacion de calidad de datos en cierre financiero:
  - Definir reglas de validacion de saldos por cuenta
  - Ejecutar validaciones sobre posiciones financieras
  - Dimensiones: cost object, profit center, segment
  - Util para detectar inconsistencias antes del cierre
  - Integrado con Financial Close Cockpit
```

## 16. Journal Upload Cases con AI (2023)

```
Aceleracion de asientos de cierre con asistencia de IA:
  - Upload masivo de journal entries via Excel
  - AI sugiere cuentas y dimensiones basado en historico
  - Validacion automatica pre-posting
  - App: Upload General Journal Entries (F1340)
  - Template Excel descargable, modificable y cargable
  - Disponible desde S/4HANA 1709, mejorado con AI en 2023
```

## ECC → S/4HANA — Cambios Clave para FI

| ECC | S/4HANA | Impacto |
|-----|---------|---------|
| BSEG (tabla real) | BSEG (tabla real reducida) + ACDOCA | BSEG sigue existiendo pero ACDOCA es fuente de verdad |
| KNA1/LFA1 standalone | BP obligatorio (BUT000) | Migracion CVI requerida |
| Classic AA (ANLC/ANLP) | New AA en ACDOCA | RASFIN_MIGRATION |
| CO posting separado | CO en ACDOCA | No reconciliacion necesaria |
| FD32 credit | UKM credit management | Nueva gestion de credito |
| FAGLFLEXT totals | ACDOCA aggregated | No tabla de totales |
| EC-CS consolidation | Group Reporting (FINCS) | Nuevo motor consolidacion |
| Classic bank statement | Advanced Payment Mgmt | Integracion bancaria mejorada |
| Manual accruals (FBS1) | Accrual Engine (ACE) | Automatizacion de provisiones |
| Report Painter | CDS + SAC | Analitica embebida |
| FBCJ Cash Journal | Enhanced Cash Mgmt | Tesoreria integrada |

## Simplification List — Items Eliminados FI

```
Items eliminados o simplificados en S/4:
- Classic GL (GLT0, KNC1-3, LFC1-3) → eliminadas, usar ACDOCA
- Special Purpose Ledger (FI-SL) → eliminado, usar ledger approach
- Classic Asset Accounting → eliminado, solo New AA
- Classic credit management → deprecated, usar UKM
- Document Summarization (BKPF.BSTAT='S') → deshabilitado
- Costing-based CO-PA → NO eliminado, pero account-based COPA (Margin Analysis)
  es OBLIGATORIO y la direccion estrategica. Ambos pueden coexistir.
  Account-based COPA usa ACDOCA directamente.
- Profit center accounting (EC-PCA) → eliminado, usar ACDOCA con PRCTR
```
