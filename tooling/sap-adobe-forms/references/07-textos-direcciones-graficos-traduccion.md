# 07 — Textos, direcciones, gráficos y traducción

## Textos

| Tipo | Cómo | Traducción |
|---|---|---|
| Texto fijo del layout | `draw` en el XDP | SE63 (XLIFF del layout, ver abajo) |
| **Módulo de texto** (Smart Forms, SMARTFORMS → Texto) | Nodo de texto del contexto, tipo módulo | SE63, tipo de objeto SSF |
| **Texto SO10 (include)** | Nodo de texto tipo *Include*: nombre, objeto (`TEXT`), ID (`ST`), idioma (fijo o desde un campo) | **No** se traduce en SE63: se crea en cada idioma en SO10 |
| Texto largo de un documento (cabecera/posición) | `READ_TEXT` en la inicialización → `TLINE` → bucle/campo multilínea | Lo trae el idioma de lectura |
| Texto dinámico | Nodo de texto dinámico (desde un campo) | — |

**Recomendación con `/adobeform`:** leer SO10/textos largos con `READ_TEXT` en la inicialización y pasar líneas al layout (control total, testeable). Con `IGNORE_ERROR`/manejo de `sy-subrc` para que un texto ausente no rompa el formulario.
Límite: un gráfico embebido en un texto SO10 con `BITMAP` **no** se renderiza en Adobe (sí en SAPscript).

## Dirección

- Nodo de dirección del contexto → llama internamente a **`ADDRESS_INTO_PRINTFORM`** ✅ (formato según país destino, nº de líneas, prioridad de calle/línea, idioma del receptor, país del remitente, interlocutor BUPA).
- Alternativa: llamar `ADDRESS_INTO_PRINTFORM` en la inicialización y pasar las líneas formateadas a un campo multilínea.
- Datos: número de dirección (`ADRNR`), número de persona, tipo (1 organización, 2 persona, 3 persona de contacto).

## Gráficos

| Origen | Cómo |
|---|---|
| **SE78** (BDS) | `cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp( EXPORTING p_object = 'GRAPHICS' p_name = <nombre> p_id = 'BMAP' p_btype = 'BCOL' RECEIVING p_bmp = lv_bmp EXCEPTIONS not_found = 1 internal_error = 2 )` (firma verificada) → XSTRING → nodo gráfico *contenido* (MIME `image/bmp`) o base64 → `imageEdit` ✅ (`CL_SSF_XSF_UTILITIES` existe en S/4 2023) |
| MIME repository | Nodo gráfico *URL* |
| Embebido en el layout | `image` con base64 en el XDP (logo fijo) ✅ |
| Dinámico por documento (firma, foto) | XSTRING → base64 en la inicialización → `imageEdit` ✅ |

- Variables de gráfico **XSTRING**, no STRING (con nodo gráfico).
- Logo por idioma/sociedad: elegir el nombre SE78 en la inicialización según el idioma/sociedad.
- Rendimiento: imágenes PNG/JPG reducidas al tamaño real de impresión; nunca BMP grandes sin comprimir.

## Traducción de formularios

- Tipos de objeto en **SE63**: `PDFB` (formulario de impresión), `PDFA` (interactivo). También desde SFP: *Pasar a → Traducción*.
- La primera vez que se guarda el layout, cada literal recibe un ID (`xliff:rid`); SAP extrae los literales a XLIFF 1.1. En SE63 solo son editables los literales.
- Se puede descargar el XLIFF y traducirlo fuera; la vista previa de la traducción requiere ADS en el sistema de traducción.
- Descripciones: formulario como objeto lógico `SFPF`, interfaz `SFPI`.
- SAP Translation Hub: nota 3582410.
- Al ejecutar, **pasar `SFPDOCPARAMS-LANGU`** (y `COUNTRY`); `REPLANGU1..3` como idiomas de respaldo.
- Si una traducción no aparece tras cambios: reabrir el layout, guardar y activar de nuevo.
- La traducción genera orden de transporte (SE10).
- **RTL** (árabe, hebreo, persa): además de traducir, hay que espejar el layout (alineaciones, orden de columnas) y usar fuentes que cubran el alfabeto.

## Idioma maestro (con ABIX)

- La clase de despliegue de ABIX corre en EN: el idioma del formulario se fija explícitamente (definición/config de ABIX) y al actualizar se pasa `i_language` + `i_suppress_language_check` ✅.
- Borrar y recrear un objeto NO limpia su idioma maestro (TADIR sobrevive): para cambiarlo, usar un nombre nuevo.
