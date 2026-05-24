# Fiori Apps PM — S/4HANA 2023

## Apps Transaccionales

| App ID | Nombre | Rol | OData Service |
|--------|--------|-----|---------------|
| F1580 | Create Maintenance Notification | Tecnico/Operador | MAINTENANCENOTIFICATION |
| F1596 | Manage Maintenance Orders | Planificador | MAINTENANCEORDER |
| F2375 | Maintenance Planner | Planificador | MAINTENANCEORDER |
| F2626 | Manage Maintenance Notifications | Planificador | MAINTENANCENOTIFICATION |
| F2649 | Create Maintenance Order | Tecnico/Planif | MAINTENANCEORDER |
| F3150 | My Maintenance Notifications | Tecnico | MAINTENANCENOTIFICATION |
| F3151 | My Maintenance Orders | Tecnico | MAINTENANCEORDER |
| F3438 | Confirm Maintenance Order | Tecnico | ALM_CONFIRMATION |
| F3540 | Schedule Maintenance Plan | Planificador | MAINTENANCEPLAN |

## Apps Analiticas

| App ID | Nombre | Tipo | CDS View |
|--------|--------|------|----------|
| F3303 | Equipment Breakdown Analysis | Analytical | C_EquipBrkdwnAnlyss |
| F3304 | Monitor Maintenance Orders | Analytical | C_MaintOrdMonitor |
| F3430 | Maintenance Notification Overview | Analytical | C_MaintNotifOverview |
| F3545 | Maintenance Cost Analysis | Analytical | C_MaintOrderCostAnalysis |
| F3675 | Maintenance Plan Overview | Analytical | C_MaintPlanOverview |
| F3680 | Equipment Reliability Analysis | Analytical | C_EquipReliabilityAnlyss |

## Apps Factsheet

| App ID | Nombre | Objeto |
|--------|--------|--------|
| F2650 | Equipment | Equipo maestro |
| F2651 | Functional Location | Ubicacion tecnica |
| F2652 | Maintenance Order | Orden PM detalle |
| F2653 | Maintenance Notification | Aviso detalle |

## Apps de Aprobacion

| App ID | Nombre | Uso |
|--------|--------|-----|
| F3155 | Approve Maintenance Orders | Workflow aprobacion ordenes |

## Roles de Negocio

| Rol | Apps Principales |
|-----|-----------------|
| Maintenance Planner (SAP_BR_MAINTENANCE_PLANNER) | F1596, F2375, F2626, F3304 |
| Maintenance Technician (SAP_BR_MAINTENANCE_TECHNICIAN) | F3151, F3150, F3438, F1580 |
| Maintenance Manager (SAP_BR_MAINTENANCE_MANAGER) | F3304, F3303, F3545, F3680 |
| Plant Manager (SAP_BR_PLANT_MANAGER) | F3303, F3545, F3680 |

## Configuracion Fiori

1. **SAP Fiori Launchpad**: configurar tiles para cada rol
2. **OData Services**: activar en /IWFND/MAINT_SERVICE
3. **Business Catalogs**: asignar catalogos a roles
4. **Custom Fields**: campos custom visibles automaticamente en apps Fiori
