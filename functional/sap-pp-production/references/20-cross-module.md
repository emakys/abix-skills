# Integracion Cross-Module PP

## PP ↔ MM (Materials Management)

### MRP genera aprovisionamiento
- MRP con BESKZ=F → solicitudes de pedido (BANFN/EBAN)
- MRP con BESKZ=E → ordenes previsionales → ordenes produccion
- Subcontratacion (SOBSL=30) → sol. pedido + provision componentes

### Movimientos de materiales
- GI 261: reduce stock componentes (MARD-LABST)
- GR 101: aumenta stock producto terminado
- Backflush: GI automatico durante confirmacion
- MATDOC (S/4) registra todos los movimientos

### Stock y reservas
- Orden produccion genera reservas (RESB)
- Reservas reducen stock disponible para ATP
- MRP considera reservas como demanda dependiente

### Datos maestros compartidos
- MARC: vistas MRP + procurement + work scheduling
- MARD: stock por almacen
- MBEW: valoracion (precio estandar para GR)

## PP ↔ CO (Controlling)

### Costes de produccion
- Orden produccion = objeto de coste CO
- Confirmaciones generan contabilizaciones de actividad
- Tarifa (CSLA) × tiempo real = coste real de operacion
- Registrado en ACDOCA (S/4HANA)

### Overhead
- CO43: aplica recargos indirectos segun costing sheet
- Costing sheet configurado en tipo de orden

### WIP y desviaciones
- KKAO: calcula WIP para ordenes abiertas
- KKS1: calcula desviaciones (ordenes DLV/TECO)
- Categorias: price, quantity, lot size, scrap, remaining

### Settlement
- CO88: liquida saldos orden a receptores
- Regla liquidacion (COBRB): define receptor (centro coste, profit center, cuenta GL)
- Varianzas → cuentas varianza en resultado

### Product costing
- CK11N/CK40N: calcula coste estandar usando BOM + routing
- Precio estandar (MBEW-STPRS) = base para valoracion GR
- Material Ledger: actual costing (diferencias)

## PP ↔ SD (Sales & Distribution)

### MTO (Make-to-Order)
- Pedido venta → MRP → orden produccion con KDAUF/KDPOS
- Stock individual por pedido (si strategy 20/50)
- Entrega desde stock individual

### ATP (Available to Promise)
- Verificacion disponibilidad considera: stock + ordenes produccion + ordenes previsionales
- MTVFP (check group) define alcance
- SD llama ATP al crear pedido venta

### Planning (MTS)
- PIR (MD61) pueden derivar de plan ventas (MC87/SOP)
- Consumo de PIR por pedidos venta (VRMOD)
- Stock libre para picking entregas (VL01N)

### Scheduling
- Fecha entrega SD → backward scheduling orden produccion
- Lead time produccion afecta fecha confirmada a cliente

## PP ↔ QM (Quality Management)

### Inspeccion en produccion
- Tipo inspeccion 03: inspeccion en fabricacion
- Se genera lote inspeccion al confirmar operacion (si configurado)
- Decision de uso determina si producto va a stock libre o bloqueado

### Stock en calidad
- GR 101 puede ir a stock QM (INSME) en vez de libre (LABST)
- Lote inspeccion → resultado → decision de uso → transferencia

### Certificados
- CoA (Certificate of Analysis) puede requerirse antes de GR
- Integrado con batch management

## PP ↔ FI (Financial Accounting)

### Via CO (indirecto)
- Settlement de ordenes genera documentos FI
- WIP → cuentas balance
- Varianzas → cuentas P&L

### Via MM (directo)
- GI 261: Debe consumo produccion / Haber stock material
- GR 101: Debe stock material / Haber produccion
- Valoracion a precio estandar (MBEW-STPRS)

### Reconciliacion
- ACDOCA contiene ambos: linea CO y linea FI
- Balance de produccion: stock inicial + GR - GI - scrap = stock final

## PP ↔ PM (Plant Maintenance)

### Disponibilidad maquinaria
- Paradas planificadas (PM) reducen capacidad disponible
- Averias (PM) causan parada no planificada → impacto en scheduling

### Puestos de trabajo compartidos
- CRHD puede usarse en PP (produccion) y PM (mantenimiento)
- Planificacion de capacidad debe considerar ambos

## PP ↔ WM/EWM (Warehouse Management)

### Staging de componentes
- Transfer order para mover componentes a area produccion
- Pick list basada en RESB (reservas)
- Automated staging en WM/EWM

### GR produccion
- Producto terminado → putaway en WM/EWM
- Determinacion automatica de storage bin

## PP ↔ PS (Project System)

### Engineer-to-Order
- WBS element como receptor de costes
- Network activities vinculadas a ordenes produccion
- Scheduling PS → restricciones PP

## Tabla resumen

| Modulo | Datos compartidos | Flujo principal |
|--------|-------------------|-----------------|
| MM | MARC, MARD, MATDOC, RESB | MRP→SolPedido, GI/GR |
| CO | ACDOCA, AUFK, COBRB | Costes, WIP, Varianzas, Settlement |
| SD | VBAK/VBAP, ATP | MTO, Disponibilidad, Planning |
| QM | QALS, QAVE | Inspeccion 03, Decision uso |
| FI | ACDOCA | Via CO settlement, via MM movimientos |
| PM | CRHD, AFIH | Capacidad compartida |
| WM/EWM | LTAP, staging | Componentes, putaway GR |
| PS | PROJ, PRPS | ETO, networks |
