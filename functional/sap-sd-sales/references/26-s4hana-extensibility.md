# S/4HANA 2023 — Extensibilidad SD

## Modelo de extensibilidad S/4HANA

```
Extensibilidad S/4HANA (de menor a mayor complejidad):

Tier 1: Key User (sin codigo)
  → Custom Fields en pedidos de venta, clientes, materiales
  → Custom Logic via BAdI Key User Framework
  → Custom CDS Views analiticas
  → Custom Fiori Tiles en Launchpad

Tier 2: Developer Extensibility (ABAP en S/4)
  → RAP business objects para entidades SD custom
  → Clases wrapper sobre APIs released (I_SalesOrderTP, etc.)
  → BAdIs released (SD_*_S4) + Enhancement Spots
  → Implicit Enhancements (compatibilidad backward)
  → Side-by-side via ABAP Environment (SAP BTP ABAP)

Tier 3: Side-by-Side (BTP)
  → Apps CAP/Node.js/Java extendiendo SD
  → Event-driven via SAP Event Mesh
  → Integration Suite para conectar sistemas externos
  → SAP Build Process Automation para workflows SD

Regla de oro S/4HANA 2023:
  NUNCA modificar objetos estandar SAP
  SIEMPRE usar APIs released o extension points oficiales
  SOLO APIs con contrato C1 (compatibilidad garantizada en upgrades)
```

## Tier 1: Key User Extensibility

### Custom Fields en SD (F1481)
```
App Fiori: "Custom Fields and Logic"

Business Contexts disponibles para SD:
  - Sales Order (Header)          → campos en VBAK
  - Sales Order (Item)            → campos en VBAP
  - Customer (Business Partner)   → campos en BUT000/KNA1
  - Billing Document (Header)     → campos en VBRK
  - Billing Document (Item)       → campos en VBRP
  - Delivery (Header)             → campos en LIKP
  - Delivery (Item)               → campos en LIPS
  - Sales Quotation (Header/Item) → campos en VBAK (tipo AN)

Proceso:
  1. Crear campo → nombre ZZ_*, tipo (CHAR/DEC/DATS/NUMC), longitud
  2. Asignar a Business Context(s)
  3. Asignar a UI Adaptation → donde aparece en la app Fiori
  4. Publicar → campo disponible en:
     - App "Manage Sales Orders" automaticamente
     - OData API (A_SalesOrder → como extension)
     - CDS views analiticas
     - Salidas (SmartForms/Adobe Forms)
     - Excel download/upload via masa

Ejemplos tipicos:
  ZZ_MOTIVO_VENTA  → Motivo de venta custom (CHAR 10)
  ZZ_CANAL_DIGITAL → Flag pedido digital (CHAR 1, Y/N)
  ZZ_PROYECTO_REF  → Referencia proyecto interno (CHAR 20)

Limitaciones:
  - Solo tipos simples (no estructuras ni tablas internas)
  - No logica compleja en campos (para eso → Custom Logic)
  - No se pueden renombrar campos una vez creados
```

### Custom Logic via BAdI Key User Framework
```
App Fiori: "Custom Fields and Logic" → Tab "Custom Logic"

Triggers disponibles para Sales Order:
  - Before Save (validacion antes de grabar)
  - After Modify (derivar valores cuando cambia un campo)
  - After Save (acciones post-grabado)

Ejemplo 1: Bloquear pedido si cliente tiene clasificacion de riesgo alto
  Trigger: Before Save (Sales Order)
  Condicion: CustomerRiskClass = 'HIGH'
  Accion: Raise Error "Cliente bloqueado por riesgo crediticio"

Ejemplo 2: Auto-asignar equipo de ventas por region
  Trigger: After Modify (Sales Order Header)
  Condicion: SalesOffice = 'NORTE'
  Accion: Set SalesGroup = 'GRP01'

Ejemplo 3: Calcular campo custom descuento adicional
  Trigger: After Modify (Sales Order Item)
  Condicion: OrderQuantity >= 1000
  Accion: Set ZZ_DESC_ADICIONAL = 5 (5% adicional)

Limitaciones:
  - No acceso directo a tablas SAP (solo campos del business context)
  - No llamadas RFC o HTTP desde Custom Logic
  - Para logica compleja → BAdI developer (Tier 2)
```

### Custom CDS Views (F5307)
```
App Fiori: "Custom CDS Views"

Permite crear CDS views analiticas sobre datos estandar SD:
  - Seleccionar campos de entidades released (I_SalesOrderItemCube, etc.)
  - Agregar campos custom ZZ_ creados en Key User
  - Definir filtros y agrupaciones
  - Publicar como OData → usar en SAC o tiles KPI

Ejemplo: Vista de pedidos con rentabilidad por canal
  Base: I_SalesOrderItemCube
  Campos: SoldToParty, Material, NetAmount, ZZ_CANAL_DIGITAL
  Filtro: SalesOrganization = '1000', OrderDateYear >= '2025'
  Publicar → conectar a SAC para analisis de tendencias
```

### Custom Fiori Tiles
```
App: "Launchpad Designer" o "Manage Launchpad Settings"

Crear tile personalizado:
  1. Definir Target Mapping → apunta a app Fiori estandar o URL
  2. Crear Tile (Static, Dynamic o KPI)
  3. Asignar al Catalog y Group del rol de ventas

Tile dinamico (con numero en tiempo real):
  - Pedidos pendientes de facturar (conteo de VF04)
  - Entregas bloqueadas (conteo de VL06O)
  Fuente del dato: CDS view con @Analytics annotation
```

## Tier 2: Developer Extensibility (ABAP en S/4)

### Released APIs y objetos SD

En S/4HANA 2023 solo usar objetos marcados "Released" (contrato C1):

```
Verificar si un objeto es released:
  ADT (Eclipse) → objeto → Properties → API State = "Released"
  SE80 → objeto → propiedades → API State = "Released"
  O via MCP:
  ReadView("I_SalesOrderTP")
  -- Buscar: apiState = "released", releaseContract = "C1"

Tipos de released objects SD:
  - CDS Views (I_SalesOrder*, C_SalesOrder*, A_SalesOrder*)
  - BAdIs SD (SD_*_S4_* enhancement spots)
  - Interfaces released (IF_SD_*)
  - RAP Business Objects (R_SalesOrderTP)
```

### APIs released clave para SD (S/4HANA 2023)

| API / Objeto | Tipo | Uso |
|---|---|---|
| I_SalesOrderTP | CDS/RAP | Leer/crear/modificar pedidos de venta |
| I_SalesOrderItemTP | CDS/RAP | Items del pedido de venta |
| I_BillingDocumentTP | CDS/RAP | Documentos de facturacion |
| I_DeliveryDocumentTP | CDS/RAP | Documentos de entrega |
| I_SalesQuotationTP | CDS/RAP | Ofertas de venta |
| I_CustomerReturnTP | CDS/RAP | Devoluciones de cliente |
| A_SalesOrder | OData V2 | API externa SD (SAP_COM_0109) |
| A_SalesOrder (A2X) | OData V4 | API Sales Order V4 (released 2023, recomendado) |
| A_BillingDocument | OData V2 | API facturacion externa |
| API_SALES_ORDER_SRV | OData V2 | Procesamiento pedidos (legacy, still released) |
| I_SalesOrderItemCube | CDS Analytics | Cubo analitico items pedido |
| I_SalesAnalyticsCube_1 | CDS Analytics | Cubo ventas (VBAK+VBAP+KONV) |
| I_BillingDocumentItemCube | CDS Analytics | Cubo analitico items factura |
| I_DeliveryDocumentItemCube | CDS Analytics | Cubo analitico items entrega |
| C_SalesOrderItemQry | CDS Query | Query analitica posiciones pedido |
| CL_SD_PRD_AVAL_CHECK_API | Clase | Verificacion disponibilidad released |

### RAP Business Objects para SD custom

```
Caso de uso: crear entidad de "Bonificacion por cliente" vinculada a SD

Arquitectura RAP:
  Tabla custom: ZBON_CLIENTE (cliente, bonif_pct, validez_inicio, validez_fin)
  CDS Interface View: ZI_BonificacionCliente
  CDS Projection View: ZC_BonificacionCliente
  Behavior Definition: ZR_BonificacionClienteTP
  Behavior Implementation: ZBP_BonificacionClienteTP
  Service Definition: ZUI_BonificacionCliente
  Service Binding: ZAPI_BonificacionCliente_0001

Consumption via OData:
  GET /sap/opu/odata4/sap/zapi_bonificacioncliente_0001/...

Wrapper pattern para I_SalesOrderTP:
  - No extender BDEF de SAP directamente
  - Crear RAP propio que LLAMA a I_SalesOrderTP via EML
  - Ejemplo: ZR_PedidoVentaEnriquecidoTP
    → En su implementacion llama: MODIFY ENTITY I_SalesOrderTP...

EML para leer pedido de venta:
  READ ENTITIES OF I_SalesOrderTP
    ENTITY SalesOrder
    FIELDS ( SalesOrder SalesOrderType SoldToParty NetAmount )
    WITH VALUE #( ( SalesOrder = lv_orden ) )
    RESULT DATA(lt_orden).
```

### BAdIs released para SD (S/4HANA 2023)

```
Pricing:
  SD_PRC_S4_COND_CUST       → Logica custom en determinacion de precio
  SD_PRC_S4_CALC_CUST       → Post-calculo precio custom
  (Reemplaza: PRICING_BADI, RV60AFZZ)

Partner Determination:
  SD_PTR_S4_PTNR_DET        → Determinacion socios personalizada
  (Reemplaza: BADI_SD_PTNR_DET)

Output / Mensajes:
  SD_OUT_S4_OUTPUT          → Output management custom
  SD_OUT_S4_PRINT           → Control de impresion
  (Reemplaza: BADI_SD_OUTPUT)

Disponibilidad:
  SD_ATP_S4_CHECK           → Verificacion disponibilidad custom
  SD_ATP_S4_RESULT          → Post-proceso resultado ATP
  (Reemplaza: BADI_SALES_ATP_RESULTS)

Pedido de venta:
  SD_SLS_S4_ODER_CUST       → Proceso pedido custom (header/item)
  SD_SLS_S4_COPY_CUST       → Logica de copia (copy control custom)
  SD_SLS_S4_BLOCK_CUST      → Bloqueo custom de documentos
  (Reemplaza: BADI_SD_SALES_BASIC, userexit_save_document)

Facturacion:
  SD_BIL_S4_CUST            → Proceso facturacion custom
  SD_BIL_S4_INVOICE_CUST    → Post-proceso factura
  (Reemplaza: BADI_SD_BILLING, RV60AFZZ)

Entrega:
  SD_DEL_S4_CUST            → Proceso entrega custom
  SD_DEL_S4_PICK_CUST       → Post-proceso picking
  (Reemplaza: BADI_LE_SHP_DELIVERY_PROC)

IMPORTANTE:
  BAdIs clasicos (user-exits, function module exits como MV45AFZB)
  siguen activos en S/4 on-premise pero estan deprecated.
  Para nuevo desarrollo SIEMPRE usar los BAdIs _S4_.
  En proyectos brownfield: plan de migracion de user-exits a BAdIs.
```

### Enhancement Spots e Implicit Enhancements

```
Enhancement Spots (explicit, preferred):
  SMODULE SD_DOCUMENT_SAVE_BADI
  Buscar: SPAU → lista de spots disponibles para SD

Implicit Enhancements (usar con cuidado):
  Solo cuando no hay BAdI ni enhancement spot disponible
  Riesgo: puede romperse en upgrades

  Ejemplo en include MV45AFZB (user exit pedido):
  ENHANCEMENT 1 ZMY_ENHANCEMENT.  "active version
    " Logica custom aqui
    PERFORM z_my_custom_check.
  ENDENHANCEMENT.

CDS View Extensions (extend released CDS):
  @AbapCatalog.sqlViewAppendName: 'ZZ_VSLOITEM'
  extend view I_SalesOrderItemTP with ZZ_I_SalesOrderItemExt {
    _Extension.ZZ_CustomField1 as CustomField1,
    _Extension.ZZ_CustomField2 as CustomField2
  }
  -- Extension aparece en todas las apps que consumen I_SalesOrderItemTP
```

### Side-by-Side via ABAP Environment (BTP ABAP)

```
Para extensiones que deben estar aisladas del core:
  - Subaccount BTP con ABAP Environment
  - Se conecta a S/4HANA via RFC o APIs OData
  - Codigo ABAP Cloud (Restricted ABAP, solo APIs released)
  - Deployment independiente del ciclo S/4

Casos de uso:
  - Logica de precios muy compleja (sin riesgo en core)
  - Integraciones con sistemas externos via ABAP
  - Transformaciones de datos previas a S/4
```

## Tier 3: BTP Side-by-Side

### Arquitectura general

```
S/4HANA SD (on-premise / RISE)
    |
    +-- APIs OData (A_SalesOrder, A_BillingDocument) → BTP
    |                  |
    |                  +-- CAP Application (Node.js/Java)
    |                  |   → Logica de negocio custom
    |                  |   → Persistencia propia (HANA Cloud)
    |                  |
    |                  +-- Custom Fiori (UI5 / SAP Build Apps)
    |                  |   → Apps de ventas custom
    |                  |
    |                  +-- Integration Suite (iFlows)
    |                      → Sincronizacion con CRM/ERP externo
    |
    +-- Business Events → SAP Event Mesh → BTP subscribers
    |   (SalesOrder.Created, Delivery.Created, Invoice.Created)
    |
    +-- SAP Build Process Automation
        → Workflows de aprobacion SD personalizados
```

### Eventos de SD disponibles (S/4HANA 2023)

```
Business Events SD (SAP Event Mesh / Event Broker):
  - SalesOrder.Created.v1       → pedido nuevo creado
  - SalesOrder.Changed.v1       → pedido modificado
  - SalesOrder.Cancelled.v1     → pedido cancelado
  - BillingDocument.Created.v1  → factura creada
  - Delivery.Created.v1         → entrega creada
  - CustomerReturn.Created.v1   → devolucion registrada
  - BusinessPartner.Changed.v1  → cliente modificado

Ejemplo: Notificar CRM externo cuando se crea un pedido > 50.000 EUR
  S/4 → Event "SalesOrder.Created" → Event Mesh →
  Integration Suite iFlow → CRM externo (Salesforce/Dynamics)

Ejemplo: Trigger workflow de aprobacion para descuentos > 30%
  S/4 → Event "SalesOrder.Changed" → Event Mesh →
  SAP Build Process Automation → email al director comercial
```

### CAP (Cloud Application Programming Model) para SD

```
Caso de uso: Portal de pedidos B2B custom con logica propia

Estructura CAP:
  my-sales-portal/
  ├── db/
  │   ├── schema.cds         → entidades propias (CarritoCompra, etc.)
  │   └── external/          → import S4SalesOrder de A_SalesOrder
  ├── srv/
  │   ├── sales-service.cds  → SalesService (expone entidades)
  │   └── sales-service.js   → logica custom (validaciones, reglas)
  └── package.json

Llamada a S/4HANA desde CAP:
  const S4 = await cds.connect.to('API_SALES_ORDER_SRV');
  const orders = await S4.run(SELECT.from('A_SalesOrder')
    .where({ SoldToParty: req.user.id }));
```

### SAP Build Process Automation para SD

```
Workflows SD typical:
  1. Aprobacion de descuento excepcional (> X%)
     Trigger: SalesOrder creado con condicion ZZ%% > umbral
     Pasos: Vendedor → Jefe Ventas → Director Comercial

  2. Aprobacion de devolucion de cliente
     Trigger: CustomerReturn creado
     Pasos: Servicio al Cliente → Logistica → Contabilidad

  3. Onboarding de nuevo cliente
     Trigger: BusinessPartner.Created
     Pasos: Verificacion KYC → Asignacion grupo precio → Notif CRM

Integracion:
  - Leer/crear en S/4 via API A_SalesOrder (OData V2 released)
  - Formularios Fiori nativos de SAP Build
  - Notificaciones via SAP Work Zone (inbox)
```

## Decision tree: Que extensibilidad usar en SD

```
Necesidad:
|
+-- Agregar campo al pedido de venta
|   +-- Campo simple (texto, fecha, importe)
|   |   → Key User: Custom Fields, Tier 1
|   +-- Campo con derivacion (si cliente=X → campo=Y)
|   |   → Key User: Custom Logic (After Modify), Tier 1
|   +-- Campo con logica compleja (multiples tablas)
|       → BAdI SD_SLS_S4_ODER_CUST, Tier 2
|
+-- Validacion / bloqueo de documentos
|   +-- Regla simple (campo = valor)
|   |   → Key User: Custom Logic Before Save, Tier 1
|   +-- Regla compleja (verificar otras tablas, calculos)
|       → BAdI SD_SLS_S4_BLOCK_CUST, Tier 2
|
+-- Pricing / condiciones
|   +-- Nueva condicion de precio (tipo condicion nuevo)
|   |   → IMG: Pricing Customizing + tablas Z condicion, Tier 2 config
|   +-- Logica de calculo personalizada
|       → BAdI SD_PRC_S4_COND_CUST o SD_PRC_S4_CALC_CUST, Tier 2
|
+-- Determinacion de socios custom
|   → BAdI SD_PTR_S4_PTNR_DET, Tier 2
|
+-- Output / mensajes custom
|   +-- Template nuevo para documento existente
|   |   → Output Management config + Adobe Form / BRF+, Tier 2
|   +-- Logica de envio custom
|       → BAdI SD_OUT_S4_OUTPUT, Tier 2
|
+-- Verificacion disponibilidad custom
|   → BAdI SD_ATP_S4_CHECK, Tier 2
|
+-- Nuevo reporte de ventas
|   +-- KPI simple sobre datos estandar
|   |   → Key User: Custom CDS View, Tier 1
|   +-- Reporte complejo con logica
|       → CDS analitica custom + Fiori, Tier 2
|
+-- Integracion con CRM o e-commerce externo
|   +-- Unidireccional (S/4 notifica al externo)
|   |   → Event Mesh + Cloud Function, Tier 3
|   +-- Bidireccional (sync pedidos)
|       → Integration Suite iFlow + A_SalesOrder API, Tier 3
|
+-- Workflow de aprobacion de descuentos
|   → SAP Build Process Automation + Event Mesh, Tier 3
```

## Escenarios de extension mas comunes en SD

### 1. Pricing custom
```
Objetivo: condicion de precio que llama a tabla Z o API externa

Opcion A (config): Tabla de condicion custom
  IMG → SD → Basic Functions → Pricing → Define Condition Types
  Crear condicion ZZDC → tipo descuento → tabla acceso Z_ZDESC
  Tabla Z_ZDESC: clave (cliente/material/grupo) → valor descuento

Opcion B (ABAP): BAdI para calculo dinamico
  ENHANCEMENT SPOT: SD_PRC_S4_CALC_CUST
  Implementacion: ZCL_MY_PRICING_BADI
  METHOD calculate_price_custom:
    " Llamar API externa de precios, leer tabla Z, etc.
    " Retornar valor del descuento
  ENDMETHOD.
```

### 2. Partner determination custom
```
Objetivo: determinar ship-to dinamicamente segun regla Z

BAdI: SD_PTR_S4_PTNR_DET
  IF iv_partner_function = 'WE' AND iv_sold_to = 'CLIENTE_X'.
    " Logica para determinar el ship-to dinamicamente
    ev_partner = zcl_sd_partner=>get_ship_to( iv_sold_to ).
  ENDIF.
```

### 3. Output (mensajes de salida) custom
```
S/4HANA 2023 usa BRF+ o SAP Forms para salida SD:
  - Adobe Forms para PDF impreso
  - BRF+ para reglas de cuando enviar/imprimir

BAdI: SD_OUT_S4_OUTPUT
  METHOD check_output_relevance:
    " Determinar si se debe emitir salida para este documento
    " Segun reglas custom (importe, pais, canal, etc.)
  ENDMETHOD.
```

### 4. Verificacion disponibilidad custom
```
Objetivo: enriquecer o reemplazar ATP con stock propio

BAdI: SD_ATP_S4_CHECK
  METHOD check_availability:
    " Llamar a tu propio sistema de gestion de stock
    " Combinar con ATP de S/4
    " Retornar confirmedQuantity y confirmedDate
  ENDMETHOD.

Alternativa: SAP Available-to-Promise (aATP) configuracion
  → backorder processing, product allocation, rules-based ATP
```

## Queries MCP para verificar extensibilidad SD

```
-- Buscar BAdIs released para SD
SearchObject("SD_SLS_S4*")
SearchObject("SD_PRC_S4*")
SearchObject("SD_OUT_S4*")
SearchObject("SD_PTR_S4*")

-- Verificar si una CDS view SD es released
ReadView("I_SalesOrderTP")
ReadView("I_BillingDocumentTP")
-- Buscar: apiState = "released", releaseContract = "C1"

-- Buscar campos custom existentes en pedido
GetSqlQuery("SELECT FIELDNAME, ROLLNAME FROM DD03L WHERE TABNAME = 'VBAK' AND FIELDNAME LIKE 'ZZ%'")
GetSqlQuery("SELECT FIELDNAME, ROLLNAME FROM DD03L WHERE TABNAME = 'VBAP' AND FIELDNAME LIKE 'ZZ%'")

-- Buscar enhancement spots SD activos
GetSqlQuery("SELECT SPOT_NAME, SHORT_TEXT FROM ENHS WHERE SPOT_NAME LIKE 'SD%'")

-- Buscar user-exits legacy SD (candidatos a migrar a BAdIs)
GetSqlQuery("SELECT MAINPROG, EXITFUNC FROM MODSAP WHERE MEMBER LIKE 'MV45A%' OR MEMBER LIKE 'RV45S%'")

-- Buscar implementaciones de BAdI SD propias
GetSqlQuery("SELECT CLSNAME, BADI_NAME FROM SXC_CLASS WHERE BADI_NAME LIKE 'SD_%S4%'")
```
