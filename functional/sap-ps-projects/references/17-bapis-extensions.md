# BAPIs, Exits y Extensibilidad en SAP PS

## Introduccion

SAP PS ofrece un rico conjunto de interfaces de programacion para automatizacion, integracion y extensibilidad. En SAP S/4HANA 2023 se complementan las BAPIs clasicas y User Exits con los modernos BAdIs, Enhancement Spots y Custom Fields & Logic del SAP Fiori Extension Framework.

---

## 1. BAPIs Principales PS

### 1.1 BAPIs de Proyecto (WBS)

#### BAPI_BUS2054_CREATE_MULTI
**Funcion:** Crear cabecera de proyecto y estructura WBS en una sola llamada.

**Parametros principales:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| PROJECT | BAPI_BUS2054_HDR | Datos de cabecera del proyecto |
| WBS_ELEMENT | BAPI_BUS2054_ELEMENT_TAB | Tabla de elementos WBS |
| RETURN | BAPIRET2 | Mensajes de retorno |

**Ejemplo ABAP:**
```abap
DATA: lt_wbs    TYPE TABLE OF bapi_bus2054_element,
      lt_return TYPE TABLE OF bapiret2.

CALL FUNCTION 'BAPI_BUS2054_CREATE_MULTI'
  IMPORTING
    project    = VALUE bapi_bus2054_hdr(
                    pspid = 'P-2024-NEW'
                    post1 = 'Nuevo Proyecto'
                    vbukr = '1000'
                 )
  TABLES
    wbs_element = lt_wbs
    return      = lt_return.

IF sy-subrc = 0.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = 'X'.
ENDIF.
```

#### BAPI_BUS2054_CHANGE
**Funcion:** Modificar datos de un proyecto existente.

**Parametros:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| PROJECT_KEY | BAPI_BUS2054_KEY | Clave del proyecto (PSPID) |
| PROJECT_CHANGES | BAPI_BUS2054_HDR_UPD | Datos a actualizar |
| WBS_CHANGES | BAPI_BUS2054_ELEM_TAB_UPD | Cambios en elementos WBS |
| RETURN | BAPIRET2 | Mensajes |

#### BAPI_BUS2054_GET_DETAIL
**Funcion:** Leer datos detallados de un proyecto WBS.

**Parametros:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| PROJECT_KEY | BAPI_BUS2054_KEY | Clave (PSPID + version) |
| PROJECT | BAPI_BUS2054_HDR | Cabecera devuelta |
| WBS_ELEMENT | BAPI_BUS2054_ELEM_TAB | Elementos WBS devueltos |
| RETURN | BAPIRET2 | Mensajes |

#### BAPI_BUS2054_SET_STATUS
**Funcion:** Cambiar el status de sistema de un elemento WBS.

**Parametros:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| OBJECTKEY | BAPI_BUS2054_KEY | Clave del WBS |
| SYSSTAT | BAPI_STATUS | Status a activar/desactivar |
| RETURN | BAPIRET2 | Mensajes |

#### BAPI_BUS2054_EXISTENCECHECK
**Funcion:** Verificar si un proyecto existe.

#### Otras BAPIs de Proyecto

| BAPI | Descripcion |
|------|-------------|
| BAPI_BUS2054_GET_LIST | Listar proyectos con filtros |
| BAPI_BUS2054_DELETE | Marcar proyecto para borrado |
| BAPI_BUS2054_COPY | Copiar proyecto (similar a CJ9BS) |
| BAPI_BUS2054_SAVE | Grabar cambios pendientes |

---

### 1.2 BAPIs de Red y Actividades

#### BAPI_NETWORK_CREATE
**Funcion:** Crear una red de trabajo PS.

**Parametros:**
| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| NETWORK | BAPI_NETWORK | Datos de cabecera de red |
| ACTIVITY | BAPI_NETWORK_ACTVTY_TAB | Tabla de actividades |
| COMPONENT | BAPI_NETWORK_COMP_TAB | Componentes de red |
| RELATION | BAPI_NETWORK_RELAT_TAB | Relaciones entre actividades |
| RETURN | BAPIRET2 | Mensajes |

**Ejemplo:**
```abap
DATA: ls_network  TYPE bapi_network,
      lt_activity TYPE TABLE OF bapi_network_actvty,
      lt_return   TYPE TABLE OF bapiret2.

ls_network-ps_psp_pnr = lv_wbs_intern.  " Numero interno WBS
ls_network-netpf = 'PS01'.              " Perfil de red

APPEND VALUE #( activity = '0010'
                short_descript = 'Actividad Inicial'
                control_key = 'PS02'
                work_activity = 8 ) TO lt_activity.

CALL FUNCTION 'BAPI_NETWORK_CREATE'
  TABLES
    network    = ls_network
    activity   = lt_activity
    return     = lt_return.
```

#### BAPI_NETWORK_CHANGE
**Funcion:** Modificar datos de una red existente.

#### BAPI_NETWORK_GET_DETAIL
**Funcion:** Leer detalle de una red.

| Parametro | Tipo | Descripcion |
|-----------|------|-------------|
| NETWORK | AUFNR | Numero de red |
| NETWORK_DETAIL | BAPI_NETWORK | Datos devueltos |
| ACTIVITY | BAPI_NETWORK_ACTVTY_TAB | Actividades devueltas |
| COMPONENT | BAPI_NETWORK_COMP_TAB | Componentes devueltos |

#### BAPI_NETWORK_CONFIRM_ACTIVITY
**Funcion:** Confirmar actividad de red (equivalente a CN25).

| Parametro | Descripcion |
|-----------|-------------|
| NETWORK | Numero de red |
| ACTIVITY | Numero de actividad |
| CONF_QUANT | Cantidad confirmada |
| CONF_UNIT | Unidad de medida |
| CONF_DATE | Fecha de confirmacion |

#### BAPI_NETWORK_SET_STAT
**Funcion:** Cambiar status de una red.

| Parametro | Descripcion |
|-----------|-------------|
| NETWORK | Numero de red |
| STATUS_CHANGE | Estructura con status a activar |

#### Otras BAPIs de Red

| BAPI | Descripcion |
|------|-------------|
| BAPI_NETWORK_DELETE | Eliminar red |
| BAPI_NETWORK_COPY | Copiar red a otro proyecto |
| BAPI_NETWORK_GET_LIST | Listar redes por proyecto |
| BAPI_NETWORK_MILESTONE_CREATE | Crear hito en red |
| BAPI_NETWORK_MILESTONE_CHANGE | Modificar hito |

---

### 1.3 BAPIs de Presupuesto PS

| BAPI | Descripcion | Funcion |
|------|-------------|---------|
| BAPI_PS_BUDGET_ALLOCATE | Asignar presupuesto original | Equivalente a CJ30 |
| BAPI_PS_BUDGET_SUPPLEMENT | Agregar suplemento de presupuesto | Equivalente a CJ32 |
| BAPI_PS_BUDGET_RETURN | Devolucion de presupuesto | Equivalente a CJ33 |
| BAPI_PS_BUDGET_TRANSFER | Traspasar presupuesto entre WBS | Equivalente a CJ34 |
| BAPI_PS_BUDGET_RELEASE | Liberar presupuesto | Equivalente a CJ36 |
| BAPI_PS_BUDGET_GETDETAIL | Leer presupuesto de un WBS | Consulta |

#### BAPI_PS_BUDGET_ALLOCATE - Ejemplo
```abap
DATA: lt_return TYPE TABLE OF bapiret2.

CALL FUNCTION 'BAPI_PS_BUDGET_ALLOCATE'
  EXPORTING
    i_wbs_element = 'P-2024-001.1'
    i_fiscal_year = '2024'
    i_amount      = '500000.00'
    i_currency    = 'EUR'
  TABLES
    return        = lt_return.

CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
  EXPORTING wait = 'X'.
```

---

### 1.4 BAPIs de Liquidacion PS

| BAPI | Descripcion |
|------|-------------|
| BAPI_PS_SETTLEMENT_CREATE | Crear reglas de liquidacion |
| BAPI_PS_SETTLEMENT_CHANGE | Modificar reglas |
| BAPI_PS_SETTLEMENT_GETDETAIL | Leer reglas de liquidacion |
| BAPI_PS_SETTLEMENT_DELETE | Eliminar reglas |

---

### 1.5 BAPIs de Costes PS

| BAPI | Descripcion |
|------|-------------|
| BAPI_PS_COSTS_CREATE | Crear plan de costes |
| BAPI_PS_COSTS_CHANGE | Modificar plan de costes |
| BAPI_PS_COSTS_GETDETAIL | Leer plan de costes |

---

## 2. User Exits (CNEX)

Los User Exits de PS se agrupan bajo el prefijo CNEX. Se implementan via Enhancement Category en la transaccion CMOD.

**Activacion:**
1. Ejecutar `CMOD`
2. Crear proyecto de enhancements
3. Asignar exit points CNEX
4. Implementar en includes correspondientes

### 2.1 Exits de Proyecto / WBS

| Exit | Funcion | Momento de Ejecucion |
|------|---------|---------------------|
| **CNEX0001** | Verificacion de datos de proyecto al grabar | Antes de grabar CJ01/CJ02 |
| **CNEX0002** | Default valores en creacion de proyecto | Al iniciar CJ01 |
| **CNEX0003** | Verificacion al liberar proyecto | Antes de activar REL |
| **CNEX0004** | Verificacion al completar tecnicamente | Antes de TECO |
| **CNEX0005** | Modificar propuesta de fechas WBS | Durante scheduling |
| **CNEX0006** | Validacion de status de usuario WBS | Cambio de status usuario |
| **CNEX0007** | Verificacion al copiar proyecto | Antes de CJ9BS |
| **CNEX0008** | Post-proceso tras copiar proyecto | Despues de CJ9BS |

### 2.2 Exits de Red y Actividad

| Exit | Funcion | Momento de Ejecucion |
|------|---------|---------------------|
| **CNEX0010** | Verificacion al crear red | Antes de grabar CN21 |
| **CNEX0011** | Default valores en actividad nueva | Al agregar actividad en CN22 |
| **CNEX0012** | Verificacion al confirmar actividad | Antes de grabar CN25 |
| **CNEX0013** | Post-proceso tras confirmacion | Despues de confirmar |
| **CNEX0014** | Calculo especial de overhead en red | Durante calculo CN50 |
| **CNEX0015** | Validacion de componentes de red | Al asignar material en CN22 |

### 2.3 Exits de Presupuesto

| Exit | Funcion | Momento de Ejecucion |
|------|---------|---------------------|
| **CNEX0016** | Verificacion antes de presupuestar | Antes de CJ30/CJ32 |
| **CNEX0017** | Validacion de control de disponibilidad | Antes de verificar tolerancias |
| **CNEX0018** | Modificar calculo de disponibilidad | Durante calculo de saldo |

### 2.4 Exits de Liquidacion

| Exit | Funcion | Momento de Ejecucion |
|------|---------|---------------------|
| **CNEX0019** | Verificacion de reglas de liquidacion | Antes de CJ88 |
| **CNEX0020** | Post-proceso tras liquidacion | Despues de CJ88 |
| **CNEX0021** | Calculo de reglas dinamicas | Durante propuesta automatica |

### 2.5 Exits de Avance

| Exit | Funcion | Momento de Ejecucion |
|------|---------|---------------------|
| **CNEX0022** | Calculo especial de avance | Durante CNE1/CNE5 |
| **CNEX0023** | Validacion de porcentaje de avance | Antes de grabar confirmacion |

### 2.6 Exits de Informes

| Exit | Funcion |
|------|---------|
| **CNEX0024** | Modificar seleccion en informes PS |
| **CNEX0025** | Agregar columnas a informes PS |

---

## 3. BAdIs (Business Add-Ins)

### 3.1 BAdI PS_FIELDCHECK - Verificacion de Campos

**Descripcion:** Permite validar y modificar campos en proyectos y elementos WBS.

**Interface:** `IF_EX_PS_FIELDCHECK`

**Metodos:**

| Metodo | Descripcion |
|--------|-------------|
| `CHECK_PROJECT` | Validar datos de proyecto al grabar |
| `CHECK_WBS` | Validar datos de elemento WBS |
| `CHANGE_PROJECT` | Modificar valores de proyecto |
| `CHANGE_WBS` | Modificar valores de WBS |
| `DEFAULT_WBS` | Proponer valores por defecto en WBS nuevo |

**Ejemplo de implementacion:**
```abap
CLASS zcl_ps_fieldcheck DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_ex_ps_fieldcheck.

ENDCLASS.

CLASS zcl_ps_fieldcheck IMPLEMENTATION.

  METHOD if_ex_ps_fieldcheck~check_wbs.
    " Validar que el responsable este asignado
    IF is_prps-vernr IS INITIAL.
      APPEND VALUE #(
        type    = 'E'
        id      = 'CNEX'
        number  = '001'
        message = 'Responsable de WBS obligatorio'
      ) TO ct_return.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
```

**Activacion:**
```
SE18 → Buscar BAdI: PS_FIELDCHECK
SE19 → Crear implementacion
```

### 3.2 BAdI PROJECT_CHECK - Verificacion de Proyecto

**Descripcion:** Validaciones especificas al grabar el proyecto completo.

**Interface:** `IF_EX_PROJECT_CHECK`

**Metodos principales:**

| Metodo | Descripcion |
|--------|-------------|
| `CHECK_BEFORE_SAVE` | Verificacion antes de grabar |
| `CHECK_BEFORE_RELEASE` | Verificacion antes de REL |
| `CHECK_BEFORE_TECO` | Verificacion antes de TECO |
| `CHECK_BEFORE_CLOSE` | Verificacion antes de CLSD |

### 3.3 BAdI PS_SETTLEMENT_RULES - Reglas de Liquidacion

**Descripcion:** Modificar o generar automaticamente reglas de liquidacion.

**Interface:** `IF_EX_PS_SETTLEMENT_RULES`

**Metodos:**

| Metodo | Descripcion |
|--------|-------------|
| `PROPOSE_RULES` | Proponer reglas de liquidacion automaticas |
| `CHECK_RULES` | Validar reglas antes de grabar |
| `CHANGE_RULES` | Modificar reglas propuestas |

**Caso de uso:** Automatizar la generacion de reglas de liquidacion basandose en el tipo de proyecto, centro de coste responsable o datos del WBS.

### 3.4 BAdI PS_BUDGET_APPROVAL - Aprobacion de Presupuesto

**Descripcion:** Control del flujo de aprobacion de presupuesto (workflow).

**Interface:** `IF_EX_PS_BUDGET_APPROVAL`

**Metodos:**

| Metodo | Descripcion |
|--------|-------------|
| `START_APPROVAL` | Iniciar proceso de aprobacion |
| `GET_APPROVERS` | Obtener lista de aprobadores |
| `CHECK_APPROVAL` | Verificar estado de aprobacion |

### 3.5 BAdI CNE_PROG_CHECK - Validacion de Avance

**Descripcion:** Validar datos de confirmacion de avance.

**Interface:** `IF_EX_CNE_PROG_CHECK`

**Metodos:**
| Metodo | Descripcion |
|--------|-------------|
| `CHECK_PROGRESS` | Validar porcentaje antes de grabar |
| `CHANGE_PROGRESS` | Modificar calculo de avance |

### 3.6 BAdI CN_NETWORK_ACTV - Actividades de Red

**Descripcion:** Logica adicional en actividades de red.

**Interface:** `IF_EX_CN_NETWORK_ACTV`

**Metodos:**

| Metodo | Descripcion |
|--------|-------------|
| `CHECK_ACTIVITY` | Validar actividad al grabar |
| `CHANGE_ACTIVITY` | Modificar datos de actividad |
| `CONFIRM_ACTIVITY` | Logica extra en confirmacion |

---

## 4. Enhancement Spots

### 4.1 Enhancement Spot PS_PROJ_SAVE

**Descripcion:** Punto de mejora en el proceso de grabado de proyecto.

**Enhancement Sections:**

| Section | Momento |
|---------|---------|
| `ES_BEFORE_PROJ_SAVE` | Antes de grabar en base de datos |
| `ES_AFTER_PROJ_SAVE` | Despues de grabar exitosamente |

**Implementacion:**
```abap
ENHANCEMENT 1 ZMY_PS_PROJ_SAVE.
  " Logica personalizada antes de grabar
  IF gs_proj-pspid+0(1) <> 'P'.
    MESSAGE e001(zps) WITH 'Clave de proyecto invalida'.
  ENDIF.
ENDENHANCEMENT.
```

### 4.2 Enhancement Spot CN_NETWORK_CREATE

**Descripcion:** Punto de mejora en la creacion de redes.

### 4.3 Enhancement Spot PS_BUDGET_POST

**Descripcion:** Punto de mejora en la contabilizacion de presupuesto.

---

## 5. Custom Fields & Logic (S/4HANA Extensibility)

### 5.1 Custom Fields en WBS (CFL)

SAP S/4HANA permite agregar campos Z a los objetos PS sin modificar el codigo estandar, usando el framework **Custom Fields and Logic**.

**Transaccion:** `BUS_CUSTOM_FIELDS` o via Fiori app "Custom Fields and Logic"

**Objetos PS extensibles:**
- Cabecera de Proyecto (PROJ)
- Elemento WBS (PRPS)
- Red (NETZ)
- Actividad de Red (VORG)

**Proceso:**
1. Abrir "Custom Fields and Logic" (Fiori)
2. Seleccionar Business Context: "Project" o "WBS Element"
3. Definir campo: nombre, tipo, longitud, etiqueta
4. Activar y publicar
5. Agregar logica en "Custom Logic" si es necesario

**Resultado:** El campo aparece automaticamente en las transacciones CJ01/CJ02/CJ20N y en las BAPIs correspondientes.

### 5.2 Custom Logic para PS

La **Custom Logic** (sin codigo ABAP tradicional) permite implementar reglas de negocio simples:

```
Business Context: WBS Element
Trigger: Before Save

Condition: WBS_ELEMENT-PRART = '01' AND WBS_ELEMENT-VERAK IS INITIAL
Action: RAISE ERROR 'Responsable obligatorio para WBS tipo 01'
```

### 5.3 Key User Extensibility para Fiori PS

Las apps Fiori PS (Manage Projects, Create Project, etc.) permiten extension via:
- **Adaptation UI:** Agregar campos, reorganizar layout
- **Custom Sections:** Agregar pestanas con datos adicionales
- **Custom Actions:** Botones con logica personalizada

---

## 6. RAP APIs para PS (S/4HANA 2023)

En SAP S/4HANA 2023 algunos objetos PS estan siendo migrados a la arquitectura RAP (RESTful ABAP Programming Model) para su uso via OData V4 y ABAP Cloud.

### 6.1 Business Object I_ProjectWbsElement

**Descripcion:** Business Object RAP para elementos WBS (disponible en versiones recientes de S/4HANA).

**Entidades CDS:**
- `I_Project` — Vista de proyecto
- `I_ProjectWbsElement` — Vista de elemento WBS
- `C_ProjectWbsElement` — Vista de consumo (Fiori)

**Operaciones disponibles:**
| Operacion | Descripcion |
|-----------|-------------|
| Create | Crear elemento WBS |
| Update | Modificar elemento WBS |
| Delete | Eliminar (marcar borrado) |
| Action: Release | Liberar (REL) |
| Action: TechComplete | Completar tecnicamente (TECO) |

**Uso en ABAP Cloud:**
```abap
" Leer WBS via EML (Entity Manipulation Language)
READ ENTITIES OF i_projectwbselement
  ENTITY ProjectWbsElement
  FIELDS ( PostId Post1 PsProjectInternalId )
  WITH VALUE #( ( %key-WbsElementInternalId = lv_pspnr ) )
  RESULT DATA(lt_wbs)
  FAILED DATA(lt_failed)
  REPORTED DATA(lt_reported).
```

### 6.2 OData Services PS

| Servicio | Descripcion |
|---------|-------------|
| `PS_PROJECT_SRV` | Proyectos y WBS via OData V2 |
| `PS_NETWORK_SRV` | Redes y actividades |
| `PS_BUDGET_SRV` | Presupuesto de proyecto |
| `PS_PROGRESS_SRV` | Avance y EVM |
| `PS_SETTLEMENT_SRV` | Liquidacion |

---

## 7. Autorizaciones PS

### 7.1 Objetos de Autorizacion Clave

| Objeto Auth. | Campo | Descripcion |
|-------------|-------|-------------|
| **C_PROJ_KOK** | BUKRS, GSBER | Sociedad del proyecto |
| **C_PRPS_KOK** | PBUKR, GSBER | Sociedad del WBS |
| **C_NETZ_KOK** | WERKS | Centro de la red |
| **C_PRPS_ATV** | ACTVT | Actividades: 01=crear, 02=mod, 03=ver, 08=eliminar |
| **C_PRPS_BDG** | PSPID | Control de presupuesto por proyecto |
| **C_PROJ_CAT** | PROJT | Tipo de proyecto |

### 7.2 Roles Tipicos PS

| Rol | Contenido |
|-----|-----------|
| `SAP_PS_PROJECT_MANAGER` | Crear/modificar/liberar proyectos |
| `SAP_PS_PROJECT_CONTROLLER` | Presupuesto, costes, liquidacion |
| `SAP_PS_PROJECT_VIEWER` | Solo lectura |
| `SAP_PS_TIMESHEET_USER` | CATS y confirmaciones |

---

## 8. Integracion via RFC y API REST

### 8.1 RFC para Integracion con Sistemas Externos

Para integracion con sistemas externos (planificacion de proyectos, ERP externos, portales) se pueden usar los Function Modules BAPI como RFC remotas:

```abap
" Llamada RFC remota a SAP PS
CALL FUNCTION 'BAPI_BUS2054_GET_DETAIL'
  DESTINATION 'SAP_PROD'
  EXPORTING
    project_key = VALUE bapi_bus2054_key( pspid = 'P-2024-001' )
  IMPORTING
    project     = ls_project
  TABLES
    wbs_element = lt_wbs.
```

### 8.2 API REST OData para Integracion Fiori/BTP

Ejemplo de llamada al API OData de PS desde SAP BTP o aplicacion externa:

```http
GET /sap/opu/odata/sap/PS_PROJECT_SRV/ProjectSet?
    $filter=Pspid eq 'P-2024-001'&
    $expand=WbsElements&
    $format=json

Authorization: Basic {base64}
```

---

## 9. Tabla de Referencia - BAPIs PS Completas

| BAPI | Area | Descripcion |
|------|------|-------------|
| BAPI_BUS2054_CREATE_MULTI | Proyecto | Crear proyecto + WBS |
| BAPI_BUS2054_CHANGE | Proyecto | Modificar proyecto |
| BAPI_BUS2054_GET_DETAIL | Proyecto | Leer detalle |
| BAPI_BUS2054_GET_LIST | Proyecto | Listar proyectos |
| BAPI_BUS2054_SET_STATUS | Proyecto | Cambiar status |
| BAPI_BUS2054_COPY | Proyecto | Copiar proyecto |
| BAPI_BUS2054_DELETE | Proyecto | Marcar borrado |
| BAPI_BUS2054_EXISTENCECHECK | Proyecto | Verificar existencia |
| BAPI_NETWORK_CREATE | Red | Crear red |
| BAPI_NETWORK_CHANGE | Red | Modificar red |
| BAPI_NETWORK_GET_DETAIL | Red | Leer red |
| BAPI_NETWORK_GET_LIST | Red | Listar redes |
| BAPI_NETWORK_SET_STAT | Red | Cambiar status |
| BAPI_NETWORK_CONFIRM_ACTIVITY | Red | Confirmar actividad |
| BAPI_NETWORK_COPY | Red | Copiar red |
| BAPI_NETWORK_DELETE | Red | Eliminar red |
| BAPI_NETWORK_MILESTONE_CREATE | Hito | Crear hito |
| BAPI_NETWORK_MILESTONE_CHANGE | Hito | Modificar hito |
| BAPI_PS_BUDGET_ALLOCATE | Presupuesto | Asignar presupuesto |
| BAPI_PS_BUDGET_SUPPLEMENT | Presupuesto | Suplemento |
| BAPI_PS_BUDGET_RETURN | Presupuesto | Devolucion |
| BAPI_PS_BUDGET_TRANSFER | Presupuesto | Traspaso |
| BAPI_PS_BUDGET_RELEASE | Presupuesto | Liberar |
| BAPI_PS_BUDGET_GETDETAIL | Presupuesto | Consultar |
| BAPI_PS_COSTS_CREATE | Costes | Plan costes |
| BAPI_PS_COSTS_CHANGE | Costes | Modificar plan |
| BAPI_PS_SETTLEMENT_CREATE | Liquidacion | Crear reglas |
| BAPI_PS_SETTLEMENT_CHANGE | Liquidacion | Modificar reglas |
| BAPI_PS_SETTLEMENT_GETDETAIL | Liquidacion | Consultar reglas |
| BAPI_TRANSACTION_COMMIT | General | Confirmar transaccion |
| BAPI_TRANSACTION_ROLLBACK | General | Revertir transaccion |

---

## 10. Buenas Practicas de Extensibilidad

1. **Preferir BAdIs sobre User Exits** — Los BAdIs son orientados a objetos, mas faciles de transportar y soportados en S/4HANA Cloud.
2. **Usar Custom Fields & Logic para campos simples** — Evita modificaciones que impidan actualizaciones del sistema.
3. **Probar BAPIs en SE37 antes de integrar** — Verificar todos los parametros y el commit.
4. **Siempre llamar BAPI_TRANSACTION_COMMIT** — Las BAPIs no hacen commit automatico.
5. **Manejar errores BAPIRET2** — Verificar messages de tipo 'E' o 'A' antes del commit.
6. **Usar RAP APIs para nuevos desarrollos en S/4HANA 2023+** — Las BAPIs clasicas seran deprecadas gradualmente.
7. **Documentar exits activos** — Registrar todos los exits/BAdIs activos para facilitar upgrades.
8. **Validar autorizaciones en BAdIs** — Los BAdIs no heredan automaticamente las verificaciones de autorización.
