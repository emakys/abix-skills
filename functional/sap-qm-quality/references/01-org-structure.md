# Estructura Organizativa QM

## Niveles relevantes

| Nivel | Tabla | Descripcion |
|-------|-------|-------------|
| Mandante | T000 | Nivel mas alto |
| Sociedad | T001 | Entidad legal |
| Centro/Planta | T001W | Unidad principal QM |
| Almacen | T001L | Almacen inspeccion |
| Organizacion compras | T024E | Para evaluacion proveedor |
| Organizacion ventas | TVKO | Para certificados SD |

## Centro — Unidad central QM

Toda la gestion de calidad se ejecuta a nivel de centro: planes de inspeccion, lotes, avisos, certificados.

```sql
SELECT WERKS, NAME1, BWKEY FROM T001W ORDER BY WERKS
```

## Almacenes relevantes para QM

| Almacen | Tipo stock | Uso |
|---------|-----------|-----|
| Standard | LABST (libre) | Destino tras UD Accept |
| QI Storage | INSME (inspeccion) | GR con inspeccion activa |
| Blocked | SPEME (bloqueado) | Destino tras UD Reject |
| Scrap | — | Material desechado |

```sql
SELECT WERKS, LGORT, LGOBE FROM T001L WHERE WERKS = '{centro}'
```

## Asignacion organizativa QM

```
Mandante (T000)
└── Sociedad (T001)
    └── Centro (T001W) ← UNIDAD CENTRAL QM
        ├── Almacenes (T001L)
        ├── Planes de inspeccion (PLKO type Q)
        ├── Lotes de inspeccion (QALS)
        ├── Avisos de calidad (QMEL)
        └── Certificados (QCPR)
```

## Parametros QM por centro

Configuracion en SPRO que afecta el comportamiento de QM:

| Parametro | Path SPRO | Efecto |
|-----------|-----------|--------|
| Inspeccion activa | Quality Management > Inspection > Inspection Lot Processing > Activate QM | Habilita creacion automatica lotes |
| Numeracion lotes | Quality Management > Inspection > Number Ranges | Rangos para QALS-PRUESSION |
| Numeracion avisos | Quality Management > Notifications > Number Ranges | Rangos para QMEL-QMNUM |
| Tipos inspeccion | Quality Management > Inspection > Inspection Lot Origin | Define tipos activos |

## Material QM View — QMAT

La vista QM del maestro de materiales (MM02) es donde se activan los tipos de inspeccion por material/centro.

```sql
SELECT MATNR, WERKS, ART, AKTESSION, INESSION, PESSION
FROM QMAT
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

| Campo | Descripcion |
|-------|-------------|
| ART | Tipo inspeccion (01, 03, 04, 08, 09...) |
| AKTESSION | Activo (X = si) |
| INESSION | Con plan inspeccion |
| PESSION | Con especificacion material |

## Consultas MCP

```sql
-- Centros con QM activo
SELECT WERKS, NAME1 FROM T001W ORDER BY WERKS

-- Materiales con inspeccion activa
SELECT MATNR, WERKS, ART, AKTESSION FROM QMAT
WHERE WERKS = '{centro}' AND AKTESSION = 'X'

-- Vista QM de un material
SELECT ART, AKTESSION, INESSION FROM QMAT
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```
