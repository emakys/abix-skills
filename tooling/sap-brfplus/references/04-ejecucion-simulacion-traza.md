# 04 · Ejecución, simulación, traza y rendimiento

## Llamar una función desde ABAP

Genera siempre el esqueleto con el report estándar **`FDT_TEMPLATE_FUNCTION_PROCESS`** (pide el ID de la función y escribe la llamada con los tipos correctos) ✅.

### Forma 1 — `CL_FDT_FUNCTION_PROCESS=>PROCESS` (estática, la habitual) ✅

```abap
DATA lt_nv TYPE abap_parmbind_tab.
DATA lr    TYPE REF TO data.

" Referencia TIPADA para cada objeto del contexto (no adivines el tipo)
cl_fdt_function_process=>get_data_object_reference(
  EXPORTING iv_function_id = lv_fu iv_data_object = lv_do_id      " ID o nombre
  IMPORTING er_data = lr ev_data_object_name = DATA(lv_nm) ).
ASSIGN lr->* TO FIELD-SYMBOL(<lv>).  <lv> = valor.
INSERT VALUE #( name = lv_nm value = lr ) INTO TABLE lt_nv.

" Resultado tipado
cl_fdt_function_process=>get_data_object_reference(
  EXPORTING iv_function_id = lv_fu iv_data_object = lo_fu->get_result_data_object( )
  IMPORTING er_data = DATA(lr_res) ).
ASSIGN lr_res->* TO FIELD-SYMBOL(<ls_res>).

cl_fdt_function_process=>process(
  EXPORTING iv_function_id = lv_fu
            iv_timestamp   = lv_ts            " opcional: ejecutar la versión vigente en ese momento
  IMPORTING ea_result      = <ls_res>
  CHANGING  ct_name_value  = lt_nv ).
```

Parámetros de `PROCESS` (verificados): `IV_FUNCTION_ID`, `IV_TIMESTAMP`, `IO_CONTEXT`, `CT_NAME_VALUE`, **`ITS_ID_VALUE`** (contexto por ID: más rápido, sin instanciar contexto), `IV_TRACE_MODE`, `EO_TRACE`, `EA_RESULT` ✅.

Otros métodos útiles de `CL_FDT_FUNCTION_PROCESS` ✅: `MOVE_DATA_TO_DATA_OBJECT`, `GET_CONTEXT_LIST`, `GET_CONTEXT_VALUE`, `GET_GENERATED_CLASS_NAME` (qué clase `/FDT/…` generó), `GET_PROCESS_LOG`, `CLEAR_BUFFERS`, `PROCESS_INTERPRETATION_MODE`.

### Forma 2 — objeto función + contexto ✅

```abap
DATA(lo_ctx) = lo_fu->get_process_context( ).
lo_ctx->set_value( iv_id = lv_pais_id ia_value = CONV if_fdt_types=>element_text( 'CO' ) ).
lo_fu->process( EXPORTING io_context = lo_ctx IMPORTING eo_result = DATA(lo_result) ).
lo_result->get_value( IMPORTING ea_value = lv_res ).
```

Es la forma de los demos estándar; necesaria para objetos en memoria (simulación).

### Contexto con estructuras DDIC ✅

Para pasar una fila real (`T001`, `VBRK`…) a una estructura BRF+ ligada al DDIC **no uses `MOVE-CORRESPONDING`**: BRF+ tradujo los tipos (fecha/hora → `ELEMENT_TIMEPOINT`, estructura) y la conversión dumpea sin poder capturarse. Copia componente a componente solo los elementales (`cl_abap_typedescr=>kind_elem`). Ver `templates/ejecutar-con-contexto-ddic.clas.abap`.

## Simular sin grabar nada ✅

BRF+ puede **activar en memoria y ejecutar sin `save`**:

1. Fábrica sobre la **aplicación temporal**: `get_instance( if_fdt_constants=>gc_application_tmp )`.
2. Crear elementos (`cl_fdt_convenience=>create_element( iv_application_id = gc_application_tmp … )`), expresiones y función como siempre (nombre con `cl_fdt_services=>get_unique_name( )`).
3. `activate( iv_deep = abap_true )` — **sin `save`**.
4. Ejecutar con la forma 2 (contexto del objeto función).
5. `dequeue`.

Medido: conteo de `FDT_ADMN_0000` idéntico antes y después, y la tabla de decisión decidió correctamente ✅. Es la base del botón "Simular" de ABIX: probar reglas nuevas **sin crear nada en SAP** (solo hace falta poder ejecutar una clase, igual que cualquier classrun).

## Simulación en el workbench

En `BRF+`: función → *Simular*: ingresas valores del contexto (o importas de Excel) y ves resultado y pasos. Corre **en modo interpretación** y no persiste nada; por eso **sus tiempos no reflejan producción** (genera la función antes si quieres medir).

## Trazas

| Traza | Para qué | Notas |
|---|---|---|
| **Técnica** | Depurar: todos los pasos, valores intermedios | Solo en interpretación (la usa la simulación); `PROCESS( iv_trace_mode … IMPORTING eo_trace )`. **No** para medir rendimiento |
| **Lean trace** | Auditoría en producción: registrar cada ejecución con poco costo | Integrada en el código generado; **requiere versionado**; ejecutar antes el *readiness check* a nivel función; grabar trazas en lotes (el llamador decide cuándo escribir). Transacción `FDT_LEAN_TRACE` ✅, interfaz `IF_FDT_LEAN_TRACE` ✅ |

Otras transacciones de seguimiento ✅: `FDT_PROCESS_LOG`, `FDT_DEPLOYMENT_LOG`, `FDT_TEST_SUITE` (casos de prueba), `FDT_SHOW_DB`.

## Rendimiento

- **Generación de código vs. interpretación**: es el factor dominante. Si BRF+ cae a interpretación, la penalidad es enorme (la documentación habla de **×500 o más** cuando una expresión tiene que cargarse). Se detecta en el depurador por el constructor de `CL_FDT_MAINTENANCE`.
- Elementos **número** antes que importe/cantidad.
- Contexto por **`ITS_ID_VALUE`** en lugar de instanciar contexto.
- **Orden de filas**: lo más frecuente arriba.
- Volumen: agrupar llamadas (RFC/web service de a cientos o miles de registros); BRF+ admite procesamiento en paralelo.
- Datos: prepararlos en ABAP y pasarlos como contexto; no convertir las reglas en capa de acceso a BD (`02`).
- Tablas de decisión enormes (miles de filas): funcionan, pero el workbench se vuelve lento para mantenerlas; considera Excel (`06`) o dividir.
