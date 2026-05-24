# Novedades S/4HANA 2023 para PS — SAP Project System

## Indice
1. Commercial Project Management (CPM)
2. Project Control
3. Integracion con Universal Journal
4. Simplificaciones S/4HANA (tablas eliminadas)
5. APIs RESTful para PS
6. Nuevos Campos en Tablas PS
7. Cambios en Liquidacion
8. Mejoras Fiori
9. Embedded Analytics
10. Mejoras de Rendimiento
11. Novedades por Release (2020-2023)

---

## 1. Commercial Project Management (CPM)

### 1.1 Descripcion General

Commercial Project Management (CPM) es la extension funcional de PS para proyectos orientados a clientes (facturacion, margen, reconocimiento de ingresos). Disponible desde S/4HANA 1610, significativamente mejorado en 2020-2023.

**Business Function:** `FIN_PS_COMMERCIALPROJECT`
**Transaccion principal:** `CPMC01` — Crear Proyecto Comercial

### 1.2 Conceptos CPM

| Concepto | Descripcion |
|----------|-------------|
| Commercial Project | Proyecto con dimension de ventas (SD-PS integrado) |
| Project Task | Equivale al WBS Element en contexto CPM |
| Revenue Plan | Plan de ingresos por proyecto/tarea |
| Cost Plan | Plan de costes estructurado |
| Profit Analysis | P&L del proyecto en tiempo real |
| Revenue Recognition | Reconocimiento de ingresos (IFRS 15, POC, CC) |
| Commercial Project Item | Item de pedido de ventas vinculado a proyecto |

### 1.3 Flujo CPM

```
Oportunidad CRM
    ↓
Propuesta tecnica (WBS/Project)
    ↓
Pedido de ventas (SD) → vinculado a WBS elemento de facturacion
    ↓
Ejecucion del proyecto (costes reales en WBS)
    ↓
Hitos de facturacion completados
    ↓
Factura SD generada desde WBS
    ↓
Revenue Recognition (POC o Completed Contract)
    ↓
Reconocimiento en P&L
```

### 1.4 Metodos de Reconocimiento de Ingresos

| Metodo | Descripcion | Norma contable |
|--------|-------------|----------------|
| POC (Percentage of Completion) | Ingresos proporcionales al avance | IFRS 15, US GAAP |
| Completed Contract | Ingresos al completar el contrato | GAAP tradicional |
| Revenue Billing | Al momento de la factura SD | Proyectos simples |
| Milestone-based | Al completar hitos definidos | Contratos hito |

**Configuracion RA (Results Analysis):**
```
SPRO → Project System → Revenue → Results Analysis →
  Define Results Analysis Methods
Transaccion: OKG1 (Claves de analisis de resultados)
Transaccion: OKG4 (Cuentas de resultados)
```

### 1.5 Apps Fiori CPM

| App | ID | Descripcion |
|-----|----|-------------|
| Commercial Project Management | F3754 | Gestion proyectos comerciales |
| Project Revenue Overview | F4856 | Vista de ingresos |
| Revenue Recognition Run | F4855 | Ejecucion reconocimiento |
| Project Margin Analysis | F4857 | Analisis de margen |

---

## 2. Project Control (Nuevo en S/4HANA 2022/2023)

### 2.1 Descripcion

Project Control es el nuevo paradigma de control financiero de proyectos en S/4HANA. Reemplaza gradualmente los conceptos clasicos de presupuesto y ofrece control mas flexible.

**Transaccion:** `PRCTRL01` — Project Control Monitor

### 2.2 Capacidades de Project Control

| Capacidad | ECC/PS Clasico | Project Control S/4 |
|-----------|---------------|---------------------|
| Presupuesto | Por ejercicio o total | Flexible (periodo/fase) |
| Control | Por WBS individual | Por proyecto completo o segmento |
| Alertas | Batch (S_ALR reports) | Real-time en Fiori |
| Forecast | Manual | Automatico via ML (beta) |
| Revision | Anual | Cualquier momento |
| Aprobacion | Manual | Workflow integrado |

### 2.3 Project Financial Planning Profile

Nuevo perfil que integra:
- Tipo de plan (coste / revenue / mixto)
- Horizonte temporal (mensual, trimestral, anual)
- Metodo de forecast automatico
- Reglas de aprobacion del plan

---

## 3. Integracion con Universal Journal

### 3.1 ACDOCA como Fuente Unica

En S/4HANA, ACDOCA es la unica fuente de verdad para todos los movimientos de valor:

```
Antes (ECC):                    Ahora (S/4HANA):
  COSP (Plan primario)    →       ACDOCA (todos los movimientos)
  COSS (Plan secundario)  →       ACDOCA
  COEP (Documentos CO)    →       ACDOCA
  COBK (Cabecera doc CO)  →       ACDOCA
```

**Impacto en PS:**
- Consultas de costes PS deben hacerse contra ACDOCA
- RPSCO se mantiene como tabla de TOTALES (resumen)
- Reconciliacion FI-CO eliminada (misma tabla)

### 3.2 Nuevos Campos ACDOCA para PS

| Campo | Descripcion | Disponible desde |
|-------|-------------|------------------|
| PSPNR | WBS Element interno | S/4HANA 1511 |
| PS_POSID | WBS ID externo (denormalizado) | S/4HANA 2020 |
| PROJK | Tipo de proyecto | S/4HANA 2021 |
| PRCTR | Centro de beneficio (desde WBS) | S/4HANA 1809 |
| SEGMENT | Segmento (desde WBS) | S/4HANA 2021 |

### 3.3 Beneficios de la Integracion

1. **Reporting en tiempo real:** No hay proceso de reconciliacion nocturno
2. **Drill-down completo:** De resumen a documento individual en un click
3. **Multi-moneda:** Todas las monedas en una tabla (local, grupo, transaccion)
4. **Auditoria:** Trazabilidad completa de cada centimo

---

## 4. Simplificaciones S/4HANA

### 4.1 Tablas Eliminadas (PS-CO)

| Tabla ECC | Descripcion | Reemplazo S/4HANA |
|-----------|-------------|-------------------|
| COSP | Plan costes primarios | ACDOCA + COSS_BAK |
| COSS | Plan costes secundarios | ACDOCA |
| COEP | Documentos individuales CO | ACDOCA |
| COBK | Cabecera documentos CO | ACDOCA |
| COSB | Totales costes secundarios | ACDOCA |
| COFP | Plan detallado | ACDOCA |

**Tablas PS mantenidas:**
- PROJ, PRPS, PRHI — Sin cambios
- RPSCO — Mantenida (totales)
- BPGE, BPJA — Mantenidas (presupuesto)
- AFKO, AFVC, AFVV — Mantenidas
- JEST, TJ02T — Mantenidas
- RESB — Mantenida

### 4.2 Transacciones Deprecadas

| Transaccion ECC | Reemplazo S/4HANA |
|-----------------|-------------------|
| CJ20N (SAPGUI) | F2284 Fiori Project Builder |
| CJ40 (Cost Plan) | F2338 Manage Project Plans |
| CJ42 (Budget) | F4852 Budget Control Fiori |
| CN41 (classic) | CN41N + Fiori Monitor Projects |
| CJR2 (planning) | F2338 / PRCTRL01 |

**Nota:** Las transacciones SAPGUI siguen funcionando pero no reciben nuevas funcionalidades.

### 4.3 Cambios en Material Management

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Stock movimientos | MSEG | MATDOC |
| Valoracion | MARC/MBEW | Simplificado |
| Reservas de proyecto | RESB | RESB (sin cambios) |
| Stock especial Q | MB52/MB53 | MM60 (Fiori) |

---

## 5. APIs RESTful para PS

### 5.1 APIs Liberadas (Released)

SAP ha liberado las siguientes APIs RESTful para PS en S/4HANA 2022/2023:

| API | Descripcion | URL Base |
|-----|-------------|----------|
| Project (A2X) | CRUD de proyectos | `/API_PROJECT_ELEMENT_SRV` |
| WBS Element (A2X) | CRUD de WBS | `/API_WBS_ELEMENT_SRV` |
| Project Network | Redes de proyecto | `/API_NETWORK_SRV` |
| Project Budget | Gestion de presupuesto | `/API_PROJECT_BUDGET_SRV` |
| Project Version | Versiones de proyecto | `/API_PROJECT_VERSION_SRV` |

### 5.2 API_PROJECT_ELEMENT_SRV — Detalle

**Tipo:** OData V2 (migrando a V4)
**Autenticacion:** Basic Auth / OAuth 2.0
**Endpoint:** `https://{host}/sap/opu/odata/sap/API_PROJECT_ELEMENT_SRV`

**Entidades principales:**
```
A_EnterpriseProject          → Cabecera de proyecto
A_EnterpriseProjectElement   → WBS Elements
A_EnterpriseProjectJVA       → JV Assignments (Joint Venture)
A_EntProjEntitlement         → Autorizaciones proyecto
```

**Ejemplo GET proyectos:**
```http
GET /sap/opu/odata/sap/API_PROJECT_ELEMENT_SRV/A_EnterpriseProject
    ?$filter=ProjectType eq 'INV'
    &$select=Project,ProjectDescription,ProjectStartDate,ProjectEndDate
    &$format=json
Authorization: Basic {base64}
```

**Ejemplo CREATE proyecto:**
```http
POST /sap/opu/odata/sap/API_PROJECT_ELEMENT_SRV/A_EnterpriseProject
Content-Type: application/json
x-csrf-token: {token}

{
  "Project": "INV-2024-001",
  "ProjectDescription": "Ampliacion Planta",
  "CompanyCode": "1000",
  "Plant": "1000",
  "ProjectStartDate": "2024-01-01",
  "ProjectEndDate": "2024-12-31",
  "ProjectType": "INV",
  "ProjectProfile": "STD001"
}
```

### 5.3 BAPIs Disponibles (Compatibilidad)

Las BAPIs clasicas siguen funcionando:
```abap
BAPI_BUS2054_CREATE_MULTI   " Crear proyecto + WBS
BAPI_BUS2054_CHANGE_MULTI   " Modificar proyecto
BAPI_BUS2054_DELETE_MULTI   " Borrar WBS elements
BAPI_PS_INITIALIZATION      " Inicializar PS session
BAPI_NETWORK_CREATE         " Crear red de proyecto
BAPI_NETWORK_CHANGE         " Modificar red
BAPI_ACTIVITY_CREATE        " Crear actividades
```

---

## 6. Nuevos Campos en Tablas PS (S/4HANA 2020-2023)

### 6.1 Nuevos Campos en PRPS (WBS Element)

| Campo | Descripcion | Release |
|-------|-------------|---------|
| PROFIT_CTR | Centro de beneficio | S/4 1709 |
| SEGMENT | Segmento FI | S/4 2020 |
| FUNC_AREA | Area funcional | S/4 2021 |
| GRANT_NBR | Numero de beca (Grants Mgmt) | S/4 2021 |
| FUND | Fondo (Public Sector) | S/4 2021 |
| FKSTL | Centro de coste imputacion | S/4 2022 |
| WORK_ITEM | Enlace a gestion de tareas | S/4 2023 |

### 6.2 Nuevos Campos en PROJ (Proyecto)

| Campo | Descripcion | Release |
|-------|-------------|---------|
| CPM_PROJECT_UUID | UUID para CPM | S/4 1610 |
| EXTERNAL_ID | ID externo (integracion) | S/4 2020 |
| CATEGORY | Categoria de proyecto | S/4 2022 |
| PRIORITY_CODE | Codigo de prioridad | S/4 2022 |

### 6.3 Campo Nuevo AUFK (Red)

| Campo | Descripcion | Release |
|-------|-------------|---------|
| IDAT3 | Fecha adicional personalizable | S/4 2021 |
| NETWORK_UUID | UUID de red (CPM) | S/4 2021 |

---

## 7. Cambios en Liquidacion

### 7.1 Nuevo Motor de Liquidacion

S/4HANA 2022 introduce mejoras en el motor de liquidacion:
- Procesamiento paralelo (hasta 10x mas rapido)
- Mejor manejo de grandes volumenes (>10,000 objetos)
- Log detallado en Application Log (SLG0)
- Restart automatico en caso de error parcial

### 7.2 Liquidacion en Proyectos Complejos

**Orden recomendado de liquidacion:**
```
1. Ordenes de produccion vinculadas
2. Ordenes internas de proyecto
3. Actividades de red
4. WBS nivel mas bajo → nivel mas alto
5. Proyecto a AuC o activo final
```

**Transaccion batch:** `CJ8G` — Liquidacion masiva de proyectos
**Transaccion individual:** `CJ88` — Liquidar proyecto especifico

### 7.3 Liquidacion a Activo Fijo (AuC)

El flujo de liquidacion a activos se simplifica en S/4HANA:
```
WBS Element → AuC (Asset under Construction)
  Transaccion: CJ8G (liquidacion periodica)
  Cuenta: cta_AuC (activo en curso)

AuC → Activo Definitivo
  Transaccion: AIAB (asignar a activo final)
  Transaccion: AIBU (capitalizacion final)
```

---

## 8. Mejoras Fiori (Por Release)

### 8.1 S/4HANA 2020

- Project Builder Web (F2284) — Version inicial estable
- Monitor Projects — Nuevos filtros y columnas
- Project Cockpit — Overview Page disponible
- Custom Fields en proyectos

### 8.2 S/4HANA 2021

- Gantt Chart en Project Builder (beta)
- Budget Approval Workflow integrado
- Mobile support para Project Builder
- New Project Financial Control app

### 8.3 S/4HANA 2022

- Gantt Chart con dependencias (GA)
- Resource Management integrado
- Mass change de proyectos
- CPM mejorado (margen en tiempo real)
- Project Template Management

### 8.4 S/4HANA 2023

- AI-assisted project planning (experimental)
- Enhanced Earned Value Management
- Project Portfolio Optimizer
- Integration con SAP Collaboration Manager
- Improved API coverage (V4 OData)
- Multi-currency planning en Fiori
- Enhanced audit trail en Project Cockpit

---

## 9. Embedded Analytics

### 9.1 CDS Views Analiticas Nuevas (2020-2023)

| CDS View | Release | Descripcion |
|----------|---------|-------------|
| `C_ProjectPlanVsActual` | 1909 | Plan vs Real |
| `C_ProjectEarnedValue` | 2020 | KPIs Valor Ganado |
| `C_ProjectBudgetAvailability` | 2021 | Disponibilidad presupuesto |
| `C_ProjectMarginAnalysis` | 2022 | Margen CPM |
| `C_ProjectPortfolioKPI` | 2023 | KPIs portfolio |

### 9.2 Queries Analiticas Predefinidas

**Transaccion:** `RSRT` — Report Designer
**Servicio:** `2C_PS_PROJECT_COST_ANALYSIS_QRY`

```
Queries disponibles en S/4HANA 2023:
  2C_PS_PROJ_COST_ANALYSIS       → Costes proyecto
  2C_PS_PROJ_BUDGET_ANALYSIS     → Presupuesto
  2C_PS_PROJ_EARNED_VALUE        → Valor ganado
  2C_PS_PROJ_REVENUE_ANALYSIS    → Ingresos (CPM)
  2C_PS_PORTFOLIO_OVERVIEW       → Portfolio
```

### 9.3 Integracion SAP Analytics Cloud (SAC)

**Live Connection:**
- SAC se conecta directamente a CDS Views via CORS
- No necesita extraccion de datos
- Datos en tiempo real

**Pasos de integracion:**
```
1. Configurar Live Connection en SAC
2. Seleccionar CDS View como fuente
3. Crear modelo en SAC (dimensions + measures)
4. Construir dashboard
5. Publicar en Fiori Launchpad (iFrame o URL)
```

---

## 10. Mejoras de Rendimiento

### 10.1 HANA-Optimized Reports

Los reports clasicos PS han sido optimizados para HANA:
- `S_ALR_87013532` — 10-50x mas rapido
- `CN41N` — Renderizado progresivo
- `CJI3/CJI5` — Paginacion en servidor

### 10.2 Parallel Processing

**Liquidacion paralela:**
```
SPRO → Project System → Costs → Settlement →
  Define Parallel Processing Parameters
```
- Numero de procesos paralelos: 2-10 (segun sistema)
- Chunk size: numero de objetos por proceso
- Mode: background obligatorio para paralelo

### 10.3 Archivado de Proyectos

Para proyectos historicos cerrados:
```
Objeto de archivado: PS_PROJECT
Transaccion: SARA → Object PS_PROJECT
Prerequisitos:
  - Status CLSD (cerrado)
  - Sin saldos abiertos
  - Sin compromisos pendientes
  - Periodo de retencion cumplido
```

---

## 11. Novedades por Release

### S/4HANA 2020 FPS01
- Stable API_PROJECT_ELEMENT_SRV
- Custom Fields en WBS sin transportes ABAP
- Project Template Library
- Enhanced status management

### S/4HANA 2021
- Gantt Chart mejorado
- Integration con SAP Time and Attendance (CATS)
- New authorization concept for projects
- CPM: Revenue Recognition automatizado

### S/4HANA 2022
- Project Control panel (nuevo concepto)
- Machine Learning para forecast (beta)
- Enhanced Fiori apps (mass change)
- OData V4 para APIs principales

### S/4HANA 2023
- AI-assisted scheduling
- Portfolio management integrado
- Enhanced EVM con SAC
- New Business Event Handling para PS
- RESTful APIs completas
- ABAP Cloud compliant PS objects

---

*Referencia: SAP S/4HANA 2023 What's New Viewer | SAP Help Portal*
*Release Notes PS: help.sap.com → SAP S/4HANA → What's New → Project System*
