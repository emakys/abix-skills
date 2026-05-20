# S/4HANA 2023 — Extensibilidad MM

## Modelo de extensibilidad S/4HANA

```
Extensibilidad S/4HANA (de menor a mayor complejidad):

Tier 1: Key User (sin codigo)
  → Custom Fields, Custom Logic, Custom CDS Views
  → Fiori Launchpad config

Tier 2: Developer Extensibility (ABAP in S/4)
  → RAP-based APIs, BAdIs, CDS extend views
  → Released APIs only (no modificaciones de objetos SAP)

Tier 3: Side-by-Side (BTP)
  → Apps externas en BTP que consumen APIs S/4
  → Event Mesh, Integration Suite
  → Microservicios, Cloud Functions

Regla de oro S/4HANA 2023:
  NUNCA modificar objetos estandar SAP
  SIEMPRE usar APIs released o extension points oficiales
```

## Tier 1: Key User Extensibility

### Custom Fields (F1481)
```
App Fiori: "Custom Fields and Logic"

Business Contexts disponibles para MM:
  - Purchase Order (Header + Item)
  - Purchase Requisition (Header + Item)
  - Material Master
  - Business Partner (Supplier)
  - Goods Movement
  - Supplier Invoice

Proceso:
  1. Crear campo → nombre, tipo, longitud
  2. Asignar a Business Context(s)
  3. Asignar a UI Adaptation (donde aparece en Fiori)
  4. Publicar → campo disponible en:
     - Fiori apps automaticamente
     - OData APIs (campo aparece como extension)
     - CDS views analiticas
     - Output forms (SmartForms/Adobe)
     - Excel upload/download

Limitaciones:
  - Max ~100 custom fields por business context
  - Solo tipos simples (CHAR, NUMC, DATS, DEC, etc.)
  - No logica compleja (para eso → Custom Logic o BAdI)
```

### Custom Logic (reglas sin ABAP)
```
App Fiori: "Custom Fields and Logic" → Tab "Custom Logic"

Triggers disponibles:
  - Before Save (validacion)
  - After Save (post-processing)
  - After Modify (derivacion de valores)
  - Side Effects (UI refresh)

Ejemplo: Bloquear PO si proveedor tiene rating < 3
  Trigger: Before Save (Purchase Order)
  Condition: SupplierRating < 3
  Action: Raise Error "Proveedor con rating insuficiente"

Ejemplo: Auto-asignar centro coste por grupo material
  Trigger: After Modify (Purchase Order Item)
  Condition: MaterialGroup = 'Z001'
  Action: Set CostCenter = 'CC1000'
```

### Custom CDS Views (F5307)
```
App Fiori: "Custom CDS Views"

Permite crear CDS views analiticas sobre datos estandar:
  - Seleccionar campos de entidades estandar
  - Agregar campos custom (del Key User)
  - Definir asociaciones/joins
  - Publicar como OData para reporting

Ejemplo: Vista custom de POs con campo Sustainability Score
  → Base: I_PurchaseOrderItemTP
  → Agregar: Custom field ZZ_SUSTAIN_SCORE
  → Filtro: solo POs del ultimo ano
  → Publicar → usar en SAC o Excel
```

## Tier 2: Developer Extensibility (ABAP en S/4)

### Released APIs y objetos

En S/4HANA 2023 solo puedes usar objetos marcados como "Released" (C1 contract):

```
Verificar si un objeto es released:
  SE80 → objeto → Properties → API State = "Released"
  O: ADT → ABAP Repository → filtro "Released"

Tipos de released objects:
  - CDS Views (I_*, C_*, A_*)
  - BAdIs (enhancement spots released)
  - Interfaces (IF_*)
  - Classes (CL_* released)
  - Function Modules (BAPI_* la mayoria)
```

### RAP-based APIs para MM

```
Entidades RAP released para compras:

Purchase Order:
  I_PurchaseOrderTP → Transactional Processing (CRUD)
  I_PurchaseOrderItemTP → Items
  C_PurchaseOrderItemQuery → Analytical
  Behavior: R_PurchaseOrderTP (BDEF)

Purchase Requisition:
  I_PurchaseRequisitionTP → Transactional
  I_PurchaseRequisitionItemTP → Items

Material Document:
  I_MaterialDocumentTP → Transactional
  I_MaterialDocumentItemTP → Items

Supplier Invoice:
  I_SupplierInvoiceTP → Transactional

Ejemplo — Leer PO via RAP API (no BAPI):
  ReadView("I_PurchaseOrderItemTP")
  ReadBehaviorDefinition("R_PurchaseOrderTP")
```

### BAdIs released para MM (S/4HANA 2023)

```
Compras:
  MM_PUR_S4_PO_CUST         → PO processing (reemplaza ME_PROCESS_PO_CUST)
  MM_PUR_S4_PR_CUST         → PR processing
  MM_PUR_S4_PO_OUT          → PO output
  MM_PUR_S4_REL_CUST        → Release procedure custom

Inventario:
  MM_IM_S4_GOODS_MVT        → Goods movement (reemplaza MB_DOCUMENT_BADI)
  MM_IM_S4_PHYS_INV         → Physical inventory

Factura:
  MM_IV_S4_INVOICE          → Invoice processing
  MM_IV_S4_BLOCK            → Invoice block reasons

Material Master:
  MM_MM_S4_MATERIAL         → Material maintenance

IMPORTANTE:
  Los BAdIs clasicos (ME_PROCESS_PO_CUST, MB_MIGO_BADI, etc.)
  siguen funcionando en S/4 on-premise pero estan deprecated.
  Para nuevo desarrollo: usar los BAdIs _S4_.
```

### CDS View Extensions
```
Agregar campos custom a CDS views estandar:

DEFINE VIEW EXTENSION ZZ_I_PURCHASEORDERITEM
  FOR I_PurchaseOrderItemTP {
    -- Campos de tabla custom
    _Extension.ZZ_SustainScore as SustainabilityScore,
    _Extension.ZZ_ApprovalDate as CustomApprovalDate
}

Ventaja: campo aparece automaticamente en Fiori apps que usan la CDS
```

### ABAP Cloud (Restricted ABAP)
```
En S/4HANA Cloud y Public Cloud:
  - Solo "Restricted ABAP" (subconjunto del lenguaje)
  - No SELECT directo a tablas no-released
  - No CALL FUNCTION a FMs no-released
  - No modificaciones de objetos SAP

En S/4HANA On-Premise 2023:
  - ABAP completo disponible (classic + restricted)
  - Pero SAP RECOMIENDA usar restricted para futureproofing
  - Puedes elegir ABAP Language Version:
    - "ABAP for Cloud Development" (restricted)
    - "Standard ABAP" (classic, todo permitido)
```

## Tier 3: Side-by-Side Extensibility (BTP)

### Arquitectura
```
S/4HANA (on-premise/cloud)
    |
    +-- APIs OData → SAP BTP
    |                  |
    |                  +-- Custom Fiori App (UI5)
    |                  +-- Cloud Functions (Node.js/Java)
    |                  +-- Integration Suite (iFlows)
    |                  +-- Workflow Management
    |
    +-- Events → SAP Event Mesh → BTP subscribers
    |
    +-- SAP Build (low-code/no-code)
```

### OData APIs Released — MM (V2 y V4)

```
Purchase Order:
  API_PURCHASEORDER_PROCESS_SRV (V2) → CRUD PO
  Purchase Order OData V4             → released 2302+ (recomendado)

Purchase Requisition:
  API_PURCHASEREQ_PROCESS_SRV (V2)   → CRUD PR
  API_PURCHASEREQUISITION_2 (V4)     → released 2308+ (recomendado)
    - Delivery address type 'S' (Supplier) y 'C' (Customer)
    - Notes a nivel header (PurReqnHeaderNote)
    - Events: 'Item Changed', 'Item Created'

Supplier Invoice:
  API_SUPPLIERINVOICE_PROCESS_SRV (V2) → CRUD invoices

Goods Movement:
  API_MATERIAL_DOCUMENT_SRV (V2)      → Post goods movements

Material Master:
  API_PRODUCT_SRV (V2)                → Material/Product master

NOTA: I_PurchaseRequisition_Api01 esta DEPRECATED desde S/4HANA 2020.
      Usar API_PURCHASEREQUISITION_2 (V4) en su lugar.
```

### Eventos de procurement disponibles
```
Business Events (S/4HANA 2023):
  - PurchaseOrder.Created.v1
  - PurchaseOrder.Changed.v1
  - PurchaseRequisition.Created.v1
  - SupplierInvoice.Created.v1
  - GoodsMovement.Created.v1
  - BusinessPartner.Created.v1

Ejemplo: Notificar via Teams cuando PO > $100k
  S/4 → Event "PO.Created" → Event Mesh → Cloud Function →
  IF amount > 100000 THEN → Microsoft Teams webhook
```

### SAP Build (Low-Code)
```
SAP Build Apps: apps custom sin codigo
SAP Build Process Automation: workflows custom
SAP Build Work Zone: portal unificado

Ejemplo: Formulario de solicitud de compra custom
  → SAP Build Apps → formulario con campos custom
  → Llama API_PURCHASEREQ_PROCESS_SRV → crea PR en S/4
  → SAP Build Process Automation → workflow de aprobacion
  → Notificacion al comprador
```

## Decision tree: Que tipo de extensibilidad usar

```
Necesidad:
|
+-- Agregar campo a objeto estandar
|   +-- Campo simple (texto, numero, fecha)
|   |   → Key User: Custom Fields (Tier 1)
|   +-- Campo con logica compleja
|       → BAdI released (Tier 2) + Custom Field
|
+-- Validacion/regla de negocio
|   +-- Regla simple (if-then)
|   |   → Key User: Custom Logic (Tier 1)
|   +-- Regla compleja (multiples tablas, calculo)
|       → BAdI released (Tier 2)
|
+-- Nuevo reporte/analisis
|   +-- KPI simple sobre datos estandar
|   |   → Key User: Custom CDS View (Tier 1)
|   +-- Reporte complejo con logica
|       → ABAP CDS View + Fiori app (Tier 2)
|
+-- Integracion con sistema externo
|   +-- Unidireccional (S/4 → externo)
|   |   → Event Mesh + Cloud Function (Tier 3)
|   +-- Bidireccional (sync)
|       → Integration Suite iFlow (Tier 3)
|
+-- App completamente nueva
|   +-- UI simple (formulario)
|   |   → SAP Build Apps (Tier 3)
|   +-- App compleja con logica
|       → RAP + Custom Fiori App (Tier 2)
```

## Queries MCP para verificar extensibilidad
```
-- Buscar BAdIs released para PO
SearchObject("MM_PUR_S4*")
GetEnhancements("CL_MM_PUR_S4_PO")

-- Verificar si una CDS view es released
ReadView("I_PurchaseOrderItemTP")
-- En la metadata: apiState = "released", releaseContract = "C1"

-- Buscar extension points
SearchObject("BADI*MM*S4*")
GetEnhancements("SAPLMEGUI")

-- Verificar custom fields existentes
GetSqlQuery("SELECT FIELDNAME, ROLLNAME FROM DD03L WHERE TABNAME = 'EKKO' AND FIELDNAME LIKE 'ZZ%'")
```
