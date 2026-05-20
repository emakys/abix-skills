# S/4HANA 2023 — Deployment y Operations MM

## Feature Toggle Framework

### Concepto
S/4HANA 2023 permite activar/desactivar funcionalidades individuales sin upgrade.
Cada feature tiene un "Business Function" o "Feature Toggle" que se activa selectivamente.

```
Transaccion: SFW5 (Switch Framework)
Fiori App: "Configure Software Packages" (solo Cloud)

Categorias:
  - Business Functions (enterprise-level, irreversible)
  - Feature Toggles (granular, reversible en algunos casos)
  - Scope Items (S/4 Cloud, activables por tenant)
```

### Feature Toggles relevantes para MM (2023)
```
MM_PUR_CI_1 → Central Invoice (verificacion facturas central)
MM_PUR_CP_1 → Central Procurement
MM_PUR_FW_1 → Flexible Workflow for PO
MM_PUR_IS_1 → Intelligent Sourcing
MM_PUR_SN_1 → Business Network Integration
MM_IM_ML_1  → Material Ledger Actual Costing
MM_IM_EW_1  → Embedded EWM
MM_IM_PI_1  → Physical Inventory Fiori
LOG_MM_SIT  → Situation Handling for MM

Verificar features activados:
  SFW5 → ver lista de Business Functions activas
  O via MCP:
  GetSqlQuery("SELECT SWITCHID, SWITCHSTATE FROM SFW_SWITCH WHERE SWITCHID LIKE 'MM%'")
```

## Transport Management en S/4HANA

### Tipos de transporte
| Tipo | Contenido | Cuando |
|------|-----------|--------|
| Workbench (SXPG_COMMAND_CHECK) | Objetos de desarrollo (ABAP, CDS, DDIC) | Desarrollo custom |
| Customizing (SXPG_COMMAND_CHECK) | Configuracion IMG | Implementacion funcional |
| Default Transport Layer | Config de tabla | Cambios de config en PRD |

### CTS (Change and Transport System)
```
Landscape tipico S/4HANA:
  DEV (desarrollo) → QAS (calidad) → PRD (productivo)

Transacciones:
  SE09/SE10 → Workbench/Customizing requests
  STMS → Transport Management System
  SCC1 → Client copy (transport within system)

Regla de oro S/4:
  - NUNCA hacer cambios directos en PRD
  - TODO va por transporte (config + desarrollo)
  - Customizing requests: agrupar por proceso/sprint
  - Workbench requests: una por desarrollo/feature
```

### ChaRM (Change Request Management)
```
S/4HANA con Solution Manager o Cloud ALM:
  - Change Requests formales
  - Approval workflow para transporte a PRD
  - Impact analysis automatico
  - Regression test integration

Cloud ALM (recomendado S/4 2023):
  App: "Manage Features" → deploy controlled features
  App: "Transport Management" → aprobacion de transportes
```

## Simplification Item Check

### Concepto
Antes de upgrade ECC → S/4HANA, SAP proporciona una lista de "Simplification Items"
que documentan cada cambio en el modelo de datos y funcionalidad.

```
Transaccion: SYCM (Custom Code Migration)
  - Analiza TODOS los objetos Z del sistema
  - Detecta uso de tablas eliminadas/cambiadas
  - Genera worklist con prioridad

Output:
  - Lista de objetos Z que necesitan adaptacion
  - Para cada uno: tabla/FM afectado → alternativa S/4
  - Esfuerzo estimado (simple/medium/complex)
```

### Simplification Items MM principales
| Item | Cambio | Impacto |
|------|--------|---------|
| INVENTORY_MANAGEMENT_S4 | MKPF+MSEG → MATDOC | Todos los reports Z de movimientos |
| FI_NEW_GL | BSEG partial → ACDOCA | Reports Z financieros con MM |
| BP_VENDOR_CUSTOMER | LFA1 creation → BUT000 | Programas Z de creacion vendor |
| MATERIAL_LEDGER | ML obligatorio | Valoracion, cierre periodo |
| LIS_STATISTICS | S000-S999 eliminadas | Reports Z sobre LIS |
| BATCH_MGMT | MCHB cambios | Programas Z con lotes |

### Queries MCP para verificar readiness
```sql
-- Objetos Z que usan tablas afectadas
-- (verificar via SYCM o manualmente)
GetSqlQuery("SELECT OBJ_NAME, OBJ_TYPE FROM TADIR WHERE OBJ_NAME LIKE 'Z%' AND DEVCLASS LIKE 'Z%'")

-- Buscar uso de tablas legacy en codigo Z
SearchObject("MKPF")      -- deberia ser MATDOC
SearchObject("BSIK")      -- deberia ser ACDOCA
SearchObject("BSAK")      -- deberia ser ACDOCA
SearchObject("S010")       -- tabla LIS eliminada
```

## Upgrade Strategy S/4HANA

### Tipos de upgrade
```
1. Brownfield (conversion in-place)
   ECC existente → S/4HANA en el mismo sistema
   - Mantiene datos y config
   - Requiere adaptacion custom code
   - Herramienta: SUM (Software Update Manager)

2. Greenfield (nueva implementacion)
   S/4HANA nuevo → migrar datos desde ECC
   - Implementacion limpia, best practices
   - Migracion de datos con LTMC
   - Sin legacy custom code

3. Selective Data Transition (shell conversion)
   Sistema S/4 nuevo → migrar datos selectivos de ECC
   - Combina ventajas de brownfield y greenfield
   - Herramienta: SLT (SAP Landscape Transformation)

Para MM:
  Brownfield → adaptar reports Z, BAdIs, interfaces a S/4
  Greenfield → re-implementar MM con best practices S/4
  Selective → migrar datos maestros y saldos, reimplementar procesos
```

### Checklist pre-upgrade MM
```
1. [ ] Ejecutar SYCM → obtener custom code worklist
2. [ ] Clasificar objetos Z: adaptar / eliminar / reescribir
3. [ ] Verificar BAdIs: legacy → S4 equivalentes
4. [ ] Verificar interfaces: IDocs, RFCs, archivos → APIs OData
5. [ ] Verificar reports: LIS → Embedded Analytics
6. [ ] Verificar formularios: SAPscript → SmartForms/Adobe
7. [ ] Plan de pruebas: proceso P2P end-to-end
8. [ ] Plan de migracion datos: materiales, vendors, stock, POs abiertas
9. [ ] Plan de cutover: secuencia y timing
10.[ ] Training plan: Fiori para usuarios MM
```

## Monitoring y Operations

### Transacciones de monitoreo MM
| TCode | Funcion | Frecuencia |
|-------|---------|-----------|
| SM21 | System log | Diario |
| ST22 | Dumps ABAP | Diario |
| SM37 | Background jobs | Diario |
| SM12 | Lock entries | Si hay problemas |
| AL11 | Directorios servidor | Si hay interfaces |
| SLG1 | Application log | Para diagnostico |
| STMS | Transport status | Post-deploy |
| SM50 | Work processes | Performance |

### Jobs batch criticos MM
| Job | Programa | Frecuencia | Funcion |
|-----|----------|-----------|---------|
| MRP Run | RMMRP000 (MD01) | Diario (nocturno) | Planificacion necesidades |
| GR/IR Clearing | RM07MSAL (MR11) | Mensual | Compensar cuenta GR/IR |
| Reclasificacion stock | RM07RECLASSIFY | Mensual | Mover stock obsoleto |
| Liquidacion consignacion | RMMR1MKO (MRKO) | Mensual | Facturar consignacion |
| ERS | RMMR1MRL (MRRL) | Diario/semanal | Facturacion automatica |
| Recalculo precio medio | RM_PRICE_RECALCULATION | Mensual | Ajustar precios V |
| Archivado doc material | RM_MATDOC_ARCHIVE | Anual | Archivar docs antiguos |

### Queries MCP para monitoreo
```sql
-- Dumps recientes relacionados con MM
RuntimeListFeeds()
RuntimeGetDumpById("{dump_id}")

-- Objetos inactivos MM
GetInactiveObjects()

-- Ordenes de transporte abiertas para MM
SELECT TRKORR, AS4TEXT, AS4USER, AS4DATE FROM E070
WHERE AS4TEXT LIKE '%MM%' AND TRSTATUS IN ('D','L')
ORDER BY AS4DATE DESC

-- Locks activos en objetos MM
-- (via SM12 o MCP si disponible)
GetSqlQuery("SELECT * FROM ENQUEUE WHERE GARG LIKE '%EKKO%' OR GARG LIKE '%MARA%'")
```

## Fiori Admin para MM

### Apps de administracion
| App | Funcion |
|-----|---------|
| Manage Launchpad Settings | Configurar tiles y groups para roles MM |
| App Finder | Buscar y asignar apps a usuarios |
| Transport Organizer | Gestionar transportes desde Fiori |
| Application Log | Ver logs de aplicacion |
| Monitor Background Jobs | Monitorear jobs batch |

### Health check MM
```
Verificacion periodica del sistema MM:

1. MRP corriendo? → SM37 buscar RMMRP000
2. Interfaces activas? → SM58 (tRFC) + BD87 (IDocs)
3. Stock negativo? → SELECT MATNR,WERKS,LGORT,LABST FROM MARD WHERE LABST < 0
4. GR/IR saldo? → MR11SHOW o query EKBE
5. Facturas bloqueadas? → MRBR o query RBKP WHERE ZLSPR <> ''
6. Objetos inactivos? → GetInactiveObjects()
7. Transportes pendientes? → STMS
8. Dumps recientes? → ST22 o RuntimeListFeeds()
```
