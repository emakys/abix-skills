# Mantenimiento Preventivo

## Concepto

El mantenimiento preventivo programa trabajos de mantenimiento periodicos automaticamente. Basado en tiempo (calendario), rendimiento (contadores) o condicion (mediciones). El sistema genera avisos u ordenes segun programacion.

## Componentes Clave

```
Estrategia de Mantenimiento (IP11)
  → Define paquetes (cada 3 meses, cada 6 meses, anual)
  |
Hoja de Ruta / Task List (IA01/IA11)
  → Define operaciones estandar
  |
Posicion de Mantenimiento (IP04/IP05)
  → Vincula: objeto tecnico + hoja ruta + estrategia
  |
Plan de Mantenimiento (IP01/IP02)
  → Agrupa posiciones, define parametros de programacion
  |
Programacion (IP10/IP30)
  → Genera llamadas → crea ordenes/avisos automaticamente
```

## Estrategias de Mantenimiento (T351)

### Concepto
Define intervalos de mantenimiento en paquetes. Un paquete = una frecuencia.

### Tipos
- **Basada en tiempo**: paquetes en dias, semanas, meses, anos
- **Basada en rendimiento**: paquetes en unidades de contador (horas, km, ciclos)

### Ejemplo — Estrategia para bomba
| Paquete | Ciclo | Descripcion |
|---------|-------|-------------|
| 01 | 90 dias | Inspeccion trimestral |
| 02 | 180 dias | Mantenimiento semestral |
| 03 | 365 dias | Overhaul anual |

### Tablas
| Tabla | Contenido |
|-------|-----------|
| T351 | Cabecera estrategia |
| T351P | Paquetes de estrategia |
| T351G | Textos estrategia |

Config: SPRO → PM → Preventive Maintenance → Maintenance Planning → Maintenance Strategies

## Planes de Mantenimiento (MPLA)

### Tipos
| Tipo | Descripcion | Uso |
|------|-------------|-----|
| Ciclo unico | Una sola ejecucion | Calibracion puntual, revision unica |
| Estrategia multiple | Multiples paquetes ciclicos | Mantenimiento periodico regular |
| Basado en rendimiento | Paquetes por contador | Cada X horas, cada Y km |
| Multiple contadores | Varios contadores combinados | El primero que se cumpla dispara |

### Campos Clave (MPLA)
| Campo | Descripcion |
|-------|-------------|
| WARPL | Numero plan |
| WAESSION | Tipo plan |
| ABESSION | Indicador de llamada |
| STESSION | Status (A=activo, I=inactivo) |
| HOESSION | Horizonte de apertura (%) |
| SFESSION | Factor de programacion |

### Posiciones de Mantenimiento (MPOS)
| Campo | Descripcion |
|-------|-------------|
| POINT | Posicion |
| EQUNR | Equipo |
| TPLNR | Ubicacion tecnica |
| PLNTY | Tipo hoja ruta |
| PLNNR | Numero hoja ruta |
| QMART | Tipo aviso a generar |
| AUESSION | Tipo orden a generar |

## Programacion (IP10/IP30)

### IP10 — Programar plan individual
- Calcula proximas fechas segun estrategia
- Muestra fechas planificadas futuras
- Permite ajustar manualmente

### IP30 — Programar masivo (batch)
- Seleccion por centro, grupo planificador, plan
- Genera ordenes/avisos para el horizonte definido
- Ejecutar periodicamente (diario/semanal) via job de fondo

### Parametros de Programacion
- **Horizonte de apertura**: porcentaje del ciclo — a partir de que % generar la orden
- **Factor programacion**: adelantar o atrasar generacion
- **Tolerancia**: dias de tolerancia para reprogramacion

## Historial de Llamadas (MHIS)

Registra cada ejecucion del plan: fecha llamada, fecha prevista, orden/aviso generado.

```
GetSqlQuery("SELECT WARPL,LESSION,ESSION,TESSION,AUFNR,QMNUM FROM MHIS WHERE WARPL='{plan}' ORDER BY TESSION DESC")
```

## Queries MCP

```
-- Planes activos de un centro
GetSqlQuery("SELECT MPLA.WARPL,MPLA.STESSION,MPOS.EQUNR,MPOS.TPLNR FROM MPLA JOIN MPOS ON MPLA.WARPL=MPOS.WARPL WHERE MPLA.STESSION='A'")

-- Estrategias disponibles
GetSqlQuery("SELECT STESSION,ESSION FROM T351 WHERE SPRAS='E'")

-- Paquetes de una estrategia
GetSqlQuery("SELECT PAESSION,NESSION,MENESSION,EINESSION FROM T351P WHERE STESSION='{estrategia}'")

-- Proximas fechas de un plan
GetSqlQuery("SELECT WARPL,LESSION,NESSION FROM MHIS WHERE WARPL='{plan}' ORDER BY LESSION DESC")

-- Posiciones de un plan
GetSqlQuery("SELECT POINT,EQUNR,TPLNR,PLNTY,PLNNR,QMART,AUESSION FROM MPOS WHERE WARPL='{plan}'")
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IP01 | Crear plan mantenimiento |
| IP02 | Modificar plan |
| IP03 | Visualizar plan |
| IP04 | Crear posicion mantenimiento |
| IP05 | Modificar posicion |
| IP10 | Programar plan individual |
| IP11 | Crear/modificar estrategia |
| IP12 | Visualizar estrategia |
| IP15 | Lista estrategias |
| IP16 | Lista planes |
| IP17 | Lista posiciones |
| IP19 | Lista llamadas |
| IP24 | Resumen planes para objeto |
| IP30 | Programacion masiva |
| IP42 | Monitoreo de planes |

## Mejores Practicas

1. **Estrategias reutilizables** — una estrategia para muchos planes del mismo tipo de equipo
2. **Horizonte de apertura 80%** — genera orden con 20% de anticipacion al vencimiento
3. **IP30 en job diario** — automatizar generacion de ordenes
4. **Monitorear IP42** — verificar planes con llamadas atrasadas o sin ejecutar
5. **Contadores actualizados** — para planes basados en rendimiento, asegurar lecturas regulares
6. **Combinar tiempo + rendimiento** — el que llegue primero dispara (maxima proteccion)
