# KPIs de Desempeño — SAP JVA

## 1. Por Qué Medir el Desempeño del Ciclo JVA

Más allá de la corrección técnica del cutback y billing, el negocio necesita visibilidad de qué
tan eficiente y predecible es el ciclo de cierre JVA — un ciclo lento o con reconciliaciones
recurrentemente problemáticas erosiona la confianza de los partners y genera riesgo de disputas.

## 2. KPIs de Ciclo de Cierre

| KPI | Qué mide | Fuente |
|---|---|---|
| Tiempo de ciclo de cierre JVA | Días desde el cierre de periodo CO/FI hasta la emisión de billing (JIB) a todos los partners | `GJHIST` + fecha de emisión de billing |
| % de periodos cerrados sin diferencia de reconciliación | Calidad del proceso de cierre (GJUBI vs ACDOCA) | Reconciliación de cierre |
| % de corridas de cutback re-ejecutadas | Indicador de calidad de datos maestros / customizing antes del cierre | `GJHIST` (conteo de re-ejecuciones por periodo) |

## 3. KPIs de Costo y Exposición

| KPI | Qué mide | Fuente |
|---|---|---|
| Costo JV no distribuido (non-billable) como % del costo total | Visibilidad de cuánto del gasto operativo el operador absorbe sin reembolso | `GJUBI` (billable vs non-billable) vs `ACDOCA` |
| Overhead recovery efectivo vs tasa contractual | Detecta desviaciones entre lo calculado y lo pactado en el JOA | `GJUBI` (líneas overhead) |
| Exposición de cash calls pendientes de reconciliar | Riesgo de descuadre acumulado entre anticipos y costo real | Anticipos FI + `GJUBI` |
| AFE ejecutado vs autorizado (%) | Control presupuestario de actividades JV significativas | PS/CO (presupuesto vs real) |

## 4. KPIs de Relación con Partners

| KPI | Qué mide | Fuente |
|---|---|---|
| Antigüedad de cuentas por cobrar de partners (aging) | Salud del cobro de billing emitido | FI-AR |
| Número de disputas de billing por periodo | Calidad percibida del proceso de facturación JV | Log de disputas (proceso de negocio, no siempre en SAP) |
| Tiempo de resolución de disputas | Eficiencia del proceso de partner audit/ajuste | Log de disputas + fecha de ajuste aplicado |

## 5. Consultas MCP de Apoyo

### Costo non-billable como % del total del venture

```sql
SELECT
  sum(case when recind in ('{lista_ri_non_billable}') then wkgbtr else 0 end) as costo_no_distribuido,
  sum(wkgbtr) as costo_total
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
```

### Conteo de re-ejecuciones de cutback por periodo (proxy de calidad de datos)

```sql
SELECT venture, gjahr, monat, count(*) as corridas
FROM gjhist
WHERE gjahr = '{year}'
GROUP BY venture, gjahr, monat
HAVING count(*) > 1
```

## 6. Buenas Prácticas

1. Revisar estos KPIs en cada cierre de periodo, no solo trimestral o anualmente — permite
   detectar deterioro del proceso antes de que se acumule en una disputa mayor.
2. Compartir un subconjunto apropiado de estos KPIs con los partners como parte de la relación de
   transparencia del venture (especialmente tiempo de ciclo de cierre y overhead recovery vs
   tasa contractual).
3. Usar el conteo de re-ejecuciones de cutback como señal temprana de necesidad de mejora en la
   calidad de datos maestros (Equity Group, atributo JV) antes de que afecte la puntualidad del
   billing.
