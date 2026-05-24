# Estructura Organizativa PM — SAP Plant Maintenance S/4HANA 2023

## 1. Introducción

La estructura organizativa de SAP PM define el marco en el que se planifica, ejecuta y controla el mantenimiento de activos. Una configuración correcta es prerequisito para que los procesos de avisos, órdenes, planes y confirmaciones funcionen de forma integrada con CO, MM y FI.

---

## 2. Elementos Organizativos Principales

### 2.1 Centro (Plant — WERKS)

El centro es la unidad organizativa central de PM. Todo equipo y ubicación técnica pertenece a un centro.

- Representa una planta de producción, almacén o instalación física.
- Se asigna a una sociedad (Company Code) en FI.
- Puede tener uno o varios **centros de planificación de mantenimiento** asociados.

**Tabla:** `T001W`

| Campo  | Descripción                        |
|--------|------------------------------------|
| WERKS  | Centro (Plant)                     |
| NAME1  | Descripción del centro             |
| BUKRS  | Sociedad asignada                  |
| IWERK  | Centro planificación mantenimiento |

**Transacción:** OX10 (crear/modificar centros)

---

### 2.2 Centro de Planificación de Mantenimiento (Maintenance Planning Plant — IWERK)

El centro de planificación de mantenimiento (CPM) es la unidad responsable de la planificación del trabajo de mantenimiento. Puede planificar para uno o varios centros de ejecución.

Características clave:
- Define dónde se realizan la creación de planes de mantenimiento y hojas de ruta.
- Los puestos de trabajo de mantenimiento se asignan al CPM.
- Un mismo CPM puede servir a múltiples centros ejecutores.
- La asignación centro ejecutor ↔ CPM se define en customizing.

**Tabla:** `T024I`

| Campo  | Descripción                            |
|--------|----------------------------------------|
| IWERK  | Centro de planificación mantenimiento  |
| INAME  | Descripción del CPM                    |
| BUKRS  | Sociedad                               |
| WAERS  | Moneda                                 |

**SPRO:** IMG → Mantenimiento de planta → Estructura organizativa → Definir centro planificación mantenimiento

**Transacción:** OIOA

---

### 2.3 Asignación CPM — Centro Ejecutor

Un CPM puede ser responsable de planificar el mantenimiento de equipos en varios centros ejecutores. Esta relación se define explícitamente.

**SPRO Path:** IMG → PM → Estructura organizativa → Asignar centros de planificación a centros

**Tabla de asignación:** `T001W` campo `IWERK`

---

### 2.4 Grupo Planificador (Planner Group — INGRP)

El grupo planificador es el responsable funcional de la planificación del mantenimiento dentro del CPM. Identifica al equipo o persona responsable de una orden o aviso.

- Agrupa planificadores con responsabilidades similares.
- Permite filtrar y gestionar cargas de trabajo por responsable.
- Se asigna en cabecera de avisos y órdenes PM.

**Tabla:** `T024I` (vinculada al CPM)

**SPRO Path:** IMG → PM → Estructura organizativa → Definir grupos planificadores

**Transacción:** OIP1

| Campo  | Descripción              |
|--------|--------------------------|
| IWERK  | CPM al que pertenece     |
| INGRP  | Clave grupo planificador |
| INNAM  | Descripción              |
| PERNR  | Número de personal       |

---

### 2.5 Puesto de Trabajo de Mantenimiento (Work Center — ARBPL)

El puesto de trabajo (PdT) representa el recurso ejecutor del mantenimiento: un taller, una cuadrilla, un técnico o un contratista.

Características:
- Se define con capacidades, calendarios de trabajo y fórmulas de planificación.
- Sirve de base para calcular fechas y cargas en las operaciones de órdenes PM.
- Se asigna a un área de valoración para integración de costes con CO.
- Puede ser de tipo **interno** (propio) o **externo** (subcontratación).

**Tablas clave:**

| Tabla | Descripción                                 |
|-------|---------------------------------------------|
| CRHD  | Cabecera de puesto de trabajo               |
| CRCA  | Asignación de capacidades                   |
| CRTX  | Textos de puesto de trabajo                 |
| KAKO  | Cabecera de capacidad                       |

**Transacción:** IR01 (crear puesto trabajo), IR02 (modificar), IR03 (visualizar)

**Campos clave en CRHD:**

| Campo  | Descripción                          |
|--------|--------------------------------------|
| ARBPL  | Clave puesto de trabajo              |
| WERKS  | Centro                               |
| VERWE  | Uso (001 = Mantenimiento de planta)  |
| KOSTL  | Centro de coste asignado             |
| LSTAR  | Tipo de actividad (para CO)          |

**SPRO:** IMG → PM → Estructura organizativa → Puestos de trabajo → Definir categorías de puestos de trabajo

---

## 3. Tipos de Orden PM

Los tipos de orden controlan el comportamiento de las órdenes de mantenimiento: perfil, clase de liquidación, tipo de orden CO, rangos de números, etc.

### Tipos de Orden Estándar SAP PM

| Tipo   | Descripción                            |
|--------|----------------------------------------|
| PM01   | Mantenimiento correctivo               |
| PM02   | Mantenimiento preventivo               |
| PM03   | Inspección                             |
| PM04   | Reparación                             |
| PM05   | Reconocimiento/revisión general        |
| PM06   | Garantía/reclamación                   |
| PM10   | Refabricación (Refurbishment)          |

Cada tipo de orden se configura con:
- Perfil de orden (parámetros por defecto para planificación)
- Clase de orden CO (para acumulación de costes)
- Regla de liquidación por defecto (a CC, activo fijo, etc.)
- Control de status
- Rangos de números

**SPRO:** IMG → PM → Órdenes de mantenimiento → Funciones y parámetros de configuración → Definir tipos de órdenes

**Transacción:** OIW1 (tipos de orden), BS33 (perfiles de status)

---

## 4. Tipos de Aviso PM

Los avisos registran problemas, necesidades de mantenimiento o actividades realizadas.

### Tipos de Aviso Estándar

| Tipo | Descripción                     |
|------|---------------------------------|
| M1   | Aviso de avería                 |
| M2   | Aviso de actividad de mantenimiento |
| M3   | Aviso de solicitud de actividad |

Los avisos se configuran con:
- Catalogos de daños, causas y actividades
- Perfil de aviso (campos obligatorios, visualización)
- Rangos de números
- Tipos de orden generados automáticamente

**SPRO:** IMG → PM → Avisos de mantenimiento → Funciones de sistema y configuración → Definir tipos de avisos

**Transacción:** QP40 (catálogos), OIOZ (perfiles de aviso)

---

## 5. Rangos de Números

Cada objeto PM (avisos, órdenes, planes, posiciones, etc.) requiere rangos de números configurados.

### Avisos PM

**Transacción:** OION (rangos de números para avisos PM)

| Intervalo | Tipo   | Rango Desde  | Rango Hasta  |
|-----------|--------|--------------|--------------|
| 12        | M1     | 100000000    | 199999999    |
| 13        | M2     | 200000000    | 299999999    |
| 14        | M3     | 300000000    | 399999999    |

### Órdenes PM

**Transacción:** OIOA → Rangos de números para tipos de orden

Los rangos se asignan al tipo de orden PM mediante el parámetro de rango de números interno/externo.

### Planes de Mantenimiento

**Transacción:** IP59 (rangos para planes), IP60 (rangos para posiciones)

---

## 6. Perfiles de Orden

El perfil de orden define los valores por defecto que se proponen al crear una orden PM.

Parámetros configurables en el perfil de orden:
- Tipo de orden por defecto
- Centro de planificación
- Grupo planificador
- Puesto de trabajo principal
- Clase de prioridad
- Perfil de capacidad
- Perfil de valoración
- Control de costes

**SPRO:** IMG → PM → Órdenes de mantenimiento → Funciones y parámetros de configuración → Definir perfiles de orden

**Transacción:** OIW2

---

## 7. Perfiles de Aviso

El perfil de aviso controla qué campos son visibles, obligatorios o de solo lectura en la pantalla de aviso.

Configuración incluye:
- Campos de cabecera (descripción, prioridad, fechas)
- Visibilidad de pestañas (daños, causas, actividades, tareas)
- Campos de ubicación técnica / equipo
- Integración con órdenes

**SPRO:** IMG → PM → Avisos de mantenimiento → Funciones de sistema y configuración → Definir perfiles de aviso

---

## 8. Integración con Áreas CO

### 8.1 Sociedad → Área de Controlling

Toda la organización PM se integra con CO a través de la cadena:

```
Centro (WERKS) → Sociedad (BUKRS) → Área de Controlling (KOKRS)
```

Los costes de órdenes PM se acumulan en la clase de orden CO correspondiente y se liquidan al objeto receptor (centro de coste, activo fijo, WBS, etc.).

### 8.2 Puesto de Trabajo → Centro de Coste

El puesto de trabajo PM se vincula a un **centro de coste** y un **tipo de actividad**. Esto permite:
- Valorar internamente el tiempo de los técnicos.
- Cargar automáticamente costes de mano de obra a la orden PM.
- Liquidar correctamente a CO.

**Campo clave:** `CRHD-KOSTL` (CC del puesto de trabajo)

### 8.3 Tipos de Actividad (Activity Types)

Para cada puesto de trabajo se definen tipos de actividad que representan las horas de trabajo:

| Tipo Actividad | Descripción              |
|----------------|--------------------------|
| PM-MOD         | Mano de obra mantenimiento |
| PM-EXT         | Trabajos externos        |
| PM-ESP         | Trabajo especializado    |

**Transacción:** KL01 (crear tipo actividad), KP26 (planificar precio)

---

## 9. Área de Mantenimiento vs. Área de Valoración

### Área de Mantenimiento (Maintenance Plant)

Es el centro en el que se encuentran físicamente los equipos. Determina:
- El almacén para la reserva de materiales.
- El puesto de trabajo ejecutor.

### Área de Valoración (Valuation Area)

En S/4HANA, la valoración de stocks se realiza siempre a nivel de centro. El área de valoración coincide con el centro (WERKS). Esto impacta en:
- Valoración de componentes de materiales en órdenes PM.
- Integración con MM y FI para consumos.

---

## 10. Profit Center y Segment en PM

Desde S/4HANA, los equipos y ubicaciones técnicas pueden tener asignado un **Profit Center** directamente. Esto permite:
- Análisis de costes de mantenimiento por línea de negocio.
- Reportes en ACDOCA por segmento.

La asignación se realiza en:
- Datos organizativos del equipo (IE02 → pestaña Organización)
- Datos de la ubicación técnica (IL02 → pestaña Organización)

**Tablas:** `ILOA` (datos de ubicación de equipo/UT), campo `PRCTR`

---

## 11. Calendario de Planificación

Los calendarios de planificación definen los días laborables para calcular fechas de mantenimiento preventivo y capacidad.

**Transacción:** SCAL (administración de calendarios de fábrica)

Cada centro puede tener asignado un calendario que afecta:
- Programación de planes de mantenimiento.
- Capacidad de puestos de trabajo.
- Fechas de inicio/fin de operaciones en órdenes.

---

## 12. Tabla Resumen de Customizing PM — Estructura Organizativa

| Concepto                          | Transacción | Tabla       |
|-----------------------------------|-------------|-------------|
| Definir CPM                       | OIOA        | T024I       |
| Definir grupo planificador        | OIP1        | T024I       |
| Asignar CPM a centros             | SPRO        | T001W       |
| Tipos de aviso PM                 | OIOZ        | T352 / QMKA |
| Tipos de orden PM                 | OIW1        | T003        |
| Perfiles de orden                 | OIW2        | OIAB        |
| Rangos de números avisos          | OION        | NRIV        |
| Puesto de trabajo (crear)         | IR01        | CRHD / CRCA |
| Calendarios de fábrica            | SCAL        | TFACD       |
| Tipos de actividad CO             | KL01        | CSLA        |

---

## 13. Consultas MCP Útiles (GetSqlQuery)

### Obtener todos los CPM y su sociedad

```sql
SELECT iwerk, iname, bukrs, waers
FROM t024i
ORDER BY iwerk
```

### Obtener centros y su CPM asignado

```sql
SELECT werks, name1, bukrs, iwerk
FROM t001w
WHERE iwerk IS NOT NULL
ORDER BY werks
```

### Obtener puestos de trabajo de mantenimiento

```sql
SELECT a.arbpl, a.werks, a.kostl, a.lstar, b.ktext
FROM crhd a
LEFT JOIN crtx b ON a.objid = b.objid AND b.spras = 'S'
WHERE a.verwe = '001'
ORDER BY a.werks, a.arbpl
```

### Obtener grupos planificadores por CPM

```sql
SELECT iwerk, ingrp, innam
FROM t024i
WHERE ingrp IS NOT NULL
ORDER BY iwerk, ingrp
```

---

## 14. Fiori Apps Relevantes — Estructura Organizativa

| App ID       | Nombre                                         | Rol                    |
|--------------|------------------------------------------------|------------------------|
| F1612        | Manage Maintenance Plants                      | Administrador PM       |
| F2229        | Manage Work Centers                            | Planificador PM        |
| F3349        | Configure Plant Maintenance Organization       | Customizing PM         |

---

## 15. Buenas Prácticas — Estructura Organizativa PM

1. **Un CPM por área de responsabilidad:** Separar CPMs por zona geográfica, tipo de activo o especialidad (mecánica, eléctrica, civil).

2. **Grupos planificadores bien definidos:** Reflejan la estructura real del equipo de mantenimiento; facilitan filtrado de cargas de trabajo y KPIs.

3. **Puestos de trabajo vinculados a CCs correctos:** Es el único mecanismo para valorar internamente el trabajo de mantenimiento en CO. Un error aquí genera costes en centros incorrectos.

4. **Tipos de orden coherentes con política de mantenimiento:** No mezclar correctivo y preventivo en el mismo tipo de orden; dificulta el análisis de KPIs (MTTR, MTBF).

5. **Rangos de números externos reservados:** Definir siempre un rango externo para migraciones/cargas masivas de datos históricos.

6. **Calendarios de planta actualizados:** Los días festivos no configurados generan fechas incorrectas en la programación de mantenimiento preventivo.
