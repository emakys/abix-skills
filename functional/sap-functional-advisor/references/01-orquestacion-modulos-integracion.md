# Mapa de orquestación — las 10 super skills funcionales

El Advisor **no sabe de módulos: dirige a quien sabe.** No reproduzcas el conocimiento de
estas skills; el motor de ABIX las inyecta por match de keyword junto al Advisor. Tu trabajo
es reconocer el módulo (o la combinación), dejar que la super skill aporte la profundidad, y
tejer una respuesta única que además aplique metodología, defensa de Clean Core y handoff.

## Las 10 super skills (id → cuándo enrutar)

| Skill id | Módulo | Enruta cuando el tema es… |
|---|---|---|
| `sap-fi-accounting` | FI | GL, AP, AR, activos fijos, bancos, impuestos, pagos, cierre, estados financieros, ACDOCA |
| `sap-co-controlling` | CO | centros de costo/beneficio, órdenes internas, CO-PA / margin analysis, costeo de producto, liquidación |
| `sap-mm-procurement` | MM | compras, P2P, pedidos, solicitudes, inventario, verificación de facturas, material, liberación |
| `sap-sd-sales` | SD | ventas, O2C, pedido de venta, fijación de precios, entrega, facturación, crédito, ATP |
| `sap-pp-production` | PP | planificación de producción, MRP, órdenes de fabricación, BOM, hojas de ruta, confirmaciones |
| `sap-qm-quality` | QM | calidad, planes de inspección, lotes, resultados, decisión de empleo, notificaciones, certificados |
| `sap-ps-projects` | PS | proyectos, WBS, redes, presupuesto, reconocimiento de ingreso, liquidación, avance |
| `sap-pm-maintenance` | PM | mantenimiento, equipos, ubicaciones técnicas, planes, avisos, órdenes, preventivo/correctivo |
| `sap-hcm-hr` | HCM | recursos humanos, PA/OM, tiempos, nómina, beneficios, ESS/MSS, SuccessFactors |
| `sap-ewm-warehouse` | EWM | almacén extendido, inbound/outbound, olas, picking/packing, ubicación, RF, yard, cross-docking |

Cuando el tema cruza módulos, reconoce **todos** los involucrados y nómbralos. El valor del
Advisor es ver el bosque que cada super skill, sola, no ve.

## Matriz de integración cross-módulo (el bosque)

Antes de cerrar cualquier requerimiento, verifica los efectos cruzados:

- **FI ↔ CO** — Universal Journal (ACDOCA): un hecho CO impacta FI en tiempo real.
- **MM → FI** — valoración y determinación de cuentas (OBYC), GR/IR.
- **MM → CO** — consumos y compromisos contra centros de costo / órdenes.
- **SD → FI** — la facturación genera el documento contable (VKOA).
- **SD ↔ MM** — disponibilidad (ATP) y entrega contra stock.
- **PP ↔ MM** — MRP enlaza necesidades con aprovisionamiento; componentes y backflush.
- **PP → CO** — liquidación de orden de producción, costeo de producto.
- **QM ↔ MM** — inspección en entrada de mercancía, stock en control de calidad.
- **QM ↔ PP** — inspección en proceso durante la fabricación.
- **PS → CO** — presupuesto y liquidación de WBS.
- **PS ↔ MM** — aprovisionamiento ligado al proyecto.
- **PM ↔ MM** — repuestos y componentes de la orden de mantenimiento.
- **PM → CO** — liquidación de la orden de mantenimiento.
- **EWM ↔ MM/SD** — ejecuta los movimientos de inbound/outbound del almacén.
- **HCM → FI/CO** — contabilización de nómina a FI/CO.

Regla práctica: si un requerimiento toca importes, stock o costos, casi siempre hay un
segundo módulo en juego. Decláralo y, si aplica, deja que su super skill aporte.

## Cómo se siente la orquestación (ejemplo)

Requerimiento: *"avisar al gerente y registrar aprobación cuando un pedido supere 50k."*
El Advisor reconoce MM (aprobación de pedidos) + posible FI (cuentas) y, sobre el conocimiento
que aporta `sap-mm-procurement`, concluye: la aprobación es estándar (estrategia de
liberación) y solo la notificación es un gap que requiere desarrollo. Una sola respuesta, dos
skills, una decisión limpia — el diseño técnico de ese gap queda fuera del alcance funcional.
