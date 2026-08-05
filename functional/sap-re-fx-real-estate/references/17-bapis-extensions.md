# BAPIs, Function Modules y Extensiones — SAP RE-FX

## 1. Naturaleza Técnica de RE-FX

RE-FX es un módulo con arquitectura orientada a objetos más moderna que otros módulos de industria
clásicos (se apoya fuertemente en clases ABAP, ej. `CL_RECN_*` para contrato, `CL_REBD_*` para
objetos inmobiliarios), aunque los procesos batch pesados (liquidación de gastos comunes, ajuste de
renta masivo) conservan un componente transaccional/batch tradicional significativo.

## 2. Puntos de Extensión Típicos

| Área | Mecanismo típico |
|---|---|
| Validaciones al crear/modificar contrato | BAdI en el flujo de guardado del contrato (`CL_RECN_*`) — para reglas de negocio adicionales antes de activar |
| Cálculo de condiciones no estándar | BAdI/exit en el punto de determinación de condición, para fórmulas no cubiertas por la técnica estándar de condiciones |
| Derivación de cuenta contable en la contabilización periódica | Determinación de cuenta estándar (similar en espíritu a OBYC de MM), con puntos de sustitución/BAdI para reglas específicas del cliente |
| Cálculo de liquidación de gastos comunes | BAdI en el motor de liquidación, para lógicas de prorrateo no cubiertas por los factores estándar |
| Clasificación/cálculo IFRS 16 | Puntos de extensión en el cálculo del pasivo/ROU para escenarios contractuales complejos (ej. componentes variables atípicos) |

**Nota de honestidad técnica:** los nombres exactos de BAdIs/exits específicos de cada punto varían
según el release y el component set instalado. Antes de diseñar una extensión, localizar el punto
exacto con `GetEnhancements` sobre las clases/programas relevantes en el sistema real del cliente.

## 3. Localización de Extensiones (Workflow con MCP)

1. Identificar la clase/programa involucrado en el proceso a extender (contrato, condición,
   liquidación, IFRS 16)
2. `GetEnhancements("{clase_o_programa}")` para listar BAdIs/exits disponibles en ese punto
3. `GetWhereUsed` sobre el método/function module relevante para entender el flujo de llamada
4. `ReadClass`/`ReadProgram` para inspeccionar la lógica estándar antes de decidir el punto de
   inserción del custom code

## 4. Custom Fields & Logic vs Desarrollo Clásico

RE-FX, al ser un módulo relativamente moderno en su diseño orientado a objetos, tiene mejor
cobertura de Key User Extensibility que módulos de industria más clásicos (ej. JVA) — es razonable
esperar soporte de Custom Fields sobre objetos inmobiliarios y contrato para atributos informativos
adicionales. Para lógica de negocio de cálculo (condiciones no estándar, fórmulas de liquidación
específicas), sigue siendo más realista asumir desarrollo vía BAdI que Key User Extensibility pura.

## 5. BAPIs de Referencia

| BAPI (familia, orientativo) | Uso |
|---|---|
| `BAPI_RE_CN*` | Operaciones sobre contrato (creación, modificación, consulta) |
| `BAPI_RE_BE*`/análogas | Operaciones sobre objetos de la jerarquía inmobiliaria |

Confirmar el catálogo exacto de BAPIs disponibles con `SearchObject("BAPI_RE*")` en el sistema real
antes de diseñar una integración — la cobertura de BAPI vs API OData/REST moderna puede variar
según el release y si el cliente usa integraciones vía BTP.

## 6. Riesgos de Modificar el Núcleo de RE-FX

- El motor de liquidación de gastos comunes y el cálculo de IFRS 16 son sensibles a la integridad
  de los datos maestros de vigencia (condiciones, membresías de grupo de participación) — cualquier
  modificación directa de clases/programas estándar pone en riesgo la reproducibilidad de estos
  cálculos ante upgrades
- Preferir siempre el punto de extensión oficial (BAdI/exit) sobre modificación directa (`SPAU`/
  `SPDD` cuando se detecta que ya se modificó núcleo, para gestionar el impacto en el próximo
  upgrade)

## 7. Buenas Prácticas

1. **Documentar cada BAdI/exit implementado con su propósito de negocio**, no solo el nombre
   técnico — la lógica de liquidación de gastos comunes y ajuste de renta suele tener reglas
   contractuales complejas detrás.

2. **Probar cualquier extensión sobre un contrato de prueba antes de activarla en producción** — un
   error en el cálculo de condiciones o en la liquidación afecta directamente montos facturados a
   inquilinos reales.

3. **Evitar modificaciones directas de núcleo**; usar siempre el punto de extensión oficial más
   cercano al comportamiento que se necesita cambiar.

4. **Priorizar Custom Fields sobre desarrollo ABAP para necesidades de dato adicional**, aprovechando
   la mejor cobertura de extensibilidad moderna de RE-FX frente a módulos de industria más clásicos.
