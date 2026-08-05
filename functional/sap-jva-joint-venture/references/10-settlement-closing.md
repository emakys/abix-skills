# Cierre de Periodo JVA — Settlement y Reconciliación

## 1. Introducción

El cierre de periodo en JVA no es un evento aislado: depende de que el cierre de CO/FI del periodo
esté sustancialmente completo (todos los costos reales contabilizados) antes de poder correr el
cutback definitivo y considerar el periodo JV cerrado. Un cierre JVA prematuro (antes de que MM/FI
terminen de contabilizar) obliga a reaperturas y recorridas.

---

## 2. Secuencia Típica de Cierre

```
1. Cierre de periodo MM (todas las entradas de mercancía/factura contabilizadas)
2. Cierre de periodo CO (asignaciones, distribuciones, recargos internos completos)
3. Corrida de cutback JVA en modo prueba — validación
4. Corrida de cutback JVA en modo producción
5. Generación de Joint Interest Billing (JIB)
6. Reconciliación de cash calls vs resultado del cutback
7. Cierre del periodo JVA (bloqueo de nuevas contabilizaciones JV-relevantes en ese periodo)
8. Reporting de cierre a partners
```

---

## 3. Reconciliación GJUBI vs ACDOCA

Antes de dar el periodo por cerrado, es estándar reconciliar:

- El total de costo 100% booked en objetos CO JV-relevantes (ACDOCA) del periodo
- Contra el total distribuido en `GJUBI` para ese mismo periodo/venture

La diferencia debe explicarse íntegramente por líneas con Recovery Indicator non-billable (que
deliberadamente no se distribuyen) o por líneas con problemas de atributo JV incompleto (que deben
corregirse, no simplemente "aceptarse" como diferencia).

---

## 4. Bloqueo de Periodo JVA

Al cerrar el periodo, se bloquea la contabilización JV-relevante contra ese periodo (análogo al
cierre de periodo estándar de FI/CO), para preservar la integridad del resultado ya facturado a
los partners. Reabrir un periodo cerrado requiere justificación formal y, casi siempre, la reversión
o el ajuste posterior del billing ya emitido (ver `06-joint-interest-billing.md` §6).

---

## 5. Ajustes de Periodos Anteriores (Prior Period Adjustments)

Cuando se detecta un error después de cerrado un periodo (costo mal clasificado, RI incorrecto),
la práctica estándar en la industria **no es reabrir y recontabilizar el periodo original**, sino
generar un **ajuste identificado explícitamente como "prior period adjustment"** que se incluye en
el cutback y billing del periodo corriente, con referencia clara al periodo original afectado. Esto
preserva la integridad del histórico ya auditado por los partners.

---

## 6. Rol del Reporting en el Cierre

El cierre no está completo, desde la óptica del partner, hasta que recibe su statement (JIB) y
tiene visibilidad de cualquier reconciliación de cash call pendiente. El equipo de cierre JVA debe
coordinar la emisión oportuna de ambos, no solo la ejecución técnica del cutback.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Estado de cierre por venture

```sql
SELECT venture, gjahr, monat, status
FROM gjhist
WHERE gjahr = '{year}'
ORDER BY venture, monat
```

### Reconciliación resumida costo 100% vs distribuido, por venture

```sql
SELECT venture, sum(wkgbtr) as total_distribuido
FROM gjubi
WHERE gjahr = '{year}'
  AND monat = '{periodo}'
GROUP BY venture
```

---

## 8. Errores Frecuentes en Cierre

| Error | Causa | Fix |
|---|---|---|
| Periodo JVA cerrado con diferencias sin explicar | Reconciliación GJUBI vs ACDOCA no se hizo antes de cerrar | Revertir el cierre si es posible, investigar y corregir diferencias antes de re-cerrar |
| Costos llegan después del cierre del periodo | Documento de MM/FI contabilizado tarde, fuera del ciclo de cutback | Se arrastra al periodo siguiente como ajuste, con la referencia correspondiente |
| Reapertura de periodo sin respaldo formal | Falta de proceso de control interno para autorizar reaperturas | Definir y exigir un flujo de aprobación documentado para toda reapertura de periodo JVA |

---

## 9. Buenas Prácticas

1. **Fijar un calendario de cierre JVA coordinado con FI/CO/MM**, comunicado a todo el equipo de
   cierre, no solo al equipo JVA.

2. **Nunca cerrar un periodo con diferencias de reconciliación sin explicar** — es la principal
   fuente de sorpresas en auditorías de partner meses después.

3. **Preferir ajustes de periodo corriente sobre reaperturas** siempre que el impacto lo permita —
   preserva la trazabilidad y reduce el riesgo de control interno.

4. **Mantener evidencia de cada cierre** (reconciliación, aprobación, fecha de bloqueo) como parte
   del expediente de auditoría del venture.
