# Compliance por Industria

## ISO 9001 — Quality Management System

| Requisito ISO | Funcionalidad SAP QM |
|---------------|---------------------|
| 7.1.5 Monitoring & measuring resources | Calibracion (QM-PM) |
| 8.4 Control of externally provided | Inspeccion GR tipo 01, vendor evaluation |
| 8.5.1 Control of production | Inspeccion en proceso tipo 03 |
| 8.6 Release of products | Usage decision (QA11) |
| 8.7 Control of nonconforming | Quality notifications (QM01) |
| 9.1.3 Analysis and evaluation | SPC, quality reports |
| 10.2 Nonconformity and corrective action | Notifications + CAPA |
| 10.3 Continual improvement | Dynamic modification, trend analysis |

## GMP / Pharma (21 CFR Part 11)

### Requisitos clave

| Requisito | Solucion SAP |
|-----------|-------------|
| Electronic signatures | Digital signatures en UD |
| Audit trail | Change documents (CDHDR/CDPOS) |
| Access control | Autorizaciones SAP (roles) |
| Validated systems | CSV (Computer System Validation) |
| Batch traceability | Batch management + QM |
| Stability studies | Recurring inspection tipo 09 |
| Deviation management | Quality notifications |
| CAPA | Notification tasks + follow-up |

### Stability Study (tipo 09)

```
Material con shelf life
├── Lotes de estabilidad (batches seleccionados)
├── Programa de estudio (tiempo: 0, 3, 6, 12, 24, 36 meses)
├── Condiciones (temperatura, humedad)
├── Inspecciones periodicas (tipo 09, QA08)
├── Resultados registrados por intervalo
└── Tendencia: si degrada → ajustar shelf life
```

## Automotriz (IATF 16949 / APQP / PPAP)

| Requisito | Funcionalidad SAP |
|-----------|------------------|
| APQP (Advanced Product Quality Planning) | Project management (PS) + QM |
| PPAP (Production Part Approval) | Inspection lots + certificates |
| FMEA | Quality notifications como registro |
| Control Plan | Inspection plans (QP01) |
| SPC / Cpk | Control charts (QGC1) |
| 8D reports | Quality notifications (Q2/Q3) |
| Measurement System Analysis | Calibracion + R&R studies |

## Alimentos (HACCP / FSSC 22000)

| Requisito | Funcionalidad SAP |
|-----------|------------------|
| HACCP Critical Control Points | Inspection points en produccion |
| Traceability (1 up / 1 down) | Batch management + MATDOC |
| Allergen management | Batch classification |
| Shelf life / expiry | MCH1-VFDAT + recurring inspection |
| Supplier approval | Vendor evaluation + audit |
| Product recall | Batch where-used (MB56) |

## Electronica (IPC Standards)

| Requisito | Funcionalidad SAP |
|-----------|------------------|
| Incoming inspection | Tipo 01 |
| In-circuit test | Tipo 03 (in-process) |
| Final test | Tipo 04 |
| Reliability testing | Recurring inspection |
| First Article Inspection | Manual lot (QA01) |

## Digital Signatures

Para industrias reguladas (GMP, FDA):
- Firma electronica en UD
- Requiere customizing especifico
- Validacion con usuario/password
- Registrado en change documents

```
SPRO > Quality Management > Quality Inspection
└── Inspection Lot Processing
    └── Usage Decision
        └── Define Digital Signature
```
