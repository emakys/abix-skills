# Estructura Organizativa FI

## Company Code (BUKRS) — Tabla T001

Unidad organizativa central de FI. Representa una entidad legal independiente con balance y P&L propios.

### Campos clave de T001

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| BUKRS | Codigo sociedad | 1000 |
| BUTXT | Nombre sociedad | SAP AG |
| ORT01 | Ciudad | Walldorf |
| LAND1 | Pais | DE |
| WAERS | Moneda local | EUR |
| KTOPL | Plan de cuentas operativo | CALA |
| PERIV | Variante ejercicio fiscal | K4 |
| FSTAG | Variante status campo | 0001 |
| KKBER | Area control credito | 1000 |
| RCOMP | Company (consolidacion) | 1000 |

### Consulta MCP — Sociedades configuradas

```sql
SELECT BUKRS, BUTXT, WAERS, KTOPL, PERIV, LAND1
FROM T001
ORDER BY BUKRS
```

### SPRO Path
`SPRO > Estructura empresa > Definicion > Gestion financiera > Definir sociedad`

---

## Business Area (GSBER) — Tabla TGSB

Segmentacion interna del negocio. Opcional pero util para reportes por linea de negocio.

| Campo | Descripcion |
|-------|-------------|
| GSBER | Area de negocio (4 char) |
| GTEXT | Descripcion |

### Consulta MCP — Areas de negocio

```sql
SELECT GSBER, GTEXT
FROM TGSBT
WHERE SPRAS = 'S'
ORDER BY GSBER
```

### Uso en Document Splitting
En S/4HANA, el Business Area puede derivarse automaticamente via reglas de splitting.
La derivacion se configura en: `SPRO > Gestion financiera > Parametrizaciones basicas > Fraccionamiento documento`

---

## Segment — Derivacion automatica

El segmento se deriva automaticamente del centro de beneficio asignado en la cuenta o en el objeto CO.

| Tabla | Contenido |
|-------|-----------|
| FAGL_SEGM | Asignacion profit center → segment |
| SETNODE / SETHEADER | Jerarquias de segmentos |

### Consulta MCP — Segmentos por profit center

```sql
SELECT PRCTR, SEGMENT
FROM FAGL_SEGM
WHERE BUKRS = '1000'
ORDER BY PRCTR
```

### SPRO Path
`SPRO > Gestion financiera > Contabilidad general > Operaciones comerciales > Fraccionamiento documento > Definir segmentos`

---

## Variante de Ejercicio Fiscal (T009 / T009B)

Define la estructura del anio fiscal: periodos normales y especiales.

### Variantes estandar

| Variante | Descripcion | Periodos | Especiales |
|----------|-------------|----------|------------|
| K4 | Ano natural (Ene-Dic) | 12 | 4 |
| V3 | Abril-Marzo (UK) | 12 | 4 |
| V6 | Julio-Junio | 12 | 4 |
| V9 | Octubre-Septiembre | 12 | 4 |

### Consulta MCP — Periodos del ejercicio

```sql
SELECT PERIV, BDATJ, BUMON, BUTAG, RESSION
FROM T009B
WHERE PERIV = 'K4'
ORDER BY BUMON
```

### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Ejercicio fiscal > Actualizar variante de ejercicio fiscal`

---

## Variante de Periodo de Contabilizacion (T001B) — OB52

Controla que periodos estan abiertos para contabilizar, por tipo de cuenta.

### Estructura de T001B

| Campo | Descripcion |
|-------|-------------|
| BUKRS | Sociedad |
| RESSION | Variante periodo |
| KESSION1 | Tipo cuenta (S=GL, D=Deudor, K=Acreedor, A=Activo, M=Material, +) |
| FRESSION1 | Periodo desde |
| TOESSION1 | Periodo hasta |
| FRESSION2 | Periodo 2 desde |
| TOESSION2 | Periodo 2 hasta |

### Consulta MCP — Periodos abiertos actuales

```sql
SELECT BUKRS, RESSION, KESSION1, FRESSION1, TOESSION1, FRESSION2, TOESSION2
FROM T001B
WHERE BUKRS = '1000'
ORDER BY KESSION1
```

### Transaccion: OB52
### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Ejercicio fiscal > Abrir y cerrar periodos de contabilizacion`

---

## Variante de Status de Campo (T004) — OBC4

Controla que campos son obligatorios, opcionales, ocultos o solo lectura en las transacciones de contabilizacion.

### Grupos de status de campo

| Grupo | Descripcion tipica |
|-------|-------------------|
| G001 | Datos generales (obligatorios) |
| G004 | Division (opcional) |
| G005 | Area de negocio |
| G010 | Centro de coste |
| G013 | Orden CO |
| G014 | Profit Center |
| G049 | Referencia |

### Logica de interseccion
El status final de un campo = interseccion de 3 fuentes:
1. **Variante de transaccion** (OB41) — por tipo de documento
2. **Grupo de cuentas** (OBC4) — por cuenta de mayor
3. **Clave de contabilizacion** (TBSL) — por posting key

Regla: `Suppress > Required > Optional`. Si cualquier fuente dice Suppress, el campo se oculta.

### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Variante de status de campo > Definir variante de status de campo`

---

## Grupos de Tolerancia — T043 / T043T

### Para cuentas de mayor (T043)

| Campo | Descripcion |
|-------|-------------|
| BUKRS | Sociedad |
| HTEFN | Grupo tolerancia |
| HWLOW | Importe maximo por documento |
| HWDIF | Diferencia maxima permitida |

### Para empleados

Define limites de contabilizacion por usuario. Transaccion: OBA4.

### Para clientes/proveedores

Define tolerancias de pago (diferencias admitidas en compensacion). Transaccion: OBA3.

### Consulta MCP — Grupos de tolerancia

```sql
SELECT BUKRS, HTEFN, HWLOW, HWDIF
FROM T043
WHERE BUKRS = '1000'
```

### SPRO Path
`SPRO > Gestion financiera > Parametrizaciones basicas > Definir grupos de tolerancia para cuentas de mayor`
`SPRO > Gestion financiera > Parametrizaciones basicas > Definir grupos de tolerancia para empleados`

---

## Plan de Cuentas (KTOPL) — T004

### Tipos de plan de cuentas

| Tipo | Uso | Ejemplo |
|------|-----|---------|
| Operativo | Contabilizacion diaria | CALA, INT, YCOA |
| Grupo | Consolidacion corporativa | GKTO |
| Pais | Reportes legales locales | LKTO |

### Consulta MCP — Planes de cuentas

```sql
SELECT KTOPL, KTPLT, XBILK
FROM T004
ORDER BY KTOPL
```

### Asignacion a sociedad
Cada sociedad tiene UN plan de cuentas operativo (T001-KTOPL). Los planes de grupo y pais se asignan via OB62.

### SPRO Path
`SPRO > Gestion financiera > Contabilidad general > Datos maestros > Plan de cuentas > Definir plan de cuentas`

---

## Area de Control de Credito (KKBER) — T014

| Campo | Descripcion |
|-------|-------------|
| KKBER | Area control credito |
| KKBTX | Descripcion |
| WAESSION | Moneda |
| KLIMK | Limite credito global |

### Asignacion
Una o mas sociedades se asignan a un area de control de credito.

### Consulta MCP

```sql
SELECT KKBER, BUKRS
FROM T001
WHERE KKBER <> ''
ORDER BY KKBER, BUKRS
```

### SPRO Path
`SPRO > Estructura empresa > Definicion > Gestion financiera > Definir area de control de credito`

---

## Diagnostico rapido — Verificar configuracion organizativa completa

```sql
SELECT T1.BUKRS, T1.BUTXT, T1.WAERS, T1.KTOPL, T1.PERIV, T1.FSTAG, T1.KKBER
FROM T001 AS T1
WHERE T1.BUKRS = '1000'
```

### Checklist de configuracion minima FI

| Paso | Objeto | Transaccion | Tabla |
|------|--------|-------------|-------|
| 1 | Sociedad | OX02 | T001 |
| 2 | Plan de cuentas | OB13 | T004 |
| 3 | Variante ejercicio | OB29 | T009 |
| 4 | Variante periodos | OB52 | T001B |
| 5 | Variante status campo | OBC4 | T004F |
| 6 | Tolerancia GL | OBA0 | T043 |
| 7 | Tolerancia empleados | OBA4 | T043 |
| 8 | Tolerancia clientes | OBA3 | T043 |
| 9 | Moneda paralela | OB22 | T001 |
| 10 | Area control credito | OB45 | T014 |
