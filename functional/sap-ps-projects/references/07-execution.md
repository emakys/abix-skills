# Ejecucion del Proyecto — SAP PS S/4HANA 2023

## 1. Ciclo de Vida del Proyecto — Estados

La ejecucion del proyecto en SAP PS esta gobernada por un ciclo de estados de sistema. Cada estado habilita o bloquea determinadas transacciones.

### Estados de Sistema del Proyecto/WBS/Red

| Estado | Codigo | Descripcion | Transacciones habilitadas |
|---|---|---|---|
| Creado | CREA (I0001) | Objeto creado, no liberado | Solo datos maestros |
| Liberado | REL (I0002) | Objeto activo, en ejecucion | Imputaciones, confirmaciones, pedidos |
| Cierre Tecnico | TECO (I0045) | Trabajo terminado | Solo liquidacion y cierre |
| Cierre | CLSD (I0046) | Cerrado definitivamente | Solo visualizacion |
| Bloqueado | LKD (I0043) | Bloqueado temporalmente | Ninguna imputacion |
| Eliminado | DLFL (I0076) | Marcado para borrar | Ninguna |

### Tabla JEST — Estado de Objeto

| Campo | Descripcion |
|---|---|
| OBJNR | Numero de objeto (PRPS-OBJNR, AFKO-OBJNR) |
| STAT | Codigo de estado (I0001, I0002...) |
| INACT | Indicador inactivo (' '=activo, 'X'=inactivo) |
| CHNAM | Usuario que cambio el estado |
| UDATE | Fecha del cambio de estado |
| UTIME | Hora del cambio de estado |

---

## 2. Liberacion del Proyecto (CREA → REL)

La liberacion es el paso que habilita la ejecucion real del proyecto: imputaciones de costes, confirmaciones de actividades, movimientos de mercancias.

### Niveles de Liberacion

La liberacion puede hacerse a distintos niveles:

| Nivel | Transaccion | Descripcion |
|---|---|---|
| Proyecto completo | CJ20N | Libera proyecto + todos sus WBS y redes |
| WBS individual | CJ22 | Libera un elemento WBS especifico |
| Red individual | CN25 | Libera una red y sus actividades |
| Colectiva | CJ2F | Libera multiples proyectos/WBS |

### Proceso de Liberacion

```
CJ20N → Seleccionar proyecto o WBS → Editar → Liberar
O bien: menu Estado → Liberar

El sistema verifica:
1. Que los datos maestros esten completos
2. Que el presupuesto este asignado (si control disponibilidad activo)
3. Que no haya errores de configuracion

Resultado: Estado cambia de CREA a REL
           JEST tabla: STAT='I0001' INACT='X', STAT='I0002' INACT=' '
```

---

## 3. Gestion de Status (BS02, TJ02)

### Transaccion BS02 — Esquema de Status de Usuario

Permite definir estados de usuario propios para el proyecto (adicionales a los estados de sistema).

```
SPRO → Project System → Estructuras → Estado →
Definir Esquema de Status de Usuario
Transaccion: BS02
```

Ejemplos de estados de usuario tipicos:

| Estado | Descripcion | Accion permitida |
|---|---|---|
| APRO | Aprobado por gerencia | Solo informativo |
| ENRE | En revision de costes | Bloquea liberacion |
| AUDIT | En auditoria | Bloquea liquidacion |
| PEND | Pendiente de documentacion | Informativo |

### Tabla TJ02 — Codigos de Estado del Sistema

TJ02 contiene la definicion de los estados de sistema estandar de SAP:

```sql
SELECT ISTAT, TXT04, TXT30
FROM TJ02T
WHERE SPRAS = 'S'
  AND ISTAT LIKE 'I00%'
ORDER BY ISTAT
```

---

## 4. Confirmaciones de Actividades

Las confirmaciones registran el progreso real de las actividades de red: horas trabajadas, cantidad realizada, fechas reales.

### Tipos de Confirmacion

| Tipo | Descripcion | Uso |
|---|---|---|
| Individual | Una actividad a la vez | CN27 |
| Colectiva | Multiples actividades | CN25 |
| Confirmacion parcial | Actividad no terminada | CN27 (sin finalizar) |
| Confirmacion final | Actividad terminada | CN27 (finalizar) |
| Anulacion | Revertir confirmacion | CN28 |

### Transaccion CN27 — Confirmacion Individual

```
CN27 → Numero de red / Numero de actividad
Introducir:
  - Fecha de confirmacion
  - Horas reales trabajadas (por tipo de actividad)
  - Cantidad realizada
  - Fecha inicio real / Fecha fin real
  - Si es confirmacion final (actividad terminada)
  - Texto de confirmacion
Guardar → AFRU tabla actualizada
         ACDOCA actualizado con coste real
```

### Transaccion CN25 — Confirmacion Colectiva

```
CN25 → Seleccionar proyecto, red o actividades
Lista de actividades pendientes de confirmacion
Introducir porcentaje de avance o horas para cada una
Guardar en bloque
```

### Tabla AFRU — Confirmaciones de Red

| Campo | Tipo | Descripcion |
|---|---|---|
| RUECK | NUMC(10) | Numero de confirmacion |
| RMZHL | NUMC(8) | Contador de confirmacion |
| AUFNR | CHAR(12) | Numero de red |
| VORNR | CHAR(4) | Numero de actividad |
| BUDAT | DATS(8) | Fecha de contabilizacion |
| ISDD | DATS(8) | Fecha inicio real |
| IEDD | DATS(8) | Fecha fin real |
| ISMNG | DEC | Cantidad confirmada |
| CONF_QUAN_UNIT | UNIT | Unidad de cantidad |
| LASMG | DEC | Cantidad restante |
| RMNGA1..6 | DEC | Horas confirmadas por tipo actividad |
| XSTORNO | CHAR(1) | Indicador de anulacion |

```sql
-- Confirmaciones por proyecto
SELECT f.AUFNR, f.VORNR, f.BUDAT,
       f.RMNGA1 AS HORAS_CONF,
       f.ISDD, f.IEDD,
       f.XSTORNO
FROM AFRU f
INNER JOIN AFKO k ON k.AUFNR = f.AUFNR
WHERE k.PSPEL IN (
  SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUM_PROYECTO'
)
  AND f.XSTORNO = ' '
ORDER BY f.BUDAT, f.AUFNR, f.VORNR
```

---

## 5. Movimientos de Mercancias a Proyecto (MIGO)

Los movimientos de stock se pueden imputar directamente a elementos WBS o actividades de red.

### Tipos de Movimiento Relevantes

| Mvt | Descripcion | Impacto |
|---|---|---|
| 281 | Salida de stock a WBS (orden de proyecto) | Debita WBS |
| 282 | Anulacion 281 | Credita WBS |
| 261 | Consumo a orden (actividad de red) | Debita red/WBS |
| 262 | Anulacion 261 | Credita |
| 101 | Entrada de mercancias en pedido (a WBS) | Si pedido imputado a WBS |
| 501 | Entrada sin pedido a WBS | Debita WBS directamente |

### Proceso MIGO con Imputacion a WBS

```
MIGO → Clase de movimiento 281
Seleccionar material, cantidad, almacen
En ficha Imputacion:
  - Tipo de cuenta: P (WBS/Proyecto)
  - Numero de cuenta: POSID del WBS
Contabilizar → ACDOCA actualizado con coste real en el WBS
```

### Solicitudes de Pedido Automaticas (Actividades Externas)

Cuando una actividad de red con clave de control "pedido externo" se libera, el sistema genera automaticamente una Solicitud de Pedido (SolPed).

```
Liberacion actividad externa → SolPed automatica (BANF)
SolPed → (aprobacion) → Pedido de compras ME21N
Pedido → Entrada mercancias MIGO (mvt 101) → Coste en WBS/red
```

---

## 6. Pedidos de Compras a Proyecto

Los pedidos de compras pueden imputarse directamente a proyectos PS (WBS o actividades de red).

### Tipos de Imputacion en Pedido

| Tipo | Codigo | Descripcion |
|---|---|---|
| Proyecto (WBS) | P | Imputa a elemento WBS |
| Red | N | Imputa a actividad de red |
| Orden | F | Imputa a orden interna |

### Proceso de Pedido con Imputacion WBS

```
ME21N → Crear pedido
En posicion → ficha Imputacion:
  - Categoria imputacion: P
  - WBS: POSID del elemento WBS
  - Cantidad, precio, centro, grupo compra
Grabar → EKKO/EKPO con PSPNR del WBS
```

### Compromisos (Commitments)

Los pedidos de compras con imputacion a proyecto generan Compromisos en PS:
- El compromiso representa el gasto futuro esperado (pedido no facturado)
- Se incluye en el control de disponibilidad de presupuesto
- Se elimina al registrar la factura (MIRO)

```
SolPed → Compromiso nivel 1
Pedido  → Compromiso nivel 2 (reemplaza nivel 1)
MIGO   → Compromiso se convierte en coste real (parcial o total)
MIRO   → Compromiso eliminado completamente
```

---

## 7. Verificacion de Facturas (MIRO) a Proyecto

La verificacion de facturas de proveedores completa el ciclo de imputacion de costes externos al proyecto.

### Proceso MIRO

```
MIRO → Seleccionar pedido de referencia
Sistema propone posiciones del pedido con imputacion WBS
Introducir fecha factura, importe, impuestos
Contabilizar:
  - ACDOCA: coste real en WBS
  - Compromiso del pedido eliminado
  - FI: cuenta de proveedor acreedor
```

### Diferencias de Precio

Si el precio de la factura difiere del pedido:
```
Precio pedido: 1.000 EUR → imputado al WBS al hacer MIGO
Precio factura: 1.100 EUR → diferencia de 100 EUR → WBS asume la diferencia
```

La diferencia de precio se imputa al mismo objeto de imputacion (WBS/red) del pedido original.

---

## 8. Imputaciones Manuales (FB50 / FB60)

Se pueden imputar costes directamente a proyectos desde FI sin pasar por MM.

### FB50 — Asiento Manual a WBS

```
FB50 → Crear documento FI
En posicion de debito:
  - Cuenta: clase de coste (cuenta G/L de coste)
  - Tipo de objeto CO: WBS
  - Numero de objeto: POSID del WBS
  - Importe y texto
Contabilizar → ACDOCA con PSPNR del WBS
```

### FB60 — Factura de Proveedor a WBS

```
FB60 → Factura proveedor sin pedido de referencia
Linea de gasto:
  - Cuenta de coste
  - Imputacion: tipo P + WBS
Contabilizar → WBS asume el coste directamente
```

---

## 9. CATS — Time Recording (Confirmacion de Horas via CATS)

El Cross-Application Time Sheet (CATS) permite a los empleados registrar sus horas de trabajo imputadas a proyectos PS directamente.

### Transacciones CATS

| Transaccion | Descripcion |
|---|---|
| CAT2 | Ingresar tiempo (empleado) |
| CAT6 | Aprobar tiempo (supervisor) |
| CAT5 | Transferir a PS (confirmacion de red) |
| CATSPS | CATS especifico para PS |

### Flujo CATS→PS

```
Empleado: CAT2 → registra horas con referencia a red/actividad
Supervisor: CAT6 → aprueba el registro de horas
Transferencia: CAT5 → genera confirmacion en AFRU
                     → ACDOCA con coste real (horas × tarifa CO)
```

---

## 10. Distribucion de Gastos Indirectos (Overhead)

Los gastos indirectos (overhead) se pueden distribuir automaticamente a proyectos mediante:

### Calculo de Overhead Periodico

```
Transaccion: CJN1 / CJN2 (calculo overhead para PS)
O bien: KSS2 (calculo de gastos generales via ordenes PS)
```

La tasa de overhead se define en el esquema de calculo de costes del perfil de red/proyecto.

---

## 11. Reportes de Ejecucion

| Transaccion | Descripcion |
|---|---|
| CJI3 | Partidas individuales de costes del proyecto |
| CJ20N | Project Builder con costes en tiempo real |
| CNS41 | Estructura de proyecto con resumen costes |
| S_ALR_87013532 | Plan/real por proyecto |
| S_ALR_87013533 | Control de costes |
| CN60 | Evaluacion de hitos |
| CJIA | Informacion del proyecto (ABAP report) |

---

## 12. Fiori Apps de Ejecucion

| App ID | Descripcion |
|---|---|
| F2389 | Project Cockpit |
| F4567 | Monitor Project Costs |
| F3100 | Confirm Activities |
| F2390 | Monitor Project Budgets |

---

## 13. Consultas SQL/MCP de Ejecucion

```javascript
// Costes reales por proyecto, WBS y clase de coste
GetSqlQuery({
  query: `SELECT p.POSID, a.KSTAR, a.GJAHR, a.POPER,
                 SUM(a.HSL) AS COSTE_REAL,
                 SUM(a.KSL) AS COSTE_REAL_CO
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.RRCTY = '0'  -- real
            AND a.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, a.KSTAR, a.GJAHR, a.POPER
          ORDER BY p.POSID, a.KSTAR, a.POPER`
})

// Estado de todos los WBS de un proyecto
GetSqlQuery({
  query: `SELECT w.POSID, w.POST1,
                 j.STAT, t.TXT30 AS ESTADO
          FROM PRPS w
          INNER JOIN JEST j ON j.OBJNR = w.OBJNR AND j.INACT = ' '
          INNER JOIN TJ02T t ON t.ISTAT = j.STAT AND t.SPRAS = 'S'
          WHERE w.PSPNR IN (SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUM_PROYECTO')
            AND j.STAT IN ('I0001','I0002','I0045','I0046')
          ORDER BY w.POSID, j.STAT`
})

// Compromisos activos por proyecto
GetSqlQuery({
  query: `SELECT p.POSID, c.BTYP AS TIPO_COMPROMISO,
                 c.BELNR, c.WRTTP,
                 SUM(c.WKGBTR) AS IMPORTE_COMPROMISO
          FROM COOI c
          INNER JOIN PRPS p ON p.OBJNR = c.OBJNR
          WHERE c.WRTTP IN ('21','22')  -- SolPed y Pedido
            AND c.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, c.BTYP, c.BELNR, c.WRTTP
          ORDER BY p.POSID`
})
```

---

## 14. Mejores Practicas de Ejecucion

1. **Liberar en cascada**: Liberar siempre el proyecto desde el nivel superior (CJ20N) para que todos los WBS y redes queden liberados de forma coherente.

2. **Control de compromisos**: Monitorear regularmente los compromisos pendientes (pedidos sin facturar). Un proyecto puede tener el presupuesto "consumido" por compromisos aunque no haya costes reales todavia.

3. **Confirmaciones periodicas**: Establecer una cadencia semanal de confirmacion de actividades. Confirmaciones atrasadas distorsionan el avance real del proyecto.

4. **Separar costes internos de externos**: Usar clases de coste distintas para mano de obra interna (via CATS/confirmaciones) y proveedores externos (via MM). Facilita el analisis de la estructura de costes.

5. **TECO antes de liquidar**: Siempre marcar los WBS como TECO antes de ejecutar la liquidacion final. El estado TECO bloquea nuevas imputaciones y senaliza que el trabajo esta terminado.

6. **Anulacion documentada**: Toda anulacion de confirmacion o movimiento de mercancia debe llevar texto explicativo. La trazabilidad es critica en proyectos de auditoria.
