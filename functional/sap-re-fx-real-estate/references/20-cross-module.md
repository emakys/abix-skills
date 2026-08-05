# Integración Cross-Módulo — SAP RE-FX

## 1. RE-FX ↔ FI

- La contabilización periódica de renta (lease-out) y su contraparte de gasto (lease-in) generan
  partidas FI-AR/AP contra el Business Partner correspondiente
- La liquidación de gastos comunes genera partidas adicionales de ajuste (cobro adicional o nota de
  crédito) también contra el BP del inquilino
- El cierre RE-FX (facturación periódica, reconocimiento de devengos) debe coordinarse con el
  cierre contable FI de la sociedad
- El tratamiento de IVA/impuesto sobre la renta requiere coordinación con la determinación fiscal
  general de FI (ver `13-input-tax-treatment.md`)

## 2. RE-FX ↔ FI-AA

- **Lease-in**: el contrato genera automáticamente el activo por derecho de uso (ROU) con su plan
  de amortización financiera — ver `07-lease-in-ifrs16.md` y `10-integration-fi-aa.md`
- **Lease-out**: el inmueble propio arrendado suele estar también registrado como activo fijo
  tradicional, con vínculo de referencia (no automático) al objeto RE-FX correspondiente

## 3. RE-FX ↔ CO

- Cada objeto de renta puede llevar asignación de centro de coste/centro de beneficio, permitiendo
  analizar rentabilidad del portafolio inmobiliario por objeto, edificio o Business Entity
- Los costos operativos del inmueble (mantenimiento, administración) que alimentan la liquidación
  de gastos comunes se recolectan de la contabilización CO estándar contra esos objetos

## 4. RE-FX ↔ PM

- Un objeto inmobiliario puede coexistir como objeto técnico de PM (equipo o ubicación técnica)
  cuando requiere mantenimiento planificado — relevante para edificios con instalaciones críticas
  (HVAC, ascensores, sistemas contra incendio)
- Los avisos y órdenes de mantenimiento sobre esas instalaciones generan costos que, según diseño,
  pueden alimentar la liquidación de gastos comunes del edificio

## 5. RE-FX ↔ PS

- Proyectos de construcción, refacción o acondicionamiento de un inmueble se modelan como WBS de
  PS, con el inmueble/Rental Object como objeto de referencia
- Al finalizar el proyecto, la liquidación de la WBS puede capitalizar el gasto contra el activo
  fijo del inmueble (si es lease-out propio) o quedar como gasto directo según el escenario

## 6. RE-FX ↔ SD/MM (escenarios menos comunes)

- Facturación de servicios adicionales al inquilino no cubiertos por la condición de renta estándar
  (ej. servicios especiales) puede canalizarse vía SD en algunos diseños
- Compras de servicios de mantenimiento/administración del inmueble se gestionan vía MM, con el
  costo resultante fluyendo hacia el centro de coste del objeto y, eventualmente, hacia la
  liquidación de gastos comunes

## 7. RE-FX ↔ Business Partner (transversal)

- El inquilino, el arrendador externo (lease-in) y el garante se modelan uniformemente como
  Business Partner, consistente con la simplificación de modelo de datos de S/4HANA (CVI) — no hay
  un maestro separado de "inquilino" en el sistema

## 8. Matriz Resumen

| Módulo | Relación con RE-FX |
|---|---|
| FI | Facturación periódica y liquidación generan AR/AP; determinación de impuesto sobre renta |
| FI-AA | ROU asset automático en lease-in; vínculo de referencia con inmueble propio en lease-out |
| CO | Centro de coste/beneficio por objeto de renta; fuente de costos para liquidación de gastos comunes |
| PM | Objeto inmobiliario como objeto técnico compartido para mantenimiento de instalaciones |
| PS | Proyectos de construcción/refacción con el inmueble como objeto de referencia |
| SD/MM | Servicios adicionales al inquilino (SD) y compras de mantenimiento del inmueble (MM), escenarios menos comunes |
