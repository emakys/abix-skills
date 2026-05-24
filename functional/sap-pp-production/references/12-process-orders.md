# Ordenes de Proceso (PP-PI)

## Concepto

PP-PI (Production Planning for Process Industries) se usa en industrias de proceso: quimica, farmaceutica, alimentos, bebidas. En lugar de routing usa **master recipe**, en lugar de work centers usa **resources**.

## Diferencias PP discreto vs PP-PI

| Aspecto | PP Discreto | PP-PI |
|---------|-------------|-------|
| Routing | Hoja de ruta (PLKO/PLPO) | Master recipe (PLKO type 2) |
| Work center | Puesto trabajo (CRHD type A) | Resource (CRHD type D) |
| Orden | Orden produccion (CO01) | Orden proceso (COR1) |
| BOM | Misma (CS01) | Misma (CS01) |
| Confirmacion | CO11N/CO15 | COR6N |
| Batch | Opcional | Casi siempre obligatorio |
| Parametros proceso | No | Si (instrucciones PI, PI sheets) |

## Master Recipe

- Tipo routing: PLNTY = '2'
- Contiene: operaciones (fases) + asignacion recursos + parametros proceso
- Transacciones: C201 (crear), C202 (modificar), C203 (visualizar)

```sql
SELECT PLNTY, PLNNR, PLNAL, WERKS, KTEXT, STATU
FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = '2'
```

## Resources (Recursos)

- Tipo CRHD-OBJTY = 'D'
- Representan: reactores, tanques, mezcladores, lineas de llenado
- Pueden tener capacidad por volumen/peso (no solo tiempo)

```sql
SELECT OBJID, ARBPL, WERKS FROM CRHD
WHERE WERKS = '{centro}' AND OBJTY = 'D'
```

## Orden de proceso

| TCode | Descripcion |
|-------|-------------|
| COR1 | Crear orden proceso |
| COR2 | Modificar orden proceso |
| COR3 | Visualizar orden proceso |
| COR5 | Liberar colectivo |
| COR6N | Confirmacion orden proceso |
| COR8 | Conversion previsional → proceso |
| CORK | Lista ordenes proceso |

### Tablas (mismas que PP discreto)
- AFKO: Cabecera (AUART = PP02 tipicamente)
- AFPO: Posiciones
- AFVC: Operaciones (fases)
- RESB: Reservas componentes

## Gestion de lotes (Batch Management)

Fundamental en PP-PI para trazabilidad:

| Tabla | Descripcion |
|-------|-------------|
| MCHA | Lotes material |
| MCH1 | Lotes (nivel centro) |
| MCHB | Stock por lote |
| INOB | Link a clasificacion |

```sql
-- Lotes de un material
SELECT MATNR, WERKS, CHARG, HSDAT, VFDAT FROM MCHB
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND CLABS > 0
```

### Determinacion de lotes
- Busqueda automatica segun clasificacion
- SPRO: estrategia de busqueda lotes
- Batch where-used: MB56

## Process Instructions (PI)

- Instrucciones para operadores en planta
- PI Sheets: formularios electronicos para registro de datos de proceso
- Integradas con control de proceso (PP-PI-PMA)
- Pueden conectar a sistemas SCADA/MES

## Control Recipe

Cuando la orden de proceso se libera, genera un **control recipe** que contiene:
- Instrucciones de proceso
- Parametros operativos
- Puntos de control
- Se envia a sistema de control de planta

## Transacciones adicionales PP-PI

| TCode | Descripcion |
|-------|-------------|
| C201 | Crear master recipe |
| C202 | Modificar master recipe |
| C203 | Visualizar master recipe |
| C223 | Version fabricacion |
| POIT | PI Sheet |
| POCO | Control recipe monitor |
| CORA | Evaluacion ordenes proceso |

## Consultas MCP diagnostico

```sql
-- Master recipes de un material
SELECT PLNTY, PLNNR, PLNAL, STATU, KTEXT FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = '2'

-- Recursos PP-PI de un centro
SELECT OBJID, ARBPL, WERKS FROM CRHD WHERE WERKS = '{centro}' AND OBJTY = 'D'

-- Ordenes proceso abiertas
SELECT A.AUFNR, A.AUART, A.PLNBEZ, A.GAMNG, A.GSTRP, A.GLTRP
FROM AFKO A
WHERE A.WERKS = '{centro}' AND A.AUART = 'PP02'
```
