# 10 — ADS: diagnóstico y rendimiento

## Secuencia de prueba (SA38) ✅ programas existen en S/4 2023

1. **`FP_TEST_00`** — si muestra el formulario de prueba en vista previa, ADS está bien configurado.
2. **`FP_PDF_TEST_00`** — si muestra la versión de ADS, la conexión RFC/HTTP está bien.
3. **`FP_CHECK_DESTINATION_SERVICE`** — con y sin la casilla; debe reportar bytes transferidos.
4. Interactivos: `FP_TEST_IA_01` ✅ y credencial configurada.

Configuración: destino **`ADS`** (SM59, tipo G) y tabla **`FPCONNECT`** (destino, caché, versión de ADS). La plantilla debe ser accesible por ADS: `http://<host>:<puerto>/sap/bc/fp/form/layout/fp_test_00.xdp` ✅ (servicio ICF `/sap/bc/fp`). Guías: notas 894009 (configuración), 944221 (análisis de errores).

## Tabla de errores

| Síntoma | Causa típica | Acción |
|---|---|---|
| `FPRUNX001/002/004` al llamar el módulo | Binding sin resolver, formato de dato no coincide con el patrón, carácter inválido en los datos, error HTTP | `FP_GET_LAST_ADS_ERRSTR`; `ADSTRLEVEL` + `FP_GET_LAST_ADS_TRACE`; KBA 2359874 (capturar el XML de datos) |
| `ProcessingException 200101` | Rol `SAP_BC_FP_ICF` con autorizaciones en amarillo; falta destino Java→ABAP | PFCG generar perfil (nota 915399); destino en NWA |
| `HTTP-401 Unauthorized` | Usuario ADS / autenticación ICF `fp`/`fpads` | KBA 3427687, 2215134 |
| `SOAP runtime exception 100101` | Transporte HTTP a ADS | SM59, certificados, proxy |
| `ZCI-002 could not be found` (Web Dynpro) | Formulario sin actualizar a ZCI | `SFP_ZCI_UPDATE` |
| `Invalid usage right` | ADS/J2EE con patch menor que ABAP | Alinear patches |
| `SPADS011` | Tipo de dispositivo sin XDC | `RSPO0022` / tipo estándar (`08`) |
| `CX_FP_API_INTERNAL` al **cargar** en SFP o activar ✅ | ADS caído: `set_new_layout_id` → `copy_template` llama a ADS | Levantar ADS; probar `FP_TEST_00` |
| Cargar objeto: "El objeto … ya existe" ✅ | SFP toma el nombre del **campo de la pantalla**, no del archivo; *Cargar objeto* solo crea | Escribir un nombre nuevo, o actualizar con la ruta de ABIX (`11`) |
| Campo vacío en el PDF | Binding a nombre inexistente, nodo inactivo (STATE I) en el contexto, patrón de datos | Revisar `$.RUTA`, contexto y `<bind><picture>` |
| Imagen no aparece ✅ | XSTRING crudo enlazado a `imageEdit` | Base64 en la inicialización o nodo gráfico |
| Importes absurdos (p. ej. `0.094800`) ✅ | Decimales de la moneda en TCURX del sistema | Revisar TCURX; formatear con `WRITE … CURRENCY` |
| Texto cortado ✅ | Campo de una línea / altura fija | `multiLine` + `minH`/`maxH` |
| Página en blanco al final | `breakAfter` incondicional o subform con altura fija | Salto condicional; quitar alturas fijas |
| Encabezados duplicados / campos superpuestos | Leader/trailer en flujo o con binding | Leader/trailer posicionado y sin binding |

## Caché

- En el formulario (Propiedades → Valores por defecto): *permitir caché del render en el servidor* para layouts fijos.
- En el servidor: campo `CACHING` de `FPCONNECT` (aplica a todos los formularios del sistema).
- Caché obsoleta tras cambios: `IQS1_REFRESH_ALL` ✅ limpia parte; desactivar caché de plantillas (nota 2258036).

## Rendimiento

- **Imágenes** primero: PNG/JPG al tamaño real; un logo "chico" en BMP puede inflar el PDF.
- Fuentes: pocas, estándar, embeber solo si hace falta.
- Formularios **estáticos** renderizan más rápido; minimizar visibilidad dinámica anidada.
- Lógica en el programa (no en la interfaz ni en scripts); el formulario recibe datos listos.
- ADS dedicado y balanceado para volumen (notas 1522165, 1462986); `poolmax` solo si hay carga real; métricas por plantilla (nota 2714231: `adsTime`, tamaño de request/response).
- Volumen muy alto: agrupar (`BUMODE`), paralelizar, y evaluar límites (notas 894389, 735050, 852235).
