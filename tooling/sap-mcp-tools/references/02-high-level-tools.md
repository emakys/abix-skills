# HIGH-LEVEL Tools (135) — @mcp-abap-adt/core v6.8.0

Tools de escritura disponibles en modo SAP (`--exposition=readonly,high`). Lock/unlock/activate automatico.

## Behavior Definition (BDEF)

| Tool | Descripcion |
|------|-------------|
| `CreateBehaviorDefinition` | Crea nuevo BDEF. Params: `bdef_name`, `package`, `transport_request`, `source` |
| `UpdateBehaviorDefinition` | Actualiza source de BDEF. Params: `bdef_name`, `source`, `transport_request` |
| `DeleteBehaviorDefinition` | Elimina BDEF |
| `ActivateBehaviorDefinition` | Activa BDEF (lock/activate/unlock automatico) |
| `CheckBehaviorDefinition` | Syntax check de BDEF |

## Behavior Implementation

| Tool | Descripcion |
|------|-------------|
| `CreateBehaviorImplementation` | Crea behavior pool |
| `UpdateBehaviorImplementation` | Actualiza source del pool |
| `DeleteBehaviorImplementation` | Elimina pool |
| `ActivateBehaviorImplementation` | Activa pool |

## Class (CLAS) — 21 tools

| Tool | Descripcion |
|------|-------------|
| `CreateClass` | Crea clase ABAP. Params: `class_name`, `package`, `transport_request`, `description` |
| `UpdateClassSource` | Actualiza source principal. Params: `class_name`, `source`, `transport_request` |
| `UpdateClassDefinition` | Actualiza solo la definicion (PUBLIC SECTION, etc.) |
| `UpdateClassImplementation` | Actualiza solo la implementacion |
| `UpdateLocalDefinitions` | Actualiza locals_def |
| `UpdateLocalTypes` | Actualiza locals_imp |
| `UpdateLocalTestClasses` | Actualiza testclasses |
| `UpdateLocalMacros` | Actualiza macros |
| `DeleteClass` | Elimina clase y todos sus includes |
| `ActivateClass` | Activa clase (lock/activate/unlock) |
| `CheckClass` | Syntax check de clase |
| `CreateClassTestClasses` | Crea include de test |
| `ActivateClassTestClasses` | Activa include de test |

## Data Element (DTEL)

| Tool | Descripcion |
|------|-------------|
| `CreateDataElement` | Crea DTEL. Params: `data_element_name`, `package`, `transport_request` |
| `UpdateDataElement` | Actualiza definicion |
| `DeleteDataElement` | Elimina DTEL |
| `ActivateDataElement` | Activa |
| `CheckDataElement` | Verifica |

## Domain (DOMA)

| Tool | Descripcion |
|------|-------------|
| `CreateDomain` | Crea dominio. Params: `domain_name`, `package`, `transport_request` |
| `UpdateDomain` | Actualiza definicion y fixed values |
| `DeleteDomain` | Elimina |
| `ActivateDomain` | Activa |
| `CheckDomain` | Verifica |

## CDS View (DDLS)

| Tool | Descripcion |
|------|-------------|
| `CreateView` | Crea CDS View. Params: `view_name`, `package`, `transport_request`, `source` |
| `UpdateView` | Actualiza DDL source |
| `DeleteView` | Elimina view |
| `ActivateView` | Activa |
| `CheckView` | Syntax check CDS |
| `GetView` | Obtiene definicion actual |

## Metadata Extension (DDLX)

| Tool | Descripcion |
|------|-------------|
| `CreateMetadataExtension` | Crea DDLX. Params: `extension_name`, `package`, `transport_request`, `source` |
| `UpdateMetadataExtension` | Actualiza annotations |
| `DeleteMetadataExtension` | Elimina |
| `ActivateMetadataExtension` | Activa |

## Table (TABL)

| Tool | Descripcion |
|------|-------------|
| `CreateTable` | Crea tabla. Params: `table_name`, `package`, `transport_request` |
| `UpdateTable` | Actualiza campos/estructura |
| `DeleteTable` | Elimina |
| `ActivateTable` | Activa |
| `CheckTable` | Verifica |

## Structure (STRU)

| Tool | Descripcion |
|------|-------------|
| `CreateStructure` | Crea estructura |
| `UpdateStructure` | Actualiza campos |
| `DeleteStructure` | Elimina |
| `ActivateStructure` | Activa |
| `CheckStructure` | Verifica |

## Interface (INTF)

| Tool | Descripcion |
|------|-------------|
| `CreateInterface` | Crea interface ABAP |
| `UpdateInterface` | Actualiza source |
| `DeleteInterface` | Elimina |
| `ActivateInterface` | Activa |
| `CheckInterface` | Verifica |

## Program (PROG)

| Tool | Descripcion |
|------|-------------|
| `CreateProgram` | Crea programa/report. Params: `program_name`, `package`, `transport_request` |
| `UpdateProgram` | Actualiza source |
| `DeleteProgram` | Elimina |
| `ActivateProgram` | Activa |
| `CheckProgram` | Syntax check |

## Service Definition (SRVD)

| Tool | Descripcion |
|------|-------------|
| `CreateServiceDefinition` | Crea SRVD |
| `UpdateServiceDefinition` | Actualiza source |
| `DeleteServiceDefinition` | Elimina |
| `ActivateServiceDefinition` | Activa |

## Service Binding (SRVB)

| Tool | Descripcion |
|------|-------------|
| `CreateServiceBinding` | Crea SRVB |
| `UpdateServiceBinding` | Actualiza definicion |
| `DeleteServiceBinding` | Elimina |
| `ActivateServiceBinding` | Activa |
| `PublishServiceBinding` | Publica servicio OData (lo hace accesible) |
| `UnpublishServiceBinding` | Despublica servicio |
| `GetServiceBindingStatus` | Estado de publicacion |

## Function Group (FUGR)

| Tool | Descripcion |
|------|-------------|
| `CreateFunctionGroup` | Crea function group |
| `ActivateFunctionGroup` | Activa |

## Function Module (FUNC)

| Tool | Descripcion |
|------|-------------|
| `CreateFunctionModule` | Crea function module dentro de un FUGR |
| `UpdateFunctionModule` | Actualiza source |
| `ActivateFunctionModule` | Activa |
| `CheckFunctionModule` | Syntax check |

## Package (DEVC)

| Tool | Descripcion |
|------|-------------|
| `CreatePackage` | Crea paquete de desarrollo |
| `UpdatePackage` | Actualiza propiedades |
| `DeletePackage` | Elimina paquete |

## Transport

| Tool | Descripcion |
|------|-------------|
| `CreateTransport` | Crea nuevo transport request |

## Unit Test (AUnit) — 13 tools

| Tool | Descripcion |
|------|-------------|
| `RunUnitTest` | Inicia ejecucion de ABAP Unit tests |
| `CreateUnitTest` | Crea run de test |
| `GetUnitTest` | Status + resultado de un run |
| `GetUnitTestStatus` | Solo status (RUNNING/COMPLETED/FAILED) |
| `GetUnitTestResult` | Solo resultados (pass/fail por metodo) |
| `UpdateUnitTest` | Actualiza run |
| `DeleteUnitTest` | Elimina run |
| `CreateCdsUnitTest` | Crea clase de test CDS |
| `GetCdsUnitTest` | Status + resultado CDS test |
| `GetCdsUnitTestStatus` | Solo status |
| `GetCdsUnitTestResult` | Solo resultados |
| `UpdateCdsUnitTest` | Actualiza source de test CDS |
| `DeleteCdsUnitTest` | Elimina clase test CDS |

## Common

| Tool | Descripcion |
|------|-------------|
| `ActivateObjects` | Activa multiples objetos en una sola llamada |

## Compact (High-Level Aliases) — 25 tools

Tools compactas que combinan operaciones frecuentes en una sola llamada:
- `HandlerCreate` — Crear objeto generico
- `HandlerRead` — Leer objeto generico
- `HandlerUpdate` — Actualizar objeto generico
- `HandlerDelete` — Eliminar objeto generico
- `HandlerActivate` — Activar objeto generico
- `HandlerCheck` — Verificar objeto generico
- `HandlerProfileRun` — Ejecutar con profiler
- `HandlerUnitTest` — Ejecutar unit test
- Y variantes por tipo de objeto
