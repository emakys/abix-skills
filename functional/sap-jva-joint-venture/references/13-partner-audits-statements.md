# Partner Audits y Statements — Transparencia hacia los Socios (SAP JVA)

## 1. Introducción

La relación entre el operador y los partners no-operadores se sostiene en la confianza de que el
reparto de costos es correcto y auditable. Dos mecanismos formales sostienen esa confianza: el
**statement periódico** (el detalle que acompaña cada billing) y el **derecho de auditoría del
partner (partner audit)**, contractualmente reconocido en la mayoría de los JOAs, que permite a
cada partner revisar en detalle los registros del operador relacionados con el venture.

---

## 2. Statement — Contenido y Nivel de Detalle

Un statement bien diseñado debe permitir al partner reconciliar, sin ambigüedad, el monto
facturado contra:

- El detalle de costo por categoría/cuenta
- El % de participación aplicado (y el Equity Group de referencia, con su vigencia)
- El overhead recovery aplicado, separado del costo directo
- Ajustes de periodos anteriores, claramente identificados como tales
- Aplicación de cash calls previamente recibidos

La falta de alguno de estos elementos es la causa más común de fricción entre operador y partners
— no porque el cálculo esté mal, sino porque el partner no puede verificarlo con la información
provista.

---

## 3. Partner Audit — Proceso

1. El partner (o un tercero auditor en su representación) solicita formalmente acceso a los
   registros del venture para un periodo determinado
2. El operador prepara y provee la evidencia: detalle de `GJUBI`, documentos de origen (facturas,
   pedidos), customizing relevante (Equity Group vigente, Recovery Indicators aplicados)
3. El auditor revisa muestras de transacciones, cuestiona clasificaciones o montos específicos
4. Los hallazgos válidos derivan en ajustes de periodo corriente (ver `10-settlement-closing.md`
   §5), no en reapertura de periodos ya cerrados salvo excepción justificada

---

## 4. Preparación Proactiva para Auditorías

Buenas prácticas de la industria (no específicas de SAP, pero que el diseño del sistema debe
soportar):

- Mantener trazabilidad completa desde el documento de costo original hasta la línea de billing
  final (objeto CO → línea ACDOCA → línea GJUBI → documento JIB)
- Preservar el histórico de vigencias de Equity Group y Recovery Indicators usados en cada periodo,
  no solo su valor actual
- Documentar cualquier ajuste manual o re-ejecución de cutback con su justificación

---

## 5. Reportes de Soporte a Auditoría

| Reporte | Propósito |
|---|---|
| Detalle GJUBI por venture/periodo/partner | Base de cualquier revisión de auditoría |
| Reconciliación GJUBI vs ACDOCA | Demuestra que no hay costo "perdido" fuera del reparto |
| Historial de vigencias de Equity Group | Justifica el % aplicado en cada periodo |
| Log de re-ejecuciones de cutback | Evidencia de control sobre cambios posteriores al cierre |
| Detalle de ajustes de periodo anterior | Trazabilidad de correcciones post-cierre |

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Extracto completo de un partner para un periodo (base de un statement)

```sql
SELECT recind, belnr, wkgbtr, value_type
FROM gjubi
WHERE venture = '{venture}'
  AND partner = '{partner}'
  AND gjahr = '{year}'
ORDER BY recind, belnr
```

### Trazabilidad de una línea de billing hasta su documento de origen

```sql
-- Desde GJUBI, obtener el documento de referencia y buscarlo en ACDOCA
SELECT belnr, buzei, racct, hsl, budat
FROM acdoca
WHERE belnr = '{documento_origen}'
  AND gjahr = '{year}'
```

---

## 7. Errores Frecuentes en el Proceso de Auditoría

| Error | Causa | Fix |
|---|---|---|
| No se puede rastrear una línea de billing hasta su documento de origen | Falta de referencia consistente entre GJUBI y el documento ACDOCA original | Revisar el diseño de trazabilidad; puede requerir mejora de campos de referencia |
| Statement no incluye el detalle suficiente para reconciliar | Diseño del formato de statement incompleto | Rediseñar el statement incluyendo los elementos de §2 |
| Auditoría revela un patrón sistemático de mala clasificación | Recovery Indicator o sustitución mal diseñada desde el origen | Corregir customizing y evaluar el impacto retroactivo con el equipo legal/contable |

---

## 8. Buenas Prácticas

1. **Tratar cada statement como si fuera a ser auditado** — el nivel de detalle no debería
   depender de si se espera o no una auditoría formal.

2. **Responder a solicitudes de auditoría con evidencia extraída del sistema, no reconstruida
   manualmente** — reduce el riesgo de inconsistencias y demuestra control del proceso.

3. **Revisar con el equipo legal cualquier hallazgo de auditoría antes de comunicar una
   corrección** al partner — los ajustes financieros de un venture compartido pueden tener
   implicancias contractuales más allá del cálculo técnico.

4. **Mantener un calendario de auditorías esperadas** (muchos JOAs limitan la ventana de tiempo en
   que un partner puede auditar un periodo determinado) para priorizar la preparación de evidencia.
