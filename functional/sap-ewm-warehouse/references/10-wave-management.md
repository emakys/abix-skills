# Wave Management (Gestión de Oleadas)

## Concepto

Una **Wave** (oleada) es una agrupación de outbound deliveries (o posiciones de entrega) que se procesarán juntas en picking. El Wave Management permite coordinar y optimizar el trabajo de picking agrupando demandas similares para maximizar la eficiencia del almacén.

Sin waves, cada entrega genera sus WTs de forma independiente. Con waves, múltiples entregas se procesan coordinadamente, permitiendo picking por zona, por ruta de transporte, o por ventana de tiempo.

## Relación Wave — Deliveries — WTs

```
Wave
├── Outbound Delivery 1
│   ├── Posición 10 → Warehouse Task
│   └── Posición 20 → Warehouse Task
├── Outbound Delivery 2
│   └── Posición 10 → Warehouse Task
└── Outbound Delivery N
    └── Posición 10 → Warehouse Task
```

Las WTs se crean al **liberar** la wave, no al asignar las entregas.

## Creación de Waves

### Manual
- Transacción `/SCWM/WAVE` — Monitor de Waves.
- El planificador selecciona entregas manualmente y las agrupa en una wave.
- Útil para casos especiales, urgencias o ajustes de última hora.
- Pasos: Abrir monitor → Seleccionar entregas en lista → Crear Wave → Asignar template.

### Automática (Wave Template)
- El sistema crea y libera waves en segundo plano según criterios definidos.
- Un job programado evalúa las entregas pendientes y las asigna a waves.
- La liberación puede ser automática (inmediata) o manual (el planificador aprueba).

## Wave Template

El Wave Template es la configuración maestra que define cómo se crean las waves automáticamente.

### Criterios de Agrupación (Wave Template Criteria)

| Criterio | Descripción |
|----------|-------------|
| Ruta de transporte | Agrupa entregas del mismo camión/ruta |
| Ship-to Party | Agrupa por destinatario (cliente) |
| Prioridad de entrega | Urgentes en wave separada |
| Cutoff Time | Fecha/hora límite de expedición |
| Zona de picking | Entregas que usan la misma zona |
| Carrier / Transportista | Por empresa de transporte |
| Tipo de entrega | Estándar, urgente, frío, peligroso |
| Período de tiempo | Ventana horaria de expedición |

### Parámetros del Template

- **Máximo de entregas por wave:** límite de agrupación.
- **Máximo de posiciones por wave:** control del volumen de picking.
- **Regla de creación de WOs:** qué regla se aplica al liberar la wave.
- **Cola de destino:** a qué cola van las WOs generadas.
- **Horizonte de planificación:** cuánto tiempo hacia adelante se miran las entregas.
- **Liberación automática:** si la wave se libera sola o requiere aprobación.

Configuración en `/SCWM/WAVE_TPL` — Wave Template.

## Proceso Completo de Wave

```
1. CREACIÓN
   Outbound Deliveries disponibles
         │
         ▼
   Evaluación de Wave Template (criterios de agrupación)
         │
         ▼
   Wave creada en estado "ABIERTA"

2. REVISIÓN (opcional)
   Planificador revisa contenido de wave
   Puede agregar/quitar entregas manualmente

3. LIBERACIÓN (Wave Release)
   Wave pasa a estado "LIBERADA"
         │
         ▼
   Creación de Warehouse Tasks (una por posición de entrega)
         │
         ▼
   Creación de Warehouse Orders (agrupación de WTs)
         │
         ▼
   WOs asignadas a colas de trabajo

4. PROCESAMIENTO
   Operarios ejecutan WTs (picking)
   Confirmación de WTs en RF / Fiori

5. COMPLETADO
   Todas las WTs confirmadas → Wave completada
   Entregas actualizadas → listas para expedición
```

## Monitor de Waves: /SCWM/WAVE

La transacción `/SCWM/WAVE` es el centro de control del Wave Management.

Funcionalidades:
- Vista de todas las waves por estado, fecha, template.
- Drill-down a entregas asignadas a cada wave.
- Drill-down a WTs y WOs generadas.
- Acciones: crear wave, liberar wave, cancelar wave, reasignar entregas.
- Indicadores de progreso: % de WTs confirmadas por wave.
- Alertas de waves con entregas próximas al cutoff time.

## Estados de una Wave

| Estado | Código | Descripción |
|--------|--------|-------------|
| Abierta | 01 | Creada, en preparación, sin WTs |
| En Proceso | 02 | Liberada, WTs creadas, picking en curso |
| Completada | 03 | Todas las WTs confirmadas |
| Cancelada | 04 | Anulada antes o durante el proceso |
| Liberada Parcialmente | 05 | Algunas posiciones liberadas, otras pendientes |

## División de Waves (Wave Splitting)

Una wave puede dividirse en sub-waves cuando:
- El volumen supera la capacidad de procesamiento simultáneo.
- Se requiere separar por zona de picking para optimizar el recorrido.
- Parte de las entregas tiene mayor prioridad (split urgente vs. estándar).

División manual desde `/SCWM/WAVE` o automática por regla en el template.

## Entregas de Última Hora (Late-Arriving Items)

Cuando llega una entrega urgente después de que la wave fue liberada:

- **Opción 1:** Agregar a wave existente (si aún hay WTs pendientes).
- **Opción 2:** Crear una nueva wave urgente (wave de una sola entrega).
- **Opción 3:** Crear la WT manualmente sin wave (para casos excepcionales).

Configuración de política de adición tardía en el wave template.

## Control de Capacidad de Waves

El sistema puede limitar el tamaño de una wave por:

- **Número de posiciones de entrega:** evita sobrecargar el área de picking.
- **Volumen total en m³:** control por capacidad física.
- **Peso total en kg:** control por capacidad de recursos.
- **Número de WOs que se generarán:** evita saturar las colas de trabajo.

Cuando se alcanza el límite, el sistema crea una nueva wave con las entregas restantes.

## Pick-to-Zero

Pick-to-Zero es una estrategia donde el objetivo es vaciar completamente los bins de picking activo durante la wave.

- Se planifica la wave para que la cantidad total a picar vacíe todos los bins seleccionados.
- Facilita el reabastecimiento completo al final del turno.
- Útil en operaciones de turno único con reposición nocturna.
- Se complementa con la estrategia de extracción "Partial Quantities First".

## Integración con Otros Procesos

| Proceso | Integración |
|---------|-------------|
| Outbound Delivery | Fuente de demanda para la wave |
| Reabastecimiento | Se puede disparar automáticamente al liberar la wave |
| Resource Management | WOs asignadas a recursos según colas |
| Labor Management | Medición de eficiencia por wave y operario |
| Yard Management | Coordinación con llegada de camiones (cutoff time) |

## Consultas MCP relevantes

```
// Waves abiertas en el almacén
ReadTable: /SCWM/WAVE WHERE LGNUM = 'ZW01' AND WAVESTAT = '01'

// Waves liberadas con WTs pendientes
ReadTable: /SCWM/WAVE WHERE LGNUM = 'ZW01' AND WAVESTAT = '02'

// Entregas asignadas a una wave específica
ReadTable: /SCWM/WAVEOBD WHERE LGNUM = 'ZW01' AND WAVEKEY = '000000001'

// WTs generadas por una wave
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND WAVEKEY = '000000001'

// Wave templates configurados
ReadTable: /SCWM/WAVE_TPL WHERE LGNUM = 'ZW01'

// Progreso de una wave (WTs confirmadas vs. total)
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND WAVEKEY = '000000001' AND TASTA = 'C'
ReadTable: /SCWM/ORDIM_O WHERE LGNUM = 'ZW01' AND WAVEKEY = '000000001'

// Waves próximas a cutoff time
ReadTable: /SCWM/WAVE WHERE LGNUM = 'ZW01' AND WAVESTAT <> '03' AND CUTOFF_DATE = SY-DATUM
```

## Notas de implementación S/4HANA 2023

- BAdI `/SCWM/EX_WAVE_DETERMINATION` para lógica custom de asignación de entregas a waves.
- BAdI `/SCWM/EX_WAVE_RELEASE` para acciones custom durante la liberación.
- En S/4HANA 2023 embedded EWM, las waves se integran con SAP TM (Transportation Management) para alinear cutoff times con rutas de transporte.
- El campo `WAVEKEY` en `/SCWM/ORDIM_O` permite rastrear todas las WTs de una wave en una sola consulta.
- Para operaciones de alto volumen, se recomienda liberar waves en background job con transacción `/SCWM/WAVEREL_JOB`.
- El monitor `/SCWM/WAVE` soporta selecciones de layout personalizadas (ALV) para diferentes perfiles de usuario (planificador, supervisor, operaciones).
