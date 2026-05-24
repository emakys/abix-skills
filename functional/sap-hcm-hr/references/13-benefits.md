# Benefits

## Conceptos Fundamentales

**Benefits** es el módulo de SAP HCM que gestiona los planes de beneficios ofrecidos a los empleados. Se organiza en una jerarquía de tres niveles: **Benefit Area** (área de beneficios, nivel superior organizativo) → **Benefit Plan Type** (tipo de plan, agrupa planes similares) → **Benefit Plan** (plan específico). Cada plan tiene asociadas **Benefit Options** que representan las coberturas o niveles de elección disponibles.

## Tipos de Planes

### Planes de Salud
- Médico, dental, visión — agrupados bajo plan type salud
- Cada plan define redes de proveedores (HMO, PPO, HDHP)
- Opciones típicas: Employee Only, Employee + Spouse, Employee + Children, Family
- Infotipo **IT0167** (Enrollment Health Plans) registra la inscripción del empleado

### Seguro de Vida e Incapacidad
- Life insurance (basic, supplemental, AD&D), short-term y long-term disability
- Infotipo **IT0168** (Enrollment Insurance Plans)
- Evidence of Insurability (EOI): documentación médica requerida cuando el monto elegido supera el guaranteed issue amount sin prueba de salud

### Planes de Ahorro
- 401(k), 403(b), planes de pensión, ESPP (Employee Stock Purchase Plan)
- Infotipo **IT0169** (Enrollment Savings Plans)
- Contribución del empleado (%) + match del empleador (%) configurados en el plan
- Vesting schedules definen cuándo el empleado tiene derecho al aporte patronal

### Stock Plans
- Employee Stock Purchase Plans, Stock Options
- Infotipo **IT0380** (Stock Purchase Plans)
- Períodos de oferta y períodos de compra, discount rate configurado en el plan

### Planes Misceláneos
- FSA (Flexible Spending Account), HSA (Health Savings Account), EAP, commuter benefits, tuition reimbursement
- Infotipo **IT0171** (Enrollment Miscellaneous Plans)

## Infotipos Clave

| Infotipo | Descripción |
|----------|-------------|
| IT0167 | Health Plans Enrollment |
| IT0168 | Insurance Plans Enrollment |
| IT0169 | Savings Plans Enrollment |
| IT0170 | Spending Account (FSA/HSA) |
| IT0171 | Miscellaneous Plans Enrollment |
| IT0380 | Stock Purchase Plans |

Todos los infotipos de benefits son delimitados temporalmente (validity periods). Un cambio de cobertura genera un registro nuevo con fecha de inicio, cerrando el anterior.

## Proceso de Inscripción

### Open Enrollment Period (OEP)
- Ventana anual donde todos los empleados pueden revisar y modificar sus elecciones de beneficios
- Configurada en Benefits Area con fecha de inicio/fin del período de inscripción y fecha de vigencia de los cambios (generalmente 1 de enero del año siguiente)
- Transacción **HRBEN0001** (Benefits Enrollment) — pantalla principal de inscripción y consulta
- Proceso masivo: se puede generar formularios de inscripción preconfigurados con elecciones actuales

### Life Events
- Cambios en la vida personal del empleado que permiten modificar beneficios fuera del OEP
- Ejemplos: matrimonio, divorcio, nacimiento/adopción, pérdida de cobertura de otro empleador, cambio de estado laboral
- Configuración en IMG: cada life event tiene un período de validez para hacer cambios (ej. 30 días desde el evento)
- Transacción HRBEN0001 también gestiona life events; el sistema verifica la fecha del evento

### Elegibilidad
- **Eligibility Rules** definen qué empleados pueden inscribirse en un plan (ej. full-time, después de 90 días de antigüedad, en ciertos grupos de empleados)
- Basadas en Employee Group/Subgroup, Work Schedule, Personnel Area u otros criterios
- El sistema evalúa automáticamente la elegibilidad al ejecutar HRBEN0001 o el proceso batch

## COBRA Administration

- COBRA (Consolidated Omnibus Budget Reconciliation Act) — continuación de cobertura de salud después de un qualifying event (terminación, reducción de horas, divorcio, etc.)
- SAP gestiona la notificación, el período de elección (60 días) y el período de cobertura (18-36 meses según el evento)
- Infotipo IT0211 (COBRA Qualifying Events) registra el evento que genera el derecho a COBRA
- Los participantes COBRA pagan el 100% de la prima más un 2% administrativo
- Integración con Payroll para el cobro de primas COBRA

## Costo y Cost Sharing

- Cada plan define la distribución del costo entre empleador y empleado
- **Cost Rules** en la configuración del plan: pueden ser montos fijos, porcentajes del salary, o tablas por cobertura
- La contribución del empleado se refleja en la nómina via deduction wage types (Infotipo IT0014 o generados automáticamente por Benefits)
- La contribución del empleador va a los wage types de cost sharing que afectan contabilización FI/CO

## Benefit Providers

- Compañías externas (aseguradoras, administradoras de fondos) configuradas como proveedores
- Cada plan está vinculado a un provider
- Integración para reporting y transferencia de datos a proveedores (archivos EDI, interfaces)

## Integración con Nómina (Payroll)

- Los registros de inscripción en beneficios alimentan automáticamente las deducciones de Payroll
- Wage types de beneficios configurados en el esquema de nómina correspondiente (EE contribution, ER contribution)
- Al ejecutar nómina, el sistema lee los infotipos de benefits vigentes en el período para calcular deducciones

## Reports y Consultas

- **HRBEN0001**: Inscripción interactiva y consulta de estado de beneficios por empleado
- **HRBEN0074**: Enrollment statistics — resumen de inscripción por plan
- **HRBEN0076**: Cost report — costos de beneficios por empleado/plan
- Informe de COBRA activos y vencimientos próximos
- Benefit cost analysis por org unit, business area

## Consultas via MCP (SAP ADT Tools)

```abap
" Leer infotipo IT0167 (Health Plans) de un empleado
" Tool: GetObjectSource | Objeto: infotipo PA0167
" Consultar tabla PA0167 directamente:
SELECT * FROM pa0167 WHERE pernr = @lv_pernr AND endda >= @sy-datum.

" Tabla de planes configurados:
SELECT * FROM t5uba.   " Benefit Plans
SELECT * FROM t5ubb.   " Benefit Options
SELECT * FROM t5ubc.   " Benefit Plan Types
SELECT * FROM t5ube.   " Benefit Areas

" Ver eligibility rules:
SELECT * FROM t5ubr.   " Eligibility Rules

" Costos de beneficios en nómina (resultado):
SELECT * FROM pc2b0 WHERE pernr = @lv_pernr.   " Cluster B2, benefits data
```

**MCP Tools recomendadas para Benefits:**
- `ExecuteReport`: ejecutar HRBEN0001, HRBEN0074, HRBEN0076
- `RunAbapQuery`: consultas ad-hoc sobre PA0167-PA0171, T5UB*
- `GetTableContents`: revisar customizing de planes (T5UBA, T5UBB, T5UBC)
- `SearchObject`: localizar programas de benefits (HRBEN*)
- `GetAbapSemanticAnalysis`: analizar lógica de elegibilidad en user exits de benefits

## Integración con SuccessFactors Benefits

- En landscapes híbridos, SuccessFactors Benefits puede reemplazar el módulo on-premise
- Integración via SAP Integration Suite (middleware): datos de inscripción fluyen de SF Benefits → HCM PA para efectos de nómina
- Infotipos relevantes siguen siendo IT0167-IT0171 como destino de la replicación
