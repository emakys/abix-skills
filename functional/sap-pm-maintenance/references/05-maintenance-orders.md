# Ordenes de Mantenimiento

## Concepto

La orden de mantenimiento es el documento de ejecucion en PM. Planifica, programa, ejecuta y registra costes de trabajos de mantenimiento. Es un objeto CO que acumula costes reales.

## Tipos de Orden

| Tipo | Descripcion | Uso |
|------|-------------|-----|
| PM01 | Correctivo | Reparacion de averia ya ocurrida |
| PM02 | Preventivo | Trabajo planificado basado en tiempo/rendimiento |
| PM03 | Inspeccion/Revision | Diagnostico, inspeccion visual, revision |
| PM04 | Reacondicionamiento | Overhaul/refurbishment de componente |
| PM05 | Calibracion | Instrumentos de medicion |
| PM06 | Predictivo | Basado en condicion (mediciones, IoT) |
| PM10 | Parada/Turnaround | Mantenimiento mayor con shutdown |

Config: SPRO → PM → Maintenance Orders → Functions and Settings → Order Types

## Estructura de la Orden

### Cabecera (AUFK + AFIH)
| Campo | Tabla | Descripcion |
|-------|-------|-------------|
| AUFNR | AUFK | Numero de orden |
| AUART | AUFK | Tipo de orden |
| KTEXT | AUFK | Texto breve |
| EQUNR | AFIH | Equipo |
| TPLNR | AFIH | Ubicacion tecnica |
| IWERK | AUFK | Centro planificacion mantto |
| INGRP | AFIH | Grupo planificador |
| GSTRP | AFKO | Fecha inicio programada |
| GLTRP | AFKO | Fecha fin programada |
| GETRI | AFKO | Fecha inicio real |
| GLTRI | AFKO | Fecha fin real |
| KOSTV | AUFK | Centro coste responsable |
| AUFPL | AFKO | Plan de operaciones |
| QMNUM | AFIH | Aviso de referencia |
| OBJNR | AUFK | Numero objeto (status) |

### Operaciones (AFVC)
| Campo | Descripcion |
|-------|-------------|
| VORNR | Numero operacion (0010, 0020...) |
| LTXA1 | Texto operacion |
| ARBID | Puesto de trabajo |
| WERKS | Centro |
| STEUS | Clave de control |
| ANESSION | Numero personas |
| DAESSION | Duracion |
| ARBEI | Trabajo (horas) |

### Componentes/Repuestos (RESB)
| Campo | Descripcion |
|-------|-------------|
| RSNUM | Numero reserva |
| RSPOS | Posicion |
| MATNR | Material/repuesto |
| BDMNG | Cantidad necesaria |
| ENMNG | Cantidad tomada |
| MEINS | Unidad |
| LGORT | Almacen |

## Claves de Control (STEUS)

| Clave | Tipo | Descripcion |
|-------|------|-------------|
| PM01 | Interna | Trabajo interno con tiempo |
| PM02 | Interna | Trabajo interno sin tiempo |
| PM03 | Externa | Servicio externo (subcontrato) |
| PM04 | Interna | Solo costes generales |

Config: SPRO → PM → Maintenance Orders → Functions → Operation → Control key

## Ciclo de Vida de la Orden

```
1. CREADA (CREA) — IW31
   → Planificacion: operaciones, repuestos, puestos trabajo
   |
2. LIBERADA (REL) — IW32 → Liberar
   → Reservas de material se activan
   → Impresion de orden de trabajo
   |
3. EN EJECUCION
   → Toma de materiales (MIGO/MB1A → mov 261)
   → Registro de servicios externos (ML81N)
   → Confirmaciones parciales (IW42)
   |
4. CONFIRMADA (CNF) — Confirmacion final (IW41/IW42)
   → Horas trabajadas, datos tecnicos
   |
5. CIERRE TECNICO (TECO) — IW32 → Funciones → Cierre tecnico
   → No mas movimientos de mercancias
   → No mas confirmaciones
   → Reservas pendientes se eliminan
   |
6. CIERRE COMERCIAL (CLSD) — Despues de liquidacion
   → No mas contabilizaciones
   → Orden archivable
```

## Planificacion de Trabajo

### Operaciones
1. Crear operacion → asignar puesto de trabajo → definir tiempo trabajo
2. Clave de control determina: confirmacion, programacion, material, servicio externo
3. Relaciones entre operaciones: FS (fin-inicio), SS, FF, SF

### Repuestos/Componentes
1. Asignar material a operacion → crea reserva automatica
2. Campos: material, cantidad, almacen, centro
3. No planificados: se pueden agregar durante ejecucion

### Servicios Externos
1. Operacion con clave PM03 (externa)
2. Genera solicitud de pedido automatica o manual
3. Entrada de servicios: ML81N / Hoja de entrada de servicios

## Queries MCP

```
-- Ordenes abiertas de un centro
GetSqlQuery("SELECT AUFK.AUFNR,AUFK.AUART,AUFK.KTEXT,AFIH.EQUNR,AFIH.TPLNR,AFKO.GSTRP,AFKO.GLTRP FROM AUFK JOIN AFIH ON AUFK.AUFNR=AFIH.AUFNR JOIN AFKO ON AUFK.AUFNR=AFKO.AUFNR WHERE AUFK.AUART LIKE 'PM%' AND AUFK.LOESSION=''")

-- Operaciones de una orden
GetSqlQuery("SELECT VORNR,LTXA1,ARBID,STEUS,DAESSION,ARBEI FROM AFVC WHERE AUFPL=(SELECT AUFPL FROM AFKO WHERE AUFNR='{orden}')")

-- Componentes/repuestos
GetSqlQuery("SELECT RSPOS,MATNR,BDMNG,ENMNG,MEINS,LGORT FROM RESB WHERE AUFNR='{orden}'")

-- Costes de la orden
GetSqlQuery("SELECT RACCT,SUM(HSL) as TOTAL FROM ACDOCA WHERE AUFNR='{orden}' AND GJAHR='{year}' AND RLDNR='0L' GROUP BY RACCT")

-- Historial ordenes por equipo
GetSqlQuery("SELECT AUFK.AUFNR,AUFK.AUART,AUFK.KTEXT,AFKO.GSTRP FROM AUFK JOIN AFIH ON AUFK.AUFNR=AFIH.AUFNR JOIN AFKO ON AUFK.AUFNR=AFKO.AUFNR WHERE AFIH.EQUNR='{equipo}' ORDER BY AFKO.GSTRP DESC")

-- Status de una orden
GetSqlQuery("SELECT STAT,INACT FROM JEST WHERE OBJNR=(SELECT OBJNR FROM AUFK WHERE AUFNR='{orden}') AND INACT=''")
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IW31 | Crear orden |
| IW32 | Modificar orden |
| IW33 | Visualizar orden |
| IW38 | Lista ordenes (seleccion) |
| IW39 | Lista ordenes (multi-nivel) |
| IW40 | Visualizar operaciones |
| IW41 | Confirmacion individual |
| IW42 | Confirmacion colectiva |
| IW47 | Confirmacion con seleccion |
| IW66 | Analisis costes orden |
| IW67 | Costes plan/real orden |
| IW37N | Lista ordenes ampliada |

## Fiori Apps

| App ID | Nombre | Tipo |
|--------|--------|------|
| F1596 | Manage Maintenance Orders | Transactional |
| F2375 | Maintenance Planner | Transactional |
| F2649 | Create Maintenance Order | Transactional |
| F3304 | Monitor Maintenance Orders | Analytical |

## Mejores Practicas

1. **Siempre vincular** a equipo o ubicacion tecnica — base para historial y estadisticas
2. **Planificar antes de liberar** — operaciones, materiales y tiempos completos
3. **Confirmar operaciones** — registra horas reales, base para MTTR y costes mano obra
4. **Regla liquidacion** — definir ANTES del cierre tecnico (a CC, activo o WBS)
5. **TECO cuando trabajo fisico completado** — aunque falten facturas de proveedores pendientes
6. **CLSD solo despues de liquidacion** — cierre comercial definitivo
