# Avisos de Mantenimiento (Notifications)

## Concepto

El aviso de mantenimiento es el documento central para reportar hallazgos, averias, solicitudes de mantenimiento y actividades. Sirve como registro historico y base estadistica (MTBF/MTTR). Puede generar ordenes de mantenimiento automatica o manualmente.

## Tipos de Aviso

| Tipo | Codigo | Descripcion | Uso |
|------|--------|-------------|-----|
| Averia | M1 | Breakdown/Malfunction notification | Equipo parado o con falla critica |
| Actividad | M2 | Activity/Maintenance request | Solicitud de trabajo planificado |
| General | M3 | General maintenance notification | Observaciones, hallazgos, inspecciones |

### Tipos adicionales comunes
- **PM** — Aviso preventivo (generado por plan de mantenimiento)
- **S1/S2/S3** — Avisos de servicio (CS)
- Tipos custom: definidos en SPRO segun necesidad del cliente

## Estructura del Aviso

### Cabecera (QMEL)
| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| QMNUM | Numero de aviso | 000010001234 |
| QMART | Tipo de aviso | M1 |
| QMTXT | Texto breve | Bomba P-101 no arranca |
| EQUNR | Equipo | 000000012345 |
| TPLNR | Ubicacion tecnica | PLNT-01-AREA-BOMB |
| IWERK | Centro planif mantto | 1000 |
| INGRP | Grupo planificador | 010 |
| PRIESSION | Prioridad | 1 (muy alta) |
| QMDAT | Fecha aviso | 20260524 |
| STRMN | Fecha inicio requerida | 20260524 |
| LTRMN | Fecha fin requerida | 20260525 |
| AUFNR | Orden generada | 000004001234 |
| OBJNR | Numero objeto (status) | QM000010001234 |

### Items de Dano (QMFE)
Registran QUE fallo — parte del objeto + codigo de dano.

| Campo | Descripcion |
|-------|-------------|
| FESSION | Parte del objeto (ej: motor, rodamiento, sello) |
| FEGRP | Grupo de codigo de dano |
| FECOD | Codigo de dano (ej: rotura, desgaste, fuga) |
| OTGRP | Grupo parte objeto |
| OTEIL | Codigo parte objeto |
| FETXT | Texto libre del dano |

### Causas (QMUR)
Registran POR QUE fallo.

| Campo | Descripcion |
|-------|-------------|
| URESSION | Causa (ej: falta lubricacion, fatiga material) |
| URGRP | Grupo causa |
| UESSION | Codigo causa |
| URTXT | Texto libre de causa |

### Actividades/Medidas (QMSM)
Registran QUE se hizo o se hara.

| Campo | Descripcion |
|-------|-------------|
| MESSION | Medida/actividad |
| MNGRP | Grupo actividad |
| MNCOD | Codigo actividad (ej: reemplazo, ajuste, limpieza) |
| MATXT | Texto libre de medida |
| ERESSION | Responsable |

## Catalogos

Los catalogos definen los codigos disponibles para danos, causas y actividades.

| Catalogo | Tipo | Tabla Config | Uso |
|----------|------|-------------|-----|
| B | Danos | QPCT | Que fallo (rotura, desgaste, fuga, cortocircuito) |
| C | Causas | QPCT | Por que fallo (falta mantenimiento, fatiga, error operador) |
| 5 | Actividades | QPCT | Que se hizo (reemplazo, reparacion, ajuste, limpieza) |

### Config SPRO
```
SPRO → Plant Maintenance → Maintenance Processing → Notifications
  → Catalogs → Define catalog profile
  → Catalogs → Assign catalog profile to notification type
  → Define notification types
  → Define priorities
```

### Transacciones de catalogo
- **QS41** — Crear grupo de codigos
- **QS51** — Crear codigos
- **QS61** — Crear codigos de seleccion

## Prioridades

| Prioridad | Texto | Tiempo respuesta tipico |
|-----------|-------|------------------------|
| 1 | Muy alta / Emergencia | Inmediato (< 4h) |
| 2 | Alta / Urgente | < 24h |
| 3 | Media / Normal | < 1 semana |
| 4 | Baja / Planificada | Proximo paro programado |

Config: SPRO → PM → Notifications → Define priorities

## Flujo de Vida del Aviso

```
1. CREADO (IW21) → Status OSNO (Outstanding Notification)
   |
2. EN PROCESO → Asignar responsable, codificar dano/causa
   |
3. ORDEN GENERADA → IW21 boton "Crear orden" o IW31 referencia aviso
   |   → AUFNR se asigna al aviso (QMEL-AUFNR)
   |
4. ACTIVIDADES COMPLETADAS → Registrar acciones realizadas
   |
5. COMPLETADO (IW22 → "Completar") → Status NOPR (Notification in Process → Completed)
```

## Generacion de Orden desde Aviso

### Manual
1. IW21/IW22 → Boton "Crear orden"
2. O: IW31 → campo "Aviso" = numero del aviso

### Automatica (desde plan de mantenimiento)
- Plan de mantenimiento genera aviso + orden automaticamente en IP30
- Config: posicion de mantenimiento (MPOS) define si genera aviso, orden o ambos

## Queries MCP

```
-- Avisos abiertos de un centro
GetSqlQuery("SELECT QMNUM,QMART,QMTXT,EQUNR,TPLNR,PRIESSION,QMDAT FROM QMEL WHERE IWERK='{centro}' AND QMART IN ('M1','M2','M3') AND QMNUM NOT IN (SELECT QMNUM FROM QMEL WHERE QMNUM IN (SELECT OBJNR FROM JEST WHERE STAT='I0068' AND INACT=''))")

-- Detalle de un aviso
GetSqlQuery("SELECT QMNUM,QMART,QMTXT,EQUNR,TPLNR,IWERK,INGRP,PRIESSION,AUFNR,QMDAT,STRMN,LTRMN FROM QMEL WHERE QMNUM='{aviso}'")

-- Items de dano
GetSqlQuery("SELECT FEESSION,FEGRP,FECOD,OTGRP,OTEIL,FETXT FROM QMFE WHERE QMNUM='{aviso}'")

-- Causas
GetSqlQuery("SELECT URESSION,URGRP,UESSION,URTXT FROM QMUR WHERE QMNUM='{aviso}'")

-- Actividades
GetSqlQuery("SELECT MESSION,MNGRP,MNCOD,MATXT FROM QMSM WHERE QMNUM='{aviso}'")

-- Avisos por equipo (historial)
GetSqlQuery("SELECT QMNUM,QMART,QMTXT,QMDAT,PRIESSION FROM QMEL WHERE EQUNR='{equipo}' ORDER BY QMDAT DESC")

-- Top averias por ubicacion tecnica
GetSqlQuery("SELECT TPLNR,COUNT(*) as CNT FROM QMEL WHERE QMART='M1' AND IWERK='{centro}' AND QMDAT >= '{desde}' GROUP BY TPLNR ORDER BY CNT DESC")
```

## Transacciones Principales

| TCode | Descripcion |
|-------|-------------|
| IW21 | Crear aviso |
| IW22 | Modificar aviso |
| IW23 | Visualizar aviso |
| IW28 | Lista avisos (seleccion) |
| IW29 | Lista avisos (multi-nivel) |
| IW24 | Crear aviso con referencia |
| IW25 | Lista de tareas de avisos |
| IW30 | Lista de ubicaciones/avisos |
| IW64 | Avisos completados |
| IW65 | Avisos por objeto tecnico |

## Fiori Apps

| App ID | Nombre | Tipo |
|--------|--------|------|
| F1580 | Create Maintenance Notification | Transactional |
| F2626 | Manage Maintenance Notifications | Transactional |
| F3430 | Maintenance Notification Overview | Analytical |

## Mejores Practicas

1. **Siempre codificar** dano, causa y accion — es la base para estadisticas MTBF/MTTR
2. **Un aviso por falla** — no agrupar multiples fallas en un aviso
3. **Prioridad coherente** — definir criterios claros por tipo de impacto
4. **Generar orden** para todo trabajo que requiera planificacion o registro de costes
5. **Completar aviso** cuando la accion correctiva esta verificada, no antes
6. **No eliminar avisos** — son registro historico. Usar status si se creo por error
