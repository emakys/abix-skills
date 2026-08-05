# Condiciones de Contrato — SAP RE-FX

## 1. Introducción

Las condiciones (`VICNCND`) son los componentes financieros del contrato: qué se cobra o paga,
cuándo, con qué periodicidad y bajo qué vigencia. RE-FX reutiliza la **técnica de condiciones de
pricing** (la misma arquitectura conceptual usada en SD para determinación de precios), adaptada al
dominio inmobiliario.

---

## 2. Tipos de Condición Principales

| Tipo de condición | Descripción |
|---|---|
| **Renta base (Basic Rent)** | El componente principal de la renta, normalmente calculado por m² o como monto fijo |
| **Adelanto de gastos comunes (Service Charge Advance Payment)** | Anticipo periódico que el inquilino paga a cuenta de la liquidación real posterior |
| **Depósito de garantía (Security Deposit)** | Garantía financiera retenida por el arrendador, no es un ingreso periódico sino un pasivo/activo de garantía |
| **Condición de indexación** | Parámetro que vincula la renta a un índice de precios para ajustes automáticos |
| **Renta variable por ventas (Sales-based rent)** | Componente adicional calculado como % de ventas del inquilino, típico en retail |
| **Cargos adicionales (Additional charges)** | Estacionamiento, publicidad exterior, uso de áreas comunes específicas, servicios opcionales |

**Tabla:** `VICNCND` — condiciones asociadas a un contrato, con tipo, importe, unidad de tiempo y
vigencia

---

## 3. Estructura de una Condición

- **Tipo de condición (KSCHL)**: qué representa (renta, gasto común, depósito)
- **Importe (KBETR)**: monto o porcentaje según el tipo
- **Moneda (WAERS)**
- **Unidad de periodicidad (ZEINH)**: mensual, trimestral, anual
- **Vigencia (DATAB/DATBI)**: desde/hasta — crítico, porque la facturación periódica y el ajuste de
  renta dependen de encontrar una condición vigente en la fecha de proceso
- **Base de cálculo (opcional)**: para condiciones calculadas por m², referencia a la superficie del
  Rental Object

---

## 4. Depósito de Garantía (Security Deposit)

El depósito no se trata como ingreso corriente: es una garantía que el arrendador retiene y que, en
principio, debe devolverse al inquilino al finalizar el contrato (salvo compensación por daños o
incumplimientos contractuales).

**Consideraciones funcionales:**
- Puede modelarse como una condición específica que dispara una contabilización de garantía (no de
  ingreso) o gestionarse fuera del ciclo de facturación periódica, según el diseño
- Requiere seguimiento hasta la finalización del contrato para su devolución (total o parcial)
- En jurisdicciones con regulación de renta residencial, puede existir un tope legal al monto del
  depósito (ej. máximo equivalente a N meses de renta) — validación de negocio, no técnica del
  sistema

---

## 5. Indexación (referencia a Rent Adjustment)

La condición de indexación no calcula el nuevo importe por sí misma en el momento de creación: solo
define el parámetro de vinculación (a qué índice, con qué periodicidad de revisión). El cálculo
efectivo del nuevo monto ocurre en el proceso de **ajuste de renta** (ver `06-rent-adjustment.md`),
que genera un nuevo periodo de vigencia de la condición de renta base con el importe recalculado.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Condiciones vigentes de un contrato a la fecha actual

```sql
SELECT vertrag, kschl, kbetr, waers, zeinh, datab, datbi
FROM vicncnd
WHERE vertrag = '{contrato}'
  AND datab <= CURRENT_DATE
  AND datbi >= CURRENT_DATE
```

### Contratos con condición de renta próxima a vencer sin renovación de condición

```sql
SELECT vertrag, kschl, datbi
FROM vicncnd
WHERE kschl = '{tipo_condicion_renta_base}'
  AND datbi BETWEEN CURRENT_DATE AND CURRENT_DATE + 60
```

### Catálogo de tipos de condición configurados

```sql
SELECT kschl, vtext
FROM t685t
WHERE spras = 'S'
  AND kappl = 'RE'
```

---

## 7. Validaciones al Mantener Condiciones

| Validación | Por qué importa |
|---|---|
| Sin huecos de vigencia entre periodos consecutivos de la misma condición | Un hueco impide la facturación periódica de ese componente en las fechas sin cobertura |
| Depósito dentro de topes legales aplicables (si la jurisdicción lo regula) | Riesgo legal/regulatorio, no solo funcional |
| Condición de indexación referencia un índice efectivamente mantenido en el sistema | Sin el índice actualizado, el ajuste automático no puede calcularse |
| Moneda de la condición consistente con la moneda del contrato | Evita diferencias de conversión no esperadas en la facturación |

---

## 8. Buenas Prácticas

1. **Nunca modificar el importe de una condición vigente directamente para reflejar un ajuste** —
   crear un nuevo periodo de vigencia preserva el histórico de renta, necesario para auditoría y
   para el cálculo correcto de ajustes futuros basados en el valor anterior.

2. **Mantener un catálogo acotado y bien documentado de tipos de condición** — la tentación de
   crear un tipo de condición nuevo para cada variante contractual dificulta el reporting
   consolidado.

3. **Vincular la condición de depósito a un proceso de seguimiento explícito** para su devolución
   al finalizar el contrato — un depósito "olvidado" en el sistema tras la salida del inquilino es
   un riesgo de auditoría frecuente.

4. **Documentar la fórmula exacta de cualquier condición calculada** (renta por m², renta variable
   por ventas) para que sea auditable sin depender de memoria institucional.
