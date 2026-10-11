# 08 · Diagnóstico y buenas prácticas

## Checklist: "la regla no da lo que espero"

1. **¿Se ejecuta la función correcta?** ID desde el código ABAP que llama (`iv_function_id`) → `FDT_ADMN_0000(S)`.
2. **¿Reglas y sets encendidos?** (modo evento) Un set o regla apagado da resultado vacío **sin error**. `check` → "Rule … is disabled".
3. **¿El set de reglas apunta a esta función y está activo?**
4. **¿Qué valores entraron al contexto?** Traza técnica / simulación, o el contexto real del documento (`07`).
5. **¿Qué filas hay?** Reconstruye la tabla por SQL **incluyendo empaquetadas** (`05`); orden = prioridad.
6. **¿Comodín o allow-no-match?** Sin fila comodín ni *allow no match* → `CX_FDT` "No match found for the given context (DT_…)".
7. **¿Versión?** Con versionado, se ejecuta la vigente en el `iv_timestamp` (por defecto, ahora).
8. **¿Customizing distinto por mandante/sistema?** Reglas de customizing/datos maestros cambian entre DEV, QAS y PRD; compara.
9. **¿Interpretación en vez de código generado?** (lentitud) `GET_GENERATED_CLASS_NAME`; constructor de `CL_FDT_MAINTENANCE` en el depurador.

## Diseño

- **Función en app de customizing**, partes que el negocio cambia en cada sistema en app de **datos maestros**.
- **Preparar datos en ABAP** y pasarlos como contexto; reglas sin capa de acceso a BD compleja.
- **Una decisión por tabla**, columnas mínimas; fila **comodín al final**; lo frecuente arriba.
- Modo **evento** cuando el cliente debe poder **agregar** reglas sin tocar lo estándar (como OPD); **funcional** para decisiones simples.
- Elementos **ligados al DDIC** para heredar tipos, longitudes y valores fijos.
- **Número** antes que importe/cantidad, salvo que se necesite moneda/unidad.
- **Versionado** si hay auditoría (y lean trace).
- Pruebas: casos en `FDT_TEST_SUITE` o simulación; para cambios masivos, export/import XML con import **simulado** primero.

## Nomenclatura sugerida (cliente)

| Objeto | Patrón |
|---|---|
| Aplicación | `Z<MÓDULO>_<ÁREA>` (p. ej. `ZFI_APROBACIONES`) |
| Función | `FU_<DECISIÓN>` |
| Set de reglas | `RS_<DECISIÓN>` |
| Regla | `RU_<QUÉ_HACE>` |
| Tabla de decisión | `DT_<DECISIÓN>` |
| Objetos de datos | nombre del campo DDIC cuando estén ligados |

(Es el mismo patrón que SAP usa en OPD: `FU_` / `RS_` / `RU_PROCESS_DT_` / `DT_`.)

## Anti-patrones

- Reglas que hacen SELECT complejos o FOR ALL ENTRIES (no soportado en DB lookup).
- Tablas de decisión con miles de filas mantenidas en el workbench (usa Excel, divide, o datos maestros).
- Importar Excel sobre una tabla con filas mantenidas en destino (reemplaza todo).
- Modificar apps de **sistema** entregadas por SAP: copia la plantilla.
- Asumir que un objeto existe sin buscarlo (ver "Regla cero" del SKILL).
- `MOVE-CORRESPONDING` de una fila DDIC a una estructura BRF+ (dump por `ELEMENT_TIMEPOINT`).
