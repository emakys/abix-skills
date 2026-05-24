# Extensibilidad HCM

## Infotipos de Cliente (Rango 9000-9999)

Los infotipos de cliente permiten extender el modelo de datos de Empleados sin modificar objetos SAP estándar. El rango reservado para clientes es **9000 a 9999**.

### Crear un Infotipo Personalizado (Transaccion PM01)

**Pasos en PM01:**
1. Ingresar numero de infotipo (ej. 9001) y descripcion
2. Seleccionar categoria: Single, Time Constraint 1/2/3, o Tiempo
3. PM01 genera automaticamente:
   - Estructura `PS9001` (campos del infotipo)
   - Tabla de base de datos `PA9001`
   - Dynpro de mantenimiento (pantalla 2000)
   - Modulos de funcion `MP900100` (inicial), `MP900110` (verificacion)
4. Activar en SE11 la estructura y tabla generadas
5. Agregar entradas en `T582A` (infotipo permitido por subarea de personal) y `T588B` (menu de infotipos)

**Campos obligatorios en toda estructura PSxxxx:**
- INCLUDE `PAKEY` (clave del infotipo: PERNR, INFTY, SUBTY, OBJPS, SPRPS, ENDDA, BEGDA, SEQNR)
- INCLUDE `PSHDR` (cabecera estandar: AEDTM, UNAME, HISTO, ITXEX, REFEX, ORDEX, ITBLD, PREAS, FLAG1-4, ITOLD, PSYST)

**Recomendaciones:**
- Usar subtipos (`SUBTY`) para variantes del mismo infotipo
- Definir time constraint segun negocio: TC1 (siempre uno), TC2 (maximo uno activo), TC3 (sin restriccion)
- Documentar en `T591` (subtipos) y `T591S` (textos de subtipos)

---

## Customer Includes en Infotipos Estandar

SAP entrega includes de cliente vacias en estructuras de infotipos estandar para agregar campos Z sin modificar objetos originales.

### Includes Disponibles por Infotipo

| Infotipo | Include de Cliente | Tabla BD |
|----------|-------------------|----------|
| 0001 (Asignacion Org) | `CI_P0001` | PA0001 |
| 0002 (Datos Personales) | `CI_P0002` | PA0002 |
| 0006 (Direcciones) | `CI_P0006` | PA0006 |
| 0007 (Tiempo de Trabajo) | `CI_P0007` | PA0007 |
| 0008 (Retribucion Basica) | `CI_P0008` | PA0008 |
| 0014 (Conceptos Nomina Recurrentes) | `CI_P0014` | PA0014 |
| 0015 (Pagos Adicionales) | `CI_P0015` | PA0015 |
| 0021 (Familia) | `CI_P0021` | PA0021 |
| 0041 (Especificaciones de Fecha) | `CI_P0041` | PA0041 |

**Procedimiento:**
1. Ir a SE11, buscar el include correspondiente (ej. `CI_P0001`)
2. Agregar campos Z (convencion: `ZZ` + nombre_campo para evitar colisiones)
3. Activar — la tabla PA0001 se amplia automaticamente
4. Ajustar dynpro si se requiere mostrar los campos en pantalla (modificacion de pantalla estandar con Screen Painter)

**Limitacion:** No se pueden agregar campos clave ni modificar la estructura base del infotipo.

---

## BAdIs Principales de HCM

### HRPAD00INFTY — Operaciones de Infotipo

**Proposito:** Ejecutar logica de negocio al crear, modificar, borrar o copiar cualquier infotipo.

**Metodos clave:**
- `BEFORE_INFOTYPE_OPERATION` — Validaciones previas, puede cancelar la operacion con `RAISE EXCEPTION`
- `AFTER_INFOTYPE_OPERATION` — Acciones post-grabacion (escribir otros infotipos, logs)
- `CHANGE_INFOTYPE_CONTEXT` — Modificar datos antes de mostrar en pantalla

**Filtros disponibles:** Por numero de infotipo (INFTY), por subtipo (SUBTY), por tipo de operacion (INS/MOD/DEL/COP).

**Uso tipico:**
```abap
METHOD if_ex_hrpad00infty~before_infotype_operation.
  IF infty = '0008' AND operatpn = 'INS'.
    " Validar salario dentro de banda salarial
    IF new_infty-p0008-bet01 > lv_banda_max.
      RAISE EXCEPTION TYPE cx_hrpad_stop_processing
        EXPORTING textid = cx_hrpad_stop_processing=>salary_exceeded.
    ENDIF.
  ENDIF.
ENDMETHOD.
```

### HRCMP0030B — Compensacion

**Proposito:** Extensibilidad del proceso de compensacion (Compensation Management, modulo CM).

**Metodos clave:**
- `CHECK_ELIGIBILITY` — Determinar si empleado es elegible para revision salarial
- `CALCULATE_INCREASE` — Calcular incremento propuesto
- `AFTER_SAVE` — Logica post-grabacion de ajuste salarial

**Contexto:** Se ejecuta en las transacciones HCMP_PROCESS_COMP y workflows de compensacion.

### HRBEN00_ELIGY — Elegibilidad de Beneficios

**Proposito:** Determinar que planes de beneficios aplican a cada empleado.

**Metodos clave:**
- `CHECK_BENEFIT_ELIGIBILITY` — Retorna flag de elegibilidad por empleado y plan
- `DETERMINE_BENEFIT_AREA` — Asignar area de beneficios dinamicamente
- `OVERRIDE_STANDARD_RULES` — Sobrescribir reglas de elegibilidad estandar

**Configuracion previa requerida:** Reglas de elegibilidad en SPRO > Gestion de Personal > Beneficios > Planes de Beneficios > Elegibilidad.

### Otros BAdIs Relevantes

| BAdI | Modulo | Descripcion |
|------|--------|-------------|
| `HRPAY00_CHECK_FOR_ERRORS` | PY | Verificaciones adicionales durante calculo de nomina |
| `HRPAD00_ADD_EMPLOYMENT` | PA | Ampliar proceso de contratacion |
| `HRTIM00_ABS_ATT_CHECK` | TM | Validar ausencias/asistencias |
| `HRPBS00_INFOTYPE_0001` | PA | Logica especifica para infotipo 0001 |
| `PT_ARQ_REQ_CHECK` | TM | Verificar solicitudes de ausencia en workflows |

---

## User Exits en Esquemas de Nomina (PCRs Personalizadas)

La nomina de SAP se controla mediante **esquemas** (PE01) y **reglas de calculo de personal** (PE02). El punto de extension mas flexible son las **funciones de usuario** y los **PCRs de cliente**.

### Funciones de Usuario en Esquemas (PE01)

Funciones clave para insertar logica Z:

| Funcion | Descripcion |
|---------|-------------|
| `ZLIT` | Ejecutar PCR de cliente en la posicion del esquema |
| `ACTIO` | Ejecutar accion de proceso (operaciones predefinidas) |
| `COPY`  | Copiar resultados entre tablas internas de nomina |

**Regla de naming:** Los PCRs de cliente deben empezar con `Z` o `Y` (rango de cliente).

### Crear PCR de Cliente (PE02)

1. Transaccion PE02 → crear nueva regla con prefijo Z
2. Definir el arbol de decision usando operaciones:
   - `ADDWT` — Agregar concepto de nomina al resultado
   - `MULTI` — Multiplicar valor
   - `DIVID` — Dividir valor
   - `ROUND` — Redondear
   - `LIMIT` — Aplicar limite superior/inferior
   - `HRS=P` — Tomar horas de la tabla P (infotipos de tiempo)
   - `AMT=P` — Tomar importe de infotipo
3. Insertar PCR en el esquema con funcion `ZLIT`

**Ejemplo — PCR para calcular bono por asistencia:**
```
ZBON  Bono Asistencia
  IF  AMT>0 HRS ..
  AMT=  ... (logica de calculo)
  ADDWT /001 OT ..
```

### Enhancement Spots en HCM

SAP HCM tiene enhancement spots en los modulos de funcion criticos:

| Enhancement Spot | Descripcion |
|-----------------|-------------|
| `ES_RPUCTP00_PROCESS` | Proceso de tiempo (RP_TIME_EVALUATION) |
| `ES_PAYROLL_CALCULATION` | Motor de calculo de nomina |
| `SMOD: PBAS0001` | Datos basicos de empleado (User Exit clasico) |
| `SMOD: PPOCF001` | Evaluacion de organizacion |

**Activar con CMOD:** Crear proyecto Z, asignar la mejora, implementar el include de funcion.

---

## PE01/PE02 — Customizing de Esquemas y Reglas

### PE01 — Editor de Esquemas

- **Esquemas pais:** `X000` (base internacional), `DE00` (Alemania), `US00` (EEUU), etc.
- **Esquemas de cliente:** Copiar esquema pais a `ZXXX` y modificar la copia (nunca editar estandar)
- **Asignacion:** SPRO > Calculo de Nomina > Pais > Funciones de Esquema > Esquemas > Asignar esquema al area de calculo de nomina

### PE02 — Editor de Reglas de Calculo de Personal

- **Tablas usadas en PCRs:** IT (infotipos), RT (resultados de nomina), CRT (resultados acumulados), DT (dias), ZL (conceptos de tiempo)
- **Operacion de depuracion:** `MESSG` para escribir trazas en el log de nomina (PE51)
- **Simulacion:** PE00 con flag de simulacion para probar sin grabar resultados

---

## Custom Fields via Key User Extensibility

En S/4HANA, el framework de Key User Extensibility permite agregar campos a ciertas aplicaciones Fiori sin desarrollo ABAP. En HCM, las capacidades son **limitadas** comparado con otros modulos:

**Disponible:**
- Campos adicionales en algunas apps Fiori de Self-Service (ESS/MSS)
- Extension de Business Context para datos de empleado en algunos escenarios BTP/SuccessFactors

**No disponible via Key User:**
- Extension directa de infotipos PA (requiere PM01 o CI_Pxxxx)
- Campos en esquemas de nomina
- Reglas de calculo de nomina

**Alternativa recomendada:** Para S/4HANA HCM on-premise, la via estandar sigue siendo PM01 para infotipos y CI_Pxxxx para includes.

---

## Queries HCM (SAP Query / Ad Hoc Query)

### SAP Query (SQ01/SQ02/SQ03)

- **SQ02:** Definir infoset — seleccionar tablas de infotipos (PA0001, PA0002, etc.) y joins logicos
- **SQ01:** Crear query sobre el infoset — seleccionar campos, criterios de seleccion, formato de salida
- **SQ03:** Administrar grupos de usuarios con acceso a las queries
- **Area de trabajo:** Estandar (cliente-independiente) vs. cliente-especifica

### Ad Hoc Query (PAAH / S_PH9_46000172)

Herramienta para usuarios de RRHH sin conocimiento tecnico:
- Seleccion visual de campos de infotipos
- Filtros por fechas de vigencia
- Exportacion a Excel/ALV
- Acceso controlado por perfil de autorizacion `PLOG` y `P_ORGINCON`

### Logical Databases para HCM

| LDB | Uso |
|-----|-----|
| `PNP` | Seleccion de empleados por infotipos (base para la mayoria de reportes PA) |
| `PNPCE` | Version mejorada de PNP (recomendada en S/4HANA) |
| `PCH` | Objetos de gestion organizativa (O, S, C, etc.) |

**Programas con LDB PNPCE:**
```abap
REPORT zprueba_hcm.
INFOTYPES: 0001, 0002, 0008.
START-OF-SELECTION.
  GET PERNR.
    " p0001, p0002, p0008 disponibles directamente
    WRITE: pernr-pernr, p0002-vorna, p0008-bet01.
```
