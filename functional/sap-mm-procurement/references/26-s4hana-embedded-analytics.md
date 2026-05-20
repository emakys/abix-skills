# S/4HANA 2023 — Embedded Analytics MM

## Concepto

En S/4HANA, los reports clasicos LIS/SIS (MC$0, MCBA, MCBC, etc.) son reemplazados
por **Embedded Analytics** basado en CDS Views + Fiori apps analiticas.

```
ECC (legacy):                    S/4HANA 2023:
LIS/SIS tables (S000-S999)  →   CDS Analytical Views
MC reports (MCBA, MCBC)      →   Fiori Analytical Apps
BW extractors              →   CDS extraction views
Custom ABAP reports        →   CDS + Fiori or SAC
```

## Arquitectura Embedded Analytics

```
ACDOCA / MATDOC / EKKO+EKPO (tablas reales)
    |
    +-- CDS Views (I_*) → Interface views (datos base)
    |
    +-- CDS Views (C_*) → Consumption views (analiticas)
    |   |
    |   +-- Annotations: @Analytics, @ObjectModel, @Consumption
    |   +-- Measures + Dimensions definidos en CDS
    |   |
    |   +-- Fiori Analytical Apps (F####)
    |   |   → Smart Chart, Smart Table, KPI Tiles
    |   |
    |   +-- SAP Analytics Cloud (SAC)
    |       → Live connection a CDS views
    |
    +-- CDS Views (A_*) → API views (para extraccion BW/SAC)
```

## NSDM CDS Views — Infraestructura de Stock

```
Las tablas de stock (MARD, MCHB) ya NO almacenan valores directamente.
Stock se calcula on-the-fly via estas CDS views internas:

  NSDM_V_MARD      → Stock por almacen (reemplaza SELECT de MARD-LABST)
  NSDM_V_MCHB      → Stock por lote
  NSDM_V_MARC_DIFF → Campos agregados de MARC
  V_MARC_MD         → Solo master data de MARC

Para custom reports de stock: usar estas views, NO las tablas directamente.
Referencia: SAP Note 2206980
```

## CDS Views analiticas clave — MM

### Compras
| CDS View | Descripcion | Reemplaza |
|----------|-------------|-----------|
| C_PurchasingDocumentItemQuery | Analisis items PO | ME80FN |
| C_PurchaseOrderItemQuery | Items PO con metricas | ME2M/ME2L |
| C_PurchaseRequisitionItemQry | Items PR con metricas | ME5A |
| C_PurContractItemQuery | Items contrato | ME3M |
| C_PurchaseOrderScheduleLine | Schedule lines | ME38 |
| C_OperationalPurchasing | Purchasing operativo | — |
| C_SupplierEvaluationQuery | Evaluacion proveedores | ME61 |
| C_SpendAnalysisQuery | Analisis de gasto | — |

### Inventario
| CDS View | Descripcion | Reemplaza |
|----------|-------------|-----------|
| C_MaterialStockQuery | Stock por material | MB52 |
| C_MaterialStockTimeSeries | Evolucion stock | MCBC |
| C_MaterialConsumptionQuery | Consumo materiales | MCBA |
| C_InventoryTurnoverQuery | Rotacion inventario | MCBE |
| C_SlowMovingItemsQuery | Materiales lento movimiento | — |
| C_StockInTransitQuery | Stock en transito | MB5T |
| C_WarehouseStockQuery | Stock por almacen | MB52 |

### Verificacion facturas
| CDS View | Descripcion | Reemplaza |
|----------|-------------|-----------|
| C_SupplierInvoiceItemQuery | Items factura proveedor | MIR5 |
| C_BlockedInvoiceQuery | Facturas bloqueadas | MRBR |
| C_GRIRAccountClearingQuery | Saldo GR/IR | MR11SHOW |

### Queries MCP para explorar CDS analiticas
```
-- Buscar CDS views analiticas de compras
SearchObject("C_Purchas*")
SearchObject("C_Material*Query")
SearchObject("C_Supplier*Query")

-- Leer estructura de una CDS analitica
ReadView("C_PurchasingDocumentItemQuery")
ReadView("C_MaterialStockQuery")

-- Verificar annotations analiticas
ReadView("C_PurchaseOrderItemQuery")
-- Buscar: @Analytics.query: true, @Aggregation.default: #SUM
```

## Fiori Analytical Apps — MM

### KPI Tiles (Launchpad)
```
Tiles de KPI para el Launchpad del comprador:

+------------------+  +------------------+  +------------------+
| POs pendientes   |  | Facturas         |  | Stock valor      |
| de GR            |  | bloqueadas       |  | total            |
| 47               |  | 12               |  | $2.4M            |
+------------------+  +------------------+  +------------------+

+------------------+  +------------------+  +------------------+
| On-time          |  | Maverick         |  | GR/IR            |
| delivery %       |  | buying %         |  | variance         |
| 94.2%            |  | 8.1%             |  | $12,340          |
+------------------+  +------------------+  +------------------+

Config: Fiori Launchpad → Target Mapping → KPI Tile →
  CDS View → Measure → Filter → Threshold (rojo/amarillo/verde)
```

### Smart Business KPIs predefinidos
| KPI App | Descripcion | CDS base |
|---------|-------------|----------|
| F0862 | Purchase Order Analysis | C_PurchaseOrderItemQuery |
| F0863 | Purchasing Spend Analysis | C_SpendAnalysisQuery |
| F2100 | Stock Overview Analysis | C_MaterialStockQuery |
| F2101 | Inventory Turnover | C_InventoryTurnoverQuery |
| F3045 | Supplier Evaluation | C_SupplierEvaluationQuery |

## SAP Analytics Cloud (SAC) Integration

### Live Connection
```
SAC se conecta directamente a CDS views de S/4HANA:
  - Sin replicacion de datos
  - Datos en tiempo real
  - Usa las mismas CDS views (C_*)

Config:
  1. S/4 HANA: activar servicio /sap/bc/adt/analytics/query
  2. SAC: crear Live Connection a S/4HANA
  3. SAC: crear modelo sobre CDS view (C_PurchaseOrderItemQuery)
  4. SAC: crear story con graficos y tablas
```

### Import Connection (batch)
```
Para datos historicos o analisis pesado:
  SAC importa datos via CDS extraction views (A_*)
  Programacion: diaria, semanal, mensual
  Ventaja: no impacta performance de S/4
```

## Custom Analytics (Key User)

### Custom CDS View analitica
```
App Fiori: "Custom CDS Views" (F5307)

Ejemplo: Analisis de compras por proveedor con rating sustentabilidad

1. Base entity: I_PurchaseOrderItemTP
2. Campos:
   - Supplier (dimension)
   - MaterialGroup (dimension)
   - NetOrderValueInLC (measure, SUM)
   - OrderQuantity (measure, SUM)
   - ZZ_SustainRating (custom field, dimension)
3. Filtro: CompanyCode = '1000', PurchaseOrderDate >= '2025-01-01'
4. Publicar → disponible en Fiori y SAC
```

### Custom KPI Tile
```
App Fiori: "KPI Workspace" (F0868) o "Manage KPI" (F3501)

1. Seleccionar CDS view
2. Definir medida (SUM, AVG, COUNT)
3. Definir umbrales (verde/amarillo/rojo)
4. Asignar a grupo del Launchpad
5. Los usuarios ven el KPI en tiempo real
```

## Queries MCP para diagnostico analitico

```sql
-- Top 10 proveedores por gasto (S/4 nativo)
SELECT LIFNR, SUM(NETWR) as TOTAL_SPEND
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKKO.BEDAT BETWEEN '{desde}' AND '{hasta}'
AND EKKO.EKORG = '{org}'
GROUP BY LIFNR ORDER BY TOTAL_SPEND DESC

-- Analisis ABC de materiales por valor stock
SELECT MATNR, WERKS, LABST, VERPR, (LABST * VERPR) as STOCK_VALUE
FROM MARD JOIN MBEW ON MARD.MATNR = MBEW.MATNR AND MARD.WERKS = MBEW.BWKEY
WHERE MARD.WERKS = '{centro}' AND MARD.LABST > 0
ORDER BY STOCK_VALUE DESC

-- On-time delivery rate
SELECT
  COUNT(*) as TOTAL_GR,
  SUM(CASE WHEN EKBE.BUDAT <= EKET.EINDT THEN 1 ELSE 0 END) as ON_TIME
FROM EKBE
JOIN EKET ON EKBE.EBELN = EKET.EBELN AND EKBE.EBELP = EKET.EBELP
WHERE EKBE.VGABE = '1' AND EKBE.BEWTP = 'E'
AND EKBE.BUDAT BETWEEN '{desde}' AND '{hasta}'

-- Invoice accuracy (% sin bloqueo)
SELECT
  COUNT(*) as TOTAL,
  SUM(CASE WHEN RBKP.ZLSPR = '' THEN 1 ELSE 0 END) as SIN_BLOQUEO
FROM RBKP
WHERE RBKP.BUKRS = '{sociedad}'
AND RBKP.BUDAT BETWEEN '{desde}' AND '{hasta}'

-- Inventory days of supply
SELECT MATNR, WERKS, LABST,
  CASE WHEN CONSUMED_QTY > 0
    THEN LABST / (CONSUMED_QTY / 365)
    ELSE 9999
  END as DAYS_OF_SUPPLY
FROM (
  SELECT MARD.MATNR, MARD.WERKS, MARD.LABST,
    (SELECT SUM(MENGE) FROM MATDOC
     WHERE MATNR = MARD.MATNR AND WERKS = MARD.WERKS
     AND BWART IN ('201','261') AND BUDAT >= '{hace_1_ano}') as CONSUMED_QTY
  FROM MARD WHERE MARD.WERKS = '{centro}' AND MARD.LABST > 0
)
ORDER BY DAYS_OF_SUPPLY ASC
```

## Migracion de reports legacy a Embedded Analytics

### Checklist
```
1. [ ] Identificar reports Z que usan tablas LIS (S000-S999)
2. [ ] Identificar reports Z que usan BSIK/BSAK directamente
3. [ ] Mapear cada report a CDS view equivalente (C_*)
4. [ ] Crear custom CDS views para reports sin equivalente
5. [ ] Crear Fiori apps analiticas (Smart Chart)
6. [ ] Configurar KPI tiles en Launchpad
7. [ ] Conectar SAC para analisis avanzado
8. [ ] Desactivar batch jobs de actualizacion LIS (ya no necesarios)
9. [ ] Entrenar usuarios en Fiori analytics
```
