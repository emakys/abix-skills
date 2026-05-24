# KPIs y Analytics HR

## Vision General

Los KPIs de RRHH permiten medir la efectividad de la gestion de personas y el impacto financiero de la fuerza laboral. En S/4HANA 2023, los datos maestros y transaccionales de HCM alimentan tanto los reportes estandar como las herramientas de analytics embebido (Embedded Analytics, SAC, CDS views).

---

## KPIs Clave de RRHH

### 1. Headcount (Plantilla)

**Definicion:** Numero de empleados activos en un momento dado.

**Formula:**
```
Headcount = COUNT(PERNR) WHERE status = 'Activo' AND fecha BETWEEN begda AND endda
```

**Variantes:**
- Headcount al inicio del periodo
- Headcount al final del periodo
- Headcount promedio del periodo = (inicio + fin) / 2

**Fuente de datos HCM:**
- Tabla `PA0000` (Acciones): `STAT2 = '3'` (activo)
- Filtrar por `BEGDA <= fecha_ref <= ENDDA`
- Tabla `T529A` — tipos de accion (para clasificar entradas/salidas)

**Benchmarks:** Varia por industria y tamano de empresa. Util como denominador para otros KPIs.

---

### 2. FTE (Full-Time Equivalent)

**Definicion:** Conversion de empleados a tiempo completo equivalente. Un empleado part-time al 50% = 0.5 FTE.

**Formula:**
```
FTE = SUM(porcentaje_dedicacion / 100) para todos los empleados activos
FTE = SUM(IT0007-ZTEILE / IT0007-ZTEILN)  -- horas contratadas / horas jornada completa
```

**Fuente de datos HCM:**
- Tabla `PA0007` (Planned Working Time): campos `ZTEILE` (horas contratadas), `ZTEILN` (horas jornada completa)
- Alternativamente: `TEILK` (porcentaje de jornada) en `PA0008`

**Query MCP:**
```
ReadTable: PA0007, campos PERNR, BEGDA, ENDDA, ZTEILE, ZTEILN, TEILK
Filtrar por fecha de referencia y empleados activos (join con PA0000)
```

---

### 3. Tasa de Rotacion (Turnover Rate)

**Definicion:** Porcentaje de empleados que abandonan la organizacion en un periodo.

**Formula — Rotacion Total:**
```
Turnover Rate = (Numero de bajas en el periodo / Headcount promedio del periodo) x 100
```

**Formula — Rotacion Voluntaria:**
```
Voluntary Turnover = (Bajas voluntarias / Headcount promedio) x 100
```

**Formula — Rotacion Involuntaria:**
```
Involuntary Turnover = (Bajas involuntarias / Headcount promedio) x 100
```

**Clasificacion en HCM:**
- Tabla `PA0000` (Acciones): tipo de accion `MASSN` + razon de accion `MASSG`
- Tabla `T529A` — definicion de tipos de accion (identificar cuales son bajas)
- Tabla `T529T` — textos de tipos de accion
- Convension comun: crear grupos de reasons para clasificar voluntaria vs involuntaria

**Benchmarks por industria:**
- Retail: 60-100% anual (alta rotacion esperada)
- Manufactura: 15-30% anual
- Tecnologia: 13-20% anual
- Servicios financieros: 10-15% anual
- Sector publico: 5-10% anual

---

### 4. Time to Hire (Tiempo de Contratacion)

**Definicion:** Dias promedio desde la apertura de una vacante hasta la aceptacion de la oferta.

**Formula:**
```
Time to Hire = AVG(fecha_aceptacion_oferta - fecha_apertura_requisicion)
```

**Variante — Time to Fill:**
```
Time to Fill = AVG(fecha_primer_dia_trabajo - fecha_apertura_requisicion)
```

**Fuente de datos:**
- HCM Recruitment: tablas `PB4000` (aplicantes), `PB0001` (datos basicos aplicante)
- Fecha de requisicion: campo `BEGDA` del anuncio de puesto
- Fecha de contratacion: IT0000 con accion 'contratacion' (MASSN para hire)
- SuccessFactors Recruiting: via OData `JobApplication`, `JobRequisition`

**Benchmarks:**
- Posiciones operativas: 15-30 dias
- Posiciones profesionales: 30-45 dias
- Posiciones directivas: 60-90 dias

---

### 5. Cost per Hire (Costo por Contratacion)

**Definicion:** Costo total incurrido para contratar a un empleado.

**Formula:**
```
Cost per Hire = (Costos internos de reclutamiento + Costos externos) / Numero de contrataciones
```

**Componentes:**
- Costos internos: salarios del equipo de RRHH, tiempo dedicado a entrevistas
- Costos externos: agencias, job boards, assessment tools, relocation
- Fuente: ordenes internas CO o WBS de RRHH con acumulacion de costos de contratacion

**Benchmarks:**
- Pequenas empresas: 1,000 - 3,000 USD por contratacion
- Medianas: 3,000 - 8,000 USD
- Posiciones ejecutivas: puede superar 50,000 USD

---

### 6. Tasa de Ausentismo (Absenteeism Rate)

**Definicion:** Porcentaje de dias laborables perdidos por ausencias no programadas.

**Formula:**
```
Absenteeism Rate = (Dias de ausencia no planificada / Dias laborables disponibles) x 100
```

**Formula alternativa (Bradford Factor):**
```
Bradford Factor = S^2 x D
Donde: S = numero de episodios de ausencia, D = total de dias de ausencia
```

**Fuente de datos HCM:**
- Tabla `PTABS` (absences): ausencias registradas por empleado
- Tabla `T554S` — tipos de ausencia (clasificar planificadas vs no planificadas)
- Tabla `PA2001` (Absences infotype): ausencias con fechas
- Dias laborables disponibles: segun work schedule (IT0007) y calendario de fabrica

**Benchmarks:**
- Aceptable: menor a 2.5%
- Elevado: 3-5%
- Critico: mayor a 5%

**Query MCP:**
```
ReadTable: PA2001, filtros por BEGDA/ENDDA y tipo de ausencia (AWART)
ReadTable: T554S, para obtener clasificacion de ausencias
```

---

### 7. Ratio de Horas Extra (Overtime Ratio)

**Definicion:** Porcentaje de horas extra sobre las horas laborables totales.

**Formula:**
```
Overtime Ratio = (Horas extra / Horas regulares totales) x 100
```

**Fuente de datos HCM:**
- Tabla `ZL` en cluster de tiempos (tabla PCL2, clave B2): resultados de calculo de tiempo
- Wage types de horas extra: dependen del customizing (tiempo management)
- Tabla `PA2010` (Employee Remuneration Info): si se usa infotipo para horas extra manuales
- CATS: tabla `CATSDB`, tipo de actividad para overtime

**Alerta:** Overtime ratio alto sostenido indica posible necesidad de nuevas contrataciones o redistribucion de trabajo.

---

### 8. Horas de Formacion por Empleado (Training Hours per Employee)

**Definicion:** Promedio de horas de formacion realizadas por empleado en un periodo.

**Formula:**
```
Training Hours = SUM(horas de formacion completadas) / Headcount
```

**Fuente de datos HCM:**
- Modulo Training & Event Management (PE): tabla `HRP1021` (participaciones en cursos)
- Tabla `T77PR` — tipos de actividades de formacion
- SuccessFactors LMS: completaciones via OData `LearnerHistory`
- CATS: si se registran horas de formacion como tipo de actividad especifico

**Benchmarks:**
- Promedio global: 30-50 horas/empleado/ano
- Industrias de alta tecnologia: 60-80 horas
- Manufactura: 40-60 horas

---

### 9. Compa-Ratio (Ratio de Compensacion)

**Definicion:** Relacion entre el salario de un empleado y el punto medio del rango salarial para su puesto.

**Formula:**
```
Compa-Ratio = (Salario actual del empleado / Punto medio del rango salarial) x 100
```

**Interpretacion:**
- Compa-Ratio < 80%: empleado por debajo del mercado (riesgo de rotacion)
- Compa-Ratio 80-120%: rango competitivo
- Compa-Ratio > 120%: empleado sobrecompensado vs mercado (posible techo salarial)

**Fuente de datos HCM:**
- Salario actual: `PA0008` — `BET01` (salario base) + `WAERS` (moneda)
- Rango salarial: tablas de estructura de salarios `T510` (Pay Scale Groups/Levels) o tablas Z personalizadas
- Para pay grade: `PA0008-TRFGR` (pay scale group), `PA0008-TRFST` (pay scale level)

**Query MCP:**
```
ReadTable: PA0008, campos PERNR, BET01, WAERS, TRFGR, TRFST, BSGRD
ReadTable: T510, para obtener rangos por grupo/nivel de pay scale
```

---

### 10. Ingresos por Empleado (Revenue per Employee)

**Definicion:** Productividad economica de la fuerza laboral.

**Formula:**
```
Revenue per Employee = Ingresos totales del periodo / FTE promedio del periodo
```

**Fuente de datos:**
- Ingresos: S/4HANA FI/CO — ACDOCA filtrado por cuentas de ingresos (`KTOSL` tipo E)
- FTE: calculado desde PA0007 (ver seccion FTE)
- Combinar via SAP Analytics Cloud (SAC) o Embedded Analytics (CDS views)

**Benchmarks por industria:**
- Software/Tech: 250,000 - 500,000 USD/empleado
- Servicios financieros: 200,000 - 400,000 USD
- Manufactura: 100,000 - 200,000 USD
- Retail: 50,000 - 100,000 USD

---

### 11. Ratio de Costos de RRHH (HR Cost Ratio)

**Definicion:** Porcentaje que representa el costo total de personal sobre los costos operativos totales.

**Formula:**
```
HR Cost Ratio = (Costos totales de personal / Costos operativos totales) x 100
```

**Componentes de costos de personal:**
- Salarios y sueldos (wage types de nomina)
- Beneficios y cargas sociales
- Costos de formacion
- Costos de reclutamiento

**Fuente de datos:**
- Costos de personal: ACDOCA filtrado por cuentas de naturaleza personal (tipo 4xxx o segun chart of accounts)
- Costos totales: ACDOCA todos los costos operativos
- Combinar con CO report: S_ALR_87013611 (Cost Centers: Actual/Plan)

**Benchmarks:**
- Servicios profesionales: 60-75% (costo de personal es el costo principal)
- Manufactura: 20-30%
- Retail: 10-20%
- Tecnologia (producto): 40-60%

---

## CDS Views para Analytics Embebido (S/4HANA 2023)

### CDS Views estandar de HCM disponibles

**Organizational Data:**
- `C_HCMEmployeeOrganization` — empleado con asignacion organizacional actual
- `I_HCMEmployeeOrgAssignment` — historial de asignaciones organizacionales

**Time Data:**
- `I_HCMTimeRecording` — registros de tiempo
- `I_HCMAbsence` — ausencias

**Payroll:**
- `I_PayrollResult` — resultados de nomina
- `C_PayrollDocumentLine` — lineas de documento de posting de nomina

**Composite (para KPIs):**
- `C_HCMHeadcountQuery` — headcount por fecha, org unit, cost center
- `C_HCMTurnoverQuery` — movimientos de personal (entradas/salidas)

### Crear Query Analytical en ABAP CDS

Ejemplo para Headcount por Cost Center:
```abap
@Analytics.query: true
@VDM.viewType: #CONSUMPTION
define view entity C_HCMHeadcountByCostCenter
  as select from I_HCMEmployeeOrgAssignment
{
  @AnalyticsDetails.query.axis: #ROWS
  CostCenter,
  @AnalyticsDetails.query.axis: #ROWS
  OrgUnit,
  @DefaultAggregation: #COUNT_DISTINCT
  PersonnelNumber,
  @DefaultAggregation: #SUM
  FtePercentage
}
where EmploymentStatus = 'Active'
```

---

## SAP Analytics Cloud (SAC) — Integracion con HCM

### Conexion Live con S/4HANA
- Live Data Connection: SAC se conecta directamente a CDS views de S/4HANA
- No requiere replicacion de datos (datos en tiempo real)
- Configuracion: SAC → System → Connections → Add → SAP S/4HANA (Live)

### Modelos de datos SAC para HR
- Importar desde CDS views de HCM (Embedded Analytics)
- Combinar con datos de CO (costos) para KPIs integrados
- Ejemplo: Revenue per Employee = datos FI (ACDOCA) + FTE (PA0007)

### Stories HR recomendadas
- **Headcount & FTE Dashboard:** evolucion mensual, por departamento, por ubicacion
- **Turnover Analysis:** tasa por mes, por causa, por antiguedad, por departamento
- **Compensation Analytics:** distribucion salarial, compa-ratio por job grade, equidad de genero
- **Time & Attendance:** ausentismo por tipo, overtime trends, horas de formacion

### Workforce Planning en SAC
- Modelado de escenarios: "que pasa si contratamos 50 personas en Q3"
- Driver-based planning: vincular headcount con revenue y costos
- Version management: planificado vs real vs forecast

---

## Fiori Analytical Apps para HR

| App | Tile | Descripcion |
|---|---|---|
| Headcount and FTE | F2302 | Headcount y FTE por org unit, con drill-down |
| Employee Turnover | F2303 | Analisis de rotacion con causas |
| Time and Attendance | F1367 | Ausentismo, overtime, horas planificadas vs reales |
| Workforce Demographics | F2304 | Distribucion por genero, edad, antiguedad |
| Compensation Analysis | F2305 | Distribucion salarial, compa-ratio |
| Training Completion | F2306 | Completaciones de formacion, cumplimiento compliance |
| Payroll Overview | F0847 | Resumen de costos de nomina por periodo |

---

## Queries MCP para KPIs

### Headcount actual
```
ReadTable: PA0000
Filtros: STAT2 = '3' (activo), BEGDA <= TODAY, ENDDA >= TODAY
Campos: PERNR, MASSN, BEGDA
COUNT resultados = Headcount
```

### FTE por Cost Center
```
ReadTable: PA0007
Filtros: BEGDA <= TODAY, ENDDA >= TODAY
Campos: PERNR, KOSTL (de PA0001 via join), ZTEILE, ZTEILN
FTE por empleado = ZTEILE / ZTEILN
```

### Rotacion del periodo
```
ReadTable: PA0000
Filtros: MASSN IN (tipos de baja), BEGDA BETWEEN fecha_inicio AND fecha_fin
Campos: PERNR, MASSN, MASSG, BEGDA
COUNT = total de bajas en el periodo
```

### Ausencias del mes
```
ReadTable: PA2001
Filtros: BEGDA >= primer_dia_mes, ENDDA <= ultimo_dia_mes
Campos: PERNR, AWART, BEGDA, ENDDA, ABWTG (dias de ausencia)
SUM(ABWTG) = total dias de ausencia
```

### Horas extra del periodo
```
ReadTable: CATSDB
Filtros: WORKDATE BETWEEN fecha_inicio AND fecha_fin, LSTAR = (activity type overtime)
Campos: PERNR, WORKDATE, CATSHOURS
SUM(CATSHOURS) = total horas extra via CATS
```

### Salario promedio por Job Grade
```
ReadTable: PA0008
Filtros: BEGDA <= TODAY, ENDDA >= TODAY
Campos: PERNR, BET01, WAERS, TRFGR, TRFST
AVG(BET01) GROUP BY TRFGR = salario promedio por pay scale group
```

### Costos de personal en ACDOCA
```
ReadTable: ACDOCA
Filtros: RBUKRS, GJAHR, MONAT, RACCT IN (cuentas de personal)
Campos: RBUKRS, RACCT, KOSTL, PRCTR, HSL (importe en moneda local)
SUM(HSL) GROUP BY KOSTL = costo de personal por cost center
```

### Verificar CDS views disponibles para HR
```
SearchObject: tipo DDLS, buscar por nombre C_HCM*
SearchObject: tipo DDLS, buscar por nombre I_HCM*
```
