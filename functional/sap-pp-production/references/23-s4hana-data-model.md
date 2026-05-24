# Modelo de Datos S/4HANA 2023 — PP

## Cambios principales vs ECC

### MATDOC reemplaza MKPF+MSEG

| ECC | S/4HANA | Descripcion |
|-----|---------|-------------|
| MKPF | MATDOC (header fields) | Cabecera doc material |
| MSEG | MATDOC (item fields) | Posiciones doc material |
| AUFM | MATDOC (filtered) | Movimientos para ordenes |

```sql
-- Movimientos produccion en S/4HANA
SELECT MBLNR, MJAHR, ZEESSION, BWART, MATNR, WERKS, LGORT,
       MENGE, MEINS, AUFNR, DMBTR, BUDAT, CPUDT, USNAM
FROM MATDOC
WHERE AUFNR = '{orden}'
AND BWART IN ('101','102','261','262','531','532')
ORDER BY BUDAT, MBLNR
```

### ACDOCA — Universal Journal

Todos los costes de produccion se registran en ACDOCA:

```sql
-- Costes acumulados en orden produccion
SELECT AUFNR, KSTAR, POPER, SUM(HSL) AS COSTE_REAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND AUFNR = '{orden}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
GROUP BY AUFNR, KSTAR, POPER

-- Actividades internas (confirmaciones)
SELECT AUFNR, KSTAR, LSTAR, MESSION, SUM(HSL) AS IMPORTE
FROM ACDOCA
WHERE AUFNR = '{orden}' AND LSTAR <> ''
GROUP BY AUFNR, KSTAR, LSTAR, MESSION
```

### Tablas eliminadas en S/4HANA

| Tabla ECC | Reemplazada por | Area |
|-----------|-----------------|------|
| MKPF | MATDOC | Material documents |
| MSEG | MATDOC | Material doc items |
| AUFM | MATDOC | Order goods movements |
| COEP | ACDOCA | CO line items |
| COSS | ACDOCA | CO totals statistical |
| COSP | ACDOCA | CO totals primary |
| COBK | ACDOCA | CO document header |

### Tablas que permanecen

| Tabla | Descripcion | Nota |
|-------|-------------|------|
| AFKO | Cabecera orden produccion | Sin cambios |
| AFPO | Posiciones orden | Sin cambios |
| AFVC | Operaciones orden | Sin cambios |
| AFRU | Confirmaciones | Sin cambios |
| RESB | Reservas componentes | Sin cambios |
| JEST | Status | Sin cambios |
| MARC | Material-centro | Sin cambios |
| MARD | Stock almacen | Sin cambios |
| STKO | Cabecera BOM | Sin cambios |
| STPO | Posiciones BOM | Sin cambios |
| PLKO | Cabecera routing | Sin cambios |
| PLPO | Operaciones routing | Sin cambios |
| CRHD | Puesto trabajo | Sin cambios |
| MKAL | Version fabricacion | Sin cambios |
| PLAF | Ordenes previsionales | Sin cambios |

## Campos ACDOCA relevantes para PP

| Campo | Descripcion | Uso PP |
|-------|-------------|--------|
| AUFNR | Numero orden | Orden produccion |
| KSTAR | Clase de coste | Tipo de coste |
| LSTAR | Clase de actividad | Actividad interna |
| MESSION | Unidad de medida | Unidad actividad |
| HSL | Importe moneda sociedad | Coste real |
| POPER | Periodo | Periodo contable |
| GJAHR | Ejercicio | Ano fiscal |
| RBUKRS | Sociedad | Sociedad |
| RLDNR | Ledger | 0L = leading ledger |
| BWART | Tipo movimiento | 101, 261, etc. |
| MATNR | Material | Material producido/componente |

## CDS Views nativas S/4HANA

### Core PP views

| CDS View | Descripcion |
|----------|-------------|
| I_ProductionOrder | Orden produccion (cabecera) |
| I_ProductionOrderItem | Posicion orden |
| I_ProductionOrderOperation | Operacion orden |
| I_ProductionOrderComponent | Componente (reserva) |
| I_ProductionOrderConfirmation | Confirmacion |
| I_ProductionOrderStatus | Status sistema/usuario |

### MRP views

| CDS View | Descripcion |
|----------|-------------|
| I_MRPElement | Elemento MRP individual |
| I_PlannedOrder | Orden previsional |
| I_MRPMaterial | Material con datos MRP |
| I_MaterialStockTimeSeries | Serie temporal stock |

### Stock views

| CDS View | Descripcion |
|----------|-------------|
| I_MaterialStock | Stock consolidado |
| I_MaterialStockByPlant | Stock por centro |
| I_MaterialStockByStorageLocation | Stock por almacen |

### Master data views

| CDS View | Descripcion |
|----------|-------------|
| I_BillOfMaterial | BOM |
| I_BillOfMaterialItem | Posiciones BOM |
| I_ProductionRouting | Routing |
| I_ProductionRoutingOperation | Operacion routing |
| I_WorkCenter | Puesto trabajo |
| I_ProductionVersion | Version fabricacion |

## Compatibility views (S/4)

SAP provee compatibility views para codigo legacy:
- MKPF → vista sobre MATDOC
- MSEG → vista sobre MATDOC
- AUFM → vista sobre MATDOC
- COEP → vista sobre ACDOCA

**Importante**: Las compatibility views funcionan pero con rendimiento inferior. Para nuevo desarrollo, usar siempre MATDOC y ACDOCA directamente.
