# S/4HANA 2023 — Analiticas Embebidas SD

## CDS Views Analiticas para SD

### Views de Cubo (Cube)
| CDS View | Descripcion | Campos clave |
|----------|-------------|--------------|
| I_SalesOrderItemCube | Analisis pedidos | VKORG, KUNNR, MATNR, NETWR, KWMENG |
| I_BillingDocumentItemCube | Analisis facturacion | VKORG, KUNAG, MATNR, NETWR, FKIMG |
| I_DeliveryDocumentItemCube | Analisis entregas | VKORG, KUNNR, MATNR, LFIMG |
| I_SalesDocumentItemPrcgElmnt | Condiciones pricing | KSCHL, KWERT, KBETR |
| I_CreditMemoRequestItemCube | Notas de credito | KUNNR, MATNR, NETWR |

### Views de Dimension
| CDS View | Dimension |
|----------|-----------|
| I_Customer | Cliente (BP) |
| I_Product | Material/Producto |
| I_SalesOrganization | Org ventas |
| I_DistributionChannel | Canal distribucion |
| I_Division | Sector |
| I_SalesDistrict | Distrito ventas |
| I_CustomerGroup | Grupo cliente |

### Views de Query (Consumption)
| CDS View | Uso | Fiori App |
|----------|-----|-----------|
| C_SalesOrderItemQry | Query pedidos | Sales Order Fulfillment |
| C_BillingDocumentItemQry | Query facturacion | Billing Document Analysis |
| C_DeliveryDocumentItemQry | Query entregas | Delivery Performance |
| C_CreditExposureQry | Query credito | Credit Exposure |

## KPI Tiles para SD

```
Configurar en Fiori Launchpad:

Tile 1: Order Intake (valor pedidos nuevos periodo)
  CDS: C_SalesOrderItemQry
  Measure: SUM(NetAmount)
  Filter: CreationDate = current period
  Threshold: verde > target, rojo < 80% target

Tile 2: Revenue (facturacion periodo)
  CDS: C_BillingDocumentItemQry
  Measure: SUM(NetAmount)
  Filter: BillingDate = current period

Tile 3: Delivery Performance (% entregas a tiempo)
  CDS: C_DeliveryDocumentItemQry
  Measure: COUNT(OnTimeDelivery) / COUNT(*)
  Threshold: verde > 95%, amarillo > 90%

Tile 4: Returns Rate (% devoluciones)
  CDS: custom view
  Measure: SUM(ReturnValue) / SUM(SalesValue) * 100
  Threshold: verde < 3%, rojo > 5%

Tile 5: Credit Utilization (% uso credito)
  CDS: C_CreditExposureQry
  Measure: AVG(Utilization%)

Tile 6: Open Orders Backlog
  CDS: C_SalesOrderItemQry
  Filter: OverallDeliveryStatus <> 'C'
  Measure: SUM(NetAmount)
```

## Dashboards en Tiempo Real

### Sales Overview Dashboard
```
Componentes:
  1. Bar chart: Revenue por mes (12 meses)
  2. Pie chart: Revenue por canal distribucion
  3. Table: Top 10 clientes por revenue
  4. Line chart: Order intake trend
  5. KPI cards: Revenue actual vs target vs YoY
```

### Order Fulfillment Monitor
```
Componentes:
  1. Funnel: Pedidos → Entregas → Facturas (conversion)
  2. Heatmap: Entregas por region y status
  3. List: Pedidos criticos (vencidos, bloqueados)
  4. Gauge: % completitud OTC
```

## SAP Analytics Cloud (SAC) Integracion

```
Live Data Connection:
  S/4HANA → SAC via OData
  CDS views con @Analytics.dataCategory: #CUBE
  Requiere: Communication Arrangement en S/4HANA

Modelos de planning:
  - Forecast de ventas por producto/region
  - Budget vs actual por org ventas
  - Simulacion pricing

Stories:
  - Executive Sales Dashboard
  - Customer Profitability Analysis
  - Product Performance
```

## Custom CDS Views Analiticas

```sql
-- Ejemplo: Revenue por cliente y mes
@AbapCatalog.sqlViewName: 'ZISDRVENUEQ'
@Analytics.query: true
@VDM.viewType: #CONSUMPTION
define view Z_I_SD_RevenueByCustomerMonth
  as select from I_BillingDocumentItemCube
{
  @AnalyticsDetails.query.axis: #ROWS
  SoldToParty,
  @AnalyticsDetails.query.axis: #ROWS
  CalendarYearMonth,
  @Semantics.amount.currencyCode: 'TransactionCurrency'
  @DefaultAggregation: #SUM
  NetAmount,
  @DefaultAggregation: #SUM
  BillingQuantity,
  TransactionCurrency
}
where BillingDocumentIsCancelled = ''
```

## Comparacion con SIS Clasico

| SIS Clasico | S/4HANA Analytics |
|-------------|-------------------|
| MC+ reports (MCTA, MCTC) | CDS views + Fiori apps |
| LIS structures (S001-S004) | Eliminadas — datos en tiempo real |
| VB(S) info structures | No necesarias |
| Batch updates | Real-time desde tablas operativas |
| ABAP reports custom | CDS views + SAC stories |

## Queries MCP para Analiticas

```sql
-- Revenue por cliente (top 20)
SELECT KUNAG, SUM(NETWR) as REVENUE, COUNT(*) as NUM_FACTURAS
FROM VBRK WHERE FKART = 'F2' AND FKSTO = '' AND VKORG = '{org}'
AND FKDAT BETWEEN '{desde}' AND '{hasta}'
GROUP BY KUNAG ORDER BY REVENUE DESC
FETCH FIRST 20 ROWS ONLY

-- Revenue por material
SELECT VBRP.MATNR, MAKT.MAKTX, SUM(VBRP.NETWR) as REVENUE, SUM(VBRP.FKIMG) as QTY
FROM VBRP JOIN VBRK ON VBRP.VBELN = VBRK.VBELN
JOIN MAKT ON VBRP.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'S'
WHERE VBRK.FKSTO = '' AND VBRK.VKORG = '{org}'
GROUP BY VBRP.MATNR, MAKT.MAKTX ORDER BY REVENUE DESC

-- Order backlog (pedidos abiertos sin entregar)
SELECT VBAK.VBELN, VBAK.KUNNR, SUM(VBAP.NETWR) as VALOR,
       VBAK.ERDAT, VBAK.AUART
FROM VBAK JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
WHERE VBAK.GBSTK <> 'C' AND VBAP.ABGRU = '' AND VBAK.VKORG = '{org}'
GROUP BY VBAK.VBELN, VBAK.KUNNR, VBAK.ERDAT, VBAK.AUART

-- Delivery performance (entregas a tiempo vs tarde)
SELECT
  CASE WHEN LIKP.WADAT_IST <= LIKP.WADAT THEN 'ON_TIME' ELSE 'LATE' END as STATUS,
  COUNT(*) as NUM
FROM LIKP WHERE LIKP.VKORG = '{org}' AND LIKP.WADAT_IST <> '00000000'
AND LIKP.ERDAT BETWEEN '{desde}' AND '{hasta}'
GROUP BY CASE WHEN LIKP.WADAT_IST <= LIKP.WADAT THEN 'ON_TIME' ELSE 'LATE' END

-- Returns rate
SELECT
  (SELECT SUM(NETWR) FROM VBRK WHERE FKART IN ('RE','G2') AND FKSTO='' AND VKORG='{org}'
   AND FKDAT BETWEEN '{desde}' AND '{hasta}') as RETURNS_VALUE,
  (SELECT SUM(NETWR) FROM VBRK WHERE FKART = 'F2' AND FKSTO='' AND VKORG='{org}'
   AND FKDAT BETWEEN '{desde}' AND '{hasta}') as SALES_VALUE
FROM DUMMY
```
