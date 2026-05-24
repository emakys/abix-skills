# Dynamic Modification y SPC

## Dynamic Modification Rule

Permite ajustar automaticamente el nivel de inspeccion basado en el historial de calidad. Si un proveedor/material tiene buen historico, se reduce la inspeccion (skip lot). Si tiene mal historico, se intensifica.

### Niveles de inspeccion

```
Tightened (intensificada)
    ↓ N lotes buenos consecutivos
Normal
    ↓ N lotes buenos consecutivos
Reduced (reducida)
    ↓ N lotes buenos consecutivos
Skip lot (sin inspeccion)
    ↑ 1 lote malo → vuelve a Normal/Tightened
```

### Configuracion

| Tabla | Descripcion |
|-------|-------------|
| T160D | Dynamic modification criteria |
| QDEB | Dynamic mod. rule data |

```
SPRO > Quality Management > Quality Inspection
├── Inspection Lot Processing
│   └── Dynamic Modification
│       ├── Define Dynamic Modification Rules
│       ├── Define Inspection Stages
│       └── Assign to Inspection Type
```

### Stages (etapas)

| Stage | Descripcion | Muestreo tipico |
|-------|-------------|-----------------|
| 1 | Tightened | 100% o muestra grande |
| 2 | Normal | Muestra estandar AQL |
| 3 | Reduced | Muestra pequena |
| 4 | Skip | Sin inspeccion |

### Criterios de transicion

| Transicion | Criterio tipico |
|------------|-----------------|
| Tightened → Normal | 5 lotes aceptados consecutivos |
| Normal → Reduced | 10 lotes aceptados consecutivos + quality score > 80 |
| Reduced → Skip | 15 lotes aceptados + quality score > 90 |
| Skip → Normal | 1 lote rechazado |
| Any → Tightened | 2 lotes rechazados en ultimos 5 |

## Quality Score

Valor numerico que alimenta la dynamic modification:

```sql
-- Quality score por material/proveedor
SELECT L.MATNR, L.LIFNR, V.VBESSION AS SCORE, V.VDATUM
FROM QALS L INNER JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.WERKS = '{centro}' AND L.ART = '01'
ORDER BY V.VDATUM DESC
```

## Quality Level

Similar al quality score pero a nivel de material/centro. Refleja el nivel de calidad historico.

```sql
SELECT MATNR, WERKS, ART, DYNESSION FROM QMAT
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

## SPC — Statistical Process Control

### Cartas de control

| Tipo | Uso | Variables |
|------|-----|-----------|
| X-bar/R | Media y rango | Cuantitativa |
| X-bar/S | Media y desv. estandar | Cuantitativa |
| p-chart | Proporcion defectos | Atributo |
| np-chart | Numero defectos | Atributo |
| c-chart | Conteo defectos | Atributo |
| u-chart | Tasa defectos | Atributo |

### Configuracion SPC

1. MIC con indicador SPC activo (QPMK)
2. Control chart type asignado
3. Limites de control calculados
4. Resultados alimentan cartas automaticamente

### Reglas de deteccion (Western Electric / Nelson)

| Regla | Descripcion |
|-------|-------------|
| 1 | Un punto fuera de limites de control |
| 2 | 2 de 3 puntos fuera de 2 sigma |
| 3 | 4 de 5 puntos fuera de 1 sigma |
| 4 | 8 puntos consecutivos al mismo lado |
| 5 | 6 puntos consecutivos crecientes/decrecientes |

### Transacciones SPC

| TCode | Descripcion |
|-------|-------------|
| QGC1 | Control chart display |
| QGC2 | Control chart evaluation |
| QGR1 | Quality analysis (Pareto, etc.) |
| QGR2 | Quality analysis colectiva |
| QGP1 | Calculate control limits |

## Consultas MCP

```sql
-- Nivel de inspeccion actual por material
SELECT MATNR, WERKS, ART, DYNESSION FROM QMAT
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Historial de lotes para dynamic mod
SELECT PRUESSION, MATNR, ERDAT, LOESSION
FROM QALS L
INNER JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.MATNR = '{material}' AND L.WERKS = '{centro}' AND L.ART = '01'
ORDER BY L.ERDAT DESC
```
