# Fiori Apps HR

## Catalogo de Apps Fiori HCM — S/4HANA 2023

### Resumen de Apps Clave

| App ID | Nombre | Modulo | Tipo |
|---|---|---|---|
| F1844 | My Leave Request | ESS - Ausencias | Transaccional |
| F1845 | Approve Leave Request | MSS - Ausencias | Aprobacion |
| F1797 | My Pay Stubs | ESS - Nomina | Informativo |
| F2740 | My Timesheet | ESS - Tiempos | Transaccional |
| F0711 | Maintain Employee Master Data | HR Admin | Transaccional |
| F1569 | Display Employee Master Data | HR Admin | Informativo |
| F3041 | People Profile | ESS/MSS | Analitico |
| F1494 | Mass Changes | HR Admin | Masivo |
| F0396 | Manager Self-Service Overview | MSS | Overview |

---

## F1844 — My Leave Request (Solicitud de Ausencia)

### Descripcion
App ESS que permite al empleado crear, modificar y cancelar solicitudes de ausencia directamente desde Fiori Launchpad. Reemplaza el servicio WebDynpro HRESS_A_LEAVE_REQ.

### Servicio OData
- **Service**: `HCMFAB_LEAVE_REQUEST_SRV` (v1) / `API_MANAGE_HOLIDAY_CALENDAR` (complementario)
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCMFAB_LEAVE_REQUEST`
- **Entity sets**: LeaveRequestCollection, AbsenceTypeCollection, HolidayCalendarCollection

### Roles Requeridos
```
SAP_FLP_USER                        " Acceso basico Fiori Launchpad
SAP_HCM_ESS_LEAVE_REQUEST_DISP     " Visualizacion solicitudes
SAP_HCM_ESS_LEAVE_REQUEST_MNT      " Creacion y modificacion
HR_ESS_000_001                      " Rol base ESS (PFCG)
```

### Configuracion
1. **Infotipo de ausencia (IT2001)**: configurar tipos de ausencia en V_T554S con indicador "Solicitud via ESS"
2. **Cuotas (IT2006)**: habilitar deduccion automatica via esquema de cuotas
3. **Workflow**: configurar regla de decision en **BRF+** (aplicacion `HRWPC_RUL_LEAVE`) para determinar aprobador
4. **Notificaciones**: activar **Business Workplace** o correo via SOST para avisos de aprobacion/rechazo
5. **Calendario de festivos**: asignar via IT0001 (campo MOCAT → tabla T553E)
6. **Validaciones**: BAdI `HRESS_ENH_LEAVE_REQU` para reglas de negocio custom

### Parametros de Configuracion Clave
```abap
" Tabla de control ESS por tipo de ausencia
TABLE: T554S
FIELD: ESSBEZ = 'X'  " Habilitado para ESS
FIELD: ESSNEGQ = ' ' " No requiere cuota previa

" BRF+ para regla de aprobador
Application: HRWPC_RUL_LEAVE
Function:    HRWPC_FU_LEAVE_APPROVER
```

---

## F1845 — Approve Leave Request (Aprobacion de Ausencias)

### Descripcion
App MSS para que el mando directo (o aprobador delegado) revise y apruebe/rechace solicitudes de ausencia de su equipo. Incluye vista de equipo con indicador de disponibilidad.

### Servicio OData
- **Service**: `HCMFAB_LEAVE_APPROVAL_SRV`
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCMFAB_LEAVE_APPROVAL`
- **Entity sets**: LeaveRequestApprovalCollection, TeamCalendarCollection

### Roles Requeridos
```
SAP_HCM_MSS_LEAVE_APPROVAL_DISP    " Visualizacion bandeja aprobacion
SAP_HCM_MSS_LEAVE_APPROVAL_MNT     " Aprobacion / rechazo
HR_MSS_000_001                      " Rol base MSS
```

### Configuracion
1. **Relacion de reporte**: IT0001 campo MSTBR (superior jerarquico) o estructura OM (evaluacion A/B 002)
2. **Delegacion**: configurar via transaccion **HRMSS_VC_DELEG** (tabla T77WWW_DELEG)
3. **Vista de equipo**: requiere estructura OM activa con relaciones de puestos (HRP1001, relacion 002)
4. **BRF+**: misma aplicacion que F1844 (HRWPC_RUL_LEAVE) — aprobador resuelto en server side
5. **Sustituto**: configurar via IT0105 subtipo 0030 o regla BRF+ de sustitutos

### Integracion con Workflow HR
```abap
" Task de aprobacion en workflow HR
OBJECT TYPE: TSKG
TASK:        TS17900078  " Approve/Reject Leave Request
METHOD:      DECIDE

" Contenedor de workflow
CONTAINER ELEMENT: _WI_Requester  " Empleado solicitante
CONTAINER ELEMENT: _WI_Object     " LeaveRequest ID
```

---

## F1797 — My Pay Stubs (Mis Recibos de Sueldo)

### Descripcion
App ESS informativa que permite al empleado visualizar y descargar sus recibos de sueldo historicos en formato PDF. Reemplaza el acceso via portal WebDynpro HRESS_A_PAYSLIP.

### Servicio OData
- **Service**: `HCMFAB_PAYSLIP_SRV`
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCMFAB_PAYSLIP`
- **Entity sets**: PayslipCollection, PayPeriodCollection

### Roles Requeridos
```
SAP_HCM_ESS_PAYSLIP_DISP           " Visualizacion recibos
HR_ESS_000_001                      " Rol base ESS
```

### Configuracion
1. **Formulario de recibo (PE51)**: crear/adaptar formulario para clase de nomina y pais. Nombre del formulario referenciado en tabla **T596F**
2. **Generacion de PDF**: activar Adobe Document Services (ADS) o alternativa BSP
3. **Tabla T596F**: configurar forma de recibo por pais/area de nomina
```
T596F: LGART = ' ', MOLGA = '99', FCODE = 'ZS01' (nombre del formulario PE51)
```
4. **Archivado**: para historico, configurar Content Server o integrar con OpenText/ArchiveLink
5. **Autorizacion de datos**: objeto **P_ORGIN** con infotipo 0000 minimo (verificar que el empleado solo vea sus propios datos)

### Consideraciones Tecnicas
- El PDF se genera en tiempo real via el mismo motor que PC00_M99_REMUNERATION
- Para archivado largo plazo: transaccion **OAAD** (ArchiveLink) vinculada a PERNR
- Rendimiento: activar cache de resultados de nomina (tabla PCL2 clúster RG)

---

## F2740 — My Timesheet (Mi Hoja de Tiempos)

### Descripcion
App ESS para registro de tiempos de trabajo (CATS - Cross Application Time Sheet). Reemplaza las transacciones CAT2/CATW de SAP GUI. Permite imputar horas a centros de costo, ordenes, proyectos PS o redes.

### Servicio OData
- **Service**: `CATS_TIMESHEET_SRV` / `MANAGE_MY_TIMESHEET_SRV`
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `CATS_TIMESHEET`
- **Entity sets**: TimesheetEntryCollection, ReceiverObjectCollection, WorkItemCollection

### Roles Requeridos
```
SAP_CATS_ESS_USER                   " Usuario CATS basico
SAP_HCM_ESS_TIMESHEET_MNT          " Mantenimiento hoja de tiempos
HR_ESS_000_001                      " Rol base ESS
```

### Configuracion
1. **Perfil CATS** (transaccion CAC1/tabla T_CATS_PROFILE): define campos visibles, objetos de imputacion, aprobacion requerida
2. **Tipo de actividad CO**: tabla KA01/KA06 — necesario para imputacion a centros de costo
3. **Integracion PS/PM**: activar en perfil CATS campos de orden/proyecto/actividad de red
4. **Aprobacion**: workflow CATS (tarea TS00008267) o aprobacion directa del mando
5. **Transferencia a HR**: reporte **RCATSHR** — transfiere CATS a infotipos IT2001/IT2002/IT2010
6. **Transferencia a CO**: reporte **RCATP00** — transfiere imputaciones a ordenes/centros de costo

### Configuracion de Perfil CATS
```
Transaccion: CAC1
PROFILE: ZCATS_STANDARD
  - Data entry profile: Weekly view
  - Approval required: Yes
  - Receiver types: Cost Center (KST), Internal Order (ORD), WBS Element (PRO)
  - Work item type: Activity type (LAT)
  - Transfer to HR: X (activo)
  - HR: Schema tiempo (tabla T555A)
```

---

## F0711 — Maintain Employee Master Data (Mantenimiento Datos Maestros)

### Descripcion
App de administracion HR para mantenimiento completo de datos maestros de empleados (equivalente a PA30 en Fiori). Soporta creacion, modificacion y delimitacion de infotipos.

### Servicio OData
- **Service**: `HCM_EMPLOYEE_MASTERDATA_SRV`
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCM_EMPLOYEE_MASTERDATA`
- **Entity sets**: EmployeeCollection, InfotypeDataCollection

### Roles Requeridos
```
SAP_HCM_HR_ADMIN_EMPL_MNT          " Mantenimiento datos maestros
SAP_HCM_HR_ADMIN_EMPL_DISP         " Solo visualizacion
HR_PA_INFTY_MAINT                   " Mantenimiento infotipos (PFCG)
```
Complementar con objetos de autorizacion:
- **P_ORGIN**: INFTY, SUBTY, AUTHC (tipo acceso: R/S/M/E)
- **P_PERNR**: acceso por numero de empleado especifico

### Configuracion
1. **Pantallas de infotipo**: las mismas PS definidas en V_T588M (sin cambio vs. PA30)
2. **Verificaciones de plausibilidad**: BAdI `HRPAD00_INFOTYPE` (equivalente a MENSTL00)
3. **Customer-specific infotypes (IT9xxx)**: compatibles si siguen estandar de tablas PA9xxx
4. **Flujo de proceso (HR Actions)**: tabla T529A y T529Q — acciones de personal disponibles en app
5. **Campos custom**: Screen Enhancement via AET (Application Extension Tool) o Enhancement Workbench

### Limitaciones vs. PA30
- No soporta todos los infotipos en S/4HANA 2023 (los menos frecuentes aun requieren PA30)
- Infotipos de pais (ITnnnn > IT0999) — soporte variable por pais
- Verificar lista de infotipos soportados en SAP Note **2477920**

---

## F1569 — Display Employee Master Data (Visualizacion Datos Maestros)

### Descripcion
Version de solo visualizacion de F0711. Usada para usuarios de RRHH con acceso de consulta, o para el propio empleado visualizando sus datos (en combinacion con rol ESS).

### Servicio OData
- **Service**: `HCM_EMPLOYEE_MASTERDATA_SRV` (mismo que F0711, diferente rol)
- El servicio distingue operaciones de lectura (GET) vs. escritura (POST/PATCH) via autorizacion

### Roles Requeridos
```
SAP_HCM_HR_ADMIN_EMPL_DISP         " Solo visualizacion
P_ORGIN: AUTHC = 'R'               " Read only en objeto de autorizacion
```

### Caso de Uso ESS
Empleados pueden ver sus propios datos (IT0001, IT0006, IT0009) via F1569 con restriccion `P_PERNR` a su propio PERNR:
```
Objeto: P_PERNR
Field PSIGN: I (incluir)
Field PERNR: <propio PERNR> — dinamico via variable de usuario SY-UNAME→PERNR
```

---

## F3041 — People Profile (Perfil de Empleado)

### Descripcion
App unificada que presenta el perfil completo de un empleado: datos personales, cargo, dependientes, habilidades, ausencias, objetivos de desempeno. Combina datos PA + OM + PD + SuccessFactors (si integrado).

### Servicio OData
- **Service**: `HCM_PEOPLE_PROFILE_SRV` (multiple entity sets)
- **Servicios adicionales**: `HCM_ORG_CHART_SRV` (organigrama embebido)
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCM_PEOPLE_PROFILE`

### Roles Requeridos
```
SAP_HCM_PEOPLE_PROFILE_DISP        " Visualizacion perfil
SAP_HCM_ORG_CHART_DISP             " Organigrama (complementario)
```

### Configuracion
1. **Secciones visibles**: customizar via tabla de configuracion `T77FIORI_PPRO_CFG` (que secciones aparecen)
2. **Integracion SuccessFactors**: activar via middleware CPI + configuracion SSO entre S/4 y SF
3. **Foto de empleado**: IT0105 subtipo 0010 (URL o binario en ArchiveLink) o desde SF
4. **Organigrama**: requiere relaciones OM activas y evaluacion de estructura en PPOME
5. **Skills/Qualifications**: datos de modulo PD (IT0024 Calificaciones) + perfil de requisitos (QK)

### Analitica Embebida en F3041
- KPIs de headcount del departamento en tiempo real
- Historial de ausencias del empleado
- Objetivos de desempeno (si SF Performance integrado)
- Formaciones completadas (si SF Learning o LSO integrado)

---

## F1494 — Mass Changes (Cambios Masivos de Empleados)

### Descripcion
App de administracion para aplicar cambios de datos maestros a multiples empleados simultaneamente. Reemplaza la transaccion **PA71** de SAP GUI para operaciones masivas frecuentes (cambio de area de nomina, grupo de empleados, CC, etc.).

### Servicio OData
- **Service**: `HCM_MASS_CHANGE_SRV`
- **Activacion**: `/IWFND/MAINT_SERVICE` → buscar `HCM_MASS_CHANGE`

### Roles Requeridos
```
SAP_HCM_HR_ADMIN_MASS_CHANGE_MNT   " Ejecucion de cambios masivos
SAP_HCM_HR_ADMIN_MASS_CHANGE_DISP  " Solo simulacion
```
Adicionar autorizaciones P_ORGIN con AUTHC = 'M' (mass change) para los infotipos afectados.

### Configuracion
1. **Infotipos habilitados para cambio masivo**: tabla **T529U** — activar flag de cambio masivo por infotipo
2. **Plantillas de cambio**: pre-definir combinaciones de campos frecuentes para usuarios HR
3. **Log de cambios**: tabla **PA_CHANGEDOC** (Change Documents) — auditoria automatica
4. **Simulacion previa**: siempre ejecutar en modo simulacion antes de grabar (flag SIM en batch)
5. **BAdI de validacion**: `HRPAD00_INFOTYPE` actua tambien en cambios masivos

### Proceso Tipico de Cambio Masivo
```
1. Seleccionar empleados (por area de personal, org unit, grupo, etc.)
2. Seleccionar infotipo y campo a modificar (ej: IT0001-KOSTL Centro de Costo)
3. Definir nuevo valor y fecha de vigencia
4. Ejecutar simulacion → revisar log de errores
5. Ejecutar en productivo → verificar en PA20
```

---

## F0396 — Manager Self-Service Overview (Resumen MSS)

### Descripcion
App central del Manager Self-Service: tablero de mando para mandos con acceso rapido a aprobaciones pendientes, datos del equipo, ausencias planificadas, KPIs de headcount y accesos directos a otras apps MSS.

### Servicio OData
- **Service**: `HCMFAB_MSS_OVERVIEW_SRV` (agregador de multiples servicios)
- **Servicios subyacentes**: HCMFAB_LEAVE_APPROVAL_SRV, HCM_PEOPLE_PROFILE_SRV, HCM_ORG_CHART_SRV

### Roles Requeridos
```
SAP_HCM_MSS_OVERVIEW_DISP          " Acceso al overview MSS
HR_MSS_000_001                      " Rol base MSS
SAP_HCM_MSS_TEAMCALENDAR_DISP      " Calendario del equipo (complementario)
```

### Configuracion
1. **Delimitacion de equipo**: basado en estructura OM (relacion A/B 002 entre S-S o S-P) o campo MSTBR de IT0001
2. **Tile de aprobaciones pendientes**: conectado a bandeja de entrada de Business Workplace (SBWP) filtrada por tipo de tarea HR
3. **Calendario de equipo**: requiere IT2001 (ausencias) + estructura OM activa para visualizar equipo
4. **KPIs analiticos**: activar Embedded Analytics HR (VDM CDS views) para headcount en tiempo real
5. **Navegacion a otras apps MSS**: configurar grupos de tiles en Fiori Launchpad (transaccion /UI2/FLPD_CONF)
6. **Delegacion de acceso MSS**: tabla T77WWW_DELEG + transaccion HRMSS_VC_DELEG

### Tiles del Launchpad MSS Recomendados
```
Grupo: "Mi Equipo"
  - F3041 People Profile
  - F1845 Approve Leave Request
  - F0396 MSS Overview (home)
  - F2740 My Timesheet (ver tiempos equipo)

Grupo: "Aprobaciones"
  - F1845 Leave Requests
  - HCMFAB_TIMESHEET_APPROVAL (aprobacion tiempos)
  - Workflow inbox general (/UI2/FLP task center)
```

---

## Guia de Activacion General — Fiori HR en S/4HANA 2023

### Pasos de Activacion (orden recomendado)
```
1. SICF          → Activar nodos ICF para Fiori (/sap/bc/ui5_ui5, /sap/opu/odata)
2. /IWFND/MAINT_SERVICE → Activar OData services HR
3. SPRO → HR → ESS → Configuracion general ESS/MSS
4. /UI2/FLPD_CONF → Configurar Fiori Launchpad
5. PFCG          → Asignar roles Fiori a usuarios
6. SU01/SU10     → Asignar roles a usuarios (mass)
7. /IWFND/ERROR_LOG → Monitorear errores OData durante pruebas
```

### Verificacion de Conectividad OData
```
" URL de prueba (browser o Postman)
https://<server>:<port>/sap/opu/odata/sap/HCMFAB_LEAVE_REQUEST_SRV/$metadata

" Respuesta esperada: XML con EntityTypes y AssociationSets
" Error 401: problema de autorizacion → revisar rol SAP_HCM_ESS_*
" Error 404: servicio no activado → /IWFND/MAINT_SERVICE
```

### Troubleshooting Frecuente
| Problema | Causa Probable | Solucion |
|---|---|---|
| App no aparece en Launchpad | Catalogo/Grupo no asignado al rol | PFCG → Fiori tab → agregar catalogo |
| Error 403 al ejecutar | P_ORGIN sin campo correcto | Verificar AUTHC y INFTY en rol |
| Workflow sin aprobador | BRF+ mal configurado | Transaccion BRF+, aplicacion HRWPC_RUL_LEAVE |
| PDF recibo no genera | ADS no configurado | SPAD → verificar Adobe Document Services |
| Organigrama no muestra equipo | Relaciones OM faltantes | PPOME → verificar relaciones A002 |
| CATS no transfiere a HR | Perfil sin flag de transferencia | CAC1 → perfil → tab Transferencia |
