# General Ledger (FI-GL) — Libro Mayor en S/4HANA

## Cuenta de Mayor — Datos Maestros

En S/4HANA, la cuenta de mayor tiene dos niveles:

### Nivel Plan de Cuentas (SKA1) — FSP0

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| KTOPL | Plan de cuentas | CALA |
| SAESSION | Numero cuenta | 110000 |
| XBILK | Indicador balance | X = Balance, ' ' = P&L |
| GESSION | Grupo cuentas | BS01, PL01 |
| KTOKS | Grupo cuentas GL | SAKO |
| BILKT | Cuenta grupo (consolidacion) | 110000 |
| XLOEV | Marcado borrado | ' ' |

### Nivel Sociedad (SKB1) — FSS0

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| BUKRS | Sociedad | 1000 |
| SAESSION | Numero cuenta | 110000 |
| WAESSION | Moneda cuenta | EUR |
| MESSION | Tipo cuenta | S (GL) |
| XOPVW | Gestion partidas abiertas | X |
| XKRES | Gestion partidas individuales | X |
| FSTAG | Grupo status campo | G001 |
| MIESSION | Tipo impuesto | V1 (IVA soportado) |
| ZUESSION | Tipo interes | 01 |

### Consulta MCP — Cuentas de mayor con detalle

```sql
SELECT A.SAKNR, A.XBILK, A.GESSION, B.WAESSION, B.XOPVW, B.XKRES, T.TXT50
FROM SKA1 AS A
INNER JOIN SKB1 AS B ON A.KTOPL = B.KTOPL AND A.SAKNR = B.SAKNR
INNER JOIN SKAT AS T ON A.KTOPL = T.KTOPL AND A.SAKNR = T.SAKNR AND T.SPRAS = 'S'
WHERE A.KTOPL = 'CALA' AND B.BUKRS = '1000'
ORDER BY A.SAKNR
```

### SPRO Path
`SPRO > Gestion financiera > Contabilidad general > Datos maestros > Cuentas de mayor > Preparar creacion cuentas de mayor`

---

## Grupos de Cuentas (T077S)

| Grupo | Descripcion tipica | Rango numeros |
|-------|-------------------|---------------|
| BS01 | Balance Sheet - Assets | 100000-199999 |
| BS02 | Balance Sheet - Liabilities | 200000-299999 |
| PL01 | P&L - Revenue | 400000-499999 |
| PL02 | P&L - Expenses | 500000-699999 |
| SAKO | General GL | 000000-999999 |

---

## Contabilizacion en Mayor

### Transacciones principales

| Txn | Descripcion | Uso |
|-----|-------------|-----|
| FB50 | Asiento contable simple | Contabilizacion directa GL |
| FB01 | Asiento contable complejo | Multi-tipo cuenta |
| FV50 | Documento preliminar GL | Pre-contabilizacion |
| FB05 | Compensar con contabilizacion | Clearing + nuevo asiento |
| FAGLB03 | Saldos cuenta mayor | Visualizar saldos |
| FBL3N | Partidas individuales GL | Detalle movimientos |
| S_ALR_87012547 | Balance de sumas y saldos | Trial Balance report |

### Consulta MCP — Asientos contables en ACDOCA

```sql
SELECT RCLNT, RLDNR, RBUKRS, BELNR, GJESSION, BUZEI, BUDAT, BLDAT, BLART,
       RACCT, RHCUR, HSL, DRCRK, KTOPL, BKTXT, SGTXT
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND RACCT = '0000110000'
  AND GJESSION = '2026'
ORDER BY BUDAT DESC, BELNR, BUZEI
```

### Consulta MCP — Trial Balance (saldos por cuenta)

```sql
SELECT RACCT, RHCUR,
       SUM(CASE WHEN DRCRK = 'S' THEN HSL ELSE 0 END) AS DEBITOS,
       SUM(CASE WHEN DRCRK = 'H' THEN HSL ELSE 0 END) AS CREDITOS,
       SUM(HSL) AS SALDO
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND RLDNR = '0L'
  AND GJESSION = '2026'
GROUP BY RACCT, RHCUR
ORDER BY RACCT
```

---

## Document Splitting en S/4HANA

Divide automaticamente las lineas del documento contable para obtener balances a cero por dimension (segmento, profit center, business area).

### Tipos de splitting

| Tipo | Descripcion |
|------|-------------|
| Pasivo | Solo hereda la dimension de las lineas de gasto/ingreso a las lineas de impuesto/banco |
| Activo | Genera lineas adicionales de compensacion para garantizar balance cero |

### Configuracion clave

| Paso | SPRO Path |
|------|-----------|
| Activar splitting | `Gestion financiera > Parametrizaciones basicas > Fraccionamiento documento > Activar fraccionamiento` |
| Definir categorias | `Fraccionamiento documento > Clasificar tipos documento FI` |
| Definir reglas | `Fraccionamiento documento > Definir reglas fraccionamiento` |
| Constantes | `Fraccionamiento documento > Definir constantes para splitting no pasivo` |

### Consulta MCP — Verificar splitting en documentos

```sql
SELECT BELNR, BUZEI, RACCT, SEGMENT, PRCTR, HSL, DRCRK
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND BELNR = '0100000001'
  AND GJESSION = '2026'
  AND RLDNR = '0L'
ORDER BY BUZEI
```

---

## Leading vs Non-Leading Ledger

### Tabla FINSC_LEDGER

| Campo | Descripcion |
|-------|-------------|
| RLDNR | ID ledger |
| LDGRP | Grupo ledger |
| XLEADING | Indicador leading |
| LANGU | Idioma |

### Ledgers estandar S/4HANA

| Ledger | Tipo | Uso tipico |
|--------|------|------------|
| 0L | Leading | Contabilidad local (GAAP principal) |
| 2L | Non-Leading | IFRS / segundo principio contable |
| 3L | Non-Leading | Tax reporting |

### Consulta MCP — Ledgers configurados

```sql
SELECT RLDNR, NAME, XLEADING
FROM FINSC_LEDGER
ORDER BY RLDNR
```

### Contabilidad paralela
Para registrar diferencias entre GAAP: se contabiliza con ledger group especifico. Los documentos comunes van a todos los ledgers del grupo.

### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Ledgers > Definir ledgers para principio contable`

---

## Cuenta de Resultados Acumulados — OB53

Mapea cada cuenta de P&L a una cuenta de balance donde se acumula el resultado del ejercicio al cierre.

### Consulta MCP — Asignacion resultado acumulado

```sql
SELECT KTOPL, VONKT, BISKT
FROM T030HK
WHERE KTOPL = 'CALA'
ORDER BY VONKT
```

### Transaccion: OB53
### SPRO Path
`SPRO > Gestion financiera > Contabilidad general > Operaciones comerciales > Cierre > Arrastre > Definir cuenta resultados acumulados`

---

## Arrastre de Saldos — FAGLGVTR

| Paso | Descripcion |
|------|-------------|
| 1 | Ejecutar FAGLGVTR para arrastrar saldos de balance al nuevo ejercicio |
| 2 | Las cuentas P&L se saldan contra la cuenta de resultados acumulados (OB53) |
| 3 | Repetir si hay contabilizaciones en el periodo anterior despues del arrastre |

### Parametros FAGLGVTR

| Parametro | Valor tipico |
|-----------|--------------|
| Ledger | 0L |
| Sociedad | 1000 |
| Ejercicio fiscal | 2025 |
| Tipo tratamiento | Solo cuentas de balance / Todo |

---

## Diagnostico — Consultas frecuentes GL

### Movimientos del dia

```sql
SELECT BELNR, BUZEI, RACCT, HSL, RHCUR, BLART, BUDAT, SGTXT, USNAM
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND RLDNR = '0L'
  AND BUDAT = '20260515'
ORDER BY BELNR, BUZEI
```

### Cuentas sin movimiento en el periodo

```sql
SELECT A.SAKNR, T.TXT50
FROM SKB1 AS A
INNER JOIN SKAT AS T ON A.KTOPL = T.KTOPL AND A.SAKNR = T.SAKNR AND T.SPRAS = 'S'
WHERE A.BUKRS = '1000'
  AND A.SAKNR NOT IN (
    SELECT DISTINCT RACCT FROM ACDOCA
    WHERE RBUKRS = '1000' AND GJESSION = '2026' AND PESSION = '05' AND RLDNR = '0L'
  )
ORDER BY A.SAKNR
```

### Verificar balance cuadrado por segmento

```sql
SELECT SEGMENT, SUM(HSL) AS BALANCE
FROM ACDOCA
WHERE RBUKRS = '1000'
  AND RLDNR = '0L'
  AND GJESSION = '2026'
GROUP BY SEGMENT
ORDER BY SEGMENT
```

---

## Errores comunes FI-GL

| Error | Causa | Solucion |
|-------|-------|----------|
| F5 155 | Periodo contable cerrado | Abrir periodo en OB52 |
| F5 003 | Cuenta no existe en sociedad | Crear nivel sociedad en FSS0 |
| F5 201 | Balance no cuadra | Revisar importes debe = haber |
| F5 312 | Status campo: campo obligatorio faltante | Revisar OBC4, OB41, posting key |
| FP080 | Moneda incorrecta para la cuenta | Verificar SKB1-WAESSION vs documento |
