# Extensibilidad — SAP JVA (Clean Core)

## 1. Principio General

Antes de recurrir a modificación de núcleo o desarrollo clásico extenso, evaluar siempre las
opciones de extensibilidad "clean core" disponibles — aunque, como se señaló en
`17-bapis-extensions.md`, la cobertura de Key User Extensibility moderna en JVA es más limitada
que en módulos genéricos por su naturaleza de módulo de industria con legado clásico.

## 2. Custom Fields

**Dónde suele ser viable:**
- Campos informativos adicionales en el maestro de Venture o Equity Group (ej. referencia al
  número de JOA, fecha de firma del contrato) — si la infraestructura de extensibilidad estándar
  de las vistas de customizing lo permite
- Campos adicionales en el objeto CO (centro de coste/orden/WBS) más allá del atributo JV
  estándar, usando el framework estándar de Custom Fields de S/4HANA sobre esos objetos genéricos

**Dónde es menos viable sin desarrollo:**
- Campos nuevos dentro de la lógica interna de cálculo de cutback/billing (`GJUBI`) — al ser una
  tabla transaccional propia del módulo con lógica de escritura batch específica, extenderla
  requiere evaluar el punto de extensión oficial disponible, no asumir que el framework genérico
  de Custom Fields aplica automáticamente

## 3. BAdIs en el Cutback

Ejemplos de escenarios donde un BAdI en el punto de cálculo del cutback es la vía razonable:

- Fórmula de overhead recovery no estándar (sliding scale compleja, tope contractual variable por
  venture)
- Lógica de derivación de Recovery Indicator para escenarios de non-consent que exceden lo que la
  sustitución estándar (`GGB1`) puede resolver con condiciones simples
- Validaciones adicionales previas a permitir la corrida de cutback en producción (ej. bloquear si
  algún objeto CO del alcance no tiene atributo JV completo)

Ver `17-bapis-extensions.md` para el flujo de localización de estos puntos de extensión con MCP.

## 4. Custom Logic / CDS Views para Reporting

El área con mayor libertad de extensión "clean" en JVA es el **reporting**: construir CDS Views
custom sobre `GJUBI`/`ACDOCA`/`T8J1`/`T8J2` para embedded analytics (ver `27-embedded-analytics.md`)
no toca el núcleo transaccional del módulo y es la vía recomendada para necesidades de análisis no
cubiertas por reportes estándar.

## 5. Evaluación Antes de Cualquier Extensión

1. ¿El requerimiento es de **dato adicional** (campo informativo) o de **lógica de negocio**
   (cálculo, derivación, validación)?
2. Si es dato adicional → evaluar Custom Fields sobre el objeto genérico correspondiente
3. Si es lógica de negocio en el cutback/billing → localizar el BAdI/exit oficial más cercano,
   nunca modificar el programa estándar directamente
4. Si es reporting → preferir CDS View custom sobre modificación de reportes estándar

## 6. Buenas Prácticas

1. Documentar cada extensión (Custom Field o BAdI) con su justificación de negocio ligada al JOA,
   no solo con la descripción técnica.
2. Revisar el impacto de cada extensión ante cada upgrade — el legado clásico de JVA hace que la
   compatibilidad de puntos de extensión sea menos predecible que en módulos genéricos modernos.
3. Priorizar siempre CDS Views/reporting sobre extensión del proceso transaccional cuando el
   requerimiento pueda resolverse solo con mejor visibilidad de datos.
