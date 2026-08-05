# AFE — Authorization for Expenditure (SAP JVA + PS/CO)

## 1. Introducción

El **AFE (Authorization for Expenditure)** es el documento de negocio con el que el operador
solicita, y los partners aprueban, el presupuesto para una actividad específica dentro del venture
(perforar un pozo, construir una facilidad, una campaña de workover). No es un objeto técnico
exclusivo de JVA — se modela normalmente sobre **elementos WBS (PS)** o, en implementaciones más
simples, sobre **órdenes internas (CO)** con presupuesto — pero su gobierno (aprobación de
partners, control de gasto vs autorizado) es un proceso de negocio central en la operación de un
joint venture.

---

## 2. Ciclo de Vida de un AFE

1. **Estimación**: el operador prepara la estimación de costo de la actividad propuesta
2. **Circulación para aprobación**: se distribuye a los partners (proceso normalmente fuera de
   SAP, vía el mecanismo de gobierno del JOA — puede incluir plazos de respuesta y derecho a voto
   proporcional al % de participación)
3. **Aprobación (o non-consent parcial)**: los partners aprueban, o algunos declinan participar
   (ver `11-non-consent-adjustments.md`)
4. **Registro del presupuesto aprobado en SAP**: se refleja como presupuesto de la orden/WBS
   correspondiente
5. **Ejecución**: los costos reales se contabilizan contra el objeto CO, con seguimiento de
   ejecutado vs autorizado
6. **Cierre del AFE**: cuando la actividad concluye, se revisa el gasto final vs lo autorizado y se
   documenta cualquier sobre-ejecución (over-AFE) que requiera una autorización suplementaria

---

## 3. AFE como WBS Element (Patrón Recomendado)

Cuando la actividad es de duración/complejidad significativa (perforación de un pozo, por
ejemplo), modelarla como proyecto PS con elementos WBS permite:

- Presupuestar y controlar por fases (elementos WBS jerárquicos: pozo → fases de perforación)
- Aprovechar el control de disponibilidad presupuestaria estándar de PS (availability control)
- Vincular el atributo JV (Venture/Equity Group/Recovery Indicator) a nivel de WBS, heredado por
  los objetos de coste inferiores del proyecto

---

## 4. AFE como Orden Interna (Patrón Simplificado)

Para actividades más simples o de menor monto, una orden interna con presupuesto (`KO22`) puede
ser suficiente, evitando la complejidad de un proyecto PS completo cuando no se justifica.

---

## 5. Control de Ejecutado vs Autorizado

El seguimiento de "cuánto se ha gastado contra el AFE aprobado" usa las herramientas estándar de
disponibilidad presupuestaria de CO/PS (no es una funcionalidad exclusiva de JVA), comparando el
presupuesto cargado contra el compromiso (pedidos abiertos) y el real contabilizado. La dimensión
JV-específica es que ese control debe leerse en conjunto con el Equity Group vigente, porque una
sobre-ejecución del AFE tiene implicancia directa en cuánto se le termina facturando a cada
partner vía cutback.

---

## 6. Relación AFE — Cash Call

Los AFEs de monto significativo suelen ser el disparador de cash calls: en vez de esperar al ciclo
normal de cutback mensual, se solicita financiamiento anticipado a los partners específicamente
para el AFE, dado el tamaño del compromiso. Ver `07-cash-calls-advances.md`.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Presupuesto vs ejecutado de un AFE modelado como WBS

```sql
GetSqlQuery("SELECT posid,post1,plikz FROM prps WHERE pspid='{proyecto}'")
-- Cruzar contra ACDOCA para el gasto real y contra la tabla de presupuesto PS (BPJA/BPGE según el esquema usado)
```

### Órdenes internas usadas como AFE, con atributo JV

```sql
SELECT aufnr, ktext, venture, egrup, recind
FROM aufk
WHERE venture = '{venture}'
  AND auart = '{tipo_orden_afe}'
```

---

## 8. Errores Frecuentes en el Ciclo de AFE

| Error | Causa | Fix |
|---|---|---|
| Gasto contabilizado contra un AFE sin atributo JV | El WBS/orden se creó sin completar Venture/Equity Group/Recovery Indicator | Corregir el maestro antes de contabilizar más, revisar líneas ya contabilizadas |
| Sobre-ejecución no detectada a tiempo | Falta de disponibilidad presupuestaria activa (availability control) en el objeto | Activar/parametrizar el control de disponibilidad presupuestaria |
| Partner disputa costos por encima del AFE aprobado | Falta de proceso formal de autorización suplementaria antes de la sobre-ejecución | Establecer y documentar el flujo de aprobación de "AFE supplement" antes de superar el monto original |

---

## 9. Buenas Prácticas

1. **No contabilizar costos contra un objeto CO destinado a un AFE hasta confirmar que el atributo
   JV está completo** — corregir retroactivamente es más costoso que prevenir.

2. **Modelar AFEs de perforación como WBS jerárquico** para poder analizar el costo por fase
   (locación, perforación, completación) de cara al reporting a partners.

3. **Vincular explícitamente cada cash call a su AFE de origen** en la documentación del proceso,
   aunque el sistema no siempre fuerce esa relación técnicamente.

4. **Revisar el estado de aprobación de partners antes de autorizar sobre-ejecución** — gastar por
   encima de lo aprobado sin respaldo formal es una de las causas más frecuentes de disputas
   serias entre operador y partners.
