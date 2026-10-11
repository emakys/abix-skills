# 01 · Arquitectura y objetos de BRF+

## Qué es

BRF+ (BRFplus, *Business Rule Framework plus*) es el motor de reglas de SAP NetWeaver/ABAP Platform (prefijo técnico **FDT**, *Formula and Derivation Tool*). Viene con el ABAP Platform sin licencia extra; **DSM** (Decision Service Management) es un add-on con licencia aparte (ver `06`).

- Diseño: **workbench Web Dynpro** — transacciones `BRF+` / `BRFPLUS` / `FDT_WORKBENCH` ✅. No hay editor ADT.
- Ejecución: ABAP llama a una **función**; BRF+ **genera código ABAP** (clases en el namespace `/FDT/…`) para las funciones y lo ejecuta. Si no puede generar, **interpreta** (mucho más lento, ver `04`).
- Objeto de transporte: **`R3TR FDT0`** ✅ (una aplicación o sus objetos).

## Tipos de objeto (`IF_FDT_CONSTANTS=>GC_OBJECT_TYPE_*`) ✅

| Código | Objeto |
|---|---|
| `AP` | Aplicación |
| `DO` | Objeto de datos |
| `EX` | Expresión (incluye reglas, tablas de decisión, acciones…) |
| `ET` | Tipo de expresión (catálogo de tipos, también propios de aplicaciones SAP) |
| `FU` | Función |
| `RS` | Set de reglas |
| `CA` | Catálogo (agrupación de objetos para usuarios de negocio) |
| `FI` | Filtro |
| `DR`/`DT`/`VO`/`DV` | Objetos del modo analítico/BD (regla BD, plantilla, vocabulario, vista BD dinámica) |

## Aplicación y almacenamiento

Al crear la aplicación se elige el **tipo de almacenamiento**; **no se cambia después**. Los objetos heredan el de su aplicación.

| Almacenamiento | Tablas | Cliente | Transporte | Uso |
|---|---|---|---|---|
| **Sistema** | `…S` (clase de entrega S) | Independiente | Orden de **workbench** | Lógica técnica; no se modifica en sistemas destino |
| **Customizing** | clase C | Dependiente | Orden de **customizing** | El caso normal para funciones llamadas desde ABAP |
| **Datos maestros** | clase A | Dependiente | **No se transporta** | Reglas que el negocio cambia en cada sistema/cliente (p. ej. ligadas a clientes, materiales) |

- Los objetos de sistema no pueden referenciar objetos de customizing/datos maestros; los de customizing solo referencian sistema; los de datos maestros referencian ambos. Patrón útil: la **función** en una app de customizing y algunas **tablas de decisión** en una app de datos maestros (mantenibles en cada sistema).
- **Aplicación local**: `create_local_application( )` → paquete `$TMP`, no transportable, **no entra en TADIR** ✅. También existen `create_customizing_application`, `create_system_application`, `create_masterdata_application` (`IF_FDT_APPLICATION`) ✅.
- Copia entre clientes: app customizing/datos maestros en paquete transportable → `SCC1`; si es local → exportar e importar XML en cada cliente.
- Aplicación **temporal** `IF_FDT_CONSTANTS=>GC_APPLICATION_TMP` (`0000AAAA000000FF…`): para objetos en memoria que no se graban (usada por los demos estándar y para simular, ver `04`) ✅.

Otras propiedades de la aplicación (`IF_FDT_APPLICATION`, setters ✅): componente de aplicación, componente de software, paquete (`SET_DEVELOPMENT_PACKAGE`), **modo de versionado** (`SET_VERSIONING_MODE`), moneda de la aplicación, conexión BD secundaria, ajustes de log, **clase de salida** (`SET_SETTINGS_CLASS`, ver `06`), atributos propios.

## Versionado

- Por aplicación se elige si los objetos quedan **bajo versión**: cada activación crea una versión nueva con fecha de validez; las funciones se pueden ejecutar "como estaban" en un momento dado (`iv_timestamp` en `PROCESS`).
- Sin versionado (por defecto en apps locales), la versión queda en `000001` y se sobrescribe ✅.
- La **lean trace** exige versionado activo.
- Limpieza: reports `FDT_TRUNCATE_VERSIONING`, `FDT_SET_VERSIONING`, herramienta de administración de aplicaciones (`FDT_HELPERS`, `FDT_APPLICATION_CLEANUP`) ✅.
- El código generado depende de las versiones: varias versiones vigentes → varias clases generadas.

## Objetos de datos

### Elementos (`IF_FDT_CONSTANTS=>GC_ELEMENT_TYPE_*`) ✅

| Tipo | Código | Tipo ABAP en BRF+ |
|---|---|---|
| Texto | `T` | `if_fdt_types=>element_text` |
| Número | `N` | `if_fdt_types=>element_number` (decfloat34) |
| Booleano | `B` | `if_fdt_types=>element_boolean` |
| Importe | `A` | `if_fdt_types=>element_amount` (número + moneda) |
| Cantidad | `Q` | `if_fdt_types=>element_quantity` (número + unidad) |
| Punto en el tiempo | `P` | `if_fdt_types=>element_timepoint` (estructura: fecha, hora, tipo) |

Importe y cantidad son más lentos que número (conversión de moneda/unidad): úsalos solo si la regla necesita la moneda/unidad.

Elementos predefinidos sin crear nada (`GC_DOBJ_ELEMENT_TEXT`, `_NUMBER`, `_BOOLEAN`, `_AMOUNT`, `_QUANTITY`, `_TIMEPOINT`) ✅ — útiles como tipo de resultado de constantes y fórmulas.

### Estructuras y tablas

- Estructura: `get_data_object( iv_data_object_type = gc_data_object_type_structure )` + `set_elements( ts_element )` (posición + id de elemento/estructura/tabla) ✅.
- Tabla: `gc_data_object_type_table` + `set_structure( id )` — la línea puede ser un elemento o una estructura (demo `FDT_DEMO_REPORT_LOOP`, `FDT_DEMO_REPORT_PROC_CALL`) ✅.

### Binding DDIC ✅

- `if_fdt_data_object~set_ddic_binding( iv_ddic_typename = 'T001' )` sobre una **estructura** crea un elemento por campo (81 para `T001`) y los deja ligados; `ets_object_id` devuelve los creados.
- Sobre un **elemento**: `set_ddic_binding( iv_ddic_typename = 'BLART' )` → toma tipo, longitud y textos del elemento de datos (valores fijos del dominio incluidos).
- Otros bindings: GDT/ESR (`set_gdt_binding`), elemento de referencia (`GC_BINDING_TYPE_REF_ELEMENT`).
- ⚠️ Los tipos se **traducen** a los de BRF+ (timestamp → `ELEMENT_TIMEPOINT`). Ver regla 5 del SKILL.
- Utilidades: `CL_FDT_CONVENIENCE=>CREATE_DOBJ_DDIC`, `CREATE_FUNCTION_W_DDIC_STRUCT`, `DO_WHERE_USED_DDIC`/`DO_WHERE_USED_CDS` ✅; report `FDT_DDIC_WHERE_USED` (qué objetos BRF+ usan un tipo DDIC).

## Contexto y resultado

- **Contexto** = objetos de datos de entrada de la función (`set_context_data_objects`). En modo evento las reglas pueden **modificarlos** (asignaciones con `change_mode`).
- **Resultado** = un objeto de datos (`set_result_data_object`). En OPD suelen ser **tablas** (varios tipos de salida, varios receptores) o estructuras (impresora + copias).
- Clase de contexto opcional (`set_context_class`) para tipar el contexto desde una clase.

## Catálogos

Agrupan funciones/objetos para que usuarios de negocio naveguen y mantengan reglas sin ver la aplicación entera (`FDT_WD_START_CATALOG_BROWSER`) ✅.
