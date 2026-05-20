# S/4HANA 2023 — Data Model FI

## ACDOCA (Universal Journal) — Tabla Central

```
S/4HANA elimina tablas de totales y subledger separadas.
ACDOCA = GL + AP + AR + AA + CO + ML (todo en una sola tabla)

Reemplaza como fuente de verdad:
  BSIS/BSAS, BSID/BSAD, BSIK/BSAK → compatibility views sobre ACDOCA
  FAGLFLEXA, FAGLFLEXT, GLT0 → compatibility views / eliminadas
  COEP, COBK → compatibility views sobre ACDOCA
  ANLC, ANLP, ANEP, ANEK → compatibility views (New Asset Accounting)

NOTA: BSEG sigue existiendo como tabla real (ver seccion BSEG abajo).
      BKPF sigue como tabla real para cabeceras de documento.
```

### Campos clave ACDOCA

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| **RLDNR** | Ledger | 0L (leading), 2L (IFRS), 3L (local) |
| **RBUKRS** | Sociedad | 1000 |
| **BELNR** | Numero documento | 0100000001 |
| **GJAHR** | Ejercicio fiscal | 2025 |
| **BUZEI** | Posicion | 001, 002 |
| **DOCLN** | Line number (6 digits) | 000001 |

### Campos de cuenta y subledger

| Campo | Descripcion | Valores |
|-------|-------------|---------|
| RACCT / HKONT | Cuenta GL | 400000, 140000 |
| KOART | Tipo cuenta | D=deudor, K=acreedor, S=GL, A=activo, M=material |
| KUNNR | Cliente (AR) | 10001 |
| LIFNR | Proveedor (AP) | 50001 |
| ANLN1 / ANLN2 | Activo fijo / sub-numero | 000001000 / 0000 |
| MATNR | Material (ML) | MAT-001 |

### Campos de importe (multi-moneda)

| Campo | Moneda | Descripcion |
|-------|--------|-------------|
| HSL | RHCUR | Company code currency (moneda sociedad) |
| KSL | RKCUR | Controlling area currency (moneda area CO) |
| OSL | ROCUR | Freely defined currency 1 (configurable por ledger) |
| VSL | RVCUR | Freely defined currency 2 (configurable por ledger) |
| TSL | RTCUR | Transaction currency (moneda de transaccion/balance) |
| WSL | RWCUR | Document currency (moneda original documento) |
| MSL | RMCUR | Material ledger currency |

Notas monedas:
- WSL, TSL, HSL, KSL son obligatorias en todos los ledgers
- KSL se llena si la sociedad esta asignada a un area de controlling
- OSL y VSL son libremente definibles por ledger (pueden ser group currency, etc.)
- Campos de importe tienen longitud 23 digitos (incluidos 2 decimales)

### Campos dimensionales

| Campo | Descripcion |
|-------|-------------|
| RCNTR / KOSTL | Centro de coste |
| PRCTR | Centro de beneficio |
| RFAREA | Area funcional |
| RBUSA / GSBER | Area de negocio |
| SEGMENT | Segmento |
| RCOMP | Sociedad asociada (intercompany) |
| AUFNR | Orden interna |
| PS_PSP_PNR | Elemento PEP (WBS) |
| KSTAR | Elemento de coste (= GL account en S/4) |

### Campos de status

| Campo | Descripcion |
|-------|-------------|
| DRCRK | Indicador D/C (S=debe, H=haber) |
| AUGDT | Fecha compensacion (vacio = abierto) |
| AUGBL | Documento compensacion |
| BSTAT | Status documento (vacio=normal, S=estadistico) |
| XREVERSED | Indicador anulado |
| XREVERSING | Indicador doc de anulacion |

### Campos de impuesto

| Campo | Descripcion |
|-------|-------------|
| MWSKZ | Codigo impuesto |
| TXJCD | Jurisdiccion fiscal |
| HWBAS | Base imponible moneda local |
| FWBAS | Base imponible moneda documento |

### Campos CO integrados

| Campo | Descripcion |
|-------|-------------|
| CO_BELKZ | Categoria doc CO |
| BELTP | Tipo doc CO |
| OBJNR | Objeto CO |
| KALNR | Numero calculo coste |

## Vistas de compatibilidad (NO son tablas en S/4)

| Tabla Legacy | Status S/4 | Filtro ACDOCA |
|-------------|-----------|---------------|
| BSEG | **TABLA REAL (reducida)** | Entry view, open items. NO es view. |
| BSIS | View | KOART='S' AND AUGDT='' (GL abiertas) |
| BSAS | View | KOART='S' AND AUGDT<>'' (GL compensadas) |
| BSID | View | KOART='D' AND AUGDT='' (AR abiertas) |
| BSAD | View | KOART='D' AND AUGDT<>'' (AR compensadas) |
| BSIK | View | KOART='K' AND AUGDT='' (AP abiertas) |
| BSAK | View | KOART='K' AND AUGDT<>'' (AP compensadas) |
| FAGLFLEXA | View | Line items GL |
| FAGLFLEXT | View | Totals GL (aggregated) |
| GLT0 | Eliminada | ACDOCA aggregated |
| COEP | View | CO line items |
| COBK | View | CO doc headers |
| ANLC | View | Asset values (KOART='A' en ACDOCA) |
| ANLP | View | Asset periodic values |
| ANEP | View | Asset postings |
| ANEK | View | Asset doc headers (→ BKPF) |

## BSEG — Status real en S/4HANA (IMPORTANTE)

```
BSEG sigue siendo una TABLA REAL (transparente) en S/4HANA, NO es compatibility view.

Comportamiento:
  - La MAYORIA de documentos contables actualizan TANTO BSEG como ACDOCA simultaneamente
  - BSEG = "Entry View" (vista de entrada del documento, para open item management)
  - ACDOCA = "Accounting View" (fuente de verdad contable, integra FI+CO+AA+ML)

Excepciones (solo ACDOCA, sin BSEG):
  - Documentos con BSTAT = 'U' (ej: depreciacion automatica AFAB desde S/4 1809)
  - Estos documentos solo tienen BKPF + ACDOCA, sin entry view BSEG

Implicaciones para custom code:
  - SELECT FROM BSEG → funciona y retorna datos (es tabla real)
  - Pero ACDOCA es la fuente de verdad y tiene mas campos (CO, ML, multi-ledger)
  - Para reporting: usar ACDOCA (mas completo y eficiente)
  - Para open items / clearing: BSEG sigue siendo relevante

Futuro:
  - SAP planea que BSEG se use SOLO para open item management
  - Postings que no sean open items dejaran de escribir en BSEG
  - BSEG podria ser eliminada en versiones futuras (no confirmado aun)
```

## BKPF (Document Header) — Sigue existiendo

```
Campos principales:
  BUKRS, BELNR, GJAHR     → Clave documento
  BLART                    → Tipo documento
  BLDAT, BUDAT, CPUDT      → Fecha doc, contabilizacion, registro
  MONAT                    → Periodo
  WAERS, KURSF             → Moneda, tipo cambio
  XBLNR                    → Referencia
  BKTXT                    → Texto cabecera
  STBLG, STJAH             → Doc anulacion + ejercicio
  BSTAT                    → Status (vacio=normal, V=preliminar, S=estadistico)
  AWTYP                    → Tipo objeto referencia (BKPF, MKPF, VBRK, etc.)
  AWKEY                    → Clave objeto referencia
  USNAM, PPNAM             → Usuario creador, autor
```

## Tablas nuevas S/4HANA

| Tabla | Proposito |
|-------|-----------|
| ACDOCA | Universal Journal (principal) |
| ACDOCP | Plan data (planning journal) |
| ACDOCU | Documentos no contabilizados |
| FINSC_LEDGER | Configuracion de ledgers |
| FINSC_LD_CMP | Asignacion ledger-sociedad |
| BUT000 | Business Partner (central) |
| BUT0BK | BP bank data |
| BUT020 | BP addresses |

## CDS Views analiticas

| CDS View | Descripcion |
|----------|-------------|
| I_JournalEntry | Cabecera asiento contable |
| I_JournalEntryItem | Posiciones asiento contable |
| I_GLAccountLineItem | Partidas individuales GL |
| I_GLAccountBalance | Saldos cuenta GL |
| I_TrialBalance | Balance de comprobacion |
| I_OperatingExpense | Gastos operativos |
| I_FixedAsset | Datos maestros activos |
| I_CustomerLineItem | Partidas cliente |
| I_SupplierLineItem | Partidas proveedor |
| I_GLAccountLineItemRawData | GL raw data (sin agregacion) |
| I_JournalEntryItemBasic | Journal entry basic (API) |
| I_OPLAccountingDocumentItem | Operational doc items |

## Queries MCP

```sql
-- Documento completo con todas las dimensiones
SELECT RLDNR, RBUKRS, BELNR, GJAHR, BUZEI,
       RACCT, KOART, DRCRK, HSL, TSL,
       RCNTR, PRCTR, SEGMENT, RFAREA,
       KUNNR, LIFNR, ANLN1, MATNR,
       AUGDT, AUGBL, MWSKZ
FROM ACDOCA
WHERE BELNR = '{doc}' AND RBUKRS = '{sociedad}' AND GJAHR = '{year}'
AND RLDNR = '0L'

-- Reconciliacion subledger vs GL
SELECT KOART, RACCT, SUM(HSL) as TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}' AND RLDNR = '0L'
AND KOART IN ('D','K')
GROUP BY KOART, RACCT

-- Verificar si BKPF doc esta anulado
SELECT BUKRS, BELNR, GJAHR, BLART, BUDAT, STBLG, STJAH, BSTAT
FROM BKPF
WHERE BELNR = '{doc}' AND BUKRS = '{sociedad}' AND GJAHR = '{year}'

-- Journal entries por usuario y fecha
SELECT BELNR, BLART, BUDAT, WAERS, USNAM, BKTXT
FROM BKPF
WHERE BUKRS = '{sociedad}' AND CPUDT = '{fecha}' AND USNAM = '{usuario}'

-- Ledger comparison (parallel accounting)
SELECT RLDNR, RACCT, SUM(HSL) as TOTAL_LOCAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}' AND GJAHR = '{year}'
AND RACCT = '{cuenta}'
GROUP BY RLDNR, RACCT
```
