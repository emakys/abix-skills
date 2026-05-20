# Estructura Organizativa MM

## Jerarquia

```
Mandante (Client)
+-- Sociedad (Company Code) [T001]
|   +-- Centro / Planta (Plant) [T001W]
|   |   +-- Almacen (Storage Location) [T001L]
|   |   +-- Area de valoracion (Valuation Area)
|   +-- Organizacion de compras (Purchasing Org) [T024E]
|       +-- Grupo de compra (Purchasing Group) [T024]
```

## Asignaciones clave

| Asignacion | Tabla | Transaccion IMG | Obligatoria |
|------------|-------|-----------------|:-----------:|
| Sociedad -> Centro | T001K (BWKEY) | OX18 | Si |
| Centro -> Org compras | T024W | OX17 | Si |
| Org compras -> Sociedad | T024Z | OX01 | Si |
| Org compras -> Centro -> Sociedad (triangulo) | — | SPRO | Si |
| Almacen -> Centro | T001L | OX09 | Si |

## Queries MCP para verificar

```sql
-- Estructura completa del cliente
SELECT T001.BUKRS, T001.BUTXT, T001W.WERKS, T001W.NAME1, T024E.EKORG, T024E.EKOTX
FROM T001
JOIN T001K ON T001.BUKRS = T001K.BUKRS
JOIN T001W ON T001K.BWKEY = T001W.WERKS
LEFT JOIN T024W ON T001W.WERKS = T024W.WERKS
LEFT JOIN T024E ON T024W.EKORG = T024E.EKORG
WHERE T001.SPRAS = 'E'

-- Centros sin org compras asignada (error comun)
SELECT WERKS, NAME1 FROM T001W
WHERE WERKS NOT IN (SELECT WERKS FROM T024W)

-- Almacenes por centro
SELECT WERKS, LGORT, LGOBE FROM T001L WHERE WERKS = '{centro}'
```

## Decisiones de diseno

### Org compras centralizada vs descentralizada
- **Centralizada** (1 org compras para N sociedades):
  - Ventaja: negociacion consolidada, contratos marco globales
  - Uso: corporaciones con compras centralizadas
  - Config: 1 EKORG asignada a N BUKRS
- **Descentralizada** (1 org compras por sociedad):
  - Ventaja: autonomia local, reporting separado
  - Uso: empresas independientes, paises distintos
  - Config: 1 EKORG = 1 BUKRS
- **Hibrida**: org compras central + org compras locales referenciadas

### Almacenes tipicos
| Almacen | Uso | Tipo mov. entrada |
|---------|-----|-------------------|
| 0001 | Materia prima | 101 |
| 0002 | Producto terminado | 101 |
| 0003 | Repuestos/MRO | 101 |
| 0004 | Consignacion | 411K |
| 0005 | Calidad/Inspeccion | 103 |
| 0006 | Bloqueo | 103 -> 321 |
