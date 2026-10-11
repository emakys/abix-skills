# 02 · Tipos de expresión y de acción

Las constantes `IF_FDT_CONSTANTS=>GC_EXTY_*` identifican cada tipo (son IDs fijos, iguales en todo sistema). La columna "Uso" es **orientativa**: conteo de expresiones de almacenamiento sistema (casi todas estándar SAP) medido en **un** S/4HANA 2023 ✅; en otro sistema varía según versión y componentes instalados. Sirve para saber qué tipos conviene dominar primero. Para medirlo en el sistema actual: `SELECT expr_type_id, COUNT(*) FROM fdt_expr_0000s GROUP BY expr_type_id` (y `fdt_expr_0000` para las del mandante).

| Expresión | Constante | Uso (orientativo) | Para qué |
|---|---|---|---|
| **Llamada a procedimiento** (método/FM/proc. BD) | `GC_EXTY_STATIC_METHOD` | **1.193** | Ejecutar ABAP: leer datos, calcular, integrar. La más usada por SAP |
| **Regla** | `GC_EXTY_RULE` | **1.001** | Si condición → acciones (en sets de reglas, loops, reglas anidadas) |
| **Booleano** | `GC_EXTY_BOOLEAN` | 480 | Condiciones combinadas (A y B o C…) |
| **Constante** | `GC_EXTY_CONSTANT` | 403 | Valores fijos con nombre |
| **Tabla de decisión** | `GC_EXTY_DECISION_TABLE` | 324 | Columnas condición → columnas resultado. La de OPD |
| **Fórmula** | `GC_EXTY_FORMULA` | 235 | Cálculo con funciones (fechas, textos, números) |
| **Bucle (loop)** | `GC_EXTY_LOOP` | 150 | Recorrer una tabla del contexto aplicando reglas |
| **Operación de tabla** | `GC_EXTY_TABLE_OPERATION` | 88 | Contar, sumar, existe, mín/máx sobre una tabla |
| **Rango de valores** | `GC_EXTY_RANGE` | 56 | Condición simple sobre un parámetro (usada en reglas) |
| **Búsqueda en BD** (DB lookup) | `GC_EXTY_DB_LOOKUP` | 40 | SELECT simple sobre una tabla (sin FOR ALL ENTRIES) |
| **Case** | `GC_EXTY_CASE` | 20 | Según valor → resultado |
| **Árbol de decisión** | `GC_EXTY_DECISION_TREE` | 13 | Nodos sí/no |
| **Llamada a función BRF+** | `GC_EXTY_FUNCTION_CALL` | 10 | Reusar otra función |
| **Árbol de búsqueda** | `GC_EXTY_SEARCH_TREE` | 2 | Búsqueda jerárquica |
| **Expresión dinámica** | `GC_EXTY_DYNAMIC_EXPRESSION` | 1 | Decide en ejecución qué expresión evaluar |
| Número aleatorio | `GC_EXTY_RANDOM_NUMBER` | — | Muestreo |
| Secuencia / secuencia con área | `GC_EXTY_SEQUENCE`(`_WORKAREA`) | — | Pasos en orden |
| Flujo | `GC_EXTY_FLOW` | — | Flujo de decisión |
| Transformación XSL | `GC_EXTY_XSL_TRANSFORMATION` | — | Transformar XML |
| Conector BRMS | `GC_EXTY_BRMS_CONNECTOR` | — | Llamar a un motor externo (SAP NW BRM Java) |
| Acceso a BO | `GC_EXTY_BO_ACCESS` | — | Leer business objects (p. ej. BOPF) |
| Y/O | `GC_EXTY_AND_OR` | — | Conectores lógicos |

**Tipos de expresión propios de aplicaciones SAP** (objeto `ET`): en el mismo sistema aparecen `METHOD_CALL`, `COMPARE`, `DB_ENRICHMENT`, `SIMPLE_MAPPING`, `MESSAGE_LOG`, `/BOFU/RETRIEVE_BO_DATA`, los `ICL_*` de gestión de reclamaciones de seguros y `BPEM_CASE` (FI-CA). Una aplicación SAP puede traer los suyos; búscalos en `FDT_ADMN_0000S` con `OBJECT_TYPE = 'ET'` ✅.

## Acciones (`GC_EXTY_ACTN_*`) ✅

| Acción | Constante | Uso |
|---|---|---|
| Llamada a método | `GC_EXTY_ACTN_STATIC_METHOD` | 59 en sistema |
| Log de mensajes | `GC_EXTY_ACTN_MESSAGE_LOG` | Mensajes al log de aplicación (SLG1) / a la tabla de acciones |
| Lanzar evento | `GC_EXTY_ACTN_RAISE_EVENT` | Evento de workflow |
| Iniciar workflow | `GC_EXTY_ACTN_START_WORKFLOW` | |
| Correo | `GC_EXTY_ACTN_EMAIL` | |
| Cambio de contexto | `GC_EXTY_ACTN_CONTEXT_CHANGE` | |

Una función que dispara acciones usa como resultado la tabla estándar de acciones `IF_FDT_ACTION=>GC_DOBJ_ACTION_TABLE` (demo `FDT_DEMO_REPORT_RULESET`) ✅.

## Cómo crear cada tipo por API

**Fuente primaria: los programas demo estándar del propio sistema** — cada uno construye una expresión completa por API, la activa y la ejecuta ✅. Léelos con `GetProgram` antes de escribir código para un tipo que no esté en `03`:

| Tipo | Demo estándar |
|---|---|
| Tabla de decisión | `FDT_DEMO_REPORT_DECISION_TABLE`, `FDT_TUTORIAL_DECN_TABLE`, `FDT_TUTORIAL_RANGE_DESCN_TABLE` |
| Árbol de decisión | `FDT_DEMO_REPORT_DECISION_TREE` |
| Árbol de búsqueda | `FDT_DEMO_REPORT_SEARCH_TREE` |
| Booleano | `FDT_DEMO_REPORT_BOOLEAN` |
| Case | `FDT_DEMO_REPORT_CASE` |
| Rango | `FDT_DEMO_REPORT_RANGE_NUM` / `_CHAR` / `_STRING` |
| Regla | `FDT_DEMO_REPORT_RULE` |
| Set de reglas + acciones | `FDT_DEMO_REPORT_RULESET` |
| Bucle + fórmula + rango + reglas | `FDT_DEMO_REPORT_LOOP` |
| Llamada a procedimiento (método y FM) + estructura + tabla | `FDT_DEMO_REPORT_PROC_CALL` |
| Fórmula + constante | `FDT_SDN_FORMULA`, `FDT_SDN_FORMULA_FUNCTION` |
| Escenario completo | `FDT_SDN_BONUS_DETERMINATION`, `FDT_DEMO_COMPANY_CAR`, `FDT_SDN_HELLO_WORLD` |
| Llamada de una función desde ABAP | report generador `FDT_TEMPLATE_FUNCTION_PROCESS` |

Patrones extraídos de esos demos ✅:

```abap
" Árbol de decisión: el árbol trae un nodo raíz; cada nodo lleva una condición (parámetro + rango)
lo_tree ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_decision_tree ).
lv_root = lo_tree->get_root_node( ).
lo_tree->set_node_property( iv_node = lv_root is_range = ls_param_range ).   " s_param_range: parameter_id + ts_range
lo_tree->get_children( EXPORTING iv_parent_node = lv_root IMPORTING ev_true_node = lv_si ev_false_node = lv_no ).

" Case: parámetro + tabla WHEN (valor de prueba → valor de retorno) + OTHERS
lo_case ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_case ).
lo_case->set_case_parameter( lv_param_id ).
lo_case->set_when_table( lts_when ).          " if_fdt_case=>s_when: position, r_test_value, r_return_value
lo_case->set_other_value( lr_valor_por_defecto ).

" Booleano: operandos (rangos o expresiones) + operación (gc_operation_a_and_b, _a_or_b_and_c, …)
lo_bool ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_boolean ).
lo_bool->set_operands( is_first_operand_range = ls_r1 is_second_operand_range = ls_r2 ).
lo_bool->set_operation( iv_operation = if_fdt_boolean=>gc_operation_a_and_b ).

" Rango (condición simple para una regla)
lo_range ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_range ).
lo_range->set_test_parameter( lv_param_id ).
lo_range->set_range( its_range = lts_range ).
lo_rule->set_condition( lo_range->mv_id ).     " alternativa a set_condition_range (ver 03)

" Fórmula: texto con los OPERANDOS POR ID (no por nombre)
lo_formula ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_formula ).
lo_formula->set_formula( |{ lv_monto_id } * 1.19| ).
lo_formula->if_fdt_expression~set_result_data_object( if_fdt_constants=>gc_dobj_element_number ).

" Constante
lo_const ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_constant ).
lo_const->if_fdt_expression~set_result_data_object( iv_id = if_fdt_constants=>gc_dobj_element_text ).
lo_const->set_constant_value( 'X' ).

" Bucle sobre una tabla del contexto con reglas
lo_loop ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_loop ).
lo_loop->set_loop_mode( if_fdt_loop=>gc_loop_mode_for_each ).
lo_loop->set_loop_properties( iv_for_each_table = lv_tabla_id ).
lo_loop->set_rules( lts_rule ).

" Llamada a procedimiento: método estático o FM, con mapeo de parámetros
lo_pc ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_static_method ).
lo_pc->set_call_type( if_fdt_static_method=>gc_call_type_static_method ).   " o gc_call_type_function_module
lo_pc->set_class( iv_class = 'ZCL_…' ).  lo_pc->set_method( iv_method = '…' ).
lo_pc->set_mapping( lts_mapping ).        " move_type: gc_move_type_value / _suppl / _move_corr

" Acción de log de mensajes
lo_actn ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_actn_message_log=>gc_exty_message_log ).
lo_actn->set_messages( lt_msg ).
lo_actn->set_persistency_settings( abap_false ).
lo_rule->set_true_action( lo_actn->mv_id ).    lo_rule->set_false_action( … ).
```

Helpers estándar `CL_FDT_CONVENIENCE` ✅: `CREATE_ELEMENT`, `CREATE_STRUCTURE`, `CREATE_TABLE`, `CREATE_CONSTANT`, `CREATE_FUNCTION`, `CREATE_DOBJ_DDIC`, `CREATE_FUNCTION_W_DDIC_STRUCT`, `CREATE_EMPTY_DECISION_TABLE`, `FILL_DECISION_TABLE`, `CREATE_SIMPLE_RANGE`, `ACTIVATE_OBJECT`, `PROCESS_EXPRESSION`, `GET_FUNCTION_RESULT`, `GET_ALL_FUNCTIONS_FOR_APPL`, `TRANSPORT_APPLICATION`, `CONVERT_TIMEPOINT_TO_DATE_TIME`/`CONVERT_DATE_TIME_TO_TIMEPOINT`. `CL_FDT_SERVICES=>GET_UNIQUE_NAME( )` genera nombres únicos (los demos lo usan para poder correr varias veces).

## Fórmulas: funciones

La fórmula referencia operandos **por ID** de objeto de datos. Familias de funciones (documentación SAP/comunidad; la lista exacta está en el editor de fórmulas del sistema):
- **Fecha/hora:** `DT_ADD_DAYS`, `DT_ADD_MONTHS`, `DT_ADD_WEEKS`, `DT_DURATION_DIFF_*`, `DT_PART_DAYS`, … (operan sobre puntos en el tiempo).
- **Texto:** `CONCATENATE`, `CONDENSE`, `SUBSTRING`, `FIND_SUBSTRING`, `STRING_LENGTH`, `STRING_SIMILARITY`, `EDIT_DISTANCE`, …
- **Lógicas/numéricas:** `IF( cond, a, b )`, aritmética, redondeo, mín/máx.
- Una aplicación puede **agregar funciones propias** a la fórmula por la salida `GET_FORMULA_FUNCTIONALS` (`06`).

## Búsqueda en BD vs. llamada a procedimiento

- **DB lookup**: lectura simple (existe / un valor / varios valores con "All entries"). **No soporta FOR ALL ENTRIES** contra una tabla interna.
- Recomendación de SAP/comunidad: **preparar los datos en ABAP antes** y pasarlos como contexto; o usar una **llamada a procedimiento**. Las reglas no deberían hacer de capa de acceso a datos.
- Con BD secundaria configurada en la aplicación, la llamada a procedimiento de BD y la vista BD dinámica apuntan a esa BD.

## DSM y tipos no soportados

En **Decision Service Management** (despliegue remoto, `06`) no se soportan: conector BRMS, expresión dinámica, secuencia de pasos y transformación XSL.
