# S/4HANA 2023 — Modelo de Datos Simplificado SD

## Principio fundamental

S/4HANA simplifica el modelo de datos eliminando tablas de agregacion e indices redundantes.
En SD, las tablas de ventas (VBAK/VBAP, LIKP/LIPS, VBRK/VBRP) se mantienen, pero el impacto
principal viene de ACDOCA (documentos FI de facturacion) y MATDOC (salida de mercancias en entrega).

---

## Tablas SD — Las que SE MANTIENEN sin cambios

### Pedidos de venta
```
VBAK  → Cabecera pedido de venta          (SIN CAMBIOS — tabla real)
        ABSORBE campos de status de VBUK (GBSTK, LFSTK, FKSTK, etc.)
VBAP  → Posiciones pedido de venta        (SIN CAMBIOS — tabla real)
        ABSORBE campos de status de VBUP (GBSTA, LFSTA, FKSTA, etc.)
VBEP  → Plan de entregas/necesidades      (SIN CAMBIOS — tabla real)
VBKD  → Datos comerciales cabecera/pos    (SIN CAMBIOS — tabla real)
VBPA  → Interlocutores del documento      (SIN CAMBIOS — tabla real)
VBFA  → Flujo de documentos SD            (SIMPLIFICADA — campo STUFE eliminado,
        doc numbers indirectos ya no se almacenan)

VBUK  → ELIMINADA — campos de status movidos a VBAK/LIKP/VBRK
        Tabla existe fisicamente pero NO se llena para docs nuevos.
        SAP Note 2198647.
VBUP  → ELIMINADA — campos de status movidos a VBAP/LIPS
        Tabla existe fisicamente pero NO se llena para docs nuevos.
        SAP Note 2267306.
```

### Impacto VBUK/VBUP en custom code
```
ECC:  SELECT GBSTK FROM VBUK WHERE VBELN = '{pedido}'
S/4:  SELECT GBSTK FROM VBAK WHERE VBELN = '{pedido}'
      (campo GBSTK ahora vive en VBAK, no en VBUK)

ECC:  SELECT LFSTA FROM VBUP WHERE VBELN = '{pedido}' AND POSNR = '{pos}'
S/4:  SELECT LFSTA FROM VBAP WHERE VBELN = '{pedido}' AND POSNR = '{pos}'

Beneficio: 1 SELECT en vez de 2 (VBAK+VBUK) → mejor performance
```

### Entregas
```
LIKP  → Cabecera entrega                  (SIN CAMBIOS — tabla real)
LIPS  → Posiciones entrega                (SIN CAMBIOS — tabla real)
VTTP  → Cabecera transporte               (SIN CAMBIOS — tabla real)
VTTK  → Etapas transporte                 (SIN CAMBIOS — tabla real)
```

### Facturacion
```
VBRK  → Cabecera documento de facturacion (SIN CAMBIOS — tabla real)
VBRP  → Posiciones factura               (SIN CAMBIOS — tabla real)
VBSS  → Asignacion doc. facturacion       (SIN CAMBIOS — tabla real)
```

### Condiciones de precio
```
KONV  → Condiciones en documentos SD      (COMPATIBILITY VIEW en S/4HANA)
        S/4 usa PRCD_ELEMENTS como tabla real para condiciones de documento.
        KONV existe como view sobre PRCD_ELEMENTS para lectura.
        INSERT/UPDATE/DELETE en KONV → FALLA (dump).
        SAP Note 2220005.
KONH  → Cabeceras de condicion            (SIN CAMBIOS — tabla real)
KONP  → Posiciones de condicion           (SIN CAMBIOS — tabla real)

PRCD_ELEMENTS → Tabla unica de condiciones de documento (nueva en S/4)
  Combina: pricing, output determination, batch split
  Campos clave: KNUMV, KPOSN, STUNR, ZAESSION
  Campos adicionales vs KONV: RECORD_ID, COND_GROUP_ID, etc.
```

### Datos maestros SD
```
KNVV  → Datos de cliente por area de ventas  (SIN CAMBIOS — tabla real)
KNVP  → Interlocutores del cliente           (SIN CAMBIOS — tabla real)
KNVS  → Datos de expedicion del cliente      (SIN CAMBIOS — tabla real)
KNVI  → Datos de impuestos del cliente       (SIN CAMBIOS — tabla real)
KNMT  → Determinacion de materiales          (SIN CAMBIOS — tabla real)
```

---

## ACDOCA — Universal Journal para documentos FI de facturacion

### Cambio principal
```
ECC:  Factura SD → VF01 → doc. contable → BKPF (cabecera) + BSEG (posiciones)
                                           + BSID (partidas abiertas cliente)
                                           + BSAD (partidas compensadas cliente)

S/4:  Factura SD → VF01 → doc. contable → BKPF (se mantiene, tabla real)
                                           ACDOCA (fuente de verdad, Universal Journal)
                                           BSEG → COMPATIBILITY VIEW sobre ACDOCA
                                           BSID/BSAD → COMPATIBILITY VIEWS sobre ACDOCA
```

### Campos ACDOCA relevantes para SD
| Campo ACDOCA | Equivalente ECC | Descripcion |
|-------------|-----------------|-------------|
| BELNR | BKPF-BELNR | Numero documento contable |
| BUDAT | BKPF-BUDAT | Fecha contabilizacion |
| KOART | BSEG-KOART | Clase de cuenta (D=cliente, S=GL) |
| KUNNR | BSEG-KUNNR | Cliente |
| HKONT | BSEG-HKONT | Cuenta GL |
| HSL | BSEG-DMBTR | Importe en moneda local |
| KSL | BSEG-WRBTR | Importe en moneda documento |
| VBELN | — | Referencia documento SD (nuevo en ACDOCA) |
| FKART | — | Clase de factura SD (nuevo en ACDOCA) |
| RLDNR | — | Ledger (0L = leading ledger) |
| AUGBL | BSEG-AUGBL | Documento de compensacion |
| AUGDT | BSEG-AUGDT | Fecha de compensacion |

### Queries MCP — Documentos FI de facturacion SD

```sql
-- OPCION A: Via ACDOCA (S/4 nativo, recomendado)
SELECT BELNR, BUDAT, KOART, KUNNR, HKONT, HSL, KSL, VBELN
FROM ACDOCA
WHERE VBELN = '{factura_sd}' AND RLDNR = '0L'

-- OPCION B: Via BSEG (compatibility view — funciona pero menos eficiente)
SELECT BKPF.BELNR, BKPF.BUDAT, BSEG.KOART, BSEG.KUNNR, BSEG.HKONT, BSEG.DMBTR
FROM BKPF JOIN BSEG ON BKPF.BELNR = BSEG.BELNR AND BKPF.BUKRS = BSEG.BUKRS
WHERE BSEG.VBELN = '{factura_sd}'

-- Saldo de cliente (S/4: usar ACDOCA, NO BSID/BSAD)
SELECT KUNNR, SUM(HSL) AS SALDO FROM ACDOCA
WHERE KUNNR = '{cliente}' AND KOART = 'D' AND RLDNR = '0L' AND AUGBL = ''
GROUP BY KUNNR

-- Partidas abiertas cliente via compatibility view (funciona igual que ECC)
SELECT BELNR, BUDAT, DMBTR, WRBTR FROM BSID
WHERE KUNNR = '{cliente}' AND BUKRS = '{sociedad}'
```

---

## MATDOC — Impacto en la salida de mercancias (PGI) de entrega

### Cambio
```
ECC:  Entrega SD → VL02N (PGI) → MKPF (cabecera doc.material) + MSEG (posiciones)
S/4:  Entrega SD → VL02N (PGI) → MATDOC (tabla unica doc.material)
      MKPF y MSEG existen como COMPATIBILITY VIEWS sobre MATDOC
```

### Campos MATDOC relevantes para SD/PGI
| Campo MATDOC | Descripcion | Notas PGI |
|-------------|-------------|-----------|
| MBLNR | Numero doc. material | Generado por PGI |
| MJAHR | Ejercicio | — |
| ZEILE | Posicion | — |
| BUDAT | Fecha contabilizacion | Fecha PGI |
| BWART | Tipo movimiento | 601=PGI venta, 602=anulacion |
| MATNR | Material | De la posicion entrega |
| WERKS | Centro | Centro expedidor |
| LGORT | Almacen | Almacen expedicion |
| MENGE | Cantidad | Cantidad PGI |
| VBELN_IM | Referencia entrega | Nuevo campo S/4 (enlace a LIKP) |
| VBELP_IM | Posicion entrega | Nuevo campo S/4 (enlace a LIPS) |

### Queries MCP — Movimientos de mercancias desde entrega

```sql
-- PGI de una entrega (S/4 nativo via MATDOC)
SELECT MBLNR, MJAHR, ZEILE, BUDAT, BWART, MATNR, WERKS, MENGE, VBELN_IM
FROM MATDOC
WHERE VBELN_IM = '{entrega}' AND BWART IN ('601', '602')

-- Via compatibility views (igual que ECC)
SELECT MKPF.MBLNR, MKPF.BUDAT, MSEG.BWART, MSEG.MATNR, MSEG.MENGE, MSEG.VBELN
FROM MKPF JOIN MSEG ON MKPF.MBLNR = MSEG.MBLNR AND MKPF.MJAHR = MSEG.MJAHR
WHERE MSEG.VBELN = '{entrega}' AND MSEG.BWART = '601'

-- Historial de salidas de un material (MATDOC es mas eficiente)
SELECT MBLNR, BUDAT, BWART, MENGE, VBELN_IM FROM MATDOC
WHERE MATNR = '{material}' AND BWART = '601' AND BUDAT BETWEEN '{desde}' AND '{hasta}'
```

---

## Business Partner (BP) — Maestro de clientes en S/4HANA

### Cambio estructural
```
ECC:  KNA1 (datos generales cliente) → tabla principal para crear/gestionar clientes
      KNB1 (datos sociedad)
      KNVV (datos area ventas)

S/4:  Creacion SOLO via transaccion BP (XD01/VD01 redirigen a BP)
      BUT000 → Datos generales BP (persona/organizacion)
      BUT020 → Direcciones del BP
      BUT100 → Roles del BP
      KNA1   → COMPATIBILITY VIEW (lectura OK, INSERT directo NO)
      KNB1   → SE MANTIENE (sincronizado via CVI)
      KNVV   → SE MANTIENE (datos area ventas, tabla real)
```

### CVI — Customer-Vendor Integration
```
CVI sincroniza automaticamente BP <-> Customer number:
  BP con rol FLCU00 (FI customer) o FLCU01 (customer general)
  Tabla mapping: CVI_CUST_LINK (PARTNER_GUID <-> KUNNR)

Flujo de creacion en S/4:
  1. Crear BP en transaccion BP
  2. Asignar rol "Customer" (FLCU01)
  3. CVI genera automaticamente KUNNR en KNA1/KNB1
  4. Datos de area ventas se completan en KNVV via BP
```

### Tablas BP relevantes para SD
| Tabla | Descripcion | Equivalente ECC |
|-------|-------------|-----------------|
| BUT000 | Datos generales BP | KNA1 (parcial) |
| BUT020 | Direcciones | ADRC |
| BUT100 | Roles del BP | — |
| CVI_CUST_LINK | Mapeo BP <-> Cliente | — |
| KNA1 | Datos generales cliente | KNA1 (compatibility view) |
| KNB1 | Datos sociedad cliente | KNB1 (tabla real, via CVI) |
| KNVV | Datos area ventas | KNVV (tabla real, sin cambios) |
| KNVP | Interlocutores | KNVP (tabla real, sin cambios) |

### Queries MCP

```sql
-- Buscar cliente via BP
SELECT BP.PARTNER, BP.NAME_ORG1, BP.BU_GROUP, CVI.KUNNR
FROM BUT000 BP
JOIN CVI_CUST_LINK CVI ON BP.PARTNER = CVI.PARTNER_GUID
WHERE CVI.KUNNR = '{cliente}'

-- Verificar rol cliente
SELECT PARTNER, BU_GROUP, RLTYP FROM BUT100
WHERE PARTNER = '{bp_number}' AND RLTYP IN ('FLCU00', 'FLCU01')

-- Datos de area ventas (sin cambios, KNVV directo)
SELECT KUNNR, VKORG, VTWEG, SPART, KDGRP, BZIRK, ZTERM
FROM KNVV
WHERE KUNNR = '{cliente}' AND VKORG = '{org_ventas}'

-- Interlocutores del cliente
SELECT KUNNR, PARVW, KUNN2 FROM KNVP
WHERE KUNNR = '{cliente}' AND PARVW = 'RE'
```

---

## Gestion de credito — Tablas nuevas UKM*

### ECC vs S/4
```
ECC:  KNKK → Datos de credito del cliente (tabla principal)
      FD32 → Gestion limite de credito

S/4:  KNKK → SE MANTIENE (compatibility, lectura OK)
      SAP Credit Management (FSCM-CR) — tablas UKM*:
        UKM_CUST_MASTER  → Master de credito FSCM
        UKM_CASE         → Casos de bloqueo de credito
        UKM_SCORING      → Scores de credito
        UKM_LIMIT        → Limites de credito por segmento
        UKM_EXPOSURE     → Exposicion de credito calculada
```

### Queries MCP — Credito

```sql
-- Via KNKK (compatibility, funciona igual que ECC)
SELECT KUNNR, KLIMK, SKFOR, SKNUL FROM KNKK
WHERE KUNNR = '{cliente}' AND KKBER = '{area_credito}'

-- Via FSCM Credit Management (S/4 nativo)
SELECT PARTNER, CREDIT_SEGMENT, CREDIT_LIMIT, CREDIT_EXPOSURE
FROM UKM_LIMIT
WHERE PARTNER = '{bp_number}' AND CREDIT_SEGMENT = '{segmento}'

-- Casos de bloqueo activos
SELECT CASE_ID, PARTNER, STATUS, AMOUNT, CREATED_ON FROM UKM_CASE
WHERE PARTNER = '{bp_number}' AND STATUS = 'OPEN'
```

---

## PRCD_ELEMENTS — Condiciones de documento en S/4HANA

```
ECC:  KONV → tabla real de condiciones en documentos SD
S/4:  PRCD_ELEMENTS → tabla unica de condiciones de documento (reemplaza KONV)
      KONV → COMPATIBILITY VIEW sobre PRCD_ELEMENTS (lectura OK, escritura NO)
      SAP Note 2220005.

PRCD_ELEMENTS campos clave:
  KNUMV    → Handle de condiciones del documento (igual que KONV)
  KPOSN    → Posicion
  STUNR    → Step number
  ZAESSION → Sesion de calculo (nuevo en S/4)
  KSCHL    → Tipo de condicion
  KBETR    → Valor/porcentaje
  KWERT    → Importe
  WAERS    → Moneda

Impacto en custom code:
  SELECT FROM KONV → funciona (compatibility view, lectura OK)
  INSERT/UPDATE/DELETE INTO KONV → FALLA (dump en S/4)
  Codigo Z que escribe en KONV → migrar a PRCD_ELEMENTS o usar APIs
```

### Query MCP — Condiciones de precio de un pedido

```sql
-- OPCION A: Via PRCD_ELEMENTS (S/4 nativo, recomendado)
SELECT PE.KSCHL, PE.KWERT, PE.KBETR, PE.WAERS, T685T.VTEXT
FROM VBAK
JOIN PRCD_ELEMENTS PE ON VBAK.KNUMV = PE.KNUMV
LEFT JOIN T685T ON PE.KSCHL = T685T.KSCHL AND T685T.SPRAS = 'E'
WHERE VBAK.VBELN = '{pedido}'
ORDER BY PE.STUNR

-- OPCION B: Via KONV (compatibility view — lectura OK, menos eficiente)
SELECT KONV.KSCHL, KONV.KWERT, KONV.KBETR, KONV.WAERS
FROM VBAK
JOIN KONV ON VBAK.KNUMV = KONV.KNUMV
WHERE VBAK.VBELN = '{pedido}'
ORDER BY KONV.STUNR
```

---

## Compatibility Views — Resumen completo SD

| Tabla ECC | Estado en S/4 | Alternativa nativa S/4 | Notas |
|-----------|---------------|----------------------|-------|
| BSEG | Compatibility view | ACDOCA | Lento en grandes volumenes |
| BSID | Compatibility view | ACDOCA (AUGBL='') | Partidas abiertas cliente |
| BSAD | Compatibility view | ACDOCA (AUGBL<>'') | Partidas compensadas cliente |
| BSIS/BSAS | Eliminadas | ACDOCA | NO EXISTEN en S/4 |
| MKPF | Compatibility view | MATDOC | Cabecera doc material |
| MSEG | Compatibility view | MATDOC | Posiciones doc material |
| KNA1 | Compatibility view | BUT000 + CVI_CUST_LINK | Lectura OK, INSERT NO |
| KONV | Compatibility view | PRCD_ELEMENTS | Lectura OK, escritura NO. SAP Note 2220005 |
| VBUK | Eliminada (no poblada) | VBAK/LIKP/VBRK | Status fields absorbidos. SAP Note 2198647 |
| VBUP | Eliminada (no poblada) | VBAP/LIPS | Status fields absorbidos. SAP Note 2267306 |

---

## Tablas eliminadas en S/4HANA relevantes para SD

| Tabla ECC | Motivo eliminacion | Alternativa S/4 |
|-----------|-------------------|-----------------|
| BSIS/BSAS | Partidas GL | ACDOCA |
| BSID/BSAD | Partidas clientes | ACDOCA (compatibility views) |
| GLT0 | Saldos GL | ACDOCA agregado |
| COEP | Partidas CO | ACDOCA (columnas CO_*) |
| S001-S999 | LIS/SIS estadisticas | Embedded Analytics CDS |
| MC*** tables | SIS estadisticas ventas | CDS views analiticas SD |
| VBKL | Colectivos | Funcionalidad simplificada |
| VAKPA | Indice docs ventas por interlocutor | SELECT directo de VBAK+VBPA |
| VAPMA | Indice posiciones ventas por material | SELECT directo de VBAP |
| VLKPA | Indice entregas por interlocutor | SELECT directo de LIKP+VBPA |
| VLPMA | Indice posiciones entrega por material | SELECT directo de LIPS |
| VRKPA | Indice facturas por interlocutor | SELECT directo de VBRK |
| VRPMA | Indice posiciones factura por material | SELECT directo de VBRP |

---

## Impacto en codigo custom SD

### Regla de oro
```
1. SELECT desde compatibility views → FUNCIONA (pero puede ser lento)
2. INSERT/UPDATE en compatibility views (KNA1, BSEG...) → FALLA (dump)
3. Reports custom sobre BSID/BSAD → migrar a ACDOCA para rendimiento
4. BAPIs SD (BAPI_SALESORDER_*, BAPI_DELIVERY_*, BAPI_BILLINGDOC_*) → SIGUEN FUNCIONANDO
5. BADIs SD -> SIGUEN EXISTIENDO (BAdI_SD_SALES_*)
6. PERFORM en include Z -> CUIDADO con includes eliminados/cambiados
```

### Verificacion de codigo SD
```
Transaccion SYCM → Custom Code Migration Worklist
  - Detecta uso de BSEG, BSID, BSAD, KNA1 (INSERT), MKPF/MSEG en codigo Z
  - Clasifica por criticidad: error/warning
  - Sugiere alternativa S/4

Transaccion SCI → Code Inspector
  - Check "S/4HANA Readiness" (variante estandar SAP)
  - Detecta tablas eliminadas, funciones obsoletas, SELECT con tablas LIS
```

### Ejemplos de migracion

```abap
" ECC: leer partidas abiertas cliente
SELECT * FROM BSID INTO TABLE @DATA(lt_bsid)
  WHERE KUNNR = @lv_kunnr AND BUKRS = @lv_bukrs.

" S/4: via ACDOCA (fuente de verdad)
SELECT belnr, budat, hsl, ksl, augbl
  FROM acdoca INTO TABLE @DATA(lt_acdoca)
  WHERE kunnr = @lv_kunnr AND koart = 'D'
    AND rldnr = '0L' AND augbl = ''.

" ECC: movimientos por PGI de entrega
SELECT mkpf~mblnr mkpf~budat mseg~matnr mseg~menge
  FROM mkpf JOIN mseg ON mkpf~mblnr = mseg~mblnr AND mkpf~mjahr = mseg~mjahr
  INTO TABLE @DATA(lt_mkpf_mseg)
  WHERE mseg~vbeln = @lv_entrega.

" S/4: via MATDOC (1 tabla, mas eficiente)
SELECT mblnr, budat, matnr, menge, vbeln_im
  FROM matdoc INTO TABLE @DATA(lt_matdoc)
  WHERE vbeln_im = @lv_entrega AND bwart = '601'.
```

---

## Nuevos campos S/4HANA en tablas SD

### VBAK — Nuevos campos relevantes
```
VBAK-ABAP_LANGUAGE_VERSION  → Version lenguaje ABAP del objeto
VBAK-PRSDT_CONDS_CHANGED    → Indicator condiciones recalculadas (S/4 2022+)
```

### VBRK — Nuevos campos
```
VBRK-SFAKN  → Factura con Output Management 2.0 (referencia output)
```

### LIPS — Nuevos campos
```
LIPS-VBELV_IM  → Referencia al MATDOC generado por PGI (directo en posicion)
```
