# Migracion de Datos PS — SAP Project System

## Indice
1. Estrategia de Migracion
2. Herramientas de Migracion
3. Objetos a Migrar y Secuencia
4. BAPIs de Migracion PS
5. S/4HANA Migration Cockpit (LTMC)
6. Secuencia de Carga Detallada
7. Validaciones Pre y Post Carga
8. Cutover Plan
9. Tratamiento de Proyectos Historicos
10. Scripts y Templates

---

## 1. Estrategia de Migracion

### 1.1 Enfoques de Migracion PS

| Enfoque | Descripcion | Cuando Usar |
|---------|-------------|-------------|
| Big Bang | Todo en una sola carga | Sistemas pequenos (<500 proyectos) |
| Phased | Por tipo de proyecto | Sistemas complejos, poco downtime |
| Cutover date | Solo proyectos activos | Historico en archivo |
| Parallel Run | Ambos sistemas en paralelo | Critico, zero tolerance |

### 1.2 Principios de Migracion PS

**Regla 1: Secuencia obligatoria**
```
Customizing → Datos maestros → Estructuras → Costes → Saldos
```

**Regla 2: Solo migrar lo necesario**
- Proyectos CERRADOS (CLSD): migrar solo saldos agregados, no detalle
- Proyectos ACTIVOS (REL/TECO): migrar estructura completa + saldos
- Proyectos HISTORICOS (>3 anos): considerar archivado o no migrar

**Regla 3: Cutover date**
- Definir fecha de corte exacta
- Costes pre-cutover → saldos iniciales agregados
- Costes post-cutover → documentos individuales

### 1.3 Mapa de Objetos PS

```
PROYECTO (BAPI_BUS2054_CREATE_MULTI)
  └── WBS ELEMENTS (incluido en mismo BAPI)
      └── PRESUPUESTO (CJ30/CJ31 o BAPI_PS_BUDGET_POST)
      └── PLAN DE COSTES (CJ40 o BAPI_PS_PLAN_POST)
      └── SALDOS INICIALES (BAPI via cuenta de apertura o FI)
      └── REGLAS LIQUIDACION (BAPI_PS_SETTLEMENT_RULE)
      └── STATUS USUARIO (BAPI_PS_STATUS_UPDATE)

RED DE PROYECTO (BAPI_NETWORK_CREATE)
  └── ACTIVIDADES (BAPI_ACTIVITY_CREATE)
      └── COMPONENTES MATERIAL (BAPI_BUS2054_CREATE_MULTI)
```

---

## 2. Herramientas de Migracion

### 2.1 Comparison de Herramientas

| Herramienta | Tipo | Pros | Contras |
|-------------|------|------|---------|
| LSMW | ABAP batch | Flexible, probado | Curva aprendizaje alta |
| LTMC/S/4 Migration Cockpit | Fiori | Guiado, templates | Solo objetos soportados |
| BAPIs + programa ABAP | Programacion | Control total | Requiere ABAP dev |
| BAPI_BUS2054_CREATE_MULTI | BAPI directa | Estandar SAP | Complejo, muchos campos |
| IDocs | Integracion | Estandar EDI | Complejo configurar |
| Migration Object Modeler | Model-based | Reutilizable | Solo S/4HANA |

### 2.2 LSMW — Legacy System Migration Workbench

**Transaccion:** `LSMW`

**Proceso LSMW para PS:**
```
1. Crear proyecto → Subproyecto → Objeto de conversion
2. Seleccionar metodo: BAPI / Batch Input / Direct Input
3. Definir estructura de fuente (layout del CSV/Excel)
4. Definir estructura de destino (campos BAPI)
5. Mapear campos fuente → destino
6. Transformaciones: reglas, conversiones de dominio
7. Especificar archivos de fuente de datos
8. Ejecutar en modo simulacion → revisar errores
9. Ejecutar real
```

**Objeto LSMW para proyectos:**
- Business Object: BUS2054 (Project)
- Method: CREATE_MULTI

### 2.3 S/4HANA Migration Cockpit (LTMC)

**Transaccion:** `LTMC` o app Fiori "Migration Cockpit"

**Objetos PS disponibles:**
| Objeto | Nombre en LTMC |
|--------|----------------|
| Proyecto WBS | "Project" (Basic WBS) |
| Presupuesto | "Project Budget" |
| Plan costes | "Project Cost Plan" |

**Proceso LTMC:**
```
1. LTMC → Create Migration Project
2. Seleccionar objetos a migrar (Project, Budget, etc.)
3. Download template Excel por objeto
4. Rellenar template con datos fuente
5. Upload del Excel
6. Simulate → revisar errores
7. Migrate → carga real
8. Review → revisar errores de carga
```

**Template Excel — Proyecto (campos principales):**
```
Columna A: PROJECT_ID (obligatorio)
Columna B: PROJECT_DESCRIPTION
Columna C: COMPANY_CODE
Columna D: PROJECT_TYPE
Columna E: PROJECT_START_DATE (YYYYMMDD)
Columna F: PROJECT_END_DATE
Columna G: RESPONSIBLE_PERSON
...
```

---

## 3. Objetos a Migrar y Secuencia

### 3.1 Secuencia Obligatoria

```
FASE 1: CUSTOMIZING (debe estar listo antes de migrar)
  └── Perfiles de proyecto (OPSA)
  └── Mascaras de codificacion (OPSK)
  └── Perfiles de presupuesto (OPS9)
  └── Perfiles de liquidacion (OKO7)
  └── Perfiles de status (BS02)
  └── Tipos de red (OPUU)

FASE 2: DATOS MAESTROS DEPENDIENTES
  └── Centros de coste (KS01) - ya existentes
  └── Activos fijos AuC (AS01) - crear si aplica
  └── Clientes/Deudores (XD01) - ya existentes

FASE 3: PROYECTOS Y WBS
  └── BAPI_BUS2054_CREATE_MULTI
  └── Orden: proyecto padre → WBS nivel 1 → WBS nivel 2 → ...

FASE 4: REDES DE PROYECTO
  └── BAPI_NETWORK_CREATE
  └── BAPI_ACTIVITY_CREATE (actividades por red)

FASE 5: DATOS FINANCIEROS
  └── Presupuesto (CJ30/BAPI_PS_BUDGET_POST)
  └── Plan de costes (CJ40/BAPI_PS_PLAN_POST)
  └── Saldos iniciales (via FI document o BAPI)

FASE 6: STATUS Y CONFIGURACION
  └── Reglas de liquidacion (BAPI_PS_SETTLEMENT_RULE)
  └── Status usuario inicial
  └── Liberacion de proyectos (status REL)
```

### 3.2 Pre-condiciones por Objeto

| Objeto | Pre-condiciones |
|--------|----------------|
| Proyecto | Perfil de proyecto configurado |
| WBS | Proyecto padre creado |
| Red | WBS asignada creada |
| Actividad | Red creada |
| Presupuesto | WBS con indicador de presupuesto (PRAJI) |
| Plan costes | WBS con indicador de planificacion (BELKZ) |
| Regla liquidacion | WBS creado, receptor existe |
| Status usuario | Perfil de status asignado |

---

## 4. BAPIs de Migracion PS

### 4.1 BAPI_BUS2054_CREATE_MULTI — Crear Proyecto con WBS

**Descripcion:** BAPI principal para crear proyectos completos con estructura WBS.

**Parametros principales:**

```abap
CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI'
  TABLES
    i_project_definition     = lt_project_def   " Cabecera proyecto
    i_wbs_element            = lt_wbs_elements   " Elementos WBS
    i_project_def_texts      = lt_proj_texts     " Textos
    i_project_coding_masks   = lt_coding_masks   " Mascara codificacion
    o_project_definition     = lt_proj_created   " Resultado creacion
    o_wbs_element            = lt_wbs_created    " WBS creados
    return                   = lt_return.        " Mensajes

" Estructura i_project_definition (BAPI_PS_PROJECT_DEFINITION_NEW):
" PSPID           → ID de proyecto (externo)
" POST1           → Descripcion
" PLFAZ           → Fecha inicio plan (YYYYMMDD)
" PLSEZ           → Fecha fin plan
" VERNA           → Responsable
" PROFL           → Perfil de proyecto
" BUKRS           → Sociedad
" WERKS           → Centro
" PSPRI           → Prioridad
```

**Estructura WBS (BAPI_PS_WBS_ELEMENT_NEW):**
```abap
" Campos de cada WBS element:
" PSPID           → ID del proyecto padre
" POSID           → ID del WBS (externo completo)
" POST1           → Descripcion
" PROJK           → Tipo de objeto WBS
" PLFAZ/PLSEZ     → Fechas
" FAKKZ           → Indicador elemento facturacion ('X')
" PRAJI           → Indicador elemento presupuesto ('X')
" BELKZ           → Indicador elemento planificacion ('X')
" STUFE           → Nivel jerarquico (1, 2, 3...)
" VERNA           → Responsable
" KOSTL           → Centro de coste
" PRCTR           → Centro de beneficio
```

**Ejemplo de uso:**

```abap
DATA: lt_project_def  TYPE TABLE OF bapi_ps_project_definition_new,
      lt_wbs_elements TYPE TABLE OF bapi_ps_wbs_element_new,
      lt_return       TYPE TABLE OF bapiret2.

" Cabecera del proyecto
APPEND VALUE #(
  pspid  = 'INV-2024-001'
  post1  = 'Ampliacion Planta Barcelona'
  plfaz  = '20240101'
  plsez  = '20241231'
  profl  = 'STD001'
  bukrs  = '1000'
  werks  = '1000'
  verna  = 'JMARTINEZ'
) TO lt_project_def.

" WBS nivel 1
APPEND VALUE #(
  pspid  = 'INV-2024-001'
  posid  = 'INV-2024-001.ING'
  post1  = 'Fase de Ingenieria'
  stufe  = 2
  praji  = 'X'    " Elemento de presupuesto
  belkz  = 'X'    " Elemento de planificacion
) TO lt_wbs_elements.

" WBS nivel 2
APPEND VALUE #(
  pspid  = 'INV-2024-001'
  posid  = 'INV-2024-001.ING.DIS'
  post1  = 'Diseno'
  stufe  = 3
  belkz  = 'X'
) TO lt_wbs_elements.

CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI'
  TABLES
    i_project_definition = lt_project_def
    i_wbs_element        = lt_wbs_elements
    return               = lt_return.

" Verificar errores
IF lt_return[] CA 'EA'.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
  " Gestionar errores
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = 'X'.
ENDIF.
```

### 4.2 BAPI_NETWORK_CREATE — Crear Red

```abap
CALL FUNCTION 'BAPI_NETWORK_CREATE'
  EXPORTING
    network_type         = 'PS01'    " Tipo de red
    plant                = '1000'    " Centro
    wbs_element          = 'INV-2024-001.ING'  " WBS asignada
    basic_start_date     = '20240201'
    basic_end_date       = '20240630'
  IMPORTING
    network              = lv_network_id
  TABLES
    return               = lt_return.
```

### 4.3 BAPI_ACTIVITY_CREATE — Crear Actividades

```abap
CALL FUNCTION 'BAPI_ACTIVITY_CREATE'
  EXPORTING
    network              = lv_network_id
    activity             = '0010'
    short_description    = 'Ingenieria civil'
    control_key          = 'PS01'
    work_center          = 'WC_CIVIL'
    plant                = '1000'
    normal_duration      = 30
    unit_for_duration    = 'TAG'    " Dias
    basic_start_date     = '20240201'
    basic_end_date       = '20240302'
  TABLES
    return               = lt_return.
```

### 4.4 BAPI_PS_BUDGET_POST — Aprobar Presupuesto

```abap
DATA: lt_budget_wbs TYPE TABLE OF ps_bapi_bud_item_wbs.

APPEND VALUE #(
  wbs_element   = 'INV-2024-001.ING'
  budget_year   = '2024'
  budget_period = 'TOTAL'     " TOTAL o ANNUAL
  budget_type   = 'ORIGINAL'  " Presupuesto original
  budget        = '500000.00'
  currency      = 'EUR'
) TO lt_budget_wbs.

CALL FUNCTION 'BAPI_PS_BUDGET_POST'
  EXPORTING
    documenttype   = 'KOBU'
    postingdate    = sy-datum
    project        = 'INV-2024-001'
  TABLES
    wbs_elements   = lt_budget_wbs
    return         = lt_return.
```

### 4.5 BAPI_PS_SETTLEMENT_RULE — Crear Regla de Liquidacion

```abap
CALL FUNCTION 'BAPI_PS_SETTLEMENT_RULE'
  EXPORTING
    wbs_element           = 'INV-2024-001.ING'
    distribution_type     = 'PER'    " PER o FUL
  TABLES
    settlement_receivers  = lt_receivers
    return                = lt_return.

" Estructura receptor (PS_BAPI_SETTLEMENT_RECEIVER):
" RECEIVER_CATEGORY = 'KS' (CoCosto), 'AN' (Activo), 'GL' (CuMayor)
" RECEIVER           = 'KOSTL_ID' o 'ANLNR'
" PERCENTAGE        = 100 (si es un solo receptor)
```

---

## 5. S/4HANA Migration Cockpit — Proceso Detallado

### 5.1 Configuracion Inicial LTMC

```
Transaccion: LTMC
1. "Create Migration Project"
   - Nombre del proyecto de migracion
   - Sistema destino: S/4HANA actual
   - Type: S/4HANA (on-prem o cloud)

2. "Add Migration Objects"
   - Project (PS) → proyecto basico con WBS
   - Project Budget → presupuesto
   - Project Cost Plan → plan de costes

3. Por objeto: "Download Template"
   → Archivo Excel con columnas predefinidas
```

### 5.2 Rellenar Template Excel

**Hoja "Project":**
```
MANDATORY FIELDS:
- PROJECT_ID: identificador unico (max 24 chars)
- COMPANY_CODE: sociedad (4 chars)

OPTIONAL BUT IMPORTANT:
- PROJECT_DESCRIPTION: descripcion larga
- PROJECT_TYPE: tipo de proyecto
- PROJECT_START_DATE: formato YYYYMMDD
- PROJECT_END_DATE: formato YYYYMMDD
- RESPONSIBLE_PERSON: ID usuario SAP
- PROJECT_PROFILE: perfil proyecto (must exist in system)
```

**Hoja "WBS_Element":**
```
MANDATORY FIELDS:
- PROJECT_ID: referencia al proyecto padre
- WBS_ELEMENT: ID completo (incluye prefijo proyecto)
- WBS_DESCRIPTION: descripcion

CONTROL FIELDS:
- IS_BILLING_ELEMENT: X si es elem. facturacion
- IS_BUDGET_ELEMENT: X si lleva presupuesto
- IS_PLANNING_ELEMENT: X si es elem. planificacion
- HIERARCHY_LEVEL: nivel (2=primer nivel WBS, etc.)
```

### 5.3 Proceso de Carga LTMC

```
Upload del Excel:
  1. LTMC → seleccionar objeto → "Upload Data"
  2. Seleccionar archivo Excel
  3. Mapear hojas a tablas (si multiples hojas)

Simulate (OBLIGATORIO):
  1. "Simulate" → proceso de validacion
  2. Revisar:
     - Errores (E): bloquean la carga
     - Advertencias (W): no bloquean pero revisar
  3. Exportar log de errores a Excel
  4. Corregir en Excel fuente
  5. Re-upload y re-simulate hasta 0 errores

Migrate (carga real):
  1. "Migrate" → carga real en sistema
  2. Proceso puede tardar segun volumen
  3. Log de resultado disponible al terminar
  4. Exportar errores si los hay

Review:
  1. Verificar datos cargados en SAP
  2. Transacciones: CJ03, CJ20N, CN41
  3. Comparar conteos: fuente vs destino
```

---

## 6. Secuencia de Carga Detallada

### 6.1 Cronograma de Carga Tipico (Proyecto Mediano)

```
DIA -30: Preparacion
  □ Customizing completado y validado
  □ Datos fuente extraidos y limpiados
  □ Templates preparados
  □ Entorno QA listo para pruebas

DIA -15: Prueba completa en QA
  □ Carga completa en QA
  □ Validacion de datos
  □ Identificar y corregir errores
  □ Documento de errores conocidos

DIA -7: Ensayo de cutover
  □ Simular carga en tiempo real
  □ Medir tiempo de cada fase
  □ Documentar plan de contingencia

DIA -2: Preparacion de cutover
  □ Freeze de datos en sistema origen
  □ Extraccion final de datos
  □ Preparar archivos de carga

DIA 0: CUTOVER
  □ Sistema origen: modo solo lectura
  □ FASE 1: Customizing (2h)
  □ FASE 2: Maestros (4h)
  □ FASE 3: Proyectos/WBS (6h)
  □ FASE 4: Redes (3h)
  □ FASE 5: Financiero (4h)
  □ FASE 6: Status y config (2h)
  □ Validacion final (4h)
  □ GO LIVE
```

### 6.2 Control de Carga por Fases

Para cada fase, usar tabla de control:

```
| Objeto          | #Fuente | #Cargado | #Error | Estado |
|-----------------|---------|----------|--------|--------|
| Proyectos       |     342 |      340 |      2 | ERROR  |
| WBS Elements    |   4,521 |    4,521 |      0 | OK     |
| Redes           |     189 |      189 |      0 | OK     |
| Actividades     |   2,340 |    2,340 |      0 | OK     |
| Presupuesto     |     280 |      280 |      0 | OK     |
| Plan Costes     |   1,200 |    1,195 |      5 | WARN   |
| Reglas Liquid.  |     321 |      321 |      0 | OK     |
```

---

## 7. Validaciones Pre y Post Carga

### 7.1 Validaciones Pre-Carga (QA Gate)

```abap
" Verificar que todos los proyectos padre existen
" antes de cargar WBS
SELECT COUNT(*) FROM PROJ
WHERE PSPID IN (SELECT DISTINCT PSPID_PADRE FROM ZMIG_WBS_DATA)
→ Debe coincidir con # proyectos unicos en fuente

" Verificar perfiles de proyecto existen
SELECT COUNT(*) FROM T_PROJECT_PROFILE
WHERE PROFL IN (SELECT DISTINCT PROFL FROM ZMIG_PROJECT_DATA)
→ Todos los perfiles deben existir

" Verificar mascaras de codificacion
SELECT * FROM T400A
WHERE MANDT = SY-MANDT
→ Verificar que los IDs de WBS cumplen la mascara
```

### 7.2 Query Post-Carga: Conteos

```sql
-- Verificar conteos post-carga
SELECT
    'Proyectos'     AS Objeto,
    COUNT(*)        AS Total_Cargado
FROM PROJ
WHERE ERDAT = :fecha_carga

UNION ALL

SELECT
    'WBS Elements',
    COUNT(*)
FROM PRPS
WHERE ERDAT = :fecha_carga

UNION ALL

SELECT
    'Con Presupuesto',
    COUNT(DISTINCT prps.PSPNR)
FROM PRPS
JOIN BPGE ON PRPS.OBJNR = BPGE.OBJNR
    AND BPGE.VORGA = 'KOBU'
WHERE PRPS.ERDAT = :fecha_carga
```

### 7.3 Reconciliacion de Saldos

```sql
-- Comparar saldos pre/post carga
-- (Requiere tabla de control ZPS_SALDOS_ORIGEN con datos fuente)
SELECT
    orig.POSID,
    orig.SALDO_PLAN         AS Plan_Origen,
    COALESCE(rps.Plan_SAP, 0) AS Plan_SAP,
    orig.SALDO_REAL         AS Real_Origen,
    COALESCE(act.Real_SAP, 0) AS Real_SAP,
    ABS(orig.SALDO_PLAN - COALESCE(rps.Plan_SAP, 0)) AS Diferencia_Plan,
    ABS(orig.SALDO_REAL - COALESCE(act.Real_SAP, 0)) AS Diferencia_Real
FROM ZPS_SALDOS_ORIGEN AS orig
LEFT JOIN (
    SELECT OBJNR, SUM(WKBTR) AS Plan_SAP
    FROM RPSCO WHERE WRTTP = '01'
    GROUP BY OBJNR
) AS rps ON orig.OBJNR = rps.OBJNR
LEFT JOIN (
    SELECT PSPNR, SUM(HSL) AS Real_SAP
    FROM ACDOCA WHERE PSPNR <> ''
    GROUP BY PSPNR
) AS act ON orig.PSPNR = act.PSPNR
WHERE ABS(orig.SALDO_PLAN - COALESCE(rps.Plan_SAP, 0)) > 0.01
   OR ABS(orig.SALDO_REAL - COALESCE(act.Real_SAP, 0)) > 0.01
ORDER BY Diferencia_Real DESC
```

---

## 8. Cutover Plan

### 8.1 Criterios de GO / NO-GO

**GO si:**
```
□ Proyectos activos cargados: >= 99%
□ Diferencia de saldos: < 0.01 EUR por proyecto
□ Todos los proyectos criticos: 100%
□ Tiempo de cutover: dentro de ventana
□ Tests de integracion: PASADOS
□ Usuarios clave: disponibles
□ Rollback plan: documentado
```

**NO-GO si:**
```
□ Proyectos activos cargados: < 95%
□ Diferencias de saldos: > 1,000 EUR total
□ Proyectos criticos faltantes: cualquiera
□ Tiempo excedido: > 110% de lo planificado
□ Errores criticos en integracion
```

### 8.2 Plan de Rollback

Si se decide NO-GO durante cutover:
```
1. Detener cargas inmediatamente
2. Notificar a equipo de proyecto y sponsor
3. Si ya se cargo parcialmente:
   → Ejecutar eliminacion de datos via ZMIG_ROLLBACK (programa ABAP)
   → O: usar punto de restauracion del sistema (si disponible)
4. Sistema origen: volver a modo normal
5. Analizar errores
6. Replantear fecha de cutover
7. Documentar lecciones aprendidas
```

---

## 9. Tratamiento de Proyectos Historicos

### 9.1 Clasificacion de Proyectos

| Clase | Criterio | Estrategia |
|-------|----------|------------|
| Activo | Status REL, costes en 2024 | Migrar completo |
| En cierre | Status TECO, sin actividad 2024 | Migrar estructura + saldos |
| Cerrado reciente | Status CLSD, < 3 anos | Migrar solo saldos resumidos |
| Historico | Status CLSD, > 3 anos | No migrar (archivo) |
| Cancelado | Status DLTD | No migrar |

### 9.2 Migracion de Saldos Resumidos (Proyectos Cerrados)

Para proyectos cerrados, en lugar de migrar cada documento:

```
Enfoque: Documento de apertura de saldo
1. Crear el proyecto + WBS en SAP (estructura)
2. Aplicar status CLSD directamente
3. Crear documento FI con imputacion al WBS (saldo total)
   → Cuenta: cuenta de apertura de saldo migrado
   → Importe: saldo total del proyecto en sistema origen
4. Ejecutar liquidacion (CJ8G) para cerrar saldo
5. Verificar saldo = 0 en WBS
```

### 9.3 Archivo de Proyectos Historicos

Para proyectos muy antiguos (> 5 anos, cerrados):
```
Objeto de archivado: PS_PROJECT
Transaccion: SARA

Pre-requisitos:
  - Status: CLSD (cerrado)
  - Saldo = 0 (liquidado)
  - Sin documentos FI abiertos
  - Periodo de retencion cumplido

Proceso:
  SARA → Objeto PS_PROJECT
       → Preprocessing → ejecutar
       → Archive Write → ejecutar
       → Postprocessing → ejecutar (borra de tablas activas)
```

---

## 10. Scripts y Templates

### 10.1 Programa ABAP de Carga Masiva (Template)

```abap
REPORT zmig_ps_project_load.
" ============================================================
" Programa de carga masiva de proyectos PS
" ============================================================
TABLES: proj, prps.

TYPES: BEGIN OF ty_source,
  pspid TYPE pspid,   " ID proyecto
  posid TYPE posid,   " WBS ID
  post1 TYPE post1,   " Descripcion
  stufe TYPE stufe,   " Nivel
  plfaz TYPE plfaz,   " Fecha inicio
  plsez TYPE plsez,   " Fecha fin
  profl TYPE profl,   " Perfil proyecto
  bukrs TYPE bukrs,   " Sociedad
  fakkz TYPE fakkz,   " Elem facturacion
  praji TYPE praji,   " Elem presupuesto
  belkz TYPE belkz,   " Elem planificacion
END OF ty_source.

DATA: lt_source      TYPE TABLE OF ty_source,
      lt_project_def TYPE TABLE OF bapi_ps_project_definition_new,
      lt_wbs_elems   TYPE TABLE OF bapi_ps_wbs_element_new,
      lt_return      TYPE TABLE OF bapiret2,
      lv_error_count TYPE i VALUE 0.

" 1. Leer datos de tabla staging Z
SELECT * FROM zmig_ps_source INTO TABLE @lt_source.

" 2. Separar proyectos y WBS
DATA(lt_projects) = lt_source.
DELETE lt_projects WHERE posid <> pspid.  " Solo cabeceras

DATA(lt_wbs) = lt_source.
DELETE lt_wbs WHERE posid = pspid.  " Solo WBS

" 3. Cargar por proyecto (agrupa WBS del mismo proyecto)
LOOP AT lt_projects INTO DATA(ls_proj).
  CLEAR: lt_project_def, lt_wbs_elems, lt_return.

  " Armar cabecera
  APPEND VALUE #(
    pspid  = ls_proj-pspid
    post1  = ls_proj-post1
    plfaz  = ls_proj-plfaz
    plsez  = ls_proj-plsez
    profl  = ls_proj-profl
    bukrs  = ls_proj-bukrs
  ) TO lt_project_def.

  " Armar WBS del proyecto
  LOOP AT lt_wbs INTO DATA(ls_wbs)
       WHERE pspid = ls_proj-pspid.
    APPEND VALUE #(
      pspid  = ls_wbs-pspid
      posid  = ls_wbs-posid
      post1  = ls_wbs-post1
      stufe  = ls_wbs-stufe
      plfaz  = ls_wbs-plfaz
      plsez  = ls_wbs-plsez
      fakkz  = ls_wbs-fakkz
      praji  = ls_wbs-praji
      belkz  = ls_wbs-belkz
    ) TO lt_wbs_elems.
  ENDLOOP.

  " Llamar BAPI
  CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI'
    TABLES
      i_project_definition = lt_project_def
      i_wbs_element        = lt_wbs_elems
      return               = lt_return.

  " Procesar resultado
  IF lt_return[] CA 'EA'.
    ADD 1 TO lv_error_count.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    " Log error en tabla Z
    INSERT zmig_ps_errors FROM VALUE #(
      pspid    = ls_proj-pspid
      messages = lt_return
      datum    = sy-datum
    ).
  ELSE.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = 'X'.
    " Log exito
  ENDIF.

ENDLOOP.

WRITE: / |Errores: { lv_error_count }|.
```

### 10.2 Checklist de Migracion PS

```
PRE-MIGRACION:
  □ Customizing PS completo y validado en sistema destino
  □ Datos maestros CO/FI disponibles (CoCosto, activos, clientes)
  □ Datos extraidos del sistema fuente y validados
  □ Templates preparados por objeto
  □ Plan de carga aprobado por sponsor
  □ Ventana de downtime acordada
  □ Equipo de soporte disponible (FI, CO, PS, Basis)
  □ Plan de rollback documentado

DURANTE MIGRACION:
  □ Proyectos cargados → verificar conteo
  □ WBS cargados → verificar jerarquia
  □ Redes cargadas → verificar actividades
  □ Presupuesto cargado → verificar vs fuente
  □ Plan costes → verificar totales
  □ Saldos iniciales → reconciliacion
  □ Status aplicados → verificar transiciones
  □ Reglas liquidacion → verificar receptores

POST-MIGRACION:
  □ Reconciliacion de saldos: < tolerancia definida
  □ Tests de usuario: completados
  □ Reports PS funcionan correctamente
  □ Control presupuesto funcionando
  □ Usuarios formados
  □ Documentacion actualizada
  □ Hiper-care planificado (2 semanas)
```

---

*Referencia: SAP S/4HANA 2023 | Migration Guide for SAP Project System*
*SAP Note 2332595 — PS Data Migration Best Practices*
*BAPI Reference: Function Module BAPI_BUS2054_CREATE_MULTI*
