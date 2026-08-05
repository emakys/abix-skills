# Transacciones SAP — JVA (Joint Venture Accounting)

## 1. Transacciones Núcleo JVA (familia GJxx)

| Transacción | Descripción | Notas |
|---|---|---|
| `GJ04` | Cutback Processing — ejecuta la corrida de cutback (test o producción) | Transacción más usada operativamente en JVA |
| `GJ08` | Generación de Joint Interest Billing (JIB) | Nombre/número orientativo — confirmar en el menú de aplicación del sistema real, puede variar según release |

**Nota de honestidad técnica:** la familia `GJxx` es la convención de nomenclatura conocida para
transacciones de JVA en el árbol clásico de SAP; sin embargo, no todos los números de transacción
específicos (más allá de `GJ04` como cutback) están confirmados con la misma certeza para toda
combinación de release/parche. Ante cualquier procedimiento operativo formal, confirmar el código
exacto navegando el menú de aplicación (`SAP Easy Access → Joint Venture Accounting`) o vía `SE93`
en el sistema real antes de documentarlo como definitivo.

## 2. Transacciones de Mantenimiento de Datos Maestros JVA

| Área | Transacción (familia) | Notas |
|---|---|---|
| Venture | Mantenimiento vía menú JVA / `SM30` sobre vistas de customizing | Depende de si Venture se gestiona como vista de customizing o transacción dedicada |
| Equity Group | Mantenimiento vía menú JVA / `SM30` | Igual consideración |
| Recovery Indicator | `SM30` sobre `T8J3` u otra vista de customizing asociada | Confirmar vista exacta en el sistema |

## 3. Transacciones Estándar CO/PS Reutilizadas

| Transacción | Uso en contexto JVA |
|---|---|
| `KS01`/`KS02` | Crear/modificar centro de coste — mantenimiento del atributo JV (pestaña JVA) |
| `KO01`/`KO02` | Crear/modificar orden interna — atributo JV, presupuesto de AFE simplificado |
| `KO22` | Presupuesto de orden interna (AFE modelado como orden) |
| `CJ01`/`CJ02` | Crear/modificar proyecto y WBS — atributo JV cuando el AFE se modela como proyecto |
| `GGB1` | Mantenimiento de reglas de sustitución CO — usada para sustitución de atributo JV a nivel de línea |
| `SE16N`/`GetSqlQuery` (MCP) | Consulta directa de tablas para diagnóstico |

## 4. Transacciones de Reporting

| Transacción | Uso |
|---|---|
| Reportes estándar de JVA (menú de aplicación) | Statements por partner, resumen de cutback |
| `KSB1`/`KOB1` | Partidas individuales del objeto CO origen (para trazabilidad hasta el costo real) |
| Report Painter/Writer o CDS custom | Reporting a medida de JVA cuando el estándar no cubre el formato requerido por el JOA |

## 5. Buenas Prácticas al Referenciar Transacciones

1. Documentar el código de transacción **junto con la versión de release** en cualquier
   procedimiento operativo — la nomenclatura de JVA puede diferir entre implementaciones clásicas
   (add-on IS-OIL) y JVA embebido en S/4HANA.

2. Ante duda sobre un código de transacción, preferir describir el **proceso de negocio** (ej.
   "ejecutar cutback") y remitir a `SE93`/menú de aplicación para el código exacto, en vez de
   asumir un número no verificado.
