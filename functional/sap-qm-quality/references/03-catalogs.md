# Catalogos QM

## Concepto

Los catalogos definen los codigos estandarizados usados en QM para clasificar defectos, causas, actividades y resultados cualitativos. Son la base para el analisis estadistico de calidad.

## Tipos de catalogo

| Tipo | Descripcion | Uso principal | TCode |
|------|-------------|---------------|-------|
| 1 | Defect types (tipos defecto) | Items en avisos calidad | QS41 |
| 2 | Defect locations (ubicacion defecto) | Donde ocurre el defecto | QS41 |
| 3 | Defect causes (causas) | Por que ocurre | QS41 |
| 5 | Activities/tasks (actividades) | Acciones correctivas | QS41 |
| 9 | Usage decision codes | Codigos para UD | QS41 |
| C | Characteristic attributes | Resultados cualitativos MIC | QS41 |

## Estructura del catalogo

```
Catalogo (tipo)
└── Code group (grupo de codigos)
    ├── Code 1 (codigo individual)
    ├── Code 2
    └── Code 3
```

## Tablas de catalogos

| Tabla | Descripcion |
|-------|-------------|
| QPCD | Codigos de catalogo |
| QPCM | Textos de codigos |
| QPGT | Grupos de codigos |
| QPCT | Textos grupos |

```sql
-- Codigos de un catalogo
SELECT KATESSION, CODGRUPPE, CODE, KUESSION
FROM QPCD
WHERE KATESSION = '{tipo_catalogo}' AND CODGRUPPE = '{grupo}'

-- Grupos de un tipo de catalogo
SELECT KATESSION, CODGRUPPE, KUESSION
FROM QPGT
WHERE KATESSION = '{tipo_catalogo}'
```

## Transacciones catalogos

| TCode | Descripcion |
|-------|-------------|
| QS41 | Mantener catalogos |
| QS42 | Editar catalogos (modo tabla) |
| QS43 | Visualizar catalogos |
| QS51 | Mantener selected sets |
| QS52 | Editar selected sets |
| QS53 | Visualizar selected sets |
| QS61 | Mantener selection procedures |

## Selected Sets

Un selected set es un subconjunto de codigos de un catalogo, agrupados para un uso especifico.

```
Catalogo tipo 1 (Defectos) — 200 codigos totales
├── Selected set "VISUAL" — 15 codigos para inspeccion visual
├── Selected set "DIMENS" — 10 codigos para dimensional
└── Selected set "FUNCIO" — 8 codigos para funcional
```

- Se asignan a operaciones del plan de inspeccion
- Limitan los codigos disponibles al registrar resultados/defectos
- Pueden asignarse a MICs cualitativas

## Catalogos para avisos de calidad

### Catalogo tipo 1 — Defectos
```
Grupo: VISUAL
├── V01 — Rayon/scratch
├── V02 — Mancha/stain
├── V03 — Deformacion
└── V04 — Color incorrecto

Grupo: DIMENSIONAL
├── D01 — Fuera de tolerancia superior
├── D02 — Fuera de tolerancia inferior
└── D03 — Forma incorrecta
```

### Catalogo tipo 3 — Causas
```
Grupo: PROCESO
├── P01 — Error de maquina
├── P02 — Error de operador
├── P03 — Materia prima defectuosa
└── P04 — Parametro proceso fuera de rango

Grupo: DISENO
├── D01 — Especificacion incorrecta
└── D02 — Material inadecuado
```

### Catalogo tipo 5 — Actividades
```
Grupo: CORRECT
├── C01 — Reproceso
├── C02 — Reparacion
├── C03 — Cambio de proveedor
└── C04 — Ajuste de maquina

Grupo: PREVENT
├── P01 — Capacitacion
├── P02 — Modificacion proceso
└── P03 — Cambio especificacion
```

## Catalogo tipo 9 — Usage Decision codes

```
Grupo: STANDARD
├── A — Accepted (aceptado)
├── R — Rejected (rechazado)
└── C — Conditionally accepted (aceptado con restriccion)
```

Cada codigo UD se configura con:
- Follow-up action (stock posting, aviso automatico)
- Quality score impact
- Dynamic modification impact

## Consultas MCP diagnostico

```sql
-- Todos los grupos de un tipo de catalogo
SELECT CODGRUPPE, KUESSION FROM QPGT WHERE KATESSION = '{tipo}'

-- Codigos de un grupo
SELECT CODE, KUESSION FROM QPCD
WHERE KATESSION = '{tipo}' AND CODGRUPPE = '{grupo}'
ORDER BY CODE

-- Selected sets
SELECT KATESSION, AUESSION, KUESSION FROM QPGT
WHERE KATESSION = 'C' AND AUESSION <> ''
```
