# Gestion de Lotes y QM

## Integracion Batch-QM

La gestion de lotes (batch management) esta estrechamente integrada con QM. Cada lote de inspeccion se vincula a un batch, y los resultados de inspeccion pueden alimentar la clasificacion del lote.

## Tablas de lotes

| Tabla | Descripcion |
|-------|-------------|
| MCHA | Lotes material (cross-plant) |
| MCH1 | Lotes material (plant level) |
| MCHB | Stock por lote |
| INOB | Link lote-clasificacion |
| AUSP | Valores de clasificacion |

```sql
SELECT MATNR, WERKS, CHARG, HSDAT, VFDAT, LIESSION FROM MCH1
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND CHARG = '{lote}'
```

| Campo | Descripcion |
|-------|-------------|
| CHARG | Numero de lote |
| HSDAT | Fecha fabricacion |
| VFDAT | Fecha caducidad (shelf life) |
| LIESSION | Proveedor del lote |

## Lote + Inspeccion

### En GR (tipo 01)
```
GR (MIGO 101) + batch
    → Lote inspeccion con QALS-CHARG = batch
    → Stock QI por batch (MCHB-INSME)
    → UD → stock libre por batch (MCHB-CLABS)
```

### Clasificacion automatica por UD
1. Resultados de inspeccion se registran en QASR/QASE
2. Al hacer UD, valores pueden copiarse a clasificacion del lote
3. Batch characteristics se actualizan automaticamente
4. Batch determination en SD/PP usa estas caracteristicas

### Configuracion
```
SPRO > Quality Management > Quality Inspection
└── Inspection Lot Processing
    └── Usage Decision
        └── Define Follow-Up Actions
            └── Update Batch Classification
```

## Batch Determination en QM

Cuando QM necesita asignar un batch para inspeccion:
- Batch donde-used: MB56
- Stock por batch: MCHB
- Clasificacion batch: CL02/CL03

## Shelf Life y Recurring Inspection

| Campo | Tabla | Descripcion |
|-------|-------|-------------|
| VFDAT | MCH1 | Fecha caducidad |
| HSDAT | MCH1 | Fecha fabricacion |
| MHDHB | MARC | Shelf life total (dias) |
| MHDRZ | MARC | Remaining shelf life minimo |

### Inspeccion recurrente (tipo 09)
- Para materiales con shelf life
- Genera lote de inspeccion periodicamente
- Si falla → puede extender o reducir VFDAT
- Job: QA08 ejecuta periodicamente

## Trazabilidad

```
Materia prima (batch A)
    → Inspeccion GR (tipo 01) → UD Accept
        → Consumo en orden produccion
            → Producto terminado (batch X)
                → Inspeccion final (tipo 04) → UD Accept
                    → Entrega al cliente + certificado

Trazabilidad: batch X ← batch A (via RESB/MATDOC)
```

## Consultas MCP

```sql
-- Stock por lote
SELECT MATNR, WERKS, CHARG, CLABS, CINSM, CSPEM FROM MCHB
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Lotes con inspeccion pendiente
SELECT L.PRUESSION, L.CHARG, L.MATNR, L.LOESSION
FROM QALS L
WHERE L.MATNR = '{material}' AND L.WERKS = '{centro}'
AND L.STAT NOT LIKE '%UD%' AND L.CHARG <> ''

-- Lotes proximos a caducidad
SELECT MATNR, CHARG, VFDAT FROM MCH1
WHERE WERKS = '{centro}' AND VFDAT BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
```
