# S/4HANA 2023 — Modelo de Datos Simplificado MM

## Principio fundamental

S/4HANA elimina tablas de agregacion e indices redundantes. Las tablas originales pueden
convertirse en **compatibility views** que leen de las tablas nuevas.

## Tablas de inventario

### MATDOC — Tabla unica de documentos de material
```
ECC:  MKPF (cabecera) + MSEG (posiciones) → tablas separadas
S/4:  MATDOC → tabla unica (combina cabecera + posiciones)
      MKPF y MSEG existen como COMPATIBILITY VIEWS sobre MATDOC
```

| Campo MATDOC | Equivalente ECC | Descripcion |
|-------------|-----------------|-------------|
| MBLNR | MKPF-MBLNR | Numero documento material |
| MJAHR | MKPF-MJAHR | Ejercicio |
| ZEILE | MSEG-ZEILE | Posicion |
| BUDAT | MKPF-BUDAT | Fecha contabilizacion |
| USNAM | MKPF-USNAM | Usuario |
| BWART | MSEG-BWART | Tipo movimiento |
| MATNR | MSEG-MATNR | Material |
| WERKS | MSEG-WERKS | Centro |
| LGORT | MSEG-LGORT | Almacen |
| MENGE | MSEG-MENGE | Cantidad |
| DMBTR | MSEG-DMBTR | Importe moneda local |
| EBELN | MSEG-EBELN | Pedido de compra |
| EBELP | MSEG-EBELP | Posicion PO |

### Queries MCP — Usar MATDOC o compatibility views
```sql
-- OPCION A: Tabla nueva MATDOC (recomendado para S/4)
SELECT MBLNR, MJAHR, ZEILE, BUDAT, BWART, MATNR, WERKS, LGORT, MENGE, EBELN
FROM MATDOC WHERE MATNR = '{material}' AND BUDAT BETWEEN '{desde}' AND '{hasta}'

-- OPCION B: Compatibility views (funciona igual que ECC)
SELECT MKPF.MBLNR, MKPF.BUDAT, MSEG.BWART, MSEG.MATNR, MSEG.MENGE
FROM MKPF JOIN MSEG ON MKPF.MBLNR = MSEG.MBLNR AND MKPF.MJAHR = MSEG.MJAHR
WHERE MSEG.MATNR = '{material}'

-- Ambas funcionan, pero MATDOC es mas eficiente (1 tabla vs join de 2 views)
```

### MATDOC_EXTRACT — Tabla condensada para performance
```
MATDOC_EXTRACT es una version compactada de MATDOC:
  - Registros insertados automaticamente al mismo tiempo que MATDOC
  - Pre-compacting ejecutado automaticamente con cierre de periodo
  - Usada internamente para calculos on-the-fly de stock
  - NO acceder directamente — es infraestructura interna del NSDM
```

### Campos clave completos MATDOC (4 campos, no 3)
```
MBLNR  → Numero documento material
MJAHR  → Ejercicio
ZEILE  → Posicion
BWCOUNTER → Contador unico de linea (nuevo en S/4, distingue splits)
```

### Stock tables — NSDM (New Simplified Data Model)
```
IMPORTANTE: En S/4HANA, las tablas de stock YA NO almacenan stock directamente.
Los valores de stock se calculan ON-THE-FLY desde MATDOC via CDS views.

MARD → COMPATIBILITY VIEW (stock calculado via NSDM_V_MARD)
        MARD-LABST = SUM de movimientos en MATDOC, no un campo persistente
        Para queries: usar NSDM_V_MARD en vez de MARD directamente

MCHB → COMPATIBILITY VIEW (stock por lote calculado on-the-fly)

MARC → TABLA REAL para master data, pero campos agregados (stock)
        vienen de NSDM views.
        Usar: V_MARC_MD (solo master data)
              NSDM_V_MARC_DIFF (campos agregados)

MARA, MAKT → SIN CAMBIOS (tablas reales, no afectadas por NSDM)
MBEW → SIN CAMBIOS para master data (precio), pero actuals en ACDOCA

Referencia tecnica: SAP Note 2206980 (Material Inventory Data Model)
```

## Tablas de compras — Sin cambios significativos

```
EKKO, EKPO, EKET, EKBE → SE MANTIENEN como tablas reales
EBAN (solicitud pedido) → SE MANTIENE
EINA, EINE (info record) → SE MANTIENEN
EORD (source list) → SE MANTIENE
```

## Contabilidad — ACDOCA (Universal Journal)

```
ECC:  BKPF (cabecera) + BSEG (posiciones) + BSIK/BSAK (AP) + COEP (CO)
S/4:  ACDOCA → Universal Journal (une FI + CO + ML + AA)
      BKPF se mantiene como tabla real
      BSEG se mantiene como tabla real (pero ACDOCA es la fuente de verdad)
      BSIK/BSAK → compatibility views sobre ACDOCA
```

### Queries MCP — Asientos de una factura logistica
```sql
-- Via ACDOCA (S/4 nativo, recomendado)
SELECT BELNR, BUZEI, KOART, KTOSL, HKONT, HSL, LIFNR, MATNR
FROM ACDOCA WHERE BELNR = '{doc_contable}' AND RLDNR = '0L'

-- Via BSEG (compatibility, funciona pero menos eficiente)
SELECT BELNR, BUZEI, KOART, HKONT, DMBTR, LIFNR
FROM BSEG WHERE BELNR = '{doc_contable}' AND BUKRS = '{sociedad}'

-- Saldo proveedor (S/4: usar ACDOCA, no BSIK/BSAK)
SELECT LIFNR, SUM(HSL) as SALDO FROM ACDOCA
WHERE LIFNR = '{proveedor}' AND KOART = 'K' AND RLDNR = '0L'
GROUP BY LIFNR
```

## Business Partner — Modelo definitivo S/4HANA 2023

```
Creacion: SOLO via transaccion BP (MK01/XK01 redirigen a BP)
Tablas principales:
  BUT000 → Datos generales BP (reemplaza LFA1 para creacion)
  BUT020 → Direcciones
  BUT0BK → Datos bancarios
  LFA1 → COMPATIBILITY VIEW (lectura OK, creacion NO)
  LFM1 → SE MANTIENE (datos compras via CVI sync)
  LFB1 → SE MANTIENE (datos sociedad via CVI sync)

CVI (Customer Vendor Integration):
  Sincroniza automaticamente BP <-> Vendor number
  BP con rol FLVN00 (FI vendor) o FLVN01 (vendor general)
  Tabla mapping: CVI_VEND_LINK (BP_NUMBER <-> VENDOR)
```

### Queries MCP
```sql
-- BP como proveedor (S/4 nativo)
SELECT BP.PARTNER, BP.NAME_ORG1, BP.BU_GROUP, CVI.VENDOR
FROM BUT000 BP
JOIN CVI_VEND_LINK CVI ON BP.PARTNER = CVI.PARTNER_GUID
WHERE CVI.VENDOR = '{proveedor}'

-- Verificar CVI sync
SELECT PARTNER_GUID, VENDOR FROM CVI_VEND_LINK WHERE VENDOR = '{proveedor}'
```

## Tablas eliminadas en S/4HANA (no existen)

| Tabla ECC | Motivo eliminacion | Alternativa S/4 |
|-----------|-------------------|-----------------|
| BSIS/BSAS | Partidas GL | ACDOCA + BKPF |
| BSID/BSAD | Partidas clientes | ACDOCA |
| BSIK/BSAK | Partidas proveedores | ACDOCA (compatibility view exists) |
| GLT0 | Saldos GL | ACDOCA agregate |
| COEP | Partidas CO | ACDOCA (columnas CO) |
| FAGLFLEXA | New GL totals | ACDOCA |
| S000-S999 | LIS statistics | Embedded Analytics CDS |
| MC*** tables | SIS statistics | Embedded Analytics CDS |

## Impacto en custom code

### Regla de oro
```
1. SELECT de tablas de compatibility views → FUNCIONA (pero lento)
2. INSERT/UPDATE/DELETE en compatibility views → NO FUNCIONA (error dump)
3. Reports custom deben migrar a ACDOCA/MATDOC para rendimiento
4. BAPIs siguen funcionando (abstraen las tablas)
5. Code Inspector (SCI) con check S/4HANA readiness detecta problemas
```

### Transaccion de verificacion
```
SYCM → Custom Code Migration Worklist
  Detecta automaticamente uso de tablas eliminadas/cambiadas en codigo Z
```
