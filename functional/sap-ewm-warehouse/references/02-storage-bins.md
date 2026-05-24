# Storage Bins y Layout

## Concepto de Storage Bin (Ubicacion de Almacen)

Un Storage Bin es la unidad minima de almacenamiento en EWM. Representa una posicion fisica o logica donde se pueden almacenar materiales, unidades de manejo (HU) o quants. Tabla principal: `/SCWM/LAGP`.

## Estructura y Nomenclatura de Ubicaciones

### Campos de Identificacion (clave primaria de `/SCWM/LAGP`)
| Campo | Longitud | Descripcion |
|---|---|---|
| `LGNUM` | 4 | Warehouse Number |
| `LGTYP` | 4 | Storage Type |
| `LGPLA` | 18 | Storage Bin ID (nombre fisico) |

### Coordenadas de Layout (Pasillo-Columna-Nivel)
- `GANG`: Pasillo (aisle). Ejemplo: `001`, `002`, `A01`.
- `SPALTE`: Columna / posicion horizontal (stack). Ejemplo: `001`–`050`.
- `REGAL`: Nivel / altura (level). Ejemplo: `001` (suelo), `002`, `003`.
- Formato tipico de bin: `A01-050-003` = Pasillo A01, columna 50, nivel 3.
- El formato se configura por Storage Type en customizing (`/SCWM/T301`).

### Seccion de Almacenamiento
- Campo `LGBER`: Storage Section a la que pertenece la ubicacion.
- Asignada durante la creacion de la ubicacion o por regla de determinacion automatica.

## Tipos de Ubicacion (Bin Types)

Tabla de tipos: `/SCWM/T307` (Bin Types). Campo en `/SCWM/LAGP`: `LPTYP`.

| Bin Type tipico | Uso |
|---|---|
| `RACK` | Estanteria convencional |
| `BULK` | Almacenamiento en bloque (floor storage) |
| `PICK` | Ubicacion de picking (zona activa) |
| `STAGE` | Area de consolidacion/staging |
| `GR` | Zona de entrada de mercancias |
| `GI` | Zona de salida de mercancias |
| `PACK` | Puesto de embalaje |
| `DOOR` | Puerta de muelle (door) |

Los Bin Types se definen libremente en customizing y se usan en estrategias de determinacion de ubicacion.

## Capacidad de Ubicaciones

### Limites Configurables (por ubicacion o por Storage Type)
- **Peso maximo** (`GEWMAX`, unidad `GEWEI`): limite de carga en kg/lb.
- **Volumen maximo** (`VOLMAX`, unidad `MEINS`): limite en m3/ft3.
- **Cantidad maxima de HUs** (`ANZHU`): numero maximo de unidades de manejo simultaneas.
- **Cantidad maxima de quants** (`MAXANZ`): para almacenes sin gestion de HU.

### Gestion de Capacidad
- Verificacion de capacidad activable por Storage Type: el sistema bloquea traspasos que excedan limites.
- Estrategia "Mixed storage" (almacenamiento mixto): permite multiples materiales/lotes por ubicacion.
- Estrategia "Fixed bin" (ubicacion fija): un material especifico asignado permanentemente.

## Estados de Ubicacion

Campo `BESTQ` en `/SCWM/LAGP` indica el estado de ocupacion:

| Valor BESTQ | Descripcion |
|---|---|
| ` ` (espacio) | Vacia |
| `S` | Ocupada parcialmente |
| `F` | Llena (full) |
| `B` | Bloqueada para todos los movimientos |
| `X` | Bloqueada para entrada |
| `Y` | Bloqueada para salida |
| `I` | En inventario (bloqueada temporalmente) |

Campo adicional `LGPLA_STAT`: estado logico de la ubicacion (activa/inactiva).

## Zonas Especiales

### Zonas de Mercancias Peligrosas (Hazmat)
- Indicador de clase de peligro (`HAZMAT_ZONE`) en la ubicacion.
- Solo materiales con clase de peligro compatible pueden almacenarse.
- Customizing: `/SCWM/` → Mercancias Peligrosas → Asignacion de clases a Storage Types/Bins.

### Zonas de Temperatura Controlada
- Campo de clase de temperatura (`TEMPZONE`) en Storage Type y en ubicacion.
- Materiales con requisito de temperatura (del maestro de materiales EWM) solo se asignan a ubicaciones compatibles.
- Ejemplo: `COLD` (2-8°C), `FREEZE` (-18°C), `AMB` (temperatura ambiente).

### Ubicaciones de Staging (Pulmones)
- Areas intermedias entre muelles y zona de almacenaje permanente.
- Identificadas por Storage Type dedicado (p.ej. `STAG`).
- Las tareas de warehouse (WT) hacia/desde staging tienen confirmacion inmediata en muchos flujos.

## Determinacion de Ubicacion (Bin Determination)

### Estrategias de Entrada (Putaway)
Configuradas en customizing EWM → Estrategias de busqueda de ubicacion:
- `P1`: Ubicacion fija de material (fixed bin).
- `P2`: Ubicacion vacia (empty bin).
- `P3`: Adicion a stock existente (addition to existing stock).
- `P4`: Almacenamiento masivo (bulk storage — rellena hasta capacidad).
- `P5`: Siguiente ubicacion vacia en secuencia (next empty).
- `NP`: Putaway por Slotting (resultado del proceso de slotting EWM).

### Estrategias de Salida (Stock Removal)
- `F`: FIFO (primero en entrar, primero en salir) por fecha de entrada.
- `L`: LIFO.
- `M`: FEFO (primero en expirar — usa fecha de caducidad del lote).
- `S`: Segun shelf life / SLED.
- `Q`: Cantidad mayor primero (maximizar vaciado de ubicacion).

## Transacciones de Gestion de Ubicaciones

| Transaccion | Descripcion |
|---|---|
| `/SCWM/LS01` | Crear ubicacion individual |
| `/SCWM/LS02` | Modificar ubicacion |
| `/SCWM/LS03` | Visualizar ubicacion (datos completos) |
| `/SCWM/LS04` | Lista de ubicaciones con filtros multiples |
| `/SCWM/LS05` | Crear ubicaciones masivamente (rango de coordenadas) |
| `/SCWM/BINBLK` | Bloqueo/desbloqueo masivo de ubicaciones |
| `/SCWM/SLOTTING` | Proceso de Slotting (asignacion optimizada) |
| `/SCWM/MON` | Monitor → vista "Stock per Bin" |

## Consultas MCP Recomendadas

```
// Listar ubicaciones de un Storage Type
tool: ReadTable
params: {
  table_name: "/SCWM/LAGP",
  fields: ["LGNUM","LGTYP","LGBER","LGPLA","LPTYP","BESTQ","GEWMAX","VOLMAX","ANZHU"],
  where: "LGNUM = '0001' AND LGTYP = 'RACK'",
  max_rows: 500
}

// Ver stock en ubicaciones (quants)
tool: ReadTable
params: {
  table_name: "/SCWM/QUANT",
  fields: ["LGNUM","LGTYP","LGPLA","MATNR","CHARG","QUAN","MEINS","EINDT"],
  where: "LGNUM = '0001'",
  max_rows: 200
}

// Ver tipos de ubicacion configurados
tool: ReadTable
params: {
  table_name: "/SCWM/T307",
  fields: ["LGNUM","LPTYP","LPTXT"],
  max_rows: 50
}

// Ubicaciones bloqueadas
tool: ReadTable
params: {
  table_name: "/SCWM/LAGP",
  fields: ["LGNUM","LGTYP","LGPLA","BESTQ","LGPLA_STAT"],
  where: "LGNUM = '0001' AND (BESTQ = 'B' OR BESTQ = 'X' OR BESTQ = 'Y')",
  max_rows: 100
}
```

## Notas S/4HANA 2023 — EWM Embebido

- La creacion masiva de ubicaciones se hace tipicamente via LSMW o BAPIs `/SCWM/BAPI_STORAGEBINS_CREATE`.
- El Slotting EWM (optimizacion de layout) esta disponible en S/4HANA 2023 via app Fiori "Slotting Simulation" (F3622).
- Las ubicaciones pueden visualizarse en 3D con el Warehouse Visualization (addon SAP Visual Business).
- Para almacenes automatizados (AS/RS, Miniload), la interfaz EWM-MFS (Material Flow System) controla los bins automaticamente.
