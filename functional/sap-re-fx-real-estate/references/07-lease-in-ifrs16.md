# Lease-in e IFRS 16 / ASC 842 — SAP RE-FX

## 1. Introducción

Cuando la empresa es **arrendataria** (lease-in) de un inmueble de un tercero, los estándares
contables modernos (**IFRS 16** internacionalmente, **ASC 842** en el marco US GAAP) exigen
reconocer en el balance un **activo por derecho de uso (Right-of-Use / ROU asset)** y un
**pasivo por arrendamiento (Lease Liability)**, reemplazando el tratamiento anterior donde muchos
arrendamientos operativos solo se reconocían como gasto lineal fuera de balance.

RE-FX embebido en S/4HANA integra esta lógica directamente con el contrato lease-in: al completar
la clasificación IFRS 16 del contrato, el sistema puede generar automáticamente el activo ROU en
FI-AA y el pasivo correspondiente, con su propio plan de amortización financiera.

---

## 2. Clasificación del Contrato

- **Arrendamiento a capitalizar (on-balance)**: la gran mayoría de los contratos lease-in de largo
  plazo bajo IFRS 16 se reconocen en balance — IFRS 16 eliminó, para el arrendatario, la
  distinción operativo/financiero que existía en el estándar anterior (IAS 17)
- **Excepciones de reconocimiento** (según política contable del cliente, alineada al estándar):
  - **Arrendamientos de corto plazo**: plazo ≤ 12 meses y sin opción de compra
  - **Activos subyacentes de bajo valor**: umbral definido por política contable del cliente (el
    estándar da un ejemplo orientativo, pero cada empresa fija su propio umbral de materialidad)
- Bajo **ASC 842** (US GAAP), a diferencia de IFRS 16, sí se mantiene una distinción entre
  arrendamiento financiero y operativo para efectos de presentación en el estado de resultados,
  aunque ambos se reconocen en balance

**Nota importante:** la clasificación contable es una **decisión de política contable del
cliente**, típicamente definida por el equipo de Accounting Policy/FI, no una decisión técnica que
el consultor RE-FX tome unilateralmente. El rol de RE-FX es parametrizar correctamente el contrato
según esa política ya definida.

---

## 3. Componentes del Cálculo

- **Pagos de arrendamiento (Lease Payments)**: incluye renta fija, y componentes variables que
  dependan de un índice o tasa (los componentes puramente variables no ligados a índice, como
  renta por % de ventas, generalmente se excluyen de la medición inicial del pasivo y se
  reconocen como gasto en el periodo en que se incurren)
- **Plazo del arrendamiento (Lease Term)**: plazo no cancelable más periodos cubiertos por
  opciones de renovación/terminación que sea razonablemente cierto ejercer
- **Tasa de descuento**: la tasa implícita del arrendamiento si es determinable fácilmente, o —el
  caso más común en la práctica— la **tasa incremental de financiamiento del arrendatario**
- **Componentes no-lease**: servicios incluidos en el contrato (ej. mantenimiento, limpieza) que,
  salvo que el cliente aplique la exención práctica de no separarlos, deben excluirse de la
  medición del arrendamiento y tratarse como gasto de servicio separado

---

## 4. Generación del ROU Asset y el Pasivo

Al completar la clasificación IFRS 16 del contrato lease-in y confirmar/activar el contrato, el
sistema:

1. Calcula el valor presente de los pagos de arrendamiento con la tasa de descuento parametrizada
2. Genera el **pasivo por arrendamiento** inicial por ese valor presente
3. Genera el **activo por derecho de uso (ROU)** en FI-AA, típicamente por un monto igual al pasivo
   inicial (ajustado por costos directos iniciales, incentivos recibidos y pagos anticipados, según
   corresponda)
4. Establece el plan de amortización financiera: el pasivo se reduce con cada pago, reconociendo
   gasto financiero (interés implícito) por separado; el activo ROU se amortiza linealmente (o
   según el patrón de consumo) a lo largo del plazo del arrendamiento

**Clase de activo ROU:** requiere una clase de activo específica en el customizing de FI-AA,
separada de las clases de activos inmobiliarios propios, para diferenciar claramente en el balance
qué activos son propiedad y cuáles son derecho de uso sobre bienes de terceros.

---

## 5. Remedición del Pasivo (Lease Modifications & Reassessments)

Eventos que requieren remedir el pasivo (y ajustar el ROU correspondientemente) durante la vida del
contrato:
- Modificación del contrato (ej. extensión de plazo, cambio de espacio arrendado)
- Cambio en la evaluación de si es razonablemente cierto ejercer una opción de renovación/terminación
- Cambio en pagos que dependen de un índice o tasa (ej. ajuste por indexación de la renta —
  requiere recalcular el pasivo con el nuevo flujo de pagos esperado)

Cada uno de estos eventos genera un ajuste contable específico, distinto del simple reconocimiento
periódico de amortización/interés.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Activos ROU generados por contratos lease-in de una sociedad

```sql
SELECT bukrs, anln1, anln2, anlkl, aktiv
FROM anla
WHERE bukrs = '{sociedad}'
  AND anlkl = '{clase_activo_rou}'
```

### Contratos lease-in vigentes sin clasificación IFRS 16 completa (gap a corregir)

```sql
-- Requiere cruzar VICNCN (tipo lease-in) contra los campos de clasificación IFRS 16 del contrato
SELECT vertrag, vertnr, verttyp
FROM vicncn
WHERE verttyp = '{tipo_contrato_lease_in}'
  AND vbegdat <= CURRENT_DATE
  AND venddat >= CURRENT_DATE
```

---

## 7. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| ROU asset no generado | Contrato lease-in sin clasificación IFRS 16 completa, o clase de activo ROU no configurada en customizing |
| Pasivo y activo con montos que no cuadran al inicio | Costos directos iniciales, incentivos o pagos anticipados no parametrizados correctamente |
| Gasto financiero no se reconoce periódicamente | Plan de amortización financiera no generado o no ejecutado en el cierre |
| Remedición no reflejada tras modificación de contrato | Evento de modificación no disparó el recálculo (proceso manual u omitido) |

---

## 8. Buenas Prácticas

1. **Involucrar al equipo de Accounting Policy en la definición del umbral de bajo valor y en la
   metodología de tasa de descuento** antes de parametrizar contratos — es una decisión contable,
   no técnica.

2. **Completar la clasificación IFRS 16 en el momento de creación del contrato lease-in**, evitando
   contabilizaciones provisionales que después requieren corrección retroactiva.

3. **Establecer un proceso disciplinado de identificación de eventos de remedición** (modificación
   de contrato, cambio en evaluación de opciones) — es fácil que pasen desapercibidos si no hay un
   checklist explícito ligado a cada cambio de contrato.

4. **Reconciliar periódicamente el saldo del pasivo por arrendamiento en FI contra el detalle por
   contrato en RE-FX** — una diferencia aquí indica un evento de remedición no procesado o un error
   de contabilización.
