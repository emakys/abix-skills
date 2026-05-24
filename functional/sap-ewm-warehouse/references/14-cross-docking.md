# Cross-Docking

## Concepto General

El **Cross-Docking (CD)** en EWM es el proceso de transferir mercancias directamente desde el muelle de recepcion (inbound dock) al muelle de salida (outbound dock) sin almacenamiento intermedio, o con almacenamiento temporal minimo. El objetivo es reducir el tiempo de ciclo, los costos de almacenamiento y el manejo de mercancias.

En S/4HANA 2023 con Embedded EWM, el cross-docking se integra nativamente con SD (entregas de salida), MM (recepciones) y TM (gestion de transporte), permitiendo flujos complejos de redistribucion.

El CD es especialmente valioso cuando:
- La demanda es conocida antes de la llegada de la mercancia
- El producto tiene alta rotacion y poco tiempo de permanencia
- Se necesita consolidar envios de multiples proveedores para un destino

## Tipos de Cross-Docking

### 1. Cross-Docking Planificado / Predeterminado (Planned / Predetermined)
Impulsado desde ERP (MM/SD) antes de que llegue la mercancia:

- La necesidad de salida ya existe al momento de planificar la recepcion
- ERP vincula la orden de compra (inbound) con la orden de venta (outbound)
- EWM recibe la instruccion de CD al crear el inbound delivery
- Cuando llega la mercancia, se genera directamente el WT hacia el staging area de salida
- **Ventaja**: maxima eficiencia, sin almacenamiento
- **Requisito**: demanda firme conocida con anticipacion

Flujo:
```
Purchase Order → Inbound Delivery (CD-flagged) → GR → WT to Outbound Staging → Outbound Delivery
```

### 2. Cross-Docking Oportunistico (Opportunistic / EWM-Driven)
EWM detecta oportunidades de CD durante el proceso de recepcion:

- Llega mercancia sin estar planificada como CD
- EWM verifica si existe demanda pendiente (outbound deliveries) para esa mercancia
- Si hay coincidencia (material, cantidad, fecha), EWM propone el CD
- El sistema crea una asociacion dinamica entre inbound y outbound delivery
- **Ventaja**: aprovecha oportunidades sin planificacion previa
- **Requisito**: outbound deliveries ya creadas y en estado pendiente de picking

### 3. Cross-Docking Push (Exceso / Redistribucion)
Redistribucion de exceso de stock hacia destinos que lo necesitan:

- Llega mas stock del esperado o se detecta desequilibrio entre ubicaciones
- EWM "empuja" el exceso directamente hacia destinos de demanda
- Comun en distribucion minorista: centro de distribucion → tiendas
- Puede ser manual (decision del planificador) o automatico (reglas configuradas

### 4. Cross-Docking de Transporte (Transportation Cross-Docking)
Integrado con SAP TM:

- Carga de un vehiculo (trailer inbound) se transfiere a otro vehiculo (trailer outbound)
- Sin desconsolidacion: se mueve la carga completa o por contenedor
- Optimiza rutas de transporte de larga distancia
- Requiere integracion TM-EWM activa

### 5. Flow-Through Processing
Variante donde la mercancia pasa por una zona de procesamiento antes de salir:

- Recepcion → zona de processing (etiquetado, control calidad, sorting) → salida
- El "almacenamiento" es temporal y en staging area (no en rack permanente)
- Tiempo en almacen: horas, no dias

### 6. Pick-by-Line (Retail Distribution)
Para distribucion minorista con multiples destinos (tiendas):

- Mercancias llegan del proveedor en pallets mixtos o homogeneos
- Se desconsolidan por linea de destino (store)
- Se reembalan y se etiquetan por tienda de destino
- Se consolidan por camion de reparto
- **KPI clave**: throughput de lineas por hora, precision de sorteo

## Configuracion de Cross-Docking

### Reglas de Cross-Docking (CD Rules)
Definidas en IMG > EWM > Cross-Docking > Define Cross-Docking Rules

Parametros:
- Tipo de CD (planned, opportunistic, push)
- Material / grupo de materiales aplicables
- Ventana de tiempo: cuanto antes puede llegar la necesidad de salida
- Prioridad sobre otras estrategias de putaway
- Staging area asignada para CD

### Determinacion de CD (CD Determination)
El sistema evalua si aplicar CD usando:
1. Tipo de inbound delivery / fuente (OC, devolucion, transferencia)
2. Material y sus atributos (indicador CD en material master)
3. Regla de CD activa para el warehouse number
4. Existencia de demanda pendiente (para oportunistico)

### Relevancia CD en Delivery
- En el inbound delivery item: campo `CD_RELEVANT` indica si el item esta planificado para CD
- En el outbound delivery item: referencia al inbound delivery si ya esta asociado
- Activacion desde ERP o manualmente en EWM

### Warehouse Process Type para CD
Se configura un WPT especifico para movimientos de cross-docking:
- Categoria: Cross-Docking
- Sin ubicacion de almacenamiento intermedia (direct staging)
- Staging area de entrada y salida claramente definidas

## Staging Areas en Cross-Docking

La correcta configuracion de staging areas es critica:

```
Dock de Entrada → Staging Area Inbound (GR Zone)
                         ↓ [CD Transfer]
Staging Area Outbound (GI Zone) → Dock de Salida
```

- Cada dock door tiene su staging area asociada
- Los WT de CD mueven stock directamente entre staging areas
- El stock nunca entra al area de almacenamiento permanente (racks)

## Beneficios del Cross-Docking

| Beneficio | Impacto |
|-----------|---------|
| Reduccion de tiempo de ciclo | Horas vs dias de almacenamiento |
| Menor costo de almacenamiento | Menos espacio utilizado en racks |
| Reduccion de manejo | Menos movimientos de WT |
| Mejora de frescura (productos perecederos) | FEFO mas efectivo |
| Mayor velocidad de respuesta al cliente | Entregas mas rapidas |
| Reduccion de inventario | Menor capital inmovilizado |

## KPIs de Cross-Docking

- **CD Rate (%)**: porcentaje de volumen procesado via CD vs total recibido
- **Dwell Time**: tiempo promedio que la mercancia pasa en staging antes de salir
- **CD Utilization**: % de capacidad de staging area utilizada
- **Perfect CD Order Rate**: % de transferencias CD sin errores

## Arbol de Decision: Seleccion de Tipo de CD

```
¿Existe demanda firme ANTES de la recepcion?
├── SI → ¿La orden viene del ERP con link SD-MM?
│         ├── SI → Cross-Docking Planificado
│         └── NO → Flow-Through con staging temporal
└── NO → ¿Existe outbound delivery pendiente para el material?
          ├── SI → Cross-Docking Oportunistico
          └── NO → ¿Hay desequilibrio de stock a redistribuir?
                    ├── SI → Cross-Docking Push
                    └── NO → Putaway normal (sin CD)
```

## Tablas Principales

| Tabla | Descripcion |
|-------|-------------|
| `/SCWM/CDRULE` | Reglas de cross-docking |
| `/SCWM/CDDET` | Determinacion de CD (asignacion reglas) |
| `/SCWM/CDT` | Tipos de cross-docking |
| `/SCWM/WHO` | Warehouse orders (incluye WT de CD) |
| `/SCWM/ORDIM_O` | Outbound delivery orders (campo CD-relevant) |
| `/SCWM/ORDIM_I` | Inbound delivery orders (campo CD-relevant) |

## Consultas MCP Recomendadas

```
-- Explorar objetos de CD en EWM
SearchObject: tipo CLAS, nombre "/SCWM/CL_CD*" → clases de cross-docking
SearchObject: tipo FUGR, nombre "/SCWM/CD*" → function groups de CD
ReadClass: /SCWM/CL_CD_CTRL → controlador principal de CD
GetFunctionGroup: /SCWM/CROSS_DOCKING → funciones core

-- BAdIs para extension
SearchObject: tipo DEVC, nombre "/SCWM/CROSS_DOCKING"
-- Ejemplo de BAdI: /SCWM/EX_CD_DETERMINATION para logica custom de determinacion
```

## Configuracion IMG

```
IMG > Extended Warehouse Management
  > Cross-Docking
    > Activate Cross-Docking
    > Define Cross-Docking Types
    > Define Cross-Docking Rules
    > Assign CD Rules to Warehouse Number
    > Configure Staging Areas for Cross-Docking
    > Define Time Windows for Opportunistic CD
  > Interfaces
    > ERP Integration
      > Cross-Docking Relevance from ERP
```

## Mejores Practicas S/4HANA 2023

- Empezar con CD planificado (menor complejidad de configuracion) antes de activar oportunistico
- Configurar staging areas dedicadas al CD para evitar confusion con stock regular
- Monitorear el dwell time: si supera X horas, el beneficio del CD se pierde
- Para retail pick-by-line: combinar CD con sorting systems automatizados si el volumen lo justifica
- Usar BAdI `/SCWM/EX_CD_DETERMINATION` para reglas de negocio complejas (excepciones por cliente, material, temporada)
- En integracion TM-EWM: verificar que los freight orders esten correctamente sincronizados antes de activar transportation CD
- Medir el CD Rate objetivo: industria sugiere 20-30% para almacenes de distribucion general, hasta 70%+ en retail de alta rotacion
