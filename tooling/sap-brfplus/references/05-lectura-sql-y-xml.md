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
| `FDT_EXPR_0240` | Atributos de la tabla | `ID`, `VERSION` |
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

## Otras expresiones por SQL

Cada tipo tiene sus tablas `FDT_EXPR_xxxx` (`0200`/`0210` árbol de búsqueda, `0220`/`0230`/`0231` árbol de decisión, `0001`/`0010`/`0020` …). Su formato no está documentado: para otras expresiones **prefiere el export XML** (sistemas donde puedas ejecutar una clase) o la vista del workbench.

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
- Reports estándar: `FDT_XML_EXPORT`, `FDT_XML_IMPORT` ✅; FM `FDT_UPLOAD_XML` ✅.

### Formato de la tabla de decisión en el XML ✅

- `TABLE_COLUMNS` (columnas), `TABLE_DATA` (`item` con `COL_NO`, `ROW_NO`, `S_VALUE` para resultados, `TS_RANGE` con `SIGN`/`OPTION`/`S_LOW_VALUE`/`S_HIGH_VALUE` para condiciones), **`PACKED`** (valores compartidos con `<ROWS>1 2</ROWS>`, igual que `0247`/`0248`) y `ROW_COUNT`.
- Agregar una fila: insertar sus celdas en `TABLE_DATA`, renumerar las siguientes y subir `ROW_COUNT`. Cambiar un valor compartido: editarlo en `PACKED`.
