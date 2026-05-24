# KPIs de Confiabilidad y Disponibilidad

## KPIs Fundamentales

### MTBF — Mean Time Between Failures
```
MTBF = Tiempo total de operacion / Numero de fallas

Ejemplo: Bomba opera 8,760 horas/ano, 4 fallas
MTBF = 8,760 / 4 = 2,190 horas
```

**Query MCP:**
```
-- Fallas por equipo en periodo
GetSqlQuery("SELECT EQUNR,COUNT(*) as FALLAS FROM QMEL WHERE QMART='M1' AND QMDAT >= '{desde}' AND QMDAT <= '{hasta}' GROUP BY EQUNR")
```

### MTTR — Mean Time To Repair
```
MTTR = Tiempo total de reparacion / Numero de reparaciones

Ejemplo: 4 fallas, tiempo total reparacion = 32 horas
MTTR = 32 / 4 = 8 horas
```

**Query MCP:**
```
-- Horas reparacion por equipo
GetSqlQuery("SELECT AFIH.EQUNR,COUNT(DISTINCT AUFK.AUFNR) as REPARACIONES,SUM(AFRU.ISDD) as HORAS_TOTAL FROM AUFK JOIN AFIH ON AUFK.AUFNR=AFIH.AUFNR JOIN AFRU ON AUFK.AUFNR=AFRU.AUFNR WHERE AUFK.AUART='PM01' AND AFRU.IESSION >= '{desde}' GROUP BY AFIH.EQUNR")
```

### Disponibilidad
```
Disponibilidad = MTBF / (MTBF + MTTR) × 100

Ejemplo: MTBF=2190h, MTTR=8h
Disponibilidad = 2190 / (2190 + 8) × 100 = 99.64%
```

### OEE — Overall Equipment Effectiveness
```
OEE = Disponibilidad × Rendimiento × Calidad

Disponibilidad = Tiempo operacion / Tiempo planificado
Rendimiento = Produccion real / Produccion teorica
Calidad = Piezas buenas / Piezas totales

Ejemplo: 95% × 90% × 98% = 83.8%
```

## KPIs de Costes

| KPI | Formula | Meta |
|-----|---------|------|
| Coste mantto / Valor reposicion | Costes PM anuales / RAV | 2-5% |
| Coste por falla | Costes correctivos / Num fallas | Minimizar |
| Ratio preventivo/correctivo | Costes prev / Costes corr | > 3:1 |
| Coste mano obra / Total | Costes MO / Costes totales | 40-60% |

**Query MCP:**
```
-- Costes por tipo de orden (preventivo vs correctivo)
GetSqlQuery("SELECT AUFK.AUART,COUNT(*) as ORDENES,SUM(ACDOCA.HSL) as COSTE FROM AUFK JOIN ACDOCA ON AUFK.AUFNR=ACDOCA.AUFNR WHERE AUFK.AUART IN ('PM01','PM02','PM03') AND ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AUFK.AUART")

-- Top 10 equipos mas costosos
GetSqlQuery("SELECT AFIH.EQUNR,EQKT.EQKTX,SUM(ACDOCA.HSL) as COSTE FROM ACDOCA JOIN AFIH ON ACDOCA.AUFNR=AFIH.AUFNR JOIN EQKT ON AFIH.EQUNR=EQKT.EQUNR AND EQKT.SPRAS='E' WHERE ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AFIH.EQUNR,EQKT.EQKTX ORDER BY COSTE DESC")
```

## KPIs Operativos

| KPI | Formula | Meta |
|-----|---------|------|
| Backlog | Ordenes abiertas × Horas estimadas | < 2 semanas |
| Cumplimiento plan PM | Ejecutados / Programados × 100 | > 90% |
| Tasa emergencia | Ordenes PM01 / Total ordenes × 100 | < 10% |
| Ordenes vencidas | Ordenes pasadas fecha fin | 0 |
| Tiempo reaccion | Tiempo aviso → inicio trabajo | Segun prioridad |

**Query MCP:**
```
-- Backlog actual
GetSqlQuery("SELECT COUNT(*) as ORDENES_ABIERTAS FROM AUFK WHERE AUART LIKE 'PM%' AND AUFNR NOT IN (SELECT AUFNR FROM AUFK WHERE OBJNR IN (SELECT OBJNR FROM JEST WHERE STAT='I0045' AND INACT=''))")

-- Cumplimiento planes
GetSqlQuery("SELECT WARPL,COUNT(*) as LLAMADAS FROM MHIS WHERE TESSION >= '{desde}' AND TESSION <= '{hasta}' GROUP BY WARPL")
```

## Benchmarks por Industria

| Industria | Disponibilidad | MTBF | Prev/Corr ratio |
|-----------|---------------|------|-----------------|
| Manufactura discreta | > 95% | > 500h | 3:1 |
| Proceso continuo | > 98% | > 2000h | 5:1 |
| Utilities/Energia | > 99% | > 5000h | 4:1 |
| Mineria | > 90% | > 300h | 2:1 |
| Alimentos | > 95% | > 1000h | 4:1 |

## Reporting SAP

### PMIS (Plant Maintenance Information System)
| TCode | KPI |
|-------|-----|
| MCI5 | Analisis de danos (MTBF) |
| MCI7 | Analisis de costes mantenimiento |
| MCJB | Analisis de ordenes |
| MCI1 | Analisis por ubicacion tecnica |
| MCI3 | Analisis avisos por ubicacion |

### Fiori Apps Analiticas
| App ID | KPI |
|--------|-----|
| F3303 | Equipment Breakdown Analysis (MTBF) |
| F3545 | Maintenance Cost Analysis |
| F3680 | Equipment Reliability Analysis |
| F3304 | Monitor Maintenance Orders (backlog) |
