# Fiori Apps EWM

Catálogo de aplicaciones SAP Fiori para operaciones de almacén EWM en S/4HANA 2023. Incluye apps de escritorio y móviles para reemplazar terminales RF clásicos.

---

## Resumen de Apps por Proceso

| App ID | Nombre | Proceso | Tipo |
|--------|--------|---------|------|
| F3456 | Warehouse Monitor | Monitoreo general | Analytical |
| F4762 | Manage Inbound Deliveries | Entrada de mercancías | Transactional |
| F4763 | Manage Outbound Deliveries | Salida de mercancías | Transactional |
| F3891 | Physical Inventory | Inventario físico | Transactional |
| F5213 | Stock Overview (Warehouse) | Visualización de stock | Analytical |
| F3189 | Monitor Warehouse Tasks | Gestión de tareas | Transactional |
| F4764 | Post Goods Receipt | Confirmación GR | Transactional |
| F4765 | Confirm Warehouse Tasks | Confirmación de tareas | Transactional |
| F3892 | Manage Physical Inventory | Gestión PI | Transactional |
| F5777 | Create Warehouse Tasks | Creación manual WT | Transactional |
| F4766 | Pack Handling Units | Empaque de HU | Transactional |
| F3457 | Resource Monitor | Gestión de recursos | Analytical |
| F5778 | Yard Management | Gestión de patio | Transactional |
| F4000 | Manage Waves | Gestión de waves | Transactional |

---

## F3456 — Warehouse Monitor

### Descripción
App analítica central para supervisores y jefes de almacén. Proporciona visibilidad en tiempo real de todas las operaciones del almacén. Reemplaza la transacción /SCWM/MON.

### Funcionalidades Principales
- Vista de alertas configurables por perfil de usuario
- KPIs de throughput: tareas pendientes, tareas en proceso, completadas
- Drill-down desde indicadores a documentos individuales
- Visualización de ocupación de bins y tipos de almacén
- Estado de recursos: montacargas, operarios, docas
- Filtros por área de actividad, tipo de proceso, turno

### Configuración
```
SPRO > EWM > Cross-Process Settings > Warehouse Monitor
Tabla configuración: /SCWM/TMON_PROF
```
- Definir perfiles de monitor por rol de usuario
- Configurar alertas: umbral, color (verde/amarillo/rojo), frecuencia de refresco
- Habilitar/deshabilitar vistas por perfil

### Servicio OData
```
Servicio: /SCWM/API_WAREHOUSE_MONITOR_SRV
Versión OData: V2
Entidades principales:
  - WarehouseAlert
  - WarehouseTask
  - StockOverview
  - ResourceStatus
```

### Autorización Requerida
```
Objeto: /SCWM/WM_MON
Campo: ACTVT (valor 03 = display, 02 = change)
```

---

## F4762 — Manage Inbound Deliveries

### Descripción
Gestión completa de entregas de entrada (Inbound Delivery Orders). Cubre desde la recepción en doca hasta el putaway. Reemplaza /SCWM/GR y transacciones relacionadas.

### Funcionalidades Principales
- Lista de entregas pendientes de recepción filtrada por doca, proveedor, fecha
- Confirmación de Goods Receipt (GR) total o parcial
- Creación manual de Warehouse Tasks de putaway
- Impresión de etiquetas HU directamente desde la app
- Gestión de diferencias: cantidades, materiales no esperados
- Integración con inspección de calidad (lotes de QM)
- Visualización del estado de la entrega: Abierta / En proceso / Cerrada

### Flujo de Proceso en la App
1. Seleccionar entrega desde lista o búsqueda por número
2. Verificar posiciones y cantidades esperadas
3. Registrar cantidades reales recibidas (con diferencias si aplica)
4. Asignar doca (Yard Door)
5. Crear HU (Handling Units) de entrada
6. Confirmar GR → genera movimiento MM
7. Iniciar putaway (creación automática o manual de WT)

### Configuración
```
SPRO > EWM > Goods Receipt Process > Inbound Delivery Processing
Perfil: /SCWM/TIB_PROF
```
- Controlar campos visibles/obligatorios
- Activar confirmación de GR automática vs manual
- Configurar creación de HU: obligatoria, opcional, no aplica

### Servicio OData
```
Servicio: /SCWM/API_INBOUND_DELIVERY_SRV
Versión OData: V2
Entidades principales:
  - InboundDelivery
  - InboundDeliveryItem
  - HandlingUnit
  - WarehouseTask (putaway)
```

### Autorización Requerida
```
Objeto: /SCWM/WM_GR
Objeto: /SCWM/WM_HU (para gestión de HU)
```

---

## F4763 — Manage Outbound Deliveries

### Descripción
Gestión de entregas de salida (Outbound Delivery Orders). Cubre desde la liberación de ola hasta el Post Goods Issue (PGI). Reemplaza /SCWM/GI y relacionadas.

### Funcionalidades Principales
- Vista de deliveries pendientes filtrada por destino, fecha prometida, ruta
- Asignación a waves de picking
- Liberación de Warehouse Tasks de picking
- Seguimiento del estado de picking: pendiente / en proceso / completo
- Confirmación de carga en camión (loading confirmation)
- Ejecución de PGI individual o masivo
- Gestión de entregas parciales y residuos
- Impresión de albarán / delivery note

### Flujo de Proceso en la App
1. Seleccionar entregas pendientes (filtro por fecha, carrier, ruta)
2. Agrupar en wave o procesar individualmente
3. Liberar picking: crea Warehouse Tasks
4. Monitorear progreso de picking
5. Confirmar empaque y carga
6. Ejecutar PGI → genera movimiento MM/SD

### Configuración
```
SPRO > EWM > Goods Issue Process > Outbound Delivery Processing
Perfil: /SCWM/TOB_PROF
```
- Control de PGI: automático al completar picking vs manual
- Gestión de entregas parciales: permitir / bloquear
- Integración con Transportation Management (TM)

### Servicio OData
```
Servicio: /SCWM/API_OUTBOUND_DELIVERY_SRV
Versión OData: V2
Entidades principales:
  - OutboundDelivery
  - OutboundDeliveryItem
  - WarehouseTask (picking)
  - Wave
```

---

## F3891 — Physical Inventory

### Descripción
Ejecución y gestión de inventarios físicos en el almacén EWM. Soporta inventarios cíclicos, periódicos y por zona. Reemplaza /SCWM/PI01 y relacionadas.

### Funcionalidades Principales
- Creación de documentos de inventario por bin, material, área de actividad
- Asignación de recuentos a usuarios / equipos
- Registro de conteo en app móvil (modo RF replacement)
- Aprobación de diferencias dentro de tolerancias
- Reconteo automático cuando la diferencia supera umbral
- Conciliación con libro de inventario MM/FI
- Historial de conteos por bin

### Tipos de Inventario Soportados
| Tipo | Descripción |
|------|-------------|
| Cíclico (CC) | Por frecuencia de movimiento (A/B/C) |
| Periódico (PI) | Inventario anual completo |
| Por muestreo | Selección aleatoria de bins |
| Espontáneo | Disparado por discrepancia |
| Ad hoc | Manual por supervisor |

### Configuración
```
SPRO > EWM > Physical Inventory > Configure Physical Inventory Types
Tabla: /SCWM/TPI_TYPE
```
- Tolerancias de diferencia aceptables por material/tipo
- Número de reconteos permitidos
- Aprobación automática dentro de tolerancia

### Servicio OData
```
Servicio: /SCWM/API_PHYSICAL_INVENTORY_SRV
Versión OData: V2
Entidades principales:
  - PhysInventoryDocument
  - PhysInventoryItem
  - PhysInventoryCount
```

---

## F5213 — Stock Overview (Warehouse)

### Descripción
Vista consolidada del stock a nivel de almacén EWM con detalle hasta nivel de bin, lote, número de serie y HU. Reemplaza /SCWM/LSTK y /SCWM/BIN.

### Funcionalidades Principales
- Stock por material, tipo de almacén, bin, lote, unidad de almacén
- Visualización de stock en diferentes estados: disponible, bloqueado, en tránsito, cuarentena
- Drill-down desde material hasta HU individual
- Trazabilidad de movimientos históricos
- Exportación a Excel
- Gráficos de distribución de stock por zona

### Vistas de Stock
| Vista | Descripción |
|-------|-------------|
| Por Material | Totales por material y almacén |
| Por Bin | Contenido detallado de cada ubicación |
| Por HU | Estado y contenido de HUs |
| Por Lote | Stock agrupado por número de lote |
| En Tránsito | Stock en movimiento (WT abiertos) |

### Configuración
```
SPRO > EWM > Master Data > Configure Stock Display Profiles
```

### Servicio OData
```
Servicio: /SCWM/API_STOCK_SRV
Versión OData: V2
Entidades principales:
  - WarehouseStock
  - StorageBinStock
  - HandlingUnitStock
```

---

## F3189 — Monitor Warehouse Tasks

### Descripción
Monitoreo y gestión operativa de Warehouse Tasks (WT). Permite a supervisores intervenir en tareas bloqueadas, reasignar recursos y ajustar prioridades.

### Funcionalidades Principales
- Lista de tareas filtrada por estado, tipo, recurso, área, prioridad
- Reasignación de tareas a otro recurso
- Cambio de prioridad de tareas pendientes
- Cancelación de tareas y creación de tareas inversas
- Confirmación manual de tareas
- Visualización de tareas agrupadas por Warehouse Order
- Alertas de tareas vencidas o bloqueadas

### Estados de Warehouse Task
| Estado | Código | Descripción |
|--------|--------|-------------|
| Creada | A | Tarea creada, no asignada |
| En proceso | B | Asignada a recurso |
| Confirmada | C | Completada |
| Cancelada | X | Anulada |
| Bloqueada | L | Requiere intervención |

### Servicio OData
```
Servicio: /SCWM/API_WAREHOUSE_TASK_SRV
Versión OData: V2
Entidades principales:
  - WarehouseTask
  - WarehouseOrder
  - Resource
```

---

## Apps Moviles — Reemplazo de Terminales RF

### Contexto
SAP EWM en S/4HANA 2023 ofrece apps Fiori optimizadas para dispositivos móviles (tablets y smartphones) como alternativa moderna a los terminales RF clásicos. No requieren RF Framework.

### Apps Móviles Principales

#### Picking (Mobile)
```
App: EWM - Pick Handling Units (F4000M)
Optimizada para: Scanner Bluetooth + Tablet Android/iOS
```
- Escaneo de HU source y código de barras de bin
- Confirmación por escaneo (scan-to-confirm)
- Manejo de excepciones en campo
- Modo sin conexión (offline-capable con sincronización posterior)

#### Putaway (Mobile)
```
App: EWM - Putaway (F4001M)
```
- Propuesta automática de bin de destino
- Override manual con verificación de capacidad
- Escaneo de HU y bin confirmación

#### Goods Receipt (Mobile)
```
App: EWM - Post Goods Receipt (F4764M)
```
- Recepción con escaneo de código de barras / QR
- Creación de HU en campo
- Impresión de etiquetas en impresoras portátiles (Zebra, etc.)

#### Physical Inventory (Mobile)
```
App: EWM - Count Physical Inventory (F3891M)
```
- Conteo por escaneo bin a bin
- Sin necesidad de papel: conteo digital directo
- Sincronización automática al completar zona

### Configuración de Apps Móviles
```
SPRO > EWM > Mobile Apps > Configure Mobile Profiles
```
- Perfil de dispositivo: tipo de escáner, resolución
- Comportamiento offline: qué datos cachear
- Sincronización: intervalo, condiciones de red

### Infraestructura Requerida
- SAP Mobile Services (BTP) o Mobile Platform On-Premise
- Certificado SSL para comunicación segura
- SAP Fiori Client en dispositivos (o navegador Chrome/Safari)
- Wi-Fi de cobertura completa en el almacén

---

## Configuración General de Fiori para EWM

### Activación de Servicios OData
```
Transacción: /IWFND/MAINT_SERVICE
```
Servicios a activar para EWM:
- `/SCWM/API_WAREHOUSE_MONITOR_SRV`
- `/SCWM/API_INBOUND_DELIVERY_SRV`
- `/SCWM/API_OUTBOUND_DELIVERY_SRV`
- `/SCWM/API_PHYSICAL_INVENTORY_SRV`
- `/SCWM/API_STOCK_SRV`
- `/SCWM/API_WAREHOUSE_TASK_SRV`

### Catálogo y Grupo Fiori
```
Transacción: /UI2/FLPD_CONF
Catálogo: SAP_EWM_BC_WM (catálogo base EWM)
Grupo sugerido: EWM_WAREHOUSE_OPS
```

### Roles de Fiori Recomendados
| Rol PFCG | Apps incluidas |
|----------|---------------|
| /SCWM/R_FIORI_SUPERVISOR | F3456, F3189, F3457 |
| /SCWM/R_FIORI_INBOUND | F4762, F4764 |
| /SCWM/R_FIORI_OUTBOUND | F4763, F4765 |
| /SCWM/R_FIORI_INVENTORY | F3891, F3892, F5213 |
| /SCWM/R_FIORI_RF | F4765, F4764 (móvil) |
