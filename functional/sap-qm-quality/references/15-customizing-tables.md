# Tablas de Customizing QM

## Datos maestros QM

| Tabla | Descripcion |
|-------|-------------|
| QMAT | Material-QM view (tipos inspeccion) |
| QPMK | Master inspection characteristics |
| QPMM | Inspection methods |
| QPCD | Catalog codes |
| QPCM | Catalog code texts |
| QPGT | Code groups |
| QPCT | Code group texts |

## Planes de inspeccion

| Tabla | Descripcion |
|-------|-------------|
| PLKO | Cabecera plan (type Q) |
| PLPO | Operaciones plan |
| PLMK | MIC assignment |
| PLAS | Material-plan assignment |

## Lotes de inspeccion

| Tabla | Descripcion |
|-------|-------------|
| QALS | Lote inspeccion cabecera |
| QASR | Resultados resumen |
| QASE | Resultados individuales |
| QAMR | Master record resultados |
| QAMV | Valores individuales |
| QAVE | Decision de empleo |

## Avisos de calidad

| Tabla | Descripcion |
|-------|-------------|
| QMEL | Cabecera aviso |
| QMFE | Items defecto |
| QMUR | Causas |
| QMSM | Actividades/tareas |
| QMMA | Activities del item |
| QMIH | Object reference |

## Certificados

| Tabla | Descripcion |
|-------|-------------|
| QCPR | Certificate profile |
| QCVD | Certificate data |

## Customizing — Inspection types

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TQ70 | Inspection type control | QM > Inspection > Inspection Lot Origin |
| TQ73 | Inspection lot origin | QM > Inspection > Define Origin |
| TQ74 | Automatic lot creation control | QM > Inspection > Auto Lot |

## Customizing — Usage Decision

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TQ76 | UD catalog assignment | QM > Inspection > UD > Catalogs |
| TQ75 | Follow-up actions | QM > Inspection > UD > Follow-Up |
| TQSS | Stock posting for UD | QM > Inspection > UD > Stock Posting |

## Customizing — Notifications

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TQ80 | Notification types | QM > Notifications > Define Types |
| TQ81 | Notification type control | QM > Notifications > Control |
| TQ82 | Priority types | QM > Notifications > Priority |
| TQ84 | Notification partners | QM > Notifications > Partners |

## Customizing — Dynamic modification

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| T160D | Dynamic modification rules | QM > Inspection > Dynamic Modification |
| QDEB | Dynamic mod data | — |

## Customizing — Sampling

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| QDPK | Sampling procedures | QM > Inspection > Sampling |
| QDPP | Sampling procedure params | QM > Inspection > Sampling |
| QDPA | Sampling scheme | QM > Inspection > Sampling Scheme |

## Customizing — Catalogs

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TQ02 | Catalog types | QM > Basic Settings > Catalogs |
| TQ04 | Catalog categories | QM > Basic Settings > Catalogs |

## Customizing — General

| Tabla | Descripcion | SPRO Path |
|-------|-------------|-----------|
| TQ01 | QM control parameters | QM > Basic Settings |
| TQ06 | Number ranges | QM > Basic Settings > Number Ranges |
| TQ09 | Authorization groups | QM > Basic Settings > Authorization |

## Status management

| Tabla | Descripcion |
|-------|-------------|
| JEST | Status individual |
| JSTO | Status object header |
| TJ02 | System status definitions |
| TJ30 | User status profiles |
