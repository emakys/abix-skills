# Embedded Analytics — SAP JVA

## 1. Por Qué Embedded Analytics es Especialmente Relevante en JVA

Dado que la cobertura Fiori transaccional de JVA es limitada (ver `24-fiori-apps.md`) y que el
negocio necesita constantemente visibilidad de costo por venture/partner/periodo, el área de mayor
valor incremental para modernizar la experiencia de JVA sin tocar el núcleo transaccional es el
**reporting analítico embebido** sobre CDS Views.

## 2. Fuentes de Datos para CDS Views Custom

| Fuente | Qué aporta |
|---|---|
| `ACDOCA` | Costo real 100% booked, con todas las dimensiones contables estándar |
| `GJUBI` | Resultado del cutback: costo distribuido por partner, Recovery Indicator, overhead |
| `GJHIST` | Estado de las corridas de cutback (para dashboards de control de cierre) |
| `T8J1`/`T8J2`/`T8J3` | Maestros para enriquecer descripciones (nombre de venture, partner, RI) |

## 3. Casos de Uso Típicos para CDS Views/Analíticas

- Dashboard de exposición por venture: costo 100% vs distribuido vs pendiente de billing
- Análisis de overhead recovery acumulado por venture y comparación contra tasa contractual
- Seguimiento de AFE: ejecutado vs autorizado, con drill-down a línea de detalle
- Reporte de reconciliación GJUBI vs ACDOCA como control automatizado de cierre (alertando
  diferencias no explicadas antes del cierre formal)
- Vista consolidada de exposición de cash calls pendientes de reconciliar

## 4. Consideraciones de Diseño

- Modelar las CDS Views como **capa de análisis (Consumption/Analytical)** sobre las tablas base,
  sin modificar la lógica transaccional del módulo — cumple con el principio Clean Core
- Enriquecer con descripciones de maestros (`T8J1`/`T8J3`) para que los reportes sean legibles por
  usuarios de negocio sin necesitar conocer las claves técnicas
- Si el volumen de datos de `GJUBI` es alto en implementaciones con muchos ventures/partners,
  diseñar las vistas con agregaciones apropiadas para no penalizar el rendimiento de dashboards
  ejecutivos

## 5. Integración con Herramientas de Analítica Corporativa

Las CDS Views de JVA pueden exponerse igual que cualquier CDS analítico estándar hacia
herramientas de BI/analítica corporativa (SAP Analytics Cloud u otras), permitiendo combinar el
detalle JVA con reporting financiero corporativo más amplio — relevante quando el negocio necesita
ver el JV como parte de un portafolio de activos más grande.

## 6. Buenas Prácticas

1. Priorizar la construcción de una vista de reconciliación GJUBI vs ACDOCA como control
   automatizado — es el reporte de mayor valor preventivo para evitar cierres con diferencias sin
   explicar.
2. Versionar las CDS Views custom junto con la documentación de negocio de cada Recovery Indicator
   que consumen, para que el reporte siga siendo interpretable si cambia el customizing.
3. Evitar construir lógica de negocio (cálculos que decidan billable/non-billable) dentro de la CDS
   View — esa decisión ya está resuelta en `GJUBI` por el proceso de cutback; la vista solo debe
   presentar el resultado, no recalcularlo.
