# Centros de Beneficio (Profit Centers)

## Tabla principal: CEPC (datos) + CEPCT (textos)

### Campos clave CEPC

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| KOKRS | Area controlling | 1000 |
| PRCTR | Centro beneficio | PC01 |
| DATAB | Validez desde | 20240101 |
| DATBI | Validez hasta | 99991231 |
| BUKRS | Sociedad | 1000 |
| SEGMENT | Segmento (derivado) | S01 |
| VERAK | Responsable | JDOE |

### Profit Center en S/4HANA vs ECC

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Tabla de totales | GLPCT / FAGLFLEXT | ACDOCA (Universal Journal) |
| Balance zero | Opcional via doc splitting | Obligatorio por defecto |
| Segment reporting | Via profit center | Automatico via CEPC-SEGMENT |
| Eliminacion IC | EC-PCA (1KEK) | Universal Journal + reglas eliminacion |

### Consulta MCP — Profit centers con detalle

```sql
SELECT P.PRCTR, T.KTEXT, P.BUKRS, P.SEGMENT, P.KOSAR, P.DATAB, P.DATBI
FROM CEPC AS P
JOIN CEPCT AS T ON P.KOKRS = T.KOKRS AND P.PRCTR = T.PRCTR AND T.SPRAS = 'E'
WHERE P.KOKRS = '{area}'
AND P.DATBI >= '{fecha_hoy}'
ORDER BY P.PRCTR
```

### Consulta MCP — P&L por profit center

```sql
SELECT PRCTR, RACCT, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND PRCTR = '{pc}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
GROUP BY PRCTR, RACCT
ORDER BY RACCT
```

### Derivacion automatica del profit center

El profit center se deriva automaticamente segun estas prioridades:
1. **Centro de coste** (CSKS-PRCTR)
2. **Orden interna** (AUFK-PRCTR)
3. **Material** (MARC-PRCTR)
4. **Cuenta GL** (SKA1) — default por cuenta
5. **Dummy profit center** — si no hay derivacion

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| KE51 | Crear profit center | F0999 |
| KE52 | Modificar profit center | F0999 |
| KE53 | Visualizar profit center | F0999 |
| KCH1 | Jerarquia estandar PC | — |

### Reglas

- Todo profit center DEBE estar en la jerarquia estandar
- El segmento se deriva del profit center (CEPC-SEGMENT)
- Document splitting genera balance zero por profit center automaticamente en S/4
