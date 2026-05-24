# Clases de Coste (Cost Elements)

## Cambio critico S/4HANA

En S/4HANA, las clases de coste ya no se crean por separado. Cada cuenta de mayor (GL account) que tenga tipo de cuenta P&L es automaticamente una clase de coste.

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Tabla | CSKA / CSKB | SKA1 / SKB1 (GL master) |
| Creacion | KA01 / KA06 | FS00 (cuenta GL) |
| Tipo clase coste (KATYP) | Manual en CSKA | Derivado del tipo de cuenta GL |
| Transaccion | KA01/KA02/KA03 | Siguen funcionando pero redirigen a GL |

## Tipos de clase de coste (KATYP)

### Primarias (costes reales del exterior)

| KATYP | Descripcion | Ejemplo |
|-------|-------------|---------|
| 1 | Clase coste primaria (gasto) | 400000 Salarios |
| 11 | Ingreso primario | 800000 Ventas |
| 12 | Ingreso ventas (CO-PA deduction) | 810000 Descuentos |

### Secundarias (movimientos internos CO)

| KATYP | Descripcion | Ejemplo |
|-------|-------------|---------|
| 21 | Liquidacion interna | 690000 Settlement |
| 22 | Liquidacion externa | 691000 External settlement |
| 31 | Cifra estadistica (orden/CC) | Para valores estadisticos |
| 41 | Recargo overhead | 695000 Overhead applied |
| 42 | Assessment (reparto secundario) | 696000 Assessment |
| 43 | Actividad interna | 697000 Internal activity |

### Consulta MCP

```sql
-- Cuentas P&L que actuan como clases de coste primarias
SELECT SAKNR, TXT50, XBILK, GVTYP
FROM SKAT
WHERE KTOPL = '{plan_cuentas}' AND SPRAS = 'E'
AND XBILK = ''
ORDER BY SAKNR

-- Clases de coste secundarias (siguen en CSKA en S/4)
SELECT KSTAR, KATYP, DATBI
FROM CSKA
WHERE KOKRS = '{area}' AND KATYP >= '21'
ORDER BY KSTAR
```

### Errores frecuentes

| Error | Causa | Fix |
|-------|-------|-----|
| KD 210 | Cuenta no es clase coste | En ECC: KA01 crear. En S/4: verificar tipo cuenta en FS00 |
| KD 302 | No cost element for account | OKB9: activar creacion automatica de clases coste |
| KD 106 | Cost element already exists | Ya existe, verificar validez con KA03 |

### SPRO Path
`SPRO > Controlling > Contabilidad clases coste > Datos maestros > Clases de coste > Creacion automatica (OKB9)`
