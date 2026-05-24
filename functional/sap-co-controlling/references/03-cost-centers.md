# Centros de Coste (Cost Centers)

## Tabla principal: CSKS (datos) + CSKT (textos)

### Campos clave CSKS

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| KOKRS | Area controlling | 1000 |
| KOSTL | Centro de coste | 1000-CC01 |
| DATAB | Validez desde | 20240101 |
| DATBI | Validez hasta | 99991231 |
| KOSAR | Categoria CC | H (Overhead) |
| VERAK | Responsable | JSMITH |
| BUKRS | Sociedad | 1000 |
| GSBER | Area negocio | 0001 |
| PRCTR | Profit center (asignacion) | PC01 |

### Categorias de centro de coste (KOSAR)

| Cat | Descripcion | Uso tipico |
|-----|-------------|-----------|
| H | Overhead / Administrativo | Costes generales, admin, IT |
| F | Produccion / Fabricacion | Planta, lineas de produccion |
| E | Investigacion y desarrollo | I+D |
| V | Ventas y distribucion | Comercial, marketing |
| L | Logistica | Almacen, transporte |
| S | Servicios | Servicios internos |

### Consulta MCP — Centros de coste con detalle

```sql
SELECT K.KOSTL, T.KTEXT, K.KOSAR, K.BUKRS, K.PRCTR, K.VERAK, K.DATAB, K.DATBI
FROM CSKS AS K
JOIN CSKT AS T ON K.KOKRS = T.KOKRS AND K.KOSTL = T.KOSTL AND T.SPRAS = 'E'
WHERE K.KOKRS = '{area}'
AND K.DATBI >= '{fecha_hoy}'
ORDER BY K.KOSTL
```

### Consulta MCP — Saldo real de un centro de coste

```sql
SELECT RCNTR, KSTAR, POPER, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND RCNTR = '{cc}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND VRESSION = '000'
GROUP BY RCNTR, KSTAR, POPER
ORDER BY KSTAR, POPER
```

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| KS01 | Crear centro coste | F0998 |
| KS02 | Modificar centro coste | F0998 |
| KS03 | Visualizar centro coste | F0998 |
| KSH1 | Crear grupo CC | — |
| OKEON | Jerarquia estandar CC | — |

### Reglas de asignacion

- Todo centro de coste DEBE tener un profit center asignado (CSKS-PRCTR)
- Todo centro de coste DEBE estar en la jerarquia estandar
- La validez (DATAB/DATBI) debe cubrir el periodo de contabilizacion
- La sociedad (BUKRS) debe estar asignada al area de controlling
