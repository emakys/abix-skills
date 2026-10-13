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

## Tablas del sistema útiles para auditar (SQL de solo lectura) — **(a confirmar)**

Antes de depender de estas tablas, verifica en el sistema que existen y cuáles son sus campos (`SELECT … UP TO 1 ROWS`):

| Tabla | Contenido esperado |
|---|---|
| `SXS_ATTR` | Definiciones de BAdIs clásicos |
| `SXC_EXIT` | Implementación clásica → BAdI (`IMP_NAME`, `EXIT_NAME`) |
| `SXC_ATTR` | Atributos de implementaciones clásicas (incluido si están activas) |
| `BADIIMPL_ENH` | Implementación de BAdI nuevo → enhancement implementation y BAdI |
| `ENHHEADER` | Cabecera de enhancement implementations (`ENHO`) |
| `ENHOBJ` | Objetos ampliados por cada enhancement implementation |
| `TADIR` (`OBJECT = 'ENHO'`, nombre Z/Y) | Inventario de ampliaciones del cliente por paquete |

Uso típico en ABIX: inventariar las `ENHO` Z/Y de un paquete con `TADIR`, y para las que tocan código estándar abrir cada objeto con `GetEnhancements` para clasificar su nivel (implícita = D, explícita con código inline = D, implementación de BAdI = A/B).
