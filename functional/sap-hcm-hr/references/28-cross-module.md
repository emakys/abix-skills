# Integracion Cross-Module HCM

## Vision General

HCM no opera en silos. Cada proceso de RRHH genera impacto financiero, operativo y de capacidad en otros modulos de S/4HANA. Esta guia cubre los puntos de integracion criticos, las tablas involucradas y como consultar el estado via MCP.

---

## HCM → FI: Contabilizacion de Nomina

### Flujo tecnico
La nomina (PY) genera documentos contables en FI mediante el proceso de **Posting de Nomina** (programa RPCIPE00 / transaccion PC00_M99_CIPE).

**Symbolic Accounts (cuentas simbolicas)**
- Tabla: `T52EK` — mapeo de wage types a symbolic accounts
- Tabla: `T030` — mapeo de symbolic accounts a cuentas GL reales (chart of accounts)
- Tabla: `T52EZ` — asignacion de employee groupings a symbolic accounts

**Posting a ACDOCA (Universal Journal)**
En S/4HANA 2023 la nomina contabiliza directamente en ACDOCA con todos los segmentos:
- `RBUKRS` — company code del infotipo 0001
- `KOSTL` — cost center del infotipo 0001
- `LSTAR` — activity type (si aplica)
- `PRCTR` — profit center derivado del cost center
- `GJAHR`, `MONAT` — periodo contable

**Proceso paso a paso**
1. Ejecutar nomina (RPCLSTRD / PC00_M99_CALC)
2. Verificar resultado en cluster de nomina (tabla PCL2, clave RD)
3. Crear posting run (PC00_M99_CIPE): simulacion primero, luego real
4. Verificar documento FI: transaccion FB03, referencia = numero de posting run
5. Reconciliacion: reporte RPCLSTRD comparar totales nomina vs FI

**Reconciliacion nomina-FI**
- Reporte: PC00_M99_CEDT (Payroll Journal)
- Diferencias comunes: wage types sin symbolic account, employees sin cost center, posting periodos cerrados
- Tabla de errores de posting: `T52BF`

**Customizing clave**
- IMG: Payroll → Reporting → Posting to Financial Accounting
- `T52EL` — employee grouping para posting
- `T52EP` — asignacion posting

---

## HCM → CO: Asignacion de Costos

### Cost Center Assignment (IT0001)
El infotipo 0001 (Organizational Assignment) es la fuente primaria de asignacion de costos:
- `IT0001-KOSTL` — cost center del empleado
- `IT0001-LSTAR` — activity type
- `IT0001-AUFNR` — internal order (opcional, para cargar costos directos)
- `IT0001-PS_PSP_PNR` — WBS element (opcional)

La jerarquia de derivacion: WBS > Order > Cost Center.

### Activity Allocation (Distribucion de Actividades)
- CATS (Cross-Application Time Sheet) alimenta confirmaciones de actividad a CO
- Transaccion: CAT2 (entrada), CAT6 (aprobacion), CATA (transferencia a CO/PP/PM/PS)
- La transferencia crea documentos en CO (tabla COEP) y actualiza ACDOCA

### Cost Distribution (IT0027)
Permite distribuir el costo de un empleado entre multiples cost centers:
- Infotipo: IT0027 (Cost Distribution)
- Campos: KOSTL (cost center), LSTAR (activity type), PROZS (porcentaje)
- Tabla: `P0027`
- La distribucion se aplica durante el posting de nomina

### Internal Orders para Personal
- Empleados pueden asignarse a ordenes internas (IT0001-AUFNR)
- Costos de nomina van directo a la orden
- Settlement de la orden distribuye a cost centers/WBS segun regla de liquidacion (tabla COBRB)

---

## HCM → PM: CATS a Ordenes de Mantenimiento

### Integracion CATS-PM
Los tecnicos de mantenimiento registran horas en CATS que se transfieren a ordenes PM:
- CATS entrada: CAT2 — campo `AUFNR` (orden PM) + `VORNR` (operacion)
- Transferencia: CATA o programa RCATSCOF
- La confirmacion de la orden PM actualiza costos reales (tabla AFRU)

**Costos de personal en ordenes PM**
- La orden PM acumula costos de personal via confirmaciones CATS
- Vista de costos: CO03 → Costos → Analisis de costos
- Tabla: `COEP` (partidas individuales CO) con `AUFNR` de la orden PM

**Customizing CATS-PM**
- IMG: Cross-Application Components → Time Sheet → Settings for Time Recording → Plant Maintenance

---

## HCM → PS: CATS a Elementos WBS

### Registro de horas en proyectos
- CATS permite imputar horas directamente a WBS elements o network activities
- Campos CATS: `PS_PSP_PNR` (WBS), `NPLNR` (network), `VORNR` (activity)
- Transferencia via CATA actualiza confirmaciones de red (tabla AFRU) y costos PS

**Project Staffing**
- Asignacion de personal a proyectos via IT0001 o por WBS en CATS
- Capacidad disponible: comparar horas planificadas vs confirmadas en proyecto
- Reporte: CN41 (Project Info System — Costs), filtrar por tipo de costo personal

**Costos de personal en PS**
- Planificacion: CJ40 (costo plan en WBS), incluir actividades de personal
- Real: viene de CATS transfer → confirma en red → actualiza WBS
- Revenue recognition: no aplica directamente a costos de personal

---

## HCM → PP: Capacidad de Centros de Trabajo

### Work Centers y Personal
- Centro de trabajo PP (tabla CR, CRHD) puede referenciar una posicion HCM
- Capacidad disponible del work center se basa en calendarios de trabajo (IT0007)
- El horario del empleado (work schedule) determina las horas disponibles

**Confirmaciones de produccion**
- Operarios confirman en CO11N → genera costos de mano de obra en orden PP
- Activity type vincula el work center con la tarifa de CO (tabla KBK1)
- Costos reales de mano de obra: COEP con tipo de costo de actividad

**Planificacion de capacidad**
- CM01 — perfil de carga de work centers
- La base de capacidad toma horas de la formula del work center
- Vincular con HCM: work center referencia personal number → disponibilidad real de IT0007

---

## HCM → MM: Gestion de Viajes

### Travel Management (FI-TV)
- Solicitudes de viaje: PR05 (Travel Request), TRIP (Travel Expense Report)
- Integracion con MM: viajes pueden generar purchase requisitions para reservas
- Posting de gastos de viaje → FI (similar a nomina, via symbolic accounts)

**Tablas clave Travel**
- `PTRV_HEAD` — cabecera del viaje
- `PTRV_PERIO` — periodos del viaje
- `PTRV_COST` — costos por tipo

---

## Arbol de Decision: Asignacion de Costos de Personal

```
¿El costo debe ir a un proyecto especifico?
  SI → ¿Hay orden de red (network activity)?
         SI → Usar NPLNR+VORNR en CATS → transferencia a PS
         NO → Usar PS_PSP_PNR (WBS) en IT0001 o CATS
  NO → ¿El costo es para mantenimiento?
         SI → Usar AUFNR (orden PM) en CATS → transferencia PM
         NO → ¿El costo se distribuye entre multiples cost centers?
                SI → IT0027 (Cost Distribution) con porcentajes
                NO → IT0001-KOSTL (cost center unico del empleado)
```

---

## Queries MCP Recomendadas

### Verificar configuracion de symbolic accounts
```
SearchObject: tipo TABL, nombre T52EK
ReadTable: T52EK, filtros por molga (country grouping) y lgart (wage type)
```

### Verificar posting runs de nomina
```
SearchObject: tipo PROG, nombre RPCIPE00
GetObjectSource: para revisar logica de posting
```

### Consultar infotipos de asignacion
```
ReadTable: PA0001, filtros por PERNR y BEGDA/ENDDA
ReadTable: PA0027, filtros por PERNR (cost distribution)
```

### Verificar transferencia CATS
```
ReadTable: CATSDB, filtros por PERNR, WORKDATE, RAUFNR (orden)
ReadTable: CATS_DA, estado de aprobacion por entrada
```

### Verificar costos en CO post-nomina
```
ReadTable: ACDOCA, filtros por RBUKRS, GJAHR, MONAT, RACCT (cuenta GL de personal)
ReadTable: COEP, filtros por AUFNR (si hay orden) y GJAHR
```

### Verificar asignacion work center-personal (PP)
```
ReadTable: CRHD, filtros por ARBPL (work center), WERKS
ReadTable: CRCA, capacidades del work center
```

---

## Notas S/4HANA 2023

- En S/4HANA el posting de nomina va a ACDOCA directamente (no pasa por tablas FI clasicas como BSEG de forma primaria)
- CATS usa la tabla CATSDB como staging; la transferencia genera documentos reales en CO/PM/PS/PP
- El Universal Journal (ACDOCA) unifica los costos de personal con el resto de movimientos financieros, permitiendo reportes integrados sin reconciliacion manual
- Fiori apps relevantes: "My Timesheet" (CATS), "Approve Timesheet" (aprobacion), "Monitor Payroll Results" (nomina), "Display Payroll Documents" (FI posting)
