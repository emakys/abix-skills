# 06 · Transporte, salidas de aplicación, autorizaciones y herramientas

## Transporte

- Objeto **`R3TR FDT0`** ✅. Almacenamiento **sistema** → orden de workbench; **customizing** → orden de **customizing**; **datos maestros** → no se transporta (`01`).
- Al grabar una app transportable, BRF+ pide orden. Por API: `save( iv_transport_request = … )` (`IF_FDT_TRANSACTION`) o `import_xml( iv_customizing_trrequest | iv_workbench_trrequest )`.
- Reports ✅: `FDT_TRANS` (escribir una app o IDs en una orden), `FDT_TRANS_MASS_CHECK` (chequeo masivo de objetos en órdenes), `FDT_TRANS_Q_RESTART`. Transacciones: `FDT_TRANS_EMEX`, `FDT_TRANS_CLOUD` ✅.
- ⚠️ Un transporte desde DEV **sobrescribe** la tabla de decisión en destino: si el negocio mantiene filas en QAS/PRD, respáldalas antes (Excel o XML).
- Copia entre mandantes: app transportable → `SCC1`; app local → export/import XML por mandante.

## Mantener reglas en productivo

Opciones (de más a menos recomendada):
1. Diseñar la parte variable como **aplicación de datos maestros** (no transportable, editable en cada sistema).
2. **Salida `GET_CHANGEABILITY`** en la clase de salida de la aplicación: permite cambiar objetos customizing en un sistema donde normalmente no se podría.
3. **DSM** (abajo).

## Salidas de aplicación — `IF_FDT_APPLICATION_SETTINGS` ✅

Una aplicación tiene **una** clase de salida (`SET_SETTINGS_CLASS`) que implementa la interfaz. Cada salida es un método **estático** que solo se llama si su atributo `GV_<SALIDA>` está en `abap_true` (se pone en el `CLASS_CONSTRUCTOR`).

| Método | Para qué |
|---|---|
| `AUTHORITY_CHECK` | Autorización propia, más fina que la estándar (`ev_passes`; actividades en `IF_FDT_CONSTANTS=>GC_ACTIVITY_*`) |
| `CHECK` | Chequeos adicionales (reglas de modelado del equipo); la activación ya lo dispara |
| `ACTIVATION_VETO` | Vetar una activación (`et_message`); también usado para sincronizar tablas Z al activar |
| `GET_CHANGEABILITY` | Permitir/bloquear cambios según sistema/cliente |
| `SAVE_NOTIFICATION` / `CHANGE_NOTIFICATION` | Reaccionar a cambios |
| `GET_CALENDAR` | Calendario de fábrica para funciones de fecha |
| `GET_FORMULA_FUNCTIONALS` | Agregar funciones propias al editor de fórmulas |
| `GET_ELEMENT_VALUES` | Lista de valores para un elemento |
| `DELETE_TRACE_VETO` | Impedir borrar trazas |

Dentro de una salida el control salió de BRF+: los errores no controlados son responsabilidad del implementador.

## Autorizaciones ✅

Objetos: `FDT_WORKB` (workbench), `FDT_OBJECT` (objetos por aplicación/tipo/actividad), `FDT_ADMN` (administración), `FDT_TRACE` (trazas), `FDT_PROC` (ejecución), `FDT_DDBV`, `FDT_BRS_MS`, `FDT_BRS_VA`, `FDT_CP_IN`, `S_FDT_CP`. Para ejecutar desde un programa existe `CL_FDT_FUNCTION_PROCESS=>AUTHORITY_CHECK_FOR_PROCESSING`.

## Herramientas y transacciones ✅

| Transacción / report | Uso |
|---|---|
| `BRF+`, `BRFPLUS`, `FDT_WORKBENCH`, `FDT_WB` | Workbench (Web Dynpro) |
| `FDT_HELPERS` | Utilidades varias (administración, borrado, reorganización) |
| `FDT_WD_ADMIN_TOOL`, `FDT_APPLICATION_CLEANUP`, `FDT_DELETE`, `FDT_MARK_FOR_DELETE`, `FDT_REORGANIZE_OBJECTS` | Limpieza: versiones viejas, objetos marcados, reorganizar |
| `FDT_TRUNCATE_VERSIONING`, `FDT_SET_VERSIONING` | Versionado |
| `FDT_TEST_SUITE` | Casos de prueba de funciones |
| `FDT_LEAN_TRACE`, `FDT_PROCESS_LOG` | Trazas y log de proceso |
| `FDT_CHECK_DB_CONSISTENCY`, `FDT_CHECK_CONSISTENCY_LOG` | Consistencia |
| `FDT_GEN_TOOL`, `FDT_GENERATE_MANY_FUNCTIONS` | Generación de código |
| `BRFPLUS_MANAGER` | Gestor de aplicaciones |
| `BRF`, `BRFAPL01`, `BRFRUL01`, … | ⚠️ **BRF clásico** (predecesor, otra tecnología): no confundir con BRF+ |

## Excel (tablas de decisión)

- Workbench: tabla de decisión → *Acciones adicionales* → **Exportar a Excel / Importar desde Excel**. El archivo trae hojas *Data*, *Help* (formatos) y *Column Details*. Exporta primero para obtener el formato exacto.
- ⚠️ La importación **reemplaza toda la tabla** (no hay delta) y no reordena filas.
- Por código: clase `CL_FDT_DT_EXCEL` ✅ (la comunidad la usa para exportar/importar y para respaldos antes de `set_table_data`).

## DSM — Decision Service Management

Add-on con **licencia aparte** sobre BRF+: modela en un servidor central y **despliega** funciones a sistemas gestionados (sin transporte, con fecha efectiva, "hot deployment"), con pruebas remotas, trazas importadas y aprobación por workflow. No soporta: conector BRMS, expresión dinámica, secuencia de pasos, transformación XSL. Si el cliente no lo tiene, nada de esto aplica.
