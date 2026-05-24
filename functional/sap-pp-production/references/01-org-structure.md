# Estructura Organizativa PP

## Niveles relevantes

| Nivel | Tabla | Campo | Descripcion |
|-------|-------|-------|-------------|
| Mandante | T000 | MANDT | Nivel mas alto |
| Sociedad | T001 | BUKRS | Entidad legal |
| Centro/Planta | T001W | WERKS | Unidad productiva principal |
| Almacen | T001L | LGORT | Almacen dentro del centro |
| Area MRP | T460A | BERID | Subdivision del centro para MRP |
| Puesto de trabajo | CRHD | ARBPL | Recurso productivo |
| Linea de produccion | CRHD | ARBPL | Tipo capacidad 007 |

## Centro (Planta) — T001W

El centro es la unidad organizativa central de PP. Toda la planificacion, produccion y gestion de stocks se ejecuta a nivel de centro.

```sql
SELECT WERKS, NAME1, BWKEY, FABKL FROM T001W ORDER BY WERKS
```

### Campos clave

| Campo | Descripcion |
|-------|-------------|
| WERKS | Codigo centro |
| NAME1 | Nombre |
| BWKEY | Area valoracion (normalmente = WERKS) |
| FABKL | Calendario de fabrica |

## Almacen — T001L

```sql
SELECT WERKS, LGORT, LGOBE FROM T001L WHERE WERKS = '{centro}'
```

### Almacenes tipicos PP

| Almacen | Uso |
|---------|-----|
| 0001 | Materia prima |
| 0002 | Producto terminado |
| 0003 | Producto semielaborado |
| 0004 | WIP / piso de planta |
| 0010 | Almacen de calidad |

## Area MRP — T460A

Permite dividir un centro en sub-areas con planificacion independiente.

```sql
SELECT BERID, BESSION, WERKS FROM T460A WHERE WERKS = '{centro}'
```

### Cuando usar areas MRP
- Almacenes con planificacion independiente
- Subcontratacion con MRP separado
- Lineas de produccion con parametros MRP distintos

## Calendario de fabrica — T001W-FABKL

Define dias laborales para scheduling de ordenes y MRP.

```sql
-- Calendario asignado al centro
SELECT WERKS, FABKL FROM T001W WHERE WERKS = '{centro}'
```

- Se mantiene en SPRO o transaccion SCAL
- Afecta: scheduling de ordenes, fechas MRP, capacidad disponible
- Path: `SPRO > Logistics General > Factory Calendar`

## Asignacion organizativa PP

```
Mandante (T000)
└── Sociedad (T001)
    └── Centro (T001W) ← UNIDAD CENTRAL PP
        ├── Almacen (T001L)
        ├── Area MRP (T460A) [opcional]
        ├── Puestos de trabajo (CRHD)
        ├── Versiones fabricacion (MKAL)
        └── Recursos PP-PI (CRID)
```

## Consultas MCP

```sql
-- Centros con calendario
SELECT WERKS, NAME1, FABKL FROM T001W ORDER BY WERKS

-- Almacenes por centro
SELECT WERKS, LGORT, LGOBE FROM T001L WHERE WERKS = '{centro}'

-- Areas MRP por centro
SELECT BERID, BESSION, WERKS FROM T460A WHERE WERKS = '{centro}'
```
