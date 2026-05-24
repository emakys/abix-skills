# Replenishment — Reabastecimiento

## Concepto General

El **Reabastecimiento (Replenishment)** en EWM es el proceso de mover stock desde ubicaciones de almacenamiento masivo (bulk storage) o reserva hacia ubicaciones de picking activo (picking face bins), asegurando que siempre haya suficiente stock disponible para el picking eficiente.

En S/4HANA 2023 con Embedded EWM, el reabastecimiento se gestiona completamente dentro de EWM sin depender de MM para los movimientos internos del almacen. Los warehouse tasks (WT) de reabastecimiento se diferencian de los WT de picking por su warehouse process type especifico.

Transaccion de monitor: `/SCWM/MON` > Replenishment o `/SCWM/REPL`

## Tipos de Reabastecimiento

### 1. Reabastecimiento de Bin Fijo (Fixed Bin Replenishment)
El metodo mas comun. Cada material tiene asignado un **bin fijo de picking** (fixed bin) y un **bin de reserva** (bulk bin).

Logica:
- El sistema monitorea el stock en el bin fijo de picking
- Cuando el stock cae por debajo del **minimo (min quantity)**, se genera un WT de reabastecimiento
- El WT mueve stock desde el bin de reserva hasta el bin fijo de picking
- La cantidad a reponer lleva el stock hasta la **cantidad maxima (max quantity)**

Configuracion en `/SCWM/LGPLA` (bin master data):
- `MIN_QTY`: Cantidad minima que dispara el reabastecimiento
- `MAX_QTY`: Cantidad maxima (cantidad objetivo tras reponer)
- `REPL_LGTYP`: Storage type fuente del reabastecimiento
- Indicador de bin fijo activo

### 2. Reabastecimiento Min/Max
Variante del bin fijo con umbrales configurables independientes:

- **Punto de reorden (reorder point)**: cantidad que activa el reabastecimiento
- **Cantidad de reabastecimiento (replenishment qty)**: cantidad fija a mover en cada reabastecimiento
- **Stock maximo (max stock)**: limite superior en el bin de picking

Permite mayor flexibilidad que el fixed bin puro.

### 3. Reabastecimiento Basado en Demanda / Planificado (Demand-Based)
Usa las ordenes de almacen pendientes (warehouse orders) o delivery orders para anticipar la necesidad:

- El sistema analiza las necesidades de picking futuras (wave management)
- Calcula si el stock en el bin de picking sera suficiente para completar la wave
- Si no alcanza, genera el reabastecimiento **antes** de que comience el picking
- Evita interrupciones durante la ejecucion de la wave
- Requiere integracion con wave management

### 4. Reabastecimiento Automatico (Automatic / Triggered)
El sistema genera WT de reabastecimiento automaticamente cuando:
- Se confirma un WT de picking que deja el bin por debajo del minimo
- Se ejecuta un job periodico de verificacion de niveles de stock
- Se calcula la necesidad durante la creacion de warehouse orders

El reabastecimiento automatico se activa mediante la configuracion del **replenishment rule** en el warehouse process type.

### 5. Reabastecimiento Manual
El planificador de almacen crea manualmente los WT de reabastecimiento:
- Via `/SCWM/MON` > Replenishment > Create Manually
- Util para situaciones especiales o ajustes puntuales
- No sigue las reglas automaticas, control total del operador

## Configuracion de Reglas de Reabastecimiento

### Regla de Reabastecimiento (Replenishment Rule)
Definida en IMG > EWM > Replenishment > Define Replenishment Rules

Parametros de la regla:
- **Tipo de reabastecimiento**: fixed bin, min/max, demand-based
- **Storage type fuente**: de donde viene el stock de reposicion
- **Storage section fuente**: seccion dentro del storage type fuente
- **Sorting**: criterio de seleccion de bins fuente (FIFO, FEFO, etc.)
- **Minimum fill rate**: % minimo de llenado del WT antes de ejecutar
- **Batch splitting**: permitir o no mezcla de lotes en bin de picking

### Determinacion de la Regla
La regla se determina por:
1. Warehouse process type del WT de reabastecimiento
2. Warehouse number + storage type de destino
3. Material (opcionalmente por material o grupo)

### Storage Type de Origen y Destino

**Flujo tipico:**
```
Bulk Storage (BULK) → High Bay (HBAY) → Picking Face (PICK)
      [reabastecimiento nivel 2]     [reabastecimiento nivel 1]
```

Configuracion de la jerarquia:
- Storage type PICK: replenish desde HBAY
- Storage type HBAY: replenish desde BULK
- El sistema puede encadenar reabastecimientos en cascada

## Creacion de WT de Reabastecimiento

### Proceso automatico
1. Evento disparador: picking confirma bin bajo minimo, o job programado
2. Sistema verifica regla de reabastecimiento aplicable
3. Busqueda de stock en storage type fuente (segun estrategia de stock removal)
4. Creacion del WT: origen (bulk bin) → destino (picking bin)
5. Asignacion al grupo de recursos (resource group) apropiado
6. Ejecucion por el operario (RF/Fiori)

### Warehouse Process Type para Reabastecimiento
Configurar un WPT especifico para reabastecimiento:
- Category: Internal Replenishment
- HU-relevant: segun si se mueven HU completas o contenido
- Confirmacion: una etapa (single step) o dos etapas (two-step)
- Priority: mas alta que tareas de picking regular

## Manejo de Prioridades

El reabastecimiento compite con otras tareas en la cola del almacen:
- **Prioridad del WT**: campo numerico (1=mayor prioridad, 99=menor)
- Reabastecimiento urgente (bin en cero) → prioridad maxima
- Reabastecimiento preventivo → prioridad media
- Configuracion en el warehouse process type y/o en la regla

Los resource managers pueden ver y reordenar prioridades en `/SCWM/MON`.

## Reabastecimiento Especifico de Lote (Batch-Specific)

Cuando el picking es batch-determinado (FEFO, FIFO):
- El reabastecimiento debe respetar el mismo lote que se necesita para el picking
- Configuracion: batch-specific replenishment = activo en regla
- El sistema busca especificamente el lote requerido en bulk storage
- Si no encuentra el lote, puede generar excepcion o usar lote alternativo

## Monitor de Reabastecimiento

Transaccion: `/SCWM/MON` > Replenishment Tab

Funcionalidades:
- Vista de todos los bins por debajo del minimo
- Estado de WT de reabastecimiento pendientes / en proceso / completados
- Alertas de stock-out en bins de picking
- Reabastecimiento manual desde el monitor
- Filtros por storage type, section, material, recurso

Fiori: App "Monitor Replenishment" (parte del Warehouse Management Fiori group)

## Reabastecimiento Planificado vs Disparado

| Aspecto | Planificado | Disparado |
|---------|-------------|-----------|
| Cuando | Antes de wave | Al confirmar picking |
| Base | Demanda futura | Stock actual |
| Riesgo | Sobrestock | Stock-out momentaneo |
| Mejor para | Alta rotacion, waves planificadas | Flujo continuo, demanda variable |

## Tablas Principales

| Tabla | Descripcion |
|-------|-------------|
| `/SCWM/LGPLA` | Master data de bins (min/max qty, repl config) |
| `/SCWM/REPLRULE` | Reglas de reabastecimiento |
| `/SCWM/REPLRULEI` | Items / condiciones de reglas de reabastecimiento |
| `/SCWM/T331` | Warehouse process types (incluye reabastecimiento) |
| `/SCWM/WHO` | Warehouse orders (incluye WT de reabastecimiento) |
| `/SCWM/WHOI` | Items de warehouse orders |

## Consultas MCP Recomendadas

```
-- Explorar logica de reabastecimiento
SearchObject: tipo CLAS, nombre "/SCWM/CL_REPL*"
ReadClass: /SCWM/CL_REPL_CTRL → controlador principal de reabastecimiento
GetFunctionGroup: /SCWM/REPLENISHMENT → funciones core

-- Ver configuracion de bins
SearchObject: tipo TABL, nombre "/SCWM/LGPLA" → estructura bin master
GetObjectSource: via ADT URI para includes de reabastecimiento

-- BAdIs de extension
SearchObject: tipo DEVC, nombre "/SCWM/REPLENISHMENT"
```

## Configuracion IMG

```
IMG > Extended Warehouse Management
  > Replenishment
    > Define Replenishment Rules
    > Assign Replenishment Rules to Storage Types
    > Configure Automatic Replenishment Triggers
    > Define Replenishment Warehouse Process Types
  > Internal Warehouse Processes
    > Replenishment
      > Activate Replenishment per Warehouse
```

## Mejores Practicas S/4HANA 2023

- Usar demand-based replenishment junto con wave management para maxima eficiencia
- Definir min/max por material y bin basado en datos historicos de picking
- Configurar prioridades diferenciadas: urgente (bin en 0) vs preventivo
- Monitorear KPI: stockouts en picking face, reabastecimientos por turno, tiempo promedio de reposicion
- Para almacenes con picking por batch: activar siempre batch-specific replenishment
- Programar job automatico `/SCWM/REPLENISHMENT` cada 15-30 minutos en horario pico
- Usar slotting (/SCWM/SLO) para optimizar la asignacion bin fijo y cantidades min/max
