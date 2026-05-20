# S/4HANA 2023 — Fiori Apps para MM Procurement

## Concepto Fiori en S/4

En S/4HANA 2023 las Fiori Apps son la UI principal. Las transacciones SAP GUI siguen
funcionando pero SAP recomienda Fiori para usuarios finales.

Cada app tiene: App ID (F####), Technical Name, y SAP Fiori Launchpad Catalog.

## Apps de compras — Purchase Requisitions

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F0843 | Manage Purchase Requisitions | ME51N/ME52N/ME53N | Transactional |
| F1984 | Create Purchase Requisition | ME51N | Transactional |
| F2229 | Approve Purchase Requisitions | ME54N | Approval |
| F1986 | Central Purchase Requisitions | — | NEW S/4 only |
| F2334 | Track Purchase Requisition | — | Analytical |
| F3810 | Purchase Requisition Item | — | Object Page |

## Apps de compras — Purchase Orders

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F2735 | Manage Purchase Orders | ME21N/ME22N/ME23N | Transactional |
| F2735A | Manage Purchase Orders v3 | ME21N (mejorada) | Transactional |
| F0861 | Monitor Purchase Order Items | ME2M/ME2L | Analytical |
| F0859 | Create Supplier Invoice | MIRO | Transactional |
| F4988 | Manage Purchase Orders - Prof. | ME21N (advanced) | Transactional |
| F3066 | Purchase Order Collaboration | — | NEW S/4 only |

## Apps de inventario — Stock & Goods Movement

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F1234 | Post Goods Receipt | MIGO (GR) | Transactional |
| F1602 | Post Goods Issue | MIGO (GI) | Transactional |
| F2685 | Manage Stock | MB52/MMBE | Overview |
| F4379 | Stock - Single Material | MMBE | Analytical |
| F3889 | Manage Physical Inventory Docs | MI01-MI07 | Transactional |
| F4415 | Physical Inventory Overview | MI06/MI20 | Analytical |
| F1080 | Post Goods Movement | MIGO | Transactional |

## Apps de facturacion — Invoice Verification

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F0859 | Create Supplier Invoice | MIRO | Transactional |
| F1927 | Manage Supplier Invoices | MIR4/MIR5 | Transactional |
| F4416 | Display Supplier Invoice | MIR4 | Display |
| F2244 | Release Blocked Invoices | MRBR | Approval |
| F5351 | Manage Invoice Verification | MIRO + MRBR | Combined |

## Apps de datos maestros

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F1804 | Manage Business Partner | BP/MK01/XK01 | Transactional |
| F1602 | Manage Product Master | MM01/MM02/MM03 | Transactional |
| F2093 | Manage Purchasing Info Records | ME11/ME12/ME13 | Transactional |
| F2074 | Manage Source Lists | ME01 | Transactional |
| F2094 | Manage Purchasing Contracts | ME31K/ME32K | Transactional |

## Apps analiticas — Embedded Analytics

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F0862 | Purchase Order Analysis | ME80FN | Analytical |
| F0863 | Purchasing Spend Analysis | — | Analytical |
| F2100 | Stock Overview Analysis | MB52/MCBA | Analytical |
| F2101 | Inventory Turnover | MCBE | Analytical |
| F3045 | Supplier Evaluation | ME61 | Analytical |
| F5115 | Purchase Requisition Tracking | — | Analytical |
| F0860 | Overdue Materials | — | Situation |

## Apps de Situation Handling (alertas inteligentes)

```
Situaciones predefinidas para procurement:
  - Overdue Purchase Order Items (F0860)
  - Supplier Invoice Blocked (F2244)
  - Purchase Requisition Not Processed
  - GR/IR Clearing Account Discrepancy
  - Stock Below Safety Level

Config: SPRO → SAP Customizing → Situation Handling →
  Define Situation Types → Assign Anchor Objects
```

## Fiori Launchpad — Catalogs y Groups

### Catalogs relevantes MM
```
SAP_MM_BC_PO_MANAGE      → Purchase Order management
SAP_MM_BC_PR_MANAGE      → Purchase Requisition management
SAP_MM_BC_IM_GR          → Goods Receipt
SAP_MM_BC_IV_MANAGE      → Invoice Verification
SAP_MM_BC_IM_STOCK       → Stock Overview
SAP_MM_BC_MM_MANAGE      → Material Master
SAP_MM_BC_SRCSUPPLY      → Source of Supply
```

### Roles estandar
```
SAP_BR_PURCHASER             → Comprador
SAP_BR_PURCHASING_MANAGER    → Jefe de compras
SAP_BR_INVENTORY_MANAGER     → Gestor de inventario
SAP_BR_WAREHOUSE_CLERK       → Empleado almacen
SAP_BR_AP_ACCOUNTANT         → Contable AP
SAP_BR_MASTER_SPECIALIST_MM  → Especialista datos maestros
```

## Custom Fiori Apps — Extensibilidad

### In-App Extensibility (sin codigo)
```
Key User Tools (transaccion: /n/UI2/FLP → Key User menu):
  - Custom Fields: agregar campos Z a apps estandar
  - Custom Logic: agregar logica de negocio (BAdI basado en reglas)
  - Custom CDS Views: crear vistas analiticas custom
  - Custom Analytical Queries: KPIs custom

Ejemplo: agregar campo "Sustainability Rating" a la app Manage Purchase Orders
  → Key User → Custom Fields → PurchaseOrder → Create Field
  → Publicar → aparece automaticamente en la app Fiori
```

### Side-by-Side Extensibility (BTP)
```
SAP BTP (Business Technology Platform):
  - Custom Fiori app que consume APIs OData de S/4
  - Event-driven: escuchar eventos de procurement
  - Cloud Functions para logica custom

Ejemplo: Notificacion Slack cuando se crea PO > $100k
  → S/4 Event → BTP Event Mesh → Cloud Function → Slack API
```

## Equivalencia rapida SAPGUI → Fiori MM

| Si preguntan por... | App Fiori equivalente | App ID |
|---------------------|----------------------|--------|
| ME21N / ME22N / ME23N | Manage Purchase Orders | F2735 / F0348A |
| ME51N / ME52N / ME53N | Manage Purchase Requisitions | F0843 / F0349A |
| ME28 / ME29N (liberar PO) | My Inbox – Approve Purchase Order | F1640 |
| ME31K / ME32K (contratos) | Manage Contracts | F2094 / F2209 |
| ME31L / ME32L (sched. agreements) | Manage Scheduling Agreements | F2145 |
| ME41 / ME47 / ME49 (RFQ) | Manage RFQs | F2049 |
| ME11 / ME12 / ME13 (info records) | Manage Purchasing Info Records | F2093 / F2296 |
| ME61 / ME65 (eval. proveedor) | Operational Supplier Evaluation | F1662A / F3045 |
| MIGO (GR vs PO) | Post Goods Receipt for PO | F0843A / F1234 |
| MIGO (general) | Post Goods Movement | F1080 / F1048A |
| MIRO | Create/Manage Supplier Invoices | F0859 / F1927 |
| MRBR (liberar facturas) | Release Blocked Invoices | F2244 / F2027 |
| MMBE / MB52 | Stock – Single Material / Manage Stock | F4379 / F2685 / F2063 |
| MB51 (docs material) | Goods Movement Analysis | F2077 |
| MB5T (stock transito) | Overdue Materials – Stock in Transit | F2348 |
| MI01 / MI04 / MI07 | Physical Inventory apps | F1507 / F1508 / F1509 / F3889 |
| MD01 / MD01N (MRP) | MRP Cockpit | F2064 |
| MD04 (stock/requirements) | Monitor Material Coverage | F2065 |
| ME57 / ME5A (convertir PR) | Process Purchase Requisitions | F1048A |
| MM01 / MM02 / MM03 | Manage Product Master | F1602 / F2771 |
| BP / XK01 / MK01 (proveedor) | Manage Business Partner | F1804 / F0354 |
| — (cockpit) | Procurement Overview Page | F1990 |
| — (spend analysis) | Purchasing Spend | F2416 / F0863 |

> Nota: Algunos App IDs tienen versiones Fiori 2 y Fiori 3. Ambas coexisten en S/4HANA 2023.

---

## Queries MCP para verificar apps disponibles
```sql
-- Catalogos de Fiori activados
-- (No hay tabla directa, pero se puede verificar roles)
-- Verificar via ReadProgram o GetTransaction

-- Verificar si una transaccion redirige a Fiori
GetTransaction("ME21N")
-- En S/4 2023: puede redirigir a Fiori app si esta configurado

-- Buscar BSP apps (Fiori backend)
SearchObject("/UI2/FLP*")
SearchObject("MM_PUR_PO*")
```
