# Embedded Analytics PM

## CDS Analytical Queries

| CDS View | Descripcion | KPIs |
|----------|-------------|------|
| C_MaintOrdMonitor | Monitor ordenes PM | Backlog, aging, por status |
| C_MaintNotifOverview | Overview avisos | Volumen, tendencia, por tipo |
| C_MaintOrderCostAnalysis | Analisis costes | Plan vs Real, por equipo/CC |
| C_EquipBrkdwnAnlyss | Analisis averias equipo | MTBF, frecuencia fallas |
| C_EquipReliabilityAnlyss | Confiabilidad equipo | Disponibilidad, MTTR |
| C_MaintPlanOverview | Overview planes | Adherencia, vencidos |

## KPIs de Mantenimiento

### Disponibilidad y Confiabilidad
| KPI | Formula | Meta tipica |
|-----|---------|-------------|
| MTBF | Tiempo operacion / Numero de fallas | Maximizar |
| MTTR | Tiempo total reparacion / Numero de fallas | Minimizar |
| Disponibilidad | (MTBF / (MTBF + MTTR)) × 100 | > 95% |
| OEE | Disponibilidad × Rendimiento × Calidad | > 85% |

### Costes
| KPI | Formula |
|-----|---------|
| Coste por equipo | Total costes PM / Numero equipos |
| Coste por falla | Total costes correctivos / Numero averias |
| Ratio preventivo/correctivo | Costes preventivos / Costes correctivos |
| Coste mantto / Valor activo | Costes PM anuales / Valor reposicion |

### Operativos
| KPI | Formula |
|-----|---------|
| Backlog ordenes | Ordenes abiertas × Horas estimadas |
| Cumplimiento plan | Planes ejecutados / Planes programados |
| Tasa de emergencia | Ordenes PM01 / Total ordenes |

## Queries ACDOCA para KPIs

```
-- Costes mantenimiento por equipo (anual)
GetSqlQuery("SELECT AFIH.EQUNR,EQKT.EQKTX,SUM(ACDOCA.HSL) as COSTE_TOTAL FROM ACDOCA JOIN AFIH ON ACDOCA.AUFNR=AFIH.AUFNR JOIN EQKT ON AFIH.EQUNR=EQKT.EQUNR AND EQKT.SPRAS='E' WHERE ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AFIH.EQUNR,EQKT.EQKTX ORDER BY COSTE_TOTAL DESC")

-- Ratio correctivo vs preventivo
GetSqlQuery("SELECT AUFK.AUART,COUNT(*) as CNT,SUM(ACDOCA.HSL) as COSTE FROM AUFK JOIN ACDOCA ON AUFK.AUFNR=ACDOCA.AUFNR WHERE AUFK.AUART IN ('PM01','PM02') AND ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AUFK.AUART")

-- MTBF por equipo (averias por periodo)
GetSqlQuery("SELECT EQUNR,COUNT(*) as FALLAS FROM QMEL WHERE QMART='M1' AND QMDAT >= '{desde}' AND QMDAT <= '{hasta}' GROUP BY EQUNR ORDER BY FALLAS DESC")
```

## Integracion SAP Analytics Cloud (SAC)

- **Live Connection**: datos en tiempo real desde ACDOCA/CDS views
- **Import Connection**: snapshot periodico para analisis historico
- **Dashboards**: Plant Maintenance Overview con drill-down
- **Predictive**: modelos de prediccion de fallas integrados
