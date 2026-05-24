# Guias de Configuracion IMG (SPRO) — QM

## 1. Basic Settings

### QM Control Parameters (TQ01)
```
SPRO → Quality Management → Basic Settings → Define QM Control Parameters
```
- Control por centro (plant)
- Activar/desactivar QM por planta
- Parametros generales: catalogos, numeracion

### Number Ranges (TQ06)
```
SPRO → QM → Basic Settings → Maintain Number Ranges
```
| Objeto | Rango tipico | Uso |
|--------|-------------|-----|
| QMEL | 1000000000-1999999999 | Avisos calidad |
| QALS | 100000000-199999999 | Lotes inspeccion |
| PLKO (Q) | — | Planes inspeccion |

### Catalogs (TQ02, TQ04)
```
SPRO → QM → Basic Settings → Define Catalog Types
SPRO → QM → Basic Settings → Define Catalog Categories
```
| Catalogo | Tipo | Uso |
|----------|------|-----|
| 1 | Defect types | Items defecto |
| 5 | Defect causes | Causas |
| 6 | Activities | Actividades/tareas |
| 9 | Usage decision | Codigos UD |
| C | Characteristics attributes | Valoracion MIC |

## 2. Inspection Planning

### Inspection Types (TQ70, OQI3)
```
SPRO → QM → Inspection Lot Creation → Define Inspection Types
```
| Config | Descripcion |
|--------|-------------|
| Lot creation | Auto/manual |
| Plan determination | Plan, material spec, sin plan |
| Stock posting | QI stock, unrestricted |
| Partial lot | Permitir parcial |

### Inspection Lot Origin (TQ73)
```
SPRO → QM → Inspection Lot Creation → Define Origin
```
- 01: Goods receipt (vendor)
- 03: In-process (production)
- 04: Final inspection (production GR)
- 08: Stock transfer
- 09: Recurring
- 10: Source inspection
- 12: Customer returns
- 14: Certificates
- 89: Manual/other

### Automatic Lot Creation (TQ74)
```
SPRO → QM → Inspection Lot Creation → Automatic Lot Creation
```
- Asignar tipo inspeccion a movimiento
- Condiciones: tipo movimiento, centro, tipo material
- Control: crear automaticamente si/no

### Sampling Procedures (QDPK, QDPP)
```
SPRO → QM → Inspection Planning → Sampling → Define Sampling Procedures
```
| Parametro | Opciones |
|-----------|----------|
| Sampling type | Fixed, percentage, sampling scheme |
| Valuation mode | Attributive, variable |
| Sample size | Fija, por tabla AQL |
| Inspection points | Con/sin |

### Sampling Schemes (QDPA)
```
SPRO → QM → Inspection Planning → Sampling → Define Sampling Schemes
```
- Basado en AQL (ISO 2859-1)
- Niveles: I, II, III
- Switching rules: normal → tightened → reduced

## 3. Usage Decision

### UD Catalogs (TQ76)
```
SPRO → QM → Inspection → Usage Decision → Assign Catalogs
```
- Asignar catalogo tipo 9 al tipo inspeccion
- Codigos: Accept (A), Reject (R), Conditional (AC), etc.

### Follow-Up Actions (TQ75)
```
SPRO → QM → Inspection → Usage Decision → Define Follow-Up Actions
```
| Accion | Descripcion |
|--------|-------------|
| Stock posting | 321, 322, 551 |
| Create notification | Q1, Q2, Q3 automatico |
| Update quality score | Para dynamic modification |
| Update vendor eval | Para tipo 01 |
| Batch classification | Actualizar clase batch |

### Stock Posting for UD (TQSS)
```
SPRO → QM → Inspection → Usage Decision → Stock Posting
```
- Mapeo: codigo UD → tipo movimiento
- Accept → 321 (QI → libre)
- Reject → 322 (QI → bloqueado) o 551 (scrap)

## 4. Quality Notifications

### Notification Types (TQ80)
```
SPRO → QM → Quality Notifications → Define Notification Types
```
| Tipo | Nombre | Uso |
|------|--------|-----|
| Q1 | Internal problem | Problemas internos |
| Q2 | Customer complaint | Reclamaciones cliente |
| Q3 | Vendor complaint | Reclamaciones proveedor |
| Q4 | Audit finding | Hallazgos auditoria |
| QM | General | Generico |

### Notification Control (TQ81)
```
SPRO → QM → Quality Notifications → Define Notification Type Control
```
- Screen control por tipo
- Campos obligatorios
- Status profile
- Partner determination
- Number range

### Priority Types (TQ82)
```
SPRO → QM → Quality Notifications → Define Priority Types
```
| Prioridad | Descripcion | Tiempo respuesta |
|-----------|-------------|-----------------|
| 1 | Very high | Inmediato |
| 2 | High | 24h |
| 3 | Medium | 72h |
| 4 | Low | 1 semana |

## 5. Dynamic Modification

### Dynamic Modification Rules (T160D)
```
SPRO → QM → Inspection → Dynamic Modification → Define Rules
```
| Parametro | Config |
|-----------|--------|
| Stages | Tightened → Normal → Reduced → Skip |
| Switching rules | N lotes buenos para cambiar nivel |
| Quality score | Criterio para cambio |
| Scope | Material, proveedor, combinacion |

## 6. Certificates

### Certificate Profiles (QCPR)
```
SPRO → QM → Quality Certificates → Define Certificate Profiles
```
- Tipo certificado (CoA, CoC, test report)
- Datos a incluir (MICs, resultados, lote)
- Output: SmartForm, PDF
- Trigger: automatico con entrega o manual

### Inbound Certificates
```
SPRO → QM → Quality Certificates → Define Inbound Certificate Requirements
```
- Procurement key → requiere certificado
- Bloquear GR sin certificado
- Registro via QC51

## 7. Quality Score / Vendor Evaluation

### Quality Score
```
SPRO → QM → Quality Inspection → Dynamic Mod → Quality Score
```
- Calculo basado en historial UD
- Pesos por tipo defecto
- Umbral para cambio de nivel inspeccion

### Vendor Evaluation QM
```
SPRO → MM → Purchasing → Vendor Evaluation → Quality Criteria
```
- Subcriteria calidad (automatic/semi-auto/manual)
- Ponderacion en evaluacion general
- Fuente: quality score de lotes inspeccion

## 8. SPC / Control Charts
```
SPRO → QM → Quality Inspection → SPC → Define Control Chart Types
```
| Tipo | Uso |
|------|-----|
| X-bar / R | Media y rango |
| X-bar / S | Media y desv. estandar |
| p chart | Proporcion defectuosos |
| c chart | Numero defectos |
| np chart | Numero defectuosos |
| u chart | Defectos por unidad |

## 9. Material Master QM View
```
MM02 → Vista Quality Management
```
| Campo | Descripcion |
|-------|-------------|
| Inspection type | Tipos activos (01, 03, 04, etc.) |
| QM procurement key | Clave para GR inspection |
| QM control key | Control de inspeccion |
| Certificate type | Tipo certificado requerido |
| Inspection interval | Para tipo 09 (recurring) |

## Checklist Implementacion QM

```
1. [ ] Activar QM en planta (TQ01)
2. [ ] Rangos numeros (QALS, QMEL)
3. [ ] Catalogos (defectos, causas, actividades, UD)
4. [ ] Tipos inspeccion (TQ70)
5. [ ] Origen lote (TQ73)
6. [ ] Sampling procedures (QDV1)
7. [ ] MICs maestras (QS21)
8. [ ] Planes inspeccion (QP01)
9. [ ] Material master QM view (MM02)
10. [ ] UD codes + follow-up (TQ76, TQ75)
11. [ ] Stock posting (TQSS)
12. [ ] Notification types (TQ80)
13. [ ] Dynamic modification (T160D)
14. [ ] Certificates (si aplica)
15. [ ] Vendor evaluation QM (si aplica)
16. [ ] Autorizaciones QM
17. [ ] Test end-to-end
```
