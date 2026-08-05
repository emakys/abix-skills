# Datos Maestros — Venture, Equity Group y Partner (SAP JVA)

## 1. Introducción

Antes de que cualquier costo pueda pasar por cutback o billing, deben existir tres piezas de
datos maestros correctamente parametrizadas: el **Venture**, su(s) **Equity Group(s)** con
vigencia, y los **Partners** con su porcentaje de participación. Un error de mantenimiento en
cualquiera de estas tres capas se propaga silenciosamente hasta el momento del cutback, donde
recién se manifiesta como un rechazo o una distribución incorrecta.

---

## 2. Creación de un Venture

Datos mínimos a definir:

- **Clave del venture** (código corto, normalmente alineado al nombre del campo/bloque/activo)
- **Nombre/descripción**
- **Indicador de operador**: si la sociedad local es el operador de este venture o no
- **Moneda del venture** (puede diferir de la moneda local de la sociedad si el JOA se administra
  en una moneda distinta, típicamente USD en Oil & Gas)
- **Sociedad/Área de Controlling** de referencia

**Tabla:** `T8J1`

**Errores comunes al crear un venture:**
- Omitir el indicador de operador → el sistema no sabe si debe correr cutback local o solo recibir
  billing de un operador externo
- Moneda del venture inconsistente con la moneda de los objetos CO asociados → diferencias de
  conversión en el cutback

---

## 3. Equity Group — Mantenimiento

El Equity Group agrupa a los partners y sus porcentajes, con vigencia temporal. Un venture puede
tener varios Equity Groups activos simultáneamente si distintas áreas de costo dentro del mismo
venture tienen distinta composición de partners (ej. un pozo con partners distintos al resto del
campo).

**Datos a mantener:**
- Clave de Equity Group
- Venture al que pertenece
- Vigencia (`VALFR` / `VALTO`)
- Lista de partners con su % (debe sumar 100%)

**Tabla cabecera:** `T8J2`. Detalle de partners y % — confirmar nombre exacto de tabla en el
sistema real (varía por release); no asumir un nombre fijo sin verificar.

**Regla de vigencia:** cuando cambia la composición de partners (farm-in/farm-out, renegociación),
se crea un **nuevo periodo de Equity Group** con `VALFR` = fecha efectiva del cambio; el periodo
anterior se cierra con `VALTO` = día previo. El cutback de un periodo histórico siempre debe usar
el Equity Group vigente en la fecha del documento, no el actual.

---

## 4. Partner — Modelado

El partner se representa típicamente como un **acreedor/deudor (Business Partner con rol
FI-AP/AR)**, porque el resultado del cutback y del billing debe poder generar partidas contables
reales (factura al partner no-operador, o partida de compensación si el partner es la propia
sociedad operadora vista desde otra perspectiva).

**Datos clave del partner en el contexto JVA:**
- Vinculación al Business Partner / cuenta de mayor de reconciliación
- Cuenta bancaria y condiciones de pago (para el billing JIB)
- Rol: operador vs no-operador (puede variar por venture — una misma compañía puede ser operadora
  en un venture y no-operadora en otro)

---

## 5. Working Interest vs Participating Interest

Estos dos porcentajes no siempre coinciden y es una fuente frecuente de confusión funcional:

- **Working Interest (WI)**: porcentaje de participación en costos e ingresos operativos del
  venture, tal como está definido en el JOA.
- **Participating Interest (PI)**: porcentaje efectivo de participación después de ajustes
  contractuales (carried interest, non-consent, back-in rights). En ausencia de estos ajustes,
  PI = WI.

JVA modela el reparto de cutback con el porcentaje vigente en el Equity Group, que en la práctica
representa el PI efectivo del periodo — si hay carried interest o non-consent activos, se necesita
un Equity Group o Recovery Indicator específico para ese escenario (ver `11-non-consent-adjustments.md`
y `12-farm-in-farm-out-carried-interest.md`).

---

## 6. Validaciones al Mantener Datos Maestros

| Validación | Por qué importa |
|---|---|
| Suma de % del Equity Group = 100% | El cutback distribuye proporcionalmente; si no suma 100%, quedan costos sin asignar o sobre-asignados |
| Vigencias sin solapamiento ni huecos | Un documento con fecha en un "hueco" de vigencia no encuentra Equity Group válido → error en cutback |
| Partner con datos bancarios/fiscales completos | El billing JIB no puede generarse ni contabilizarse sin esos datos |
| Venture con moneda consistente con objetos CO | Evita diferencias de conversión en el resultado del cutback |

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Ventures activos y su indicador de operador

```sql
SELECT venture, vname, opind, waers
FROM t8j1
ORDER BY venture
```

### Equity Groups vigentes de un venture a la fecha actual

```sql
SELECT venture, egrup, valfr, valto
FROM t8j2
WHERE venture = '{venture}'
ORDER BY valfr DESC
```

### Objetos CO marcados como JV-relevantes de un venture

```sql
SELECT kostl, venture, egrup, recind
FROM csks
WHERE venture = '{venture}'
```

---

## 8. Buenas Prácticas

1. **Mantener un catálogo maestro de partners centralizado**, no duplicar el mismo partner con
   claves distintas por venture — dificulta el reporting consolidado por partner.

2. **Documentar el JOA de referencia** (número de contrato, fecha de firma) como texto en el
   venture o en un campo custom — facilita la trazabilidad ante auditorías de partner.

3. **Revisar vigencias de Equity Group antes de cada cierre de periodo**: un venture con
   composición de partners que cambia frecuentemente (farm-outs parciales) es más propenso a
   huecos de vigencia si no se disciplina el mantenimiento.

4. **No reutilizar la clave de Equity Group** para representar una composición completamente
   distinta — mejor crear una clave nueva y dejar la vieja con `VALTO` cerrado, para preservar
   legibilidad histórica en auditorías.
