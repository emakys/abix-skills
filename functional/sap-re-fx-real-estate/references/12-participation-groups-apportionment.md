# Grupos de Participación y Factores de Reparto — SAP RE-FX

## 1. Introducción

El **Grupo de Participación (Participation Group)** es el mecanismo de customizing que determina,
para cada tipo de gasto dentro de una Unidad de Liquidación, **quién comparte el costo** y **con
qué factor**. Es el corazón técnico de la precisión (o imprecisión) de la liquidación de gastos
comunes — ver `05-service-charge-settlement.md` para el proceso completo.

---

## 2. Estructura de un Grupo de Participación

- **Unidad de Liquidación** a la que pertenece (el alcance físico del reparto)
- **Tipo(s) de gasto** que cubre (puede haber un grupo distinto por cada tipo de gasto, o uno
  combinado según el diseño)
- **Rental Objects miembros** del grupo, con vigencia (un objeto puede entrar/salir del grupo si
  cambia su condición — ej. deja de estar vacante)
- **Factor de reparto** aplicable a cada miembro

---

## 3. Tipos de Factor de Reparto

| Factor | Cuándo usarlo |
|---|---|
| **Por superficie (m²)** | El más común — proporcional al área del Rental Object sobre el total del grupo |
| **Por unidad (partes iguales)** | Gastos que no varían con el tamaño (ej. limpieza de accesos comunes, en algunos diseños) |
| **Por consumo medido (submetering)** | Gastos con medición individual real — típicamente energía o calefacción con medidor propio por unidad |
| **Factor fijo/manual** | Casos negociados específicamente distintos al criterio general del grupo (ej. un inquilino ancla con acuerdo particular) |

---

## 4. Cálculo del Reparto

```
Costo total del tipo de gasto en el periodo (recolectado de CO/FI)
  ÷ Suma de los factores de todos los miembros del Grupo de Participación
  × Factor individual del Rental Object
  = Monto asignado a ese Rental Object
```

La precisión de este cálculo depende críticamente de que:
1. La suma de factores sea consistente y completa (sin miembros faltantes ni duplicados)
2. La vigencia de membresía de cada objeto sea correcta para el periodo liquidado
3. El tratamiento de vacancia esté explícitamente resuelto (ver `09-vacancy-management.md`)

---

## 5. Cambios de Membresía Durante el Periodo

Cuando un Rental Object entra o sale del grupo **dentro** del periodo de liquidación (ej. nuevo
inquilino que ocupa una unidad previamente vacante a mitad de mes), el sistema debe prorratear
correctamente el factor de ese objeto por los días de membresía efectiva dentro del periodo, no
aplicar el factor completo como si hubiera sido miembro todo el periodo.

**Riesgo funcional:** si la vigencia de membresía no se mantiene con precisión diaria, la
liquidación puede sobre-cargar o sub-cargar a los objetos con cambios de ocupación durante el
periodo — fuente frecuente de disputas de inquilinos que se mudaron a mitad de periodo.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Miembros de un Grupo de Participación con su factor

```sql
-- Nombre de tabla de detalle de grupo de participación orientativo, confirmar en el sistema real
SELECT meinh, faktor, datab, datbi
FROM visc_partgrp
WHERE partgrp = '{grupo_participacion}'
```

### Rental Objects de un Building con su superficie (base típica del factor)

```sql
SELECT meinh, mebez, qmnut
FROM vibdob
WHERE gebaeude = '{building}'
```

---

## 7. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Suma de factores no cuadra al 100% (o al total esperado) | Miembro faltante, duplicado, o factor mal cargado |
| Objeto con cambio de ocupación a mitad de periodo mal prorrateado | Vigencia de membresía no mantenida con precisión diaria |
| Inquilino disputa el monto de un gasto con submetering | Lectura de consumo individual no cargada o cargada con error |
| Objeto excluido incorrectamente del grupo | Vigencia de membresía vencida sin renovar tras cambio de contrato |

---

## 8. Buenas Prácticas

1. **Validar la suma de factores del grupo cada vez que cambia su composición**, no esperar al
   momento de correr la liquidación para descubrir un desbalance.

2. **Mantener la vigencia de membresía sincronizada con los cambios de ocupación** (nuevo contrato,
   finalización de contrato, cambio de estado a vacante) de forma automática o con un checklist
   disciplinado si el proceso es manual.

3. **Documentar el criterio de factor elegido por cada tipo de gasto** — no todos los gastos deben
   usar el mismo factor dentro del mismo edificio, y esa decisión debe quedar trazable.

4. **Para gastos con submetering, validar la completitud de las lecturas antes de correr la
   liquidación** — una lectura faltante distorsiona el reparto de todo el grupo, no solo del
   objeto sin lectura.
