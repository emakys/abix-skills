# Extensibilidad PS en S/4HANA — SAP Project System

## Indice
1. Tipos de Extensibilidad en S/4HANA
2. Key User Extensibility (In-App)
3. BAdIs Clasicos PS
4. BAdIs S/4HANA (ABAP Cloud)
5. RAP Business Objects para PS
6. ABAP Cloud APIs Liberadas
7. Side-by-Side Extensibility (BTP)
8. APIs Deprecadas y Migracion
9. Ejemplos Practicos
10. Guia de Decision: Que Usar

---

## 1. Tipos de Extensibilidad en S/4HANA

### 1.1 Modelo de Extensibilidad SAP

```
┌─────────────────────────────────────────────────────┐
│              ABAP CLOUD EXTENSIBILITY               │
├─────────────────────────────────────────────────────┤
│  KEY USER (In-App)   │  DEVELOPER (Side-by-Side)    │
│  - Custom Fields     │  - BTP / CAP                 │
│  - Custom Logic      │  - RAP Extensions             │
│  - UI Adaptation     │  - OData Proxies             │
│  - Custom Workflows  │  - Event-driven Integration  │
├─────────────────────────────────────────────────────┤
│           CLASSIC ABAP (On-Stack Developer)          │
│  - BAdIs (Enhancement Spots)                        │
│  - User Exits                                       │
│  - Implicit/Explicit Enhancements                   │
└─────────────────────────────────────────────────────┘
```

### 1.2 Regla de Oro ABAP Cloud

**Clean Core Principle:**
- Extensiones deben usar SOLO APIs liberadas (Released)
- No modificar codigo SAP estandar (no modificaciones)
- No usar tablas/clases marcadas como `@AccessControl.authorizationCheck: #NOT_REQUIRED` si no son Released
- Usar `USE IN CLOUD DEVELOPMENT` como indicador

**Verificar si un objeto es Released:**
```
Transaccion: ABAPDOC → buscar el objeto
O en ADT: Click derecho → Properties → API State = "Released"
```

---

## 2. Key User Extensibility (In-App)

### 2.1 Custom Fields

**Acceso:** Fiori Launchpad → "Custom Fields and Logic"
**App:** F2351

**Business Contexts disponibles para PS:**

| Contexto | Descripcion | Tabla origen |
|----------|-------------|-------------|
| `SAP_PS_PROJECT` | Cabecera de proyecto | PROJ |
| `SAP_PS_WBS_ELEMENT` | Elemento WBS | PRPS |
| `SAP_PS_NETWORK` | Red de proyecto | AUFK |
| `SAP_PS_ACTIVITY` | Actividad de red | AFVC |
| `SAP_PS_MILESTONE` | Hitos | |

**Tipos de campo disponibles:**
- Texto (CHAR, 1-250 chars)
- Numerico (DEC, sin decimales)
- Importe (CURR, con moneda)
- Cantidad (QUAN, con unidad)
- Fecha (DATS)
- Casilla (CHAR 1, check)
- Codigo de referencia (FK a tabla custom)

**Proceso de creacion:**
```
1. Ir a Custom Fields and Logic app
2. Seleccionar Business Context
3. "New Field" → definir tipo y label
4. Activar en apps Fiori (checkbox por app)
5. Activar en servicios OData (para integracion)
6. Publicar → disponible sin transporte
```

**Tabla extension generada:**
SAP genera automaticamente una tabla de extension: `YY1_{CAMPO}_{CONTEXT}`

### 2.2 Custom Logic

**Descripcion:** BAdI-like pero sin ABAP por parte del Key User. Se puede usar para validaciones simples, derivaciones y mensajes.

**Triggers disponibles para PS:**
| Trigger | Descripcion |
|---------|-------------|
| Before Save (Project) | Antes de grabar proyecto |
| After Save (Project) | Despues de grabar |
| Before Save (WBS) | Antes de grabar WBS |
| Status Change | Al cambiar status |
| Budget Check | Al verificar presupuesto |

**Ejemplo de validacion (Key User Logic):**
```abap
" Validar que proyectos tipo 'CAP' tengan centro de beneficio
IF project_type = 'CAP' AND profit_center IS INITIAL.
  APPEND VALUE #(
    field_name = 'ProfitCenter'
    message_text = 'Centro de beneficio obligatorio para proyectos CAPEX'
    severity = 'E'
  ) TO messages.
ENDIF.
```

### 2.3 UI Adaptation

**Sin codigo:**
- Mostrar/ocultar campos en formularios Fiori PS
- Reordenar secciones del Project Builder
- Cambiar etiquetas a terminologia de la empresa
- Agregar campos custom al layout

**Con herramienta SAPUI5 Flexibility:**
- Adaptar a nivel usuario, rol o global
- Exportar/importar variantes de UI
- A/B testing de layouts

---

## 3. BAdIs Clasicos PS

### 3.1 Enhancement Spots PS

Los BAdIs clasicos se agrupan en Enhancement Spots:

| Enhancement Spot | Descripcion |
|-----------------|-------------|
| `BADI_PS_GENERAL` | BAdIs generales PS |
| `BADI_PS_WBS` | BAdIs para WBS |
| `BADI_PS_NETWORK` | BAdIs para redes |
| `BADI_PS_COSTS` | BAdIs para costes |
| `BADI_PS_BUDGET` | BAdIs para presupuesto |
| `BADI_PS_SETTLEMENT` | BAdIs para liquidacion |

### 3.2 BAdIs Principales

#### BADI_PROJ_DATA_CHECK
**Descripcion:** Validacion de datos de proyecto antes de grabar.
**Metodo:** `CHECK_DATA`

```abap
METHOD if_badi_proj_data_check~check_data.
  " Validar que todos los proyectos activos tengan PM asignado
  IF im_proj-verna IS INITIAL
    AND im_proj_status = 'REL'.

    APPEND VALUE #(
      field = 'VERNA'
      msgid = 'ZPS'
      msgno = '001'
      msgty = 'E'
      msgv1 = im_proj-pspid
    ) TO ch_messages.
  ENDIF.
ENDMETHOD.
```

#### BADI_POSID_MASK
**Descripcion:** Validacion o modificacion de la mascara de codificacion WBS.

#### BADI_BUDGET_AVAILABILITY
**Descripcion:** Logica personalizada de control de disponibilidad de presupuesto.
**Metodo:** `CHECK_AVAILABILITY`
**Uso tipico:** Agregar excepciones al control estandar.

```abap
METHOD if_badi_budget_availability~check_availability.
  " Eximir pedidos de emergencia del control de presupuesto
  IF im_purchase_order-bsart = 'ZEMG'.  " Pedido de emergencia
    ev_exempt = abap_true.
  ENDIF.
ENDMETHOD.
```

#### BADI_PS_SETTLEMENT_RULE
**Descripcion:** Modificar reglas de liquidacion antes de ejecutar.

#### BADI_PS_NETCHANGE_SCHEDULE
**Descripcion:** Modificar programacion de redes.

### 3.3 Implementar un BAdI Clasico

```
1. SE18 → Enhancement Spot → buscar BADI_PROJ_DATA_CHECK
2. "Create Implementation"
3. Nombre: ZCHK_PROJ_VALIDATIONS
4. Implementar metodos requeridos en clase ABAP
5. Activar
6. Transportar (SE10)
```

---

## 4. BAdIs S/4HANA (ABAP Cloud Compliant)

### 4.1 RAP Enhancement BAdIs

En S/4HANA con ABAP Cloud, los BAdIs se definen como Enhancement Spots en el Business Object:

```abap
" Definicion de Enhancement Spot (SAP entrega)
ENHANCEMENT SPOT es_project_check
  FOR BDEF i_projectbuildertp;

  BADI check_project_data
    FOR MODIFY
    ENTITY project;
END ENHANCEMENT SPOT.
```

### 4.2 Implementacion BAdI ABAP Cloud

```abap
" Clase de implementacion del BAdI
CLASS zcl_badi_project_check DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_badi_check_project_data.

ENDCLASS.

CLASS zcl_badi_project_check IMPLEMENTATION.

  METHOD if_badi_check_project_data~check_data.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " Validacion: proyecto tipo INV requiere centro beneficio
      IF <entity>-%data-projecttype = 'INV'
         AND <entity>-%data-profitcenter IS INITIAL.

        APPEND VALUE #(
          %key = <entity>-%key
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |Proyecto { <entity>-%data-project }: Centro de beneficio obligatorio|
          )
          profitcenter = if_abap_behv=>mk-on
        ) TO failed-project.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
```

---

## 5. RAP Business Objects para PS

### 5.1 PS y RAP en S/4HANA 2023

SAP ha reescrito partes de PS como RAP Business Objects:

| RAP BO | CDS View | Descripcion |
|--------|----------|-------------|
| `I_ProjectBuilderTP` | Project + WBS | Crear/editar proyectos |
| `I_EnterpriseProject` | Proyecto | CRUD basico |
| `I_WBSElement` | WBS | CRUD basico |
| `I_ProjectNetwork` | Red | Redes y actividades |
| `I_ProjectBudget` | Presupuesto | Aprobar/liberar |

### 5.2 Consumir RAP BO desde ABAP

```abap
" Leer proyecto via EML (Entity Manipulation Language)
READ ENTITIES OF i_enterpriseproject
  ENTITY EnterpriseProject
    FIELDS ( Project ProjectDescription CompanyCode )
  WITH VALUE #( ( %key-Project = 'INV-2024-001' ) )
  RESULT DATA(lt_projects)
  FAILED DATA(lt_failed)
  REPORTED DATA(lt_reported).

IF lt_failed IS INITIAL.
  DATA(ls_project) = lt_projects[ 1 ].
  " Procesar datos...
ENDIF.
```

```abap
" Crear proyecto via EML
MODIFY ENTITIES OF i_enterpriseproject
  ENTITY EnterpriseProject
    CREATE FIELDS ( Project ProjectDescription CompanyCode ProjectType )
    WITH VALUE #(
      (
        %cid = 'NEW_PROJECT_1'
        Project            = 'INV-2024-NEW'
        ProjectDescription = 'Nuevo Proyecto Inversion'
        CompanyCode        = '1000'
        ProjectType        = 'INV'
      )
    )
  REPORTED DATA(lt_reported)
  FAILED DATA(lt_failed)
  MAPPED DATA(lt_mapped).

IF lt_failed IS INITIAL.
  COMMIT ENTITIES.
ENDIF.
```

### 5.3 Extension de RAP BO (Projection Extension)

Para agregar campos o comportamiento a BOs existentes:

```abap
" Extension de proyeccion (Add-On pattern)
EXTEND BEHAVIOR PROJECTION i_enterpriseproject_ext
  WITH
    ENTITY EnterpriseProject
      FIELD (READONLY) CustomField1;

    VALIDATION validate_custom_fields
      ON SAVE FIELD CustomField1;
```

---

## 6. ABAP Cloud APIs Liberadas

### 6.1 Clases Released para PS

| Clase/Interface | Descripcion | Release |
|----------------|-------------|---------|
| `IF_PS_PROJECT_API` | Interface proyecto (deprecated, usar RAP) | 1809 |
| `CL_PS_WBS_API` | Operaciones WBS via API | 2020 |
| `IF_BAPI_PS` | BAPIs PS encapsuladas | 1511 |
| `CL_PS_BUDGET_CHECK` | Verificacion de presupuesto | 2021 |

**Verificar objetos Released:**
```
ADT (Eclipse) → Project → buscar clase
  → Click derecho → Properties → Release State
  → "Released" = se puede usar en ABAP Cloud
```

### 6.2 APIs de Negocio (Business APIs) S/4

```abap
" Usar API Released para leer datos de proyecto
DATA(lo_project_api) = cl_ps_project_factory=>create_project_api(
  iv_project_id = 'INV-2024-001'
).

DATA(ls_project_data) = lo_project_api->get_header_data( ).
DATA(lt_wbs_elements) = lo_project_api->get_wbs_elements( ).
```

### 6.3 OData V4 Consumer Proxy

Para consumir APIs externas desde ABAP:
```abap
" Consumir API REST de proyecto desde ABAP
DATA(lo_http) = cl_web_http_client_manager=>create_by_http_destination(
  i_destination = cl_http_destination_provider=>create_by_comm_arrangement(
    i_comm_scenario = 'SAP_PS_OUTBOUND'
  )
).

DATA(lo_request) = lo_http->get_http_request( ).
lo_request->set_uri_path( '/sap/opu/odata4/sap/api_project/srvd_a2x/sap/project/0001/Project' ).
lo_request->set_method( 'GET' ).

DATA(lo_response) = lo_http->execute( i_method = if_web_http_client=>get ).
```

---

## 7. Side-by-Side Extensibility (BTP)

### 7.1 Cuando Usar BTP (Side-by-Side)

| Escenario | In-App | Side-by-Side (BTP) |
|-----------|--------|---------------------|
| Campo adicional simple | X | |
| Validacion de negocio | X | |
| UI cosmetics | X | |
| App completamente nueva | | X |
| Machine Learning | | X |
| Integracion sistema externo | | X |
| Proceso aprobacion complejo | | X |
| Reporting avanzado | | X |

### 7.2 Arquitectura BTP + PS

```
SAP S/4HANA (PS)
    ↑↓ OData APIs (API_PROJECT_ELEMENT_SRV)
SAP Integration Suite (Cloud Integration)
    ↑↓
SAP BTP (Business Technology Platform)
    ├── CAP Application (Node.js / Java)
    ├── SAP Build Apps (Low Code)
    └── SAP Analytics Cloud
```

### 7.3 Extension CAP para PS

```javascript
// CAP Service que consume API PS de S/4HANA
const cds = require('@sap/cds');

module.exports = class ProjectExtensionService extends cds.ApplicationService {

  async init() {
    // Conectar a S/4HANA via destination
    const ps = await cds.connect.to('S4HANA_PS');

    // Extender entidad Project con logica adicional
    this.before('CREATE', 'Projects', async (req) => {
      // Validacion personalizada desde BTP
      const { ProjectType, Budget } = req.data;
      if (ProjectType === 'CAP' && Budget > 1000000) {
        await this.notifyExecutiveApproval(req.data);
      }
    });

    this.on('READ', 'Projects', async (req) => {
      // Enriquecer con datos de sistema externo
      const projects = await ps.run(req.query);
      return this.enrichWithExternalData(projects);
    });

    await super.init();
  }

  async notifyExecutiveApproval(project) {
    // Enviar notificacion via SAP Alert Notification
  }
};
```

### 7.4 Event-Driven Integration (Business Events)

S/4HANA 2022+ emite Business Events que BTP puede consumir:

**Eventos PS disponibles:**
```
sap.s4.beh.project.v1.Project.Created.v1
sap.s4.beh.project.v1.Project.Changed.v1
sap.s4.beh.project.v1.Project.StatusChanged.v1
sap.s4.beh.wbselement.v1.WBSElement.Created.v1
sap.s4.beh.project.v1.Budget.Exceeded.v1
```

**Configuracion:**
```
S/4HANA → Enterprise Eventing (Transaccion: /IWXBE/CONFIG)
  → Crear Canal → Seleccionar eventos PS
  → Configurar Topic (SAP Event Mesh)

BTP → Event Mesh → Suscribir al topic
  → CAP/Function → Procesar evento
```

---

## 8. APIs Deprecadas y Migracion

### 8.1 Objetos Deprecados

| Objeto | Estado | Reemplazo |
|--------|--------|-----------|
| Function group BAPI_PS | Deprecated | CL_PS_WBS_API / RAP EML |
| BAPI_NETWORK_CREATE | Deprecated | RAP BO I_ProjectNetwork |
| CLASS CL_PROJECT (legacy) | Deprecated | CL_PS_PROJECT_FACTORY |
| User Exit EXIT_SAPLFMSC_001 | Deprecated | BAdI BADI_PROJ_DATA_CHECK |
| Table COSP/COSS (read) | Removed | ACDOCA |

### 8.2 Guia de Migracion de User Exits

```
ECC: EXIT_SAPLFMSC_001 (Proyecto: antes de grabar)
  ↓
S/4 ABAP Classic: BAdI BADI_PROJ_DATA_CHECK
  ↓
S/4 ABAP Cloud: Enhancement BAdI en RAP BO
```

---

## 9. Ejemplos Practicos

### 9.1 Custom Field: "Numero de Contrato" en Proyecto

**Via Key User Tools:**
```
1. Custom Fields and Logic → New Field
2. Context: SAP_PS_PROJECT
3. Name: CONTRACT_NUMBER
4. Label: "Numero de Contrato"
5. Type: CHAR(20)
6. Visible en: Project Builder Web, Project Cockpit
7. En OData: si (para integracion)
8. Publicar
```

**Resultado:** El campo aparece en el formulario de proyecto sin desarrollo ABAP.

### 9.2 BAdI: Derivacion Automatica de Centro de Beneficio

```abap
" Derivar ProfitCenter automaticamente segun tipo de proyecto
METHOD if_badi_proj_data_check~check_data.

  DATA(lv_profit_center) = SWITCH #( im_proj-projk
    WHEN 'INV'  THEN '4100'   " Inversiones → PC Inversiones
    WHEN 'OPS'  THEN '4200'   " Operaciones → PC Operaciones
    WHEN 'RES'  THEN '4300'   " Investigacion → PC I+D
    ELSE ''
  ).

  IF lv_profit_center IS NOT INITIAL
    AND im_proj-prctr IS INITIAL.
    " Derivar automaticamente
    ch_proj-prctr = lv_profit_center.
  ENDIF.

ENDMETHOD.
```

### 9.3 RAP Extension: Validacion Budget Maximo

```abap
" En clase de implementacion del BAdI RAP
METHOD validate_budget_limit.
  READ ENTITIES OF i_projectbuildertp
    ENTITY WBSElement
      FIELDS ( WBSElement PlannedCost ProjectType )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_wbs).

  LOOP AT lt_wbs ASSIGNING FIELD-SYMBOL(<wbs>).
    IF <wbs>-ProjectType = 'INV'
       AND <wbs>-PlannedCost > 5000000.  " 5M limite

      APPEND VALUE #(
        %key       = <wbs>-%key
        %msg       = new_message_with_text(
          severity = if_abap_behv_message=>severity-warning
          text     = |WBS { <wbs>-WBSElement }: Supera el limite de 5M para proyectos INV|
        )
        PlannedCost = if_abap_behv=>mk-on
      ) TO reported-wbselement.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
```

---

## 10. Guia de Decision: Que Usar

```
¿Que necesito extender?
│
├── Campo adicional en formulario
│   └── → Key User: Custom Fields (sin ABAP)
│
├── Validacion simple de negocio
│   ├── Regla simple → Key User: Custom Logic
│   └── Logica compleja → BAdI clasico o RAP BAdI
│
├── UI completamente diferente
│   └── → SAP Build Apps (BTP) consumiendo OData
│
├── Integracion con sistema externo
│   └── → SAP Integration Suite + Business Events
│
├── Reporte avanzado / BI
│   └── → SAP Analytics Cloud con Live Connection a CDS Views
│
├── ML / IA aplicada a proyectos
│   └── → SAP AI Core (BTP) + consumo via API
│
└── Override de logica core PS
    ├── S/4 en cloud → RAP BAdI (ABAP Cloud)
    └── S/4 on-prem → BAdI clasico (Enhancement Spot)
```

---

*Referencia: SAP S/4HANA 2023 | Extensibility Guide | ABAP Cloud Developer Guide*
*SAP Help: help.sap.com → SAP S/4HANA → Extensibility*
