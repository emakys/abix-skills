# Estructura Organizativa PS — SAP Project System S/4HANA 2023

## 1. Introduccion al Modulo PS

SAP Project System (PS) es el modulo de SAP S/4HANA que permite planificar, ejecutar y controlar proyectos complejos. Integra gestion de tiempos, costes, recursos, presupuestos y facturacion en un unico entorno. Se conecta nativamente con CO (controlling), MM (compras), SD (ventas), PM (mantenimiento) y FI (finanzas).

### Conceptos Fundamentales

| Concepto | Descripcion |
|---|---|
| Proyecto | Objeto de agrupacion superior. Contiene WBS y/o Redes. Tabla PROJ |
| Definicion de Proyecto | Cabecera del proyecto. Datos maestros generales |
| Elemento WBS | Nodo de la estructura de desglose de trabajo |
| Red (Network) | Secuencia de actividades con relaciones logicas |
| Actividad | Tarea individual dentro de una red |
| Hito (Milestone) | Evento significativo en el ciclo de vida del proyecto |

---

## 2. Definicion de Proyecto (Project Definition)

La definicion de proyecto es el objeto raiz de cualquier proyecto PS. Se crea con la transaccion CJ01 o desde la transaccion proyecto CJ20N.

### Campos Clave de la Definicion de Proyecto

| Campo | Descripcion | Tabla/Campo |
|---|---|---|
| PSPNR | Numero interno del proyecto | PROJ-PSPNR |
| PSPID | ID externo del proyecto (visible al usuario) | PROJ-PSPID |
| VERNA | Nombre del proyecto | PROJ-VERNA |
| PROFL | Perfil del proyecto | PROJ-PROFL |
| VERNR | Responsable del proyecto | PROJ-VERNR |
| WERKS | Centro | PROJ-WERKS |
| BUKRS | Sociedad | PROJ-BUKRS |
| KOKRS | Area de controlling | PROJ-KOKRS |
| WAERS | Moneda del proyecto | PROJ-WAERS |
| PLFAZ | Fecha inicio plan | PROJ-PLFAZ |
| PLSEZ | Fecha fin plan | PROJ-PLSEZ |
| IZWEK | Objetivo de inversion | PROJ-IZWEK |
| PRART | Tipo de proyecto | PROJ-PRART |

### Tabla PROJ — Definicion de Proyecto

```sql
-- Consulta basica de proyectos activos
SELECT PSPNR, PSPID, VERNA, BUKRS, KOKRS, WERKS, PRART, PROFL
FROM PROJ
WHERE BUKRS = '1000'
  AND PLFAZ >= '20240101'
ORDER BY PSPID
```

---

## 3. Perfiles de Proyecto (Project Profile)

El perfil de proyecto (PROFL) es el control maestro de comportamiento del proyecto. Define que campos son obligatorios, opcionales u ocultos, y que funcionalidades estan activas.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Definiciones de Proyecto →
Definir Perfil de Proyecto
Transaccion: OPSA (Imagen inicial), OPS0 (Detalle perfil)
```

### Parametros del Perfil de Proyecto

| Parametro | Descripcion |
|---|---|
| Perfil red | Red por defecto al crear desde proyecto |
| Perfil WBS | Control de campos WBS |
| Tipo objeto CO | Orden o Elemento WBS como objeto CO |
| Planif. costes | Activar/desactivar planificacion de costes |
| Control presup. | Nivel de control (proyecto, WBS) |
| Perfil temporal | Parametros de programacion |
| Cat. estadisticas | Tipo de estadisticas activas |
| Facturacion | Indicadores de facturacion activos |

### Tabla de Referencia de Perfiles

| Tabla | Descripcion |
|---|---|
| TCPS1 | Perfiles de proyecto |
| TCPS2 | Perfiles de elemento WBS |
| TCPS3 | Perfiles de red |
| T430 | Tipos de red |

---

## 4. Tipos de Proyecto (Project Type)

El tipo de proyecto categoriza el proyecto para control de costes, reporting e integracion con otros modulos.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Definiciones de Proyecto →
Definir Tipos de Proyecto
Tabla de customizing: TCJTYPE
```

### Tipos de Proyecto Estandar

| Tipo | Descripcion tipica |
|---|---|
| 01 | Proyecto de inversion (conexion con IM) |
| 02 | Proyecto de cliente (conexion con SD) |
| 03 | Proyecto de overhead/indirecto |
| 04 | Proyecto de servicios |
| 05 | Proyecto de I+D |

Cada tipo de proyecto puede tener:
- Asignacion automatica de perfil de proyecto
- Rango de numeros propio
- Integracion con Programa de Inversion (IM)
- Control de disponibilidad especifico

---

## 5. Tipos de Red (Network Type)

Los tipos de red controlan el comportamiento de las redes y sus actividades dentro del proyecto.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Redes →
Definir Tipos de Red
Tabla: T430
```

### Campos del Tipo de Red (T430)

| Campo | Descripcion |
|---|---|
| Tipo de red | Clave del tipo (2 caracteres) |
| Perfil de red | Perfil asignado por defecto |
| Tipo orden | Categoria de la orden (PP01, PM02, etc.) |
| Clase valoracion | Para imputacion de costes |
| Control numero | Asignacion automatica/manual |

### Perfiles de Red

```
SPRO → Project System → Estructuras → Redes →
Definir Perfil de Red
Transaccion: OPUU
```

| Parametro Perfil | Descripcion |
|---|---|
| Estrategia programacion | Forward/Backward/hacia atras |
| Reduccion | Permitir reduccion de duracion |
| Control capacidad | Necesidades de capacidad activas |
| Control de costo | Clase de valoracion por defecto |
| Componentes | Control de lista de materiales |

---

## 6. Claves de Control (Control Keys / STEUS)

Las claves de control determinan las funciones disponibles para cada actividad de red. Son el parametro mas importante para controlar el comportamiento de las actividades.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Redes → Actividades →
Definir Claves de Control
Transaccion: OP67
Tabla: PLPO (campo STEUS)
```

### Claves de Control Estandar PS

| Clave | Descripcion | Uso tipico |
|---|---|---|
| PS01 | Actividad interna con confirmacion | Trabajo interno propio |
| PS02 | Actividad interna sin confirmacion | Costes automáticos |
| PS03 | Actividad externa (pedido compras) | Subcontratacion |
| PS04 | Actividad de coste (imputacion general) | Costes generales |
| PS10 | Actividad con hito | Actividades criticas con hito |

### Parametros de la Clave de Control

| Indicador | Descripcion |
|---|---|
| Confirmacion | Si la actividad requiere confirmacion manual |
| Impresion | Si genera lista de trabajo impresa |
| Pedido externo | Si genera automaticamente un pedido de compras |
| Calculo costes | Si el coste se calcula automaticamente |
| Capacidad | Si genera necesidades de capacidad |
| Tiempo real | Si participa en programacion critica |

---

## 7. Asignacion a Area CO y Sociedad

Todo proyecto PS debe asignarse a una estructura organizativa de Controlling y Finanzas.

### Estructura Organizativa PS

```
Sociedad (BUKRS)
    └── Area de Controlling (KOKRS)
            └── Centro (WERKS)
                    └── Proyecto (PSPID)
                            └── Elementos WBS
                            └── Redes / Actividades
```

### Asignacion en la Definicion de Proyecto

La asignacion se realiza en la cabecera del proyecto (CJ01/CJ20N):

| Campo | Descripcion | Obligatorio |
|---|---|---|
| BUKRS | Sociedad (Financial Company Code) | Si |
| KOKRS | Area de Controlling | Si (derivado) |
| WERKS | Centro de planificacion | Configurable |
| PRCTR | Centro de beneficio | Opcional |
| GSBER | Area de negocio | Opcional |
| FUNC_AREA | Area funcional | Opcional |

### Derivacion del Area CO

```
SPRO → Project System → Estructuras →
Asignar Area de Controlling a Sociedad
(Heredado de la configuracion general CO)
```

La sociedad determina el area de controlling. Todos los proyectos de una sociedad pertenecen al mismo area CO. Los costes del proyecto fluyen al Universal Journal (ACDOCA) con la clave CO correspondiente.

---

## 8. Rangos de Numeros

Los rangos de numeros controlan como se asignan los identificadores a proyectos, WBS y redes.

### Configuracion SPRO — Proyecto

```
SPRO → Project System → Estructuras → Definiciones de Proyecto →
Definir Rangos de Numeros para Proyectos
Transaccion: CJ79
```

### Configuracion SPRO — WBS

```
SPRO → Project System → Estructuras → Elementos WBS →
Definir Rangos de Numeros para Elementos WBS
Transaccion: CJ80
```

### Configuracion SPRO — Red

```
SPRO → Project System → Estructuras → Redes →
Definir Rangos de Numeros para Redes
(Heredado del tipo de orden PP/PM asociado)
```

### Tipos de Asignacion de Numeros

| Tipo | Descripcion |
|---|---|
| Interna | SAP asigna el numero automaticamente |
| Externa | El usuario introduce el ID manualmente |
| Mascara de proyecto | Numero del WBS se forma a partir del ID del proyecto |

### Mascara de Numeracion WBS

La mascara define como se forma el numero del WBS a partir del numero del proyecto. Ejemplo:

```
Proyecto:   PROJ-2024-001
WBS nivel 1: PROJ-2024-001.1
WBS nivel 2: PROJ-2024-001.1.1
```

```
SPRO → Project System → Estructuras → Elementos WBS →
Definir Mascara de Codificacion para Elementos WBS
Transaccion: OKEV
```

---

## 9. Tablas Clave del Sistema

### Tabla PROJ — Definicion de Proyecto

| Campo | Tipo | Descripcion |
|---|---|---|
| PSPNR | NUMC(8) | Numero interno del proyecto |
| PSPID | CHAR(24) | ID externo del proyecto |
| VERNA | CHAR(40) | Nombre del proyecto |
| PRART | CHAR(2) | Tipo de proyecto |
| PROFL | CHAR(6) | Perfil del proyecto |
| VERNR | CHAR(12) | Responsable |
| WERKS | CHAR(4) | Centro |
| BUKRS | CHAR(4) | Sociedad |
| KOKRS | CHAR(4) | Area de controlling |
| WAERS | CUKY(5) | Moneda |
| IZWEK | CHAR(2) | Objetivo de inversion |
| PLFAZ | DATS(8) | Fecha inicio plan |
| PLSEZ | DATS(8) | Fecha fin plan |
| ASTNA | CHAR(12) | Usuario creacion |
| ASTZT | DATS(8) | Fecha creacion |

### Tabla TCPS1 — Perfiles de Proyecto

| Campo | Descripcion |
|---|---|
| PROFL | Clave del perfil |
| PRFTX | Descripcion |
| NETZ | Tipo de red por defecto |
| KOVAR | Variante de cuenta |
| BEWAR | Indicador de inversion |
| IMKEY | Clave de presupuesto |

### Tabla TCPS2 — Perfiles de Elemento WBS

| Campo | Descripcion |
|---|---|
| PSPROFIL | Clave del perfil WBS |
| PRFTX | Descripcion |
| TARIFKZ | Control de tarifa |
| ABRKZ | Indicador de facturacion |

### Tabla TCPS3 — Perfiles de Red

| Campo | Descripcion |
|---|---|
| PROFIL | Clave del perfil de red |
| PROFTXT | Descripcion |
| PLART | Tipo de planificacion |
| KAPID | Control de capacidad |

### Tabla T430 — Tipos de Red

| Campo | Descripcion |
|---|---|
| AUART | Tipo de red/orden |
| ABART | Categoria de orden |
| KTEXT | Descripcion |
| AUFNR | Rango de numeros |

---

## 10. Transacciones Principales de Configuracion

| Transaccion | Descripcion |
|---|---|
| CJ01 | Crear definicion de proyecto |
| CJ02 | Modificar definicion de proyecto |
| CJ03 | Visualizar definicion de proyecto |
| CJ20N | Project Builder (gestion completa) |
| CJ06 | Crear proyecto desde template |
| OPSA | Parametros iniciales proyecto |
| OPS0 | Definir perfil de proyecto |
| OPUU | Definir perfil de red |
| OP67 | Definir claves de control (actividades) |
| CJ79 | Rangos de numeros proyecto |
| CJ80 | Rangos de numeros WBS |
| OKEV | Mascara de codificacion WBS |

---

## 11. Fiori Apps Relevantes (PS Org Structure)

| App ID | Descripcion |
|---|---|
| F1964 | Manage Projects (S/4HANA) |
| F2389 | Project Cockpit |
| F3422 | Configure Project Templates |
| F2390 | Monitor Project Budgets |

---

## 12. Consultas MCP GetSqlQuery

```javascript
// Listar todos los proyectos de una sociedad con su perfil y tipo
GetSqlQuery({
  query: `SELECT p.PSPNR, p.PSPID, p.VERNA, p.PRART, p.PROFL,
                 p.BUKRS, p.KOKRS, p.WERKS, p.PLFAZ, p.PLSEZ,
                 t.KTEXT AS TIPO_DESC
          FROM PROJ p
          LEFT JOIN TCJTYPE t ON t.PRART = p.PRART AND t.SPRAS = 'S'
          WHERE p.BUKRS = '1000'
          ORDER BY p.PSPID`
})

// Consultar perfiles de proyecto disponibles
GetSqlQuery({
  query: `SELECT PROFL, PRFTX, NETZ, KOVAR
          FROM TCPS1
          WHERE SPRAS = 'S'
          ORDER BY PROFL`
})

// Verificar asignacion CO-Sociedad
GetSqlQuery({
  query: `SELECT BUKRS, KOKRS
          FROM T001
          WHERE BUKRS = '1000'`
})
```

---

## 13. Integracion con Otros Modulos

| Modulo | Punto de Integracion |
|---|---|
| CO | Proyectos son objetos CO. Costes en ACDOCA con PSPNR |
| FI | Imputaciones directas via FB50/MIRO con elemento WBS |
| MM | Pedidos con imputacion a WBS o red |
| SD | Pedidos de venta con referencia a WBS (proyecto de cliente) |
| PM | Ordenes de mantenimiento vinculadas a proyecto |
| IM | Programas de inversion vinculados a proyectos de inversion |
| HR | Confirmaciones de horas via CATS (Cross-Application Time Sheet) |

---

## 14. Mejores Practicas S/4HANA 2023

1. **Universal Journal**: Todos los valores CO de proyectos fluyen directamente a ACDOCA. No hay tablas CO separadas (COSP/COSS son vistas de compatibilidad).

2. **Fiori First**: Usar Project Cockpit (F2389) para gestion diaria. Transacciones clasicas siguen disponibles pero Fiori es el futuro.

3. **Commercial Project Management (CPM)**: Nueva funcionalidad S/4HANA para proyectos orientados a cliente. Integra PS con SD y reconocimiento de ingresos IFRS 15.

4. **Jerarquia de Controlling**: Definir correctamente la jerarquia de derivacion: Sociedad → Area CO → Centro de Coste → Centro de Beneficio antes de crear proyectos.

5. **Plantillas de Proyecto**: Usar plantillas (CJ91/CJ92) para estandarizar la estructura de proyectos recurrentes y reducir errores de configuracion.
