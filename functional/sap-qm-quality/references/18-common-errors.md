# Errores Frecuentes QM

## Por clase de mensaje

### QE — Results Recording

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| QE 013 | No inspection plan found | Sin plan para material/tipo | QP01 crear plan o asignar en QMAT |
| QE 025 | No inspection characteristics | Plan sin MICs | QP02 agregar MICs a operaciones |
| QE 040 | Results already confirmed | Resultados ya confirmados | Solo reversar si configurado |
| QE 055 | Sample size not determined | Sin procedimiento muestreo | QDV1 crear y asignar en plan |
| QE 080 | Value outside tolerance | Resultado fuera de limites | Verificar limites MIC o valor |

### QA — Inspection Lot / Usage Decision

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| QA 005 | Inspection type not active | Tipo inspeccion inactivo | MM02 → QM view → activar tipo |
| QA 316 | No stock available for posting | Stock insuficiente para mov. UD | Verificar MARD, cantidades en lote |
| QA 360 | Inspection lot locked | Lote bloqueado | Esperar o desbloquear |
| QA 501 | Usage decision already made | UD ya registrada | Solo si se permite cambio |
| QA 510 | Results not yet confirmed | Resultados sin confirmar | QE51N confirmar resultados |
| QA 520 | Inspection lot already closed | Lote cerrado | No se puede modificar |

### QI — Material / QM View

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| QI 008 | Material not relevant for inspection | Vista QM no activa | MM02 → QM view activar |
| QI 010 | Inspection type not maintained | Tipo no configurado en QMAT | MM02 → QM view → tipo inspeccion |
| QI 015 | No QM procurement key | Sin clave QM en info record | ME12 → asignar QM key |

### QM — Notifications

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| QM 100 | Notification type not allowed | Tipo no permitido | Verificar autorizaciones |
| QM 110 | Priority required | Prioridad obligatoria | Indicar prioridad en aviso |
| QM 200 | Task not completed | Tareas pendientes | Completar tareas antes de cerrar |
| QM 210 | Defect items required | Items obligatorios | Agregar al menos un item defecto |

### QP — Inspection Planning

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| QP 045 | Sampling procedure not found | Sin procedimiento muestreo | QDV1 crear |
| QP 050 | Plan not released | Plan en status creado | QP02 → cambiar status a released |
| QP 060 | No valid plan for date | Plan fuera de validez | QP02 → extender validez |

## Diagnostico rapido por codigo

```
QE *** → Resultados (QASR, QASE, PLMK)
QA *** → Lote inspeccion / UD (QALS, QAVE, QMAT)
QI *** → Material QM view (QMAT, info record)
QM *** → Avisos calidad (QMEL, QMFE, QMSM)
QP *** → Planes inspeccion (PLKO, PLPO, PLMK)
```

## Workflow diagnostico QM

```
1. Identificar clase mensaje (QE, QA, QI, QM, QP)
2. T100 → texto exacto
3. GetWhereUsed → programa fuente
4. Leer condicion en codigo
5. Consultar datos:
   - QA/QE: QALS, QMAT, PLKO
   - QM: QMEL, QMFE
   - QI: QMAT, info record
6. Causa raiz → solucion
```

## Consultas MCP diagnostico

```sql
-- Texto del mensaje
SELECT TEXT FROM T100 WHERE ARBGB = '{clase}' AND MSGNR = '{num}' AND SPRSL = 'E'

-- QA 005: tipo inspeccion no activo
SELECT ART, AKTESSION FROM QMAT WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- QE 013: plan no encontrado
SELECT PLNTY, PLNNR, STATU FROM PLKO
WHERE MATNR = '{mat}' AND WERKS = '{centro}' AND PLNTY = 'Q'

-- QA 316: stock para posting
SELECT LGORT, LABST, INSME, SPEME FROM MARD
WHERE MATNR = '{mat}' AND WERKS = '{centro}'
```
