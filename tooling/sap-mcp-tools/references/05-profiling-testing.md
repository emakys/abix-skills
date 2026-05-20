# Profiling y Unit Testing — MCP Tools

## Profiling (SAT/SE30 via MCP)

### Flujo completo de profiling

```
Paso 1: Ejecutar con profiler
  RuntimeRunProgramWithProfiling(
    program_name: "ZR_MATERIAL_REPORT",
    description: "Performance analysis",
    all_procedural_units: true,    → trazar PERFORM, CALL METHOD, etc.
    all_db_events: true,           → trazar SELECT, INSERT, UPDATE
    sql_trace: true,               → equivale a ST05
    all_internal_table_events: true → trazar APPEND, READ TABLE, SORT
  )
  → Retorna: { profiler_id: "ABC123", run_status: 200 }

Paso 2: Buscar la traza (esperar 2-3 segundos)
  RuntimeListProfilerTraceFiles
  → Lista todas las trazas disponibles, buscar la que coincide con profiler_id

Paso 3: Analizar
  RuntimeAnalyzeProfilerTrace(trace_id: "...")
  → Retorna: hotspots, tiempos por procedimiento, llamadas SQL, estadisticas
```

### Parametros de profiling

| Parametro | Default | Descripcion |
|-----------|---------|-------------|
| `program_name` | (requerido) | Nombre del programa a ejecutar |
| `description` | "" | Descripcion de la traza |
| `all_procedural_units` | false | PERFORM, CALL METHOD, CALL FUNCTION |
| `all_misc_abap_statements` | false | Statements ABAP generales |
| `all_internal_table_events` | false | APPEND, READ TABLE, SORT, DELETE |
| `all_db_events` | false | SELECT, INSERT, UPDATE, DELETE (DB) |
| `all_dynpro_events` | false | Eventos de dynpro/pantalla |
| `sql_trace` | false | SQL trace detallado (como ST05) |
| `amdp_trace` | false | Trazar AMDP / HANA procedures |
| `with_rfc_tracing` | false | Incluir llamadas RFC |
| `all_system_kernel_events` | false | Eventos del kernel SAP |
| `aggregate` | false | Agregar resultados (vs detalle completo) |
| `max_size_for_trace_file` | auto | Tamano maximo en bytes |
| `max_time_for_tracing` | auto | Tiempo maximo en segundos |

### Profiling de clases

```
RuntimeRunClassWithProfiling(
  class_name: "ZCL_EXAMPLE",
  method_name: "EXECUTE",
  all_procedural_units: true,
  all_db_events: true
)
```

### Recomendaciones de profiling
- Para analisis de SQL: usar `sql_trace: true` + `all_db_events: true`
- Para analisis de tablas internas: usar `all_internal_table_events: true`
- Para analisis general: usar `all_procedural_units: true` + `aggregate: true`
- `aggregate: true` reduce el tamano de la traza (recomendado para programas largos)

---

## Unit Testing (AUnit via MCP)

### Flujo de ABAP Unit Test

```
Paso 1: Iniciar test
  RunUnitTest(class_name: "ZCL_EXAMPLE")
  → Retorna: { run_id: "RUN123" }

Paso 2: Verificar status
  GetUnitTestStatus(run_id: "RUN123")
  → { status: "RUNNING" | "COMPLETED" | "FAILED" }

Paso 3: Obtener resultados
  GetUnitTestResult(run_id: "RUN123")
  → Desglose por metodo: pass/fail, mensajes de error, duracion

Alternativa: GetUnitTest obtiene status + resultado en una sola llamada
```

### Flujo de CDS Unit Test

```
Paso 1: Crear clase de test (si no existe)
  CreateCdsUnitTest(
    class_name: "ZCL_CDS_TEST_MATERIAL",
    cds_view: "ZI_MATERIAL",
    test_methods: ["test_basic_select", "test_filter"]
  )

Paso 2: Ejecutar
  RunUnitTest(class_name: "ZCL_CDS_TEST_MATERIAL")

Paso 3: Resultado
  GetCdsUnitTestResult(run_id: "...")
```

### Actualizar test existente

```
UpdateCdsUnitTest(
  class_name: "ZCL_CDS_TEST_MATERIAL",
  source: "CLASS ltcl_test DEFINITION FOR TESTING...\nENDCLASS.\nCLASS ltcl_test IMPLEMENTATION..."
)
→ Actualiza el source de la clase local de test
```

### Patrones comunes de test ABAP

```abap
" Test basico de creacion
METHOD test_create.
  " Given
  DATA ls_material TYPE zmat_d.
  ls_material-material_uuid = cl_system_uuid=>create_uuid_x16_static( ).
  ls_material-material_id = 'MAT001'.

  " When
  MODIFY ENTITIES OF zi_material IN LOCAL MODE
    ENTITY Material
      CREATE SET FIELDS WITH VALUE #( ( %cid = 'CID1' %data = ls_material ) )
    MAPPED DATA(mapped)
    FAILED DATA(failed)
    REPORTED DATA(reported).

  " Then
  cl_abap_unit_assert=>assert_initial( failed ).
  cl_abap_unit_assert=>assert_not_initial( mapped-material ).
ENDMETHOD.
```

### Limpieza de tests

```
DeleteUnitTest(run_id: "RUN123") → elimina run de la cola
DeleteCdsUnitTest(class_name: "ZCL_CDS_TEST_MATERIAL") → elimina clase test
```
