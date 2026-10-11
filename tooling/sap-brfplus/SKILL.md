---
name: sap-brfplus
description: Experto en BRF+ / BRFplus (Business Rule Framework plus, FDT) en SAP S/4HANA — jerarquía (aplicación, objetos de datos, función, set de reglas, reglas, expresiones), modos de función (funcional, evento, funcional+evento, analítico), tipos de expresión y acciones, binding DDIC, almacenamiento (sistema/customizing/datos maestros), versionado, transporte (FDT0), salidas de aplicación, autorizaciones, simulación y traza, rendimiento, API ABAP (CL_FDT_FACTORY, CL_FDT_FUNCTION_PROCESS, CL_FDT_DATA_EXCHANGE), lectura de reglas por SQL (FDT_ADMN_0000, FDT_EXPR_*), export/import XML, y su uso en S/4HANA (output management OPD, MDG, crédito, TM, GRC, revenue accounting, reportes legales, EWM Labor Management).
---

# SAP BRF+ (BRFplus) — Guía experta (ABIX)

Eres especialista en **BRF+** (BRFplus, prefijo técnico **FDT**): entiendes las reglas que ya existen en el sistema del cliente, las diagnosticas, las documentas y diseñas nuevas. Sabes leerlas por SQL en cualquier sistema (incluido productivo), y crearlas/modificarlas/ejecutarlas por API en un sistema de desarrollo.

> Todo lo marcado ✅ se verificó en vivo (S/4HANA 2023 FPS03 on-premise, oct-2026): creación por API, modificación por XML, modo evento, binding DDIC, simulación en memoria, lectura de reglas OPD reales por SQL. Lo demás sale de documentación SAP y de la comunidad: confírmalo en el sistema antes de afirmarlo.

## Regla cero: no inventes objetos

BRF+ es una caja negra para el código ABAP (la decisión vive en tablas de decisión, no en el programa) y por eso es fácil "rellenar" con nombres plausibles. **No existen** (verificado): clase `/BRF/FUNCTION`, FM `FDT_PROCESS_FUNCTION`, tablas `FDT_FUNCTION`/`FDT_RULE`, transacciones `FDT_EXPR`/`FDT_RULE`. Si necesitas un objeto que no está en esta skill, búscalo (`SearchObject`, `GetSqlQuery` sobre `FDT_ADMN_0000S`/`SEOCLASS`/`TSTC`) antes de nombrarlo.

## Jerarquía de un BRF+

| Pieza | Tipo (`OBJECT_TYPE`) | Qué es |
|---|---|---|
| **Aplicación** | `AP` | Contenedor. Fija **almacenamiento** (sistema/customizing/datos maestros), paquete, versionado, clase de salida |
| **Objeto de datos** | `DO` | Elemento (texto, número, booleano, importe, cantidad, punto en el tiempo), **estructura** o **tabla**. Puede ligarse al DDIC |
| **Función** | `FU` | Punto de entrada: **contexto** (objetos de entrada) + **resultado**. Se llama desde ABAP |
| **Set de reglas** | `RS` | Grupo ordenado de reglas, asignado a una función (modo evento). Tiene interruptor, prioridad y condición |
| **Regla** | `EX` (tipo regla) | *Si condición → acciones*; sí/no |
| **Expresión** | `EX` | Lógica: tabla de decisión, fórmula, árbol, búsqueda en BD, llamada a método/FM, … (`references/02`) |
| **Acción** | `EX` (tipo acción) | Efecto: log de mensajes, correo, workflow, evento, método |

## Modos de función (constantes `IF_FDT_FUNCTION`) ✅

| Modo | Valor | Cómo decide |
|---|---|---|
| **Funcional** | `1` `GC_MODE_FUNCTIONAL` | Una **expresión de nivel superior** (p. ej. tabla de decisión); su resultado es el de la función |
| **Evento** | `2` `GC_MODE_EVENT` | Sin expresión; dispara los **sets de reglas** asignados. Las reglas modifican el contexto/resultado **en orden** (una posterior pisa a una anterior). Es el modo de OPD |
| **Funcional + evento** | `3` | Primero la expresión, después los sets de reglas (excepciones sobre la decisión base) |
| **Analítico / BD** | `4` | Reglas sobre conjuntos de datos en la base (HANA); caso aparte |

## Qué puedes hacer, por sistema

| Necesidad | Cómo | Dónde funciona |
|---|---|---|
| **Entender/diagnosticar** reglas existentes | SQL de solo lectura sobre `FDT_ADMN_0000(S)` + `FDT_EXPR_*` → reconstruir tablas de decisión (`references/05`) | **Cualquier sistema, incluido productivo** ✅ |
| "¿Por qué este documento salió/no salió con X?" (OPD) | Contexto real del documento (vista de parámetros del objeto) + tablas reconstruidas + `APOC_D_OR_ITEM` (`references/07`) | Cualquiera ✅ |
| **Simular** reglas nuevas | Aplicación temporal `GC_APPLICATION_TMP`, activar **sin grabar** y ejecutar: cero escrituras (`references/04`) | Sistema donde se pueda correr una clase (DEV/QAS abierto) ✅ |
| **Ejecutar** una función real con datos | `CL_FDT_FUNCTION_PROCESS=>PROCESS` (`references/04`) | Ídem ✅ |
| **Crear** aplicación/función/reglas | API `CL_FDT_FACTORY` (`references/03`, `templates/`) | DEV ✅ |
| **Modificar** reglas existentes | Export XML → editar → `IMPORT_XML` (simular, luego real) (`references/05`) | DEV ✅ |

En **sistema cerrado o productivo** solo lees (SQL). Nunca propongas cambiar reglas en productivo salvo que la aplicación lo permita por diseño (almacenamiento datos maestros o salida `GET_CHANGEABILITY`, `references/06`).

## Reglas duras (las que más fallan)

1. **Reglas y sets de reglas nacen APAGADOS.** Sin `switch = gc_switch_on` en cada regla del set **y** `set_ruleset_switch( gc_switch_on )`, la función se ejecuta y devuelve **vacío sin error**. El `check` lo avisa ("Rule … is disabled"). ✅
2. **El set de reglas apunta a la función** (`set_function_restriction`), no al revés: activar la función "en profundidad" no arrastra sus sets. Activa y graba los dos. ✅
3. **`set_result_data_object` de una expresión** se llama con el prefijo de interfaz: `lo_dt->if_fdt_expression~set_result_data_object( … )` (la tabla de decisión no tiene alias). ✅
4. **Nombra los parámetros** en `get_data_object( iv_id = … | iv_data_object_type = … )` y `set_ddic_binding( iv_ddic_typename = … )`: tienen varios opcionales y sin nombre no compila. ✅
5. **Binding DDIC ≠ tipos DDIC.** Una estructura ligada a una tabla DDIC crea sus elementos sola, pero BRF+ **traduce los tipos** (fecha/hora → `ELEMENT_TIMEPOINT`, una estructura). `MOVE-CORRESPONDING` de la fila DDIC a la estructura BRF+ **dumpea sin poder capturarse**: copia solo componentes elementales. ✅
6. **Columna de tabla de decisión = ID del componente**, no de la estructura. ✅
7. **`save` hace COMMIT propio**: lo creado antes de un error queda grabado. Limpia explícitamente. ✅
8. **Celdas comodín**: en `set_table_data`, una celda sin condición simplemente no se inserta. Valores de condición como `REF` al tipo BRF+ (`if_fdt_types=>element_text`, `element_number`, …). ✅
9. **Orden de filas y de reglas importa**: la primera fila que coincide gana (salvo *multiple match*); la regla posterior pisa a la anterior. Pon la fila comodín al final. ✅
10. **Lectura por SQL: decodifica las celdas empaquetadas** (`FDT_EXPR_0247`/`0248`) y usa la versión máxima; si no, faltan casi todas las filas. ✅
11. **Contexto como lo ve BRF+:** obtén la referencia tipada con `cl_fdt_function_process=>get_data_object_reference` antes de llenarla; no adivines tipos. ✅
12. **Rendimiento:** prefiere elementos *número* a importe/cantidad, evita expresiones que fuercen interpretación, ordena filas por frecuencia (`references/04`).

## Referencias

- `references/01-arquitectura-y-objetos.md` — objetos, almacenamiento, versionado, tipos de elemento, binding DDIC
- `references/02-expresiones-y-acciones.md` — todos los tipos de expresión y acción, cuáles usa SAP, cómo crearlos (demos estándar)
- `references/03-api-crear-y-modificar.md` — código verificado: app, elementos, tabla de decisión, función funcional y evento, reglas, DDIC
- `references/04-ejecucion-simulacion-traza.md` — PROCESS, contexto, simulación en memoria, traza técnica y lean trace, rendimiento
- `references/05-lectura-sql-y-xml.md` — tablas FDT, reconstrucción de tablas de decisión, export/import XML
- `references/06-transporte-exits-autorizaciones.md` — FDT0, órdenes, clientes, salidas de aplicación, objetos de autorización, herramientas
- `references/07-brfplus-en-s4hana.md` — OPD (estructura real, diagnóstico), MDG, crédito, TM, GRC, RAR, reportes legales, EWM
- `references/08-diagnostico-y-buenas-practicas.md` — checklist de diagnóstico, diseño, nomenclatura, anti-patrones
- `templates/` — clases classrun verificadas (crear modo funcional, crear modo evento, simular en memoria, ejecutar con contexto DDIC)
