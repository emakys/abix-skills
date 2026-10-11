CLASS zcl_abix_brf_tpl_evento DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    DATA mo_out TYPE REF TO if_oo_adt_classrun_out.
    METHODS find
      IMPORTING iv_app       TYPE if_fdt_types=>id
                iv_name      TYPE if_fdt_types=>name
                iv_type      TYPE if_fdt_types=>object_type
      RETURNING VALUE(rv_id) TYPE if_fdt_types=>id.
    METHODS msgs
      IMPORTING iv_step TYPE string
                it_msg  TYPE if_fdt_types=>t_message.
    METHODS run_case
      IMPORTING iv_fu    TYPE if_fdt_types=>id
                iv_pais  TYPE if_fdt_types=>element_text
                iv_monto TYPE if_fdt_types=>element_number.
ENDCLASS.



CLASS zcl_abix_brf_tpl_evento IMPLEMENTATION.

  METHOD find.
    SELECT SINGLE id FROM fdt_admn_0000
      WHERE application_id = @iv_app AND name = @iv_name AND object_type = @iv_type AND deleted = @abap_false
      INTO @rv_id.
  ENDMETHOD.

  METHOD msgs.
    LOOP AT it_msg INTO DATA(ls_m).
      mo_out->write( |  [{ iv_step }] { ls_m-msgty } { ls_m-text }| ).
    ENDLOOP.
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
    " ABIX PoC BRF+ modo EVENTO: funcion + set de reglas + 2 reglas sobre la app ZABIX_BRF_POC.
    CONSTANTS lc_app TYPE if_fdt_types=>id VALUE '<ID_APLICACION_32>'.
    mo_out = out.
    DATA lo_fu  TYPE REF TO if_fdt_function.
    DATA lo_rs  TYPE REF TO if_fdt_ruleset.
    DATA lo_ru1 TYPE REF TO if_fdt_rule.
    DATA lo_ru2 TYPE REF TO if_fdt_rule.
    DATA lt_msg TYPE if_fdt_types=>t_message.
    DATA lv_failed TYPE abap_bool.

    DATA(lv_fu) = find( iv_app = lc_app iv_name = 'FU_APROBADOR_EV' iv_type = 'FU' ).
    IF lv_fu IS INITIAL.
      DATA(lv_pais)  = find( iv_app = lc_app iv_name = 'PAIS'         iv_type = 'DO' ).
      DATA(lv_monto) = find( iv_app = lc_app iv_name = 'MONTO'        iv_type = 'DO' ).
      DATA(lv_aprob) = find( iv_app = lc_app iv_name = 'APROBADOR'    iv_type = 'DO' ).
      DATA(lv_dt)    = find( iv_app = lc_app iv_name = 'DT_APROBADOR' iv_type = 'EX' ).
      out->write( |PAIS={ lv_pais } MONTO={ lv_monto } APROBADOR={ lv_aprob } DT={ lv_dt }| ).
      TRY.
          DATA(lo_factory) = cl_fdt_factory=>if_fdt_factory~get_instance( lc_app ).

          " 1. Funcion en modo EVENTO (sin expresion de nivel superior)
          lo_fu ?= lo_factory->get_function( ).
          lo_fu->if_fdt_transaction~enqueue( ).
          lo_fu->if_fdt_admin_data~set_name( 'FU_APROBADOR_EV' ).
          lo_fu->set_context_data_objects( VALUE #( ( lv_pais ) ( lv_monto ) ) ).
          lo_fu->set_result_data_object( lv_aprob ).
          lo_fu->set_function_mode( if_fdt_function=>gc_mode_event ).
          lv_fu = lo_fu->mv_id.
          out->write( |FU FU_APROBADOR_EV = { lv_fu }| ).

          " 2. Regla 1 (sin condicion): APROBADOR := resultado de DT_APROBADOR
          lo_ru1 ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_rule ).
          lo_ru1->if_fdt_transaction~enqueue( ).
          lo_ru1->if_fdt_admin_data~set_name( 'RU_PROCESS_DT' ).
          lo_ru1->set_true_action_extended(
            it_expression_assignment = VALUE #( ( position = 1 expression = lv_dt target_data_object = lv_aprob ) ) ).
          out->write( |RU RU_PROCESS_DT = { lo_ru1->mv_id }| ).

          " 3. Regla 2 (si MONTO > 50000): APROBADOR := 'DIRECTOR'
          lo_ru2 ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_rule ).
          lo_ru2->if_fdt_transaction~enqueue( ).
          lo_ru2->if_fdt_admin_data~set_name( 'RU_MONTO_ALTO' ).
          lo_ru2->set_condition_range( VALUE #( parameter_id = lv_monto
            ts_range = VALUE #( ( position = 1 sign = 'I' option = 'GT'
                                  r_low_value = NEW if_fdt_types=>element_number( 50000 ) ) ) ) ).
          lo_ru2->set_true_action_extended(
            it_value_assignment = VALUE #( ( position = 1 data_object = lv_aprob
                                             r_value = NEW if_fdt_types=>element_text( `DIRECTOR` ) ) ) ).
          out->write( |RU RU_MONTO_ALTO = { lo_ru2->mv_id }| ).

          " 4. Set de reglas asignado a la funcion, con las 2 reglas en orden
          lo_rs ?= lo_factory->get_ruleset( ).
          lo_rs->if_fdt_transaction~enqueue( ).
          lo_rs->if_fdt_admin_data~set_name( 'RS_APROBADOR' ).
          lo_rs->set_function_restriction( lv_fu ).
          lo_rs->set_rules( VALUE #( ( position = 1 rule_id = lo_ru1->mv_id )
                                     ( position = 2 rule_id = lo_ru2->mv_id ) ) ).
          out->write( |RS RS_APROBADOR = { lo_rs->mv_id }| ).

          " 5. Verificar + activar + grabar: funcion y set de reglas (el set apunta a la funcion, no al reves)
          msgs( iv_step = 'FU check' it_msg = lo_fu->if_fdt_transaction~check( iv_deep = abap_true ) ).
          msgs( iv_step = 'RS check' it_msg = lo_rs->if_fdt_transaction~check( iv_deep = abap_true ) ).
          lo_fu->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                              IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
          msgs( iv_step = 'FU activate' it_msg = lt_msg ).
          out->write( |FU ACTIVACION FALLIDA: { lv_failed }| ).
          lo_rs->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                              IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
          msgs( iv_step = 'RS activate' it_msg = lt_msg ).
          out->write( |RS ACTIVACION FALLIDA: { lv_failed }| ).
          lo_fu->if_fdt_transaction~save( iv_deep = abap_true ).
          lo_rs->if_fdt_transaction~save( iv_deep = abap_true ).
          lo_fu->if_fdt_transaction~dequeue( iv_deep = abap_true ).
          lo_rs->if_fdt_transaction~dequeue( iv_deep = abap_true ).
          out->write( `GRABADO` ).
        CATCH cx_fdt INTO DATA(lx).
          out->write( |ERROR CREACION: { lx->get_text( ) }| ).
          LOOP AT lx->mt_message INTO DATA(ls_m).
            out->write( |  { ls_m-msgty } { ls_m-text }| ).
          ENDLOOP.
          RETURN.
      ENDTRY.
    ELSE.
      out->write( |FU_APROBADOR_EV YA EXISTE { lv_fu }| ).
      " Encender reglas y set de reglas (BRF+ los crea APAGADOS)
      TRY.
          DATA(lv_rs)  = find( iv_app = lc_app iv_name = 'RS_APROBADOR'  iv_type = 'RS' ).
          DATA(lv_ru1) = find( iv_app = lc_app iv_name = 'RU_PROCESS_DT' iv_type = 'EX' ).
          DATA(lv_ru2) = find( iv_app = lc_app iv_name = 'RU_MONTO_ALTO' iv_type = 'EX' ).
          lo_rs ?= cl_fdt_factory=>if_fdt_factory~get_instance( )->get_ruleset( lv_rs ).
          IF lo_rs->get_ruleset_switch( ) = if_fdt_ruleset=>gc_switch_off.
            lo_rs->if_fdt_transaction~enqueue( ).
            lo_rs->set_rules( VALUE #( ( position = 1 rule_id = lv_ru1 switch = if_fdt_ruleset=>gc_switch_on )
                                       ( position = 2 rule_id = lv_ru2 switch = if_fdt_ruleset=>gc_switch_on ) ) ).
            lo_rs->set_ruleset_switch( if_fdt_ruleset=>gc_switch_on ).
            msgs( iv_step = 'RS check' it_msg = lo_rs->if_fdt_transaction~check( iv_deep = abap_true ) ).
            lo_rs->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                                IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
            msgs( iv_step = 'RS activate' it_msg = lt_msg ).
            out->write( |RS ENCENDIDO, ACTIVACION FALLIDA: { lv_failed }| ).
            lo_rs->if_fdt_transaction~save( iv_deep = abap_true ).
            lo_rs->if_fdt_transaction~dequeue( iv_deep = abap_true ).
          ELSE.
            out->write( `RS ya encendido` ).
          ENDIF.
        CATCH cx_fdt INTO DATA(lx2).
          out->write( |ERROR ENCENDIDO: { lx2->get_text( ) }| ).
          LOOP AT lx2->mt_message INTO DATA(ls_m2).
            out->write( |  { ls_m2-msgty } { ls_m2-text }| ).
          ENDLOOP.
      ENDTRY.
    ENDIF.

    run_case( iv_fu = lv_fu iv_pais = `CO` iv_monto = 500 ).
    run_case( iv_fu = lv_fu iv_pais = `CO` iv_monto = 60000 ).
    run_case( iv_fu = lv_fu iv_pais = `MX` iv_monto = 1 ).
    run_case( iv_fu = lv_fu iv_pais = `PE` iv_monto = 10 ).
    run_case( iv_fu = lv_fu iv_pais = `BR` iv_monto = 10 ).
    run_case( iv_fu = lv_fu iv_pais = `BR` iv_monto = 99999 ).
  ENDMETHOD.

ENDCLASS.
