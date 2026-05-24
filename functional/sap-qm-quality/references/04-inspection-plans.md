# Planes de Inspeccion

## Concepto

Un plan de inspeccion define QUE inspeccionar, COMO y CUANTO. Contiene operaciones con MICs asignadas, procedimientos de muestreo y limites de aceptacion.

## Tablas

| Tabla | Descripcion |
|-------|-------------|
| PLKO | Cabecera plan (PLNTY='Q') |
| PLPO | Operaciones plan |
| PLMK | Asignacion MIC a operacion |
| PLAS | Asignacion material-plan |

## PLKO — Cabecera plan inspeccion

```sql
SELECT PLNTY, PLNNR, PLNAL, WERKS, KTEXT, STATU, VERWE,
       MATNR, LOESSION, ANESSION
FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = 'Q'
```

| Campo | Descripcion |
|-------|-------------|
| PLNTY | Tipo = 'Q' (inspection plan) |
| PLNNR | Numero grupo plan |
| PLNAL | Alternativa |
| STATU | Status (1=created, 2=released, 4=deleted) |
| VERWE | Uso (5=inspection plan) |
| LOESSION | Tamano lote desde |
| ANESSION | Tamano lote hasta |

## PLPO — Operaciones

```sql
SELECT PLNTY, PLNNR, PLNAL, VESSION, LTXA1, ARBID, STEUS
FROM PLPO
WHERE PLNNR = '{plan}' AND PLNTY = 'Q'
ORDER BY VESSION
```

Cada operacion puede tener multiples MICs asignadas.

## PLMK — Asignacion MIC

```sql
SELECT PLNTY, PLNNR, PLNAL, VESSION, MKMNR, VERWESSION,
       SOLLWERT, TOLERANZOB, TOLERANZUN
FROM PLMK
WHERE PLNNR = '{plan}' AND PLNTY = 'Q'
```

| Campo | Descripcion |
|-------|-------------|
| MKMNR | MIC number |
| VERWESSION | Version MIC |
| SOLLWERT | Target value (puede override MIC) |
| TOLERANZOB | Tolerancia superior (puede override) |
| TOLERANZUN | Tolerancia inferior (puede override) |

## Tipos de task list QM

| Tipo PLNTY | Descripcion |
|------------|-------------|
| Q | Inspection plan |
| N | Routing (PP) — tambien puede tener MICs |
| 2 | Master recipe (PP-PI) |

## Estructura plan de inspeccion

```
Plan inspeccion (QP01)
├── Header: material, centro, uso, validez, tamano lote
├── Operacion 0010: "Inspeccion visual"
│   ├── MIC 001: Aspecto (cualitativa, catalogo VISUAL)
│   ├── MIC 002: Color (cualitativa, catalogo COLOR)
│   └── Sampling: 100% inspeccion
├── Operacion 0020: "Inspeccion dimensional"
│   ├── MIC 003: Largo (cuantitativa, 100±0.5 mm)
│   ├── MIC 004: Ancho (cuantitativa, 50±0.3 mm)
│   └── Sampling: AQL Level II, 5 muestras
└── Operacion 0030: "Prueba funcional"
    ├── MIC 005: Resistencia (cuantitativa, >500 N)
    └── Sampling: 3 muestras destructivas
```

## Asignacion plan a material

### Automatica (preferred)
- Plan con material en cabecera (PLKO-MATNR)
- Al crear lote inspeccion, sistema busca plan por material/centro/tipo

### Manual
- Task list assignment en vista QM del material (QMAT)
- O seleccion manual al crear lote (QA01)

## Procedimientos de muestreo — QDV1

Define cuantas muestras tomar y cuantos defectos se aceptan.

| TCode | Descripcion |
|-------|-------------|
| QDV1 | Crear sampling procedure |
| QDV2 | Modificar |
| QDV3 | Visualizar |

### Tipos de muestreo

| Tipo | Descripcion |
|------|-------------|
| Fixed sample | Cantidad fija siempre |
| Percentage | % del lote |
| 100% inspection | Todo el lote |
| Sampling scheme | Segun tabla AQL (ANSI Z1.4 / ISO 2859) |

### Sampling scheme
- Define nivel de inspeccion (I, II, III)
- AQL (Acceptable Quality Level): 0.1%, 0.65%, 1.0%, 2.5%, 4.0%
- Tablas predefinidas: SAP incluye esquemas ISO 2859

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| QP01 | Crear plan inspeccion |
| QP02 | Modificar plan |
| QP03 | Visualizar plan |
| QP05 | Listar planes |
| QP49 | Where-used MIC en planes |
| QDV1 | Crear sampling procedure |

## Consultas MCP diagnostico

```sql
-- Plan no encontrado (error QE 013)
SELECT PLNTY, PLNNR, PLNAL, STATU, KTEXT FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = 'Q'

-- Operaciones del plan
SELECT VESSION, LTXA1, STEUS FROM PLPO
WHERE PLNNR = '{plan}' AND PLNTY = 'Q' ORDER BY VESSION

-- MICs del plan (error QE 025 si vacio)
SELECT VESSION, MKMNR FROM PLMK
WHERE PLNNR = '{plan}' AND PLNTY = 'Q'
```
