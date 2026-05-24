# Analisis de Causa Raiz — Metodologia PS

## Indice
1. Framework de Diagnostico PS
2. Clasificacion de Incidentes
3. Decision Tree de Diagnostico
4. Queries MCP por Tipo de Incidente
5. Escenarios Comunes Resueltos Paso a Paso
6. Patrones de Error Recurrente
7. Herramientas de Diagnostico
8. Checklist de Cierre

---

## 1. Framework de Diagnostico PS

### 1.1 Metodologia de 5 Pasos

```
PASO 1: IDENTIFICAR
  ¿Cual es el sintoma exacto?
  ¿Transaccion/app donde ocurre?
  ¿Mensaje de error exacto (numero + texto)?
  ¿Desde cuando? ¿Reproducible?

PASO 2: CLASIFICAR
  ¿Categoria del problema?
  (presupuesto / status / liquidacion / fechas / costes / datos)

PASO 3: RECOPILAR DATOS
  Consultar tablas relevantes (queries MCP)
  Verificar Customizing (IMG)
  Revisar log de errores (SLG1)

PASO 4: IDENTIFICAR CAUSA RAIZ
  Descartar causas superficiales
  Buscar causa raiz (5 Whys)
  Documentar

PASO 5: SOLUCIONAR Y PREVENIR
  Aplicar solucion
  Validar resultado
  Documentar para prevenir recurrencia
```

### 1.2 Principio de Triaje

Antes de profundizar, aplicar triaje rapido:

| Sintoma | Primer Check | Herramienta |
|---------|-------------|-------------|
| Error al grabar proyecto | Status/autorizacion | BS02 / SU53 |
| Error al aprobar presupuesto | Perfil presupuesto / status | OPS9 / BS02 |
| Error en liquidacion | Regla de liquidacion / status | KO8G / BS02 |
| Costes no aparecen | Imputacion incorrecta | KSB1 / CJI3 |
| Fechas incorrectas | Programacion / calendario | SCAL / CN25 |
| Control disponibilidad falla | Configuracion tolerancias | OPS9 |

---

## 2. Clasificacion de Incidentes

### 2.1 CATEGORIA A: Problemas de Presupuesto

| Codigo | Incidente | Frecuencia |
|--------|-----------|------------|
| A01 | Error al aprobar presupuesto original | Alta |
| A02 | Control disponibilidad no funciona | Alta |
| A03 | Exceso de presupuesto inesperado | Media |
| A04 | Traslado de presupuesto falla | Media |
| A05 | Presupuesto suplementario bloqueado | Baja |
| A06 | Inconsistencia BPGE vs RPSCO | Baja |

### 2.2 CATEGORIA B: Problemas de Status

| Codigo | Incidente | Frecuencia |
|--------|-----------|------------|
| B01 | No se puede liberar el proyecto (REL) | Alta |
| B02 | No se puede cerrar tecnicamente (TECO) | Alta |
| B03 | Status usuario no disponible | Media |
| B04 | Transicion de status bloqueada | Media |
| B05 | Status inconsistente (JEST vs JSTO) | Baja |

### 2.3 CATEGORIA C: Problemas de Liquidacion

| Codigo | Incidente | Frecuencia |
|--------|-----------|------------|
| C01 | Liquidacion termina con error | Alta |
| C02 | Regla de liquidacion no definida | Alta |
| C03 | Receptor de liquidacion invalido | Media |
| C04 | Liquidacion a AuC falla | Media |
| C05 | Doble liquidacion / importes erroneos | Baja |
| C06 | Liquidacion de costes estadisticos | Baja |

### 2.4 CATEGORIA D: Problemas de Costes

| Codigo | Incidente | Frecuencia |
|--------|-----------|------------|
| D01 | Costes no aparecen en WBS | Alta |
| D02 | Costes duplicados | Media |
| D03 | Plan de costes incorrecto | Media |
| D04 | Compromisos no se actualizan | Media |
| D05 | Imputacion a proyecto incorrecta | Alta |

### 2.5 CATEGORIA E: Problemas de Fechas/Programacion

| Codigo | Incidente | Frecuencia |
|--------|-----------|------------|
| E01 | Fechas de red no se calculan | Media |
| E02 | Duracion de actividad incorrecta | Baja |
| E03 | Calendario de fabrica erroneo | Baja |
| E04 | Fechas WBS inconsistentes | Media |

---

## 3. Decision Tree de Diagnostico

### 3.1 Arbol para Errores de Presupuesto

```
¿Error al aprobar presupuesto?
│
├── ¿Mensaje "Status no permite"?
│   └── → Verificar BS02: perfil de status del proyecto
│       → ¿Transicion KOBU permitida desde status actual?
│       → Si NO: cambiar status o modificar perfil BS02
│
├── ¿Mensaje "Sin autorizacion"?
│   └── → SU53: verificar objeto C_PRPS_KOK
│       → Agregar autorizacion al rol del usuario
│
├── ¿Mensaje "Perfil de presupuesto no encontrado"?
│   └── → Verificar OPS9: perfil asignado al proyecto
│       → Verificar OPSA: perfil en config proyecto
│
└── ¿Control disponibilidad dispara error?
    ├── ¿Para todos los proyectos?
    │   └── → OPS9: revisar tolerancias globales
    │
    └── ¿Para un proyecto especifico?
        ├── → CJI3: verificar presupuesto vs actual
        └── → BPGE: verificar importe liberado
```

### 3.2 Arbol para Errores de Liquidacion

```
¿Error en liquidacion (CJ88/CJ8G)?
│
├── "Regla de liquidacion no existe"
│   └── → CJ20N → WBS → Extras → Regla de liquidacion
│       → Definir receptor (CTR, AuC, G/L, etc.)
│       → Verificar OKO7: perfil de liquidacion
│
├── "Receptor invalido/no existe"
│   ├── Receptor = Centro de coste → KS03: verificar existe + activo
│   ├── Receptor = Activo fijo    → AS03: verificar existe + no bloqueado
│   └── Receptor = WBS            → CJ03: verificar existe + liberado
│
├── "Status no permite liquidar"
│   └── → JEST: verificar status del WBS origen
│       → TECO o REL requerido para liquidar
│       → Si CRTD: liberar primero
│
├── "Sociedad no autorizada"
│   └── → OKO7: verificar sociedad en perfil
│       → SU01: verificar parametros usuario
│
└── "Error en calculo de importe"
    └── → CJI3: ver costes reales en WBS
        → CJ8G: revisar log detallado
        → Verificar configuracion de claves de equivalencia
```

### 3.3 Arbol para Costes No Encontrados

```
¿Costes no aparecen en el proyecto?
│
├── ¿El documento FI fue contabilizado?
│   └── → FB03: verificar documento existe y status
│       → Ver imputacion en posicion (campo Objeto CO)
│
├── ¿Imputacion correcta en el documento?
│   └── → Verificar campo AUFNR (red) o PSPNR (WBS)
│       → Si incorrecto: storno (FB08) y recontabilizar
│
├── ¿Costes de pedido de compra?
│   └── → EKPO: verificar campo PS_PSP_PNR (WBS asignado)
│       → EKKO: verificar sociedad y tipo de pedido
│       → ME2J: ver pedidos por proyecto
│
└── ¿Costes de horas (CATS)?
    └── → CAT5: verificar entradas de tiempo confirmadas
        → Verificar asignacion actividad de red
        → CAT6: verificar transferencia a CO
```

---

## 4. Queries MCP por Tipo de Incidente

### 4.1 Query: Estado de Presupuesto (Incidente A)

```sql
-- Verificacion rapida de presupuesto vs consumo
SELECT
    prps.POSID                              AS WBSElement,
    bpge.WLGES                             AS Budget_Total,
    bpge.WLIBFR                            AS Budget_Liberado,
    COALESCE(rps_act.Real, 0)              AS Costes_Reales,
    COALESCE(rps_obl.Compromisos, 0)       AS Compromisos,
    bpge.WLIBFR
        - COALESCE(rps_act.Real, 0)
        - COALESCE(rps_obl.Compromisos, 0) AS Disponible,
    CASE
        WHEN bpge.WLIBFR - COALESCE(rps_act.Real,0)
                         - COALESCE(rps_obl.Compromisos,0) < 0
        THEN 'EXCEDIDO'
        WHEN bpge.WLIBFR = 0 THEN 'SIN PRESUPUESTO'
        ELSE 'OK'
    END                                     AS Estado
FROM PRPS
LEFT JOIN BPGE ON PRPS.OBJNR = BPGE.OBJNR AND BPGE.VORGA = 'KOBU'
LEFT JOIN (
    SELECT OBJNR, SUM(WKBTR) AS Real
    FROM RPSCO WHERE WRTTP = '10'
    GROUP BY OBJNR
) AS rps_act ON PRPS.OBJNR = rps_act.OBJNR
LEFT JOIN (
    SELECT OBJNR, SUM(WKBTR) AS Compromisos
    FROM RPSCO WHERE WRTTP IN ('40','41','43')
    GROUP BY OBJNR
) AS rps_obl ON PRPS.OBJNR = rps_obl.OBJNR
WHERE PRPS.PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = :proyecto)
ORDER BY Estado DESC, PRPS.POSID
```

### 4.2 Query: Status Actual WBS (Incidente B)

```sql
-- Todos los status activos de WBS del proyecto
SELECT
    prps.POSID                  AS WBSElement,
    jest.STAT                   AS CodigoStatus,
    tj02t.TXT04                 AS Abreviatura,
    tj02t.TXT30                 AS Descripcion,
    CASE jest.STAT
        WHEN 'E0001' THEN 'SISTEMA'
        WHEN 'E0002' THEN 'SISTEMA'
        WHEN 'E0003' THEN 'SISTEMA'
        WHEN 'E0004' THEN 'SISTEMA'
        WHEN 'E0005' THEN 'SISTEMA'
        ELSE 'USUARIO'
    END                         AS TipoStatus
FROM PRPS
JOIN JEST ON PRPS.OBJNR = JEST.OBJNR AND JEST.INACT = ''
JOIN TJ02T ON JEST.STAT = TJ02T.ISTAT AND TJ02T.SPRAS = 'S'
WHERE PRPS.POSID LIKE :wbs_mask
ORDER BY PRPS.POSID, TipoStatus, jest.STAT
```

### 4.3 Query: Regla de Liquidacion (Incidente C)

```sql
-- Reglas de liquidacion definidas por WBS
SELECT
    prps.POSID                  AS WBS_Origen,
    cobrb.KONTY                 AS TipoReceptor,
    cobrb.OBJNR                 AS Receptor_Interno,
    cobrb.PROZS                 AS PorcentajeEquivalencia,
    cobrb.LSTAR                 AS TipoActividad,
    cobrb.KSTAR                 AS ElementeCoste,
    CASE cobrb.KONTY
        WHEN 'KS' THEN 'Centro de Coste'
        WHEN 'AN' THEN 'Activo Fijo'
        WHEN 'PSP' THEN 'WBS Element'
        WHEN 'GL' THEN 'Cuenta Mayor'
        WHEN 'OR' THEN 'Orden Interna'
        ELSE cobrb.KONTY
    END                         AS DescripcionTipo,
    cobrb.PAOBJNR               AS Receptor_COPA,
    cobrb.VBELN                 AS PedidoVentas
FROM COBRB
JOIN PRPS ON COBRB.PSPNR = PRPS.PSPNR
WHERE PRPS.POSID LIKE :wbs_mask
ORDER BY PRPS.POSID
```

### 4.4 Query: Imputaciones por Proyecto (Incidente D)

```sql
-- Todos los documentos imputados al proyecto (real)
SELECT
    acd.BELNR                   AS Documento,
    acd.GJAHR,
    acd.BUDAT                   AS FechaContab,
    prps.POSID                  AS WBS,
    acd.KSTAR                   AS ElementeCoste,
    acd.HSL                     AS Importe,
    acd.WAERS                   AS Moneda,
    acd.AWTYP                   AS TipoOrigen,
    acd.AWKEY                   AS ReferenciaTipo,
    acd.USNAM                   AS Usuario
FROM ACDOCA AS acd
JOIN PRPS ON acd.PSPNR = PRPS.PSPNR
WHERE
    acd.RBUKRS = :sociedad
    AND acd.GJAHR = :ejercicio
    AND acd.PSPNR <> ''
    AND prps.POSID LIKE :wbs_mask
ORDER BY acd.BUDAT DESC, prps.POSID
```

### 4.5 Query: Compromisos Abiertos (Incidente D04)

```sql
-- Pedidos de compra con imputacion a proyecto
SELECT
    ekko.EBELN                  AS Pedido,
    ekpo.EBELP                  AS Posicion,
    ekpo.TXZ01                  AS Descripcion,
    ekpo.MENGE                  AS CantidadPedida,
    ekpo.WEMNG                  AS CantidadEntregada,
    (ekpo.MENGE - ekpo.WEMNG) * ekpo.NETPR AS ValorPendiente,
    ekko.WAERS                  AS Moneda,
    prps.POSID                  AS WBS,
    ekko.AEDAT                  AS FechaCreacion,
    ekko.LIFNR                  AS Proveedor
FROM EKPO
JOIN EKKO ON EKPO.EBELN = EKKO.EBELN
JOIN PRPS ON EKPO.PS_PSP_PNR = PRPS.PSPNR
WHERE
    ekko.LOEKZ = ''             -- No borrados
    AND ekpo.LOEKZ = ''
    AND ekpo.ELIKZ = ''         -- Suministro no completo
    AND prps.POSID LIKE :wbs_mask
ORDER BY ekko.AEDAT DESC
```

---

## 5. Escenarios Comunes Resueltos Paso a Paso

### Escenario 1: "No se puede liberar el proyecto" (B01)

**Sintoma:** Al intentar REL (liberar) el proyecto via CJ02, aparece mensaje de error.

**Paso 1: Identificar mensaje**
```
Ir a CJ02 → intentar cambiar status a REL
Anotar el numero de mensaje exacto (Ej: PS 123)
```

**Paso 2: Verificar perfil de status**
```
BS02 → buscar perfil de status del proyecto
→ Ir al status CRTD
→ Verificar si "REL" aparece como transicion permitida
→ Si NO aparece: agregar la transicion
→ Si aparece: verificar si hay pre-condiciones bloqueantes
```

**Paso 3: Verificar status actual**
```
Query: SELECT * FROM JEST WHERE OBJNR = 'PR{PSPNR}' AND INACT = ''
→ Listar todos los status activos
→ ¿Hay algun status de usuario que bloquee REL?
→ BS02: verificar business transactions bloqueadas por ese status
```

**Paso 4: Verificar autorizaciones**
```
SU53 → ejecutar intentando REL
→ Ver si hay objeto de autorizacion faltante
→ Tipico: C_PROJ_KOK (area de controlling)
```

**Resolucion:**
- Si es config BS02: agregar transicion o quitar bloqueo
- Si es status usuario bloqueante: remover ese status primero
- Si es autorizacion: agregar al rol en PFCG

---

### Escenario 2: "Liquidacion termina con error" (C01)

**Sintoma:** CJ8G termina con errores para algunos WBS. Status "error" en spool.

**Paso 1: Ver log detallado**
```
CJ8G → ejecutar → tras ejecucion → ver spool (SP02)
O: SLG1 → objeto SETTLEMENT → fecha del dia
→ Leer mensajes de error exactos
```

**Paso 2: Verificar regla de liquidacion**
```
CJ20N → WBS con error → Extras → Settlement Rule
→ ¿Existe una regla definida?
→ Si NO: crear regla con receptor y porcentaje
→ Si SI: verificar que el receptor existe y esta activo
```

**Paso 3: Verificar status WBS**
```
JEST → buscar WBS problema
→ ¿Tiene status REL o TECO? (requerido para liquidar)
→ Si CRTD: liberar el WBS primero
→ Si CLSD: no se puede liquidar (ya cerrado)
```

**Paso 4: Verificar receptor**
```
Si receptor es Centro de Coste (KS):
  → KS03: verificar que existe, no bloqueado, valido en ese periodo

Si receptor es Activo Fijo (AN):
  → AS03: verificar que existe, no bloqueado

Si receptor es AuC:
  → AW01N: verificar el activo AuC
  → Verificar que tiene clase de activo correcta
```

**Paso 5: Ejecutar en modo test**
```
CJ8G → marcar "Test run" → ejecutar
→ Ver errores sin afectar datos
→ Corregir segun errores encontrados
→ Ejecutar real cuando test pasa
```

---

### Escenario 3: "Control disponibilidad bloquea pedido" (A02)

**Sintoma:** Al crear/liberar un pedido de compra con imputacion a WBS, el sistema bloquea por presupuesto excedido.

**Paso 1: Confirmar el exceso**
```
Query de presupuesto disponible (ver Query 4.1 arriba)
→ Verificar que efectivamente hay exceso
→ Si no hay exceso real → paso 2
→ Si hay exceso real → solicitar suplemento (CJ36/CJ37)
```

**Paso 2: Verificar configuracion de tolerancias**
```
OPS9 → seleccionar perfil de presupuesto del proyecto
→ Tolerance limits → verificar % configurado
→ ¿Es demasiado restrictivo (0%)?
→ ¿Esta la clave de tolerancia correctamente asignada?
```

**Paso 3: Verificar si hay excepciones**
```
SPRO → PS → Budget → Exempt Cost Elements
→ ¿El elemento de coste del pedido esta exento?
→ Si deberia estar exento: agregar
```

**Paso 4: Opcion temporal**
```
Si es urgente y hay presupuesto real disponible:
1. CJ37: liberar presupuesto adicional (suplemento)
2. O: aumentar tolerancia temporalmente
3. O: aprobar suplemento de presupuesto
```

---

### Escenario 4: "Costes de pedido no aparecen en WBS" (D01)

**Sintoma:** Hay pedidos de compra con imputacion a WBS pero no se ven en S_ALR o CJI3.

**Paso 1: Verificar el pedido**
```
ME23N → abrir pedido → posicion
→ Campo "Asignacion de cuenta" → tipo P (WBS)
→ Campo "Elemento WBS" → verificar que es el correcto
```

**Paso 2: Verificar compromisos**
```
CJI5 o RPSCO con WRTTP='41'
→ ¿Aparece el compromiso (pedido)?
→ Si NO: problema en imputacion del pedido

Query:
SELECT * FROM RPSCO
WHERE OBJNR = 'WBS{PSPNR}' AND WRTTP = '41'
→ Verificar si el pedido actualizo RPSCO
```

**Paso 3: Verificar entrada de mercancias**
```
ME23N → pedido → historial
→ ¿Ha habido entradas de mercancias?
→ Si SI: los costes reales deben estar en ACDOCA
→ Si NO: solo hay compromiso (RPSCO WRTTP=41)
```

**Paso 4: Verificar ACDOCA**
```
SELECT * FROM ACDOCA
WHERE PSPNR = '{WBS_INTERNO}'
  AND GJAHR = '{AÑO}'
→ ¿Aparecen los documentos de GR?
→ Si NO: verificar configuracion de valuacion (OMJJ)
```

---

### Escenario 5: "Presupuesto liberado difiere del aprobado" (A06)

**Sintoma:** En reports, presupuesto liberado (WLIBFR) es menor al total (WLGES).

**Explicacion:** En SAP PS, el presupuesto puede aprobarse en bloque pero liberarse parcialmente (por ejercicio o por fase).

**Verificacion:**
```
CJ31 → ver presupuesto total del proyecto
CJ30 → ver liberacion de presupuesto
→ Comparar WLGES vs WLIBFR en BPGE/BPJA

Si la diferencia es intencional:
→ CJ32: liberar la parte pendiente
→ O es por diseño (liberacion por fases)

Si es error:
→ Verificar transacciones de presupuesto en CJI8
→ Buscar liberaciones parciales no intencionadas
```

---

## 6. Patrones de Error Recurrente

### 6.1 Patron: Proyecto sin Perfil de Liquidacion

**Sintoma:** Error al ejecutar CJ8G — "Perfil de liquidacion no encontrado"
**Causa raiz:** WBS creado sin asignar perfil de liquidacion (OKO7)
**Prevencion:** Asignar perfil por defecto en perfil de proyecto (OPSA)

```
Solucion:
1. CJ20N → WBS → Detalles → campo "Settlement Profile"
2. Asignar el perfil correcto (ej: PS01)
3. Grabar
```

### 6.2 Patron: Status TECO sin Liquidar

**Sintoma:** WBS con TECO pero saldo no liquidado
**Causa raiz:** Se aplico TECO sin ejecutar liquidacion final
**Prevencion:** Checklists de cierre obligatorias

```
Solucion:
1. Verificar saldo en CJI3
2. Ejecutar liquidacion final (CJ88, modo FUL)
3. Verificar saldo = 0
4. Si es correcto, aplicar CLSD
```

### 6.3 Patron: Compromisos "Fantasma"

**Sintoma:** RPSCO muestra compromisos pero no hay pedidos activos
**Causa raiz:** Pedidos borrados sin actualizar compromisos de PS
**Prevencion:** Usar CJBV para reconcilar

```
Solucion:
Transaccion: CJBV (Recalcular compromisos)
  → Seleccionar proyecto
  → Ejecutar en modo test primero
  → Ejecutar real para reconcilar
```

### 6.4 Patron: Doble Imputacion por Storno/Recargo

**Sintoma:** Costes duplicados en WBS
**Causa raiz:** Recargo calculado sobre costes que ya incluian recargos previos
**Diagnostico:**

```sql
-- Identificar posibles duplicados
SELECT
    acd.KSTAR,
    COUNT(*) AS Num_Doc,
    SUM(acd.HSL) AS Total,
    MIN(acd.BUDAT) AS Primera,
    MAX(acd.BUDAT) AS Ultima
FROM ACDOCA AS acd
WHERE acd.PSPNR = :wbs_pspnr
  AND acd.GJAHR = :ejercicio
GROUP BY acd.KSTAR
HAVING COUNT(*) > 2  -- Sospechoso si hay muchos para mismo elemento
ORDER BY Num_Doc DESC
```

### 6.5 Patron: Fechas WBS Inconsistentes con Red

**Sintoma:** Fechas de WBS no coinciden con fechas de actividades en la red
**Causa raiz:** Programacion de red no actualizo WBS, o WBS fijado manualmente

```
Solucion:
CN25 o CJ20N → ejecutar programacion
  → Modo: "Schedule + Update WBS Dates"
  → Verificar que no hay fechas fijadas (flag fixado)
```

### 6.6 Patron: Control Disponibilidad Activo sin Presupuesto

**Sintoma:** Todos los pedidos se bloquean aunque el proyecto deberia estar exento
**Causa raiz:** Perfil de presupuesto activa control pero no hay presupuesto aprobado
**Prevencion:** Para proyectos sin presupuesto formal, usar perfil sin control de disponibilidad

```
Solucion rapida:
CJ32 → aprobar presupuesto suficiente
O: cambiar perfil de presupuesto del proyecto a uno sin control
```

---

## 7. Herramientas de Diagnostico

### 7.1 Transacciones Clave

| Transaccion | Uso de Diagnostico |
|-------------|-------------------|
| `CJI3` | Ver items reales de WBS (drill-through) |
| `CJI5` | Ver items de redes |
| `CJI8` | Ver documentos de presupuesto |
| `CJBV` | Reconcilar compromisos de proyecto |
| `CJN2` | Verificar consistencia de proyecto |
| `SLG1` | Log de aplicacion (errores batch) |
| `SM37` | Monitor de jobs (errores en background) |
| `SU53` | Verificar autorizaciones faltantes |
| `FB03` | Ver documento FI individual |
| `ME23N` | Ver pedido de compra |
| `KSB1` | Items reales de centro de coste |

### 7.2 Transaccion CJN2 — Verificacion de Consistencia

**Descripcion:** Verifica la consistencia interna de datos del proyecto.

```
CJN2 → seleccionar proyecto
→ Checks:
  - Jerarquia WBS (PRHI vs PRPS)
  - Status vs datos (JEST vs JSTO)
  - Compromisos (RPSCO vs tablas origen)
  - Presupuesto (BPGE vs BPJA)
→ Resultado: lista de inconsistencias encontradas
→ Opcion "Repair": corregir inconsistencias automaticamente
```

### 7.3 Log de Aplicacion (SLG1)

```
SLG1 → Objeto: SETTLEMENT (liquidacion)
      → Objeto: BUDGET (presupuesto)
      → Objeto: PS (general)
      → Fecha: hoy o rango
→ Ver mensajes con nivel E (error) o A (abend)
→ Drill-down para ver contexto completo del error
```

### 7.4 CJBV — Reconciliacion de Compromisos

```
CJBV → proyecto o lista de proyectos
     → Test run primero
     → Ver diferencias entre RPSCO y tablas origen (EKPO, RESB)
     → Si diferencias: ejecutar real para corregir
```

---

## 8. Checklist de Cierre de Incidentes

```
[ ] Sintoma documentado con mensaje exacto
[ ] Causa raiz identificada (no sintoma superficial)
[ ] Solucion aplicada en sistema
[ ] Validacion: el problema ya no ocurre
[ ] Impacto verificado: no se introdujeron nuevos errores
[ ] Datos corregidos si habia datos inconsistentes
[ ] Documentacion actualizada (si es nuevo patron)
[ ] Prevencion: ¿es necesario cambiar config o proceso?
[ ] Comunicacion al usuario/PM: solucion y pasos preventivos
[ ] Ticket cerrado con descripcion completa de causa + solucion
```

---

*Referencia: SAP PS Troubleshooting Guide | SAP Note 1640756 (PS Settlement)*
*SAP Notes relevantes: 1640756, 2078604, 1918760, 897280 (presupuesto)*
