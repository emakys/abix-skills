# Errores Comunes — SAP JVA (Catálogo Consolidado)

## 1. Errores de Datos Maestros

| Error | Causa | Fix |
|---|---|---|
| Venture no válido / no encontrado | Venture no creado, o clave incorrecta | Verificar en `T8J1`, crear si corresponde |
| No equity group valid for this date | Vigencia de Equity Group (`VALFR`/`VALTO`) no cubre la fecha del documento | Extender o crear nuevo periodo de Equity Group en `T8J2` |
| Equity percentages do not total 100% | Error de mantenimiento de % de partners en el Equity Group | Corregir el detalle de partners hasta sumar 100% |
| Recovery Indicator no derivado en la línea | Objeto CO sin RI por defecto y sin sustitución que aplique | Completar atributo JV en el maestro CO, o revisar regla de sustitución `GGB1` |

## 2. Errores de Proceso — Cutback

| Error | Causa | Fix |
|---|---|---|
| Cutback already processed for this period | Doble ejecución de `GJ04` en modo producción sobre el mismo periodo | Revisar `GJHIST`, revertir antes de re-ejecutar |
| Diferencia entre costo 100% (ACDOCA) y total distribuido (GJUBI) | Líneas sin Equity Group vigente, o Recovery Indicator non-billable no esperado | Investigar línea por línea, corregir vigencia o RI |
| Objeto CO esperado no aparece en el resultado del cutback | No pertenece al Cutback Group procesado, o carece de atributo JV | Verificar asignación de Cutback Group y completar atributo JV |

## 3. Errores de Proceso — Billing (JIB)

| Error | Causa | Fix |
|---|---|---|
| No cutback data available for billing | Se intentó generar JIB sin cutback previo del periodo | Ejecutar `GJ04` antes de reintentar billing |
| Billing duplicado | Generación repetida sin control de estado | Revisar historial antes de regenerar; anular duplicado según procedimiento |
| Partida FI-AR no se generó tras el billing | Cuenta de reconciliación del partner mal configurada | Revisar maestro de Business Partner / cuenta de reconciliación |

## 4. Errores de Cierre

| Error | Causa | Fix |
|---|---|---|
| Periodo JVA cerrado con diferencias sin explicar | Reconciliación GJUBI vs ACDOCA omitida antes de cerrar | Revertir cierre si es posible, investigar diferencias, re-cerrar |
| Posting period for venture is closed | Intento de contabilizar/procesar sobre un periodo ya bloqueado | Reabrir con autorización formal, o mover el ajuste al periodo corriente |

## 5. Errores en Escenarios Especiales

| Error | Causa | Fix |
|---|---|---|
| Costo de operación non-consent repartido con el % estándar del venture | Objeto CO usó el Equity Group general en vez del específico | Corregir asignación, re-procesar cutback |
| Overhead no calculado o con tasa incorrecta | Recovery Indicator sin bandera de overhead, o tasa/fase mal configurada | Ajustar customizing del RI y de la tasa aplicable |
| Cash call contabilizado como costo en vez de anticipo | Mapeo contable incorrecto en la contabilización del cobro | Corregir cuenta de contrapartida (debe ser pasivo/anticipo) |

## 6. Workflow General de Diagnóstico

1. Identificar en qué fase del ciclo Cutback-to-Bill ocurre el error (datos maestros → atributo CO
   → cutback → billing → cierre)
2. Confirmar el texto exacto del mensaje (`T100`) si hay código de error
3. Verificar los datos reales (`T8J1`/`T8J2`/`T8J3`/`GJUBI`/`GJHIST`/`ACDOCA`) contra lo esperado
4. Aislar si la causa es de **customizing** (Equity Group, Recovery Indicator) o de **datos
   transaccionales** (línea sin atributo, doble ejecución)
5. Documentar el fix y su impacto en billing ya emitido, si aplica

## 7. Buenas Prácticas de Prevención

1. Ejecutar siempre cutback en modo prueba antes de producción.
2. Reconciliar GJUBI vs ACDOCA antes de cada cierre.
3. Validar suma de % de Equity Group al mantenerlo, no esperar a que falle el cutback.
4. Mantener un catálogo corto y bien documentado de Recovery Indicators.
