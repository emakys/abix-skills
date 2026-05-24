# Recargos de Costes Indirectos (Overhead)

## Concepto

El overhead aplica un porcentaje o importe fijo de recargo sobre una base de costes (ej: +15% sobre materiales directos para cubrir costes indirectos de almacenaje).

### Estructura de la hoja de recargo (Costing Sheet)

```
Hoja de recargo: ZCS001
|
+-- Fila 10: Base — Material directo (clases coste 400000-409999)
+-- Fila 20: Overhead — 15% sobre fila 10
|   Clase coste credito: 695000 (overhead applied)
|   CC credito: 1000-ALMACEN
|
+-- Fila 30: Base — Mano obra directa (clases coste 620000-629999)
+-- Fila 40: Overhead — 25% sobre fila 30
|   Clase coste credito: 695001
|   CC credito: 1000-RRHH
```

### Componentes de la hoja de recargo

| Componente | Descripcion | SPRO |
|------------|-------------|------|
| Base (Basis) | Que clases de coste forman la base | OKZ1 |
| Overhead rate | Porcentaje o importe fijo | OKZ3 |
| Credit key | Clase coste secundaria y CC credito | OKZ4 |
| Costing sheet | Combinacion de base + rate + credit | KZS2 |

### Transacciones principales

| TCode | Descripcion |
|-------|-------------|
| KGI2 | Overhead real — ordenes internas |
| CO43 | Overhead real — ordenes produccion |
| KZS2 | Definir hoja de recargo (costing sheet) |

### SPRO Path
`SPRO > Controlling > Product Cost Controlling > Cost Object Controlling > Period-End Closing > Overhead > Costing Sheet`
