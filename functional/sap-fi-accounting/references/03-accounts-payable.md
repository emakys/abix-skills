# Accounts Payable (FI-AP) — Cuentas por Pagar

## Dato Maestro de Proveedor en S/4HANA

En S/4HANA, el Business Partner (BP) es obligatorio. El proveedor se crea como BP con rol FLVN00 y se sincroniza con LFA1/LFB1.

### Estructura de tablas maestro proveedor

| Tabla | Nivel | Contenido |
|-------|-------|-----------|
| BUT000 | General BP | Nombre, direccion, NIF |
| BUT020 | Direcciones BP | Direcciones multiples |
| LFA1 | General proveedor | Datos generales (pais, moneda, idioma) |
| LFB1 | Sociedad | Cuenta reconciliacion, condiciones pago, retencion |
| LFB5 | Sociedad - Withholding | Datos retencion ampliada |
| LFBK | Banco | Datos bancarios del proveedor |
| LFM1 | Organizacion compras | Datos de compras |

### Consulta MCP — Proveedores con cuenta reconciliacion

```sql
SELECT A.LIFNR, A.NAME1, A.LAND1, B.BUKRS, B.AKONT, B.ZTERM, B.ZWELS, B.LNRZE
FROM LFA1 AS A
INNER JOIN LFB1 AS B ON A.LIFNR = B.LIFNR
WHERE B.BUKRS = '1000'
  AND A.LOEVM = ''
ORDER BY A.LIFNR
```

---

## Grupos de Cuentas Proveedor (T077K)

| Grupo | Descripcion | Rango |
|-------|-------------|-------|
| KRED | Acreedor nacional | 100000-199999 |
| 0001 | Acreedor general | 200000-299999 |
| LIEF | Proveedor one-time | 600000-699999 |
| CPD | Cuentas por pagar diversas | 700000-799999 |

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Cuentas de acreedor > Datos maestros > Preparar creacion datos maestros acreedores > Definir grupos de cuentas`

---

## Cuenta de Reconciliacion (LFB1-AKONT)

Vincula el subledger de acreedores con el libro mayor. Cada contabilizacion en AP actualiza simultaneamente la cuenta de reconciliacion en GL.

### Consulta MCP — Verificar cuentas reconciliacion

```sql
SELECT DISTINCT B.AKONT, T.TXT50
FROM LFB1 AS B
INNER JOIN SKAT AS T ON T.SAKNR = B.AKONT AND T.SPRAS = 'S' AND T.KTOPL = 'CALA'
WHERE B.BUKRS = '1000'
ORDER BY B.AKONT
```

---

## Registro de Facturas

### Transacciones de entrada

| Txn | Descripcion | Doc Type | Posting Keys |
|-----|-------------|----------|--------------|
| FB60 | Factura acreedor simple | KR | 31 (cr) / 40 (db) |
| MIRO | Factura con referencia pedido | RE | 31 / 86 |
| FB65 | Nota credito acreedor | KG | 21 (db) / 50 (cr) |
| FV60 | Factura preliminar | KR | 31 / 40 |

### Consulta MCP — Facturas proveedor en ACDOCA

```sql
SELECT BELNR, BUZEI, BUDAT, BLDAT, RACCT, LIFNR, RHCUR, HSL, DRCRK,
       BLART, XBLNR, SGTXT, ZUESSION_NETTO
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'K'
  AND BLART IN ('KR', 'RE')
  AND GJESSION = '2026'
ORDER BY BUDAT DESC, BELNR
```

---

## Anticipos (Down Payments)

### Flujo completo

| Paso | Txn | Descripcion | Doc Type |
|------|-----|-------------|----------|
| 1 | F-47 | Solicitud de anticipo | - |
| 2 | F-48 | Contabilizar anticipo | KZ |
| 3 | FB60 | Factura final | KR |
| 4 | F-54 | Compensar anticipo contra factura | AB |

### Consulta MCP — Anticipos pendientes proveedor

```sql
SELECT BELNR, BUZEI, LIFNR, BUDAT, HSL, RHCUR, AUGBL, AUGDT
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'K'
  AND UMSKZ = 'A'
  AND AUGBL = ''
ORDER BY LIFNR, BUDAT
```

---

## Condiciones de Pago (T052)

| Campo | Descripcion |
|-------|-------------|
| ZTERM | Clave condicion pago |
| ZTAGG | Dias neto |
| ZTAG1 | Dias descuento 1 |
| ZSK1 | Porcentaje descuento 1 |
| ZTAG2 | Dias descuento 2 |
| ZSK2 | Porcentaje descuento 2 |

### Condiciones estandar comunes

| ZTERM | Descripcion | Neto | Desc1 | Desc2 |
|-------|-------------|------|-------|-------|
| 0001 | Inmediato | 0 | - | - |
| ZB01 | 14d 2%, 30d neto | 30 | 14d/2% | - |
| ZB02 | 10d 3%, 20d 2%, 30d neto | 30 | 10d/3% | 20d/2% |
| ZN30 | 30 dias neto | 30 | - | - |
| ZN60 | 60 dias neto | 60 | - | - |

### Consulta MCP — Condiciones de pago

```sql
SELECT ZTERM, TEXT1, ZTAG1, ZSK1, ZTAG2, ZSK2, ZTAGG
FROM T052U
INNER JOIN T052 ON T052U.ZTERM = T052.ZTERM
WHERE T052U.SPESSION = 'S'
ORDER BY ZTERM
```

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Operaciones comerciales > Entrada facturas > Actualizar condiciones de pago`

---

## Retencion Fiscal (Withholding Tax)

### Tipos en S/4HANA

| Tipo | Descripcion |
|------|-------------|
| Clasico | Una sola retencion por linea (obsoleto) |
| Ampliado | Multiples retenciones por linea, certificados, reportes |

### Tablas clave

| Tabla | Contenido |
|-------|-----------|
| LFBW | Config retencion por proveedor/sociedad |
| T059Z | Tipos retencion |
| T059P | Codigos retencion |
| WITH_ITEM | Posiciones de retencion |

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Retencion ampliada > Definir tipos de retencion para contabilizacion factura`

---

## Programa de Pagos Automaticos — F110

### Parametros principales

| Parametro | Descripcion |
|-----------|-------------|
| Fecha ejecucion | Fecha del run de pagos |
| Fecha identificacion | ID unico del run |
| Sociedad | Sociedades a procesar |
| Vias pago | T (transferencia), S (cheque), W (letra) |
| Fecha proximo pago | Fecha limite para seleccion |

### Pasos F110

| Paso | Descripcion |
|------|-------------|
| 1 - Parametros | Definir fechas, sociedades, vias pago |
| 2 - Propuesta | Seleccionar partidas abiertas elegibles |
| 3 - Revision | Verificar propuesta, excepciones |
| 4 - Ejecucion | Generar pagos y documentos contables |
| 5 - Impresion | Generar medios de pago (cheques, transferencias) |

---

## Partidas Abiertas y Compensacion

### Consulta MCP — Partidas abiertas proveedor

```sql
SELECT LIFNR, BELNR, BUZEI, BUDAT, BLDAT, HSL, RHCUR, ZFBDT, ZTERM, BLART, XBLNR
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'K'
  AND AUGBL = ''
  AND RLDNR = '0L'
ORDER BY LIFNR, BUDAT
```

### Consulta MCP — Aging de cuentas por pagar

```sql
SELECT LIFNR,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') <= 30 THEN HSL ELSE 0 END) AS D0_30,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') BETWEEN 31 AND 60 THEN HSL ELSE 0 END) AS D31_60,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') BETWEEN 61 AND 90 THEN HSL ELSE 0 END) AS D61_90,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') > 90 THEN HSL ELSE 0 END) AS D90_PLUS,
  SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '1000' AND KOART = 'K' AND AUGBL = '' AND RLDNR = '0L'
GROUP BY LIFNR
ORDER BY TOTAL
```

### Consulta MCP — Historial de pagos proveedor

```sql
SELECT BELNR, BUZEI, BUDAT, HSL, RHCUR, BLART, AUGBL, AUGDT
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND LIFNR = '0000001000'
  AND KOART = 'K'
  AND BLART IN ('KZ', 'ZP')
  AND GJESSION = '2026'
  AND RLDNR = '0L'
ORDER BY BUDAT DESC
```

---

## Compensacion GR/IR — Cuenta de Transito

La cuenta GR/IR (Goods Receipt / Invoice Receipt) registra la diferencia temporal entre la entrada de mercancias y la recepcion de factura.

### Diagnostico

| Txn | Descripcion |
|-----|-------------|
| F.19 | Reclasificacion GR/IR para balance |
| MR11 | Mantenimiento cuenta GR/IR |
| FAGLB03 | Saldo cuenta GR/IR |

### Consulta MCP — Saldo cuenta GR/IR

```sql
SELECT RACCT, SUM(HSL) AS SALDO, RHCUR
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND RACCT = '0000191100'
  AND RLDNR = '0L'
  AND GJESSION = '2026'
GROUP BY RACCT, RHCUR
```

---

## Errores comunes FI-AP

| Error | Causa | Solucion |
|-------|-------|----------|
| F5 155 | Periodo cerrado | Abrir periodo OB52 |
| F5 312 | Campo obligatorio faltante | Revisar field status |
| KI 235 | Factura duplicada (XBLNR) | Verificar referencia, usar FB60 con otro XBLNR |
| F5 003 | Proveedor no existe en sociedad | Ampliar BP a la sociedad |
| M8 889 | Diferencia cantidad MIRO | Verificar GR vs factura |
| FZ 003 | Bloqueo de pago activo | Revisar LFB1-ZAHLS (payment block) |
| F5 201 | Doc no cuadra | Verificar importes debe/haber + impuesto |
