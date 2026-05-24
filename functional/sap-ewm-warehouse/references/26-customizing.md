# Customizing EWM Overview

Guía de configuración del sistema EWM en S/4HANA 2023 mediante SPRO. Cubre todas las rutas de customizing relevantes para la implementación y operación del almacén extendido bajo el namespace /SCWM/.

---

## Ruta Base en SPRO

```
IMG > SCM Extended Warehouse Management > Extended Warehouse Management
```

Abreviado como: `SPRO > EWM`

---

## 1. Definición del Almacén

### 1.1 Crear Número de Almacén
```
SPRO > EWM > Master Data > Define Warehouses
Tabla: /SCWM/T340
```
- Número de almacén (4 caracteres)
- Asignación a planta / Storage Location (para EWM embebido)
- Tipo de EWM: Embebido (S/4HANA) vs Descentralizado
- Moneda del almacén, zona horaria, unidad de peso/volumen por defecto

### 1.2 Áreas de Actividad
```
SPRO > EWM > Master Data > Define Activity Areas
Tabla: /SCWM/TACT
```
- Agrupación lógica de bins para gestión de tareas
- Asignación de recursos a áreas de actividad
- Priorización de áreas en la determinación de almacenamiento

### 1.3 Zonas de Almacén
```
SPRO > EWM > Master Data > Define Storage Sections
Tabla: /SCWM/TSECT
```
- Secciones dentro de un tipo de almacén
- Uso en estrategias de ubicación (putaway) y extracción (picking)

---

## 2. Tipos de Proceso de Almacén (Warehouse Process Types)

### 2.1 Definición
```
SPRO > EWM > Goods Receipt Process > Define Warehouse Process Types
Tabla: /SCWM/T340B
```
Los Warehouse Process Types (WPT) controlan el comportamiento de las tareas de almacén:

| WPT | Descripción típica | Dirección |
|-----|--------------------|-----------|
| GR01 | Goods Receipt - Standard | Inbound |
| GI01 | Goods Issue - Standard | Outbound |
| RL01 | Putaway - Automático | Inbound |
| PK01 | Picking - Standard | Outbound |
| ST01 | Stock Transfer interno | Internal |
| PI01 | Physical Inventory | Internal |
| RW01 | Rewarehouse | Internal |
| VAS01 | Value Added Services | Internal |

### 2.2 Configuración del WPT
Para cada WPT se define:
- **Dirección de movimiento**: Inbound / Outbound / Internal
- **Tipo de tarea de almacén**: Pick, Putaway, Move, Pack, etc.
- **Creación de HU**: Si se crea Handling Unit en la tarea
- **Verificación**: Confirmar cantidad / diferencias permitidas
- **Prioridad por defecto**
- **Queue assignment**: Cola de trabajo asociada

---

## 3. Determinación del Proceso de Almacenamiento (Storage Process Determination)

### 3.1 Perfil de Proceso de Almacenamiento
```
SPRO > EWM > Goods Receipt Process > Storage Process Determination
Tabla: /SCWM/T340C
```

Jerarquía de determinación:
1. Tipo de material + Warehouse Process
2. Grupo de proceso de almacenamiento
3. Perfil de proceso de almacenamiento
4. Estrategia de putaway / picking

### 3.2 Estrategias de Putaway
```
SPRO > EWM > Goods Receipt Process > Define Putaway Strategies
```
Estrategias disponibles en S/4HANA 2023:

| Código | Estrategia | Descripción |
|--------|-----------|-------------|
| A | Adición a stock existente | Consolida materiales en bins ocupados |
| B | Ubicación vacía | Primera ubicación libre disponible |
| C | Almacén fijo | Bin fijo por material |
| F | FIFO | First In, First Out (por fecha de entrada) |
| L | LIFO | Last In, First Out |
| I | Inventario uniforme | Distribución equitativa entre bins |
| P | Próximo uso | Cerca del punto de consumo |
| Q | Pallets completos | Solo si cantidad completa de pallet |

### 3.3 Estrategias de Extracción (Picking)
```
SPRO > EWM > Goods Issue Process > Define Removal Strategies
```

| Código | Estrategia |
|--------|-----------|
| F | FIFO por fecha entrada |
| L | LIFO |
| M | FEFO (Fecha expiración) |
| N | FEFO extendido (Lote más próximo a vencer) |
| A | Bin con mayor cantidad |
| Q | Cantidad parcial / pallets completos primero |
| Z | Estrategia personalizada (user exit) |

---

## 4. Reglas de Creación de Órdenes de Almacén (Warehouse Order Creation Rules)

### 4.1 Definición de Reglas
```
SPRO > EWM > Cross-Process Settings > Warehouse Order > Define Warehouse Order Creation Rules
Tabla: /SCWM/TWOCR
```

Las Warehouse Orders agrupan Warehouse Tasks. Las reglas definen:
- **Criterios de agrupación**: Material, Área, Recurso, Ruta, Tipo
- **Límite de tareas por orden**: Max líneas por WO
- **Límite de peso/volumen**: Restricciones físicas
- **Tiempo de procesamiento estimado**
- **Agrupación por zona de destino**

### 4.2 Perfil de Creación de WO
```
SPRO > EWM > Cross-Process Settings > Warehouse Order > Define Warehouse Order Creation Profiles
```
- Asignación de reglas por tipo de proceso
- Control de creación: Manual, Automática, por Wave
- Interacción con Resource Management

### 4.3 Waves (Olas de Picking)
```
SPRO > EWM > Goods Issue Process > Wave Management > Define Wave Templates
Tabla: /SCWM/TWAVE
```
- Criterios de selección de entregas para la wave
- Reglas de liberación: manual, automática por tiempo, por cantidad mínima
- Agrupación de entregas en la wave
- Secuencia de procesamiento

---

## 5. Rangos de Número (Number Ranges)

### 5.1 Objetos de Rango de Número EWM
```
SPRO > EWM > Cross-Process Settings > Number Ranges
Transacciones: /SCWM/NR01, /SCWM/NR02, ...
```

| Objeto | Descripción | Transacción |
|--------|-------------|-------------|
| /SCWM/HU | Handling Units internas | /SCWM/NR_HU |
| /SCWM/WT | Warehouse Tasks | /SCWM/NR_WT |
| /SCWM/WO | Warehouse Orders | /SCWM/NR_WO |
| /SCWM/PI | Physical Inventory Documents | /SCWM/NR_PI |
| /SCWM/QINSP | Queue Inspection | /SCWM/NR_QI |

### 5.2 Configuración
- Rango externo vs interno
- Advertencia de agotamiento (threshold %)
- Reutilización de números (solo en desarrollo)

---

## 6. Configuración de Impresión

### 6.1 Etiquetas (Labels)
```
SPRO > EWM > Cross-Process Settings > Printing > Label Printing
```
- Definición de tipos de etiqueta: HU Label, Bin Label, Pick Label
- Asignación de formularios SmartForms / Adobe Forms
- Determinación de impresora: por área, por tipo de proceso
- Número de copias por tipo de operación

### 6.2 Listas de Picking (Pick Lists)
```
SPRO > EWM > Goods Issue Process > Printing > Pick List Configuration
```
- Layout de la lista de picking
- Ordenamiento: por pasillo, por zona, por material
- Contenido: bins, cantidades, descripción, código de barras
- Asignación de impresora por usuario / área de actividad

### 6.3 Determinación de Impresora
```
SPRO > EWM > Cross-Process Settings > Printing > Define Printer Determination
Tabla: /SCWM/TPRINT
```
Jerarquía de determinación:
1. Usuario + Tipo de documento
2. Área de actividad + Tipo de documento
3. Almacén + Tipo de documento
4. Default del sistema

---

## 7. Definición de Roles de Usuario

### 7.1 Roles EWM Estándar en S/4HANA 2023
```
Transacción: PFCG
```

| Rol | Descripción |
|-----|-------------|
| /SCWM/R_WM_ADM | Administrador de almacén |
| /SCWM/R_WM_IB | Responsable de entrada de mercancías |
| /SCWM/R_WM_OB | Responsable de salida de mercancías |
| /SCWM/R_WM_PI | Responsable de inventario físico |
| /SCWM/R_WM_RM | Gestión de recursos |
| /SCWM/R_WM_MON | Monitor de almacén (solo lectura) |
| /SCWM/R_WM_RF | Usuario de terminales RF |

### 7.2 Configuración de Roles en Warehouse Monitor
```
SPRO > EWM > Cross-Process Settings > Warehouse Monitor > Define Monitor Roles
```
- Vistas disponibles por rol
- Alertas configurables por perfil
- Acciones permitidas desde el monitor

---

## 8. Rutas Internas (Internal Routing)

### 8.1 Definición
```
SPRO > EWM > Cross-Process Settings > Internal Routing > Define Routes
Tabla: /SCWM/TROUTE
```
- Secuencia de bins para recorrido optimizado
- Tipos de ruta: Picking route, Putaway route
- Asignación de ruta a área de actividad
- Dirección del recorrido (ascending / descending)

### 8.2 Optimización de Rutas
- Algoritmo de secuenciación: por coordenadas XYZ del bin
- Agrupación por pasillo (aisle grouping)
- Compatibilidad con Wave Management

---

## 9. Determinación del Tipo de Almacén de Destino (Destination Storage Type)

### 9.1 Configuración
```
SPRO > EWM > Goods Receipt Process > Storage Type Determination
Tabla: /SCWM/TSTYPE_DET
```

Secuencia de determinación:
1. **Indicador especial de almacenamiento** del material
2. **Hazmat class** (materiales peligrosos)
3. **Temperatura** (condiciones especiales)
4. **Peso / Volumen** de la HU
5. **Tipo de almacenamiento** disponible (capacidad libre)
6. **Regla alternativa** (fallback)

### 9.2 Tabla de Determinación
```
/SCWM/TSTYPE_SEQ
```
Define la secuencia de tipos de almacén a intentar en orden de preferencia.

---

## 10. Configuracion Orientada a Layout vs Orientada a Proceso

### 10.1 Configuración Orientada a Layout
- Foco en la estructura física del almacén
- Bins, pasillos, filas, columnas con coordenadas
- Restricciones físicas: peso máximo, volumen, tipo de material
- Relevante para: estanterías, mezzanines, cámaras frigoríficas

```
SPRO > EWM > Master Data > Define Storage Bins (layout)
/SCWM/LS01 - Crear bin individual
/SCWM/LS_MASS - Creación masiva de bins
```

### 10.2 Configuración Orientada a Proceso
- Foco en el flujo de trabajo y las transiciones de estado
- Control de qué procesos ocurren en qué áreas
- Integración con Resource Management y Queue Management
- Relevante para: zonas de staging, packing stations, dock doors

```
SPRO > EWM > Cross-Process Settings > Process-Oriented Storage Control
```

### 10.3 Compatibilidad
Ambos enfoques pueden coexistir en el mismo almacén:
- Layout-oriented: almacenamiento en estanterías
- Process-oriented: zonas de entrada, staging, expedición
- La determinación de tipo de almacén decide el enfoque por zona

---

## Transacciones de Referencia Rápida

| Transacción | Descripción |
|-------------|-------------|
| /SCWM/PRDI | Configuración de proceso de almacenamiento |
| /SCWM/WPCUST | Configuración de Warehouse Process Types |
| /SCWM/ORDERC | Reglas de creación de Warehouse Orders |
| /SCWM/MON | Warehouse Monitor |
| /SCWM/LS01 | Crear Storage Bin |
| /SCWM/LS03 | Visualizar Storage Bin |
| /SCWM/MATID | Master Data Material en EWM |
| /SCWM/SRUT | Storage Type Search |
| SPRO | Pantalla principal de customizing |
