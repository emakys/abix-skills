# 11 — ABIX: despliegue sin SFP y lecciones verificadas en vivo

Todo lo de este archivo se verificó contra S/4HANA 2023 FPS03 con ADS en BTP (oct-2026), creando, actualizando y renderizando formularios generados desde cero.

## Cómo despliega ABIX (sin la transacción SFP)

No hay API remota estándar para escribir SFPF/SFPI (ADT solo expone metadatos; el servicio `/sap/bc/fp` es de solo lectura). ABIX usa **clases classrun** en `$TMP`, creadas por su bridge MCP (nunca por el modelo):

| Clase | Hace |
|---|---|
| `ZCL_ABIX_FPP_<ws>` (pre-validación) | XDP + datos de ejemplo embebidos → `cl_fp_ads_util=>render_pdf`. No necesita el formulario. NO valida interfaz ni contexto |
| `ZCL_ABIX_FPD_<ws>` (despliegue) | asXML embebido → `cl_fp_helper=>convert_xstring_to_interface/form` → `set_new_layout_id` → crear (`cl_fp_wb_*=>create`) o actualizar (`load` WRITE + `cl_fp_wb_helper=>*_set_object`) → `save` → `COMMIT WORK AND WAIT` → `RS_WORKING_OBJECT_ACTIVATE` (`ui_decoupled`) |
| `ZCL_ABIX_FPR_<ws>` (runtime) | `FP_FUNCTION_MODULE_NAME` → `FP_JOB_OPEN(getpdf)` → módulo generado con los datos de `test.abap` → `FP_JOB_CLOSE` |

El PDF vuelve en base64 en la salida de `RuntimeRunClass` y queda en el workspace.

Gates: SAP conectado, `accessMode` readWrite, sistema modificable (solo `TADIR-EDTFLAG='N'` es cerrado) y mandante no productivo. Paquete y orden: los del workspace.

## Trampas y su solución

| Trampa | Solución |
|---|---|
| `cl_fp_wb_helper=>interface_exists`/`form_exists` | Lanzan `object_not_existing` si **no** existe; sin excepción = existe |
| Update dumpea `dynpro SAPLSETX 0100` | La sesión classrun corre en EN y SAP quiere preguntar por el idioma: `load( i_language = <maestro> i_suppress_language_check = 'X' )` |
| `sy-langu` = EN en classrun | Pasar el idioma explícito en todo (lectura de layout, docparams) |
| Carga y activación de SFPF fallan con `CX_FP_API_INTERNAL` | ADS caído (`copy_template`). Sin ADS no hay despliegue posible |
| Imagen dinámica en blanco | XSTRING → base64 en la inicialización, campo `imageEdit` con `contentType` |
| Importe en yenes "0.094800" | `TCURX` del sistema (JPY con 6 decimales en ese sistema). El formulario respeta la configuración |
| Título cortado | `multiLine` + `minH`/`maxH` |
| Pre-validación OK pero runtime distinto | La pre-validación usa XML armado a mano; la serialización real de tipos ABAP (XSTRING, importes, fechas) solo se ve en el runtime real |
| Formulario cargado con el nombre de la interfaz | En SFP el nombre lo pone el campo de pantalla; con ABIX no aplica |

## Ciclo recomendado

1. Partir de `templates/base-documento.*` y los bloques.
2. **Pre-validar** hasta que el diseño esté bien (rápido, no crea el formulario).
3. **Desplegar y probar** con datos de prueba realistas (varias páginas).
4. Leer el PDF del runtime: datos vacíos, formatos, cortes, imágenes, paginación.
5. Corregir definición/layout → `/adobeform desplegar` → repetir.

## Datos de prueba

Solo para renderizar: nada se graba en SAP. `test.abap` lee datos reales de DEV si existen (`SELECT … UP TO n ROWS`) y simula si no. Mismos valores en `.sfpf.data.xml` para la pre-validación.
