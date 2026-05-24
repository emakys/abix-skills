# Catalogo de Errores EWM

Referencia de los errores más frecuentes en SAP EWM S/4HANA 2023 bajo el namespace /SCWM/. Organizado por proceso con causa típica y pasos de resolución.

---

## Clases de Mensajes EWM Principales

| Clase | Área |
|-------|------|
| /SCWM/GM | Goods Movement (GR/GI) |
| /SCWM/IB | Inbound / Goods Receipt |
| /SCWM/OB | Outbound / Goods Issue |
| /SCWM/L | Putaway / Storage |
| /SCWM/P | Picking / Extraction |
| /SCWM/PI | Physical Inventory |
| /SCWM/HU | Handling Units |
| /SCWM/Q | Queue / Resource |
| /SCWM/WO | Warehouse Orders |
| /SCWM/ST | Stock / Quants |
| /SCWM/WV | Wave Management |
| /SCWM/CORE | Core EWM (errores genéricos) |

---

## 1. Errores de Entrada de Mercancías (Inbound / GR)

### /SCWM/IB 001 — Entrega de entrada no encontrada
```
Texto: Inbound delivery & not found in warehouse &
Causa: La entrega MM/SD no se ha distribuido a EWM o el número es incorrecto
Resolución:
  1. Verificar que la entrega exista en MM: transacción VL03N / MIGO
  2. Revisar distribución a EWM: /SCWM/PRDI → buscar entrega
  3. Forzar redistribución: /SCWM/IBD_DET → redispatch manual
  4. Verificar configuración de determinación de almacén en la entrega
```

### /SCWM/IB 002 — Diferencia de cantidad superior a tolerancia
```
Texto: Quantity difference & for item & exceeds tolerance &%
Causa: Cantidad recibida difiere de la pedida más del porcentaje de tolerancia configurado
Resolución:
  1. Revisar tolerancias: SPRO > EWM > GR > Quantity Tolerance
  2. Si la diferencia es real: crear nota de devolución o ajustar entrega en MM
  3. Si es error de entrada: corregir cantidad en la app F4762
  4. Aprobación de supervisor para diferencias fuera de tolerancia
```

### /SCWM/GM 010 — Error al publicar movimiento de mercancías
```
Texto: Error posting goods movement: &
Causa: Error de integración EWM↔MM al confirmar GR. Puede ser: período cerrado,
       clase de movimiento no configurada, cuenta contable no determinada
Resolución:
  1. Revisar log en /SCWM/PRDI → mensaje de error MM detallado
  2. Verificar período contable: MR22 / OB52
  3. Revisar determinación de cuenta: OBYC
  4. Verificar clase de movimiento asignada en customizing EWM↔MM
  5. En S/4HANA: revisar en ACDOCA si hay entradas parciales
```

### /SCWM/IB 015 — HU ya asignada a otra entrega
```
Texto: Handling unit & already assigned to delivery &
Causa: Se intenta crear una HU con un número ya utilizado en otra entrega
Resolución:
  1. Verificar estado de la HU: /SCWM/HU03
  2. Si la HU original está cerrada: configurar rango de número para HU
  3. Desasignar HU de entrega original si es un error: /SCWM/HU_DEASSIGN
```

### /SCWM/IB 020 — Doca no disponible
```
Texto: Dock door & is not available for warehouse &
Causa: La doca no está configurada o está asignada a otro vehículo
Resolución:
  1. Verificar configuración de docas: /SCWM/LS03 (bins tipo Yard)
  2. Revisar disponibilidad en Yard Management (F5778)
  3. Asignar doca diferente o liberar la ocupada
```

---

## 2. Errores de Salida de Mercancías (Outbound / GI)

### /SCWM/OB 001 — Entrega de salida bloqueada
```
Texto: Outbound delivery & is blocked for warehouse processing
Causa: La entrega tiene un bloqueo de entrega activo en SD (bloqueo de crédito,
       bloqueo de picking, etc.)
Resolución:
  1. Verificar bloqueo en VL03N → campo "Bloqueo de entrega"
  2. Liberar bloqueo de crédito: VKM1 / VKM3
  3. Liberar bloqueo de picking: VL09 o manualmente en VL02N
  4. Verificar que el cliente no tenga bloqueo de pedido activo
```

### /SCWM/OB 005 — Stock insuficiente para picking
```
Texto: Insufficient stock for material & in warehouse &, available: &, required: &
Causa: No hay stock disponible suficiente en EWM (puede existir en MM pero no en EWM)
Resolución:
  1. Verificar stock EWM: /SCWM/LSTK o F5213
  2. Comparar con stock MM: MMBE
  3. Si hay diferencia EWM↔MM: ejecutar conciliación /SCWM/RECON
  4. Verificar si el stock está bloqueado o en inventario activo
  5. Revisar si hay WT abiertas que consumen stock: F3189
```

### /SCWM/OB 010 — PGI fallido: cantidades de picking incompletas
```
Texto: Post Goods Issue failed: open pick quantities exist for delivery &
Causa: El PGI se ejecutó antes de completar todo el picking
Resolución:
  1. Revisar tareas abiertas: F3189 filtro por entrega
  2. Confirmar WT pendientes o cancelar y recrear
  3. Si es entrega parcial: configurar en SPRO si se permite PGI parcial
  4. Verificar perfil de entrega de salida en customizing
```

### /SCWM/WV 001 — Wave no puede liberarse
```
Texto: Wave & cannot be released: &
Causa: Causas múltiples: sin entregas asignadas, stock insuficiente,
       error en reglas de wave, período contable cerrado
Resolución:
  1. Revisar log de wave en F4000 → botón "Release Log"
  2. Verificar que las entregas en la wave tienen stock reservado
  3. Revisar reglas de liberación automática: SPRO > EWM > Wave > Release Rules
  4. Liberar manualmente si el automático falla: /SCWM/WAVE_REL
```

### /SCWM/WV 005 — Criterio de selección de wave sin resultados
```
Texto: No deliveries found for wave template & with current selection criteria
Causa: Los filtros del template de wave no coinciden con entregas disponibles
Resolución:
  1. Revisar template: SPRO > EWM > Wave Management > Wave Templates
  2. Verificar estado de las entregas (deben estar en estado "A" para picking)
  3. Ajustar criterios: fecha, ruta, zona de destino, tipo de envío
```

---

## 3. Errores de Putaway (Almacenamiento)

### /SCWM/L 001 — Sin bin disponible para putaway
```
Texto: No storage bin found for material & in warehouse & with strategy &
Causa: La estrategia de putaway no encontró ningún bin libre que cumpla los criterios
Resolución:
  1. Verificar ocupación del tipo de almacén destino: F5213
  2. Revisar restricciones del material: /SCWM/MATID (temperatura, hazmat, etc.)
  3. Verificar capacidad de bins: /SCWM/BIN_CAP
  4. Ampliar criterios en la estrategia: SPRO > EWM > Storage Type Search
  5. Crear bins adicionales o vaciar bins con movimientos internos
```

### /SCWM/L 005 — Capacidad de bin excedida
```
Texto: Bin & capacity exceeded: maximum weight & kg, current load & kg, adding & kg
Causa: El material a almacenar supera el límite de peso o volumen del bin destino
Resolución:
  1. Verificar capacidad del bin: /SCWM/LS03
  2. Seleccionar bin alternativo con capacidad suficiente
  3. Si el bin debe aceptar más carga: aumentar capacidad en master data
  4. Revisar si la capacidad está siendo calculada correctamente (peso de HU vs material)
```

### /SCWM/L 008 — Tipo de almacén no permite el material
```
Texto: Storage type & does not allow material & (special storage indicator &)
Causa: El material tiene un indicador especial (hazmat, temperatura) incompatible con el tipo de almacén
Resolución:
  1. Verificar indicador especial del material: /SCWM/MATID
  2. Verificar configuración del tipo de almacén: /SCWM/TSTTYP
  3. Corregir la secuencia de búsqueda de tipo de almacén en customizing
  4. O modificar el indicador del material si es un error de datos maestros
```

### /SCWM/L 012 — Bin de destino ocupado por otro material (almacenamiento mixto no permitido)
```
Texto: Bin & contains material & - mixed storage not allowed
Causa: El bin de destino ya contiene un material diferente y no se permite mezcla
Resolución:
  1. Verificar configuración de almacenamiento mixto: /SCWM/TSTTYP → Mixed Storage
  2. Seleccionar bin vacío como destino
  3. O mover el material existente antes del putaway
```

---

## 4. Errores de Picking

### /SCWM/P 001 — Material no encontrado en bin propuesto
```
Texto: Material & not found in source bin & (quantity available: &)
Causa: Discrepancia de stock: EWM propone bin donde el stock ya no existe físicamente
Resolución:
  1. Verificar stock real en el bin: F5213 drill-down a bin
  2. Si el bin está vacío: realizar mini-inventario /SCWM/PI01 en ese bin
  3. Ejecutar reconciliación de stock: /SCWM/RECON
  4. Seleccionar bin alternativo manual en la tarea
```

### /SCWM/P 005 — WT no puede confirmarse: diferencia fuera de tolerancia
```
Texto: Cannot confirm WT &: quantity difference & exceeds allowed tolerance
Causa: El operario registra cantidad diferente a la propuesta y supera tolerancia
Resolución:
  1. Verificar tolerancias de confirmación: SPRO > EWM > WT Confirmation Tolerances
  2. Si diferencia es real: confirmar cantidad real y disparar inventario en el bin
  3. Supervisor puede autorizar excepción con rol /SCWM/R_WM_ADM
```

### /SCWM/P 010 — Lote incorrecto en picking
```
Texto: Batch & specified does not match required batch & for delivery item &
Causa: Se seleccionó un lote diferente al requerido en la entrega (cliente con lote específico)
Resolución:
  1. Verificar si la entrega requiere lote fijo: VL03N → posición → lote
  2. Confirmar el WT con el lote correcto
  3. Si el lote requerido no está disponible: coordinar con ventas para ajustar
```

---

## 5. Errores de Inventario Físico (PI)

### /SCWM/PI 001 — Bin bloqueado por inventario activo
```
Texto: Bin & is blocked due to active physical inventory document &
Causa: El bin está en conteo de inventario y no se pueden realizar movimientos
Resolución:
  1. Completar el inventario: F3891 → finalizar conteo del bin
  2. Si el inventario es obsoleto: cancelar documento PI en /SCWM/PI_CANCEL
  3. Autorización especial para liberar bloqueo: /SCWM/R_WM_PI
```

### /SCWM/PI 005 — Diferencia de inventario requiere reconteo
```
Texto: Inventory difference for bin & exceeds threshold &%. Recount required.
Causa: La diferencia entre el libro y el conteo físico supera el umbral configurado
Resolución:
  1. Ejecutar reconteo: F3891 → crear documento de reconteo
  2. Verificar umbral de reconteo: SPRO > EWM > PI > Recount Rules
  3. Si tras reconteo la diferencia persiste: ajuste requiere aprobación de supervisor
  4. Ajuste en libro de inventario: /SCWM/PI_POST
```

### /SCWM/PI 010 — Inventario no puede publicarse: período contable cerrado
```
Texto: Cannot post PI adjustments: accounting period & is closed
Causa: El período fiscal en FI está cerrado y no se puede registrar el ajuste de inventario
Resolución:
  1. Abrir período: OB52 (requiere autorización FI)
  2. Postear ajuste en período correcto
  3. Si el período no puede abrirse: postear en el período actual y justificar
```

---

## 6. Errores de Handling Units (HU)

### /SCWM/HU 001 — HU no existe en el almacén
```
Texto: Handling Unit & does not exist in warehouse &
Causa: La HU fue transferida a otro almacén, eliminada, o el número es incorrecto
Resolución:
  1. Buscar HU: /SCWM/HU03 con número exacto
  2. Verificar historial de HU: /SCWM/HU_HIST
  3. Si la HU fue destruida/vaciada: crear nueva HU
```

### /SCWM/HU 005 — HU cerrada, no puede modificarse
```
Texto: Handling Unit & is packed and closed - cannot add items
Causa: Se intenta agregar contenido a una HU ya cerrada y sellada
Resolución:
  1. Desempacar la HU: /SCWM/HU_PACK → desempacar
  2. Agregar el material
  3. Volver a empacar y cerrar
```

### /SCWM/HU 010 — Peso máximo de HU excedido
```
Texto: Maximum weight & kg for HU type & exceeded when adding & kg
Causa: El material a agregar supera la capacidad de peso del tipo de HU
Resolución:
  1. Verificar capacidad del tipo de HU: /SCWM/HU_TYPE
  2. Crear HU adicional para el excedente
  3. O cambiar a un tipo de HU con mayor capacidad
```

### /SCWM/HU 015 — HU anidada demasiado profundamente
```
Texto: HU nesting depth & exceeds maximum allowed depth &
Causa: Se intentó crear una jerarquía de HU mayor a la permitida (ej: pallet en pallet en pallet)
Resolución:
  1. Revisar límite de anidamiento: SPRO > EWM > HU > Nesting Depth
  2. Reestructurar la jerarquía de empaque
```

---

## 7. Errores de Stock y Quants

### /SCWM/ST 001 — Stock negativo no permitido
```
Texto: Negative stock not allowed for material & in bin &
Causa: El movimiento generaría stock negativo en el bin/quant
Resolución:
  1. Verificar si está habilitado stock negativo: /SCWM/TSTTYP → Allow Negative Stock
  2. Realizar inventario en el bin para corregir saldo
  3. Verificar si hay WT abiertas que aún no se confirmaron
```

### /SCWM/ST 005 — Quant bloqueado por otro proceso
```
Texto: Quant & in bin & is locked by another process (lock type: &)
Causa: El quant de stock está reservado por una tarea activa
Resolución:
  1. Identificar proceso que tiene el lock: /SCWM/QLOCK o SE16 en /SCWM/LQUANT
  2. Esperar que el proceso termine o cancelar la WT que lo bloquea
  3. En casos críticos: liberar lock manualmente (solo administrador)
```

### /SCWM/ST 010 — Número de serie ya utilizado
```
Texto: Serial number & for material & already in use in warehouse
Causa: Se intenta registrar un número de serie ya existente en el sistema
Resolución:
  1. Verificar dónde está el serial: /SCWM/SER (Serial Number Management)
  2. Si fue un error de entrada: corregir número de serie en GR
  3. Si el serial fue dado de baja incorrectamente: ajuste con soporte Basis
```

---

## 8. Errores de Recursos (Resource Management)

### /SCWM/Q 001 — Recurso no disponible
```
Texto: Resource & is not available in queue &
Causa: El recurso (montacargas, operario) no está registrado como activo en la cola
Resolución:
  1. Verificar estado del recurso: F3457 (Resource Monitor)
  2. Activar recurso: /SCWM/RES_ACTIV
  3. Asignar recurso a la cola correcta: /SCWM/QUEUE_ASG
```

### /SCWM/Q 005 — Cola vacía: sin tareas disponibles
```
Texto: No warehouse tasks available in queue & for resource &
Causa: No hay tareas asignadas a la cola del recurso
Resolución:
  1. Verificar si hay WT creadas sin cola asignada: F3189
  2. Revisar reglas de creación de WO y asignación de cola
  3. Crear WT manualmente si el proceso automático falló
```

---

## 9. Errores de Distribución de Entregas

### /SCWM/CORE 001 — Error en distribución de entrega a EWM
```
Texto: Distribution of delivery & to EWM warehouse & failed: &
Causa: Error de integración MM/SD → EWM. Causas comunes: almacén no configurado,
       material no extendido a EWM, error de comunicación RFC
Resolución:
  1. Revisar log en /SCWM/PRDI
  2. Verificar que el material está extendido al almacén EWM: /SCWM/MATID
  3. Verificar la conexión RFC entre MM y EWM (solo en decentralized)
  4. Para EWM embebido: verificar configuración de almacén en IM ↔ EWM
  5. Redistribuir manualmente: /SCWM/IBD_DET o /SCWM/OBD_DET
```

### /SCWM/CORE 005 — Material no extendido al almacén EWM
```
Texto: Material & is not extended to warehouse & in EWM
Causa: Falta el registro de almacén EWM en el material master
Resolución:
  1. Extender material: MM01 → vista "Warehouse Management 2"
  2. Configurar: tipo de almacenamiento especial, unidad de almacén, perfil de putaway
  3. Ejecutar de nuevo la distribución de entrega
```

---

## Referencia Rapida — Transacciones de Diagnóstico

| Transacción | Descripción |
|-------------|-------------|
| /SCWM/PRDI | Log de distribución de entregas (inbound/outbound) |
| /SCWM/MON | Warehouse Monitor (alertas centralizadas) |
| /SCWM/RECON | Reconciliación de stock EWM↔MM |
| /SCWM/HU03 | Visualizar/rastrear Handling Unit |
| /SCWM/LSTK | Stock del almacén por quant |
| /SCWM/LS03 | Datos del Storage Bin |
| /SCWM/QLOCK | Ver locks de quants activos |
| SLG1 | Log de aplicación (filtrar por objeto /SCWM/*) |
| SM13 | Update records bloqueados |
| SM12 | Lock entries activos |
