# Farm-in / Farm-out y Carried Interest (SAP JVA)

## 1. Introducción

Los cambios de participación en un venture — ya sea por venta parcial de interés (farm-out),
adquisición (farm-in), o acuerdos de financiamiento diferido (carried interest) — son eventos de
negocio frecuentes en la industria Oil & Gas y requieren mantenimiento cuidadoso del Equity Group
para que el cutback refleje correctamente el reparto vigente en cada fecha.

---

## 2. Farm-out y Farm-in

- **Farm-out**: un partner (el "farmor") cede parte o la totalidad de su participación (working
  interest) en un venture a un tercero, a cambio de una contraprestación — puede ser dinero, o que
  el tercero asuma la obligación de financiar cierta actividad futura (ej. cubrir el costo de
  perforación de los próximos N pozos).
- **Farm-in**: la perspectiva del tercero (el "farmee") que adquiere la participación cedida.

**Impacto en JVA:**

1. Se determina la fecha efectiva del cambio de participación
2. Se crea un **nuevo periodo de Equity Group** con `VALFR` = fecha efectiva, reflejando los nuevos
   porcentajes (el farmor con % reducido o cero, el farmee incorporado con su nuevo %)
3. El periodo de Equity Group anterior se cierra con `VALTO` = día previo, preservando el
   histórico para cutback de periodos previos a la fecha efectiva
4. Se debe asegurar que el nuevo partner (farmee) esté correctamente dado de alta como Business
   Partner con los datos necesarios para JIB (ver `02-venture-partner-master-data.md`)

---

## 3. Carried Interest

En un acuerdo de **carried interest**, un partner (el "carried party") no paga su porción de
ciertos costos hasta que se cumple una condición contractual — típicamente hasta que el pozo
alcanza "first oil" (primera producción comercial) o hasta que se recupera cierta inversión. Otro
partner (el "carrying party", frecuentemente el operador u otro socio con mayor capacidad
financiera) adelanta esa porción.

**Mecánica típica:**

1. Durante el periodo de "carry", el cutback distribuye el costo del carried party hacia el
   carrying party (no hacia el carried party directamente) — esto requiere un Equity Group o
   Recovery Indicator especial para ese periodo, distinto del reparto estándar
2. Una vez cumplida la condición de recuperación, el carried party comienza a asumir su propia
   porción normalmente, y en muchos acuerdos además "repaga" al carrying party el monto adelantado
   más un rendimiento pactado (mediante cargos adicionales fuera del reparto normal de costo, según
   los términos del contrato)

**Nota de honestidad técnica:** SAP JVA no tiene, en el estándar, un objeto llamado literalmente
"carried interest" — el patrón funcional descrito arriba es la forma habitual de modelarlo con las
piezas estándar del módulo (Equity Group con vigencia, Recovery Indicator dedicado). La
recuperación del monto adelantado (repago con rendimiento) suele requerir tratamiento adicional
fuera del cutback estándar, y en implementaciones complejas puede apoyarse en desarrollo
específico o en procesos manuales controlados — confirmar siempre el diseño real implementado en
el sistema del cliente antes de asumir que existe automatización estándar para esta parte.

---

## 4. Consideraciones de Diseño

- **Nunca modificar retroactivamente un Equity Group ya usado en cutback de periodos cerrados**
  para reflejar un farm-in/out — siempre crear un nuevo periodo de vigencia
- **Validar la fecha efectiva contractual** (fecha de cierre de la transacción, que puede diferir
  de la fecha de firma del acuerdo) antes de fijar `VALFR`
- **Comunicar el cambio a todos los equipos dependientes** (facturación, reporting, AR) antes del
  siguiente ciclo de cutback, para evitar sorpresas en el billing del periodo de transición

---

## 5. Consultas MCP Útiles (GetSqlQuery)

### Historial de vigencias de Equity Group de un venture (para rastrear farm-in/out históricos)

```sql
SELECT venture, egrup, valfr, valto
FROM t8j2
WHERE venture = '{venture}'
ORDER BY valfr
```

### Verificar el primer periodo de cutback donde participa un nuevo partner

```sql
SELECT gjahr, monat, min(belnr) as primer_documento
FROM gjubi
WHERE venture = '{venture}'
  AND partner = '{nuevo_partner}'
GROUP BY gjahr, monat
ORDER BY gjahr, monat
```

---

## 6. Errores Frecuentes

| Error | Causa | Fix |
|---|---|---|
| Cutback de un periodo usa el % de participación incorrecto tras un farm-out | Vigencia de Equity Group con fecha efectiva mal fijada | Corregir `VALFR`/`VALTO` y re-ejecutar cutback del periodo de transición |
| Nuevo partner (farmee) no recibe billing | Business Partner no configurado a tiempo con los datos requeridos para JIB | Completar alta del partner antes del primer cutback donde debe participar |
| Carried party recibe billing durante el periodo de carry | Recovery Indicator/Equity Group especial no aplicado correctamente | Revisar y corregir la asignación del objeto CO para el periodo de carry |

---

## 7. Buenas Prácticas

1. **Formalizar un checklist de "onboarding de cambio de equity"** que cubra: nuevo Equity Group,
   alta de partner, comunicación a equipos de billing, antes de que se acerque el siguiente cierre.

2. **Documentar cada acuerdo de carried interest con sus condiciones de terminación** de forma
   accesible para el equipo funcional, no solo en el contrato legal — facilita saber cuándo debe
   cambiar la parametrización.

3. **Simular el primer cutback tras un farm-in/out en modo prueba** con especial atención, dado que
   es el periodo con mayor probabilidad de error de vigencia.
