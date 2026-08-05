# Root Cause Analysis — SAP JVA

## 1. Metodología General

Ante cualquier incidente JVA, seguir un análisis en capas, desde el dato transaccional hacia el
customizing, sin saltar pasos:

```
1. Síntoma reportado (ej. "el partner X no recibió billing del periodo Y")
2. ¿El objeto CO de origen tiene atributo JV completo? (Venture/Equity Group/Recovery Indicator)
3. ¿La línea llegó a ACDOCA con ese atributo? (o se perdió por una sustitución que la vació)
4. ¿El Equity Group vigente en la fecha cubre el periodo, y el partner está incluido en él?
5. ¿El Recovery Indicator de la línea está parametrizado como billable?
6. ¿La corrida de cutback (GJ04) del periodo procesó ese objeto/Cutback Group?
7. ¿El billing (JIB) se generó tras el cutback, y se generó incluyendo a ese partner?
```

## 2. Caso Tipo 1 — "El costo no se distribuyó"

- Verificar primero que el objeto CO tiene atributo JV (paso 2 del árbol)
- Si tiene atributo, verificar el Recovery Indicator (¿es non-billable por diseño, o es un error?)
- Si el RI es correcto y billable, verificar el Equity Group vigente en la fecha exacta del
  documento — la causa más común en este punto es un hueco de vigencia
- Si todo lo anterior es correcto, verificar `GJHIST` — puede que el cutback simplemente no se
  haya ejecutado aún para ese periodo/objeto

## 3. Caso Tipo 2 — "El monto distribuido no coincide con el % esperado"

- Confirmar el % real mantenido en el Equity Group vigente para la fecha del documento (no el
  Equity Group "actual" si hubo cambios posteriores)
- Verificar si hay overhead aplicado que esté sumándose al monto base, confundiendo la
  comparación
- Verificar si la línea corresponde a una operación non-consent con Equity Group dedicado distinto
  al estándar del venture

## 4. Caso Tipo 3 — "Diferencia entre costo 100% y total distribuido en el cierre"

- Ejecutar la reconciliación estándar GJUBI vs ACDOCA (ver `10-settlement-closing.md`)
- Clasificar cada línea de diferencia en: (a) non-billable por diseño — esperado, (b) sin atributo
  JV — gap a corregir, (c) fuera del alcance de la corrida de cutback (Cutback Group incorrecto) —
  gap de configuración de alcance

## 5. Caso Tipo 4 — "Disputa de partner sobre un cargo específico"

- Rastrear la línea desde `GJUBI` hasta su documento de origen en `ACDOCA`
- Confirmar la clasificación contable (cuenta) y el Recovery Indicator aplicado
- Contrastar contra el JOA (no solo contra el customizing técnico) — algunas disputas son válidas
  desde la óptica contractual aunque el sistema haya calculado exactamente lo que el customizing
  indicaba

## 6. Herramientas MCP para Root Cause

```
GetSqlQuery — consulta directa a T8J1/T8J2/T8J3/GJUBI/GJHIST/ACDOCA para reconstruir el camino del dato
GetWhereUsed — localizar el programa/función que generó un mensaje de error específico
ReadClass/ReadProgram — inspeccionar la lógica de derivación o cálculo cuando el dato no explica el resultado
GetEnhancements — verificar si hay un BAdI/exit custom activo que pueda estar alterando el comportamiento estándar
```

## 7. Principio de Separación: Hecho Confirmado vs Hipótesis

En cada análisis, distinguir explícitamente:

- **Hecho confirmado**: verificado con datos reales del sistema (queries MCP)
- **Hipótesis**: explicación plausible aún no verificada con datos
- **Acción recomendada**: siguiente paso concreto, condicionado a confirmar o descartar la
  hipótesis

Esta disciplina es especialmente importante en JVA porque las correcciones tienen impacto
financiero directo en terceros (partners) — una hipótesis presentada como hecho puede llevar a una
corrección innecesaria o a una comunicación prematura al partner.
