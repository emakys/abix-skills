# Configuracion de Impuestos FI

## Resumen

La configuracion de impuestos en SAP FI abarca el esquema de calculo (Tax Procedure), codigos de impuestos (FTXP), determinacion de cuentas (OB40), retencion en la fuente (Withholding Tax) y reporting fiscal. En S/4HANA se recomienda el esquema de retencion extendido (Extended Withholding Tax) y se incorporan CDS views y apps Fiori para reporting fiscal.

---

## Tax Procedure — Esquema de Calculo (OBYZ)

### SPRO Path
```
SPRO → Gestion financiera → Parametrizaciones basicas de gestion financiera →
  Impuestos sobre el volumen de negocios → Calculo →
  Definir esquemas de calculo (OBYZ)
```

### Esquemas por Pais

| Esquema | Pais | Descripcion |
|---------|------|-------------|
| TAXD | USA | US Sales Tax / Use Tax |
| TAXEU | Europa | IVA europeo (intra/extracomunitario) |
| TAXBR | Brasil | ICMS, IPI, PIS, COFINS, ISS |
| TAXCO | Colombia | IVA, Retefuente, ReteICA, ReteCREE |
| TAXMX | Mexico | IVA 16%, IEPS, ISR retenido |
| TAXAR | Argentina | IVA 21%, percepciones, retenciones |
| TAXCL | Chile | IVA 19% |
| TAXPE | Peru | IGV 18%, detracciones, retenciones |
| TAXIN | India | GST (CGST, SGST, IGST) |
| TAXDE | Alemania | Vorsteuer / Umsatzsteuer |

### Asignacion Esquema a Pais
```
SPRO → Gestion financiera → Parametrizaciones basicas →
  Impuestos → Parametrizaciones basicas →
  Asignar esquema de calculo a pais (OBBG)
```

---

## Codigos de Impuesto (FTXP)

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| FTXP | Definir codigos de impuesto |
| FQ01 | Crear excepcion impuesto |
| OBCL | Asignar codigos a jurisdiccion (USA) |

### Tipos de Codigos

| Tipo | Prefijo Tipico | Descripcion | Ejemplo |
|------|----------------|-------------|---------|
| Input Tax (soportado) | I* / V* | IVA de compras (deducible) | I1 = IVA 21% compras |
| Output Tax (repercutido) | O* / A* | IVA de ventas | O1 = IVA 21% ventas |
| No deducible | N* | Porcion no deducible a coste | N1 = IVA 50% no deducible |
| Exento | E* / 0* | Operaciones exentas | E0 = Exento |
| Intracomunitario | U* | Adquisicion intra-UE | U1 = IVA intra-UE |
| Importacion | M* | IVA de importacion | M1 = IVA importacion |

### Campos de Codigo de Impuesto

| Campo | Descripcion |
|-------|-------------|
| MWSKZ | Clave indicador impuestos |
| KSCHL | Clase de condicion |
| MWART | Tipo de impuesto (V=soportado, A=repercutido) |
| Porcentaje | Tipo impositivo |
| Account Key | Clave para determinacion cuenta (VST, MWS, NVV, etc.) |

### SPRO Path
```
SPRO → Gestion financiera → Parametrizaciones basicas →
  Impuestos sobre el volumen de negocios → Calculo →
  Definir codigos de impuesto para ventas y compras (FTXP)
```

---

## Determinacion de Cuentas de Impuestos (OB40)

### Cuentas por Account Key

| Account Key | Descripcion | Cuenta Tipica |
|-------------|-------------|---------------|
| VST | IVA soportado (deducible) | 1720000 |
| MWS | IVA repercutido | 2120000 |
| NVV | IVA no deducible | Va a coste (no tiene cuenta propia) |
| ESA | Adquisicion intra-UE (soportado) | 1720010 |
| ESE | Adquisicion intra-UE (repercutido) | 2120010 |
| MW1 | Output tax 1 (tasa reducida) | 2120001 |
| MW2 | Output tax 2 (tasa super-reducida) | 2120002 |
| VS1 | Input tax 1 (tasa reducida) | 1720001 |

### SPRO Path
```
SPRO → Gestion financiera → Parametrizaciones basicas →
  Impuestos sobre el volumen de negocios → Contabilizacion →
  Definir ctas de mayor para contab.automatica de impuestos (OB40)
```

---

## Withholding Tax — Retencion en la Fuente

### Clasico vs Extendido

| Aspecto | Clasico (EWT) | Extendido (Extended WHT) |
|---------|---------------|--------------------------|
| Momento | Solo al pago | Al facturar y/o al pagar |
| Multiples tipos | No | Si (varios tipos por documento) |
| Certificados | Limitado | Completo |
| S/4HANA | Deprecado | Recomendado |
| Transaccion config | OBAW | OBWI |

### Configuracion Extendida

#### Paso 1: Tipo de Retencion (OBWI)

| Campo | Descripcion |
|-------|-------------|
| Tipo WHT | Identificador (ej: W1, W2) |
| Momento | Al facturar (invoice) / al pagar (payment) |
| Base calculo | Importe bruto / neto / impuesto |
| Acumulacion | Si aplica bases acumuladas |
| Certificado | Si genera certificado de retencion |

#### Paso 2: Codigo de Retencion

| Campo | Descripcion |
|-------|-------------|
| Codigo WHT | Subclave del tipo (ej: W1-01) |
| Porcentaje | Tasa de retencion |
| Base reducida | Porcentaje de base gravable |
| Umbral | Importe minimo para retener |
| Exento desde | Fecha de exencion |

#### Paso 3: Maestro de Proveedor (LFB1)

| Campo | Descripcion |
|-------|-------------|
| WHT Type | Tipo de retencion asignado |
| WHT Code | Codigo de retencion |
| Liable | Sujeto a retencion (X) |
| Exemption number | Numero de certificado de exencion |
| Exemption rate | Porcentaje exento |
| Valid from/to | Vigencia de la exencion |

### SPRO Path — Withholding Tax
```
SPRO → Gestion financiera → Parametrizaciones basicas →
  Retencion ampliada →
  Definir tipos de retencion para facturacion (OBWI)
  Definir codigos de retencion para facturacion
  Definir ctas de mayor para retencion ampliada
  Definir certificados de retencion
```

---

## Impuestos Especificos por Pais

### LATAM — Ejemplos

| Pais | Impuesto | Config Especifica |
|------|----------|-------------------|
| Mexico | IVA 16% + Retencion IVA 2/3 + ISR | TAXMX + WHT types para retenciones |
| Colombia | IVA + Retefuente + ReteICA | TAXCO + condition-based + WHT |
| Brasil | ICMS + IPI + PIS + COFINS | TAXBR + Nota Fiscal (J1B*) |
| Argentina | IVA 21% + Percepciones IIBB | TAXAR + percepciones por jurisdiccion |
| Peru | IGV 18% + Detracciones | TAXPE + detraccion automatica |
| Chile | IVA 19% | TAXCL estandar |

### USA — Jurisdiction Codes

```
SPRO → Gestion financiera → Parametrizaciones basicas →
  Impuestos → Parametrizaciones basicas →
  USA → Definir codigos de jurisdiccion (TXJCD)
```

| Concepto | Descripcion |
|----------|-------------|
| TXJCD | Codigo de jurisdiccion fiscal (estado+condado+ciudad) |
| Tax Rate | Tasa por jurisdiccion |
| Vertex/Sabrix | Integracion con motor fiscal externo |

---

## Tax Reporting

### Reportes Estandar

| Transaccion / Reporte | Descripcion |
|------------------------|-------------|
| S_ALR_87012357 | Declaracion previa IVA repercutido |
| S_ALR_87012359 | Declaracion previa IVA soportado |
| S_ALR_87012360 | Listado codigos de impuesto |
| RFUMSV00 | Declaracion recapitulativa IVA |
| S_P00_07000134 | Certificado de retencion |
| J_1EWHT_CERT | Certificado WHT (paises especificos) |

### S/4HANA — CDS Views y Apps Fiori

| CDS View / App | Descripcion |
|----------------|-------------|
| I_TaxItems | Items de impuesto (vista analitica) |
| I_WithholdingTaxItem | Items de retencion |
| F2548 | Tax Reporting Cockpit |
| F4565 | Tax Returns Overview |
| F0722 | Withholding Tax Reporting |

---

## Tablas de Impuestos

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T007A | Codigos de impuesto | KALSM, MWSKZ, MWART |
| T007B | Porcentajes de impuesto | KALSM, MWSKZ, KSCHL |
| T007S | Textos codigos de impuesto | KALSM, MWSKZ, SPRAS |
| T059Z | Codigos de retencion | LAND1, WITHT, WT_WITHCD |
| T059P | Tipos de retencion | LAND1, WITHT |
| T059Q | Cuentas de retencion | BUKRS, WITHT, WT_WITHCD, HKONT |
| A003 | Registros de condicion de impuesto | AESSION, MWSKZ, KSCHL |
| WITH_ITEM | Partidas de retencion (S/4) | BUKRS, BELNR, GJAHR, BUZEI |
| T030K | Cuentas contab. automatica impuestos | KTOPL, KTOSL |

---

## Consultas MCP

```sql
-- Importes de impuesto por codigo y periodo
SELECT MWSKZ, KTOSL, RHCUR,
       SUM(HSL) AS IMPORTE_IMPUESTO,
       COUNT(*) AS NUM_POSICIONES
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND MWSKZ <> ''
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND RLDNR = '0L'
GROUP BY MWSKZ, KTOSL, RHCUR
ORDER BY MWSKZ

-- Retencion acumulada por proveedor
SELECT LIFNR, MWSKZ, RHCUR,
       SUM(HSL) AS TOTAL_RETENCION,
       COUNT(DISTINCT BELNR) AS NUM_DOCS
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KTOSL IN ('WIT', 'W01', 'W02')
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND RLDNR = '0L'
GROUP BY LIFNR, MWSKZ, RHCUR
ORDER BY LIFNR

-- Verificar cuentas de impuesto configuradas
SELECT KTOPL, KTOSL, MWSKZ, HKONT
FROM T030K
WHERE KTOPL = '{chart_of_accounts}'
  AND KTOSL IN ('VST', 'MWS', 'ESA', 'ESE', 'NVV')
ORDER BY KTOSL, MWSKZ

-- IVA repercutido vs soportado del periodo
SELECT CASE WHEN KTOSL IN ('MWS','MW1','MW2','ESE') THEN 'OUTPUT'
            WHEN KTOSL IN ('VST','VS1','ESA') THEN 'INPUT'
            ELSE 'OTHER' END AS TAX_TYPE,
       MWSKZ, RHCUR,
       SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND MWSKZ <> ''
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND RLDNR = '0L'
GROUP BY CASE WHEN KTOSL IN ('MWS','MW1','MW2','ESE') THEN 'OUTPUT'
              WHEN KTOSL IN ('VST','VS1','ESA') THEN 'INPUT'
              ELSE 'OTHER' END,
         MWSKZ, RHCUR
ORDER BY TAX_TYPE, MWSKZ

-- WHT items por proveedor (tabla dedicada S/4HANA)
SELECT BUKRS, BELNR, GJAHR, BUZEI, LIFNR,
       WITHT, WT_WITHCD, WT_QSSHH, WT_QBSHH, WAERS
FROM WITH_ITEM
WHERE BUKRS = '{company_code}'
  AND GJAHR = '{fiscal_year}'
  AND LIFNR = '{vendor}'
ORDER BY BELNR, BUZEI
```

---

## Errores Comunes

| Error | Causa | Solucion |
|-------|-------|----------|
| Codigo de impuesto no valido para procedimiento | Codigo no asignado al esquema del pais | Verificar FTXP y OBBG |
| Cuenta no encontrada en OB40 | Falta account key en determinacion de cuentas | Mantener OB40 con la clave correspondiente |
| Umbral de retencion excedido | Acumulado supera el umbral configurado | Verificar T059Z umbrales, ajustar si aplica |
| WHT no se calcula | Proveedor no marcado como sujeto a retencion | Verificar LFB1 → datos de retencion |
| Error porcentaje impuesto | Vigencia del porcentaje expirada | Verificar FTXP → porcentajes y fechas |
| Doble imposicion en intra-UE | Falta config ESA/ESE en procedure | Verificar esquema TAXEU tiene lineas ESA/ESE |
| Retencion al facturar y al pagar duplicada | Tipo WHT configurado en ambos momentos | Separar en tipos distintos (invoice vs payment) |
| Codigo jurisdiccion no encontrado | TXJCD no definido para la combinacion | Crear en OBCP o via tabla TTXJT |
