# Batch Management y Serial Numbers en EWM

## Visión General

La gestión de lotes (Batch Management) y números de serie (Serial Numbers) en SAP EWM permite el rastreo completo de mercancías a nivel de lote o unidad individual. EWM extiende la funcionalidad de MM/WM añadiendo capacidades de manejo físico, determinación de lotes durante el picking, y gestión de características de lote (incluida la vida útil) dentro del almacén.

En S/4HANA 2023, los datos de lote y serie se almacenan en /SCWM/AQUA (stock EWM) y se sincronizan con las tablas MM correspondientes (MCHA, MCHB, SER*).

---

## Batch Management en EWM

### Concepto
Un lote (batch) es un subconjunto de un material con características homogéneas producido o recibido en un momento determinado. En EWM, el stock se gestiona a nivel material + lote + número de HU (si aplica).

### Tabla de stock EWM con lote
La tabla `/SCWM/AQUA` almacena el stock EWM e incluye:
- `MATNR`: Material.
- `CHARG`: Número de lote.
- `LGNUM`: Warehouse number.
- `LGPLA`: Storage bin.
- `NISTA`: Cantidad disponible.
- `WDATU`: Fecha de fabricación / producción.
- `VFDAT`: Fecha de vencimiento (SLED / BBD).
- `INSPTYP`: Tipo de stock especial (Q = inspección, etc.).

---

## Determinación de Lotes (Batch Determination)

### Cuándo ocurre la determinación
La determinación de lotes en EWM ocurre al crear warehouse tasks de outbound (picking):
- Para cada línea de delivery, el sistema determina qué lote(s) usar.
- Se basa en la estrategia de almacenamiento configurada (stock removal strategy).

### Estrategias de determinación de lotes en EWM

| Estrategia | Descripción |
|---|---|
| **FEFO (First Expired First Out)** | El lote con fecha de vencimiento más próxima se usa primero |
| **FIFO (First In First Out)** | El lote más antiguo (por fecha de entrada al almacén) se usa primero |
| **LIFO (Last In First Out)** | El lote más reciente se usa primero |
| **Batch-specific picking** | La delivery ya especifica el lote; EWM busca ese lote específico |
| **Partial lots allowed** | Permite dividir la cantidad entre múltiples lotes |

### Configuración de FEFO en EWM
1. Activar gestión de lotes en el maestro de materiales (vista Planta/Almacenamiento 1, campo "Batch management").
2. En /SCWM/CUSTOMIZING → Storage Type → Stock Removal: seleccionar estrategia FEFO.
3. Activar "Shelf life management" en el maestro de materiales (vista Planta/Almacenamiento 2).
4. Configurar "Min. remaining shelf life" y "Total shelf life" por material/planta.
5. La fecha de vencimiento (VFDAT en /SCWM/AQUA) se usa para el ordenamiento FEFO.

---

## Picking Específico por Lote (Batch-Specific Picking)

### Concepto
En batch-specific picking, la delivery indica un lote específico a usar (no deja que EWM lo determine libremente). Casos de uso:
- Cliente solicitó un lote específico.
- Contrato de venta vinculado a un lote de producción.
- Trazabilidad estricta requerida (farmacéutico, alimentario).

### Flujo
```
Outbound Delivery → Línea con MATNR + CHARG especificado
→ EWM crea WT buscando ese CHARG en el almacén
→ Si no hay stock de ese CHARG → excepción / error
→ Si hay stock → WT hacia staging area con ese lote
```

### Configuración
/SCWM/CUSTOMIZING → Delivery Types → Batch-Specific Picking: activar por tipo de delivery.

---

## Batch Splitting (División de Lotes)

### Cuándo ocurre
Cuando la cantidad solicitada supera el stock disponible de un único lote, EWM puede dividir automáticamente la cantidad entre múltiples lotes:

```
Delivery: Material X, 100 unidades
Lote A: 60 unidades disponibles (FEFO: vence primero)
Lote B: 80 unidades disponibles

→ EWM crea 2 WT:
   WT1: Material X, Lote A, 60 ud
   WT2: Material X, Lote B, 40 ud
```

### Activación
- "Partial lots" activado en la estrategia de stock removal.
- La delivery puede tener múltiples sub-items (split items) en el EWM.
- Requiere que el tipo de entrega permita multiple batches por línea.

---

## Características de Lote (Batch Characteristics)

Las características de lote son atributos específicos de un lote que EWM puede usar para:
- Determinar el lote correcto (classification-based batch determination).
- Mostrar información al operador en RF.
- Tomar decisiones de inspección (temperatura, pH, pureza, etc.).

### Características comunes en almacén
| Característica | Descripción | Uso |
|---|---|---|
| `LOBM_VFDAT` | Fecha de vencimiento | FEFO, visible en RF |
| `LOBM_HSDAT` | Fecha de fabricación | Cálculo de edad del lote |
| `LOBM_MHDRZ` | Vida útil restante mínima | Validación GR de proveedor |
| `LOBM_MHDLP` | Vida útil mínima para delivery | Validación outbound |
| Temperatura | Temperatura de almacenamiento | Verificación en RF |
| Humedad | % humedad | Control de calidad |
| Concentración | % pureza / concentración | Farmacéutico / químico |

### Configuración de características
MM → Batch Classification: clase de lote (class type 023) con características ABAP.
EWM puede leer estas características via /SCWM/BATCH_CHAR.

---

## Shelf Life Management (Gestión de Vida Útil)

### Parámetros en el maestro de materiales (Vista Planta/Almacenamiento 2)
| Campo | Descripción |
|---|---|
| **Total shelf life** | Vida útil total desde fabricación (días) |
| **Min. remaining shelf life** | Vida mínima restante aceptable en GR (días) |
| **Min. remaining shelf life (delivery)** | Vida mínima restante para despacho a cliente |
| **Storage conditions** | Condiciones de almacenamiento requeridas |
| **Period indicator** | D (días), M (meses), Y (años) |

### Flujo de validación en GR
```
GR de proveedor → Lote con SLED ingresada
→ EWM calcula: Vida útil restante = SLED - Fecha GR
→ Compara con "Min. remaining shelf life"
→ Si insuficiente → Bloquea GR o crea excepción
```

### Flujo de validación en outbound
```
Picking → Lote con SLED
→ EWM calcula: Vida útil restante al momento de despacho
→ Compara con "Min. remaining shelf life (delivery)"
→ Si insuficiente → No propone el lote para picking
```

---

## SLED y BBD

### Definiciones
- **SLED (Shelf Life Expiration Date)**: Fecha de vencimiento — el producto no puede usarse después de esta fecha. Sinónimo: expiration date.
- **BBD (Best Before Date)**: Fecha de consumo preferente — el producto puede seguir siendo seguro pero ya no cumple calidad óptima. Más común en alimentos.

### En SAP EWM
Ambos se almacenan en el campo `VFDAT` de `/SCWM/AQUA`. La distinción SLED/BBD es semántica y depende del negocio; la lógica FEFO aplica a ambos (se usa primero el que vence antes).

### Ingreso de SLED/BBD
- En GR manual: el usuario ingresa la fecha de vencimiento al registrar el goods receipt.
- Automático: si la vida útil total está configurada en el material, el sistema calcula `VFDAT = Fecha GR + Total shelf life`.
- En producción: la fecha de fabricación ingresada más la vida útil total.

---

## Gestión de Números de Serie (Serial Numbers) en EWM

### Concepto
Los números de serie identifican unidades individuales de un producto. A diferencia de los lotes (que agrupan múltiples unidades), cada número de serie es único para cada unidad física.

### Perfiles de número de serie (Serial Number Profiles)
Configurados en MM → Serial Number Management (SPRO → Plant Maintenance → Basic Settings):

| Perfil | Descripción | Serialización en |
|---|---|---|
| **MMSL** | Solo en movimientos de material | GR, GI, Transfer |
| **PPAU** | Producción + todos los movimientos | PP + MM |
| **SDAU** | Ventas + movimientos | SD + MM |
| **SDRQ** | Requerido en SD (delivery obligatorio) | SD obligatorio |

### Serialización en EWM — Niveles

#### Nivel producto (material)
- El número de serie se asigna directamente al material en el warehouse task.
- Cada unidad que se mueve tiene un número de serie individual.
- EWM verifica el número de serie en la confirmación de RF.

#### Nivel HU (Handling Unit)
- La HU completa tiene un número de serie asignado.
- La HU puede contener múltiples unidades (cajas de 10 piezas serializadas).
- El escaneo de la HU en RF captura todos los seriales contenidos.

#### Serialización mixta
- HU con número de serie de contenedor (shipping unit serial).
- Producto dentro de HU también con serial individual.
- Más común en electrónica de alta gama o equipos industriales.

### Flujo de serialización en outbound
```
Outbound Delivery → Línea de producto serializado
→ EWM crea WT con cantidad (ej. 5 unidades)
→ Operador en RF:
   1. Escanea bin origen
   2. Escanea serial 1, serial 2, ... serial 5
   3. Confirma WT con 5 seriales asignados
→ Sistema registra: delivery item → 5 números de serie específicos
→ MM registra GI con trazabilidad completa
```

---

## Consultas MCP para /SCWM/AQUA con Batch y Serial

### Consultar stock por lote en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, LGTYP, MATNR, CHARG, NISTA, EINME, VFDAT, WDATU, INSPTYP]
  where: LGNUM = '[WH]' AND MATNR = '[MATERIAL]'
  order_by: VFDAT ASC
```

### Consultar lotes próximos a vencer (FEFO critical)
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, MATNR, CHARG, NISTA, EINME, VFDAT]
  where: LGNUM = '[WH]' AND VFDAT BETWEEN '[TODAY]' AND '[DATE_LIMIT]' AND NISTA > 0
  order_by: VFDAT ASC
```

### Consultar dónde está un lote específico en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGTYP, LGPLA, MATNR, CHARG, NISTA, EINME, HUIDENT]
  where: LGNUM = '[WH]' AND MATNR = '[MATERIAL]' AND CHARG = '[BATCH]'
```

### Buscar lotes con vida útil insuficiente para despacho
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, MATNR, CHARG, NISTA, VFDAT]
  where: LGNUM = '[WH]' AND NISTA > 0 AND VFDAT < '[MIN_ALLOWED_VFDAT]'
  order_by: MATNR, VFDAT ASC
```

### Consultar stock serializado en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA_SER
  fields: [LGNUM, LGPLA, MATNR, CHARG, SERNR, HUIDENT, NISTA]
  where: LGNUM = '[WH]' AND MATNR = '[MATERIAL]'
```

### Buscar un número de serie específico en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA_SER
  fields: [LGNUM, LGPLA, LGTYP, MATNR, CHARG, SERNR, HUIDENT]
  where: LGNUM = '[WH]' AND SERNR = '[SERIAL_NUMBER]'
```

### Consultar warehouse tasks de un lote específico
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/ORDIM_O
  fields: [LGNUM, TANUM, MATNR, CHARG, NISTA, EINME, VLTYP, VLPLA, NLTYP, NLPLA, TOSTAT]
  where: LGNUM = '[WH]' AND MATNR = '[MATERIAL]' AND CHARG = '[BATCH]'
```

### Verificar clasificación de un lote (características)
```
Tool: ReadTableData
Parameters:
  table_name: AUSP
  fields: [OBJEK, ATINN, ATWRT, ATFLV, ATFLB, MSEHI]
  where: OBJEK = '[PLANT]/[MATERIAL]/[BATCH]'
```

### Consultar lotes bloqueados por QM con stock en almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, MATNR, CHARG, NISTA, EINME, INSPTYP, VFDAT]
  where: LGNUM = '[WH]' AND INSPTYP IN ('S', 'Q') AND NISTA > 0
  order_by: MATNR, CHARG
```
