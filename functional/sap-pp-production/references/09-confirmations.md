# Confirmaciones de Produccion

## Concepto

La confirmacion registra el avance real de produccion: cantidades producidas, tiempos consumidos, merma. Puede disparar automaticamente movimientos de materiales (backflush, entrada de mercancias).

## Tabla principal — AFRU

```sql
SELECT RUESSION, AUFNR, VORNR, LMNGA, XMNGA, RMNGA,
       ISDD, ISDZ, IEDD, IEDZ, ISM01, ISM02, ISM03,
       STESSION, SESSION, PESSION, AUESSION
FROM AFRU
WHERE AUFNR = '{orden}'
ORDER BY RUESSION
```

| Campo | Descripcion |
|-------|-------------|
| RUESSION | Numero secuencial confirmacion |
| AUFNR | Orden produccion |
| VORNR | Numero operacion |
| LMNGA | Cantidad buena (yield) |
| XMNGA | Cantidad chatarra (scrap) |
| RMNGA | Cantidad reproceso (rework) |
| ISDD/ISDZ | Fecha/hora inicio real |
| IEDD/IEDZ | Fecha/hora fin real |
| ISM01 | Tiempo real valor 1 (setup) |
| ISM02 | Tiempo real valor 2 (machine) |
| ISM03 | Tiempo real valor 3 (labor) |
| STESSION | Storno (X=anulada) |
| AUESSION | Confirmacion final (X=si) |

## Tipos de confirmacion

| TCode | Tipo | Descripcion |
|-------|------|-------------|
| CO11N | Individual | Una operacion, una confirmacion |
| CO11 | Individual (vieja) | Interfaz anterior |
| CO12 | Colectiva hora | Multiples confirmaciones por tiempo |
| CO13 | Anulacion | Revierte una confirmacion |
| CO14 | Display confirmacion | Ver detalle |
| CO15 | Confirmacion con GR | Confirma + entrada mercancias automatica |
| CO16 | Confirmacion operacion con backflush | Con consumo automatico |

## CO11N — Confirmacion individual

### Datos a ingresar
1. Numero orden + operacion
2. Cantidad buena (yield)
3. Cantidad chatarra (scrap) + motivo chatarra
4. Tiempos reales (setup, machine, labor)
5. Fecha/hora inicio-fin
6. Confirmacion parcial o final

### Indicadores importantes
- **Confirmacion final**: marca la operacion como completamente confirmada (status CNF)
- **Auto GR**: si activado, genera entrada de mercancias (mov. 101) al confirmar ultima operacion
- **Backflush**: si componentes tienen indicador backflush, se consumen automaticamente

## CO15 — Confirmacion con entrada mercancias

Combina en una transaccion:
1. Confirmacion de la operacion (o milestone)
2. Entrada de mercancias del producto terminado (mov. 101)
3. Backflush de componentes (mov. 261) si aplica

## Motivos de chatarra — TCode: OPK3

```sql
SELECT GRUND, GESSION FROM T430 WHERE SPRAS = 'E'
```

## Status despues de confirmacion

| Situacion | Status resultante |
|-----------|-------------------|
| Confirmacion parcial | PCNF (partially confirmed) |
| Confirmacion final todas oper. | CNF (confirmed) |
| GR parcial | PDLV (partially delivered) |
| GR completa | DLV (delivered) |

## Tolerancias

### Over-delivery tolerance
- MARC-UEESSION o tipo orden
- Si yield > cantidad orden × (1 + tolerancia) → error CF 010

### Under-delivery tolerance
- Permite confirmar final con menos de la cantidad orden
- MARC-UNESSION o tipo orden

## Confirmacion automatica (milestone)

- Una operacion milestone confirma automaticamente las anteriores
- Configurado en routing: PLPO-STEUS con milestone indicator
- Util para reducir confirmaciones manuales

## Impacto de confirmaciones

### En CO (Controlling)
- Genera actividades internas (contabilizacion en ACDOCA)
- Tarifa × tiempo real = coste real operacion
- Actualiza AFVC-ISMNW01/02/03 (valores reales)

### En MM (stock)
- Backflush: mov. 261 (consumo componentes)
- GR automatica: mov. 101 (entrada producto)
- MATDOC en S/4HANA

### En QM
- Si tipo inspeccion 03 activo → genera lote inspeccion
- Cantidad scrap puede disparar notificacion calidad

## Errores frecuentes confirmacion

| Error | Causa | Solucion |
|-------|-------|----------|
| CF 010 | Yield > orden qty | Verificar tolerancia |
| No backflush | Componente sin indicador | RESB-XWAOK o CS02 |
| Sin stock GI | Stock insuficiente para backflush | Verificar MARD |
| COGI error | Error en movimiento automatico | COGI → corregir → reprocesar |
| Operacion bloqueada | Status LKD en operacion | CO02 → desbloquear |

## Consultas MCP diagnostico

```sql
-- Confirmaciones de una orden
SELECT RUESSION, VORNR, LMNGA, XMNGA, ISM01, ISM02, ISM03, ISDD, AUESSION, STESSION
FROM AFRU WHERE AUFNR = '{orden}' AND STESSION = '' ORDER BY RUESSION

-- Cantidad confirmada vs orden
SELECT K.AUFNR, K.GAMNG, SUM(R.LMNGA) AS CONFIRMADO, SUM(R.XMNGA) AS SCRAP
FROM AFKO K
INNER JOIN AFRU R ON K.AUFNR = R.AUFNR
WHERE K.AUFNR = '{orden}' AND R.STESSION = ''
GROUP BY K.AUFNR, K.GAMNG

-- Operaciones pendientes de confirmacion
SELECT V.VORNR, V.LTXA1, V.VGW01, V.VGW02, V.ISMNW01, V.ISMNW02
FROM AFVC V
INNER JOIN AFKO K ON V.AUFPL = K.AUFPL
WHERE K.AUFNR = '{orden}'
AND V.ISMNW01 = 0 AND V.ISMNW02 = 0
```
