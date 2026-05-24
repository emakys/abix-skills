# Lotes de Inspeccion

## Concepto

El lote de inspeccion (inspection lot) es el documento central de QM. Representa una cantidad de material que debe ser inspeccionada. Se crea automatica o manualmente.

## Tabla principal — QALS

```sql
SELECT PRUESSION, MATNR, WERKS, ART, HERESSION, LOESSION,
       LMESSION, STAT, CHARG, LIFNR, AUFNR, EBESSION
FROM QALS
WHERE PRUESSION = '{lote}'
```

| Campo | Descripcion |
|-------|-------------|
| PRUESSION | Numero lote inspeccion |
| MATNR | Material |
| WERKS | Centro |
| ART | Tipo inspeccion (01, 03, 04...) |
| HERESSION | Origen (01=GR, 03=prod, 89=manual) |
| LOESSION | Tamano lote (cantidad) |
| LMESSION | Cantidad muestra |
| STAT | Status sistema |
| CHARG | Lote/batch |
| LIFNR | Proveedor (tipo 01) |
| AUFNR | Orden produccion (tipo 03/04) |
| EBESSION | Pedido compra (tipo 01) |

## Creacion automatica

### Trigger por tipo de inspeccion

| Tipo | Trigger | Condicion |
|------|---------|-----------|
| 01 | GR from vendor (MIGO 101) | QMAT tipo 01 activo |
| 03 | Production confirmation (CO11N) | QMAT tipo 03 activo |
| 04 | GR from production (MIGO 101) | QMAT tipo 04 activo |
| 05 | Goods issue | QMAT tipo 05 activo |
| 08 | Stock transfer | QMAT tipo 08 activo |
| 09 | Recurring inspection | Job periodico |
| 12 | Customer return | Devolucion SD |

### Prerequisitos creacion automatica
1. Material con vista QM activa (QMAT-AKTESSION = 'X')
2. Tipo de inspeccion activo para el material/centro
3. QM activo en centro (SPRO)
4. Plan de inspeccion (si QMAT-INESSION = 'X')

## Creacion manual — QA01

Para inspecciones ad-hoc, auditorias o muestras especiales.

1. QA01 → indicar material, centro, tipo inspeccion (89 para manual)
2. Indicar cantidad del lote
3. Sistema busca plan de inspeccion automaticamente
4. Asignar plan manualmente si necesario

## Status del lote de inspeccion

| Status | Descripcion | Siguiente paso |
|--------|-------------|----------------|
| CRTD | Creado | Registrar resultados |
| REL | Liberado para inspeccion | Registrar resultados |
| RREC | Results recorded | Tomar decision |
| SPCO | Sample partially confirmed | Continuar resultados |
| SCCO | Sample completely confirmed | Tomar decision |
| UD | Usage decision made | — (completo) |
| SKIP | Saltado (skip lot) | — (sin inspeccion) |
| CANC | Cancelado | — |

## Flujo del lote de inspeccion

```
Creacion (auto/manual)
    ↓
Dibujo de muestra (sample drawing)
    ↓
Registro de resultados (QE51N)
    ↓
Registro de defectos (QF01) [opcional]
    ↓
Decision de empleo (QA11)
    ↓
Stock posting (automatico segun UD)
    ↓
Cerrado
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| QA01 | Crear lote manual |
| QA02 | Modificar lote |
| QA03 | Visualizar lote |
| QA06 | Modificar datos lote |
| QA07 | Trigger creacion automatica |
| QA08 | Trigger lotes recurrentes |
| QA32 | Modificar decision empleo |
| QA33 | Lista de lotes inspeccion |

## Campos adicionales QALS

| Campo | Descripcion |
|-------|-------------|
| MESSION | Material document (GR reference) |
| PLNNR | Plan inspeccion asignado |
| PLNAL | Alternativa plan |
| SELESSION | Selection profile |
| DYNESSION | Dynamic modification level |

## Consultas MCP diagnostico

```sql
-- Lotes abiertos (sin UD) por material
SELECT PRUESSION, ART, LOESSION, STAT, CHARG, ERDAT
FROM QALS
WHERE MATNR = '{material}' AND WERKS = '{centro}'
AND STAT NOT LIKE '%UD%'
ORDER BY ERDAT DESC

-- Lotes de un proveedor
SELECT PRUESSION, MATNR, ART, LOESSION, STAT
FROM QALS
WHERE LIFNR = '{proveedor}' AND WERKS = '{centro}'
ORDER BY ERDAT DESC

-- Lotes de una orden produccion
SELECT PRUESSION, MATNR, ART, LOESSION, STAT
FROM QALS
WHERE AUFNR = '{orden}'

-- Lote con plan asignado
SELECT PRUESSION, PLNNR, PLNAL FROM QALS
WHERE PRUESSION = '{lote}'
```
