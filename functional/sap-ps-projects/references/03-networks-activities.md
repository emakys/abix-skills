# Redes y Actividades — SAP PS S/4HANA 2023

## 1. Concepto de Red en SAP PS

Una Red (Network) en SAP PS es un conjunto de actividades interrelacionadas que representan el plan de trabajo detallado de un proyecto o parte de el. Las redes permiten:

- Planificacion detallada de actividades con dependencias logicas
- Calculo automatico de fechas (programacion en red / CPM)
- Necesidades de capacidad y recursos
- Imputacion de costes por actividad (internos, externos, materiales)
- Generacion automatica de pedidos de compras para actividades externas

La red se vincula a los elementos WBS del proyecto para integrar planificacion de tiempo con control de costes.

---

## 2. Tipos de Red

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Redes →
Definir Tipos de Red
Tabla: T430 (campo AUART)
```

### Tipos de Red Estandar

| Tipo | Descripcion | Uso tipico |
|---|---|---|
| PS01 | Red interna | Actividades con recursos propios |
| PS02 | Red de servicio | Actividades de subcontratacion |
| PS10 | Red de mantenimiento | Conexion con PM |
| PM01 | Mantenimiento preventivo | Heredado de PM |

Cada tipo de red esta asociado a una categoria de orden que determina:
- Rango de numeros de la red
- Tipo de objeto CO (que origina)
- Integracion con PP/PM
- Control de costes y valoracion

---

## 3. Creacion de Redes

### Transacciones Principales

| Transaccion | Descripcion |
|---|---|
| CN01 | Crear red |
| CN02 | Modificar red |
| CN03 | Visualizar red |
| CN20N | Project Builder con redes |
| CN21 | Crear red desde perfil |
| CN22 | Crear red desde plantilla |
| CNB1 | Asignar red a WBS |

### Proceso de Creacion en CN20N

```
1. Abrir proyecto en CJ20N/CN20N
2. En la estructura izquierda, seleccionar WBS receptor
3. Insertar red: menu Editar → Crear red
4. Especificar tipo de red y descripcion
5. Crear actividades dentro de la red
6. Definir relaciones entre actividades
7. Asignar componentes y recursos
8. Guardar
```

---

## 4. Tabla AFKO — Cabecera de Red (Orden)

La tabla AFKO almacena la cabecera de la red (equivalente a la cabecera de orden de PP/PM).

| Campo | Tipo | Descripcion |
|---|---|---|
| AUFNR | CHAR(12) | Numero de red/orden |
| AUART | CHAR(4) | Tipo de red |
| AUTYP | NUMC(2) | Categoria de orden (20=PS) |
| WERKS | CHAR(4) | Centro |
| PSPEL | NUMC(8) | WBS asignado |
| GSTRP | DATS(8) | Fecha inicio basica |
| GLTRP | DATS(8) | Fecha fin basica |
| FTRMS | DATS(8) | Fecha inicio pronosticada |
| FTRMI | DATS(8) | Fecha fin pronosticada |
| GSTRI | DATS(8) | Fecha inicio real |
| GETRI | DATS(8) | Fecha fin real |
| OBJNR | CHAR(22) | Numero de objeto (estado) |
| KOSTL | CHAR(10) | Centro de coste (actividades int.) |
| KALSM | CHAR(6) | Esquema de calculo de costes |

---

## 5. Tabla AFVC — Actividades de Red

La tabla AFVC contiene las actividades individuales de cada red. Es la tabla mas importante para el detalle de actividades.

### Campos Principales de AFVC

| Campo | Tipo | Descripcion |
|---|---|---|
| AUFPL | NUMC(10) | Numero de plan de trabajo (red) |
| APLZL | NUMC(8) | Contador de actividad |
| VORNR | CHAR(4) | Numero de actividad (0010, 0020...) |
| LTXA1 | CHAR(40) | Descripcion de la actividad |
| STEUS | CHAR(4) | Clave de control |
| WERKS | CHAR(4) | Centro |
| ARBID | NUMC(8) | Puesto de trabajo |
| ARBPL | CHAR(8) | Clave puesto de trabajo |
| PSPEL | NUMC(8) | WBS asignado (puede diferir de la red) |
| DAUNO | DEC(7,3) | Duracion normal |
| DAUNE | CHAR(3) | Unidad de duracion |
| MGVRG | DEC(13,3) | Cantidad de trabajo (horas) |
| MEINH | CHAR(3) | Unidad de cantidad |
| APLFL | CHAR(4) | Clave de control de calculo |
| NPLDA | DATS(8) | Fecha inicio schedulada |
| NPLDS | DATS(8) | Fecha fin schedulada |
| FTRMS | DATS(8) | Fecha inicio pronosticada |
| FTRMI | DATS(8) | Fecha fin pronosticada |
| ISTAZ | DATS(8) | Fecha inicio real |
| ISTA2 | DATS(8) | Fecha fin real |
| OBJNR | CHAR(22) | Numero de objeto (estado) |
| ISTAD | CHAR(4) | Estado de la actividad |

---

## 6. Tabla AFVV — Valores de Actividad (Horas y Costes)

La tabla AFVV complementa AFVC con los valores de planificacion de horas, maquina y costes.

| Campo | Descripcion |
|---|---|
| AUFPL | Numero de plan de trabajo |
| APLZL | Contador de actividad |
| VGW01..VGW06 | Valores de planificacion (horas hombre, maquina, setup...) |
| VGE01..VGE06 | Unidades de cada valor |
| PEINH | Cantidad base para calculo de tarifa |
| LOANZ | Cantidad de personal |
| LOEIN | Unidad de tiempo de trabajo |
| SKT01..SKT06 | Claves de actividad (tipo de actividad CO) |

---

## 7. Tipos de Actividad

### 7.1 Actividad Interna

Actividades realizadas con recursos propios de la empresa. El coste se calcula a partir de la tarifa del puesto de trabajo.

**Campos relevantes:**
- ARBPL: Puesto de trabajo (vinculado a un centro de coste)
- SKT01-06: Tipos de actividad CO (actividades de coste)
- VGW01-06: Horas planificadas por tipo

**Clave de control tipica:** PS01, PS02

```
Calculo de coste:
Horas plan × Tarifa del tipo actividad CO = Coste plan
```

### 7.2 Actividad Externa

Actividades realizadas por proveedores externos. Generan automaticamente una solicitud de pedido o un pedido de compras.

**Campos relevantes en AFVC:**
- STEUS: Clave de control con flag "pedido externo"
- PREIS: Precio externo planificado
- WAERS: Moneda
- LIFNR: Proveedor (opcional)
- EKGRP: Grupo de compras

**Proceso:**
```
Actividad externa → (liberacion red) → Solicitud de pedido automatica
                                     → Pedido de compras (ME21N)
                                     → Entrada de mercancias/servicios (MIGO/ML81N)
                                     → Verificacion de factura (MIRO)
                                     → Coste real en ACDOCA
```

**Clave de control tipica:** PS03

### 7.3 Actividad de Coste

Actividades que representan costes generales no vinculados a trabajo especifico. Permiten planificar costes en clases de coste directamente.

**Campos relevantes:**
- KOSTL: Centro de coste imputado
- KSTAR: Clase de coste
- Monto planificado en moneda del proyecto

**Clave de control tipica:** PS04

---

## 8. Claves de Control (STEUS)

Las claves de control son el parametro mas critico de las actividades de red.

### Parametros de la Clave de Control

| Parametro | Descripcion |
|---|---|
| Impresion orden | Si aparece en lista de trabajo impresa |
| Confirmacion | Tipo de confirmacion (manual, automatica, hito) |
| Calculo automatico | Calculo automatico de costes al confirmar |
| Solicitud compra | Generacion automatica de SolPed (actividad externa) |
| Capacidad | Genera necesidades de capacidad para el puesto |
| Inspection QM | Genera lote de inspeccion QM |
| Tiempo real | Participa en calculo de ruta critica |
| Hito | La actividad tiene hitos programables |

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Redes → Actividades →
Definir Claves de Control para Actividades de Red
Transaccion: OP67
```

---

## 9. Componentes de Material (RESB)

Las actividades de red pueden tener componentes de material asignados, los cuales generan necesidades de material y reservas.

### Tabla RESB — Reservas / Necesidades de Componentes

| Campo | Tipo | Descripcion |
|---|---|---|
| RSNUM | NUMC(10) | Numero de reserva |
| RSPOS | NUMC(4) | Posicion de reserva |
| AUFNR | CHAR(12) | Numero de red |
| AUFPL | NUMC(10) | Plan de trabajo |
| APLZL | NUMC(8) | Contador actividad |
| MATNR | CHAR(40) | Material |
| WERKS | CHAR(4) | Centro |
| LGORT | CHAR(4) | Almacen |
| BDMNG | QUAN | Cantidad necesaria |
| MEINS | UNIT | Unidad de medida |
| BEDAT | DATS | Fecha de necesidad |
| BWART | CHAR(3) | Tipo de movimiento (261, 281...) |
| KZEAR | CHAR(1) | Indicador entrada definitiva |

### Tipos de Componentes

| Tipo | Descripcion |
|---|---|
| L (Stock) | Material en almacen → genera reserva |
| N (No gestionado) | Informativo, sin movimiento de stock |
| R (Proveedor) | Compra directa → genera SolPed |
| B (Bulto) | Material de embalaje |

---

## 10. Relaciones entre Actividades (Dependencias)

Las relaciones definen el orden logico de ejecucion de las actividades en la red.

### Tipos de Relacion

| Tipo | Sigla | Descripcion | Ejemplo |
|---|---|---|---|
| Fin-Inicio | FS (Finish-Start) | B empieza cuando A termina | Diseno → Construccion |
| Inicio-Inicio | SS (Start-Start) | B empieza cuando A empieza | Paralelo con desfase |
| Fin-Fin | FF (Finish-Finish) | B termina cuando A termina | Dos tareas finalizan juntas |
| Inicio-Fin | SF (Start-Finish) | B termina cuando A empieza | Raro, solapamiento inverso |

### Configuracion de Relaciones

En CN20N o la transaccion de modificacion de red:
```
1. Seleccionar actividad origen
2. Insertar relacion → seleccionar tipo
3. Seleccionar actividad destino
4. Especificar desfase temporal (positivo o negativo)
5. Ejemplo: FS con desfase +5 dias = B empieza 5 dias despues de que A termine
```

### Tabla AFAB — Relaciones de Red

| Campo | Descripcion |
|---|---|
| AUFPL | Plan de trabajo (red) |
| APLZL | Actividad sucesora |
| APLFL | Actividad predecesora |
| ANORD | Tipo de relacion (NF=FS, NA=SS, EF=FF, EA=SF) |
| MINZO | Tiempo de desfase |
| MINZE | Unidad de desfase |

---

## 11. Hitos (Milestones)

Los hitos son puntos de control en las actividades de red. En SAP PS tienen dos funciones principales:

1. **Hitos de programacion**: Marcan eventos criticos en el cronograma
2. **Hitos de facturacion**: Desencadenan la creacion de facturas en proyectos PS-SD

### Tabla AFMG — Hitos de Red

| Campo | Descripcion |
|---|---|
| AUFPL | Plan de trabajo |
| APLZL | Actividad con hito |
| MEILNR | Numero de hito |
| MLNAM | Nombre del hito |
| MLDAT | Fecha del hito |
| FKDAT | Fecha de facturacion (billing milestone) |
| DPROG | Programa de facturacion (billing plan) |

### Hitos de Facturacion

```
Actividad de red → Hito con FKDAT → Facturacion SD
                                   → AL confirmar hito → billing plan SD activa posicion
                                   → VF01 → Factura SD
```

La confirmacion del hito (CN27) activa la posicion en el plan de facturacion del pedido de venta asociado al WBS.

---

## 12. Asignacion de Red a WBS

Una red puede estar asignada a un WBS a nivel de cabecera y/o a nivel de actividad individual.

### Asignacion a Nivel de Cabecera (AFKO-PSPEL)

La red completa se imputa al WBS especificado en AFKO. Es la asignacion por defecto.

### Asignacion a Nivel de Actividad (AFVC-PSPEL)

Cada actividad puede asignarse a un WBS diferente. Util cuando las actividades de una misma red corresponden a distintas fases del proyecto (distintos WBS).

```
Red NETZ-001
├── Actividad 0010 → WBS.1.1 (Diseno)
├── Actividad 0020 → WBS.1.2 (Construccion)
└── Actividad 0030 → WBS.1.3 (Pruebas)
```

---

## 13. Transacciones de Gestion de Redes

| Transaccion | Descripcion |
|---|---|
| CN01 | Crear red independiente |
| CN02 | Modificar red |
| CN03 | Visualizar red |
| CN20N | Project Builder con gestion de redes |
| CN22 | Crear desde plantilla de red |
| CNB1 | Visualizar lista de redes por proyecto |
| CNR1 | Asignacion de materiales a actividades |
| CN25 | Confirmacion colectiva de actividades |
| CN27 | Confirmacion individual de actividad |
| CN28 | Anular confirmacion |
| COR5 | Confirmacion de red (interfaz PP-like) |
| CO01 | Crear orden de produccion (aplicable si tipo red PP) |

---

## 14. Consultas SQL/MCP

```javascript
// Actividades de una red con su estado y WBS asignado
GetSqlQuery({
  query: `SELECT k.AUFNR, v.VORNR, v.LTXA1, v.STEUS,
                 v.DAUNO, v.DAUNE, v.NPLDA, v.NPLDS,
                 p.POSID AS WBS_ASIGNADO
          FROM AFKO k
          INNER JOIN AFVC v ON v.AUFPL = k.AUFPL
          LEFT JOIN PRPS p ON p.PSPNR = v.PSPEL
          WHERE k.PSPEL = (SELECT PSPNR FROM PRPS WHERE POSID = 'WBS-001')
          ORDER BY v.VORNR`
})

// Componentes de material por actividad
GetSqlQuery({
  query: `SELECT r.AUFNR, r.RSPOS, r.MATNR,
                 m.MAKTX, r.BDMNG, r.MEINS, r.BEDAT,
                 r.LGORT, r.BWART
          FROM RESB r
          INNER JOIN MAKT m ON m.MATNR = r.MATNR AND m.SPRAS = 'S'
          WHERE r.AUFNR = '000012345678'
            AND r.XLOEK = ' '
          ORDER BY r.RSPOS`
})

// Relaciones entre actividades
GetSqlQuery({
  query: `SELECT a.AUFPL, a.APLZL AS SUCESORA,
                 a.APLFL AS PREDECESORA,
                 a.ANORD AS TIPO_RELACION,
                 a.MINZO AS DESFASE, a.MINZE AS UNIDAD
          FROM AFAB a
          WHERE a.AUFPL = '0000123456'
          ORDER BY a.APLZL`
})
```

---

## 15. Mejores Practicas

1. **Redes por WBS de nivel hoja**: Asignar cada red al WBS mas detallado posible para granularidad de control de costes.

2. **Claves de control estandar**: Definir un conjunto limitado de claves de control (4-6) para toda la empresa. Evitar proliferacion de claves con diferencias minimas.

3. **Actividades externas y pedidos**: Configurar la generacion automatica de SolPed para actividades externas. Reduce la entrada manual y asegura trazabilidad desde la actividad hasta la factura.

4. **Hitos como entregables**: Usar hitos para marcar entregables clave. En proyectos PS-SD, los hitos son el mecanismo de control de facturacion por avance.

5. **Duracion vs. cantidad de trabajo**: Distinguir entre duracion de la actividad (calendario) y cantidad de trabajo (horas). Una actividad puede durar 10 dias con 80 horas de trabajo (8 horas/dia por 1 persona, o 4 dias con 2 personas).

6. **Redes estandar (plantillas)**: Crear plantillas de redes para tipos de proyecto recurrentes. Ahorra tiempo y garantiza coherencia en la planificacion.
