# Catalogo Fiori Apps PP — S/4HANA 2023

## Planificacion y MRP

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F0917 | Monitor Material Coverage | Analytical | MD04 | Vista stock/necesidades con graficos |
| F2873 | Schedule MRP Runs | Transactional | MD01N | Programar ejecuciones MRP |
| F2874 | Monitor MRP Runs | Analytical | — | Monitorear corridas MRP |
| F1613 | Manage Planned Independent Requirements | Transactional | MD61 | Crear/modificar PIR |
| F3059 | Material Requirements Overview | Analytical | MD07 | Resumen necesidades |
| F2875 | Display MRP Results | Analytical | MD05 | Resultados MRP por material |
| F4508 | Manage Supply and Demand | Transactional | MD04 | Vista integrada oferta/demanda |

## Ordenes de produccion

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F2093 | Manage Production Orders | Transactional | COOIS | Lista interactiva de ordenes |
| F2428 | Manage Production Orders (extended) | Transactional | CO01/CO02 | Crear/modificar/visualizar ordenes |
| F2429 | Release Production Orders | Transactional | CO05N | Liberacion masiva |
| F1596 | Schedule Production Orders | Transactional | — | Scheduling interactivo visual |
| F3523 | Manage Production Operations | Transactional | — | Gestion operaciones en planta |
| F3810 | Production Order Confirmation | Transactional | CO11N | Confirmacion en Fiori |

## Ordenes previsionales

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F1780 | Manage Planned Orders | Transactional | MD04/CO40 | Gestionar previsionales |
| F2876 | Convert Planned Orders | Transactional | CO41 | Conversion a ordenes produccion |

## Shop Floor / Ejecucion

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F2525 | Post Goods Issue for Production Order | Transactional | MIGO 261 | GI componentes |
| F2526 | Post Goods Receipt for Production Order | Transactional | MIGO 101 | GR producto |
| F3523 | Manage Production Operations | Transactional | — | Operaciones en piso |
| F4073 | Production Operator Dashboard | Analytical | — | Dashboard operador |
| F4074 | Work Center Load Monitor | Analytical | CM01 | Carga puestos trabajo |

## Ordenes proceso (PP-PI)

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F2767 | Process Manufacturing Orders | Transactional | COR2 | Gestionar ordenes proceso |
| F3524 | Manage Process Order Operations | Transactional | COR6N | Operaciones proceso |

## Capacidad

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F3814 | Monitor Capacity Load | Analytical | CM01/CM07 | Dashboard capacidad |
| F3815 | Evaluate Capacity Load | Analytical | CM21 | Evaluacion detallada |
| F4074 | Work Center Load Monitor | Analytical | — | Monitor en tiempo real |

## Datos maestros

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F1595 | Manage Bill of Materials | Transactional | CS02 | Crear/modificar BOM |
| F2766 | Manage Production Routing | Transactional | CA02 | Crear/modificar routing |
| F3058 | Manage Production Version | Transactional | C223 | Versiones fabricacion |
| F2096 | Manage Work Centers | Transactional | CR02 | Puestos de trabajo |
| F3060 | Display BOM Comparison | Analytical | CS14 | Comparar BOMs |
| F3061 | Display BOM Where-Used | Analytical | CS15 | Donde se usa componente |

## Analisis y KPIs

| App ID | Nombre | Tipo | Descripcion |
|--------|--------|------|-------------|
| F2094 | Production Order Analysis | Analytical | Costes real vs plan |
| F3057 | Production Order Cost Analysis | Analytical | Desglose costes |
| F4392 | Scrap Analysis for Production | Analytical | Merma/chatarra |
| F3056 | Production Plan vs Actual | Analytical | Cumplimiento plan |
| F4393 | Production Efficiency Analysis | Analytical | OEE, rendimiento |
| F4507 | Production Order Variance Analysis | Analytical | Desviaciones por categoria |

## Repetitive Manufacturing

| App ID | Nombre | Tipo | TCode equiv. | Descripcion |
|--------|--------|------|--------------|-------------|
| F2877 | Planning Table (REM) | Transactional | MF50 | Tabla planificacion |
| F2878 | Backflush (REM) | Transactional | MFBF | Backflush repetitivo |

## Quality en produccion

| App ID | Nombre | Tipo | Descripcion |
|--------|--------|------|-------------|
| F2095 | Manage Inspection Lots | Transactional | QA32 equiv. |
| F3525 | Record Inspection Results | Transactional | QE01 equiv. |

## Semantic Object navigation (Fiori Launchpad)

| Semantic Object | Action | App resultante |
|-----------------|--------|----------------|
| ProductionOrder | manage | F2093 |
| ProductionOrder | create | F2428 |
| PlannedOrder | manage | F1780 |
| BillOfMaterial | manage | F1595 |
| ProductionRouting | manage | F2766 |
| MaterialCoverage | monitor | F0917 |
