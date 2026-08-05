# Embedded Analytics — SAP RE-FX

## 1. Por Qué Embedded Analytics es Especialmente Relevante en RE-FX

Dado que la cobertura Fiori transaccional de RE-FX es desigual (ver `24-fiori-apps.md`) y que el
negocio necesita constantemente visibilidad de ocupación, vencimientos y rentabilidad del
portafolio, el área de mayor valor incremental para modernizar la experiencia sin tocar el núcleo
transaccional es el **reporting analítico embebido** sobre CDS Views.

## 2. Fuentes de Datos para CDS Views Custom

| Fuente | Qué aporta |
|---|---|
| `VIBDBE`/`VIBDPR`/`VIBDGB`/`VIBDOB` | Jerarquía de objetos inmobiliarios, superficie, tipo de uso, estado |
| `VICNCN`/`VICNCND` | Contratos vigentes, tipo, vigencia, condiciones |
| `ACDOCA` | Renta facturada, gastos comunes contabilizados, amortización IFRS 16 real |
| `ANLA` | Activos fijos — inmuebles propios y ROU assets |
| Business Partner (tablas centrales BP) | Enriquecimiento con datos del inquilino/arrendador |

## 3. Casos de Uso Típicos para CDS Views/Analíticas

- Dashboard de ocupación y vacancia por Business Entity/tipo de uso, con drill-down a Rental Object
- Cartera de contratos con alertas de vencimiento próximo, segmentada por valor de renta
- Reporte de liquidación de gastos comunes consolidado por edificio, con comparación anticipo vs
  real por inquilino
- Dashboard IFRS 16: saldo de pasivo por arrendamiento y ROU asset por contrato, con vencimientos
  por tramos de tiempo (útil para la nota de revelación en estados financieros)
- Análisis de rentabilidad de portafolio: ingreso por renta vs costo operativo vs depreciación,
  combinando `ACDOCA` con dimensiones de objeto inmobiliario

## 4. Consideraciones de Diseño

- Modelar las CDS Views como **capa de análisis (Consumption/Analytical)** sobre las tablas base,
  sin modificar la lógica transaccional del módulo — cumple con el principio Clean Core
- Enriquecer con descripciones de maestros (nombre de Business Entity, nombre de inquilino vía BP)
  para que los reportes sean legibles por usuarios de negocio sin necesitar conocer claves técnicas
- Diseñar con agregaciones apropiadas si el volumen de contratos/objetos es alto (portafolios
  grandes), para no penalizar el rendimiento de dashboards ejecutivos

## 5. Integración con Herramientas de Analítica Corporativa

Las CDS Views de RE-FX pueden exponerse igual que cualquier CDS analítico estándar hacia
herramientas de BI/analítica corporativa (SAP Analytics Cloud u otras), permitiendo combinar el
detalle de portafolio inmobiliario con reporting financiero corporativo más amplio — relevante para
negocios donde el inmobiliario es una línea de negocio significativa dentro de un portafolio más
diverso.

## 6. Buenas Prácticas

1. Priorizar la construcción de un dashboard de ocupación/vacancia como control operativo de alto
   valor — es de los reportes más consultados regularmente por el negocio de gestión de portafolio.
2. Versionar las CDS Views custom junto con la documentación de negocio de cada Grupo de
   Participación o clasificación IFRS 16 que consuman, para que el reporte siga siendo
   interpretable si cambia el customizing.
3. Evitar construir lógica de negocio (cálculos de liquidación o de pasivo IFRS 16) dentro de la
   CDS View — esa decisión ya está resuelta por el proceso transaccional correspondiente; la vista
   solo debe presentar el resultado, no recalcularlo.
4. Construir el dashboard IFRS 16 con el formato de desglose de vencimientos que el equipo de FI
   necesita para la nota de revelación, evitando reconstruir manualmente esa información fuera del
   sistema en cada cierre.
