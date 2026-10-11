CLASS zcl_abix_brf_tpl_ddic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    CONSTANTS gc_app TYPE if_fdt_types=>id VALUE '<ID_APLICACION_32>'.
    DATA mo_out TYPE REF TO if_oo_adt_classrun_out.
    DATA mt_data TYPE if_fdt_decision_table=>ts_table_data.
    METHODS find
      IMPORTING iv_name      TYPE if_fdt_types=>name
                iv_type      TYPE if_fdt_types=>object_type
      RETURNING VALUE(rv_id) TYPE if_fdt_types=>id.
    METHODS msgs
      IMPORTING iv_step TYPE string
                it_msg  TYPE if_fdt_types=>t_message.
    METHODS cond
      IMPORTING iv_col TYPE i
                iv_row TYPE i
                iv_val TYPE string.
    METHODS res
      IMPORTING iv_row TYPE i
                iv_val TYPE string.
    METHODS run_case
      IMPORTING iv_fu    TYPE if_fdt_types=>id
                iv_bukrs TYPE bukrs
                iv_blart TYPE blart.
ENDCLASS.



CLASS zcl_abix_brf_tpl_ddic IMPLEMENTATION.

  METHOD find.
    SELECT SINGLE id FROM fdt_admn_0000
      WHERE application_id = @gc_app AND name = @iv_name AND object_type = @iv_type AND deleted = @abap_false
      INTO @rv_id.
  ENDMETHOD.

  METHOD msgs.
    LOOP AT it_msg INTO DATA(ls_m) WHERE msgty CA 'EWAX'.
      mo_out->write( |  [{ iv_step }] { ls_m-msgty } { ls_m-text }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD cond.
    " Valor de condicion como texto: los elementos con binding DDIC CHAR son de tipo texto en BRF+
    INSERT VALUE #( col_no = iv_col row_no = iv_row
                    ts_range = VALUE #( ( position = 1 sign = 'I' option = 'EQ'
                                          r_low_value = NEW if_fdt_types=>element_text( iv_val ) ) ) ) INTO TABLE mt_data.
  ENDMETHOD.

  METHOD res.
    INSERT VALUE #( col_no = 3 row_no = iv_row r_value = NEW if_fdt_types=>element_text( iv_val ) ) INTO TABLE mt_data.
  ENDMETHOD.

  METHOD run_case.
    " Contexto con DATOS REALES: fila de T001 movida a la estructura de BRF+ (tipada por el binding)
    DATA lr_soc   TYPE REF TO data.
    DATA lr_blart TYPE REF TO data.
    DATA lv_res   TYPE if_fdt_types=>element_text.
    DATA lt_nv    TYPE abap_parmbind_tab.
    SELECT SINGLE * FROM t001 WHERE bukrs = @iv_bukrs INTO @DATA(ls_t001).
    IF sy-subrc <> 0.
      mo_out->write( |CASO { iv_bukrs }: no existe en T001| ).
      RETURN.
    ENDIF.
    TRY.
        cl_fdt_function_process=>get_data_object_reference(
          EXPORTING iv_function_id = iv_fu iv_data_object = find( iv_name = 'S_SOCIEDAD' iv_type = 'DO' )
          IMPORTING er_data = lr_soc ).
        ASSIGN lr_soc->* TO FIELD-SYMBOL(<ls_soc>).
        " NO MOVE-CORRESPONDING: BRF+ mapea los tipos DDIC a los suyos (fecha/hora -> ELEMENT_TIMEPOINT,
        " una estructura) y la conversion dumpea. Copiar solo componentes elementales.
        DATA(lo_sd) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( <ls_soc> ) ).
        DATA lv_copied TYPE i.
        DATA lv_skipped TYPE string.
        LOOP AT lo_sd->get_components( ) INTO DATA(ls_c).
          ASSIGN COMPONENT ls_c-name OF STRUCTURE <ls_soc> TO FIELD-SYMBOL(<lv_tgt>).
          ASSIGN COMPONENT ls_c-name OF STRUCTURE ls_t001 TO FIELD-SYMBOL(<lv_src>).
          IF <lv_src> IS NOT ASSIGNED OR <lv_tgt> IS NOT ASSIGNED.
            CONTINUE.
          ENDIF.
          IF ls_c-type->kind = cl_abap_typedescr=>kind_elem.
            <lv_tgt> = <lv_src>.
            lv_copied += 1.
          ELSE.
            lv_skipped = |{ lv_skipped } { ls_c-name }|.
          ENDIF.
          UNASSIGN: <lv_tgt>, <lv_src>.
        ENDLOOP.
        IF iv_blart = 'KR'.
          mo_out->write( |  copiados { lv_copied } componentes; omitidos (no elementales):{ lv_skipped }| ).
        ENDIF.
        cl_fdt_function_process=>get_data_object_reference(
          EXPORTING iv_function_id = iv_fu iv_data_object = find( iv_name = 'BLART' iv_type = 'DO' )
          IMPORTING er_data = lr_blart ).
        ASSIGN lr_blart->* TO FIELD-SYMBOL(<lv_blart>).
        <lv_blart> = iv_blart.
        lt_nv = VALUE #( ( name = 'S_SOCIEDAD' value = lr_soc ) ( name = 'BLART' value = lr_blart ) ).
        cl_fdt_function_process=>process(
          EXPORTING iv_function_id = iv_fu
          IMPORTING ea_result      = lv_res
          CHANGING  ct_name_value  = lt_nv ).
        mo_out->write( |CASO { iv_bukrs } ({ ls_t001-butxt }, LAND1={ ls_t001-land1 }, WAERS={ ls_t001-waers }) BLART={ iv_blart } -> APROBADOR={ lv_res }| ).
      CATCH cx_fdt INTO DATA(lx).
        mo_out->write( |CASO { iv_bukrs } BLART={ iv_blart } -> ERROR { lx->get_text( ) }| ).
        LOOP AT lx->mt_message INTO DATA(ls_m).
          mo_out->write( |  { ls_m-msgty } { ls_m-text }| ).
        ENDLOOP.
    ENDTRY.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    " ABIX PoC BRF+: estructura con binding DDIC (T001) + elemento con binding a elemento de datos (BLART).
    mo_out = out.
    DATA lo_st  TYPE REF TO if_fdt_structure.
    DATA lo_el  TYPE REF TO if_fdt_element.
    DATA lo_dt  TYPE REF TO if_fdt_decision_table.
    DATA lo_fu  TYPE REF TO if_fdt_function.
    DATA lt_msg TYPE if_fdt_types=>t_message.
    DATA lv_failed TYPE abap_bool.
    DATA lv_land1 TYPE if_fdt_types=>id.

    DATA(lv_fu) = find( iv_name = 'FU_APROBADOR_SOC' iv_type = 'FU' ).
    IF lv_fu IS INITIAL.
      TRY.
          DATA(lo_factory) = cl_fdt_factory=>if_fdt_factory~get_instance( gc_app ).
          DATA(lv_aprob) = find( iv_name = 'APROBADOR' iv_type = 'DO' ).

          " 1. Estructura con binding DDIC a T001: BRF+ crea un elemento por campo
          lo_st ?= lo_factory->get_data_object( iv_data_object_type = if_fdt_constants=>gc_data_object_type_structure ).
          lo_st->if_fdt_transaction~enqueue( ).
          lo_st->if_fdt_admin_data~set_name( 'S_SOCIEDAD' ).
          lo_st->if_fdt_data_object~set_ddic_binding( EXPORTING iv_ddic_typename = 'T001'
                                                      IMPORTING ets_object_id   = DATA(lts_comp) ).
          out->write( |S_SOCIEDAD = { lo_st->mv_id } (binding T001, { lines( lts_comp ) } elementos creados)| ).
          LOOP AT lo_st->get_elements( ) INTO DATA(ls_e).
            DATA(lv_nm) = cl_fdt_factory=>if_fdt_factory~get_instance( )->get_data_object( iv_id = ls_e-element_id )->if_fdt_admin_data~get_name( ).
            IF lv_nm = 'LAND1'.
              lv_land1 = ls_e-element_id.
            ENDIF.
          ENDLOOP.
          out->write( |  componente LAND1 = { lv_land1 }| ).

          " 2. Elemento con binding a elemento de datos DDIC BLART
          lo_el ?= lo_factory->get_data_object( iv_data_object_type = if_fdt_constants=>gc_data_object_type_element ).
          lo_el->if_fdt_transaction~enqueue( ).
          lo_el->if_fdt_admin_data~set_name( 'BLART' ).
          lo_el->if_fdt_data_object~set_ddic_binding( iv_ddic_typename = 'BLART' ).
          DATA(lv_blart) = lo_el->mv_id.
          out->write( |BLART = { lv_blart } (binding DDIC BLART)| ).

          " 3. Tabla de decision sobre componente de estructura + elemento DDIC
          lo_dt ?= lo_factory->get_expression( iv_expression_type_id = if_fdt_constants=>gc_exty_decision_table ).
          lo_dt->if_fdt_transaction~enqueue( ).
          lo_dt->if_fdt_admin_data~set_name( 'DT_APROBADOR_SOC' ).
          lo_dt->set_columns( VALUE #( ( col_no = 1 object_id = lv_land1 )
                                       ( col_no = 2 object_id = lv_blart )
                                       ( col_no = 3 object_id = lv_aprob is_result = abap_true ) ) ).
          cond( iv_col = 1 iv_row = 1 iv_val = `CO` ). cond( iv_col = 2 iv_row = 1 iv_val = `KR` ). res( iv_row = 1 iv_val = `JEFE_CO_PROVEEDORES` ).
          cond( iv_col = 1 iv_row = 2 iv_val = `CO` ).                                              res( iv_row = 2 iv_val = `GERENTE_CO` ).
          cond( iv_col = 1 iv_row = 3 iv_val = `CL` ).                                              res( iv_row = 3 iv_val = `GERENTE_CL` ).
                                                                                                    res( iv_row = 4 iv_val = `REVISION_MANUAL` ).
          lo_dt->set_table_data( mt_data ).
          lo_dt->if_fdt_expression~set_result_data_object( lv_aprob ).

          " 4. Funcion: contexto = estructura + elemento DDIC
          lo_fu ?= lo_factory->get_function( ).
          lo_fu->if_fdt_transaction~enqueue( ).
          lo_fu->if_fdt_admin_data~set_name( 'FU_APROBADOR_SOC' ).
          lo_fu->set_context_data_objects( VALUE #( ( lo_st->mv_id ) ( lv_blart ) ) ).
          lo_fu->set_result_data_object( lv_aprob ).
          lo_fu->set_function_mode( if_fdt_function=>gc_mode_functional ).
          lo_fu->set_expression( lo_dt->mv_id ).
          lv_fu = lo_fu->mv_id.

          msgs( iv_step = 'FU check' it_msg = lo_fu->if_fdt_transaction~check( iv_deep = abap_true ) ).
          lo_fu->if_fdt_transaction~activate( EXPORTING iv_deep = abap_true
                                              IMPORTING et_message = lt_msg ev_activation_failed = lv_failed ).
          msgs( iv_step = 'FU activate' it_msg = lt_msg ).
          out->write( |FU FU_APROBADOR_SOC = { lv_fu }, ACTIVACION FALLIDA: { lv_failed }| ).
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
    ELSE.
      out->write( |FU_APROBADOR_SOC YA EXISTE { lv_fu } -> solo pruebas| ).
    ENDIF.

    run_case( iv_fu = lv_fu iv_bukrs = 'CO01' iv_blart = 'KR' ).
    run_case( iv_fu = lv_fu iv_bukrs = 'CO01' iv_blart = 'SA' ).
    run_case( iv_fu = lv_fu iv_bukrs = 'CL01' iv_blart = 'KR' ).
    run_case( iv_fu = lv_fu iv_bukrs = 'CA01' iv_blart = 'KR' ).
  ENDMETHOD.

ENDCLASS.
