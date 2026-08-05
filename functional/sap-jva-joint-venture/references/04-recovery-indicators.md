# Recovery Indicators (RI) — Núcleo de Decisión de SAP JVA

## 1. Introducción

El Recovery Indicator (RI) es la pieza de customizing más consultada en cualquier diagnóstico JVA:
determina qué hace el sistema con cada línea de costo/ingreso JV-relevante en el momento del
cutback. Si el Recovery Indicator no está bien parametrizado o mal derivado en la línea, el
resultado del cutback será incorrecto aunque el Venture y el Equity Group estén perfectos.

---

## 2. Qué Decide un Recovery Indicator

Para cada línea que llega al cutback con un RI asignado, el sistema resuelve (según la
parametrización de ese RI):

1. **¿Se distribuye entre los partners del Equity Group, o queda 100% en el operador?**
2. **¿Dispara cálculo de overhead recovery adicional?**
3. **¿Es meramente informativo/estadístico** (se registra pero no genera obligación de cobro)?
4. **¿Requiere tratamiento especial** (non-consent, carried interest) que redirige a un
   subconjunto distinto de partners?

**Tabla de customizing:** `T8J3`

| Campo (orientativo) | Descripción |
|---|---|
| RECIND | Clave del Recovery Indicator |
| RITXT | Descripción |

La lógica de comportamiento detrás de cada RI (billable, overhead, non-billable) se define en
transacciones de customizing adicionales de JVA — no toda la parametrización vive en una única
tabla plana; algunos comportamientos se controlan por configuración adicional asociada al RI y por
el tipo de valor (`value type`) de la línea.

---

## 3. Categorías Típicas de Recovery Indicator

| Categoría | Comportamiento |
|---|---|
| **Billable / recuperable** | El costo se distribuye entre partners según % del Equity Group; genera obligación de cobro (JIB) |
| **Non-billable / propio del operador** | El costo NO se distribuye; permanece 100% en los libros del operador. Uso típico: gastos que el JOA excluye explícitamente de reembolso |
| **Overhead-applicable** | Además de distribuirse (o no), dispara el cálculo de recargo de gastos generales del venture |
| **Estadístico/informativo** | Se registra para trazabilidad y análisis, sin efecto de cobro real |

---

## 4. Cómo se Asigna el RI a una Línea

1. **Por defecto desde el maestro del objeto CO** (centro de coste, orden, WBS) — el RI
   "default" configurado en el objeto se propone en cada contabilización.
2. **Por sustitución JVA** — puede sobrescribirse según cuenta contable, clase de coste, tipo de
   documento u otras condiciones (ver `03-jv-relevant-cost-objects.md` §5).
3. **Manualmente en la contabilización** — en ciertos escenarios de contabilización manual con
   pantallas habilitadas para JVA, el usuario puede indicar el RI explícitamente.

---

## 5. Diagnóstico: "El Costo No se Distribuyó Como Esperaba"

Checklist de verificación en orden:

1. ¿La línea llegó a ACDOCA con `Venture`/`Equity Group`/`RECIND` poblados? (si están vacíos, la
   línea nunca entró al alcance JVA)
2. ¿El RI asignado es el esperado, o hay una sustitución que lo cambió? (revisar `GGB1` y el log
   de sustitución si está disponible)
3. ¿El RI asignado está parametrizado como se espera (billable vs non-billable vs overhead)?
   Confirmar en customizing, no asumir por el nombre del RI
4. ¿El Equity Group vigente en la fecha del documento es el correcto? (un RI "billable" perfecto no
   sirve de nada si el % de partners de ese periodo está mal)
5. ¿La corrida de cutback (`GJ04`) realmente procesó ese objeto/Cutback Group y ese periodo?
   (revisar `GJHIST`)

---

## 6. Recovery Indicators y Non-Consent

Cuando una operación específica dentro del venture tiene partners que no consintieron
participar (ver `11-non-consent-adjustments.md`), normalmente se necesita un RI dedicado (o un
Equity Group dedicado a esa operación) para que el cutback excluya a esos partners únicamente para
esa línea/actividad, sin afectar el reparto estándar del resto del venture.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Catálogo de Recovery Indicators configurados

```sql
SELECT recind, ritxt
FROM t8j3
ORDER BY recind
```

### Líneas GJUBI agrupadas por Recovery Indicator para un venture/periodo

```sql
SELECT recind, count(*) as lineas, sum(wkgbtr) as monto_total
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
GROUP BY recind
```

### Objetos CO con Recovery Indicator asignado vs sin asignar

```sql
SELECT kostl, venture, recind
FROM csks
WHERE venture = '{venture}'
  AND (recind IS NULL OR recind = '')
```

---

## 8. Errores Frecuentes Relacionados a Recovery Indicator

| Situación | Causa típica | Acción |
|---|---|---|
| Costo no aparece en billing del partner | RI configurado como non-billable cuando debía ser billable | Revisar parametrización del RI en customizing, corregir y re-ejecutar cutback del periodo |
| Overhead no se calculó | RI no tiene marcada la bandera de overhead-applicable | Ajustar customizing del RI (afecta a futuro; periodos ya cerrados requieren ajuste manual) |
| Todo el costo de un objeto compartido cae en un único venture | Falta sustitución que discrimine por venture real de la línea | Diseñar/corregir regla de sustitución `GGB1` |
| RI correcto pero Equity Group vencido | Vigencia de Equity Group no cubre la fecha del documento | Extender o crear nuevo periodo de Equity Group, re-ejecutar cutback |

---

## 9. Buenas Prácticas

1. **Mantener un catálogo de RI corto y bien documentado** (idealmente menos de 10-15 valores
   distintos a nivel global) — un catálogo con decenas de RIs poco diferenciados es
   ingobernable en auditoría.

2. **Nombrar los RI de forma autoexplicativa** en su descripción (`RITXT`), no solo con un código
   interno — facilita revisiones funcionales rápidas.

3. **Versionar cualquier cambio de comportamiento de un RI existente** con fecha de vigencia clara
   comunicada al equipo de cierre — cambiar el comportamiento de un RI "en caliente" afecta
   retroactivamente el próximo cutback si no se controla el alcance.

4. **Antes de re-parametrizar un RI, simular su efecto en un venture de prueba** — el impacto de
   un cambio de comportamiento (billable → non-billable) puede ser significativo en el resultado
   financiero de todos los ventures que lo usan.
