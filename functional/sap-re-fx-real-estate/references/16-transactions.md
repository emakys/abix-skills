# Transacciones SAP — RE-FX (Flexible Real Estate Management)

## 1. Transacciones de Datos Maestros — Jerarquía de Objetos

| Transacción | Descripción |
|---|---|
| `REBDBE` | Crear/modificar/visualizar Business Entity |
| `REBDPR` | Crear/modificar/visualizar Property |
| `REBDBU` | Crear/modificar/visualizar Building |
| `REBDOB` | Crear/modificar/visualizar Rental Object |

Las transacciones de objetos inmobiliarios en RE-FX suelen manejar crear/modificar/visualizar bajo
un mismo código con distinto modo de acceso (patrón habitual en el árbol de aplicación RE-FX), a
diferencia de la convención clásica de 3 transacciones separadas (crear/cambiar/visualizar) de
otros módulos como PM o MM.

## 2. Transacciones de Contrato

| Transacción | Descripción |
|---|---|
| `RECN` | Crear/modificar/visualizar contrato (lease-out, lease-in, general) |

## 3. Liquidación de Gastos Comunes

| Transacción | Descripción | Notas |
|---|---|---|
| `RESC` | Liquidación de gastos comunes (Service Charge Settlement) | |
| `RECEEC` | Transacción relacionada a liquidación/gastos comunes | Nombre/alcance exacto orientativo — confirmar en el menú de aplicación del sistema real |

## 4. Ajuste de Renta

| Transacción | Descripción |
|---|---|
| `RERAADJUST` | Ejecución de ajuste de renta (índice, escalonado, comparativo, según parametrización del contrato) |

**Nota de honestidad técnica:** más allá de las transacciones núcleo listadas arriba (`REBDBE`,
`REBDPR`, `REBDBU`, `REBDOB`, `RECN`, `RESC`, `RERAADJUST`), existen numerosas transacciones
adicionales de RE-FX (reporting, correspondencia, IFRS 16, gestión de vacancia) cuyo código exacto
conviene confirmar navegando el menú de aplicación (`SAP Easy Access → Flexible Real Estate
Management`) o vía `SE93` en el sistema real antes de documentarlas como definitivas en un
procedimiento operativo formal.

## 5. Transacciones Estándar CO/FI/FI-AA Reutilizadas

| Transacción | Uso en contexto RE-FX |
|---|---|
| `BP` | Mantenimiento de Business Partner (inquilinos, arrendadores externos, garantes) |
| `KS01`/`KS02` | Centro de coste — cuando el objeto de renta tiene asignación CO |
| `AS01`/`AS02` | Activo fijo — inmueble propio o clase de activo ROU |
| `SE16N`/`GetSqlQuery` (MCP) | Consulta directa de tablas para diagnóstico |

## 6. Transacciones de Reporting

| Transacción | Uso |
|---|---|
| Reportes estándar del menú RE-FX | Cartera de contratos, vacancia, vencimientos próximos |
| `KSB1`/`KOB1` | Partidas individuales del objeto CO/orden asociado al inmueble |
| Fiori apps analíticas | Reporting moderno sobre CDS Views de RE-FX (ver `24-fiori-apps.md`) |

## 7. Buenas Prácticas al Referenciar Transacciones

1. Documentar el código de transacción **junto con la versión de release** — RE-FX evolucionó
   significativamente desde el RE clásico y algunos clientes aún operan mezclas de convención
   antigua/nueva en documentación interna desactualizada.

2. Ante duda sobre un código de transacción específico de un proceso menos frecuente (ej. una
   variante puntual de liquidación), preferir describir el **proceso de negocio** y remitir a
   `SE93`/menú de aplicación para el código exacto, en vez de asumir un número no verificado.
