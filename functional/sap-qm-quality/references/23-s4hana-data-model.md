# Modelo de Datos QM en S/4HANA 2023

## Tablas Principales (sin cambios S/4)

QM mantiene sus tablas core en S/4HANA — no hubo simplificacion como en FI (ACDOCA) o MM (MATDOC).

### Lotes de Inspeccion
| Tabla | Descripcion | Campos clave |
|-------|-------------|--------------|
| QALS | Cabecera lote | PRUEFLOS, MATNR, WERK, ART, CHARG, STAT |
| QASR | Resultados resumen | PRUEFLOS, VESSION, VORGLFNR, MERESSION |
| QASE | Resultados individuales | PRUEFLOS, VESSION, VORGLFNR, MERESSION, PROESSION |
| QAMR | Master record resultados | PRUEFLOS, VORGLFNR, MERESSION |
| QAMV | Valores individuales | PRUEFLOS, VORGLFNR, MERKNR, PROESSION |
| QAVE | Decision de empleo | PRUEFLOS, VDATUM, VCODE |
| QAPP | Physical samples | PRUEFLOS, PROESSION |

### Avisos de Calidad
| Tabla | Descripcion | Campos clave |
|-------|-------------|--------------|
| QMEL | Cabecera aviso | QMNUM, QMART, MATNR, WERK, LIFNR, KESSION |
| QMFE | Items defecto | QMNUM, FEESSION, FEGRP, FECOD |
| QMUR | Causas | QMNUM, FEESSION, URESSION, URGRP, URCOD |
| QMSM | Tareas/actividades | QMNUM, MESSION, MNGRP, MNCOD |
| QMMA | Actividades del item | QMNUM, FEESSION, MAESSION |
| QMIH | Object reference | QMNUM (ref a equipo, ubicacion) |

### Datos Maestros QM
| Tabla | Descripcion | Campos clave |
|-------|-------------|--------------|
| QMAT | Material QM view | MATNR, WERKS, ART, AKTESSION |
| QPMK | Master inspection char | MERESSION (MIC interna) |
| QPMM | Inspection methods | PRUEFMETHODE |
| QPCD | Catalog codes | KATESSION, CODEGRUPPE, CODE |
| QPGT | Code groups | KATESSION, CODEGRUPPE |

### Planes de Inspeccion
| Tabla | Descripcion | Campos clave |
|-------|-------------|--------------|
| PLKO | Cabecera plan (type Q) | PLNTY='Q', PLNNR, PLNAL |
| PLPO | Operaciones | PLNTY, PLNNR, PLNKN |
| PLMK | MIC assignment | PLNTY, PLNNR, PLNKN, MERESSION |
| PLAS | Material assignment | PLNTY, PLNNR, MATNR |

## CDS Views QM (S/4HANA)

### Basic Interface Views
| CDS View | Tabla base | Descripcion |
|----------|-----------|-------------|
| I_InspectionLot | QALS | Lote inspeccion |
| I_InspectionLotWithStatus | QALS+JEST | Lote con status |
| I_InspectionResult | QASR | Resultados |
| I_InspectionResultDetail | QASE | Resultados individuales |
| I_QualityNotification | QMEL | Aviso calidad |
| I_QualityNotificationItem | QMFE | Items defecto |
| I_QualityNotificationCause | QMUR | Causas |
| I_QualityNotificationTask | QMSM | Tareas |
| I_InspectionCharacteristic | QPMK | MIC |

### Composite Views
| CDS View | Descripcion |
|----------|-------------|
| I_InspectionLotWthMatlAndPlnt | Lote + material + centro |
| I_QltyNotifnWthMatlAndPlnt | Aviso + material + centro |
| I_InspLotResultAndCharc | Resultado + MIC |

### Consumption Views (C_)
| CDS View | Descripcion | App Fiori |
|----------|-------------|-----------|
| C_InspectionLotQ | Query lotes | Inspection Lot Processing |
| C_QualityNotificationQ | Query avisos | Quality Notification Processing |
| C_InspLotResultRecordQ | Query resultados | Results Recording |

## Impacto S/4HANA en QM

### MATDOC (reemplaza MKPF+MSEG)
```
Movimientos de stock QI ahora en MATDOC:
- 321: QI → libre (MATDOC.BWART = '321')
- 322: QI → bloqueado (MATDOC.BWART = '322')
- 551: Scrap (MATDOC.BWART = '551')
- MATDOC.PRUEFLOS = referencia al lote inspeccion
```

### ACDOCA (Universal Journal)
```
Contabilizaciones QM en ACDOCA:
- Scrap → valoracion material → ACDOCA
- Orden QM (costes calidad) → ACDOCA
- Ya no es necesario reconciliar CO-FI
```

### Business Partner (BP)
```
Proveedores en QM ahora via BP:
- QMEL.LIFNR → mapeo a BP via BUT000
- Vendor evaluation → BP scoring
- QM info record → BP-based
```

## Campos Status en QALS

### System Status (JEST)
| Status | Texto | Significado |
|--------|-------|-------------|
| I0001 | CRTD | Creado |
| I0002 | REL | Liberado |
| I0009 | SPCO | Sample planned, confirmed |
| I0010 | RREC | Results recorded |
| I0012 | RCON | Results confirmed |
| I0016 | UD | Usage decision made |
| I0068 | CALC | Calculated |
| I0070 | SKIP | Skipped |

### Status Flow Tipico
```
CRTD → REL → SPCO → RREC → RCON → UD → CLOSE
         │                              │
         └── SKIP (dynamic mod) ────────┘
```

## Relaciones entre Tablas

```
QALS (lote)
├── QAVE (UD) — 1:1
├── QASR (resultados resumen) — 1:N (por operacion/MIC)
│   └── QASE (resultados individuales) — 1:N
├── QAMV (valores individuales) — 1:N
├── QAPP (physical samples) — 1:N
└── MATDOC (movimientos stock) — 1:N

QMEL (aviso)
├── QMFE (items defecto) — 1:N
│   ├── QMUR (causas) — 1:N
│   └── QMMA (actividades item) — 1:N
├── QMSM (tareas) — 1:N
└── QMIH (object reference) — 1:1

PLKO (plan, type Q)
├── PLPO (operaciones) — 1:N
│   └── PLMK (MICs) — 1:N
└── PLAS (material assignment) — 1:N

QMAT (material QM view)
└── QALS (lotes) — via MATNR+WERKS+ART
```
