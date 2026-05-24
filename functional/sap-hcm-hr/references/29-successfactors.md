# SuccessFactors Integration

## Vision General

SAP SuccessFactors (SF) es la solucion cloud de SAP para HR. En muchas organizaciones coexiste con HCM on-premise en un modelo hibrido: SF gestiona talento y experiencia del empleado, mientras que S/4HANA HCM (o SAP Payroll embebido) gestiona la nomina y la administracion de personal core.

---

## Modulos de SuccessFactors

### Employee Central (EC)
El nucleo del sistema. Equivalente al PA + OM de HCM on-premise.
- Datos maestros del empleado: datos personales, empleo, asignacion organizacional
- Estructura organizacional: company, business unit, division, department, location
- Position Management: posiciones, job codes, job families
- Global Benefits (opcional, sustituye a Benefits de HCM)
- Time Off y Time Tracking (sustituye a Time Management de HCM)

### Recruiting (RCM)
- Job Requisitions, Job Postings, Candidate Pipeline
- Offer Management, Background Check integration
- Integra con EC para conversionar candidato → empleado

### Onboarding (ONB 2.0)
- Pre-day 1: tareas de compliance, documentos, equipo
- Day 1 experience: actividades de orientacion
- Integra con EC para activar el empleado en el sistema

### Learning Management System (LMS)
- Catalogo de cursos, matriculas, completaciones
- Compliance training tracking
- Integra con Performance & Goals para planes de desarrollo

### Performance & Goals (PMGM)
- Objetivo setting (Goals), Performance Reviews, Calibration
- Continuous performance (check-ins, badges, feedback)
- Integra con Succession y Compensation

### Compensation (CMP)
- Merit, Bonus y Long-Term Incentive planning
- Compensation statements, budgeting
- Integra con EC para actualizar salarios (write-back)

### Succession & Development
- Talent pools, Succession plans, Bench strength
- Career development plans
- Integra con Performance & Goals y Learning

### Workforce Analytics & Planning (WFA/WFP)
- KPIs predefinidos y dashboards (headcount, turnover, etc.)
- Story-based reporting
- Workforce Planning: modelado de escenarios de fuerza laboral

---

## Modelos de Integracion

### Modelo 1: SuccessFactors Full Suite (Cloud-only)
- Todo en SF, incluyendo Employee Central Payroll (ECP)
- ECP = Motor de nomina SAP corriendo en cloud (mismo motor que HCM on-prem)
- Sin HCM on-premise
- Integracion con S/4 FI/CO para posting de nomina

### Modelo 2: Side-by-Side Hibrido (el mas comun)
```
SuccessFactors EC        S/4HANA HCM on-premise
(Talent, Core HR)   ↔   (Payroll, Time Management)
     |                           |
     └── EC Payroll Replication → PA/OM data en HCM
                                  |
                                  └── Nomina → FI/CO (S/4HANA)
```
- EC es el sistema de registro para datos maestros de RRHH
- HCM on-prem recibe replicas de EC y ejecuta la nomina
- Posting de nomina va a S/4HANA FI/CO

### Modelo 3: HCM Core + SF Talent
- HCM on-prem es el sistema de registro (PA/OM/PY/TM)
- SF solo para modulos de talento (Performance, Learning, Succession)
- Integracion via Employee Data Replication (EDR): HCM → SF
- Mas comun en organizaciones con HCM maduro que agregan talento en cloud

---

## Employee Central Integration (ECI)

### Plataforma de Integracion
La integracion EC ↔ S/4HANA corre sobre:
- **SAP Integration Suite (CPI)**: Cloud Platform Integration — middleware cloud SAP
- **Integration Center**: herramienta nativa SF para integraciones simples (salida de datos)
- **Dell Boomi** / **MuleSoft**: terceros, menos comun en proyectos SAP puros

### Paquetes de Integracion Preconstruidos
SAP entrega iFlows (integration flows) en CPI para los casos mas comunes:
- `EC to HCM — Employee Replication`: persona → infotipo 0000, 0001, 0002, 0006, 0105
- `HCM to EC — Cost Center Replication`: cost centers CO → EC (para asignacion)
- `EC to HCM — Position to Job Replication`: posiciones SF → posiciones OM HCM

### Mapeo de datos EC ↔ PA Infotipos

| EC Entity / Field | HCM Infotipo | Campo HCM |
|---|---|---|
| Person — firstName | IT0002 | VORNA |
| Person — lastName | IT0002 | NACHN |
| Person — dateOfBirth | IT0002 | GBDAT |
| Person — gender | IT0002 | GESCH |
| Employment — hireDate | IT0000 | BEGDA (accion 01) |
| Employment — status | IT0000 | MASSN |
| Job Information — company | IT0001 | BUKRS |
| Job Information — businessUnit | IT0001 | GSBER (business area) |
| Job Information — department | IT0001 | ORGEH |
| Job Information — position | IT0001 | PLANS |
| Job Information — costCenter | IT0001 | KOSTL |
| Compensation — baseSalary | IT0008 | BET01 |
| Compensation — currency | IT0008 | WAERS |
| Address — homeAddress | IT0006 | STRAS, ORT01, PSTLZ |
| Communication — email | IT0105 (type 0010) | USRID_LONG |
| Communication — phone | IT0105 (type 0020) | USRID_LONG |

### Campos clave de matching (Employee Matching)
Para correlacionar un empleado de EC con uno de HCM:
- EC `externalCode` = HCM `PERNR` (personnel number) — configuracion mas comun
- EC `userId` puede usarse como alternativa
- Importante: definir la regla de matching en el iFlow (CPI) para evitar duplicados

---

## APIs de SuccessFactors

### OData V2 (SFAPI legacy)
- Endpoint: `https://{tenant}.successfactors.com/odata/v2/{entity}`
- Autenticacion: Basic Auth o OAuth 2.0 (SAML Bearer)
- Entidades principales: `PerPerson`, `PerPersonal`, `EmpEmployment`, `EmpJob`, `EmpCompensation`
- Query example: `GET /odata/v2/EmpJob?$filter=userId eq '12345'&$expand=jobInfoNav`

### OData V4 (nueva generacion)
- Disponible para modulos nuevos (Time Tracking, algunas entidades EC)
- Endpoint: `https://{tenant}.successfactors.com/odataV4/{service}`
- Mas estandar, soporta batch requests

### SFAPI (SOAP — legacy)
- Para integraciones antiguas, aun soportado
- Metodo: `query`, `upsert`, `insert`, `update`, `delete`
- Recomendacion: migrar a OData cuando sea posible

### Compound Employee API
- API especial para replicacion masiva de empleados
- Devuelve entidades compuestas (persona + empleo + compensacion en una llamada)
- Util para sincronizaciones batch HCM ↔ EC

---

## Diferencias Clave: SF Employee Central vs HCM On-Premise

| Aspecto | HCM On-Premise | SuccessFactors EC |
|---|---|---|
| Arquitectura | ABAP, on-premise o private cloud | Java/cloud, multi-tenant |
| Datos maestros | Infotipos (tablas PA, HRP) | Entities (HRIS Elements) |
| Cambios en el tiempo | Date-based infotypes (BEGDA/ENDDA) | Effective-dated records |
| Estructura org | OM (objetos O, S, P, C, T) | EC Org Chart (company/BU/dept/position) |
| Nomina | Motor PY integrado | ECP (cloud) o replicacion a HCM |
| Time Management | PT: work schedules, quotas, absences | EC Time Off / Time Tracking |
| Extensibilidad | ABAP (user exits, BAdIs) | Metadata Framework (MDF), Business Rules |
| Reportes | ABAP queries, Ad Hoc, BI | Story Reports, Workforce Analytics, SAC |
| Actualizaciones | Upgrade projects (cada 2-3 años) | Releases semestrales automaticos (H1/H2) |
| UX | Fiori (S/4HANA 2023) / GUI | Responsive Web, Mobile nativo |

---

## Consideraciones de Implementacion

### Gobierno de datos: EC como System of Record
Cuando EC es el sistema de registro:
- Cambios se originan en EC y replican a HCM
- NO modificar infotipos directamente en HCM (riesgo de sobrescritura en la siguiente replicacion)
- Configurar lock de infotipos en HCM para que solo el proceso de replicacion pueda escribir

### Nomina en modelo hibrido
- EC envia los datos de compensacion (salario base, tipo de salario) a HCM vía replicacion
- HCM calcula la nomina con esos datos
- El resultado de nomina (posting) va a S/4HANA FI/CO
- La sincronizacion debe ser lo suficientemente frecuente (tipicamente diaria o en tiempo real para cambios criticos)

### Gestion de errores en integracion CPI
- Monitoreo: SAP Integration Suite → Monitor → Message Processing
- Errores comunes: campo obligatorio vacio en EC, codigo de empresa no encontrado en HCM, fecha de vigencia conflictiva
- Recomendacion: implementar alertas en CPI y proceso de reenvio de mensajes fallidos

### Testing de integracion
- Test en sandbox: validar mapeo de campos antes de produccion
- Herramienta EC: Import & Export Data (carga masiva para tests)
- Herramienta CPI: Send Test Message en iFlow
- Validar en HCM: transaccion PA20 para verificar infotipos replicados

---

## Queries MCP para Contexto de Integracion

### Verificar infotipos replicados desde EC
```
ReadTable: PA0002, filtros por PERNR (validar datos personales replicados)
ReadTable: PA0001, filtros por PERNR (validar asignacion organizacional)
ReadTable: PA0008, filtros por PERNR (validar compensacion)
```

### Revisar log de replicacion (tablas HCM Integration)
```
SearchObject: tipo TABL, nombre HRSFI_EC (tablas de staging de replicacion)
ReadTable: HRSFI_A_EMPLO (employment data staging, si existe)
```

### Verificar estructura organizacional sincronizada
```
ReadTable: HRP1000, filtros por OTYPE='O' (org units replicadas de EC)
ReadTable: HRP1001, filtros por OTYPE='S', RSIGN='A', RELAT='003' (posiciones en org units)
```

### Consultar datos de compensacion post-replicacion
```
ReadTable: PA0008, filtros por PERNR y BEGDA (wage types y montos)
ReadTable: T510, filtros por TRFGR + TRFST (pay scale tabla, si aplica)
```
