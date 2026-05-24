# Migracion de Datos QM

## Objetos Migrables

### Prioridad 1 — Datos Maestros
| Objeto | Tabla destino | Tool migracion |
|--------|--------------|----------------|
| Master Inspection Chars (MIC) | QPMK | LSMW / BAPI_CHARACT_CREATE |
| Inspection Methods | QPMM | LSMW |
| Catalog Codes | QPCD, QPGT | QS41 batch input |
| Inspection Plans | PLKO, PLPO, PLMK | BAPI_INSPPLAN_CREATE / LSMW |
| Sampling Procedures | QDPK | QDV1 manual (pocos) |
| Material QM View | QMAT | MM02 (junto con maestro material) |

### Prioridad 2 — Datos Transaccionales (opcional)
| Objeto | Tabla destino | Migracion |
|--------|--------------|-----------|
| Inspection Lots (abiertos) | QALS | BAPI_INSPLOT_CREATE |
| Quality Notifications (abiertas) | QMEL | BAPI_QUALNOT_CREATE |
| Quality Scores | QDEB | Manual / custom program |

### No Migrar (regenerar)
```
- Lotes de inspeccion cerrados → historico, no operativo
- Resultados detallados → solo si regulatorio
- Avisos cerrados → solo si historico requerido
- Certificados emitidos → archivados, no migrar
```

## Estrategia de Migracion

### Fase 1: Preparacion
```
1. Inventario datos QM en sistema origen
2. Mapeo campos origen → destino
3. Limpieza datos (MICs duplicadas, planes obsoletos)
4. Validar dependencias:
   - MICs → necesitan metodos, catalogos
   - Planes → necesitan MICs, materiales, centros
   - QMAT → necesita material creado con QM view
```

### Fase 2: Datos Maestros Base
```
Orden de carga:
1. Catalogos (code groups + codes) → QS41
2. Inspection Methods → QS31 / LSMW
3. MICs → QS21 / BAPI / LSMW
4. Sampling Procedures → QDV1
5. Selected Sets → QS51
```

### Fase 3: Planes de Inspeccion
```
1. Crear planes (QP01) con:
   - Cabecera: material, centro, usage, status
   - Operaciones: numero, centro trabajo, clave control
   - MICs: asignacion a operacion, limites, sampling
   - Material assignment (PLAS)
2. Liberar planes (status = released)
3. Verificar determinacion automatica
```

### Fase 4: Material QM View
```
1. MM02 → extender QM view (batch o LSMW)
2. Campos:
   - Inspection types activos (01, 03, 04, etc.)
   - QM procurement key
   - Certificate type
   - Inspection interval (tipo 09)
3. Verificar QMAT despues de carga
```

### Fase 5: Datos Transaccionales (si aplica)
```
1. Avisos abiertos → BAPI_QUALNOT_CREATE
   - Solo avisos con acciones pendientes
   - Mantener numero original si posible
2. Lotes abiertos → BAPI_INSPLOT_CREATE
   - Solo lotes sin UD
   - Re-crear con referencia a plan
3. Quality scores → programa custom
   - Cargar historial para dynamic modification
```

## SAP Migration Cockpit (S/4HANA)

### Migration Objects QM
| Migration Object | Descripcion |
|-----------------|-------------|
| Inspection Plan | Planes con operaciones y MICs |
| Quality Notification | Avisos con items y tareas |
| Inspection Lot | Lotes (limitado) |
| Master Inspection Char | MICs maestras |

### Uso Migration Cockpit
```
1. LTMOM → Migration Cockpit
2. Seleccionar proyecto
3. Seleccionar migration object
4. Download template (Excel/XML)
5. Mapear datos origen → template
6. Upload → validar → simular → ejecutar
```

## LSMW para QM

### Recording: QS21 (Crear MIC)
```
Campos:
- VERWESSION → MIC number (external)
- KURZTEXT → Description
- MERKMAL → Char type (quantitative/qualitative)
- TOLERANZOB → Upper limit
- TOLERANZUN → Lower limit
- SOLLWERT → Target value
- MEESSION → Unit of measure
- PRUEFMETHODE → Inspection method
- STICHPROBENVERFAHREN → Sampling procedure
```

### Recording: QP01 (Crear Plan)
```
Campos cabecera:
- MATNR → Material
- WERKS → Plant
- VERESSION → Usage
- STTAG → Key date
Campos operacion:
- VORNR → Operation number
- ARBPL → Work center
- STESSION → Control key
Campos MIC:
- MERESSION → MIC reference
- PRUEFUMFANG → Sample size
```

## Validaciones Post-Migracion

### Checks Automaticos
```sql
-- MICs cargadas correctamente
SELECT COUNT(*) FROM QPMK WHERE ERDAT = '{fecha_carga}'

-- Planes con status correcto
SELECT PLNNR, STATU FROM PLKO
WHERE PLNTY = 'Q' AND ERDAT = '{fecha_carga}'
-- STATU debe ser '4' (released)

-- Material QM view activa
SELECT MATNR, WERKS, ART, AKTESSION FROM QMAT
WHERE ERDAT = '{fecha_carga}'

-- Plan determination funciona
-- Crear lote manual (QA01) → verificar que plan se asigna
```

### Test End-to-End
```
1. Crear pedido compra (ME21N)
2. Entrada mercancia (MIGO) → verificar lote creado
3. Registrar resultados (QE51N)
4. Decision empleo (QA11)
5. Verificar stock posting
6. Crear aviso calidad (QM01) → verificar catalogos
7. Certificado (QC31) → verificar perfil y datos
```

## Consideraciones Especiales

### Numeracion
```
- Definir rangos numeros nuevos o mantener
- MICs: numeracion interna vs externa
- Planes: numeracion interna (recomendado)
- Avisos: nuevo rango en destino
```

### Dependencias Cross-Module
```
QM necesita que esten migrados ANTES:
- Maestro material (con vista QM)
- Centros y almacenes (org structure)
- Proveedores / Business Partners
- Centros de trabajo (para planes)
- Clases y caracteristicas (para batch)
```

### Volumen Tipico
| Objeto | Volumen tipico | Metodo recomendado |
|--------|---------------|-------------------|
| Catalogos | 50-200 codes | QS41 manual o batch input |
| MICs | 100-1000 | LSMW / Migration Cockpit |
| Planes | 50-500 | LSMW / Migration Cockpit |
| QMAT entries | = materiales QM | MM02 batch (junto con material) |
| Sampling proc. | 10-50 | QDV1 manual |
