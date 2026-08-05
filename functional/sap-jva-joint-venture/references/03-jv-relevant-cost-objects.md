# Objetos CO JV-Relevantes — Centro de Coste, Orden Interna, WBS (SAP JVA)

## 1. Introducción

JVA no tiene sus propios "objetos de coste": reutiliza los objetos CO estándar (centro de coste,
orden interna, elemento WBS) y les añade el atributo JV (Venture + Equity Group + Recovery
Indicator). Entender cómo y cuándo se marca un objeto como JV-relevante es la base de cualquier
diagnóstico de "por qué este costo no se distribuyó" o "por qué se distribuyó con el % incorrecto".

---

## 2. Centro de Coste JV-Relevante

Se marca directamente en el maestro del centro de coste (pestaña/campos JVA en `KS01`/`KS02`).

**Campos añadidos (orientativos, verificar en el sistema real):**
- `VENTURE` — venture al que pertenece
- `EGRUP` — equity group por defecto
- `RECIND` — recovery indicator por defecto

**Uso típico:** centros de coste creados específicamente para administrar un venture (ej. "Pozo
XYZ — Operación") donde el 100% de la actividad pertenece a ese venture. Es el patrón más limpio y
recomendado quando es posible dedicar el objeto CO al venture.

---

## 3. Orden Interna JV-Relevante

Igual mecanismo que el centro de coste, mantenido en `KO01`/`KO02`. Muy usada para actividades
puntuales dentro de un venture que no ameritan un centro de coste permanente (ej. una campaña de
workover, una reparación puntual de facilidades compartidas).

**Ventaja de la orden interna sobre el centro de coste para JV:** su ciclo de vida (crear → cargar
costos → liquidar/cerrar) encaja naturalmente con el ciclo de una actividad JV específica y
facilita reportar el costo total de esa actividad antes del cutback.

---

## 4. WBS Element (PS) JV-Relevante

Cuando la actividad del venture se gestiona como proyecto (ej. desarrollo de un campo, campaña de
perforación con múltiples pozos como elementos WBS), el atributo JV se mantiene a nivel de
elemento WBS. Esto conecta naturalmente con AFE (ver `09-afe-budgeting.md`), donde el proyecto
completo o cada elemento representa una autorización de gasto aprobada por los partners.

---

## 5. Sustitución JVA (Nivel de Línea)

Cuando el objeto CO es compartido (recibe costos de más de un venture, o el atributo JV depende de
la cuenta contable, la fecha, o el tipo de documento), el atributo por defecto del maestro no
alcanza. Se usa una **regla de sustitución** (`GGB1`, tipo de sustitución CO/JVA) que evalúa
condiciones en el momento de la contabilización y sobrescribe `VENTURE`/`EGRUP`/`RECIND` en la
línea individual.

**Casos típicos de sustitución:**
- Un centro de coste de "servicios compartidos" que atiende múltiples ventures — la sustitución
  deriva el venture correcto según el WBS/orden de referencia en la línea
- Ciertas cuentas contables (ej. gastos administrativos generales) que siempre deben ir con un
  Recovery Indicator "overhead-only" independientemente del objeto CO
- Periodos de transición donde el % de equity cambió a mitad de mes y se necesita lógica adicional
  más allá de la vigencia estándar del Equity Group

**Dónde se configura:** `GGB1` (mantenimiento de reglas de sustitución), asignada al call point
correspondiente de contabilización CO/FI.

---

## 6. Precedencia: Maestro vs Sustitución

1. El sistema deriva primero el atributo JV del **maestro del objeto CO** (si existe)
2. Si hay una **regla de sustitución activa** que aplica a la línea, esta puede sobrescribir
   parcial o totalmente el atributo derivado del maestro
3. Si ni el maestro ni la sustitución determinan un atributo JV, la línea **queda fuera del
   alcance JVA** — no entra a cutback, no genera billing

Este orden es la causa raíz más común de "el costo no se distribuyó": o el maestro no tiene el
atributo, o hay una sustitución que lo está sobrescribiendo con un valor no esperado (o vaciándolo
bajo ciertas condiciones no consideradas por el usuario funcional).

---

## 7. Multi-Venture en un Mismo Objeto CO

Cuando un objeto CO recibe costos de más de un venture (patrón "servicios compartidos"), es
indispensable la sustitución basada en algún campo adicional que indique el venture de destino real
(ej. campo de referencia, texto de posición, WBS/orden asociada en la imputación). Sin ese campo
de "pista", la sustitución no tiene cómo distinguir a qué venture pertenece cada línea y termina
asignando todo al mismo valor por defecto — un anti-patrón frecuente en diseños JVA mal planificados
desde el arranque del proyecto.

---

## 8. Consultas MCP Útiles (GetSqlQuery)

### Centros de coste JV-relevantes de un venture

```sql
SELECT kostl, venture, egrup, recind
FROM csks
WHERE venture = '{venture}'
  AND datbi >= sy-datum
```

### Órdenes internas JV-relevantes

```sql
SELECT aufnr, venture, egrup, recind, auart
FROM aufk
WHERE venture = '{venture}'
```

### Objetos CO sin atributo JV pero con costos contabilizados en ACDOCA de un centro que debería ser JV

```sql
SELECT rcntr, racct, sum(hsl) as total
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND rcntr = '{cc}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
GROUP BY rcntr, racct
```

(Comparar el resultado contra `csks.venture` del mismo `rcntr` — si el CC no tiene venture
asignado pero tiene costos, es una bandera de revisión.)

---

## 9. Buenas Prácticas

1. **Diseñar la estructura de objetos CO pensando en JVA desde el proyecto de implementación**,
   no como un parche posterior — objetos dedicados por venture minimizan la necesidad de
   sustituciones complejas.

2. **Documentar cada regla de sustitución JVA con su propósito de negocio** — son difíciles de
   auditar si solo se lee el código técnico sin el contexto funcional.

3. **Revisar periódicamente objetos CO "huérfanos"** (sin atributo JV) que reciben costos que
   deberían ser compartidos — indicador típico de un gap de diseño o de un cambio de alcance del
   venture no reflejado en customizing.

4. **Evitar mezclar en un mismo objeto CO actividad JV y actividad 100% propia de la sociedad**
   salvo que la sustitución esté genuinamente bien probada — el riesgo de fuga de costos (JV o
   no-JV) es alto.
