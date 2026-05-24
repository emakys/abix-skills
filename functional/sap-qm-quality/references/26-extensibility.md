# Extensibilidad QM

## 1. User Exits (Classic)

### Inspection Lot Exits
| Exit | Include | Descripcion |
|------|---------|-------------|
| QQMA0001 | ZXQQMU01 | Creacion lote — validaciones custom |
| QQMA0002 | ZXQQMU02 | UD — follow-up actions custom |
| QQMA0003 | ZXQQMU03 | UD — stock posting custom |
| QQMA0005 | ZXQQMU05 | Determinacion plan inspeccion |

### Results Exits
| Exit | Include | Descripcion |
|------|---------|-------------|
| QQMA0006 | ZXQQMU06 | Resultados — validacion custom |
| QQMA0007 | ZXQQMU07 | Resultados — valoracion custom |

### Notification Exits
| Exit | Include | Descripcion |
|------|---------|-------------|
| QQMA0010 | ZXQQMU10 | Aviso — validaciones |
| QQMA0011 | ZXQQMU11 | Aviso — valores default |
| QQMA0012 | ZXQQMU12 | Aviso — follow-up custom |

## 2. BAdIs (S/4HANA)

### Inspection Processing
| BAdI | Interface | Descripcion |
|------|-----------|-------------|
| QINSP_LOT_CREATE | IF_QINSP_LOT_CREATE | Crear lote — enriquecer/validar |
| QINSP_LOT_PROCESS | IF_QINSP_LOT_PROCESS | Procesar lote — modificar |
| QINSP_RESULT_RECORD | IF_QINSP_RESULT_RECORD | Registro resultados — validar/enriquecer |
| QINSP_USAGE_DECISION | IF_QINSP_USAGE_DECISION | UD — custom actions |
| QINSP_STOCK_POSTING | IF_QINSP_STOCK_POSTING | Stock posting — modificar movimiento |

### Notifications
| BAdI | Interface | Descripcion |
|------|-----------|-------------|
| QNOTIF_CREATE | IF_QNOTIF_CREATE | Crear aviso — defaults/validacion |
| QNOTIF_PROCESS | IF_QNOTIF_PROCESS | Procesar — enriquecer |
| QNOTIF_STATUS_CHANGE | IF_QNOTIF_STATUS | Cambio status — acciones |

### Certificates
| BAdI | Interface | Descripcion |
|------|-----------|-------------|
| QCERT_CREATE | IF_QCERT_CREATE | Crear certificado — datos custom |
| QCERT_PROCESS | IF_QCERT_PROCESS | Procesar — layout custom |

### Plan Determination
| BAdI | Interface | Descripcion |
|------|-----------|-------------|
| QINSP_PLAN_SEL | IF_QINSP_PLAN_SEL | Seleccion plan — logica custom |

## 3. Enhancement Spots

| Enhancement Spot | Programa | Area |
|------------------|----------|------|
| ES_SAPLQEVA | SAPLQEVA | Inspection lot + UD |
| ES_SAPLQEEV | SAPLQEEV | Results recording |
| ES_SAPLQMSS | SAPLQMSS | Quality notifications |
| ES_SAPLQPLA | SAPLQPLA | Inspection planning |
| ES_SAPLQCAT | SAPLQCAT | Catalogs |

## 4. Custom Fields (S/4HANA Key User)

### Extensible Objects
```
Key User Extensibility (sin codigo):
- Inspection lot → custom fields en QALS
- Quality notification → custom fields en QMEL
- Notification item → custom fields en QMFE
- Results → custom fields en QASR
```

### Configuracion
```
1. App: Custom Fields and Logic (F1481)
2. Seleccionar business context (Inspection Lot / Notification)
3. Crear campo (tipo, label, help text)
4. Publicar → campo aparece en Fiori + CDS
5. Opcionalmente: custom logic (determinations, validations)
```

### Limitaciones
```
- Solo para Fiori apps (no GUI)
- Tipos: texto, numero, fecha, booleano, value help
- Max campos custom por objeto: ~50
- No soporta tablas custom anidadas
```

## 5. Custom CDS Views

### Ejemplo: Vista Analitica Custom
```sql
@AbapCatalog.sqlViewName: 'ZV_QM_LOT_ANL'
@Analytics.dataCategory: #CUBE
define view ZI_QM_InspLotAnalysis
  as select from qals as q
  left outer join qave as v on q.prueflos = v.prueflos
{
  key q.prueflos,
  q.matnr,
  q.werk,
  q.art,
  q.charg,
  q.erdat,
  v.vcode,
  v.vdatum,
  @Semantics.quantity.unitOfMeasure: 'meins'
  q.lmenge01 as lot_size,
  q.meins,

  @DefaultAggregation: #SUM
  case when v.vcode like 'A%' then 1 else 0 end as accepted_count,

  @DefaultAggregation: #SUM
  case when v.vcode like 'R%' then 1 else 0 end as rejected_count,

  @DefaultAggregation: #SUM
  1 as total_count
}
```

### Ejemplo: Vista Consumption
```sql
@AbapCatalog.sqlViewName: 'ZV_QM_LOT_Q'
@OData.publish: true
define view ZC_QM_InspLotQuery
  as select from ZI_QM_InspLotAnalysis
{
  key prueflos,
  matnr,
  werk,
  art,
  erdat,
  vcode,
  lot_size,
  meins,
  accepted_count,
  rejected_count,
  total_count,

  division(accepted_count * 100, total_count, 2) as fpy_pct
}
```

## 6. Custom OData Services

### API Extension
```
Pasos:
1. Crear CDS view con @OData.publish: true
2. O crear service definition (SRVD) + binding (SRVB)
3. Implementar CRUD si necesario (managed/unmanaged)
4. Registrar en /IWFND/MAINT_SERVICE
5. Test con /IWFND/GW_CLIENT
```

### Side-by-Side Extension (BTP)
```
SAP BTP → CAP service:
- Consume QM OData APIs
- Agrega logica custom
- UI5 frontend custom
- Event-driven (SAP Event Mesh)
```

## 7. Workflow Integration

### Standard Workflows QM
| Workflow | Trigger | Accion |
|----------|---------|--------|
| WS20000075 | Notification created | Notify responsible |
| WS20000076 | Task overdue | Escalation |
| WS20000077 | UD required | Notify quality engineer |

### Custom Workflow
```
1. SWDD → crear workflow template
2. Trigger: evento QM (e.g., aviso prioridad 1)
3. Steps: aprobacion, revision, firma
4. Agents: por rol, organizacion, regla
5. Deadline: escalacion automatica
```

### Flexible Workflow (S/4HANA)
```
S/4HANA Flexible Workflow:
- My Inbox (Fiori) para aprobaciones
- Workflow templates configurables sin ABAP
- Condiciones basadas en campos QM
- Multi-step approval chains
```

## 8. Output Management

### SmartForms / Adobe Forms QM
| Output | Uso | Form |
|--------|-----|------|
| Certificate of Analysis | Certificado con entrega | QM_CERTIFICATE |
| Inspection Report | Reporte inspeccion | QM_INSP_REPORT |
| Notification Print | Impresion aviso | QM_NOTIFICATION |

### Configuracion Output
```
1. NACE → condicion output QM
2. Asignar programa print + form
3. Trigger: automatico (entrega) o manual
4. Medio: impresora, email, EDI, PDF
```

## 9. Escenarios Comunes de Extension

### Auto-create Notification on Reject
```abap
" En BAdI QINSP_USAGE_DECISION
METHOD if_qinsp_usage_decision~after_usage_decision.
  IF iv_ud_code CP 'R*'.
    " Crear aviso Q3 automaticamente
    CALL FUNCTION 'BAPI_QUALNOT_CREATE'
      EXPORTING
        notif_type = 'Q3'
        ...
  ENDIF.
ENDMETHOD.
```

### Custom Valuation Logic
```abap
" En BAdI QINSP_RESULT_RECORD
METHOD if_qinsp_result_record~valuate_result.
  " Logica custom de valoracion
  " Ej: combinar multiples MICs para resultado compuesto
  IF lv_combined_score < lv_threshold.
    ev_valuation = 'R'.  " Reject
  ELSE.
    ev_valuation = 'A'.  " Accept
  ENDIF.
ENDMETHOD.
```

### Vendor Block on Quality Failure
```abap
" En user exit QQMA0002 o BAdI QINSP_USAGE_DECISION
" Si N rechazos consecutivos → bloquear proveedor
SELECT COUNT(*) FROM qals AS q
  JOIN qave AS v ON q~prueflos = v~prueflos
  WHERE q~lifnr = @iv_vendor
    AND q~art = '01'
    AND v~vcode LIKE 'R%'
  ORDER BY q~erdat DESCENDING
  INTO @DATA(lv_reject_count)
  UP TO 3 ROWS.

IF lv_reject_count >= 3.
  " Bloquear proveedor via BAPI
ENDIF.
```
