# S/4HANA 2023 — Funcionalidades Nuevas MM

## 1. Central Procurement

### Concepto
Compras centralizadas que operan sobre multiples backends S/4HANA.
Un sistema central gestiona contratos, proveedores y compras para N sistemas.

```
Central Procurement Hub (S/4HANA)
    |
    +-- Backend S/4 #1 (Planta Mexico)
    +-- Backend S/4 #2 (Planta Colombia)
    +-- Backend S/4 #3 (Planta Peru)

El hub centraliza:
  - Contratos marco
  - Evaluacion proveedores
  - Central purchase requisitions
  - Sourcing decisions
```

### Enhancements 2023
```
- Mass Changes to Central Purchase Contracts (con simulation jobs)
- Consumption bar: muestra consumo agregado de todos los contratos distribuidos
- Guided simulation para cambios masivos
- Change document display en Central Purchase Contracts
- Sourcing projects: agregar proveedores despues de publicar el proyecto
```

### Config
```
SPRO → Materials Management → Purchasing → Central Procurement →
  - Activate Central Procurement
  - Define Connection to Backend Systems (RFC)
  - Define Central Contracts
```

## 2. Intelligent Sourcing

### Source Assignment con Machine Learning
```
S/4HANA 2023 puede sugerir proveedor automaticamente basado en:
  - Historial de compras (POs anteriores del mismo material)
  - Performance del proveedor (on-time delivery, quality)
  - Precio historico
  - Capacidad del proveedor

Config: SPRO → MM → Purchasing → Source Determination →
  Enable Intelligent Source Determination
  Requiere: SAP AI Foundation o BTP AI Services
```

### Automatic Source Assignment
```
MRP genera PR → Source assignment automatico basado en:
  1. Quota arrangement (si existe)
  2. Source list (si marcada como fija)
  3. Info record (precio mas bajo)
  4. Contract (si vigente)
  5. ML suggestion (si activado)
```

## 3. SAP Business Network Integration

### Concepto
Reemplaza la integracion directa con proveedores (EDI/IDoc/email) con
una plataforma de red empresarial (antes Ariba Network).

```
Comprador (S/4HANA) → SAP Business Network → Proveedor
  PO → Network → PO Confirmation
  Invoice → Network → Invoice verification
  Delivery notification → Network → GR trigger

Config: SPRO → MM → Purchasing → SAP Business Network →
  Activate Integration → Define Connection
```

## 4. Predictive MRP

### Concepto
MRP mejorado con algoritmos predictivos que consideran:
- Patrones de demanda historicos
- Estacionalidad
- Tendencias
- Eventos externos (si conectado a SAP IBP)

```
Config: SPRO → Production → MRP → Predictive MRP →
  - Activate Predictive Functionality
  - Define Prediction Models
  - Requiere: SAP Analytics Cloud o BTP predictive services

Transaccion: MD01 con flag "Use Predictive"
```

## 5. Flexible Workflow para Procurement

### Concepto
Reemplaza/complementa la release strategy clasica con workflows
configurables en Fiori sin necesidad de ABAP.

```
Caracteristicas:
  - Configuracion via Fiori (no SPRO)
  - Aprobadores dinamicos (por org structure, no hardcoded)
  - Escalation automatica (timeout)
  - Delegacion de aprobacion
  - Mobile approval (Fiori mobile)
  - Parallel approval (multiples aprobadores simultaneos)

App Fiori: "Manage Workflows for Purchase Requisitions" (F3201)
App Fiori: "Manage Workflows for Purchase Orders"
App Fiori: "My Inbox" (F0570) → aprobar desde ahi
```

### Diferencias vs Release Strategy clasica
| Aspecto | Release Strategy | Flexible Workflow |
|---------|-----------------|-------------------|
| Config | SPRO + clasificacion | Fiori (key user) |
| Aprobadores | Fijos (release codes) | Dinamicos (org structure) |
| Escalacion | No | Si (configurable) |
| Delegacion | No | Si |
| Paralelo | No (secuencial) | Si |
| Mobile | No (SAP GUI) | Si (Fiori) |
| Complejidad | Alta | Media |

## 6. Advanced Available-to-Promise (AATP)

```
Verificacion de disponibilidad avanzada:
  - Considera multiples centros
  - Redistribucion automatica de stock
  - Backorder processing
  - Allocations (cuotas por cliente)

Enhancements 2023:
  - Third-Party Order Processing (TPOP) via Alternative-Based Confirmations
    → usa stock en proveedor para cantidades abiertas
  - BPS + Transportation Management (SAP TM) integracion
    → delegacion de scheduling de transporte
  - Change documents para Product Allocation Sequence/Object
  - Supply Protection: "Restriction outside Planned Protection"
    → ordenes protegidas siempre obtienen confirmacion dentro de cantidades protegidas

Config: SPRO → Production → Advanced ATP →
  Activate AATP → Define Checking Rules
  Requiere: aATP add-on activado
```

## 7. Batch Management con ATTP

### Advanced Track and Trace for Pharmaceuticals
```
Tracking de lotes desde produccion hasta consumo:
  - Numero de serie unico por unidad
  - Verificacion de autenticidad
  - Recall management
  - Compliance regulatorio (pharma, food)

S/4HANA 2023: integrado nativamente (antes era add-on)
Transaccion: /STTPEC/COCKPIT
```

## 8. Embedded Stewardship (Data Quality)

```
Verificacion automatica de calidad de datos maestros:
  - Material master completeness check
  - Vendor master data quality score
  - Duplicados potenciales
  - Campos faltantes por uso (ej: material sin vista compras pero tiene POs)

App Fiori: "Master Data Quality" (F5600)
```

## 9. Purchase Contract Lifecycle Management

```
Gestion completa del ciclo de vida del contrato:
  - Creacion → Negociacion → Aprobacion → Vigencia → Renovacion/Cierre
  - Monitoreo de consumo vs tope
  - Alertas de vencimiento
  - Version management
  - Integration con Legal (DocuSign, Adobe Sign)

App Fiori: "Manage Purchase Contracts" (F2094)
App Fiori: "Monitor Purchase Contracts" (F2095)
```

## 10. Lean Services (Strategic Direction for Service Procurement)

### Concepto
```
Lean Services reemplaza MM-SRV (classic service procurement):
  - Proceso simplificado para compra de servicios externos
  - S/4HANA Cloud public edition SOLO soporta Lean Services
  - S/4HANA on-premise: Lean Services coexiste con MM-SRV (transitional)
  - SAP's strategic solution — MM-SRV sera deprecado
```

### Diferencias clave vs MM-SRV
| Aspecto | MM-SRV (clasico) | Lean Services |
|---------|-------------------|---------------|
| Material type | DIEN | SERV (con Product Type) |
| Service specs | ML81N (service entry sheet) | Fiori app only |
| Limits | Classic limits | Enhanced Limits E (valor sin cantidad) |
| Service Entry Sheet | ML81N/ML85 | "Manage Service Entry Sheet" Fiori |
| Hierarchies | Service specifications | Item hierarchies (2023) |
| Approval | Release strategy | Flexible Workflow |
| API | BAPI_ENTRYSHEET_CREATE | OData V4 |

### Migration from MM-SRV
```
S/4HANA 2023+ soporta migracion:
  - Service Purchase Orders → Lean format
  - Service-Based Purchasing Contracts → Lean Contracts
  - Opcion: flat item lists o hierarchical structures
  - Migration tool in SPRO
```

### Config
```
SPRO → Materials Management → External Services Management →
  Lean Services → Activate Lean Service Processing
```

## 11. Product Sourcing — Carbon Footprint

```
S/4HANA 2023 permite solicitar datos de huella de carbono en RFQs:
  - Comprador incluye requisito de carbon footprint en RFQ
  - Proveedor proporciona datos en su quotation
  - Datos integrados en evaluacion de proveedores
  - Model Product Specifications: templates reutilizables para docs de compra
    (sets estructurados de items material + servicio)

App: "Manage Model Product Specifications" (con import function mejorada en 2023)
```

## 12. Sustainability in Procurement

```
S/4HANA 2023 incorpora metricas de sostenibilidad:
  - CO2 footprint por proveedor
  - Sustainability rating en evaluacion proveedores
  - Green procurement KPIs
  - Product carbon footprint tracking

App Fiori: "Product Footprint Management"
Requiere: SAP Sustainability Control Tower (BTP)
```

## 11. Key User Extensibility — Custom Fields & Logic

### Custom Fields (sin ABAP)
```
Agregar campos Z a objetos estandar desde Fiori:
  - Purchase Order → campo "Sustainability Score"
  - Material → campo "Carbon Footprint"
  - Vendor → campo "ESG Rating"

App: "Custom Fields and Logic" (F1481)
  → Crear campo → Asignar a Business Context → Publicar
  → Campo aparece automaticamente en:
    - Fiori apps
    - OData APIs
    - CDS views analiticas
    - Output forms
```

### Custom Logic (sin ABAP)
```
Reglas de negocio configurables:
  - Validaciones custom en PO (ej: bloquear si vendor inactive)
  - Derivacion de valores (ej: auto-asignar centro coste por material group)
  - Notificaciones custom

App: "Custom Fields and Logic" → Tab "Custom Logic"
  → Crear regla → Trigger (before save, after save) → Condiciones → Acciones
```

## Impacto en el Super Skill

### Queries MCP a actualizar
```
-- En vez de BSIK/BSAK, usar ACDOCA:
SELECT LIFNR, BELNR, BUZEI, HSL, BUDAT FROM ACDOCA
WHERE KOART = 'K' AND LIFNR = '{prov}' AND RLDNR = '0L'

-- En vez de MKPF+MSEG join, usar MATDOC:
SELECT MBLNR, ZEILE, BUDAT, BWART, MATNR, MENGE FROM MATDOC
WHERE MATNR = '{material}'

-- En vez de reports MC* (LIS), usar CDS views analiticas:
ReadView("C_PurchasingDocumentItemQuery")
ReadView("C_MaterialStockQuery")
ReadView("C_SupplierInvoiceItemQuery")
```

### Decision tree actualizado para S/4 2023
```
Release procedure: que usar?
|
+-- Escenario simple (< 5 estrategias)
|   → Release Strategy clasica (funciona igual, mas simple)
|
+-- Escenario complejo (org dinamica, escalacion, mobile)
|   → Flexible Workflow
|
+-- Aprobacion cross-system
    → Central Procurement + Flexible Workflow
```
