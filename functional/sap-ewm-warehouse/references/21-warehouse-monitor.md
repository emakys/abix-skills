# Warehouse Monitor (/SCWM/MON)

## Visión General

El Warehouse Monitor es la herramienta central de visibilidad en tiempo real del almacén en SAP EWM S/4HANA 2023. Se accede via transacción `/SCWM/MON` y proporciona una vista consolidada de todas las actividades, excepciones, recursos y stock del almacén. Diseñado para supervisores y responsables de operaciones, permite monitorear y reaccionar ante situaciones operativas sin salir de una única pantalla.

## Nodos del Monitor

El monitor se organiza en una estructura de árbol de nodos, cada uno enfocado en un área operativa:

### Inbound (Entrada)
- Entregas de entrada pendientes de procesamiento
- Tareas de almacén (WT) en proceso de entrada
- Puestos de trabajo de desconsolidación activos
- GR esperados por fecha/ventana de tiempo

### Outbound (Salida)
- Entregas de salida abiertas y en proceso
- Waves activas y su estado de progreso
- Órdenes de picking pendientes de confirmación
- Expediciones próximas (shipping deadlines)

### Internal (Internos)
- Reposiciones en curso
- Movimientos internos de redistribución
- Tareas de slotting pendientes

### Exceptions (Excepciones)
- Diferencias de inventario
- Tareas bloqueadas o con errores
- Alertas de vencimiento de tiempo
- Bin bloqueados con stock

### Queues (Colas)
- Estado de colas de trabajo activas
- Cantidad de tareas pendientes por cola
- Recursos asignados vs. capacidad disponible

### Resources (Recursos)
- Usuarios RF activos y su estado
- Montacargas y equipos registrados
- Última actividad por recurso
- Asignación de recurso a cola o zona

### Bins (Ubicaciones)
- Bins bloqueados
- Bins con sobre-capacidad
- Bins vacíos en zonas críticas

### Stock
- Stock en cuarentena o inspección de calidad
- Lotes próximos a vencer
- Stock bloqueado sin movimiento

## Gestión de Alertas

El monitor soporta alertas configurables que se activan cuando se superan umbrales definidos:

- **Tiempo de permanencia**: WT sin confirmar por más de X minutos
- **Cola saturada**: más de N tareas en espera sin recurso disponible
- **Entrega urgente**: SLA de expedición en riesgo
- **Diferencia de inventario**: cantidad negativa o sin quant registrado

Las alertas aparecen con indicadores de color (rojo/amarillo/verde) y pueden escalarse por correo o workflow.

## Códigos de Excepción y Manejo

Los códigos de excepción (`/SCWM/T_EXC_CODE`) se asignan a tareas o entregas para indicar el motivo de una anomalía:

| Código | Descripción Ejemplo | Acción Típica |
|--------|--------------------|----|
| 0001 | Diferencia de cantidad | Revisión física + ajuste |
| 0002 | Producto dañado | Bloqueo + notificación QM |
| 0003 | Bin incorrecto | Corrección de destino |
| 0010 | Sin recursos disponibles | Asignación manual |

Configuración en: IMG > EWM > Monitoring > Define Exception Codes.

## Vistas Personalizadas del Monitor

Es posible crear variantes del monitor por rol o turno:

1. Acceder a `/SCWM/MON`
2. Seleccionar los nodos relevantes para el perfil
3. Guardar como variante con nombre
4. Asignar variante a usuario o rol de autorización

Cada variante puede tener sus propios filtros (almacén, tipo de proceso, fecha).

## Umbrales y Escalación

Los umbrales se definen en la configuración del monitor:

- **Tiempo máximo de WT abierta**: en minutos, por tipo de proceso
- **Ocupación máxima de bin**: porcentaje de capacidad
- **Antigüedad máxima de entrega pendiente**: en horas

La escalación puede conectarse a SAP Alert Management o BRF+ para disparar acciones automáticas cuando se supera un umbral.

## KPIs Mostrados en el Monitor

| KPI | Descripción |
|-----|-------------|
| WT Abiertas | Total de tareas de almacén sin confirmar |
| Tasa de Completitud | % de waves completadas en el turno |
| Productividad por Recurso | Tareas confirmadas / hora por usuario RF |
| Tiempo Medio de Ciclo | Tiempo promedio desde creación a confirmación de WT |
| Bin Fill Rate | % de ocupación de bins en zona de picking |
| Excepciones Activas | Número de alertas sin resolver |

## Capacidades de Drill-Down

Desde cualquier nodo del monitor es posible hacer doble clic para navegar al detalle:

- **WT**: abre `/SCWM/MONA` con detalle de la tarea
- **Entrega**: navega a `/SCWM/PRDI` o `/SCWM/PRDO`
- **Recurso**: muestra historial de actividad del usuario RF
- **Bin**: abre vista de quants con contenido del bin
- **Cola**: muestra lista de tareas en esa cola

## Configuración de Nodos del Monitor

Ruta IMG: EWM > Monitoring > Warehouse Monitor > Define Monitor Nodes

Parámetros de cada nodo:
- Activo/Inactivo
- Tipo de dato a mostrar
- Filtros por defecto (tipo de almacén, área de almacén)
- Frecuencia de refresco (manual / automático cada N segundos)
- Columnas visibles y orden

## Consultas via MCP (SAP ADT Tools)

Para analizar o extender la lógica del Warehouse Monitor via desarrollo ABAP:

```
-- Ver configuración de nodos del monitor
SearchObject: type=TABL, name=/SCWM/T_MON*

-- Leer clase principal del monitor
GetClass: class_name=/SCWM/CL_MON_*

-- Buscar BAdIs del monitor
SearchObject: type=ENHO, name=*MON*

-- Ver tablas de códigos de excepción
GetObjectSource: /SCWM/T_EXC_CODE (TABL via ADT URI)

-- Consultar enhancement spots del monitor
SearchObject: type=ENHS, name=/SCWM/ES_MON*
```

### Tablas Relevantes

| Tabla | Contenido |
|-------|-----------|
| `/SCWM/T_MON_NODE` | Definición de nodos del monitor |
| `/SCWM/T_EXC_CODE` | Códigos de excepción EWM |
| `/SCWM/T_ALERT` | Configuración de alertas |
| `/SCWM/ORDIM_O` | Tareas de almacén abiertas |
| `/SCWM/ORDIM_C` | Tareas de almacén confirmadas |

### Clases y FMs Clave

- `/SCWM/CL_MON_QUERY`: Clase base para queries del monitor
- `/SCWM/CL_MON_NODE_INBOUND`: Lógica del nodo de entrada
- `/SCWM/CL_MON_NODE_OUTBOUND`: Lógica del nodo de salida
- `/SCWM/CL_EXC_HANDLER`: Manejador de excepciones operativas
- BAdI: `/SCWM/EX_MON_NODE_QUERY` — extensión de queries por nodo

## Transacciones Relacionadas

| Transacción | Función |
|-------------|---------|
| `/SCWM/MON` | Warehouse Monitor principal |
| `/SCWM/MONA` | Monitor de tareas de almacén detallado |
| `/SCWM/MONB` | Monitor de bins |
| `/SCWM/MONQ` | Monitor de colas |
| `/SCWM/MONR` | Monitor de recursos |
| `/SCWM/MONS` | Monitor de stock |
| `/SCWM/MONX` | Monitor de excepciones |
