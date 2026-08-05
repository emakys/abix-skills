# Estructura Organizativa RE-FX — SAP Flexible Real Estate Management S/4HANA 2023

## 1. Introducción

RE-FX no define una jerarquía organizativa propia independiente de FI/CO: se apoya en Sociedad
(BUKRS) y Área de Controlling (KOKRS), y agrega sobre esa base una **jerarquía de objetos
inmobiliarios (GPO — General Purpose Objects)** que representa el portafolio físico, junto con la
capa de **contratos** que vincula esos objetos con Business Partners (inquilinos o arrendadores
externos).

---

## 2. Elementos Organizativos de FI/CO como Base

### 2.1 Sociedad (Company Code — BUKRS) y Área de Controlling (KOKRS)

Todo objeto inmobiliario y todo contrato vive dentro de una sociedad. La cadena es:

```
Sociedad (BUKRS) → Área de Controlling (KOKRS) → Portafolio inmobiliario (Business Entities) → Contratos
```

**Tablas:** `T001` (sociedades), `TKA02` (sociedad → área CO)

Una misma sociedad puede tener múltiples Business Entities (varios edificios, campus o complejos
gestionados independientemente); un portafolio grande puede además distribuirse entre varias
sociedades cuando existen entidades legales separadas por país o por vehículo de inversión
inmobiliaria (SPV).

---

## 3. Jerarquía de Objetos Inmobiliarios (GPO)

RE-FX reemplaza la jerarquía rígida del RE clásico por una arquitectura de **objetos de propósito
general** con **vistas de uso (usage views)** activables por objeto. La jerarquía física estándar
es:

```
Business Entity (BE)
  └── Property (Terreno/Predio)
        └── Building (Edificio)
              └── Rental Object (Unidad de Renta / Terreno arrendable / Espacio)
                    └── Architectural Object (medición de superficie, opcional)
```

Ver detalle completo de cada nivel en `02-real-estate-objects-master-data.md`.

### 3.1 Vistas de Uso (Usage Views)

Cada objeto GPO puede tener múltiples vistas de uso activas simultáneamente, sin duplicar el
maestro físico:

- **Vista RE** (Real Estate) — la vista base para renta/contrato, siempre presente si el objeto
  participa en RE-FX
- **Vista de Facility Management** — cuando el mismo objeto también es relevante para gestión de
  instalaciones/mantenimiento
- **Vista de Valoración** — para escenarios de valuación de activos inmobiliarios
- **Vista Fiscal/Tax** — atributos relevantes para impuestos inmobiliarios locales

Esta flexibilidad es la razón del nombre "Flexible" en RE-FX: el mismo Rental Object puede
participar en RE (contrato de renta) y, simultáneamente, en un proceso de Facility Management, sin
que el consultor necesite crear dos maestros distintos.

---

## 4. Business Entity como Ancla del Portafolio

La **Business Entity (BE)** es el nivel más alto de agrupación y suele alinearse con una unidad de
gestión de negocio (un centro comercial, un campus corporativo, un edificio de oficinas
independiente). Determina:

- La sociedad (BUKRS) a la que pertenece el portafolio
- La base típica para reporting consolidado de portafolio (ocupación, ingresos, gastos comunes)
- El alcance de ciertas unidades de liquidación de gastos comunes cuando el reparto es a nivel de
  todo el complejo

---

## 5. Contrato como Capa de Negocio

El contrato (`RECN`, tabla `VICNCN`) no forma parte de la jerarquía física de objetos: es la capa
que vincula uno o más Rental Objects con uno o más Business Partners (inquilino en lease-out,
arrendador externo en lease-in), con sus condiciones de renta y vigencia.

```
Business Entity → Property → Building → Rental Object(s)
                                              │
                                              └── vinculado a → Contrato (VICNCN) → Business Partner
```

---

## 6. Cadena Organizativa Completa

```
Sociedad (BUKRS)
  └── Área de Controlling (KOKRS)
        └── Business Entity (portafolio/complejo)
              └── Property (terreno)
                    └── Building (edificio)
                          └── Rental Object (unidad arrendable)
                                └── Contrato (lease-out o lease-in)
                                      └── Business Partner (inquilino o arrendador externo)
```

---

## 7. Tabla Resumen de Customizing RE-FX — Estructura Organizativa

| Concepto | Transacción (familia) | Tabla |
|---|---|---|
| Activar RE-FX para sociedad | SPRO → Flexible Real Estate Management | TIVxx (customizing) |
| Definir Business Entity | REBDBE | VIBDBE (orientativo) |
| Definir Property | REBDPR | VIBDPR (orientativo) |
| Definir Building | REBDBU | VIBDGB (orientativo) |
| Definir Rental Object | REBDOB | VIBDOB (orientativo) |
| Definir vistas de uso activas | SPRO → Flexible Real Estate Management → Objetos inmobiliarios | TIVxx |

---

## 8. Buenas Prácticas — Estructura Organizativa RE-FX

1. **Definir la Business Entity alineada a la unidad de gestión real del negocio**, no
   necesariamente a la sociedad legal completa — facilita el reporting de portafolio por complejo.

2. **Activar solo las vistas de uso que realmente se necesitan** por objeto — activar vistas sin
   uso real complica el mantenimiento sin aportar valor.

3. **No forzar la jerarquía completa cuando no aplica**: un terreno arrendable sin edificación
   puede modelarse como Rental Object directamente bajo Property, sin necesidad de un Building
   intermedio.

4. **Coordinar la definición de Business Entities con el equipo de FI-AA** cuando los inmuebles
   también se registran como activos fijos — evita descoordinación entre la jerarquía RE-FX y la
   estructura de activos.

5. **Documentar el criterio de agrupación de Business Entities** usado en el proyecto — es una
   decisión de diseño con impacto directo en todo el reporting posterior de portafolio.
