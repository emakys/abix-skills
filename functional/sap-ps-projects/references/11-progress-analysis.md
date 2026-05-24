# Analisis de Avance (Progress Analysis / Earned Value)

## Introduccion

El Analisis de Avance en SAP PS permite medir el progreso real de un proyecto y compararlo con la planificacion original. Se implementa mediante **Progress Analysis** (PA) que calcula metricas de Earned Value Management (EVM) a nivel de elemento WBS, red y actividad.

SAP S/4HANA 2023 integra el analisis de avance con el **Project Information System**, el **Results Analysis** y el modulo de **Commercial Project Management (CPM)** para proyectos comerciales.

---

## 1. Conceptos Fundamentales EVM

### 1.1 Metricas Base

| Sigla | Nombre Completo | Descripcion | Calculo |
|-------|----------------|-------------|---------|
| **PV** | Planned Value (BCWS) | Valor planificado del trabajo programado | Coste plan * % avance planificado |
| **EV** | Earned Value (BCWP) | Valor ganado del trabajo realizado | Coste plan * % avance real |
| **AC** | Actual Cost (ACWP) | Coste actual incurrido | Suma costes reales |
| **BAC** | Budget at Completion | Presupuesto total aprobado | Presupuesto total del proyecto |
| **EAC** | Estimate at Completion | Estimacion a la terminacion | AC + (BAC - EV) / CPI |
| **ETC** | Estimate to Complete | Estimacion para terminar | EAC - AC |
| **VAC** | Variance at Completion | Variacion a la terminacion | BAC - EAC |

### 1.2 Indices de Rendimiento

| Sigla | Nombre | Formula | Interpretacion |
|-------|--------|---------|----------------|
| **SV** | Schedule Variance | EV - PV | Positivo = adelantado; Negativo = retrasado |
| **CV** | Cost Variance | EV - AC | Positivo = bajo presupuesto; Negativo = sobre presupuesto |
| **SPI** | Schedule Performance Index | EV / PV | >1 adelantado; <1 retrasado; =1 en tiempo |
| **CPI** | Cost Performance Index | EV / AC | >1 bajo presupuesto; <1 sobre presupuesto; =1 en plan |
| **TCPI** | To-Complete Performance Index | (BAC - EV) / (BAC - AC) | CPI necesario para terminar dentro de presupuesto |
| **SPI(t)** | Time-based SPI | ES / AT | Variante temporal del SPI |

---

## 2. Metodos de Medicion de Avance

### 2.1 Clasificacion General

SAP PS ofrece los siguientes metodos de medicion de avance (configurables en el perfil de avance):

#### Metodo 01: Hitos (Milestones)
- El avance se calcula en base a hitos definidos con porcentajes de avance asociados.
- Cada hito completado aporta su peso al total del avance del elemento.
- Ideal para proyectos con entregables claramente definidos.

**Ejemplo:**
```
Hito 1: Aprobacion de Diseño = 20%
Hito 2: Construccion Completada = 50%
Hito 3: Pruebas Aprobadas = 20%
Hito 4: Entrega Final = 10%
Total: 100%
```

**Configuracion en sistema:**
- Transaccion: `CN30` (crear hito), `CN31` (modificar hito)
- Los hitos deben tener el campo **Indicador de avance** activado
- Se asigna porcentaje de avance en la ficha del hito

#### Metodo 02: Porcentaje Manual (Estimation by Supervisor)
- El responsable del proyecto introduce manualmente el porcentaje completado.
- Flexible pero subjetivo.
- Requiere disciplina en la actualizacion periodica.

**Uso:** Transaccion `CNE1` o `CNE5` para confirmacion colectiva.

#### Metodo 03: Cantidad (Units Complete)
- Avance = Cantidad completada / Cantidad total planificada.
- Objetivo y automatico si se registran cantidades reales.
- Ejemplo: metros de tuberia instalados vs. total planificado.

**Formula SAP:**
```
POC (%) = Cantidad Confirmada / Cantidad Planificada * 100
```

#### Metodo 04: Inicio-Fin (0/100)
- 0% hasta que la actividad comienza, 100% cuando termina.
- Solo para actividades muy cortas o de bajo valor.

#### Metodo 05: Inicio-Fin (20/80)
- 20% al iniciar, 80% al completar.
- Variante mas gradual del metodo 0/100.

#### Metodo 06: Inicio-Fin (50/50)
- 50% al iniciar, 50% al completar.

#### Metodo 07: Nivel de Esfuerzo (Level of Effort)
- Avance = avance del proyecto padre o fecha actual vs. duracion.
- Para actividades de soporte que duran todo el proyecto.

#### Metodo 08: Formula Ponderada (Weighted Milestone)
- Combinacion de hitos con pesos relativos.

#### Metodo 10: Proporcional al Tiempo (Time-Proportional)
- Avance = (Fecha actual - Fecha inicio) / (Fecha fin - Fecha inicio) * 100.
- Solo refleja tiempo, no trabajo real.

#### Metodo 11: Curva S / Distribucion
- Distribucion del avance segun curva predefinida.

---

## 3. Configuracion del Perfil de Avance

### 3.1 Perfil de Avance (Progress Profile)

El perfil de avance controla como se mide y agrega el avance.

**Ruta SPRO:**
```
Project System > Progress > Progress Analysis > Define Progress Profile
```
`Transaccion SPRO → IM53 / tabla EVPROFIL`

**Parametros del Perfil:**

| Campo | Descripcion |
|-------|-------------|
| Perfil avance | Clave del perfil (4 caracteres) |
| Metodo medicion | Metodo por defecto para nuevos elementos |
| Tipo avance WBS | Como agregar avance de hijos a padres |
| Tipo avance red | Como agregar avance de actividades |
| Metodo ponderacion | Costes plan / Duracion / Manual |
| Version plan | Version de plan para base de calculo |
| Clase de valor | Costes primarios / secundarios para base |
| Indicador automatico | Si calcular avance automaticamente |

### 3.2 Asignacion del Perfil

El perfil se asigna a nivel de:
- **Tipo de proyecto** (parametro por defecto)
- **Perfil de WBS** (sobrescritura por elemento)
- **Red** (para actividades de red)

**Ruta SPRO:**
```
Project System > Progress > Progress Analysis > Assign Progress Profile to Project Type
```

---

## 4. Transacciones Principales

### 4.1 CNE1 - Confirmacion de Avance Individual

**Funcion:** Registrar avance de un elemento WBS o actividad especifica.

**Campos principales:**
| Campo | Descripcion |
|-------|-------------|
| Elemento WBS / Actividad | Objeto a actualizar |
| Fecha | Fecha del avance |
| Porcentaje avance | % completado (metodo manual) |
| Cantidad confirmada | Para metodo cantidad |
| Estado | OPEN / CONFIRMED |

**Pasos:**
1. Ejecutar `CNE1`
2. Introducir clave WBS o red/actividad
3. Seleccionar fecha de avance
4. Introducir porcentaje o cantidad
5. Grabar

### 4.2 CNE5 - Confirmacion Colectiva de Avance

**Funcion:** Actualizar avance de multiples elementos simultaneamente.

**Variantes de seleccion:**
- Por proyecto
- Por responsable
- Por fecha
- Por estado de elemento

**Proceso:**
1. Ejecutar `CNE5`
2. Seleccionar rango de proyectos/WBS
3. Lista editable de elementos con avance actual
4. Modificar porcentajes
5. Grabar todos los cambios

### 4.3 CNE6 - Vista General de Avance

**Funcion:** Reporte de avance con metricas EVM.

**Seleccion:** Por proyecto, versión, fecha clave.

**Columnas disponibles:**
- EV (Earned Value)
- PV (Planned Value)
- AC (Actual Cost)
- SV, CV, SPI, CPI
- Fecha de avance
- Metodo de medicion

### 4.4 CNE7 - Historial de Avance

**Funcion:** Ver evolucion del avance en el tiempo.

Muestra la curva S real vs. planificada.

### 4.5 S_ALR_87013532 - Analisis de Avance (Informe Estandar)

Informe clasico PS con comparacion plan/real/avance.

---

## 5. Versiones de Avance

Las **versiones de avance** permiten congelar una fotografia del estado del proyecto en un momento dado (similar a un baseline).

### 5.1 Crear Version de Avance

**Transaccion:** `CJ9B` o dentro de `CNE1`/`CNE5`

**Campos:**
| Campo | Descripcion |
|-------|-------------|
| Version | Numero de version (01-99) |
| Descripcion | Texto descriptivo |
| Fecha | Fecha de referencia |
| Indicador bloqueo | Si la version es de solo lectura |

### 5.2 Comparacion entre Versiones

- Version 00 = Version operativa (actual)
- Versiones 01-99 = Versiones de simulacion/baseline

Se pueden comparar en los informes `CNE6` y `S_ALR_87013532` seleccionando la version de comparacion.

---

## 6. Tablas de Base de Datos

### 6.1 EVPR - Registros de Avance de Proyecto

**Descripcion:** Almacena los registros de confirmacion de avance por elemento WBS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| PSPNR | NUMC8 | Numero interno WBS |
| PGVER | NUMC2 | Version de avance |
| DATUM | DATS | Fecha de avance |
| PGIST | DEC | Porcentaje avance real (%) |
| PGSOL | DEC | Porcentaje avance planificado (%) |
| ISMNQ | QUAN | Cantidad real confirmada |
| SLMNQ | QUAN | Cantidad planificada |
| PGMTH | CHAR2 | Metodo de medicion |
| PGPRO | CHAR4 | Perfil de avance |
| ERNAM | CHAR12 | Usuario creacion |
| AENAM | CHAR12 | Usuario modificacion |
| ERDAT | DATS | Fecha creacion |
| AEDAT | DATS | Fecha modificacion |
| LOEVM | CHAR1 | Indicador borrado |

**Query MCP ejemplo:**
```sql
-- Avance actual de todos los WBS de un proyecto
SELECT p.posid, p.post1, e.datum, e.pgist, e.pgsol, e.pgmth
FROM prps p
INNER JOIN evpr e ON p.pspnr = e.pspnr
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001')
  AND e.pgver = '00'
ORDER BY p.posid, e.datum DESC
```

### 6.2 EVPO - Posiciones de Avance (Earned Value por Posicion)

**Descripcion:** Almacena los valores de Earned Value calculados (EV, PV, AC) por elemento.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| PSPNR | NUMC8 | Numero interno WBS |
| PGVER | NUMC2 | Version de avance |
| WRTTP | CHAR2 | Tipo de valor (04=plan, 11=real) |
| VERSN | NUMC3 | Version de plan |
| GJAHR | NUMC4 | Ejercicio fiscal |
| PERIO | NUMC2 | Periodo |
| PGWRT | CURR | Valor EV (Earned Value) |
| PLWRT | CURR | Valor PV (Planned Value) |
| ISTWRT | CURR | Valor AC (Actual Cost) |
| WAERS | CUKY | Moneda |
| PGBAS | CHAR1 | Base de calculo (C=coste, D=duracion) |

**Query MCP ejemplo:**
```sql
-- Metricas EVM por elemento WBS
SELECT
    p.posid AS "WBS",
    p.post1 AS "Descripcion",
    e.pgwrt AS "EV",
    e.plwrt AS "PV",
    e.istwrt AS "AC",
    (e.pgwrt - e.plwrt) AS "SV",
    (e.pgwrt - e.istwrt) AS "CV",
    CASE WHEN e.plwrt <> 0 THEN e.pgwrt / e.plwrt ELSE 0 END AS "SPI",
    CASE WHEN e.istwrt <> 0 THEN e.pgwrt / e.istwrt ELSE 0 END AS "CPI"
FROM prps p
INNER JOIN evpo e ON p.pspnr = e.pspnr
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001')
  AND e.pgver = '00'
  AND e.gjahr = '2024'
ORDER BY p.posid
```

### 6.3 Otras Tablas Relacionadas

| Tabla | Descripcion |
|-------|-------------|
| EVPRP | Parametros de perfil de avance |
| EVPVER | Versiones de avance |
| EVPST | Status de posicion de avance |
| CNTAB | Tabla control confirmaciones |

---

## 7. Tecnicas de Medicion Avanzadas

### 7.1 Ponderacion por Costes Plan

Es el metodo de agregacion mas comun. El avance de nivel superior se calcula ponderando los avances de los elementos inferiores por sus costes planificados.

**Formula:**
```
EV_padre = SUM(EV_hijo_i) para todos los hijos i
PV_padre = SUM(PV_hijo_i)
```

### 7.2 Ponderacion por Duracion

Similar al anterior pero usa la duracion planificada de las actividades como peso.

**Uso:** Proyectos donde el coste no es proporcional al esfuerzo.

### 7.3 Ponderacion Manual

El usuario define manualmente el peso relativo de cada elemento hijo.

### 7.4 Tecnicas EVM Avanzadas

#### Regla del 50/50
- Al iniciar una tarea: 50% EV
- Al completar: 50% EV restante
- Simple y frecuente en proyectos agiles

#### Regla del 0/100
- Sin EV hasta completar
- Muy conservadora, penaliza el avance

#### Formula Fisica
Para trabajos con entregables cuantificables:
```
EV = (Unidades completadas / Unidades totales) * BAC
```

---

## 8. Integracion con Fiori

### 8.1 Apps Fiori Relevantes

| App ID | Nombre | Funcion |
|--------|--------|---------|
| F2390 | Project Progress | Vista consolidada de avance del proyecto |
| F3538 | Confirm Project Progress | Confirmacion de avance via Fiori |
| F2394 | Project Overview | Dashboard con indicadores EVM |
| F3540 | Monitor Project Progress | Seguimiento periodico de avance |

### 8.2 Configuracion Fiori para Progress Analysis

**Ruta:**
```
SPRO > Project System > Progress > Integration with Fiori
```

Se debe activar el **OData Service** correspondiente:
- `PS_PROJECT_PROGRESS_SRV`
- `PS_PROJECT_DASHBOARD_SRV`

---

## 9. Customizing Detallado

### 9.1 Definir Metodos de Medicion

**Ruta SPRO:**
```
Project System > Progress > Progress Analysis > Define Measurement Methods
```

Tabla: `T8PF` (metodos de medicion de avance)

| Campo | Descripcion |
|-------|-------------|
| PGMTH | Clave del metodo (2 car.) |
| MTEXT | Descripcion |
| PGTYP | Tipo (M=manual, Q=cantidad, H=hitos, T=tiempo) |
| PGAUTO | Calculo automatico |

### 9.2 Configurar Versiones de Avance

**Ruta SPRO:**
```
Project System > Progress > Progress Analysis > Define Progress Versions
```

Tabla: `EVPVER`

### 9.3 Tolerancias y Alertas

**Ruta SPRO:**
```
Project System > Progress > Progress Analysis > Define Tolerances for Progress
```

Permite definir umbrales para semaforos:
- Verde: SPI/CPI entre 0.95 y 1.05
- Amarillo: SPI/CPI entre 0.85 y 0.95 o 1.05 y 1.15
- Rojo: SPI/CPI < 0.85 o > 1.15

---

## 10. Flujo de Proceso Completo

```
1. PLANIFICACION
   └── Definir perfil de avance en tipo de proyecto (SPRO)
   └── Asignar perfil a proyecto (CJ01/CJ02)
   └── Definir hitos con pesos (si metodo = hitos)
   └── Establecer baseline (version 01)

2. EJECUCION
   └── Confirmar avance periodicamente (CNE1 / CNE5)
   └── Registrar costes reales (FB01, MIGO, etc.)
   └── Actualizar hitos completados (CN30/CN31)

3. ANALISIS
   └── Ejecutar calculo EVM (CNE6)
   └── Ver metricas SPI, CPI, SV, CV
   └── Analizar variaciones y tendencias (CNE7)

4. REPORTE
   └── S_ALR_87013532 - Informe estandar
   └── Fiori App F2390 - Project Progress
   └── Exportar a Excel / BI / BW
```

---

## 11. Errores Frecuentes y Soluciones

| Error | Causa | Solucion |
|-------|-------|---------|
| No se calcula EV para elemento | Falta perfil de avance asignado | Asignar perfil en CJ02 |
| Avance no se agrega al nivel superior | Tipo de agregacion incorrecto en perfil | Revisar perfil SPRO |
| SPI = 0 aunque hay avance | PV = 0 por falta de plan de costes | Planificar costes en CJ40 |
| Porcentaje no se graba | Elemento WBS en status incorrecto | Verificar status TECO/LKD |
| Hitos no contribuyen al avance | Indicador de avance no activado en hito | Activar en CN30/CN31 |
| Version de avance bloqueada | Version marcada como solo lectura | Desbloquear en EVPVER |

---

## 12. Buenas Practicas

1. **Establecer baseline antes de iniciar ejecucion** — Congelar version 01 con el plan aprobado.
2. **Actualizar avance con frecuencia definida** — Semanal o quincenal segun el proyecto.
3. **No mezclar metodos** — Usar un unico metodo de medicion por nivel de WBS para consistencia.
4. **Validar datos antes de reportar** — Verificar que costes reales esten contabilizados antes de calcular EVM.
5. **Usar hitos para proyectos de construccion** — El metodo de hitos es el mas objetivo para proyectos de ingenieria.
6. **Capacitar a los responsables** — El metodo manual requiere disciplina y comprension de EVM.
7. **Integrar con SAP Analytics Cloud** — Para dashboards EVM en tiempo real.
8. **Archivar versiones de avance mensualmente** — Para trazabilidad del progreso historico.
