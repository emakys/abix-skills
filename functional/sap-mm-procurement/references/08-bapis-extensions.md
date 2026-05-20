# BAPIs y Extensiones MM

## BAPIs de Compras

### Purchase Order
| BAPI | Accion | Parametros clave |
|------|--------|-----------------|
| BAPI_PO_CREATE1 | Crear PO | PO_HEADER, PO_ITEMS, PO_ITEM_SCHEDULES, PO_ITEM_ACCOUNT_ASSIGNMENT |
| BAPI_PO_CHANGE | Modificar PO | PURCHASEORDER, PO_HEADER, PO_ITEMS, PO_ITEM_SCHEDULESX |
| BAPI_PO_GETDETAIL1 | Leer PO | PURCHASEORDER → PO_HEADER, PO_ITEMS, PO_ITEM_HISTORY |
| BAPI_PO_RELEASE | Liberar PO | PURCHASEORDER, PO_REL_CODE |
| BAPI_PO_RESET_RELEASE | Resetear release | PURCHASEORDER |

### Purchase Requisition
| BAPI | Accion |
|------|--------|
| BAPI_PR_CREATE | Crear solicitud pedido |
| BAPI_PR_CHANGE | Modificar solicitud |
| BAPI_PR_GETDETAIL | Leer solicitud |

### Goods Receipt
| BAPI | Accion |
|------|--------|
| BAPI_GOODSMVT_CREATE | Crear movimiento mercancias |
| BAPI_GOODSMVT_CANCEL | Cancelar movimiento |
| BAPI_GOODSMVT_GETITEMS | Leer items movimiento |

### Invoice
| BAPI | Accion |
|------|--------|
| BAPI_INCOMINGINVOICE_CREATE | Crear factura logistica |
| BAPI_INCOMINGINVOICE_CHANGE | Modificar factura |
| BAPI_INCOMINGINVOICE_GETDETAIL | Leer factura |

### Material Master
| BAPI | Accion |
|------|--------|
| BAPI_MATERIAL_GET_ALL | Leer datos material |
| BAPI_MATERIAL_SAVEDATA | Crear/modificar material |
| BAPI_MATERIAL_GET_DETAIL | Leer detalle material |

### Vendor
| BAPI | Accion |
|------|--------|
| BAPI_VENDOR_GET_DETAIL | Leer datos proveedor |
| BAPI_VENDOR_CREATE | Crear proveedor |
| BAPI_VENDOR_CHANGE | Modificar proveedor |

### Queries MCP para descubrir BAPIs
```
SearchObject("BAPI_PO_*")
SearchObject("BAPI_PR_*")
SearchObject("BAPI_GOODSMVT_*")
SearchObject("BAPI_INCOMINGINVOICE_*")
SearchObject("BAPI_MATERIAL_*")
ReadFunctionModule("BAPI_PO_CREATE1")  -- Ver parametros completos
```

## BAdIs MM (S/4HANA)

### Compras
| BAdI | Descripcion | Uso tipico |
|------|-------------|-----------|
| ME_PROCESS_PO_CUST | Proceso de pedido | Validaciones custom, campos Z |
| ME_PROCESS_REQ_CUST | Proceso solicitud pedido | Validaciones, defaults |
| ME_GUI_PO_CUST | Pantalla PO Enjoy | Campos custom en dynpro |
| ME_PURCHDOC_POSTED | Despues de grabar doc compras | Notificaciones, integraciones |
| ME_REQ_POSTED | Despues de grabar solicitud | Workflows, notificaciones |
| ME_DEFINE_CALCTYPE | Esquema de calculo custom | Logica de pricing |
| ME_PROCESS_OUT_CUST | Mensaje output PO | Formatos custom email/EDI |

### Entrada de Mercancias
| BAdI | Descripcion | Uso tipico |
|------|-------------|-----------|
| MB_MIGO_BADI | Proceso MIGO | Pantallas Z, validaciones |
| MB_DOCUMENT_BADI | Documento material | Post-processing |
| MB_CHECK_LINE_BADI | Verificacion linea | Validacion de posiciones |
| MB_QUANTITY_PROPOSAL | Propuesta cantidad | Default de cantidad |

### Verificacion Facturas
| BAdI | Descripcion | Uso tipico |
|------|-------------|-----------|
| INVOICE_UPDATE | Actualizacion factura | Post-processing |
| MRM_BLOCKREASON | Motivos bloqueo | Custom block reasons |
| MRM_PAYMENT_TERMS | Condiciones pago | Override condiciones |
| MRM_ERS_HDAT | Datos cabecera ERS | Campos custom ERS |

### Material Master
| BAdI | Descripcion |
|------|-------------|
| MATERIAL_MAINTAIN_BADI | Durante mantenimiento material |
| MAT_DERIVE_DATA | Derivacion datos material |

### Queries MCP para descubrir extensiones
```
GetEnhancements("SAPLMEGUI")        -- Enhancement points en PO
GetEnhancements("SAPLMIGO")         -- Enhancement points en GR
GetEnhancements("SAPLMR1M")         -- Enhancement points en Invoice
SearchObject("ME_PROCESS_PO*")      -- BAdIs de PO
ReadClass("CL_ME_PROCESS_PO_CUST")  -- Ver implementacion
```

## User Exits clasicos (ECC legacy)

| Exit | Descripcion | Relevancia S/4 |
|------|-------------|:--------------:|
| EXIT_SAPMM06E_001-018 | Solicitud pedido | Migrar a BAdI |
| EXIT_SAPMM06E_016 | PO: Check datos posicion | Migrar a BAdI |
| USEREXIT_FIELD_MODIFICATION | Dynpro material | Aun usado |
| EXIT_SAPMM07M_001 | Goods Movement check | Migrar a BAdI |
| EXIT_SAPLMRMP_010 | Invoice verification | Migrar a BAdI |

## Clases RAP relevantes (S/4HANA)
```
SearchObject("CL_MM_PUR*")       -- Clases purchasing RAP
SearchObject("I_PURCHASEORDER*")  -- CDS views estandar PO
SearchObject("I_PURCHASEREQ*")    -- CDS views solicitud pedido
ReadView("I_PURCHASEORDERAPI01")  -- API CDS view PO
ReadBehaviorDefinition("R_PURCHASEORDERTP")  -- RAP behavior PO
```
