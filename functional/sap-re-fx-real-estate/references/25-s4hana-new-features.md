# Novedades S/4HANA — SAP RE-FX

## 1. Contexto General

RE-FX, al ser ya la evolución "flexible" moderna del RE clásico, se ha beneficiado de forma más
directa de la arquitectura S/4HANA que otros módulos con legado más clásico — particularmente en la
integración con el Universal Journal y en el reconocimiento IFRS 16/ASC 842 embebido, que es una
capacidad que requirió desarrollo significativo tras la entrada en vigor de esos estándares
contables.

## 2. Integración con ACDOCA / Universal Journal

- Las líneas de renta, gastos comunes y amortización IFRS 16 conviven con FI/CO en `ACDOCA`,
  simplificando el reporting comparado con el modelo de tablas de totales separadas de ECC
- Reduce la necesidad de reconciliar múltiples fuentes para obtener una vista consolidada de
  ingreso/gasto de portafolio inmobiliario

## 3. Reconocimiento IFRS 16 / ASC 842 Embebido

La capacidad de generar automáticamente el activo ROU y el pasivo por arrendamiento desde el
contrato lease-in (ver `07-lease-in-ifrs16.md`) es una de las evoluciones funcionales más
significativas de RE-FX en el contexto S/4HANA, respondiendo directamente a la entrada en vigor de
estos estándares contables para los arrendatarios.

## 4. Business Partner Único (CVI)

La adopción de Business Partner como modelo único de socio de negocio (en vez de mantener
Customer/Vendor separados para inquilinos/arrendadores) simplifica el mantenimiento de datos
maestros y habilita análisis 360° del socio de negocio a través de todos los procesos donde
participa, no solo RE-FX.

## 5. Áreas Donde RE-FX Mantiene Comportamiento Clásico

- Los procesos batch pesados de liquidación de gastos comunes y ajuste de renta masivo mantienen
  su lógica y transacciones históricas en gran medida
- La cobertura Fiori, aunque mejor que en módulos de industria clásicos, sigue siendo desigual (ver
  `24-fiori-apps.md`)

## 6. Nota de Honestidad Técnica

Este documento describe las tendencias generales y confirmadas de cómo RE-FX se beneficia de la
arquitectura S/4HANA (Universal Journal, IFRS 16 embebido, Business Partner único). **No se
enumeran features puntuales de un release específico (ej. "S/4HANA 2023 FPS02 agregó X") porque el
detalle exacto de notas de release requiere verificación directa contra el SAP Release Note Search
/ SAP for Me del cliente** — afirmar una fecha o versión concreta sin esa verificación sería
especulativo.

## 7. Recomendación para Proyectos de Upgrade

1. Antes de un upgrade/migración a S/4HANA de un landscape con RE clásico (no RE-FX), evaluar el
   esfuerzo de migración de la jerarquía de objetos al modelo GPO flexible — no es un simple cambio
   de nomenclatura, implica remodelar la estructura de datos
2. Si el cliente ya tenía un proceso manual/externo de IFRS 16 antes de adoptar la funcionalidad
   embebida de RE-FX, planificar cuidadosamente la migración de contratos lease-in existentes para
   no duplicar ni perder el histórico de pasivo/ROU ya reconocido
3. Validar con pruebas de facturación periódica y liquidación de gastos comunes en un sistema de
   prueba post-migración antes de dar por completo el proyecto
