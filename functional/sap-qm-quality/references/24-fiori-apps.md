# Apps Fiori QM — S/4HANA 2023

## Inspection Lot Processing

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F0711 | Manage Inspection Lots | Lista y procesamiento lotes |
| F2681 | Record Results (Fiori) | Registro resultados |
| F2682 | Make Usage Decision | Decision de empleo |
| F0712 | Monitor Inspection Lots | Monitor operativo |
| F3456 | Inspection Lot Overview | Vista general lote |

### Manage Inspection Lots (F0711)
```
Funcionalidad:
- Lista lotes con filtros (material, centro, tipo, status)
- Drill-down a detalle
- Acciones: registrar resultados, UD
- Variantes guardadas
- Export Excel
Rol: SAP_BR_QUALITY_ENGINEER
```

### Record Results (F2681)
```
Funcionalidad:
- Registro resultados por lote
- MICs cuantitativas y cualitativas
- Valoracion automatica
- Confirmacion de resultados
- Adjuntar documentos
Rol: SAP_BR_QUALITY_ENGINEER
```

### Make Usage Decision (F2682)
```
Funcionalidad:
- Seleccionar codigo UD
- Stock posting automatico
- Follow-up actions
- Crear aviso desde UD
Rol: SAP_BR_QUALITY_ENGINEER
```

## Quality Notifications

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F0713 | Manage Quality Notifications | Lista y procesamiento avisos |
| F2683 | Create Quality Notification | Crear aviso |
| F0714 | Monitor Quality Notifications | Monitor avisos |
| F3457 | Quality Notification Overview | Vista general aviso |
| F3892 | My Quality Notifications | Mis avisos asignados |

### Manage Quality Notifications (F0713)
```
Funcionalidad:
- Lista avisos con filtros multiples
- Crear/editar avisos
- Gestionar items, causas, tareas
- Workflow integrado
- Adjuntos y notas
Rol: SAP_BR_QUALITY_ENGINEER
```

### Create Quality Notification (F2683)
```
Funcionalidad:
- Crear Q1, Q2, Q3
- Asignar material, proveedor/cliente
- Items defecto con catalogo
- Causas con catalogo
- Tareas con responsable y fecha
Rol: SAP_BR_QUALITY_ENGINEER
```

## Inspection Planning

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F2684 | Manage Inspection Plans | Planes de inspeccion |
| F3458 | Display Inspection Plan | Visualizar plan |
| F4521 | Manage Master Inspection Chars | MICs |

### Manage Inspection Plans (F2684)
```
Funcionalidad:
- Crear/modificar planes
- Operaciones con MICs
- Sampling procedures
- Material assignment
- Versionado
Rol: SAP_BR_QUALITY_PLANNER
```

## Quality Certificates

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F3459 | Manage Quality Certificates | Certificados |
| F3460 | Create Quality Certificate | Crear certificado |
| F4522 | Record Inbound Certificate | Cert. entrante |

## Analytics & Monitoring

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F0715 | Quality Overview | Dashboard calidad |
| F3461 | Inspection Lot KPIs | KPIs lotes |
| F3462 | Quality Notification KPIs | KPIs avisos |
| F4523 | Vendor Quality Analysis | Analisis proveedor |
| F4524 | Defect Analysis | Analisis defectos |
| F4525 | SPC Dashboard | Control estadistico |

### Quality Overview (F0715)
```
Dashboard con:
- Lotes abiertos por tipo
- Tasa rechazo tendencia
- Avisos abiertos por tipo
- Top defectos (Pareto)
- KPIs: FPY, rejection rate, cycle time
Rol: SAP_BR_QUALITY_MANAGER
```

### Vendor Quality Analysis (F4523)
```
- Quality score por proveedor
- Tendencia 12 meses
- Comparacion proveedores
- Drill-down a lotes/avisos
- Export PDF/Excel
```

## Roles Fiori QM

| Rol Business | Descripcion | Apps principales |
|--------------|-------------|-----------------|
| SAP_BR_QUALITY_ENGINEER | Ingeniero calidad | Manage lots, results, UD, notifications |
| SAP_BR_QUALITY_PLANNER | Planificador calidad | Inspection plans, MICs, sampling |
| SAP_BR_QUALITY_MANAGER | Gerente calidad | Overview, KPIs, analytics |
| SAP_BR_QUALITY_TECHNICIAN | Tecnico calidad | Record results, physical samples |

## Catalogs & Groups Fiori

| Catalogo | Nombre | Roles |
|----------|--------|-------|
| SAP_TC_QM_INS | Inspection Processing | Engineer, Technician |
| SAP_TC_QM_PLN | Inspection Planning | Planner |
| SAP_TC_QM_NOT | Quality Notifications | Engineer, Manager |
| SAP_TC_QM_CRT | Quality Certificates | Engineer |
| SAP_TC_QM_ANL | Quality Analytics | Manager |

## Launchpad Configuration

```
Tiles recomendados en Fiori Launchpad:

Grupo: Quality Operations
- Manage Inspection Lots (F0711)
- Record Results (F2681)
- Make Usage Decision (F2682)
- Manage Quality Notifications (F0713)

Grupo: Quality Planning
- Manage Inspection Plans (F2684)
- Manage Master Inspection Chars (F4521)

Grupo: Quality Analytics
- Quality Overview (F0715)
- Vendor Quality Analysis (F4523)
- Defect Analysis (F4524)
```

## Migracion GUI → Fiori

| TCode GUI | App Fiori | Equivalencia |
|-----------|-----------|-------------|
| QA33 | F0711 | Manage Inspection Lots |
| QE51N | F2681 | Record Results |
| QA11 | F2682 | Make Usage Decision |
| QM01/02/03 | F0713 | Manage Quality Notifications |
| QP01/02/03 | F2684 | Manage Inspection Plans |
| QS21/22/23 | F4521 | Manage MICs |
| QC31/32/33 | F3459 | Manage Certificates |
