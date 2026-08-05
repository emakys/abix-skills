# Integración con Production Accounting / Upstream (SAP JVA)

## 1. Introducción

JVA reparte **costos** (y en algunos escenarios ingresos) entre partners, pero la cantidad física
de hidrocarburo producida y su distribución/venta suele gestionarse en procesos de **production
accounting / hydrocarbon accounting**, que pueden vivir en módulos o soluciones adicionales
(gestión de producción upstream) fuera del alcance estricto de JVA. Un consultor JVA necesita
entender el punto de contacto entre ambos mundos, aunque el detalle técnico de production
accounting exceda esta skill.

---

## 2. Gas/Production Balancing — Concepto de Negocio

Cuando varios partners comparten un venture de producción, puede surgir una situación en la que un
partner (u operador) vende o levanta (offtake) una porción del hidrocarburo producido que difiere
de su % de participación (por razones logísticas, de mercado, o de contrato de venta). El **balance
de producción** rastrea esta diferencia acumulada entre lo que cada partner "tiene derecho" a
levantar según su % de equity y lo que efectivamente levantó, para poder reconciliar (in-kind o
en efectivo) periódicamente.

**Nota de honestidad técnica:** el gas/production balancing es un proceso especializado de la
industria upstream que en el ecosistema SAP puede resolverse con capacidades adicionales de gestión
de producción específicas de Oil & Gas, no necesariamente como parte del núcleo transaccional de
JVA (cutback/billing). No asumas que JVA por sí solo resuelve el balanceo físico de producción;
confirma con el equipo de production accounting del cliente qué herramienta se usa realmente en su
paisaje SAP.

---

## 3. Dónde se Tocan JVA y Production Accounting

- El **costo de producción** de un pozo/facilidad compartida se reparte por JVA (cutback estándar)
- La **cantidad física producida y su distribución/venta** se gestiona por los procesos de
  production accounting del cliente
- Cuando hay una venta conjunta (offtake compartido) y el ingreso debe repartirse según equity, el
  ingreso puede modelarse con el mismo mecanismo de atributo JV (Venture/Equity Group/Recovery
  Indicator billable) sobre el objeto CO/documento de ingreso correspondiente, análogamente al
  tratamiento de costos

---

## 4. Royalties y Obligaciones Fiscales Upstream

En muchos países, la producción de hidrocarburos está sujeta a regalías (royalties) y otros
gravámenes específicos del sector, que se calculan sobre la producción física y no directamente
sobre el reparto de costo JVA. Estos procesos suelen gestionarse con herramientas fiscales/legales
específicas del país y de la industria, fuera del alcance funcional de JVA — un consultor JVA debe
reconocer el límite de su alcance y coordinar con el equipo especializado correspondiente en vez de
intentar resolverlo dentro de JVA.

---

## 5. Puntos de Verificación al Diagnosticar Incidentes en la Frontera JVA / Production Accounting

1. ¿El incidente reportado es sobre el **reparto de costo** (JVA, resuelto con cutback) o sobre la
   **cantidad física producida/vendida** (production accounting, fuera de JVA)?
2. Si involucra ingreso compartido, ¿el objeto/documento de ingreso tiene el mismo tratamiento de
   atributo JV que los objetos de costo del venture?
3. ¿Existe una reconciliación periódica documentada entre el sistema de production accounting y los
   objetos CO que JVA está distribuyendo?

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Objetos CO de ingreso marcados como JV-relevantes (si el venture reparte ingreso además de costo)

```sql
SELECT rcntr, racct, sum(hsl) as monto
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
  AND drcrk = 'H'  -- lineas de haber/ingreso, ajustar segun convencion del cliente
```

---

## 7. Errores Frecuentes en la Frontera JVA / Production Accounting

| Error | Causa | Fix |
|---|---|---|
| Ingreso de venta conjunta no se reparte entre partners | Documento de ingreso sin atributo JV asignado | Extender el diseño de atributo JV a los objetos/documentos de ingreso relevantes |
| Discrepancia entre % de equity de costo y % usado para levantar producción | Los dos procesos (JVA y production accounting) no están sincronizados en su fuente de % de participación | Establecer una única fuente de verdad para el % de equity, referenciada por ambos procesos |
| Consultor JVA intenta resolver un problema de balanceo físico de producción dentro de JVA | Confusión de alcance entre reparto de costo y gestión de producción física | Redirigir al equipo/herramienta de production accounting correspondiente |

---

## 8. Buenas Prácticas

1. **Delimitar claramente, en cualquier documento de diseño**, qué resuelve JVA (costo) y qué
   resuelve production accounting (cantidad física) — evita expectativas incorrectas del negocio.

2. **Sincronizar la fuente de % de participación** entre JVA y cualquier proceso de production
   accounting que también dependa de esa cifra, para evitar descuadres entre "cuánto cuesta" y
   "cuánto se puede levantar".

3. **Escalar temas de royalties/obligaciones fiscales upstream al equipo especializado** en vez de
   intentar resolverlos con la parametrización estándar de JVA.
