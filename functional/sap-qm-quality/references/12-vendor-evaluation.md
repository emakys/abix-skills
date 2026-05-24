# Evaluacion de Proveedores (Quality Criteria)

## Concepto

QM alimenta la evaluacion de proveedores de MM con datos de calidad. El quality score de inspecciones GR actualiza automaticamente el criterio de calidad del proveedor.

## Criterios de evaluacion MM

| Criterio | Fuente | Peso tipico |
|----------|--------|-------------|
| Price | MM (precios) | 30% |
| Quality | QM (inspecciones) | 30% |
| Delivery | MM (entregas) | 25% |
| Service | Manual | 15% |

## Quality score en vendor evaluation

### Calculo automatico
1. GR con inspeccion tipo 01
2. Resultados + UD → quality score (QAVE-VBESSION)
3. Score se propaga a evaluacion proveedor
4. ME61 muestra score actualizado

### Formula quality score
```
Quality Score = f(lotes aceptados, lotes rechazados, quality level)
             = (lotes aceptados / total lotes) × 100
             ajustado por severidad de rechazos
```

## Transacciones evaluacion

| TCode | Descripcion |
|-------|-------------|
| ME61 | Evaluacion proveedor |
| ME62 | Modificar evaluacion |
| ME63 | Visualizar evaluacion |
| ME64 | Recalcular automatico |
| ME65 | Lista evaluacion |

## Configuracion SPRO

```
SPRO > Materials Management > Purchasing > Vendor Evaluation
├── Define Main Criteria (Quality = subcriteria from QM)
├── Define Subcriteria
│   └── Quality subcriteria:
│       ├── Incoming inspection quality
│       ├── Complaint rate
│       └── Audit results
├── Define Scoring Methods
└── Assign to Purchasing Organization
```

## Datos desde QM

```sql
-- Quality score por proveedor/material
SELECT L.LIFNR, L.MATNR, V.VCODE, V.VBESSION, V.VDATUM
FROM QALS L INNER JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.LIFNR = '{proveedor}' AND L.ART = '01'
ORDER BY V.VDATUM DESC

-- Tasa de rechazo por proveedor
SELECT L.LIFNR,
  COUNT(*) AS TOTAL,
  SUM(CASE WHEN V.VCODE = 'R' THEN 1 ELSE 0 END) AS RECHAZADOS
FROM QALS L INNER JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.WERKS = '{centro}' AND L.ART = '01'
AND V.VDATUM BETWEEN '{ini}' AND '{fin}'
GROUP BY L.LIFNR

-- Avisos Q3 por proveedor
SELECT LIFNR, COUNT(*) AS COMPLAINTS FROM QMEL
WHERE QMART = 'Q3' AND ERDAT BETWEEN '{ini}' AND '{fin}'
GROUP BY LIFNR ORDER BY COMPLAINTS DESC
```

## Vendor audit (tipo inspeccion 06)

- Auditoria en sitio del proveedor
- Lote de inspeccion tipo 06 (manual)
- Plan de inspeccion con criterios de auditoria
- Resultados alimentan evaluacion

## Blocked vendor por calidad

Si quality score cae debajo de umbral:
- Bloqueo automatico del proveedor (si configurado)
- Alerta a compras
- Requiere accion correctiva (aviso Q3) para desbloquear
