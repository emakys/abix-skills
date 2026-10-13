# Patrones de BAdI — referencia

Complementa a `SKILL.md`. La tabla de niveles clean core y el flujo de remediación de Nivel D **están solo en `SKILL.md`** (no se repiten acá). Todo el código respeta las reglas de BAdI de `SKILL.md`: los BAdIs de uso múltiple no tienen `EXPORTING`/`RETURNING`, `CX_BADI_NOT_IMPLEMENTED` sale de `GET BADI`, y los tipos son concretos.

## Filtros

El filtro se define en el BAdI (nombre + tipo) y cada implementación declara para qué valores aplica. `GET BADI` selecciona las implementaciones cuyo filtro coincide.

```abap
" Filtro COUNTRY (LAND1)
GET BADI lo_badi FILTERS country = lv_land1.

" Varios filtros
GET BADI lo_badi FILTERS bukrs = lv_bukrs
                         blart = lv_blart.
```

- Usa elementos de datos reales del DDIC como tipo del filtro (`LAND1`, `BUKRS`, `BLART`, …), no `CHAR4` genérico: la implementación muestra la ayuda de búsqueda correcta.
- Si el valor del filtro cambia dentro de un bucle, repite `GET BADI` dentro del bucle; si no cambia, hazlo una vez antes (`GET BADI` tiene costo y `CALL BADI` casi no).

## Clase fallback

Se ejecuta cuando **no hay ninguna implementación activa** que coincida con el filtro. Evita la excepción en BAdIs de uso único y define el comportamiento por defecto en un solo lugar.

```abap
CLASS zcl_badi_travel_fallback DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_badi_travel_validate.
ENDCLASS.

CLASS zcl_badi_travel_fallback IMPLEMENTATION.
  METHOD zif_badi_travel_validate~validate.
    " Comportamiento estándar: sin validaciones adicionales.
    RETURN.
  ENDMETHOD.
ENDCLASS.
```

La fallback **no reemplaza** a las implementaciones: si existe alguna activa que coincida, la fallback no se ejecuta. Es una decisión de comportamiento, no una optimización de rendimiento.

## Casos de uso típicos (con tipos concretos)

### Validación (uso múltiple)

```abap
INTERFACE zif_badi_order_check PUBLIC.
  INTERFACES if_badi_interface.
  METHODS check
    IMPORTING is_header   TYPE zorder_header
              it_items    TYPE zorder_items_t
    CHANGING  ct_messages TYPE bapiret2_t.      " cada implementación AGREGA mensajes
ENDINTERFACE.
```

El llamador decide con el resultado acumulado: `IF line_exists( lt_messages[ type = 'E' ] ).` Con uso múltiple no hay "valor de retorno" por implementación; el `CHANGING` acumula lo de todas.

### Enriquecimiento (uso único)

Si la semántica es "una sola respuesta" (p. ej. determinar un valor), define el BAdI como **uso único** y usa `CHANGING` o `EXPORTING`:

```abap
INTERFACE zif_badi_route_determine PUBLIC.
  INTERFACES if_badi_interface.
  METHODS determine
    IMPORTING is_order TYPE zorder_header
    CHANGING  cv_route TYPE route.             " llega con el valor estándar; la implementación puede cambiarlo
ENDINTERFACE.
```

Pasar el valor estándar por `CHANGING` (en vez de `EXPORTING` vacío) hace que "no hacer nada" en la implementación conserve el comportamiento estándar.

### Integración con otro sistema

**No** hagas llamadas HTTP/RFC síncronas dentro de un BAdI que corre en la grabación (`SAVE`, `BEFORE_SAVE`, …): bloquea la transacción, y si el sistema remoto falla deja la LUW a medias. Opciones correctas: registrar el evento (tabla Z, evento de negocio, `qRFC`/`bgRFC`) y procesarlo **después del commit**, o usar `CALL FUNCTION … IN BACKGROUND UNIT`/`IN UPDATE TASK` según el caso.

## Pruebas

### Probar la implementación

La clase de implementación es una clase normal: se prueba instanciándola directamente.

```abap
CLASS ltc_travel_check DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zif_badi_travel_validate.
    METHODS setup.
    METHODS past_date_gives_error FOR TESTING.
ENDCLASS.

CLASS ltc_travel_check IMPLEMENTATION.
  METHOD setup.
    mo_cut = NEW zcl_badi_travel_check( ).          " la clase REAL, no un doble
  ENDMETHOD.

  METHOD past_date_gives_error.
    DATA lt_messages TYPE bapiret2_t.
    mo_cut->validate( EXPORTING is_travel   = VALUE #( begin_date = '20000101' )
                      CHANGING  ct_messages = lt_messages ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_messages[ type = 'E' ] ) ) ).
  ENDMETHOD.
ENDCLASS.
```

### Aislar al llamador

Para probar el código que **llama** al BAdI sin depender de qué implementaciones haya activas en el sistema, encapsula `GET BADI`/`CALL BADI` en un método propio y sustitúyelo en la prueba (inyección por constructor o `TEST-SEAM`/`TEST-INJECTION`). SAP ofrece además soporte de dobles de prueba para BAdIs en releases recientes (a confirmar en el sistema antes de usarlo).

## Migrar un BAdI clásico al marco nuevo

| Clásico | Nuevo |
|---|---|
| `CL_EXITHANDLER=>GET_INSTANCE( CHANGING instance = lo_exit )` | `GET BADI lo_badi.` |
| `lo_exit->metodo( … )` | `CALL BADI lo_badi->metodo …` |
| Interfaz `IF_EX_<badi>` | Interfaz propia que hereda de `IF_BADI_INTERFACE` |
| Implementación en SE19 (`ZCL_IM_…`) | Enhancement implementation `ENHO` + implementación de BAdI |
| Filtro por valor de filtro único | Filtros con nombre, varios por BAdI |

SAP ya migró muchos BAdIs clásicos: SE18 indica si un BAdI clásico está "migrado" y cuál es el nuevo. En ese caso, las implementaciones nuevas se crean sobre el BAdI nuevo.

## "Mi implementación no se ejecuta" — diagnóstico

Revisar en este orden:

1. **¿Está activa?** La enhancement implementation **y** la implementación del BAdI dentro de ella tienen cada una su activación.
2. **¿Coincide el filtro?** Comparar los valores de filtro de la implementación con los que pasa el `GET BADI` en tiempo de ejecución (breakpoint en la sentencia).
3. **¿Es el BAdI correcto?** Muchos procesos tienen varios BAdIs parecidos (cabecera vs. posición, online vs. batch, Fiori vs. GUI). Confirmar con el breakpoint por sentencia `GET BADI` que el proceso pasa por él.
4. **¿Uso único con otra implementación activa?** En un BAdI de uso único solo puede haber una activa; si hay otra, la tuya no corre (o la activación falla).
5. **Switch Framework:** el spot o la implementación pueden depender de un switch apagado (SFW5).
6. **¿El código llega a la llamada?** Un `CHECK`/`RETURN` previo en el estándar puede saltar el `GET BADI` según los datos.

## Rendimiento

- `GET BADI` fuera de los bucles cuando el filtro no cambia.
- Nada de `SELECT` por fila dentro de una implementación llamada por posición: precargar en el método de cabecera, si el BAdI lo ofrece, o usar buffers.
- Una implementación por responsabilidad: varias implementaciones pequeñas filtradas se mantienen mejor que una grande con `CASE` por sociedad o país.

## Auditar por SQL (solo lectura, con `GetSqlQuery`) ✅

Tablas y campos verificados en S4D (S/4HANA 2023, 12-oct-2026). Sirven en cualquier sistema, productivo incluido, porque solo leen.

| Tabla | Campos clave | Contenido |
|---|---|---|
| `BADI_MAIN` | `BADI_NAME`, `INTERFACE_NAME`, `SINGLE_USE` (`X` = uso único), `DEFAULT_CLASS` | Definiciones de BAdIs nuevos |
| `BADI_IMPL` | `BADI_NAME`, `ENHNAME`, `BADI_IMPL`, `CLASS_NAME`, `IS_DEFAULT` | Implementación → clase |
| `BADIIMPL_ENH` | `ENHNAME`, `BADI_IMPL`, `BADI_NAME`, `SPOTNAME`, `ACTIVE` | Implementación de BAdI nuevo → `ENHO`, BAdI y spot, y si está activa |
| `SXS_ATTR` | `EXIT_NAME`, `MLTP_USE`, `FLT_TYPE`, `INTERNAL`, `MIG_BADI_NAME`, `MIG_ENHSPOTNAME` | Definiciones de BAdIs clásicos (y a qué BAdI nuevo se migraron) |
| `SXC_EXIT` | `IMP_NAME`, `EXIT_NAME`, `FLT_VAL` | Implementación clásica → BAdI |
| `SXC_ATTR` | `IMP_NAME`, `ACTIVE`, `MIG_ENHNAME` | Atributos de implementaciones clásicas |
| `ENHHEADER` | `ENHNAME`, `VERSION`, `ENHTOOLTYPE` (`BADI_IMPL` o `HOOK_IMPL`) | Cabecera de cada `ENHO`. `HOOK_IMPL` = ampliación de **código fuente** (implícita o explícita) |
| `ENHOBJ` | `ENHNAME`, `OBJ_TYPE`, `OBJ_NAME`, `MAIN_TYPE`, `MAIN_NAME` | Objetos que amplía cada `ENHO` (programa, FUGR/FUNC, CLAS/METH) |
| `ENHINCINX` | `ENHNAME`, `PROGRAMNAME`, `FULL_NAME`, `ENHINCLUDE` | Punto exacto donde se engancha cada ampliación de código |
| `ENHSPOTHEADER` | `ENHSPOT`, `TOOL_TYPE`, `INTERNAL` | Cabecera de spots |
| `I_APIsForCloudDevelopment` (CDS) | `RELEASEDOBJECTTYPE = 'BADI_DEF'`, `RELEASEDOBJECTNAME`, `OBJECTDIRECTORYNAME` (spot) | BAdIs liberados (Nivel A) |

Filtra siempre `VERSION = 'A'` (activa) en las tablas que tienen versión.

### Clasificar una ampliación de código: `ENHINCINX.FULL_NAME`

El **último segmento antes de `\EI`** dice qué tipo de ampliación es:

| Termina en | Tipo | Nivel | Ejemplo real |
|---|---|---|---|
| `\SE:BEGIN\EI` o `\SE:END\EI` | **Implícita** (inicio/fin de FM, método, form, include) | **D** | `\FU:BAL_FILTER_CREATE\SE:BEGIN\EI`, `\TY:CL_SWF_RUN_WIM_LOCAL\ME:GET_MAIN_OBJECT\SE:END\EI` |
| `\EX:<punto>\EI` | **Explícita** (`ENHANCEMENT-POINT` de SAP) | B/D (D si tiene código inline, ver `SKILL.md`) | `\PR:SAPLMRMP\EX:MRM_INVOICE_POST_02\EI` |

Ojo con los anidados: `\EX:…\EN:…\SE:END\EI` es una implícita al final de una ampliación de SAP. Manda el último segmento, así que es **implícita**.

La barra invertida dentro de `LIKE` se toma literal (verificado: `LIKE '%\SE:END\EI'` devuelve lo mismo que `LIKE '%SE:END%'`), así que puedes filtrar por el segmento exacto.

ℹ️ **Largo de línea:** el SQL libre de ADT no admite líneas de más de 255 caracteres (falla con un error de sintaxis engañoso, p. ej. `A Boolean expression was expected`). En ABIX, `GetSqlQuery` ya parte las líneas largas automáticamente. Fuera de ABIX, escribe las consultas largas en varias líneas. Un literal de texto de más de 255 caracteres no se puede partir: divide la condición.

### Consultas probadas

```sql
-- Implícitas del cliente (Nivel D): qué ENHO y dónde se enganchan
SELECT enhname, programname, full_name FROM enhincinx
  WHERE ( enhname LIKE 'Z%' OR enhname LIKE 'Y%' ) AND version = 'A'
    AND ( full_name LIKE '%SE:BEGIN%' OR full_name LIKE '%SE:END%' )

-- Explícitas del cliente (revisar si tienen código inline → D)
SELECT enhname, programname, full_name FROM enhincinx
  WHERE ( enhname LIKE 'Z%' OR enhname LIKE 'Y%' ) AND version = 'A'
    AND full_name LIKE '%EX:%'

-- Implementaciones de BAdI del cliente, y cuáles están sobre BAdIs liberados (A) — el resto es B
SELECT b~enhname, b~badi_name, b~spotname, b~active, a~releasestate
  FROM badiimpl_enh AS b
  LEFT OUTER JOIN i_apisforclouddevelopment AS a
    ON a~releasedobjectname = b~badi_name AND a~releasedobjecttype = 'BADI_DEF'
  WHERE b~enhname LIKE 'Z%' OR b~enhname LIKE 'Y%'

-- ¿Un BAdI es de uso único o múltiple?
SELECT badi_name, interface_name, single_use, default_class FROM badi_main WHERE badi_name = '...'
```

En S4D esto dio 187 `ENHO` Z implícitas, 4 explícitas y 57 implementaciones de BAdI (varias sobre BAdIs liberados). Es el inventario de Nivel D listo para el plan de remediación de `SKILL.md`.

**Uso en ABIX:** con estas consultas sacas el inventario y la clasificación. Para leer el **código** de una ampliación concreta, usa `GetEnhancements` sobre el objeto estándar ampliado (`MAIN_NAME` de `ENHOBJ`) o `GetEnhancementImpl`.
