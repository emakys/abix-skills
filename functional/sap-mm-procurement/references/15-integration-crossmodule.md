# Integracion Cross-Module MM

## MM → FI (Finanzas)

### Asientos contables por operacion

#### Entrada mercancias GR vs PO (101) — Precio estandar (S)
```
D: 300000 BSX (Stock material)                 $1,000
C: 191000 WRX (GR/IR clearing)                 $1,000
D/C: 310000 PRD (Diferencia precio)            Dif. si precio PO != precio std
```

#### Entrada mercancias GR vs PO (101) — Precio promedio movil (V)
```
D: 300000 BSX (Stock material)                 $1,000
C: 191000 WRX (GR/IR clearing)                 $1,000
(sin diferencia de precio — precio material se actualiza)
```

#### Factura logistica MIRO (sin diferencia)
```
D: 191000 WRX (GR/IR clearing)                $1,000
C: 160000 AP Vendor (cuenta proveedor)         $1,000
```

#### Factura con diferencia de precio (precio std S)
```
D: 191000 WRX (GR/IR clearing)                $1,000
D: 310000 PRD (Diferencia precio)              $50
C: 160000 AP Vendor                            $1,050
```

#### Consumo a centro coste (201)
```
D: 400000 GBB-VBR (Consumo material)          $500
C: 300000 BSX (Stock material)                 $500
```

#### Consumo a orden produccion (261)
```
D: 810000 GBB-AUF (Consumo a orden)           $500
C: 300000 BSX (Stock material)                 $500
```

#### Devolucion a proveedor (122)
```
D: 191000 WRX (GR/IR clearing)                $1,000
C: 300000 BSX (Stock material)                 $1,000
```

### Tablas clave FI
| Tabla | Relacion con MM |
|-------|----------------|
| BKPF | Cabecera doc contable (generado por GR/IR) |
| BSEG | Posiciones doc contable |
| ACDOCA | Universal Journal (S/4HANA) |
| BSIK | Partidas abiertas proveedor |
| BSAK | Partidas compensadas proveedor |

### Config cuentas automaticas (OBYC)
```sql
-- Verificar cuentas configuradas
SELECT KTOPL, KTOSL, BKLAS, KONTS, BWMOD FROM T030
WHERE KTOPL = '{plan_cuentas}'
AND KTOSL IN ('BSX','WRX','PRD','GBB','KON','FRL','UPF','AUM','UMB')
ORDER BY KTOSL, BKLAS

-- Clase valoracion del material
SELECT MATNR, BKLAS, VPRSV, VERPR, STPRS FROM MBEW
WHERE MATNR = '{material}' AND BWKEY = '{centro}'
```

## MM → CO (Controlling)

### Imputaciones desde MM
| Operacion | Objeto CO | Config |
|-----------|----------|--------|
| Consumo a centro coste (201) | Centro coste (KOSTL) | KNTTP=K en PO |
| Consumo a orden interna | Orden CO (AUFNR) | KNTTP=F en PO |
| Consumo a proyecto WBS | Elemento PEP (PS_PSP_PNR) | KNTTP=P en PO |
| GR a orden produccion | Orden produccion | Automatico |
| Diferencia de precio | Centro coste de material | PRD → CO |

### Queries MCP
```sql
-- Ordenes internas activas para imputacion
SELECT AUFNR, KTEXT, BUKRS, AUART FROM AUFK
WHERE BUKRS = '{sociedad}' AND LOESSION = '' AND AUTYP = '01'

-- Centros de coste para imputacion
SELECT KOSTL, KTEXT, KOSAR FROM CSKT
WHERE KOKRS = '{controlling_area}' AND SPRAS = 'E' AND DATBI >= '{hoy}'

-- Elementos PEP activos
SELECT POSID, POST1, PKOKR FROM PRPS
WHERE PBUKR = '{sociedad}' AND LOEVM = ''
```

## MM → SD (Ventas)

### Stock Transfer Order (STO) — Traslado entre centros

#### STO simple (sin entrega SD)
```
ME21N: Tipo doc UB, centro emisor → centro receptor
MIGO: GR en centro receptor (101), GI en centro emisor (351)
```

#### STO con entrega (intercompany)
```
Requiere:
  - Org compras en centro receptor
  - Org ventas + canal distribucion en centro emisor
  - Cliente (centro receptor como cliente)
  - Material extendido en ambos centros

Proceso:
  ME21N (UB) → VL10B (crear entrega) → VL02N (picking) →
  MIGO GR receptor → Factura intercompany VF01

Config: SPRO → MM → Purchasing → PO → Setup STO
  Asignar tipo doc NB a tipo entrega NLCC
  Asignar sociedad emisora → org ventas + canal
```

### Third-party processing (triangular)
```
Pedido SD (VA01) → Solicitud pedido automatica → PO a proveedor (ME21N)
  Proveedor envia directo al cliente

Config: Tipo posicion TAS (third party) en material/categoria
```

## MM → PP (Produccion)

### Reservas automaticas
```
Orden produccion (CO01) genera reservas automaticas de componentes
  Tabla: RESB (reservas de componentes)
  TM 261: consumo a orden
  TM 262: devolucion desde orden
```

### MRP Integration
```
MRP (MD01) → genera:
  - Ordenes previsionales (planned orders) → convertir a PO o orden prod.
  - Solicitudes pedido automaticas

MRP lee:
  - BOM (lista materiales) → componentes necesarios
  - Routing → tiempos de proceso
  - Stock actual → necesidad neta
  - POs/SolPed existentes → oferta
```

### Backflush
```
Consumo automatico al confirmar orden produccion:
  CO11N → confirmacion → TM 261 automatico para componentes BOM

Config: MARC-RGEKZ (backflush indicator) en material
```

### Subcontratacion
```
PO con tipo posicion L:
  ME21N (tipo pos L) → provision componentes (ME2O) → MIGO GR → MIRO

Stock componentes en proveedor: tabla MSLB
Tipo movimiento provision: 541 (salida a proveedor)
Tipo movimiento GR: 101 (producto terminado del proveedor)
```

## MM → QM (Quality Management)

### Inspeccion en entrada mercancias
```
MIGO (101) → Si material tiene tipo inspeccion 01 activo:
  → Stock va a calidad (INSME) en vez de libre (LABST)
  → Crea lote inspeccion automatico
  → QA01/QA02 → registro resultados → UD (usage decision)
  → UD aprueba → stock pasa a libre (TM 321)
  → UD rechaza → stock a bloqueado o devolucion
```

### Config
```
Material master (MM02) → QM view:
  - Tipo inspeccion 01 (GR inspection) activo
  - Control activo (QM in procurement)

SPRO → QM → QM in Procurement → Define inspection type for GR
```

### Queries MCP
```sql
-- Materiales con inspeccion activa
SELECT MATNR, WERKS, QMATA FROM QMAT
WHERE WERKS = '{centro}' AND ART = '01' AND AKTIV = 'X'

-- Lotes de inspeccion pendientes
SELECT PRUEFLOS, MATNR, WERK, STAT36 FROM QALS
WHERE WERK = '{centro}' AND STAT36 = '' -- sin UD
```

## MM → WM/EWM (Warehouse Management)

### Integracion WM clasico
```
GR en MM (MIGO 101) → Transfer Requirement automatico →
  Transfer Order (LT01) → Putaway a ubicacion

GI en MM (MIGO 201) → Transfer Requirement →
  Transfer Order (LT02) → Picking desde ubicacion
```

### Integracion EWM (S/4HANA)
```
GR en MM → Inbound Delivery (VL31N) →
  Warehouse Task → Putaway confirmation

S/4 Embedded EWM: integrado directamente (sin sistema WM separado)
```
