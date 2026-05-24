# S/4HANA 2023 — Nuevas Features CO

## Margin Analysis (reemplazo CO-PA clasico)

### Ventajas sobre CO-PA clasico
- **Tiempo real**: cada factura actualiza el margen inmediatamente
- **Sin reconciliacion**: misma tabla que FI (ACDOCA)
- **Multidimensional**: analisis por cualquier caracteristica de ACDOCA
- **Fiori nativo**: apps F5889, F4012 optimizadas
- **SAC integration**: conexion directa para planning y reporting

### Migracion de CO-PA clasico
- Herramienta: `/n/FCOM/COPA_MIG`
- Se pueden mantener ambos en paralelo durante transicion
- Value fields → mapping a cuentas GL

## SAP Analytics Cloud (SAC) integration

### Planning en SAC
- SAC reemplaza BPC para planificacion CO
- Modelo: SAC planning model → write-back a S/4HANA
- Dimension mapping: CC, PC, cost element, version
- Real-time data: lectura directa de ACDOCA via CDS

### Reporting en SAC
- Live connection a S/4HANA
- CDS analytical queries como fuente
- Dashboards predefinidos para CO

## Predictive Accounting

### Impacto CO
- Pedidos de compra generan "predicted costs" en CO
- Ordenes de produccion muestran coste estimado antes de confirmacion
- Visible en reportes CC/orden como "Predicted"

### Activacion
`SPRO > Financial Accounting > Predictive Accounting > Activate`

## Central Finance (CFIN)

### CO en CFIN
- Replicacion de datos CO via SLT a sistema central
- Mapping de areas de controlling
- Consolidacion de reportes CO multi-sistema

## Intelligent Accruals Management

### Impacto CO
- Periodificaciones automaticas basadas en reglas
- Accrual Engine integrado con ACDOCA
- Elimina asientos manuales de cierre

## Extension Ledgers para CO
- Permite escenarios "what-if" en un ledger separado
- Simulate allocations sin afectar leading ledger
- Util para planificacion avanzada
