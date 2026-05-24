# Cierre de Periodo CO

## Secuencia de cierre

```
Paso  TCode    Descripcion                              Frecuencia
────  ─────    ──────────────────────────────────────── ──────────
 1    —        Verificar contabilizaciones FI/MM/SD      Mensual
 2    KB61     Recontabilizaciones manuales              Si necesario
 3    KSV5     Distribucion (costes primarios)           Mensual
 4    KSU5     Assessment (costes secundarios)           Mensual
 5    KB21N    Actividades internas (si no real-time)    Mensual
 6    KSPI     Calculo tarifas reales                    Mensual
 7    CO43     Overhead — ordenes produccion             Mensual
 8    KGI2     Overhead — ordenes internas               Mensual
 9    KKAO     Calculo WIP (trabajo en curso)            Mensual
10    KKS1     Calculo desviaciones produccion           Mensual
11    KO88     Liquidacion ordenes internas              Mensual
12    CO88     Liquidacion ordenes produccion            Mensual
13    CKMLCP   Cierre Material Ledger                    Mensual
14    KEU5     Transferencia CO-PA (si costing-based)    Mensual
15    —        Reportes de cierre                        Mensual
16    OB52     Cerrar periodo FI                         Mensual
```

### Checklist pre-cierre

| Check | Verificacion | Transaccion |
|-------|-------------|-------------|
| 1 | Todas las facturas MM contabilizadas | MRBR |
| 2 | Todas las entregas SD facturadas | VF04 |
| 3 | Todas las confirmaciones PP registradas | CO11N |
| 4 | No hay partidas parking pendientes | FBV0 |
| 5 | Periodos FI abiertos (OB52) | OB52 |

### Consulta MCP — Verificar cierre

```sql
-- Documentos CO del periodo
SELECT COUNT(*) AS DOC_COUNT, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND GJAHR = '{year}'
AND POPER = '{periodo}'
AND RLDNR = '0L'

-- Ordenes sin liquidar
SELECT AUFNR, AUART, BUKRS
FROM AUFK
WHERE BUKRS = '{sociedad}'
AND AUTYP = '01'
```

### Jobs de cierre automatico

| Job | Programa | Descripcion |
|-----|----------|-------------|
| CO_ALLOCATION | SAPKSVN | Distribucion/Assessment |
| CO_SETTLEMENT | SAPKO88 | Liquidacion masiva |
| ML_CLOSE | RCKMLCP | Cierre Material Ledger |
