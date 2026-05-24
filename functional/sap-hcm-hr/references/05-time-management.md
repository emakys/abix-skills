# Time Management — Gestión de Tiempos

## Modalidades de Registro

| Modalidad | Descripción                                                                 |
|-----------|-----------------------------------------------------------------------------|
| Positivo  | Se registran todas las presencias. Ausencias = todo lo no registrado.       |
| Negativo  | Solo se registran desviaciones (ausencias, horas extra). Presencia implícita.|

La modalidad se define por **grupo de empleados / subgrupo** en la configuración del esquema de tiempo.

## Horarios de Trabajo

### Tablas de Configuración

| Tabla  | Contenido                                                  |
|--------|------------------------------------------------------------|
| T508A  | Tipos de día laborable (DWS — Daily Work Schedule)         |
| T550A  | Horarios de trabajo periódicos (PWS — Period Work Schedule)|
| T551A  | Reglas de horario de trabajo (WSR — Work Schedule Rule)    |
| T552A  | Variantes de horario diario                                |

### Jerarquía de Horarios

```
Work Schedule Rule (T551A / IT0007)
  └── Period Work Schedule (T550A)
        └── Daily Work Schedule (T508A)
              └── Planned Working Time (horas planificadas por día)
```

El infotipo **IT0007** (Horario de Trabajo Teórico) asigna la regla de horario al empleado.

## Tipos de Ausencia y Cuotas

### Tipos de Ausencia (T554S)

Define los tipos de ausencia válidos (vacaciones, baja médica, permiso, etc.).

Campos clave:
- **Clase de ausencia**: pagada / no pagada.
- **Integración nómina**: genera wage types en payroll.
- **Deducción de cuota**: si descuenta de un saldo.

### Cuotas de Ausencia (T556A)

Define los tipos de cuota (p.ej. días de vacaciones anuales).

Generación de cuotas:
- Manual (IT2006).
- Automática vía **RPTQTA00** o evaluación de tiempos (regla de cuota en esquema).

## Infotipos de Tiempo

| Infotipo | Nombre              | Descripción                                          |
|----------|---------------------|------------------------------------------------------|
| IT2001   | Ausencias           | Registro de ausencias (vacaciones, baja, etc.)       |
| IT2002   | Presencias          | Registro de presencias adicionales / horas extra     |
| IT2003   | Sustituciones       | Cambio temporal de horario o puesto                  |
| IT2004   | Disponibilidad      | Guardias y disponibilidades                          |
| IT2006   | Cuotas de ausencia  | Saldo de cuotas (vacaciones acumuladas, etc.)        |
| IT2007   | Cuotas de presencia | Saldo de horas extra compensables                    |
| IT2010   | Resultados EE       | Resultados intermedios de la evaluación de tiempos   |
| IT2011   | Fichajes (TEVEN)    | Pares de fichaje (entrada/salida) — tiempo positivo  |

## Evaluación de Tiempos

### Programa Principal

**RPTIME00**: programa de evaluación de tiempos. Procesa los datos de tiempo de los empleados según el esquema asignado.

### Esquemas Estándar

| Esquema | Uso                                              |
|---------|--------------------------------------------------|
| TM00    | Evaluación de tiempos — registro negativo        |
| TM04    | Evaluación de tiempos — registro positivo        |

Los esquemas se configuran en **PE01** (igual que los esquemas de nómina) y usan **reglas de cálculo (PCR)** de tiempo.

### Tipos de Tiempo (Time Types)

Acumuladores internos durante la evaluación. Ejemplos:
- **0050**: Tiempo planificado.
- **0100**: Tiempo real trabajado.
- **0200**: Horas extra.

Se definen en tabla **T555A**.

### Pares de Tiempo (Time Pairs)

Generados a partir de fichajes (IT2011). Cada par = entrada + salida. La evaluación los clasifica en:
- Tiempo planificado cubierto.
- Horas extra.
- Ausencias no justificadas.

## Transacciones de Tiempo

| TCode | Descripción                                              |
|-------|----------------------------------------------------------|
| PT60  | Evaluación de tiempos (ejecutar RPTIME00)                |
| PT61  | Hoja de tiempos individual                               |
| PT62  | Calendario de presencias (vista mensual empleado)        |
| PT63  | Resumen de horario de trabajo                            |
| PA61  | Mantenimiento infotipos de tiempo (IT20xx)               |
| PA51  | Visualización infotipos de tiempo                        |
| CATS  | Cross-Application Time Sheet (registro de tiempos multi-app)|
| CAT2  | CATS — Entrada de datos de tiempo                        |
| CAT6  | CATS — Aprobación de tiempos                             |

## CATS — Cross-Application Time Sheet

CATS permite el registro de tiempos integrado con:
- **CO** (imputación a órdenes/centros de coste).
- **PS** (imputación a actividades de proyecto WBS/Red).
- **PM/CS** (órdenes de mantenimiento).
- **HCM Payroll** (como base para nómina).

Tablas CATS: **CATSDB** (datos CATS), **CATSCO** (transferencia a CO).

## Consultas vía MCP (SAP ADT)

### Leer ausencias de un empleado

```abap
SELECT pernr, begda, endda, abwtp, stdaz
  FROM pa2001
  WHERE pernr = @lv_pernr
    AND begda >= @lv_fecha_inicio
    AND endda <= @lv_fecha_fin
  INTO TABLE @DATA(lt_ausencias).
```

### Leer cuota de vacaciones

```abap
SELECT pernr, begda, endda, ktart, kverb, krest
  FROM pa2006
  WHERE pernr = @lv_pernr
    AND ktart = '10'       " Tipo de cuota vacaciones
    AND endda >= @sy-datum
  INTO TABLE @DATA(lt_cuotas).
```

Herramienta MCP recomendada: `GetObjectSource` para leer programas de tiempo custom, `ExecuteReport` para RPTIME00/RPTQTA00.

## Notas S/4HANA 2023

- En S/4HANA on-premise 2023, la gestión de tiempos HCM clásica (PT60, RPTIME00) sigue siendo el estándar.
- **SAP Time and Attendance Management** (solución cloud) se integra vía SF EC para clientes en transición a cloud.
- Las **CDS Views** de HCM tiempo (p.ej. `I_TimeAccount`, `I_EmployeeTime`) están disponibles para reporting en SAC y Fiori.
- La integración con **sistemas de control de acceso** (fichadores) se realiza vía IDocs (HR_TIME_TICKETS) o APIs REST custom.
- Recomendación: usar **FIORI app "My Leave Requests"** (F0570) para empleados y **"Approve Leave Requests"** (F1241) para managers en implementaciones S/4HANA 2023.
