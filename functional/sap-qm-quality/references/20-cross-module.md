# Integracion Cross-Module QM

## QM ↔ MM (Materials Management)

### Goods Receipt Inspection (Tipo 01)
```
Pedido (ME21N) → Entrada mercancia (MIGO)
  → Stock QI automatico (INSME en MARD)
  → Lote inspeccion creado (QALS)
  → Resultados (QE51N) → UD (QA11)
  → Stock posting: QI → libre (321) o bloqueado (322)
```

### Procurement Key (QM en info record)
| Clave | Efecto |
|-------|--------|
| Sin clave | Sin inspeccion en GR |
| Con clave | Inspeccion automatica en GR |
| Con certificado | Requiere cert. entrante (QC51) |

### Tablas de integracion MM
| Tabla | Campo | Descripcion |
|-------|-------|-------------|
| EKPO | INSMK | Indicador stock inspeccion |
| MSEG/MATDOC | INSMK | Stock QI en movimiento |
| MARD | INSME | Stock en inspeccion |
| EINE | QMAT_LTXT | QM key en info record |
| QMAT | ART | Tipo inspeccion activo |

### Vendor Evaluation (ME61)
```
UD reject → quality score baja
  → vendor evaluation recalcula
  → si score < threshold → bloqueo automatico
Criterio calidad = nota QM (ponderacion configurable)
```

## QM ↔ PP (Production Planning)

### In-Process Inspection (Tipo 03)
```
Orden produccion (CO01) → Confirmacion (CO11N)
  → Lote inspeccion tipo 03 creado
  → Inspeccion durante produccion
  → Resultados → UD → continuar/parar produccion
```

### Final Inspection (Tipo 04)
```
GR de produccion (MIGO 101) → Stock QI
  → Lote inspeccion tipo 04
  → Resultados → UD
  → Stock libre (321) o scrap (551)
  → Scrap impacta costes orden produccion
```

### Routing con MICs
```
Routing PP (CA01) → Operaciones con MICs
  → Plan inspeccion referencia routing
  → Confirmacion PP trigger inspeccion
  → Resultados ligados a operacion routing
```

### Tablas de integracion PP
| Tabla | Relacion |
|-------|----------|
| AFKO | Orden produccion → lote inspeccion via PRUEFLOS |
| AFRU | Confirmacion → trigger tipo 03 |
| RESB | Componentes → scrap QM afecta reserva |
| PLKO/PLPO | Routing compartido PP-QM |

## QM ↔ SD (Sales & Distribution)

### Certificate of Analysis (CoA)
```
Pedido venta (VA01) → Entrega (VL01N)
  → Output determination → certificado calidad
  → QC31 o automatico con SmartForms
  → Datos de lote inspeccion del batch
```

### Returns Inspection (Tipo 12)
```
Devolucion cliente (VL01N tipo devolucion)
  → GR devolucion → lote tipo 12
  → Inspeccion → UD
  → Re-stock (321) o scrap (551)
```

### Customer Complaint (Q2)
```
Reclamacion cliente → QM01 tipo Q2
  → Referencia pedido/entrega/factura
  → 8D process → acciones correctivas
  → Nota credito SD si aplica (VF01)
```

### ATP y Stock QI
```
Stock en inspeccion (INSME) NO esta disponible para ATP
  → Pedidos venta NO pueden reservar stock QI
  → Solo despues de UD accept → libre → ATP disponible
```

## QM ↔ PM (Plant Maintenance)

### Calibracion
```
Equipo medicion (IE01) → Plan mantenimiento (IP01)
  → Orden PM para calibracion
  → Resultados calibracion en QM
  → Certificado calibracion
  → Punto medida actualizado
```

### Test Equipment Management
| Proceso | QM | PM |
|---------|----|----|
| Equipo registrado | Punto medida | Equipo tecnico |
| Calibracion planificada | — | Plan mantenimiento |
| Ejecucion calibracion | Lote inspeccion | Orden PM |
| Resultado | MIC resultado | Punto medida |
| Certificado | QC31 | — |

## QM ↔ FI/CO (Finance/Controlling)

### Costes de No-Calidad
```
Aviso calidad (Q1/Q2/Q3)
  → Orden CO asociada (KO01)
  → Costes: retrabajo, scrap, devolucion, garantia
  → Liquidacion → centro coste o orden
  → Reporting: costes calidad por periodo
```

### Scrap Contabilizacion
```
UD reject → scrap (551)
  → Contabilizacion material (MATDOC)
  → Valoracion a precio estandar/medio
  → Cargo a centro coste o orden produccion
  → Impacto en material ledger (si activo)
```

### Quality Cost Reports
| Tipo coste | Origen | Destino CO |
|------------|--------|------------|
| Scrap | UD reject → 551 | CC produccion |
| Retrabajo | Orden retrabajo | CC calidad |
| Inspeccion | Horas inspeccion | CC calidad |
| Garantia | Aviso Q2 | CC ventas |
| Devolucion proveedor | Aviso Q3 → return | Proveedor (nota debito) |

## QM ↔ WM/EWM (Warehouse Management)

### Stock QI en WM
```
GR con inspeccion → Transfer order a storage type QI
  → Inspeccion en area calidad
  → UD accept → TO a storage type libre
  → UD reject → TO a storage type bloqueado/scrap
```

### Flujo WM-QM
| Paso | WM | QM |
|------|----|----|
| GR | TO a QI area | Lote creado |
| Inspeccion | Material en QI bin | Resultados |
| UD accept | TO a libre | Stock posting 321 |
| UD reject | TO a blocked | Stock posting 322 |

## QM ↔ Batch Management

### Batch + Inspeccion
```
Material con batch → GR con batch
  → Lote inspeccion por batch
  → Resultados → clasificacion batch
  → Batch class actualizada con valores QM
  → Batch determination en SD usa clasificacion
```

### Shelf Life + Recurring Inspection (Tipo 09)
```
Batch con fecha produccion/vencimiento
  → Inspeccion recurrente planificada
  → Antes de vencimiento → re-test
  → Resultado OK → extender shelf life
  → Resultado FAIL → bloquear batch
```

## Consultas SQL Cross-Module

```sql
-- Lotes inspeccion con referencia a pedido compra
SELECT q.PRUEFLOS, q.MATNR, q.WERK, q.ART, q.STAT,
       e.EBELN, e.EBELP
FROM QALS q
JOIN MATDOC m ON q.PRUEFLOS = m.PRUEFLOS
JOIN EKPO e ON m.EBELN = e.EBELN AND m.EBELP = e.EBELP
WHERE q.WERK = '{centro}' AND q.ART = '01'

-- Avisos calidad con referencia SD
SELECT q.QMNUM, q.QMART, q.MATNR, q.RKMNG,
       q.VBELN_I AS pedido, q.VBELN AS entrega
FROM QMEL q
WHERE q.QMART = 'Q2' AND q.ERDAT >= '{fecha}'

-- Stock en inspeccion por material
SELECT MATNR, WERKS, LGORT, INSME
FROM MARD
WHERE INSME > 0 AND WERKS = '{centro}'

-- Costes calidad via ordenes CO
SELECT a.AUFNR, a.KTEXT, c.WKGBTR, c.KSTAR
FROM AUFK a
JOIN COEP c ON a.AUFNR = c.AUFNR
WHERE a.AUART = 'QM01' AND c.GJAHR = '{anno}'
```
