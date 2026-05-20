# S/4HANA 2023 — Fiori Apps para SD Sales

## Concepto Fiori en S/4

En S/4HANA 2023 las Fiori Apps son la UI recomendada para usuarios finales de SD.
Las transacciones SAP GUI siguen funcionando pero muchas redirigen automaticamente
a la app Fiori equivalente cuando el launchpad esta configurado.

Cada app tiene: App ID (F####), Technical Name (componente SAPUI5), Catalog y Role.

---

## Apps de pedidos de venta — Sales Orders

### Apps transaccionales principales

| App ID | Nombre | Reemplaza | Componente SAPUI5 |
|--------|--------|-----------|-------------------|
| F1814 | Manage Sales Orders | VA01/VA02/VA03 | SD.MD.SO.MANAGESALESORDERS |
| F5765 | Manage Sales Orders (v2/Fiori 3) | VA01/VA02/VA03 | SD.UI.MNGSLS |
| F6594 | Create Sales Order | VA01 | SD.UI.MNGSLS.CREATE |
| F2093 | Sales Order Fulfillment | VA03 (overview) | SD.UI.SORD.FLFL |
| F5764 | Display Sales Order | VA03 | SD.MD.SO.DISPSALESORDER |
| F2349 | Sales Order Items | — | SD.UI.SORD.ITEMS |
| F4774 | Change Sales Orders (mass) | VA05 + VA02 | SD.UI.MASSCHNG |
| F4829 | Import Sales Orders from Excel | LSMW/VA01 batch | SD.UI.IMPORTSLS |

### Caracteristicas clave de las apps principales

```
F1814 / F5765 — Manage Sales Orders:
  - Lista con filtros avanzados por cliente, material, org. ventas, fechas
  - Edicion inline de cabecera y posiciones
  - Acceso directo a flujo de documento (VBFA)
  - Indicador de estado de entrega y facturacion
  - Bloqueo/desbloqueo de pedido
  - Cambio de precios y condiciones
  - Asignacion de interlocutores
  - Vista de availability check integrada

F2093 — Sales Order Fulfillment:
  - Vista end-to-end del pedido: pedido → entrega → factura
  - KPIs de cumplimiento en tiempo real
  - Alertas de pedidos bloqueados o con problemas
  - Detalle de motivos de bloqueo
  - Acceso directo a acciones correctivas

F6594 — Create Sales Order:
  - Wizard simplificado para crear pedidos
  - Busqueda de cliente con datos de KNVV pre-cargados
  - Propuesta automatica de condiciones de precio
  - ATP check integrado al agregar posiciones
```

---

## Apps de entregas — Delivery

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F1085 | Create Outbound Delivery | VL01N | Transactional |
| F6925 | Manage Outbound Deliveries | VL06O / VL02N | Transactional |
| F3751 | Post Goods Issue | VL02N (PGI) | Transactional |
| F5768 | Outbound Delivery Monitor | VL06O | Analytical |
| F4382 | Display Outbound Delivery | VL03N | Display |
| F2340 | Create Transfer Orders (WM) | LT01 | Transactional |
| F5773 | Manage Picking | LT0A | Transactional |
| F5772 | Monitor Picking | LT0B | Analytical |
| F4796 | Delivery Split Worklist | — | Transactional |

### Caracteristicas clave

```
F6925 — Manage Outbound Deliveries:
  - Lista de entregas con estado (picking, PGI, etc.)
  - Procesamiento masivo: picking masivo, PGI masivo
  - Filtro por ruta, zona de transporte, fecha de entrega
  - Integracion con Extended Warehouse Management (EWM)
  - Cambio de picking quantity inline

F3751 — Post Goods Issue:
  - PGI individual o masivo desde lista
  - Verificacion de stock disponible antes de PGI
  - Generacion automatica de MATDOC (movimiento 601)
  - Opcion de PGI parcial

F1085 — Create Outbound Delivery:
  - Creacion desde pedido o independiente
  - Propuesta automatica de rutas y transportistas
  - Split automatico por criterios de expedicion
```

---

## Apps de facturacion — Billing

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F0862 | Create Billing Documents | VF04 (billing due list) | Transactional |
| F2548 | Manage Billing Documents | VF03 / VF05N | Transactional |
| F1459 | Billing Due List | VF04 | Transactional |
| F5774 | Display Billing Document | VF03 | Display |
| F3752 | Cancel Billing Document | VF11 | Transactional |
| F4384 | Intercompany Billing | — | Transactional |
| F5775 | Billing Document Items | — | Object Page |
| F2876 | Preliminary Billing Documents | — | NEW S/4 2023 |

### Caracteristicas clave

```
F1459 / F0862 — Billing Due List:
  - Lista de entregas y ordenes listas para facturar
  - Facturacion masiva con un click
  - Separacion automatica por criteiros de split de factura
  - Simulacion de factura antes de crear
  - Filtro por org. ventas, cliente, clase de pedido

F2548 — Manage Billing Documents:
  - Vista de todas las facturas con estado contabilizacion
  - Acceso al documento contable FI (ACDOCA)
  - Reimpresion de facturas (Output Management 2.0)
  - Cancelacion y re-facturacion
  - Vista de condiciones de precio por factura
```

---

## Apps de precios — Pricing

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F4599 | Manage Pricing Conditions | VK11/VK12/VK13 | Transactional |
| F5640 | Display Condition Records | VK13 | Display |
| F3876 | Sales Price Simulation | V/LD | Analytical |
| F4912 | Manage Customer-Specific Prices | — | Transactional |
| F5776 | Pricing Analysis | — | Analytical |

### Caracteristicas clave

```
F4599 — Manage Pricing Conditions:
  - Crear/modificar/borrar registros de condicion por tipo
  - Vista de validity periods con solapamientos detectados
  - Mass upload de condiciones via spreadsheet
  - Filtro por esquema de calculo, tipo de condicion

F3876 — Sales Price Simulation:
  - Simular precio para cliente/material/cantidad/fecha
  - Ver desglose completo del esquema de calculo
  - Comparar precios entre periodos o clientes
  - Exportar resultado a Excel
```

---

## Apps de gestion de credito — Credit Management

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F3838 | Credit Limit Overview | FD32 / S_ALR_87012215 | Analytical |
| F3839 | Manage Credit Cases | — | Transactional |
| F3840 | Credit Limit Utilization | — | Analytical |
| F4141 | Release Sales Orders (Credit) | VKM1/VKM4 | Transactional |
| F5641 | Customer Credit Overview | FD33 | Display |
| F4385 | Credit Scoring | — | Analytical |

### Caracteristicas clave

```
F3838 — Credit Limit Overview:
  - Vista de exposicion de credito por cliente y segmento
  - Semaforo de utilizacion (verde/amarillo/rojo)
  - Drill-down a documentos SD que generan la exposicion
  - Datos de FSCM Credit Management (UKM_LIMIT, UKM_EXPOSURE)

F4141 — Release Sales Orders:
  - Lista de pedidos bloqueados por credito
  - Liberacion individual o masiva
  - Historial de liberaciones previas
  - Acceso a motivo de bloqueo y recomendacion

F3839 — Manage Credit Cases:
  - Gestion de casos FSCM (UKM_CASE)
  - Workflow de aprobacion para limites de credito
  - Integracion con gestor de credito
```

---

## Apps de datos maestros — Master Data

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F1804 | Manage Business Partner | BP / XD01 / VD01 | Transactional |
| F1602 | Manage Product Master | MM01/MM02/MM03 (vistas SD) | Transactional |
| F3875 | Customer Line Items | FBL5N | Analytical |
| F5642 | Display Customer | XD03 / VD03 | Display |
| F4597 | Manage Customer-Material Info | VD51 | Transactional |
| F4598 | Manage Output Condition Records | VV11/VV12 | Transactional |

### Manage Business Partner (F1804)
```
App central para gestion del maestro de clientes en S/4:
  - Crear/modificar BP con rol Customer (FLCU01)
  - CVI sincroniza automaticamente KNA1, KNB1
  - Datos de area ventas (KNVV) integrados en la misma app
  - Interlocutores (KNVP), datos de expedicion (KNVS) accesibles
  - Verificacion de duplicados integrada
  - Historial de cambios
```

---

## Apps de disponibilidad — Availability

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F3837 | Check Product Availability | CO09 | Transactional |
| F4143 | Backorder Processing | V_V2 | Transactional |
| F5643 | Product Allocation | — | NEW S/4 (aATP) |
| F5644 | Availability Overview | MD04 simplificado | Analytical |

### Caracteristicas clave
```
F3837 — Check Product Availability:
  - ATP check individual por material/centro/cantidad/fecha
  - Resultado inmediato con fecha de entrega confirmada
  - Drill-down a stock disponible y entradas previstas
  - Escenario "what-if" con diferentes fechas

F4143 — Backorder Processing (aATP):
  - Repriorizar pedidos pendientes cuando hay stock disponible
  - Reglas de backorder configurables
  - Procesamiento masivo
```

---

## Apps de devoluciones — Returns

| App ID | Nombre | Reemplaza | Tipo |
|--------|--------|-----------|------|
| F4146 | Manage Returns | VA01 clase RE | Transactional |
| F4147 | Create Return Order | VA01 clase RE | Transactional |
| F4148 | Returns Monitor | — | Analytical |
| F4386 | Manage Customer Returns | — | NEW S/4 only |

---

## Apps analiticas — Embedded Analytics SD

| App ID | Nombre | CDS View base | Tipo |
|--------|--------|--------------|------|
| F2262 | Sales Order Fulfillment Analysis | C_SalesOrderFulfillmentAnalysis | Analytical |
| F3843 | Revenue Analysis | C_SalesRevenueQuery | Analytical |
| F3844 | Delivery Performance | C_DeliveryPerformanceQuery | Analytical |
| F4154 | Sales Volume Analysis | C_SalesVolumeQuery | Analytical |
| F4155 | Incoming Sales Orders | C_IncomingSalesOrderQuery | KPI Tile |
| F4388 | Net Sales | C_NetSalesQuery | KPI Tile |
| F4389 | Days Sales Outstanding (DSO) | C_DSO_Query | KPI Tile |
| F5645 | Order-to-Cash Performance | C_OTCPerformanceQuery | Analytical |
| F5646 | Customer Returns Analysis | C_CustomerReturnsQuery | Analytical |
| F4854 | Monitor Value Chains | — | O2C end-to-end monitoring |

### Caracteristicas analiticas
```
Todas las apps analiticas SD leen desde CDS Analytical Views:
  - Datos en tiempo real (sin data warehouse)
  - Filtros configurables por usuario
  - Export a Excel / SAP Analytics Cloud
  - KPI tiles en el launchpad con threshold colors

CDS Views analiticas clave SD:
  C_SalesOrderItem          → Posiciones de pedidos (query)
  C_BillingDocumentItemQuery → Posiciones de factura (query)
  C_DeliveryItemQuery       → Posiciones de entrega (query)
  C_CustomerBalanceQuery    → Saldos de cliente (desde ACDOCA)
```

---

## Fiori Launchpad — Catalogs y Roles SD

### Catalogos relevantes SD
```
SAP_SD_BC_SO_MANAGE      → Sales Order management
SAP_SD_BC_DLV_MANAGE     → Delivery management
SAP_SD_BC_BILL_MANAGE    → Billing management
SAP_SD_BC_PRICE_MANAGE   → Pricing conditions
SAP_SD_BC_CR_MANAGE      → Credit management
SAP_SD_BC_MD_CUSTOMER    → Customer master data
SAP_SD_BC_ATP_MANAGE     → Availability check
SAP_SD_BC_RT_MANAGE      → Returns management
SAP_SD_BC_ANALYTICS      → SD Embedded Analytics
```

### Roles estandar SD
```
SAP_BR_SALES_REPRESENTATIVE    → Representante de ventas
  Acceso: Manage Sales Orders, Create Sales Order, Check Availability

SAP_BR_INTERNAL_SALES_REP      → Ventas internas
  Acceso: Manage Sales Orders, Billing Due List, Credit Release

SAP_BR_SALES_MANAGER           → Jefe de ventas
  Acceso: todos + apps analiticas + Revenue Analysis

SAP_BR_BILLING_CLERK           → Empleado de facturacion
  Acceso: Create Billing, Manage Billing, Billing Due List

SAP_BR_SHIPPING_SPECIALIST     → Especialista en expedicion
  Acceso: Manage Deliveries, Post Goods Issue, Picking

SAP_BR_CREDIT_CONTROLLER       → Gestor de credito
  Acceso: Credit Limit Overview, Manage Credit Cases, Release Orders

SAP_BR_CUSTOMER_MASTER         → Maestro de datos cliente
  Acceso: Manage Business Partner, Customer master views
```

### Configuracion basica del Launchpad
```
Transaccion: /UI2/FLP o /n/UI2/FLP (SAP GUI)

Pasos para agregar app al launchpad:
  1. SU01 o PFCG → asignar rol con catalogo SD al usuario
  2. /UI2/FLP → App Finder → buscar app por ID o nombre
  3. Agregar al grupo/pagina del usuario

SPRO → SAP NetWeaver → UI Technologies → SAP Fiori →
  SAP Fiori Launchpad → Fiori Launchpad Content Manager
  → Assign Catalogs to Groups → Assign to Roles
```

---

## Extensibilidad de Apps Fiori SD

### In-App Extensibility (Key User, sin ABAP)
```
Herramienta: UI Adaptation (transaccion /n/UI2/FLP → Key User Mode)

Que se puede hacer sin ABAP:
  1. Agregar campos custom (Custom Fields and Logic F1481):
     - Campo "Motivo especial descuento" en Sales Order
     - Campo "Numero pedido cliente alternativo" en Sales Order item
     → Aparece automaticamente en Manage Sales Orders + OData API

  2. Ocultar/reorganizar campos en la app (Adaptation Mode):
     - Click derecho → Hide/Move fields
     - Guardar como variante de app para un rol especifico

  3. Custom Logic (reglas de negocio):
     - Validacion: no permitir pedido si cliente tiene bloqueo Z
     - Derivacion: auto-asignar grupo de estadistica por cliente
     → Sin ABAP, via BRF+ simplificado en Fiori

  4. Custom Analytical Queries:
     - Crear KPI tile con medida propia (ej: margen % por rep)
     → App: Custom Analytical Queries (F4512)
```

### Side-by-Side Extensibility (BTP)
```
Para cambios mas profundos:
  - Custom Fiori app que consume SD OData APIs:
      API_SALES_ORDER_SRV         → CRUD de Sales Orders
      API_OUTBOUND_DELIVERY_SRV   → Entregas
      API_BILLING_DOCUMENT_SRV    → Facturas
      API_CUSTOMER_SRV            → Maestro de clientes

  - Event Mesh: escuchar eventos SD:
      SalesOrder.Created.v1
      SalesOrder.Changed.v1
      OutboundDelivery.GoodsIssuePosted.v1

  Ejemplo: alerta Teams cuando pedido supera $500k
    → S/4 Event → BTP Event Mesh → Cloud Function → Teams Webhook
```

## Equivalencia rapida SAPGUI → Fiori SD

| Si preguntan por... | App Fiori equivalente | App ID |
|---------------------|----------------------|--------|
| VA01 (crear pedido) | Create Sales Order | F6594 / F2176 |
| VA02 / VA03 / VA05 | Manage Sales Orders | F1814 / F5765 / F1869 |
| VA01 tipo RE | Manage Customer Returns | F4146 / F0744A |
| VA01 tipo CR | Manage Credit Memo Requests | F1367 |
| VA01 tipo DR | Manage Debit Memo Requests | F2917 |
| VA21 (oferta) | Manage Sales Quotations | F2183 |
| VL01N / VL02N | Manage Outbound Deliveries | F6925 / F2139 |
| VL06O | Outbound Delivery Monitor | F5768 / F2416 |
| VL02N (PGI) | Post Goods Issue | F3751 / F1602 |
| VF01 / VF04 | Create Billing Documents / Due List | F0862 / F1459 / F0797 |
| VF02 / VF03 / VF05 | Manage Billing Documents | F2548 / F0798 |
| VF11 | Cancel Billing Document | F3752 |
| VK11 / VK12 / VK13 | Manage Pricing Conditions | F4599 / F1048 |
| FD32 / FD33 | Credit Limit Overview | F3838 / F5641 |
| VKM1 / VKM4 | Release Sales Orders (Credit) | F4141 |
| BP / XD01 / VD01 | Manage Business Partner | F1804 / F0354 |
| CO09 (ATP) | Check Product Availability | F3837 |
| V_V2 (backorder) | Backorder Processing | F4143 |
| MC+A / MC+E | Sales Volume Analysis | F4154 / F2681 |
| — (cockpit) | My Sales Overview | F1090A |
| — (360°) | Customer 360° View | F2691 |

> Nota: Algunos App IDs tienen versiones Fiori 2 y Fiori 3 (la mas reciente). Ambas coexisten en S/4HANA 2023. La version Fiori 3 tiene UI mejorada.

---

## OData APIs para extensibilidad BTP

| API | Descripcion | Operaciones |
|-----|-------------|-------------|
| API_SALES_ORDER_SRV | Sales Orders (V2) | CRUD + simulate pricing |
| A_SalesOrder (A2X) | Sales Orders (V4, 2023) | CRUD V4, recomendado |
| API_OUTBOUND_DELIVERY_SRV | Deliveries | Create, change, PGI |
| API_BILLING_DOCUMENT_SRV | Billing Documents | Create, display |
| API_CUSTOMER_SRV / API_BUSINESS_PARTNER | Customer/BP | CRUD |
| API_SD_PRICING_CONDITION_SRV | Pricing Conditions | CRUD condition records |
| API_CREDIT_MEMO_REQUEST_SRV | Credit Memo Requests | CRUD |
| API_RETURNS_DELIVERY_SRV | Return Deliveries | Create, change |

### Event Mesh — Eventos SD
```
Eventos publicados por S/4HANA para integracion BTP:

SalesOrder.Created.v1          → Pedido creado
SalesOrder.Changed.v1          → Pedido modificado
OutboundDelivery.Created.v1    → Entrega creada
OutboundDelivery.GoodsIssuePosted.v1 → PGI ejecutado
BillingDocument.Created.v1     → Factura creada
BillingDocument.Cancelled.v1   → Factura cancelada
CreditMemoRequest.Created.v1   → Nota credito creada

Uso tipico:
  S/4 Evento → BTP Event Mesh → Cloud Function → accion externa
  Ejemplo: alerta Teams/Slack cuando pedido supera $500k
```

---

### Queries MCP para verificar apps y roles
```sql
-- Buscar transacciones que redirigen a Fiori
GetTransaction("VA01")
GetTransaction("VL02N")

-- Buscar componentes SAPUI5 desplegados
SearchObject("SD.UI.MNGSLS*")
SearchObject("SD.MD.SO*")

-- Verificar BSP apps (backend Fiori)
SearchObject("/UI2/FLP*")

-- Roles SD estandar para auditar
ReadProgram("RSUSR002")
```
