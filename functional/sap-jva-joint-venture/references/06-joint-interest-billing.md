# Joint Interest Billing (JIB) — Facturación a Partners (SAP JVA)

## 1. Introducción

El **Joint Interest Billing (JIB)** es el proceso que convierte el resultado del cutback (las
líneas `GJUBI` con el detalle de cuánto le corresponde a cada partner) en un documento de
facturación formal — el **statement** o extracto que se envía a cada partner no-operador,
respaldado por una partida contable de cuenta por cobrar en FI-AR.

---

## 2. Prerrequisito: Cutback Ejecutado

JIB no puede generarse sin que el cutback del periodo correspondiente haya corrido exitosamente:
el billing lee directamente el resultado de `GJUBI`. Un intento de facturar sin cutback previo
para ese periodo/venture es uno de los errores más comunes reportados por usuarios finales.

---

## 3. Contenido de un Statement JIB

Un statement típico incluye, por partner y periodo:

- Detalle de costos por categoría (agrupado por cuenta contable, tipo de actividad, o el
  agrupamiento que defina el diseño de reporting del venture)
- El % de participación aplicado
- El monto resultante a cargo del partner
- Overhead recovery aplicado (si corresponde según el Recovery Indicator de las líneas)
- Ajustes de periodos anteriores (correcciones, reversiones) si aplica
- Neto de cash calls ya recibidos, si el venture opera con anticipos (ver `07-cash-calls-advances.md`)

---

## 4. Generación del Documento de Billing

La generación de JIB produce:

1. Un documento de facturación/contabilización dentro del ciclo JVA
2. Una partida FI-AR contra el partner (si el partner es no-operador y debe pagar)
3. Actualización del registro de billing para trazabilidad (qué corrida de cutback originó qué
   factura, necesario para poder rastrear reversiones)

**Transacción de referencia (familia GJxx):** la generación de billing se ejecuta mediante
transacciones de la familia de billing JVA; el número de transacción exacto puede variar según
versión — confirmar en el sistema con `SE93`/menú de aplicación antes de documentarlo como fijo
en procedimientos operativos.

---

## 5. Integración con FI-AR

El resultado de JIB no se queda "dentro" de JVA: genera un documento que impacta la cuenta por
cobrar del partner en FI. Esto significa que:

- El seguimiento de cobro (aging, recordatorios, aplicación de pagos) usa las herramientas
  estándar de FI-AR
- Cualquier disputa de billing que derive en nota de crédito/débito debe coordinarse entre el
  equipo JVA (que entiende el detalle de costo) y el equipo FI-AR (que administra la cuenta)

---

## 6. Disputas y Ajustes de Billing (Partner Audit)

Es común que un partner no-operador cuestione una parte del billing recibido (costo mal
clasificado, gasto que considera no facturable según el JOA). El flujo típico:

1. El partner presenta la disputa (formal o informalmente) sobre líneas específicas
2. El operador revisa la línea de origen: objeto CO, Recovery Indicator, cuenta contable
3. Si la disputa es válida, se corrige en el origen (recontabilización o ajuste de atributo JV) y
   se re-procesa vía un cutback de ajuste, no editando `GJUBI` manualmente
4. El ajuste se refleja en el siguiente ciclo de billing, normalmente identificado explícitamente
   como "ajuste de periodo anterior" para mantener trazabilidad

Ver `13-partner-audits-statements.md` para el detalle del proceso de auditoría formal.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Resumen de billing por partner y periodo

```sql
SELECT partner, gjahr, sum(wkgbtr) as monto_facturado
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
GROUP BY partner, gjahr
```

### Verificar si un venture/periodo tiene cutback pero no tiene billing generado

```sql
-- Confirmar estado de cutback
SELECT venture, gjahr, monat, status
FROM gjhist
WHERE venture = '{venture}'
  AND gjahr = '{year}'

-- Cruzar contra el registro de documentos de billing generados
-- (tabla específica de documentos JIB — confirmar nombre exacto en el sistema real)
```

---

## 8. Errores Frecuentes en JIB

| Error | Causa | Fix |
|---|---|---|
| No cutback data available for billing | Se intentó generar JIB sin cutback previo del periodo | Ejecutar `GJ04` para el periodo, luego reintentar billing |
| Billing duplicado para el mismo periodo | Se generó billing dos veces sin control de estado | Revisar historial de billing antes de regenerar; anular el duplicado según el procedimiento estándar |
| Monto de billing no cuadra con GJUBI | Ajustes manuales posteriores al cutback no reflejados correctamente | Nunca ajustar `GJUBI` manualmente; usar un cutback de ajuste |
| Partida FI-AR no se generó | Cuenta de reconciliación del partner mal configurada, o partner sin rol AR habilitado | Revisar maestro de Business Partner / cuenta de mayor de reconciliación |

---

## 9. Buenas Prácticas

1. **Nunca editar `GJUBI` manualmente** para "corregir" un billing — rompe la trazabilidad entre
   costo origen, cutback y factura. Corregir siempre en el origen y re-procesar.

2. **Emitir el JIB con un periodo de gracia para revisión interna** antes de enviarlo al partner —
   revisar el statement generado contra el detalle de `GJUBI` como control de calidad.

3. **Mantener un log de disputas y su resolución** por venture — es la evidencia que sustenta la
   relación de confianza con los partners y lo que se solicita en cualquier auditoría externa.

4. **Alinear la periodicidad de billing con lo pactado en el JOA** — algunos acuerdos exigen
   billing mensual, otros trimestral; el proceso técnico debe seguir el calendario contractual, no
   al revés.
