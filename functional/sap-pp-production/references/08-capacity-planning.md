# Planificacion de Capacidad

## Concepto

La planificacion de capacidad evalua si los puestos de trabajo pueden absorber la carga generada por las ordenes de produccion/previsionales, y permite nivelar la carga.

## Flujo de capacidad

```
Ordenes previsionales/produccion
→ Operaciones con tiempos (AFVC/PLPO)
→ Puestos de trabajo (CRHD)
→ Necesidad de capacidad (carga)
vs
Capacidad disponible (KAKO)
→ Sobrecarga / Subcarga
→ Nivelacion (manual/automatica)
```

## Tipos de capacidad

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| 001 | Maquina | Capacidad de maquina |
| 002 | Mano de obra | Capacidad de personal |
| 003 | Recurso (PP-PI) | Recurso de produccion |
| 007 | Linea | Capacidad de linea |

## Capacidad disponible — KAKO

```sql
SELECT OBJID, KAPESSION, BEGDA, ENDDA, AESSION, KESSION,
       PAUSE, NUESSION, ANESSION
FROM KAKO
WHERE OBJID = '{objid}'
```

### Calculo capacidad disponible

```
Disponible = (Fin - Inicio - Pausa) × Num_recursos × Utilizacion%
             × Dias laborales (calendario fabrica)

Ejemplo:
  Turno: 06:00-14:00 (8h), pausa 30min = 7.5h
  Recursos: 3 maquinas
  Utilizacion: 85%
  Dias mes: 22
  → Disponible mensual = 7.5 × 3 × 0.85 × 22 = 421 horas
```

## Necesidad de capacidad (carga)

Se calcula desde operaciones de ordenes:

```
Carga operacion = Setup + (Machine_time × Qty / Base_qty)
                = VGW01 + (VGW02 × GAMNG / BMSCH)
```

```sql
-- Carga por puesto de trabajo
SELECT V.ARBID, H.ARBPL, SUM(V.VGW01 + V.VGW02) AS CARGA_TOTAL
FROM AFVC V
INNER JOIN CRHD H ON V.ARBID = H.OBJID
INNER JOIN AFKO K ON V.AUFPL = K.AUFPL
WHERE H.WERKS = '{centro}'
AND K.GSTRP BETWEEN '{fecha_ini}' AND '{fecha_fin}'
GROUP BY V.ARBID, H.ARBPL
```

## Evaluacion de capacidad

### Transacciones de evaluacion

| TCode | Vista | Descripcion |
|-------|-------|-------------|
| CM01 | Puesto trabajo | Carga vs capacidad por puesto |
| CM02 | Puesto trabajo (lista) | Lista detallada |
| CM04 | Centro trabajo (backlog) | Atrasos |
| CM05 | Orden | Carga por orden |
| CM07 | Vista general | Tabla resumen todos los puestos |
| CM21 | Perfil de carga | Grafico barras |
| CM25 | Pool | Evaluacion pool capacidades |
| CM50 | Lista de capacidad | Vista de todas las capacidades |

### Indicadores clave

| Indicador | Formula | Interpretacion |
|-----------|---------|----------------|
| Carga % | Necesidad / Disponible × 100 | >100% = sobrecarga |
| Horas libres | Disponible - Necesidad | Negativo = faltante |
| Backlog | Operaciones atrasadas | Requiere accion |

## Nivelacion de capacidad

### Manual (CM01/CM02)
- Mover operaciones a otros periodos
- Reasignar a otros puestos de trabajo
- Split de operaciones
- Ajustar turnos/overtime

### Automatica
- **PP/DS** (APO/IBP): Programacion detallada con restricciones
- **Finite scheduling**: Respeta limites de capacidad
- **Infinite scheduling**: Ignora limites (default MRP)

## Estrategias de scheduling

| Tipo | Descripcion |
|------|-------------|
| Forward | Desde fecha inicio → calcula fin |
| Backward | Desde fecha fin → calcula inicio |
| Midpoint | Desde operacion referencia en ambas direcciones |

### Scheduling en MRP

| Nivel | Descripcion | Precision |
|-------|-------------|-----------|
| Basic dates | Solo lead time (MARC-DZEIT) | Baja |
| Lead time scheduling | Operaciones routing | Alta |

## Turnos — T550A

```sql
SELECT MESSION, TESSION, ENDDA, BEGDA, PAESSION, PESSION
FROM T550A
WHERE MESSION = '{modelo_turno}'
```

| Campo | Descripcion |
|-------|-------------|
| MESSION | Modelo de turno |
| TESSION | Definicion turno |
| PAESSION | Pausa |

## Pool de capacidades

Agrupa puestos de trabajo intercambiables:
- Permite que MRP asigne carga al puesto con disponibilidad
- Configurado en CR01 (vista pooling)

## Fiori apps

| App ID | Nombre | Funcion |
|--------|--------|---------|
| F2428 | Manage Production Orders | Incluye vista capacidad |
| F3814 | Monitor Capacity Load | Dashboard capacidad |
| F1596 | Schedule Production Orders | Scheduling interactivo |

## Consultas MCP diagnostico

```sql
-- Capacidad disponible por puesto
SELECT H.ARBPL, K.AESSION, K.KESSION, K.PAUSE, K.NUESSION, K.ANESSION
FROM CRHD H
INNER JOIN KAKO K ON H.OBJID = K.OBJID
WHERE H.WERKS = '{centro}'

-- Carga acumulada por puesto (periodo)
SELECT H.ARBPL, COUNT(*) AS NUM_OPER, SUM(V.VGW01) AS SETUP_TOTAL, SUM(V.VGW02) AS MACHINE_TOTAL
FROM AFVC V
INNER JOIN CRHD H ON V.ARBID = H.OBJID
INNER JOIN AFKO K ON V.AUFPL = K.AUFPL
WHERE H.WERKS = '{centro}'
AND K.GSTRP BETWEEN '{ini}' AND '{fin}'
GROUP BY H.ARBPL
```
