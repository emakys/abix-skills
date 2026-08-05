# Fiori Apps — SAP RE-FX

## 1. Cobertura Fiori de RE-FX (Honestidad Técnica)

RE-FX tiene cobertura Fiori **desigual**: más moderna que módulos de industria clásicos como JVA en
el área de gestión de objetos y contratos, pero con procesos batch pesados (liquidación de gastos
comunes, ajuste de renta masivo) que en muchas implementaciones siguen apoyándose en transacciones
clásicas de SAP GUI. No se debe asumir ni inventar nombres específicos de apps Fiori de RE-FX sin
haberlos confirmado en el catálogo de apps del sistema del cliente (`Fiori Apps Reference Library`
o el launchpad real).

## 2. Áreas con Mejor Cobertura Fiori Esperable

- **Gestión de contratos**: apps de tipo "Manage Real Estate Contracts" (nombre orientativo — el
  concepto de gestión de contrato vía Fiori es razonable de esperar en un release moderno, pero el
  nombre exacto de la app debe confirmarse en el catálogo del cliente)
- **Consulta de objetos inmobiliarios**: visualización de la jerarquía de portafolio
- **Dashboards analíticos**: ocupación, vacancia, vencimientos próximos — construidos sobre CDS
  Views (embedded analytics), con alto valor de negocio y buen ajuste al patrón Fiori

## 3. Qué Puede Seguir Siendo SAP GUI / Transacción Clásica

- Configuración detallada de Grupos de Participación y factores de reparto complejos
- Ejecución de corridas masivas de liquidación de gastos comunes y ajuste de renta
- Configuración fina de la parametrización IFRS 16 en escenarios contractuales complejos

## 4. Recomendación de Alcance en Proyectos

- No prometer al negocio una experiencia 100% Fiori para el ciclo operativo completo de RE-FX en
  la definición de alcance de un proyecto sin antes verificar qué apps existen realmente en el
  catálogo del release contratado
- Priorizar el desarrollo/activación de apps analíticas Fiori (ocupación, vacancia, cartera de
  contratos) como área de alto retorno de inversión, incluso si algunos procesos batch pesados
  permanecen en transacción clásica
- Validar específicamente la cobertura Fiori de gestión de contrato con el cliente, ya que es el
  área donde RE-FX suele tener mejor soporte moderno comparado con otros módulos de industria

## 5. Buenas Prácticas

1. Verificar siempre en la `Fiori Apps Reference Library` del release contratado antes de
   documentar o prometer una app Fiori específica de RE-FX.
2. Si el negocio requiere una experiencia moderna en procesos batch pesados que aún son clásicos,
   evaluar apps analíticas custom (embedded analytics) como la vía más realista de mejora de UX en
   el corto plazo, sin re-arquitecturar el proceso batch en sí.
3. Comunicar con transparencia cualquier limitación de cobertura Fiori identificada durante el
   fit-gap — es una característica real del release, no necesariamente un gap de implementación.
