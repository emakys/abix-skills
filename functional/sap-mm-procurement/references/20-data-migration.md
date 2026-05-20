# Migracion de Datos MM

## Objetos a migrar

### Orden de carga (dependencias)
```
1. Estructura organizativa (manual o config)
   Sociedades → Centros → Almacenes → Org compras → Grupos compra

2. Datos maestros (orden critico)
   a) Dominios / Valores fijos (si hay custom)
   b) Material Master — por vistas:
      General → Centro → Almacen → Compras → MRP → Contabilidad
   c) Business Partner / Vendor
      General → Org compras → Sociedad → Banco
   d) Info Records (requiere material + vendor)
   e) Source Lists (requiere material + vendor)
   f) Condiciones de precio (requiere info record o contrato)

3. Stock inicial (despues de datos maestros)
   Saldo de stock por centro/almacen/lote
   Tipo movimiento: 561 (inventario inicial)

4. Documentos abiertos (opcionales)
   a) Solicitudes pedido abiertas
   b) Pedidos abiertos (POs pendientes de GR)
   c) Contratos vigentes
   d) Saldo GR/IR pendiente
```

## Herramientas de migracion

### LTMC / Migration Cockpit (S/4HANA recomendado)
```
Transaccion: LTMC (S/4HANA Cloud) o LTMOM (on-premise)

Objetos predefinidos para MM:
  - Material master (all views)
  - Business partner (supplier role)
  - Purchasing info record
  - Source list
  - Purchase order (open)
  - Stock balance
  - GR/IR clearing balance

Ventajas:
  - Templates Excel predefinidos
  - Validacion antes de carga
  - Log de errores detallado
  - Soporte para S/4 data model (BP, MATDOC, etc.)
```

### LSMW (Legacy System Migration Workbench)
```
Transaccion: LSMW

Metodos:
  1. Batch Input (SHDB recording) — el mas comun
  2. Direct Input — programas estandar de carga
  3. BAPI — via function module
  4. IDoc — via interfaz IDoc

Para MM tipicamente:
  Material: Direct Input (RMDATIND) o BAPI (BAPI_MATERIAL_SAVEDATA)
  Vendor: Batch Input (MK01) o BAPI (BAPI_VENDOR_CREATE)
  Info Record: Batch Input (ME11) o BAPI
  Stock: Direct Input (RM07MMFI)
```

### BAPIs de carga masiva
| Objeto | BAPI | Parametros clave |
|--------|------|-----------------|
| Material | BAPI_MATERIAL_SAVEDATA | HEADDATA, CLIENTDATA, PLANTDATA, STORAGELOCATIONDATA, VALUATIONDATA |
| Vendor (ECC) | BAPI_VENDOR_CREATE | VENDOR_GEN, VENDOR_PUR, VENDOR_COMPANY |
| BP (S/4) | CL_MD_BP_MAINTAIN=>MAINTAIN | Business partner con roles |
| Info Record | ME_MAINTAIN_INFORECORD | EINA, EINE data |
| PO | BAPI_PO_CREATE1 | PO_HEADER, PO_ITEMS |
| Stock | BAPI_GOODSMVT_CREATE | GM_CODE='05' (otros), TM 561 |

## Templates de datos

### Material Master — Campos minimos
```
| Campo | Tabla | Obligatorio | Ejemplo |
|-------|-------|:-----------:|---------|
| MATNR | MARA | Si | 000000004711 |
| MTART | MARA | Si | ROH (materia prima) |
| MBRSH | MARA | Si | M (mecanica) |
| MATKL | MARA | Si | 001 (grupo materiales) |
| MEINS | MARA | Si | KG |
| MAKTX | MAKT | Si | "Acero inoxidable 304" |
| WERKS | MARC | Si | 1000 |
| DISMM | MARC | Rec. | PD (MRP) |
| EKGRP | MARC | Rec. | 001 (grupo compra) |
| LGORT | MARD | Rec. | 0001 |
| VPRSV | MBEW | Si | V (promedio movil) |
| VERPR | MBEW | Si | 100.00 |
| BKLAS | MBEW | Si | 3000 (clase valoracion) |
```

### Vendor/BP — Campos minimos
```
| Campo | Tabla | Obligatorio | Ejemplo |
|-------|-------|:-----------:|---------|
| LIFNR | LFA1 | Auto/manual | 0000001000 |
| KTOKK | LFA1 | Si | 0001 (grupo cuenta) |
| NAME1 | LFA1 | Si | "Proveedor ABC" |
| LAND1 | LFA1 | Si | MX |
| EKORG | LFM1 | Si | 1000 |
| ZTERM | LFM1 | Rec. | 0030 (30 dias) |
| WAERS | LFM1 | Rec. | MXN |
| BUKRS | LFB1 | Si | 1000 |
| AKONT | LFB1 | Si | 160000 (cuenta AP) |
```

### Stock inicial — Campos
```
| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| MATNR | Material | 4711 |
| WERKS | Centro | 1000 |
| LGORT | Almacen | 0001 |
| MENGE | Cantidad | 1000 |
| MEINS | Unidad | KG |
| BUDAT | Fecha contabilizacion | 2026-01-01 |
| BWART | Tipo movimiento | 561 |
| Valor | Precio unitario | 100.00 (o usa precio del maestro) |
```

## Validaciones pre-carga

### Material
```sql
-- Materiales duplicados (por descripcion)
SELECT MAKTX, COUNT(*) FROM MAKT WHERE SPRAS = 'E' GROUP BY MAKTX HAVING COUNT(*) > 1

-- Materiales sin precio
SELECT MATNR FROM MARC WHERE WERKS = '{centro}'
AND MATNR NOT IN (SELECT MATNR FROM MBEW WHERE BWKEY = '{centro}')

-- Materiales sin grupo material
SELECT MATNR, MAKTX FROM MARA JOIN MAKT ON MARA.MATNR = MAKT.MATNR
WHERE MARA.MATKL = '' AND MAKT.SPRAS = 'E'
```

### Vendor
```sql
-- Proveedores sin extension a org compras
SELECT LFA1.LIFNR, LFA1.NAME1 FROM LFA1
WHERE LFA1.LIFNR NOT IN (SELECT LIFNR FROM LFM1 WHERE EKORG = '{org}')

-- Proveedores sin datos bancarios
SELECT LFA1.LIFNR, LFA1.NAME1 FROM LFA1
WHERE LFA1.LIFNR NOT IN (SELECT LIFNR FROM LFBK)
```

### Stock
```sql
-- Stock sin precio (no se puede valorar)
SELECT MARD.MATNR, MARD.WERKS, MARD.LABST
FROM MARD LEFT JOIN MBEW ON MARD.MATNR = MBEW.MATNR AND MARD.WERKS = MBEW.BWKEY
WHERE MARD.LABST > 0 AND (MBEW.VERPR = 0 OR MBEW.VERPR IS NULL)
```

## Checklist de migracion MM

```
Pre-migracion:
  [ ] Estructura org configurada y verificada
  [ ] Rangos de numeros definidos (materiales, proveedores, POs)
  [ ] Grupos de materiales creados
  [ ] Clases de valoracion configuradas
  [ ] Cuentas automaticas OBYC configuradas
  [ ] Condiciones de pago creadas
  [ ] Templates de carga preparados y validados

Carga:
  [ ] Materiales cargados (todas las vistas necesarias)
  [ ] Proveedores/BP cargados (general + org compras + sociedad)
  [ ] Info records cargados
  [ ] Source lists creadas
  [ ] Condiciones de precio migradas
  [ ] Stock inicial cargado (fecha de corte = go-live)

Post-migracion:
  [ ] Reconciliacion: stock SAP vs stock real/legacy
  [ ] Reconciliacion: saldos AP SAP vs legacy
  [ ] Verificar proceso P2P end-to-end (PO → GR → IR → Pago)
  [ ] Verificar MRP genera propuestas correctas
  [ ] Verificar output (impresion/email PO)
  [ ] Verificar release strategies funcionan
```

## Queries MCP post-migracion
```sql
-- Contar registros migrados
SELECT COUNT(*) as MATERIALES FROM MARA WHERE ERSDA = '{fecha_carga}'
SELECT COUNT(*) as PROVEEDORES FROM LFA1 WHERE ERDAT = '{fecha_carga}'
SELECT COUNT(*) as INFO_RECORDS FROM EINA WHERE ERDAT = '{fecha_carga}'

-- Stock total cargado
SELECT SUM(LABST) as TOTAL_QTY, SUM(LABST * MBEW.VERPR) as TOTAL_VALUE
FROM MARD JOIN MBEW ON MARD.MATNR = MBEW.MATNR AND MARD.WERKS = MBEW.BWKEY
WHERE MARD.WERKS = '{centro}'

-- POs abiertas migradas
SELECT COUNT(*) as POS_ABIERTAS, SUM(EKPO.NETWR) as VALOR_TOTAL
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKKO.BEDAT = '{fecha_carga}' AND EKPO.ELIKZ = ''
```

## Errores comunes en migracion

| Error | Causa | Prevencion |
|-------|-------|-----------|
| Material ya existe | Duplicado en archivo fuente | Dedup previo |
| Clase valoracion invalida | No configurada en OMWD | Config previa |
| Cuenta no determinada | OBYC incompleto | OBYC antes de carga stock |
| Proveedor sin sociedad | Falta extension LFB1 | Template completo |
| Stock sin precio | MBEW vacio | Cargar material con precio antes de stock |
| Conversion unidad falla | Unidad no mantenida en CUNI | T006 verificar |
| Numero de material overflow | Rango de numeros lleno | MMNR verificar |
