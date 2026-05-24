# Lista de Materiales (BOM)

## Tablas BOM

| Tabla | Descripcion |
|-------|-------------|
| MAST | Asignacion material-BOM (material→STLNR) |
| STKO | Cabecera BOM |
| STPO | Posiciones BOM |
| STAS | Asignacion posicion-sub-item |
| STZU | Textos largos BOM |

## Tipos de BOM

| Tipo (STLTY) | Descripcion | TCode |
|--------------|-------------|-------|
| M | BOM de material | CS01 |
| E | BOM de equipo | IB01 |
| T | BOM de documento | CV01N |
| K | BOM de orden (order BOM) | CO02 |

## MAST — Asignacion material-BOM

```sql
SELECT MATNR, WERKS, STLAN, STLNR, STLAL
FROM MAST
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

| Campo | Descripcion |
|-------|-------------|
| STLAN | Uso BOM (1=produccion, 2=ingenieria, 3=costing) |
| STLNR | Numero interno BOM |
| STLAL | Alternativa BOM |

## STKO — Cabecera BOM

```sql
SELECT STLNR, STLTY, STLAL, BMENG, BMEIN, CADKZ, LOESSION, ANESSION, STKTX
FROM STKO
WHERE STLNR = '{bom_number}'
```

| Campo | Descripcion |
|-------|-------------|
| BMENG | Cantidad base BOM |
| BMEIN | Unidad base |
| CADKZ | Indicador CAD |
| LOESSION | Indicador borrado |
| ANESSION | Uso alternativo |
| DAESSION | Fecha validez desde |
| STKTX | Texto BOM |

## STPO — Posiciones BOM

```sql
SELECT STLNR, STLKN, POSNR, POSTP, IDNRK, MENGE, MEINS,
       AUESSION, POTX1, SCHGT, ERSKZ, SANFE, SANIN
FROM STPO
WHERE STLNR = '{bom_number}'
```

| Campo | Descripcion |
|-------|-------------|
| POSNR | Numero posicion |
| POSTP | Tipo posicion (L=stock, N=non-stock, R=variable, T=texto) |
| IDNRK | Material componente |
| MENGE | Cantidad componente |
| MEINS | Unidad de medida |
| AUESSION | Factor merma (%) |
| SCHGT | Material a granel (bulk) |
| ERSKZ | Indicador parte repuesto |
| SANFE | Qty scrap fija |
| SANIN | Qty scrap variable |

## Tipos de posicion BOM

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| L | Item de stock | Material del inventario |
| N | Item sin stock | Material sin gestion stock |
| R | Item variable | Cantidad variable por orden |
| T | Texto | Instrucciones |
| M | Clase | Item con clasificacion |
| D | Documento | Referencia a documento |
| K | Co-producto | By-product/co-product |

## Alternativas BOM

Permiten tener multiples listas de materiales para el mismo producto.

```sql
-- Todas las alternativas de un material
SELECT STLAL, STLNR FROM MAST
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND STLAN = '1'
```

- Se asignan via version de fabricacion (C223)
- MRP selecciona la alternativa segun version de fabricacion activa
- Cada alternativa puede tener validez temporal diferente

## BOM multi-nivel (explosion)

```
Producto terminado (nivel 0)
├── Componente A (nivel 1) ← BOM nivel 1
│   ├── Subcomponente A1 (nivel 2)
│   └── Subcomponente A2 (nivel 2)
├── Componente B (nivel 1)
│   └── Subcomponente B1 (nivel 2)
└── Materia prima C (nivel 1) ← sin BOM
```

- MRP explota BOM nivel por nivel (top-down)
- CS11: BOM multi-nivel (display)
- CS12: BOM multi-nivel con cantidades
- CS13: BOM resumida (suma componentes de todos los niveles)

## Transacciones BOM

| TCode | Descripcion |
|-------|-------------|
| CS01 | Crear BOM material |
| CS02 | Modificar BOM material |
| CS03 | Visualizar BOM material |
| CS05 | Modificar BOM grupo (cambiar en multiples BOMs) |
| CS11 | Display BOM multi-nivel |
| CS12 | Display BOM multi-nivel (qty) |
| CS13 | BOM resumida |
| CS14 | BOM comparativa |
| CS15 | Where-used (donde se usa un componente) |
| CS20 | Mass change BOM |
| CS40 | Crear BOM referencial |
| CS80 | Cambiar BOM con ECM (Engineering Change) |

## Engineering Change Management (ECM)

- STKO-AESSION = numero de cambio
- Permite control de versiones con fechas de validez
- Transacciones: CC01 (crear cambio), CC02 (modificar), CC04 (display)
- Importante para trazabilidad en industrias reguladas

## Consultas MCP diagnostico

```sql
-- BOM no encontrada (error CO 049)
SELECT MATNR, WERKS, STLAN, STLNR, STLAL FROM MAST
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND STLAN = '1'

-- Componentes de una BOM
SELECT P.POSNR, P.IDNRK, P.MENGE, P.MEINS, P.POSTP, P.AUESSION
FROM STPO P
WHERE P.STLNR = '{bom_number}'
ORDER BY P.POSNR

-- Donde se usa un componente
SELECT M.MATNR, M.WERKS, M.STLAL FROM MAST M
INNER JOIN STPO P ON M.STLNR = P.STLNR
WHERE P.IDNRK = '{componente}' AND M.WERKS = '{centro}'
```
