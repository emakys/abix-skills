# PPF y BRF+ en EWM

> **Verificación (oct-2026, S/4HANA 2023 FPS03 on-premise):** todo objeto marcado ✅ se comprobó que existe en un
> sistema real (tablas DD02L, clases SEOCLASS, transacciones TSTC, BAdIs BADI_MAIN, catálogo BRF+ FDT_ADMN_0000S).
> Lo que no lleva ✅ es concepto o ejemplo ilustrativo. **No inventar nombres de objetos**: si hace falta uno que no
> está acá, buscarlo con `SearchObject` / `GetSqlQuery` antes de afirmarlo.

## 1. Post Processing Framework (PPF)

### Concepto

El **PPF** es un framework genérico (no exclusivo de EWM) que ejecuta **acciones** sobre documentos de negocio cuando
se cumplen **condiciones**. En EWM se usa para: impresión de documentos y etiquetas (entregas, HUs, órdenes de
almacén, inventario, VAS), mensajes a otros sistemas y pasos automáticos de los documentos de entrega.

- **Condición de planificación** (*schedule condition*): ¿se crea la acción para este documento?
- **Condición de inicio** (*start condition*): ¿ya se puede ejecutar la acción creada?
- **Método de tratamiento** (*processing medium*): qué hace la acción — método BAdI, impresión Smart Forms / PDF (Adobe), workflow, alerta, fax/correo.
- **Momento de tratamiento**: inmediato, al grabar el documento, o por job de selección (`RSPPFPROCESS` / `SPPFP`).

### Aplicaciones PPF de EWM ✅

Leídas de `PPFTAPPL` (aplicaciones en customizing):

| Aplicación PPF | Ámbito |
|----------------|--------|
| `/SCDL/DELIVERY` | Documentos de entrega (entregas de entrada/salida, pedidos de entrega de salida) |
| `/SCWM/SHP_RCV` | Expedición y recepción (unidades/vehículos de transporte, puertas) |
| `/SCWM/WME` | Objetos de almacén (HU, orden de almacén, inventario, VAS, etc.) |

### Configuración

- **IMG**: SPRO → Extended Warehouse Management → Cross-Process Settings → … → *Post Processing Framework* (la ruta exacta varía por versión; buscar "PPF" o "Action Profile" en el IMG).
- **`SPPFCADM`** ✅ — administración del customizing PPF (aplicación → perfil de acciones → definición de acción → condiciones).
- Las **condiciones** se mantienen con el editor de condiciones del PPF (tipo de condición de la definición de acción), o por BAdI (ver abajo).

### Transacciones ✅

| Transacción | Uso |
|-------------|-----|
| `SPPFCADM` | Customizing del PPF |
| `SPPFP` | Procesar acciones pendientes / reprocesar acciones con error |
| `SPPFDEMO` | Demo del PPF (útil para entender el flujo) |
| `/SCWM/PRDI` | Procesar entrega de entrada — ahí se ven las acciones PPF del documento |
| `/SCWM/PRDO` | Procesar pedido de entrega de salida — ídem |

> ⚠️ No existen `/SCWM/PPFCOND`, `/SCWM/PPFACT` ni `/SCWM/PPFLOG` (verificado). El log de acciones se ve en el propio
> documento y en `SPPFP`.

### Tablas ✅

| Tabla | Contenido |
|-------|-----------|
| `PPFTAPPL` | Aplicaciones PPF (customizing) |
| `PPFTTTCU` | Definiciones de acción (customizing) |
| `PPFTCONDE` | Contexto (perfil de acciones) en customizing |
| `PPFTCOND` | Condiciones |
| `PPFTTRIGG` | **Acciones creadas en tiempo de ejecución** (una fila por acción/documento: `APPLCTN`, `CONTEXT`, `TTYPE`, `STATUS`, `APPL_OID`…). Es la tabla para diagnosticar "¿se creó / se ejecutó la acción?" — no es customizing |

> ⚠️ No existen `PPFTACTION` ni `/SCWM/T_PPF_ACTP`.

### Clases y BAdIs PPF de EWM ✅

Clases de acción/método PPF estándar (ejemplos verificados): `/SCWM/CL_DLV_PPF_CONF`, `/SCWM/CL_DLV_PPF_EXEC`,
`/SCWM/CL_DLV_PPF_SCHED`, `/SCWM/CL_HU_PPF`, `/SCWM/CL_WO_PPF`, `/SCWM/CL_PI_PPF`, `/SCWM/CL_VAS_PPF`,
`/SCWM/CL_IM_PRINTER_PPF`, `/SCWM/CL_IM_PRINT_DET_PPF`. Para encontrar más: `SearchObject` con `/SCWM/CL_*PPF*`.

BAdIs:

| BAdI | Uso |
|------|-----|
| `EVAL_SCHEDCOND_PPF` ✅ | Condición de planificación propia (BAdI clásico del PPF) |
| `EVAL_STARTCOND_PPF` ✅ | Condición de inicio propia |
| `/SCWM/EX_DLV_PPF_CONF` ✅ | Configuración de acciones PPF de entrega |
| `/SCWM/EX_DLV_TOWHR_CREA_PPF` ✅ | Acciones PPF al crear la solicitud de almacén desde la entrega |
| `/SCWM/EX_PRNT_CTRL_PPF_HU` ✅ | Control de impresión PPF de HU |

> ⚠️ No existen `/SCWM/EX_PPF_ACTION`, `/SCWM/EX_PPF_CONDITION`, `/SCWM/CL_PPF_ACTION_HANDLER` ni
> `/SCWM/CL_PPF_COND_BRF`. **En EWM estándar no hay una clase que una PPF con BRF+**: una condición PPF basada en
> BRF+ es un desarrollo del cliente (BAdI `EVAL_SCHEDCOND_PPF` que llama a una función BRF+, ver §3).

## 2. BRF+ en EWM estándar

### Dónde lo usa SAP de verdad ✅

En EWM estándar, BRF+ se usa en **Labor Management** y en el **cálculo de tiempos de transporte (TDC)** — no en las
estrategias de ubicación, extracción ni en la selección de templates de ola. Aplicaciones de sistema verificadas
(`FDT_ADMN_0000S`):

| Aplicación BRF+ | Funciones | Uso |
|-----------------|-----------|-----|
| `/SCWM/LM_LA_SYS` | `/SCWM/LM_DETERMINE_LA_WO`, `_VS`, `_RH`, `_RV`, `_HU`, `_PI`, `_WT`, `_QD`, `_QE` | Labor Management: determinación de la **actividad de mano de obra** por objeto (orden de almacén, VAS, HU, tarea, inventario, …) |
| `/SCWM/LM_ELS_SYS` | `/SCWM/LM_ELS_CALC_WHOPI`, `_INV_I`, `_IL`, `_EWL`, `_HU`, `_HU_I`, `_VAS`, `_RH`, `_RV`, `_WHOWT`, `_WT`, `_QD`, `_QE` | Labor Management: cálculo de **estándares de mano de obra (ELS, Engineered Labor Standards)** |
| `/SCWM/LM_PFD_SYS` | `/SCWM/LM_PFD` | Labor Management: factores PFD (personal, fatiga, demora) |
| `/SCWM/TDC_SYS` | `/SCWM/TDC_CALC_TIME` | Cálculo de tiempo de transporte |

Objetos relacionados ✅: clase `/SCWM/CL_LM_BRFPLUS_EXIT` (exit de Labor Management hacia BRF+), clase
`/SCWM/CL_EI_TDC_BRF_CALC_TIME` y BAdI `/SCWM/EX_TDC_BRF_CALC_TIME` (cálculo de tiempo TDC), transacción
`/SCWM/ELS` (estándares de mano de obra).

> Las aplicaciones `*_SYS` son de **almacenamiento de sistema**: no se modifican; el cliente copia o crea las suyas
> (aplicación de customizing, nombre Z) y las referencia desde el customizing de Labor Management.

> ⚠️ No existen `/SCWM/CL_SRULE_BRF`, `/SCWM/CL_PUT_STRAT_BRF` ni `/SCWM/CL_WAVE_TEMPL_BRF`. La determinación de
> estrategia de ubicación/extracción, del tipo de proceso de almacén y del template de ola se hace por **customizing
> EWM** (indicadores de búsqueda, tablas de determinación de tipo de almacén, condiciones de ola) y **BAdIs** del área
> correspondiente — no por BRF+. Si un cliente lo resolvió con BRF+, es desarrollo propio.

### Conceptos BRF+

| Concepto | Descripción |
|----------|-------------|
| Aplicación | Contenedor (tipo de almacenamiento: sistema / customizing / datos maestros) |
| Función | Punto de entrada: objetos de datos de **contexto** (entrada) y un objeto **resultado** |
| Ruleset | Conjunto de reglas asignado a una función (modo evento) |
| Regla | Si condición → acciones |
| Tabla de decisión | Columnas de condición y de resultado; devuelve la primera fila (o todas) que coincide |
| Expresión | Constante, fórmula, búsqueda en BD, llamada a procedimiento, etc. |

## 3. Llamar BRF+ desde ABAP (API real) ✅

> Detalle completo de BRF+ (API, modos, simulación, lectura por SQL, OPD): skill **`sap-brfplus`**.

```abap
" Ejecutar una función BRF+ por ID (GUID de 32 caracteres, ver FDT_ADMN_0000S)
DATA lt_nv TYPE abap_parmbind_tab.
DATA lr_result TYPE REF TO data.

" Referencia tipada al objeto de datos resultado
cl_fdt_function_process=>get_data_object_reference(
  EXPORTING iv_function_id = lv_function_id
            iv_data_object = lv_result_id   " = get_function( id )->get_result_data_object( )
  IMPORTING er_data        = lr_result ).
ASSIGN lr_result->* TO FIELD-SYMBOL(<ls_result>).

" Contexto: un par nombre/valor por objeto de datos de entrada (nombre = nombre del objeto en BRF+)
lt_nv = VALUE #( ( name = 'LGNUM' value = REF #( lv_lgnum ) ) ).

cl_fdt_function_process=>process(
  EXPORTING iv_function_id = lv_function_id
  IMPORTING ea_result      = <ls_result>
  CHANGING  ct_name_value  = lt_nv ).
```

- Generador de código oficial: report **`FDT_TEMPLATE_FUNCTION_PROCESS`** ✅ — genera la llamada exacta (con los
  tipos correctos) para una función dada. Usarlo antes que escribir el contexto a mano.
- Leer la definición: `cl_fdt_factory=>if_fdt_factory~get_instance( )->get_function( id )` →
  `get_context_data_objects( )` / `get_result_data_object( )`.
- Catálogo por SQL: `FDT_ADMN_0000S` (ID, OBJECT_TYPE — `FU` función, `AP` aplicación, `EX` expresión —, NAME,
  APPLICATION_ID). El contenido de las reglas vive en decenas de tablas `FDT_*` por tipo: leerlo por API o export XML
  (`CL_FDT_DATA_EXCHANGE`, report `FDT_XML_EXPORT`), no por SQL.
- Objeto de transporte: `R3TR FDT0`.

> ⚠️ No existen la clase `/BRF/FUNCTION`, el FM `FDT_PROCESS_FUNCTION` ni las tablas `FDT_FUNCTION` / `FDT_RULE`, ni
> las transacciones `FDT_EXPR` / `FDT_RULE`. El workbench es `BRF+` / `BRFPLUS` / `FDT_WORKBENCH` ✅ (Web Dynpro).

## 4. Ejemplos ilustrativos (desarrollo de cliente, NO estándar)

Patrones habituales cuando un cliente decide parametrizar reglas EWM con BRF+ propio. Todos los nombres son
inventados para el ejemplo: crear las aplicaciones en el namespace del cliente (Z/Y).

```
Tabla de decisión Z (ilustrativa): selección de impresora/formulario de etiqueta de HU
| Tipo de HU | País destino | Mercancía peligrosa | → Formulario   | → Impresora   |
|------------|--------------|---------------------|----------------|---------------|
| PALLET     | *            | X                   | ZHU_HAZMAT     | ZEBRA_DOCK_A  |
| PALLET     | *            | *                   | ZHU_PALLET     | ZEBRA_PACKING |
| *          | US           | *                   | ZHU_US         | LASER_DOCK_A  |
```

Integración típica: implementación del BAdI `EVAL_SCHEDCOND_PPF` (condición PPF) o de un BAdI de determinación de
impresora que construye el contexto desde el documento y llama a la función con `CL_FDT_FUNCTION_PROCESS=>PROCESS`.

Pasos:
1. Crear aplicación BRF+ Z (almacenamiento *customizing* si las reglas las mantiene funcional) en `BRF+`.
2. Función con objetos de contexto (campos del documento) + resultado; tabla de decisión.
3. Probar con la simulación del workbench o con un classrun que llame `PROCESS` con datos reales.
4. Llamarla desde el BAdI correspondiente (generar el esqueleto con `FDT_TEMPLATE_FUNCTION_PROCESS`).
5. Transportar `FDT0` junto con el BAdI.

## 5. Consultas MCP útiles

```
-- Clases PPF de EWM
SearchObject: object_name=/SCWM/CL_*PPF*
-- BAdIs PPF de EWM
GetSqlQuery: SELECT badi_name FROM badi_main WHERE badi_name LIKE '/SCWM/%PPF%'
-- Aplicaciones y funciones BRF+ de EWM
GetSqlQuery: SELECT id, object_type, name FROM fdt_admn_0000s WHERE name LIKE '/SCWM/%' AND object_type IN ('AP','FU')
-- ¿Se creó la acción PPF para un documento? (diagnóstico)
GetSqlQuery: SELECT applctn, context, ttype, status, timecreate FROM ppfttrigg WHERE applctn = '/SCDL/DELIVERY' AND ttype = '<acción>'
```

## 6. Buenas prácticas

1. **No afirmar BRF+ donde SAP no lo usa**: ubicación, extracción, tipo de proceso y olas se resuelven con customizing + BAdIs.
2. **Acciones pesadas en background** (impresión masiva, mensajes externos): momento "procesar por job de selección" y reproceso en `SPPFP`.
3. **Diagnóstico de impresión que no sale**: primero `PPFTTRIGG` (¿existe la acción? ¿`STATUS`?), luego el log de la acción en el documento, luego la condición.
4. **BRF+ del cliente**: aplicación de customizing si las reglas las mantiene funcional (se transportan como customizing); de sistema solo si es lógica técnica. Nunca modificar las `*_SYS` estándar.
5. **Probar funciones BRF+ con datos reales** antes de transportar (simulación del workbench o `PROCESS` desde un classrun de solo lectura).
