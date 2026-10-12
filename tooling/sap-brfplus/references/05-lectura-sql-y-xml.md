# 05 · Leer reglas por SQL y por XML

## Por qué SQL

Leer por SQL (`GetSqlQuery`, solo lectura) funciona en **cualquier sistema, incluido productivo y cerrado**, sin crear nada. Es la vía para entender y diagnosticar reglas existentes ✅.

## Catálogo de objetos ✅

| Tabla | Contenido |
|---|---|
| `FDT_ADMN_0000S` | Objetos de almacenamiento **sistema** (independiente de mandante): casi todo lo estándar de SAP |
| `FDT_ADMN_0000` | Objetos **customizing / datos maestros** del mandante (aquí suelen estar las apps Z del cliente y las apps OPD importadas) |

Campos: `ID` (GUID 32), `OBJECT_TYPE` (`AP`/`FU`/`EX`/`DO`/`RS`/`ET`…), `NAME`, `APPLICATION_ID`, `VERSION`, `DELETED`, datos de transporte.

```sql
-- aplicaciones (estándar y Z) del sistema / del mandante
SELECT id, name FROM fdt_admn_0000s WHERE object_type = 'AP' AND deleted = ' '
SELECT id, name FROM fdt_admn_0000  WHERE object_type = 'AP' AND deleted = ' '
-- objetos de una aplicación
SELECT object_type, name, id FROM fdt_admn_0000 WHERE application_id = '<APP_ID>'
```

Tipo de cada expresión: `FDT_EXPR_0000` (`ID`, `EXPR_TYPE_ID` = constante `GC_EXTY_*`, ver `02`) y `…0000S`.

## Reconstruir una tabla de decisión ✅

Tablas (sufijo `A`/`S`/`T` = variantes por almacenamiento/textos; las del mandante sin sufijo):

| Tabla | Contenido | Campos clave |
|---|---|---|
| `FDT_EXPR_0240` | Atributos de la tabla: **`MULTIPLE_MATCH`** (`X` = devuelve todas las filas que coinciden) y **`ALLOW_NO_MATCH`** (`X` = sin coincidencia no lanza excepción) | `ID`, `VERSION` |
| `FDT_EXPR_0241` | **Columnas** | `ID`, `VERSION`, `COL_NO`, `ELEMENT_ID`, `IS_RESULT` |
| `FDT_EXPR_0244` | **Celdas condición** | `ID`, `VERSION`, `COL_NO`, `ROW_NO`, `SEQNR`, `SIGN`, `OPTIONS`, `VALUEL`, `VALUEH` |
| `FDT_EXPR_0242` | **Celdas resultado** | `ID`, `VERSION`, `COL_NO`, `ROW_NO`, `VALUE` |
| `FDT_EXPR_0247` | **Valores empaquetados** (un valor usado por varias filas) | `COL_NO`, `VALUE_NO`, `SIGN`, `OPTIONS`, `VALUEL`, `VALUEH` |
| `FDT_EXPR_0248` | **Filas que usan cada valor empaquetado** | `COL_NO`, `VALUE_NO`, `ROW_NOS` (lista separada por espacios) |

Algoritmo:
1. Versión = la máxima en `0241` para el `ID`.
2. Columnas de `0241` (nombre de cada columna = `NAME` de `ELEMENT_ID` en `FDT_ADMN_0000(S)`).
3. Celdas de `0244` (condición) y `0242` (resultado) → `(fila, columna)`.
4. **Expandir los empaquetados**: para cada fila de `0248`, el valor de `0247` con el mismo `COL_NO`+`VALUE_NO` va a cada número de `ROW_NOS`. Sin este paso faltan casi todas las filas (en una tabla OPD real: 2 filas visibles → 9 reales).
5. Celda vacía = comodín `*`. Varias entradas para la misma celda = varias opciones (O).

`FDT_DT_D`/`FDT_DTROW_D` **no** son las de las tablas de decisión BRF+ (vacías en las pruebas). El script `scripts/brf-dt-read.mjs` de ABIX implementa esto.

Reports estándar de ayuda ✅: `FDT_ANALYZE_DECISION_TABLE` (huecos/solapamientos), `FDT_SHOW_OBJ_USAGE_TREE`, `FDT_SHOW_OBJ_REFERENCE_TREE`, `FDT_DDIC_WHERE_USED`, `FDT_CODE_SEARCH`, `FDT_APPLICATION_OVERVIEW`, `FDT_CONTENT_OVERVIEW`.

## Versión vigente ✅

La versión a leer es `FDT_ADMN_0000(S).VERSION`, **salvo** que esa versión esté inactiva en `FDT_ADMN_0030(S)` (`STATE <> 'A'`, cambios sin activar): entonces, la última con `STATE = 'A'`. Tomar "la versión máxima" NO es seguro. Los objetos de un mismo app pueden tener versiones distintas (en una OPD real: tablas en v2, v3, v4 y v5).

## Función, sets de reglas, reglas y objetos de datos ✅

| Tabla | Contenido | Campos clave |
|---|---|---|
| `FDT_FNCT_0100` | Función | `EXPRESSION_ID` (expresión de nivel superior), `RESULT_DOBJ_ID`, `FUNCTION_MODE` (1 funcional, 2 evento, 3 ambos, 4 analítico) |
| `FDT_FNCT_0110` | Contexto de la función | `DATA_OBJECT_ID` (una fila por objeto) |
| `FDT_RLST_0000` | Set de reglas | `FUNCTION_ID` (a qué función apunta), `SWITCH` (X = encendido), `PRIORITY`, `CONDITION_ID` |
| `FDT_RLST_1000` | Reglas del set, en orden | `POS`, `SWITCH`, `RULE_ID`, `CONDITION_ID`, `EXIT_RULESET`, `VALID_FROM`/`VALID_TO` |
| `FDT_EXPR_3000` | Regla | `COND_RANGE_P` (condición por rango sobre ese objeto) o `BOOLE_CONDITION` (booleano); `TRUE_ACTION`/`FALSE_ACTION` |
| `FDT_EXPR_3001` | Acciones de la regla | `TF_TYPE` (T = entonces, F = si no), `DOBJ_TARGET` + `EXPRESSION` (asignar resultado de expresión) / `VALUE` (asignar valor) / `DOBJ_SOURCE` (asignar objeto), `ACTION`, `RULE_ID` |
| `FDT_EXPR_3002` | Rango de la condición | `SIGN`, `OPTIONS`, `VALUEL`, `VALUEH` |
| `FDT_DOBJ_0000` | Tipo de objeto de datos | `DATA_OBJECT_TYPE` (E elemento, S estructura, T tabla) |
| `FDT_DOBJ_0100` | Elemento | `ELEMENT_TYPE` (T/N/B/A/Q/P), `LENGTH` |
| `FDT_DOBJ_0200` | Componentes de estructura | `SEQNR`, `ELEMENT_ID`/`STRUCTURE_ID`/`TABLE_ID` |
| `FDT_DOBJ_0300` | Línea de una tabla | `STRUCTURE_ID` |
| `FDT_DOBJ_0010` | Binding DDIC | `TYPENAME` |

Los sets de reglas de una función pueden estar en el OTRO almacenamiento (busca por `FUNCTION_ID` en `FDT_RLST_0000` y `…0000S`).

## Otras expresiones por SQL ✅

Resultado de **cualquier** expresión: `FDT_EXPR_0010.DATA_OBJECT_ID`.

| Expresión | Tablas | Cómo leerla |
|---|---|---|
| Constante | `FDT_EXPR_1000` | `VALUE` |
| Case | `1200` + `1202` | `1200.CASE_PARAMETER` (objeto evaluado), `1200.VALUE` (valor "otro"); `1202` por `WHEN_POSITION`: `VALUET` → `VALUER` (o `TEST_PARAMETER`/`RETURN_PARAMETER` si son expresiones) |
| Fórmula | `1401` | **Tokens** por `LINE`: `DO`/`EX` → ID del objeto/expresión en `FSYM`; `SP` → espacio; el resto, `FSYM` literal (operadores, paréntesis, funciones `FUnnnnnnnn`, strings `ST` ya entre comillas). Concatenar reconstruye el texto (p. ej. `MONTO * 1.19`) |
| Rango de valores | `1101` + `1104` | `1101.TEST_PARAMETER` + rangos de `1104` |
| Booleano | `1300` (+ `1302`/`1303`/`1304`) | `OPERATION` 1-6 = plantillas con operandos A/B/C (`IF_FDT_BOOLEAN=>GC_OPERATION_A_OR_B`=1, `A_AND_B`=2, `A_OR_B_OR_C`=3, `A_AND_B_OR_C`=4, `A_OR_B_AND_C`=5, `A_AND_B_AND_C`=6; operando = `FIRST/SECOND/THIRD_OPERAND` (expresión) o `…_RANGE_P` (objeto + rangos de `1304` con `TYPE` 1/2/3)); 7/8 = todos AND/OR (lista en `1303`); **9 = definido por el usuario: tokens en `1302`** (`TOKEN` AND/OR/NOT/paréntesis, u operando con rangos en `1304` `TYPE = 'U'` y `POS`) |

Ejemplo real decodificado (OPD de movimientos de mercancías): un booleano sin nombre en la regla `RU_HANDLE_COLLECTIVE_SLIP` = `VERSIONFORPRINTINGSLIP EQ 3 AND MATERIALDOCUMENTITEM NE 0001` → en el vale colectivo solo imprime la primera posición.

Siguen sin formato documentado: árboles (`0200`/`0210`, `0220`/`0230`/`0231`), llamada a procedimiento (`1500…`), búsqueda en BD (`2200…`), bucles, etc. Para esas, **export XML** o el workbench.

## Export / import XML ✅

```abap
DATA(lo_dx) = cl_fdt_factory=>if_fdt_factory~get_instance( )->get_data_exchange( ).
" Aplicación COMPLETA (no uses export_xml con el ID de la app: saca solo la cabecera, EntireApplication="False")
lo_dx->export_xml_application( EXPORTING iv_application_id = lv_app IMPORTING ev_string = lv_xml et_message = lt_msg ).
" Import: siempre primero simulado
lo_dx->import_xml( EXPORTING iv_string = lv_xml iv_simulate = abap_true iv_create = abap_true iv_activate = abap_true
                   IMPORTING ets_success = lts_ok ets_failure = lts_ko et_message = lt_msg ).
```

- `IMPORT_XML` acepta `iv_customizing_trrequest` / `iv_workbench_trrequest`, `iv_import_type`, `iv_import_scope` ✅.
- El export trae **mensajes de validación** de BRF+ (celdas inválidas, tablas sin columnas de condición): úsalos como chequeo de calidad.
- ⚠️ Cada export registra un ID `$X1P…` en el sistema (no es 100 % sin escritura).
- ⚠️ El XML trae BOM y un salto de línea tras `<?xml …?>`: quítalos antes de embeberlo en un literal ABAP.
- ⚠️ Una aplicación con estructuras ligadas al DDIC exporta grande: una app de prueba con `T001` dio **240 KB / 95 objetos** (81 son los componentes de la estructura).
- Reports estándar: `FDT_XML_EXPORT`, `FDT_XML_IMPORT` ✅; FM `FDT_UPLOAD_XML` ✅.

### Formato de la tabla de decisión en el XML ✅

- `TABLE_COLUMNS` (columnas), `TABLE_DATA` (`item` con `COL_NO`, `ROW_NO`, `S_VALUE` para resultados, `TS_RANGE` con `SIGN`/`OPTION`/`S_LOW_VALUE`/`S_HIGH_VALUE` para condiciones), **`PACKED`** (valores compartidos con `<ROWS>1 2</ROWS>`, igual que `0247`/`0248`) y `ROW_COUNT`.
- Agregar una fila: insertar sus celdas en `TABLE_DATA`, renumerar las siguientes y subir `ROW_COUNT`. Cambiar un valor compartido: editarlo en `PACKED`.
