# Quality Inspection en EWM

## Visión General

La inspección de calidad en SAP EWM gestiona el stock de productos que requieren verificación antes de ser liberados para su uso o despacho. EWM se integra con SAP QM (Quality Management) para crear lotes de inspección, registrar resultados y tomar decisiones de uso, mientras que EWM controla el movimiento físico del stock de inspección dentro del almacén.

En S/4HANA 2023, la integración EWM-QM es nativa en el mismo sistema, lo que elimina interfaces y permite visibilidad en tiempo real del estado del stock de inspección.

---

## Tipo de Almacenamiento de Inspección (QI Storage Type)

### Concepto
El QI Storage Type es un tipo de almacenamiento especial en EWM donde se ubica físicamente el stock durante el período de inspección. Es un área de cuarentena gestionada dentro del almacén.

### Características del QI Storage Type
- El stock aquí almacenado tiene estado de valoración "Quality Inspection" (Q en el stock especial de MM).
- No puede usarse para picking de outbound deliveries regulares.
- Solo puede salir mediante una decisión de uso (usage decision) en QM.
- Puede ser una zona física separada o un tipo de almacenamiento lógico.

### Configuración en /SCWM/CUSTOMIZING
- Crear storage type con indicador "Quality Inspection".
- Asignar estrategia de putaway automática hacia QI storage type para los materiales que requieren inspección.
- Configurar reglas de determinación: qué materiales van a QI vs. stock libre.

---

## Proceso Completo de Quality Inspection

### Flujo estándar GR → Inspección → Decisión

```
1. GR (Goods Receipt) registrado en EWM/MM
   → Stock entra como tipo Q (Quality Inspection stock)

2. Putaway automático al QI Storage Type
   → EWM crea WT hacia la zona de cuarentena

3. QM crea Inspection Lot automáticamente
   → Lote de inspección con parámetros definidos por plan de muestreo

4. Inspector registra resultados en QM
   → Medidas, características, aprobaciones/rechazos

5. Usage Decision en QM
   → Decisión: Liberar / Bloquear / Rechazar / Devolver

6. EWM reacciona a la Usage Decision
   → Liberar: WT de QI Storage Type → stock libre
   → Bloquear: WT hacia zona bloqueada o retención en QI
   → Rechazar/Scrap: WT hacia zona de desechos + movimiento MM de baja
```

---

## Tipos de Stock de Inspección en EWM

| Tipo de stock | Código MM | Descripción |
|---|---|---|
| **Quality Inspection** | Q | Stock pendiente de inspección de calidad |
| **Blocked** | S | Stock bloqueado por decisión de QM |
| **Restricted** | R | Stock con restricciones parciales |
| **Unrestricted** | Libre | Stock liberado para uso normal |

---

## Integración con QM (Inspection Lots)

### Creación automática de inspection lot
El inspection lot se crea automáticamente cuando:
- Se registra un GR con un material que tiene plan de inspección activo.
- El origen de inspección (inspection origin) es "01" (GR from vendor) o "08" (GR from production).

### Parámetros del inspection lot relevantes para EWM
- **Cantidad de inspección**: Puede ser total o muestra parcial.
- **Fecha de completitud requerida**: Fecha límite para la decisión de uso.
- **Almacén de inspección**: El warehouse EWM donde está el stock.
- **Lote (batch)**: Vinculación al número de lote si hay gestión de lotes.

### Resultado de la Usage Decision → movimiento de stock EWM
| Código UD | Acción en QM | Movimiento EWM |
|---|---|---|
| **A (Accept)** | Lote aceptado sin restricciones | WT: QI → Unrestricted stock |
| **R (Reject)** | Lote rechazado | WT: QI → Scrap / devolución |
| **B (Block)** | Lote bloqueado parcialmente | WT: QI → Blocked stock |
| **S (Sample use)** | Muestra destruida en análisis | Ajuste de cantidad en EWM |

---

## Gestión de Muestras (Sample Management) en EWM

### Tipos de muestreo
1. **100% inspection**: Todo el lote debe inspeccionarse.
2. **Statistical sampling**: Solo una muestra representativa (calculada por QM según AQL).
3. **Skip inspection**: Proveedores con historial excelente pueden saltar inspección.

### Manejo de muestras en EWM
- La cantidad de muestra puede extraerse como stock separado hacia un área de laboratorio.
- EWM crea una WT especial de tipo "Sample extraction".
- La cantidad de muestra destruida en análisis genera un movimiento de scrapping en MM.
- El stock restante (no muestreado) permanece en QI Storage Type hasta la UD.

### Configuración de muestreo
/SCWM/CUSTOMIZING → Quality Inspection → Sample Management:
- Movimiento de muestra: desde QI Storage Type hacia zona de laboratorio.
- Tipo de almacenamiento de laboratorio.
- Indicador de destrucción de muestra (genera baja automática).

---

## Documentos de Calidad (Quality Documents)

EWM puede generar o vincular documentos de calidad:
- **Certificate of Analysis (CoA)**: Certificado del proveedor adjunto al inspection lot.
- **Inspection record**: Registro de mediciones tomadas por el inspector.
- **Non-conformance report**: Informe de no conformidad generado en QM Notifications.

Los documentos pueden visualizarse desde EWM en el contexto del stock (vínculo a GOS / Document Management).

---

## Reglas de Inspección por Producto/Proveedor

### Determinación de plan de inspección
QM determina qué inspection lot crear basándose en:
1. **Material** (maestro de materiales, vista QM).
2. **Proveedor** (combinación material-proveedor en info record de QM).
3. **Planta** y **almacén**.
4. **Origen de inspección** (GR externo, producción, devolution, etc.).

### Evaluación de proveedor (Vendor Evaluation)
- QM registra el resultado de cada inspection lot como puntuación para el proveedor.
- Proveedores con buenas puntuaciones pueden calificar para "skip lot" (sin inspección).
- Integración con MM → Purchasing Info Record.

---

## Gestión de Estado de Lote (Batch Status)

Cuando hay gestión de lotes activa, la inspección afecta el estado del lote:

| Estado del lote | Descripción |
|---|---|
| **Unrestricted** | Lote libre para uso |
| **Restricted** | Lote con restricciones, requiere decisión |
| **Blocked** | Lote bloqueado por QM |

El cambio de estado de lote se propaga en toda la cadena de suministro:
- Bloquea el lote en todos los almacenes.
- Impide su uso en órdenes de producción.
- Impide su despacho a clientes.

Transacción: MSC2N (cambio de estado de lote) — triggereada automáticamente desde QM Usage Decision.

---

## Área de Cuarentena (Quarantine Area)

### Propósito
La zona de cuarentena es el área física donde se almacena el stock pendiente de inspección. Puede ser:
- Una sección del almacén cercada físicamente.
- Un tipo de almacenamiento lógico en EWM sin área física dedicada.
- Un almacén EWM separado (warehouse number distinto) para inspección.

### Mejores prácticas de diseño
- Ubicar el QI Storage Type cerca del área de recepción (GR dock).
- Separar físicamente los productos rechazados de los pendientes.
- Tener un área de laboratorio / muestras dentro o adyacente a cuarentena.
- Señalización visual clara (etiquetas QI, paneles visuales).

---

## Matriz de Decisión — Qué hacer con el stock

| Situación | Acción recomendada |
|---|---|
| Material nuevo de nuevo proveedor | 100% inspection + CoA obligatorio |
| Proveedor certificado, historial excelente | Skip lot habilitado |
| Material con fecha de caducidad próxima | Inspección urgente + regla FEFO en picking |
| Lote rechazado parcialmente | Split lote: liberar parte conforme, bloquear parte rechazada |
| GR de devolución de cliente | Inspection lot con origen de inspección de devoluciones |
| Rework desde producción | Inspection lot origen producción (inprocess/final) |

---

## Consultas MCP relevantes para Quality Inspection

### Consultar stock en estado de inspección en el almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, MATNR, CHARG, INSPTYP, MEINS, NISTA, EINME]
  where: LGNUM = '[WH]' AND INSPTYP = 'Q'
```

### Consultar lotes de inspección abiertos vinculados al almacén
```
Tool: ReadTableData
Parameters:
  table_name: QMEL
  fields: [QMNUM, MATNR, CHARG, LGORT, WERKS, PRUEFLOS, STATUS, KDAUF]
  where: LGORT = '[SLOC]' AND STATUS NOT IN ('LTCA', 'ABKL')
```

### Consultar inspection lots de QM por material
```
Tool: ReadTableData
Parameters:
  table_name: QALS
  fields: [PRUEFLOS, MATNR, CHARG, WERK, LGORT, MENGEIST, MENGEEINS, ENSTEHDAT, UDCODE, UDZEIT]
  where: MATNR = '[MATERIAL]' AND UDCODE = ''
  order_by: ENSTEHDAT DESC
```

### Consultar warehouse tasks hacia QI Storage Type
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/ORDIM_C
  fields: [LGNUM, TANUM, MATNR, CHARG, INSPTYP, NLTYP, NLPLA, VLENME, VLPLA]
  where: LGNUM = '[WH]' AND NLTYP = '[QI_STORAGE_TYPE]'
  order_by: LSD DESC
```

### Verificar decisiones de uso registradas recientemente
```
Tool: ReadTableData
Parameters:
  table_name: QAVE
  fields: [PRUEFLOS, MATNR, CHARG, UDCODE, VDATZ, UNAME]
  where: VDATZ >= '[DATE]'
  order_by: VDATZ DESC
```

### Consultar estado de lotes (batch status) bloqueados
```
Tool: ReadTableData
Parameters:
  table_name: MCH7
  fields: [MATNR, CHARG, WERKS, LGORT, RLOSD, SPERR]
  where: WERKS = '[PLANT]' AND SPERR = 'X'
```

### Buscar stock de inspección con antigüedad (posible vencimiento de UD)
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/AQUA
  fields: [LGNUM, LGPLA, MATNR, CHARG, INSPTYP, NISTA, EINME, WDATU]
  where: LGNUM = '[WH]' AND INSPTYP = 'Q' AND WDATU <= '[DATE_LIMIT]'
  order_by: WDATU ASC
```
