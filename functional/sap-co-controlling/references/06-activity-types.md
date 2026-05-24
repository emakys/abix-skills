# Clases de Actividad (Activity Types)

## Tabla principal: CSLA (datos) + CSLAT (textos)

Las clases de actividad representan servicios internos prestados por centros de coste (ej: horas maquina, horas hombre, kWh).

### Campos clave CSLA

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| KOKRS | Area controlling | 1000 |
| LSTAR | Clase de actividad | 1410 |
| DATAB | Validez desde | 20240101 |
| DATBI | Validez hasta | 99991231 |
| LEIESSION | Clase coste secundaria | 697000 |

### Tipos de tarifa

| Tipo | Descripcion |
|------|-------------|
| 1 | Tarifa plan manual |
| 2 | Tarifa plan automatica (costes plan / cantidad plan) |
| 3 | Tarifa plan politica |
| 4 | Tarifa real automatica (costes reales / cantidad real) |

### Flujo de actividad interna

```
CC Emisor (centro productivo)          CC Receptor (centro consumidor)
  Clase actividad: 1410 (horas maq)
  Tarifa plan: 50 EUR/h
                                        KB21N: 10 horas
  Haber: 500 EUR (clase coste 43)  →   Debe: 500 EUR (clase coste 43)
```

### Consulta MCP

```sql
SELECT L.LSTAR, T.KTEXT, L.LEIESSION
FROM CSLA AS L
JOIN CSLAT AS T ON L.KOKRS = T.KOKRS AND L.LSTAR = T.LSTAR AND T.SPRAS = 'E'
WHERE L.KOKRS = '{area}'
AND L.DATBI >= '{fecha_hoy}'
ORDER BY L.LSTAR
```

### Transacciones principales

| TCode | Descripcion | Fiori App |
|-------|-------------|-----------|
| KL01 | Crear clase actividad | F2003 |
| KP26 | Planificar tarifa/actividad CC | F2723 |
| KB21N | Contabilizar actividad interna | — |
| KSB1 | Partidas individuales CC | F2709 |
