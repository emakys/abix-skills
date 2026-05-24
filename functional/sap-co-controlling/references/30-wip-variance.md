# WIP (Work in Process) y Desviaciones de Produccion

## WIP — Trabajo en Curso

### Flujo WIP

```
Orden produccion abierta (status REL o PCNF)
│
├── Costes acumulados: 80,000 EUR
│   ├── Material: 40,000
│   ├── Mano obra: 25,000
│   └── Overhead: 15,000
│
├── Entregas parciales: 50,000 EUR (a precio estandar)
│
├── WIP = Costes acumulados - Entregas = 30,000 EUR
│
└── Contabilizacion WIP (KKAO):
    Debe: 790000 (WIP cuenta balance) — 30,000
    Haber: 890000 (WIP offset P&L) — 30,000
```

### Claves WIP

| Clave | Descripcion | Metodo |
|-------|-------------|--------|
| 000001 | WIP at target costs | Coste objetivo |
| 000002 | WIP at actual costs | Coste real acumulado |
| 000003 | WIP at planned costs | Coste plan |

### Transacciones WIP

| TCode | Descripcion |
|-------|-------------|
| KKAO | Calcular WIP (colectivo) |
| KKAX | Calcular WIP (individual) |
| OKG1 | Configurar claves WIP |
| OKG2 | Asignar cuentas WIP |

---

## Desviaciones de Produccion (Variance)

Las desviaciones miden la diferencia entre el coste planificado (estandar) y el coste real. Solo se calculan para ordenes con status DLV o TECO.

### Categorias de desviacion

| Categoria | Descripcion | Causa tipica |
|-----------|-------------|-------------|
| Input price variance | Diferencia en precio | Precio real ≠ estandar |
| Input quantity variance | Diferencia en cantidad | Consumo real ≠ BOM |
| Resource usage variance | Diferencia uso recursos | — |
| Remaining variance | No categorizable | Overhead, redondeo |
| Lot size variance | Diferencia tamano lote | Lote real ≠ plan |
| Scrap variance | Chatarra/merma | Material descartado |

### Flujo de desviaciones

```
Orden produccion con status DLV o TECO
│
├── Coste real total: 63,250 EUR
├── Coste estandar (target): 60,000 EUR
│
├── Desviacion total: 3,250 EUR
│   ├── Price variance: 1,500 EUR
│   ├── Quantity variance: 1,000 EUR
│   └── Remaining variance: 750 EUR
│
└── Settlement (CO88):
    ├── Product a estandar: 60,000 → stock (BSX)
    └── Desviaciones: 3,250 → cuentas varianza
```

### Consulta MCP

```sql
-- WIP acumulado por orden
SELECT AUFNR, KSTAR, POPER, SUM(HSL) AS WIP_AMOUNT
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND AUFNR LIKE '{prefix}%'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND KSTAR BETWEEN '790000' AND '799999'
GROUP BY AUFNR, KSTAR, POPER

-- Desviaciones por orden produccion
SELECT AUFNR, KSTAR, SUM(HSL) AS VARIANCE_AMOUNT
FROM ACDOCA
WHERE RBUKRS = '{sociedad}'
AND AUFNR = '{orden}'
AND GJAHR = '{year}'
AND RLDNR = '0L'
AND KSTAR IN ('{variance_accounts}')
GROUP BY AUFNR, KSTAR
```

### Transacciones desviaciones

| TCode | Descripcion |
|-------|-------------|
| KKS1 | Calcular desviaciones (colectivo) |
| KKS2 | Calcular desviaciones (individual) |
| OKV1 | Definir variante de desviacion |

### SPRO Path
`SPRO > Controlling > Product Cost Controlling > Cost Object Controlling > Variance Calculation > Define Variance Variants`
`SPRO > Controlling > Product Cost Controlling > Cost Object Controlling > WIP > Define Results Analysis Keys`
