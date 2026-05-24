# Reporting y Analitica PP

## SAP GUI — Transacciones de reporting

### Ordenes de produccion

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| COOIS | Lista informativa ordenes | Vista principal de ordenes con filtros avanzados |
| CO04 | Lista ordenes (tree) | Vista arbol por centro/tipo/status |
| CO03 | Visualizar orden individual | Detalle completo de una orden |
| CO14 | Lista confirmaciones | Confirmaciones por orden/periodo |
| CO24 | Lista faltantes | Componentes no disponibles |
| CO46 | Lista ordenes preliberacion | Ordenes pendientes de liberar |

### MRP / Planificacion

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| MD04 | Lista stock/necesidades | Vista central planificacion por material |
| MD05 | Lista MRP individual | Resultado MRP con mensajes excepcion |
| MD06 | Lista MRP colectiva | Multiples materiales |
| MD07 | Evaluacion general MRP | Resumen por planificador |
| MD73 | Evaluacion PIR | Necesidades independientes |
| MDLD | Display MRP list | Lista MRP guardada |

### Capacidad

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| CM01 | Carga puesto trabajo | Grafico carga vs capacidad |
| CM07 | Vista general capacidad | Tabla todos puestos |
| CM21 | Perfil de carga | Barras por periodo |
| CM25 | Pool capacidades | Evaluacion pool |
| CM50 | Lista capacidad | Vista detallada |

### BOM / Routing

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| CS11 | BOM multi-nivel | Explosion completa BOM |
| CS12 | BOM multi-nivel qty | Con cantidades |
| CS13 | BOM resumida | Todos componentes en un nivel |
| CS15 | Where-used | Donde se usa un componente |
| CA80 | Lista routings | Routings por material |

### Movimientos / Stock

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| MB52 | Stock por almacen | Stock actual detallado |
| MMBE | Resumen stock | Stock por almacen/centro |
| MB51 | Lista documentos material | Historial movimientos |
| COGI | Errores auto GI/GR | Pendientes de corregir |
| CO27 | Lista faltantes (picking) | Componentes para staging |

### Costes produccion

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| CK13N | Coste estandar material | Precio estandar calculado |
| KKBC_ORD | Informe costes orden | Real vs plan por orden |
| S_ALR_87013127 | Ordenes con WIP | WIP acumulado |
| S_ALR_87013128 | Ordenes con varianzas | Desviaciones por categoria |

## Fiori Apps PP

### Planificacion y MRP

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F0917 | Monitor Material Coverage | Analytical | MD04 |
| F2873 | Schedule MRP Runs | Transactional | MD01N |
| F2874 | Monitor MRP Runs | Analytical | — |
| F1613 | Manage Planned Independent Requirements | Transactional | MD61 |
| F3059 | Material Requirements Overview | Analytical | MD07 |

### Ordenes de produccion

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F2093 | Manage Production Orders | Transactional | COOIS |
| F2428 | Manage Production Orders (extended) | Transactional | CO01/CO02 |
| F1596 | Schedule Production Orders | Transactional | — |
| F2429 | Release Production Orders | Transactional | CO05N |
| F3810 | Production Order Confirmation | Transactional | CO11N |

### Shop Floor

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F2525 | Post Goods Issue for Production Order | Transactional | MIGO 261 |
| F2526 | Post Goods Receipt for Production Order | Transactional | MIGO 101 |
| F3523 | Manage Production Operations | Transactional | — |
| F2767 | Process Manufacturing Orders | Transactional | COR2 |

### Capacidad

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F3814 | Monitor Capacity Load | Analytical | CM01 |
| F3815 | Evaluate Capacity Load | Analytical | CM07 |

### BOM y Routing

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F1595 | Manage Bill of Materials | Transactional | CS02 |
| F2766 | Manage Production Routing | Transactional | CA02 |
| F3058 | Manage Production Version | Transactional | C223 |

### Analisis

| App ID | Nombre | Tipo | Equivalente |
|--------|--------|------|-------------|
| F2094 | Production Order Analysis | Analytical | KKBC_ORD |
| F3057 | Production Order Cost Analysis | Analytical | — |
| F4392 | Scrap Analysis for Production | Analytical | — |
| F3056 | Production Plan vs Actual | Analytical | — |

## CDS Views para reporting custom

| CDS View | Descripcion |
|----------|-------------|
| I_ProductionOrder | Orden produccion |
| I_ProductionOrderItem | Posiciones |
| I_ProductionOrderOperation | Operaciones |
| I_ProductionOrderComponent | Componentes |
| I_ProductionOrderConfirmation | Confirmaciones |
| I_MRPElement | Elementos MRP |
| I_PlannedOrder | Ordenes previsionales |
| I_MaterialStock | Stock por material |
| I_BillOfMaterial | BOM |
| I_WorkCenter | Puestos trabajo |

## Consultas MCP para reporting

```sql
-- Ordenes por status (resumen)
SELECT AUART, COUNT(*) AS CANTIDAD
FROM AFKO WHERE WERKS = '{centro}' AND GSTRP BETWEEN '{ini}' AND '{fin}'
GROUP BY AUART

-- Rendimiento por material (yield vs scrap)
SELECT K.PLNBEZ, SUM(R.LMNGA) AS YIELD, SUM(R.XMNGA) AS SCRAP
FROM AFKO K INNER JOIN AFRU R ON K.AUFNR = R.AUFNR
WHERE K.WERKS = '{centro}' AND R.STESSION = ''
GROUP BY K.PLNBEZ

-- Lead time real promedio
SELECT PLNBEZ, AVG(JULIANDAY(GLTRP) - JULIANDAY(GSTRP)) AS AVG_LEADTIME
FROM AFKO WHERE WERKS = '{centro}'
GROUP BY PLNBEZ
```
