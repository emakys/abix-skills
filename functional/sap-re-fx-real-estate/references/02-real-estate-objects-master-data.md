# Datos Maestros — Jerarquía de Objetos Inmobiliarios (SAP RE-FX)

## 1. Introducción

La jerarquía de objetos inmobiliarios (GPO) es el cimiento de todo proceso RE-FX: sin objetos
correctamente definidos y medidos, ningún contrato puede vincularse correctamente ni la
liquidación de gastos comunes puede prorratear con precisión. Este documento detalla cada nivel.

---

## 2. Business Entity (BE) — REBDBE

Nivel más alto de agrupación del portafolio.

**Datos clave:**
- Clave y descripción de la Business Entity
- Sociedad (BUKRS)
- Dirección principal del complejo
- Responsable de gestión (opcional, para reporting)

**Tabla:** `VIBDBE` (orientativo — confirmar campos exactos en el sistema real)

**Errores comunes:**
- Crear una BE por cada edificio individual cuando el negocio realmente gestiona el complejo como
  unidad — dificulta el reporting consolidado de portafolio
- Omitir la dirección principal, requerida para correspondencia con inquilinos generada desde el
  nivel BE

---

## 3. Property (Terreno/Predio) — REBDPR

Representa el terreno físico, con o sin edificación.

**Datos clave:**
- Clave y descripción
- Business Entity a la que pertenece
- Datos catastrales/registrales (referencia externa, opcional pero recomendado para trazabilidad
  legal)
- Superficie total del terreno

**Uso sin Building:** un terreno arrendable como tal (ej. estacionamiento a cielo abierto, lote
para publicidad exterior) puede tener Rental Objects vinculados directamente, sin Building
intermedio.

---

## 4. Building (Edificio) — REBDBU

Representa la edificación sobre una Property.

**Datos clave:**
- Clave y descripción
- Property a la que pertenece
- Año de construcción, superficie construida (relevante para reporting de portafolio y, en
  algunos escenarios, para depreciación si el edificio también es activo fijo)
- Estándar de medición de superficie aplicado (ver Architectural Object)

---

## 5. Rental Object (Unidad de Renta) — REBDOB

El objeto efectivamente arrendable — el nivel al que se vincula el contrato.

**Tipos comunes de Rental Object:**
- **Unidad de renta (Rental Unit)**: espacio dentro de un edificio (oficina, local comercial,
  departamento)
- **Terreno arrendable (Land)**: cuando se arrienda el terreno directamente
- **Espacio (Rental Space)**: subdivisión más granular dentro de una unidad, útil en escenarios de
  coworking o espacios compartidos con múltiples ocupantes simultáneos

**Datos clave:**
- Clave y descripción
- Building/Property al que pertenece
- Tipo de uso (oficina, retail, industrial, residencial, estacionamiento)
- Superficie (m²) — dato crítico, base de la mayoría de los cálculos de prorrateo de gastos
  comunes y, frecuentemente, de la renta misma
- Estado (disponible, arrendado, en remodelación, fuera de servicio)

**Tabla:** `VIBDOB` (orientativo)

**Errores comunes:**
- Superficie mal cargada o desactualizada tras una remodelación → distorsiona tanto la renta
  calculada por m² como el prorrateo de gastos comunes de todo el edificio
- Rental Object sin tipo de uso definido → dificulta el análisis de portafolio por segmento
  (oficina vs retail vs industrial)

---

## 6. Architectural Object — Medición de Superficies

Objeto opcional usado cuando se requiere precisión y trazabilidad en la medición de superficies,
especialmente relevante si el cliente aplica un estándar de medición reconocido internacionalmente.

**Estándares de medición comunes en la práctica de portafolios inmobiliarios internacionales:**
- **GIF (Gesellschaft für Immobilienwirtschaftliche Forschung)** — estándar alemán ampliamente
  usado en Europa continental
- **BOMA (Building Owners and Managers Association)** — estándar norteamericano

**Por qué importa:** dos estándares de medición pueden arrojar superficies distintas para el mismo
espacio físico (ej. tratamiento distinto de áreas comunes/circulación). Si el contrato pacta renta
por m² y el negocio opera en múltiples países con distintos estándares, es crítico documentar qué
estándar aplica a cada Rental Object para evitar disputas con inquilinos.

**Tabla:** `VIBDIO` (orientativo)

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Business Entities de una sociedad

```sql
SELECT swenr, swename, bukrs
FROM vibdbe
WHERE bukrs = '{sociedad}'
```

### Rental Objects de un Building, con superficie

```sql
SELECT meinh, mebez, nutza, qmnut
FROM vibdob
WHERE gebaeude = '{building}'
```

### Rental Objects sin contrato vigente (candidatos a vacancia)

```sql
-- Combinar con VICNCN para identificar objetos sin vínculo de contrato activo en la fecha actual
SELECT meinh, mebez
FROM vibdob
WHERE gebaeude = '{building}'
  AND meinh NOT IN (SELECT vertrag FROM vicncn WHERE vbegdat <= CURRENT_DATE AND venddat >= CURRENT_DATE)
```

---

## 8. Validaciones al Mantener Datos Maestros

| Validación | Por qué importa |
|---|---|
| Superficie del Rental Object actualizada y consistente con el plano vigente | Base de renta por m² y de todo el prorrateo de gastos comunes |
| Jerarquía completa sin huecos (Rental Object sin Building/Property cuando corresponde) | Evita objetos "huérfanos" difíciles de reportar a nivel portafolio |
| Tipo de uso definido en cada Rental Object | Habilita el análisis de portafolio por segmento |
| Estándar de medición documentado por Building | Previene disputas de superficie con inquilinos |

---

## 9. Buenas Prácticas

1. **Actualizar la superficie inmediatamente tras cualquier remodelación** que la afecte — un
   desfase aquí distorsiona renta y gastos comunes de todos los inquilinos del edificio.

2. **Mantener el estado del Rental Object disciplinadamente** (disponible/arrendado/remodelación)
   — es la fuente de la mayoría de los reportes de vacancia y ocupación.

3. **Documentar el estándar de medición aplicado por Building**, especialmente en portafolios
   multi-país.

4. **Evitar crear Rental Objects "fantasma"** solo para pruebas en el sistema productivo — genera
   ruido en reportes de portafolio y puede confundir cálculos de ocupación.
