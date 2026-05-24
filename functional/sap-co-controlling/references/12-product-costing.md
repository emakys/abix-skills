# Product Costing (Calculo de Costes de Producto)

## Tipos de calculo

| Tipo | TCode | Descripcion |
|------|-------|-------------|
| Estimacion estandar | CK11N | Calcula coste estandar para un material |
| Marcacion (marking) | CK24 | Prepara nuevo precio estandar |
| Liberacion (release) | CK24 | Activa nuevo precio estandar → MBEW |
| Calculo masivo | CK40N | Calculo para multiples materiales |

## Componentes del coste de producto

```
Coste de producto
|
+-- Material directo
|   +-- Materia prima: cantidad BOM x precio material (MBEW)
|
+-- Mano de obra directa
|   +-- Operacion: tiempo routing x tarifa actividad (CSLA)
|
+-- Costes indirectos (overhead)
|   +-- Overhead material: % sobre material directo
|   +-- Overhead produccion: % sobre mano de obra
|
= Coste total de produccion (Manufacturing cost)
```

### Consulta MCP

```sql
-- Precio estandar actual del material
SELECT MATNR, BWKEY, VPRSV, STPRS, VERPR, PEINH, BKLAS, SALK3, LBKUM
FROM MBEW
WHERE MATNR = '{material}' AND BWKEY = '{centro}'

-- Resultado de calculo (itemizacion)
SELECT MATNR, WERKS, KADKY, LOSGR, ELESSION, TYPPS, KSTAR, GPREIS
FROM KEKO
JOIN KEPH ON KEKO.KALNR = KEPH.KALNR
WHERE KEKO.MATNR = '{material}' AND KEKO.WERKS = '{centro}'
AND KEKO.KALKA = '01'
```

### Flujo CK40N — Calculo masivo

```
CK40N: Seleccionar materiales
  → Calcular (costing run)
    → Analizar resultados
      → Marcar (CK24 mark)
        → Liberar (CK24 release)
          → Nuevo precio estandar en MBEW
```

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| CK11N | Crear calculo individual | F0710 |
| CK13N | Visualizar calculo | F0711 |
| CK40N | Costing run (masivo) | — |
| CK24 | Marcar / Liberar precio | — |
| CKM3N | Cockpit Material Ledger | F2839 |

### SPRO Path
`SPRO > Controlling > Product Cost Controlling > Product Cost Planning > Material Cost Estimate > Costing Variant`
