# S/4HANA 2023 — Extensibilidad FI

## In-App Extensibility (Key User Tools)

### Custom Fields

```
Key User Tools → Custom Fields (transaccion: /UI2/FLP → Key User menu)

Objetos FI extensibles:
  - Journal Entry (ACDOCA): agregar campos Z a asientos contables
  - Supplier Invoice: campos custom en facturas proveedor
  - Business Partner: campos adicionales en BP
  - Fixed Asset: campos custom en maestro activos
  - Bank Statement: campos en extracto bancario

Proceso:
  1. Key User → Custom Fields → seleccionar business context
  2. Create Field (tipo: text, number, date, checkbox, dropdown)
  3. Publicar → aparece automaticamente en apps Fiori
  4. Opcional: agregar logica custom via Custom Logic (BAdI)
```

### Custom Logic (BAdI basado en reglas)

```
Logica de negocio sin codigo ABAP:
  - Validaciones en journal entry posting
  - Derivaciones automaticas (profit center, segment)
  - Checks en payment approval
  - Reglas en bank statement matching

Proceso:
  1. Key User → Custom Logic → seleccionar business object
  2. Definir condicion (IF campo = valor)
  3. Definir accion (set value, raise message, block)
  4. Activar → se ejecuta en runtime
```

### Custom CDS Views

```
Vistas analiticas custom:
  - Crear sobre ACDOCA para reporting custom
  - KPIs financieros personalizados
  - Dashboards especificos por empresa

Ejemplo: Vista de gastos por profit center con filtro custom
  → Key User → Custom CDS Views → Create
  → Base: I_JournalEntryItem
  → Filtros y campos custom
  → Publicar como tile en Fiori Launchpad
```

## Side-by-Side Extensibility (BTP)

### Arquitectura

```
S/4HANA (on-premise/cloud)
    |
    +-- OData APIs (journal entries, invoices, payments)
    |
    +-- Event Mesh (document posted, payment created)
    |
    +-- BTP (Business Technology Platform)
        |
        +-- SAP Build Apps (low-code)
        +-- SAP Build Process Automation
        +-- Cloud Functions (Node.js/Java)
        +-- SAP Integration Suite
```

### Casos de uso FI en BTP

| Caso | Implementacion |
|------|---------------|
| Approval workflow custom | Build Process Automation + Fiori |
| Notificacion pago > $100k | Event Mesh → Cloud Function → Teams/Slack |
| Reconciliacion externa | Integration Suite → API → ACDOCA comparison |
| Dashboard CFO custom | SAC + CDS Views + BTP |
| Tax engine externo | Integration Suite → Vertex/Avalara API |
| E-invoicing | Event Mesh → Document Compliance → Gov portal |
| Bank connectivity custom | Integration Suite → SWIFT/bank APIs |

### APIs OData principales para FI

| API | Operaciones |
|-----|------------|
| API_JOURNALENTRYITEMBASIC_SRV | Read/Create journal entries |
| API_OPLACCTGDOCITEMCUBE_SRV | Analytical read |
| API_GLACCOUNTBALANCE_SRV | GL balances |
| API_SUPPLIERINVOICE_PROCESS_SRV | Create/Read/Update invoices |
| API_FIXEDASSET_0001 | Asset master read |
| API_BUSINESS_PARTNER | BP CRUD |
| API_BANKDETAIL_SRV | Bank master data |
| API_COMPANYCODE_SRV | Company code config |
| API_CREDITEXPOSURE_SRV | Credit data |

## ABAP Extensibility (Developer)

### BAdIs principales FI

| BAdI | Proposito | Uso tipico |
|------|-----------|-----------|
| BADI_ACC_DOCUMENT | Processing documento contable | Validar/modificar antes de post |
| BADI_FDCB_SUBACC01 | Subledger substitution | Derivar campos en linea |
| BADI_AP_PAYMENT | Payment program | Modificar seleccion de pagos |
| BADI_BANK_STATEMENT | Bank statement | Custom matching rules |
| FI_TAX_BADI | Tax determination | Logica impuesto custom |
| BADI_ASSET_ACQUISITION | Asset acquisition | Validar adquisicion |
| BADI_ASSET_RETIREMENT | Asset retirement | Validar retiro |
| BADI_FI_CLOSE_CHECK | Closing checks | Validaciones pre-cierre |
| BADI_ACC_GL_LINE | GL line item | Enriquecer linea GL |

### Validaciones y Sustituciones

```
GGB1: Definir validaciones
GGB4: Definir sustituciones
OBBH: Asignar validacion a sociedad (callup point)
OBBG: Asignar sustitucion a sociedad

Callup points:
  1 = Document header (BKPF fields)
  2 = Line item (BSEG/ACDOCA fields)
  3 = Complete document

User exits:
  RGGBR000 → Validation user exit
  RGGBS000 → Substitution user exit

Ejemplo validacion: bloquear posting si centro coste no pertenece a sociedad
Ejemplo sustitucion: derivar profit center desde centro coste automaticamente
```

### Enhancement Spots FI

```
Spots relevantes para extensiones custom:
  ES_SAPLFI_DOCUMENT_POSTING → Document posting
  ES_FI_CLOSING → Closing operations
  ES_PAYMENT_PROGRAM → F110 payment
  ES_BANK_STATEMENT → Bank statement processing
  ES_ASSET_ACCOUNTING → Asset transactions
```

## RAP APIs (S/4HANA Cloud & On-Premise)

### Released APIs para FI

| Business Object | RAP BO | Operaciones |
|----------------|--------|------------|
| Journal Entry | I_JournalEntryTP | Create, Read |
| Supplier Invoice | I_SupplierInvoiceTP | Create, Read, Release |
| Fixed Asset | I_FixedAssetTP | Create, Change, Read |
| Bank Statement | I_BankStatementTP | Import, Process |
| Payment Request | I_PaymentRequestTP | Create, Approve |
| Business Partner | I_BusinessPartnerTP | Create, Change, Read |

### Custom RAP Objects para FI

```
Patron tipico: extension de journal entry con campos custom

1. Crear tabla Z para extension (ZTFI_JE_EXT)
2. Crear CDS view projection sobre I_JournalEntryItem
3. Agregar campos custom via extension include
4. Crear behavior definition (managed, with draft)
5. Implementar validaciones en behavior class
6. Crear service definition + binding
7. Publicar en Fiori Elements
```

## Event-Driven Architecture

### Eventos FI disponibles

```
Business Events (Event Mesh / Enterprise Messaging):

Accounting Document:
  sap.s4.beh.accountingdocument.v1.AccountingDocument.Created.v1
  sap.s4.beh.accountingdocument.v1.AccountingDocument.Changed.v1

Supplier Invoice:
  sap.s4.beh.supplierinvoice.v1.SupplierInvoice.Created.v1
  sap.s4.beh.supplierinvoice.v1.SupplierInvoice.Changed.v1

Payment:
  sap.s4.beh.payment.v1.Payment.Created.v1
  sap.s4.beh.payment.v1.Payment.Completed.v1

Fixed Asset:
  sap.s4.beh.fixedasset.v1.FixedAsset.Created.v1
  sap.s4.beh.fixedasset.v1.FixedAsset.Changed.v1

Bank Statement:
  sap.s4.beh.bankstatement.v1.BankStatement.Imported.v1
```

### Ejemplo: Notificacion de asiento > $1M

```
Trigger: AccountingDocument.Created.v1
Filter: HSL > 1000000 (moneda local)
Action: Cloud Function → Microsoft Teams webhook
Payload: {doc_number, company_code, amount, user, timestamp}
```
