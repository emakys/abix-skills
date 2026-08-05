# Gestión de Inquilinos y Correspondencia — SAP RE-FX

## 1. Introducción

Más allá del maestro de datos financiero (Business Partner con rol AR), la gestión efectiva de
inquilinos en RE-FX incluye evaluación de riesgo crediticio, gestión de garantías, y generación de
correspondencia formal a lo largo de todo el ciclo de vida de la relación comercial.

---

## 2. El Inquilino como Business Partner

En S/4HANA, el inquilino se modela como **Business Partner (BP)** con rol de cliente (FI-AR),
consistente con la simplificación general del modelo de datos (Customer/Vendor Integration — CVI)
que unifica el maestro de socios de negocio en toda la suite. No existe un maestro de "inquilino"
separado del BP estándar.

**Datos relevantes del BP en contexto RE-FX:**
- Rol FI-AR (cuenta de reconciliación, condiciones de pago)
- Datos de contacto para correspondencia (dirección de correspondencia puede diferir de la
  dirección del Rental Object arrendado — ej. facturación a oficina central corporativa)
- Datos bancarios (para eventuales devoluciones de depósito o notas de crédito)

---

## 3. Garante (Guarantor)

Cuando el contrato requiere respaldo financiero adicional (frecuente en inquilinos nuevos sin
historial, o de riesgo crediticio elevado), se vincula un **Garante** como socio adicional del
contrato con su propio rol (`VICNCNP`, ver `03-contract-management.md`).

**Consideraciones:**
- El garante puede ser una persona física (garantía personal) o una entidad (garantía corporativa,
  carta de crédito bancaria)
- El vínculo tiene su propia vigencia, que puede no coincidir exactamente con la del contrato (ej.
  garantía limitada a los primeros N años)

---

## 4. Evaluación de Riesgo Crediticio del Inquilino

Antes de activar un contrato de valor significativo, es práctica estándar evaluar la capacidad de
pago del inquilino potencial:

- Antigüedad y solidez financiera de la empresa (si es corporativo)
- Historial de pago si ya es inquilino en otro objeto del portafolio
- Necesidad de depósito de garantía mayor o garante adicional según el resultado de la evaluación

Este proceso suele apoyarse en el módulo de **Gestión de Crédito (Credit Management)** estándar de
FI, reutilizando la infraestructura de scoring/límite de crédito ya existente para el Business
Partner, en vez de construir una lógica de riesgo separada dentro de RE-FX.

---

## 5. Correspondencia con el Inquilino

RE-FX genera correspondencia formal en distintos puntos del ciclo de vida:

- Confirmación de alta de contrato
- Notificación de ajuste de renta (ver `06-rent-adjustment.md`)
- Liquidación de gastos comunes (ver `05-service-charge-settlement.md`)
- Recordatorios de vencimiento próximo de contrato
- Confirmación de devolución de depósito al finalizar el contrato

**Mecanismo técnico:** la generación de correspondencia se apoya típicamente en SmartForms/Adobe
Forms (o su evolución más moderna) con datos extraídos del contrato y sus condiciones — el formato
exacto de cada pieza de correspondencia suele requerir adaptación al estándar de comunicación de
cada cliente (logo, idioma, formato legal local).

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Inquilinos (partners con rol tenant) de un contrato

```sql
SELECT vertrag, partner, parvw, datab, datbi
FROM vicncnp
WHERE vertrag = '{contrato}'
  AND parvw = '{rol_inquilino}'
```

### Datos de Business Partner de un inquilino específico

```sql
SELECT partner, name1, bukrs
FROM lfa1
WHERE lifnr = '{partner_como_proveedor}'
-- o consultar la tabla de Business Partner central según el diseño de CVI del sistema
```

---

## 7. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| No se genera partida FI-AR al inquilino | BP sin rol FI-AR completo, o sin cuenta de reconciliación asignada |
| Correspondencia no llega al destinatario correcto | Dirección de correspondencia del BP desactualizada o distinta a la esperada |
| Garante no vinculado correctamente al contrato | Rol de socio (`parvw`) mal asignado en `VICNCNP` |

---

## 8. Buenas Prácticas

1. **Reutilizar siempre el maestro de Business Partner existente** si el mismo inquilino ya opera
   en otro objeto del portafolio — evita duplicados que fragmentan el historial de pago y el
   reporting consolidado por inquilino.

2. **Evaluar riesgo crediticio de forma consistente antes de activar contratos de valor
   significativo**, apoyándose en la infraestructura estándar de Credit Management de FI.

3. **Mantener plantillas de correspondencia versionadas y alineadas a requerimientos legales
   locales** — algunas jurisdicciones exigen contenido mínimo específico en notificaciones de
   ajuste de renta o liquidación de gastos comunes.

4. **Documentar la relación garante-inquilino-contrato de forma explícita** en el sistema, no solo
   en documentación externa — facilita la ejecución de la garantía si se necesita.
