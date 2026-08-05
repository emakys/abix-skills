# Fiori Apps — SAP JVA

## 1. Cobertura Fiori de JVA (Honestidad Técnica)

A diferencia de módulos genéricos como FI, CO, MM o SD — que en S/4HANA 2023 tienen un catálogo
extenso y bien documentado de Fiori apps (Manage Cost Centers, Manage Journal Entries, etc.) — JVA,
como módulo de industria con fuerte legado transaccional clásico, **tiene cobertura Fiori
limitada**. No se debe asumir ni inventar nombres específicos de apps Fiori de JVA sin haberlos
confirmado en el catálogo de apps del sistema del cliente (`Fiori Apps Reference Library` o el
launchpad real).

## 2. Qué Sigue Siendo SAP GUI / Transacción Clásica

En la mayoría de las implementaciones actuales de JVA, los procesos centrales continúan
ejecutándose vía transacciones clásicas de SAP GUI:

- Mantenimiento de Venture/Equity Group/Recovery Indicator
- Ejecución de cutback (`GJ04`)
- Generación de Joint Interest Billing

## 3. Dónde SÍ es Razonable Esperar Cobertura Fiori

- **Reporting**: statements y análisis de costo JV pueden construirse como apps analíticas Fiori
  custom sobre CDS Views (embedded analytics), incluso si el proceso transaccional en sí sigue
  siendo GUI
- **Maestros genéricos reutilizados**: si el objeto CO JV-relevante es un centro de coste u orden
  interna, las apps Fiori estándar de mantenimiento de esos objetos (donde existan) muestran los
  campos JV si el diseño de la app los incluye — pero esto depende de extensión específica del
  layout, no es out-of-the-box

## 4. Recomendación de Alcance en Proyectos

- No prometer al negocio una experiencia 100% Fiori para el ciclo operativo de JVA en la
  definición de alcance de un proyecto sin antes verificar qué apps existen realmente en el
  catálogo del release contratado
- Priorizar el desarrollo de apps analíticas Fiori (reporting) sobre intentar fiorizar el proceso
  transaccional completo, que suele tener menor retorno de inversión dado el volumen relativamente
  bajo de usuarios especializados en JVA comparado con módulos transaccionales de alto volumen

## 5. Buenas Prácticas

1. Verificar siempre en la `Fiori Apps Reference Library` del release contratado antes de
   documentar o prometer una app Fiori específica de JVA.
2. Si el negocio requiere una experiencia moderna, evaluar apps analíticas custom (embedded
   analytics) como la vía más realista de mejora de UX en el corto plazo.
3. Comunicar con transparencia esta limitación de cobertura durante el fit-gap — es una
   característica real y conocida del módulo, no un gap de implementación.
