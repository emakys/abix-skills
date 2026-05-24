# BAPIs, Extensiones y Exits QM

## BAPIs principales

### Lotes de inspeccion
| BAPI | Descripcion |
|------|-------------|
| BAPI_INSPLOT_GETLIST | Listar lotes inspeccion |
| BAPI_INSPLOT_GETDETAIL | Detalle lote |
| BAPI_INSPLOT_CREATE | Crear lote manual |
| BAPI_INSPLOT_SETUSAGEDECISION | Registrar UD |

### Resultados
| BAPI | Descripcion |
|------|-------------|
| BAPI_INSPRESULT_GETLIST | Listar resultados |
| BAPI_INSPRESULT_GETDETAIL | Detalle resultados |
| BAPI_INSPRESULT_RECORD | Registrar resultados |

### Avisos de calidad
| BAPI | Descripcion |
|------|-------------|
| BAPI_QUALNOT_CREATE | Crear aviso |
| BAPI_QUALNOT_CHANGE | Modificar aviso |
| BAPI_QUALNOT_GETLIST | Listar avisos |
| BAPI_QUALNOT_GETDETAIL | Detalle aviso |
| BAPI_QUALNOT_ADD_ITEM | Agregar item defecto |
| BAPI_QUALNOT_ADD_CAUSE | Agregar causa |
| BAPI_QUALNOT_ADD_TASK | Agregar tarea |
| BAPI_QUALNOT_COMPLNOTIF | Completar aviso |

### Planes
| BAPI | Descripcion |
|------|-------------|
| BAPI_INSPPLAN_GETLIST | Listar planes |
| BAPI_INSPPLAN_GETDETAIL | Detalle plan |

### Catalogos
| BAPI | Descripcion |
|------|-------------|
| BAPI_QMCATALOG_GETLIST | Listar catalogos |

## User Exits QM

### Lotes de inspeccion
| Exit | Programa | Descripcion |
|------|----------|-------------|
| QQMA0001 | SAPLQEVA | Creacion lote inspeccion |
| QQMA0002 | SAPLQEVA | UD follow-up actions |
| QQMA0003 | SAPLQEVA | Stock posting en UD |
| QQMA0005 | SAPLQEVA | Determinacion plan inspeccion |

### Avisos
| Exit | Programa | Descripcion |
|------|----------|-------------|
| QQMA0010 | SAPLQMSS | Notificacion — validaciones |
| QQMA0011 | SAPLQMSS | Notificacion — default values |
| QQMA0012 | SAPLQMSS | Notificacion — follow-up |

### Resultados
| Exit | Programa | Descripcion |
|------|----------|-------------|
| QQMA0006 | SAPLQEEV | Resultados — validacion |
| QQMA0007 | SAPLQEEV | Resultados — valoracion custom |

## BAdIs QM (S/4HANA)

### Inspection
| BAdI | Descripcion |
|------|-------------|
| QINSP_LOT_CREATE | Creacion lote inspeccion |
| QINSP_LOT_PROCESS | Procesamiento lote |
| QINSP_RESULT_RECORD | Registro resultados |
| QINSP_USAGE_DECISION | Decision de empleo |
| QINSP_STOCK_POSTING | Stock posting en UD |

### Notifications
| BAdI | Descripcion |
|------|-------------|
| QNOTIF_CREATE | Creacion aviso |
| QNOTIF_PROCESS | Procesamiento aviso |
| QNOTIF_STATUS_CHANGE | Cambio status aviso |

### Certificates
| BAdI | Descripcion |
|------|-------------|
| QCERT_CREATE | Creacion certificado |
| QCERT_PROCESS | Procesamiento certificado |

## CDS Views QM (S/4HANA)

| CDS View | Descripcion |
|----------|-------------|
| I_InspectionLot | Lote inspeccion |
| I_InspectionLotWithStatus | Lote con status |
| I_InspectionResult | Resultados |
| I_QualityNotification | Aviso calidad |
| I_QualityNotificationItem | Items aviso |
| I_QualityNotificationCause | Causas |
| I_QualityNotificationTask | Tareas |

## Programas clave QM

| Programa | Descripcion |
|----------|-------------|
| SAPLQEVA | Inspeccion — lotes y UD |
| SAPLQEEV | Resultados |
| SAPLQPLA | Planes de inspeccion |
| SAPLQMSS | Avisos de calidad |
| SAPLQCAT | Catalogos |
| RQEVA000 | Creacion masiva lotes |

## Enhancement Spots

| Enhancement Spot | Area |
|------------------|------|
| ES_SAPLQEVA | Inspection lot processing |
| ES_SAPLQEEV | Results recording |
| ES_SAPLQMSS | Quality notifications |
| ES_SAPLQPLA | Inspection planning |
