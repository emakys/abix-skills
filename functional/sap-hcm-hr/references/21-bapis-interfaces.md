# BAPIs e Interfaces HR

Referencia de BAPIs, módulos de función, IDocs y patrones de integración para SAP HCM S/4HANA 2023.

---

## BAPIs Principales

### BAPI_EMPLOYEE_GETDATA
Lee datos maestros de uno o varios empleados.

**Parámetros de entrada:**
| Parámetro | Tipo | Descripción |
|---|---|---|
| EMPLOYEENUMBER | PERNR | Número de personal |
| EMPLOYEENUMBERRANGE | BAPIP0002_RAN | Rango de números |
| INFOTYPESLIST | BAPIINFTY | Infotipos a leer (tabla) |
| BEGDA | DATUM | Fecha inicio validez |
| ENDDA | DATUM | Fecha fin validez |

**Parámetros de salida:**
- Tablas por infotipo: `PERSONALDATA` (IT0002), `ORGASSIGNMENT` (IT0001), `ADDRESSES` (IT0006), etc.
- `RETURN` — Mensajes de retorno (E=error, W=aviso, S=éxito)

**Ejemplo de uso ABAP:**
```abap
DATA: lt_infotypes TYPE TABLE OF bapiinfty,
      ls_infotype  TYPE bapiinfty,
      lt_personaldata TYPE TABLE OF bapip0002,
      lt_return    TYPE TABLE OF bapiret2.

ls_infotype-infotype = '0002'.
APPEND ls_infotype TO lt_infotypes.
ls_infotype-infotype = '0001'.
APPEND ls_infotype TO lt_infotypes.

CALL FUNCTION 'BAPI_EMPLOYEE_GETDATA'
  EXPORTING
    employeenumber = '00012345'
    begda          = sy-datum
    endda          = sy-datum
  TABLES
    infotypeslist  = lt_infotypes
    personaldata   = lt_personaldata
    return         = lt_return.
```

---

### BAPI_HRMASTER_SAVE_REPL_MULT
Graba o replica datos maestros HR para múltiples empleados. Utilizada principalmente en escenarios de replicación ALE/IDoc.

**Casos de uso:**
- Replicación de datos entre sistemas SAP (ERP → S/4HANA)
- Integración con SuccessFactors Employee Central via middleware
- Carga masiva de datos maestros desde sistemas externos

**Parámetros clave:**
| Parámetro | Descripción |
|---|---|
| NOBATCHINPUT | Sin batch input (procesamiento directo) |
| TESTRUN | Modo simulación sin grabación real |
| LOGSYSTEM | Sistema lógico origen |
| DATA_RECORD | Tabla con registros de infotipos a grabar |
| OBJECT_IDS | Tabla con números de personal |
| RETURN | Mensajes de retorno |

---

### BAPI_ORGUNITEXT_DATA_GET
Obtiene datos de unidades organizativas del plan organizativo.

**Parámetros de entrada:**
| Parámetro | Descripción |
|---|---|
| EVALUATE_DATE | Fecha de evaluación |
| OBJECT_ID | ID de unidad organizativa (OBJID) |
| OBJECT_TYPE | Tipo de objeto (O, S, P, etc.) |
| DEPTH | Profundidad jerárquica (0=todos) |

**Parámetros de salida:**
- `ORGUNIT_DATA_TABLE` — Datos de unidades organizativas
- `ORGUNIT_LIST` — Lista de objetos en la jerarquía

---

## Módulo de Función: HR_INFOTYPE_OPERATION

El módulo de función central para crear, modificar, copiar y borrar registros de infotipo desde ABAP.

```abap
CALL FUNCTION 'HR_INFOTYPE_OPERATION'
  EXPORTING
    infty         = '0002'        " Infotipo
    number        = lv_pernr      " Número de personal
    subtype       = ' '           " Subtipo
    objectid      = ' '           " Tipo de objeto (PA=vacío)
    lockindicator = ' '           " Indicador de bloqueo
    validitybegin = sy-datum      " Inicio validez
    validityend   = '99991231'    " Fin validez
    record        = ls_p0002      " Estructura del infotipo
    operation     = 'INS'         " INS/MOD/DEL/COP/DIS
    tclas         = 'A'           " Clase de transacción
  IMPORTING
    return        = ls_return
  EXCEPTIONS
    illegal_operation       = 1
    wrong_parameters        = 2
    time_constraint_error   = 3
    document_not_found      = 4
    OTHERS                  = 5.
```

**Valores del parámetro OPERATION:**
| Valor | Descripción |
|---|---|
| INS | Insertar nuevo registro |
| MOD | Modificar registro existente |
| DEL | Borrar registro |
| COP | Copiar registro |
| DIS | Delimitar (fijar fecha fin) |
| LIS | Listar registros existentes |

**Consideraciones importantes:**
- Siempre verificar `ls_return-type` después de la llamada
- Para modificaciones en nómina retroactiva, usar en combinación con `HR_MAINTAIN_MASTERDATA`
- En S/4HANA, preferir las APIs OData equivalentes para integraciones externas

---

## RFC Destinations

Las conexiones RFC son la base para la comunicación entre sistemas SAP y con sistemas externos.

**Transacción:** SM59

### Tipos de Destinos RFC para HCM
| Tipo | Descripción | Uso HCM |
|---|---|---|
| 3 (ABAP) | Conexión a otro sistema SAP | ALE entre sistemas SAP |
| H (HTTP) | Conexión HTTP/HTTPS | SuccessFactors, CPI |
| L (Liberado) | Sistema local | BAPIs locales sin red |
| G (HTTP externo) | Servicios REST externos | APIs de terceros |

**Destinos estándar en paisajes HCM:**
- `SUCC_XXX` — Destino a SuccessFactors (configurado en `/SHCM/HRASSISYSTEM`)
- `CPI_XXX` — Destino a SAP Integration Suite (Cloud Platform Integration)
- `EC_XXX` — Destino directo a Employee Central (para APIs OData)

---

## Distribución ALE — IDocs HRMD

ALE (Application Link Enabling) permite la replicación de datos maestros HR entre sistemas SAP via IDocs.

### Tipos de IDoc HRMD

| Tipo IDoc | Descripción | Infotipos incluidos |
|---|---|---|
| HRMD_A01 | Datos personales | IT0001, IT0002, IT0006, IT0007 |
| HRMD_A02 | Datos de nómina | IT0008, IT0014, IT0015 |
| HRMD_A03 | Tiempos y ausencias | IT0041, IT2001, IT2002 |
| HRMD_A04 | Datos bancarios | IT0009 |
| HRMD_A05 | Gestión organizativa | IT1000, IT1001 (objetos OM) |
| HRMD_A06 | Datos cualitativos | IT0024 (cualificaciones) |
| HRMD_A07 | Comunicaciones | IT0105 |
| HRMD_A08 | Beneficios | IT0167-IT0170 |
| HRMD_A09 | Solicitantes (Recruitment) | IT4xxx |

### Configuración ALE para HCM
1. **BD64** — Modelo de distribución: definir partners y mensajes a distribuir
2. **WE20** — Acuerdos de partner: configurar proceso de IDoc por partner
3. **PFAL** — Distribución de plan organizativo (OM) via ALE
4. **RHALEINI** — Programa inicial de distribución HR (envío masivo inicial)
5. **RHALECOR** — Consistencia y corrección de distribuciones ALE HR

### Mensajes ALE Relevantes
| Mensaje | Descripción |
|---|---|
| HRMD_A | Datos maestros de personal |
| HRMD_B | Datos maestros OM (plan de puestos) |
| SYNCH | Sincronización general |

---

## Integración con SAP SuccessFactors

### SAP Integration Suite (Cloud Platform Integration — CPI)

El middleware estándar para la integración bidireccional entre S/4HANA HCM y SuccessFactors.

**Paquetes de integración estándar (Integration Advisor / pre-built iFlows):**
- `SAP_SuccessFactors_Employee_Central_Integration`
- Disponibles en SAP Business Accelerator Hub: `api.sap.com`

**Flujos de integración principales:**
| iFlow | Dirección | Descripción |
|---|---|---|
| Replication of Employees from SAP S/4HANA to SAP SuccessFactors | S/4 → SF | Empleados y datos maestros |
| Replication of Cost Centers from SAP S/4HANA to SAP SuccessFactors | S/4 → SF | Centros de coste |
| Replication of Employees from SAP SuccessFactors to SAP S/4HANA | SF → S/4 | Nuevas contrataciones/cambios EC |
| Replication of Payroll Data from SAP S/4HANA to SAP SuccessFactors | S/4 → SF | Resultados de nómina para MDF |

**Configuración en S/4HANA:**
- Transacción `/SHCM/HRASSISYSTEM` — Parámetros de sistema SuccessFactors
- Transacción `/SHCM/HRASSIMAPPING` — Mapeo de campos SAP ↔ SuccessFactors

---

## Employee Central Integration (ECI)

### Modelo de Replicación

La integración entre SuccessFactors Employee Central y SAP S/4HANA sigue el modelo:

```
SuccessFactors EC (sistema de registro RRHH)
         ↓  (via CPI / Integration Suite)
   SAP S/4HANA HCM (datos maestros locales)
         ↓
   Nómina S/4HANA / Gestión de tiempos
```

### Modelos de Despliegue
| Modelo | Descripción |
|---|---|
| Side-by-Side Payroll | EC como sistema de RRHH + nómina en S/4HANA |
| Full Cloud HXM | EC + SF Payroll (sin S/4HANA para RRHH) |
| Core Hybrid | PA/OM en S/4HANA + Talent Management en SF |

### API OData Employee Central
SuccessFactors expone APIs OData v2/v4 para consulta y manipulación de datos:
- Endpoint base: `https://{tenant}.successfactors.com/odata/v2/`
- Entidades principales: `PerPerson`, `EmpEmployment`, `EmpJob`, `EmpPayCompensation`
- Autenticación: OAuth 2.0 (SAML Bearer Assertion recomendado para S2S)

---

## Consultas HR (Query / Ad-Hoc Reporting)

### Transacciones de Query Estándar
| Transacción | Descripción |
|---|---|
| SQ01 | SAP Query — definición de queries |
| SQ02 | InfoSets — áreas funcionales de datos |
| SQ03 | Grupos de usuarios para queries |
| SQVI | QuickViewer — queries rápidas sin grupo de usuarios |
| PC00_M99_CLSTB2 | Consulta de clúster B2 (resultados de nómina) |
| PC00_M99_CLSTA1 | Consulta de clúster A1 (datos de tiempos) |

### InfoSets Estándar Relevantes
| InfoSet | Área | Descripción |
|---|---|---|
| /SAPQUERY/HR_XX_PA | PA | Datos maestros de personal |
| /SAPQUERY/HR_XX_OM | OM | Estructura organizativa |
| /SAPQUERY/HR_XX_TM | TM | Datos de tiempos |
| /SAPQUERY/HR_XX_PY | PY | Datos de nómina (estructura) |

---

## Programas de Reporting Estándar

### Extracción y Reporting

| Programa | Descripción |
|---|---|
| RPUAUD00 | Log de cambios de infotipos (auditoría) |
| RPLMIT00 | Listado de empleados con infotipos |
| RPITIM00 | Listado de datos de infotipos genérico |
| RPTIME00 | Driver de evaluación de tiempos |
| RPCALCX0 | Driver de nómina (X=código de país) |
| RHALTD00 | Listado organizativo jerárquico |
| RHPNPE00 | Estructura de personal en OM |
| RHALEINI | Distribución inicial ALE de datos HR |

---

## Patrones de Integración Recomendados S/4HANA 2023

### Para integraciones nuevas
1. **Preferir APIs OData** sobre BAPIs y RFCs — mejor soporte en nube y bajo acoplamiento
2. **SAP Integration Suite** como middleware — visibilidad, monitorización y transformaciones
3. **Event-Driven con SAP Event Mesh** — para cambios en tiempo real (cambio de puesto, contratación)

### API OData HR en S/4HANA
| API | Descripción | Protocolo |
|---|---|---|
| `API_EMPLOYEE_SRV` | Datos de empleados | OData v2 |
| `API_HCM_TIMESHEET_SRV` | Registro de tiempos | OData v2 |
| `EmployeeLeaveRequest` | Solicitudes de ausencia | OData v2 |
| `OrganizationalObject` | Objetos OM | OData v2 |

**SAP Business Accelerator Hub:** `api.sap.com/package/SAPS4HANACloud`

### Monitorización de interfaces
- **SXMB_MONI** — Monitor de mensajes XI/PI (legacy)
- **SMQS** — Monitor de colas qRFC
- **SM58** — Log de llamadas RFC asíncronas fallidas
- **WE05 / WE09** — Monitor de IDocs (entrada/salida)
- **Integration Suite Operations** — Monitor web para iFlows CPI
