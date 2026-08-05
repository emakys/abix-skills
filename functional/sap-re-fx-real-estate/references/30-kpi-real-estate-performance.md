# KPIs de Desempeño — SAP RE-FX

## 1. Por Qué Medir el Desempeño del Portafolio Inmobiliario

Más allá de la corrección técnica de la facturación y la liquidación, el negocio necesita
visibilidad de qué tan rentable y eficientemente gestionado está el portafolio — un portafolio con
alta vacancia, rentas desactualizadas o liquidaciones recurrentemente disputadas erosiona el
retorno de la inversión inmobiliaria.

## 2. KPIs de Ocupación y Portafolio

| KPI | Qué mide | Fuente |
|---|---|---|
| Tasa de ocupación | % de superficie/objetos con contrato vigente sobre el total del portafolio | `VIBDOB` + `VICNCN` |
| Tasa de vacancia por segmento | Vacancia desagregada por tipo de uso (oficina/retail/industrial/residencial) | `VIBDOB` + `VICNCN` |
| Tiempo promedio de vacancia (turnover) | Días entre finalización de un contrato y activación del siguiente sobre el mismo objeto | Histórico de contratos por objeto |
| Renta promedio por m² por segmento | Comparabilidad de precio dentro del portafolio | `VICNCND` + `VIBDOB` |

## 3. KPIs de Ciclo Contractual

| KPI | Qué mide | Fuente |
|---|---|---|
| % de contratos próximos a vencer sin renovación gestionada | Riesgo de vacancia futura no anticipada | `VICNCN` (vencimientos próximos) |
| Tiempo de ciclo de liquidación de gastos comunes | Días desde el cierre del periodo hasta la emisión de la liquidación a inquilinos | Historial de corridas de liquidación |
| % de ajustes de renta ejecutados en fecha vs con retraso | Calidad del proceso de gestión de portafolio | `VICNCND` (histórico de condiciones vs calendario pactado) |

## 4. KPIs Financieros

| KPI | Qué mide | Fuente |
|---|---|---|
| Ingreso por renta vs costo operativo del portafolio (NOI — Net Operating Income aproximado) | Rentabilidad operativa del portafolio | `ACDOCA` |
| Costo de vacancia (gasto operativo de objetos sin ingreso) | Impacto financiero de la vacancia, más allá de la pérdida de ingreso | `ACDOCA` (objetos vacantes) |
| Saldo de pasivo por arrendamiento (IFRS 16) y su evolución | Exposición financiera de contratos lease-in | `ANLA`/`ACDOCA` |
| Antigüedad de cuentas por cobrar de inquilinos (aging) | Salud del cobro de renta y liquidaciones emitidas | FI-AR |

## 5. KPIs de Relación con Inquilinos

| KPI | Qué mide | Fuente |
|---|---|---|
| Número de disputas de liquidación de gastos comunes por periodo | Calidad percibida del proceso de liquidación | Log de disputas (proceso de negocio, no siempre en SAP) |
| Tasa de renovación de contratos | Retención de inquilinos, indicador de satisfacción y competitividad de renta | `VICNCN` (contratos renovados vs finalizados sin renovar) |

## 6. Consultas MCP de Apoyo

### Tasa de ocupación aproximada por Business Entity

```sql
SELECT
  count(*) as total_objetos,
  sum(case when meinh in (select vertrag from vicncn where vbegdat <= current_date and venddat >= current_date) then 1 else 0 end) as objetos_ocupados
FROM vibdob
WHERE swenr = '{business_entity}'
```

### Renta total facturada del periodo vs costo operativo (NOI aproximado)

```sql
SELECT
  sum(case when racct = '{cuenta_ingreso_renta}' then hsl else 0 end) as ingreso_renta,
  sum(case when racct in ('{cuentas_costo_operativo}') then hsl else 0 end) as costo_operativo
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
```

## 7. Buenas Prácticas

1. Revisar estos KPIs en cada cierre de periodo, no solo trimestral o anualmente — permite detectar
   deterioro de ocupación o de calidad del proceso de liquidación antes de que se acumule en una
   pérdida significativa de ingreso o en disputas mayores.
2. Compartir un subconjunto apropiado de estos KPIs con el equipo de gestión de portafolio como
   parte de la revisión periódica de desempeño (especialmente ocupación, tiempo de vacancia y renta
   promedio por segmento).
3. Usar el tiempo de ciclo de liquidación de gastos comunes como señal temprana de necesidad de
   mejora en el proceso (recolección de costos, calidad de datos de Grupos de Participación) antes
   de que afecte la puntualidad hacia los inquilinos.
