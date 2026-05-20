# Accounts Receivable (FI-AR) — Cuentas por Cobrar

## Dato Maestro de Cliente en S/4HANA

En S/4HANA, el Business Partner (BP) es obligatorio. El cliente se crea como BP con rol FLCU00 y se sincroniza automaticamente con KNA1/KNB1.

### Estructura de tablas maestro cliente

| Tabla | Nivel | Contenido |
|-------|-------|-----------|
| BUT000 | General BP | Nombre, direccion, NIF |
| BUT020 | Direcciones BP | Direcciones multiples |
| KNA1 | General cliente | Datos generales (pais, moneda, grupo cuentas) |
| KNB1 | Sociedad | Cuenta reconciliacion, condiciones pago, dunning |
| KNB5 | Sociedad - Dunning | Datos de reclamacion |
| KNBK | Banco | Datos bancarios del cliente |
| KNVV | Area ventas | Datos comerciales (org ventas, canal, sector) |

### Consulta MCP — Clientes con datos de sociedad

```sql
SELECT A.KUNNR, A.NAME1, A.LAND1, A.ORT01,
       B.BUKRS, B.AKONT, B.ZTERM, B.MAHNA, B.ZWELS
FROM KNA1 AS A
INNER JOIN KNB1 AS B ON A.KUNNR = B.KUNNR
WHERE B.BUKRS = '1000'
  AND A.LOEVM = ''
ORDER BY A.KUNNR
```

---

## Grupos de Cuentas Cliente (T077D)

| Grupo | Descripcion | Rango numeros |
|-------|-------------|---------------|
| DEBI | Deudor nacional | 100000-199999 |
| 0001 | Deudor general | 200000-299999 |
| CPD | Deudor ocasional (one-time) | 600000-699999 |
| KUNA | Deudor intercompany | 800000-899999 |

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Cuentas de deudor > Datos maestros > Preparar creacion datos maestros deudores > Definir grupos de cuentas con formato de pantalla`

---

## Cuenta de Reconciliacion (KNB1-AKONT)

Vincula el subledger de deudores con el libro mayor. Cada contabilizacion en AR actualiza simultaneamente la cuenta de reconciliacion en GL.

### Consulta MCP — Cuentas reconciliacion AR

```sql
SELECT DISTINCT B.AKONT, T.TXT50, COUNT(*) AS NUM_CLIENTES
FROM KNB1 AS B
INNER JOIN SKAT AS T ON T.SAKNR = B.AKONT AND T.SPRAS = 'S' AND T.KTOPL = 'CALA'
WHERE B.BUKRS = '1000'
GROUP BY B.AKONT, T.TXT50
ORDER BY B.AKONT
```

---

## Registro de Facturas y Notas de Credito

### Transacciones principales AR

| Txn | Descripcion | Doc Type | Posting Keys |
|-----|-------------|----------|--------------|
| FB70 | Factura deudor simple | DR | 01 (db) / 50 (cr) |
| VF01 | Factura desde facturacion SD | RV | 01 / 50 |
| F-22 | Contabilizacion factura deudor | DR | 01 / 50 |
| FB75 | Nota credito deudor | DG | 11 (cr) / 40 (db) |
| FV70 | Factura preliminar deudor | DR | 01 / 50 |

### Consulta MCP — Facturas emitidas a clientes

```sql
SELECT BELNR, BUZEI, BUDAT, BLDAT, RACCT, KUNNR, RHCUR, HSL, DRCRK,
       BLART, XBLNR, SGTXT
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'D'
  AND BLART IN ('DR', 'RV')
  AND GJESSION = '2026'
  AND RLDNR = '0L'
ORDER BY BUDAT DESC, BELNR
```

---

## Anticipos de Cliente (Down Payments)

### Flujo completo

| Paso | Txn | Descripcion | Doc Type |
|------|-----|-------------|----------|
| 1 | F-37 | Solicitud de anticipo | - |
| 2 | F-29 | Contabilizar anticipo recibido | DZ |
| 3 | FB70 | Factura final al cliente | DR |
| 4 | F-39 | Compensar anticipo contra factura | AB |

### Consulta MCP — Anticipos recibidos pendientes

```sql
SELECT BELNR, BUZEI, KUNNR, BUDAT, HSL, RHCUR, AUGBL, AUGDT
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'D'
  AND UMSKZ = 'A'
  AND AUGBL = ''
  AND RLDNR = '0L'
ORDER BY KUNNR, BUDAT
```

---

## Cobros y Compensacion

### Transacciones de cobro

| Txn | Descripcion | Uso |
|-----|-------------|-----|
| F-28 | Entrada de pago recibido | Cobro con seleccion de partidas |
| F-32 | Compensar partidas abiertas | Clearing sin nuevo pago |
| F-26 | Cobro con diferencia residual | Pago parcial, genera nuevo item |
| F-30 | Contabilizar con compensacion | Similar a F-28, mas flexible |

### Diferencias de pago

| Tipo | Descripcion | Tratamiento |
|------|-------------|-------------|
| Pago parcial | Cliente paga menos, partida original sigue abierta | F-28 con partial payment |
| Pago residual | Cliente paga menos, se crea nueva partida por la diferencia | F-26 residual item |
| Sobrepago | Cliente paga de mas | Contabilizar en cuenta de diferencias |
| Descuento | Cliente aplica descuento pronto pago | Automatico si esta en tolerancia |

### Tolerancias de pago (OBA3)

| Campo | Descripcion |
|-------|-------------|
| HESSION | Tolerancia grupo |
| RWBTR1 | Importe maximo ganancia permitida |
| RWBTR2 | Importe maximo perdida permitida |
| ANTEI1 | Porcentaje maximo ganancia |
| ANTEI2 | Porcentaje maximo perdida |

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Operaciones comerciales > Cobros > Diferencias de pago > Definir tolerancias`

---

## Partidas Abiertas y Aging

### Consulta MCP — Partidas abiertas cliente

```sql
SELECT KUNNR, BELNR, BUZEI, BUDAT, BLDAT, HSL, RHCUR, ZFBDT, ZTERM, BLART, XBLNR
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'D'
  AND AUGBL = ''
  AND RLDNR = '0L'
ORDER BY KUNNR, BUDAT
```

### Consulta MCP — Aging de cuentas por cobrar

```sql
SELECT KUNNR,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') <= 30 THEN HSL ELSE 0 END) AS D0_30,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') BETWEEN 31 AND 60 THEN HSL ELSE 0 END) AS D31_60,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') BETWEEN 61 AND 90 THEN HSL ELSE 0 END) AS D61_90,
  SUM(CASE WHEN DATS_DAYS_BETWEEN(ZFBDT, '20260515') > 90 THEN HSL ELSE 0 END) AS D90_PLUS,
  SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '1000' AND KOART = 'D' AND AUGBL = '' AND RLDNR = '0L'
GROUP BY KUNNR
ORDER BY TOTAL DESC
```

### Consulta MCP — DSO (Days Sales Outstanding) simplificado

```sql
SELECT
  SUM(CASE WHEN AUGBL = '' THEN HSL ELSE 0 END) AS AR_ABIERTO,
  SUM(CASE WHEN DRCRK = 'S' AND BUDAT >= '20260101' THEN HSL ELSE 0 END) AS VENTAS_YTD
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'D'
  AND RLDNR = '0L'
  AND GJESSION = '2026'
```

---

## Gestion de Credito — FD32 / UKM

### Credit Management clasico (FD32)

| Campo KNB1 | Descripcion |
|-------------|-------------|
| KLIMK | Limite de credito |
| SKESSION | Saldo total |
| CRESSION | Grupo riesgo credito |

### S/4HANA Credit Management (UKM)

| Txn | Descripcion |
|-----|-------------|
| UKM_MP | Datos maestros credito BP |
| UKM_CASE | Casos de credito |
| UKM_MY_DCISN | Decisiones pendientes |
| FD32 | Vista clasica (aun disponible) |

### Consulta MCP — Limites de credito

```sql
SELECT KUNNR, KLIMK, SKESSION, CTLPC
FROM KNKK
WHERE KKBER = '1000'
  AND KLIMK > 0
ORDER BY KLIMK DESC
```

---

## Reclamacion (Dunning) — F150

### Configuracion dunning

| Elemento | Tabla/Txn | Descripcion |
|----------|-----------|-------------|
| Procedimiento | T047 / OB61 | Define niveles, dias, textos |
| Area dunning | T047A | Area de reclamacion |
| Niveles | T047B | 1-9 niveles, dias entre cartas |
| Textos | T047E | Textos por nivel e idioma |
| Asignacion | KNB1-MAHNA | Procedimiento asignado al cliente |

### Consulta MCP — Estado dunning clientes

```sql
SELECT A.KUNNR, A.NAME1, B.MAHNA, B.MAESSION, B.MAHDT, B.MANSP
FROM KNA1 AS A
INNER JOIN KNB1 AS B ON A.KUNNR = B.KUNNR
WHERE B.BUKRS = '1000'
  AND B.MAESSION > 0
ORDER BY B.MAESSION DESC, A.KUNNR
```

### SPRO Path
`SPRO > Gestion financiera > Contabilidad deudores y acreedores > Operaciones comerciales > Reclamacion > Procedimiento reclamacion > Definir procedimientos reclamacion`

---

## Calculo de Intereses — F.52 / F.2B

| Txn | Descripcion |
|-----|-------------|
| F.52 | Calculo intereses sobre partidas (mora) |
| F.2B | Calculo intereses sobre saldos |
| OB46 | Definir indicador intereses |

### Consulta MCP — Partidas vencidas con dias mora

```sql
SELECT KUNNR, BELNR, BUDAT, ZFBDT, HSL, RHCUR,
       DATS_DAYS_BETWEEN(ZFBDT, '20260515') AS DIAS_MORA
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND KOART = 'D'
  AND AUGBL = ''
  AND RLDNR = '0L'
  AND ZFBDT < '20260515'
ORDER BY DIAS_MORA DESC
```

---

## Errores comunes FI-AR

| Error | Causa | Solucion |
|-------|-------|----------|
| F5 155 | Periodo cerrado | Abrir periodo en OB52 |
| FD 100 | Cliente bloqueado por credito | Revisar limite en FD32 o liberar en VKM1 |
| F5 003 | Cliente no existe en sociedad | Ampliar BP con rol FLCU00 a la sociedad |
| F5 312 | Campo obligatorio faltante | Revisar field status OBC4/OB41 |
| F-28 tolerance | Diferencia de pago fuera de tolerancia | Revisar OBA3, usar pago residual |
| FP 301 | Dunning area no configurada | Revisar T047A y asignacion en KNB1 |
| F5 201 | Documento no cuadra | Verificar must = haber, revisar impuestos |
| VF01 pricing | Error en precios al facturar | Revisar condiciones de precio en VK13 |

---

## Reportes principales AR

| Txn | Descripcion | Uso |
|-----|-------------|-----|
| FBL5N | Partidas individuales deudor | Detalle por cliente |
| FD10N | Saldo deudor | Balance por cliente |
| S_ALR_87012168 | Lista saldos deudores | Balance masivo |
| S_ALR_87012178 | Vencimientos deudores | Aging report |
| F.27 | Clientes con partidas vencidas | Diagnostico mora |
| F.28 | Lista maestra credito | Revision limites credito |
| F.30 | Analisis ABC clientes | Clasificacion por volumen |
