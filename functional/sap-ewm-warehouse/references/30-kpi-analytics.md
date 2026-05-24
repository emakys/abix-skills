# KPIs y Analytics EWM

Métricas clave de operación de almacén, fórmulas de cálculo, consultas MCP para obtener datos, benchmarks por tipo de almacén e integración con analytics en S/4HANA 2023 EWM.

---

## KPIs Principales de Almacén

### 1. Dock-to-Stock Time (Tiempo Doca a Stock)

**Definición:** Tiempo transcurrido desde que el camión llega al dock hasta que la mercancía queda disponible en su ubicación definitiva (putaway completo).

**Fórmula:**
```
Dock-to-Stock Time = Timestamp(GR confirmado) − Timestamp(llegada al dock)

Unidad: horas o minutos
Medición: por entrega, promedio diario/semanal
```

**Componentes:**
- Tiempo de descarga (unloading time)
- Tiempo de verificación / QM (si aplica)
- Tiempo de putaway (desde GR hasta confirmación WT)

**Benchmark por tipo de almacén:**
| Tipo | World Class | Promedio industria | Deficiente |
|------|------------|-------------------|------------|
| Distribución retail | < 2 horas | 4-8 horas | > 12 horas |
| Manufactura (componentes) | < 4 horas | 8-24 horas | > 48 horas |
| Farmacéutico (con QM) | < 8 horas | 12-48 horas | > 72 horas |
| e-Commerce fulfillment | < 1 hora | 2-4 horas | > 6 horas |

**Consulta MCP:**
```javascript
// Obtener tiempos de entrega de entrada recientes
const result = await mcp.call("SearchObjects", {
  object_type: "PROG",
  search_term: "/SCWM/IB"
});

// Query CDS para dock-to-stock (embedded analytics)
// Vista: /SCWM/C_INBDELIVERY_STATS
// Campos: InbDelivery, CreationTimestamp, GRPostingTimestamp, PutawayConfirmTimestamp
```

**CDS View relevante:**
```abap
@Analytics.dataCategory: #CUBE
define view /SCWM/C_INBDELIVERY_STATS
  as select from /SCWM/LQUA
  ...
  key WarehouseNumber,
  key InboundDelivery,
  GRTimestamp,
  PutawayConfirmTimestamp,
  ( PutawayConfirmTimestamp - GRTimestamp ) as DockToStockMinutes
```

---

### 2. Order Cycle Time (Tiempo de Ciclo de Pedido)

**Definición:** Tiempo total desde la creación de la entrega de salida hasta el PGI (Post Goods Issue).

**Fórmula:**
```
Order Cycle Time = Timestamp(PGI) − Timestamp(Creación entrega SD)

Descomposición:
  + Wave assignment time (tiempo hasta asignación a ola)
  + Pick time (tiempo de picking)
  + Pack time (tiempo de empaque)
  + Load time (tiempo de carga)
  + PGI execution time
```

**Benchmark:**
| Segmento | World Class | Promedio | Deficiente |
|----------|------------|----------|------------|
| e-Commerce same-day | < 2 horas | 4-6 horas | > 8 horas |
| Distribución B2B | < 4 horas | 8-24 horas | > 48 horas |
| Proyecto/especial | N/A | 24-72 horas | > 1 semana |

**Query EWM para ciclo de pedido:**
```sql
-- Tablas EWM S/4HANA 2023
SELECT
  odb.lgnum AS WarehouseNumber,
  odb.who   AS OutboundDelivery,
  odb.erdat AS DeliveryCreateDate,
  odb.erzet AS DeliveryCreateTime,
  gi.budat  AS GIPostingDate,
  gi.uzeit  AS GIPostingTime
FROM /scwm/d_obd AS odb
JOIN matdoc AS gi
  ON gi.aufnr = odb.who
WHERE gi.bwart = '601'
```

---

### 3. Pick Accuracy (Exactitud de Picking)

**Definición:** Porcentaje de líneas de picking completadas sin errores (material correcto, cantidad correcta, bin correcto).

**Fórmula:**
```
Pick Accuracy (%) = (Líneas correctas / Total líneas pickeadas) × 100

Complemento:
  Error Rate (%) = (Líneas con error / Total líneas) × 100

Errores contabilizados:
  - Material incorrecto seleccionado
  - Cantidad diferente a la requerida
  - Bin de origen incorrecto
  - Lote incorrecto (si aplica)
```

**Benchmark:**
| Nivel | Pick Accuracy |
|-------|--------------|
| World Class | >= 99.95% |
| Bueno | 99.5% - 99.95% |
| Promedio industria | 98% - 99.5% |
| Deficiente | < 98% |

**Consulta MCP para errores de picking:**
```javascript
// Buscar tareas con diferencias de cantidad
const warehouseTasks = await mcp.call("GetObjectSource", {
  object_type: "PROG",
  object_name: "/SCWM/R_WT_DIFF_REPORT"
});

// Via Warehouse Monitor (F3456):
// Sección "Task Differences" → filtrar por tipo PICK y con diferencia > 0
```

**Indicador en Warehouse Monitor:**
```
/SCWM/MON → Performance → Pick Accuracy
Alerta: < 99.5% → amarillo, < 99% → rojo
```

---

### 4. Inventory Accuracy (Exactitud de Inventario)

**Definición:** Porcentaje de bins / posiciones de stock donde el conteo físico coincide exactamente con el libro (sin diferencias).

**Fórmula:**
```
Inventory Accuracy (%) = (Bins sin diferencia / Total bins contados) × 100

Alternativa por valor:
  Inventory Accuracy (valor) = (Valor stock correcto / Valor total inventario) × 100
```

**Componentes de medición:**
- Exactitud de ubicación: material en el bin correcto
- Exactitud de cantidad: cantidad igual al libro
- Exactitud de lote: lote correcto registrado
- Exactitud de HU: HU asignada al bin correcto

**Benchmark:**
| Nivel | Inventory Accuracy |
|-------|-------------------|
| World Class | >= 99.5% |
| Bueno | 98% - 99.5% |
| Promedio | 95% - 98% |
| Deficiente | < 95% |

**Query PI para accuracy:**
```sql
-- Documentos de inventario físico con diferencias
SELECT
  lgnum,
  ivnum,              -- Número documento PI
  matnr,             -- Material
  lgpla,             -- Bin
  menge_buch,        -- Cantidad libro
  menge_ist,         -- Cantidad contada
  ( menge_buch - menge_ist ) AS diferencia,
  CASE WHEN ( menge_buch - menge_ist ) = 0 THEN 'OK' ELSE 'DIFF' END AS estado
FROM /scwm/lpiitem
WHERE gjahr = @sy-datum(1,4)
  AND status = 'C'   -- completado
```

---

### 5. Throughput (Líneas por Hora)

**Definición:** Cantidad de líneas de warehouse tasks confirmadas por hora de trabajo.

**Fórmula:**
```
Throughput = Total WT confirmadas / Horas de trabajo efectivas

Por proceso:
  Picking Throughput    = Líneas picking / Horas picking
  Putaway Throughput    = Líneas putaway / Horas putaway
  Packing Throughput    = Líneas empaque / Horas empaque
```

**Benchmark por operación:**
| Operación | World Class | Promedio | Deficiente |
|-----------|------------|----------|------------|
| Picking unitario | > 100 líneas/hora | 50-80 l/h | < 30 l/h |
| Picking caja | > 80 líneas/hora | 40-60 l/h | < 25 l/h |
| Picking pallet | > 30 pallets/hora | 15-25 p/h | < 10 p/h |
| Putaway estantería | > 40 líneas/hora | 20-35 l/h | < 15 l/h |
| Putaway pallet | > 25 pallets/hora | 12-20 p/h | < 8 p/h |

**Query MCP para throughput:**
```javascript
// Resource Monitor (F3457) → Performance tab
// Muestra: líneas/hora por recurso, por turno, por área de actividad

// Consulta directa a Warehouse Tasks confirmadas hoy
const tasks = await mcp.call("ReadTable", {
  table: "/SCWM/ORDIM_C",  -- WT confirmadas
  fields: ["LGNUM", "LENA", "VLENAID", "UZEIT_E", "UZEIT_A"],
  where: "BUDAT = SY-DATUM AND PROCESSTEP = 'PICK'"
});
```

---

### 6. Space Utilization (Utilización de Espacio)

**Definición:** Porcentaje de capacidad de almacenamiento utilizada respecto a la capacidad total.

**Fórmulas:**
```
Por bins:
  Utilización bins (%) = (Bins ocupados / Total bins) × 100

Por volumen/peso:
  Utilización volumen (%) = (Volumen ocupado / Capacidad total) × 100

Por tipo de almacén:
  Utilización por tipo = Bins ocupados en tipo / Total bins en tipo
```

**Benchmark:**
| Nivel | Utilización ideal | Riesgo |
|-------|------------------|--------|
| Óptimo | 75% - 85% | Buen equilibrio flujo/capacidad |
| Alerta | 85% - 95% | Dificultad en putaway |
| Crítico | > 95% | Operaciones comprometidas |
| Desaprovechado | < 60% | Costos fijos altos sin justificación |

**Query para utilización:**
```sql
-- Ocupación por tipo de almacén
SELECT
  lgtyp AS StorageType,
  COUNT(*) AS TotalBins,
  SUM( CASE WHEN matnr IS NOT NULL THEN 1 ELSE 0 END ) AS OccupiedBins,
  CAST( SUM( CASE WHEN matnr IS NOT NULL THEN 1 ELSE 0 END ) AS DECIMAL(5,2) )
    / COUNT(*) * 100 AS UtilizationPct
FROM /scwm/lplk
WHERE lgnum = @lgnum
GROUP BY lgtyp
```

**En Warehouse Monitor F3456:**
```
Tile: "Storage Type Occupancy"
Drill-down: por tipo → por sección → por bin individual
Alertas configurables: 80% amarillo, 90% rojo
```

---

### 7. On-Time Shipment Rate (Tasa de Envío a Tiempo)

**Definición:** Porcentaje de entregas de salida con PGI ejecutado antes o en la fecha/hora prometida al cliente.

**Fórmula:**
```
On-Time Shipment (%) = (Entregas PGI a tiempo / Total entregas) × 100

A tiempo = PGI Timestamp <= Fecha/Hora prometida de entrega - Lead time de transporte
```

**Benchmark:**
| Segmento | World Class | Promedio |
|----------|------------|----------|
| FMCG / Retail | >= 98.5% | 95-97% |
| Industrial B2B | >= 97% | 92-96% |
| e-Commerce | >= 99% | 96-98% |
| Farmacéutico | >= 99.5% | 97-99% |

**Query:**
```sql
SELECT
  lgnum,
  who AS OutboundDelivery,
  lpnr AS Carrier,
  lfdat AS PlannedShipDate,
  pgi_timestamp,
  CASE
    WHEN pgi_timestamp <= lfdat THEN 'ON_TIME'
    ELSE 'LATE'
  END AS ShipmentStatus,
  ( pgi_timestamp - lfdat ) AS DelayMinutes
FROM /scwm/d_obd
WHERE status = 'C'   -- cerrada/PGI ejecutado
  AND budat >= @start_date
```

---

### 8. Stock Turn (Rotación de Inventario)

**Definición:** Número de veces que el inventario se renueva en un período (usualmente anual).

**Fórmula:**
```
Stock Turn = Costo de Mercancía Vendida (COGS) / Inventario Promedio

Alternativa operativa EWM:
  Stock Turn = Total GI (unidades/valor) / Stock Promedio (unidades/valor)

Days on Hand (DOH) = 365 / Stock Turn
```

**Benchmark por industria:**
| Industria | Stock Turn anual | DOH |
|-----------|-----------------|-----|
| Retail FMCG | 20-30x | 12-18 días |
| Manufactura | 8-15x | 24-46 días |
| Farmacéutico | 5-10x | 37-73 días |
| Equipos industriales | 3-6x | 61-122 días |
| Moda/Apparel | 4-8x | 46-91 días |

**Datos desde EWM:**
```sql
-- Movimientos de salida (GI) del período para cálculo de rotación
SELECT
  matnr,
  SUM( menge ) AS TotalGIQuantity,
  SUM( wert )  AS TotalGIValue
FROM /scwm/lquav    -- Historial de movimientos de valor
WHERE bwart IN ('601', '261', '201')  -- GI SD, PP, genérico
  AND budat BETWEEN @period_start AND @period_end
GROUP BY matnr
```

---

## CDS Views para Embedded Analytics

### Vistas Analíticas EWM en S/4HANA 2023

```abap
-- Vista de rendimiento de tareas de almacén
/SCWM/C_WHTASK_PERFORMANCE    -- Warehouse Task performance
/SCWM/C_STOCK_OVERVIEW        -- Stock overview analítico
/SCWM/C_INBDLV_MONITOR        -- Inbound delivery monitor
/SCWM/C_OUTBDLV_MONITOR       -- Outbound delivery monitor
/SCWM/C_PI_ACCURACY           -- Physical inventory accuracy
/SCWM/C_RESOURCE_UTILIZATION  -- Resource utilization
/SCWM/C_BIN_OCCUPANCY         -- Storage bin occupancy
```

**Ejemplo de activación embedded analytics:**
```
Transacción: RSRT (Query Monitor)
O bien: Fiori app "Query Browser" con las vistas /SCWM/*
```

---

## KPIs en Warehouse Monitor (F3456 / /SCWM/MON)

### Configuración de KPIs en el Monitor

```
SPRO > EWM > Cross-Process Settings > Warehouse Monitor > Define KPI Tiles
```

**KPI tiles estándar disponibles:**

| Tile | Métrica | Actualización |
|------|---------|--------------|
| Open WT | Tareas pendientes | Tiempo real |
| WT Throughput | Líneas/hora actual | Cada 15 min |
| Dock-to-Stock | Promedio últimas 4h | Cada hora |
| GR Backlog | Entregas sin procesar | Tiempo real |
| GI Backlog | Entregas sin PGI vencidas | Tiempo real |
| PI Progress | % conteo completado | Tiempo real |
| Bin Occupancy | % ocupación por tipo | Cada hora |
| Resource Status | Recursos activos/total | Tiempo real |

### Alertas Configurables
```
/SCWM/MON → Settings → Alert Thresholds
```

Ejemplos de alertas recomendadas:
```
WT > 2 horas sin confirmar      → Alerta nivel AMARILLO
WT > 4 horas sin confirmar      → Alerta nivel ROJO
Bin occupancy > 90%             → Alerta nivel AMARILLO
GR backlog > 5 entregas         → Alerta nivel AMARILLO
Pick accuracy < 99.5% (hoy)     → Alerta nivel ROJO
Recursos activos < 50% planificados → Alerta nivel ROJO
```

---

## Integración con SAP Analytics Cloud (SAC)

### Arquitectura de Integración

```
S/4HANA EWM (CDS Views)
  → SAP BW/4HANA (opcional, para histórico largo plazo)
  → SAP Analytics Cloud
      ├── Live Connection (tiempo real via OData)
      └── Import Connection (batch, para datos históricos pesados)
```

### Conexión Directa SAC → S/4HANA

**Tipo de conexión:** Live Data Connection via OData V4
```
En SAC: Connections → Add → SAP S/4HANA
URL: https://{s4host}/sap/opu/odata4/...
Autenticación: OAuth 2.0 / Basic Auth
```

**Modelos analíticos recomendados en SAC:**

1. **EWM Operational Dashboard**
   - Throughput en tiempo real
   - Estado de waves activas
   - Recursos por área de actividad

2. **EWM Management Report (diario/semanal)**
   - Dock-to-stock trend
   - Pick accuracy por área / turno
   - On-time shipment rate

3. **Inventory Analytics**
   - Stock turn por material / categoría ABC
   - Inventory accuracy histórico
   - Space utilization por tipo de almacén

### Stories SAC — Templates Disponibles

SAP Content Network (content.sap.com) ofrece:
```
Template: "SAP EWM Analytics"
Package: SCM_EWM_ANALYTICS_CONTENT_SAC
```
Incluye: 4 stories preconfiguradas, 12 KPI cards, 8 CDS views vinculadas.

---

## Formulas de Referencia Rapida

| KPI | Fórmula simplificada |
|-----|---------------------|
| Dock-to-Stock | GR_timestamp − Dock_arrival_timestamp |
| Order Cycle Time | PGI_timestamp − Delivery_create_timestamp |
| Pick Accuracy % | (Lines_OK / Lines_total) × 100 |
| Inventory Accuracy % | (Bins_no_diff / Bins_counted) × 100 |
| Throughput | WT_confirmed / Work_hours |
| Space Utilization % | (Bins_occupied / Bins_total) × 100 |
| On-Time Shipment % | (On_time_PGI / Total_PGI) × 100 |
| Stock Turn | Annual_COGS / Avg_inventory_value |
| Days on Hand | 365 / Stock_Turn |
| Fill Rate % | (Lines_shipped_complete / Lines_ordered) × 100 |
