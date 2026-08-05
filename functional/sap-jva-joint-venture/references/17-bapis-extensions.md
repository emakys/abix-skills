# BAPIs, Function Modules y Extensiones — SAP JVA

## 1. Naturaleza Técnica de JVA

JVA es un módulo con fuerte componente batch (cutback, billing) construido principalmente sobre
function modules y programas clásicos (no un stack CDS/OData moderno como los módulos genéricos
FI/CO/MM). Esto tiene implicancias prácticas: la extensibilidad se apoya más en BAdIs/exits de
function modules que en extension frameworks Fiori/BTP modernos.

## 2. Puntos de Extensión Típicos

| Área | Mecanismo típico |
|---|---|
| Derivación de Venture/Equity Group/Recovery Indicator | BAdI o exit de sustitución (además de la sustitución estándar `GGB1`) para lógica de derivación no cubierta por condiciones simples |
| Cálculo de overhead recovery | BAdI/exit en el punto de cálculo del cutback, para fórmulas de tasa no estándar (sliding scale compleja, topes contractuales) |
| Validaciones previas al cutback | Exit de validación para bloquear la corrida si datos maestros están incompletos, más allá de las validaciones estándar |
| Formato de statement/billing | Extensión del layout de salida (SmartForms/Adobe Forms clásico, o desarrollo de reporte custom) para adaptarse al formato exigido por el JOA |

**Nota de honestidad técnica:** los nombres exactos de BAdIs/exits de JVA (ej. equivalentes a los
puntos de extensión de cutback o billing) no se citan aquí con nombres específicos porque varían
según el release y el paquete de function modules instalado. Antes de diseñar una extensión,
localizar el punto exacto con `GetEnhancements` sobre los programas/function groups relevantes
(`SAPLGJ04` y análogos) en el sistema real del cliente.

## 3. Localización de Extensiones (Workflow con MCP)

1. Identificar el programa/function group involucrado en el proceso a extender (cutback, billing)
2. `GetEnhancements("{function_group}")` para listar BAdIs/exits disponibles en ese punto
3. `GetWhereUsed` sobre el function module relevante para entender el flujo de llamada
4. `ReadClass`/`ReadProgram` para inspeccionar la lógica estándar antes de decidir el punto de
   inserción del custom code

## 4. Custom Fields & Logic vs Desarrollo Clásico

Dado que JVA es un módulo de industria con fuerte legado clásico, el patrón moderno de "Custom
Fields & Logic" (Key User, sin código ABAP) tiene cobertura limitada comparado con módulos
genéricos S/4HANA. Para extensiones de campo simples (ej. un campo adicional informativo en el
maestro de Venture), evaluar primero si existe un append/enhancement estándar disponible; para
lógica de negocio (fórmulas de overhead, derivación compleja), es más realista asumir desarrollo
clásico (BAdI/exit) que Key User Extensibility.

## 5. Riesgos de Modificar el Núcleo de JVA

- El proceso de cutback es sensible a orden de ejecución y a la integridad de `GJUBI`/`GJHIST` —
  cualquier modificación directa de programas estándar (no vía punto de extensión oficial) pone en
  riesgo la reproducibilidad del cutback ante upgrades
- Preferir siempre el punto de extensión oficial (BAdI/exit/sustitución) sobre modificación directa
  (`SPAU`/`SPDD` cuando se detecta que ya se modificó núcleo, para gestionar el impacto en el
  próximo upgrade)

## 6. Buenas Prácticas

1. **Documentar cada BAdI/exit implementado en JVA con su propósito de negocio**, no solo el
   nombre técnico — la lógica de cutback/billing suele tener reglas contractuales complejas detrás
   que no son evidentes solo leyendo el código.

2. **Probar cualquier extensión en un venture de prueba antes de activarla en producción** — un
   error en la derivación de atributo JV o en el cálculo de overhead afecta directamente el monto
   facturado a partners reales.

3. **Evitar modificaciones directas de núcleo**; usar siempre el punto de extensión oficial
   disponible más cercano al comportamiento que se necesita cambiar.
