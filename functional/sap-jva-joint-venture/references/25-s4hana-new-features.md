# Novedades S/4HANA — SAP JVA

## 1. Contexto General

JVA es un módulo de industria (Oil & Gas / Energy) que ha evolucionado de forma más conservadora
que los módulos genéricos S/4HANA en cada release. Las novedades relevantes tienden a concentrarse
en la **integración con el Universal Journal** y en mejoras incrementales de proceso, más que en
un rediseño arquitectónico completo del módulo (a diferencia de, por ejemplo, CO-PA → Margin
Analysis).

## 2. Integración con ACDOCA / Universal Journal

- Las líneas JV-relevantes conviven con FI/CO en `ACDOCA`, lo que simplifica el reporting
  comparado con el modelo de tablas de totales separadas de ECC (ver `23-s4hana-data-model.md`)
- Se reduce la necesidad de reconciliar múltiples tablas de totales clásicas (`COSP`/`COSS`) para
  obtener el costo 100% base del cutback

## 3. Simplificaciones de Proceso

- El principio general de "instant insight" del Universal Journal beneficia indirectamente a JVA:
  el costo 100% booked está disponible en tiempo real para análisis antes incluso de correr el
  cutback formal, útil para estimaciones y seguimiento de AFE

## 4. Áreas Donde JVA Mantiene Comportamiento Clásico

- El proceso transaccional de cutback y billing (`GJ04` y análogos) mantiene su lógica y
  transacciones históricas — no fue rediseñado como un flujo Fiori nativo
- La cobertura Fiori sigue siendo limitada (ver `24-fiori-apps.md`)

## 5. Nota de Honestidad Técnica

Este documento describe las tendencias generales y confirmadas de cómo JVA se beneficia de la
arquitectura S/4HANA (Universal Journal). **No se enumeran features puntuales de un release
específico (ej. "S/4HANA 2023 FPS02 agregó X") porque el detalle exacto de notas de release de JVA
requiere verificación directa contra el SAP Release Note Search / SAP for Me del cliente** — la
cadencia de innovación de JVA es menor y más específica de parche que la de módulos genéricos, y
afirmar una fecha o versión concreta sin esa verificación sería especulativo.

## 6. Recomendación para Proyectos de Upgrade

1. Antes de un upgrade/migración a S/4HANA de un landscape con JVA clásico (IS-OIL), revisar
   específicamente las notas SAP de compatibilidad de JVA para el release destino — no asumir
   compatibilidad automática solo porque otros módulos FI/CO migran sin problemas
2. Validar con pruebas de cutback/billing en un sistema de prueba post-migración antes de dar por
   completo el proyecto — es un módulo de bajo volumen de usuarios pero alto impacto financiero por
   transacción (montos de reparto entre partners suelen ser significativos)
