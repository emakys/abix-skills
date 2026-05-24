# Cierre de Periodo PP

## Secuencia de cierre produccion

```
1. Reprocesar errores COGI
2. Verificar confirmaciones pendientes
3. Completar GI/GR pendientes
4. Cierre tecnico ordenes completadas (TECO)
5. Calculo WIP (KKAO)
6. Calculo overhead (CO43)
7. Calculo desviaciones (KKS1)
8. Settlement (CO88)
9. Cierre de periodo MM (MMPV)
```

## Detalle por paso

### 1. COGI — Reprocesar errores
- Verificar y corregir todos los errores de movimientos automaticos
- Prioridad maxima: si no se corrigen, costes quedan incompletos

### 2. Confirmaciones pendientes
```sql
-- Operaciones sin confirmar en ordenes liberadas
SELECT K.AUFNR, V.VORNR, V.LTXA1
FROM AFKO K
INNER JOIN AFVC V ON K.AUFPL = V.AUFPL
INNER JOIN JEST J ON J.OBJNR = CONCAT('OR', K.AUFNR)
WHERE K.WERKS = '{centro}'
AND J.STAT = 'I0002' AND J.INACT = ''
AND V.ISMNW01 = 0 AND V.ISMNW02 = 0
```

### 3. GI/GR pendientes
```sql
-- Componentes no retirados
SELECT AUFNR, MATNR, BDMNG, ENMNG FROM RESB
WHERE WERKS = '{centro}' AND KZEAR = '' AND XLOEK = ''
AND (BDMNG - ENMNG) > 0

-- Ordenes sin GR completa
SELECT K.AUFNR, K.PLNBEZ, K.GAMNG, P.WEMNG
FROM AFKO K INNER JOIN AFPO P ON K.AUFNR = P.AUFNR
WHERE K.WERKS = '{centro}' AND P.ELIKZ = '' AND P.WEMNG < K.GAMNG
```

### 4. Cierre tecnico (TECO)
- CO02 individual o COHV colectivo
- TECO impide mas movimientos/confirmaciones
- Reservas pendientes se anulan
- Compromisos se liberan

### 5. Calculo WIP — KKAO
- Calcula Work in Process para ordenes abiertas (no TECO/DLV)
- WIP = Costes acumulados - Entregas (a estandar)
- Genera contabilizacion en balance

| TCode | Descripcion |
|-------|-------------|
| KKAO | WIP colectivo |
| KKAX | WIP individual |

### 6. Overhead — CO43
- Aplica recargos indirectos a ordenes produccion
- Segun costing sheet configurado en tipo orden
- Genera cargo adicional en la orden

### 7. Desviaciones — KKS1
- Solo para ordenes con status DLV o TECO
- Compara coste real vs coste estandar
- Categorias: precio, cantidad, lote, merma, remaining

| TCode | Descripcion |
|-------|-------------|
| KKS1 | Varianzas colectivo |
| KKS2 | Varianzas individual |

### 8. Settlement — CO88
- Liquida saldos de la orden a receptores
- Tipicamente: varianzas → cuentas de resultado
- WIP → cuentas de balance
- Regla de liquidacion en AUFK (COBRB)

| TCode | Descripcion |
|-------|-------------|
| CO88 | Settlement colectivo |
| KO88 | Settlement individual |

### 9. Cierre periodo MM — MMPV
- Cierra periodo de materiales
- Impide movimientos en periodo cerrado
- Debe hacerse DESPUES del cierre PP

## Checklist cierre PP

```
[ ] COGI limpio (sin errores pendientes)
[ ] Confirmaciones completadas o cerradas
[ ] GI/GR pendientes procesadas
[ ] Ordenes completadas → TECO
[ ] WIP calculado (KKAO)
[ ] Overhead aplicado (CO43)
[ ] Desviaciones calculadas (KKS1)
[ ] Settlement ejecutado (CO88)
[ ] Periodo MM cerrado (MMPV)
[ ] Reconciliacion PP-CO-FI verificada
```

## Jobs de cierre (programacion)

| Job | Programa | Descripcion |
|-----|----------|-------------|
| WIP | RKKKS_ORDER_WIP | Calculo WIP masivo |
| Overhead | SAPRCKMS | Overhead ordenes |
| Varianza | RKKKS_ORDER_VARIANCE | Calculo varianzas |
| Settlement | SAPRCO88 | Settlement masivo |

## Consultas MCP diagnostico

```sql
-- Ordenes listas para TECO (DLV pero no TECO)
SELECT K.AUFNR, K.PLNBEZ, K.GAMNG, P.WEMNG
FROM AFKO K
INNER JOIN AFPO P ON K.AUFNR = P.AUFNR
INNER JOIN JEST J ON J.OBJNR = CONCAT('OR', K.AUFNR) AND J.STAT = 'I0046' AND J.INACT = ''
WHERE K.WERKS = '{centro}'

-- WIP acumulado por orden (ACDOCA S/4)
SELECT AUFNR, SUM(HSL) AS WIP_AMOUNT
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}'
AND KSTAR BETWEEN '790000' AND '799999'
GROUP BY AUFNR
```
