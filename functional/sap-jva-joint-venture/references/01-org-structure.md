# Estructura Organizativa JVA — SAP Joint Venture Accounting S/4HANA 2023

## 1. Introducción

JVA no define una jerarquía organizativa propia independiente: se apoya en la estructura
organizativa de FI/CO (Sociedad, Área de Controlling) y le agrega una capa adicional específica
del negocio de joint venture — el **Venture**, el **Equity Group**, el **Recovery Indicator** y el
**Cutback Group** — que determina quién comparte el costo de qué objeto CO y en qué porcentaje.

---

## 2. Elementos Organizativos de FI/CO como Base

### 2.1 Sociedad (Company Code — BUKRS) y Área de Controlling (KOKRS)

Todo venture vive dentro de una sociedad y su área de controlling asociada. La cadena es:

```
Sociedad (BUKRS) → Área de Controlling (KOKRS) → Venture(s) operados/no-operados en esa sociedad
```

**Tablas:** `T001` (sociedades), `TKA02` (sociedad → área CO)

Una misma sociedad operadora puede participar en múltiples ventures simultáneamente (múltiples
campos/pozos), y un mismo venture puede — en configuraciones más complejas de grupos — involucrar
objetos CO de más de una sociedad, aunque el patrón más común es 1 venture por unidad de negocio
dentro de una sociedad.

---

## 3. Venture (Joint Venture)

El **Venture** es el objeto maestro central de JVA. Representa el acuerdo de operación conjunta
(Joint Operating Agreement — JOA) sobre un activo compartido: un campo petrolero, un bloque de
exploración, un yacimiento de gas, un ducto compartido, etc.

**Tabla:** `T8J1`

| Campo (orientativo) | Descripción |
|---|---|
| VENTURE | Clave del venture |
| VNAME | Nombre/descripción del venture |
| OPIND | Indicador de operador (si la sociedad local es operadora de este venture) |
| WAERS | Moneda del venture |

Cada venture se crea vía customizing (transacción de mantenimiento de venture) y queda disponible
para asignarse como atributo JV en los objetos CO relevantes.

**SPRO:** IMG → Joint Venture Accounting → Master Data → Define Ventures (nombre de ruta
orientativo; el árbol exacto puede variar según el release y si JVA está activo como add-on
clásico o embebido en S/4HANA)

---

## 4. Equity Group

El **Equity Group** define el conjunto de partners que comparten un venture y el **porcentaje de
participación (Working Interest / Participating Interest)** de cada uno, con vigencia temporal
(`VALFR`/`VALTO`).

**Tabla:** `T8J2` (cabecera de equity group por venture y periodo de vigencia)

| Campo (orientativo) | Descripción |
|---|---|
| VENTURE | Venture al que pertenece |
| EGRUP | Clave del equity group |
| VALFR / VALTO | Vigencia (fecha desde/hasta) |

La tabla de detalle con el porcentaje por partner dentro del equity group existe (normalmente con
un sufijo tipo `T8J2P` o similar), pero **su nombre exacto debe confirmarse en el sistema real**
antes de usarla en un reporte productivo — varía según release/parche.

**Por qué un venture puede tener múltiples equity groups vigentes en el tiempo:** cada farm-in,
farm-out o renegociación de participación genera un nuevo periodo de equity group con % distintos,
sin borrar el histórico (necesario para recalcular cutback de periodos pasados con el % correcto
de esa fecha).

---

## 5. Partner

El **Partner** es cada una de las compañías (incluida la propia sociedad operadora) que participa
en el venture. En el sistema, el partner suele modelarse como un **Business Partner / acreedor**
(para poder generar las partidas de JIB contra FI-AR/AP), vinculado al Equity Group con su %.

Distinción clave:
- **Operador (Operator)**: la sociedad que ejecuta el 100% del booking operativo y corre el
  cutback. Es quien "presta" el servicio de administración del venture a los demás.
- **No-Operador (Non-Operator)**: partner que solo recibe el billing (JIB) y reconcilia contra su
  propia contabilidad — no contabiliza el detalle operativo, solo el resultado del cutback.

---

## 6. Recovery Indicator (RI)

El **Recovery Indicator** es el código que se asigna (por defecto en el maestro del objeto CO, o
vía sustitución a nivel de línea) para decidir **cómo** se trata cada línea de costo/ingreso desde
la óptica JV: si se distribuye entre partners, si queda 100% en el operador, si dispara overhead,
etc. Es el mecanismo de decisión más consultado en diagnóstico de incidentes JVA.

**Tabla:** `T8J3` (customizing de Recovery Indicators)

Ver detalle completo en `04-recovery-indicators.md`.

---

## 7. Cutback Group

El **Cutback Group** agrupa objetos CO (o combinaciones de Recovery Indicator) que deben
procesarse juntos en una misma corrida de cutback, típicamente para controlar el orden y alcance
de la corrida `GJ04` cuando un venture tiene múltiples sub-áreas de costo.

---

## 8. Atributo JV en el Objeto CO

Un centro de coste, orden interna o elemento WBS se convierte en "JV-relevante" cuando se le
asignan `Venture` + `Equity Group` + `Recovery Indicator` (por defecto) en sus datos maestros. A
partir de ese momento, toda línea contabilizada contra ese objeto hereda el atributo, salvo que una
regla de sustitución JVA lo sobrescriba a nivel de documento.

**Campos típicos añadidos al maestro CO:** `VENTURE`, `EGRUP`, `RECIND` (nombres de campo
orientativos; pueden variar según el release y si son campos estándar o de extensión).

---

## 9. Cadena Organizativa Completa

```
Sociedad (BUKRS)
  └── Área de Controlling (KOKRS)
        └── Venture (T8J1)
              └── Equity Group (T8J2, con vigencia)
                    └── Partners + % de participación
              └── Recovery Indicators (T8J3, customizing global reutilizable entre ventures)
              └── Cutback Group (agrupación de proceso)
        └── Objeto CO (CC / Orden / WBS) — atributo Venture+EGRUP+RECIND
```

---

## 10. Tabla Resumen de Customizing JVA — Estructura Organizativa

| Concepto | Transacción (familia) | Tabla |
|---|---|---|
| Definir Venture | GJxx (mantenimiento maestro) | T8J1 |
| Definir Equity Group y vigencia | GJxx | T8J2 |
| Definir Recovery Indicators | GJxx / SM30 | T8J3 |
| Asignar atributo JV a centro de coste | KS02 (pestaña JVA) | CSKS (campos extendidos) |
| Asignar atributo JV a orden interna | KO02 (pestaña JVA) | AUFK (campos extendidos) |
| Reglas de sustitución JVA | GGB1 (sustitución CO, tipo JVA) | — |

---

## 11. Buenas Prácticas — Estructura Organizativa JVA

1. **Un Equity Group por cada cambio real de participación**, nunca reutilizar un Equity Group
   vigente para reflejar un farm-in/farm-out — crear uno nuevo con `VALFR` correcto.

2. **Recovery Indicators reutilizables entre ventures**, pero con semántica clara y documentada:
   evitar crear un RI nuevo por cada venture si el comportamiento (billable/non-billable/overhead)
   es el mismo — dificulta el mantenimiento y el análisis cross-venture.

3. **Atributo JV en el maestro CO como primera opción**; reservar la sustitución JVA para casos
   genuinamente variables (objeto CO compartido entre ventures o con reglas por cuenta).

4. **Validar que la suma de % del Equity Group sea 100%** antes de dar por cerrado el
   mantenimiento — un error aquí no se detecta hasta la corrida de cutback.

5. **Coordinar la creación de Cutback Groups con el equipo de cierre**: el orden de procesamiento
   de los grupos puede afectar la secuencia de generación de billing hacia los partners.
