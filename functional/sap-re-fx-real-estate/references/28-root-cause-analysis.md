# Root Cause Analysis — SAP RE-FX

## 1. Metodología General

Ante cualquier incidente RE-FX, seguir un análisis en capas, desde el dato transaccional hacia el
customizing, sin saltar pasos:

```
1. Síntoma reportado (ej. "el inquilino X no fue facturado en el periodo Y")
2. ¿El Rental Object tiene un contrato vinculado y vigente en la fecha? (VICNCN)
3. ¿El contrato está en estado activo (liberado), no en borrador/bloqueado?
4. ¿Existe una condición de renta vigente que cubra la fecha de facturación? (VICNCND)
5. ¿El Business Partner del inquilino tiene el rol FI-AR completo?
6. ¿La corrida de facturación periódica del periodo procesó ese contrato/objeto?
7. ¿La partida FI-AR se generó y contabilizó correctamente en ACDOCA?
```

## 2. Caso Tipo 1 — "No se facturó la renta del periodo"

- Verificar primero la vigencia del contrato y de la condición de renta (pasos 2-4 del árbol)
- Si ambos son correctos, verificar el rol FI-AR del Business Partner — causa frecuente cuando el
  inquilino es nuevo y el maestro aún no está completo
- Si todo lo anterior es correcto, verificar si la corrida de facturación periódica simplemente no
  se ejecutó aún para ese periodo/objeto

## 3. Caso Tipo 2 — "El monto de la liquidación de gastos comunes no coincide con lo esperado"

- Confirmar el factor de reparto real mantenido en el Grupo de Participación vigente para el
  periodo (no el grupo "actual" si hubo cambios de composición posteriores)
- Verificar si hay objetos vacantes cuyo tratamiento de costo pueda estar afectando el cálculo de
  forma inesperada
- Verificar si el costo real recolectado del periodo está completo (todas las facturas/documentos
  de costo ya contabilizados antes de correr la liquidación)

## 4. Caso Tipo 3 — "El ROU asset o el pasivo por arrendamiento tienen un monto inesperado"

- Confirmar los componentes de la medición inicial: pagos de arrendamiento incluidos, tasa de
  descuento aplicada, plazo del arrendamiento considerado (incluyendo opciones de renovación
  evaluadas como razonablemente ciertas)
- Verificar si hubo un evento de modificación de contrato o cambio en la evaluación de opciones que
  debió disparar una remedición y no se procesó
- Contrastar contra la política contable documentada del cliente (no solo contra el customizing
  técnico) — algunas diferencias son válidas si la política define un tratamiento específico

## 5. Caso Tipo 4 — "Diferencia entre superficie facturada y superficie física real"

- Rastrear la superficie registrada en el Rental Object y compararla contra el Architectural Object
  vinculado, si existe
- Confirmar bajo qué estándar de medición se registró la superficie (GIF, BOMA, otro) y si coincide
  con el estándar pactado en el contrato
- Si hay disputa del inquilino, evaluar si corresponde una remedición formal y su impacto
  retroactivo en la renta ya facturada

## 6. Caso Tipo 5 — "Disputa de inquilino sobre un cargo específico de gastos comunes"

- Rastrear la línea desde el resultado de la liquidación hasta su documento de origen en `ACDOCA`
- Confirmar el factor de reparto aplicado y el Grupo de Participación correspondiente
- Contrastar contra el contrato de arrendamiento (no solo contra el customizing técnico) — algunas
  disputas son válidas desde la óptica contractual aunque el sistema haya calculado exactamente lo
  que el customizing indicaba

## 7. Herramientas MCP para Root Cause

```
GetSqlQuery — consulta directa a VIBDBE/VIBDOB/VICNCN/VICNCND/ACDOCA/ANLA para reconstruir el camino del dato
GetWhereUsed — localizar el programa/clase que generó un mensaje de error específico
ReadClass/ReadProgram — inspeccionar la lógica de cálculo cuando el dato no explica el resultado
GetEnhancements — verificar si hay un BAdI/exit custom activo que pueda estar alterando el comportamiento estándar
```

## 8. Principio de Separación: Hecho Confirmado vs Hipótesis

En cada análisis, distinguir explícitamente:

- **Hecho confirmado**: verificado con datos reales del sistema (queries MCP)
- **Hipótesis**: explicación plausible aún no verificada con datos
- **Acción recomendada**: siguiente paso concreto, condicionado a confirmar o descartar la
  hipótesis

Esta disciplina es especialmente importante en RE-FX porque las correcciones (renta, gastos
comunes, IFRS 16) tienen impacto financiero directo hacia terceros (inquilinos) o en el balance
(activo/pasivo IFRS 16) — una hipótesis presentada como hecho puede llevar a una corrección
innecesaria o a una comunicación prematura al inquilino.
