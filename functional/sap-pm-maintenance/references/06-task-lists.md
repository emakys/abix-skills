# Hojas de Ruta / Task Lists

## Concepto

Las hojas de ruta (task lists) definen secuencias estandar de operaciones de mantenimiento reutilizables. Se asignan a planes de mantenimiento o se copian a ordenes. Reducen tiempo de planificacion y estandarizan el trabajo.

## Tipos de Hoja de Ruta

| Tipo | TCode | Asignacion | Tabla |
|------|-------|-----------|-------|
| Equipment Task List | IA01/IA02/IA03 | A un equipo especifico | PLKO (PLNTY='E') |
| Functional Location TL | IA01 (tipo T) | A ubicacion tecnica | PLKO (PLNTY='T') |
| General Maintenance TL | IA11/IA12/IA13 | Sin asignacion fija, reutilizable | PLKO (PLNTY='A') |

## Estructura

### Cabecera (PLKO)
| Campo | Descripcion |
|-------|-------------|
| PLNTY | Tipo (A=general, E=equipo, T=ubicacion) |
| PLNNR | Numero grupo |
| PLNAL | Contador grupo |
| VERWE | Utilizacion (4=mantenimiento) |
| STATU | Status (1=creado, 4=liberado) |
| WERKS | Centro |
| LOESSION | Numero puestos trabajo |

### Operaciones (PLPO)
| Campo | Descripcion |
|-------|-------------|
| VORNR | Numero operacion |
| LTXA1 | Texto operacion |
| ARBID | Puesto de trabajo |
| STEUS | Clave de control |
| VGW01-VGW06 | Valores estandar (duracion, trabajo) |
| DAESSION | Duracion normal |

### Componentes de Material (PLMZ → STPO)
| Campo | Descripcion |
|-------|-------------|
| IDNRK | Material/componente |
| MENGE | Cantidad |
| MEINS | Unidad |

### Paquetes de Mantenimiento (PLAS)
| Campo | Descripcion |
|-------|-------------|
| PAESSION | Paquete de mantenimiento |
| PLNTY | Tipo hoja ruta |
| PLNNR | Numero hoja ruta |

## Uso en Planes de Mantenimiento

1. Crear hoja de ruta general (IA11)
2. Crear posicion de mantenimiento (IP04) → referenciar hoja de ruta
3. Plan de mantenimiento (IP01) → asignar posicion
4. Al ejecutar plan (IP30) → genera orden con operaciones de la hoja de ruta

## Uso Directo en Ordenes

- IW31 → campo "Hoja ruta" → copia operaciones y materiales a la orden
- Se pueden modificar las operaciones copiadas sin afectar la hoja ruta original

## Queries MCP

```
-- Hojas ruta generales de un centro
GetSqlQuery("SELECT PLNTY,PLNNR,PLNAL,KTEXT,WERKS,STATU FROM PLKO WHERE PLNTY='A' AND WERKS='{centro}'")

-- Operaciones de una hoja ruta
GetSqlQuery("SELECT VORNR,LTXA1,ARBID,STEUS,VGW01,DAESSION FROM PLPO WHERE PLNTY='{tipo}' AND PLNNR='{numero}'")

-- Hojas ruta de un equipo
GetSqlQuery("SELECT PLNTY,PLNNR,PLNAL,KTEXT FROM PLKO WHERE PLNTY='E' AND VAESSION='{equipo}'")
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IA01 | Crear hoja ruta equipo |
| IA02 | Modificar hoja ruta equipo |
| IA03 | Visualizar hoja ruta equipo |
| IA05 | Lista hojas ruta equipo |
| IA11 | Crear hoja ruta general |
| IA12 | Modificar hoja ruta general |
| IA13 | Visualizar hoja ruta general |
| IA15 | Lista hojas ruta general |
| IA06 | Crear hoja ruta ubicacion |
| IA07 | Modificar hoja ruta ubicacion |
| IA08 | Visualizar hoja ruta ubicacion |

## Mejores Practicas

1. **Usar hojas ruta generales** cuando el mismo procedimiento aplica a multiples equipos
2. **Hojas ruta de equipo** solo para equipos con procedimientos unicos
3. **Liberar antes de usar** — status 4 (liberado) para uso en produccion
4. **Paquetes de mantenimiento** — asignar operaciones a paquetes para estrategias de multiples niveles
5. **Estandarizar textos** — operaciones con textos claros y concisos, idioma del operador
