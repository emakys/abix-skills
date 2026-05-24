# Versiones de Proyecto

## Introduccion

Las **Versiones de Proyecto** en SAP PS permiten crear instantaneas del estado del proyecto en diferentes momentos, facilitando la comparacion entre el plan original (baseline), revisiones posteriores y el estado actual. Son esenciales para el control de cambios, la gestion de claims y el analisis de variaciones.

En SAP S/4HANA 2023 las versiones se integran con el **Commercial Project Management (CPM)** y con el **Project Information System** para reportes comparativos.

---

## 1. Tipos de Versiones

### 1.1 Version Operativa (Version 00)

- Siempre existe y no puede eliminarse.
- Contiene los datos actuales y activos del proyecto.
- Todos los cambios en CJ01/CJ02/CJ11/CJ12 afectan la version 00.
- Es la unica version con la que se trabaja en modo productivo.

### 1.2 Versiones de Simulacion (01 - 99)

- Copias de la version operativa en un punto del tiempo.
- Se pueden usar para:
  - Conservar el baseline aprobado
  - Simular escenarios "what-if"
  - Comparar plan original vs. plan actual
  - Archivo de revisiones de proyecto (re-baseline)
- Solo lectura una vez "congeladas" (bloqueadas).

### 1.3 Clasificacion por Proposito

| Tipo | Version | Uso |
|------|---------|-----|
| Baseline original | 01 | Plan aprobado en inicio del proyecto |
| Revision 1 | 02 | Primer re-baseline aprobado |
| Revision 2 | 03 | Segundo re-baseline |
| Simulacion | 10-19 | Escenarios what-if (no aprobados) |
| Archivo | 90-99 | Cierres de fase o hitos mayores |

---

## 2. Transacciones Principales

### 2.1 CJ91 - Crear Version de Proyecto (WBS Estandar)

**Funcion:** Crear una nueva version de proyecto copiando la estructura WBS actual.

**Campos principales:**

| Campo | Descripcion |
|-------|-------------|
| Proyecto origen | Proyecto del que se copia |
| Numero version | 01-99 (destino) |
| Descripcion version | Texto descriptivo (max 40 car.) |
| Fecha de referencia | Fecha del snapshot |
| Opciones de copia | Que datos copiar (ver seccion 3) |

**Pasos:**
1. Ejecutar `CJ91`
2. Introducir clave de proyecto origen
3. Seleccionar numero de version destino
4. Definir fecha de referencia
5. Marcar opciones de copia (estructuras, fechas, costes, etc.)
6. Ejecutar

**Nota:** Solo copia la estructura WBS. Para copiar tambien las redes y actividades usar `CJ9C` o `CJ9BS`.

### 2.2 CJ9BS - Copiar Proyecto con Redes

**Funcion:** Copiar un proyecto completo (WBS + redes + actividades + componentes) a:
- Una nueva clave de proyecto (proyecto completo nuevo), o
- Una nueva version del mismo proyecto.

**Diferencias con CJ91:**

| Aspecto | CJ91 | CJ9BS |
|---------|------|-------|
| Copia WBS | Si | Si |
| Copia Redes | No | Si |
| Copia Actividades | No | Si |
| Copia Componentes | No | Si |
| Copia Hitos | No | Si |
| Nuevo proyecto | No | Si (opcional) |

**Casos de uso:**
- Crear proyecto similar a uno existente (plantilla)
- Congelar baseline completo incluyendo redes
- Copiar proyecto para otra sociedad / centro

**Parametros de copia en CJ9BS:**

```
Opciones estructura:
[X] Copiar estructura WBS
[X] Copiar redes de trabajo
[X] Copiar componentes de red
[X] Copiar relaciones entre actividades
[X] Copiar hitos
[ ] Copiar documentos

Opciones datos:
[X] Copiar fechas planificadas
[X] Copiar datos de planificacion de costes
[ ] Copiar confirmaciones (datos reales)
[X] Copiar presupuesto
[ ] Copiar status usuario
```

### 2.3 CJ9CS - Copiar Elemento WBS Individual

**Funcion:** Copiar un elemento WBS con su subestructura a otro proyecto o como nueva version.

**Uso:** Cuando se necesita copiar solo una rama del WBS, no el proyecto completo.

### 2.4 CJ9D - Borrar Version de Proyecto

**Funcion:** Eliminar una version de simulacion (no la version 00).

**Prerrequisito:** La version no debe estar bloqueada (si esta bloqueada, desbloquear primero en SPRO o tabla PRVER).

---

## 3. Parametros de Version

### 3.1 Tabla PROJ - Campo VERNR

La tabla `PROJ` contiene el campo `VERNR` (numero de version) que identifica a que version pertenece cada registro de proyecto.

| Campo | Descripcion |
|-------|-------------|
| PSPNR | Numero interno de proyecto |
| PSPID | Clave de proyecto |
| VERNR | Numero de version (00 = operativa) |
| POST1 | Denominacion del proyecto |
| VBUKR | Sociedad |
| WAERS | Moneda del proyecto |

### 3.2 Tabla PRPS - Elementos WBS por Version

La tabla `PRPS` almacena los elementos WBS incluyendo la version.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PSPNR | NUMC8 | Numero interno WBS |
| VERNR | NUMC2 | Numero de version |
| POSID | CHAR24 | Codigo del elemento WBS |
| POST1 | CHAR40 | Denominacion |
| PBUKR | CHAR4 | Sociedad del WBS |
| PSPHI | NUMC8 | Proyecto padre (numero interno) |
| STUFE | NUMC2 | Nivel en la jerarquia |
| PSTRT | DATS | Fecha inicio planificada |
| PENDE | DATS | Fecha fin planificada |
| BELKZ | CHAR1 | Indicador elemento de cuenta |
| PRART | CHAR2 | Tipo de WBS |

**Query MCP - Comparar estructura entre version 00 y version 01:**
```sql
SELECT
    v0.posid AS "WBS_Actual",
    v0.post1 AS "Descripcion_Actual",
    v0.pstrt AS "Inicio_Actual",
    v0.pende AS "Fin_Actual",
    v1.posid AS "WBS_Baseline",
    v1.pstrt AS "Inicio_Baseline",
    v1.pende AS "Fin_Baseline",
    CAST(v0.pstrt AS INT) - CAST(v1.pstrt AS INT) AS "Desviacion_Inicio"
FROM prps v0
LEFT JOIN prps v1
    ON v0.posid = v1.posid
    AND v1.vernr = '01'
    AND v1.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '01')
WHERE v0.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND v0.vernr = '00'
ORDER BY v0.stufe, v0.posid
```

### 3.3 Tabla PRVER - Cabecera de Versiones

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| PSPID | CHAR24 | Clave de proyecto |
| VERNR | NUMC2 | Numero de version |
| VTEXT | CHAR40 | Descripcion de la version |
| ERDAT | DATS | Fecha de creacion |
| ERNAM | CHAR12 | Usuario creador |
| SPEDT | DATS | Fecha de congelacion |
| SPERR | CHAR1 | Indicador bloqueado (X=bloqueado) |
| VSPCD | CHAR1 | Version de plan asociada |

**Query MCP - Listar todas las versiones de un proyecto:**
```sql
SELECT pspid, vernr, vtext, erdat, ernam, spedt,
       CASE WHEN sperr = 'X' THEN 'BLOQUEADA' ELSE 'ACTIVA' END AS estado
FROM prver
WHERE pspid = 'P-2024-001'
ORDER BY vernr
```

---

## 4. Congelar Baseline (Bloquear Version)

### 4.1 Proceso Manual

Para congelar una version y convertirla en solo lectura:

1. Ir a `SPRO` → `Project System` → `Structures` → `Project Versions` → `Lock Project Version`
2. O directamente en tabla `PRVER` via `SE16`: poner `SPERR = 'X'` y `SPEDT = fecha actual`.

**Mejor practica:** Congelar la version 01 (baseline) inmediatamente despues de la aprobacion del proyecto para que nunca pueda ser modificada.

### 4.2 Implicaciones del Bloqueo

| Accion | Version Bloqueada | Version Activa |
|--------|-----------------|----------------|
| Ver en informes | Si | Si |
| Modificar WBS | No | Si |
| Agregar elementos | No | Si |
| Copiar a nueva version | Si | Si |
| Eliminar version | No (desbloquear primero) | Si |

---

## 5. Comparacion Plan/Real/Version en Informes

### 5.1 S_ALR_87013532 - Analisis de Jerarquia de Proyecto

**Configuracion para comparacion con version:**
- Parametro `VERSN` = numero de version de plan (ej. 01)
- Parametro `PGVER` = version de avance para EVM

**Columnas disponibles:**
- Plan version 00 (actual)
- Plan version 01 (baseline)
- Real acumulado
- Comprometido
- Variacion plan vs. baseline
- Variacion plan vs. real

### 5.2 CJE0 - Comparacion de Versiones de Proyecto

**Funcion especifica para comparar dos versiones** de la estructura WBS.

**Parametros:**
- Version de referencia: 00 (actual)
- Version de comparacion: 01 (baseline)
- Tipo de comparacion: Fechas / Costes / Ambos

### 5.3 S_ALR_87013542 - Informe de Variaciones

Muestra diferencias entre plan original y plan actual por elemento WBS.

---

## 6. Customizing de Versiones

### 6.1 Definir Rangos de Versiones Permitidas

**Ruta SPRO:**
```
Project System > Structures > Project Versions > Define Project Version Parameters
```

Tabla: `T8PV` (parametros de version de proyecto)

| Campo | Descripcion |
|-------|-------------|
| VERNR_VON | Version inicial del rango |
| VERNR_BIS | Version final del rango |
| VTEXT | Descripcion del rango |
| SPERRK | Perfil de bloqueo |

### 6.2 Control de Numeracion

Las versiones se numeran manualmente (01-99). No existe un rango de numeracion automatico para versiones — el usuario elige el numero al crear la version.

### 6.3 Perfiles de Copia

**Ruta SPRO:**
```
Project System > Structures > Project Versions > Define Copy Profiles for Projects
```

Define que elementos se copian al crear una version:
- Datos basicos WBS
- Fechas de WBS
- Datos de planificacion de costes
- Presupuesto
- Definicion de redes
- Componentes de material
- Relaciones de dependencia

---

## 7. Flujo de Proceso Recomendado

```
INICIO PROYECTO
    |
    v
[1] Crear proyecto base (CJ01)
    |
    v
[2] Planificar WBS, redes, costes (CJ12, CJ40, CN21)
    |
    v
[3] Aprobar proyecto internamente
    |
    v
[4] Crear Version 01 - BASELINE (CJ9BS)
    |-- Copiar toda la estructura
    |-- Incluir fechas y costes plan
    |-- Excluir confirmaciones
    |
    v
[5] BLOQUEAR Version 01 (SPERR = X en PRVER)
    |
    v
[6] LIBERAR proyecto (status REL en CJ02)
    |
    v
[7] Ejecucion del proyecto
    | Cambios autorizados -> Version 00 (operativa)
    |
    v
[8] Si hay re-baseline aprobado -> Crear Version 02
    | Bloquear Version 02
    |
    v
[9] Reporting: Comparar V00 vs V01 (plan actual vs. baseline)
    |
    v
[10] Cierre: Version 99 = snapshot final antes de CLSD
```

---

## 8. Integracion con Presupuesto y Costeo

### 8.1 Versiones de Plan de Costes

Las versiones de proyecto (01-99 en PRVER) son **independientes** de las versiones de plan de costes (tabla COSP, campo VERSN).

| Concepto | Tabla | Campo version |
|----------|-------|--------------|
| Version de proyecto | PRVER, PRPS, PROJ | VERNR |
| Version de plan CO | COSP, COSS | VERSN |
| Version de avance | EVPR, EVPO | PGVER |

Al copiar un proyecto con `CJ9BS` se puede elegir si copiar tambien los planes de costes y a que version CO destino copiarlos.

### 8.2 Presupuesto en Versiones

El presupuesto (BPGE, BPJA) **no se copia automaticamente** a las versiones de simulacion. El presupuesto oficial siempre pertenece a la version 00.

Para comparar presupuesto original con plan, usar:
- `S_ALR_87013558` - Presupuesto vs. Real vs. Compromiso

---

## 9. Casos de Uso Practicos

### Caso 1: Gestion de Claims (Reclamaciones)

```
Situacion: Cliente solicita extension de alcance que afecta fechas y costes.

1. Crear Version 02 = Estado antes de la reclamacion
   Bloquear Version 02

2. Modificar Version 00 con el nuevo alcance aprobado

3. Comparar V00 vs V02 en CJE0 para cuantificar el impacto
   -> Variacion de fechas = fundamento del claim de tiempo
   -> Variacion de costes = fundamento del claim economico
```

### Caso 2: Auditoria de Cambios al Proyecto

```
Situacion: Auditoria externa requiere evidencia de cambios al proyecto.

1. Versiones bloqueadas 01, 02, 03 proporcionan evidencia objetiva
2. CJE0 entre versiones muestra quien cambio que y cuando
3. PRVER.ERNAM + ERDAT muestra usuario y fecha de cada version
```

### Caso 3: Plantillas de Proyecto

```
Situacion: Crear proyecto similar a uno exitoso anterior.

1. Buscar proyecto origen (ej. P-2023-045)
2. Ejecutar CJ9BS con proyecto origen
3. Nueva clave proyecto = P-2024-067
4. Ajustar fechas, recursos y responsables
5. El proyecto nuevo parte de una estructura probada
```

---

## 10. Limitaciones y Consideraciones

| Aspecto | Detalle |
|---------|---------|
| Maximo versiones | 99 por proyecto |
| Datos reales | Las confirmaciones NO se copian a versiones (son datos de la version 00) |
| Documentos adjuntos | No se copian automaticamente con CJ9BS |
| Perfiles de WBS | Se copian con la estructura |
| Status de elementos | Se pueden incluir o excluir en parametros de copia |
| Objetos de coste CO | Se crean nuevos para la version copiada |
| Relaciones entre actividades | Se copian con CJ9BS pero no con CJ91 |
| Componentes de material | Solo se copian si se marca la opcion en parametros |

---

## 11. Buenas Practicas

1. **Crear baseline antes de REL** — La version 01 debe crearse y bloquearse antes de liberar el proyecto para ejecucion.
2. **Nomenclatura consistente** — Definir una politica: V01=baseline, V02=revision1, V10-V19=simulaciones.
3. **Documentar en descripcion** — El campo VTEXT de PRVER debe indicar la razon y fecha de la version.
4. **Un re-baseline por aprobacion** — Cada cambio aprobado de alcance genera una nueva version numerada.
5. **No usar versiones de simulacion como baseline** — Reservar 01-09 para baselines aprobados, 10-99 para simulaciones.
6. **Verificar antes de bloquear** — Una vez bloqueada, la version no puede modificarse. Verificar completitud de datos antes.
7. **Integrar con control de cambios** — El proceso de creacion de version debe estar ligado al proceso formal de change management.
