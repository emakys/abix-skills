# Integración RE-FX ↔ FI-AA — Activos Fijos y ROU

## 1. Introducción

RE-FX se integra con Financial Accounting - Asset Accounting (FI-AA) en **dos escenarios
distintos**, que no deben confundirse:

1. **Lado lessor (lease-out)**: el inmueble propio arrendado a terceros suele estar también
   registrado como activo fijo tradicional (terreno/edificio), con su propio plan de depreciación —
   independiente del contrato de renta que genera el ingreso
2. **Lado lessee (lease-in)**: el contrato de arrendamiento entrante genera automáticamente un
   activo fijo especial — el **Right-of-Use asset (ROU)** — bajo IFRS 16, distinto en naturaleza y
   tratamiento de un activo de propiedad tradicional

---

## 2. Escenario Lessor — Inmueble Propio como Activo Fijo

Cuando la empresa es propietaria del inmueble que arrienda (lease-out), el Building/Property
normalmente ya existe como activo fijo en FI-AA desde su adquisición o construcción, siguiendo el
proceso estándar de capitalización (compra directa, o vía liquidación de un proyecto PS de
construcción).

**Relación con RE-FX:** el objeto inmobiliario (Building/Property en la jerarquía GPO) puede
vincularse por referencia al activo fijo correspondiente, permitiendo:
- Cruzar rentabilidad del activo: ingreso por renta (RE-FX) vs depreciación y costo de
  mantenimiento (FI-AA/CO) del mismo inmueble
- Coordinar bajas/ventas del inmueble con la terminación de los contratos vigentes sobre sus
  Rental Objects

Esta vinculación es de **referencia/análisis**, no automática en el sentido de que RE-FX no genera
ni modifica el activo fijo del inmueble propio — ese ciclo de vida lo gestiona FI-AA de forma
independiente.

---

## 3. Escenario Lessee — ROU Asset (IFRS 16)

A diferencia del escenario anterior, en lease-in el activo fijo **sí se genera desde RE-FX**: al
completar la clasificación IFRS 16 del contrato y activarlo, el sistema crea automáticamente el
activo ROU en FI-AA con su plan de amortización financiera derivado del contrato. Ver detalle
completo del cálculo y remedición en `07-lease-in-ifrs16.md`.

**Clase de activo:** requiere una(s) clase(s) de activo dedicada(s) para ROU assets, separada de
las clases de activos de propiedad tradicional — necesario para que el balance distinga claramente
activos propios de derechos de uso sobre bienes de terceros, y para aplicar el tratamiento de
depreciación/baja correcto (que sigue el plazo del arrendamiento, no la vida útil física del
activo subyacente).

---

## 4. Diferencias Clave entre los Dos Escenarios

| Aspecto | Inmueble propio (lease-out) | ROU asset (lease-in) |
|---|---|---|
| Origen del activo | Adquisición/construcción, proceso FI-AA estándar | Generado automáticamente desde el contrato RE-FX |
| Vida útil/plazo de depreciación | Vida útil física del inmueble | Plazo del arrendamiento (lease term) |
| Qué representa | Propiedad legal del bien | Derecho de uso, no propiedad |
| Pasivo asociado | No necesariamente (puede o no tener financiamiento) | Sí — pasivo por arrendamiento, siempre |
| Remedición periódica especial | No (depreciación estándar) | Sí — ante modificaciones de contrato o cambios en evaluación de opciones |

---

## 5. Consultas MCP Útiles (GetSqlQuery)

### Activos fijos vinculados a inmuebles propios de una sociedad

```sql
SELECT anln1, anln2, anlkl, aktiv
FROM anla
WHERE bukrs = '{sociedad}'
  AND anlkl IN ('{clases_activo_inmueble_propio}')
```

### Activos ROU (lease-in) de una sociedad

```sql
SELECT anln1, anln2, anlkl, aktiv
FROM anla
WHERE bukrs = '{sociedad}'
  AND anlkl = '{clase_activo_rou}'
```

### Depreciación acumulada de un inmueble propio (Universal Journal)

```sql
SELECT racct, sum(hsl) as total
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND anln1 = '{activo}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
GROUP BY racct
```

---

## 6. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| ROU asset generado en clase de activo incorrecta (mezclado con propiedad tradicional) | Customizing de clase de activo ROU no configurado o mal asignado al tipo de contrato |
| Inmueble propio sin vínculo de referencia a su activo fijo | Vinculación no establecida al momento de crear el objeto RE-FX, actividad manual/opcional según diseño |
| Depreciación del ROU no sigue el plazo del arrendamiento | Parametrización de vida útil del activo ROU copiada por error del patrón estándar de propiedad |

---

## 7. Buenas Prácticas

1. **Nunca mezclar clases de activo de propiedad tradicional con ROU assets** — el tratamiento
   contable, plazo y naturaleza del activo son fundamentalmente distintos.

2. **Establecer la vinculación de referencia entre objeto RE-FX e inmueble propio en FI-AA** desde
   el alta del objeto, si el negocio requiere análisis cruzado de rentabilidad por activo.

3. **Coordinar el proceso de baja/venta de un inmueble propio con RE-FX** — no debería completarse
   la baja del activo fijo si aún existen contratos vigentes sobre Rental Objects de ese inmueble
   sin resolver.

4. **Validar con el equipo de FI-AA la correcta configuración de la clase de activo ROU** antes de
   activar el primer contrato lease-in en producción — un error aquí afecta el balance desde el
   primer contrato.
