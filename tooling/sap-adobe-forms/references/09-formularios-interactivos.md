# 09 — Formularios interactivos

## Escenarios

| | Online | Offline |
|---|---|---|
| Conexión | Usuario conectado (Web Dynpro) | Usuario sin conexión; devuelve el PDF por correo/subida |
| Ayudas/validaciones | Dinámicas (contexto Web Dynpro, ayudas de búsqueda) | Estáticas (dentro del PDF) |
| Recuperar datos | Web Dynpro los escribe en el contexto | Extraer el XML del PDF |

SAP recomienda la integración **Web Dynpro** (ABAP o Java) para interactivos.

## ZCI (Zero Client Installation) para Web Dynpro

1. SFP → propiedades del formulario → tipo de layout **ZCI**.
2. LiveCycle → Utilidades → *Insertar script de Web Dynpro* (agrega `ContainerFoundation_JS`).
3. Formularios viejos: **`SFP_ZCI_UPDATE`** (report `FP_ZCI_UPDATE` ✅, basado en `FP_CHK_REPORT` ✅; requiere `S_FP_CHK`, formulario activo, ADS; no corre en fondo; nota 956074).
4. Web Dynpro: elemento `InteractiveForm` con `enabled = X`; si sigue sin ser interactivo, revisar el tipo de layout y rehacer el binding.
5. `SFPDOCPARAMS-FILLABLE = 'X'` para generar interactivo desde ABAP.

## Extraer datos de un PDF (offline) ✅ clases existen

```abap
DATA(lo_fp)  = cl_fp=>get_reference( ).
TRY.
    DATA(lo_pdf) = lo_fp->create_pdf_object( connection = 'ADS' ).
    lo_pdf->set_document( pdfdata = lv_pdf ).
    lo_pdf->set_extractdata( ).
    lo_pdf->execute( ).
    lo_pdf->get_data( IMPORTING formdata = lv_xml ).
  CATCH cx_fp_runtime INTO DATA(lx).
ENDTRY.
" lv_xml → CALL TRANSFORMATION / iXML / SMUM_XML_PARSE
```
Programa de ejemplo: `FP_PDF_TEST_03` ✅. PDF desde un spool: `FPCOMP_CREATE_PDF_FROM_SPOOL` ✅.

## Licencias y usage rights

- Formularios **interactivos** y códigos de barras 2D dinámicos (Paper Forms Barcode) requieren licencia; sin *usage rights* el Reader gratuito no permite guardar los datos / el código se cifra.
- Error *"Invalid usage right"*: patch de ADS/J2EE al menos al nivel del ABAP.
- ZCI y versiones de Reader: mantener Reader/Acrobat actualizados (nota 999998 para errores de Web Dynpro).

## Rendimiento en interactivos

- Formularios dinámicos grandes (>10 páginas) se re-maquetan en el Reader: ocultar secciones según datos ayuda mucho.
- Evitar listas desplegables enormes y lógica de visibilidad muy anidada.
- Opción de propiedades del formulario para liberar variables JS tras su uso (formularios que quedan en blanco tras muchos eventos).
