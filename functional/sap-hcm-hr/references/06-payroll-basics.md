# Payroll — Fundamentos

## Proceso de Nómina — Visión General

El proceso de nómina sigue una secuencia estricta de pasos:

```
1. SIMULACIÓN    → Prueba sin impacto en datos reales
2. LIBERACIÓN    → Bloqueo del período (control record: Released)
3. INICIO        → Ejecución real de nómina (RPCALC*)
4. VERIFICACIÓN  → Revisión de resultados (logs, listas)
5. CORRECCIONES  → Si hay errores: unlock → corregir → re-run
6. SALIDA        → Cierre del período (control record: Exited)
7. CONTABILIZACIÓN → Post a FI/CO (RPCIPE0 / RPCIE0)
```

El proceso es controlado por el **registro de control** (PA03) y bloqueado por área de nómina.

## Área de Nómina (T549A)

Define el agrupamiento de empleados que se procesan juntos.

| Campo        | Descripción                                        |
|--------------|----------------------------------------------------|
| ABKRS        | Clave de área de nómina                            |
| Descripción  | Nombre del área (p.ej. "Mensual España")           |
| Período      | Frecuencia: mensual, quincenal, semanal, etc.      |
| Esquema       | Esquema de nómina asignado (p.ej. ES00 para España)|

El área de nómina se asigna al empleado en **IT0001** (campo ABKRS) y se hereda de la organización.

## Período de Nómina (T549Q)

Define los períodos exactos de proceso por área de nómina.

| Campo   | Descripción                          |
|---------|--------------------------------------|
| ABKRS   | Área de nómina                       |
| YYYYPP  | Año + número de período              |
| BEGDA   | Fecha inicio del período             |
| ENDDA   | Fecha fin del período                |
| LDATE   | Fecha límite (última fecha de datos) |

Se genera automáticamente con la herramienta **RPUCTP00**.

## Registro de Control (PA03)

Controla el estado del proceso de nómina por área.

Estados del registro de control:

| Estado              | Código | Descripción                                      |
|---------------------|--------|--------------------------------------------------|
| Released for Payroll| 1      | Período liberado, listo para ejecución           |
| Released for Correction| 2  | Abierto para correcciones durante el proceso     |
| Exited              | 3      | Período cerrado, nómina finalizada               |

**Bloqueo (Lock):** Durante la ejecución de nómina, el período se bloquea automáticamente para evitar ejecuciones paralelas. Se desbloquea al finalizar o en caso de error.

TCode **PA03**: Mantenimiento del registro de control por área de nómina.

## Esquemas de Nómina (PE01)

Los esquemas definen la lógica de cálculo de la nómina.

| Esquema | País / Uso                              |
|---------|-----------------------------------------|
| X000    | Esquema internacional (base)            |
| DE00    | Alemania                                |
| ES00    | España                                  |
| US00    | EE.UU.                                  |
| /xxx    | Esquemas country-specific personalizados|

Los esquemas se construyen con **funciones** (p.ej. ACTIO, COPY, IF, ENDIF) y llaman a **reglas de cálculo (PCR)**.

Herramienta: **PE01** — Editor de esquemas de nómina.

## Reglas de Cálculo PCR (PE02)

Las PCR (Payroll Calculation Rules) son la unidad mínima de lógica de nómina.

Estructura de una PCR:
- **Operación**: qué hacer (ADDWT, MULTI, DIVID, COPY...).
- **Tipo de wage type**: con qué wage types operar.
- **Condiciones**: decisiones basadas en campos del empleado o resultado.

Herramienta: **PE02** — Editor de reglas de cálculo.

Ejemplos de operaciones comunes:

| Operación | Descripción                               |
|-----------|-------------------------------------------|
| ADDWT     | Sumar wage type a una tabla interna       |
| MULTI     | Multiplicar importe por factor            |
| DIVID     | Dividir importe                           |
| COPY      | Copiar wage type a otro                   |
| ELIMI     | Eliminar wage type de tabla               |

## Wage Types (Tipos de Salario)

Los wage types son el elemento central de la nómina. Cada concepto salarial es un wage type.

### Clasificación por Tipo

| Rango    | Tipo        | Descripción                                          |
|----------|-------------|------------------------------------------------------|
| /1xx     | Primarios   | Salario base, complementos — definidos en IT0008/0014/0015 |
| /3xx     | Secundarios | Generados por el proceso de nómina (IRPF, SS...)     |
| /5xx     | Técnicos    | Acumuladores internos del esquema                    |
| /8xx     | Técnicos    | Resultados de proceso (neto, bruto, etc.)            |
| /559     | Neto        | Importe neto a pagar (estándar internacional)        |

### Infotipos con Wage Types

| Infotipo | Contenido                                          |
|----------|----------------------------------------------------|
| IT0008   | Salario básico (wage types periódicos fijos)       |
| IT0014   | Devengos/descuentos periódicos recurrentes         |
| IT0015   | Pagos/descuentos adicionales (fecha puntual)       |

### Configuración de Wage Types

- Tabla **T512W**: definición de wage types.
- Tabla **T511**: características de wage types (evaluación, acumulación).
- Herramienta **OH11**: mantenimiento de wage types.

## Clústeres de Resultados

Los resultados de nómina se almacenan en tablas de clústeres (no tablas relacionales estándar).

| Clúster | Tabla | Contenido                                          |
|---------|-------|----------------------------------------------------|
| B1      | PCL1  | Datos personales en bruto (buffer nómina)          |
| B2      | PCL2  | Resultados de nómina (wage types, acumuladores)    |
| RX      | PCL2  | Resultados de nómina para Reporting internacional  |
| G1      | PCL1  | Datos de tiempo para nómina                        |

Para leer resultados de nómina en ABAP se usa la **función estándar**:

```abap
CALL FUNCTION 'CU_READ_RGDIR'
  EXPORTING
    persnr          = lv_pernr
  TABLES
    in_rgdir        = lt_rgdir
  EXCEPTIONS
    no_record_found = 1.

" Leer resultados del período
CALL FUNCTION 'PYXX_READ_PAYROLL_RESULT'
  EXPORTING
    clusterid                 = 'RX'
    employeenumber            = lv_pernr
    sequencenumber            = ls_rgdir-seqnr
    read_only_international   = 'X'
  CHANGING
    payroll_result            = ls_payroll_result
  EXCEPTIONS
    illegal_isocode_or_cltype = 1
    error_generating_import   = 2
    import_mismatch_error     = 3
    subpool_dir_full          = 4
    no_read_authority         = 5
    no_record_found           = 6
    others                    = 7.
```

## Contabilización Retroactiva (RRDAT)

Cuando un empleado tiene cambios con fecha retroactiva (p.ej. aumento salarial en enero procesado en marzo), el sistema genera **diferencias retroactivas**.

- El campo **RRDAT** (fecha retroactiva) en el registro de control determina desde cuándo recalcular.
- Los períodos afectados se procesan nuevamente y las diferencias se contabilizan en el período actual.
- Los resultados retroactivos se almacenan en el clúster B2 con indicador de período original.

Wage types de diferencias retroactivas generalmente en rango **/5xx** y **/6xx**.

## Transacciones de Nómina

| TCode    | Descripción                                              |
|----------|----------------------------------------------------------|
| PA03     | Registro de control de nómina                            |
| PC00_M99_CALC / RPCALCX0 | Ejecución de nómina (country-specific)  |
| PC00_M99_CEDT | Diario de nómina (Employee Payroll Summary)        |
| PC00_M99_CLGA | Contabilización a FI/CO                            |
| PE01     | Editor de esquemas de nómina                             |
| PE02     | Editor de reglas de cálculo PCR                          |
| PE03     | Editor de características (Merkmal)                      |
| OH11     | Mantenimiento de wage types                              |
| PU01     | Borrar datos de nómina (test)                            |
| PU03     | Mantenimiento del registro de control                    |

## Consultas vía MCP (SAP ADT)

### Verificar estado del registro de control

```abap
SELECT SINGLE abkrs, paydt, permo, pernr, ldate
  FROM t549q
  WHERE abkrs = @lv_abkrs
    AND pabrj = @lv_year
    AND pabrp = @lv_period
  INTO @DATA(ls_period).
```

### Leer wage types de IT0008 (salario básico)

```abap
SELECT pernr, begda, endda, lga01, bet01, lga02, bet02
  FROM pa0008
  WHERE pernr = @lv_pernr
    AND endda >= @sy-datum
  INTO TABLE @DATA(lt_salary).
```

Herramienta MCP recomendada: `GetObjectSource` para leer esquemas/PCRs custom, `SearchObject` para localizar wage types (tipo PYTP), `ExecuteReport` para ejecutar reports de nómina estándar.

## Notas S/4HANA 2023

- **SAP S/4HANA Payroll** (on-premise) mantiene la arquitectura clásica de esquemas/PCRs en 2023. No hay cambio de modelo en esta versión.
- **SAP SuccessFactors Employee Central Payroll** es la opción cloud, construida sobre el mismo motor de nómina SAP pero operado en la nube.
- En S/4HANA 2023, la **contabilización de nómina a FI** usa los mismos IDocs y tablas simbólicas (T52EK, T52EL) de siempre.
- **Fiori apps de nómina**: limitadas en 2023 para empleados (ver nómina, descargar recibo). La ejecución de nómina sigue siendo transaccional (PC00_Mxx).
- Para reporting de nómina analítico se recomienda **SAP Analytics Cloud** con extractores basados en **CDS views** (p.ej. `I_PayrollResult`).
- La función **PYXX_READ_PAYROLL_RESULT** sigue siendo el método estándar para leer resultados en desarrollos custom en S/4HANA 2023.
