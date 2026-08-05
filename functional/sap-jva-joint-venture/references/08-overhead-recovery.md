# Overhead Recovery — Recuperación de Gastos Generales (SAP JVA)

## 1. Introducción

Además de repartir los costos directos de operación entre partners, muchos Joint Operating
Agreements permiten al operador recuperar un **recargo por gastos generales de administración**
(overhead) asociado a la gestión del venture — personal administrativo, infraestructura de
soporte, sistemas, supervisión — que no se contabiliza directamente contra objetos CO del venture
pero que el operador incurre para poder operarlo.

---

## 2. Cómo se Calcula el Overhead

El overhead recovery en JVA típicamente se calcula como un **porcentaje aplicado sobre una base**
(el costo directo distribuido, o un componente específico como costos de perforación), definido en
el contrato JOA y parametrizado en customizing por venture o por categoría de actividad. El
cálculo se dispara durante el cutback cuando la línea tiene un Recovery Indicator marcado como
"overhead-applicable" (ver `04-recovery-indicators.md`).

**Tipos de tasa de overhead comunes en la práctica de la industria (contractual, no todos
necesariamente parametrizados igual en cada implementación):**
- Tasa fija mensual (drilling overhead / producing overhead) — un monto fijo por pozo o por
  actividad, independiente del costo real del periodo
- Tasa porcentual sobre el costo directo — un % aplicado sobre el gasto distribuido del periodo
- Tasas escalonadas (sliding scale) — el % disminuye a medida que el costo directo aumenta

La parametrización exacta de qué esquema aplica depende del diseño de customizing hecho para cada
cliente y del JOA específico; no asumir un único esquema universal sin confirmarlo en el sistema.

---

## 3. Fases del Ciclo de Vida y Overhead

Es común que el overhead recovery distinga entre fases del proyecto, porque la naturaleza y monto
del gasto administrativo varía:

- **Drilling overhead**: aplicable durante la fase de perforación de un pozo
- **Producing overhead**: aplicable una vez el pozo/campo entra en producción, normalmente una
  tasa distinta (y a menudo menor) que la de perforación

Esta distinción, cuando aplica, se refleja en Recovery Indicators diferenciados (uno para la fase
de perforación, otro para producción) sobre el mismo venture.

---

## 4. Integración con el Resultado del Cutback

El monto de overhead calculado se agrega como una línea adicional en el resultado del cutback (no
reemplaza al costo directo, se suma), y se refleja en `GJUBI` con su propio detalle, de forma que
el statement de billing al partner (ver `06-joint-interest-billing.md`) muestre claramente costo
directo distribuido + overhead recovery como conceptos separados.

---

## 5. Diagnóstico: Overhead No se Calculó o se Calculó con Monto Incorrecto

1. Confirmar que el Recovery Indicator de la línea tiene la bandera de overhead-applicable activa
2. Confirmar la tasa/parámetro de overhead vigente para el venture y la fase correspondiente en la
   fecha del documento
3. Verificar si el objeto CO/línea corresponde a la fase esperada (perforación vs producción) si el
   venture distingue tasas por fase
4. Revisar si hay un tope contractual (cap) de overhead que esté limitando el monto calculado

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Recovery Indicators con comportamiento overhead activo

```sql
SELECT recind, ritxt
FROM t8j3
WHERE recind IN (
  -- filtrar por los RI conocidos como overhead-applicable en el customizing del cliente
  '{lista_ri_overhead}'
)
```

### Monto de overhead distribuido por partner en un periodo

```sql
SELECT partner, sum(wkgbtr) as monto_overhead
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
  AND recind IN ('{lista_ri_overhead}')
GROUP BY partner
```

---

## 7. Errores Frecuentes en Overhead Recovery

| Error | Causa | Fix |
|---|---|---|
| Overhead no calculado en absoluto | RI sin bandera overhead-applicable, o tasa no configurada para el venture | Revisar y completar customizing del RI/tasa |
| Overhead calculado con tasa de fase incorrecta | Objeto CO no reclasificado al pasar de perforación a producción | Actualizar atributo/Recovery Indicator del objeto CO al cambiar de fase |
| Overhead excede el tope contractual | Falta de validación de cap en la parametrización | Implementar validación de tope si el JOA lo exige, revisar caso por caso los periodos ya facturados |
| Partner disputa el monto de overhead | Tasa aplicada no coincide con lo pactado en el JOA vigente | Revisar el JOA y ajustar customizing; comunicar la corrección formalmente al partner |

---

## 8. Buenas Prácticas

1. **Documentar la fórmula de overhead exactamente como está en el JOA**, incluyendo excepciones y
   topes, antes de parametrizarla — un desalineamiento aquí genera disputas recurrentes con
   partners.

2. **Revisar la tasa de overhead al menos anualmente** — muchos JOAs indexan la tasa a inflación o
   la renegocian periódicamente (práctica común en asociaciones tipo COPAS en la industria).

3. **Separar claramente costo directo y overhead en todo reporte y statement** — mezclar ambos
   conceptos dificulta la auditoría y la conciliación por parte del partner.

4. **Validar el cálculo de overhead en cada cutback de prueba**, no solo el reparto de costo
   directo — es un área frecuentemente subestimada en las pruebas de cierre.
