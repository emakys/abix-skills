# Ordenes Internas CO

## Tabla principal: AUFK

### Campos clave AUFK

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| AUFNR | Numero orden | 800001 |
| AUART | Tipo de orden | 0100 (overhead) |
| AUTYP | Categoria orden | 01 (interna) |
| BUKRS | Sociedad | 1000 |
| KOKRS | Area controlling | 1000 |
| KOSTV | CC responsable | 1000-CC01 |
| PRCTR | Profit center | PC01 |
| KSTAR | Clase coste liquidacion | 690000 |

### Tipos de orden (AUART) — Tabla T003O

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| 0100 | Overhead | Gastos generales, proyectos internos |
| 0200 | Inversion (CAPEX) | Capitalizable a activo fijo |
| 0300 | Periodificacion | Accrual/deferral |
| 0400 | Orden con ingreso | Trabajos con ingreso para clientes internos |

### Status de la orden (JEST/TJ02)

| Status | Codigo | Descripcion |
|--------|--------|-------------|
| Creada | I0001 | CRTD — Solo creada, no se puede contabilizar |
| Liberada | I0002 | REL — Acepta contabilizaciones |
| Tecnicamente cerrada | I0009 | TECO — No acepta mas costes |
| Cerrada | I0046 | CLSD — Completamente cerrada |
| Bloqueada | I0043 | LKD — Bloqueada temporalmente |

### Consulta MCP — Ordenes internas con saldo

```sql
-- Datos maestros orden
SELECT AUFNR, AUART, BUKRS, KOSTV, PRCTR, KSTAR
FROM AUFK
WHERE BUKRS = '{sociedad}'
AND AUART = '{tipo}'
ORDER BY AUFNR

-- Saldo real de una orden (S/4)
SELECT AUFNR, KSTAR, POPER, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE AUFNR = '{orden}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
GROUP BY AUFNR, KSTAR, POPER
ORDER BY KSTAR, POPER

-- Verificar status
SELECT OBJNR, STAT, INACT
FROM JEST
WHERE OBJNR = 'OR{orden}'
AND INACT = ''
```

### Presupuesto de ordenes

| TCode | Descripcion |
|-------|-------------|
| KO22 | Definir presupuesto |
| KO24 | Suplemento presupuesto |
| KO23 | Visualizar presupuesto |

### Regla de liquidacion (settlement rule)

Toda orden real DEBE tener una regla de liquidacion. Se define en KO02 → tab Liquidacion.

| Receptor | Descripcion |
|----------|-------------|
| Centro coste | Liquida a un CC |
| Cuenta GL | Liquida a cuenta |
| Activo fijo | Liquida a AA (inversion) |
| WBS element | Liquida a PS |
| Orden | Liquida a otra orden |

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| KO01 | Crear orden | F1599 |
| KO02 | Modificar orden | F1599 |
| KO03 | Visualizar orden | F1599 |
| KO88 | Liquidar orden individual | — |
| KOB1 | Partidas individuales | F2709 |
