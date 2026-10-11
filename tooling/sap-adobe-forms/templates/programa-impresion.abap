*&---------------------------------------------------------------------*
*& Plantilla ABIX: programa de impresion para un formulario Adobe (SFP)
*&---------------------------------------------------------------------*
*& Cubre: vista previa, impresion sin dialogo, obtener PDF, guardarlo,
*& enviarlo por correo (BCS), archivarlo (ArchiveLink) y diagnostico de
*& ADS. El formulario se llama con PARAMETER-TABLE, asi la plantilla
*& compila para cualquier interfaz: solo hay que llenar FILL_PARAMS.
*& Compilada y activada en S/4HANA 2023 (oct-2026).
*&---------------------------------------------------------------------*
REPORT zxx_fp_print_template.

PARAMETERS:
  p_form  TYPE fpname   OBLIGATORY DEFAULT 'ZXX_FORM_PDF',
  p_langu TYPE sylangu  DEFAULT sy-langu,
  p_land  TYPE land1    DEFAULT 'CO'.

SELECTION-SCREEN BEGIN OF BLOCK out WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_prev  RADIOBUTTON GROUP o DEFAULT 'X',   " vista previa en SAP GUI
    p_print RADIOBUTTON GROUP o,               " imprimir sin dialogo
    p_pdf   RADIOBUTTON GROUP o.               " obtener el PDF (correo / archivo / guardar)
  PARAMETERS:
    p_dest  TYPE rspopname DEFAULT 'LP01',
    p_email TYPE ad_smtpadr,
    p_arch  AS CHECKBOX,
    p_trace AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK out.

CLASS lcl_print DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS run.
  PRIVATE SECTION.
    DATA mv_fm  TYPE rs38l_fnam.
    DATA mt_par TYPE abap_func_parmbind_tab.
    DATA mt_exc TYPE abap_func_excpbind_tab.
    " Datos de la interfaz del formulario (adaptar a tu SFPI)
    DATA mv_titulo TYPE string.
    METHODS fill_params IMPORTING is_doc TYPE sfpdocparams
                        CHANGING  cs_out TYPE fpformoutput.
    METHODS send_mail   IMPORTING iv_pdf TYPE xstring.
    METHODS ads_error   RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS lcl_print IMPLEMENTATION.

  METHOD run.
    DATA ls_op  TYPE sfpoutputparams.
    DATA ls_doc TYPE sfpdocparams.
    DATA ls_out TYPE fpformoutput.

    " 1. Nombre del modulo generado (nunca hardcodear /1BCDWB/SM...)
    TRY.
        CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
          EXPORTING
            i_name     = p_form
          IMPORTING
            e_funcname = mv_fm.
      CATCH cx_fp_api INTO DATA(lx_api).
        MESSAGE lx_api->get_text( ) TYPE 'E'.
    ENDTRY.

    " 2. Parametros de salida segun el canal
    CASE abap_true.
      WHEN p_prev.
        ls_op-preview = abap_true.
      WHEN p_print.
        ls_op-nodialog = abap_true.
        ls_op-dest     = p_dest.
        ls_op-reqnew   = abap_true.
        ls_op-reqimm   = abap_true.
      WHEN p_pdf.
        ls_op-nodialog = abap_true.
        ls_op-getpdf   = abap_true.     " sin PREVIEW: el PDF vuelve en ls_out-pdf
    ENDCASE.
    IF p_trace = abap_true.
      ls_op-adstrlevel = '02'.          " traza media de ADS -> FP_GET_LAST_ADS_TRACE
    ENDIF.

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = ls_op
      EXCEPTIONS
        cancel          = 1
        usage_error     = 2
        system_error    = 3
        internal_error  = 4
        OTHERS          = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    " 3. Idioma y pais: traduccion y formato local
    ls_doc-langu   = p_langu.
    ls_doc-country = p_land.

    " 4. Llamada al formulario (un documento; en masivo: bucle entre JOB_OPEN y JOB_CLOSE)
    fill_params( EXPORTING is_doc = ls_doc CHANGING cs_out = ls_out ).
    CALL FUNCTION mv_fm
      PARAMETER-TABLE mt_par
      EXCEPTION-TABLE mt_exc.
    IF sy-subrc <> 0.
      DATA(lv_err) = ads_error( ).
      CALL FUNCTION 'FP_JOB_CLOSE' EXCEPTIONS OTHERS = 1.
      MESSAGE |Error al generar el formulario: { lv_err }| TYPE 'E'.
    ENDIF.

    CALL FUNCTION 'FP_JOB_CLOSE'
      EXCEPTIONS
        usage_error    = 1
        system_error   = 2
        internal_error = 3
        OTHERS         = 4.

    " 5. Uso del PDF
    IF p_pdf = abap_true AND ls_out-pdf IS NOT INITIAL.
      IF p_email IS NOT INITIAL.
        send_mail( ls_out-pdf ).
      ENDIF.
      IF p_arch = abap_true.
        " ArchiveLink: con ARCMODE = '2'/'3' y SFPDOCPARAMS-DARATAB lo hace el runtime;
        " para un PDF propio: ARCHIV_CREATE_OUTGOINGDOC_MULT (documentclass 'PDF').
        MESSAGE 'Archivo: completar DARATAB o ARCHIV_CREATE_OUTGOINGDOC_MULT segun tu objeto' TYPE 'S'.
      ENDIF.
      MESSAGE |PDF generado: { xstrlen( ls_out-pdf ) } bytes, { ls_out-pages } paginas| TYPE 'S'.
    ENDIF.
  ENDMETHOD.


  METHOD fill_params.
    " Una entrada por parametro de la interfaz + los dos fijos del runtime.
    CLEAR: mt_par, mt_exc.
    INSERT VALUE #( name  = '/1BCDWB/DOCPARAMS' kind = abap_func_exporting
                    value = REF #( is_doc ) ) INTO TABLE mt_par.
    INSERT VALUE #( name  = '/1BCDWB/FORMOUTPUT' kind = abap_func_importing
                    value = REF #( cs_out ) ) INTO TABLE mt_par.

    " --- Parametros de TU interfaz (nombre en mayusculas, referencia a la variable) ---
    mv_titulo = |Documento de prueba { sy-datum DATE = USER }|.
    INSERT VALUE #( name = 'TITULO' kind = abap_func_exporting value = REF #( mv_titulo ) ) INTO TABLE mt_par.

    INSERT VALUE #( name = 'USAGE_ERROR'    value = 1 ) INTO TABLE mt_exc.
    INSERT VALUE #( name = 'SYSTEM_ERROR'   value = 2 ) INTO TABLE mt_exc.
    INSERT VALUE #( name = 'INTERNAL_ERROR' value = 3 ) INTO TABLE mt_exc.
    INSERT VALUE #( name = 'OTHERS'         value = 4 ) INTO TABLE mt_exc.
  ENDMETHOD.


  METHOD send_mail.
    TRY.
        DATA(lo_send) = cl_bcs=>create_persistent( ).
        DATA(lt_body) = VALUE soli_tab( ( line = 'Se adjunta el documento.' ) ).
        DATA(lo_doc)  = cl_document_bcs=>create_document( i_type    = 'RAW'
                                                          i_text    = lt_body
                                                          i_subject = 'Documento' ).
        " xstring_to_solix + tamano real: evita el PDF corrupto por relleno x'00'
        lo_doc->add_attachment( i_attachment_type    = 'PDF'
                                i_attachment_subject = 'documento'
                                i_attachment_size    = CONV #( xstrlen( iv_pdf ) )
                                i_att_content_hex    = cl_bcs_convert=>xstring_to_solix( iv_pdf ) ).
        lo_send->set_document( lo_doc ).
        lo_send->add_recipient( cl_cam_address_bcs=>create_internet_address( p_email ) ).
        lo_send->set_send_immediately( abap_true ).
        lo_send->send( ).
        COMMIT WORK.
      CATCH cx_bcs INTO DATA(lx_bcs).
        MESSAGE lx_bcs->get_text( ) TYPE 'I'.
    ENDTRY.
  ENDMETHOD.


  METHOD ads_error.
    DATA lv_trace TYPE string.
    CALL FUNCTION 'FP_GET_LAST_ADS_ERRSTR'
      IMPORTING
        e_adserrstr = rv_text.
    IF p_trace = abap_true.
      CALL FUNCTION 'FP_GET_LAST_ADS_TRACE'
        IMPORTING
          e_adstrace = lv_trace.
      rv_text = |{ rv_text } / traza: { lv_trace }|.
    ENDIF.
    IF rv_text IS INITIAL.
      MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO rv_text.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  NEW lcl_print( )->run( ).
