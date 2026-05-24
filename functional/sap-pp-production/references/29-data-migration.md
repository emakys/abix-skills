# Migracion de Datos PP

## Objetos de migracion PP

| Objeto | Herramienta | BAPI/Programa |
|--------|-------------|---------------|
| BOM material | Migration Cockpit / LSMW | CSAP_MAT_BOM_CREATE |
| Routing | Migration Cockpit / LSMW | BAPI_ROUTING_CREATE |
| Work center | Migration Cockpit / LSMW | BDC CR01 |
| Version fabricacion | BDC / LSMW | BDC C223 |
| PIR (Independent req.) | Migration Cockpit | MD_SET_ACTION_PLANNED_INDREQ |
| Material master (PP views) | Migration Cockpit | BAPI_MATERIAL_SAVEDATA |
| Ordenes produccion | No recomendado | — (abrir solo si cutover) |
| Ordenes previsionales | No recomendado | Genera MRP post-migration |

## Orden de migracion PP

```
1. Material master — vistas MRP + Work Scheduling (MM01/BAPI)
2. Work centers (CR01/BDC)
3. BOM (CS01/CSAP_MAT_BOM_CREATE)
4. Routing (CA01/BAPI_ROUTING_CREATE)
5. Versiones fabricacion (C223/BDC)
6. PIR — solo si MTS (MD61/BAPI)
7. Stock opening balances (MB1C → mov. 561)
8. MRP run inicial (MD01) → genera previsionales
9. Ordenes produccion cutover (si hay ordenes abiertas)
```

## Dependencias criticas

```
Material master PP views → REQUIERE:
  - Material base creado (vista basica)
  - Centro/almacen existente (T001W/T001L)
  - Planificador MRP definido (T024D)

BOM → REQUIERE:
  - Material padre creado con vista PP
  - Todos los componentes creados
  - Unidades de medida consistentes

Routing → REQUIERE:
  - Work centers creados (CRHD)
  - Formulas scheduling configuradas (TC24)
  - Claves control definidas (T430)

Version fabricacion → REQUIERE:
  - BOM creada (MAST/STKO)
  - Routing creado (PLKO)
  - Ambos con validez temporal compatible
```

## Material master — Campos PP obligatorios

| Campo | Vista | Obligatorio para |
|-------|-------|------------------|
| DISMM | MRP 1 | MRP run |
| DISPO | MRP 1 | Planificador MRP |
| DISLS | MRP 1 | Tamano lote |
| BESKZ | MRP 2 | Tipo aprovisionamiento |
| DZEIT | Work Scheduling | In-house production time |
| FEESSION | Work Scheduling | Production scheduler |
| STRGR | MRP 3 | Strategy group (si MTS) |

## Validacion post-migracion

```sql
-- Materiales PP sin vista MRP completa
SELECT MATNR, WERKS, DISMM, DISPO, DISLS, BESKZ
FROM MARC
WHERE WERKS = '{centro}' AND BESKZ IN ('E','X')
AND (DISMM = '' OR DISPO = '')

-- BOM sin componentes
SELECT M.MATNR, M.STLNR, COUNT(P.POSNR) AS ITEMS
FROM MAST M
LEFT JOIN STPO P ON M.STLNR = P.STLNR
WHERE M.WERKS = '{centro}' AND M.STLAN = '1'
GROUP BY M.MATNR, M.STLNR
HAVING COUNT(P.POSNR) = 0

-- Materiales con BOM pero sin routing
SELECT M.MATNR FROM MAST M
WHERE M.WERKS = '{centro}' AND M.STLAN = '1'
AND NOT EXISTS (
  SELECT 1 FROM PLKO P
  WHERE P.MATNR = M.MATNR AND P.WERKS = M.WERKS AND P.PLNTY = 'N'
)

-- Materiales con BOM y routing pero sin version fabricacion
SELECT M.MATNR FROM MAST M
WHERE M.WERKS = '{centro}' AND M.STLAN = '1'
AND EXISTS (SELECT 1 FROM PLKO P WHERE P.MATNR = M.MATNR AND P.WERKS = M.WERKS)
AND NOT EXISTS (SELECT 1 FROM MKAL K WHERE K.MATNR = M.MATNR AND K.WERKS = M.WERKS)

-- Work centers sin asignacion CC
SELECT H.ARBPL, H.WERKS FROM CRHD H
WHERE H.WERKS = '{centro}' AND H.OBJTY = 'A'
AND NOT EXISTS (SELECT 1 FROM CRCO C WHERE C.OBJID = H.OBJID)

-- Verificar version fabricacion activa
SELECT MATNR, VEESSION, MDESSION FROM MKAL
WHERE WERKS = '{centro}' AND MDESSION = 'X'
```

## Consideraciones S/4HANA

| Aspecto | Nota |
|---------|------|
| MATDOC | Movimientos se registran en MATDOC (no MKPF+MSEG) |
| ACDOCA | Costes de produccion en Universal Journal |
| MRP Live | MD01N disponible post-migration |
| Migration Cockpit | Herramienta preferida para S/4 (sobre LSMW) |
| Custom code | Verificar queries a tablas eliminadas |
| Stock balances | Migrar con MB1C (561) antes de MRP run |

## Cutover — Ordenes abiertas

Si hay ordenes de produccion abiertas al momento del cutover:

### Opcion A: Cerrar en legacy, abrir en S/4
1. TECO/CLSD en sistema legacy
2. Migrar solo datos maestros
3. MRP genera nuevas previsionales en S/4

### Opcion B: Migrar ordenes abiertas
1. Exportar ordenes con BAPI_PRODORD_GET_DETAIL
2. Crear en S/4 con BAPI_PRODORD_CREATE
3. Ajustar status, componentes retirados, confirmaciones parciales
4. **Alto riesgo** — solo si absolutamente necesario

### Recomendacion
- Minimizar ordenes abiertas en cutover
- Completar ordenes posibles antes de go-live
- Preferir opcion A
