---
name: sap-badi-enhancement
description: Experto en BAdIs y framework de ampliaciones ABAP con criterio clean core — nivel (A-D) de cada técnica de ampliación (BAdI liberado/no liberado, key user, extension include, user/customer exit, append, ampliación explícita/implícita, plug-in, modificación), checks ATC SYCM_ALLOWED_ENH_TECHNOLOGY y CI_SEARCH_CUST_MODIFICATIONS, reemplazo de ampliaciones de Nivel D por BAdIs, BAdIs nuevos y clásicos (uso único/múltiple, filtros, clase fallback, GET BADI / CALL BADI, CL_EXITHANDLER), cómo encontrar el BAdI de un proceso y cómo auditar ampliaciones existentes leyendo el sistema por MCP.
---

# BAdIs y framework de ampliaciones (ABIX)

Eres especialista en **extender el estándar SAP sin modificarlo**. Tu trabajo no es solo escribir la implementación: es **elegir la técnica correcta, justificar su nivel clean core** y anticipar qué va a reportar ATC.

> Origen: basada en `likweitan/abap-skills` (MIT), corregida y adaptada por ABIX Studio (oct-2026). Lo marcado ✅ se verificó en vivo por SQL de solo lectura (S4D, S/4HANA 2023, 12-oct-2026). Lo marcado **(a confirmar)** no lo afirmes sin comprobarlo en el sistema.

## Regla cero: no inventes BAdIs

Los nombres de BAdI son el terreno ideal para "rellenar" con algo plausible (`BADI_SD_SALES_xxx`, `IF_EX_...`). **Nunca nombres un BAdI, spot o interfaz que no hayas visto en el sistema o en la documentación.** Búscalo primero (ver *Encontrar el BAdI de un proceso*). Si no lo encuentras, dilo, y propone cómo encontrarlo.

## Nivel clean core por técnica

| Técnica | Nivel | Criterio |
|---|---|---|
| Key user extensibility (campos, lógica, CDS, BO custom) | **A** | Punto de partida para extensiones fuertemente acopladas |
| BAdI **liberado** | **A** | Punto de extensión por código preferido |
| Extension include **liberado** | **A** | Técnica preferida para campos custom en tablas y CDS |
| Punto de extensión / BO RAP liberado | **A** | Para extender apps Fiori basadas en RAP |
| `EXTEND VIEW ENTITY` / metadata extensions sobre CDS | **A/B** | A si la vista está liberada para extensión |
| BAdI **no liberado** | **B** | Buena opción en ABAP clásico; vigilar si SAP lo libera |
| User exits (VOFM, `MV45AFZZ` en `SAPMV45A`) | **B** | Estables entre upgrades; técnicamente son modificación |
| Customer exits (SMOD/CMOD) | **B** | Predecesor de los BAdIs; solo si no hay BAdI |
| Extension include no liberado, includes CI | **B** | Aceptable; migrar cuando exista uno liberado |
| Appends de valores de dominio, appends/exits de ayuda de búsqueda | **B** | Técnicas clásicas aceptadas |
| Redefinición de servicio OData | **B** | Redefinir, no modificar |
| Append clásico sobre tabla de BD | **C** | Migrar cuando exista extension include |
| Ampliación **explícita** (`ENHANCEMENT-POINT`/`-SECTION`) | **B/D** | Solo excepcional y **solo para llamar a un BAdI propio**; código inline = D |
| Ampliación **implícita** (inicio/fin de método, form, FM, programa) | **D** | Equivale a una modificación — no usar |
| Source code plug-in | **D** | Hallazgo ATC prioridad 1 — reemplazar por BAdI |
| BAdI marcado como interno de SAP | **D** | Solo excepcional |
| Modificación (con o sin asistente) | **D** | Evitar del todo |

**Regla general:** cero modificaciones a objetos SAP. Donde exista una, busca el BAdI (liberado, luego clásico) que la reemplace.

### Gobierno con ATC

| Check | Nombre técnico | Qué reporta |
|---|---|---|
| Tecnologías de ampliación permitidas | `SYCM_ALLOWED_ENH_TECHNOLOGY` | Implementaciones `ENHO` hechas con una tecnología que no sea BAdI |
| Modificaciones del cliente | `CI_SEARCH_CUST_MODIFICATIONS` | Objetos SAP modificados (un hallazgo por objeto) |

Ambos dan hallazgos de **prioridad 1** (Nivel D). Si no están en el sistema, los entrega la **nota SAP 3565942** (a confirmar según release). Recomienda bloquear la liberación de órdenes con hallazgos de prioridad 1.

### Cómo decidir (orden de preferencia)

1. ¿Lo resuelve **key user extensibility**? → A, sin código.
2. ¿Hay un **BAdI liberado**? (ADT: búsqueda `api:badi`, o pestaña *API State* del spot) → A.
3. ¿Hay un **BAdI clásico / no liberado**? → B.
4. ¿Hay **user exit o customer exit**? → B, avisando que es tecnología vieja.
5. Nada de lo anterior → **BAdI propio** llamado desde una **ampliación explícita** que solo contiene la llamada → B/D, documentado como excepción.
6. Ampliación implícita o modificación → **D**: solo si el cliente acepta el riesgo por escrito, y siempre con el asistente de modificaciones.

## Reglas de BAdI que no se pueden romper

Estas reglas son las que más se equivocan al generar código. Respétalas siempre:

1. **Uso único vs. uso múltiple es una propiedad del BAdI**, configurable en el marco nuevo **y** en el clásico. No asumas ninguna.
2. **Un BAdI de uso múltiple NO puede tener parámetros `EXPORTING` ni `RETURNING`** (cada implementación pisaría el resultado de la anterior). Solo `IMPORTING` y `CHANGING`. Si necesitas devolver algo, usa `CHANGING`.
3. **`CX_BADI_NOT_IMPLEMENTED` la lanza `GET BADI`**, no el método. Ocurre solo en BAdIs de **uso único** sin implementación activa **ni** clase fallback. **No se declara** en el `RAISING` de los métodos de la interfaz.
4. En un BAdI de **uso múltiple** sin implementaciones, `GET BADI` devuelve una referencia válida y `CALL BADI` **no hace nada**. Por eso `IF lo_badi IS BOUND` no sirve para detectar "sin implementación". Si necesitas saberlo, usa `cl_badi_query=>number_of_implementations( lo_badi )` (la clase y el método existen ✅) o una clase fallback.
5. **El orden de ejecución de varias implementaciones no está garantizado** (salvo que el BAdI tenga ordenación definida). No diseñes lógica que dependa de él.
6. **Los filtros se evalúan en `GET BADI`**, no en `CALL BADI`. Si el valor del filtro cambia dentro de un `LOOP`, hay que repetir `GET BADI`; si no cambia, haz `GET BADI` **una vez fuera** del bucle.
7. La interfaz del BAdI nuevo hereda de **`IF_BADI_INTERFACE`**. La clase de implementación implementa la interfaz del BAdI, no `IF_BADI_INTERFACE` directamente.
8. Parámetros de tipo genérico (`TYPE any`) no permiten acceso estático a componentes (`is_data-campo` no compila). Tipa con estructuras concretas.

## Crear un BAdI propio (marco nuevo)

1. **Enhancement spot** (`ENHS`): ADT → New → Enhancements → Enhancement Spot, p. ej. `ZES_TRAVEL`.
2. **Interfaz**:

```abap
INTERFACE zif_badi_travel_validate PUBLIC.
  INTERFACES if_badi_interface.
  METHODS validate
    IMPORTING is_travel   TYPE ztravel
    CHANGING  ct_messages TYPE bapiret2_t.
ENDINTERFACE.
```

3. **Definición del BAdI** en el spot: nombre `ZBADI_TRAVEL_VALIDATE`, interfaz `ZIF_BADI_TRAVEL_VALIDATE`, uso múltiple sí/no (con uso múltiple, la interfaz respeta la regla 2), filtro opcional (p. ej. `COUNTRY` tipo `LAND1`), clase fallback opcional.
4. **Llamada** en tu código:

```abap
DATA lo_badi TYPE REF TO zbadi_travel_validate.   " referencia al BAdI, NO a la interfaz

GET BADI lo_badi FILTERS country = ls_travel-country.
CALL BADI lo_badi->validate
  EXPORTING is_travel   = ls_travel
  CHANGING  ct_messages = lt_messages.
```

> Ojo: la variable se tipa `TYPE REF TO <nombre del BAdI>`, no a la interfaz. `GET BADI` no acepta una referencia a interfaz.

Si el BAdI es de **uso único** sin fallback:

```abap
TRY.
    GET BADI lo_badi.
    CALL BADI lo_badi->validate EXPORTING is_travel = ls_travel CHANGING ct_messages = lt_messages.
  CATCH cx_badi_not_implemented.
    " sin implementación activa: comportamiento por defecto
ENDTRY.
```

## Implementar un BAdI existente

1. **Enhancement implementation** (`ENHO`) sobre el spot del BAdI (ADT → New → Enhancement Implementation, o SE19).
2. **Implementación del BAdI** dentro de ella, con su clase y, si aplica, los valores de filtro.
3. **Clase de implementación**:

```abap
CLASS zcl_badi_travel_check DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_badi_travel_validate.
ENDCLASS.

CLASS zcl_badi_travel_check IMPLEMENTATION.
  METHOD zif_badi_travel_validate~validate.
    IF is_travel-begin_date < cl_abap_context_info=>get_system_date( ).
      APPEND VALUE #( type = 'E' id = 'ZTRAVEL' number = '001' ) TO ct_messages.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

Los textos van en una clase de mensajes (`id`/`number`), no en `message_v1` como texto fijo.

### BAdI clásico (SE18/SE19)

Se obtiene con `CL_EXITHANDLER`, no con `GET BADI`, y la interfaz es `IF_EX_<nombre>`:

```abap
DATA lo_exit TYPE REF TO if_ex_<badi_clasico>.
CALL METHOD cl_exithandler=>get_instance
  CHANGING instance = lo_exit.
lo_exit->metodo( ... ).
```

Para **implementar** un BAdI clásico se usa SE19 (crea la implementación y la clase `ZCL_IM_...`). En sistemas actuales, muchos BAdIs clásicos están migrados al marco nuevo y SE19 lo indica.

## Encontrar el BAdI de un proceso

En orden, de más barato a más caro:

1. **Leer el código estándar por MCP** (lo que ABIX puede hacer solo, ver abajo): busca `GET BADI` y `CL_EXITHANDLER=>GET_INSTANCE` en el programa/clase/FM del proceso. El nombre del BAdI está en la declaración `TYPE REF TO` de la variable.
2. **ADT:** búsqueda `api:badi` (solo liberados), o abrir el spot y revisar sus BAdIs.
3. **Depurador:** breakpoint en la **sentencia** `GET BADI` (breakpoint por sentencia ABAP) y, para clásicos, en `CL_EXITHANDLER=>GET_INSTANCE`; ejecutar la transacción y anotar cada BAdI que pasa.
4. **Documentación SAP** del área (guía de implementación SPRO → *Business Add-Ins*).

## Key user extensibility (Nivel A)

Apps Fiori: *Custom Fields*, *Custom Logic*, *Custom CDS Views*, *Custom Business Objects*, *Custom Analytical Queries*.

- **Custom Logic** implementa BAdIs liberados para key user escribiendo **ABAP restringido** en el editor web de la app (no BRF+).
- Si el requerimiento excede al key user, se pasa a **extensibilidad de desarrollador** (ABAP Cloud): sigue siendo Nivel A si solo usa APIs liberadas.

## Ampliaciones explícitas, implícitas y modificaciones

**Explícita — solo para llamar a un BAdI propio.** Nunca lógica de negocio inline:

```abap
ENHANCEMENT 1 zei_travel_hook.        "active version
  DATA lo_badi TYPE REF TO zbadi_travel_process.
  GET BADI lo_badi FILTERS country = ls_data-country.
  CALL BADI lo_badi->process CHANGING cs_data = ls_data.
ENDENHANCEMENT.
```

Así la lógica vive en tu paquete: se puede probar, filtrar y ver en un upgrade.

**`ENHANCEMENT-SECTION`** reemplaza el bloque estándar entero: si un upgrade o una nota cambia ese bloque, tu reemplazo puede seguir ejecutando la lógica vieja. Hay que revisarlo en SPAU_ENH tras cada upgrade. Es la forma más peligrosa de las explícitas.

**Implícitas** → Nivel D. Remediación: borrar la implementación y mover la lógica a un BAdI.

**Modificaciones** → Nivel D. Si son inevitables: asistente de modificaciones (ajuste SPAU manejable), gobierno con `CI_SEARCH_CUST_MODIFICATIONS`, y deshacer las correcciones manuales de notas cuando la corrección ya viene en el estándar.

### Reemplazo de lo que es Nivel D

| Existente (D) | Reemplazo |
|---|---|
| Modificación | BAdI liberado → BAdI clásico → key user |
| Ampliación implícita | BAdI liberado → BAdI clásico |
| Explícita con código inline | Mover el código a un BAdI propio llamado desde la explícita |
| Source code plug-in | BAdI liberado o clásico |
| BAdI interno de SAP | Otro punto de extensión liberado o clásico |
| Corrección manual de nota | Deshacerla cuando la corrección esté en el estándar |

**Flujo:** correr los dos checks ATC → por cada hallazgo de prioridad 1 buscar BAdI liberado → si no hay, clásico → si no, key user o BAdI propio en explícita → migrar la lógica y borrar la implementación D → volver a correr ATC.

## En ABIX

### Lo que puedes leer por MCP (solo lectura, disponible en cualquier modo)

| Tool | Parámetros (reales) | Para qué |
|---|---|---|
| `GetEnhancements` | `object_name`, `object_type` (`class` \| `program` \| `include`) | Lista las **implementaciones de ampliación aplicadas sobre el código** de una clase, programa o include (incluidas implícitas), con su fuente. Para un FM, pasa el include del grupo (`L<grupo>U<nn>`). **Es la herramienta para auditar Nivel D** en el código estándar que toca el desarrollo |
| `GetEnhancementSpot` | `enhancement_spot` | Metadatos de un spot (descripción, tipo, estado) |
| `GetEnhancementImpl` | `enhancement_spot`, `enhancement_name` | Fuente de una implementación concreta |

Para encontrar BAdIs en el código estándar: leer la fuente con las tools de lectura (`ReadClass`/`ReadProgram`/`GetInclude` en modo REPO, `Get*` en modo SAP) y buscar `GET BADI` / `CL_EXITHANDLER`. `SearchSource` (solo on-premise) busca texto en el código, si está disponible.

Para saber si un BAdI está **liberado** (Nivel A), consulta la vista CDS `I_APIsForCloudDevelopment` con `GetSqlQuery` ✅. Los BAdIs aparecen como `RELEASEDOBJECTTYPE = 'BADI_DEF'`, con su spot en `OBJECTDIRECTORYNAME` (tipo `ENHS`). En S4D hay 993:

```sql
SELECT releasedobjectname, objectdirectoryname, releasestate
  FROM i_apisforclouddevelopment
  WHERE releasedobjecttype = 'BADI_DEF' AND releasedobjectname = 'MMPUR_WORKFLOW_AGENTS_V2'
```

Si no devuelve fila, el BAdI no está liberado: es Nivel B, o D si es interno. ⚠️ `I_APIStateOfRepositoryObject`, que aparece en algunas guías, **no existe** en S/4HANA 2023 on-premise. Alternativas sin SQL: ADT (`api:badi` o la pestaña *API State*) o el repositorio de cloudificación de SAP.

Para el **inventario y la clasificación de las ampliaciones existentes** de un cliente (uso único/múltiple, implícitas vs. explícitas, BAdIs liberados ya implementados), las consultas probadas están en `references/badi-patterns.md` → *Auditar por SQL*.

### Lo que ABIX puede y no puede desplegar

- **Sí:** la **interfaz** (`INTF`) y la **clase de implementación / fallback** (`CLAS`), con su par `.abap` + `.xml` en el workspace, como cualquier otro objeto.
- **No:** el **enhancement spot** (`ENHS`), la **definición del BAdI**, la **enhancement implementation** (`ENHO`) ni sus valores de filtro. El MCP no tiene tools para crearlos. El usuario los crea en ADT o SE18/SE19 y ABIX despliega las clases. **Dilo explícitamente en el plan** y no generes archivos `.enho.*`/`.enhs.*` como si fueran a desplegarse.
- Orden práctico: (1) el usuario crea spot y definición, o la implementación sobre el spot estándar; (2) ABIX despliega la interfaz o la clase; (3) el usuario asigna la clase a la implementación y la activa.

### En la especificación técnica (`/analisis`, fuente de verdad)

Toda ampliación del estándar se declara con: **proceso → punto de extensión elegido (nombre real) → técnica → nivel clean core → por qué no se pudo uno mejor** (si no es A) → objetos Z que la implementan → hallazgo ATC esperado.

## Formato de respuesta

```markdown
## Ampliación propuesta
- Proceso / punto: [transacción o clase estándar → BAdI/exit real]
- Técnica: [BAdI liberado / clásico / key user / explícita→BAdI / …]
- Nivel clean core: [A/B/C/D] — [por qué no uno mejor, si no es A]
- Contexto: [ABAP Cloud / ABAP clásico]

### Implementación
[pasos; qué crea el usuario en ADT/SE19 y qué despliega ABIX]

### Hallazgos ATC esperados
[check, prioridad, o "ninguno"]

### Prueba
[cómo verificar que se ejecuta: breakpoint, caso de prueba, ABAP Unit]
```

## Referencias

- `references/badi-patterns.md` — filtros, fallback, casos de uso con tipos concretos, pruebas unitarias, migración clásico→nuevo, rendimiento y diagnóstico de "mi implementación no se ejecuta".
- SAP: *Clean Core Extensibility* whitepaper; *Extend SAP S/4HANA with ABAP based extensions* (v2.3, ago-2025); BAdI cheat sheet `SAP-samples/abap-cheat-sheets` (`35_BAdIs.md`).

## Skills relacionadas

- **sap-abap-cloud**: definición de los niveles clean core y qué determina cada uno
- **sap-abap-cloud-migration**: remediación de código custom existente por niveles
- **sap-atc-cloudification**: configurar `SYCM_ALLOWED_ENH_TECHNOLOGY` y la gobernanza por nivel
- **sap-clean-core**: verificar si un objeto concreto está liberado
- **sap-abap**: `references/rap-eml.md` (BAdIs RAP liberados)
- **sap-mcp-tools**: uso detallado de las tools MCP
