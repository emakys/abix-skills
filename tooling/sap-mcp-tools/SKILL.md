# SAP MCP Tools — Guia de Uso para @mcp-abap-adt/core v6.8.0

Eres un experto en las 196 herramientas MCP de `@mcp-abap-adt/core` para operar SAP S/4HANA via ADT (ABAP Development Tools). Conoces cada tool, sus parametros, y los workflows optimos para combinarlas.

## Modos de Operacion

| Modo | Exposition | Tools | Cuando |
|------|-----------|-------|--------|
| **REPO** | `readonly` | 61 | Leer, analizar, buscar. Sin modificar SAP |
| **SAP** | `readonly,high` | 196 | CRUD completo: crear, modificar, activar, deploy |

## Reglas Fundamentales

1. **Siempre buscar antes de crear**: `SearchObject` para verificar si ya existe
2. **Orden de activacion obligatorio**: DOMA → DTEL → TABL → DDLS(I_) → BDEF(I_) → CLAS → DDLS(C_) → BDEF(C_) → DDLX → SRVD → SRVB
3. **Lock antes de Update**: Los tools high-level hacen lock/unlock automatico
4. **Transport obligatorio**: Todo Update/Create en paquetes transportables necesita `transport_request`
5. **No pasar parametros desconocidos**: Los tools Create NO aceptan `language` — causa "save operation error"

## Workflows Clave

### Deploy de un objeto (Create + Activate)
```
1. SearchObject(query="ZCLASS", object_type="CLAS") → verificar que NO existe
2. CreateClass(class_name="ZCL_EXAMPLE", package="ZDEV", transport_request="S4DK900123")
3. UpdateClassSource(class_name="ZCL_EXAMPLE", source="...", transport_request="S4DK900123")
4. ActivateClass → lock/activate/unlock automatico (high-level)
```

### Deploy RAP completo (orden estricto)
```
1. CreateTable → tabla draft si aplica
2. CreateView → CDS Interface (I_*)
3. CreateBehaviorDefinition → BDEF interface
4. CreateClass → Behavior Pool (ZCL_BP_*)
5. CreateView → CDS Consumption (C_*)
6. CreateBehaviorDefinition → BDEF consumption (projection)
7. CreateMetadataExtension → DDLX con annotations UI
8. CreateServiceDefinition → SRVD
9. CreateServiceBinding → SRVB + PublishServiceBinding
```

### Syntax Check
```
GetAbapSemanticAnalysis(object_name="ZCL_EXAMPLE", object_type="CLAS")
→ Ejecuta syntax check REAL en el servidor SAP (no local)
→ Retorna errores con linea, columna, severidad
```

### Profiling (SAT/SE30 via API)
```
1. RuntimeRunProgramWithProfiling(program_name="ZR_REPORT", sql_trace=true, all_db_events=true)
   → Retorna profiler_id
2. RuntimeListProfilerTraceFiles → buscar la traza generada
3. RuntimeAnalyzeProfilerTrace → hotspots, tiempos, SQL
```

### Unit Testing
```
1. RunUnitTest(class_name="ZCL_EXAMPLE") → Retorna run_id
2. GetUnitTestStatus(run_id="...") → RUNNING | COMPLETED | FAILED
3. GetUnitTestResult(run_id="...") → pass/fail por metodo
```

### CDS Unit Testing
```
1. CreateCdsUnitTest(class_name="ZCL_CDS_TEST", ...) → Crea clase test CDS
2. RunUnitTest → ejecuta
3. GetCdsUnitTestResult → resultados
```

### Transports
```
- CreateTransport(description="...", target="QAS") → nuevo transport request
- GetTransportRequests(user="DEVELOPER") → lista transportes del usuario
- SearchTransport(query="S4DK9*") → buscar por patron
```

### Dumps (ST22)
```
- GetDumps(max_results=20) → ultimos dumps del sistema
- ReadDump(dump_id="...") → detalle completo con stack trace
```

## Tools por Tipo de Objeto

| Objeto | Read | Create | Update | Delete | Check | Activate |
|--------|------|--------|--------|--------|-------|----------|
| CLAS | ReadClass | CreateClass | UpdateClassSource | DeleteClass | CheckClass | ActivateClass |
| INTF | ReadInterface | CreateInterface | UpdateInterface | DeleteInterface | - | ActivateInterface |
| PROG | ReadProgram | CreateProgram | UpdateProgram | DeleteProgram | CheckProgram | ActivateProgram |
| DDLS | ReadView | CreateView | UpdateView | DeleteView | CheckView | ActivateView |
| BDEF | ReadBehaviorDefinition | CreateBehaviorDefinition | UpdateBehaviorDefinition | DeleteBehaviorDefinition | CheckBehaviorDefinition | ActivateBehaviorDefinition |
| DDLX | ReadMetadataExtension | CreateMetadataExtension | UpdateMetadataExtension | DeleteMetadataExtension | - | ActivateMetadataExtension |
| TABL | ReadTable | CreateTable | UpdateTable | DeleteTable | - | ActivateTable |
| DTEL | ReadDataElement | CreateDataElement | UpdateDataElement | DeleteDataElement | - | ActivateDataElement |
| DOMA | ReadDomain | CreateDomain | UpdateDomain | DeleteDomain | - | ActivateDomain |
| SRVD | ReadServiceDefinition | CreateServiceDefinition | UpdateServiceDefinition | DeleteServiceDefinition | - | ActivateServiceDefinition |
| SRVB | ReadServiceBinding | CreateServiceBinding | UpdateServiceBinding | DeleteServiceBinding | - | ActivateServiceBinding |
| FUGR | ReadFunctionGroup | CreateFunctionGroup | UpdateFunctionGroup | - | - | ActivateFunctionGroup |
| FUNC | ReadFunctionModule | CreateFunctionModule | UpdateFunctionModule | - | CheckFunctionModule | ActivateFunctionModule |
| STRUC | ReadStructure | CreateStructure | UpdateStructure | DeleteStructure | - | ActivateStructure |

## Tools Especiales (System/Runtime)

| Tool | Uso |
|------|-----|
| `SearchObject` | Buscar objetos por nombre/tipo/paquete |
| `WhereUsed` | Analisis de uso (donde se usa un objeto) |
| `GetAbapSemanticAnalysis` | Syntax check real en servidor |
| `GetObjectDeletionAnalysis` | Impacto de eliminar un objeto |
| `GetDumps` / `ReadDump` | Leer dumps ST22 |
| `GetTransportRequests` / `CreateTransport` | Gestion de transportes |
| `RuntimeRunProgramWithProfiling` | Ejecutar programa con profiler |
| `RuntimeRunClassWithProfiling` | Ejecutar clase con profiler |
| `RuntimeListProfilerTraceFiles` | Listar trazas del profiler |
| `RuntimeAnalyzeProfilerTrace` | Analizar hotspots/tiempos |
| `PublishServiceBinding` | Publicar servicio OData |
| `UnpublishServiceBinding` | Despublicar servicio OData |
| `GetEnhancementSpots` | Listar enhancement spots |
| `ReadEnhancementImplementation` | Leer implementacion de BAdI |
| `GetPackageStructure` | Estructura de paquete |

## Errores Comunes y Soluciones

| Error | Causa | Solucion |
|-------|-------|----------|
| "save operation" generico | Parametros invalidos, syntax error, locks | Verificar parametros, hacer CheckX antes de Update |
| "Object is locked" | Otro usuario/proceso tiene lock | Esperar o verificar con el usuario |
| "Transport request required" | Objeto en paquete transportable | Pasar `transport_request` en Create/Update |
| "Object already exists" | Intentando Create sobre existente | Usar Update en vez de Create |
| "Object does not exist" | Intentando Update sobre inexistente | Usar Create primero |
| "Activation failed" | Dependencias no activadas | Seguir orden de activacion estricto |
| DCLS no soportado | @mcp-abap-adt/core no tiene handlers DCLS | Omitir en deploy, crear manual en SAP |

## Parametros Comunes

- `class_name`, `program_name`, `view_name`, etc. → nombre del objeto (UPPERCASE)
- `source` → codigo fuente ABAP/CDS como string
- `package` → paquete SAP (ej: "ZDEV", "$TMP")
- `transport_request` → orden de transporte (ej: "S4DK900123")
- `description` → descripcion del objeto
- `version` → `'active'` o `'inactive'` (para lectura)
