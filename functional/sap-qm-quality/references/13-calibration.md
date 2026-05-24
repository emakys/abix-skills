# Calibracion y Equipos de Medicion

## Concepto

La calibracion garantiza que los equipos de medicion (instrumentos, gauges, balanzas) estan dentro de tolerancia. SAP QM se integra con PM para gestionar calibracion via ordenes de mantenimiento.

## Test Equipment Master

Los equipos de medicion se gestionan como equipos PM (IE01) con datos QM adicionales.

| Tabla | Descripcion |
|-------|-------------|
| EQUI | Equipo (PM master) |
| EQKT | Textos equipo |
| EQUZ | Time segment equipo |
| ITOB | Instalacion tecnica |

```sql
SELECT EQUNR, EQKTX, EQTYP, GEWRK FROM EQUI
WHERE EQUNR = '{equipo}'
```

## Integracion QM-PM para calibracion

```
Equipo de medicion (IE01)
├── Plan de mantenimiento preventivo (IP01)
│   └── Ciclo: cada N meses/usos
│       └── Genera orden PM (IW31)
│           └── Orden tiene tipo inspeccion calibracion
│               └── Lote inspeccion (QALS)
│                   └── Resultados (QE51N)
│                       └── UD → equipo calibrado OK/No OK
```

## Proceso de calibracion

1. **Plan mantenimiento** (IP01): programa calibracion periodica
2. **Orden PM** (IW31): se crea automaticamente por plan
3. **Lote inspeccion**: se genera vinculado a la orden
4. **Registro resultados**: mediciones del equipo vs patron
5. **Decision empleo**: equipo apto (OK) o no apto (bloqueado)
6. **Actualizacion equipo**: fecha proxima calibracion, status

## Datos QM del equipo

| Campo | Descripcion |
|-------|-------------|
| Calibration interval | Frecuencia de calibracion |
| Next calibration date | Proxima fecha |
| Calibration status | OK / Overdue / Blocked |
| Accuracy class | Clase de precision |
| Measurement range | Rango de medicion |

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IE01 | Crear equipo |
| IE02 | Modificar equipo |
| IE03 | Visualizar equipo |
| IK01 | Crear punto medida |
| IW31 | Crear orden PM (calibracion) |
| IP01 | Crear plan mantenimiento |
| QE51N | Registrar resultados calibracion |

## Trazabilidad de calibracion

- Cada calibracion genera un registro (lote + resultados)
- Historial completo por equipo
- Si equipo fuera de tolerancia → investigar mediciones realizadas con ese equipo
- Requisito para ISO 9001, GMP, FDA 21 CFR Part 11

## Consultas MCP

```sql
-- Equipos con calibracion vencida
SELECT EQUNR, EQKTX FROM EQUI
WHERE EQTYP = 'M' -- tipo medicion
-- (fecha proxima calibracion se gestiona via plan PM)

-- Lotes de calibracion
SELECT L.PRUESSION, L.MATNR, L.ERDAT, V.VCODE
FROM QALS L LEFT JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.ART = '06' -- audit/calibration type
AND L.WERKS = '{centro}'
ORDER BY L.ERDAT DESC
```
