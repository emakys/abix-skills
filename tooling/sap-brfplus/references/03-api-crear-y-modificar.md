# 03 · API: crear y modificar (código verificado)

Todo este archivo se ejecutó en un S/4HANA 2023 ✅ (clases classrun en `$TMP`). Las plantillas completas están en `templates/`.

## Patrón general

```abap
DATA(lo_factory) = cl_fdt_factory=>if_fdt_factory~get_instance( lv_app_id ).   " fábrica atada a la aplicación
lo_obj ?= lo_factory->get_xxx( … ).                                             " sin ID = objeto NUEVO
lo_obj->if_fdt_transaction~enqueue( ).
lo_obj->if_fdt_admin_data~set_name( 'NOMBRE' ).                                 " único dentro de la aplicación
… setters …
" al final, desde el objeto raíz (función):
lo_fu->if_fdt_transaction~check( iv_deep = abap_true ).                         " mensajes I/W/E
lo_fu->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                    IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
lo_fu->if_fdt_transaction~save( iv_deep = abap_true ).                          " COMMIT propio
lo_fu->if_fdt_transaction~dequeue( iv_deep = abap_true ).
```

Los mismos métodos `GET_*` de `IF_FDT_FACTORY` sirven para **leer** (con `iv_id`) y **crear** (sin `iv_id`). Errores: `CX_FDT` y subclases (`CX_FDT_INPUT`), con `mt_message` detallado.

## 1. Aplicación ✅

```abap
DATA(lo_app) = CAST if_fdt_application( cl_fdt_factory=>if_fdt_factory~get_instance( )->get_application( ) ).
lo_app->if_fdt_transaction~enqueue( ).
lo_app->create_local_application( ).                 " $TMP; o create_customizing_application( ) + set_development_package( )
lo_app->if_fdt_admin_data~set_name( 'ZMI_APP' ).
lo_app->if_fdt_admin_data~set_texts( iv_text = 'Descripción' ).
lo_app->if_fdt_transaction~activate( IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
lo_app->if_fdt_transaction~save( ).
lo_app->if_fdt_transaction~dequeue( ).
lv_app_id = lo_app->mv_id.
```

## 2. Elementos ✅

```abap
DATA lo_el TYPE REF TO if_fdt_element.
lo_el ?= lo_factory->get_data_object( iv_data_object_type = if_fdt_constants=>gc_data_object_type_element ).
lo_el->if_fdt_transaction~enqueue( ).
lo_el->if_fdt_admin_data~set_name( 'PAIS' ).
lo_el->set_element_type( if_fdt_constants=>gc_element_type_text ).     " _number, _boolean, _amount, _quantity, _timepoint
" o ligarlo al DDIC (toma tipo, longitud, textos):
lo_el->if_fdt_data_object~set_ddic_binding( iv_ddic_typename = 'BLART' ).
```

## 3. Estructura con binding DDIC ✅

```abap
DATA lo_st TYPE REF TO if_fdt_structure.
lo_st ?= lo_factory->get_data_object( iv_data_object_type = if_fdt_constants=>gc_data_object_type_structure ).
lo_st->if_fdt_transaction~enqueue( ).
lo_st->if_fdt_admin_data~set_name( 'S_SOCIEDAD' ).
lo_st->if_fdt_data_object~set_ddic_binding( EXPORTING iv_ddic_typename = 'T001'
                                            IMPORTING ets_object_id   = DATA(lts_creados) ).  " un elemento por campo
" ID de un componente (para usarlo en una columna de tabla de decisión):
LOOP AT lo_st->get_elements( ) INTO DATA(ls_e).
  IF cl_fdt_factory=>if_fdt_factory~get_instance( )->get_data_object( iv_id = ls_e-element_id )->if_fdt_admin_data~get_name( ) = 'LAND1'.
    lv_land1 = ls_e-element_id.
  ENDIF.
ENDLOOP.
```

Tabla: `gc_data_object_type_table` + `CAST if_fdt_table( … )->set_structure( lv_estructura_o_elemento_id )` (demos `FDT_DEMO_REPORT_LOOP`/`_PROC_CALL`).

## 4. Tabla de decisión ✅

```abap
DATA lo_dt   TYPE REF TO if_fdt_decision_table.
DATA lt_data TYPE if_fdt_decision_table=>ts_table_data.
lo_dt ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_decision_table ).
lo_dt->if_fdt_transaction~enqueue( ).
lo_dt->if_fdt_admin_data~set_name( 'DT_APROBADOR' ).
lo_dt->set_columns( VALUE #( ( col_no = 1 object_id = lv_pais )
                             ( col_no = 2 object_id = lv_monto )
                             ( col_no = 3 object_id = lv_aprob is_result = abap_true ) ) ).
" Celda condición: ts_range (position/sign/option/r_low_value[/r_high_value]); valores como REF al tipo BRF+
INSERT VALUE #( col_no = 1 row_no = 1 ts_range = VALUE #( ( position = 1 sign = 'I' option = 'EQ'
                r_low_value = NEW if_fdt_types=>element_text( `CO` ) ) ) ) INTO TABLE lt_data.
INSERT VALUE #( col_no = 2 row_no = 1 ts_range = VALUE #( ( position = 1 sign = 'I' option = 'LE'
                r_low_value = NEW if_fdt_types=>element_number( 1000 ) ) ) ) INTO TABLE lt_data.
" Celda resultado: r_value
INSERT VALUE #( col_no = 3 row_no = 1 r_value = NEW if_fdt_types=>element_text( `JEFE` ) ) INTO TABLE lt_data.
" Fila comodín: solo la celda resultado (las de condición NO se insertan)
INSERT VALUE #( col_no = 3 row_no = 2 r_value = NEW if_fdt_types=>element_text( `REVISION` ) ) INTO TABLE lt_data.
lo_dt->set_table_data( lt_data ).
lo_dt->if_fdt_expression~set_result_data_object( lv_aprob ).      " ⚠️ con prefijo de interfaz
```

Opciones de rango: constantes `IF_FDT_DECISION_TABLE=>GC_OPTION_*` (`EQUAL`, `NOT_EQUAL`, `LESS(_EQUAL)`, `GREATER(_EQUAL)`, `BETWEEN`, `NOT_BETWEEN`, `CONTAINS_PATTERN`, `INITIAL`, `NOT_INITIAL`, …). Propiedades de la tabla: `set_table_property( iv_multiple_match = …, iv_allow_no_match = … )` (sin *allow no match*, una entrada sin fila coincidente lanza `CX_FDT` "No match found for the given context (DT_…)" — útil como diagnóstico).

## 5. Función en modo funcional ✅

```abap
DATA lo_fu TYPE REF TO if_fdt_function.
lo_fu ?= lo_factory->get_function( ).
lo_fu->if_fdt_transaction~enqueue( ).
lo_fu->if_fdt_admin_data~set_name( 'FU_APROBADOR' ).
lo_fu->set_context_data_objects( VALUE #( ( lv_pais ) ( lv_monto ) ) ).
lo_fu->set_result_data_object( lv_aprob ).
lo_fu->set_function_mode( if_fdt_function=>gc_mode_functional ).
lo_fu->set_expression( lo_dt->mv_id ).                              " expresión de nivel superior
" check / activate / save / dequeue en profundidad desde la función
```

## 6. Modo evento: set de reglas + reglas ✅

```abap
lo_fu->set_function_mode( if_fdt_function=>gc_mode_event ).          " sin set_expression

" Regla sin condición: APROBADOR := resultado de la tabla de decisión
DATA lo_ru1 TYPE REF TO if_fdt_rule.
lo_ru1 ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_rule ).
lo_ru1->if_fdt_transaction~enqueue( ).
lo_ru1->if_fdt_admin_data~set_name( 'RU_PROCESS_DT' ).
lo_ru1->set_true_action_extended(
  it_expression_assignment = VALUE #( ( position = 1 expression = lo_dt->mv_id target_data_object = lv_aprob ) ) ).

" Regla con condición sobre un parámetro: si MONTO > 50000 → APROBADOR := 'DIRECTOR'
DATA lo_ru2 TYPE REF TO if_fdt_rule.
lo_ru2 ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_rule ).
lo_ru2->if_fdt_transaction~enqueue( ).
lo_ru2->if_fdt_admin_data~set_name( 'RU_MONTO_ALTO' ).
lo_ru2->set_condition_range( VALUE #( parameter_id = lv_monto
  ts_range = VALUE #( ( position = 1 sign = 'I' option = 'GT' r_low_value = NEW if_fdt_types=>element_number( 50000 ) ) ) ) ).
lo_ru2->set_true_action_extended(
  it_value_assignment = VALUE #( ( position = 1 data_object = lv_aprob r_value = NEW if_fdt_types=>element_text( `DIRECTOR` ) ) ) ).

" Set de reglas: apunta a la función; reglas ordenadas y ENCENDIDAS
DATA lo_rs TYPE REF TO if_fdt_ruleset.
lo_rs ?= lo_factory->get_ruleset( ).
lo_rs->if_fdt_transaction~enqueue( ).
lo_rs->if_fdt_admin_data~set_name( 'RS_APROBADOR' ).
lo_rs->set_function_restriction( lo_fu->mv_id ).
lo_rs->set_rules( VALUE #( ( position = 1 rule_id = lo_ru1->mv_id switch = if_fdt_ruleset=>gc_switch_on )
                           ( position = 2 rule_id = lo_ru2->mv_id switch = if_fdt_ruleset=>gc_switch_on ) ) ).
lo_rs->set_ruleset_switch( if_fdt_ruleset=>gc_switch_on ).
" activar/grabar la FUNCIÓN y el SET DE REGLAS por separado (iv_deep = abap_true en ambos)
```

Acciones de una regla (`set_true_action_extended` / `set_false_action_extended`):
- `it_value_assignment` — objeto de datos := valor fijo.
- `it_data_object_assignment` — objeto := otro objeto.
- `it_expression_assignment` — objeto := resultado de una expresión (p. ej. tabla de decisión). Es el patrón de OPD (`RU_PROCESS_DT_*`).
- `it_expression` — evaluar una expresión (con `change_mode` sobre el contexto).
- `it_rule` — reglas anidadas.
- `it_action` — acciones (log, correo, workflow…).
- Forma simple: `set_true_action( id )` / `set_false_action( id )` (demo `FDT_DEMO_REPORT_RULESET`).

Condición de la regla: `set_condition_range` (parámetro + rangos) o `set_condition( id )` con un booleano o un rango (`02`).

Set de reglas, además: `set_ruleset_condition( iv_condition_id | is_condition_range )` (solo corre si se cumple), `set_ruleset_priority`, `set_ruleset_variables`, `set_ruleset_initializations`; en `s_rule`: `exit_ruleset` (salir del set al cumplirse), `valid_from`/`valid_to`.

## 7. Modificar existentes por XML ✅

1. `cl_fdt_factory=>if_fdt_factory~get_instance( )->get_data_exchange( )->export_xml_application( iv_application_id ) → ev_string`.
2. Editar el XML (`05` describe el formato: `TABLE_DATA`, `PACKED`, `ROW_COUNT`).
3. `import_xml( iv_string iv_simulate = abap_true iv_create = abap_true iv_activate = abap_true )` → revisar `ets_failure`/`et_message`.
4. Si limpio, repetir con `iv_simulate = abap_false` (+ `iv_customizing_trrequest`/`iv_workbench_trrequest` si la app es transportable).

Errores de la simulación son claros (p. ej. "Invalid range option ZZ" / "Option ZZ is not allowed for test parameter Element 'PAIS'") y la simulación fallida no toca la aplicación ✅.

Para cambios puntuales de una tabla de decisión también sirve la API: `get_expression( iv_id )` → `enqueue` → `get_table_data`/`set_table_data` o `insert_rows`/`delete_rows`/`move_rows` → activar/grabar.

## Cuándo usar API y cuándo XML

| Caso | Camino |
|---|---|
| Crear una aplicación/función nueva | **API** (simple, BRF+ valida cada paso, sin GUIDs que fabricar) |
| Modificar algo existente | **XML** (export → editar → import simulado → import real; diffeable en el repo) o API puntual |
| Llevar entre sistemas sin transporte | XML (`FDT_XML_EXPORT` / `FDT_XML_IMPORT`) |
