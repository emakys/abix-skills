# BAPIs, Exits y Extensiones SD

Referencia completa de puntos de extensión en SAP SD: BAPIs estándar, User Exits, BAdIs, Enhancement Spots y Released APIs para S/4HANA.

---

## BAPIs de Pedido de Venta

### BAPI_SALESORDER_CREATEFROMDAT2
Crea un pedido de venta desde un programa externo o interfaz.

**Parámetros de entrada principales:**
- `ORDER_HEADER_IN` (BAPISDHD1): DOC_TYPE, SALES_ORG, DISTR_CHAN, DIVISION, PURCH_NO_C, REQ_DATE_H
- `ORDER_HEADER_INX` (BAPISDHD1X): flags X para cada campo modificado
- `ORDER_ITEMS_IN` (BAPISDITM[]): MATERIAL, TARGET_QTY, SALES_UNIT, PLANT, STORE_LOC
- `ORDER_ITEMS_INX` (BAPISDITMX[]): flags X por ítem
- `ORDER_PARTNERS` (BAPIPARNR[]): PARTN_ROLE (AG/WE/RE/RG), PARTN_NUMB
- `ORDER_SCHEDULES_IN` (BAPISCHDL[]): REQ_DATE, REQ_QTY por línea de reparto
- `ORDER_CONDITIONS_IN` (BAPICOND[]): COND_TYPE, COND_VALUE, CURRENCY para pricing manual
- `ORDER_TEXT` (BAPISDTEXT[]): textos de cabecera/posición

**Parámetros de salida:**
- `SALESDOCUMENT`: número de pedido creado
- `RETURN` (BAPIRET2[]): mensajes de error/warning/success

**Patrón de uso:**
```abap
CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
  EXPORTING
    order_header_in   = ls_header
    order_header_inx  = ls_headerx
  TABLES
    order_items_in    = lt_items
    order_items_inx   = lt_itemsx
    order_partners    = lt_partners
    order_schedules_in = lt_schedules
    order_conditions_in = lt_conditions
    return            = lt_return
  IMPORTING
    salesdocument     = lv_vbeln.

IF lv_vbeln IS NOT INITIAL.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING wait = abap_true.
ENDIF.
```

**Queries MCP para diagnostico:**
```sql
-- Ver estructura del pedido recien creado
SELECT VBELN, AUART, VKORG, VTWEG, SPART, KUNNR, NETWR, WAERK
FROM VBAK WHERE VBELN = '{pedido}'

-- Ver posiciones del pedido
SELECT VBELN, POSNR, MATNR, ARKTX, KWMENG, VRKME, NETPR, MWSBP
FROM VBAP WHERE VBELN = '{pedido}' ORDER BY POSNR

-- Ver socios del pedido
SELECT VBELN, POSNR, PARVW, KUNNR, LIFNR
FROM VBPA WHERE VBELN = '{pedido}'

-- Ver repartos
SELECT VBELN, POSNR, ETENR, EDATU, WMENG, BMENG
FROM VBEP WHERE VBELN = '{pedido}' ORDER BY POSNR, ETENR
```

---

### BAPI_SALESORDER_CHANGE
Modifica un pedido de venta existente.

**Parámetros clave:**
- `SALESDOCUMENT`: número del pedido a modificar
- `ORDER_HEADER_IN` + `ORDER_HEADER_INX`: cabecera con flags X (solo campos marcados se actualizan)
- `ORDER_ITEM_IN` + `ORDER_ITEM_INX`: posiciones con flags
- `ORDER_SCHEDULES_IN` + `ORDER_SCHEDULES_INX`: repartos
- `ORDER_CONDITIONS_IN` + `ORDER_CONDITIONS_INX`: condiciones de precio
- `LOGIC_SWITCH` (BAPISDLS): flags especiales (COND_HANDL para pricing, NO_STATUS_BUF)

**Patrón de uso:**
```abap
" Para cambiar cantidad de posicion
ls_item-itm_number = '000010'.
ls_item-target_qty = '50'.
ls_itemx-itm_number = '000010'.
ls_itemx-target_qty = abap_true.

CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
  EXPORTING
    salesdocument    = lv_vbeln
    order_header_in  = ls_header
    order_header_inx = ls_headerx
  TABLES
    order_item_in    = lt_items
    order_item_inx   = lt_itemsx
    return           = lt_return.
```

**Query MCP — verificar cambios en log:**
```sql
-- Log de cambios del pedido
SELECT OBJECTID, CHANGENR, USERNAME, UDATE, UTIME, TABNAME, FNAME, VALUE_OLD, VALUE_NEW
FROM CDHDR
INNER JOIN CDPOS ON CDHDR.CHANGENR = CDPOS.CHANGENR
WHERE CDHDR.OBJECTCLAS = 'VERKBELEG' AND CDHDR.OBJECTID = '{pedido}'
ORDER BY CDHDR.UDATE DESC, CDHDR.UTIME DESC
```

---

### BAPI_SALESORDER_GETLIST
Lista pedidos de venta por cliente y criterios de búsqueda.

**Parámetros:**
- `CUSTOMER_NUMBER`, `SALES_ORGANIZATION`, `DISTRIBUTION_CHANNEL`, `DIVISION`
- `MATERIAL`, `PURCHASE_ORDER_NUMBER`
- `DATE_FROM`, `DATE_TO` (fechas de documento)
- Salida: tabla `SALES_ORDERS` con VBELN, ERDAT, AUART, KUNNR, NETWR

---

### BAPI_SALESORDER_SIMULATE
Simula la creación de un pedido sin grabarlo. Ideal para precios y ATP.

**Usos principales:**
- Verificar pricing antes de crear
- Simular disponibilidad (ATP check)
- Validar customizing sin crear documento

**Query MCP — tablas de simulacion:**
```sql
-- Ver configuracion ATP por material/planta
SELECT MATNR, WERKS, MTVFP, ATPKZ FROM MARC WHERE MATNR = '{material}' AND WERKS = '{planta}'
-- Ver strategy group
SELECT MATNR, WERKS, STRGR, LGPRO FROM MARA INNER JOIN MARC ON MARA.MATNR = MARC.MATNR WHERE MARA.MATNR = '{material}'
```

---

## BAPIs de Entrega

### BAPI_OUTB_DELIVERY_CREATE_SLS
Crea una entrega de salida desde uno o varios pedidos de venta.

**Parámetros:**
- `SHIP_POINT`: punto de expedición
- `DUE_DATE`: fecha de entrega requerida
- `DELIVERY_NOITEM`: tabla con pedidos (REFDOC, REFDOCIT, MOVE_TYPE)
- Salida: `DELIVERY` con número de entrega creada

**Query MCP:**
```sql
-- Ver entregas creadas para un pedido
SELECT VBELV, VBELN, VBTYP_N, POSNN, POSNV
FROM VBFA WHERE VBELV = '{pedido}' AND VBTYP_N = 'J'

-- Ver cabecera de entrega
SELECT VBELN, VSTEL, KUNNR, LFDAT, LPRIO, TRAID, TRATY
FROM LIKP WHERE VBELN = '{entrega}'
```

---

### BAPI_OUTB_DELIVERY_CHANGE
Modifica datos de cabecera o posición de una entrega (picking qty, fechas, textos).

**Parámetros clave:**
- `DELIVERY`: número de entrega
- `DELIVERY_HEADER_IN` + `DELIVERY_HEADER_INX`
- `DELIVERY_ITEM_IN[]` + `DELIVERY_ITEM_INX[]`: DELIV_NUMB, DELIV_ITEM, ACTUAL_QUI (cantidad picking)

---

### BAPI_OUTB_DELIVERY_CONFIRM_DEC
Confirma la decentralized WM picking de una entrega. Actualiza cantidades de picking.

---

### BAPI_OUTB_DELIVERY_GOODSMVT
Ejecuta la Goods Issue (PGI) de una entrega. Equivalente al Post Goods Issue de VL02N.

**Parámetros:**
- `DELIVERY`: número de entrega
- `DELIVERY_HEADER_INP`: fechas del movimiento
- `BUSINESS_DATA_INP`: datos contables (imputación)
- Requiere stock disponible en almacén y ubicación

**Query MCP:**
```sql
-- Verificar stock antes de PGI
SELECT MATNR, WERKS, LGORT, LABST, INSME, SPEME, UMLME
FROM MARD WHERE MATNR = '{material}' AND WERKS = '{planta}'

-- Ver movimientos de mercancías generados
SELECT MBLNR, MJAHR, ZEILE, MATNR, WERKS, LGORT, BWART, MENGE, MEINS
FROM MSEG WHERE VBELN_IM = '{entrega}' OR AUFNR = '{entrega}'
```

---

## BAPIs de Factura

### BAPI_BILLINGDOC_CREATEMULTIPLE
Crea uno o varios documentos de factura desde entregas o pedidos.

**Parámetros:**
- `BILLINGDATAIN[]`: tabla con datos de entrada (REFDOC, REFDOCTYPE, ORD_REASON, BILLINGDATE, PAYER)
- Salida: `BILLINGDOCUMENTOUT[]` con números de facturas creadas
- `RETURN[]`: mensajes — verificar TYPE = 'E' para errores

**Query MCP:**
```sql
-- Ver facturas creadas para una entrega
SELECT VBELV, VBELN, VBTYP_N FROM VBFA WHERE VBELV = '{entrega}' AND VBTYP_N = 'M'

-- Ver cabecera de factura
SELECT VBELN, FKART, FKDAT, KUNRG, NETWR, MWSBK, WAERK, RFBSK
FROM VBRK WHERE VBELN = '{factura}'

-- Ver estado contable de la factura
SELECT VBELN, RFBSK, BUCHK FROM VBRK WHERE VBELN = '{factura}'
-- RFBSK: ' ' = no transferida, 'A' = transferida parcial, 'C' = completamente contabilizada
```

---

### BAPI_BILLINGDOC_CANCEL
Cancela un documento de factura. Genera documento de cancelación (tipo S1 o equivalente).

**Parámetros:**
- `BILLINGDOCUMENT`: número de factura a cancelar
- `CANCELLATION_DATE`, `CANCELLATION_REASON`
- Salida: `RETURN` con mensajes

---

### BAPI_BILLINGDOC_GETDETAIL
Lee el detalle completo de un documento de factura (cabecera, posiciones, condiciones, socios).

---

## User Exits Clásicos (SMOD/CMOD)

### Enhancement MV45AFZZ — Sales Order Processing
El enhancement más importante en VA01/VA02/VA03.

| Exit | Descripción | Uso típico |
|------|-------------|------------|
| `USEREXIT_FIELD_MODIFICATION` | Control de pantalla (input/output/required) | Hacer campos obligatorios según tipo de pedido |
| `USEREXIT_SAVE_DOCUMENT_PREPARE` | Validaciones antes de grabar | Verificar campos custom, lógica de negocio |
| `USEREXIT_SAVE_DOCUMENT` | Post-procesamiento al grabar | Crear objetos adicionales, notificaciones |
| `USEREXIT_MOVE_FIELD_TO_VBAK` | Mover datos de pantalla a VBAK (cabecera) | Campos custom en append VBAK |
| `USEREXIT_MOVE_FIELD_TO_VBAP` | Mover datos de pantalla a VBAP (posición) | Campos custom en append VBAP |
| `USEREXIT_MOVE_FIELD_TO_VBEP` | Mover datos a VBEP (repartos) | Campos custom en repartos |
| `USEREXIT_MOVE_FIELD_TO_VBKD` | Mover datos a VBKD (comercial) | Datos comerciales custom |
| `USEREXIT_CHECK_VBAP` | Validar posición antes de grabar | Cross-validaciones entre campos |
| `USEREXIT_CHECK_VBAK` | Validar cabecera | Validaciones de cabecera complejas |
| `USEREXIT_NUMBER_RANGE` | Rangos de numeración custom | Numeración externa de pedidos |
| `USEREXIT_PRICING_PREPARE_TKOMK` | Preparar comunicación pricing cabecera | Campos custom en TKOMK |
| `USEREXIT_PRICING_PREPARE_TKOMP` | Preparar comunicación pricing posición | Campos custom en TKOMP |

**Query MCP — ver exits activos:**
```sql
-- Ver includes activos en MV45AFZZ
SELECT OBJ_NAME, MESSION, MEMBER FROM MODSAP
WHERE OBJ_NAME LIKE 'MV45A%'
ORDER BY OBJ_NAME

-- Ver implementaciones CMOD
SELECT DEVCLASS, ENHNAME, ACTIVE FROM CMOD_HEAD WHERE ACTIVE = 'X'
```

---

### Enhancement MV45AFZA — Additional Sales Order Exits
| Exit | Descripción |
|------|-------------|
| `USEREXIT_CHANGE_SALESORDER` | Cambios al re-entrar al pedido |
| `USEREXIT_READ_DOCUMENT` | Post-lectura del documento |
| `USEREXIT_DELETE_DOCUMENT` | Antes de borrar posición |

---

### Enhancement MV50AFZ1 — Delivery Processing
Exits en VL01N/VL02N/VL03N.

| Exit | Descripción |
|------|-------------|
| `USEREXIT_SAVE_DOCUMENT_PREPARE` | Validaciones antes de grabar entrega |
| `USEREXIT_MOVE_FIELD_TO_LIPS` | Campos custom en LIPS (posiciones entrega) |
| `USEREXIT_MOVE_FIELD_TO_LIKP` | Campos custom en LIKP (cabecera entrega) |
| `USEREXIT_FIELD_MODIFICATION` | Control de pantalla en entrega |
| `USEREXIT_PICK_QUANTITY` | Lógica de cantidad de picking |

---

### Enhancement RV60AFZZ — Billing Processing
Exits en VF01/VF02/VF03.

| Exit | Descripción |
|------|-------------|
| `USEREXIT_FILL_VBRK_VBRP` | Rellenar campos custom en VBRK/VBRP |
| `USEREXIT_NUMBER_RANGE` | Numeración externa de facturas |
| `USEREXIT_PRICING_PREPARE_TKOMK` | Pricing comunicación en factura |

---

### Enhancement SDVFX008 — Billing Account Determination
| Exit | Descripción |
|------|-------------|
| `EXIT_SAPLV60B_001` | Determinación de cuenta contable custom |

---

## BAdIs SD (Business Add-Ins)

### BADI_SD_SALES
BAdI principal para procesamiento de pedidos de venta.

**Métodos clave:**
- `CHECK_VBAK`: validación de cabecera
- `CHECK_VBAP`: validación de posición
- `SET_FIELD_MODIFICATION`: control de pantalla programático
- `CHANGE_AT_SAVE`: cambios en el momento de grabar

**Query MCP:**
```sql
SELECT BADI_NAME, DESCRIPTION, SPOT_NAME FROM SXS_ATTR
WHERE BADI_NAME = 'BADI_SD_SALES'
```

---

### LE_SHP_DELIVERY_PROC
BAdI para procesamiento de entregas.

**Métodos:**
- `CHECK_AND_SET_HEADER_FIELD`: validar/modificar campos de cabecera
- `CHECK_AND_SET_ITEM_FIELD`: validar/modificar campos de posición
- `PROCESS_AFTER_GOODS_ISSUE`: post-procesamiento tras PGI
- `SET_DELIVERY_STATUS`: manipular status de entrega

---

### BADI_BILLING_DOC
BAdI para procesamiento de facturas.

**Métodos:**
- `CHANGE_BILLING_HEADER`: modificar datos de cabecera
- `CHANGE_BILLING_ITEM`: modificar datos de posición
- `CHECK_BEFORE_SAVE`: validaciones antes de grabar
- `NUMBER_ASSIGNMENT`: asignación de número externa

---

### SD_COND_TECHNIQUE
BAdI para la técnica de condición (pricing, textos, output).

**Usos:**
- Modificar acceso a tablas de condición
- Override de determinación de procedimiento
- Lógica custom en búsqueda de registros

---

### BADI_COPY_CONTROL
Controla el comportamiento del copy control entre documentos.

**Métodos:**
- `COPY_ITEM`: lógica custom al copiar posiciones
- `COPY_HEADER`: lógica custom al copiar cabecera

---

### BADI_SD_PARTNER
Determinación de socios custom.

**Método `DETERMINE_PARTNER`**: Override de determinación de cualquier función de socio.

---

### BADI_DELIVERYPROCESSING_STEP — S/4HANA
Nuevo BAdI para pasos de procesamiento de entrega en S/4HANA.

---

### BADI_V45_DETERMINE_SHIP_POINT — S/4HANA
Determinación de punto de expedición custom.

---

## Enhancement Spots

### ES_SAPLV45A
Enhancement spot principal para Sales Order (VA01/VA02).

**Implicit Enhancements disponibles:**
- Al inicio de includes MV45AFZZ, MV45AF0B, MV45AF0C
- Usar solo para pre/post-procesamiento que no cabe en exits

**Query MCP:**
```sql
SELECT ENHNAME, ENHTYPE, DEVCLASS, LONGTEXT_KEY
FROM ENHOBJ WHERE ENHNAME LIKE '%V45%' OR ENHNAME LIKE '%SALES%'
```

---

### ES_SAPMV50A
Enhancement spot para Delivery (VL01N/VL02N).

---

### ES_SAPLV60B
Enhancement spot para Billing (VF01/VF02).

---

## Released APIs S/4HANA (RAP/OData)

### I_SalesOrderTP — Business Object Pedido de Venta
API publicada con contrato de estabilidad C1.

**Operaciones disponibles:**
- `create`: crear pedido (equivale a BAPI_SALESORDER_CREATEFROMDAT2)
- `update`: modificar campos
- `delete`: eliminar posición
- Actions: `SetBillingBlock`, `RemoveBillingBlock`, `SetDeliveryBlock`, `RemoveDeliveryBlock`

**Acceso via EML (ABAP):**
```abap
MODIFY ENTITIES OF i_salesordertp
  ENTITY salesorder
    CREATE FIELDS ( SalesOrderType SalesOrganization ... )
    WITH VALUE #( ( %cid = 'order1' SalesOrderType = 'OR' ... ) )
  RESULT DATA(lt_result)
  REPORTED DATA(lt_reported)
  FAILED DATA(lt_failed)
  MAPPED DATA(lt_mapped).
```

**Query MCP — verificar servicios publicados:**
```sql
SELECT SRVD_NAME, SRVD_VERSION, DESCRIPTION FROM I_SERVICEDEFN_2
WHERE SRVD_NAME LIKE '%SALESORDER%'

SELECT SRVB_NAME, SRVB_VERSION FROM I_SERVICEBINDING_2
WHERE SRVB_NAME LIKE '%SALESORDER%'
```

---

### I_DeliveryDocumentTP — Business Object Entrega
**Operaciones:**
- `create`: crear entrega
- `update`: modificar (picking qty, fechas)
- Action: `PostGoodsIssue`, `ReverseGoodsIssue`

---

### I_BillingDocumentTP — Business Object Factura
**Operaciones:**
- `create`: crear factura
- Action: `Cancel`

---

### API_SALES_ORDER_SRV — OData V2 (legacy S/4HANA)
Servicio OData para integración con Fiori y sistemas externos.
- Entity set: `A_SalesOrder`, `A_SalesOrderItem`, `A_SalesOrderScheduleLine`
- Requiere autorización en SICF y S_SERVICE

---

### API_OUTBOUND_DELIVERY_SRV — OData V2
Servicio OData para entregas de salida.
- Entity set: `A_OutbDeliveryHeader`, `A_OutbDeliveryItem`

---

## Function Modules Útiles (Uso Interno)

### SD_SALESDOCUMENT_CREATE
FM interno que usa BAPI_SALESORDER_CREATEFROMDAT2 internamente. No recomendado para uso externo directo.

### SD_SALESDOCUMENT_SAVE
FM interno para grabar pedido en memoria SAP a base de datos.

### SD_DELIVERY_CREATE_SINGLE
Creación de entrega individual. Base de BAPI_OUTB_DELIVERY_CREATE_SLS.

### RV_PRICE_PRINT_HEAD
Lee y formatea condiciones de precio de cabecera para impresión.

```abap
CALL FUNCTION 'RV_PRICE_PRINT_HEAD'
  EXPORTING
    comm_head_i = ls_tkomk
  TABLES
    tkomv       = lt_conditions.
```

### RV_PRICE_PRINT_ITEM
Lee condiciones de precio de posición.

### SD_DOCUMENT_PARTNER_READ
Lee socios de un documento de ventas.

```abap
CALL FUNCTION 'SD_DOCUMENT_PARTNER_READ'
  EXPORTING
    i_vbeln  = lv_vbeln
  TABLES
    t_vbpa   = lt_partners.
```

### PRICING
FM central del motor de precios SD. Ejecuta toda la técnica de condición.

### V_CUSTOMER_CREDIT_CHECK
Verificación de crédito del cliente. Llamado automáticamente en VA01.

### SD_BACKORDER_PROCESSING
Procesamiento de pedidos atrasados (backorder).

---

## Queries MCP — Búsqueda de Puntos de Extensión

### Encontrar todos los exits de un programa
```sql
-- Exits via MODSAP (enhancement components)
SELECT MESSION, OBJ_NAME, MEMBER, STATIC_CHECK
FROM MODSAP WHERE MEMBER LIKE '%MV45A%'
ORDER BY OBJ_NAME, MEMBER

-- BAdIs relacionados con SD
SELECT BADI_NAME, SPOT_NAME, DESCRIPTION
FROM SXS_ATTR
WHERE BADI_NAME LIKE '%SD%'
   OR BADI_NAME LIKE '%SALES%'
   OR BADI_NAME LIKE '%DELIVERY%'
   OR BADI_NAME LIKE '%BILLING%'
ORDER BY BADI_NAME

-- Enhancement spots SD
SELECT ENHNAME, ENHTYPE, DEVCLASS
FROM ENHOBJ
WHERE ENHNAME LIKE '%V45%'
   OR ENHNAME LIKE '%V50%'
   OR ENHNAME LIKE '%V60%'
ORDER BY ENHNAME
```

### Verificar implementaciones activas de BAdIs
```sql
-- Ver implementaciones de BAdIs en el sistema
SELECT BADI_NAME, IMPL_NAME, ACTIVE_IMP
FROM SXS_IMPLA
WHERE BADI_NAME LIKE '%SD%' AND ACTIVE_IMP = 'X'
ORDER BY BADI_NAME

-- Ver CMOD enhancements activos
SELECT E.DEVCLASS, E.ENHNAME, M.MEMBER
FROM CMOD_HEAD E
INNER JOIN CMOD_MEMB M ON E.ENHNAME = M.ENHNAME
WHERE E.ACTIVE = 'X'
ORDER BY E.ENHNAME
```

### Encontrar BAPIs relacionadas con SD
```sql
-- BAPIs en el Business Object SALESORDER
SELECT BOBF_BAPI_NAME, BOBF_METHOD, DESCRIPTION
FROM TBAPI
WHERE BOBF_BAPI_NAME LIKE '%SALESORDER%'
   OR BOBF_BAPI_NAME LIKE '%OUTB_DELIVERY%'
   OR BOBF_BAPI_NAME LIKE '%BILLINGDOC%'
ORDER BY BOBF_BAPI_NAME

-- Ver function modules tipo BAPI
SELECT FUNCNAME, COMPONENT, COMPONENT_TYPE
FROM TFDIR
WHERE FUNCNAME LIKE 'BAPI_SALES%'
   OR FUNCNAME LIKE 'BAPI_OUTB%'
   OR FUNCNAME LIKE 'BAPI_BILLING%'
ORDER BY FUNCNAME
```

### Verificar Released APIs S/4HANA
```sql
-- Objetos con Release Contract C1 (uso externo permitido)
SELECT OBJECT_NAME, OBJECT_TYPE, RELEASE_STATE, API_STATE
FROM I_APSEXTERNALAPICATALOG
WHERE OBJECT_NAME LIKE '%SalesOrder%'
   OR OBJECT_NAME LIKE '%Delivery%'
   OR OBJECT_NAME LIKE '%BillingDocument%'

-- Verificar si una API tiene contrato de estabilidad
SELECT OBJECT_NAME, CONTRACT_TYPE, RELEASE_STATE
FROM I_APSEXTCONTRACTCATALOG
WHERE OBJECT_NAME LIKE '%SalesOrder%'
```

---

## Resumen de Selección de Punto de Extension

| Escenario | Recomendación S/4HANA | Alternativa clasica |
|-----------|----------------------|---------------------|
| Crear pedido desde interfaz | I_SalesOrderTP (EML) o BAPI_SALESORDER_CREATEFROMDAT2 | SD_SALESDOCUMENT_CREATE |
| Validacion en VA01 | BAdI BADI_SD_SALES | USEREXIT_SAVE_DOCUMENT_PREPARE |
| Campo custom en pedido | Append VBAK/VBAP + USEREXIT_MOVE_FIELD | CDS Extension (S/4) |
| Control de pantalla | USEREXIT_FIELD_MODIFICATION | BAdI SET_FIELD_MODIFICATION |
| Crear entrega | BAPI_OUTB_DELIVERY_CREATE_SLS | SD_DELIVERY_CREATE_SINGLE |
| Post-PGI logic | BAdI LE_SHP_DELIVERY_PROC PROCESS_AFTER_GOODS_ISSUE | Exit en MV50AFZ1 |
| Crear factura | BAPI_BILLINGDOC_CREATEMULTIPLE | FM interno RV_INVOICE_CREATE |
| Determinacion cuenta | BAdI SDVFX008 / EXIT_SAPLV60B_001 | VKOA customizing |
| Pricing custom | BAdI SD_COND_TECHNIQUE | USEREXIT_PRICING_PREPARE_TKOMP |
| Integracion OData | API_SALES_ORDER_SRV (V2) / I_SalesOrderTP (V4) | — |
