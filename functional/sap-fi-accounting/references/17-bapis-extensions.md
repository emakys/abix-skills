# BAPIs, User Exits y Extensiones FI

Referencia de interfaces programáticas, puntos de ampliación y APIs modernas
para SAP FI en S/4HANA.

---

## BAPIs Principales

### Contabilización de Documentos

| BAPI | Uso | Módulo | Tabla Destino |
|------|-----|--------|---------------|
| BAPI_ACC_DOCUMENT_POST | Contabilizar documento contable universal | GL/AP/AR | ACDOCA |
| BAPI_ACC_DOCUMENT_REV_POST | Anular documento contable | GL/AP/AR | ACDOCA |
| BAPI_ACC_DOCUMENT_CHECK | Validar documento sin contabilizar | GL/AP/AR | — |
| BAPI_ACC_GL_POSTING_POST | Contabilización GL simplificada | GL | ACDOCA |
| BAPI_ACC_EMPLOYEE_PAYABLE | Gastos de empleados | GL | ACDOCA |

### Parámetros clave de BAPI_ACC_DOCUMENT_POST

```abap
" Header
DOCUMENTHEADER:
  OBJ_TYPE     = 'BKPFF'        " Tipo de objeto
  OBJ_KEY      = ' '
  BUS_ACT      = 'RFBU'         " Actividad empresarial
  USERNAME     = sy-uname
  HEADER_TXT   = 'Texto cabecera'
  COMP_CODE    = '1000'
  DOC_DATE     = sy-datum
  PSTNG_DATE   = sy-datum
  DOC_TYPE     = 'SA'
  REF_DOC_NO   = 'REF001'

" GL items
ACCOUNTGL:
  ITEMNO_ACC   = '001'
  GL_ACCOUNT   = '0000400000'
  COMP_CODE    = '1000'
  PSTNG_DATE   = sy-datum
  DOC_TYPE     = 'SA'
  PROFIT_CTR   = 'PC1000'

" Currency amounts
CURRENCYAMOUNT:
  ITEMNO_ACC   = '001'
  CURRENCY     = 'EUR'
  AMT_DOCCUR   = '1000.00'
  AMT_BASE     = '1000.00'
```

### Acreedores y Deudores

| BAPI | Uso | Módulo |
|------|-----|--------|
| BAPI_AP_ACC_GETKEYDATEBAL | Saldo de acreedor a fecha clave | AP |
| BAPI_AR_ACC_GETKEYDATEBAL | Saldo de deudor a fecha clave | AR |
| BAPI_INCOMINGINVOICE_CREATE | Crear factura proveedor (logística) | AP/MM |
| BAPI_INCOMINGINVOICE_GETDETAIL | Leer detalle de factura logística | AP/MM |

### Activos Fijos

| BAPI | Uso | Módulo |
|------|-----|--------|
| BAPI_FIXEDASSET_CREATE | Crear dato maestro de activo | AA |
| BAPI_FIXEDASSET_CHANGE | Modificar dato maestro de activo | AA |
| BAPI_FIXEDASSET_GETDETAIL | Leer dato maestro de activo | AA |
| BAPI_FIXEDASSET_GETLIST | Listar activos fijos | AA |
| BAPI_ASSET_ACQUISITION_POST | Contabilizar adquisición de activo | AA |
| BAPI_ASSET_RETIREMENT_POST | Contabilizar baja de activo | AA |
| BAPI_ASSET_POSTCAP_POST | Post-capitalización de activo | AA |

### Maestros

| BAPI | Uso | Módulo |
|------|-----|--------|
| BAPI_GL_ACC_GETDETAIL | Leer cuenta de mayor | GL |
| BAPI_GL_ACC_EXISTENCECHECK | Verificar existencia de cuenta GL | GL |
| BAPI_VENDOR_GETDETAIL | Leer dato maestro acreedor | AP |
| BAPI_CUSTOMER_GETDETAIL | Leer dato maestro deudor | AR |
| BAPI_COMPANYCODE_GETDETAIL | Leer datos de sociedad | GL |

---

## User Exits y BAdIs

### Documento Contable

| Enhancement | Descripción | Tipo | Uso típico |
|-------------|-------------|------|------------|
| BADI_ACC_DOCUMENT | Proceso de documento contable | BAdI | Enriquecer/validar antes de guardar |
| BADI_ACC_DOCUMENT_CHECK | Validación de documento | BAdI | Chequeos custom pre-posting |
| BADI_ACC_DOCUMENT_POST | Post-processing de documento | BAdI | Acciones después de contabilizar |
| BADI_FDCB_SUBACC01 | Substitución/validación subledger | BAdI | Derivar campos en subcontabilidad |

### Substituciones y Validaciones

| Componente | TCode | Descripción |
|------------|-------|-------------|
| Definir validación | GGB1 | Reglas de validación con condiciones y mensajes |
| Definir substitución | GGB4 | Reglas de sustitución de campos |
| Asignar validación a sociedad | OBBH | Callup point → sociedad → validación |
| Asignar substitución a sociedad | OBBG | Callup point → sociedad → substitución |
| Programa de exit validación | RGGBR000 | User exit para lógica custom en validaciones |
| Programa de exit substitución | RGGBS000 | User exit para lógica custom en sustituciones |

**Callup points:**

| Punto | Nivel | Eventos |
|-------|-------|---------|
| 1 | Cabecera de documento | Al completar cabecera |
| 2 | Línea de documento | Al completar cada posición |
| 3 | Documento completo | Antes de guardar (validación final) |

**Ejemplo de substitución (RGGBS000):**

```abap
FORM GET_EXIT_TITLES TABLES etab.
  etab-name  = 'ZCUST_FI_SUB'.
  etab-param = 'C'.
  etab-title = 'Custom FI Substitution'.
  APPEND etab.
ENDFORM.

FORM ZCUST_FI_SUB USING is_fld TYPE ANY
                  CHANGING cs_fld TYPE ANY.
  " Derivar centro de beneficio desde centro de coste
  DATA: ls_bseg TYPE bseg.
  MOVE-CORRESPONDING is_fld TO ls_bseg.
  IF ls_bseg-kostl IS NOT INITIAL AND ls_bseg-prctr IS INITIAL.
    SELECT SINGLE prctr FROM csks
      INTO ls_bseg-prctr
      WHERE kokrs = '1000' AND kostl = ls_bseg-kostl.
    MOVE-CORRESPONDING ls_bseg TO cs_fld.
  ENDIF.
ENDFORM.
```

### Programa de Pagos

| Enhancement | Descripción | Tipo |
|-------------|-------------|------|
| BADI_AP_PAYMENT | Enhancement del programa de pagos | BAdI |
| RFFOX000 | User exit para propuesta de pagos | Exit |
| RFFOX010 | User exit para formato de medio de pago | Exit |
| BADI_PAYMENT_MEDIUM | Medio de pago personalizado | BAdI |
| EXIT_RFFORI01_001 | Enhancement para aviso de pago | Exit |

### Extracto Bancario

| Enhancement | Descripción | Tipo |
|-------------|-------------|------|
| BADI_BANK_STATEMENT | Procesamiento de extracto bancario | BAdI |
| BADI_FEBAN_POSTING | Contabilización de extracto | BAdI |
| BADI_FEBA_INTERPRET | Interpretación de extracto | BAdI |
| EXIT_RFEBKA00_001 | User exit extracto bancario | Exit |

### Impuestos y Otros

| Enhancement | Descripción | Tipo |
|-------------|-------------|------|
| FI_TAX_BADI | Determinación de impuestos custom | BAdI |
| BADI_FI_CURRENCY_VALUATION | Valoración de moneda extranjera | BAdI |
| BADI_AS_DEPRECIATION | Cálculo de amortización custom | BAdI |
| BADI_FI_OPEN_ITEM_MNG | Gestión de partidas abiertas | BAdI |
| BADI_FI_CLEARING | Compensación de partidas | BAdI |

---

## S/4HANA APIs (RAP / OData)

### APIs Estándar de Lectura

| API Service | Descripción | Tipo |
|-------------|-------------|------|
| API_JOURNALENTRYITEMBASIC_SRV | Partidas de diario (lectura) | OData V2 |
| API_OPLACCTGDOCITEMCUBE_SRV | Cubo de análisis de diario | OData V2 |
| API_JOURNALENTRYITEM_SRV | Partidas de diario (V4) | OData V4 |
| API_GLACCOUNTBALANCE_SRV | Saldos de cuenta de mayor | OData V2 |
| API_SUPPLIERINVOICE_SRV | Factura de proveedor | OData V2 |

### CDS Views Analíticas

| CDS View | Descripción | Tabla base |
|----------|-------------|------------|
| I_JournalEntry | Documento de diario | ACDOCA |
| I_JournalEntryItem | Partida de diario | ACDOCA |
| I_GLAccountLineItem | Partida individual GL | ACDOCA |
| I_OperatingExpense | Gastos operativos | ACDOCA |
| I_GLAccountBalance | Saldo de cuenta de mayor | ACDOCA (agregado) |
| I_FixedAsset | Activo fijo maestro | ANLA/ANLZ |
| I_SupplierLineItem | Partida de acreedor | ACDOCA |
| I_CustomerLineItem | Partida de deudor | ACDOCA |

### APIs de Escritura (S/4HANA Cloud)

| API | Descripción | Operación |
|-----|-------------|-----------|
| API_JOURNALENTRYITEMBASIC_SRV (POST) | Crear asiento de diario | Create |
| API_SUPPLIERINVOICE_PROCESS_SRV | Procesar factura de proveedor | Create/Update |
| API_FIXEDASSET_0001 | Gestionar activo fijo | CRUD |
| API_PAYMENTADVICE_SRV | Aviso de pago | Create |

---

## MCP — Consultas de Diagnóstico para Extensiones

```sql
-- Verificar BAdIs activos para documento contable
SELECT IMPL_NAME, FILTER_VALUE, IS_ACTIVE
FROM SXC_ATTR
WHERE EXIT_NAME LIKE '%ACC_DOCUMENT%'
ORDER BY EXIT_NAME

-- Verificar substituciones configuradas
SELECT SUBSTNAME, CALLUP_POINT, BUKRS, EXITNAME
FROM GB01
WHERE SUBSTNAME LIKE 'Z%'
ORDER BY CALLUP_POINT

-- Verificar validaciones configuradas
SELECT VALNAME, CALLUP_POINT, BUKRS, EXITNAME
FROM GB01V
WHERE VALNAME LIKE 'Z%'
ORDER BY CALLUP_POINT
```

---

## Tabla de Referencia Rápida — Enhancement Spots

| Área Funcional | Enhancement Spot | BAdI Principal |
|----------------|-----------------|----------------|
| Documento FI | SMOD_FI_DOCUMENT | BADI_ACC_DOCUMENT |
| Pagos F110 | SMOD_FI_PAYMENT | BADI_AP_PAYMENT |
| Extracto bancario | SMOD_FI_BANKSTMT | BADI_BANK_STATEMENT |
| Impuestos | SMOD_FI_TAX | FI_TAX_BADI |
| Activos fijos | SMOD_FI_ASSET | BADI_AS_DEPRECIATION |
| Compensación | SMOD_FI_CLEARING | BADI_FI_CLEARING |
| Moneda extranjera | SMOD_FI_CURRVAL | BADI_FI_CURRENCY_VALUATION |
| Reclamación | SMOD_FI_DUNNING | BADI_FI_DUNNING |
| Document Splitting | SMOD_FI_DOCSPLIT | BADI_ACAC_SPLIT |
