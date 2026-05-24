# Infotipos Maestros PA

## Conceptos Fundamentales

### Que es un Infotipo
Un infotipo es una unidad logica de datos de empleado identificada por un numero de 4 digitos (ej. IT0008). Cada infotipo tiene:
- Una tabla de base de datos: PA + numero (ej. PA0008)
- Una tabla de cluster (para algunos): RT, CRT, etc.
- Registros con validez temporal (BEGDA/ENDDA)
- Un time constraint que controla solapamiento de registros

### Time Constraint (Restriccion de Tiempo)
| Constraint | Descripcion | Ejemplo |
|------------|-------------|---------|
| 1 | Exactamente un registro activo siempre | IT0001 Asignacion Org. |
| 2 | Maximo un registro activo en cada momento | IT0008 Salario Base |
| 3 | Multiples registros activos simultaneos permitidos | IT0014 Pagos Recurrentes |
| T | Solo registros de fecha especifica | IT0000 Acciones |

### Subtypes (Subtipos)
Subdividen un infotipo en variantes. Ejemplo IT0006 tiene subtipo para tipo de direccion:
- 1 = Direccion permanente
- 2 = Direccion temporal
- 3 = Direccion de correspondencia

## Tabla Completa de Infotipos Principales

### IT0000 — Acciones (Actions)
- Tabla: PA0000
- Time Constraint: T (por fecha de accion)
- Campos clave: MASSN (tipo de accion), MASSG (motivo de accion), STAT2 (estado de empleado)
- Registro creado por cada accion de personal (contratacion, baja, cambio, etc.)
- No tiene subtipos
- Estados de empleado (STAT2): 0=Inactivo, 1=Retirado, 2=Salida, 3=Activo

### IT0001 — Asignacion Organizativa (Org Assignment)
- Tabla: PA0001
- Time Constraint: 1 (siempre debe existir exactamente un registro activo)
- Campos clave:
  - BUKRS: Sociedad FI
  - WERKS: Area de personal
  - BTRTL: Subdivision de personal
  - PERSG: Grupo de empleados
  - PERSK: Subgrupo de empleados
  - ABKRS: Area de nomina
  - KOSTL: Centro de coste CO
  - PLANS: Posicion OM
  - ORGEH: Unidad organizativa OM
  - STELL: Categoria de puesto OM
  - GSBER: Area de negocio FI
- Vinculo principal entre empleado y estructura FI/CO/OM

### IT0002 — Datos Personales (Personal Data)
- Tabla: PA0002
- Time Constraint: 1
- Campos clave:
  - NACHN: Apellido
  - VORNA: Nombre
  - GBDAT: Fecha de nacimiento
  - GESCH: Sexo (1=M, 2=F)
  - SPRSL: Idioma de correspondencia
  - NATIO: Nacionalidad
  - GBORT: Lugar de nacimiento
  - FAMST: Estado civil
- Datos especificos de pais en infotipos adicionales (IT0077 para pais adicional)

### IT0006 — Direcciones (Addresses)
- Tabla: PA0006
- Time Constraint: 2 por subtipo
- Subtipos principales:
  - 1: Direccion permanente
  - 2: Direccion temporal
  - 3: Lugar de trabajo / Oficina
  - 6: Notificacion de emergencia
- Campos clave: STRAS (calle), ORT01 (ciudad), PSTLZ (codigo postal), LAND1 (pais), TELN1 (telefono)

### IT0007 — Tiempo de Trabajo Previsto (Planned Working Time)
- Tabla: PA0007
- Time Constraint: 1
- Campos clave:
  - SCHKZ: Identificador de horario de trabajo (tabla T508A)
  - ARBST: Horas de trabajo por dia
  - WOSTD: Horas de trabajo por semana
  - ZTERF: Metodo de introduccion de tiempos
  - EMPCT: Porcentaje de empleo (p.ej. 50 para media jornada)
- Critico para nomina: determina factor de tiempo parcial

### IT0008 — Retribucion Basica (Basic Pay)
- Tabla: PA0008
- Time Constraint: 1
- Subtipos: agrupaciones de retribucion (normalmente subtipo 1 = nomina principal)
- Campos clave:
  - TRFAR: Tipo de convenio colectivo
  - TRFGB: Area de convenio colectivo
  - TRFGR: Grupo de convenio colectivo (nivel salarial)
  - TRFST: Nivel dentro del grupo
  - LGA01-LGA20: Conceptos salariales (tablas de conceptos)
  - BET01-BET20: Importes correspondientes a conceptos
  - WAERS: Moneda
  - ANSAL: Salario anual calculado
- Conceptos salariales definidos en tabla T511 / T512T

### IT0009 — Cuenta Bancaria (Bank Details)
- Tabla: PA0009
- Time Constraint: 2 por subtipo
- Subtipos: 0=Principal, 1=Cuenta 1, 2=Cuenta 2, etc.
- Campos clave:
  - ZLSCH: Metodo de pago (T=transferencia, S=cheque)
  - BANKL: Clave bancaria (BIC/SWIFT)
  - BANKN: Numero de cuenta (IBAN en EU)
  - BKONT: Cuenta de control bancaria
  - ALAND: Pais del banco (tabla T005)
  - BETRG/PROZN: Importe fijo o porcentaje para distribucion

### IT0014 — Conceptos Salariales Recurrentes (Recurring Payments/Deductions)
- Tabla: PA0014
- Time Constraint: 3 (multiples registros simultaneos)
- Campos clave:
  - LGART: Tipo de concepto salarial (tabla T511)
  - BETRG: Importe
  - OPKEN: Indicador de operacion (+/-)
  - ZDATE: Fecha de inicio de efecto
  - ENDE: Fecha de fin
  - ANZHL: Numero de periodos
- Ejemplo: plus transporte mensual fijo, deduccion sindical recurrente

### IT0015 — Conceptos Salariales Adicionales (Additional Payments)
- Tabla: PA0015
- Time Constraint: 3
- Similar a IT0014 pero para pagos puntuales (no recurrentes)
- Campos clave: LGART, BETRG, ANFDT (fecha de efecto unico)
- Ejemplo: bonus puntual, pago de vacaciones adicional

### IT0016 — Elementos del Contrato (Contract Elements)
- Tabla: PA0016
- Time Constraint: 2
- Campos clave:
  - ANSVH: Tipo de relacion laboral (tabla T542A)
  - CBEGDA: Fecha de inicio de contrato
  - CENDDA: Fecha de fin de contrato (contratos temporales)
  - KUENF: Plazo de preaviso empleado
  - KUENA: Plazo de preaviso empresa
  - PROBT: Periodo de prueba (fecha fin)
- Critico para calculos de finiquito y control de vencimientos

### IT0021 — Familia y Beneficiarios (Family Member/Dependents)
- Tabla: PA0021
- Time Constraint: 3 (multiples miembros)
- Subtipos por tipo de relacion:
  - 1: Conyugue
  - 2: Hijo/a
  - 3: Padre/Madre
  - 8: Beneficiario de seguro de vida
- Campos clave: FAMST (relacion), VORNA/NACHN (nombre), GBDAT (fecha nac.), GESCH (sexo)
- Usado para: calculo de complementos familiares, beneficiarios de seguros, cotizacion IRPF

### IT0105 — Datos de Comunicacion (Communication)
- Tabla: PA0105
- Time Constraint: 2 por subtipo
- Subtipos criticos:
  - 0001: SY-UNAME (usuario SAP vinculado al empleado)
  - 0010: Email corporativo
  - 0020: Telefono movil corporativo
  - 0030: Telefono fijo corporativo
  - 0050: Skype/Teams
- Campo clave: USRID (ID de comunicacion, p.ej. la direccion email)
- Vinculo empleado-usuario para ESS/MSS: subtipo 0001 con SY-UNAME

## Infotipos Especificos de Pais (Espana — MOLGA 04)

| IT | Descripcion |
|----|-------------|
| IT0347 | Retenciones IRPF |
| IT0348 | Datos Seguridad Social |
| IT0349 | Datos Residencia |
| IT0391 | Contratos especiales (minusvalias, bonificaciones) |
| IT0396 | Modelos IRPF (modelo 110/190) |

## Queries MCP para Infotipos

### Leer infotipo de un empleado (registro activo)
```
Tool: ReadTable
Tabla: PA0001 (cambiar numero segun infotipo)
Campos: PERNR, BEGDA, ENDDA, [campos especificos]
Filtro: PERNR = '<numero_empleado>' AND ENDDA >= SY-DATUM AND BEGDA <= SY-DATUM
```

### Leer historico completo de un infotipo
```
Tool: ReadTable
Tabla: PA0008
Campos: PERNR, BEGDA, ENDDA, LGA01, BET01, WAERS
Filtro: PERNR = '<numero_empleado>'
Ordenar: BEGDA DESC (para ver el mas reciente primero)
```

### Buscar empleados por area de nomina
```
Tool: ReadTable
Tabla: PA0001
Campos: PERNR, BUKRS, WERKS, ABKRS, ORGEH
Filtro: ABKRS = '<area_nomina>' AND ENDDA = '99991231' AND BEGDA <= SY-DATUM
```

### Leer conceptos salariales activos (IT0008)
```
Tool: ReadTable
Tabla: PA0008
Campos: PERNR, BEGDA, ENDDA, LGA01, BET01, LGA02, BET02, LGA03, BET03, WAERS, ANSAL
Filtro: ENDDA = '99991231' (registros sin fecha de fin = activos)
```

### Verificar usuarios SAP vinculados (IT0105 subtipo 0001)
```
Tool: ReadTable
Tabla: PA0105
Campos: PERNR, SUBTY, USRID
Filtro: SUBTY = '0001' AND ENDDA >= SY-DATUM
```

### Buscar empleados con contrato temporal proximos a vencer
```
Tool: ReadTable
Tabla: PA0016
Campos: PERNR, ANSVH, CBEGDA, CENDDA
Filtro: CENDDA BETWEEN SY-DATUM AND (SY-DATUM + 90) — proximos 90 dias
```

## Logica de Mantenimiento de Infotipos en ABAP

### Llamada a infotipo via modulo de funcion
```abap
CALL FUNCTION 'HR_READ_INFOTYPE'
  EXPORTING
    pernr           = lv_pernr
    infty           = '0008'
    begda           = sy-datum
    endda           = sy-datum
  TABLES
    infty_tab       = lt_pa0008
  EXCEPTIONS
    infty_not_found = 1.
```

### Estructura generica de registro de infotipo
```abap
DATA: ls_p0008 TYPE p0008.
" Campos comunes a todos los infotipos:
" ls_p0008-pernr = numero de personal
" ls_p0008-infty = '0008'
" ls_p0008-subty = subtipo
" ls_p0008-begda = fecha inicio vigencia
" ls_p0008-endda = fecha fin vigencia
" ls_p0008-aedtm = fecha ultima modificacion
" ls_p0008-uname = usuario que modifico
```

## Novedades S/4HANA 2023

- Mantenimiento de infotipos via Fiori apps ("Maintain Employee Master Data")
- HR Administrative Services: flujos de aprobacion para cambios criticos (IT0008, IT0009)
- Integracion con SuccessFactors: datos de IT0001, IT0002, IT0006 replicados via API
- Business Partner: IT0002 sincronizado con BP rol BUP001
- Fiori app "My Paystub" lee datos de IT0008 y resultado de nomina directamente
