# Material Ledger y Actual Costing

## Material Ledger en S/4HANA

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Obligatorio | Opcional | **Obligatorio** |
| Tabla | MLCD, MLCR, CKMLHD | ACDOCA + CKMLHD |
| Actual costing | Opcional | Integrado |
| Multi-currency | 3 monedas max | Hasta 10 monedas |

## Flujo de cierre Material Ledger (CKMLCP)

```
1. Determinar precio preliminar
   → Recopilar todos los movimientos del periodo
   → Calcular precio promedio ponderado

2. Determinar precio real (single/multi-level)
   → Single-level: precio real del material individual
   → Multi-level: propagar diferencias por BOM (bottom-up)

3. Revalorizar inventario
   → Calcular diferencia: precio real - precio estandar
   → Contabilizar ajuste en ACDOCA

4. Cerrar periodo ML
```

### Tipos de diferencia

| Tipo | Descripcion | Cuenta tipica |
|------|-------------|---------------|
| PPV | Diferencia precio compra vs estandar | PRD (OBYC) |
| Production variance | Diferencia produccion vs estandar | Cuentas varianza |
| Exchange rate diff | Diferencia tipo cambio | Cuenta TC |
| Revaluation | Ajuste ML al cierre | Cuenta revaluacion |

### Consulta MCP

```sql
-- Precio actual vs estandar
SELECT MATNR, BWKEY, VPRSV, STPRS, VERPR, PEINH, SALK3, LBKUM
FROM MBEW
WHERE MATNR = '{material}' AND BWKEY = '{centro}'

-- Estado Material Ledger
SELECT KALNR, MATNR, BWKEY, BDATJ, PVPRS
FROM CKMLHD
JOIN CKMLCR ON CKMLHD.KALNR = CKMLCR.KALNR
WHERE CKMLHD.MATNR = '{material}' AND CKMLHD.BWKEY = '{centro}'
```

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| CKM3N | Material Ledger cockpit | F2839 |
| CKMLCP | Cierre Material Ledger | — |
| MR22 | Revalorizar stock manual | — |
