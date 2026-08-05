# Objetos Arquitectónicos y Medición de Superficies — SAP RE-FX

## 1. Introducción

El **Architectural Object** es el objeto GPO dedicado a la medición precisa y trazable de
superficies, complementario a la jerarquía Business Entity → Property → Building → Rental Object.
Cobra especial relevancia cuando el negocio necesita rigurosidad en la medición (renta pactada por
m², prorrateo de gastos comunes sensible a superficie, o reporting de portafolio bajo un estándar
reconocido internacionalmente).

---

## 2. Por Qué un Objeto Separado para Medición

Aunque el Rental Object ya tiene un campo de superficie (ver `02-real-estate-objects-master-data.md`),
el Architectural Object permite:

- **Trazabilidad histórica de remediciones**: cada vez que se re-mide un espacio (tras remodelación,
  auditoría de superficie, cambio de estándar aplicado), se preserva el histórico sin sobrescribir
  el dato anterior sin dejar rastro
- **Aplicación de distintos estándares de medición simultáneamente**: el mismo espacio físico puede
  tener una superficie "GIF" y una superficie "BOMA" registradas en paralelo, si el negocio necesita
  reportar bajo ambos criterios (ej. portafolio internacional con inversionistas que exigen
  reporting bajo distintos estándares regionales)
- **Granularidad debajo del Rental Object**: en escenarios de medición muy detallada (ej. desglose
  de superficie útil vs superficie de circulación dentro de la misma unidad)

---

## 3. Estándares de Medición

### 3.1 GIF (Gesellschaft für Immobilienwirtschaftliche Forschung)

Estándar de origen alemán, ampliamente adoptado en Europa continental para medición de superficie
de oficinas, distinguiendo típicamente entre superficie principal, secundaria y de circulación con
reglas específicas de qué se incluye y qué se excluye del área rentable.

### 3.2 BOMA (Building Owners and Managers Association)

Estándar de origen norteamericano, con distintas versiones según el tipo de uso (oficina, retail,
industrial), ampliamente usado en Norteamérica y adoptado en portafolios internacionales que
reportan a inversionistas de esa región.

### 3.3 Por Qué Importa Elegir y Documentar el Estándar

Dos estándares pueden arrojar superficies distintas para el **mismo espacio físico** (tratamiento
distinto de áreas de circulación, columnas estructurales, espesor de muros). Si el contrato pacta
renta por m² sin especificar claramente bajo qué estándar se midió esa superficie, existe riesgo
real de disputa con el inquilino — especialmente en portafolios que operan en múltiples países con
convenciones de medición locales distintas.

---

## 4. Consultas MCP Útiles (GetSqlQuery)

### Architectural Objects de un Rental Object

```sql
SELECT baunr, bauktx, meinh
FROM vibdio
WHERE meinh = '{rental_object}'
```

### Comparación de superficie registrada en el Rental Object vs el detalle del Architectural Object (validación de consistencia)

```sql
SELECT ob.meinh, ob.qmnut as superficie_ob, io.baunr, io.bauktx
FROM vibdob ob
LEFT JOIN vibdio io ON io.meinh = ob.meinh
WHERE ob.meinh = '{rental_object}'
```

*(Consulta orientativa para diagnóstico — los nombres exactos de campo de superficie en `VIBDIO`
deben confirmarse en el sistema real antes de construir reportes formales.)*

---

## 5. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Superficie del Rental Object no coincide con la del Architectural Object vinculado | Remedición registrada solo en uno de los dos objetos, falta de sincronización |
| Disputa de inquilino sobre la superficie facturada | Estándar de medición no documentado explícitamente en el contrato |
| Reporting de portafolio inconsistente entre países | Distintos estándares aplicados sin normalizar para el reporte consolidado |

---

## 6. Buenas Prácticas

1. **Documentar explícitamente en cada contrato bajo qué estándar de medición se pactó la
   superficie** — previene la causa más común de disputa relacionada a renta por m².

2. **Sincronizar cualquier remedición entre el Rental Object y su(s) Architectural Object(s)
   vinculado(s)** — evitar que ambos queden con valores distintos tras una actualización parcial.

3. **Si el portafolio opera en múltiples países, definir desde el diseño si se normalizará el
   reporting consolidado a un único estándar**, o si se reportará explícitamente separado por
   estándar regional — evita comparaciones erróneas de portafolio "manzanas con naranjas".

4. **Conservar el histórico de remediciones** (no sobrescribir sin dejar rastro) — es evidencia
   relevante ante cualquier disputa o auditoría de superficie.
