# Autorizaciones HR

Guía completa del modelo de autorizaciones en SAP HCM S/4HANA 2023. El modelo HR combina autorizaciones generales ABAP con objetos específicos de RRHH y, opcionalmente, autorización estructural.

---

## Objetos de Autorización Principales

### P_ORGIN — Datos Maestros de Personal (General)

El objeto central para el acceso a infotipos de empleados.

| Campo | Descripción | Valores Ejemplo |
|---|---|---|
| INFTY | Infotipo | 0001, 0002, *, 0001-0010 |
| SUBTY | Subtipo | *, 01, 02 |
| AUTHC | Tipo de autorización | R, M, E, D, W, S |
| PERSA | División de personal | 1000, *, 1000-1999 |
| PERSG | Grupo de empleados | 1, 2, * |
| PERSK | Círculo de empleados | DT, MT, * |
| VDSK1 | Nivel organizativo | * (generalmente) |

**Tipos de autorización (AUTHC):**
- `R` — Read (Leer)
- `M` — Modify (Modificar campos individuales)
- `E` — Enqueue/Extend (Ampliar validez)
- `D` — Delete (Borrar registros)
- `W` — Write (Equivale a M+E+D)
- `S` — Sensitive (Datos de nómina — infotipos 0008, 0014, 0015, etc.)

---

### P_ORGXX — Datos Maestros Extendido

Amplía P_ORGIN con un campo libre configurable (NNNNN). Utilizado cuando se requiere un criterio adicional de segmentación no cubierto por los campos estándar.

| Campo | Descripción |
|---|---|
| INFTY | Infotipo |
| SUBTY | Subtipo |
| AUTHC | Tipo de autorización |
| PERSA | División de personal |
| PERSG | Grupo de empleados |
| PERSK | Círculo de empleados |
| NNNNN | Campo libre (configurable via T77S0 AUTSW NNNNN) |

**Activación:**
`T77S0 > AUTSW > NNNN1` — Nombre del campo libre del infotipo 0001 a usar como NNNNN

---

### P_PERNR — Autorización por Número de Personal

Permite control granular a nivel de número de personal individual.

| Campo | Descripción | Valores |
|---|---|---|
| INFTY | Infotipo | * o infotipos específicos |
| SUBTY | Subtipo | * |
| AUTHC | Tipo de autorización | R, W, etc. |
| PSIGN | Signo de interpretación | I (incluir) / E (excluir) |

**Casos de uso:**
- Acceso de un empleado a sus propios datos (autoservicio ESS)
- Restricción de acceso a directivos sobre sus datos propios
- `PSIGN = I` — El usuario solo puede acceder a los números de personal listados en IT0105 (comunicación, subtype sistema) o en la tabla HRUS_D2

---

### P_ABAP — Control de Programas de Reporting

Controla qué informes HR puede ejecutar un usuario y con qué nivel de detalle.

| Campo | Descripción | Valores |
|---|---|---|
| REPID | Nombre del programa | RPLMIT00, *, H99* |
| COARS | Nivel de detalle | 0 (detallado) / 1 (solo totales) |

**Nota:** Sin este objeto correctamente configurado, los informes omiten la verificación de P_ORGIN y muestran todos los datos. Es un objeto de seguridad crítico.

---

### P_TCODE — Control de Transacciones HR

Complementa S_TCODE para transacciones específicas de HR.

| Campo | Descripción |
|---|---|
| TCD | Código de transacción HR (PA30, PA40, PP01, etc.) |

---

### P_APPL — Solicitantes (Módulo Recruitment)

Análogo a P_ORGIN pero para datos de candidatos/solicitantes.

| Campo | Descripción |
|---|---|
| INFTY | Infotipo de solicitante (4xxx) |
| SUBTY | Subtipo |
| AUTHC | Tipo de autorización |
| PERSA | División de personal |

---

## Autorización Estructural

La autorización estructural restringe el acceso a objetos del plan organizativo (puestos, unidades organizativas, empleados titulares).

### Activación
`T77S0 > AUTSW > ORGIN`
- `0` — Desactivada (solo autorización general)
- `1` — Autorización estructural activa
- `2` — Solución de contexto activa (recomendada S/4HANA)

### Componentes
| Elemento | Tabla/Transacción | Descripción |
|---|---|---|
| Perfil de autorización estructural | T77PR | Define el alcance del perfil |
| Reglas de evaluación | T77AW | Define función de evaluación |
| Asignación de perfil a usuario | T77UA | Asigna perfil a usuario HR |

**Mantenimiento:** OOSP (perfiles), OOSB (asignación usuarios)

### Funciones de Evaluación Estándar
| Función | Descripción |
|---|---|
| SBESX | Evaluación estándar con períodos de tiempo |
| O_S_BESX | Evaluación de puestos |
| ORGEH_BESX | Evaluación de unidades organizativas y sus dependientes |

---

## Solución de Contexto (Context Solution)

Disponible desde SAP ERP 6.0 EhP5, recomendada en S/4HANA. Combina autorización general y estructural en una sola verificación.

**Activación:** `T77S0 > AUTSW > ORGIN = 2`

**Ventajas:**
- Elimina la doble verificación (general + estructural)
- Mejor rendimiento en sistemas grandes
- Simplifica el mantenimiento de roles

**Nuevo objeto:** `P_ORGINCON` — reemplaza P_ORGIN cuando la solución de contexto está activa. Incluye los mismos campos más `PROFL` (perfil estructural).

---

## Switch Principal de Autorización HR

La tabla `T77S0` controla el comportamiento global del sistema de autorizaciones.

| Grupo | Sem. | Valor | Descripción |
|---|---|---|---|
| AUTSW | ORGIN | 0/1/2 | Autorización estructural (ver arriba) |
| AUTSW | ORGPD | 0/1 | Autorización estructural en OM |
| AUTSW | INCON | 0/1 | Verificación de consistencia infotipos |
| AUTSW | NNNNN | nombre campo | Campo para P_ORGXX |
| AUTSW | NNNN1 | nombre campo | Campo adicional IT0001 para NNNNN |
| AUTSW | ADAYS | días | Período retroactivo para autorización temporal |

**Transacción:** SM30 > T77S0 o ruta SPRO directa.

---

## Asignación Indirecta de Roles via OM

Con la integración PA-OM activa (feature PLOGI = ORGA), los roles SAP se pueden asignar a puestos de trabajo en lugar de usuarios individuales.

**Flujo:**
1. Asignar rol SAP al puesto (IT1016 o via PPOME, relación A/B 008)
2. Asignar empleado al puesto (IT0001 campo PLANS)
3. El sistema crea automáticamente la asignación de rol al usuario en SU01

**Ventajas:**
- Gestión de autorizaciones alineada con la estructura organizativa
- Al cambiar de puesto, las autorizaciones se actualizan automáticamente
- Auditoría más clara (rol por puesto, no por persona)

**Programa de sincronización:** RHPROFL0 — sincroniza roles de OM con perfiles de usuario

---

## Problemas Comunes y Soluciones

### Error: "No tiene autorización para el infotipo XXXX"
1. Ejecutar `SU53` inmediatamente después del error
2. Identificar el objeto de autorización fallido (normalmente P_ORGIN)
3. Verificar que el rol asignado al usuario tenga el infotipo en el rango correcto
4. Comprobar que PERSA, PERSG, PERSK coinciden con los datos del empleado

### El usuario ve datos de empleados de otras divisiones
1. Verificar P_ORGIN campo PERSA — puede tener `*` (todas las divisiones)
2. Si la autorización estructural está activa (T77S0 AUTSW ORGIN=1), revisar T77UA
3. Comprobar si existe una entrada en T77UA para el usuario con un perfil demasiado amplio

### P_ABAP no aplicado en reports
- Verificar que el programa llama a `HR_READ_INFOTYPE` o funciones estándar HR
- Programas que leen directamente de PA0001 etc. sin API pueden saltarse P_ABAP
- Revisar el código del report con transaction SE38

### Autorización estructural no restringe como se espera
1. Verificar `T77S0 > AUTSW > ORGIN` — debe ser 1 o 2
2. Revisar la función de evaluación asignada al perfil en T77PR
3. Ejecutar OOSP para simular la evaluación del perfil
4. Comprobar que T77UA tiene el usuario asignado al perfil correcto

---

## Herramientas de Diagnóstico

| Transacción | Descripción |
|---|---|
| SU53 | Muestra el último fallo de autorización del usuario actual |
| SUIM | Sistema de información de usuarios y roles — búsquedas cruzadas |
| SU24 | Propuesta de valores de autorización por transacción/servicio |
| OOSB | Asignación de perfiles de autorización estructural a usuarios |
| OOSP | Mantenimiento de perfiles de autorización estructural |
| SU01D | Display de usuario (ver roles y perfiles asignados) |
| PFCG | Mantenimiento de roles |
| STAUTHTRACE | Traza de autorizaciones detallada (activar en SM19 antes) |
| SM19 | Configuración de auditoría de seguridad |
