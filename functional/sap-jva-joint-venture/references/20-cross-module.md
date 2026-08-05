# Integración Cross-Módulo — SAP JVA

## 1. JVA ↔ FI

- El resultado del Joint Interest Billing (JIB) genera partidas de cuentas por cobrar/pagar en
  FI-AR/AP contra el partner
- El cierre de periodo JVA depende de que el cierre contable FI del periodo esté sustancialmente
  completo antes de correr el cutback definitivo
- Cash calls se contabilizan como anticipo/pasivo en FI, reconciliado posteriormente contra el
  resultado del cutback

## 2. JVA ↔ CO

- Todo el mecanismo de JVA parte de objetos CO (centro de coste, orden interna, WBS) marcados como
  JV-relevantes — JVA lee y complementa la contabilización CO, no la reemplaza
- El costo 100% booked es el costo CO estándar; el cutback es una capa de reparto adicional sobre
  ese mismo costo
- Overhead recovery se contabiliza como costo adicional dentro del ciclo CO del venture

## 3. JVA ↔ MM

- Pedidos de compra y hojas de entrada de servicios marcados como JV-relevantes (heredando el
  atributo del objeto CO de imputación) alimentan directamente el ciclo de cutback
- El atributo JV debe fluir consistentemente desde el pedido de compra hasta la contabilización
  final — un pedido sin el objeto CO correcto rompe la cadena de atribución JV desde el origen

## 4. JVA ↔ PS

- Proyectos de exploración/desarrollo (AFEs complejos) se modelan como elementos WBS con atributo
  JV, con el presupuesto del proyecto alineado al AFE aprobado por los partners
- La disponibilidad presupuestaria estándar de PS es la base del control de ejecutado vs
  autorizado del AFE

## 5. JVA ↔ SD

- En escenarios de venta conjunta de producción (offtake compartido), la facturación a terceros
  puede requerir reconciliación contra la participación de cada partner en el venture
- No es el patrón más común (la venta de producción suele gestionarse por partner
  individualmente), pero aparece en acuerdos de comercialización conjunta

## 6. JVA ↔ FI-AA (Activos Fijos)

- Activos fijos compartidos (instalaciones de producción, ductos) pueden requerir distribuir
  depreciación según el % de equity del venture, dependiendo de cómo el JOA trate la propiedad de
  esos activos
- Es un escenario de diseño que debe validarse contra el contrato — no todos los JOAs comparten la
  propiedad contable del activo aunque compartan su uso

## 7. JVA ↔ Production Accounting / Gestión de Producción Upstream

- JVA reparte costo; el balanceo de producción física y las obligaciones de regalías viven en
  procesos/herramientas de production accounting, potencialmente fuera del alcance de JVA (ver
  `14-production-accounting-integration.md`)
- Ambos procesos deben compartir la misma fuente de verdad para el % de participación de cada
  partner

## 8. Matriz Resumen

| Módulo | Relación con JVA |
|---|---|
| FI | JIB genera AR/AP; cierre coordinado; cash calls como anticipo |
| CO | Base de todos los objetos JV-relevantes; cutback complementa, no reemplaza |
| MM | Compras JV-relevantes heredan atributo desde el objeto CO de imputación |
| PS | AFEs complejos modelados como WBS con atributo JV y presupuesto |
| SD | Venta conjunta de producción, reconciliación por participación (escenario menos común) |
| FI-AA | Depreciación de activos compartidos según equity, si el JOA lo contempla |
| Production Accounting | Frontera de alcance: cantidad física y regalías, fuera de JVA |
