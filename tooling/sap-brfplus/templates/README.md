# Plantillas BRF+ (verificadas en vivo, S/4HANA 2023, oct-2026)

Clases `if_oo_adt_classrun` que se ejecutaron tal cual y dieron el resultado esperado. Cámbiales el nombre de clase y los IDs (`<ID_APLICACION_32>`) antes de usarlas.

| Archivo | Qué demuestra |
|---|---|
| `crear-app-modo-funcional.clas.abap` | Aplicación local + 3 elementos + tabla de decisión + función modo funcional; si ya existe, solo ejecuta casos |
| `crear-modo-evento-reglas.clas.abap` | Función modo evento + set de reglas + regla con asignación de expresión + regla con condición y asignación de valor; **enciende** reglas y set |
| `estructura-ddic-y-contexto-real.clas.abap` | Estructura ligada a `T001`, elemento ligado a `BLART`, columna sobre componente, ejecución con filas reales de `T001` copiando solo componentes elementales |
| `simular-en-memoria.clas.abap` | Aplicación temporal `GC_APPLICATION_TMP`, activar sin grabar, ejecutar con contexto del objeto función; verifica cero escrituras |

Todas son de **sistema de desarrollo**: crean objetos (salvo la de simulación). En un sistema cerrado/productivo, usa solo lectura SQL (`references/05`).
