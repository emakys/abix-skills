# MRP — Material Requirements Planning

## Concepto

MRP calcula necesidades netas de material comparando demanda (necesidades) con oferta (stock + recepciones) y genera propuestas de aprovisionamiento (ordenes previsionales, solicitudes de pedido).

## Flujo MRP

```
Necesidades independientes (PIR)
+ Pedidos venta / Reservas
= Necesidad bruta
- Stock disponible
- Recepciones previstas (OC, OP abiertas)
= Necesidad neta
→ Propuesta: Orden previsional (BESKZ=E) o Sol. pedido (BESKZ=F)
→ Explosion BOM → MRP componentes (recursivo)
```

## Tipos de ejecucion MRP

| TCode | Tipo | Descripcion |
|-------|------|-------------|
| MD01 | Total | MRP completo para un centro |
| MD02 | Individual | MRP para un material individual |
| MD03 | Individual online | MRP interactivo |
| MDBT | Background | MRP en proceso de fondo |
| MD01N | Total (nuevo) | MRP con mejoras rendimiento |

### Parametros clave MD01/MD02

| Parametro | Descripcion | Valores |
|-----------|-------------|---------|
| Scope | Alcance planificacion | NETCH (net change), NEUPL (regenerative), NETPL (net change horizon) |
| Create PurchReq | Crear sol. pedido | 1=sol.pedido, 2=previsional, 3=schedule lines |
| Schedule lines | Crear repartos | 1=si, 2=no |
| Create MRP list | Crear lista MRP | 1=si, 2=no |
| Planning mode | Modo | 1=adapt, 2=re-explode BOM, 3=delete+recreate |
| Scheduling | Programacion | 1=basic dates, 2=lead time scheduling |

## Net Change vs Regenerative

| Modo | Codigo | Descripcion |
|------|--------|-------------|
| NETCH | Net change | Solo materiales con cambios (MDKP-NESSION ≠ '') |
| NEUPL | Regenerative | Todos los materiales del centro |
| NETPL | Net change in planning horizon | Net change dentro del horizonte |

## Tablas MRP

| Tabla | Descripcion |
|-------|-------------|
| MDKP | Cabecera lista MRP / stock-requirements |
| MDTB | Elementos de planificacion (lineas MD04) |
| MDVM | Parametros planificacion material |
| MDFD | Fechas MRP |
| MDLG | Stock segmentado MRP |
| PLAF | Ordenes previsionales |
| BANFN/EBAN | Solicitudes de pedido (si BESKZ=F) |

## PLAF — Ordenes previsionales

```sql
SELECT PLNUM, MATNR, WERKS, GESSION, PLAUF, PEDKZ,
       FLESSION, PAESSION, UMESSION, PESSION, AUFNR
FROM PLAF
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PESSION = ''
```

| Campo | Descripcion |
|-------|-------------|
| PLNUM | Numero previsional |
| GESSION | Cantidad planificada |
| FLESSION | Fecha inicio planificada |
| PAESSION | Fecha fin planificada |
| PEDKZ | Convertida (X=si) |
| UMESSION | Convertida a |
| AUFNR | Orden produccion resultante |
| PLAUF | Firme (X=si, no se borra en re-run) |

## MD04 — Lista stock/necesidades

Vista central de planificacion. Muestra todos los elementos MRP para un material/centro.

### Elementos tipicos MD04

| Elemento | Codigo | Tipo |
|----------|--------|------|
| Stock | Stock | Oferta |
| PIR (necesidad indep.) | VorBd | Demanda |
| Pedido venta | KdAuf | Demanda |
| Orden previsional | PlAuf | Oferta (propuesta) |
| Orden produccion | FerAu | Oferta |
| Orden compra | BestE | Oferta |
| Solicitud pedido | BAnfr | Oferta (propuesta) |
| Reserva | MtRes | Demanda |
| Reserva dependiente | DepBd | Demanda |

## Necesidades independientes (PIR) — MD61

```sql
SELECT MATNR, WERKS, BEDAE, VERSB, PDATU, GESSION
FROM PBIM
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

- MD61: Crear PIR
- MD62: Modificar PIR
- MD63: Visualizar PIR
- Version activa (VERSB=00) vs inactiva

## Conversion de ordenes previsionales

| TCode | Tipo | Descripcion |
|-------|------|-------------|
| CO40 | Individual | Previsional → Orden produccion |
| CO41 | Colectiva | Multiples previsionales → Ordenes produccion |
| ME59N | Colectiva | Previsional → Sol. pedido (BESKZ=F) |

## Parametros MRP criticos (MARC)

```
DISMM = PD → MRP determinista (basado en necesidades)
DISPO = 001 → Planificador MRP
DISLS = EX → Lote exacto
BESKZ = E → Fabricacion propia
SOBSL = '' → Sin aprovisionamiento especial
PLIFZ = 5 → Delivery time 5 dias
DZEIT = 3 → In-house production 3 dias
STRGR = 10 → Strategy group MTS
VRMOD = 1 → Backward consumption
```

## MRP Live (S/4HANA)

- MD01N reemplaza MD01 con mejoras de rendimiento
- Usa HANA in-memory para calculo paralelo
- Compatible con DDMRP
- Fiori: app F0917 (Monitor Material Coverage)

## Mensajes excepcion MRP

| Tipo | Descripcion | Accion |
|------|-------------|--------|
| Bring forward | Adelantar recepcion | Mover fecha orden |
| Postpone | Postergar recepcion | Mover fecha orden |
| Cancel | Cancelar propuesta | No se necesita |
| Increase | Aumentar cantidad | Ajustar orden |
| Decrease | Reducir cantidad | Ajustar orden |
| New | Nueva propuesta | Crear orden/pedido |
| Reschedule | Reprogramar | Ajustar fechas |

## Consultas MCP diagnostico

```sql
-- Estado MRP de un material
SELECT MATNR, WERKS, DISMM, DISPO, DISLS, BESKZ, EISBE, MINBE, STRGR
FROM MARC WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Ordenes previsionales abiertas
SELECT PLNUM, GESSION, FLESSION, PAESSION FROM PLAF
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PEDKZ = ''

-- Reservas dependientes abiertas
SELECT RSPOS, MATNR, BDMNG, ENMNG, AUFNR FROM RESB
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND KZEAR = '' AND XLOEK = ''
```
