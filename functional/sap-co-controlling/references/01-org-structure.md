# Estructura Organizativa CO

## Area de Controlling (KOKRS) — Tabla TKA01

Unidad organizativa principal de CO. Agrupa una o mas sociedades bajo un mismo esquema de controlling.

### Campos clave TKA01

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| KOKRS | Area controlling | 1000 |
| BEZEI | Descripcion | Area CO Global |
| WAERS | Moneda area CO | EUR |
| KESSION | Tipo clase coste | 01 (automatico en S/4) |
| IVESSION | Variante ejercicio | K4 |

### Consulta MCP

```sql
SELECT KOKRS, WAERS
FROM TKA01
ORDER BY KOKRS
```

### SPRO Path
`SPRO > Controlling > Organizacion > Actualizar area de controlling (OKKP)`

---

## Asignacion Sociedad → Area CO — Tabla TKA02

| Campo | Descripcion |
|-------|-------------|
| BUKRS | Sociedad |
| KOKRS | Area controlling |

Una sociedad solo puede pertenecer a UN area de controlling.

### Consulta MCP

```sql
SELECT BUKRS, KOKRS
FROM TKA02
ORDER BY KOKRS, BUKRS
```

### SPRO Path
`SPRO > Controlling > Organizacion > Asignar sociedad a area de controlling (OX19)`

---

## Versiones de Plan — Tabla TKA09

| Version | Uso |
|---------|-----|
| 000 | Real (automatico, no modificable) |
| 0 | Plan principal |
| 1-999 | Planes alternativos / escenarios |

### Consulta MCP

```sql
SELECT VERSN, BEZEI
FROM TKA09T
WHERE KOKRS = '{area}' AND SPRAS = 'E'
ORDER BY VERSN
```

### SPRO Path
`SPRO > Controlling > Contabilidad centros coste > Planificacion > Definir versiones (OKEQ)`

---

## Rangos de Numeros — Ordenes internas

| Tipo | Tabla | Transaccion |
|------|-------|-------------|
| Ordenes CO | NRIV (AUFNR) | KONK |
| Centros coste | NRIV (KOSTL) | KS04 |

### SPRO Path
`SPRO > Controlling > Ordenes CO > Datos maestros > Definir rangos numeros ordenes internas (KONK)`

---

## Jerarquia Estandar — Centros de Coste y Profit Centers

### Centro de coste
Cada centro de coste DEBE pertenecer a una jerarquia estandar (obligatorio).

```sql
SELECT SETNAME, DESSION
FROM SETHEADER
WHERE SETCLASS = '0101' AND SUBCLASS = '{kokrs}'
```

### Profit center
Cada profit center DEBE pertenecer a una jerarquia estandar (obligatorio en S/4HANA).

```sql
SELECT SETNAME, DESSION
FROM SETHEADER
WHERE SETCLASS = '0106' AND SUBCLASS = '{kokrs}'
```

### SPRO Path
`SPRO > Controlling > Contabilidad centros coste > Datos maestros > Jerarquia estandar > Actualizar (OKEON)`
`SPRO > Controlling > Contabilidad centros beneficio > Datos maestros > Jerarquia estandar > Actualizar (KCH1)`
