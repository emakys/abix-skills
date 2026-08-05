# Extensibilidad — SAP RE-FX (Clean Core)

## 1. Principio General

Antes de recurrir a modificación de núcleo o desarrollo clásico extenso, evaluar siempre las
opciones de extensibilidad "clean core" disponibles. RE-FX, por su diseño orientado a objetos
relativamente moderno, tiene mejor cobertura de Key User Extensibility que módulos de industria más
clásicos (ver `17-bapis-extensions.md`).

## 2. Custom Fields

**Dónde suele ser viable:**
- Campos informativos adicionales en Business Entity/Property/Building/Rental Object (ej.
  referencia catastral, certificación energética, código de zonificación)
- Campos adicionales en el contrato para atributos de negocio no cubiertos por el estándar (ej.
  referencia a número de expediente legal, clasificación interna de riesgo del inquilino)
- Campos adicionales en el Business Partner del inquilino/arrendador, usando el framework estándar
  de extensibilidad de BP

**Dónde es menos viable sin desarrollo:**
- Lógica interna de cálculo del motor de liquidación de gastos comunes o del cálculo IFRS 16 — al
  ser procesos con lógica de cálculo específica del módulo, extenderlos requiere localizar el punto
  de extensión oficial (BAdI), no asumir que el framework genérico de Custom Fields altera el
  cálculo automáticamente

## 3. Custom Logic (BAdIs)

Ejemplos de escenarios donde un BAdI es la vía razonable:

- Fórmula de renta variable por ventas con estructura de tramos compleja no cubierta por la
  configuración estándar de la condición
- Validaciones adicionales previas a activar un contrato (ej. bloquear activación si falta
  documentación legal requerida por política interna del cliente)
- Lógica de derivación de cuenta contable para escenarios de portafolio con reglas específicas no
  cubiertas por la determinación estándar
- Cálculo de escenarios IFRS 16 atípicos (componentes variables no estándar, remediciones
  complejas) que excedan la parametrización estándar

Ver `17-bapis-extensions.md` para el flujo de localización de estos puntos de extensión con MCP.

## 4. CDS Views Custom para Reporting

El área con mayor libertad de extensión "clean" en RE-FX, igual que en otros módulos, es el
**reporting**: construir CDS Views custom sobre las tablas GPO/contrato/`ACDOCA` para embedded
analytics (ver `27-embedded-analytics.md`) no toca el núcleo transaccional del módulo y es la vía
recomendada para necesidades de análisis no cubiertas por reportes estándar (ej. dashboards de
ocupación por segmento específico del negocio del cliente).

## 5. Evaluación Antes de Cualquier Extensión

1. ¿El requerimiento es de **dato adicional** (campo informativo) o de **lógica de negocio**
   (cálculo, derivación, validación)?
2. Si es dato adicional → evaluar Custom Fields sobre el objeto genérico correspondiente
3. Si es lógica de negocio en liquidación/ajuste/IFRS 16 → localizar el BAdI oficial más cercano,
   nunca modificar el programa/clase estándar directamente
4. Si es reporting → preferir CDS View custom sobre modificación de reportes estándar

## 6. Buenas Prácticas

1. Documentar cada extensión (Custom Field o BAdI) con su justificación de negocio, no solo la
   descripción técnica — la lógica de liquidación y ajuste de renta suele tener reglas
   contractuales complejas detrás.
2. Revisar el impacto de cada extensión ante cada upgrade, especialmente en el área IFRS 16 dado
   que es funcionalidad relativamente reciente y sujeta a evolución continua del estándar contable.
3. Priorizar siempre CDS Views/reporting sobre extensión del proceso transaccional cuando el
   requerimiento pueda resolverse solo con mejor visibilidad de datos.
