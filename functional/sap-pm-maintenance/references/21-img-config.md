# Guias de Configuracion IMG — Plant Maintenance (PM)

Rutas SPRO completas para la configuración del módulo PM en SAP S/4HANA 2023. Organizadas por área funcional, con descripción del impacto de cada nodo de customizing.

---

## 1. Estructuras Organizativas

### 1.1 Planta de Mantenimiento

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > General Data > Define Plant Sections`

**Descripción:** Define las secciones de planta (Planungswerk) que agrupan equipos y ubicaciones técnicas bajo una unidad organizativa de planificación de mantenimiento. Cada sección se asigna a una planta logística.

**Impacto:** Afecta la selección de órdenes de mantenimiento, el listado de equipos en IW38/IW39, y la determinación del responsable de planificación.

**Campos clave:**
| Campo | Descripción |
|-------|-------------|
| WERKS | Planta |
| BEBER | Sección de planta |
| IWERKS | Planta de mantenimiento |

---

### 1.2 Puestos de Trabajo (Work Centers)

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Basic Settings > Maintain Work Centers`

**Descripción:** Los puestos de trabajo PM se configuran con categoría PM (normalmente 0006). Definen la capacidad disponible de técnicos, costes por hora y fórmulas de programación.

**Impacto:** Determina la disponibilidad de capacidad visible en CM01/CM21, el cálculo de costes internos en las órdenes, y la asignación de operaciones en la hoja de ruta.

**Transacciones relacionadas:** IR01 (crear), IR02 (modificar), IR03 (visualizar)

---

### 1.3 Grupos de Planificadores de Mantenimiento

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Maintenance Planning > Define Maintenance Planner Groups`

**Descripción:** Agrupa los planificadores responsables de un conjunto de objetos técnicos o planes de mantenimiento. Se asigna a los planes de mantenimiento y puntos de medida.

**Impacto:** Filtro principal en IP10 (lista de planes), IW38 (selección de órdenes), y determinación del responsable en el flujo de aprobación.

---

## 2. Objetos Técnicos — Datos Maestros

### 2.1 Tipos de Objetos Técnicos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > General Data > Define Object Types`

**Descripción:** Clasifica equipos (EQUI) y ubicaciones técnicas (IFLOT) según su función: ANLAGE (instalación), MSCHINE (máquina), FAHRZG (vehículo), etc.

**Impacto:** Controla qué vistas están disponibles en IE01/IL01 y qué categorías de equipos pueden crearse.

---

### 2.2 Categorías de Equipos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Equipment > Define Equipment Categories`

**Descripción:** Las categorías de equipos determinan el tipo de dato maestro (instancia de objeto de negocio). Categorías estándar: 0 (general), F (vehiculo), I (instrumento de medición), J (sistema de red).

**Impacto:** Define los campos visibles en IE01, la integración con módulos (FI-AA para activos fijos, QM para calibración), y el tipo de orden predeterminado.

**Tabla de configuración:** T370K

---

### 2.3 Estructura de Ubicaciones Técnicas

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Functional Locations > Define Category of Functional Location`

**Descripción:** Define la estructura jerárquica de las ubicaciones técnicas (separador de niveles, longitud de cada nivel). Ejemplo: `PP-01-B-003` (Planta-Sistema-Subsistema-Posición).

**Impacto crítico:** Una vez definido el separador de estructura, NO se puede modificar sin migración de datos completa. Debe decidirse antes de cualquier go-live.

**Configuración clave:**
```
Separador: - (guion)
Niveles: 4
Longitud por nivel: 2-2-1-3
Resultado: AB-01-A-001
```

---

### 2.4 Categorías de Ubicación Técnica

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Functional Locations > Define Category of Functional Location`

**Descripción:** Similar a las categorías de equipo, controla las vistas disponibles en IL01 y la integración con otros módulos.

---

### 2.5 Clase y Características

**Ruta SPRO:**
`Cross-Application Components > Classification System > Classes > Maintain Object Types and Class Types`

**Descripción:** Para PM se usan principalmente las clases de tipo 002 (equipos) y 003 (ubicaciones técnicas). Las características permiten almacenar atributos técnicos como potencia, presión, temperatura.

**Impacto:** Habilita la búsqueda de objetos por características técnicas en IH08 (estructura de equipo) y clasificación masiva.

---

## 3. Catalogos y Codigos

### 3.1 Grupos de Catálogos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Catalogs > Define Catalog Profile`

**Descripción:** Los catálogos PM se usan en avisos y órdenes para clasificar síntomas, causas, actividades y partes del objeto. Se agrupan en perfiles de catálogo.

**Catálogos estándar:**
| Catálogo | Tipo | Descripción |
|----------|------|-------------|
| 0002 | Tipo de daño | Síntomas observados |
| 0003 | Causa del daño | Causa raíz |
| 0004 | Actividad | Trabajo realizado |
| 0005 | Parte del objeto | Componente afectado |
| B | Evaluación de aviso | Valoración |

**Transacción:** QS41 (mantenimiento de catálogos PM)

---

### 3.2 Perfiles de Catálogo

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Catalogs > Define Catalog Profile`

**Descripción:** Asigna qué catálogos están disponibles para cada combinación de tipo de aviso y categoría de objeto. Simplifica la entrada de datos limitando las opciones relevantes.

**Asignación:** Se asigna en el tipo de aviso (ver sección 4.1).

---

## 4. Avisos de Mantenimiento

### 4.1 Tipos de Aviso

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Notification Processing > Notification Types > Define Notification Types`

**Descripción:** Los tipos de aviso controlan el comportamiento del proceso de notificación. Tipos estándar PM: M1 (aviso de avería), M2 (solicitud de mantenimiento), M3 (actividad).

**Configuración por tipo:**
- Perfil de catálogo asignado
- Tipos de orden permitidos para conversión
- Propuesta de estado inicial
- Perfil de pantalla (campos visibles/obligatorios)
- Tipo de socio (responsable, notificador)

**Tabla:** T351

---

### 4.2 Perfiles de Pantalla para Avisos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Notification Processing > Notification Types > Define Screen Templates for Notification Types`

**Descripción:** Controla qué secciones y campos aparecen en la pantalla del aviso (IW21/IW22). Permite simplificar la interfaz para usuarios de planta que solo necesitan informar averías básicas.

---

### 4.3 Causas de Avería y Grupos de Códigos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Catalogs > Edit Codes and Code Groups`

**Descripción:** Define los códigos concretos dentro de cada catálogo. Organización jerárquica: Catálogo > Grupo de códigos > Código.

**Ejemplo:**
```
Catálogo: 0002 (Tipo de daño)
  Grupo: MECAN (Mecánico)
    Código: VIB (Vibración excesiva)
    Código: CORRO (Corrosión)
  Grupo: ELECT (Eléctrico)
    Código: CORTO (Cortocircuito)
```

---

## 5. Ordenes de Mantenimiento

### 5.1 Tipos de Orden PM

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > Order Types > Define Order Types`

**Descripción:** Los tipos de orden controlan el comportamiento completo del proceso de trabajo. Tipos estándar:

| Tipo | Descripción | Uso |
|------|-------------|-----|
| PM01 | Mantenimiento correctivo | Averías no planificadas |
| PM02 | Mantenimiento preventivo | Órdenes de plan |
| PM03 | Mejora de mantenimiento | Proyectos de mejora |
| PM04 | Inspección | Revisiones periódicas |
| PM05 | Copia de seguridad | Backup de configuración |

**Configuración por tipo:**
- Perfil de liquidación
- Perfil de calendario
- Clase de orden (base AUFK)
- Gestión de estado
- Parametrización de componentes
- Datos de control (FI/CO integration)

---

### 5.2 Perfiles de Liquidación de Orden PM

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > Functions and Settings for Order Types > Maintain Settlement Profiles`

**Descripción:** Define las reglas de liquidación de costes de las órdenes PM: receptor permitido (activo fijo, centro de coste, orden CO, WBS), porcentaje máximo, tipo de liquidación (completo/parcial).

**Impacto financiero:** Determina dónde se contabilizan los costes de mantenimiento. Opciones:
- CC → Centro de coste de mantenimiento
- ANL → Activo fijo (capitalización)
- WBS → Proyecto PS

---

### 5.3 Perfiles de Parámetros de Orden

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > Functions and Settings for Order Types > Define Order Type-Dependent Parameters`

**Descripción:** Parámetros que dependen de la combinación tipo de orden + planta:
- Puesto de trabajo responsable por defecto
- Prioridad por defecto
- Perfil de planificación de capacidades
- Tipo de aviso para conversión automática
- Verificación de disponibilidad de componentes

---

### 5.4 Gestión de Estados de Orden

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > Functions and Settings for Order Types > Status Management > Define Status Profile`

**Descripción:** Los estados controlan qué operaciones son permitidas en cada fase del ciclo de vida de la orden.

**Estados del sistema (internos):**
| Estado | Código | Descripción |
|--------|--------|-------------|
| CREA | I0001 | Creado |
| LIBL | I0002 | Liberado |
| GMPS | I0004 | Parcialmente confirmado |
| RÜCK | I0009 | Confirmado completamente |
| ABGS | I0045 | Liquidado técnicamente |
| TABG | I0046 | Cerrado técnicamente |

**Estados de usuario:** Se definen con prefijo U (U0001-U0999) para flujos personalizados como aprobaciones.

---

### 5.5 Prioridades de Orden/Aviso

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Notification Processing > Response Monitoring > Define Priorities`

**Descripción:** Define los niveles de prioridad con sus tiempos de respuesta y reparación requeridos. Se usa para el monitor de tiempo de respuesta (IW28) y los SLAs.

**Ejemplo estándar:**
| Prioridad | Descripción | T. respuesta | T. reparación |
|-----------|-------------|-------------|---------------|
| 1 | Muy alta | 1h | 4h |
| 2 | Alta | 4h | 8h |
| 3 | Media | 24h | 48h |
| 4 | Baja | 72h | 168h |

---

## 6. Planificacion de Mantenimiento

### 6.1 Estrategias de Mantenimiento

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Preventive Maintenance > Scheduling > Define Maintenance Strategies`

**Descripción:** Las estrategias agrupan paquetes de mantenimiento periódico. Cada paquete tiene un ciclo (cada X días, horas, km) y un desplazamiento inicial.

**Tipos de ciclo:**
- Basado en tiempo: cada 30 días
- Basado en contador: cada 500 horas motor
- Basado en fecha: primer lunes de cada mes
- Múltiple: combinación de los anteriores

**Ejemplo estrategia Z_MANT_ANUAL:**
```
Paquete 1: Mensual    → cada 30 días
Paquete 2: Trimestral → cada 90 días
Paquete 3: Semestral  → cada 180 días
Paquete 4: Anual      → cada 365 días
```

---

### 6.2 Tipos de Plan de Mantenimiento

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Preventive Maintenance > Maintenance Plans, Work Centers, Task Lists and PRTs > Define Maintenance Plan Categories`

**Descripción:** Distingue entre planes de mantenimiento single-cycle (un solo ciclo) y de estrategia (múltiples paquetes). También controla si el plan genera órdenes o solicitudes de pedido.

---

### 6.3 Tipos de Lista de Tareas (Task Lists)

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Preventive Maintenance > Maintenance Plans, Work Centers, Task Lists and PRTs > Task Lists > Define Task List Types`

**Descripción:** Las listas de tareas PM pueden ser:
- **IA** (Equipos): asignadas a un equipo específico
- **IP** (Ubicación técnica): asignadas a ubicaciones
- **IB** (General): reutilizables en múltiples objetos

**Configuración:** Control de aprobación, perfil de parámetros operación, uso de PRT (Production Resources/Tools).

---

### 6.4 Programación de Planes

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Preventive Maintenance > Scheduling > Maintain Scheduling Parameters`

**Descripción:** Define cómo se programan los planes: horizonte de apertura (días antes del vencimiento para crear la orden), horizonte de cierre, tolerancia de inicio/fin (%), comportamiento cuando se pasa la fecha.

**Parámetros clave:**
| Parámetro | Descripción | Valor típico |
|-----------|-------------|-------------|
| Horizonte apertura | Días antes de crear orden | 30 días |
| Tolerancia % | Desviación permitida de ciclo | 5% |
| Ajuste | Tomar fecha real confirma. como base | Activo |
| Optimización | Agrupar órdenes próximas | Sí |

---

## 7. Medicion y Contadores

### 7.1 Unidades de Medida para Contadores

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Measuring Points and Measurement Documents > Define Measuring Point Categories`

**Descripción:** Las categorías de puntos de medida definen el tipo de medición: contador (incrementa monotónicamente, ej: horas de operación) o punto de medida (valor actual, ej: temperatura).

**Impacto:** Solo los contadores pueden usarse como base de ciclo en planes de mantenimiento basados en contador.

---

### 7.2 Características de Medición

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Measuring Points and Measurement Documents > Define Characteristics for Measuring Points`

**Descripción:** Vincula los puntos de medida con características del sistema de clasificación para definir unidad de medida, rango de valores aceptables y valores de alerta.

---

## 8. Confirmaciones y CATS

### 8.1 Perfil de Confirmación

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Completion Confirmations > Set Parameters for Order Confirmation`

**Descripción:** Controla el comportamiento de la confirmación de operaciones de orden (IW41/IW42):
- Confirmación final automática al cerrar orden
- Visualización de consumo real vs planificado
- Integración CATS para confirmación masiva
- Contabilización automática de tiempos

---

### 8.2 Integración con CATS (Cross-Application Time Sheet)

**Ruta SPRO:**
`Cross-Application Components > Time Sheet (CATS) > Settings for CATS > CATS > Specify Profile`

**Descripción:** Los perfiles CATS para PM definen qué campos aparecen en la hoja de tiempos (orden, operación, actividad), aprobación del supervisor, transferencia automática a nómina (HR) y costes (CO).

**Transacciones CATS:** CAT2 (entrada de tiempos), CAT3 (visualización), CAT6 (aprobación gestor), CAT7 (transferencia).

---

## 9. Gestion de Materiales en PM

### 9.1 Tipos de Aprovisionamiento en Órdenes

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > General Data > Define Material Availability Check`

**Descripción:** Controla la verificación de disponibilidad de materiales en las órdenes PM: regla de verificación, alcance (solo stock propio, también pedidos), acción cuando no disponible (advertencia/error).

---

### 9.2 Reservas de Material

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > Functions and Settings for Order Types > Inventory Management > Define Movement Types for Goods Movements`

**Descripción:** Los movimientos de mercancías en órdenes PM usan tipos de movimiento estándar:
- 261: Salida para orden (consumo)
- 262: Devolución de orden al almacén
- 653: Devolución de cliente a almacén
- 101: Entrada de mercancías

---

## 10. Liquidacion e Integracion CO-FI

### 10.1 Perfiles de Liquidación

**Ruta SPRO:**
`Controlling > Internal Orders > Actual Postings > Settlement > Maintain Settlement Profiles`

**Descripción:** Las órdenes PM son órdenes internas CO. La liquidación transfiere los costes reales al receptor definido. El perfil controla:
- Tipo de receptor permitido (CC, ANL, PSP, KTR)
- Distribución de costes (completo/parcial/porcentaje)
- Indicador de resultado (para análisis de rentabilidad)

**Impacto en cierre de período:** En el cierre mensual de CO, la transacción KO8G ejecuta la liquidación masiva de órdenes PM abiertas.

---

### 10.2 Clase de Coste para Mantenimiento

**Ruta SPRO:**
`Controlling > Cost Element Accounting > Master Data > Cost Elements > Create Cost Elements Automatically`

**Descripción:** Los costes de mantenimiento se contabilizan en clases de coste primarias (material, servicios externos) y secundarias (confirmaciones de trabajo interno). La configuración PM debe alinear:
- Clase de coste actividad interna (categoria 43)
- Clase de coste para provisiones mantenimiento
- Clase de coste para servicios externos (MM-PM)

---

### 10.3 Integración con Activos Fijos (FI-AA)

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Master Data in Plant Maintenance and Customer Service > Technical Objects > Equipment > Define Equipment Categories`

**Descripción:** La integración equipo-activo fijo permite:
1. Vincular un equipo PM a un activo fijo FI-AA
2. Capitalizar costes de mejora de la orden PM al activo
3. Sincronizar datos (fecha de compra, valor, proveedor)

**Configuración:** En la categoría de equipo, activar campo "Número de inmovilizado". En el perfil de liquidación, permitir receptor tipo ANL (activo fijo).

---

## 11. Integraciones Externas

### 11.1 Integración QM — Inspección de Mantenimiento

**Ruta SPRO:**
`Quality Management > Quality Inspection > Define Inspection Types`

**Descripción:** Los tipos de inspección QM pueden vincularse a órdenes PM para generar lotes de inspección automáticamente al liberar la orden. Tipo de inspección relevante: 14 (inspección mantenimiento).

---

### 11.2 Integración PS — Proyectos de Mantenimiento Mayor

**Ruta SPRO:**
`Project System > Structures > Operative Structures > Work Breakdown Structure > Define Validation and Substitution`

**Descripción:** Para trabajos de mantenimiento mayor (overhaul), se puede crear una estructura WBS (PS) y asignar órdenes PM como elementos de red. Los costes PM se liquidan a la WBS.

**Flujo:**
```
WBS Element (PS)
  └── PM Order → Liquida → WBS → Capitaliza → Activo FI-AA
```

---

### 11.3 Integración MM — Pedidos de Servicios Externos

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Maintenance and Service Orders > External Processing > Define Profiles for External Processing`

**Descripción:** Cuando se necesitan servicios externos en la orden PM, se genera automáticamente una solicitud de pedido (PR) que MM convierte en pedido. El perfil de procesamiento externo controla:
- Tipo de pedido generado
- Organización de compras
- Tipo de imputación (F = orden)
- Verificación de entrada de servicio (ML81N)

---

## 12. Configuracion de Interaccion Usuario

### 12.1 Variantes de Pantalla

**Ruta SPRO:**
`Plant Maintenance and Customer Service > Maintenance and Service Processing > Notification Processing > Notification Types > Define Screen Templates for Notification Types`

**Descripción:** Las variantes de pantalla simplifican la interfaz eliminando campos no relevantes para el tipo de usuario (operador de planta vs planificador vs técnico de campo).

---

### 12.2 Perfiles de Autorización PM

**Transacciones de administración de autorizaciones:**
- SU21: Mantener objetos de autorización
- SU24: Comprobar valores propuestos de autorizaciones
- PFCG: Mantenimiento de roles

**Objetos de autorización clave PM:**
| Objeto | Descripción |
|--------|-------------|
| I_IWERK | Planta de mantenimiento |
| I_INGRP | Grupo de planificadores |
| I_BEBER | Sección de planta |
| I_AUFTYP | Tipo de orden PM |
| I_AUART | Tipo de aviso |

---

## Referencias Rapidas de Transacciones de Customizing

| Transacción | Descripción |
|-------------|-------------|
| SPRO | Acceso general al árbol IMG |
| OIOD | Tipos de orden mantenimiento |
| QISRSD | Perfiles catálogo PM |
| OIS5 | Estrategias mantenimiento |
| OIS1 | Tipos de plan de mantenimiento |
| OIP8 | Perfiles de programación |
| OIB1 | Tipos de ubicación técnica |
| OIOF | Tipos de aviso PM |
| OI8B | Perfiles de liquidación PM |

---

*Referencia: SAP S/4HANA 2023 — Plant Maintenance Configuration Guide*
*Documentación oficial: help.sap.com/docs/SAP_S4HANA_ON-PREMISE/2023*
