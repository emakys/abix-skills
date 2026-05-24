# Physical Samples y Temas Avanzados QM

## 1. Physical Sample Management

### Concepto
```
Muestra fisica = porcion del material tomada para inspeccion
- Registrada en QM con referencia a lote inspeccion
- Trazabilidad: quien tomo, cuando, donde se almacena
- Resultados vinculados a muestra especifica
```

### Transacciones
| TCode | Descripcion |
|-------|-------------|
| QPR1 | Crear physical sample |
| QPR2 | Modificar |
| QPR3 | Visualizar |
| QPR5 | Lista physical samples |
| QPR7 | Sample drawing (instrucciones) |

### Tablas
| Tabla | Descripcion |
|-------|-------------|
| QAPP | Physical sample header |
| QAPO | Physical sample items |
| QPRS | Sample drawing instructions |

### Flujo
```
Lote inspeccion creado
  → Physical sample drawing (QPR1)
  → Muestra tomada y etiquetada
  → Muestra enviada a laboratorio
  → Resultados registrados por muestra
  → Muestra retenida o destruida
  → Trazabilidad completa
```

### Campos Physical Sample
| Campo | Descripcion |
|-------|-------------|
| PROESSION | Sample number |
| PRUEFLOS | Inspection lot reference |
| ESSION_DATE | Sampling date |
| ESSION_TIME | Sampling time |
| PROBENEHMER | Sampler (person) |
| LAGERORT | Storage location (sample) |
| STATUS | Status (created/in-lab/completed/destroyed) |

## 2. Stability Studies

### Concepto
```
Estudio de estabilidad = inspeccion recurrente de batches
a intervalos definidos para verificar shelf life
- Regulatorio: ICH Q1A guidelines
- Pharma, alimentacion, quimica
```

### Configuracion
```
1. Material con batch management
2. Tipo inspeccion 09 (recurring) activo
3. Intervalo de inspeccion en QMAT
4. Plan inspeccion con MICs de estabilidad
5. QA08 → trigger automatico segun intervalo
```

### Flujo Stability Study
```
Batch producido → Muestra retenida
  → T=0: Inspeccion inicial (lote tipo 04)
  → T=3m: Inspeccion recurrente (lote tipo 09)
  → T=6m: Inspeccion recurrente
  → T=12m: Inspeccion recurrente
  → T=24m: Inspeccion final
  → Resultado: confirmar o reducir shelf life
```

## 3. Audit Management

### Tipos de Auditoria en QM
| Tipo | Aviso | Uso |
|------|-------|-----|
| Auditoria interna | Q4 | ISO 9001 internal audit |
| Auditoria proveedor | Q4 + Q3 | Supplier audit |
| Auditoria producto | Q4 | Product audit |
| Auditoria proceso | Q4 | Process audit (VDA 6.3) |
| Auditoria sistema | Q4 | System audit |

### Proceso Auditoria
```
1. Plan anual auditorias
2. Crear aviso Q4 (audit finding por hallazgo)
3. Checklist = items del aviso
4. Hallazgos = items con defect code
5. No conformidades → causas + acciones correctivas
6. Seguimiento tareas
7. Cierre auditoria
```

## 4. FMEA Integration

### Failure Mode and Effects Analysis
```
QM soporta FMEA via:
- Catalogo de modos de fallo (cat. tipo 1)
- Catalogo de causas (cat. tipo 5)
- Catalogo de acciones preventivas (cat. tipo 6)
- Severidad, ocurrencia, deteccion → RPN
```

### Mapeo FMEA → QM
| FMEA Element | QM Object |
|-------------|-----------|
| Failure Mode | Defect code (cat 1) |
| Cause | Cause code (cat 5) |
| Effect | Defect description |
| Current Control | Inspection plan / MIC |
| Action | Task in notification |
| RPN | Custom field or classification |

## 5. Laboratory Information Management (LIMS)

### Integracion QM-LIMS
```
Flujo:
1. Lote inspeccion creado en QM
2. Muestra enviada a LIMS (interface)
3. LIMS ejecuta analisis
4. Resultados devueltos a QM (interface)
5. UD en QM basada en resultados LIMS
```

### Interface Tipica
```
QM → LIMS: Sample request (BAPI/RFC/IDoc)
  - Material, batch, lote inspeccion
  - MICs requeridas, limites

LIMS → QM: Results (BAPI_INSPRESULT_RECORD)
  - Valores por MIC
  - Valoracion (pass/fail)
  - Certificado laboratorio
```

## 6. Nonconformance Management

### Proceso NC
```
Deteccion → Registro → Evaluacion → Disposicion → Accion → Cierre
    ↓          ↓          ↓            ↓            ↓         ↓
  Auto/    QM01       Severidad    Accept/      CAPA     Verificar
  Manual   (Q1)       impacto     Reject/                efectividad
                                  Rework/
                                  Scrap
```

### Categorias NC
| Categoria | Ejemplo | Disposicion tipica |
|-----------|---------|-------------------|
| Critica | Seguridad, regulatorio | Scrap / recall |
| Mayor | Fuera de spec, funcionalidad | Rework / reject |
| Menor | Cosmetico, etiquetado | Accept conditional |
| Observacion | Mejora potencial | Registro informativo |

## 7. CAPA (Corrective and Preventive Action)

### Flujo CAPA en QM
```
Problema detectado
  → Aviso calidad (Q1/Q2/Q3)
  → Contencion inmediata (tarea urgente)
  → Root cause analysis (5 Why, Ishikawa)
  → Causa registrada en aviso (QMUR)
  → Accion correctiva (tarea QMSM)
  → Accion preventiva (tarea QMSM)
  → Verificacion efectividad (tarea QMSM)
  → Cierre con evidencia
```

### Tracking CAPA
```sql
-- CAPAs abiertas con antigüedad
SELECT q.QMNUM, q.QMART, q.MATNR, q.ERDAT,
  s.MNGRP, s.MNCOD, s.ERLESSION AS completed,
  DATS_DAYS_BETWEEN(q.ERDAT, CURRENT_DATE) AS age_days
FROM QMEL q
JOIN QMSM s ON q.QMNUM = s.QMNUM
WHERE s.ERLESSION = '' -- no completada
ORDER BY age_days DESC
```

## 8. Control de Cambios (Change Control)

### QM + Engineering Change Management
```
Cambio en especificacion
  → ECO (Engineering Change Order)
  → Impacto en:
    - MICs (nuevos limites)
    - Plan inspeccion (nueva version)
    - Material spec
  → Validacion QM del cambio
  → Effectivity date
  → Historial de versiones
```

## 9. Environmental / Health / Safety (EHS) Integration

### QM + EHS
```
Sustancias peligrosas:
- MIC para concentracion sustancia
- Limites regulatorios como spec limits
- SDS (Safety Data Sheet) como documento adjunto
- Aviso calidad si excede limite EHS
- Notificacion automatica a EHS officer
```

## 10. Quality Gates

### Concepto
```
Quality gate = punto de decision go/no-go en proceso
  → Implementado como tipo inspeccion en cada gate
  → Gate pass = UD accept
  → Gate fail = stop process + aviso
```

### Ejemplo: Production Quality Gates
```
Gate 1: Incoming material (tipo 01)
  → Accept → liberar para produccion
Gate 2: In-process (tipo 03)
  → Accept → continuar produccion
Gate 3: Final inspection (tipo 04)
  → Accept → liberar producto
Gate 4: Pre-shipment (tipo 89 manual)
  → Accept → autorizar entrega
```

## 11. Supplier Portal Integration

### Flujo Portal Proveedor
```
Portal → SAP QM:
1. Proveedor sube certificado → QC51 (inbound cert)
2. Proveedor ve quality score → vendor evaluation
3. Proveedor responde Q3 → aviso actualizado
4. Proveedor ve spec requeridas → plan inspeccion

SAP QM → Portal:
1. Nuevo requisito calidad → notificacion proveedor
2. Rechazo lote → alerta con detalle
3. Solicitud accion correctiva → Q3 + tareas
4. Quality score actualizado → dashboard proveedor
```

## 12. Industry-Specific QM

### Automotive (IATF 16949)
```
- PPAP (Production Part Approval)
- Control plans → inspection plans
- FMEA mandatorio
- MSA (Measurement System Analysis)
- SPC obligatorio para caracteristicas criticas
- 8D para customer complaints
```

### Pharma (GMP / FDA 21 CFR)
```
- Validated system
- Electronic batch record
- Stability studies
- Digital signatures
- Audit trail completo
- Deviation management
- Out-of-specification (OOS) procedure
```

### Food (HACCP / FSSC 22000)
```
- Critical Control Points → MICs
- Monitoring → in-process inspection
- Corrective actions → notifications
- Verification → recurring inspection
- Traceability → batch genealogy
```
