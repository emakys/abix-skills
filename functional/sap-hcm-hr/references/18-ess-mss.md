# ESS/MSS — Employee & Manager Self-Service

## Descripción General

Employee Self-Service (ESS) y Manager Self-Service (MSS) son los portales de autoservicio de SAP HCM que permiten a empleados y gestores realizar tareas de RRHH directamente sin intermediación del departamento de personal. En S/4HANA 2023, ESS/MSS se implementan principalmente mediante apps Fiori, reemplazando progresivamente el portal Web Dynpro clásico (SAP NetWeaver Portal).

---

## Apps Fiori para ESS (Employee Self-Service)

### Ausencias y Tiempo

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| My Leave Request | F1844 | Solicitar, modificar y cancelar ausencias |
| My Time Sheet | F2857 | Registrar y editar horas de trabajo |
| My Absence Balances | F2069 | Consultar saldos de vacaciones y ausencias |
| My Work Schedule | F2218 | Ver calendario de turnos y horario asignado |
| My Overtime Requests | F3014 | Solicitar horas extra |

### Nómina y Retribución

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| My Pay Stubs | F1797 | Ver y descargar recibos de salario |
| My Compensation | F3097 | Resumen de compensación total |
| My Withholding Tax | F2068 | Gestión de retenciones fiscales |
| My Benefits | F2322 | Inscripción y consulta de beneficios |

### Datos Personales

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| My Personal Data | F1705 | Actualizar dirección, teléfono, datos bancarios |
| My Emergency Contacts | F2222 | Gestionar contactos de emergencia |
| My Documents | F2321 | Acceso a documentos personales |
| My Profile | F3105 | Foto, bio, habilidades (integración Talent) |

### Formación y Desarrollo

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| My Learning (LSO) | LSOCP | Acceder a catálogo e-learning |
| My Training | F2315 | Ver historial de formación asistida |
| My Qualifications | F2316 | Consultar perfil de cualificaciones |

---

## Apps Fiori para MSS (Manager Self-Service)

### Gestión de Ausencias de Equipo

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| Approve Leave Requests | F1845 | Aprobar/rechazar solicitudes de ausencia |
| My Team Calendar | F2213 | Vista de ausencias del equipo en calendario |
| Team Absences Overview | F2070 | Resumen de ausencias planificadas del equipo |
| Manage Substitutions | F2220 | Asignar sustituciones durante ausencias |

### Tiempo y Asistencia

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| Approve Timesheets | F2858 | Revisar y aprobar hojas de horas |
| Team Time Management | F3015 | Vista consolidada de tiempo del equipo |
| Approve Overtime | F3016 | Aprobar solicitudes de horas extra |

### Datos del Equipo

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| My Team | F2209 | Vista general de empleados directos |
| Employee Profile | F2210 | Perfil detallado del empleado |
| Manage Team Qualifications | F2317 | Gestión de perfiles de cualificación |
| Headcount Overview | F2211 | Resumen de plantilla por área |

### Compensación y Performance

| App Fiori | ID | Descripción |
|-----------|-----|-------------|
| Compensation Planning | ECM Fiori | Revisión salarial del equipo (ECM) |
| Performance Reviews | F2350 | Iniciar/gestionar evaluaciones de desempeño |
| Goal Setting | F2351 | Fijar y revisar objetivos del equipo |

---

## Servicios Backend

### Servicios OData para ESS/MSS
Los servicios OData son la capa de integración entre las apps Fiori y el backend S/4HANA:

| Servicio OData | Descripción | Usado por |
|----------------|-------------|-----------|
| HCM_LEAVE_REQ_SRV | Gestión de solicitudes de ausencia | F1844, F1845 |
| HCM_TIMESHEET_SRV | Hojas de tiempo del empleado | F2857, F2858 |
| HCM_ABSENCE_BAL_SRV | Saldos de ausencias | F2069 |
| HCM_PAYSLIP_SRV | Recibos de salario | F1797 |
| HCM_PERSONAL_DATA_SRV | Datos personales | F1705 |
| HCM_TEAM_CALENDAR_SRV | Calendario de equipo | F2213 |
| HCM_COMPENSATION_SRV | Compensación y revisión salarial | F3097, ECM Fiori |
| HCM_BENEFITS_SRV | Gestión de beneficios | F2322 |

### Activación de Servicios OData
```
Transacción: /IWFND/MAINT_SERVICE (Gateway Service Maintenance)
Alternativa S/4HANA: /IWFND/V4_ADMIN

Pasos:
1. Acceder a /IWFND/MAINT_SERVICE
2. "Add Service" → buscar por Technical Service Name
3. Asignar a sistema backend y RFC destination
4. Activar y verificar en Service Catalog
```

### BAPI y Módulos de Función Clave
```abap
" Ausencias
HR_ABSENCE_CREATE          " Crear ausencia
HR_ABSENCE_MODIFY          " Modificar ausencia
BAPI_EMPLOYEE_GETDATA      " Datos maestros empleado

" Tiempo
BAPI_TIMESHEET_ENTRY_SUBMIT  " Grabar horas en CATS
CATS_TIMESHEET_READ          " Leer hoja de horas

" Nómina
PYXX_READ_PAYROLL_RESULT    " Leer resultado de nómina
HR_PAYROLL_GET_PAY_STMNT    " Obtener recibo de salario

" Datos personales
BAPI_PERSDATA_CHANGE        " Modificar datos personales (IT0006, IT0009)
```

---

## Paquetes HRESS y HRMSS

### Paquete HRESS (Employee Self-Service)
Contiene los objetos ABAP que soportan el ESS clásico (Web Dynpro) y la capa de servicios para Fiori:

```
HRESS           " Paquete raíz ESS
HRESS_A_*       " Aplicaciones Web Dynpro ESS
HRESS_B_*       " Business Logic (BAPIs, FMs)
HRESS_C_*       " Customizing ESS
HRESS_OVP_*     " Overview Pages ESS
```

### Paquete HRMSS (Manager Self-Service)
Contiene los objetos ABAP para funcionalidades MSS:

```
HRMSS           " Paquete raíz MSS
HRMSS_A_*       " Aplicaciones Web Dynpro MSS
HRMSS_B_*       " Business Logic MSS
HRMSS_C_*       " Customizing MSS
HRMSS_OVP_*     " Overview Pages MSS
```

### Verificar Objetos de un Paquete (MCP)
```
SearchObject: type=DEVC, name=HRESS
GetObjectSource: object_type=DEVC, object_name=HRESS
```

---

## Configuración del Launchpad Fiori

### Estructura del Launchpad
```
Site (S/4HANA Fiori Launchpad)
  └── Catalog (ej. "SAP HCM - Employee")
        └── Group (ej. "My Employee Data")
              └── Tile (app individual)
```

### Transacciones de Configuración
| Transacción | Descripción |
|-------------|-------------|
| /UI2/FLP_SYS_CONF | Configuración del sistema Fiori Launchpad |
| /UI2/FLP | Acceder al Launchpad Fiori |
| /UI5/APP_INDEX_CALCULATE | Recalcular índice de apps SAPUI5 |
| SICF | Configurar servicios ICF para Fiori |
| /IWFND/MAINT_SERVICE | Gestionar servicios OData Gateway |

### Activar Nodos ICF para ESS/MSS
```
SICF > Hosts/Services > sap > bc > ui5_ui5
Activar: /sap/bc/ui5_ui5/sap/hcm_leave_req
         /sap/bc/ui5_ui5/sap/hcm_timesheet
         /sap/bc/ui5_ui5/sap/hcm_payslip
         ... (un nodo por app)
```

### Asignación de Apps al Catálogo
```
Transacción: Fiori Launchpad Designer (/UI2/FLPD_CONF)
1. Crear o seleccionar catálogo "Employee Self-Service"
2. Add tile → buscar por App ID (ej. F1844)
3. Configurar parámetros del tile (título, icono, intent)
4. Asignar catálogo a grupo
5. Asignar grupo al rol de autorización
```

---

## Roles de Autorización

### Roles Estándar ESS
| Rol | Descripción |
|-----|-------------|
| SAP_ESS_USER | Rol base para todos los empleados ESS |
| SAP_ESS_LEAVE | Gestión de ausencias (F1844) |
| SAP_ESS_TIMESHEET | Hojas de tiempo (F2857) |
| SAP_ESS_PAYSLIP | Acceso a nómina/recibos (F1797) |
| SAP_ESS_PERSONAL_DATA | Datos personales (F1705) |
| SAP_FIORI_LAUNCHPAD_USER | Acceso al Launchpad |

### Roles Estándar MSS
| Rol | Descripción |
|-----|-------------|
| SAP_MSS_USER | Rol base para todos los gestores MSS |
| SAP_MSS_LEAVE_APPROVAL | Aprobación de ausencias (F1845) |
| SAP_MSS_TIMESHEET_APPROVAL | Aprobación de hojas de horas (F2858) |
| SAP_MSS_TEAM_VIEWER | Vista de equipo (F2209, F2213) |
| SAP_MSS_COMPENSATION | Revisión salarial del equipo |

### Objeto de Autorización Clave
```abap
P_PERNR  " Acceso a datos del propio empleado (ESS)
PLOG     " Acceso a estructura organizativa (MSS: ver equipo)
P_ORGIN  " Infotipos PA con área/subárea de personal
PT_MGRPV " Aprobación de tiempo por el gestor
```

### Determinación del Gestor (Manager Detection)
En MSS, el sistema determina el equipo del gestor mediante:
1. **IT0001 (Org. Assignment)**: posición del gestor en OM
2. **Relación A/B 002 (Reports to)**: empleados que reportan a la posición del gestor
3. **Evaluación de la cadena jerárquica**: función HR_MANAGER_OF_PERNR

```abap
" Función para obtener equipo del gestor
CALL FUNCTION 'RH_GET_MANAGER_ASSIGNMENT'
  EXPORTING
    pernr = lv_manager_pernr
  TABLES
    emp_list = lt_employees.
```

---

## Configuración de Servicios OData

### Ruta de Customizing ESS/MSS
```
SPRO > Personnel Management
├── Employee Self-Service
│   ├── Service-Specific Settings
│   │   ├── Leave Request (HRESS_LEAVE)
│   │   ├── Working Time (HRESS_TIMESHEET)
│   │   └── Personal Data (HRESS_PERSONAL)
│   └── General Settings
│       ├── Define ESS Scenarios
│       └── Set Up Workflow for Approvals
└── Manager Self-Service
    ├── Define MSS Scenarios
    └── Configure Team Viewer
```

### Configuración del Workflow de Aprobaciones
- Basado en SAP Business Workflow (transacción SWDD)
- Tarea estándar: TS40007980 (Leave Request Approval)
- Agente de la tarea: gestor directo (HR_MANAGER_OF_PERNR)
- Escalado: si el gestor no aprueba en N días → gestor del gestor

---

## Comparativa ESS/MSS vs. SuccessFactors Employee Central

| Aspecto | SAP ESS/MSS (S/4HANA) | SuccessFactors Employee Central |
|---------|------------------------|--------------------------------|
| Despliegue | On-premise / privado | Cloud (SaaS multi-tenant) |
| Interfaz | Fiori (moderno) / Web Dynpro (legacy) | Fiori-like, totalmente web |
| Mobile | Fiori responsive (limitado) | App nativa iOS/Android |
| Ausencias | Completo (IT2001/IT2002) | Avanzado + acumulación automática |
| Tiempo | CATS/HR-TIM integrado | Time Off + Time Tracking Cloud |
| Nómina | Recibos desde HR-PY | Integración con SAP Payroll / externo |
| Datos personales | Infotipos clásicos | MDF (Metadata Framework) flexible |
| Workflow | SAP Workflow (complejo de configurar) | Workflow configurable sin código |
| Org Chart | Limitado | Org Chart visual interactivo |
| Personalización | ABAP/BAdI necesario | Studio de configuración no-code |
| Integración 3rd party | Vía RFC/OData custom | Integration Center + MDF events |
| Reporting | BW/SAP Query | People Analytics (Stories) |
| Accesibilidad | WCAG 2.0 parcial | WCAG 2.1 AA |

### Escenario Híbrido S/4HANA 2023 + SuccessFactors
```
SuccessFactors Employee Central (datos maestros, org, self-service)
        ↕ SAP Integration Suite (API iFlows)
S/4HANA HCM (nómina, tiempo, informes legales)
```
En este modelo:
- ESS de datos personales y org: SuccessFactors
- ESS de recibos de nómina: S/4HANA (generado en HR-PY)
- MSS de aprobación tiempo: configurable en cualquiera de los dos
- Empleados replicados vía Employee Central Payroll Integration

---

## Verificación y Diagnóstico

### Verificar Estado de Servicios ESS/MSS
```
/IWFND/ERROR_LOG    " Log de errores Gateway OData
/IWFND/TRACES       " Trazas de llamadas OData
/IWFND/MAINT_SERVICE > Test Service  " Probar servicio directamente
SM59                " Verificar conexiones RFC al backend
SMICM               " Estado del servidor ICM (HTTP/HTTPS)
```

### Problemas Comunes y Solución
| Problema | Causa Probable | Solución |
|----------|---------------|---------|
| App no aparece en Launchpad | Rol no asignado o tile no en catálogo | Verificar SU01 + Fiori Launchpad Designer |
| OData devuelve 403 | Objeto de autorización faltante | SU53 en el usuario afectado |
| Recibos no visibles (F1797) | Nómina no ejecutada o payslip config | Verificar HRPY_RGDIR + config HRESS_PAYSLIP |
| Workflow de aprobación no llega | Gestor no determinado | Verificar IT0001 + relación A002 en OM |
| App lenta / timeout | Caché de índice SAPUI5 desactualizado | Ejecutar /UI5/APP_INDEX_CALCULATE |

### Queries MCP para Diagnóstico ESS/MSS
```
" Verificar infotipos de un empleado (ESS backend)
ReadInfotype: infotype=0001, pernr={pernr}   " Org Assignment
ReadInfotype: infotype=0006, pernr={pernr}   " Addresses
ReadInfotype: infotype=0009, pernr={pernr}   " Bank Details

" Buscar servicios OData ESS activos
SearchObject: type=IWSV (IW Service), name=HCM_LEAVE*

" Verificar roles de autorización
SearchObject: type=AGR (Authorization Role), name=SAP_ESS*
```
