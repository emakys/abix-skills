# Liquidación de Gastos Comunes — Service Charge Settlement (SAP RE-FX)

## 1. Introducción

La liquidación de gastos comunes (conocida en el mundo germano-parlante como
**Betriebskostenabrechnung**, y para el componente específico de calefaccion como
**Nebenkostenabrechnung/Heizkostenabrechnung**) es el proceso que compara los **anticipos**
cobrados periódicamente al inquilino (condición de adelanto de gastos comunes, ver
`04-conditions-and-terms.md`) contra el **costo real** incurrido en el periodo, y genera el ajuste
(saldo a favor o en contra) por inquilino.

---

## 2. Conceptos Clave

- **Unidad de Liquidación (Settlement Unit)**: el alcance físico sobre el que se recolectan y
  reparten los costos — puede ser un Building completo, o una agrupación específica dentro de él
  (ej. solo la planta baja comercial de un edificio mixto)
- **Grupo de Participación (Participation Group)**: define qué Rental Objects participan del
  reparto de un tipo de gasto específico dentro de la Unidad de Liquidación, y con qué factor
- **Factor de Reparto (Apportionment Factor)**: el criterio de prorrateo — por superficie, por
  unidad, o por consumo medido (ver `12-participation-groups-apportionment.md` para el detalle)

---

## 3. Flujo del Proceso

```
1. Definir Unidad de Liquidación (alcance) y Grupo(s) de Participación (quién comparte cada gasto)
2. Asignar Rental Objects a la Unidad de Liquidación (y a los Grupos de Participación correspondientes)
3. Recolectar costos reales del periodo (contabilizados en CO/FI contra el objeto/CC del inmueble)
4. Ejecutar la corrida de liquidación (RESC / transacción equivalente)
5. Prorratear cada tipo de gasto según el factor de reparto de su Grupo de Participación
6. Comparar total prorrateado por inquilino vs anticipos ya cobrados en el periodo
7. Generar el documento de liquidación (saldo a favor o en contra) por inquilino
8. Contabilizar el ajuste — partida adicional a cobrar, o nota de crédito si hubo sobre-cobro
```

---

## 4. Tipos de Gasto Típicamente Liquidados

- Mantenimiento de áreas comunes (limpieza, jardinería, seguridad)
- Consumo de energía de áreas comunes
- Calefacción/climatización central (cuando aplica submetering — ver más abajo)
- Seguros del edificio
- Administración del inmueble (fee de property management)
- Impuestos inmobiliarios (cuando el contrato los traslada al inquilino, según jurisdicción y
  práctica de mercado)

---

## 5. Liquidación de Gastos de Calefacción (Heating Cost Settlement)

En jurisdicciones que regulan específicamente el reparto de costos de calefacción (por ejemplo,
bajo normativa tipo **HeizkostenV** en Alemania), el criterio de reparto no es libre: la regulación
suele exigir una combinación obligatoria entre un componente fijo (por superficie) y un componente
variable (por consumo medido individualmente — submetering), en proporciones definidas por ley.

**Implicancia funcional:** si el cliente opera en una jurisdicción con este tipo de regulación, el
Grupo de Participación para calefacción debe configurarse con el split fijo/variable exigido, y el
proceso requiere integración con las lecturas de consumo individual (medidores por unidad) — no es
un simple prorrateo por m² como el resto de los gastos comunes.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Rental Objects asignados a una Unidad de Liquidación

```sql
SELECT meinh, mebez, abrkreis
FROM vibdob
WHERE abrkreis = '{unidad_liquidacion}'
```

### Costos reales del periodo por centro de coste del inmueble

```sql
SELECT rcntr, racct, sum(hsl) as total
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND rcntr = '{cc_inmueble}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
GROUP BY rcntr, racct
```

### Estado de corridas de liquidación por unidad y año

```sql
SELECT abrkreis, gjahr, status
FROM viscabrkr
WHERE gjahr = '{year}'
```

*(Nota: `viscabrkr` es un nombre orientativo — confirmar la tabla real de historial de corridas de
liquidación con `GetWhereUsed`/`SE11` en el sistema del cliente antes de usarla en un reporte
productivo.)*

---

## 7. Errores Frecuentes del Proceso

| Situación | Causa probable |
|---|---|
| Rental Object ausente del resultado de liquidación | No asignado a la Unidad de Liquidación o al Grupo de Participación del gasto |
| Suma de factores de reparto no cuadra al 100% dentro de un Grupo de Participación | Error de mantenimiento del grupo, o vacancia no tratada explícitamente (ver `09-vacancy-management.md`) |
| Costo real del periodo no aparece en la liquidación | No contabilizado aún contra el centro de coste/objeto del inmueble al momento de correr la liquidación |
| Diferencia inesperada grande entre anticipo y liquidación real | Anticipo desactualizado desde hace tiempo (no ajustado a la inflación de costos reales) |

---

## 8. Buenas Prácticas

1. **Revisar y ajustar el monto del anticipo periódicamente** (al menos anual, o tras cada
   liquidación) para minimizar diferencias grandes que generan fricción con el inquilino.

2. **Cerrar la recolección de costos reales del periodo antes de correr la liquidación final** —
   correr la liquidación con costos incompletos obliga a una re-liquidación posterior, generando
   confusión en el inquilino.

3. **Tratar explícitamente la vacancia dentro del Grupo de Participación** (ver
   `09-vacancy-management.md`) — de lo contrario, los costos de unidades vacías pueden quedar
   incorrectamente distribuidos entre los inquilinos ocupados, o perderse sin reflejarse en ningún
   lado.

4. **Documentar y comunicar claramente al inquilino qué gastos se incluyen y con qué criterio de
   reparto** — es tanto una buena práctica de transparencia comercial como una mitigación de
   disputas.

5. **Si aplica regulación local de calefacción (submetering obligatorio)**, validar el cumplimiento
   del split fijo/variable exigido antes de emitir la liquidación — es un riesgo legal, no solo
   funcional.
