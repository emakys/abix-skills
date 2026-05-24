# Labor Management (LM)

## Visión General de Labor Management en EWM

Labor Management (LM) en SAP EWM es el módulo para medir, gestionar y optimizar la productividad de los trabajadores del almacén. Permite comparar el tiempo planificado (estándar) contra el tiempo real empleado en cada tarea, identificar desviaciones y calcular métricas de rendimiento.

En S/4HANA 2023 Embedded EWM, LM está integrado nativamente con Warehouse Management y utiliza los datos de confirmación de Warehouse Tasks (WT) como base para el cálculo de tiempos reales.

---

## Conceptos Clave

### Tiempo planificado vs. tiempo real
- **Planned time (tiempo planificado)**: Tiempo estándar que debería tardar un operador en completar una tarea, calculado por los Engineered Labor Standards (ELS).
- **Actual time (tiempo real)**: Tiempo efectivamente consumido, registrado al confirmar la WT.
- **Variance (varianza)**: Diferencia entre planificado y real. Positiva = más rápido que el estándar. Negativa = más lento.

### Performance ratio
```
Performance = (Planned Time / Actual Time) × 100
```
- 100% = rendimiento exactamente al estándar.
- > 100% = operador más productivo que el estándar.
- < 100% = operador por debajo del estándar.

---

## Engineered Labor Standards (ELS)

Los ELS son los tiempos estándar calculados para cada tipo de actividad en el almacén. Se basan en:

### Componentes del tiempo estándar
| Componente | Descripción |
|---|---|
| **Travel time** | Tiempo de desplazamiento entre ubicaciones |
| **Pick/put time** | Tiempo de tomar o depositar un artículo |
| **Scan time** | Tiempo de escaneo de barcode |
| **Setup time** | Tiempo de preparación (configurar equipo, leer instrucción) |
| **Fatigue allowance** | Porcentaje adicional por fatiga del operador |
| **Personal time** | Tiempo asignado por turno para necesidades personales |

### Métodos de cálculo de travel time
1. **Fixed time**: Tiempo fijo por tarea, independiente de la distancia.
2. **Distance-based**: Tiempo calculado según distancia entre bin origen y bin destino (requiere coordenadas de bins configuradas).
3. **Path analysis**: Cálculo por rutas predefinidas en el almacén.

Configuración de ELS: /SCWM/LM_ELS — definición de tiempos por tipo de actividad y tipo de recurso.

---

## Tipos de Trabajo (Work Types)

LM clasifica el trabajo en categorías:

### Trabajo directo
Actividades directamente relacionadas con el movimiento de mercancías:
- Picking (selección de artículos).
- Putaway (almacenamiento).
- Replenishment (reabastecimiento).
- Packing (empaque).
- Physical Inventory (inventario físico).
- Loading / Unloading (carga y descarga).

### Trabajo indirecto (Indirect Labor)
Actividades necesarias pero no directamente productivas:
- Reuniones (team meetings).
- Mantenimiento de equipos.
- Formación / capacitación.
- Esperas por sistema o supervisor.
- Descansos no programados.
- Limpieza de área.

Registro de trabajo indirecto: /SCWM/LM_INDIRECT — el operador o supervisor registra el código de actividad indirecta y la duración.

---

## Cálculo de Travel Time

El sistema puede calcular automáticamente el tiempo de viaje si las ubicaciones (bins) tienen coordenadas configuradas:

### Configuración de coordenadas de bin
En /SCWM/CUSTOMIZING → Storage Bin → Coordinates:
- **X-coordinate**: Posición horizontal (pasillo).
- **Y-coordinate**: Posición en el pasillo (columna).
- **Z-coordinate**: Altura (nivel de rack).

### Fórmula básica de travel time
```
Travel Time = √((X2-X1)² + (Y2-Y1)²) / Velocidad_recurso
            + |Z2-Z1| / Velocidad_vertical
```

La velocidad del recurso (m/s o m/min) se configura por tipo de recurso (peatón, montacargas, etc.).

---

## Integración con Confirmación de Warehouse Tasks

Cuando un operador confirma una WT en RF o Fiori:
1. El sistema registra el **timestamp de inicio** (cuando se asignó la tarea) y el **timestamp de fin** (confirmación).
2. Calcula el tiempo real empleado.
3. Recupera el tiempo planificado desde ELS para ese tipo de tarea.
4. Registra ambos tiempos en las tablas LM (/SCWM/LMLOG).
5. Acumula datos para reportes de rendimiento.

---

## Métricas e Indicadores de Rendimiento (KPIs)

### KPIs por operador
| KPI | Descripción |
|---|---|
| **Performance %** | Ratio planificado/real × 100 |
| **Lines per hour** | Líneas de picking por hora |
| **Units per hour** | Unidades procesadas por hora |
| **Travel distance** | Distancia total recorrida en el turno |
| **Direct labor %** | % del tiempo en trabajo directo vs. indirecto |
| **Indirect labor %** | % del tiempo en actividades indirectas |

### KPIs por turno / área
- Productividad total del turno.
- Distribución de trabajo por zona de almacén.
- Tiempos de espera del equipo.
- Comparativo entre turnos.

### KPIs por tipo de actividad
- Tiempo promedio de picking por línea.
- Tiempo promedio de putaway.
- Ratio de cumplimiento de estándares (% tareas dentro del tiempo planificado).

---

## Programas de Incentivos

LM permite implementar programas de incentivos basados en el rendimiento medido:

### Tipos de incentivo
1. **Bonus por productividad**: Pago adicional cuando el performance supera un umbral (ej. > 110%).
2. **Banda de rendimiento**: Diferentes tarifas según rango de performance.
3. **Incentivo grupal**: Basado en el rendimiento del equipo o turno completo.

### Configuración
/SCWM/LM_INCENTIVE — definición de programas de incentivo:
- Umbral mínimo de rendimiento para calificar.
- Fórmula de cálculo del incentivo.
- Período de evaluación (diario, semanal, mensual).
- Exportación a SAP HCM Payroll o sistema externo de nómina.

---

## Reportes de Labor Management

### Transacciones de reporte
| Transacción | Descripción |
|---|---|
| /SCWM/LM_REPORT | Reporte principal de rendimiento de operadores |
| /SCWM/LM_SUMMARY | Resumen de productividad por turno/área |
| /SCWM/LM_INDIRECT | Registro y reporte de trabajo indirecto |
| /SCWM/LM_INCENTIVE | Cálculo y reporte de incentivos |

### Fiori apps para LM (S/4HANA 2023)
- **Labor Management Overview** (F3456): Dashboard de productividad en tiempo real.
- **Worker Performance** (F3457): Detalle de rendimiento individual.
- **Indirect Labor** (F3458): Registro de actividades indirectas.

---

## Configuración de Labor Management

### Pasos de activación
1. Activar LM en el warehouse number: /SCWM/CUSTOMIZING → Labor Management → Activate.
2. Definir tipos de actividad de trabajo directo e indirecto.
3. Configurar ELS (Engineered Labor Standards) por tipo de tarea y tipo de recurso.
4. Asignar velocidades a tipos de recurso (peatón, montacargas, etc.).
5. Configurar coordenadas de bins si se usa travel time basado en distancia.
6. Definir programas de incentivo (opcional).
7. Asignar roles Fiori o acceso a transacciones de reporte.

---

## Comparación con módulos LM de WMS independientes

| Aspecto | LM en SAP EWM | WMS standalone (ej. Manhattan, JDA) |
|---|---|---|
| **Integración** | Nativa con EWM, sin interfaz | Requiere interfaz con EWM/SAP |
| **Datos base** | Confirma WT directamente | Importa eventos de WMS |
| **Complejidad ELS** | Configuración SAP estándar | Herramientas especializadas de tiempo-movimiento |
| **Incentivos** | Básico, integra con HCM | Módulo completo con gamification |
| **Real-time** | Sí, con RF/Fiori | Depende de la interfaz |
| **Coordinadas bins** | Configuradas en EWM | Mapa de almacén dedicado |

---

## Consultas MCP relevantes para Labor Management

### Verificar si LM está activado en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/TLGTYP
  fields: [LGNUM, LM_ACTIVE, LM_ELS_ACTIVE]
  where: LGNUM = '[WH]'
```

### Consultar registros de tiempo LM
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/LMLOG
  fields: [LGNUM, RSRC, TANUM, ACT_TYPE, PLAN_TIME, ACT_TIME, PERF_RATIO, UNAME, BUDAT]
  where: LGNUM = '[WH]' AND BUDAT = '[DATE]'
  order_by: UNAME, TANUM
```

### Consultar trabajo indirecto registrado
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/LMINDIR
  fields: [LGNUM, RSRC, UNAME, INDIR_TYPE, DURATION, START_TS, END_TS, BUDAT]
  where: LGNUM = '[WH]' AND BUDAT BETWEEN '[DATE_FROM]' AND '[DATE_TO]'
```

### Consultar estándares ELS definidos
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/ELS_STD
  fields: [LGNUM, ACT_TYPE, RSRC_TYPE, PLAN_TIME_BASE, UNIT, VALID_FROM]
  where: LGNUM = '[WH]'
```

### Calcular performance por operador en un período
```
Tool: ExecuteReport
Parameters:
  program_name: /SCWM/R_LM_PERFORMANCE
  parameters:
    p_lgnum: '[WH]'
    p_date_from: '[DATE_FROM]'
    p_date_to: '[DATE_TO]'
    p_uname: '[USER]'  -- vacío = todos
```

### Consultar recursos y sus velocidades configuradas
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/TRSRC_TYPE
  fields: [LGNUM, RSRC_TYPE, SPEED_HORIZ, SPEED_VERT, UNIT_SPEED]
  where: LGNUM = '[WH]'
```
