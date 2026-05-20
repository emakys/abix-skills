# MRP — Planificacion de Necesidades en Detalle

## Concepto

MRP (Material Requirements Planning) calcula automaticamente:
- Que materiales se necesitan
- Cuanto se necesita (cantidad)
- Cuando se necesita (fecha)
- Genera propuestas: solicitudes pedido o ordenes previsionales

## Transacciones principales

| TCode | Accion |
|-------|--------|
| MD01 | MRP total (todos los materiales de un centro) |
| MD02 | MRP individual (un material) |
| MD03 | MRP individual interactivo |
| MD04 | Lista MRP (stock/requirements list) — LA MAS IMPORTANTE |
| MD05 | Lista MRP individual |
| MD06 | Lista MRP colectiva |
| MD07 | Resumen de planificacion |
| MD11 | Crear orden previsional manual |
| MD16 | Convertir ordenes previsionales en PO |
| MDBT | MRP en background |
| MD20 | Crear PIR (planned independent requirement) |
| MD61 | Crear PIR (interactivo) |
| MD73 | Resumen excepciones MRP |

## Tipos de MRP (MARC-DISMM)

| Tipo | Nombre | Como funciona | Cuando usar |
|------|--------|--------------|-------------|
| PD | MRP planificado | Calcula necesidad neta vs demanda | Materiales con BOM, produccion planificada |
| VB | Punto de pedido | Genera propuesta cuando stock < punto pedido | Materiales de consumo regular |
| VV | Punto pedido automatico | Sistema calcula punto pedido por consumo historico | Materiales sin forecast |
| V1 | Punto pedido auto + MRP manual | Combina VV con planificacion | Materiales hibridos |
| V2 | Punto pedido auto + MRP auto | Completo automatico | Materiales criticos |
| ND | Sin MRP | No genera propuestas | Servicios, materiales obsoletos |
| — | No planificado | Campo vacio = sin MRP | Default |

## Parametros MRP clave (MARC)

| Campo | Descripcion | Impacto |
|-------|-------------|---------|
| DISMM | Tipo MRP | PD, VB, VV, ND |
| DISPO | Planificador MRP | Responsable (T024D) |
| DISLS | Tamano de lote | EX=exacto, FX=fijo, WB=semanal, MB=mensual |
| DISGR | MRP Group | Parametros adicionales de planificacion |
| MINBE | Punto de pedido | Stock minimo que dispara reorder |
| EISBE | Safety stock | Stock de seguridad |
| PLIFZ | Planned delivery time (dias) | Lead time del proveedor |
| WEBAZ | GR processing time (dias) | Tiempo de recepcion |
| FHORI | Planning time fence (dias) | Horizonte firme (no replannear) |
| BSTMI | Lote minimo | Cantidad minima de pedido |
| BSTMA | Lote maximo | Cantidad maxima de pedido |
| BSTFE | Lote fijo | Cantidad fija de pedido |
| BESKZ | Procurement type | E=compra, F=produccion, X=ambos |
| SOBSL | Special procurement | 10=consignacion, 20=subcontratacion, 30=STO |

## Tamanos de lote (DISLS)

| Codigo | Nombre | Descripcion |
|--------|--------|-------------|
| EX | Lote exacto | Genera exactamente la cantidad necesaria |
| FX | Lote fijo | Siempre pide BSTFE unidades |
| HB | Lote a lote rounding | Redondea al empaque |
| TB | Lote diario | Agrupa necesidades del dia |
| WB | Lote semanal | Agrupa necesidades de la semana |
| MB | Lote mensual | Agrupa necesidades del mes |
| WO | Optimized lot (Wagner-Whitin) | Minimiza costes pedido+almacen |
| SP | Part-period balancing | Equilibra coste pedido vs holding |

## Ecuacion basica MRP

```
Necesidad neta = Demanda - (Stock disponible + Ordenes pendientes - Safety stock)

Si necesidad neta > 0 → generar propuesta (PR o planned order)

Demanda:
  + PIR (planned independent requirements)
  + Reservas (ordenes produccion)
  + Pedidos de venta (SD)
  + Forecast (pronostico)

Oferta:
  + Stock libre (LABST)
  + POs pendientes de GR
  + Ordenes previsionales existentes
  + Solicitudes pedido existentes
  - Safety stock (EISBE) — se reserva

Ejemplo:
  Demanda: 100 unidades (PIR)
  Stock: 30
  PO pendiente: 20
  Safety stock: 10
  Necesidad neta: 100 - (30 + 20 - 10) = 60 → generar PR por 60
```

## Excepciones MRP (MD06/MD73)

| Exception | Codigo | Significado | Accion |
|-----------|--------|-------------|--------|
| Reprogramar adelante | 07 | PO/PR llega tarde, mover hacia adelante | Confirmar o ajustar fecha |
| Reprogramar atrasar | 06 | PO/PR llega antes de necesario | Posponer o cancelar |
| Cancelar | 08 | Propuesta ya no necesaria | Eliminar PR/planned order |
| Stock bajo safety stock | 01 | Stock caera debajo de seguridad | Crear PO urgente |
| Stock cero | 02 | Stock llegara a 0 | Accion urgente |
| Exceso de stock | 10 | Mas stock del necesario | Reducir o transferir |
| Plazo entrega no alcanzable | 20 | Lead time insuficiente | Negociar con proveedor |

## MRP Run — Parametros de ejecucion (MD01)

```
Processing key:
  NETCH = Net change (solo materiales con cambios) — el mas usado diario
  NETPL = Net change in planning horizon (mas rapido)
  NEUPL = Regenerative (todos los materiales) — fin de semana

Create PR: 1 = solicitudes pedido
Create planned orders: 2 = ordenes previsionales
Planning mode: 3 = delete and recreate / 1 = adapt

MRP Lists: 1 = crear listas MRP para revision
```

## Forecast / Pronostico (MP30/MP38)

```
MP30 → Pronostico individual por material
MP38 → Pronostico masivo
MP39 → Reprocessing forecast

Modelos:
  - Constant: demanda estable
  - Trend: demanda con tendencia
  - Seasonal: demanda estacional
  - Croston: demanda intermitente (repuestos)

Resultado: valores de consumo pronosticados → alimentan MRP como PIR
Config: MARC-PRESSION (forecast profile)
```

## Queries MCP

```sql
-- Parametros MRP de un material
SELECT MATNR, WERKS, DISMM, DISPO, DISLS, MINBE, EISBE,
       PLIFZ, WEBAZ, BESKZ, SOBSL, BSTMI, BSTMA, BSTFE
FROM MARC WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Planificadores MRP configurados
SELECT WERKS, DESSION, DSNAM FROM T024D WHERE WERKS = '{centro}'

-- MRP groups
SELECT DISGR, DITXT FROM T438M WHERE SPRAS = 'E'

-- Solicitudes pedido generadas por MRP (automaticas)
SELECT BANFN, BNFPO, MATNR, MENGE, LFDAT, BSART, ESTKZ
FROM EBAN WHERE ESTKZ = 'B' AND WERKS = '{centro}' AND LOEKZ = ''
-- ESTKZ='B' = generada automaticamente por MRP

-- Stock + demanda actual de un material
SELECT MATNR, WERKS, LABST, INSME, SPEME, TRAME
FROM MARC WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

## Errores comunes MRP

| Error/Problema | Causa | Fix |
|----------------|-------|-----|
| MD 205 MRP type not maintained | MARC-DISMM vacio | MM02 → MRP1 asignar |
| MD 045 MRP controller not defined | MARC-DESSION vacio | MM02 → MRP1 asignar, T024D config |
| No genera propuestas | Safety stock = 0, sin demanda | Revisar PIR (MD61) y parametros |
| Demasiadas propuestas | Tamano lote EX con demanda diaria | Cambiar a WB o MB |
| Fechas imposibles | Lead time > horizonte demanda | Ajustar PLIFZ o negociar |
| MRP no corre | MRP area no activa | SPRO activar planning run |
