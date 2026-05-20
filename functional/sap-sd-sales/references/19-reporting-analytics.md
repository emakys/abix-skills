# Reporting y Analytics SD

## Reports estandar principales

### Pedidos de venta
| TCode | Report | Que muestra |
|-------|--------|-------------|
| VA05 | Lista de pedidos | Pedidos filtrados por org ventas, cliente, material, fecha |
| VA05N | Lista pedidos (nuevo) | Version mejorada con mas filtros |
| V.02 | Pedidos incompletos | Pedidos con datos obligatorios faltantes (log de incompletitud) |
| V.03 | Backlog de pedidos | Pedidos sin entregar completamente |
| V.04 | Pedidos urgentes | Pedidos con prioridad alta |
| V.15 | Lista de pedidos bloqueados | Pedidos en bloqueo de credito u otro |
| VC/2 | Analisis de ventas | Report flexible por dimension |
| VA55 | Lista de contratos | Contratos marco de ventas |

### Entregas y expedicion
| TCode | Report | Que muestra |
|-------|--------|-------------|
| VL06O | Monitor de entregas salida | Vista integral de outbound deliveries |
| VL06G | Entregas para picking | Worklist de picking pendiente |
| VL06P | Entregas para PGI | Worklist para Post Goods Issue |
| VL06C | Entregas para confirmacion | Confirmaciones de entrega pendientes |
| VL10A | Entregas atrasadas | Entregas con fecha comprometida vencida |
| VT11 | Lista de transportes | Documentos de transporte |
| VL04 | Entregas pendientes de crear | Pedidos listos para crear entrega |
| MB52 | Stock en almacen | Stock disponible para comprometer |

### Facturacion
| TCode | Report | Que muestra |
|-------|--------|-------------|
| VF05 | Lista de facturas | Facturas con filtros multiples |
| VF05N | Lista facturas (nuevo) | Version mejorada |
| VFX3 | Facturas bloqueadas | Facturas en bloqueo de contabilizacion |
| V.23 | Due list para facturacion | Entregas listas para facturar |
| F.31 | Analisis credito cliente | Estado de credito y exposicion |
| VF31 | Output de facturas | Reenvio masivo de facturas |

### Devolucion y creditos
| TCode | Report | Que muestra |
|-------|--------|-------------|
| V.14 | Lista solicitudes credito | Credit memo requests abiertas |
| V.21 | Lista notas debito | Debit memo requests abiertas |
| V.25 | Devoluciones abiertas | Retornos sin procesar |

## Sales Information System (SIS/LIS)

### Estructuras LIS para SD
| Estructura | Dimension | Descripcion |
|-----------|-----------|-------------|
| S001 | Cliente / Mes | Estadisticas ventas por cliente |
| S002 | Material / Mes | Estadisticas ventas por material |
| S003 | Org ventas / Mes | Estadisticas por organizacion |
| S004 | Oficina ventas / Mes | Estadisticas por oficina de ventas |
| S005 | Grupo de vendedores | Estadisticas por grupo ventas |
| S006 | Grupos de articulos | Estadisticas por grupo de materiales |

### Actualizacion de estructuras LIS
```
Control: SPRO → SD → Basic Functions → Statistics → Update Structure
TCode:   OMO1 (actualizar estructuras)
         OMO8 (configurar actualizacion por doc type)
         OLIV (verificar consistency)

Granularidad: diaria, semanal, mensual (configurable por estructura)
Datos: cantidad pedida, cantidad entregada, cantidad facturada, valores en moneda
```

### Tcodes de analisis MC
| TCode | Report | Dimension |
|-------|--------|-----------|
| MCTA | Analisis ventas cliente | Por cliente + periodo |
| MCTC | Analisis ventas material | Por material + periodo |
| MCTE | Analisis por org ventas | Por org + canal + sector |
| MCTG | Analisis por oficina ventas | Por oficina + vendedor |
| MC+A | Incoming orders cliente | Pedidos entrada por cliente |
| MC+E | Incoming orders material | Pedidos entrada por material |
| MC+I | Incoming orders org | Pedidos entrada por org ventas |
| MC(A | Analisis facturacion | Facturacion por cliente |
| MC(E | Facturacion material | Facturacion por material |

### Variante ALV para MCTA
```
Parametros de entrada:
  - Estructura informacion: S001
  - Periodo: 001.AAAA - 012.AAAA
  - Org ventas: 1000
  - Moneda de analisis: EUR

Campos clave en resultado:
  KUNNR, NAME1    (cliente)
  ANETWR          (neto facturado)
  EMEINS          (qty pedida)
  LFIMG           (qty entregada)
  FKIMG           (qty facturada)
```

## KPIs clave de SD

### Operativos
| KPI | Formula | Objetivo |
|-----|---------|----------|
| Order intake | Pedidos nuevos / periodo (valor neto) | Tendencia positiva |
| Revenue | Facturacion neta del periodo | vs. plan |
| Delivery performance (OTIF) | Entregas a tiempo y completas / Total * 100 | >95% |
| Billing accuracy | Facturas sin reclamacion / Total * 100 | >98% |
| Returns rate | Devoluciones / Ventas * 100 | <2% |
| Credit utilization | Credito usado / Limite credito * 100 | <80% |
| Order fulfillment cycle | Fecha entrega - Fecha pedido (dias) | Reducir |
| Backlog coverage | Pedidos abiertos / Capacidad de entrega | Equilibrar |

### Financieros
| KPI | Formula | Objetivo |
|-----|---------|----------|
| Revenue per customer | Total facturacion / Clientes activos | Maximizar |
| Average order value | Total pedidos / Numero pedidos | Maximizar |
| DSO (Days Sales Outstanding) | AR / Ventas diarias promedio | Minimizar |
| Discount rate | Descuentos otorgados / Bruto * 100 | Controlar |

## Queries MCP — Tablas principales

### Tabla de referencia SD
| Tabla | Contenido |
|-------|-----------|
| VBAK | Cabecera pedido de venta |
| VBAP | Posicion pedido de venta |
| VBFA | Flujo de documentos SD |
| LIKP | Cabecera de entrega |
| LIPS | Posicion de entrega |
| VBRK | Cabecera de factura |
| VBRP | Posicion de factura |
| KNKK | Datos credito cliente (ECC) |
| KNA1 | Datos generales cliente |
| KNVV | Datos cliente por org ventas |

### Queries para KPIs

```sql
-- Order intake del periodo (pedidos nuevos)
SELECT VBAK.VKORG, VBAK.VTWEG, VBAK.SPART,
       SUM(VBAP.NETWR) as VALOR_PEDIDOS,
       COUNT(DISTINCT VBAK.VBELN) as NUM_PEDIDOS
FROM VBAK
JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
WHERE VBAK.AUART = 'OR'
  AND VBAK.AUDAT BETWEEN '{desde}' AND '{hasta}'
  AND VBAK.VKORG = '{vkorg}'
  AND VBAP.ABGRU = ''
GROUP BY VBAK.VKORG, VBAK.VTWEG, VBAK.SPART
ORDER BY VALOR_PEDIDOS DESC

-- Revenue por cliente (facturacion del periodo)
SELECT VBRK.KUNAG, KNA1.NAME1,
       SUM(VBRP.NETWR) as FACTURACION_NETA,
       COUNT(DISTINCT VBRK.VBELN) as NUM_FACTURAS
FROM VBRK
JOIN VBRP ON VBRK.VBELN = VBRP.VBELN
JOIN KNA1 ON VBRK.KUNAG = KNA1.KUNNR
WHERE VBRK.VKORG = '{vkorg}'
  AND VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
  AND VBRK.FKART IN ('F2','F8')
  AND VBRK.RFBSK = 'C'
GROUP BY VBRK.KUNAG, KNA1.NAME1
ORDER BY FACTURACION_NETA DESC

-- Revenue por material (top productos)
SELECT VBRP.MATNR, MAKT.MAKTX,
       SUM(VBRP.NETWR) as FACTURACION,
       SUM(VBRP.FKIMG) as CANTIDAD
FROM VBRP
JOIN VBRK ON VBRP.VBELN = VBRK.VBELN
JOIN MAKT ON VBRP.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'E'
WHERE VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
  AND VBRK.VKORG = '{vkorg}'
  AND VBRK.RFBSK = 'C'
GROUP BY VBRP.MATNR, MAKT.MAKTX
ORDER BY FACTURACION DESC

-- Backlog de pedidos (pedidos abiertos sin facturar)
SELECT VBAK.VBELN, VBAK.AUDAT, VBAK.KUNNR, KNA1.NAME1,
       VBAP.POSNR, VBAP.MATNR, VBAP.KWMENG, VBAP.NETWR,
       VBAP.EDATU as FECHA_ENTREGA
FROM VBAK
JOIN VBAP ON VBAK.VBELN = VBAP.VBELN
JOIN KNA1 ON VBAK.KUNNR = KNA1.KUNNR
WHERE VBAK.VKORG = '{vkorg}'
  AND VBAP.GBSTA <> 'C'
  AND VBAP.ABGRU = ''
  AND VBAP.LFSTA <> 'C'
ORDER BY VBAP.EDATU ASC

-- Entregas atrasadas (PGI no realizado despues de fecha comprometida)
SELECT LIKP.VBELN, LIKP.ERDAT, LIKP.KUNNR, KNA1.NAME1,
       LIPS.MATNR, LIPS.LFIMG,
       LIKP.WADAT as FECHA_MERCANCIAS,
       LIKP.TRSPT
FROM LIKP
JOIN LIPS ON LIKP.VBELN = LIPS.VBELN
JOIN KNA1 ON LIKP.KUNNR = KNA1.KUNNR
WHERE LIKP.VKORG = '{vkorg}'
  AND LIKP.WADAT < '{hoy}'
  AND LIKP.WBSTK <> 'C'
ORDER BY LIKP.WADAT ASC

-- Returns rate (devoluciones vs ventas)
SELECT
  (SELECT SUM(VBRP.NETWR) FROM VBRP JOIN VBRK ON VBRP.VBELN = VBRK.VBELN
   WHERE VBRK.FKART IN ('RE','G2') AND VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
   AND VBRK.VKORG = '{vkorg}') as DEVOLUCIONES,
  (SELECT SUM(VBRP.NETWR) FROM VBRP JOIN VBRK ON VBRP.VBELN = VBRK.VBELN
   WHERE VBRK.FKART = 'F2' AND VBRK.FKDAT BETWEEN '{desde}' AND '{hasta}'
   AND VBRK.VKORG = '{vkorg}') as VENTAS

-- Clientes con mayor credito utilizado
SELECT KNKK.KUNNR, KNA1.NAME1,
       KNKK.KLIMK as LIMITE_CREDITO,
       KNKK.SKFOR as CREDITO_USADO,
       (KNKK.SKFOR / KNKK.KLIMK * 100) as PCT_UTILIZADO
FROM KNKK
JOIN KNA1 ON KNKK.KUNNR = KNA1.KUNNR
WHERE KNKK.KKBER = '{kkber}'
  AND KNKK.KLIMK > 0
ORDER BY PCT_UTILIZADO DESC

-- Pedidos incompletos (log)
SELECT VBAK.VBELN, VBAK.AUDAT, VBAK.KUNNR, KNA1.NAME1,
       VBAK.AUART, VBAK.GBSTK
FROM VBAK
JOIN KNA1 ON VBAK.KUNNR = KNA1.KUNNR
WHERE VBAK.VKORG = '{vkorg}'
  AND VBAK.GBSTK = 'A'
  AND VBAK.AUDAT BETWEEN '{desde}' AND '{hasta}'
-- GBSTK = A (general processing incomplete)

-- Flujo de documentos (pedido → entrega → factura)
SELECT VBFA.VBELV, VBFA.VBELN, VBFA.VBTYP_N, VBFA.ERDAT
FROM VBFA
WHERE VBFA.VBELV = '{pedido}'
ORDER BY VBFA.ERDAT
-- VBTYP_N: J=delivery, M=invoice, N=credit memo
```

## CDS Views analiticas (S/4HANA)

| CDS View | Contenido |
|----------|-----------|
| I_SalesOrder | Cabeceras de pedidos de venta |
| I_SalesOrderItem | Items de pedidos de venta |
| I_BillingDocument | Cabeceras de facturas |
| I_BillingDocumentItem | Items de facturas |
| I_DeliveryDocument | Cabeceras de entregas |
| I_DeliveryDocumentItem | Items de entregas |
| I_CustomerCreditExposure | Exposicion credito por cliente |
| C_SalesOrderItemQuery | Query analitica de items de pedido |
| C_BillingDocumentQuery | Query analitica de facturas |

### Queries MCP para CDS
```
ReadView("I_SalesOrder")              -- Estructura cabecera pedido
ReadView("I_SalesOrderItem")          -- Estructura posicion pedido
ReadView("I_BillingDocumentItem")     -- Estructura posicion factura
ReadView("C_SalesOrderItemQuery")     -- Query analitica pedidos
SearchObject("I_Sales*")              -- Todas las CDS de ventas
SearchObject("C_Billing*Query")       -- Queries analiticas facturacion
```

## Fiori Analytical Apps (S/4HANA)

| App | ID | Descripcion |
|-----|-----|-------------|
| Sales Order Fulfillment | F1814 | Monitor integral de cumplimiento de pedidos |
| Billing Document Analysis | F2548 | Analisis de facturas y revenue |
| Customer Returns | F2391 | Analisis de devoluciones por cliente |
| Sales Performance | F2201 | KPIs de performance de ventas |
| Credit Exposure | F1583 | Exposicion de credito por cliente |
| Incoming Sales Orders | F2643 | Pedidos recibidos (order intake) |
| Delivery Performance | F2647 | Performance de entregas OTIF |

### Acceso a Fiori apps en S/4HANA
```
SAP Fiori Launchpad → Role SD_ANALYTICS o SD_MONITOR
O via NWBC → Fiori Apps

Catalogo tiles:
  SAP_SD_BC_SALES_ANALYTICS    (analitica ventas)
  SAP_SD_BC_SHIPPING_MONITOR   (monitor envios)
  SAP_SD_BC_BILLING_ANALYTICS  (analitica facturacion)
```

## Logistics Cockpit Reports

### Reports del cockpit de logistica
```
Ruta: Logistics → Sales and Distribution → Sales → Reports

Principales:
  - VB(S) → Customizing report builder (builder de reports custom SIS)
  - MC01 → Crear key figure (cifras clave custom para LIS)
  - MCSI → Actualizar estadisticas manualmente
  - MC21 → Crear planning hierarchy
```

### Variantes ALV recomendadas para VA05
```
Campos utiles:
  VBELN, AUART, KUNNR, NAME1, AUDAT, EDATU (fecha entrega deseada)
  NETWR (valor neto), WAERK (moneda), VKORG, VTWEG, SPART
  GBSTK (estado general), LFSTK (estado entrega), FKSTK (estado factura)

Filtros comunes:
  - Solo pedidos OR abiertos (GBSTK <> 'C')
  - Solo una org de ventas
  - Rango de fechas AUDAT
  - Un cliente especifico
  - Estado entrega = 'A' o 'B' (parcial/sin entregar)
```

### Variantes ALV recomendadas para VL06O
```
Campos utiles:
  VBELN, KUNNR, NAME1, ERDAT, WADAT (fecha mercancias)
  LFART (tipo entrega), VSTEL (punto expedicion)
  WBSTK (estado GI), PKSTK (estado picking)

Filtros comunes:
  - Estado PGI = ' ' (sin GI)
  - Fecha mercancias vencida
  - Solo un almacen/punto expedicion
```
