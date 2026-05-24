# RF Framework (Radio Frequency)

## Arquitectura del RF Framework en EWM

El RF Framework de SAP EWM proporciona la infraestructura para operar el almacén mediante dispositivos de radiofrecuencia (terminales portátiles, escáneres, etc.). En S/4HANA 2023 Embedded EWM, el framework se configura en el namespace /SCWM/ y soporta tanto ITS Mobile (HTML clásico) como Fiori for Warehouse Operator.

### Componentes principales
- **RF Framework Core**: Motor de presentación y navegación entre pantallas RF.
- **Perfiles RF**: Agrupan configuraciones de usuario, verificación y comportamiento.
- **Transacciones RF**: Programas ABAP dedicados que implementan cada proceso de almacén.
- **Menú RF**: Árbol de opciones que aparece en el dispositivo al autenticarse.
- **Recursos RF**: Representación del dispositivo físico y su usuario asignado.

---

## Transacciones RF principales (/SCWM/)

### Autenticación y menú
| Transacción | Descripción |
|---|---|
| /SCWM/RFUI | Customizing central del RF Framework |
| /SCWM/RFMENU | Configuración de menús RF por perfil |
| /SCWM/RF01 | Logon RF (entrada al sistema desde el dispositivo) |

### Inbound / Putaway
| Transacción | Descripción |
|---|---|
| /SCWM/RFGR | Confirmación de GR (goods receipt) en RF |
| /SCWM/RFPU | Putaway (almacenamiento) — confirmar tarea de almacenamiento |
| /SCWM/RFHUGR | GR con manejo de HU (Handling Units) |

### Picking / Outbound
| Transacción | Descripción |
|---|---|
| /SCWM/RFPICK | Picking en RF — confirmación de warehouse tasks de salida |
| /SCWM/RFPACK | Packing (empaque) en estaciones RF |
| /SCWM/RFSHIP | Shipping / carga en camión |

### Inventario físico (PI)
| Transacción | Descripción |
|---|---|
| /SCWM/RFPI | Physical Inventory en RF — contar bins |
| /SCWM/RFPIADJ | Ajuste de diferencias de inventario |

### Transferencias internas
| Transacción | Descripción |
|---|---|
| /SCWM/RFST | Stock transfer interno (bin a bin, zona a zona) |
| /SCWM/RFREPLEN | Reabastecimiento (replenishment) |

---

## Perfiles RF y Customizing

### Perfil de usuario RF
Configurado en /SCWM/RFUI. Agrupa:
- **Verification profile**: Define qué elementos deben escanearse (bin, HU, producto, cantidad).
- **Presentation profile**: Tamaño de pantalla, idioma, campos visibles.
- **Menu profile**: Opciones disponibles para el operador.
- **Resource type**: Tipo de equipo asignado al perfil.

### Pasos de configuración
1. Definir **warehouse number** habilitado para RF (/SCWM/CUSTOMIZING).
2. Crear perfiles de presentación (pantalla 20x4, 24x80, etc.).
3. Crear perfiles de verificación (ver sección siguiente).
4. Asignar perfil a usuario de almacén (/SCWM/RFMENU).
5. Configurar menú RF con las transacciones permitidas.
6. Crear recursos RF (ver sección de recursos).

---

## Verificación en RF (Scan de confirmación)

El sistema puede exigir que el operador escanee elementos para confirmar una tarea antes de aceptarla como completada.

### Elementos de verificación configurables
| Elemento | Descripción |
|---|---|
| **Bin de origen** | Escanear la ubicación de donde se toma el stock |
| **Bin de destino** | Escanear la ubicación donde se deposita |
| **HU (Handling Unit)** | Escanear el código de barras de la unidad de manejo |
| **Producto (material)** | Escanear el código del material |
| **Cantidad** | Confirmar cantidad manualmente o por pesaje |
| **Batch** | Escanear/confirmar número de lote |
| **Serial number** | Escanear número de serie |

### Perfil de verificación
Configurado por tipo de tarea de almacén (warehouse task type). Ejemplo:
- Picking: verificar bin origen + producto + HU destino.
- Putaway: verificar bin destino.
- PI Count: verificar bin + producto + cantidad.

---

## Manejo de excepciones en RF

El operador puede reportar problemas durante la ejecución de tareas:
- **Bin vacío**: El bin indicado no tiene stock.
- **Diferencia de cantidad**: Cantidad encontrada difiere de la esperada.
- **HU dañada**: La unidad de manejo está en mal estado.
- **Producto incorrecto**: El material físico no coincide con la tarea.

Cada excepción genera un **warehouse exception** (/SCWM/EXCP) que puede:
- Cancelar la tarea y crear una nueva.
- Escalar a supervisor.
- Registrar diferencia para ajuste de inventario.

Configuración de excepciones: /SCWM/CUSTOMIZING → Exception Codes.

---

## Tipos de recursos RF

Los recursos representan dispositivos físicos en el almacén.

| Tipo de recurso | Descripción |
|---|---|
| **Mobile device** | Terminal portátil de RF estándar |
| **Forklift** | Montacargas con terminal integrada |
| **Pick-by-voice** | Dispositivo de reconocimiento de voz |
| **Put-to-light** | Sistema de luces indicadoras |
| **Conveyor** | Integración con transportadores automáticos |

Configuración: /SCWM/RFUI → Resource Types. Cada recurso tiene:
- Tipo de recurso.
- Usuario SAP asignado.
- Grupo de recursos (para asignación de tareas por grupo).
- Capacidad máxima de carga.

---

## ITS Mobile vs Fiori for Warehouse Operator

### ITS Mobile (clásico)
- Basado en HTML generado por ITS (Internet Transaction Server).
- Pantallas simples, compatibles con terminales RF antiguas.
- Configuración en /SCWM/RFUI con templates de pantalla.
- Ventaja: funciona con hardware legacy de baja capacidad.
- Limitación: UX básica, sin soporte táctil moderno.

### Fiori for Warehouse Operator (S/4HANA 2023)
- Apps Fiori específicas para procesos RF: picking, putaway, PI, etc.
- Diseño responsivo, soporta tablets y smartphones modernos.
- Apps clave:
  - **Outbound Delivery Processing** (F2984).
  - **Inbound Delivery Processing** (F2983).
  - **Physical Inventory** (F2985).
  - **Warehouse Task Monitor** (F2986).
- Requiere launchpad Fiori configurado con roles EWM.
- Ventaja: UX moderna, integración con cámara para escaneo QR.

---

## Soporte de Barcode y QR Code

EWM RF Framework soporta múltiples estándares de código de barras:
- **EAN-128 / GS1-128**: Estándar para productos y HU en logística.
- **EAN-13 / UPC-A**: Códigos de producto retail.
- **QR Code**: Soportado en Fiori for Warehouse Operator.
- **Code 39 / Code 128**: Códigos internos de almacén.

Configuración de interpretación de barcode: /SCWM/BARCODEDEF — define qué campo se infiere de cada tipo de barcode escaneado (material, HU, bin, etc.).

---

## Flujo de una transacción RF (ejemplo: Picking)

```
1. Operador hace logon en terminal RF (/SCWM/RF01)
2. Sistema muestra menú RF (según perfil de usuario)
3. Operador selecciona "Picking"
4. Sistema presenta primera tarea pendiente (WT abierta)
   → Muestra: Bin origen, Material, Cantidad
5. Operador se desplaza al bin indicado
6. Operador escanea bin origen (verificación)
7. Operador escanea material / HU (verificación)
8. Operador confirma cantidad
9. Operador escanea bin destino (staging area)
10. Sistema confirma warehouse task → WT en estado "Confirmed"
11. Sistema presenta siguiente tarea (loop)
```

---

## Consultas MCP relevantes para RF Framework

### Verificar customizing RF activo
```
Tool: ExecuteReport
Parameters:
  program_name: /SCWM/R_RF_CUSTOMIZING_CHECK
  warehouse_number: [WH]
```

### Leer perfiles RF de un almacén
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/TRFPROF
  fields: [LGNUM, RFPROFILE, DESCR, PRES_PROFILE, VERIF_PROFILE]
  where: LGNUM = '[WH]'
```

### Consultar recursos RF activos
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/TRSRC
  fields: [LGNUM, RSRC, RSRC_TYPE, UNAME, QUEUE_RSRC]
  where: LGNUM = '[WH]' AND ACTIVE = 'X'
```

### Buscar warehouse tasks abiertas para RF
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/ORDIM_O
  fields: [LGNUM, TANUM, TOSTAT, RSRC, QUEUE, PROCTY]
  where: LGNUM = '[WH]' AND TOSTAT = 'A' AND RSRC = ''
```

### Revisar excepciones RF registradas
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/RF_EXCPLOG
  fields: [LGNUM, TANUM, EXCP_CODE, UNAME, TIMESTAMP, EXCP_TEXT]
  where: LGNUM = '[WH]'
  order_by: TIMESTAMP DESC
```

### Consultar menú RF asignado a un usuario
```
Tool: ReadTableData
Parameters:
  table_name: /SCWM/TRFMENU_U
  fields: [LGNUM, UNAME, RFMENU, RFPROFILE]
  where: LGNUM = '[WH]' AND UNAME = '[USER]'
```
