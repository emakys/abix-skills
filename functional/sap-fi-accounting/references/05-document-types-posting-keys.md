# Tipos de Documento y Claves de Contabilizacion

## Tipos de Documento (T003) — OBA7

Cada documento contable tiene un tipo que controla el rango de numeros, tipos de cuenta permitidos, y el tipo de documento de anulacion.

### Tipos de documento estandar FI

| Doc Type | Descripcion | Cuenta permitida | Reversal Type | Uso |
|----------|-------------|-----------------|---------------|-----|
| SA | Asiento contable GL | S (GL) | SA | Contabilizacion directa en mayor |
| KR | Factura acreedor | K+S | KG | Factura de proveedor |
| KG | Nota credito acreedor | K+S | KR | Abono de proveedor |
| KZ | Pago acreedor | K+S | KZ | Pago a proveedor |
| KA | Doc acreedor general | K+S | KA | Otros movimientos AP |
| DR | Factura deudor | D+S | DG | Factura a cliente |
| DG | Nota credito deudor | D+S | DR | Abono a cliente |
| DZ | Pago deudor | D+S | DZ | Cobro de cliente |
| DA | Doc deudor general | D+S | DA | Otros movimientos AR |
| AB | Asiento contable general | D+K+S+A | AB | Reclasificaciones, ajustes |
| AA | Amortizacion activos | A+S | AA | Amortizacion periodica |
| AF | Liquidacion activos | A+S | AF | Baja de activos |
| WE | Entrada mercancias | S | WA | Movimiento de mercancias |
| RE | Factura logistica (MIRO) | K+S | RN | Verificacion facturas MM |
| RV | Factura SD (billing) | D+S | RV | Facturacion comercial |

### Campos clave de T003

| Campo | Descripcion |
|-------|-------------|
| BLART | Tipo documento |
| LTEXT | Descripcion |
| NUMKR | Rango numeros interno |
| XKOAA | Tipo cuenta: A (activo fijo) |
| XKOAD | Tipo cuenta: D (deudor) |
| XKOAK | Tipo cuenta: K (acreedor) |
| XKOAS | Tipo cuenta: S (GL) |
| STESSION | Tipo doc anulacion |
| XNEG | Asiento negativo (storno) |

### Consulta MCP — Tipos de documento configurados

```sql
SELECT BLART, LTEXT, NUMKR, XKOAS, XKOAD, XKOAK, XKOAA, STESSION, XNEG
FROM T003
WHERE KTOPL = 'CALA'
ORDER BY BLART
```

### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Tipo de documento > Definir tipos de documento para documentos FI`

---

## Rangos de Numeros (FBN1) — Tabla NRIV

### Configuracion

| Campo | Descripcion |
|-------|-------------|
| OBJECT | Objeto numeracion (RF_BELEG) |
| NRRANGENR | Numero del intervalo |
| FROMNUMBER | Numero desde |
| TONUMBER | Numero hasta |
| INTERNFLAG | X = interno, ' ' = externo |
| FISCAL_YEAR | Dependiente de ejercicio |

### Rangos tipicos

| Intervalo | Desde | Hasta | Tipo | Doc Types |
|-----------|-------|-------|------|-----------|
| 01 | 0100000000 | 0199999999 | Interno | SA |
| 02 | 0200000000 | 0299999999 | Interno | KR, KG |
| 03 | 0300000000 | 0399999999 | Interno | DR, DG |
| 04 | 0400000000 | 0499999999 | Interno | KZ, DZ |
| 10 | 1000000000 | 1099999999 | Interno | AB |
| 19 | 5100000000 | 5199999999 | Interno | RE (MIRO) |
| 20 | 5200000000 | 5299999999 | Interno | RV (SD) |

### Consulta MCP — Rangos de numeracion

```sql
SELECT NRRANGENR, FROMNUMBER, TONUMBER, NRLEVEL, INTERNFLAG
FROM NRIV
WHERE OBJECT = 'RF_BELEG'
ORDER BY NRRANGENR
```

### Transaccion: FBN1
### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Tipo de documento > Definir rangos de numeros para documentos FI`

---

## Claves de Contabilizacion (TBSL) — OB41

Cada linea de un documento contable lleva una clave de contabilizacion que define: debe/haber, tipo de cuenta, y modificador de status de campo.

### Claves estandar

| PK | D/H | Tipo Cta | Descripcion |
|----|-----|----------|-------------|
| 01 | Debe | D (Deudor) | Factura deudor |
| 02 | Debe | D | Anulacion factura deudor |
| 05 | Debe | D | Cobro saliente (anticipo) |
| 06 | Debe | D | Cobro entrante (anulacion) |
| 09 | Haber | D | Nota cargo especial |
| 11 | Haber | D | Nota credito deudor |
| 15 | Debe | D | Pago entrante |
| 19 | Haber | D | Anulacion pago deudor |
| 21 | Debe | K (Acreedor) | Nota credito acreedor |
| 22 | Debe | K | Anulacion factura acreedor |
| 25 | Haber | K | Pago saliente |
| 29 | Debe | K | Anulacion pago acreedor |
| 31 | Haber | K | Factura acreedor |
| 34 | Haber | K | Nota debito especial |
| 39 | Debe | K | Anulacion nota credito |
| 40 | Debe | S (GL) | Debe en cuenta mayor |
| 50 | Haber | S (GL) | Haber en cuenta mayor |
| 70 | Debe | A (Activo) | Alta activo fijo - debe |
| 75 | Haber | A (Activo) | Baja activo fijo - haber |
| 81 | Debe | S | Variacion inventario |
| 86 | Debe | S | Entrada mercancias |
| 91 | Haber | S | Ajuste inventario |
| 96 | Haber | S | Movimiento material |

### Campos clave de TBSL

| Campo | Descripcion |
|-------|-------------|
| BSCHL | Clave contabilizacion |
| SHKZG | Indicador D/H (S=debe, H=haber) |
| KOESSION | Tipo de cuenta (D, K, S, A, M) |
| FESSION1-FESSION5 | Modificadores status campo |
| XOPVW | Gestion partidas abiertas |
| XNEGP | Contabilizacion negativa |
| UMSKZ | Indicador operacion especial |

### Consulta MCP — Claves de contabilizacion

```sql
SELECT BSCHL, SHKZG, KOESSION, XOPVW, XNEGP, UMSKZ
FROM TBSL
ORDER BY BSCHL
```

---

## Logica de Interseccion de Field Status

El status final de cada campo en la pantalla de contabilizacion se calcula como interseccion de 3 fuentes:

### Las 3 fuentes

| Fuente | Config en | Tabla |
|--------|-----------|-------|
| 1. Variante transaccion | OB41 (por doc type) | T081S |
| 2. Grupo cuenta mayor | OBC4 (por cuenta GL) | T004F |
| 3. Clave contabilizacion | OB41 (por posting key) | TBSL |

### Regla de interseccion

| Prioridad | Resultado |
|-----------|-----------|
| 1 (maxima) | Suppress (ocultar) — gana siempre |
| 2 | Required (obligatorio) — gana sobre optional |
| 3 | Optional (opcional) — solo si todas dicen optional |

### Ejemplo practico

| Fuente | Centro Coste | Resultado |
|--------|-------------|-----------|
| Doc Type SA | Optional | |
| Cuenta 400000 | Required | |
| Posting Key 40 | Optional | |
| **Interseccion** | | **Required** |

---

## Cabecera del Documento — Estructura BKPF / ACDOCA

### Campos de cabecera (nivel documento)

| Campo BKPF | Campo ACDOCA | Descripcion |
|-------------|-------------|-------------|
| BUKRS | RBUKRS | Sociedad |
| BELNR | BELNR | Numero documento |
| GJAHR | GJESSION | Ejercicio fiscal |
| BLART | BLART | Tipo documento |
| BUDAT | BUDAT | Fecha contabilizacion |
| BLDAT | BLDAT | Fecha documento |
| MONAT | PESSION | Periodo contable |
| WAERS | RHCUR | Moneda del documento |
| XBLNR | XBLNR | Referencia (factura proveedor) |
| BKTXT | BKTXT | Texto cabecera |
| STBLG | STBLG | Doc anulacion |
| STJAH | STJAH | Ejercicio doc anulacion |
| CPUDT | CPUDT | Fecha grabacion |
| USNAM | USNAM | Usuario |

### Consulta MCP — Buscar documento por numero

```sql
SELECT BELNR, BUZEI, BUDAT, BLDAT, BLART, RACCT, KUNNR, LIFNR,
       HSL, RHCUR, DRCRK, KOART, SGTXT, XBLNR, BKTXT, USNAM
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND BELNR = '0100000001'
  AND GJESSION = '2026'
  AND RLDNR = '0L'
ORDER BY BUZEI
```

### Consulta MCP — Documentos por tipo y periodo

```sql
SELECT BELNR, BUDAT, BLART, RACCT, HSL, RHCUR, DRCRK, KUNNR, LIFNR, XBLNR, USNAM
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND BLART = 'KR'
  AND PESSION = '05'
  AND GJESSION = '2026'
  AND RLDNR = '0L'
ORDER BY BUDAT DESC, BELNR, BUZEI
```

---

## Anulacion de Documentos

### Metodos de anulacion

| Txn | Descripcion | Alcance |
|-----|-------------|---------|
| FB08 | Anulacion individual | Un documento |
| F.80 | Anulacion masiva | Seleccion por criterios |
| FBRA | Resetear compensacion | Deshacer clearing |

### Motivos de anulacion (T041A)

| Motivo | Descripcion | Fecha |
|--------|-------------|-------|
| 01 | Anulacion en periodo actual | Fecha original |
| 02 | Anulacion en periodo actual | Fecha hoy |
| 03 | Anulacion periodo anterior | Fecha original |
| 04 | Anulacion periodo anterior | Fecha hoy |

### Consulta MCP — Cadena de anulacion

```sql
SELECT A.BELNR AS DOC_ORIGINAL, A.BUDAT, A.BLART,
       B.BELNR AS DOC_ANULACION, B.BUDAT AS FECHA_ANUL
FROM ACDOCA AS A
INNER JOIN ACDOCA AS B ON A.STBLG = B.BELNR AND A.GJESSION = B.GJESSION AND A.RBUKRS = B.RBUKRS
WHERE A.RBUKRS = '1000'
  AND A.STBLG <> ''
  AND A.RLDNR = '0L'
  AND B.RLDNR = '0L'
  AND A.BUZEI = '001'
  AND B.BUZEI = '001'
  AND A.GJESSION = '2026'
ORDER BY A.BUDAT DESC
```

---

## Documentos de Referencia

### Documentos periodicos (Recurring) — FBD1

| Txn | Descripcion |
|-----|-------------|
| FBD1 | Crear documento periodico |
| FBD2 | Modificar documento periodico |
| FBD3 | Visualizar documento periodico |
| F.14 | Ejecutar documentos periodicos |

### Documentos modelo (Sample) — FBM1

| Txn | Descripcion |
|-----|-------------|
| FBM1 | Crear documento modelo |
| FBM2 | Modificar documento modelo |
| FBM3 | Visualizar documento modelo |

Los documentos modelo se usan como plantilla al crear asientos con FB50/FB01, acelerando la captura.

---

## Arbol de decision — Seleccion de tipo de documento

```
Operacion contable
|
+-- Factura proveedor?
|   +-- Con pedido MM → RE (MIRO)
|   +-- Sin pedido → KR (FB60)
|
+-- Nota credito proveedor? → KG (FB65)
|
+-- Pago a proveedor? → KZ (F-53/F110)
|
+-- Factura cliente?
|   +-- Desde SD billing → RV (VF01)
|   +-- Manual → DR (FB70)
|
+-- Nota credito cliente? → DG (FB75)
|
+-- Cobro cliente? → DZ (F-28)
|
+-- Asiento mayor puro? → SA (FB50)
|
+-- Reclasificacion/ajuste? → AB (FB01)
|
+-- Activo fijo?
|   +-- Alta → AA
|   +-- Amortizacion → AF
|   +-- Baja → AB con PK 70/75
|
+-- Asiento negativo (storno)? → Activar XNEG en T003
```

---

## Diagnostico — Consultas utiles

### Documentos contabilizados hoy por usuario

```sql
SELECT BELNR, BLART, BUDAT, RACCT, HSL, RHCUR, DRCRK, USNAM
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND CPUDT = '20260515'
  AND RLDNR = '0L'
ORDER BY USNAM, BELNR, BUZEI
```

### Volumen de documentos por tipo y mes

```sql
SELECT BLART, PESSION,
       COUNT(DISTINCT BELNR) AS NUM_DOCS
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND GJESSION = '2026'
  AND RLDNR = '0L'
GROUP BY BLART, PESSION
ORDER BY BLART, PESSION
```

### Verificar posting keys usadas por tipo documento

```sql
SELECT BLART, BSCHL, DRCRK, KOART, COUNT(*) AS LINEAS
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND GJESSION = '2026'
  AND RLDNR = '0L'
GROUP BY BLART, BSCHL, DRCRK, KOART
ORDER BY BLART, BSCHL
```
