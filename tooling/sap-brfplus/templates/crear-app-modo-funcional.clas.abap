CLASS zcl_abix_brf_tpl_funcional DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    CONSTANTS gc_app_name TYPE if_fdt_types=>name VALUE 'ZABIX_BRF_POC'.
    DATA mo_out TYPE REF TO if_oo_adt_classrun_out.
    DATA mt_data TYPE if_fdt_decision_table=>ts_table_data.
    METHODS msgs
      IMPORTING iv_step TYPE string
                it_msg  TYPE if_fdt_types=>t_message.
    METHODS new_element
      IMPORTING io_factory   TYPE REF TO if_fdt_factory
                iv_name      TYPE if_fdt_types=>name
                iv_type      TYPE if_fdt_types=>element_type
      RETURNING VALUE(rv_id) TYPE if_fdt_types=>id
      RAISING   cx_fdt.
    METHODS find_object
      IMPORTING iv_app       TYPE if_fdt_types=>id OPTIONAL
                iv_name      TYPE if_fdt_types=>name
                iv_type      TYPE if_fdt_types=>object_type
      RETURNING VALUE(rv_id) TYPE if_fdt_types=>id.
    METHODS cond
      IMPORTING iv_col TYPE i
                iv_row TYPE i
                iv_opt TYPE if_fdt_range=>option
                ir_val TYPE REF TO data.
    METHODS res
      IMPORTING iv_row TYPE i
                iv_val TYPE string.
    METHODS run_case
      IMPORTING iv_fu    TYPE if_fdt_types=>id
                iv_pais  TYPE if_fdt_types=>element_text
                iv_monto TYPE if_fdt_types=>element_number.
ENDCLASS.



CLASS zcl_abix_brf_tpl_funcional IMPLEMENTATION.

  METHOD msgs.
    LOOP AT it_msg INTO DATA(ls_m).
      mo_out->write( |  [{ iv_step }] { ls_m-msgty } { ls_m-text }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD find_object.
    IF iv_app IS INITIAL.
      SELECT SINGLE id FROM fdt_admn_0000 WHERE name = @iv_name AND object_type = @iv_type AND deleted = @abap_false INTO @rv_id.
    ELSE.
      SELECT SINGLE id FROM fdt_admn_0000 WHERE application_id = @iv_app AND name = @iv_name AND object_type = @iv_type AND deleted = @abap_false INTO @rv_id.
    ENDIF.
  ENDMETHOD.

  METHOD new_element.
    DATA lo_el TYPE REF TO if_fdt_element.
    lo_el ?= io_factory->get_data_object( iv_data_object_type = if_fdt_constants=>gc_data_object_type_element ).
    lo_el->if_fdt_transaction~enqueue( ).
    lo_el->if_fdt_admin_data~set_name( iv_name ).
    lo_el->set_element_type( iv_type ).
    rv_id = lo_el->mv_id.
    mo_out->write( |ELEMENT { iv_name } = { rv_id }| ).
  ENDMETHOD.

  METHOD cond.
    INSERT VALUE #( col_no = iv_col row_no = iv_row
                    ts_range = VALUE #( ( position = 1 sign = 'I' option = iv_opt r_low_value = ir_val ) ) ) INTO TABLE mt_data.
  ENDMETHOD.

  METHOD res.
    DATA(lr) = NEW if_fdt_types=>element_text( iv_val ).
    INSERT VALUE #( col_no = 3 row_no = iv_row r_value = lr ) INTO TABLE mt_data.
  ENDMETHOD.

  METHOD run_case.
    DATA lt_nv  TYPE abap_parmbind_tab.
    DATA lv_res TYPE if_fdt_types=>element_text.
    DATA(lv_pais)  = iv_pais.
    DATA(lv_monto) = iv_monto.
    lt_nv = VALUE #( ( name = 'PAIS'  value = REF #( lv_pais ) )
                     ( name = 'MONTO' value = REF #( lv_monto ) ) ).
    TRY.
        cl_fdt_function_process=>process(
          EXPORTING iv_function_id = iv_fu
          IMPORTING ea_result      = lv_res
          CHANGING  ct_name_value  = lt_nv ).
        mo_out->write( |CASO PAIS={ iv_pais } MONTO={ iv_monto } -> APROBADOR={ lv_res }| ).
      CATCH cx_fdt INTO DATA(lx).
        mo_out->write( |CASO PAIS={ iv_pais } MONTO={ iv_monto } -> ERROR { lx->get_text( ) }| ).
        LOOP AT lx->mt_message INTO DATA(ls_m).
          mo_out->write( |  { ls_m-msgty } { ls_m-text }| ).
        ENDLOOP.
    ENDTRY.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    " ABIX PoC BRF+ via A: crear por API una aplicacion local ($TMP) completa y ejecutarla.
    mo_out = out.
    DATA lo_app TYPE REF TO if_fdt_application.
    DATA lo_dt  TYPE REF TO if_fdt_decision_table.
    DATA lo_fu  TYPE REF TO if_fdt_function.
    DATA lt_msg TYPE if_fdt_types=>t_message.
    DATA lv_failed TYPE abap_bool.
    DATA lv_fu_id TYPE if_fdt_types=>id.

    DATA(lv_app) = find_object( iv_name = gc_app_name iv_type = 'AP' ).
    IF lv_app IS NOT INITIAL.
      out->write( |APP YA EXISTE { lv_app } -> solo pruebas| ).
      lv_fu_id = find_object( iv_app = lv_app iv_name = 'FU_APROBADOR' iv_type = 'FU' ).
    ELSE.
      TRY.
          " 1. Aplicacion local
          lo_app = cl_fdt_factory=>if_fdt_factory~get_instance( )->get_application( ).
          lo_app->if_fdt_transaction~enqueue( ).
          lo_app->create_local_application( ).
          lo_app->if_fdt_admin_data~set_name( gc_app_name ).
          lo_app->if_fdt_admin_data~set_texts( iv_text = 'ABIX PoC: aprobador por pais y monto' ).
          lo_app->if_fdt_transaction~activate( IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
          msgs( iv_step = 'APP activate' it_msg = lt_msg ).
          lo_app->if_fdt_transaction~save( ).
          lo_app->if_fdt_transaction~dequeue( ).
          lv_app = lo_app->mv_id.
          out->write( |APP { gc_app_name } = { lv_app } (activacion fallida: { lv_failed })| ).

          " 2. Objetos de datos
          DATA(lo_factory) = cl_fdt_factory=>if_fdt_factory~get_instance( lv_app ).
          DATA(lv_pais)  = new_element( io_factory = lo_factory iv_name = 'PAIS'      iv_type = if_fdt_constants=>gc_element_type_text ).
          DATA(lv_monto) = new_element( io_factory = lo_factory iv_name = 'MONTO'     iv_type = if_fdt_constants=>gc_element_type_number ).
          DATA(lv_aprob) = new_element( io_factory = lo_factory iv_name = 'APROBADOR' iv_type = if_fdt_constants=>gc_element_type_text ).

          " 3. Tabla de decision: CO<=1000 JEFE | CO>1000 GERENTE | MX GERENTE_MX | resto REVISION_MANUAL
          lo_dt ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_decision_table ).
          lo_dt->if_fdt_transaction~enqueue( ).
          lo_dt->if_fdt_admin_data~set_name( 'DT_APROBADOR' ).
          lo_dt->set_columns( VALUE #( ( col_no = 1 object_id = lv_pais )
                                       ( col_no = 2 object_id = lv_monto )
                                       ( col_no = 3 object_id = lv_aprob is_result = abap_true ) ) ).
          DATA(r_co)   = NEW if_fdt_types=>element_text( `CO` ).
          DATA(r_mx)   = NEW if_fdt_types=>element_text( `MX` ).
          DATA(r_1000) = NEW if_fdt_types=>element_number( 1000 ).
          cond( iv_col = 1 iv_row = 1 iv_opt = 'EQ' ir_val = r_co ).
          cond( iv_col = 2 iv_row = 1 iv_opt = 'LE' ir_val = r_1000 ).
          res( iv_row = 1 iv_val = `JEFE` ).
          cond( iv_col = 1 iv_row = 2 iv_opt = 'EQ' ir_val = r_co ).
          cond( iv_col = 2 iv_row = 2 iv_opt = 'GT' ir_val = r_1000 ).
          res( iv_row = 2 iv_val = `GERENTE` ).
          cond( iv_col = 1 iv_row = 3 iv_opt = 'EQ' ir_val = r_mx ).
          res( iv_row = 3 iv_val = `GERENTE_MX` ).
          res( iv_row = 4 iv_val = `REVISION_MANUAL` ).
          lo_dt->set_table_data( mt_data ).
          lo_dt->if_fdt_expression~set_result_data_object( lv_aprob ).
          DATA(lv_dt) = lo_dt->mv_id.
          out->write( |DT DT_APROBADOR = { lv_dt }| ).

          " 4. Funcion (modo funcional): contexto PAIS+MONTO, resultado APROBADOR, expresion superior = DT
          lo_fu ?= lo_factory->get_function( ).
          lo_fu->if_fdt_transaction~enqueue( ).
          lo_fu->if_fdt_admin_data~set_name( 'FU_APROBADOR' ).
          lo_fu->set_context_data_objects( VALUE #( ( lv_pais ) ( lv_monto ) ) ).
          lo_fu->set_result_data_object( lv_aprob ).
          lo_fu->set_function_mode( if_fdt_function=>gc_mode_functional ).
          lo_fu->set_expression( lv_dt ).
          lv_fu_id = lo_fu->mv_id.
          out->write( |FU FU_APROBADOR = { lv_fu_id }| ).

          " 5. Verificar + activar + grabar en profundidad desde la funcion
          msgs( iv_step = 'FU check' it_msg = lo_fu->if_fdt_transaction~check( iv_deep = abap_true ) ).
          lo_fu->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                              IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
          msgs( iv_step = 'FU activate' it_msg = lt_msg ).
          out->write( |ACTIVACION FALLIDA: { lv_failed }| ).
          lo_fu->if_fdt_transaction~save( iv_deep = abap_true ).
          lo_fu->if_fdt_transaction~dequeue( iv_deep = abap_true ).
          out->write( `GRABADO` ).
        CATCH cx_fdt INTO DATA(lx).
          out->write( |ERROR CREACION: { lx->get_text( ) }| ).
          LOOP AT lx->mt_message INTO DATA(ls_m).
            out->write( |  { ls_m-msgty } { ls_m-text }| ).
          ENDLOOP.
          RETURN.
      ENDTRY.
    ENDIF.

    " 6. Ejecutar casos
    IF lv_fu_id IS INITIAL.
      out->write( `SIN FUNCION` ).
      RETURN.
    ENDIF.
    run_case( iv_fu = lv_fu_id iv_pais = `CO` iv_monto = 500 ).
    run_case( iv_fu = lv_fu_id iv_pais = `CO` iv_monto = 5000 ).
    run_case( iv_fu = lv_fu_id iv_pais = `CO` iv_monto = 1500 ).
    run_case( iv_fu = lv_fu_id iv_pais = `MX` iv_monto = 1 ).
    run_case( iv_fu = lv_fu_id iv_pais = `PE` iv_monto = 10 ).
  ENDMETHOD.

ENDCLASS.
