# Integracion Cross-Module EWM

Descripción de las integraciones entre SAP EWM y los módulos MM, SD, PP, FI, QM, TM y LE en S/4HANA 2023. Incluye flujos de datos, puntos de integración técnica y árbol de decisión para EWM embebido vs descentralizado.

---

## Arquitectura de Integración EWM en S/4HANA

### EWM Embebido (Embedded EWM)
En S/4HANA 2023, EWM está embebido directamente en el sistema central. No requiere sistema EWM separado ni conexión RFC entre WM y EWM.

```
S/4HANA Core
├── MM (Materiales)
├── SD (Ventas)
├── PP (Producción)
├── FI (Finanzas)
├── QM (Calidad)
├── TM (Transportes)
└── EWM (Almacén extendido) ← integrado en el mismo sistema
```

### EWM Descentralizado (Legacy / On-Premise separado)
EWM corre en un sistema separado conectado via CIF (Core Interface) + RFC.

```
S/4HANA / ECC Core ←→ [RFC/CIF] ←→ EWM System
```

---

## 1. EWM ↔ MM (Materials Management)

### Punto de Integración: Goods Receipt (GR)

**Flujo entrada de mercancías:**
```
Pedido de compra (ME21N)
  → Entrega de entrada en EWM (/SCWM/PRDI)
  → Warehouse Tasks de putaway (/SCWM/WT)
  → Confirmación GR en EWM
  → Documento de material (MATDOC) en MM
  → Actualización de stock MM (MARD/MCHB/MARC)
  → Entrada en ACDOCA (S/4HANA)
```

**Tablas clave:**
```
/SCWM/LQUANT  → Stock en EWM (quants)
MATDOC        → Documentos de movimiento MM
MSEG          → Posiciones del documento material
MKPF          → Cabecera documento material
```

**Clases de movimiento MM relevantes:**
| Mov. | Descripción | Trigger desde EWM |
|------|-------------|-------------------|
| 101 | GR para pedido de compra | Confirmación GR inbound |
| 122 | Devolución a proveedor | Retorno desde EWM |
| 201 | GI para orden de producción | GI outbound PP |
| 261 | GI para orden de producción (componentes) | Confirmación GI |
| 601 | GI para entrega SD | PGI desde EWM outbound |
| 701 | Diferencia de inventario | Ajuste PI en EWM |

### Punto de Integración: Goods Issue (GI)

**Flujo salida de mercancías:**
```
Entrega de salida SD (VL02N)
  → Distribución a EWM
  → Warehouse Tasks de picking
  → Confirmación picking
  → Post Goods Issue (PGI) desde EWM
  → MATDOC clase 601 en MM
  → Reducción de stock en MM
  → Facturación SD habilitada (VF01)
```

### Reconciliación de Stock EWM ↔ MM
```
Transacción: /SCWM/RECON
```
En S/4HANA embebido, el stock debe estar siempre sincronizado. La reconciliación identifica diferencias causadas por errores de programa, inconsistencias de actualización o cancelaciones parciales.

**Regla de gestión:** El stock en EWM es la fuente de verdad para ubicaciones en el almacén. El stock MM es la fuente de verdad para movimientos contables.

---

## 2. EWM ↔ SD (Sales and Distribution)

### Flujo de Entrega de Salida

**Creación y distribución:**
```
Pedido de ventas (VA01)
  → Verificación disponibilidad ATP
  → Creación entrega (VL01N/VL04)
  → Distribución automática a EWM
  → Outbound Delivery Order (ODO) en EWM
  → Wave assignment (si aplica)
  → Warehouse Tasks de picking
```

**Confirmación y cierre:**
```
Picking completado en EWM
  → Post Goods Issue (PGI) desde EWM o SD
  → MATDOC 601
  → Actualización entrega SD: estado PGI = "C"
  → Habilitación de facturación (billing)
  → VF01 / VF04 → Factura cliente
```

### ATP (Available to Promise)
```
Módulo: SAP Advanced ATP (S/4HANA)
```
- EWM actualiza el stock disponible en tiempo real
- ATP consulta el stock de EWM a través de la integración embebida
- Reservas de stock en EWM bloquean cantidades para ATP

### Configuración Relevante SD ↔ EWM
```
SPRO > SD > Shipping > Delivery > Define Warehouse Integration
```
- Asignación: Planta + Storage Location → Almacén EWM
- Control: EWM como sistema WM de la entrega
- Perfil de procesamiento de entrega (distribución a EWM)

---

## 3. EWM ↔ PP (Production Planning)

### Production Supply Area (PSA)

La PSA (Production Supply Area) es la zona de staging de materiales entre el almacén EWM y la línea de producción.

**Flujo de aprovisionamiento a producción:**
```
Orden de producción (CO01/CO10)
  → Pull List generada (/SCWM/PULL)
  → Warehouse Tasks: picking de componentes
  → Staging en PSA (Production Supply Area)
  → Confirmación de staging
  → GI automático a la orden de producción
  → MATDOC 261 en MM
```

**Transacciones clave:**
```
/SCWM/PULL    → Gestión de Pull List (demanda de componentes)
/SCWM/PSA     → Configurar Production Supply Areas
/SCWM/REPL    → Reposición a PSA
```

**Estrategias de aprovisionamiento PP:**
| Estrategia | Descripción |
|-----------|-------------|
| PULL | EWM reacciona a demanda de PP (pull list) |
| PUSH | Reposición proactiva basada en niveles mínimos |
| Kanban | Disparado por señales Kanban desde PP |

### Sincronización con Órdenes de Producción
```
SPRO > EWM > Integration with PP > Define PSA
```
- Asignación de PSA a centro de trabajo / línea de producción
- Bins de staging dedicados por PSA
- Reglas de reposición: tiempo de reaprovisionamiento, cantidad mínima/máxima

### GR desde Producción
```
Confirmación de operación en PP (CO11N / CO15)
  → GR de producto terminado
  → Entrega de entrada EWM (si configurado)
  → Putaway del producto terminado en almacén
```

---

## 4. EWM ↔ FI (Financial Accounting)

### Valoración de Inventario

En S/4HANA 2023 con EWM embebido:
- Cada movimiento de stock en EWM que implica GR/GI genera un documento FI automáticamente
- La valoración usa el precio estándar o promedio del material master (MM)
- No hay valoración independiente en EWM

**Tabla central S/4HANA:**
```
ACDOCA → Tabla universal de documentos contables
```
Cada MATDOC generado por EWM tiene entradas correspondientes en ACDOCA.

### Ajustes por Inventario Físico

```
Diferencia de inventario en EWM (PI)
  → Aprobación en EWM
  → Posting PI → MATDOC clase 701 (ajuste positivo) / 702 (ajuste negativo)
  → Entrada en FI:
    - Débito / Crédito cuenta de inventario (BSX)
    - Contra cuenta de diferencia de inventario (INV)
  → Entrada en ACDOCA con referencia al documento PI
```

**Cuentas contables relevantes:**
```
OBYC → Determinación automática de cuentas
  - BSX: Inventario
  - PRD: Diferencia de precio
  - GBB: Salidas de mercancías (consumo)
  - WRX: GR/IR clearing
```

### Impacto en Balance

EWM no tiene un impacto directo en FI más allá de los movimientos de mercancías que genera. La valoración es siempre responsabilidad de MM/FI.

---

## 5. EWM ↔ QM (Quality Management)

### Inspección en Entrada de Mercancías

```
GR para pedido de compra
  → Si el material tiene clase de inspección activa:
    → Creación de Lote de Inspección (QM) automático
    → Stock de entrada en estado "En inspección"
    → En EWM: stock queda en bin de cuarentena / tipo de almacén de QM
  → Resultado de inspección registrado en QM (QA32)
  → Decisión de uso: Liberado / Rechazado / Reelaboración
  → Si liberado: WT de putaway creada (EWM mueve a stock disponible)
  → Si rechazado: retorno a proveedor o destrucción
```

**Tipos de almacén para QM:**
```
/SCWM/TSTTYP → Definir tipo de almacén "Calidad / Cuarentena"
```
- Stock en cuarentena: no disponible para picking ATP
- Visible en /SCWM/LSTK con indicador especial "Q" (Quality Inspection)

### Configuración QM ↔ EWM
```
SPRO > QM > QM in Procurement > Define Inspection Lots Integration with EWM
```
- Activar creación automática de lote en GR
- Asignar tipo de almacén de cuarentena por planta / tipo de material
- Definir qué pasa con el stock al aprobar / rechazar el lote

### Lote de Inspección y Batch
```
Si el material es gestionado por lotes (Batch Management):
  - El lote de inspección QM se vincula al batch MM
  - Liberación del lote QM → activa el batch para uso en EWM
  - FEFO / BEST (Best Before Date) se calcula desde el batch
```

---

## 6. EWM ↔ TM (Transportation Management)

### Integración con Yard Management

```
TM gestiona el transporte hasta/desde el almacén
EWM gestiona las operaciones dentro del almacén
El Yard (patio) es la zona de transición
```

**Flujo inbound con TM:**
```
Freight Order en TM (camión en ruta)
  → Notificación de llegada al Yard
  → Asignación de doca en EWM (Yard Door)
  → Check-in del vehículo en TM
  → Descarga coordinada: TM notifica a EWM
  → GR procesado en EWM
  → Check-out del vehículo
```

**Flujo outbound con TM:**
```
Freight Order en TM (planificación de envío)
  → EWM recibe lista de entregas para la unidad de transporte
  → Wave picking coordinado con ventana de carga
  → Carga del camión confirmada en EWM
  → TM actualiza estado del Freight Order
  → PGI
```

### Transacciones Yard Management
```
F5778 → Yard Management (Fiori)
/SCWM/YARD → Gestión de patio clásica
/SCWM/DOOR → Asignación de docas
```

### Configuración TM ↔ EWM
```
SPRO > TM > Integration > EWM Integration
SPRO > EWM > Yard Management
```
- Mapeo de Freight Order Types → procesos EWM
- Integración de Unidad de Transporte (TU) en EWM
- Reglas de asignación de docas por tipo de vehículo / ruta

---

## 7. EWM ↔ LE (Logistics Execution / Handling Units)

### Gestión de Handling Units

Las Handling Units (HU) son la unidad central de trazabilidad en LE/EWM.

**Niveles de HU:**
```
SSCC (Serial Shipping Container Code)
  └── Pallet HU
       └── Caja HU
            └── Unidad de venta (material)
```

**Integración LE ↔ EWM:**
- HU creadas en LE (VL02N) se transfieren a EWM
- HU internas de EWM (creadas en picking / putaway) no necesariamente existen en LE
- HU de expedición (outbound) se sincronizan de vuelta a LE para documentación de entrega

**Transacciones HU:**
```
/SCWM/HU01  → Crear HU en EWM
/SCWM/HU02  → Modificar HU en EWM
/SCWM/HU03  → Visualizar HU en EWM
HUMO        → Workbench de HU en LE
```

---

## 8. CIF (Core Interface) — EWM Descentralizado

### Función del CIF
En implementaciones con EWM descentralizado (sistema EWM separado de ECC o S/4HANA), el CIF es el middleware de replicación de datos maestros y documentos.

**Datos replicados via CIF:**
```
Master Data:
  ├── Materiales (MATMAS IDoc)
  ├── Clientes / Proveedores (DEBMAS / CREDMAS)
  ├── Planta / Storage Location → Almacén EWM
  └── Batch records (BATMAS)

Transactional Data:
  ├── Entregas de entrada (WMMBXY / LAUFD IDoc)
  ├── Entregas de salida (WMMBXY IDoc)
  └── Documentos de material (MATDOC confirmación)
```

**Transacciones CIF:**
```
/SAPAPO/CIF    → Monitor CIF
/SAPAPO/CIFCHECK → Verificación de consistencia
SM58           → Cola de RFC (errores de transferencia)
WE02 / WE05   → Monitor IDoc
```

**Errores comunes en CIF:**
- IDoc en estado 51 (error de aplicación): revisar en WE02
- Cola RFC bloqueada: reiniciar en SM58
- Material no replicado: ejecutar replicación manual en /SAPAPO/CIF

---

## Arbol de Decision: EWM Embebido vs Descentralizado

```
¿El sistema SAP es S/4HANA 1909 o superior?
├── NO  → EWM Descentralizado (sistema EWM separado + CIF)
└── SÍ  → EWM Embebido disponible
    ├── ¿Se requiere alta disponibilidad independiente del core?
    │   └── SÍ → considerar EWM Descentralizado (arquitectura separada)
    ├── ¿El almacén tiene requerimientos de volumen extremo (>1M WT/día)?
    │   └── SÍ → evaluar EWM Descentralizado para no impactar core
    └── Caso estándar → EWM Embebido (recomendado por SAP para S/4HANA)
```

**Ventajas EWM Embebido:**
- Un solo sistema: sin latencia de comunicación RFC/CIF
- Datos maestros siempre sincronizados (mismo client)
- Menor costo de operación (un sistema vs dos)
- Fiori apps funcionan nativamente

**Ventajas EWM Descentralizado:**
- Independencia operativa: el almacén sigue funcionando si el core cae
- Actualizaciones de EWM independientes del ciclo S/4HANA
- Posibilidad de múltiples sistemas EWM por un único S/4HANA core
- Mejor rendimiento en volúmenes extremos

---

## Resumen de Puntos de Integración

| Integración | Documento/Objeto | Dirección | Trigger |
|-------------|-----------------|-----------|---------|
| EWM→MM | MATDOC (GR/GI) | EWM→MM | Confirmación WT/GR/GI en EWM |
| MM→EWM | Inbound Delivery | MM→EWM | GR pedido / creación entrega |
| SD→EWM | Outbound Delivery | SD→EWM | Creación entrega SD |
| EWM→SD | PGI status update | EWM→SD | PGI desde EWM |
| PP→EWM | Pull List / PSA | PP→EWM | Demanda de componentes PP |
| EWM→PP | GI componentes | EWM→PP | Confirmación staging PSA |
| QM→EWM | Inspection Lot | QM→EWM | Liberación de lote QM |
| EWM→FI | Documento FI | EWM→FI | Via MATDOC (automático) |
| TM→EWM | Freight Order | TM→EWM | Asignación de transporte |
| EWM→TM | Status update | EWM→TM | Carga confirmada / PGI |
