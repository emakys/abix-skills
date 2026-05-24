# Customizing Overview HCM

Referencia de rutas SPRO y configuración principal para los módulos HCM en SAP S/4HANA 2023.

## Rutas SPRO Principales

### Administración de Personal (PA)
- `SPRO > Gestión de Personal > Administración de Personal > Datos maestros`
- Configuración de infotipos: grupos de infotipos, pantallas, controles de campo
- Definición de rangos de números para números de personal
- Asignación de acciones de personal (contratación, cambio, baja)
- `V_T529A` — Tipos de acciones de personal
- `V_T529` — Grupos de acciones de personal
- `V_T500P` — Parámetros de país (Molga)

### Gestión Organizativa (OM)
- `SPRO > Gestión de Personal > Gestión organizativa > Ajustes básicos`
- Tipos de objeto (S, O, P, C, T, US)
- Tipos de relación y reglas de restricción
- Plan de puestos de trabajo: versiones y estados
- Evaluaciones de puestos (Jobs vs Positions)
- `T77S0` — Switches globales del sistema OM

### Gestión de Tiempos (TM)
- `SPRO > Gestión de Personal > Gestión de tiempos`
- Tipos de ausencias y presencias (V_T554S)
- Reglas de cómputo de tiempos
- Calendarios de festivos y horarios de trabajo (V_T508A)
- Modelos de horario (V_T551A, V_T551C)
- Agrupaciones de empleados para gestión de tiempos
- Evaluación de tiempos: esquemas y reglas (TM04, driver RPTIME00)

### Nómina (PY)
- `SPRO > Gestión de Personal > Nómina`
- Áreas de nómina y períodos de nómina (V_T549A, V_T549Q)
- Esquemas de nómina por país (p.ej. DE_00, US_00, ES_00)
- Clases de cotización y conceptos de nómina (V_T511)
- Reglas de cálculo de nómina (PE04)
- Configuración de RPCALCX0 (driver de nómina)

---

## Estructura de la Empresa

### Estructura Organizativa de la Empresa
| Elemento | Tabla | Descripción |
|---|---|---|
| Sociedad | T001 | Unidad contable |
| División de personal | T500P | Agrupación de empleados |
| Subdivisión de personal | T001P | Unidad local de RRHH |
| Área de personal | T527X | Agrupación funcional (opcional) |

### Estructura de Personal
| Elemento | Tabla | Descripción |
|---|---|---|
| Grupo de empleados | T501 | Nivel organizativo general |
| Círculo de empleados | T503 | Clasificación funcional |
| Tipo de nómina | T503K | Vinculado al esquema de nómina |

**Ruta SPRO:**
`Estructura de empresa > Definir divisiones de personal / subdivisiones`
`Gestión de Personal > Administración de Personal > Organización > Crear estructura de personal`

---

## Configuración de Features

Las features son funciones de decisión que controlan el comportamiento del sistema según la combinación de parámetros del empleado.

### Features Principales
| Feature | Función |
|---|---|
| NUMKR | Rango de números para número de personal |
| ABKRS | Asignación de área de nómina |
| LGMST | Esquema de retribución predeterminado |
| PINCH | Asignación de asesor de personal |
| VDSK1 | Cálculo de antigüedad |
| PLOGI | Gestión organizativa: activar integración PA-OM |

**Mantenimiento de features:** PE03

---

## Rangos de Números

- `SPRO > Gestión de Personal > Administración de Personal > Datos maestros > Número de personal > Definir rangos de números`
- Transacción PA04 para configurar rangos de números de personal
- Rangos internos (asignación automática) vs externos (asignación manual)
- Feature NUMKR determina el rango según división/subdivisión de personal

---

## Configuración de Infotipos

### Tabla V_T582A — Control de infotipos
Define para cada infotipo:
- Si es obligatorio, opcional o no permitido por grupo/círculo de empleados
- Acceso de tiempo: único, limitado en el tiempo, con historial
- Parámetros de subtipos

### Modificaciones de Pantalla (V_T588M)
- Permite hacer campos obligatorios, opcionales u ocultos por dinamismo
- Dependiente de: grupo de empleados, círculo, división, acción de personal
- Verificación con programa `RPUDYN00`

### Pantallas de Infotipo (PM01)
- Creación de infotipos cliente (9xxx)
- Estructura de tabla de base de datos (Pxxxx)
- Estructura de pantalla (PSxxxx)
- Módulo de función de verificación (MPxxxx00)

---

## Customizing por País

Las rutas de customizing específicas por país siguen el patrón `/xxx` donde `xxx` es el código de país (molga):
- `/001` — Alemania
- `/005` — México
- `/008` — España
- `/010` — Argentina

Ejemplo: `SPRO > Gestión de Personal > Nómina > Nómina para España (/008)`

---

## Acciones Dinámicas (T588Z)

Las acciones dinámicas se ejecutan automáticamente al modificar un infotipo específico.

| Campo | Descripción |
|---|---|
| Infotipo | Infotipo que activa la acción |
| Campo | Campo específico que desencadena (o * para cualquiera) |
| Tiempo | Antes o después de grabar |
| Tipo | Verificación, actualización, mensaje |
| Función | Módulo de función o rutina FORM |

**Transacción de mantenimiento:** SM30 > V_T588Z

Ejemplos de uso:
- Creación automática de IT0009 (banco) al contratar (IT0000)
- Propuesta de IT0007 (horario) según subdivisión
- Validaciones cruzadas entre infotipos

---

## Menús de Infotipos (V_T588B / V_T588C)

Agrupan infotipos en menús para las transacciones PA30/PA40:
- Definición de grupos de menú por tipo de transacción
- Secuencia de infotipos en acciones de personal
- Control de qué infotipos se muestran en cada acción

---

## Objetos de Autorización HR

| Objeto | Campo | Descripción |
|---|---|---|
| P_ORGIN | INFTY, SUBTY, AUTHC, PERSA, PERSG, PERSK, VDSK1 | Datos maestros general |
| P_ORGXX | INFTY, SUBTY, AUTHC, PERSA, PERSG, PERSK, NNNNN | Datos maestros extendido |
| P_PERNR | INFTY, SUBTY, AUTHC, PSIGN | Por número de personal |
| P_ABAP | REPID, COARS | Control de programas de reporting |
| P_TCODE | TCD | Control de transacciones HR |
| P_APPL | INFTY, SUBTY, AUTHC, PERSA | Solicitantes (Recruitment) |

### Configuración AUTHC (Tipos de Autorización)
- R — Leer
- M — Modificar
- E — Ampliar (datos temporales)
- D — Borrar
- W — Escritura (todos los anteriores)
- S — Ver datos nómina

### Switch de Autorización HR
`T77S0 > AUTSW > ORGIN` — Activar verificación de autorización estructural
Valores principales:
- `0` — Sin autorización estructural
- `1` — Autorización estructural activa
- `2` — Solución de contexto activa

### Asignación Indirecta de Roles (OM-PA)
Con integración PA-OM activa (feature PLOGI = ORGA), los roles se pueden asignar a puestos (IT1001 relación A/008) y se heredan automáticamente al titular del puesto.

### Verificación y Diagnóstico
- `SU53` — Ver últimas autorizaciones fallidas del usuario
- `SUIM` — Análisis de roles y autorizaciones
- `SU24` — Propuesta de valores de autorización por transacción
