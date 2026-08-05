# Gestión de Vacancia — SAP RE-FX

## 1. Introducción

Un Rental Object sin contrato vigente está **vacante**. La gestión de vacancia no es solo una
métrica de reporting: tiene impacto directo en la liquidación de gastos comunes (¿quién paga los
costos de un objeto sin inquilino?) y en el reconocimiento contable de costos que, sin ingreso de
renta que los compense, deben tratarse explícitamente.

---

## 2. Identificación de Vacancia

Un Rental Object está vacante cuando no tiene un contrato activo vinculado en la fecha de análisis.
Puede ser:

- **Vacancia estructural**: el objeto nunca fue arrendado desde su alta (ej. unidad recién
  construida, aún en comercialización)
- **Vacancia por rotación (turnover vacancy)**: el objeto tuvo inquilino previo y quedó vacante tras
  la finalización/rescisión de ese contrato
- **Vacancia por remodelación**: el objeto está fuera de disponibilidad comercial temporalmente por
  obras, no cuenta como vacancia "comercializable" en el mismo sentido

---

## 3. Impacto en la Liquidación de Gastos Comunes

Cuando un Rental Object está vacante, sus costos de gastos comunes (parte proporcional que le
correspondería si tuviera inquilino) no pueden trasladarse a un inquilino inexistente. El diseño
del Grupo de Participación debe resolver explícitamente esta situación:

- **El costo de la vacancia queda a cargo del propietario/operador** (patrón más común): se excluye
  al objeto vacante del reparto entre los inquilinos ocupados, y el costo correspondiente se
  contabiliza como gasto propio del arrendador
- **Redistribución entre los inquilinos ocupados**: en algunos diseños contractuales (menos
  favorables al inquilino, y no siempre permitido según jurisdicción/regulación), el costo de la
  vacancia se reparte proporcionalmente entre los inquilinos activos

**Riesgo funcional si no se resuelve explícitamente:** si el Grupo de Participación no contempla la
vacancia, el sistema puede excluir simplemente al objeto vacante del prorrateo sin redirigir su
costo a ningún lado — el costo "desaparece" del reporting de liquidación aunque siga existiendo
contablemente, generando una diferencia no explicada en la reconciliación de cierre.

---

## 4. Contabilización de Costos de Vacancia (One-Time Postings)

Para objetos vacantes de valor significativo o vacancia prolongada, es práctica común generar
contabilizaciones puntuales (one-time postings) que reflejen el costo de mantener el objeto
disponible sin ingreso — relevante para el análisis de rentabilidad real del portafolio, que de lo
contrario subestimaría el costo total de mantener capacidad vacante.

---

## 5. Consultas MCP Útiles (GetSqlQuery)

### Rental Objects vacantes de un Building a la fecha actual

```sql
SELECT ob.meinh, ob.mebez
FROM vibdob ob
WHERE ob.gebaeude = '{building}'
  AND ob.meinh NOT IN (
    SELECT vertrag FROM vicncn
    WHERE vbegdat <= CURRENT_DATE AND venddat >= CURRENT_DATE
  )
```

### Tasa de vacancia por Business Entity (conteo simple)

```sql
SELECT
  count(*) as total_objetos,
  sum(case when meinh not in (select vertrag from vicncn where vbegdat <= current_date and venddat >= current_date) then 1 else 0 end) as objetos_vacantes
FROM vibdob
WHERE swenr = '{business_entity}'
```

*(Consulta simplificada con fines de diagnóstico rápido — para reporting formal de tasa de
vacancia, preferir una CDS View o reporte estándar que maneje correctamente los cruces de vigencia
histórica, ver `22-reporting.md` y `27-embedded-analytics.md`.)*

---

## 6. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Costo de objeto vacante "desaparece" de la liquidación | Grupo de Participación no contempla explícitamente el tratamiento de la vacancia |
| Objeto marcado como vacante pero en realidad tiene contrato próximo a iniciar | Fecha de inicio del nuevo contrato aún no alcanzada — vacancia técnica correcta hasta esa fecha |
| Tasa de vacancia reportada no cuadra con la percepción del negocio | Objetos en remodelación incluidos/excluidos incorrectamente según el criterio de reporte usado |

---

## 7. Buenas Prácticas

1. **Definir explícitamente en el diseño del Grupo de Participación qué pasa con el costo de
   objetos vacantes** — no dejarlo como comportamiento implícito del sistema.

2. **Distinguir en el reporting entre vacancia comercializable y objetos fuera de servicio por
   remodelación** — mezclarlos distorsiona la métrica de vacancia real que el negocio necesita para
   decisiones comerciales.

3. **Monitorear la tasa de vacancia por segmento (tipo de uso, Business Entity)** — una vacancia
   concentrada en un segmento específico suele indicar un problema de precio o de calidad del
   espacio, información valiosa para el negocio más allá del reporting financiero.

4. **Registrar contablemente el costo de vacancia prolongada** en vez de dejarlo diluido en el
   costo operativo general — mejora la visibilidad real de rentabilidad del portafolio.
