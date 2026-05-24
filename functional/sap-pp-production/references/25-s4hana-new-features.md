# Novedades S/4HANA 2023 — PP

## MRP Live (MD01N)

- Reemplaza MD01 clasico con procesamiento in-memory HANA
- Beneficios: velocidad (10-100x mas rapido), procesamiento paralelo
- Soporte completo para DDMRP
- Compatible con todas las funcionalidades MRP clasicas
- Fiori app F2873 para scheduling, F2874 para monitoreo

## Demand-Driven MRP (DDMRP)

### Concepto
DDMRP combina lo mejor de MRP clasico con Lean/TOC:
- Posicionamiento estrategico de buffers de inventario
- Calculo dinamico de niveles de buffer
- Demand-driven planning (pull, no push)
- Visible and collaborative execution

### Componentes DDMRP
1. **Strategic Inventory Positioning**: donde colocar buffers
2. **Buffer Profiles and Levels**: green/yellow/red zones
3. **Dynamic Adjustments**: ajustes por estacionalidad/tendencia
4. **Demand-Driven Planning**: net flow equation
5. **Visible and Collaborative Execution**: alertas por color

### Configuracion
- MARC-DISMM = 'D6' (DDMRP)
- Buffer profiles en customizing
- Zones: Green (order cycle), Yellow (lead time), Red (safety)

## Predictive MRP (pMRP)

- Machine learning para predecir necesidades
- Analiza patrones historicos de consumo
- Ajusta automaticamente parametros MRP
- Integrado con SAP Analytics Cloud

## Advanced Production Scheduling

- Scheduling con restricciones finitas nativo en S/4
- Reemplaza parcialmente APO PP/DS
- Integrado con Fiori (F1596 Schedule Production Orders)
- Considera: capacidad, materiales, secuencia operaciones

## Simplified Production Order

- Modelo simplificado de orden produccion
- Menos campos, interfaz Fiori-first
- Ideal para escenarios simples de produccion discreta
- API OData para integracion

## Embedded Analytics PP

### KPI Tiles (Fiori Launchpad)
- Production Order Completion Rate
- Scrap Rate by Material/Work Center
- MRP Exception Messages Count
- Capacity Utilization by Work Center
- On-Time Delivery from Production

### CDS Views analiticas
- I_ProductionOrderAnalysis
- I_ProductionOrderCostAnalysis
- I_ProductionScrapAnalysis
- I_CapacityUtilizationAnalysis

## SAP Digital Manufacturing (DM) Integration

- S/4HANA PP se integra con SAP Digital Manufacturing
- Shop floor execution en cloud
- IoT integration para senales de maquina
- Trazabilidad genealogia de produccion

## Custom Fields & Logic

### Key User Extensibility
- Agregar campos custom a ordenes de produccion sin ABAP
- Usar Custom Logic (BAdIs key user) para validaciones
- Disponible en Fiori apps de PP

### Campos custom soportados
- Production Order header
- Production Order operations
- BOM items
- Routing operations

## Manufacturing Execution Integration

- API OData para confirmar operaciones desde MES
- Events para sincronizacion bi-direccional
- Support para Industry 4.0 scenarios

## Production Planning Board

- Vista visual tipo Gantt para scheduling
- Drag & drop de operaciones
- Vista de capacidad integrada
- Fiori app F1596

## Intelligent Situation Handling

- Alertas inteligentes basadas en ML
- Deteccion automatica de situaciones anomalas
- Recomendaciones de accion
- Integrado con SAP Business AI

## Migration desde ECC

### Aspectos clave PP
| Area | Impacto migracion |
|------|-------------------|
| MRP | MD01 → MD01N (MRP Live) — opcional pero recomendado |
| MATDOC | MKPF/MSEG → MATDOC — automatico en migration |
| ACDOCA | COEP/COSS/COSP → ACDOCA — automatico |
| Ordenes | AFKO/AFPO/AFVC sin cambios |
| BOM/Routing | STKO/STPO/PLKO/PLPO sin cambios |
| Custom reports | Adaptar queries a MATDOC/ACDOCA |
| Fiori | Nuevas apps disponibles inmediatamente |

### Custom code adaptation
- Reemplazar SELECT de MKPF/MSEG por MATDOC
- Reemplazar SELECT de COEP/COSS/COSP por ACDOCA
- Verificar BAPIs deprecadas
- Custom Code Migration Worklist (SYCM)
