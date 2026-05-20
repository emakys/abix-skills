# Reporting y Analytics MM

## Reports estandar principales

### Compras
| TCode | Report | Que muestra |
|-------|--------|-------------|
| ME2M | POs por material | Lista de pedidos filtrados por material |
| ME2L | POs por proveedor | Lista pedidos por proveedor |
| ME2N | POs por numero | Lista pedidos por rango de numeros |
| ME2C | POs por grupo material | Pedidos agrupados por material group |
| ME2W | POs por centro proveedor | Pedidos por combinacion centro+proveedor |
| ME2J | POs por proyecto | Pedidos con imputacion a proyecto |
| ME2K | POs por centro coste | Pedidos con imputacion a CC |
| ME80FN | Analisis general compras | Report flexible multi-criterio |
| ME5A | Solicitudes pedido | Lista de PRs |
| ME3M | Contratos por material | Contratos marco |
| ME3L | Contratos por proveedor | Contratos marco |

### Inventario y Stock
| TCode | Report | Que muestra |
|-------|--------|-------------|
| MB52 | Stock por almacen | Stock actual desglosado por almacen |
| MMBE | Resumen stock | Vista consolidada de stock por material |
| MB51 | Lista doc material | Historial de movimientos |
| MB5B | Stock a fecha | Stock valorado a una fecha pasada |
| MB5L | Saldos de stock | Valores de stock por cuenta |
| MB5T | Stock en transito | Materiales en transito entre centros |
| MC.9 | Analisis ABC | Clasificacion ABC por valor/consumo |
| MCBA | Analisis de consumo | Consumo historico de materiales |
| MCBC | Analisis de stock | Evolucion de stock en el tiempo |
| MCBE | Rango de cobertura | Dias de stock disponible |
| MI23 | Resultado inventario | Diferencias de inventario fisico |

### Verificacion facturas
| TCode | Report | Que muestra |
|-------|--------|-------------|
| MIR5 | Lista facturas | Facturas logisticas por criterios |
| MIR6 | Resumen facturas | Resumen de facturas |
| MR11SHOW | Saldo GR/IR | Saldo cuenta transitoria GR/IR |
| S_ALR_87012357 | Saldos proveedor | Saldo AP por proveedor |

### MRP
| TCode | Report | Que muestra |
|-------|--------|-------------|
| MD04 | Lista MRP | Stock/requirements — el mas importante |
| MD05 | Lista MRP individual | Para un material |
| MD06 | Lista MRP colectiva | Multiples materiales |
| MD07 | Resumen planificacion | Excepciones y propuestas |
| MD73 | Excepciones MRP | Lista consolidada de excepciones |
| MDBT | Log MRP | Resultado del ultimo run |

## Variantes ALV utiles

### Para ME2M (POs por material)
```
Campos recomendados en layout:
  EBELN, EBELP, LIFNR, NAME1, MATNR, MAKTX,
  MENGE, MEINS, WEMNG, NETPR, NETWR,
  EINDT, BEDAT, BSART

Filtros comunes:
  - Solo POs abiertas (ELIKZ = '')
  - Solo tipo NB
  - Solo un centro especifico
  - Periodo de fecha (BEDAT)
```

### Para MB52 (Stock por almacen)
```
Campos:
  MATNR, MAKTX, WERKS, LGORT, LABST, INSME, SPEME,
  VERPR/STPRS, SALK3 (valor stock)

Filtros:
  - Solo libre utilizacion > 0
  - Solo un almacen
  - Solo un grupo de materiales
```

## KPIs de Procurement

### Operativos
| KPI | Formula | Objetivo |
|-----|---------|----------|
| On-time delivery | GR on-time / Total GR * 100 | >95% |
| PO cycle time | Fecha GR - Fecha PO (dias promedio) | Reducir |
| PR-to-PO conversion time | Fecha PO - Fecha PR (dias) | <3 dias |
| Invoice accuracy | Facturas sin bloqueo / Total facturas * 100 | >98% |
| Maverick buying | POs sin contrato / Total POs * 100 | <10% |

### Financieros
| KPI | Formula | Objetivo |
|-----|---------|----------|
| Savings | (Precio anterior - Precio nuevo) / Precio anterior * 100 | Maximizar |
| Inventory turnover | COGS / Inventario promedio | Maximizar |
| Days of supply | Stock actual / Consumo diario promedio | Optimizar |
| GR/IR variance | Saldo cuenta GR/IR | Minimizar |
| Payment terms utilization | % facturas pagadas con descuento | >80% |

### Queries MCP para KPIs
```sql
-- On-time delivery (GR dentro de fecha prometida)
SELECT COUNT(*) as TOTAL,
       SUM(CASE WHEN MSEG.BUDAT <= EKET.EINDT THEN 1 ELSE 0 END) as ON_TIME
FROM EKPO
JOIN EKET ON EKPO.EBELN = EKET.EBELN AND EKPO.EBELP = EKET.EBELP
JOIN EKBE ON EKPO.EBELN = EKBE.EBELN AND EKPO.EBELP = EKBE.EBELP AND EKBE.VGABE = '1'
JOIN MSEG ON EKBE.BELNR = MSEG.MBLNR
WHERE EKPO.WERKS = '{centro}' AND MSEG.BUDAT BETWEEN '{desde}' AND '{hasta}'

-- Inventory turnover
SELECT MATNR, WERKS, LABST, VERPR, (LABST * VERPR) as STOCK_VALUE
FROM MARD JOIN MBEW ON MARD.MATNR = MBEW.MATNR AND MARD.WERKS = MBEW.BWKEY
WHERE MARD.WERKS = '{centro}' AND MARD.LABST > 0
ORDER BY (LABST * VERPR) DESC

-- POs sin contrato (maverick buying)
SELECT COUNT(*) as TOTAL_POS,
       SUM(CASE WHEN EKPO.KONNR = '' THEN 1 ELSE 0 END) as SIN_CONTRATO
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKKO.EKORG = '{org}' AND EKKO.BEDAT BETWEEN '{desde}' AND '{hasta}'
AND EKKO.BSART = 'NB'

-- Valor de stock por grupo de materiales
SELECT MARA.MATKL, SUM(MARD.LABST * MBEW.VERPR) as STOCK_VALUE
FROM MARD
JOIN MARA ON MARD.MATNR = MARA.MATNR
JOIN MBEW ON MARD.MATNR = MBEW.MATNR AND MARD.WERKS = MBEW.BWKEY
WHERE MARD.WERKS = '{centro}' AND MARD.LABST > 0
GROUP BY MARA.MATKL ORDER BY STOCK_VALUE DESC

-- Facturas bloqueadas (invoice accuracy)
SELECT COUNT(*) as TOTAL,
       SUM(CASE WHEN ZLSPR <> '' THEN 1 ELSE 0 END) as BLOQUEADAS
FROM RBKP WHERE BUKRS = '{sociedad}' AND BUDAT BETWEEN '{desde}' AND '{hasta}'
```

## CDS Views analiticas (S/4HANA)

| CDS View | Contenido |
|----------|-----------|
| I_PurchaseOrderItemAPI01 | Items de PO (API) |
| I_PurchaseRequisitionItemAPI01 | Items de PR (API) |
| I_MaterialDocumentItem | Items doc material |
| I_SupplierInvoiceItemAPI01 | Items factura proveedor |
| I_ProductStockAPI01 | Stock de material |
| C_PurchasingDocumentItemQuery | Query PO analitica |
| C_MaterialStockQuery | Query stock analitica |

### Queries MCP para CDS
```
ReadView("I_PurchaseOrderItemAPI01")     -- Estructura de la CDS
ReadView("C_PurchasingDocumentItemQuery") -- Query analitica
SearchObject("I_Purchase*")               -- Todas las CDS de compras
SearchObject("C_Material*Query")          -- Queries analiticas de materiales
```
