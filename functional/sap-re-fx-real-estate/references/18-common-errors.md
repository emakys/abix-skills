# Errores Comunes — SAP RE-FX (Catálogo Consolidado)

## 1. Errores de Datos Maestros — Jerarquía de Objetos

| Error | Causa | Fix |
|---|---|---|
| Rental object does not exist | Objeto no creado o clave incorrecta | Verificar en `VIBDOB`, crear vía `REBDOB` si corresponde |
| Building/Property reference invalid | Vínculo jerárquico roto (Building sin Property válida, etc.) | Corregir la asignación jerárquica del objeto |
| Superficie inconsistente entre Rental Object y Architectural Object | Remedición registrada solo en uno de los dos | Sincronizar ambos registros (ver `14-architectural-objects-measurements.md`) |

## 2. Errores de Contrato y Condiciones

| Error | Causa | Fix |
|---|---|---|
| Contract not active | Contrato en borrador o bloqueado, no liberado | Completar flujo de liberación/activación en `RECN` |
| No condition item valid for posting date | Condición sin vigencia que cubra la fecha de facturación | Extender/crear nuevo periodo de condición en `VICNCND` |
| Rental object not assigned to a contract | Falta vínculo objeto-contrato activo en la fecha | Verificar asignación y vigencia en `RECN` |
| Business Partner role missing | BP del inquilino/arrendador sin rol FI-AR/AP asignado | Completar rol en transacción `BP` |

## 3. Errores de Liquidación de Gastos Comunes

| Error | Causa | Fix |
|---|---|---|
| Settlement unit incomplete | No todos los Rental Objects asignados a la Unidad de Liquidación | Completar asignación antes de correr `RESC` |
| Apportionment factors do not total expected value | Grupo de Participación mal mantenido | Corregir factores de reparto (ver `12-participation-groups-apportionment.md`) |
| Cost missing from settlement result | Costo real no contabilizado aún contra el CC/objeto al momento de correr la liquidación | Verificar cierre de recolección de costos antes de liquidar |
| Vacant object cost not explained | Grupo de Participación no trata explícitamente la vacancia | Definir tratamiento de vacancia en el diseño del grupo (ver `09-vacancy-management.md`) |

## 4. Errores de Ajuste de Renta

| Error | Causa | Fix |
|---|---|---|
| Rent adjustment not triggered | Programación no ejecutada, o índice de referencia sin actualizar | Verificar programación y actualizar el índice |
| Calculated amount differs from expected | Fórmula de aplicación mal parametrizada (tope, aplicación parcial) | Revisar parametrización de la condición de indexación |

## 5. Errores IFRS 16 / Lease-in

| Error | Causa | Fix |
|---|---|---|
| ROU asset not generated | Contrato sin clasificación IFRS 16 completa, o clase de activo ROU no configurada | Completar parametrización IFRS 16 y customizing de clase de activo |
| Lease liability and ROU amounts inconsistent | Costos directos iniciales/incentivos mal parametrizados | Revisar componentes de la medición inicial |
| Remeasurement not applied after contract modification | Evento de modificación no disparó el recálculo | Ejecutar el proceso de remedición manualmente o revisar el trigger |

## 6. Workflow General de Diagnóstico

1. Identificar en qué fase del ciclo Lease-to-Settle ocurre el error (objetos → contrato →
   condiciones → facturación periódica → ajuste/liquidación → IFRS 16 → cierre)
2. Confirmar el texto exacto del mensaje (`T100`) si hay código de error
3. Verificar los datos reales (`VIBDBE`/`VIBDOB`/`VICNCN`/`VICNCND`/`ACDOCA`/`ANLA`) contra lo
   esperado
4. Aislar si la causa es de **customizing** (Grupo de Participación, tipo de condición) o de
   **datos transaccionales** (vigencia faltante, objeto sin asignar)
5. Documentar el fix y su impacto en facturación/liquidación ya emitida, si aplica

## 7. Buenas Prácticas de Prevención

1. Validar vigencias de condiciones sin huecos antes de cada corrida de facturación periódica.
2. Reconciliar liquidación de gastos comunes vs costo real (`ACDOCA`) antes de emitir al inquilino.
3. Completar clasificación IFRS 16 en el momento de creación del contrato lease-in, no después.
4. Mantener un catálogo corto y bien documentado de tipos de condición y Grupos de Participación.
