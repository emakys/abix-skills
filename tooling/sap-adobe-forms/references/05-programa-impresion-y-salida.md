# 05 — Programa de impresión y canales de salida

Plantilla completa: `templates/programa-impresion.abap`.

## Secuencia ✅

```
FP_FUNCTION_MODULE_NAME( i_name ) → e_funcname          " nunca hardcodear /1BCDWB/SM…
FP_JOB_OPEN( CHANGING ie_outputparams )                  " UNA vez antes del bucle
  LOOP AT documentos.
    CALL FUNCTION lv_fm EXPORTING /1bcdwb/docparams = ls_doc  <params>
                        IMPORTING /1bcdwb/formoutput = ls_out
                        EXCEPTIONS usage_error = 1 system_error = 2 internal_error = 3.
  ENDLOOP.
FP_JOB_CLOSE( )                                          " UNA vez después
```
Ejemplo estándar en el sistema: `FP_EXAMPLE_01` ✅. Excepciones de `FP_JOB_OPEN`: `cancel`, `usage_error`, `system_error`, `internal_error`.

## `SFPOUTPUTPARAMS` (campos verificados en S/4HANA 2023) ✅

| Campo | Para qué |
|---|---|
| `DEVICE` | Medio (`PRINTER`, …) |
| `NODIALOG` | `X` = sin diálogo de impresión (obligatorio en fondo/OData/RFC) |
| `PREVIEW` | `X` = vista previa en SAP GUI |
| `GETPDF` | `X` = devolver el PDF al programa (`/1bcdwb/formoutput-pdf`). `M` = PDF combinado (con `BUMODE`) |
| `GETPDL` / `GETXML` | Devolver el PDL (PCL/PS/ZPL) / el XML de datos |
| `CONNECTION` / `LPORT` | Destino RFC de ADS / puerto lógico (por defecto el de `FPCONNECT`) |
| `ADSTRLEVEL` | Traza de ADS `00`–`10` → leer con `FP_GET_LAST_ADS_TRACE` |
| `JOB_PROFILE` | Perfil de trabajo de ADS (p. ej. dúplex) |
| `BUMODE` / `ASSEMBLE` | Agrupar varios formularios (`BUMODE = 'M'`, `ASSEMBLE = 'S'`) |
| `PARALLEL` | Procesamiento paralelo |
| `PDFVERSION` / `PDFTAGGED` / `PDFNORM` / `PDFCHANGESRESTRICTED` | Versión PDF, PDF etiquetado (accesibilidad), norma (PDF/A), restricción de cambios |
| `DEST` | Impresora (dispositivo de salida SPAD) |
| `REQNEW` / `REQIMM` / `REQDEL` / `REQFINAL` | Nueva orden de spool / imprimir ya / borrar tras imprimir / orden final |
| `SPOOLID` | Spool resultante |
| `COPIES` | Copias |
| `DATASET` / `SUFFIX1` / `SUFFIX2` / `TITLE` / `COVTITLE` / `RECEIVER` / `DIVISION` / `LIFETIME` / `AUTHORITY` | Atributos del spool |
| `PDLTYPE` / `XDCNAME` / `NOPDF` | Tipo de PDL y XDC para impresión directa |
| `ARCMODE` | Archivo: `1` imprimir, `2` solo archivar, `3` imprimir y archivar |
| `NOARMCH` | No cambiar modo de archivo en el diálogo |
| `NOPREVIEW` / `NOPRINT` / `NOARCHIVE` / `NOPRIBUTT` / `IMMEXIT` | Control de botones/acciones del diálogo |
| `XFP` / `XFPTYPE` / `XFPOUTDEV` | Salida XFP (otros formatos/procesadores) |

## `SFPDOCPARAMS` ✅

`LANGU` y `COUNTRY` (idioma y país: traducción y formato local), `REPLANGU1..3` (idiomas de reemplazo si falta traducción), `FILLABLE` (interactivo), `DYNAMIC`, `UPDATE_INTERACTION_CODE`, `DARATAB` (índices de archivo ArchiveLink).

## `FPFORMOUTPUT` (`/1bcdwb/formoutput`) ✅

`PDF` (xstring), `PDL`, `XML`, `PAGES`, `LANGU`.

## Escenarios

| Escenario | Parámetros |
|---|---|
| Vista previa en SAP GUI | `PREVIEW = 'X'` (deja el diálogo) |
| Imprimir sin diálogo | `NODIALOG = 'X'`, `DEST = <impresora>`, `REQNEW = 'X'`, `REQIMM = 'X'` |
| Obtener PDF (OData, correo, Web Dynpro, job) | `NODIALOG = 'X'`, `GETPDF = 'X'` — **sin** `PREVIEW` ✅ |
| Job de fondo | `GET_PRINT_PARAMETERS( no_dialog = 'X' )` → `DEST`, `COPIES`, `REQIMM`; `CONNECTION = cl_fp=>get_ads_connection( )` |
| Imprimir y archivar | `ARCMODE = '3'` + al menos una entrada en `SFPDOCPARAMS-DARATAB` (`FUNCTION = 'DARA'`, `MANDANT`, `SAP_OBJECT`, `AR_OBJECT`, `OBJECT_ID`). Desde NAST: `arcmode = nast-tdarmod` y `TOA_DARA`. Verificar en OAAD |
| Archivar un PDF propio | `ARCHIV_CREATE_OUTGOINGDOC_MULT` (documentclass `PDF`) ✅ |
| Varios documentos en un PDF | `GETPDF = 'M'`, `BUMODE = 'M'`, `ASSEMBLE = 'S'`; tras `FP_JOB_CLOSE`, `FPCOMP_GET_PDF_TABLE` ✅ |
| PDF desde un spool existente | `FPCOMP_CREATE_PDF_FROM_SPOOL` ✅ |
| PDL para impresora (ZPL/PCL) | `GETPDL = 'X'` + dispositivo/XDC adecuados (`08`) |

## Correo con el PDF (BCS)

```abap
DATA(lt_solix) = cl_bcs_convert=>xstring_to_solix( ls_out-pdf ).   " evita PDF corrupto por relleno x'00'
DATA(lo_send)  = cl_bcs=>create_persistent( ).
DATA(lo_doc)   = cl_document_bcs=>create_document( i_type = 'RAW' i_text = lt_body i_subject = lv_asunto ).
lo_doc->add_attachment( i_attachment_type    = 'PDF'
                        i_attachment_subject = lv_nombre_archivo
                        i_attachment_size    = CONV #( xstrlen( ls_out-pdf ) )
                        i_att_content_hex    = lt_solix ).
lo_send->set_document( lo_doc ).
lo_send->add_recipient( cl_cam_address_bcs=>create_internet_address( lv_email ) ).
lo_send->set_send_immediately( abap_true ).
lo_send->send( ).
COMMIT WORK.
```
PDF corrupto en el adjunto = longitud no informada (relleno de la última línea). Usa `xstring_to_solix` + `i_attachment_size`.

## Errores en runtime ✅

```abap
IF sy-subrc <> 0.
  CALL FUNCTION 'FP_GET_LAST_ADS_ERRSTR' IMPORTING e_adserrstr = lv_err.
  CALL FUNCTION 'FP_GET_LAST_ADS_TRACE'  IMPORTING e_adstrace  = lv_trace.   " con ADSTRLEVEL > 0
ENDIF.
```
Firmas verificadas en S/4HANA 2023: `FP_GET_LAST_ADS_ERRSTR` exporta `e_adserrstr TYPE string`, `FP_GET_LAST_ADS_TRACE` exporta `e_adstrace TYPE string`, `FPCOMP_GET_PDF_TABLE` exporta `e_pdf_table TYPE tfpcontent` (tabla de PDFs del job; llamarlo tras `FP_JOB_CLOSE`). `FPRUNX001/002/004` = error de ADS al renderizar (binding sin resolver, formato de dato, carácter inválido en los datos, autorización HTTP).

## Diseño del programa

- Abrir/cerrar el job **una vez**; el bucle llama al módulo por documento.
- Lectura de datos y cálculos en el programa (o en la inicialización si son de presentación); el formulario recibe datos listos.
- OData `GET_STREAM`: `NODIALOG` + `GETPDF`, devolver `ls_out-pdf` con mime `application/pdf`.
- RAP/ABAP Cloud: ver `01` (render_pdf con form data provider).
