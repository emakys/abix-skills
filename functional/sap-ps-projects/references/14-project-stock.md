# Stock de Proyecto y Material en SAP PS

## Introduccion

El **Stock de Proyecto** (Project Stock) en SAP PS permite gestionar inventario de materiales especificamente asignado a un proyecto, separandolo del stock general del almacen. Esta funcionalidad es esencial para proyectos con materiales costosos, de larga entrega o que no pueden mezclarse con el inventario general.

SAP S/4HANA 2023 mantiene el stock de proyecto en la tabla `MATDOC` (nueva tabla de documentos de material que reemplaza `MSEG`/`MKPF`), con plena integración con el Universal Journal (`ACDOCA`).

---

## 1. Tipos de Stock de Proyecto

### 1.1 Stock Individual de Proyecto (Individual Project Stock)

- El material se asigna a **un WBS especifico**.
- Aparece en el balance de inventario con el numero WBS.
- Solo puede utilizarse en ese proyecto especifico.
- Se identifica con el indicador de stock especial **Q** (project stock).
- Movimiento de entrada: tipo 101 con imputacion WBS.

**Cuenta contable:** La valoracion se hace en una cuenta de inventario especifica de proyecto (configurable).

**Cuando usar:**
- Materiales muy costosos (cables de fibra optica, equipos industriales)
- Materiales con numero de serie vinculado al proyecto
- Proyectos con auditorias estrictas de materiales
- Materiales con restricciones de uso exclusivo

### 1.2 Stock Colectivo de Proyecto (Collective Project Stock / Sales Order Stock)

- El material se asigna a un **pedido de cliente SD** o a un segmento de planificacion.
- Menos comun en PS puro; mas frecuente en MTO (Make-to-Order) combinado con PS.
- Indicador de stock especial **E** (sales order stock).

### 1.3 Stock No Restringido con Imputacion WBS (sin stock especial)

- El material se consume directamente desde stock no restringido.
- El coste se imputa al WBS mediante el movimiento de mercancia (reserva → MIGO 261).
- No hay separacion fisica del stock.
- Mas simple de gestionar pero sin visibilidad por proyecto.

---

## 2. Valoracion del Stock de Proyecto

### 2.1 Precio Estandar vs. Precio Medio

El stock de proyecto puede valorarse con:

| Metodo | Descripcion | Uso Tipico |
|--------|-------------|------------|
| Precio estandar (S) | Precio fijo definido en maestro material | Fabricacion propia, productos acabados |
| Precio medio ponderado (V) | Se recalcula con cada entrada | Materias primas, materiales comprados |
| Precio especifico proyecto | Precio unico para este stock de proyecto | Proyectos con materiales costosos y especificos |

### 2.2 Cuenta de Stock Especifica de Proyecto

Se puede configurar que el stock de proyecto use una **cuenta contable diferente** a la del stock normal:

**Ruta SPRO:**
```
Project System > Material > Stock Management > Assign G/L Accounts for Project Stock
```

Tabla: `T030` (determinacion de cuentas - transaccion OBYC)
Transaccion: `OBYC` → Clave de operacion `BSX` para inventario, con modificador de cuenta = clave de valoracion del proyecto.

---

## 3. Flujo de Material en Proyectos

### 3.1 Proceso Completo P2P con WBS

```
PLANIFICACION
   |
   v
[1] Componentes de red (CN22) / Reservas manuales (MB21)
    Asignacion de material a actividad de red o WBS
   |
   v
APROVISIONAMIENTO
   |
   v
[2] MRP genera solicitudes de pedido (MD01/MD02)
    Con imputacion WBS (tipo imputacion P) o red (tipo N)
   |
   v
[3] Convertir solicitud a pedido (ME57 / ME21N)
    Posicion de pedido con cuenta WBS
   |
   v
RECEPCION
   |
   v
[4] Entrada de mercancia (MIGO - mov. 101)
    → Si hay WBS: va a stock de proyecto (tipo Q)
    → Si hay componente de red: reserva se cubre
   |
   v
CONSUMO
   |
   v
[5] Salida de mercancia (MIGO - mov. 221 para stock proyecto)
    O confirmacion de actividad que consume componente (CN25)
   |
   v
[6] Coste real en WBS / actividad
```

### 3.2 Tipos de Movimiento Clave

| Mov. | Descripcion | Stock | Imputacion |
|------|-------------|-------|------------|
| 101 | Entrada de mercancias de pedido | + Stock proyecto (Q) | WBS en pedido |
| 161 | Devolucion a proveedor desde stock proyecto | - Stock proyecto | WBS |
| 201 | Salida para centro de coste | - Stock normal | CC |
| 221 | Salida para proyecto (WBS) desde stock proyecto | - Stock proyecto | WBS |
| 261 | Salida para orden/red | - Stock normal | Red/WBS |
| 281 | Salida para WBS desde stock normal | - Stock normal | WBS |
| 301 | Traslado entre almacenes | Movimiento interno | - |
| 411 Q | Transferencia stock libre a stock proyecto | Stock libre → Stock Q | WBS |
| 412 Q | Transferencia stock proyecto a stock libre | Stock Q → Stock libre | - |
| 531 | Entrada de subproducto | + Stock | - |

**Movimientos especiales para stock de proyecto:**
- **Mov. 411 Q:** Transfiere material ya en stock normal al stock de proyecto especifico.
- **Mov. 412 Q:** Devuelve material del stock de proyecto al stock normal.

---

## 4. Reservas de Material

### 4.1 Crear Reserva Manual

**Transaccion:** `MB21`

**Campos principales:**

| Campo | Descripcion |
|-------|-------------|
| Fecha | Fecha de necesidad |
| Tipo movimiento | 201 (CC), 221 (proyecto), 261 (orden) |
| Centro | Centro de planificacion |
| Material | Codigo de material |
| Cantidad | Cantidad reservada |
| UM | Unidad de medida |
| WBS / Actividad red | Objeto receptor de coste |
| Almacen | Almacen de donde saldr el material |

**Transaccion MB22:** Modificar reserva existente.
**Transaccion MB23:** Visualizar reserva.
**Transaccion MB25:** Listar reservas por WBS/red.

### 4.2 Reservas Automaticas via Componentes de Red

Cuando se asignan componentes a actividades de red en `CN22`, el sistema puede crear **reservas automaticas** al liberar la red:

**Configuracion en perfil de red (SPRO):**
```
Project System > Structures > Operative Structures > Network
> Settings for Networks > Define Network Profile
→ Campo "Indicador de reserva": crear reserva al REL
```

Los componentes de red con disponibilidad manual generan reservas que pueden verse en `MB25`.

---

## 5. Componentes de Red

### 5.1 Asignar Componentes a Actividades (CN22)

**Transaccion CN22:** Componentes de material de red.

**Tipos de componentes:**

| Tipo | Descripcion |
|------|-------------|
| L | Stock de almacen (se reserva) |
| N | Material no en stock (genera solicitud) |
| R | Material de recursos (CC) |

**Campos por componente:**

| Campo | Descripcion |
|-------|-------------|
| Material | Codigo SAP |
| Cantidad | Cantidad planificada |
| Unidad | UM base del material |
| Fecha necesidad | Cuando se necesita |
| Centro | Centro de planificacion |
| Tipo de posicion | L, N, R |
| Indicador MRP | Si MRP debe planificar el material |
| WBS | Para imputacion de coste |

### 5.2 Disponibilidad de Componentes

**Transaccion CN49:** Verificar disponibilidad de materiales en red.

Muestra:
- Fecha de necesidad del componente
- Stock disponible en esa fecha
- Deficit / excedente
- Propuesta de accion (crear pedido, etc.)

---

## 6. MRP para Proyecto (Project-Oriented MRP)

### 6.1 Conceptos

El MRP de proyecto (llamado tambien **MRP orientado a proyecto**) planifica los materiales necesarios para las redes y actividades, respetando las fechas de la programacion de red.

**Diferencias con MRP estandar:**
- Las necesidades se generan por los componentes de red (no por orden de fabricacion)
- Los grupos de planificacion son por proyecto (no por punto de pedido)
- Las fechas de las necesidades vienen de la programacion de red (backward scheduling)

### 6.2 Ejecucion

**Transaccion MD01:** MRP global (incluye proyectos)
**Transaccion MD02:** MRP para un material especifico
**Transaccion MD41:** MRP por proyecto (orientado a proyecto)

**Parametros clave para MRP de proyecto:**

| Parametro | Descripcion |
|-----------|-------------|
| Proyecto | Filtrar por proyecto especifico |
| Tipo de planificacion | Net Change / Regenerativo |
| Horizonte MRP | Dias hacia el futuro |
| Crear solicitudes | Si/No/Solo verificar |
| Nivel de mensaje | Detalle de log |

### 6.3 Estrategia de Planificacion con WBS (Estrategia 52)

La **estrategia 52** (Planning with Final Assembly) permite planificar stock anonimo a nivel semi-acabado y convertirlo en stock de proyecto al recibir pedido de cliente.

Otras estrategias relevantes:
- **Estrategia 50:** Planning without Final Assembly (MTS con stock especial)
- **Estrategia 20:** Make-to-Order (cada pedido genera produccion especifica)

---

## 7. MIGO con WBS

### 7.1 Entrada de Mercancias con Imputacion WBS

**Transaccion MIGO → Mov. 101:**

1. Accion: "Entrada de mercancias"
2. Referencia: "Pedido de compras" (con WBS asignado)
3. El sistema hereda la imputacion WBS del pedido
4. El material queda en stock de proyecto del WBS

**Verificacion post-MIGO:**
- Stock de proyecto visible en `MMBE` (seleccionando "Stock especial Q")
- Coste real en WBS visible en `CJI3`

### 7.2 Salida de Stock de Proyecto (Mov. 221)

**MIGO → Mov. 221:**

1. Accion: "Salida de mercancias"
2. Tipo movimiento: 221
3. Seleccionar material y cantidad
4. Imputacion: WBS (mismo u otro WBS del proyecto)
5. Almacen y tipo stock especial: Q + numero WBS

**Efecto contable:**
- Credito a cuenta de inventario proyecto
- Debito a cuenta de gastos del WBS

### 7.3 Devolucion de Stock de Proyecto

**MIGO → Mov. 221 con devolucion:**
O usar movimiento 222 (devolucion de salida de stock proyecto).

---

## 8. Tablas de Base de Datos

### 8.1 RESB - Reservas de Material

**Descripcion:** Almacena todas las reservas de material (manuales y automaticas de componentes de red).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| RSNUM | NUMC10 | Numero de reserva |
| RSPOS | NUMC4 | Posicion de reserva |
| RSART | CHAR1 | Tipo de reserva (M=manual, N=red) |
| AUFNR | CHAR12 | Numero de orden / red |
| VORNR | CHAR4 | Numero de actividad |
| PS_PSP_PNR | NUMC8 | Numero interno WBS |
| MATNR | CHAR40 | Material |
| WERKS | CHAR4 | Centro |
| LGORT | CHAR4 | Almacen |
| BDMNG | QUAN | Cantidad necesaria |
| ENMNG | QUAN | Cantidad ya retirada |
| BWART | CHAR3 | Tipo de movimiento |
| BDDAT | DATS | Fecha de necesidad |
| SOBKZ | CHAR1 | Tipo stock especial (Q=proyecto) |
| PROJK | NUMC8 | Numero WBS para stock especial |
| XLOEK | CHAR1 | Indicador borrado |
| XCHAR | CHAR1 | Material en lotes |

**Query MCP - Reservas abiertas de un proyecto:**
```sql
SELECT r.rsnum, r.rspos, r.matnr, m.maktx,
       r.bdmng - r.enmng AS cantidad_pendiente,
       r.bdmng AS cantidad_total,
       r.enmng AS cantidad_retirada,
       r.bddat AS fecha_necesidad,
       p.posid AS wbs
FROM resb r
INNER JOIN prps p ON p.pspnr = r.ps_psp_pnr
INNER JOIN makt m ON m.matnr = r.matnr AND m.spras = 'S'
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND r.xloek <> 'X'
  AND r.bdmng > r.enmng
ORDER BY r.bddat, r.matnr
```

### 8.2 MATDOC - Documentos de Material (S/4HANA)

**Descripcion:** En S/4HANA reemplaza a MSEG + MKPF. Almacena todas las entradas/salidas de material.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| MBLNR | CHAR10 | Numero documento de material |
| MJAHR | NUMC4 | Ejercicio del documento |
| ZEILE | NUMC4 | Posicion del documento |
| BWART | CHAR3 | Tipo de movimiento |
| MATNR | CHAR40 | Material |
| WERKS | CHAR4 | Centro |
| LGORT | CHAR4 | Almacen |
| MENGE | QUAN | Cantidad |
| MEINS | UNIT3 | Unidad de medida |
| DMBTR | CURR | Importe en moneda local |
| WAERS | CUKY | Moneda |
| PS_PSP_PNR | NUMC8 | Numero WBS (imputacion) |
| SOBKZ | CHAR1 | Tipo stock especial |
| PROJK | NUMC8 | WBS del stock especial |
| BUDAT | DATS | Fecha de contabilizacion |
| BLDAT | DATS | Fecha del documento |
| XAUTO | CHAR1 | Contabilizacion automatica |

**Query MCP - Movimientos de material para un proyecto (S/4HANA):**
```sql
SELECT m.mblnr, m.mjahr, m.zeile, m.bwart,
       m.matnr, mk.maktx, m.menge, m.meins,
       m.dmbtr, m.budat,
       p.posid AS wbs_imputacion
FROM matdoc m
INNER JOIN prps p ON p.pspnr = m.ps_psp_pnr
LEFT JOIN makt mk ON mk.matnr = m.matnr AND mk.spras = 'S'
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND m.budat BETWEEN '20240101' AND '20241231'
ORDER BY m.budat, m.mblnr
```

### 8.3 MSEG / MKPF (sistema clasico, pre-S/4HANA)

| Tabla | Descripcion |
|-------|-------------|
| MKPF | Cabecera de documento de material |
| MSEG | Posiciones de documento de material |

En S/4HANA estas tablas existen como vistas de compatibilidad sobre MATDOC.

**Campos clave MSEG para PS:**
- `PS_PSP_PNR`: Numero interno WBS de imputacion
- `SOBKZ`: Tipo de stock especial (Q=stock proyecto, E=pedido cliente)
- `PROJK`: Numero WBS del stock especial

### 8.4 MBGR - Agrupacion de Tipos de Movimiento

| Tabla | Descripcion |
|-------|-------------|
| T156 | Tipos de movimiento (config) |
| T156X | Tipos de movimiento especiales |
| T157E | Texto de tipos de movimiento |

---

## 9. Verificacion de Stock de Proyecto

### 9.1 MMBE - Vista de Stock por Almacen y Tipo

En `MMBE` seleccionar:
- Material especifico
- Centro
- Expandir "Stock especial" → "Stock de proyecto (Q)"

Muestra el stock por numero WBS con disponibilidad en diferentes fechas.

### 9.2 MB54 - Stock de Proyecto por Proyecto

**Funcion:** Listar todo el stock de proyecto de un WBS o proyecto especifico.

Muestra:
- Material
- Almacen
- Cantidad disponible en stock especial Q
- Valor total

### 9.3 MB25 - Lista de Reservas

**Funcion:** Ver todas las reservas de un WBS/actividad de red.

---

## 10. Determinacion Automatica de Necesidades (MRP PS)

### 10.1 Indicadores en Componente de Red

Cada componente de red tiene un **indicador de MRP** que controla si el sistema genera necesidades automaticamente:

| Indicador | Comportamiento |
|-----------|---------------|
| 0 | Sin MRP (manual) |
| 1 | MRP activo, crear solicitudes automaticas |
| 2 | MRP activo, solo verificacion |

### 10.2 Grupo de Planificacion PS

El **grupo de planificacion** (planning group) agrupa los requerimientos de proyecto para el MRP.

**Configuracion SPRO:**
```
Project System > Material > MRP for Projects > Define Planning Parameters
```

### 10.3 Perfil de Necesidades Primarias

Para proyectos con produccion propia, las necesidades de componentes de red se traducen en **necesidades primarias** que MRP planifica en cascada.

---

## 11. Integracion Stock Proyecto con CO-PS

### 11.1 Valoracion y Flujo Contable

Al entrar material a stock de proyecto (Mov. 101):
```
Cuenta Inventario Proyecto (Activo)     + Valor
  vs.
Cuenta GR/IR (Pasivo transitorio)       - Valor
```

Al salir material a proyecto (Mov. 221):
```
Cuenta de Consumo Materiales (CO WBS)   + Valor
  vs.
Cuenta Inventario Proyecto (Activo)     - Valor
```

### 11.2 Reporting CO con Stock Proyecto

En `CJI3` (Partidas individuales reales por proyecto) aparecen:
- Las salidas de stock (mov. 221) como costes reales con clase de coste de consumo de materiales
- Las entradas (mov. 101) NO aparecen directamente en CJI3 (son movimientos de inventario)

---

## 12. Buenas Practicas

1. **Decidir el tipo de stock al inicio** — Individual (Q) o consumo directo. Cambiar a mitad de proyecto genera inconsistencias.
2. **Usar mov. 411Q para transferir stock existente** — Si hay material en stock normal que debe vincularse al proyecto.
3. **Monitorear reservas abiertas** — Reservas sin cubrir generan costes comprometidos que impactan el presupuesto.
4. **Limpiar stock residual antes de TECO** — Stock de proyecto no consumido al cierre genera saldo en WBS.
5. **Configurar cuenta especifica de inventario** — Facilita la reconciliacion y el reporte financiero de proyectos.
6. **MRP orientado a proyecto para materiales criticos** — Especialmente en proyectos EPC con plazos de entrega largos.
7. **Numeros de serie en stock proyecto** — Para equipos que requieren trazabilidad completa desde compra hasta instalacion.
8. **Verificar disponibilidad antes de confirmar actividades** — Usar CN49 para evitar paros por falta de material.
