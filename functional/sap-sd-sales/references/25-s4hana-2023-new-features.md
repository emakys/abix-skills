# S/4HANA 2023 — Funcionalidades Nuevas SD

## 1. Advanced Available-to-Promise (aATP)

### Concepto
aATP reemplaza el ATP clasico (tabla VBBE/VBBS) con un motor de disponibilidad
avanzado que soporta multiples centros, asignaciones y backorder processing con reglas.

```
ATP clasico (ECC):
  - Verificacion por centro unico
  - Sin redistribucion entre centros
  - Sin product allocation
  - Backorder: manual via V_V2

aATP S/4HANA 2023:
  - Multi-plant sourcing (verifica varios centros en secuencia)
  - Product allocation (cuotas por cliente/canal)
  - Backorder processing automatico con reglas de prioridad
  - Rule-based ATP (alternativas de producto)
  - Confirmacion parcial inteligente
```

### Activacion y configuracion
```
SPRO → Advanced Available-to-Promise →
  Basic Settings → Activate aATP (Business Function: LOG_AATP_BASIC)

Componentes:
  1. Product Availability Check (PAC): reemplaza MTVFP clasico
  2. Product Allocation (PAL): asignaciones por caracteristica
  3. Backorder Processing (BOP): reproceso masivo con reglas
  4. Rule-based ATP (RBTP): alternativas de material/centro

Tablas nuevas aATP:
  IAOM_ALLOC_HEADER  → Cabeceras de asignacion (product allocation)
  IAOM_ALLOC_ITEM    → Posiciones de asignacion
  IAOM_CHAR          → Caracteristicas de asignacion (cliente, canal, pais)
  /SAPAPO/MVSB       → Confirmaciones aATP (vista de stock comprometido)
```

### Backorder Processing (BOP)
```
Escenario tipico:
  1. Stock disponible de PROD-A: 100 unidades
  2. 5 pedidos pendientes (backorder) de PROD-A: total 150 unidades
  3. BOP ejecuta reglas de prioridad:
     - Regla 1: Cliente A (key account) → prioridad 1
     - Regla 2: Pedidos mas antiguos primero
     - Regla 3: Pedidos con fecha entrega mas proxima
  4. BOP redistribuye confirmaciones automaticamente

App Fiori: Backorder Processing (F4143)
  → Ejecutar BOP masivo → ver resultado → confirmar
```

### Product Allocation
```
Ejemplo: PROD-A con stock limitado, asignacion por cliente:
  Cliente TOP-001: max 50 unidades/mes
  Canal ONLINE: max 30 unidades/mes
  Resto: sin limite hasta agotamiento

Config: SPRO → aATP → Product Allocation →
  Define Allocation Procedure → Assign to Checking Rule

ABAP: Exit BAdI /SAPAPO/ATP_CHECK_BADI para logica custom de asignacion
```

---

## 2. Simplificacion del modelo de ventas (Sales Order Simplification)

### Mejoras de rendimiento
```
S/4HANA 2023 introduce mejoras internas en el procesamiento de pedidos:

  - HANA-optimized pricing: calculo de precios directamente en HANA
    (antes: ABAP loop por condiciones KONV)
  - Parallel pricing determination: calculo de posiciones en paralelo
  - Simplified status handling: status fields ahora en VBAK/VBAP directamente
    (VBUK/VBUP eliminadas — campos absorbidos en tablas principales)
  - Reduced locking: menos bloqueos de tabla en creacion masiva de pedidos

Impacto:
  - Creacion masiva de pedidos (LSMW, BAPI): hasta 40% mas rapido
  - Pricing recalculation masivo: reduccion significativa de tiempo
```

### Simplificacion de datos
```
ECC: UPDATE separados en VBAK, VBKD, VBPA, VBEP, VBUK...
S/4: Actualizaciones agrupadas y optimizadas para HANA
     VBUK/VBUP eliminadas — status ahora directo en VBAK/VBAP/LIKP/LIPS/VBRK
     KONV → compatibility view sobre PRCD_ELEMENTS

Nuevo: Pedidos de venta con items hasta 9999 posiciones
  (ECC tenia limitaciones practicas en batch de alto volumen)
```

### Low-Touch / No-Touch Sales Order Processing
```
S/4HANA 2023 permite automatizar la creacion de pedidos sin intervencion manual:

  Escenarios:
  - Import Sales Orders from Excel (App F4829):
    → Carga masiva de pedidos via spreadsheet
    → Validacion automatica antes de crear
    → Modo simulacion disponible
  - EDI/IDoc automated processing (ORDERS05):
    → Pedidos entrantes via IDoc se crean automaticamente
    → Sin intervencion si datos completos y sin errores
  - API-based creation (A_SalesOrder V4):
    → Creacion programatica con OData V4 (A2X)
    → Soporte para confirmacion inmediata de ATP

  Low-touch: pedido se crea automaticamente, humano solo interviene si hay error
  No-touch: end-to-end sin intervencion (order → delivery → billing)
```

### Transportation Requirement Scheduling (TRS)
```
S/4HANA 2023 mejora el calculo de fechas de entrega con TRS:
  - Integrado con SAP Transportation Management (TM)
  - Considera lead times reales de transporte (no solo rutas fijas)
  - Routing y scheduling delegados a TM
  - Fecha de entrega mas precisa para el cliente

Flujo:
  1. Pedido creado → scheduling determination
  2. S/4 consulta SAP TM para tiempos de transporte reales
  3. TM retorna fecha factible considerando disponibilidad de carrier
  4. S/4 confirma fecha al pedido

Config: SPRO → Logistics Execution → Shipping →
  Transportation Requirement → Activate TRS Integration
```

---

## 3. Optimizacion de entregas — Delivery Optimization

### Wave Management
```
Concepto: agrupar entregas en "olas" de picking para optimizar
el trabajo en el almacen.

Funciona con:
  - EWM (Extended Warehouse Management): full wave management
  - WM clasico: wave management simplificado (S/4 2023)

Config EWM: SPRO → Extended Warehouse Management → Delivery Processing →
  Wave Management → Define Wave Templates

Criterios de agrupacion en ola:
  - Ruta de shipping
  - Zona de picking
  - Tipo de almacen / zona
  - Ventana de tiempo de carga
  - Transportista

App Fiori: Manage Waves (EWM) → crear ola → asignar entregas → procesar
```

### Yard Management Integration
```
S/4HANA 2023: integracion nativa con SAP Yard Logistics:
  - Gestion de muelles (dock doors)
  - Citas de carga (appointments)
  - Tracking de vehiculos en el patio
  - Cola de vehiculos prioritizada

Tablas Yard Logistics:
  /SCWM/YARD_SLOT     → Definicion de muelles
  /SCWM/YARD_APPT     → Citas de carga
  /SCWM/YARD_VEHICLE  → Registro de vehiculos

Integracion: entrega SD → genera aviso de carga → Yard Management asigna muelle
```

### Route Optimization
```
S/4HANA 2023 con SAP Transportation Management (TM):
  - Optimizacion de rutas con algoritmos (TSP - Travelling Salesman)
  - Consolidacion de cargas automatica
  - Cost optimization entre carriers
  - Real-time tracking integration (IoT)

Sin TM: route determination via SPRO → LE → Shipping →
  Basic Shipping Functions → Routes → Define Routes
```

---

## 4. Mejoras en facturacion — Billing Improvements

### Facturacion paralela (Parallel Billing)
```
S/4HANA 2023 permite procesar la billing due list en paralelo:
  - Multiples procesos en background procesan diferentes grupos
  - Division automatica por criterio (org. ventas, cliente, ruta)
  - Reduccion del tiempo de facturacion masiva

Config: SPRO → SD → Billing → Billing Documents →
  Define Billing Types → Parallel Processing → Activate

Transaccion: VF06 (background billing) con parallelizacion
  → Definir numero de jobs paralelos
  → Split criteria (VKORG, KUNAG, etc.)
```

### Preliminary Billing Documents
```
S/4HANA 2023 introduce documentos de facturacion preliminares:

App Fiori: Preliminary Billing Documents (F2876)
  - Crear factura borrador antes de contabilizar
  - Revision por equipo de facturacion o ventas
  - Aprobacion antes de posting final al FI
  - Util para facturas complejas o de alto valor

Flujo:
  1. Billing due list → crear preliminary billing doc
  2. Revisor verifica montos, condiciones, impuestos
  3. Aprobacion → convierte en billing document real → posting FI
```

### Mass Billing Performance
```
Mejoras tecnicas en S/4 2023:
  - HANA-native split check: determinacion de split de factura en HANA
    (reduce el tiempo de VF04/VF06 hasta 60% en volumes altos)
  - Buffer optimizado para KONV (condiciones)
  - Reduced DB calls en billing document creation

Monitoreo: App "Manage Billing Documents" (F2548)
  → Filtrar por estado "Error" → acciones correctivas masivas
```

---

## 5. Credit Management FSCM — SAP Credit Management

### Concepto y arquitectura
```
S/4HANA 2023 unifica la gestion de credito de ECC (FD32/KNKK) con
FSCM Credit Management (Financial Supply Chain Management):

ECC clasico:
  KNKK → limite credito simple por area de credito
  FD32 → mantenimiento manual del limite
  V1 credit check → bloqueo de pedido

S/4 con FSCM-CR:
  UKM_LIMIT    → limites por segmento de credito
  UKM_SCORING  → scoring automatico por reglas
  UKM_CASE     → casos de bloqueo gestionados en workflow
  UKM_EXPOSURE → exposicion calculada en tiempo real

Activacion:
  SPRO → Financial Supply Chain Management → Credit Management →
    Integration with Sales and Distribution → Activate Credit Check
  Business Function: FSCM_CR
```

### Credit Scoring automatico
```
Reglas de scoring configurables (sin ABAP):
  - DSO (Days Sales Outstanding): si DSO > 60 dias → puntuacion baja
  - Comportamiento de pago historico: % de pagos en fecha
  - Exposicion actual / limite: ratio de utilizacion
  - Calificacion externa (bureau de credito): Dun & Bradstreet, etc.

Config: SPRO → FSCM → Credit Management → Credit Scoring →
  Define Scoring Formula → Assign to Credit Segment

Resultado: score 0-100 → determina limite automatico o caso manual
```

### Integracion con bureau de credito externo
```
S/4HANA 2023 soporta integracion con:
  - Dun & Bradstreet (D&B)
  - Coface
  - Euler Hermes (seguro de credito)

Via: UKM_BP_RATING (tabla de ratings externos por BP)
Middleware: BTP Integration Suite o RFC directo

Flujo:
  1. Nuevo cliente creado en BP
  2. Job periodico llama API D&B → obtiene rating
  3. Rating actualiza UKM_BP_RATING
  4. Formula de scoring recalcula limite automaticamente
```

### Credit Insurance
```
S/4HANA 2023 con Euler Hermes / Coface:
  - Limites asegurados por poliza de credito
  - Monitorizacion automatica: si aseguradora retira cobertura → bloqueo
  - Tablas: UKM_INS_POLICY, UKM_INS_COVER

App Fiori: Credit Limit Overview (F3838)
  → Ver columna "Insured Amount" vs "Exposure"
```

---

## 6. Flexible Workflow para SD

### Concepto
```
Aprobacion de documentos SD configurable via Fiori sin ABAP:
  - Pedidos de venta bloqueados → workflow de liberacion
  - Cambios de precio manual → aprobacion jefe de ventas
  - Ordenes de devolucion > X euros → aprobacion gerente

Ventajas vs release strategy clasica:
  - Aprobadores dinamicos (org. structure, no hardcoded)
  - Escalacion automatica por timeout
  - Delegacion de aprobacion (vacaciones)
  - Aprobacion mobile (app My Inbox F0570)
  - Aprobacion paralela (multiples aprobadores simultaneos)
  - Aprobacion secuencial (jerarquica)
```

### Configuracion Flexible Workflow SD
```
App Fiori: Manage Workflows for Sales Orders
  1. Definir condicion de trigger:
     - Pedido con descuento manual > 15%
     - Pedido > 100.000 EUR
     - Cliente con bloqueo de pago
  2. Definir pasos de aprobacion:
     - Paso 1: jefe de ventas del area (org. unit)
     - Paso 2 (si > 500k): director de ventas
  3. Definir acciones: Aprobar / Rechazar / Reasignar
  4. Definir escalacion: 48h sin respuesta → siguiente nivel

App Fiori: My Inbox (F0570):
  → Aprobador recibe tarea
  → Ver detalle del pedido + motivo de bloqueo
  → Aprobar o rechazar con comentario
  → Notificacion automatica al creador
```

### BAdIs para Flexible Workflow
```abap
" Logica custom de determinacion de aprobador
BADI: WS_TASK_DECISION_BADI
  → Metodo: GET_AGENTS → retorna usuarios/roles aprobadores
  → Parametros: categoria objeto, datos del documento SD

" Logica custom de condicion de trigger
BADI: WS_WF_RULE_BADI
  → Metodo: EVALUATE_RULE → retorna ABAP_TRUE/FALSE
```

---

## 7. Embedded Analytics para SD

### CDS Analytical Views principales
```
Vista CDS                           | Descripcion
------------------------------------|------------------------------------------
C_SalesOrderItem                    | Posiciones pedido (query con KPIs)
C_BillingDocumentItemQuery          | Posiciones factura (revenue analysis)
C_DeliveryItemQuery                 | Posiciones entrega (fulfillment)
C_SalesOrderFulfillmentAnalysis     | End-to-end cumplimiento
C_IncomingSalesOrderQuery           | Pedidos entrantes (KPI tile)
C_NetSalesQuery                     | Ventas netas (KPI tile)
C_DSO_Query                         | Days Sales Outstanding
C_CustomerReturnsQuery              | Analisis de devoluciones
C_SalesPriceQuery                   | Analisis de precios y margenes
C_DeliveryPerformanceQuery          | On-time delivery %
```

### KPI Tiles en el Launchpad
```
KPI tiles SD disponibles (configurables en /n/UI2/FLP):
  - Incoming Sales Orders (valor y cantidad del dia)
  - Net Revenue (acumulado mes)
  - Days Sales Outstanding (DSO actual)
  - Delivery Performance % (entregas a tiempo)
  - Blocked Sales Orders (numero de pedidos bloqueados)
  - Billing Due (facturas pendientes de crear)
  - Open Credit Cases (casos de credito abiertos)

Configuracion:
  App: KPI Design (F3857) → Crear KPI → Asignar CDS view → Definir threshold
  App: KPI Workspace (F3858) → Agregar tiles al launchpad
```

### Custom Analytical Queries
```
Para crear queries analiticas custom sobre datos SD:
  App: Custom Analytical Queries (F4512) — Key User Tool

Ejemplo: "Revenue by Sales Rep by Month"
  1. F4512 → New Query → Source: C_BillingDocumentItemQuery
  2. Dimensions: VKBUR (oficina ventas), PERNR (rep), FKDAT (mes)
  3. Measures: NETWR (valor neto), MENGE (cantidad)
  4. Filters: VKORG = '1000'
  5. Publicar → genera KPI tile automaticamente
```

---

## 8. Situation Handling — Alertas inteligentes SD

### Concept
```
Situation Handling envia alertas proactivas a los usuarios responsables
cuando ocurren eventos criticos en el proceso de ventas.

A diferencia de los batch jobs de monitoreo, las situaciones se disparan
en tiempo real o con muy poca latencia.
```

### Situaciones SD predefinidas en S/4 2023
```
Situacion                           | Trigger | Destinatario
------------------------------------|---------|-------------
Delivery Overdue                    | Entrega con fecha pasada sin PGI | Rep ventas
Sales Order Blocked (credit)        | Pedido bloqueado > N horas | Rep + gestor credito
Sales Order Incomplete              | Datos incompletos > N dias | Rep ventas
Delivery Quantity Shortfall         | Stock insuficiente para entrega | Planificador
Billing Document Error              | Error en creacion de factura | Facturacion
Customer Payment Overdue            | Vencimiento factura superado | Gestor credito
Return Order Not Processed          | Devolucion sin procesar > N dias | Rep ventas
```

### Configuracion
```
SPRO → SAP Customizing → Situation Handling →
  Define Situation Types → Assign Anchor Objects → Define Recipients

O via App Fiori: Manage Situation Types (F4607)
  → Crear situacion → Definir condicion (CDS event o ABAP class)
  → Definir destinatarios (rol, org unit, usuario especifico)
  → Definir mensaje (texto con variables: cliente, pedido, importe)
  → Activar

Resultado: el usuario ve la situacion en:
  - My Situations tile en el launchpad
  - Email (si configurado)
  - Directamente en la app relevante (ej: Manage Sales Orders muestra badge)
```

---

## 9. Intelligent Sales — ML e integracion con IBP

### Machine Learning para SD
```
S/4HANA 2023 con SAP AI Foundation (BTP):
  - Demand forecasting: prediccion de demanda por material/cliente
    integrada con SAP IBP (Integrated Business Planning)
  - Customer churn prediction: score de riesgo de abandono
  - Recommended order quantities: sugerencia al crear pedido
  - Smart pricing suggestion: precio optimo por segmento

Activacion:
  Requiere: SAP AI Foundation en BTP + entrenamiento con datos historicos
  SPRO → SD → Intelligent Sales → Activate ML Features → Connect BTP tenant
```

### Integracion con SAP IBP
```
Flujo de integracion S/4 ↔ IBP:
  1. S/4 exporta historial de ventas (VBRK/VBRP) → IBP
  2. IBP genera forecast estadistico
  3. Forecast vuelve a S/4 como PIR (Planned Independent Requirements)
  4. MRP usa PIR para planificar produccion/compras
  5. aATP usa forecast para product allocation

Tablas PIR en S/4:
  PBIM → Planned Independent Requirements
  PBED → Datos de planificacion de demanda
```

---

## 10. Output Management 2.0

### Diferencia con output clasico
```
ECC / S/4 (output clasico):
  NAST → tabla de outputs SD
  TNAPR → procedimientos de output (acceso condicion)
  Formularios: SAPscript o SmartForms
  Envio: via SO10 / SCOT / SAP Connect

S/4HANA 2023 — Output Management 2.0:
  BRF+ → reglas de determinacion de output (sin SPRO)
  Adobe Document Services → formularios (Adobe Forms / PDF)
  Email templates → plantillas HTML editables por key user
  Output Controller → monitoreo y reenvio desde Fiori
  KEINE NAST (para documentos con OM 2.0 activado)
```

### Configuracion Output Management 2.0 para SD
```
SPRO → SAP NetWeaver → Application Server → Output Management →
  Assign Output Types → Define Output Rules (BRF+)

O via App Fiori: "Manage Output Parameter Determination" (F2984)
  1. Crear regla para "Billing Document Output":
     - Condicion: VBRK-FKART = 'F2' (factura estandar)
     - Output: Form Template "BillingDocument_PDF"
     - Canal: Email a VBPA-ADRNR (sold-to party)
  2. Crear plantilla email (App: Manage Email Templates)
  3. Asignar Adobe Form template

Tabla de monitoreo (reemplaza NAST):
  BEA_OUTPARAM    → parametros de output determinados
  BEA_OUTDOC      → documentos de output generados

App Fiori: Output Parameter Determination (F3034)
  → Ver outputs generados → Reenviar → Ver errores
```

### BRF+ para reglas de output SD
```abap
" Las reglas BRF+ para output SD se configuran via tabla/condicion:
" Objeto BRF+: /OPM/OUTPUT_RULE_APP
" Funciones: por tipo de documento (Billing, Sales Order, Delivery)
" Decision table: columnas = caracteristicas del documento
"                 resultado = output type + forma + canal

" ABAP: acceso programatico a BRF+ output rules
DATA(lo_brf_instance) = cl_fdt_factory=>get_instance( ).
" (no se necesita ABAP para configuracion estandar — solo Key User Tools)
```

---

## 11. Key User Extensibility para SD

### Custom Fields en objetos SD
```
App: Custom Fields and Logic (F1481) — SIN ABAP

Contextos de negocio SD disponibles:
  Sales Order Header         → VBAK extendida
  Sales Order Item           → VBAP extendida
  Billing Document Header    → VBRK extendida
  Billing Document Item      → VBRP extendida
  Outbound Delivery Header   → LIKP extendida
  Outbound Delivery Item     → LIPS extendida
  Customer (General)         → BUT000/KNA1 extendida
  Customer (Sales Area)      → KNVV extendida

Ejemplo: agregar campo "Codigo de proyecto cliente" a Sales Order Header:
  F1481 → Sales Order Header → New Field
  → Tipo: Char 20
  → Etiqueta: "Customer Project Code"
  → Incluir en: Fiori App (automatico) + OData API + CDS view
  → Publicar (genera campo ZZPROJECT_CODE en estructura extension)
```

### Custom Logic (BAdI Key User)
```
Logica de negocio configurable desde Fiori sin ABAP complejo:
  - Validaciones (before save)
  - Derivaciones (during field change)
  - Notificaciones (after save)

Ejemplo: Validar que pedido con clase 'ZEXPORT' tenga ZZPROJECT_CODE relleno:
  F1481 → Sales Order → Custom Logic → Before Save:
    IF VBAK-AUART = 'ZEXPORT' AND ZZPROJECT_CODE IS INITIAL THEN
      MESSAGE 'Project Code mandatory for export orders' TYPE 'E'
    END IF
  → Sin transportar, activo de inmediato
```

### Custom CDS Views
```
App: Custom CDS Views (F5566) — Key User Tool

Crear vista analitica custom con campos Z:
  1. F5566 → New View → Base: C_SalesOrderItem
  2. Agregar campos: ZZPROJECT_CODE (custom field)
  3. Agregar medidas: NETWR, KWMENG
  4. Publicar → genera vista CDS Z disponible para:
     - Custom Analytical Queries (F4512)
     - SAP Analytics Cloud
     - OData service

Naming convention para vistas custom: YY1_ prefijo (generado automaticamente)
```

---

## 12. Monitor Value Chains (F4854)

```
App Fiori: Monitor Value Chains (F4854)

Visibilidad end-to-end del proceso Order-to-Cash:
  - Vista unificada: pedido → entrega → factura → cobro
  - Identificar cuellos de botella (ej: pedidos sin entrega > 3 dias)
  - KPIs por etapa del proceso
  - Drill-down a documentos individuales desde cualquier etapa
  - Alertas configurables por umbral de tiempo

Util para:
  - Gerentes de Customer Service que monitorean fulfillment
  - Equipos de mejora continua (lean)
  - Auditorias de lead time del proceso O2C
```

---

## 13. Advanced Intercompany Sales (2023)

```
Mejoras en facturacion intercompany:
  - App Fiori: Intercompany Billing (F4384)
  - BAdI: SD_IC_S4_BILLING → logica custom de intercompany pricing
  - Automatic settlement: conciliacion automatica entre sociedades
  - Support for transfer pricing rules integrado

Flujo mejorado:
  1. Pedido en sociedad vendedora
  2. Entrega desde sociedad suministradora (cross-company)
  3. Factura al cliente (sociedad vendedora)
  4. Factura intercompany (sociedad suministradora → vendedora)
  5. Settlement automatico via ACDOCA
```

---

## 14. Compatibility Pack — Funciones deprecadas disponibles

### Que incluye el Compatibility Pack SD
```
Funcionalidades ECC que siguen disponibles en S/4 2023 via Compatibility Pack
(SAP los mantiene pero recomienda migrar):

  - Transacciones SD GUI (VA01, VL01N, VF01...) → SIGUEN disponibles
  - Release Strategy clasica (SPRO) → disponible, pero Flexible Workflow recomendado
  - SAPscript / SmartForms → disponibles, pero Adobe Forms recomendado
  - Output via NAST (VV11/VV12) → disponible para tipos no migrados a OM 2.0
  - LIS/SIS reports (MC* transactions) → disponibles pero sin actualizacion de datos
    (los datos ya no se escriben a tablas LIS desde MATDOC)
  - ALE/IDoc para SD (ORDERS, DESADV, INVOIC) → SIGUEN funcionando sin cambios
  - BAPIs SD legacy → SIGUEN funcionando
  - User Exits SD (MV45AFZZ, MV50AFZ1, MV60AFZ1) → SIGUEN disponiendo
    (pero SAP recomienda migrar a Enhancement Spots/BAdIs)
```

### User Exits vs BAdIs en S/4 2023
```
User Exit (ECC style)          | BAdI equivalente S/4
-------------------------------|----------------------------------
FORM USEREXIT_SAVE_DOCUMENT    | BAdI: SD_SLS_SD_ORDER_SAVE
FORM USEREXIT_FIELD_MODIFICATION| BAdI: SD_SLS_SD_ITEM_MODIFY
MV45AFZZ (include en SAPMV45A) | Enhancement Spot: SD_SLS_SD_ORDER
MV50AFZ1 (delivery)            | BAdI: LE_SHP_DELIVERY_PROC
MV60AFZ1 (billing)             | BAdI: SD_VFOX_BILLING

Ambos funcionan en S/4 2023, pero BAdIs son mas robustos:
  - Multiples implementaciones posibles
  - Filtros de activacion
  - Mejor rendimiento
  - Testeables con mockup
```

---

## 13. Migracion de ECC SD a S/4HANA SD

### Diferencias principales y gotchas

```
1. CLIENTE MAESTRO:
   ECC: XD01/VD01 crean directamente en KNA1
   S/4: OBLIGATORIO via BP. Los programas LSMW/BAPI_CUSTOMER_CREATEFROMDATA1
        redirigen automaticamente a CVI.
   Gotcha: codigo Z que hace INSERT INTO KNA1 → DUMP en S/4.

2. PARTIDAS CLIENTE (FI):
   ECC: SELECT FROM BSID/BSAD (tablas reales)
   S/4: BSID/BSAD son compatibility views → funcionan pero lentas.
   Gotcha: JOIN entre BSID y VBRK en report custom → puede ser muy lento.
   Solucion: migrar a ACDOCA con JOIN a VBRK.

3. PGI Y MATDOC:
   ECC: SELECT FROM MKPF JOIN MSEG (tablas reales)
   S/4: MKPF/MSEG son compatibility views sobre MATDOC.
   Gotcha: ninguno critico, pero rendimiento mejor con MATDOC directo.

4. ESTADISTICAS LIS/SIS:
   ECC: MC* reports leen tablas LIS actualizadas en tiempo real
   S/4: tablas LIS NO se actualizan. MC* muestran datos congelados o vacios.
   Solucion obligatoria: migrar a Embedded Analytics (CDS views).

5. CREDIT MANAGEMENT:
   ECC: FD32/KNKK (area de credito simple)
   S/4 con FSCM: UKM_LIMIT por segmento de credito → diferente estructura.
   Gotcha: si la empresa usaba FD32 en ECC, puede seguir usando KNKK en S/4
            (compatibility), pero no se beneficia de FSCM scoring.

6. OUTPUT:
   ECC: NAST + SmartForms es la combinacion estandar
   S/4: Output Management 2.0 para nuevas implementaciones.
   Gotcha: ambos pueden coexistir por tipo de documento, pero no mezclar
            en el mismo tipo de documento.

7. aATP:
   ECC: ATP clasico (MTVFP + tabla VBBE)
   S/4: si aATP activado, la verificacion es totalmente diferente.
   Gotcha: codigo Z que lee VBBE directamente → datos pueden no estar actualizados.

8. PRICING / KONV:
   KONV → COMPATIBILITY VIEW sobre PRCD_ELEMENTS (SAP Note 2220005).
   SELECT FROM KONV funciona (lectura). INSERT/UPDATE/DELETE → DUMP.
   Nuevo mantenimiento via Fiori F4599 (no VK11/VK12).
   Gotcha: codigo Z que escribe en KONV directamente → migrar a PRCD_ELEMENTS o APIs.
   BAPI_PRICES_CONDITIONS sigue funcionando (abstrae las tablas).
```

### Checklist de migracion SD (custom code)
```
Ejecutar SYCM (Custom Code Migration Worklist):
  Criticos (deben corregirse):
  [ ] INSERT/UPDATE INTO KNA1 → usar BAPI_CUSTOMER_CREATEFROMDATA1
  [ ] SELECT FROM BSID/BSAD → migrar a ACDOCA o dejar (lento)
  [ ] SELECT FROM MC* tables → migrar a CDS analytical views
  [ ] User Exits en includes deprecados → verificar si aun funcionan

  Warnings (recomendado corregir):
  [ ] SELECT FROM MKPF JOIN MSEG → migrar a MATDOC
  [ ] SELECT FROM KNKK → verificar si se usa FSCM o compatibility
  [ ] SAPscript/SmartForms outputs → migrar a Adobe Forms (OM 2.0)
```

---

## 14. Feature Toggles — Business Functions relevantes para SD

```
Business Function          | Descripcion | Activacion
---------------------------|-------------|----------
LOG_AATP_BASIC             | aATP basico (multi-plant ATP) | SFW5
LOG_AATP_PAL               | Product Allocation (aATP) | SFW5 (requiere LOG_AATP_BASIC)
LOG_AATP_BOP               | Backorder Processing (aATP) | SFW5
FSCM_CR                    | SAP Credit Management (FSCM) | SFW5
SD_01                      | SD S/4HANA Foundation | Activado por defecto S/4
LOG_SD_LEAN_DLV            | Lean Delivery (entrega simplificada) | SFW5
LOG_PP_MRP_EAM             | Predictive MRP (requiere AI) | SFW5
FIN_GL_REORG_1             | Universal Journal (ACDOCA activo) | Activado S/4
```

### Verificar business functions activas
```abap
" Verificar si aATP esta activo
IF cl_fm_area=>check( 'LOG_AATP_BASIC' ) = abap_true.
  " aATP activo - usar logica S/4
ELSE.
  " ATP clasico - usar MTVFP/VBBE
ENDIF.

" Verificar via transaccion SFW5
" SFW5 → Overview de Business Functions activas/inactivas
" NOTA: activar BF es IRREVERSIBLE en produccion
```

### Consideraciones de activacion
```
Reglas de oro para BF en SD:
  1. NUNCA activar BF en produccion sin testear en sandbox + QA
  2. LOG_AATP_BASIC: requiere re-configuracion completa de checking rules
     (las reglas ATP clasicas NO se migran automaticamente)
  3. FSCM_CR: requiere decision sobre coexistencia con KNKK clasico
     (migracion de limites de credito existentes a UKM_LIMIT)
  4. Output Management 2.0: activar por tipo de documento, no globalmente
     (permite migracion gradual sin afectar tipos existentes)
```
