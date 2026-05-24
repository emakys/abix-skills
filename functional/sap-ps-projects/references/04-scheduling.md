# Programacion y Fechas — SAP PS S/4HANA 2023

## 1. Concepto de Programacion en PS

La programacion (Scheduling) en SAP PS calcula automaticamente las fechas de inicio y fin de todas las actividades de una red, basandose en sus duraciones, relaciones logicas y el calendario de trabajo. Utiliza el metodo CPM (Critical Path Method / Metodo del Camino Critico).

### Tipos de Fechas en PS

| Tipo | Descripcion | Origen |
|---|---|---|
| Fechas basicas | Fechas manuales de referencia del proyecto | Manual (usuario) |
| Fechas pronosticadas | Calculadas por la programacion | CPM / Scheduling |
| Fechas reales | Registradas al confirmar actividades | Confirmacion |
| Fechas del sistema | Calculadas por el sistema para control | Automatico |

---

## 2. Metodo CPM — Critical Path Method

El CPM es el algoritmo de programacion utilizado en las redes PS. Calcula:

1. **Early Start / Early Finish**: La fecha mas temprana posible de inicio y fin de cada actividad (calculo hacia adelante / Forward Pass)
2. **Late Start / Late Finish**: La fecha mas tardia tolerable de inicio y fin (calculo hacia atras / Backward Pass)
3. **Holgura Total (Float)**: LS - ES = margen de tiempo antes de que la actividad afecte al proyecto
4. **Camino Critico**: Cadena de actividades con holgura cero. Un retraso en cualquiera de ellas retrasa la fecha fin del proyecto

### Calculo Forward Pass (Hacia Adelante)

```
Para cada actividad, considerando sus predecesoras:
Early Finish = Early Start + Duracion
Early Start de sucesora = MAX(Early Finish de todas las predecesoras)
```

### Calculo Backward Pass (Hacia Atras)

```
Comenzando desde la fecha fin del proyecto:
Late Start = Late Finish - Duracion
Late Finish de predecesora = MIN(Late Start de todas las sucesoras)
```

### Holgura

```
Holgura Total = Late Start - Early Start
             = Late Finish - Early Finish

Holgura = 0 → Actividad en el Camino Critico
```

---

## 3. Estrategias de Programacion

### 3.1 Programacion Hacia Adelante (Forward Scheduling)

La red se programa comenzando desde la fecha de inicio mas temprana posible. El resultado es la fecha de fin mas temprana del proyecto.

**Uso tipico:** Cuando la fecha de inicio esta fijada y queremos calcular el fin.

```
Fecha inicio fija → calculo hacia adelante → Fecha fin calculada
```

### 3.2 Programacion Hacia Atras (Backward Scheduling)

La red se programa comenzando desde la fecha de fin requerida y calculando hacia atras. El resultado son las fechas de inicio mas tardias para cumplir el plazo.

**Uso tipico:** Cuando existe un plazo de entrega fijo (deadline) y queremos saber cuando hay que empezar.

```
Fecha fin requerida → calculo hacia atras → Fecha inicio necesaria
```

### Configuracion de Estrategia

La estrategia de programacion se define en el perfil de red:

```
SPRO → Project System → Estructuras → Redes →
Definir Perfil de Red → campo "Estrategia programacion"
Valores: 1=Forward, 2=Backward, 3=Hacia fecha planificada
```

---

## 4. Ejecucion de la Programacion

### Programacion Manual desde CJ20N

```
CJ20N → seleccionar proyecto → menu Proyecto → Programar
O bien: CJ20N → icono Programar en barra de herramientas
```

Resultado: el sistema actualiza las fechas pronosticadas de todas las actividades y WBS del proyecto.

### Programacion Colectiva

```
Transaccion: CJ7M (programacion masiva de proyectos)
Permite programar multiples proyectos en un solo paso
Util para actualizacion periodica del cronograma
```

### Parametros de la Programacion

| Parametro | Descripcion |
|---|---|
| Tipo de programacion | Forward / Backward / Hacia fecha |
| Fecha de inicio | Para Forward scheduling |
| Fecha de fin | Para Backward scheduling |
| Reduccion | Si se permite reducir duraciones |
| Calendario | Calendario de fabrica/trabajo utilizado |
| Actualizar fechas | Si se actualizan fechas basicas |

---

## 5. Fechas en la Definicion de Proyecto y WBS

### Tabla PRPS — Campos de Fechas WBS

| Campo | Descripcion |
|---|---|
| PLFAZ | Fecha inicio plan (basica) |
| PLSEZ | Fecha fin plan (basica) |
| FSTAZ | Fecha inicio pronosticada |
| FSLEZ | Fecha fin pronosticada |
| ISTAD | Fecha inicio real |
| ISTED | Fecha fin real |
| PSTAZ | Fecha inicio mas temprana (Early Start) |
| PSLED | Fecha fin mas tardia (Late Finish) |

### Tabla AFVC — Campos de Fechas de Actividad

| Campo | Descripcion |
|---|---|
| NPLDA | Fecha inicio schedulada (resultado CPM) |
| NPLDS | Fecha fin schedulada |
| FTRMS | Fecha inicio pronosticada |
| FTRMI | Fecha fin pronosticada |
| ISTAZ | Fecha inicio real (de confirmacion) |
| ISTA2 | Fecha fin real |
| FSAVD | Fecha inicio mas temprana (Early Start) |
| FSAVZ | Fecha fin mas temprana (Early Finish) |
| FSSPT | Fecha inicio mas tardia (Late Start) |
| FSSPE | Fecha fin mas tardia (Late Finish) |

### Tabla AFVV — Duracion y Valores

| Campo | Descripcion |
|---|---|
| DAUNO | Duracion normal |
| DAUNE | Unidad de duracion (TAG=dia, STD=hora) |
| DAUER | Duracion reducida |
| PUFFER | Holgura total calculada |

---

## 6. Holguras y Buffer

### Tipos de Holgura

| Tipo | Descripcion |
|---|---|
| Holgura total (Total Float) | Margen antes de que afecte al fin del proyecto |
| Holgura libre (Free Float) | Margen antes de que afecte al inicio del sucesor |
| Holgura de proyecto | Diferencia entre fin calculado y fin requerido |

### Interpretacion

```
Holgura = 0        → Actividad critica (en el camino critico)
Holgura > 0        → Actividad no critica, tiene margen
Holgura < 0        → Proyecto RETRASADO, sin margen suficiente
```

### Buffer entre Actividades

Se puede definir un buffer de tiempo en las relaciones entre actividades:

```
Relacion FS con buffer +5 dias:
Actividad A termina el dia 10 → Actividad B empieza el dia 15 (no el 11)
```

El buffer puede ser positivo (espera) o negativo (solapamiento / lead time).

---

## 7. Reduccion de Duracion

La reduccion permite acortar la duracion de una actividad cuando el proyecto esta retrasado, asignando mas recursos.

### Configuracion SPRO

```
SPRO → Project System → Programacion → Definir Reduccion
Transaccion: OPP5
```

### Niveles de Reduccion

Los niveles de reduccion (1-4) se definen en el puesto de trabajo y determinan cuanto se puede reducir la duracion:

| Nivel | Factor de reduccion | Recursos adicionales |
|---|---|---|
| 1 | 100% (sin reduccion) | Normal |
| 2 | 75% de la duracion original | +33% recursos |
| 3 | 50% de la duracion original | +100% recursos |
| 4 | 25% de la duracion original | +300% recursos |

---

## 8. Nivelacion de Capacidad

Cuando las actividades scheduladas generan picos de carga superiores a la capacidad disponible, se puede realizar una nivelacion de capacidad.

### Transacciones de Capacidad

| Transaccion | Descripcion |
|---|---|
| CM01 | Evaluacion de capacidad por centro de trabajo |
| CM21 | Nivelacion de capacidad interactiva |
| CM25 | Nivelacion de capacidad tabla |
| CN49 | Analisis de capacidad en PS |
| MF50 | Tabla de planificacion (para fabricacion) |

### Tipos de Nivelacion

| Tipo | Descripcion |
|---|---|
| Infinita | Sin restriccion de capacidad (solo planificacion) |
| Finita | Respeta capacidad disponible del puesto |
| Manual | El planificador mueve actividades manualmente |

### Proceso de Nivelacion

```
1. Programar red (CPM)
2. CM01 → visualizar carga vs capacidad por puesto
3. Identificar picos de sobrecarga
4. CM21 → nivelacion interactiva: mover actividades dentro de su holgura
5. Reprogramar
6. Verificar nuevo estado de capacidad
```

---

## 9. Programacion de WBS vs Red

### Relacion entre Fechas WBS y Fechas de Red

Las fechas del WBS se derivan de las fechas de las actividades de red asignadas:

```
WBS fecha inicio = MIN(fecha inicio de todas las actividades del WBS)
WBS fecha fin    = MAX(fecha fin de todas las actividades del WBS)
```

Si no hay red asignada, las fechas del WBS se gestionan manualmente en PRPS.

### Programacion de WBS sin Red

Para proyectos donde solo se usa WBS (sin redes de actividades), las fechas se gestionan directamente en el elemento WBS:

```
CJ20N → seleccionar WBS → ficha "Datos basicos" → fechas manual
```

Este enfoque es comun en proyectos administrativos o de control de costes sin necesidad de gestion detallada de actividades.

---

## 10. Calendario de Trabajo en Programacion

El calendario de trabajo define los dias habiles y horarios. La programacion PS respeta el calendario al calcular fechas.

### Tipos de Calendario

| Tipo | Aplicacion |
|---|---|
| Calendario de fabrica (WORKCAL) | Para centros de produccion |
| Calendario de proyecto | Para proyectos con jornada especifica |
| Calendario de puesto | Para recursos individuales |

### Configuracion SPRO

```
SPRO → Tiempo libre → Gestionar calendarios de fabrica
Transaccion: SCAL
```

El calendario se asigna en el perfil de red y en los puestos de trabajo (ARBPL) utilizados en las actividades.

---

## 11. Fechas de Hitos

Los hitos tienen su propia fecha, independiente de la actividad a la que pertenecen.

```
Actividad 0020: Inicio 01.04 - Fin 30.04
Hito "Entrega Prototipo":
  - Fecha programada: 30.04 (fin de la actividad)
  - Al confirmar: MLDAT = fecha real de confirmacion
```

### Seguimiento de Hitos

```
Transaccion: CN60 → Evaluacion de hitos de proyecto
Muestra todos los hitos con fecha planificada vs real
Identifica hitos vencidos no confirmados
```

---

## 12. Consultas SQL/MCP de Programacion

```javascript
// Actividades con fechas y holgura calculada
GetSqlQuery({
  query: `SELECT v.VORNR, v.LTXA1,
                 v.NPLDA AS INI_SCHEDULE,
                 v.NPLDS AS FIN_SCHEDULE,
                 v.FTRMS AS INI_PRONOSTICO,
                 v.FTRMI AS FIN_PRONOSTICO,
                 v.ISTAZ AS INI_REAL,
                 v.ISTA2 AS FIN_REAL,
                 v.DAUNO AS DURACION, v.DAUNE,
                 v2.PUFFER AS HOLGURA
          FROM AFVC v
          INNER JOIN AFVV v2 ON v2.AUFPL = v.AUFPL AND v2.APLZL = v.APLZL
          INNER JOIN AFKO k ON k.AUFPL = v.AUFPL
          WHERE k.AUFNR = '000012345678'
          ORDER BY v.NPLDA`
})

// Camino critico: actividades con holgura cero
GetSqlQuery({
  query: `SELECT v.VORNR, v.LTXA1,
                 v.NPLDA, v.NPLDS,
                 v2.PUFFER AS HOLGURA,
                 v2.DAUNO AS DURACION
          FROM AFVC v
          INNER JOIN AFVV v2 ON v2.AUFPL = v.AUFPL AND v2.APLZL = v.APLZL
          INNER JOIN AFKO k ON k.AUFPL = v.AUFPL
          WHERE k.PSPEL IN (
            SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUM_PROYECTO'
          )
            AND v2.PUFFER = 0
          ORDER BY v.NPLDA`
})

// Hitos pendientes de confirmacion
GetSqlQuery({
  query: `SELECT m.MEILNR, m.MLNAM, m.MLDAT AS FECHA_PLAN,
                 v.VORNR, v.LTXA1,
                 k.AUFNR
          FROM AFMG m
          INNER JOIN AFVC v ON v.AUFPL = m.AUFPL AND v.APLZL = m.APLZL
          INNER JOIN AFKO k ON k.AUFPL = v.AUFPL
          WHERE m.MLDAT <= CURRENT_DATE
            AND m.MLKTR = ' '  -- no confirmado
          ORDER BY m.MLDAT`
})

// Fechas de WBS con desviacion
GetSqlQuery({
  query: `SELECT w.POSID, w.POST1,
                 w.PLFAZ AS INI_BASE, w.PLSEZ AS FIN_BASE,
                 w.FSTAZ AS INI_PRONOSTICO, w.FSLEZ AS FIN_PRONOSTICO,
                 w.ISTAD AS INI_REAL,
                 DAYS_BETWEEN(w.PLSEZ, w.FSLEZ) AS DESVIACION_DIAS
          FROM PRPS w
          WHERE w.PBUKR = '1000'
            AND w.PSPNR IN (SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUM_PROYECTO')
          ORDER BY w.POSID`
})
```

---

## 13. Reportes de Programacion

| Transaccion | Descripcion |
|---|---|
| CN60 | Evaluacion de hitos |
| CN41 | Estructura de proyecto con fechas |
| CJ2B | Fechas de proyecto |
| CJ2C | Plan de fechas del proyecto |
| S_ALR_87013537 | Analisis de fechas del proyecto |

### Fiori Apps de Programacion

| App ID | Descripcion |
|---|---|
| F2389 | Project Cockpit (cronograma Gantt integrado) |
| F3423 | Gantt Chart for Projects |
| F4567 | Monitor Project Schedule |

---

## 14. Mejores Practicas de Programacion

1. **Siempre usar calendarios reales**: Configurar el calendario de fabrica/proyecto con festivos y jornadas laborales reales para evitar que el CPM calcule fechas en dias no laborables.

2. **Definir relaciones logicas completas**: Una red sin relaciones entre actividades no permite el calculo del camino critico. Todas las actividades deben estar conectadas en la red.

3. **Revisar el camino critico periodicamente**: En cada actualizacion del cronograma, identificar el camino critico y gestionar proactivamente las actividades criticas.

4. **Usar holgura como indicador de riesgo**: Actividades con holgura menor a 5 dias en proyectos largos deben ser monitorizadas aunque no sean criticas.

5. **Programacion hacia atras en proyectos con deadline**: Cuando existe una fecha de entrega contractual, usar backward scheduling para identificar la fecha de inicio necesaria.

6. **Separar fechas basicas de pronosticadas**: Las fechas basicas son el contrato (no cambian sin aprobacion formal). Las pronosticadas reflejan la realidad del proyecto.
