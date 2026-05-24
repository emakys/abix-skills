# Recruitment (PB)

## Conceptos Fundamentales

El módulo **Recruitment (PB)** de SAP HCM gestiona el proceso completo de selección de personal, desde la publicación de vacantes hasta la contratación del candidato. Trabaja de forma integrada con **Organizational Management (OM)** para vincular vacantes con posiciones y con **Personnel Administration (PA)** para la contratación final. En S/4HANA 2023, el módulo on-premise coexiste con SuccessFactors Recruiting como alternativa cloud.

## Gestión de Vacantes

- Una **Vacancy** en SAP Recruitment se origina en una posición (objeto S) de OM marcada como vacante
- La transacción **PB10** (Maintain Vacancies) permite crear y gestionar vacantes asociadas a posiciones
- Cada vacante tiene: número de puestos, fecha de inicio buscada, requisitos del puesto, estado (open/on hold/filled)
- Integración directa con OM: al crear la vacante desde la posición, hereda el perfil de requisitos (job, org unit, reports-to)
- Las vacantes pueden publicarse internamente (intranet/ESS) y/o externamente (job boards via interfaz)

## Master de Aspirantes (Applicant Master Data)

### Transacciones Principales
- **PB10** — Crear aspirante (nueva solicitud vinculada a una vacante)
- **PB20** — Modificar datos del aspirante
- **PB30** — Visualizar datos del aspirante

El aspirante tiene un número único de candidato y su información se almacena en infotipos del rango 4000-4999 (separados de los infotipos de empleados PA que van del 0000-0999).

## Infotipos de Aspirantes (IT4000-IT4999)

| Infotipo | Descripción |
|----------|-------------|
| IT4000 | Applicant Actions (registro de acciones del proceso) |
| IT4001 | Applications (solicitudes activas del candidato) |
| IT4002 | Vacancy Assignment (vacante a la que aplica) |
| IT4003 | Applicant Activities (actividades programadas: entrevista, test) |
| IT4004 | Applicant Status / Status of Applicant Activity |
| IT4005 | Applicant's Personnel Number (si ya fue empleado antes) |
| IT4100 | Address |
| IT4101 | Education / Training |
| IT4102 | Work Experience |
| IT4103 | Qualifications del candidato |
| IT4200 | Applicant (datos básicos: nombre, fecha nac., etc.) |
| IT4201 | Application (datos de la solicitud) |

Los infotipos de aspirantes siguen la misma lógica que los de empleados (sub-type, validity period, time constraint) pero pertenecen a la tabla PA4* en lugar de PA0*.

## Acciones del Aspirante (PBA0)

- **PBA0** es la transacción análoga a PA40 (acciones de empleados) pero para aspirantes
- Tipos de acción típicos en Recruitment:
  - **Received** (solicitud recibida) — estado inicial
  - **Invited** (invitado a entrevista) — cambia estado del aspirante
  - **In Process** (en proceso de selección)
  - **Rejected** (rechazado en alguna fase)
  - **Contract Offered** (oferta extendida)
  - **Hired** (contratado — trigger para crear empleado)
  - **Withdrawn** (candidato retiró su solicitud)

Cada acción genera automáticamente registros en IT4000 con la fecha y el tipo de acción.

## Estados del Aspirante

El estado controla en qué fase del proceso de selección se encuentra el candidato:

| Estado | Descripción |
|--------|-------------|
| 1 | Solicitud recibida |
| 2 | En proceso de preselección |
| 3 | Invitado a entrevista |
| 4 | Oferta en preparación |
| 5 | Oferta extendida |
| 6 | Contratado |
| 7 | Rechazado |
| 8 | Solicitud retirada |

Los estados son configurables en IMG: **Recruitment → Applicant → Applicant Status**.

## Proceso de Selección

### Flujo Estándar
1. Recepción de solicitud → creación del aspirante en PB10 con estado "Received"
2. Preselección (CV screening) → cambio de estado via PBA0
3. Planificación de actividades (IT4003): entrevista telefónica, entrevista presencial, assessment
4. Entrevistas → registro de resultados, calificación del candidato (IT4103 qualifications match)
5. Decisión de selección → cambio de estado a "Contract Offered" o "Rejected"
6. Aprobación y extensión de oferta
7. Aceptación → acción "Hired" → contratación como empleado

### Actividades de Selección (IT4003)
- Se programan fechas, responsables y resultados para cada actividad del proceso
- Tipos de actividad: entrevista, test psicotécnico, test técnico, examen médico, verificación de referencias
- Cada actividad tiene su propio status (planned, completed, cancelled)

## Matching: Vacante vs. Candidato

- **Profile Matchup**: comparación entre el perfil de requisitos de la posición (job requirements en OM) y las calificaciones del aspirante (IT4103)
- Se genera un porcentaje de match que ayuda al reclutador a priorizar candidatos
- Reporte **RPAPL030** o similar para comparación masiva de perfiles
- Integración con Personnel Development (PD): el catálogo de qualifications (OOQA) es compartido

## Contratación: Aspirante → Empleado

- La acción "Hire from Applicant" (acción de PA vinculada a Recruitment) transfiere datos del aspirante al master de empleado
- Datos que se trasladan automáticamente: nombre, dirección, educación, experiencia (si se mapean)
- Se crea el Infotipo **IT0001** (Org Assignment) vinculando al nuevo empleado con la posición antes vacante
- La posición en OM pasa automáticamente a estado "filled"
- El número de aspirante queda referenciado en **IT4005** del candidato y en el historial del empleado

## Reports de Recruitment

| Report / Transacción | Descripción |
|----------------------|-------------|
| PBA7 | Overview of Applicants |
| PBAM | Applicant Activity Report |
| PBAW | Applicant Statistics |
| S_PH0_48000450 | Recruitment Statistics |
| PBA0 | Applicant Actions |

- Estadísticas de tiempo promedio en cada fase (time-to-hire, time-to-fill)
- Fuentes de reclutamiento (source tracking en IT4001): referidos, portales, agencias, etc.
- Análisis de pipeline por vacante: cuántos candidatos en cada etapa

## Integración con Organizational Management (OM)

- Las posiciones (objeto S) se vinculan directamente con las vacantes de Recruitment
- Los requisitos del puesto (job requirements en el objeto C/Job) fluyen al perfil de la vacante
- Al contratar, la relación "holder" (A/B 008) entre empleado y posición se actualiza automáticamente
- Los organigramas en OM reflejan en tiempo real las posiciones vacantes vs. cubiertas

## Integración con Personnel Development (PD)

- El catálogo de qualifications (OOQA) es compartido entre Recruitment, PD y Training
- Las qualifications requeridas por la posición y las que tiene el aspirante (IT4103) usan los mismos objetos Q
- El profile matchup usa la misma lógica que la comparación persona-posición en PD

## Comparación con SuccessFactors Recruiting

| Aspecto | SAP HCM Recruitment (PB) | SuccessFactors Recruiting |
|---------|--------------------------|---------------------------|
| Plataforma | On-premise, ERP-nativo | Cloud SaaS |
| UI/UX | GUI tradicional, Fiori básico | Modern Web, mobile-first |
| Job posting externo | Via interfaz manual/básica | Integraciones con LinkedIn, Indeed, etc. |
| Candidate experience | Sin portal público nativo | Career site configurable |
| Flujo de aprobación | Workflow básico | Offer Approval con routing avanzado |
| Analytics | Reportes estándar | Embedded Analytics avanzado |
| Integración HCM | Nativa directa | Via SAP Integration Suite |
| AI/ML | No disponible | Candidate matching con IA |
| Recomendación | Sistemas legacy o volumen bajo | Proyectos nuevos, volumen alto |

En landscapes híbridos: SuccessFactors Recruiting gestiona el proceso hasta la oferta, luego replica al HCM on-premise via Employee Central o Integration Center para crear el empleado en PA.

## Consultas via MCP (SAP ADT Tools)

```abap
" Consultar aspirantes activos:
SELECT * FROM pa4001
  WHERE endda >= @sy-datum
  AND begda <= @sy-datum.

" Ver acciones de un aspirante:
SELECT * FROM pa4000 WHERE aplnr = @lv_aplnr ORDER BY begda DESCENDING.

" Vacantes abiertas (objeto S de OM marcadas como vacantes):
SELECT * FROM hrp1007
  WHERE otype = 'S'
  AND istat = '1'
  AND endda >= @sy-datum.    " IT 1007 = Vacancy

" Infotipo 4103 - Qualifications del aspirante:
SELECT * FROM pa4103 WHERE aplnr = @lv_aplnr AND endda >= @sy-datum.

" Tablas de customizing Recruitment:
SELECT * FROM t750a.   " Applicant Status
SELECT * FROM t750b.   " Applicant Action Types
SELECT * FROM t750c.   " Applicant Activity Types
SELECT * FROM t750x.   " Unsolicited Application Groups (vacancy categories)
```

**MCP Tools recomendadas para Recruitment:**
- `GetTableContents`: revisar T750*, T750A, T750B (customizing de estados y acciones)
- `ExecuteReport`: ejecutar PBA7, PBAM para overview de aspirantes
- `RunAbapQuery`: análisis de pipeline por vacante, time-to-hire
- `SearchObject`: localizar programas RPAP* (reports de recruitment)
- `GetObjectSource`: revisar lógica de user exits de Recruitment (HRRCF*)
- `GetAbapSemanticAnalysis`: analizar BAdIs de Recruitment (HRRCF00_APPL_*)
