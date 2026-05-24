# Novedades S/4HANA 2023 para PM

## Intelligent Asset Management (IAM)

### Componentes
- **Asset Central Foundation**: registro central de activos, modelo digital de planta
- **Predictive Maintenance**: modelos de prediccion de fallas basados en IoT/ML
- **Asset Intelligence Network**: red colaborativa fabricante-operador
- **Asset Strategy & Performance**: optimizacion de estrategias de mantenimiento

### Predictive Maintenance
- Conecta sensores IoT via SAP IoT → datos en tiempo real
- Modelos ML detectan patrones de degradacion
- Genera ordenes PM06 automaticamente cuando modelo predice falla
- Requiere SAP BTP + IoT Services

## Simplificaciones S/4HANA

### Tablas consolidadas
| ECC | S/4HANA | Impacto |
|-----|---------|---------|
| MKPF + MSEG | MATDOC | Mov materiales en tabla unica |
| COSP + COSS + COEP | ACDOCA | Costes PM en Universal Journal |
| BSEG + BSAS + BSIS | ACDOCA | Documentos contables |

### APIs RESTful
| API | Descripcion |
|-----|-------------|
| API_MAINTENANCEORDER_SRV | CRUD ordenes PM via OData |
| API_MAINTENANCENOTIFICATION | CRUD avisos via OData |
| API_EQUIPMENT_SRV | CRUD equipos via OData |
| API_FUNCLOCATION_SRV | CRUD ubicaciones tecnicas |
| API_MAINTENANCEPLAN_SRV | Gestion planes mantenimiento |

### Mejoras Fiori 2023
- Project Builder Web mejorado para PM
- Maintenance Planner con drag & drop
- Mobile apps offline mejoradas
- Equipment 360° view con timeline de mantenimiento

## Embedded Analytics

- CDS Analytical Queries predefinidas para PM
- KPIs en tiempo real: MTBF, MTTR, disponibilidad, costes
- Integracion SAP Analytics Cloud (SAC) con Live Connection
- Dashboards de mantenimiento en Fiori Launchpad

## Custom Fields & Logic

- Agregar campos custom a ordenes, avisos, equipos sin codigo
- Logica custom (validaciones, determinaciones) via Key User
- Campos custom automaticamente visibles en Fiori apps

## Novedades por Release

### S/4HANA 2020
- Maintenance Planner Fiori (F2375)
- Confirm Maintenance Order mobile (F3438)

### S/4HANA 2021
- Equipment Breakdown Analysis (F3303)
- Enhanced mobile maintenance apps
- Maintenance cost CDS views

### S/4HANA 2022
- Equipment Reliability Analysis (F3680)
- Predictive Maintenance integration
- Improved scheduling board

### S/4HANA 2023
- AI-assisted maintenance planning
- Enhanced IoT integration
- Maintenance Plan Overview (F3675)
- Improved Asset Central Foundation
