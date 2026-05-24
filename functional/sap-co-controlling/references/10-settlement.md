# Liquidacion (Settlement)

## Concepto

La liquidacion transfiere los costes acumulados en un objeto CO (orden, proyecto) a uno o mas receptores.

### Flujo de liquidacion

```
Objeto CO emisor                     Receptor(es)
(orden interna 800001)
  Costes acumulados: 50,000 EUR
                                     Centro coste (CC01) — 70%: 35,000 EUR
                                     Activo fijo (10000-0) — 30%: 15,000 EUR

  Doc FI tipo AB generado automaticamente
  Clase coste 21 (liquidacion interna)
```

### Regla de liquidacion

| Campo | Descripcion |
|-------|-------------|
| Receptor | CC, GL account, activo, WBS, otra orden, CO-PA |
| Porcentaje | % de costes a liquidar (100% total) |
| Tipo liquidacion | Periodica (parcial) o Final (cierre) |
| Perfil liquidacion | Controla que receptores son validos |

### Perfil de liquidacion

| Perfil | Receptores permitidos | Tipo orden tipico |
|--------|----------------------|-------------------|
| 0001 | CC, Orden, GL | Overhead |
| 0002 | Activo fijo, AuC | Inversion (CAPEX) |
| 0003 | CC, GL, CO-PA | General |

### Consulta MCP

```sql
-- Regla de liquidacion de una orden
SELECT AUFNR, POESSION, KONTY, EMPGE, PROZENT
FROM COBRB
WHERE AUFNR = '{orden}'

-- Documentos de liquidacion
SELECT RBUKRS, BELNR, AUFNR, KSTAR, HSL, BUDAT
FROM ACDOCA
WHERE AUFNR = '{orden}'
AND KSTAR BETWEEN '690000' AND '699999'
AND GJAHR = '{year}'
AND RLDNR = '0L'
```

### Errores frecuentes

| Error | Causa | Fix |
|-------|-------|-----|
| CO 882 | Settlement rule missing | KO02 → tab Liquidacion → crear regla |
| CO 878 | Receiver not valid | Perfil no permite ese tipo receptor |
| CO 636 | Order locked | Revisar status (TECO/CLSD) |
| CO 770 | Percentages don't total 100% | Corregir % en regla |

### Transacciones principales

| TCode | Descripcion |
|-------|-------------|
| KO88 | Liquidar orden interna (individual) |
| KO8G | Liquidar ordenes (colectivo) |
| CO88 | Liquidar ordenes produccion |
| CJ88 | Liquidar proyectos PS |
| OKO7 | Definir perfil de liquidacion |
