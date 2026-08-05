# Non-Consent — Operaciones sin Consentimiento Unánime (SAP JVA)

## 1. Introducción

En un Joint Operating Agreement, no todas las decisiones requieren consentimiento unánime de los
partners. Algunas operaciones (perforar un pozo adicional, ampliar una facilidad) pueden
proponerse y, si algún partner vota en contra o simplemente no participa, la operación puede seguir
adelante **solo con los partners consintientes**, bajo reglas contractuales específicas de
"non-consent" que suelen incluir una penalidad o premium para el partner que se abstuvo si
posteriormente quiere reincorporarse a los beneficios de esa operación (back-in rights).

---

## 2. Impacto en el Reparto de Costos

Cuando una operación es non-consent:

- Los costos de esa operación específica **no** se reparten según el Equity Group estándar del
  venture — se reparten solo entre los partners que sí consintieron, en proporción ajustada entre
  ellos
- El partner no-consintiente queda excluido tanto del costo como (inicialmente) del beneficio
  derivado de esa operación específica (ej. producción incremental de un pozo adicional)

---

## 3. Cómo se Modela en JVA

No existe, en general, un objeto único "non-consent" separado del mecanismo estándar de Equity
Group/Recovery Indicator: el patrón funcional es:

1. Crear un **Equity Group específico** para la operación non-consent, con los partners
   consintientes y su % recalculado (excluyendo al no-consintiente)
2. Asignar ese Equity Group específico al objeto CO (o a la porción de costo) que representa
   exclusivamente esa operación — normalmente un elemento WBS/orden dedicado, para no mezclarlo con
   el resto del venture
3. Usar Recovery Indicators que reflejen si aplica una penalidad/premium contractual sobre el
   reparto ajustado

Es un escenario donde la calidad del diseño de objetos CO (uno dedicado a la operación non-consent)
es crítica: intentar resolver non-consent con sustituciones complejas sobre un objeto CO compartido
genérico es frágil y difícil de auditar.

---

## 4. Back-In Rights

Muchos JOAs otorgan al partner no-consintiente el derecho de "volver a entrar" (back-in) a los
beneficios de la operación non-consent después de que los partners consintientes hayan recuperado
su inversión más una penalidad (ej. 300% del costo, un múltiplo común en la industria, aunque varía
por contrato). Cuando esto ocurre, se requiere:

- Un nuevo periodo de Equity Group que refleje la reincorporación del partner desde la fecha
  efectiva del back-in
- Ajuste retroactivo únicamente si el JOA lo exige explícitamente (normalmente el back-in es
  prospectivo, no retroactivo)

---

## 5. Consultas MCP Útiles (GetSqlQuery)

### Identificar Equity Groups usados exclusivamente para operaciones non-consent

```sql
SELECT venture, egrup, valfr, valto
FROM t8j2
WHERE venture = '{venture}'
ORDER BY valfr
-- Cruzar con la documentación funcional de qué EGRUP corresponde a operaciones non-consent específicas
```

### Costos distribuidos bajo un Equity Group non-consent

```sql
SELECT partner, sum(wkgbtr) as monto
FROM gjubi
WHERE venture = '{venture}'
  AND egrup = '{equity_group_non_consent}'
GROUP BY partner
```

---

## 6. Errores Frecuentes en Non-Consent

| Error | Causa | Fix |
|---|---|---|
| Costo non-consent repartido con el % estándar del venture | Objeto CO usó el Equity Group general en vez del específico de la operación | Corregir asignación de Equity Group del objeto y re-procesar cutback |
| Partner no-consintiente recibió billing de la operación | Falla en el aislamiento del objeto CO dedicado a la operación non-consent | Revisar diseño de objeto CO; separar la actividad non-consent en un objeto dedicado |
| Back-in no reflejado en el reparto | Falta de nuevo periodo de Equity Group desde la fecha efectiva del back-in | Crear nuevo Equity Group con vigencia correcta |

---

## 7. Buenas Prácticas

1. **Aislar cada operación non-consent en su propio objeto CO** (orden interna o WBS dedicado)
   desde el momento en que se conoce que habrá partners no-consintientes — no intentar resolverlo
   después con sustituciones complejas.

2. **Documentar el mecanismo de penalidad/premium acordado en el JOA** antes de parametrizar el
   reparto — es un cálculo contractual, no una regla técnica estándar de SAP.

3. **Llevar un registro separado de operaciones non-consent activas por venture**, con su Equity
   Group asociado y la condición de back-in pactada, como referencia para el equipo de cierre.

4. **Validar con asesoría legal/contractual** cualquier escenario de non-consent antes de
   configurarlo — las implicancias del JOA suelen ser más complejas que lo que el sistema puede
   inferir solo de los datos maestros.
