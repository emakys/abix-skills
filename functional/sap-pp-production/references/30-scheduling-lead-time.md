# Scheduling y Lead Time

## Tipos de scheduling

### Basic Date Scheduling
- Usa solo MARC-DZEIT (in-house production time) como lead time total
- No considera operaciones individuales
- Rapido pero impreciso
- Usado por MRP cuando no hay routing

### Lead Time Scheduling
- Calcula fecha de cada operacion basada en routing
- Considera: setup, machine time, labor, interoperation times, queue times
- Mas preciso, requiere routing completo
- Usado por ordenes de produccion (CO01/CO02)

## Componentes del lead time

```
Lead Time Total
├── Queue time (tiempo en cola antes de operacion)
├── Setup time (preparacion maquina)
├── Processing time (tiempo de proceso = machine × qty / base qty)
├── Teardown time (desmontaje)
├── Wait time (tiempo espera despues)
├── Move time (transporte entre operaciones)
└── Float (margen de seguridad)
```

### Calculo detallado por operacion

```
Duracion operacion = Queue + Setup + (Machine × Qty/BaseQty) + Teardown + Wait + Move
                   = Queue + VGW01 + (VGW02 × GAMNG/BMSCH) + Teardown + Wait + Move
```

### Floats (margenes)

| Float | Tabla | Descripcion |
|-------|-------|-------------|
| Before production | T436A-VESSION | Antes de primera operacion |
| After production | T436A-NESSION | Despues de ultima operacion |
| Interoperation | T436B | Entre operaciones |

## Direccion del scheduling

### Backward scheduling (mas comun)
```
Fecha entrega requerida (fin)
← Float after production
← Ultima operacion (duration)
← Move time
← Penultima operacion (duration)
← ...
← Primera operacion (duration)
← Float before production
= Fecha inicio calculada

Si fecha inicio < hoy → forward scheduling automatico (o mensaje excepcion)
```

### Forward scheduling
```
Fecha inicio (hoy o definida)
→ Float before production
→ Primera operacion (duration)
→ Move time
→ Segunda operacion (duration)
→ ...
→ Ultima operacion (duration)
→ Float after production
= Fecha fin calculada
```

### Midpoint scheduling
- Desde una operacion de referencia en ambas direcciones
- Util cuando una operacion tiene restriccion de fecha

## In-House Production Time (MARC-DZEIT)

Tiempo total simplificado para MRP basic date scheduling:
- Se mantiene en MM02 → Work Scheduling
- Unidad: dias laborales
- Incluye TODO: cola, setup, proceso, transporte
- MRP usa este valor cuando scheduling = basic dates

### Formula lead time en MRP
```
Fecha inicio = Fecha necesidad - DZEIT - GR processing time (WEBAZ) - Float
```

## Calendario de fabrica (SCAL)

- Define dias laborales por centro
- T001W-FABKL asigna calendario al centro
- Scheduling ignora dias no laborales
- Si operacion cruza fin de semana → se extiende al siguiente dia laboral

## Scheduling en MRP vs Orden

| Aspecto | MRP (MD01) | Orden (CO01) |
|---------|------------|--------------|
| Basic dates | MARC-DZEIT | Opcional |
| Lead time sched. | Si routing existe | Si (default) |
| Finite | No (infinite) | Solo con PP/DS |
| Resultado | Fechas previsional | Fechas operaciones |

## Interoperation times — T436B

| Tipo | Descripcion | Cuando |
|------|-------------|--------|
| Queue time | Espera antes de operacion | Antes de iniciar |
| Wait time | Espera despues de operacion | Despues de terminar |
| Move time | Transporte entre puestos | Entre operaciones |

```sql
-- Interoperation times configurados
SELECT * FROM T436B WHERE WERKS = '{centro}'
```

## Overlap / Splitting

### Overlap (solapamiento)
- Permite iniciar siguiente operacion antes de terminar la actual
- PLPO-UEESSION = porcentaje de overlap
- Reduce lead time total

### Splitting (particion)
- Divide una operacion en sub-lotes procesados en paralelo
- Reduce duracion de operaciones largas
- Requiere multiples recursos disponibles

## Reduccion de lead time

### Estrategias

| Estrategia | Como |
|------------|------|
| Overlap operaciones | PLPO-UEESSION |
| Splitting lotes | PLPO split indicator |
| Reducir queue times | T436B o puesto trabajo |
| Eliminar floats | T436A |
| Reducir setup | SMED, agrupacion por familia |
| Optimizar routing | Eliminar operaciones innecesarias |

## Scheduling en ordenes abiertas

### Reprogramacion
- CO02 → Menu > Functions > Scheduling
- Recalcula fechas de todas las operaciones
- Considera: confirmaciones parciales, componentes GI

### Scheduling colectivo
- COHV con funcion scheduling
- Reprograma multiples ordenes

## Consultas MCP diagnostico

```sql
-- Lead time configurado
SELECT MATNR, WERKS, DZEIT, PLIFZ, WEBAZ FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Tiempos en routing
SELECT VESSION, LTXA1, VGW01 AS SETUP, VGW02 AS MACHINE, VGW03 AS LABOR,
       BMSCH AS BASE_QTY, UEESSION AS OVERLAP
FROM PLPO WHERE PLNNR = '{routing}' ORDER BY VESSION

-- Fechas operaciones de orden
SELECT VORNR, LTXA1, FSAVD AS EARLIEST_START, FSSBD AS EARLIEST_FIN,
       SSAVD AS LATEST_START, SSSBD AS LATEST_FIN
FROM AFVC
INNER JOIN AFKO ON AFVC.AUFPL = AFKO.AUFPL
WHERE AFKO.AUFNR = '{orden}'
ORDER BY VORNR

-- Ordenes con inicio en el pasado (backward scheduling failed)
SELECT AUFNR, PLNBEZ, GSTRP, GLTRP FROM AFKO
WHERE WERKS = '{centro}' AND GSTRP < CURRENT_DATE
AND AUFNR IN (SELECT AUFNR FROM JEST WHERE OBJNR LIKE 'OR%' AND STAT = 'I0002' AND INACT = '')
```
