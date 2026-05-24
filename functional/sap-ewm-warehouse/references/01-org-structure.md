# Estructura Organizativa EWM

## Componentes Organizativos Principales

### Warehouse Number (Numero de Almacen)
- Unidad organizativa central de EWM. Tabla de customizing: `/SCWM/T300`.
- Agrupa todos los tipos de almacen, secciones y ubicaciones bajo un identificador unico (4 caracteres).
- En EWM Embebido (S/4HANA 2023), el Warehouse Number se asigna directamente al cliente logistico (planta/almacen MM) en la tabla `/SCWM/ASGN` (anteriormente T320 en EWM Descentralizado).
- Parametros clave por Warehouse Number: unidad de peso/volumen, gestion de UMs (HU management), perfil de control de almacen, moneda local de almacen.

### Storage Type (Tipo de Almacenamiento)
- Subdivision logica del almacen. Tabla: `/SCWM/T301`.
- Ejemplos: estanteria convencional, almacen automatico, zona de recepcion, zona de expedicion, area de consolidacion.
- Cada Storage Type tiene: categoria de almacen (rack, bulk, floor), capacidad por defecto, estrategia de entrada/salida.
- Indicadores importantes: gestion de HU obligatoria, gestion de tareas dobles, relevante para inventario.

### Storage Section (Seccion de Almacenamiento)
- Subdivision del Storage Type. Tabla: `/SCWM/T302`.
- Permite agrupar ubicaciones por caracteristicas (zona fria, zona peligrosa, zona de alta rotacion).
- Usado en determinacion de ubicacion (putaway) para filtrar candidatos.

### Storage Bin (Ubicacion)
- Unidad fisica minima de almacenamiento. Tabla principal: `/SCWM/LAGP`.
- Campos clave: LGNUM (warehouse number), LGTYP (storage type), LGBER (storage section), LGPLA (bin ID), LPTYP (bin type).
- Estructura de coordenadas: pasillo (GANG), columna (SPALTE), nivel (REGAL) — configurables por almacen.
- Estados: vacia, parcialmente ocupada, llena, bloqueada para entrada/salida.
- Capacidad: peso maximo, volumen maximo, cantidad maxima de HUs.

### Activity Area (Area de Actividad)
- Agrupa ubicaciones para planificacion de tareas y asignacion de recursos.
- Tabla: `/SCWM/ACTY`.
- Usado en gestion de recursos (RF, Pick-by-Voice, Pick-by-Light).
- Permite balanceo de carga entre operarios y equipos de manejo de materiales.

### Work Center (Puesto de Trabajo)
- Punto fisico donde se realizan actividades de almacen (deconsolidacion, embalaje, control de calidad).
- Tabla: `/SCWM/TWRKC`.
- Asociado a una o varias actividades de almacen (GR processing, packing, QI, etc.).

## Asignacion Planta/Almacen → Warehouse Number

### EWM Embebido (S/4HANA 2023 — Preferido)
- La asignacion se realiza en customizing: planta + storage location → Warehouse Number EWM.
- Tabla de asignacion: `/SCWM/ASGN`.
- No requiere RFC entre sistemas; EWM corre en el mismo sistema que MM/SD/PP.
- Activacion: en S/4HANA 2023 se activa EWM via Business Function `LOG_EWM_INTEGRATION` o configuracion de sistema embebido.
- Las entregas logisticas se distribuyen automaticamente a EWM al guardar en MM/SD.

### EWM Descentralizado (referencia)
- Sistema EWM separado, conectado via RFC/qRFC a ECC o S/4HANA.
- Tabla de asignacion en sistema host: TVSWZ (planta/almacen → warehouse number WM) + configuracion de distribucion EWM.
- No recomendado para nuevas implementaciones en S/4HANA 2023.

## Jerarquia Completa

```
Warehouse Number  (/SCWM/T300)
  └── Storage Type  (/SCWM/T301)
        └── Storage Section  (/SCWM/T302)
              └── Storage Bin  (/SCWM/LAGP)
                    └── HU / Quant
```

## Transacciones Clave

| Transaccion | Descripcion |
|---|---|
| `/SCWM/MON` | Monitor de almacen (vista general) |
| `/SCWM/LS01` | Crear ubicacion |
| `/SCWM/LS02` | Modificar ubicacion |
| `/SCWM/LS03` | Visualizar ubicacion |
| `/SCWM/LS04` | Lista de ubicaciones (con filtros) |
| `/SCWM/ACTCONF` | Confirmacion de tareas de almacen |
| `SPRO` | Customizing EWM (Extended Warehouse Mgmt) |

## Consultas MCP Recomendadas

Para explorar la configuracion del almacen via MCP SAP ADT, usar:

```
// Leer contenido de tabla de customizing
tool: ReadTable
params: { table_name: "/SCWM/T300", fields: ["LGNUM", "LGBEZ", "MSEHI"], max_rows: 50 }

// Explorar asignaciones planta-almacen
tool: ReadTable
params: { table_name: "/SCWM/ASGN", fields: ["LGNUM", "WERKS", "LGORT"], max_rows: 100 }

// Listar Storage Types configurados
tool: ReadTable
params: { table_name: "/SCWM/T301", fields: ["LGNUM", "LGTYP", "LGTVS", "LGBEZ"], max_rows: 100 }

// Ver ubicaciones del almacen
tool: ReadTable
params: { table_name: "/SCWM/LAGP", fields: ["LGNUM","LGTYP","LGBER","LGPLA","LPTYP","BESTQ"], max_rows: 200 }
```

## Notas S/4HANA 2023

- EWM Embebido elimina la necesidad de Warehouse Management (WM clasico). No coexisten ambos para el mismo almacen.
- El Lean WM (gestion basica de almacenes) puede seguir activo para otros almacenes no migrados a EWM.
- Migration tool disponible: `LSMW` + `/SCWM/` BAPIs para migracion masiva de ubicaciones.
- Fiori Apps relevantes: "Manage Warehouses" (F3547), "Monitor Warehouse" (F3548).
