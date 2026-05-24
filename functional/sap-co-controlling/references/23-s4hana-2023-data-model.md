# S/4HANA 2023 — Modelo de Datos CO

## Tabla principal: ACDOCA (Universal Journal)

### Campos CO en ACDOCA

| Campo | Descripcion | Uso CO |
|-------|-------------|--------|
| RCNTR | Centro de coste receptor | Cost center accounting |
| SCNTR | Centro de coste emisor | Allocations |
| PRCTR | Profit center | Profit center accounting |
| AUFNR | Numero de orden | Internal orders |
| KSTAR | Clase de coste | Cost element |
| LSTAR | Clase de actividad | Activity allocation |
| VRESSION | Version (000=real, 0=plan) | Plan vs Actual |
| MENGE | Cantidad | Activity quantities |
| RACCT | Cuenta GL (= cost element primario) | FI + CO |
| MATNR | Material | Product costing |
| PS_PSP_PNR | Elemento PEP | Project system |
| SEGMENT | Segmento | Segment reporting |

### Tablas eliminadas en S/4HANA

| Tabla ECC | Descripcion | Reemplazada por |
|-----------|-------------|-----------------|
| COEP | Partidas individuales CO | ACDOCA |
| COBK | Cabecera documento CO | ACDOCA |
| COSS | Totales costes secundarios | ACDOCA |
| COSP | Totales costes primarios | ACDOCA |
| GLPCT | Totales profit center | ACDOCA |
| CE1xxxx | CO-PA partidas (costing) | ACDOCA (account-based) |

### Tablas que siguen existiendo

| Tabla | Descripcion |
|-------|-------------|
| CSKS/CSKT | Centros de coste (maestro) |
| CEPC/CEPCT | Profit centers (maestro) |
| AUFK | Ordenes internas (maestro) |
| CSLA/CSLAT | Clases de actividad (maestro) |
| CSKA | Clases de coste secundarias |
| MBEW | Precios material |
| KEKO/KEPH | Calculo de costes |
| CKMLHD | Material Ledger header |
| COBRB | Reglas de liquidacion |

### Queries adaptadas S/4HANA

```sql
-- Equivalente a COSP (totales primarios)
SELECT RCNTR, KSTAR, POPER, VRESSION, SUM(HSL) AS TOTAL
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND RCNTR = '{cc}'
GROUP BY RCNTR, KSTAR, POPER, VRESSION

-- Equivalente a KSB1 (partidas individuales CC)
SELECT RBUKRS, BELNR, BUZEI, BUDAT, RCNTR, KSTAR, HSL, MENGE, LSTAR, AUFNR, SGTXT
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND RCNTR = '{cc}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND VRESSION = '000'
ORDER BY BUDAT, BELNR
```
