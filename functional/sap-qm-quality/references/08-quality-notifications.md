# Avisos de Calidad (Quality Notifications)

## Concepto

Los avisos de calidad documentan problemas, reclamos y no conformidades. Permiten registrar defectos, causas, acciones correctivas y hacer seguimiento hasta el cierre.

## Tipos de aviso

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| Q1 | Internal problem report | Problema interno de calidad |
| Q2 | Customer complaint | Reclamo de cliente |
| Q3 | Vendor complaint | Reclamo a proveedor |
| Q4 | Internal audit | Hallazgo de auditoria |
| QM | General QM notification | Generico |

## Tablas principales

| Tabla | Descripcion |
|-------|-------------|
| QMEL | Cabecera aviso |
| QMFE | Items / defectos |
| QMUR | Causas |
| QMSM | Actividades / tareas |
| QMMA | Actividades del item |
| JEST | Status aviso |

## QMEL — Cabecera

```sql
SELECT QMNUM, QMART, QMTXT, MATNR, WERKS, LIFNR, KESSION,
       ERDAT, ERNAM, PRIESSION, STAT, AUFNR, PRUESSION
FROM QMEL
WHERE QMNUM = '{aviso}'
```

| Campo | Descripcion |
|-------|-------------|
| QMNUM | Numero aviso |
| QMART | Tipo (Q1, Q2, Q3) |
| QMTXT | Texto corto |
| MATNR | Material |
| WERKS | Centro |
| LIFNR | Proveedor (Q3) |
| KESSION | Cliente (Q2) |
| PRIESSION | Prioridad |
| PRUESSION | Lote inspeccion (si viene de UD) |

## QMFE — Items de defecto

```sql
SELECT QMNUM, FEESSION, FESSION, OTESSION, FESSION,
       FEGRP, FECOD, FEESSION
FROM QMFE
WHERE QMNUM = '{aviso}'
```

| Campo | Descripcion |
|-------|-------------|
| FEESSION | Numero item |
| FESSION | Texto defecto |
| OTESSION | Posicion defecto (ubicacion) |
| FEGRP | Grupo codigo defecto |
| FECOD | Codigo defecto |
| FEESSION | Cantidad defectuosa |

## QMUR — Causas

```sql
SELECT QMNUM, UESSION, URESSION, URGRP, URCOD, ESSION
FROM QMUR
WHERE QMNUM = '{aviso}'
```

| Campo | Descripcion |
|-------|-------------|
| UESSION | Numero causa |
| URGRP | Grupo codigo causa |
| URCOD | Codigo causa |
| ESSION | Texto causa |

## QMSM — Actividades/tareas

```sql
SELECT QMNUM, MESSION, MATXT, PESSION, MNGRP, MNCOD,
       ERDAT, LTRMN, SESSION
FROM QMSM
WHERE QMNUM = '{aviso}'
```

| Campo | Descripcion |
|-------|-------------|
| MESSION | Numero actividad |
| MATXT | Texto actividad |
| PESSION | Responsable |
| MNGRP | Grupo codigo actividad |
| MNCOD | Codigo actividad |
| LTRMN | Fecha limite |
| SESSION | Status actividad |

## Status del aviso

| Status | Descripcion |
|--------|-------------|
| OSNO | Outstanding notification (abierto) |
| NOCO | Notification completed |
| TACO | Task completed |
| NOPR | In process |

## Flujo del aviso

```
Creacion (QM01)
├── Defect items (que fallo)
├── Causes (por que fallo)
├── Tasks/Activities (que hacer)
│   ├── Immediate actions
│   ├── Corrective actions
│   └── Preventive actions
├── Follow-up (seguimiento)
└── Close (QM02 → complete)
```

## 8D Report mapping

| Paso 8D | Equivalente QM |
|---------|----------------|
| D1: Team | Responsable aviso + partners |
| D2: Problem description | QMEL header + QMFE items |
| D3: Containment | Immediate activities (QMSM) |
| D4: Root cause | QMUR causes |
| D5: Corrective action | Corrective activities (QMSM) |
| D6: Verification | Activity completion + results |
| D7: Preventive action | Preventive activities (QMSM) |
| D8: Closure | Notification complete |

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| QM01 | Crear aviso calidad |
| QM02 | Modificar aviso |
| QM03 | Visualizar aviso |
| QM10 | Lista avisos por material |
| QM11 | Lista avisos por proveedor |
| QM12 | Lista avisos por cliente |
| QM13 | Lista avisos multi-criterio |
| QM19 | Lista avisos para cierre |

## Avisos automaticos

| Trigger | Cuando |
|---------|--------|
| UD Reject | Decision empleo rechazada → Q3 automatico |
| UD Conditional | Decision condicional → aviso |
| Customer return | Devolucion SD → Q2 |
| Incoming inspection fail | Tipo 01 rechazado → Q3 |

## Consultas MCP diagnostico

```sql
-- Avisos abiertos por centro
SELECT QMNUM, QMART, QMTXT, MATNR, ERDAT, PRIESSION
FROM QMEL
WHERE WERKS = '{centro}' AND STAT NOT LIKE '%NOCO%'
ORDER BY PRIESSION, ERDAT

-- Avisos de un proveedor
SELECT QMNUM, QMTXT, MATNR, ERDAT FROM QMEL
WHERE LIFNR = '{proveedor}' AND QMART = 'Q3'
ORDER BY ERDAT DESC

-- Actividades pendientes
SELECT M.QMNUM, M.MESSION, M.MATXT, M.PESSION, M.LTRMN
FROM QMSM M INNER JOIN QMEL E ON M.QMNUM = E.QMNUM
WHERE E.WERKS = '{centro}' AND M.SESSION NOT LIKE '%COMP%'
ORDER BY M.LTRMN

-- Top defectos por periodo
SELECT F.FEGRP, F.FECOD, COUNT(*) AS QTY
FROM QMFE F INNER JOIN QMEL E ON F.QMNUM = E.QMNUM
WHERE E.WERKS = '{centro}' AND E.ERDAT BETWEEN '{ini}' AND '{fin}'
GROUP BY F.FEGRP, F.FECOD ORDER BY QTY DESC
```
