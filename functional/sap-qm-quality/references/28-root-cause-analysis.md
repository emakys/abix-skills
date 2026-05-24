# Root Cause Analysis Framework — QM

## Metodologia de Diagnostico

### Paso 1: Identificar Sintoma
```
¿Que fallo?
├── Lote inspeccion no se crea → Seccion A
├── Resultados no se pueden registrar → Seccion B
├── UD no se puede completar → Seccion C
├── Aviso no se puede crear/cerrar → Seccion D
├── Stock no se mueve despues de UD → Seccion E
├── Certificado no se genera → Seccion F
├── Dynamic modification no funciona → Seccion G
└── Inspeccion no trigger automaticamente → Seccion H
```

## A. Lote Inspeccion No Se Crea

### Diagnostico
```sql
-- 1. Verificar QM view del material
SELECT MATNR, WERKS, ART, AKTESSION, HESSION
FROM QMAT WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- 2. Verificar tipo inspeccion activo
-- AKTESSION debe ser 'A' (activo)

-- 3. Verificar config tipo inspeccion
SELECT * FROM TQ70 WHERE ART = '{tipo}'

-- 4. Verificar procurement key (tipo 01)
SELECT * FROM EINE WHERE MATNR = '{mat}' AND LIFNR = '{prov}'
-- Campo QMATPROK debe tener valor
```

### Causas Comunes
| Causa | Verificacion | Solucion |
|-------|-------------|----------|
| QM view no mantenida | QMAT vacio | MM02 → QM view |
| Tipo inspeccion inactivo | AKTESSION != 'A' | MM02 → activar tipo |
| Sin procurement key | EINE sin QMATPROK | ME12 → QM key |
| Tipo movimiento no mapeado | TQ74 sin entry | SPRO → lot origin |
| Plan requerido pero no existe | PLKO sin plan type Q | QP01 crear plan |
| Material no relevante QM | Sin vista QM | Extender material |

## B. Resultados No Se Pueden Registrar

### Diagnostico
```sql
-- 1. Status del lote
SELECT PRUEFLOS, STAT FROM QALS WHERE PRUEFLOS = '{lote}'
-- Debe estar REL (I0002)

-- 2. Plan asignado
SELECT PLESSION, PLNTY, PLNNR FROM QALS WHERE PRUEFLOS = '{lote}'

-- 3. MICs existentes
SELECT * FROM PLMK
WHERE PLNTY = 'Q' AND PLNNR = '{plan}'

-- 4. Sampling determinado
SELECT * FROM QASR WHERE PRUEFLOS = '{lote}'
-- SOLLPROBE debe tener valor (sample size)
```

### Causas Comunes
| Causa | Verificacion | Solucion |
|-------|-------------|----------|
| Lote no liberado | Status != REL | Verificar config auto-release |
| Sin plan asignado | PLNNR vacio | QP01 crear / QMAT asignar |
| Plan sin MICs | PLMK vacio | QP02 agregar MICs |
| Sin sampling procedure | SOLLPROBE = 0 | QDV1 crear + asignar |
| Resultados ya confirmados | Status RCON | Solo reversar si permitido |
| Lote bloqueado | Status LOCK | Desbloquear |

## C. UD No Se Puede Completar

### Diagnostico
```sql
-- 1. Resultados confirmados?
SELECT PRUEFLOS, STAT FROM QALS WHERE PRUEFLOS = '{lote}'
-- Debe tener RCON (I0012)

-- 2. UD ya registrada?
SELECT * FROM QAVE WHERE PRUEFLOS = '{lote}'

-- 3. Catalogo UD disponible?
SELECT * FROM TQ76 WHERE ART = '{tipo_insp}'

-- 4. Stock disponible para posting?
SELECT LGORT, INSME FROM MARD
WHERE MATNR = '{mat}' AND WERKS = '{centro}'
```

### Causas Comunes
| Causa | Verificacion | Solucion |
|-------|-------------|----------|
| Resultados sin confirmar | Sin RCON | QE51N confirmar |
| UD ya existe | QAVE tiene registro | QA12 si cambio permitido |
| Sin catalogo UD | TQ76 vacio | SPRO → UD catalogs |
| Sin stock QI | INSME = 0 | Verificar movimiento GR |
| Lote cerrado | Status CLOSE | No modificable |

## D. Aviso No Se Puede Crear/Cerrar

### Diagnostico
```sql
-- 1. Tipo aviso permitido?
SELECT * FROM TQ80 WHERE QMART = '{tipo}'

-- 2. Autorizacion?
-- Objeto auth: Q_QMEL (crear), Q_QMTASKS (tareas)

-- 3. Tareas pendientes (para cierre)?
SELECT * FROM QMSM
WHERE QMNUM = '{aviso}' AND ERLESSION != 'X'

-- 4. Items obligatorios?
SELECT * FROM QMFE WHERE QMNUM = '{aviso}'
```

### Causas Comunes
| Causa | Solucion |
|-------|----------|
| Tipo no permitido | Verificar TQ80 + autorizaciones |
| Prioridad obligatoria | Indicar prioridad |
| Tareas sin completar | Completar tareas antes de cerrar |
| Items defecto requeridos | Agregar al menos un item |
| Campos obligatorios vacios | Completar campos requeridos |

## E. Stock No Se Mueve Despues de UD

### Diagnostico
```sql
-- 1. Configuracion stock posting
SELECT * FROM TQSS WHERE ART = '{tipo}' AND VCODE = '{ud_code}'

-- 2. Stock en QI
SELECT INSME, LGORT FROM MARD
WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- 3. Movimiento generado?
SELECT * FROM MATDOC
WHERE PRUEFLOS = '{lote}' AND BWART IN ('321','322','551')
```

### Causas Comunes
| Causa | Solucion |
|-------|----------|
| Sin config stock posting | SPRO → TQSS → mapear UD code a movimiento |
| Stock insuficiente en QI | Verificar MARD.INSME |
| Almacen bloqueado | Verificar MARC/T001L |
| Batch management | Verificar batch en lote vs stock |
| Follow-up no configurado | TQ75 → definir follow-up actions |

## F. Certificado No Se Genera

### Diagnostico
```sql
-- 1. Perfil certificado?
SELECT * FROM QCPR WHERE MATNR = '{mat}'

-- 2. Output condition?
-- NACE → verificar condicion QM

-- 3. Datos disponibles?
-- Lote inspeccion con UD completa
```

### Causas Comunes
| Causa | Solucion |
|-------|----------|
| Sin perfil certificado | QC21 crear perfil |
| Output no configurado | NACE → condicion QM |
| Sin resultados confirmados | Completar inspeccion primero |
| SmartForm incorrecto | Verificar formulario asignado |

## G. Dynamic Modification No Funciona

### Diagnostico
```sql
-- 1. Regla dynamic mod configurada?
SELECT * FROM T160D WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- 2. Quality score actual
SELECT * FROM QDEB WHERE MATNR = '{mat}' AND WERKS = '{centro}'

-- 3. Historial lotes
SELECT q.PRUEFLOS, q.ERDAT, v.VCODE
FROM QALS q JOIN QAVE v ON q.PRUEFLOS = v.PRUEFLOS
WHERE q.MATNR = '{mat}' AND q.WERK = '{centro}'
ORDER BY q.ERDAT DESC
```

### Causas Comunes
| Causa | Solucion |
|-------|----------|
| Sin regla definida | SPRO → T160D |
| Tipo inspeccion sin dyn mod | MM02 → QM view → activar |
| Historial insuficiente | Esperar N lotes |
| Quality score no actualiza | Verificar UD follow-up → update score |

## H. Inspeccion No Trigger Automaticamente

### Checklist
```
1. [ ] Material tiene QM view? (QMAT)
2. [ ] Tipo inspeccion activo? (AKTESSION = 'A')
3. [ ] Tipo movimiento mapeado? (TQ74)
4. [ ] Procurement key asignado? (EINE, para tipo 01)
5. [ ] Plan de inspeccion existe y released? (PLKO status)
6. [ ] Plan valido para fecha? (PLKO fecha validez)
7. [ ] Centro configurado para QM? (TQ01)
8. [ ] Tipo material excluido? (verificar exclusiones)
```

## Herramientas MCP para Diagnostico

```
-- Leer material QM view
MCP: SearchObject → buscar material
MCP: ExecuteQuery → SELECT FROM QMAT

-- Leer lote inspeccion
MCP: ExecuteQuery → SELECT FROM QALS WHERE PRUEFLOS = '{lote}'

-- Verificar status
MCP: ExecuteQuery → SELECT FROM JEST WHERE OBJNR = 'QM{lote}'

-- Leer resultados
MCP: ExecuteQuery → SELECT FROM QASR WHERE PRUEFLOS = '{lote}'

-- Leer aviso
MCP: ExecuteQuery → SELECT FROM QMEL WHERE QMNUM = '{aviso}'
```

## Escalation Path

```
Nivel 1: Datos maestros
  → Verificar QMAT, PLKO, QPMK
  → 70% de problemas se resuelven aqui

Nivel 2: Customizing
  → Verificar TQ70, TQ73, TQ74, TQ76, TQSS
  → 20% de problemas

Nivel 3: Autorizaciones / Workflow
  → Verificar roles, objetos auth, workflow config
  → 8% de problemas

Nivel 4: OSS / SAP Note
  → Buscar nota SAP en Launchpad
  → 2% de problemas
```
