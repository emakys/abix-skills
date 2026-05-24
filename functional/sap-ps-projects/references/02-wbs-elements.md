# Elementos WBS (Work Breakdown Structure) — SAP PS S/4HANA 2023

## 1. Concepto de WBS en SAP PS

El Work Breakdown Structure (WBS) es la estructura jerarquica de desglose del trabajo del proyecto. Cada nodo de la jerarquia es un Elemento WBS (WBS Element), que sirve como objeto CO para imputacion de costes, planificacion de presupuesto y control de disponibilidad.

### Caracteristicas Principales

- Estructura arborescente con hasta 24 niveles de jerarquia
- Cada elemento WBS es un objeto CO independiente
- Permite imputacion directa de costes, ingresos y presupuesto
- Soporta indicadores para distinguir funcion (operativo, estadistico, facturacion, cuenta)
- Base para la planificacion de costes jerarquica y el control de presupuesto

---

## 2. Jerarquia WBS — Tabla PRHI

La tabla PRHI almacena la estructura jerarquica (relaciones padre-hijo) de los elementos WBS.

### Tabla PRHI — Jerarquia de Proyecto

| Campo | Tipo | Descripcion |
|---|---|---|
| PSPHI | NUMC(8) | Numero interno WBS superior |
| POSNR | NUMC(8) | Numero interno WBS hijo |
| STUFE | NUMC(2) | Nivel en la jerarquia |
| PRPOS | CHAR(8) | ID externo del WBS |
| PSPNR | NUMC(8) | Numero interno del proyecto |

```sql
-- Obtener estructura completa de un proyecto
SELECT h.PSPHI, h.POSNR, h.STUFE, w.POSID, w.POST1
FROM PRHI h
INNER JOIN PRPS w ON w.PSPNR = h.POSNR
WHERE h.PSPNR = (SELECT PSPNR FROM PROJ WHERE PSPID = 'MI-PROYECTO-001')
ORDER BY h.STUFE, h.POSNR
```

---

## 3. Tabla PRPS — Datos Maestros WBS

La tabla PRPS contiene todos los datos maestros de los elementos WBS.

### Campos Clave de PRPS

| Campo | Tipo | Descripcion |
|---|---|---|
| PSPNR | NUMC(8) | Numero interno del elemento WBS |
| POSID | CHAR(24) | ID externo del WBS (visible al usuario) |
| POST1 | CHAR(40) | Descripcion breve |
| PSPHI | NUMC(8) | WBS superior (padre) |
| PBUKR | CHAR(4) | Sociedad |
| PKOKR | CHAR(4) | Area de controlling |
| PWERK | CHAR(4) | Centro |
| PRFLA | CHAR(1) | Indicador operativo (X = operativo) |
| FAKKZ | CHAR(1) | Indicador de facturacion |
| KONTO | CHAR(1) | Indicador de cuenta |
| BELKZ | CHAR(1) | Indicador de imputacion |
| PSPROFIL | CHAR(6) | Perfil del elemento WBS |
| VERNR | CHAR(12) | Responsable |
| PRART | CHAR(2) | Tipo de proyecto |
| IZWEK | CHAR(2) | Objetivo de inversion |
| OBJNR | CHAR(22) | Numero de objeto (para estado) |
| USTAZ | CHAR(5) | Estado de usuario |
| SYSST | CHAR(5) | Estado de sistema |
| PLFAZ | DATS(8) | Fecha inicio plan |
| PLSEZ | DATS(8) | Fecha fin plan |
| TPLNR | CHAR(18) | Puesto funcional (PM) |
| PRCTR | CHAR(10) | Centro de beneficio |
| GSBER | CHAR(4) | Area de negocio |
| FUNC_AREA | CHAR(16) | Area funcional |

---

## 4. Indicadores Clave del Elemento WBS

Los indicadores del WBS controlan su comportamiento funcional y la forma en que se imputan costes y se controla el presupuesto.

### 4.1 Indicador Operativo (PRFLA)

| Valor | Descripcion |
|---|---|
| X (activo) | WBS operativo: permite imputacion directa de costes |
| Vacio | WBS resumen: solo agrupa costes de hijos |

Un elemento WBS marcado como operativo puede recibir imputaciones directas de pedidos de compras, confirmaciones, facturas y asientos contables.

### 4.2 Indicador de Facturacion (FAKKZ)

| Valor | Descripcion |
|---|---|
| X (activo) | Permite usar el WBS como posicion de facturacion en plan de facturacion |
| Vacio | No participa en facturacion PS-SD |

Solo los WBS con FAKKZ activo aparecen disponibles en el plan de facturacion (Billing Plan) cuando el proyecto esta vinculado a un pedido de venta SD.

### 4.3 Indicador de Cuenta (KONTO)

| Valor | Descripcion |
|---|---|
| X (activo) | El WBS es el receptor principal de costes (cuenta) |
| Vacio | Los costes se agregan del nivel inferior |

### 4.4 Indicador de Imputacion / Elemento de Imputacion (BELKZ)

Determina si el elemento WBS puede recibir imputaciones directas desde otras aplicaciones (FI, MM, HR).

### 4.5 Indicador Estadistico

Un WBS puede ser estadistico cuando no acumula costes reales en CO pero si registra estadisticas para analisis. Util para WBS de agrupacion sin necesidad de control presupuestario independiente.

---

## 5. Creacion de Elementos WBS

### Transacciones Clasicas

| Transaccion | Descripcion |
|---|---|
| CJ01 | Crear proyecto (incluye primer WBS) |
| CJ11 | Crear elemento WBS individual |
| CJ12 | Modificar elemento WBS |
| CJ13 | Visualizar elemento WBS |
| CJ20N | Project Builder — gestion completa jerarquica |

### Creacion via CJ20N (Project Builder)

El Project Builder es la herramienta principal para gestionar proyectos en modo clasico. Permite:

1. Crear/modificar la jerarquia WBS de forma visual
2. Asignar redes y actividades
3. Gestionar componentes y recursos
4. Visualizar costes y presupuesto de forma integrada

**Pasos para crear un proyecto en CJ20N:**

```
1. CJ20N → Proyecto → Crear
2. Ingresar ID del proyecto (PSPID)
3. Seleccionar plantilla (opcional) o empezar desde cero
4. Definir datos cabecera: sociedad, area CO, responsable, fechas
5. Expandir estructura WBS en el arbol izquierdo
6. Para cada WBS: doble clic → datos detalle → indicadores
7. Guardar (Ctrl+S)
```

### Asignacion Organizativa en WBS

Cada elemento WBS hereda la asignacion organizativa del proyecto pero puede tener valores propios:

```
Proyecto
├── BUKRS (Sociedad)           → heredada por todos los WBS
├── KOKRS (Area CO)            → heredada
├── WERKS (Centro)             → puede diferir por WBS
└── PRCTR (Centro Beneficio)  → puede diferir por WBS
```

---

## 6. Mascara de Codificacion WBS (WBS Masking)

La mascara de codificacion define el patron de numeracion de los elementos WBS y su estructura jerarquica.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Elementos WBS →
Definir Mascara de Codificacion
Transaccion: OKEV
```

### Ejemplo de Mascara

```
Mascara definida:  AAAA-0000-00.0.00
Proyecto creado:   CONS-2024-01
WBS nivel 1:       CONS-2024-01.1
WBS nivel 2:       CONS-2024-01.1.01
WBS nivel 3:       CONS-2024-01.1.01.001
```

El separador (punto, guion, etc.) y la longitud de cada nivel son configurables. La mascara asegura consistencia en toda la empresa.

---

## 7. Plantillas Estandar de WBS (Standard WBS)

Las plantillas de WBS permiten reutilizar estructuras estandar de proyecto para agilizar la creacion.

### Transacciones de Plantillas

| Transaccion | Descripcion |
|---|---|
| CJ91 | Crear WBS estandar (plantilla) |
| CJ92 | Modificar WBS estandar |
| CJ93 | Visualizar WBS estandar |
| CJ2D | Crear proyecto desde plantilla WBS |

### Proceso de Creacion de Plantilla

```
CJ91 → Crear WBS estandar
1. Asignar ID y descripcion de la plantilla
2. Definir estructura jerarquica (sin fechas especificas)
3. Configurar indicadores por nivel (operativo, facturacion, cuenta)
4. Asignar perfiles y clases de costes tipicas
5. Guardar como plantilla reutilizable
```

### Uso de Plantilla al Crear Proyecto

```
CJ20N → Proyecto → Crear con plantilla
O bien: CJ06 → Crear proyecto desde plantilla WBS estandar
1. Seleccionar plantilla WBS
2. Ajustar fechas de inicio/fin
3. Modificar IDs de WBS segun convencion de numeracion
4. Adaptar responsables y asignacion organizativa
```

---

## 8. Perfil de Elemento WBS (WBS Profile)

El perfil controla la visualizacion y comportamiento de los campos en el elemento WBS.

### Configuracion SPRO

```
SPRO → Project System → Estructuras → Elementos WBS →
Definir Perfil de Elemento WBS
Tabla: TCPS2
```

### Parametros del Perfil WBS

| Parametro | Descripcion |
|---|---|
| Control de tarifa | Si el WBS usa tarifas de liquidacion propias |
| Indicador de facturacion | Si permite activar FAKKZ |
| Control presupuesto | Nivel de control (propio, heredado) |
| Campo estadistico | Activar indicador estadistico |
| Asignacion de red | Si permite vincular redes |
| Control CO | Tipo de objeto CO (WBS o Orden interna) |

---

## 9. Estado del Elemento WBS

El estado controla el ciclo de vida del WBS y las transacciones permitidas.

### Estados de Sistema Principales (SYSST)

| Estado | Descripcion | Transacciones permitidas |
|---|---|---|
| CREA | Creado | Solo datos maestros |
| REL | Liberado | Imputaciones, confirmaciones |
| TECO | Cierre tecnico | Solo liquidacion |
| CLSD | Cerrado | Solo visualizacion |
| LKD | Bloqueado | Ninguna imputacion |

### Tabla JEST — Estado de Objeto

```sql
-- Verificar estado actual de elementos WBS
SELECT j.OBJNR, j.STAT, j.INACT, t.TXT04
FROM JEST j
INNER JOIN TJ02T t ON t.ISTAT = j.STAT AND t.SPRAS = 'S'
INNER JOIN PRPS w ON w.OBJNR = j.OBJNR
WHERE w.PSPNR IN (SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUMERO_PROYECTO')
  AND j.INACT = ' '
ORDER BY w.POSID, j.STAT
```

### Estados de Usuario (USTAZ)

Los estados de usuario son estados adicionales definibles por el cliente para controlar procesos especificos del proyecto (ej. "APROBADO", "EN REVISION", "AUDITADO").

```
SPRO → Project System → Estructuras → Estado →
Definir Esquema de Status de Usuario
Transaccion: BS02
```

---

## 10. Asignacion Organizativa Detallada

### Centro de Beneficio en WBS

```
PRPS-PRCTR → Centro de Beneficio
```

Si no se asigna explicitamente, se puede configurar derivacion automatica desde la jerarquia del proyecto o desde la cuenta de mayor de imputacion.

### Area Funcional (Derivacion Presupuestaria)

El campo FUNC_AREA en PRPS permite clasificar el WBS dentro de la estructura presupuestaria publica (relevante para sector publico).

### Asignacion Proyecto → Centro de Coste

Aunque los WBS no son centros de coste, pueden tener una asignacion a centro de coste para:
- Derivacion de tarifas de actividad
- Confirmaciones de horas (CATS)
- Asignacion de costes indirectos

---

## 11. Consultas SQL/MCP Utiles

```javascript
// Estructura WBS completa con indicadores
GetSqlQuery({
  query: `SELECT w.POSID, w.POST1, w.STUFE,
                 w.PRFLA AS OPERATIVO,
                 w.FAKKZ AS FACTURACION,
                 w.KONTO AS CUENTA,
                 w.BELKZ AS IMPUTACION,
                 w.PRCTR, w.VERNR,
                 w.PLFAZ, w.PLSEZ
          FROM PRPS w
          INNER JOIN PRHI h ON h.POSNR = w.PSPNR
          WHERE h.PSPNR = (SELECT PSPNR FROM PROJ WHERE PSPID = 'MI-PROY-001')
          ORDER BY w.POSID`
})

// WBS con estado actual
GetSqlQuery({
  query: `SELECT w.POSID, w.POST1,
                 j.STAT, t.TXT04 AS ESTADO_DESC
          FROM PRPS w
          INNER JOIN JEST j ON j.OBJNR = w.OBJNR AND j.INACT = ' '
          INNER JOIN TJ02T t ON t.ISTAT = j.STAT AND t.SPRAS = 'S'
          WHERE w.PBUKR = '1000'
            AND j.STAT IN ('I0001','I0002','I0045','I0046')
          ORDER BY w.POSID`
})

// Costes reales por elemento WBS (ACDOCA - S/4HANA)
GetSqlQuery({
  query: `SELECT a.PSPNR, p.POSID, a.KSTAR, a.GJAHR, a.POPER,
                 SUM(a.HSL) AS COSTE_REAL
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.GJAHR = '2024'
            AND a.PSPNR IS NOT NULL
          GROUP BY a.PSPNR, p.POSID, a.KSTAR, a.GJAHR, a.POPER
          ORDER BY p.POSID, a.KSTAR`
})
```

---

## 12. Mejores Practicas WBS en S/4HANA 2023

### Estructura Recomendada

```
Nivel 1: Proyecto (WBS resumen, no operativo)
Nivel 2: Fase o Entregable principal (WBS resumen)
Nivel 3: Paquete de trabajo (WBS operativo)
Nivel 4: Tarea especifica (WBS operativo, imputacion directa)
```

### Reglas de Diseno

1. **No mas de 4-5 niveles**: Estructuras muy profundas complican el reporting y la navegacion
2. **Separar WBS de agrupacion de WBS operativos**: Facilita el control presupuestario por nivel
3. **Indicador operativo solo en hojas**: Los WBS hoja son los que reciben imputaciones directas
4. **Facturacion en nivel de entregable**: Alinear hitos de facturacion con entregables del proyecto
5. **Responsable por WBS**: Asignar VERNR en cada WBS para trazabilidad y reporting

### Integracion con S/4HANA Universal Journal

En S/4HANA, los costes de proyectos se almacenan en ACDOCA con los campos:
- `PSPNR`: Numero interno del WBS
- `PS_PSP_PNR`: Numero del WBS en formato externo
- `RLDNR`: Ledger ('0L' para ledger principal)

Ya no es necesario consultar COSP/COSS para costes reales; ACDOCA es la fuente unica de verdad.
