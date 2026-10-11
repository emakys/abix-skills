CLASS zcl_abix_brf_tpl_simular DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.



CLASS zcl_abix_brf_tpl_simular IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " ABIX PoC BRF+: simular EN MEMORIA en la aplicacion temporal (GC_APPLICATION_TMP), activar SIN grabar,
    " ejecutar y verificar que no se escribio nada en FDT_ADMN_0000.
    DATA lo_dt  TYPE REF TO if_fdt_decision_table.
    DATA lo_fu  TYPE REF TO if_fdt_function.
    DATA lt_msg TYPE if_fdt_types=>t_message.
    DATA lv_failed TYPE abap_bool.
    DATA lt_data TYPE if_fdt_decision_table=>ts_table_data.
    DATA lv_res TYPE if_fdt_types=>element_text.

    SELECT COUNT(*) FROM fdt_admn_0000 INTO @DATA(lv_before).
    TRY.
        DATA(lo_factory) = cl_fdt_factory=>if_fdt_factory~get_instance( if_fdt_constants=>gc_application_tmp ).
        cl_fdt_convenience=>create_element( EXPORTING iv_name = 'PAIS' iv_application_id = if_fdt_constants=>gc_application_tmp
                                                      iv_element_type = if_fdt_constants=>gc_element_type_text
                                            IMPORTING ev_element_id = DATA(lv_pais) ).
        cl_fdt_convenience=>create_element( EXPORTING iv_name = 'APROBADOR' iv_application_id = if_fdt_constants=>gc_application_tmp
                                                      iv_element_type = if_fdt_constants=>gc_element_type_text
                                            IMPORTING ev_element_id = DATA(lv_aprob) ).
        lo_dt ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_decision_table ).
        lo_dt->set_columns( VALUE #( ( col_no = 1 object_id = lv_pais )
                                     ( col_no = 2 object_id = lv_aprob is_result = abap_true ) ) ).
        INSERT VALUE #( col_no = 1 row_no = 1 ts_range = VALUE #( ( position = 1 sign = 'I' option = 'EQ'
                        r_low_value = NEW if_fdt_types=>element_text( `CO` ) ) ) ) INTO TABLE lt_data.
        INSERT VALUE #( col_no = 2 row_no = 1 r_value = NEW if_fdt_types=>element_text( `SIMULADO_CO` ) ) INTO TABLE lt_data.
        INSERT VALUE #( col_no = 2 row_no = 2 r_value = NEW if_fdt_types=>element_text( `SIMULADO_OTRO` ) ) INTO TABLE lt_data.
        lo_dt->set_table_data( lt_data ).
        lo_dt->if_fdt_expression~set_result_data_object( lv_aprob ).

        lo_fu ?= lo_factory->get_function( ).
        lo_fu->if_fdt_admin_data~set_name( cl_fdt_services=>get_unique_name( ) ).
        lo_fu->set_context_data_objects( VALUE #( ( lv_pais ) ) ).
        lo_fu->set_result_data_object( lv_aprob ).
        lo_fu->set_expression( lo_dt->mv_id ).
        lo_fu->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                            IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
        LOOP AT lt_msg INTO DATA(ls_m) WHERE msgty CA 'EAX'.
          out->write( |  ACT { ls_m-msgty } { ls_m-text }| ).
        ENDLOOP.
        out->write( |ACTIVADO EN MEMORIA (fallida: { lv_failed }), SIN save| ).

        LOOP AT VALUE string_table( ( `CO` ) ( `PE` ) ) INTO DATA(lv_p).
          DATA(lo_ctx) = lo_fu->get_process_context( ).
          lo_ctx->set_value( iv_id = lv_pais ia_value = CONV if_fdt_types=>element_text( lv_p ) ).
          lo_fu->process( EXPORTING io_context = lo_ctx IMPORTING eo_result = DATA(lo_result) ).
          lo_result->get_value( IMPORTING ea_value = lv_res ).
          out->write( |CASO PAIS={ lv_p } -> { lv_res }| ).
        ENDLOOP.
        lo_fu->if_fdt_transaction~dequeue( iv_deep = abap_true ).
      CATCH cx_fdt INTO DATA(lx).
        out->write( |ERROR: { lx->get_text( ) }| ).
        LOOP AT lx->mt_message INTO DATA(ls_e).
          out->write( |  { ls_e-msgty } { ls_e-text }| ).
        ENDLOOP.
    ENDTRY.
    SELECT COUNT(*) FROM fdt_admn_0000 INTO @DATA(lv_after).
    out->write( |FDT_ADMN_0000 antes={ lv_before } despues={ lv_after }| ).
  ENDMETHOD.

ENDCLASS.
