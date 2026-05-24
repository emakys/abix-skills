# Gestion de Status en SAP PS

## Introduccion

La **Gestion de Status** en SAP PS controla el ciclo de vida de los objetos del proyecto (proyectos, WBS, redes, actividades). Cada objeto tiene un status que determina que operaciones estan permitidas o prohibidas en ese momento. El sistema distingue entre **status de sistema** (gestionados por SAP) y **status de usuario** (definidos por el cliente).

---

## 1. Status de Sistema (Status SAP)

Los status de sistema son gestionados automaticamente por SAP cuando se realizan determinadas acciones. No pueden modificarse directamente por el usuario.

### 1.1 Tabla de Status de Sistema PS

| Status | Abreviatura | Descripcion | Como se activa |
|--------|-------------|-------------|----------------|
| **CREA** | Created | Objeto creado, sin liberar | Al crear WBS/red en CJ01/CJ02/CJ11 |
| **REL** | Released | Liberado para ejecucion | CJ02 → Editar → Status → Liberar, o CJ20N |
| **TECO** | Technically Complete | Completado tecnicamente | CJ02 → Status → Completar tecnicamente |
| **LKD** | Locked | Bloqueado (no permite postings) | CJ02 → Status → Bloquear |
| **DLFL** | Deletion Flag | Marcado para borrado | CJ02 → Editar → Marcar para borrado |
| **CLSD** | Closed | Cerrado definitivamente | Liquidacion final + cierre |
| **AVLB** | Available | Disponible (usado en ordenes) | Automatico al crear orden |
| **FNBL** | Final Billing | Factura final completada | Automatico en SD billing |
| **ASGN** | Assigned | Asignado a pedido de cliente | Automatico en SD |
| **PRC** | Procurement Blocked | Bloqueado para aprovisionamiento | Manual o por regla de negocio |

### 1.2 Transiciones de Status de Sistema

```
CREA
  |
  |--> [Liberar] --> REL
  |                    |
  |                    |--> [Completar tecnicamente] --> TECO
  |                    |                                    |
  |                    |                                    |--> [Cerrar] --> CLSD
  |                    |
  |                    |--> [Bloquear] --> LKD
  |                    |                    |
  |                    |                    |--> [Desbloquear] --> REL
  |
  |--> [Marcar borrado] --> DLFL
                              |
                              |--> [Quitar marca] --> CREA
```

### 1.3 Impacto de Cada Status en Operaciones

#### Status CREA (Creado)

| Operacion | Permitida |
|-----------|-----------|
| Modificar datos maestros | Si |
| Planificar costes | Si |
| Presupuestar | Si |
| Crear pedidos con imputacion | No |
| Confirmaciones de actividad | No |
| Contabilizar costes reales | No |
| Liquidar | No |

#### Status REL (Liberado)

| Operacion | Permitida |
|-----------|-----------|
| Modificar datos maestros | Si (limitado) |
| Planificar costes | Si |
| Presupuestar | Si |
| Crear pedidos con imputacion | Si |
| Confirmaciones de actividad | Si |
| Contabilizar costes reales | Si |
| Solicitudes de pedido automaticas | Si |
| Liquidar al WBS superior | Si |
| Reservas de material | Si |

#### Status TECO (Completado Tecnicamente)

| Operacion | Permitida |
|-----------|-----------|
| Modificar datos maestros | No |
| Planificar costes | No |
| Crear nuevos pedidos | No |
| Contabilizar en pedidos abiertos | Si (hasta cierre) |
| Confirmar actividades abiertas | Si (hasta cierre) |
| Liquidar | Si (obligatorio para cerrar) |
| Archivar | Si (tras liquidar) |

**Efecto TECO en redes:** Las actividades de red en estado TECO no permiten nuevas confirmaciones, pero las confirmaciones pendientes (abiertas) pueden cerrarse.

#### Status LKD (Bloqueado)

| Operacion | Permitida |
|-----------|-----------|
| Contabilizar costes | No |
| Crear solicitudes / pedidos | No |
| Modificar datos maestros | No |
| Ver datos | Si |
| Liquidar | Si (si hay saldo residual) |
| Desbloquear | Si |

**Caso de uso:** Bloquear temporalmente un elemento WBS mientras se revisa un problema de presupuesto o auditoria.

#### Status DLFL (Marcado para Borrado)

| Operacion | Permitida |
|-----------|-----------|
| Cualquier posting | No |
| Borrado logico | Si (via CJ9D o archivo) |
| Desmarcar | Si (mientras no se archive) |

#### Status CLSD (Cerrado)

| Operacion | Permitida |
|-----------|-----------|
| Cualquier posting | No |
| Liquidacion | No |
| Reabrir | No (irreversible en produccion) |
| Ver datos historicos | Si |

---

## 2. Status de Usuario

Los **status de usuario** son definidos por el cliente y permiten representar estados de negocio especificos que SAP no cubre con sus status de sistema.

### 2.1 Perfil de Status (BS02)

**Transaccion BS02:** Definir perfiles de status de usuario.

El **perfil de status** agrupa los posibles status de usuario y sus transiciones permitidas.

**Proceso de creacion:**
1. Ejecutar `BS02`
2. Nuevo perfil: Clave (4 car.) + descripcion
3. Agregar status individuales:
   - Numero de secuencia (1-999)
   - Texto corto / texto largo
   - Status inicial (solo uno puede ser inicial)
   - Transacciones de negocio permitidas/prohibidas
   - Status que puede seguir / preceder

**Ejemplo de Perfil ZPROY:**

| Num | Clave | Descripcion | Inicial | Sigue a |
|-----|-------|-------------|---------|---------|
| 10 | IPRO | En Planificacion | X | - |
| 20 | AREP | Aprobado por Representante | - | IPRO |
| 30 | AJGE | Aprobado por Gerencia | - | AREP |
| 40 | EECC | En Ejecucion con Cambios | - | AJGE |
| 50 | SUSP | Suspendido | - | AJGE, EECC |
| 60 | CANC | Cancelado | - | SUSP, IPRO |
| 70 | FCOM | Formalmente Completado | - | AJGE, EECC |

### 2.2 Asignacion del Perfil de Status

El perfil se asigna en el **Perfil de Proyecto** (tipo de proyecto):

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Work Breakdown Structure
> Define Project Profile
```
Campo: `Status Profile` (STATSCHEMAL = BS profile)

O en el **Perfil de Red** para actividades de red:

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Network
> Settings for Network > Define Network Profile
```

### 2.3 Transacciones de Negocio (Business Transactions)

Los status de usuario pueden bloquear o desbloquear **transacciones de negocio especificas** en SAP. Esto se configura en BS02 por status.

Ejemplos de transacciones de negocio relevantes para PS:

| Cod. Trans. Negocio | Descripcion |
|--------------------|-------------|
| BUDG | Presupuestar |
| PCRQ | Crear solicitud de pedido |
| PCNF | Confirmar actividad de red |
| PSTS | Modificar status de sistema |
| PORD | Crear pedido de compras |
| PSET | Transferir datos de liquidacion |
| PCAL | Calcular costes overhead |
| PSUM | Cerrar periodo de planificacion |

---

## 3. Tablas de Base de Datos

### 3.1 JEST - Status Activos por Objeto

**Descripcion:** Almacena todos los status (sistema y usuario) activos para cada objeto.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| OBJNR | CHAR22 | Numero de objeto (clave compuesta) |
| STAT | CHAR5 | Clave de status (ej. I0001=CREA, I0002=REL) |
| INACT | CHAR1 | Indicador inactivo (X = inactivo) |

**Estructura del OBJNR:**
- Para WBS: `PR` + numero interno WBS (8 digitos)
- Para proyectos: `PR` + numero interno proyecto
- Para redes: `OR` + numero de red (12 digitos)
- Para actividades: `NL` + numero red + numero actividad

**Status de sistema y sus codigos internos:**

| Status | Codigo STAT |
|--------|-------------|
| CREA | I0001 |
| REL | I0002 |
| TECO | I0009 |
| LKD | I0045 |
| DLFL | I0076 |
| CLSD | I0012 |
| AVLB | I0046 |
| FNBL | I0057 |

**Query MCP - WBS con status REL en un proyecto:**
```sql
SELECT p.posid, p.post1,
       CASE WHEN j1.stat IS NOT NULL AND j1.inact <> 'X' THEN 'REL'
            WHEN j2.stat IS NOT NULL AND j2.inact <> 'X' THEN 'TECO'
            WHEN j3.stat IS NOT NULL AND j3.inact <> 'X' THEN 'CREA'
            ELSE 'OTRO' END AS status_sistema
FROM prps p
LEFT JOIN jest j1 ON j1.objnr = CONCAT('PR', p.pspnr) AND j1.stat = 'I0002'
LEFT JOIN jest j2 ON j2.objnr = CONCAT('PR', p.pspnr) AND j2.stat = 'I0009'
LEFT JOIN jest j3 ON j3.objnr = CONCAT('PR', p.pspnr) AND j3.stat = 'I0001'
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
ORDER BY p.stufe, p.posid
```

**Query MCP - Todos los status activos de un WBS especifico:**
```sql
SELECT j.stat, t.txt04, t.txt30
FROM jest j
INNER JOIN tj02t t ON j.stat = t.istat AND t.spras = 'S'
WHERE j.objnr = (
    SELECT CONCAT('PR', pspnr) FROM prps
    WHERE posid = 'P-2024-001.1.1' AND vernr = '00'
)
AND j.inact <> 'X'
```

### 3.2 TJ02 - Definicion de Status de Sistema

**Descripcion:** Catalogo de todos los status de sistema SAP (no modificar).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| ISTAT | CHAR5 | Codigo interno (I0001-I9999) |
| STATV | CHAR4 | Abreviatura visible (CREA, REL, etc.) |
| ESTAT | CHAR1 | Tipo: S=sistema, U=usuario |
| ECANC | CHAR1 | Cancelable |

### 3.3 TJ30 - Perfiles de Status (Cabecera)

**Descripcion:** Cabecera de los perfiles de status de usuario creados en BS02.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| STSMA | CHAR8 | Clave del perfil de status |
| SPRAS | LANG | Idioma |
| STEXT | CHAR40 | Descripcion del perfil |

**Query MCP - Listar perfiles de status configurados:**
```sql
SELECT stsma, stext FROM tj30
WHERE spras = 'S'
ORDER BY stsma
```

### 3.4 JSTO - Cabecera de Status por Objeto

**Descripcion:** Una fila por objeto con el perfil de status asignado y numero de objeto.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| OBJNR | CHAR22 | Numero de objeto |
| STSMA | CHAR8 | Perfil de status asignado |
| OBTYP | CHAR2 | Tipo de objeto (PS=WBS, NL=red, etc.) |
| STONR | CHAR18 | Numero de status (interno) |
| ESTAT | CHAR4 | Status usuario activo actual |
| LOEKZ | CHAR1 | Indicador borrado |

**Query MCP - WBS con su perfil de status y status usuario activo:**
```sql
SELECT p.posid, p.post1, js.stsma, js.estat,
       t.txt30 AS descripcion_status_usuario
FROM prps p
INNER JOIN jsto js ON js.objnr = CONCAT('PR', p.pspnr)
LEFT JOIN tj32t t ON t.stsma = js.stsma AND t.estat = js.estat AND t.spras = 'S'
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
ORDER BY p.posid
```

### 3.5 TJ32 - Status de Usuario (Detalle)

**Descripcion:** Definicion detallada de cada status de usuario dentro de un perfil.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| STSMA | CHAR8 | Perfil de status |
| ESTAT | CHAR4 | Clave del status usuario |
| SPRAS | LANG | Idioma |
| TXT04 | CHAR4 | Abreviatura (4 car.) |
| TXT30 | CHAR30 | Descripcion larga |
| INITU | CHAR1 | Status inicial (X = si) |
| POSTI | CHAR1 | Posicion (num. secuencia) |

---

## 4. Status a Nivel de Cada Objeto PS

### 4.1 A Nivel de Proyecto (PROJ)

Los proyectos tienen su propio numero de objeto: `PR` + PSPNR del proyecto.

**Status tipicos en proyecto:**
- CREA, REL, TECO, CLSD aplican al proyecto en su conjunto
- El status del proyecto NO se propaga automaticamente a los WBS hijos
- Para propagar, usar `CJ02` → Editar → Status → Propagar a elementos

### 4.2 A Nivel de Elemento WBS (PRPS)

Cada elemento WBS tiene status independiente.

**Regla importante:** Para que un WBS pueda recibir costes reales, tanto el WBS como el proyecto deben estar en status REL.

**Status WBS en presupuesto:**
- La disponibilidad presupuestaria se verifica solo en WBS con BELKZ='X' (elementos de cuenta)
- Status TECO en WBS: los pedidos asignados pueden seguir procesandose pero no se crean nuevos

### 4.3 A Nivel de Red (AUFK/NETZ)

Las redes (ordenes internas de tipo PS) tienen numero de objeto: `OR` + numero de red.

**Status tipicos de red:**
| Status | Descripcion |
|--------|-------------|
| CREA | Red creada, sin liberar |
| REL | Red liberada (permite confirmaciones) |
| PRC | Bloqueada para aprovisionamiento |
| TECO | Completada tecnicamente |
| CLSD | Cerrada |

**Implicacion REL en red:** Solo las redes en REL pueden recibir confirmaciones de actividad y reservas de material.

### 4.4 A Nivel de Actividad (VORG)

Las actividades heredan el status de la red padre pero tambien pueden tener status propios:

| Status | Descripcion |
|--------|-------------|
| NTUP | No confirmada |
| PCNF | Parcialmente confirmada |
| CNF | Totalmente confirmada |
| DLFL | Marcada para borrado |

---

## 5. Combinaciones de Status Permitidas

### 5.1 Reglas de Combinacion

SAP permite que un objeto tenga multiples status activos simultaneamente. Las reglas son:

- Solo un status de sistema "principal" puede estar activo a la vez (CREA, REL, TECO, CLSD son mutuamente excluyentes)
- Pero pueden combinarse con status secundarios (LKD, DLFL, FNBL)
- Los status de usuario son adicionales y pueden combinarse entre si segun el perfil

**Combinaciones validas:**

| Combinacion | Es valida | Observacion |
|-------------|-----------|-------------|
| CREA + LKD | Si | Bloqueado antes de liberar |
| REL + LKD | Si | Bloqueado temporalmente |
| TECO + LKD | Redundante | TECO ya impide postings |
| REL + FNBL | Si | Liberado con factura final |
| CREA + REL | No | Mutuamente excluyentes |
| REL + TECO | No | Mutuamente excluyentes |
| TECO + CLSD | No | Mutuamente excluyentes |

### 5.2 Secuencia Obligatoria

Para cerrar (CLSD) un WBS, SAP requiere:
1. Status TECO activo
2. Sin saldo de costes no liquidado
3. Liquidacion ejecutada (KO88 o CJ88)

---

## 6. Customizing de Status

### 6.1 Configurar Esquema de Status (BS02)

**Pasos detallados:**

1. Ejecutar `BS02`
2. Nuevo esquema: Clave (8 car.) + descripcion
3. Para cada status de usuario:
   - Definir numero de secuencia
   - Introducir textos (4 car. y 30 car.)
   - Marcar si es status inicial
   - Definir transacciones de negocio bloqueadas/desbloqueadas
   - Definir que status puede seguir a este

4. Activar el esquema

**Ruta SPRO alternativa:**
```
Project System > Structures > Status Management > Define Status Schemas
```

### 6.2 Asignar Esquema al Tipo de Proyecto

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Work Breakdown Structure
> Define Project Profile
```
Campo: `Esquema de status (WBS)` y `Esquema de status (red)`

### 6.3 Definir Transacciones de Negocio Autorizadas por Status

**Ruta SPRO:**
```
Cross-Application Components > Status Management
> Define Permitted Business Transactions for User Status
```

---

## 7. Funciones Especiales de Status

### 7.1 Completado Tecnico en Bloque (TECO Masivo)

**Transaccion:** `CJ20N` (Mass Processing) o reporte `CJCO` (completado tecnico masivo WBS)

Permite cambiar a TECO multiples WBS o redes en una sola operacion.

**Seleccion posible:**
- Por proyecto
- Por tipo de proyecto
- Por responsable
- Por fecha de fin real

### 7.2 Liberar en Bloque

**Transaccion:** `CJ26` - Liberar WBS masivamente

O desde `CJ20N` con funcion "Liberar".

### 7.3 Modificar Status via BAPI

Para automatizacion, usar:
```abap
BAPI_BUS2054_SET_STATUS    " Set status en elemento WBS
BAPI_NETWORK_SET_STAT      " Set status en red
```

### 7.4 Status con Fecha de Vigencia

Algunos status de usuario pueden tener fecha de inicio/fin de vigencia. Esto se configura en BS02 marcando el indicador de fecha.

---

## 8. Reportes de Status

### 8.1 S_ALR_87013533 - Informe de Status de WBS

Muestra el status de todos los elementos WBS de un proyecto con filtros por status de sistema y usuario.

### 8.2 CNS44 - Informacion de Status de Red

Muestra el status de todas las redes y actividades con posibilidad de cambio masivo.

### 8.3 Query JEST para Auditoria

**Query MCP - WBS sin liberar en proyectos activos:**
```sql
SELECT pro.pspid, p.posid, p.post1,
       CASE WHEN jrel.stat IS NOT NULL AND jrel.inact <> 'X' THEN 'REL'
            ELSE 'NO REL' END AS status
FROM proj pro
INNER JOIN prps p ON p.psphi = pro.pspnr AND p.vernr = '00'
LEFT JOIN jest jrel ON jrel.objnr = CONCAT('PR', p.pspnr) AND jrel.stat = 'I0002'
WHERE pro.vernr = '00'
  AND (jrel.stat IS NULL OR jrel.inact = 'X')
  AND NOT EXISTS (
      SELECT 1 FROM jest j WHERE j.objnr = CONCAT('PR', p.pspnr)
      AND j.stat = 'I0009' AND j.inact <> 'X'
  )
ORDER BY pro.pspid, p.posid
```

---

## 9. Errores Comunes de Status

| Error | Causa | Solucion |
|-------|-------|---------|
| No se pueden registrar costes | WBS en status CREA (no REL) | Liberar WBS en CJ02 |
| No se puede liberar WBS | Datos obligatorios incompletos | Completar centro de coste, sociedad, etc. |
| No se puede pasar a TECO | Hay solicitudes/pedidos abiertos | Cerrar o eliminar posiciones abiertas |
| No se puede cerrar (CLSD) | Saldo de costes no liquidado | Ejecutar liquidacion CJ88 primero |
| Status usuario no aparece | Perfil no asignado al tipo de proyecto | Asignar perfil en customizing |
| No se puede cambiar status | Status bloqueado por transaccion negocio | Revisar configuracion BS02 |
| TECO impide confirmaciones | Correcto — es el comportamiento esperado | Revertir TECO si es necesario (CJ02) |

---

## 10. Buenas Practicas

1. **Definir politica de liberacion clara** — Quienes pueden liberar (REL) y bajo que condiciones.
2. **Usar status usuario para flujos de aprobacion** — No sustituye el status sistema pero lo complementa.
3. **Documentar transiciones en BS02** — Las reglas de transicion deben reflejar el proceso real del negocio.
4. **TECO antes de CLSD** — Siempre pasar por TECO para asegurar que no quedan partidas abiertas.
5. **No bloquear (LKD) en lugar de TECO** — LKD es temporal, TECO es el cierre tecnico formal.
6. **Verificar status en MRP** — Elementos WBS sin REL no generan necesidades en MRP.
7. **Propagar status con cuidado** — La propagacion masiva puede afectar muchos objetos a la vez.
8. **Auditar cambios de status** — Usar tabla CDHDR/CDPOS para trazar quien cambio el status y cuando.
