# 02 — Definición del formulario (`{form}.sfpf.json`) y nodos de contexto

ABIX genera la interfaz SFPI y el contexto SFPF **por código** a partir de esta definición. Tú escribes el JSON; no escribas el asXML.

## Esquema

```json
{
  "form": "ZFI_CONSTANCIA_PDF",          // SFPF: Z/Y, ≤30, DISTINTO de "interface"
  "interface": "ZFI_CONSTANCIA_IF",      // SFPI
  "description": "Constancia de pagos",
  "params": [                            // parámetros de importación (todos opcionales por defecto)
    { "name": "CABECERA",  "type": "ZFI_S_CONST_CAB" },
    { "name": "PAGOS",     "type": "ZFI_T_CONST_PAGOS" },
    { "name": "LOGO",      "type": "XSTRING" },
    { "name": "ES_COPIA",  "type": "XFELD", "optional": true }
  ],
  "types": [                             // TYPES de la interfaz (líneas ABAP)
    "TYPES: BEGIN OF ty_tot, waers TYPE waers, importe TYPE wrbtr, importe_txt TYPE c LENGTH 25, END OF ty_tot.",
    "TYPES tt_tot TYPE STANDARD TABLE OF ty_tot WITH DEFAULT KEY."
  ],
  "globals": [ { "name": "TOTALES", "type": "TT_TOT" }, { "name": "LOGO_B64", "type": "STRING" } ],
  "initInputs":  [ "PAGOS", "LOGO" ],     // parámetros que LEE la inicialización
  "initOutputs": [ "TOTALES", "LOGO_B64" ],// globales que ESCRIBE
  "initCode": [ "logo_b64 = cl_web_http_utility=>encode_x_base64( logo ).", "..." ],
  "currencyRefs": [ { "value": "PAGOS-WRBTR", "unit": "PAGOS-WAERS" } ],  // kind: CURR (default) | QUAN
  "context": [ /* nodos, ver abajo */ ],
  "test": {                              // datos para la prueba de runtime (solo para renderizar)
    "abap": [ "DATA cabecera TYPE zfi_s_const_cab.", "DATA pagos TYPE zfi_t_const_pagos.",
              "SELECT * FROM zfi_pagos INTO TABLE @pagos UP TO 40 ROWS.",
              "IF pagos IS INITIAL.", "  pagos = VALUE #( ( belnr = '1000000001' wrbtr = '1500000' waers = 'COP' ) ).", "ENDIF." ],
    "params": [ "CABECERA", "PAGOS" ]    // opcional; por defecto, los parámetros que aparecen en "abap"
  }
}
```

### Reglas
- Nombres de nodo únicos por nivel; `A-Z0-9_`, empiezan con letra.
- `field`/`loop` deben apuntar a un parámetro o global (validación determinista de ABIX).
- `test.abap`: variables locales con el **mismo nombre** que los parámetros. Si DEV tiene datos, `SELECT … UP TO n ROWS`; si viene vacío, `VALUE #( … )` simulados. Varias filas para ver la paginación. **Solo sirven para renderizar: nada se graba.**
- El código de inicialización corre en el módulo generado: no hagas `COMMIT`, ni llamadas con pantalla, ni lecturas pesadas que podrían ir al programa.

## Nodos de contexto que genera ABIX

| `kind` | Clase SFP | Uso |
|---|---|---|
| `field` | `CL_FP_DATA` | Campo simple o estructura completa (`field` acepta rutas `CAB-NUMERO`) |
| `loop` | `CL_FP_LOOP` → `CL_FP_LOOP_DATA "DATA"` → `CL_FP_DATA` por columna | Tabla interna. `columns` = componentes usados (STATE A); `inactiveColumns` = el resto de la fila (STATE I) |
| `folder` | `CL_FP_FOLDER` | Agrupa nodos; con `conditions` el bloque solo existe en los datos si se cumple |

Condiciones: `{ "operand1": "CAB-STATUS", "operator": "EQ|NE|LT|LE|GT|GE", "operand2": "'X'" , "logical": "AND|OR" }` (`logical` une con la condición anterior). Literales entre comillas simples. ✅ (`EQ 'X'` verificado)

## Los 17 tipos de nodo de SFP (S/4HANA 2023) ✅

Herencia de `CL_FP_NODE` leída del sistema. ABIX genera hoy los tres de arriba; el resto se agrega a mano en SFP o requiere extender el generador.

| Clase | Nodo en SFP | Atributos clave |
|---|---|---|
| `CL_FP_CONTEXT` | raíz | — |
| `CL_FP_FOLDER` | Carpeta | condición |
| `CL_FP_DATA` | Campo / tabla / estructura | `FIELD` |
| `CL_FP_STRUCTURE` | Estructura (componentes generados) | `FIELD` |
| `CL_FP_LOOP` / `CL_FP_LOOP_DATA` | Bucle | `TABLE_NAME`, `WORK_AREA`, `WHERE_CONDITION`, `FIRST_LINE`/`LAST_LINE`, `SORTED`, `CONTROL_LEVEL` |
| `CL_FP_LOOP_CONTROL_GROUP` / `_DATA` | Nivel de control (agrupación en bucle) | — |
| `CL_FP_SINGLE_RECORD` | Registro único de una tabla | `TABLE_NAME`, `LINE`, `WITH_KEY_CONDITION`, `BINARY_SEARCH` |
| `CL_FP_ALTERNATIVE` (+`_TRUE`/`_FALSE`) | Alternativa (if/else) | `ALTERNATIVE_CONDITION` |
| `CL_FP_ADDRESS` | Dirección (llama a `ADDRESS_INTO_PRINTFORM`) | tipo, nº dirección, nº persona, líneas, país remitente, idioma receptor, prioridades, interlocutor (BUPA) |
| `CL_FP_TEXT_MODULE` | Módulo de texto (Smart Forms) | `TEXT_NAME`, `TEXT_LANGUAGE`, `TEXT_STYLE`, `STYLE_NAME`, `IGNORE_ERROR` |
| `CL_FP_TEXT_INCLUDE` | Texto SO10 (include) | `TEXT_NAME`, `TEXT_OBJECT`, `TEXT_ID`, `TEXT_LANGUAGE`, párrafos, `STYLE_NAME`, `IGNORE_ERROR` |
| `CL_FP_TEXT_DYNAMIC` | Texto dinámico (desde un campo) | `TEXT_FIELD`, `TEXT_LANGUAGE`, `STYLE_NAME` |
| `CL_FP_TEXT_BTF` | Texto BTF | — |
| `CL_FP_GRAPHIC_CONTENT` | Gráfico por contenido | `GRAPHIC_FIELD` (XSTRING), `GRAPHIC_MIME` |
| `CL_FP_GRAPHIC_URL` | Gráfico por URL (MIME repository) | `GRAPHIC_URL` |
| `CL_FP_PROGRAMLINES` | Líneas de programa | entradas, salidas, código — preferir la inicialización de la interfaz |
| `CL_FP_COMMAND` | Comando (atributos de spool) | `SPOOL_ATTRIBUTES` |

### Serialización (formato "Descargar objeto" de SFP) ✅

Cada nodo: `CL_FP_NODE` (`ID` GUID de 32 hex, `NAME`, `GENERATED`, `STATE` A/I, `CONDITION`/`PARENT`/`SUCCESSOR`/`CHILD` por `href="#oN"`) + bloque propio de la clase. Cada nodo (salvo la raíz) tiene su `CL_FP_CONDITION` con `NODE` de vuelta y `CONDITIONS` (vacío o lista de `SFPCONDITION`).

Los atributos de nodos avanzados se serializan como **valor fijo + campo dinámico** (`<X>valor</X><XFIELD>ruta</XFIELD>`):

```xml
<!-- Dirección (extracto real de un formulario estándar) -->
<CL_FP_ADDRESS classVersion="1">
  <ADDRESS_TYPE><ADDRTYPE/><ADDRTYPEFIELD>PWB_DATA-WA_REC_ADDRDT-ADRS_TYPE</ADDRTYPEFIELD></ADDRESS_TYPE>
  <ADDRESS_NUMBER><ADDRNUMBER/><ADDRNUMBERFIELD>PWB_DATA-WA_REC_ADDRDT-ADRS_NUM</ADDRNUMBERFIELD></ADDRESS_NUMBER>
  <PERSON_NUMBER><PERSNUMBER/><PERSNUMBERFIELD>…-PERS_NUM</PERSNUMBERFIELD></PERSON_NUMBER>
  <ADDRESS_LINES><ADDRLINES>10</ADDRLINES><ADDRLINESFIELD/></ADDRESS_LINES>
  <SENDER_COUNTRY><SENDERCOUNTRY/><SENDERCOUNTRYFIELD>…-COUNTRY</SENDERCOUNTRYFIELD></SENDER_COUNTRY>
  … STREET_PRIORITY, LANGUAGE_FOR_COUNTRY, RECEIVER_LANGUAGE, LINE_PRIORITY, BUPA_ORG, BUPA_PERSON, ADDRESS_HANDLE …
</CL_FP_ADDRESS>

<!-- Módulo de texto -->
<CL_FP_TEXT classVersion="1"><APPEND_MODE/></CL_FP_TEXT>
<CL_FP_TEXT_MODULE classVersion="1"><STYLE_NAME/>
  <TEXT_NAME><NAME>FI_CA_SHORT_ADRS_SENDER_SF</NAME><NAMEFIELD/></TEXT_NAME>
  <TEXT_LANGUAGE><LANGUAGE/><LANGUAGEFIELD/></TEXT_LANGUAGE><TEXT_STYLE>X</TEXT_STYLE><IGNORE_ERROR/>
</CL_FP_TEXT_MODULE>
```

Para un nodo sin ejemplo (SO10, gráfico), el camino seguro es crearlo una vez en SFP, *Utilidades → Descargar objeto* y copiar la forma.

### Alternativa sin nodos especiales (recomendada con `/adobeform`)
- **Dirección:** llamar `ADDRESS_INTO_PRINTFORM` en la inicialización y entregar las líneas en una tabla/string → campo de texto.
- **Texto SO10:** `READ_TEXT` en la inicialización → tabla de líneas (`TLINE`) → bucle o campo multilínea.
- **Logo SE78:** `cl_ssf_xsf_utilities=>get_bds_graphic_as_bmp( … )` → base64 → `imageEdit`.
Así todo queda en `field`/`loop` y en ABAP testeable.
