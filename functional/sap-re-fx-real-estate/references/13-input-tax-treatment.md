# Tratamiento de Impuestos (IVA / Opción Fiscal) — SAP RE-FX

## 1. Introducción

El arrendamiento de inmuebles tiene tratamiento fiscal particular en la mayoría de las
jurisdicciones: en muchos países la renta inmobiliaria (especialmente residencial) está **exenta**
de IVA/impuesto al valor agregado, mientras que el arrendamiento comercial puede estar gravado, ser
exento con opción de gravar (**option to tax**), o tener tratamientos mixtos según el uso del
inquilino. Este documento cubre las implicancias funcionales generales — la determinación fiscal
exacta **siempre depende de la jurisdicción** y debe validarse con el equipo fiscal/tributario
local, no asumirse desde el conocimiento genérico del módulo.

---

## 2. Escenarios Fiscales Típicos

- **Renta exenta**: común en residencial en muchas jurisdicciones — el arrendador no cobra
  IVA/impuesto sobre la renta, pero típicamente tampoco puede deducir el IVA de sus propios costos
  asociados a ese inmueble (afecta el **prorrateo de deducción de IVA soportado** del arrendador)
- **Renta gravada**: común en comercial/industrial — el arrendador cobra el impuesto
  correspondiente sobre la renta y puede deducir normalmente el IVA de sus costos asociados
- **Opción de gravar (Option to Tax)**: en algunas jurisdicciones, el arrendador de un inmueble en
  principio exento puede **optar** por gravar la renta (para poder deducir el IVA de sus propios
  costos de mantenimiento/inversión en el inmueble) — esta opción suele tener condiciones y, en
  algunos regímenes, requiere el consentimiento o registro fiscal del inquilino

---

## 3. Impacto en la Contabilización

La condición de renta (`04-conditions-and-terms.md`) debe llevar el código de impuesto correcto
para que la contabilización periódica genere la partida fiscal apropiada. Un código de impuesto
incorrecto en la condición no solo genera un error de reporting fiscal — puede tener implicancias
de cumplimiento tributario directo.

**Consideración práctica:** cuando un mismo edificio tiene mezcla de usos (ej. plantas comerciales
gravadas y unidades residenciales exentas), cada Rental Object debe llevar el tratamiento fiscal
correspondiente a su uso específico, no un tratamiento uniforme a nivel Building.

---

## 4. Prorrateo de Deducción de IVA Soportado (Input Tax Apportionment)

Cuando el arrendador tiene un portafolio mixto (parte de la renta exenta, parte gravada), el IVA
soportado en costos que no pueden asignarse directamente a un tipo de renta específico (ej. gastos
generales de administración del portafolio) debe prorratearse según la proporción de ingresos
gravados vs exentos — un cálculo estándar de determinación de crédito fiscal, no específico de
RE-FX, pero que depende de datos que RE-FX sí origina (qué parte del portafolio genera renta
gravada vs exenta).

---

## 5. Impuestos Inmobiliarios Trasladados al Inquilino

Independientemente del IVA/impuesto al valor agregado, muchos contratos trasladan al inquilino
(vía la liquidación de gastos comunes, o como condición separada) el **impuesto inmobiliario**
(property tax) que grava la propiedad del inmueble en sí, según lo pactado contractualmente y
permitido por la práctica de mercado local — este es un traslado de costo, no una determinación de
IVA sobre la renta.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Condiciones de renta con su código de impuesto por contrato

```sql
-- El campo de código de impuesto exacto puede variar según cómo esté extendida VICNCND en el sistema real
SELECT vertrag, kschl, kbetr, mwsk1
FROM vicncnd
WHERE vertrag = '{contrato}'
```

*(`mwsk1` es el nombre de campo estándar típico de código de impuesto en tablas de condición SAP —
confirmar su presencia y significado exacto en la extensión real de `VICNCND` del sistema del
cliente antes de usarlo en un reporte productivo.)*

---

## 7. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Renta contabilizada con código de impuesto incorrecto | Condición configurada con el código genérico en vez del específico al uso del Rental Object |
| Inconsistencia de tratamiento fiscal dentro del mismo edificio | Building con mezcla de usos sin diferenciar el código de impuesto por Rental Object |
| Disputa con autoridad fiscal sobre deducción de IVA | Opción de gravar no formalizada correctamente según el procedimiento exigido por la jurisdicción |

---

## 8. Buenas Prácticas

1. **Nunca asumir el tratamiento fiscal genérico sin confirmar con el equipo fiscal local** — la
   determinación de exención/gravamen de renta inmobiliaria varía significativamente entre
   jurisdicciones y no es un dato que el consultor RE-FX deba decidir por conocimiento general del
   módulo.

2. **Parametrizar el código de impuesto a nivel de condición/Rental Object**, respetando la mezcla
   de usos cuando exista dentro de un mismo Building.

3. **Documentar formalmente cualquier opción de gravar ejercida**, incluyendo la fecha de
   formalización y su alcance (qué objetos/contratos cubre), para soportar auditorías fiscales.

4. **Coordinar con el equipo de FI/Tax la configuración del prorrateo de deducción de IVA
   soportado** cuando el portafolio combina renta gravada y exenta — no es una configuración
   exclusiva de RE-FX sino compartida con la determinación fiscal general de FI.
