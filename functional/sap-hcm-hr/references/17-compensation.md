# Compensation Management

## Descripción General

Compensation Management (ECM — Enterprise Compensation Management) es el componente de SAP HCM que gestiona la estructura salarial, revisiones de compensación, incentivos y la comunicación de la compensación total al empleado. En S/4HANA 2023 funciona sobre la base de PA (infotipos 0008, 0014, 0015) y se complementa con la integración a SuccessFactors Compensation para escenarios cloud.

---

## Valoración de Puestos (Job Pricing)

### Concepto
La valoración de puestos establece el valor de mercado de cada posición mediante:
- **Encuestas salariales externas**: datos de mercado por sector/región
- **Job families**: agrupaciones de roles con responsabilidades similares
- **Job levels**: niveles de senioridad dentro de cada familia

### Integración con OM (Organizational Management)
- Posiciones (tipo S) vinculadas a Jobs (tipo C)
- El Job define la valoración; la posición hereda el grado salarial
- Infotipo 1005 (Planned Compensation) en posición: grado y nivel asignado

### Proceso de Valoración
```
1. Definir Job Family → 2. Asignar Jobs a familias → 3. Importar datos mercado
4. Calcular percentiles (P25, P50, P75, P90) → 5. Asignar pay grades
6. Comparar nómina actual vs. mercado (compa-ratio)
```

---

## Estructuras Salariales y Rangos (Pay Structures/Ranges)

### Tabla T710 — Pay Grades
```
T710: Pay Grade Types
T710A: Pay Grade Areas
T710B: Pay Grade Levels
T710C: Pay Scale Assignments
```

Ruta Customizing:
```
SPRO > Personnel Management > Enterprise Compensation Management
       > Basic Settings > Define Pay Grade Structure
```

### Áreas de Compensación (T71ADM01)
Las áreas de compensación son la unidad organizativa central de ECM:
- Agrupan empleados que siguen el mismo proceso de revisión
- Se asignan a ciclos de compensación independientes
- Permiten diferentes monedas y reglas por área

```abap
" Tabla de áreas de compensación
T71ADM01  " Compensation Areas
T71ADM02  " Compensation Review Items
T71ADM03  " Compensation Review Categories
```

### Tipos de Rangos Salariales
| Tipo | Descripción | Uso |
|------|-------------|-----|
| Broadband | Rangos amplios (±50% midpoint) | Estructuras planas |
| Graded | Rangos estrechos por nivel | Estructuras tradicionales |
| Step | Incrementos fijos por antigüedad | Sector público |
| Market-based | Actualización anual por encuesta | Alta competitividad |

### Componentes del Rango Salarial
- **Minimum**: salario mínimo del grado
- **Midpoint/Reference Point**: referencia de mercado (P50)
- **Maximum**: techo del grado
- **Compa-ratio**: salario actual / midpoint × 100

---

## Directrices y Presupuestos (Guidelines/Budgets)

### Presupuesto de Compensación
El presupuesto se define por área de compensación y ciclo de revisión:

```
Infotipo 0759: Compensation Process (encabezado del proceso por empleado)
Infotipo 0760: Compensation Eligibility Override
Infotipo 0761: LTI Granting (incentivos a largo plazo)
Infotipo 0762: LTI Exercising
Infotipo 0763: LTI Participant Data
```

### Directrices de Incremento (Guidelines)
Las directrices determinan el incremento recomendado según:
- Compa-ratio actual del empleado
- Valoración de desempeño (integración con Performance Management)
- Posición en el rango salarial (quartil)

```
Matriz guideline típica:
Performance\Compa-ratio  | <80%  | 80-95% | 95-110% | >110%
-------------------------|-------|--------|---------|------
Exceeds Expectations     | 8%    | 6%     | 4%      | 2%
Meets Expectations       | 5%    | 4%     | 2%      | 0%
Below Expectations       | 2%    | 1%     | 0%      | 0%
```

### Control de Presupuesto
- Presupuesto total asignado al gestor (por headcount o % masa salarial)
- Alerta si el gestor supera el presupuesto asignado
- Aprobación en cascada: gestor → HR Business Partner → Dirección

---

## Ajustes de Compensación (PECM_ADJ_SAL)

### Transacciones Principales ECM
| Transacción | Descripción |
|-------------|-------------|
| PECM_ADJ_SAL | Ajuste salarial masivo (batch) |
| PECM_START_PROCESS | Iniciar proceso de revisión |
| PECM_DISPLAY_BUDGET | Visualizar uso de presupuesto |
| PECM_GENE_COMP_STMT | Generar compensation statement |
| PECM_APPROVE | Aprobar ajustes salariales |
| PECM_CHANGE_BUD | Modificar presupuesto |

### Proceso de Revisión Salarial
```
1. PECM_START_PROCESS: crea registros IT0759 por empleado elegible
2. Gestor accede a Fiori/ESS: revisa recomendaciones y ajusta
3. HR BP valida y aprueba (workflow)
4. PECM_ADJ_SAL: aplica cambios masivamente a IT0008
5. Notificación al empleado (compensation statement)
```

### Actualización Infotipo 0008 (Basic Pay)
Al ejecutar PECM_ADJ_SAL:
- Crea nuevo registro IT0008 con fecha de vigencia del ciclo
- Actualiza nivel de grupo salarial y monto
- Genera registro de auditoría en IT0008 (historial completo)

---

## Incentivos a Largo Plazo (LTI — Long-Term Incentives)

### Tipos de LTI Soportados
| Tipo | Descripción | Infotipo |
|------|-------------|----------|
| Stock Options | Derecho a comprar acciones a precio fijo | IT0761/0762 |
| Restricted Stock Units (RSU) | Acciones condicionadas a permanencia | IT0761/0762 |
| Performance Shares | Acciones condicionadas a objetivos | IT0761/0762 |
| SAR (Stock Appreciation Rights) | Liquidación en efectivo | IT0761/0762 |

### Ciclo de Vida LTI
```
Granting (otorgamiento) → Vesting (consolidación) → Exercising (ejercicio) → Settlement
IT0761: datos de concesión
IT0762: datos de ejercicio
IT0763: datos del participante (banco, broker)
```

### Planes LTI en Customizing
```
SPRO > ECM > Long-Term Incentives
├── Define LTI Plan Types
├── Define Grant Rules
├── Define Vesting Schedules
└── Define Exercise Windows
```

---

## Compensation Statement (Estado de Compensación Total)

### Contenido del Statement
El compensation statement consolida toda la compensación del empleado:
- Salario base anual
- Variable/bonus del año anterior
- Beneficios cuantificados (seguro, pensión, coche, etc.)
- LTI en vigor
- Total Compensation (suma de todos los elementos)

### Generación con PECM_GENE_COMP_STMT
```abap
Programa: RHECM_GENERATE_COMP_STATEMENTS
Parámetros:
  - Compensation Area
  - Review Period
  - Output: PDF/SmartForms/Adobe Forms
  - Distribución: ESS, email, impresión
```

### Plantillas de Statement
- Basadas en SAP SmartForms o Adobe Interactive Forms
- Personalizables por área de compensación
- Multi-idioma según el idioma del empleado

---

## Integración con Encuestas Salariales

### Proveedores de Encuestas Soportados
- Mercer (archivo estándar importable)
- Willis Towers Watson (WTW)
- Hay Group
- Korn Ferry

### Proceso de Importación
```
1. Descargar datos de encuesta en formato CSV/Excel
2. Mapear campos externos a estructura SAP (job family, level, percentiles)
3. Transacción PECM_IMPORT_SURVEY_DATA (o programa custom)
4. Verificar datos importados vs. estructura de pay grades
5. Recalcular compa-ratios con nuevos datos de mercado
```

---

## Comparativa ECM vs. SuccessFactors Compensation

| Aspecto | SAP ECM (on-premise) | SuccessFactors Compensation |
|---------|----------------------|-----------------------------|
| Despliegue | On-premise / S/4HANA | Cloud (SaaS) |
| Interfaz gestor | Fiori/Web Dynpro | Compensation Planning Sheet (web moderno) |
| Workflow aprobación | SAP Workflow (complejo) | Routing configurable sin ABAP |
| Integración PM | Integración custom | Nativa con Performance & Goals |
| Calibración | No nativa | Calibración visual (caja 9 boxes) |
| Equity/LTI | Básico (IT0761-0763) | Avanzado con partner Equity Edge |
| Reporting | BW/Query | People Analytics integrado |
| Actualización datos mercado | Manual (import) | Conexión directa encuestas cloud |
| Mobile | Limitado | App nativa |
| Localización | +50 países | +70 países |

### Escenario Híbrido S/4HANA 2023
En implementaciones híbridas:
- Core HCM en S/4HANA on-premise (nómina, PA, OM)
- SuccessFactors Compensation para el proceso de revisión
- Integración via SAP Integration Suite: SF → S/4HANA actualiza IT0008
- Employees replicados con Employee Central Integration (ECI)

---

## Queries MCP para Compensation

### Verificar Datos de Compensación de Empleado
```
ReadInfotype: infotype=0008, pernr={pernr}
" Devuelve: pay scale group, pay scale level, basic pay amount, wage type

ReadInfotype: infotype=0759, pernr={pernr}
" Devuelve: compensation process, review item, eligibility, guideline

ReadInfotype: infotype=1005, object_type=S, object_id={position_id}
" Devuelve: pay grade, pay grade level asignado a posición
```

### Buscar Objetos de Compensación
```
SearchObject: type=PG (Pay Grade)
SearchObject: type=CA (Compensation Area)
GetObjectSource: object_type=PG, object_name={pay_grade_id}
```

### Tablas Clave de Compensation
```abap
T710    " Pay Grade Types
T710A   " Pay Grade Areas
T710B   " Pay Grade Levels (min/mid/max)
T71ADM01 " Compensation Areas
T71ADM02 " Review Items
T71V6   " Compensation Eligibility Rules
HRECM00_CRIT " Criteria for compensation eligibility
```

---

## Customizing Clave ECM

```
SPRO > Personnel Management > Enterprise Compensation Management
├── Basic Settings
│   ├── Define Compensation Areas
│   ├── Define Pay Grade Structure (T710/T710A/T710B)
│   └── Define Compensation Review Periods
├── Compensation Guidelines
│   ├── Define Guideline Criteria (Compa-Ratio, Performance)
│   └── Define Guideline Matrix
├── Budgeting
│   ├── Define Budget Types
│   └── Define Budget Units (by org unit/manager)
├── Long-Term Incentives
│   ├── Define LTI Plan Types
│   ├── Define Vesting Schedules
│   └── Define Exercise Rules
├── Total Compensation Statement
│   ├── Define Statement Components
│   └── Assign SmartForms/Adobe Forms
└── Workflow Integration
    ├── Define Approval Levels
    └── Assign Workflow Tasks (SWDD)
```
