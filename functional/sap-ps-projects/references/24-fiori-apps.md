# Fiori Apps PS — S/4HANA 2023

## Indice
1. Catalogo de Apps PS
2. Project Builder Web
3. Monitor Projects
4. Project Financials
5. Manage Project Plans
6. Approve Projects
7. Project Cockpit
8. Apps de Analisis y Reporting
9. Business Roles PS
10. Configuracion y Activacion
11. OData Services y CDS Views
12. Personalizacion y Extensibilidad

---

## 1. Catalogo de Apps PS

### Resumen por Categoria

| Categoria | Num Apps | Descripcion |
|-----------|----------|-------------|
| Gestion de proyecto | 6 | Creacion, edicion, aprobacion |
| Control financiero | 5 | Costes, presupuesto, varianzas |
| Reporting analitico | 4 | Dashboards, KPIs, portfolios |
| Administracion | 3 | Config, maestros, templates |

---

### Listado Completo

| App Name | App ID | Tipo | Fiori Role |
|----------|--------|------|------------|
| Project Builder | F2284 | Transactional | SAP_BR_PROJECT_MANAGER |
| My Projects | F3539 | Transactional | SAP_BR_PROJECT_MANAGER |
| Monitor Projects | F2375 | Analytical | SAP_BR_PROJECT_MANAGER |
| Project Cost Overview | F2344 | Analytical | SAP_BR_PROJECT_MANAGER |
| Project Budget Control | F4852 | Analytical | SAP_BR_PROJECT_MANAGER |
| Manage Project Plans | F2338 | Transactional | SAP_BR_PROJECT_MANAGER |
| Approve Projects | F2237 | Transactional | SAP_BR_PROJECT_MANAGER |
| Project Cockpit | F4850 | Overview Page | SAP_BR_PROJECT_MANAGER |
| Project Financial Control | F5567 | Analytical | SAP_BR_CTRL_SPECST |
| WBS Cost Details | F2348 | Analytical | SAP_BR_PROJECT_MANAGER |
| Project Earned Value | F2347 | Analytical | SAP_BR_PROJECT_MANAGER |
| Commercial Project Mgmt | F3754 | Transactional | SAP_BR_COMML_PROJ_MGR |
| Change Budget | F2252 | Transactional | SAP_BR_PROJECT_MANAGER |
| Transfer Budget | F2253 | Transactional | SAP_BR_PROJECT_MANAGER |
| Close Project | F2254 | Transactional | SAP_BR_PROJECT_MANAGER |
| Project Milestone Billing | F2256 | Transactional | SAP_BR_PROJECT_MANAGER |

---

## 2. Project Builder Web (F2284)

### Descripcion General

Reemplazo de la transaccion CJ20N (Project Builder SAPGUI). Permite crear y gestionar proyectos con estructuras WBS y redes directamente desde el navegador.

**App ID:** F2284
**Tipo:** Transactional (SAPUI5)
**OData Service:** `C_PROJECTBUILDER_SRV` (basado en RAP)
**CDS View:** `I_ProjectBuilderTP` (transactional processing)
**Business Role:** SAP_BR_PROJECT_MANAGER

### Funcionalidades

| Funcionalidad | Descripcion |
|---------------|-------------|
| Crear proyecto | Nuevo proyecto con datos basicos |
| Editar WBS | Anadir/modificar/eliminar WBS elements |
| Asignar fechas | Fechas inicio/fin por WBS |
| Planificar costes | Manual cost planning en WBS |
| Asignar status | Cambio de status sistema y usuario |
| Redes de proyecto | Crear/editar redes y actividades |
| Hitos | Definicion de milestones |
| Vista jerarquica | Arbol de WBS con expand/collapse |
| Exportar | Export a Excel de la estructura |

### Pantallas Principales

```
1. Lista de proyectos (overview)
2. Detalles del proyecto (header)
3. Estructura WBS (tree view)
4. Detalles WBS element (form)
5. Actividades de red (Gantt opcional)
6. Planificacion de costes (tabla)
```

### Permisos Requeridos

```
Role: SAP_BR_PROJECT_MANAGER
Authorization Objects:
  - C_PRPS_KOK (Area de controlling para WBS)
  - C_PROJ_KOK (Area de controlling para proyecto)
  - M_BEST_WRK (Centro para operaciones MM)
```

---

## 3. Monitor Projects (F2375)

### Descripcion General

Dashboard de supervision del estado de proyectos. Vista de cartera con filtros avanzados y KPIs semaforo (RAG).

**App ID:** F2375
**Tipo:** Analytical (Smart Controls)
**OData Service:** `C_PROJECTMONITOR_CDS`
**CDS View:** `C_ProjectMonitor` (consumption view)
**Business Role:** SAP_BR_PROJECT_MANAGER, SAP_BR_PROGRAM_MANAGER

### Funcionalidades

| Funcionalidad | Descripcion |
|---------------|-------------|
| Lista proyectos | Tabla configurable con todos los proyectos |
| Filtros rapidos | Por status, tipo, responsable, fecha, sociedad |
| Semaforo RAG | Indicador visual de estado del proyecto |
| KPIs inline | CPI, SPI, % budget usado en la lista |
| Drill-down | Navegacion a Project Cockpit o Builder |
| Export | Descarga a Excel/CSV |
| Grupos | Agrupacion por tipo, status, responsable |

### Columnas Configurables

| Columna | Campo fuente | Descripcion |
|---------|-------------|-------------|
| Project | PSPID | ID del proyecto |
| Description | POST1 | Nombre del proyecto |
| System Status | JEST status | Status SAP |
| User Status | Perfil usuario | Status personalizado |
| Responsible | VERNA | PM asignado |
| Start | PLFAZ | Fecha inicio plan |
| End | PLSEZ | Fecha fin plan |
| Plan Cost | RPSCO WRTTP=01 | Coste planificado |
| Actual Cost | ACDOCA HSL | Coste real |
| Budget | BPGE WLIBFR | Presupuesto liberado |
| Available | Calculo | Budget - Actual - Commitment |
| % Complete | Progress | Avance fisico |
| Traffic Light | Calculado | RAG basado en reglas |

### Logica Semaforo RAG

```
VERDE  → CPI >= 0.95 AND SPI >= 0.95 AND Budget% <= 90
AMBAR  → (CPI < 0.95 OR SPI < 0.95) AND no critico
ROJO   → CPI < 0.85 OR SPI < 0.85 OR Budget% > 100
```

---

## 4. Project Financial Control (F5567)

### Descripcion General

Control financiero detallado de proyectos. Permite ver plan vs real vs presupuesto a nivel WBS, con analisis de varianzas y compromisos.

**App ID:** F5567
**Tipo:** Analytical
**OData Service:** `C_PROJECTFINANCIALCONTROL_SRV`
**CDS View:** `C_ProjectFinancialControl`
**Business Role:** SAP_BR_CTRL_SPECST, SAP_BR_PROJECT_MANAGER

### Secciones del App

```
1. Header KPIs
   - Total Budget | Actual | Commitment | Available
   - % Consumed | CPI | Forecast

2. WBS Breakdown (tabla jerarquica)
   - Por WBS element: Plan | Actual | Commitment | Budget | Variance

3. Cost Element Detail
   - Desglose por elemento de coste del WBS seleccionado

4. Period Trend (grafico)
   - Costes mensuales plan vs real en linea de tiempo

5. Document List
   - Documentos FI individuales drill-through
```

### OData Entities

| Entity | Descripcion |
|--------|-------------|
| `ProjectFinancialControl` | Cabecera financiera proyecto |
| `WBSFinancialControl` | Datos por WBS |
| `CostElementBreakdown` | Desglose elementos de coste |
| `PeriodCostValues` | Costes por periodo |
| `FinancialDocument` | Documentos individuales |

---

## 5. Manage Project Plans (F2338)

### Descripcion General

Gestion de planes de costes de proyecto. Permite introducir, revisar y aprobar planes de costes anuales o totales.

**App ID:** F2338
**Tipo:** Transactional
**OData Service:** `C_PROJECTPLANMGMT_SRV`
**CDS View:** `I_WBSPlannedCost`
**Business Role:** SAP_BR_PROJECT_MANAGER, SAP_BR_CTRL_SPECST

### Funcionalidades

| Funcionalidad | Descripcion |
|---------------|-------------|
| Plan manual | Introduccion de costes plan por WBS |
| Plan por elemento de coste | Desglose por tipo de coste |
| Plan periodico | Distribucion mensual del plan |
| Comparativa versiones | Plan v0 vs v1 vs real |
| Copiar plan | De periodo a periodo, de version a version |
| Distribucion automatica | Distribucion uniforme del total anual |
| Aprobacion de plan | Flujo de aprobacion configurable |

### Proceso de Planificacion

```
1. Seleccionar proyecto/WBS
2. Introducir plan total por elemento de coste
3. Distribuir por periodos (manual o automatico)
4. Revisar totales y varianzas
5. Enviar a aprobacion (si hay workflow)
6. Aprobar → plan queda activo en version 0
```

---

## 6. Approve Projects (F2237)

### Descripcion General

App de aprobacion de proyectos y cambios de status. Permite a managers aprobar solicitudes de apertura, cambios de fase o cierre.

**App ID:** F2237
**Tipo:** Transactional (con workflow)
**OData Service:** basado en BRF+ / Flexible Workflow
**Business Role:** SAP_BR_PROJECT_APPROVER

### Flujo de Aprobacion

```
1. PM crea/modifica proyecto → estado PENDIENTE
2. Sistema crea work item en Business Workplace (SBWP)
3. Notificacion por email a aprobador
4. Aprobador accede a F2237 → lista de solicitudes pendientes
5. Revision de detalles (costes, fechas, scope)
6. Aprobar / Rechazar / Solicitar info adicional
7. Si aprobado → status cambia automaticamente (BS02)
8. PM notificado del resultado
```

### Tipos de Aprobacion

| Tipo | Trigger | Aprobador |
|------|---------|-----------|
| Nueva apertura de proyecto | Status CRTD → REL | Program Manager |
| Suplemento de presupuesto | Solicitud exceso >10% | Controlling |
| Cierre tecnico | Status REL → TECO | PM Senior |
| Reactivacion | Status TECO → REL | Program Manager |

---

## 7. Project Cockpit (F4850)

### Descripcion General

Overview Page (OVP) que consolida en una sola pantalla los KPIs, estado, fechas y documentos del proyecto. Vision 360° para el Project Manager.

**App ID:** F4850
**Tipo:** Overview Page (OVP)
**OData Services:** Multiples (composicion)
**Business Role:** SAP_BR_PROJECT_MANAGER

### Secciones del Cockpit

| Seccion | Contenido | Tipo |
|---------|-----------|------|
| Project Header | Datos basicos, status, PM, fechas | Card basico |
| Financial KPIs | Budget, Actual, CPI, EAC | KPI card |
| Cost Trend | Grafico mensual plan vs real | Chart card |
| WBS Summary | Top 5 WBS con mayores costes | List card |
| Open Issues | Issues/risks abiertos | List card |
| Milestones | Proximos hitos y estado | Timeline card |
| Team | Equipo del proyecto con roles | People card |
| Documents | Ultimos documentos adjuntos | List card |
| Changes | Ultimas modificaciones | Activity card |

### Navegacion Integrada

Desde el Project Cockpit se puede navegar directamente a:
- Project Builder (para editar)
- Financial Control (para analisis de costes)
- Monitor Projects (para vista de cartera)
- Issue Management (para gestionar problemas)

---

## 8. Apps de Analisis y Reporting

### 8.1 Project Cost Overview (F2344)

**Descripcion:** Analisis de costes con drill-down multidimensional.
**Tipo:** Analytical
**CDS View:** `C_ProjectCostOverview`

**Dimensiones de analisis:**
- Por proyecto
- Por WBS element
- Por elemento de coste
- Por periodo
- Por centro de coste de origen

### 8.2 Project Earned Value (F2347)

**Descripcion:** Analisis de valor ganado (EVM) con KPIs completos.
**Tipo:** Analytical
**CDS View:** `C_ProjectEarnedValue`

**KPIs calculados:**
```
PV  = Planned Value
EV  = Earned Value (basado en % avance)
AC  = Actual Cost
SV  = EV - PV (Schedule Variance)
CV  = EV - AC (Cost Variance)
SPI = EV / PV
CPI = EV / AC
EAC = BAC / CPI
ETC = EAC - AC
```

### 8.3 Project Budget Control (F4852)

**Descripcion:** Control de presupuesto con alertas de exceso.
**Tipo:** Analytical
**CDS View:** `C_ProjectBudgetAvailability`

**Alertas configurables:**
- Umbral de aviso (ej: 80%)
- Umbral de error (ej: 95%)
- Notificacion por email

### 8.4 WBS Cost Details (F2348)

**Descripcion:** Desglose de costes por WBS con documentos individuales.
**Tipo:** Analytical
**CDS View:** `I_WBSActualCostByPeriod`

**Drill-down:**
```
Proyecto → WBS → Elemento de coste → Periodo → Documento FI
```

---

## 9. Business Roles PS

### 9.1 Roles Standard

| Business Role | ID | Descripcion |
|---------------|-----|-------------|
| Project Manager | SAP_BR_PROJECT_MANAGER | Gestion completa del proyecto |
| Program Manager | SAP_BR_PROGRAM_MANAGER | Supervision multi-proyecto |
| Project Team Member | SAP_BR_PROJECT_TEAM_MEMBER | Confirmaciones y view only |
| Controlling Specialist | SAP_BR_CTRL_SPECST | Control financiero |
| Commercial Project Manager | SAP_BR_COMML_PROJ_MGR | CPM (proyectos comerciales) |
| Project Approver | SAP_BR_PROJECT_APPROVER | Solo aprobaciones |

### 9.2 Asignacion de Apps por Rol

| App | PM | Program Mgr | Team Member | Ctrl Specialist |
|-----|----|-------------|-------------|-----------------|
| Project Builder | X | X | View | |
| My Projects | X | X | X | |
| Monitor Projects | X | X | | X |
| Project Cockpit | X | X | | |
| Financial Control | X | | | X |
| Manage Plans | X | | | X |
| Approve Projects | | X | | |
| Budget Control | X | X | | X |
| Earned Value | X | X | | X |

### 9.3 Configuracion de Roles

**Transaccion:** `PFCG` — Mantenimiento de roles
**Fiori Launchpad Designer:** Configuracion de grupos y tiles
**Business Role App:** `/UI2/FLPD_CUST`

---

## 10. Configuracion y Activacion

### 10.1 Activacion de Business Functions

Para apps Fiori PS se requieren las siguientes business functions activas:

| Business Function | Descripcion |
|-------------------|-------------|
| `PS_CLI_1` | PS Classic Integration |
| `PS_FND_MNGT_1` | Foundations Management |
| `LOG_PS_CI_1` | CI para PS |
| `FIN_CO_PS_1` | CO-PS integration |

**Transaccion:** `SFW5` — Activar/desactivar business functions

### 10.2 Activacion de OData Services

**Transaccion:** `/IWFND/MAINT_SERVICE` — Activar servicios OData

**Servicios criticos PS:**
```
C_PROJECTBUILDER_SRV
C_PROJECTMONITOR_CDS
C_PROJECTFINANCIALCONTROL_SRV
C_PROJECTPLANMGMT_SRV
C_PROJECTBUDGETAVAIL_CDS
```

### 10.3 Launchpad Designer

**App:** Fiori Launchpad Designer (`/UI2/FLPD_CONF`)

**Proceso:**
```
1. Crear grupo de tiles "Project Management"
2. Agregar tiles de apps PS
3. Asignar al Catalogo del rol SAP_BR_PROJECT_MANAGER
4. Publicar cambios
5. Verificar en Launchpad de usuario
```

### 10.4 Gateway Trace para Debug

**Transaccion:** `/IWFND/ERROR_LOG` — Log de errores OData
**Transaccion:** `/IWFND/TRACES` — Trace de llamadas OData

---

## 11. OData Services y CDS Views

### Mapa de Servicios a CDS Views

| OData Service | CDS View Principal | Entidades |
|---------------|-------------------|-----------|
| `C_PROJECTBUILDER_SRV` | `I_ProjectBuilderTP` | Project, WBSElement, Activity |
| `C_PROJECTMONITOR_CDS` | `C_ProjectMonitor` | ProjectMonitor |
| `C_PROJECTFINANCIALCONTROL_SRV` | `C_ProjectFinancialControl` | FinCtrl, WBSCtrl, CostElmt |
| `C_PROJECTPLANMGMT_SRV` | `I_WBSPlannedCost` | PlannedCost, PeriodCost |
| `C_PROJECTBUDGETAVAIL_CDS` | `C_ProjectBudgetAvailability` | Budget, Available |
| `C_PROJECTEARNEDVALUE_CDS` | `C_ProjectEarnedValue` | EV, KPIs |

### Consumo desde ABAP (RAP)

Para extensions o custom apps:
```abap
" Lectura via RAP Managed BO
DATA(lo_project) = NEW lhc_project( ).
DATA(lt_projects) = lo_project->get_all_projects( ).

" O via Entity Manipulation Language (EML)
READ ENTITIES OF i_projectbuildertp
  ENTITY Project
  FIELDS ( ProjectID ProjectDescription )
  WITH VALUE #( ( ProjectInternalID = '00000042' ) )
  RESULT DATA(lt_projects).
```

---

## 12. Personalizacion y Extensibilidad

### 12.1 Custom Fields en Apps Fiori

**Proceso (Key User Tools):**
```
1. Business Customizing → Custom Fields and Logic
2. Seleccionar Business Context: Project Management
3. Crear campo personalizado (tipo de dato, label)
4. Activar en las apps Fiori deseadas
5. Publicar → campo aparece en app sin transportar ABAP
```

**Contextos disponibles PS:**
- `SAP_PS_PROJECT_HEADER` — Cabecera de proyecto
- `SAP_PS_WBS_ELEMENT` — WBS element
- `SAP_PS_NETWORK` — Red de proyecto
- `SAP_PS_ACTIVITY` — Actividad de red

### 12.2 Custom Logic (BAdIs via Key User)

```
Business Customizing → Custom Fields and Logic → Logic
  → Add Logic for: Project Saved, WBS Saved, Status Change
```

**Ejemplo:** Validar que todos los proyectos tipo INV tengan centro de beneficio:
```abap
" Implementacion BAdI via Key User
IF project-project_type = 'INV' AND project-profit_center IS INITIAL.
  APPEND VALUE #(
    field = 'ProfitCenter'
    message = 'El centro de beneficio es obligatorio para proyectos de inversion'
  ) TO messages.
ENDIF.
```

### 12.3 Adaptacion de UI (UI Adaptation)

Las apps Fiori permiten adaptacion sin codigo:
- Mostrar/ocultar campos
- Reordenar columnas
- Cambiar etiquetas (labels)
- Agregar filtros
- Guardar variantes

**Herramienta:** UI Adaptation (desde boton "Settings" en la app)
**Nivel:** Usuario / Clave / Administrador

### 12.4 Side-by-Side Extensions (BTP)

Para funcionalidades mas complejas fuera del standard:
```
SAP BTP → SAP Build Apps / CAP
  → Consume I_Project OData API
  → Extend con logica custom
  → Integrar via iFrame o Navigation en Launchpad
```

---

*Referencia: SAP S/4HANA 2023 | Fiori App Library | apps.sap.com/appdetail*
*Verificar disponibilidad de cada App ID en SAP Fiori Apps Reference Library segun release exacto*
