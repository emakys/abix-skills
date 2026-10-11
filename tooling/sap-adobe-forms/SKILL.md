---
name: sap-adobe-forms
description: Experto en SAP Interactive Forms by Adobe (Adobe Forms, SFP) — interfaz SFPI, contexto, layout XFA/XDP en LiveCycle Designer, scripting FormCalc/JavaScript, programa de impresión (FP_JOB_OPEN/SFPOUTPUTPARAMS), salida a impresora/PDF/correo/archivo, gestión de salidas S/4HANA (BRF+/OPD, formularios maestros y fragmentos), textos SO10/módulos, direcciones, gráficos SE78, traducción SE63, códigos de barras/QR, impresión ZPL/PCL/PostScript, formularios interactivos (ZCI, Web Dynpro, offline), ADS (diagnóstico y rendimiento) y el flujo /adobeform de ABIX (generar, pre-validar, desplegar sin SFP y probar el runtime real).
---

# SAP Adobe Forms — Guía experta (ABIX)

Eres especialista en **SAP Interactive Forms by Adobe** (transacción **SFP**): diseñas formularios de impresión e interactivos, escribes el programa que los llama, configuras su salida y diagnosticas ADS. Conoces el flujo **`/adobeform`** de ABIX, que genera interfaz + contexto + layout desde una definición, los pre-valida con ADS y los despliega **sin la transacción SFP**.

> Todo lo marcado ✅ se verificó en vivo (S/4HANA 2023 FPS03, oct-2026). Lo demás sale de documentación SAP/Adobe y de la comunidad: tómalo como guía y confírmalo en el sistema.

## Piezas de un formulario SFP

| Pieza | Objeto | Qué es |
|---|---|---|
| **Interfaz** | `SFPI` | Parámetros de importación, datos globales, tipos, **código de inicialización** (ABAP), referencias de moneda/cantidad |
| **Formulario** | `SFPF` | **Contexto** (qué datos de la interfaz llegan al layout y cómo: campos, bucles, carpetas con condición, textos, direcciones, gráficos) + **layout** XFA |
| **Layout** | XDP dentro del SFPF | Diseño XFA (LiveCycle Designer): páginas maestras, subformularios, tablas, scripts |
| **Módulo generado** | `/1BCDWB/SM…` | Lo genera SAP al activar; se obtiene con `FP_FUNCTION_MODULE_NAME` |
| **ADS** | Adobe Document Services | Servicio (Java o BTP) que **renderiza**: sin ADS no hay PDF, ni carga, ni activación de layouts XFA |

## Qué tecnología usar

| Escenario | Recomendación |
|---|---|
| Formulario Z llamado desde un programa propio (on-premise) | **SFP clásico** (interfaz ABAP + contexto + layout) — es lo que genera `/adobeform` |
| Documento estándar de S/4HANA (factura, pedido, entrega) con gestión de salidas | **Output control BRF+ (OPD)** + plantilla con **fragmentos** y formulario maestro (`SOMU_FORM_MASTER_A4`/`LETTER`). Ver `references/06` |
| S/4HANA Cloud / ABAP Cloud | Form Data Provider (CDS + service definition, `cl_fp_fdp_services`) + `cl_fp_ads_util=>render_pdf`; plantillas en el template store (BTP) |
| Etiquetas Zebra | SFP + dispositivo **AZPL203/AZPL300** (ADS genera ZPL). Ver `references/08` |
| Formulario que el usuario rellena | **Interactivo** (ZCI + Web Dynpro, u offline con extracción de datos). Ver `references/09` |
| Migrar un Smart Form | Asistente de SMARTFORMS solo como borrador; casi siempre conviene rediseñar. Ver `references/01` |

## Flujo ABIX `/adobeform`

1. `/adobeform <documento>` → escribes en `src/{ws}/`:
   - `{form}.sfpf.json` — definición (interfaz + contexto + datos de prueba) → `references/02`
   - `{form}.sfpf.xdp` — layout XFA → `references/03`, bloques en `templates/bloques/`
   - `{form}.sfpf.data.xml` — datos de ejemplo para pre-validar (opcional, recomendado)
2. ABIX valida y ofrece **Pre-validar diseño ▶** (render del layout con ADS, sin crear el formulario) y **Desplegar y probar ▶** (crea/actualiza SFPI+SFPF sin SFP, en el paquete y la orden del workspace, activa y ejecuta el runtime real).
3. Los PDF quedan en el workspace (`{form}.preview.pdf`, `{form}.runtime.pdf`). **Léelos y corrige.**
4. Ajustes posteriores: `/adobeform desplegar [form]` · `/adobeform prevalidar [form]`.

**No escribas** `.sfpf.xml`/`.sfpi.xml` (el grafo del contexto lo genera ABIX por código) y **no despliegues** por tu cuenta: el usuario usa los botones.

**Parte de la plantilla base** (`templates/base-documento.*`, verificada de punta a punta ✅) y de los bloques probados; no inventes XFA desde cero.

## Reglas duras (las que más fallan)

1. **Raíz de datos = `data`.** Subform raíz `name="data"`; las filas de un bucle llegan como `<BUCLE><DATA>…</DATA></BUCLE>` → tabla `ref="$.BUCLE"`, fila `ref="DATA[*]"`, celdas `ref="$.CAMPO"`. ✅
2. **Contexto ↔ interfaz:** todo nodo del contexto apunta a un parámetro o global de la interfaz; consulta el DDIC real antes de escribir tipos y columnas. No inventes campos.
3. **Imagen dinámica:** un `XSTRING` crudo NO se ve. Conviértelo a base64 en la inicialización (`cl_web_http_utility=>encode_x_base64`) y enlaza un campo `imageEdit`. Alternativa estándar: nodo **gráfico** del contexto (contenido + MIME). ✅
4. **Importes:** declara la referencia de moneda (`currencyRefs`, acepta componentes de tabla ✅) o entrega texto formateado (`WRITE … CURRENCY`). Los decimales salen de **TCURX del sistema** (no asumas 2 ni 0). ✅
5. **Textos variables:** campo `multiLine` con `minH`/`maxH`, nunca altura fija. ✅
6. **Tablas largas:** fila con `<keep intact="contentArea"/>` + `<overflow leader="<encabezado>"/>` para repetir el encabezado. ✅
7. **Leader/trailer de overflow:** contenido **posicionado** y sin data binding, o se superponen campos.
8. **Fechas/números:** patrón explícito (`date{DD/MM/YYYY}`, `num{z,zzz,zz9.99}`); SAP manda fechas `YYYY-MM-DD`. Un patrón mal escrito da usage error opaco.
9. **Lógica en ABAP, no en scripts:** cálculos y selección de datos en la inicialización o el programa; scripts solo para presentación (paginación, totales por página, ocultar vacíos).
10. **Idioma:** pasa `SFPDOCPARAMS-LANGU` y `COUNTRY`; sin eso la traducción y el formato local no aplican.
11. **Sin diálogo:** fuera de SAP GUI (fondo, OData, RFC) usa `NODIALOG = 'X'` + `GETPDF = 'X'`; nunca `PREVIEW`.
12. **ADS caído = nada funciona:** ni preview, ni carga en SFP, ni activación de un layout XFA. Diagnostica con `FP_TEST_00` → `FP_PDF_TEST_00` → `FP_CHECK_DESTINATION_SERVICE`. ✅
13. **Error opaco `FPRUNX001`:** pide `FP_GET_LAST_ADS_ERRSTR` (y `ADSTRLEVEL` + `FP_GET_LAST_ADS_TRACE`). Causa típica: binding sin resolver o formato de dato. ✅ (existen en S/4 2023)
14. **Los `draw` NO ejecutan scripts.** Todo lo que se oculta/muestra o calcula por script (marca de agua, totales, numeración) debe ser un `field` (con `bind match="none"` si no lleva datos). ✅
15. **La pre-validación no valida interfaz ni contexto:** los problemas de serialización ABAP→datos solo aparecen en el runtime real. ✅

## Referencias

| Archivo | Contenido |
|---|---|
| `references/01-arquitectura-y-tecnologias.md` | SFP, ADS, tipos de interfaz, fragmentos, ABAP Cloud, migración desde Smart Forms |
| `references/02-definicion-sfpf-json.md` | Esquema de la definición ABIX, los 17 tipos de nodo de contexto y su serialización |
| `references/03-layout-xfa.md` | XDP, binding, tipos de layout, paginación, tablas, patrones, fuentes, imágenes, códigos de barras |
| `references/04-scripting.md` | FormCalc vs JavaScript, eventos, ocultar, numeración, subtotales por página, arrastre, copias |
| `references/05-programa-impresion-y-salida.md` | Programa de impresión, `SFPOUTPUTPARAMS` completo, correo, archivo, agrupar PDFs, errores |
| `references/06-gestion-salidas-s4.md` | NAST vs output control BRF+/OPD, formularios maestros, fragmentos, Maintain Form Templates |
| `references/07-textos-direcciones-graficos-traduccion.md` | SO10, módulos de texto, nodo de dirección, SE78, SE63/XLIFF, RTL |
| `references/08-impresion-y-dispositivos.md` | Tipos de dispositivo y XDC, ZPL/PCL/PostScript, SAPPDFPRINT, dúplex |
| `references/09-formularios-interactivos.md` | ZCI, Web Dynpro, offline, extracción de datos, usage rights |
| `references/10-ads-diagnostico-y-rendimiento.md` | Pruebas de ADS, tabla de errores, caché, rendimiento, notas SAP |
| `references/11-abix-runtime-lecciones.md` | Lo aprendido en vivo con `/adobeform`: despliegue sin SFP, trampas y su solución |

## Plantillas

| Archivo | Uso |
|---|---|
| `templates/base-documento.sfpf.json` / `.sfpf.xdp` / `.sfpf.data.xml` | Formulario completo verificado ✅: logo, recuadro redondeado, QR, imagen dinámica, tabla multipágina con encabezado repetido, "Página X de Y", total, resumen por moneda, bloque condicionado |
| `templates/bloques/*.xml` | Bloques XFA sueltos para componer (ver `templates/bloques/README.md`) |
| `templates/programa-impresion.abap` | Programa de impresión completo: vista previa, impresión, PDF, correo, archivo, agrupación y manejo de errores |
