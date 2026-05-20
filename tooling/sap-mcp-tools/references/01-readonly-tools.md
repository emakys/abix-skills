# READ-ONLY Tools (61) — @mcp-abap-adt/core v6.8.0

Tools disponibles en modo REPO (`--exposition=readonly`). No modifican el sistema SAP.

## Lectura de Objetos

| Tool | Tipo | Descripcion |
|------|------|-------------|
| `ReadBehaviorDefinition` | BDEF | Lee source y metadata de Behavior Definition |
| `ReadBehaviorImplementation` | BDEF | Lee source de Behavior Implementation |
| `ReadClass` | CLAS | Lee source (definition, implementation, locals, macros, test) y metadata |
| `ReadDataElement` | DTEL | Lee definicion y metadata de Data Element |
| `ReadDomain` | DOMA | Lee definicion, fixed values y metadata |
| `ReadEnhancementImplementation` | ENHO | Lee implementacion de enhancement (BAdI) |
| `ReadEnhancementSpot` | ENHC | Lee enhancement spot definition |
| `ReadFunctionGroup` | FUGR | Lee function group metadata |
| `ReadFunctionModule` | FUNC | Lee source y metadata de Function Module |
| `ReadInclude` | PROG | Lee source de un include |
| `ReadInterface` | INTF | Lee source y metadata de Interface |
| `ReadMetadataExtension` | DDLX | Lee source y metadata de Metadata Extension |
| `ReadProgram` | PROG | Lee source y metadata de programa ABAP |
| `ReadServiceBinding` | SRVB | Lee metadata de Service Binding |
| `ReadServiceDefinition` | SRVD | Lee source y metadata de Service Definition |
| `ReadStructure` | STRU | Lee definicion de estructura |
| `ReadTable` | TABL | Lee definicion y campos de tabla |
| `ReadView` | DDLS | Lee DDL source y metadata de CDS View |

## Lectura Especifica de Clases

| Tool | Descripcion |
|------|-------------|
| `GetClassSource` | Source code principal de la clase |
| `GetLocalDefinitions` | locals_def — definiciones locales |
| `GetLocalTypes` | locals_imp — implementaciones locales |
| `GetLocalTestClass` | testclasses — clase de test local |
| `GetLocalMacros` | macros locales de la clase |

## Busqueda y Navegacion

| Tool | Descripcion |
|------|-------------|
| `SearchObject` | Buscar objetos por nombre, tipo, paquete. Soporta wildcards (*) |
| `SearchTransport` | Buscar transportes por patron |
| `WhereUsed` | Analisis de uso — donde se referencia un objeto |
| `GetPackageStructure` | Estructura y sub-paquetes de un DEVC |
| `GetPackageHierarchy` | Jerarquia de paquetes |
| `GetObjectDeletionAnalysis` | Analisis de impacto antes de eliminar |

## Analisis y Verificacion

| Tool | Descripcion |
|------|-------------|
| `GetAbapSemanticAnalysis` | Syntax check real en servidor SAP. Retorna errores con linea/columna |
| `CheckClass` | Verificacion de sintaxis de clase |
| `CheckProgram` | Verificacion de sintaxis de programa |
| `CheckView` | Verificacion de sintaxis de CDS View |
| `CheckBehaviorDefinition` | Verificacion de BDEF |
| `CheckFunctionModule` | Verificacion de Function Module |

## Runtime y Diagnostico

| Tool | Descripcion |
|------|-------------|
| `GetDumps` | Lista ultimos dumps ST22 del sistema |
| `ReadDump` | Lee detalle completo de un dump (raw text, stack trace) |
| `RuntimeRunProgramWithProfiling` | Ejecuta programa con profiler (SAT) |
| `RuntimeRunClassWithProfiling` | Ejecuta clase con profiler |
| `RuntimeListProfilerTraceFiles` | Lista trazas del profiler |
| `RuntimeAnalyzeProfilerTrace` | Analiza hotspots, tiempos, SQL de una traza |
| `RuntimeGetProgramCallStack` | Obtiene call stack de ejecucion |

## Transportes

| Tool | Descripcion |
|------|-------------|
| `GetTransportRequests` | Lista transportes del usuario (modifiable + released) |
| `SearchTransport` | Buscar transportes por patron de nombre |
| `GetTransportContent` | Objetos dentro de un transporte |

## Enhancement

| Tool | Descripcion |
|------|-------------|
| `GetEnhancementSpots` | Lista enhancement spots de un objeto |
| `ReadEnhancementImplementation` | Lee source de una implementacion |
| `ReadEnhancementSpot` | Lee definicion del spot |
