# Personnel Development (PD)

## Conceptos Fundamentales

**Personnel Development (PD)** es el módulo de SAP HCM que gestiona el desarrollo profesional de los empleados mediante la definición, medición y cierre de brechas de competencias. Se basa en un **catálogo de qualifications** compartido por toda la organización y opera integrado con Organizational Management (OM), Training & Event Management (PE) y Recruitment (PB). En S/4HANA 2023 coexiste con SuccessFactors Learning y Succession como alternativas cloud.

## Catálogo de Qualifications (OOQA)

- **OOQA** es la transacción para mantener el catálogo de qualifications (objeto tipo **Q** en el modelo de objetos HCM)
- Estructura jerárquica: **Qualification Groups** (QK, objeto tipo Q-group) → **Qualifications** (Q, objeto individual)
- Ejemplo de jerarquía:
  ```
  Tecnología SAP (grupo)
  ├── ABAP Development (qualification)
  ├── SAP SD Configuration (qualification)
  └── SAP FI/CO Functional (qualification)
  Idiomas (grupo)
  ├── Inglés (qualification)
  └── Alemán (qualification)
  ```
- Cada qualification tiene una **escala de valoración** (proficiency scale): ej. 1-Básico, 2-Intermedio, 3-Avanzado, 4-Experto
- Las escalas son configurables en IMG: **Personnel Development → Qualifications Catalog → Proficiency Scales**
- Fecha de vigencia: las qualifications tienen validity periods (una certificación puede expirar)

## Perfiles de Qualifications

### Perfil de la Posición (Requirements Profile)
- Cada posición (objeto S en OM) puede tener un **requirements profile**: lista de qualifications requeridas con el nivel mínimo necesario
- Se mantiene en la transacción **PPPM** o desde la posición en **PPOME**
- Relación: objeto S (posición) → relación A/B 028 → objetos Q (qualifications requeridas)
- También los Jobs (objeto C) pueden tener requirements, que se heredan a las posiciones asignadas a ese job

### Perfil de la Persona (Qualifications Profile)
- El perfil de qualifications del empleado se gestiona en **Infotipo IT0024** (Qualifications)
- Cada registro IT0024 contiene: qualification (Q), nivel alcanzado, fecha de adquisición, fecha de expiración
- Transacción: **PA30** (sub-type por qualification) o la vista integrada en **PPPM/LSO_PVENR**
- Un empleado puede tener múltiples registros IT0024, uno por cada qualification que posee

## Profile Matchup (Brecha de Competencias)

- La comparación entre el perfil de requisitos de la posición y el perfil de qualifications del empleado genera el **gap analysis**
- Transacción: **PPPM** → Profile Matchup → muestra qualifications requeridas vs. poseídas con indicador de brecha
- El sistema calcula automáticamente qué qualifications faltan o están por debajo del nivel requerido
- Las brechas identificadas alimentan los planes de desarrollo y las necesidades de formación

## Evaluación del Desempeño (Appraisals — PHAP)

### Conceptos del Módulo Appraisals
- SAP HCM incluye un sub-módulo de **Appraisals** (evaluación del desempeño) que se integra con PD
- **PHAP_ADMIN** — transacción principal de administración de appraisals (crear, ver, procesar evaluaciones)
- **PHAP_CREATE** — crear nueva appraisal (evaluación individual)
- **PHAP_SEARCH** — buscar appraisals existentes

### Estructura de una Appraisal
- **Appraisal Template**: plantilla que define la estructura de la evaluación (categorías, criterios, escalas)
- **Appraisal Category**: agrupa templates similares (ej. Annual Review, Mid-Year Review, 360° Feedback)
- **Appraisal**: instancia individual de evaluación para un empleado en un período determinado
- Los criterios de evaluación pueden ser competencias (qualifications del catálogo Q), objetivos (MBO) o criterios libres
- Escalas de valoración: numéricas, alfanuméricas o descriptivas, configurables por template

### Flujo del Proceso de Appraisal
1. **Preparation**: el manager prepara la evaluación para su equipo directo
2. **In Review**: etapa activa — el manager y/o empleado completan la evaluación
3. **In Review (Appraisee)**: si hay autoevaluación, el empleado completa su parte
4. **Approved**: supervisor o HR aprueba la evaluación completada
5. **Completed**: evaluación cerrada y archivada
6. Los resultados pueden actualizar automáticamente el IT0024 (qualifications) del empleado

### 360° Feedback
- Configuración en el appraisal template para incluir múltiples evaluadores (peers, reportes directos, clientes)
- Cada evaluador tiene acceso restringido a su parte de la evaluación
- Resultados consolidados con ponderación por tipo de evaluador

## Planificación de Carrera (Career Planning)

- SAP PD permite definir **Career Models**: trayectorias profesionales posibles dentro de la organización
- Objetos relacionados: Jobs (C), Positions (S) y las relaciones de progresión entre ellos
- La transacción **PPCP** (Career Planning) muestra para un empleado las posibles posiciones futuras según su perfil y el modelo de carrera
- El career plan se almacena como registros en el objeto persona (P) con relaciones hacia jobs/positions objetivo
- Criterios de elegibilidad para una posición futura: gap mínimo de qualifications, tiempo mínimo en rol actual

## Planificación de Sucesión (Succession Planning)

- Identifica candidatos potenciales para posiciones clave (key positions)
- Transacción **PPCP** también cubre succession: se marcan posiciones como "key positions" y se asignan candidatos con porcentaje de readiness
- **Succession Planning Report**: muestra qué posiciones tienen candidatos identificados vs. sin cobertura (succession risk)
- Integración con appraisals: empleados con ratings altos aparecen automáticamente como candidatos potenciales
- Los candidatos de sucesión se vinculan a la posición con la relación A/B 210 (potential successor) en el modelo de objetos

## Planes de Desarrollo (Development Plans)

- Un **Development Plan** es un conjunto de medidas de desarrollo asignadas a un empleado para cerrar brechas específicas
- Medidas de desarrollo: formación (cursos en Training & Event Management), mentoring, proyectos especiales, rotaciones, lecturas
- Transacción: **LSO_PVENR** o desde PPPM → Create Development Plan
- Cada medida tiene: objetivo (qualification a desarrollar), fecha objetivo, status (planned/in progress/completed)
- Al completar una medida de formación vinculada a una qualification, el IT0024 del empleado se actualiza automáticamente con el nuevo nivel

## Gestión de Competencias (Competency Management)

- En SAP HCM, las "competencias" se implementan usando el mismo catálogo de qualifications (objeto Q)
- La diferencia es conceptual: se crean grupos de qualifications específicos para competencias conductuales (liderazgo, comunicación, trabajo en equipo) diferenciados de competencias técnicas
- Las competencias conductuales se incluyen en los appraisal templates para evaluación durante el performance review
- SAP no tiene un módulo de "competencies" separado en la versión on-premise; todo usa el objeto Q

## IT0024 — Qualifications (Infotipo)

```
Infotipo 0024 — Qualifications
- PERNR: número de personal
- SUBTY: código de la qualification (objeto Q)
- BEGDA / ENDDA: validity period
- SEQNR: secuencia (para múltiples records del mismo subtipo)
- LANGT: nivel alcanzado (proficiency level, vinculado a la escala)
- ZDATE: fecha de adquisición o última actualización
- EXPDT: fecha de expiración (si la qualification caduca)
```

La tabla física es **PA0024**. Un empleado con 10 qualifications tiene 10 registros en PA0024.

## Integración con Training & Event Management (PE)

- Los cursos en Training (tipo D — Business Event) pueden estar vinculados a qualifications que desarrollan
- Al marcar la asistencia de un empleado como completada, si el curso tiene qualifications asignadas, el sistema propone actualizar el IT0024 del empleado
- Las necesidades de formación detectadas en el profile matchup generan automáticamente booking proposals en Training
- El catálogo de qualifications Q es completamente compartido entre PD y PE

## Integración con Recruitment (PB)

- El catálogo Q es también el utilizado en el infotipo IT4103 de los aspirantes (qualifications del candidato)
- El profile matchup vacante-candidato usa la misma lógica de comparación que el matchup posición-empleado
- Cuando un aspirante se contrata y se convierte en empleado, sus IT4103 pueden migrarse a IT0024

## Integración con Organizational Management (OM)

- Los requirements profiles de posiciones (relación A028) viven en el modelo de objetos OM
- Transacción **PPOME** permite ver y editar requirements profiles desde el organigrama
- Los profile matchups en PD leen directamente las relaciones de OM para las posiciones actuales del empleado (IT0001 → posición S → requirements en OM)

## Comparación con SuccessFactors Learning y Succession

| Aspecto | SAP HCM PD (on-premise) | SuccessFactors Learning | SuccessFactors Succession |
|---------|-------------------------|------------------------|--------------------------|
| Catálogo de competencias | Objeto Q (OOQA) | Competency Library | Competency Library |
| Evaluación desempeño | PHAP Appraisals | Performance & Goals | — |
| Planificación sucesión | PPCP básico | — | Succession Planning avanzado |
| Planes de desarrollo | Development Plans básico | Development Goals | Career Development Planning |
| Learning Management | Integrado con PE (básico) | LMS completo (video, SCORM, xAPI) | — |
| UI/UX | GUI + Fiori básico | Modern Web, mobile | Modern Web, mobile |
| Analytics | Reportes estándar | People Analytics avanzado | Org Chart + Analytics |
| Integración con nómina | Nativa | Via SAP Integration Suite | Via SAP Integration Suite |
| Recomendación nueva impl. | Solo si todo on-premise | Proyectos con LMS robusto | Proyectos con sucesión formal |

En landscapes híbridos: SuccessFactors gestiona performance/succession/learning; el IT0024 se sincroniza via Employee Central para mantener el perfil de qualifications actualizado en HCM on-premise (relevante para nómina y PD básico).

## Consultas via MCP (SAP ADT Tools)

```abap
" Qualifications de un empleado (IT0024):
SELECT * FROM pa0024
  WHERE pernr = @lv_pernr
  AND endda >= @sy-datum.

" Catálogo de qualifications (objetos Q en HRP1000):
SELECT * FROM hrp1000
  WHERE otype = 'Q'
  AND istat = '1'
  AND endda >= @sy-datum.

" Requirements de una posición (relación A028 en HRP1028):
SELECT * FROM hrp1028
  WHERE otype = 'S'
  AND sclas = 'Q'
  AND istat = '1'
  AND endda >= @sy-datum.

" Appraisals activas (tabla HRHAP_DOCUMENT):
SELECT * FROM hrhap_document
  WHERE status <> '5'   " 5 = completed/closed
  AND period_end >= @sy-datum.

" Succession planning — candidatos (relación A210):
SELECT * FROM hrp1210
  WHERE otype = 'S'
  AND sclas = 'P'
  AND endda >= @sy-datum.

" Planes de desarrollo:
SELECT * FROM hrdp_item WHERE pernr = @lv_pernr.

" Tablas de customizing PD:
SELECT * FROM t777s.   " Qualification Scales
SELECT * FROM t777p.   " Proficiency Texts
SELECT * FROM t77qs.   " Qualification Group Texts
```

**MCP Tools recomendadas para Personnel Development:**
- `GetTableContents`: revisar T777S, T777P (escalas de qualifications y textos de proficiencia)
- `ExecuteReport`: ejecutar PPPM (profile matchup), reports de gap analysis
- `RunAbapQuery`: análisis de brechas por org unit, top-N qualifications faltantes
- `SearchObject`: localizar programas RHHAP* (appraisals), RHPD* (PD reports), RHDEVELOPMENT*
- `GetObjectSource`: revisar lógica de user exits y BAdIs de Appraisals (HRHAP*)
- `GetAbapSemanticAnalysis`: analizar implementaciones de BAdI HRHAP00_PROCESS_* (workflow de appraisals)
- `GetIncludesList`: explorar includes de programas PHAP* para entender el flujo de appraisals
