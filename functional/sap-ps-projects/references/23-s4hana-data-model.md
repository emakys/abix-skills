# Modelo de Datos S/4HANA 2023 — SAP Project System

## Indice
1. Tablas Principales PS
2. Jerarquia de Tablas y Relaciones
3. Tablas de Redes y Actividades
4. Tablas de Costes y Presupuesto
5. Tablas de Status
6. Tablas de Materiales y Componentes
7. CDS Views Principales
8. Diferencias ECC vs S/4HANA
9. Universal Journal y PS
10. Guia de Consultas Tipicas

---

## 1. Tablas Principales PS

### 1.1 PROJ — Cabecera de Proyecto

**Descripcion:** Tabla maestra del proyecto. Un registro por proyecto.

| Campo | Tipo | Descripcion | Ejemplo |
|-------|------|-------------|---------|
| PSPNR | NUMC(8) | Numero interno de proyecto | 00000042 |
| PSPID | CHAR(24) | ID de proyecto (externo) | INV-2024-PLANTA-01 |
| POST1 | CHAR(40) | Descripcion del proyecto | Ampliacion Planta Barcelona |
| ERDAT | DATS | Fecha de creacion | 20240115 |
| VERNA | CHAR(12) | Responsable del proyecto | JMARTINEZ |
| PLFAZ | DATS | Fecha inicio planificada | 20240201 |
| PLSEZ | DATS | Fecha fin planificada | 20241231 |
| ASTAZ | DATS | Fecha inicio real | 20240205 |
| PSPRI | CHAR(1) | Prioridad (1-9) | 1 |
| PROJK | CHAR(8) | Tipo de proyecto | INV |
| VERNR | NUMC(8) | Numero empleado responsable | |
| PROFL | CHAR(8) | Perfil de proyecto | STD001 |
| BUKRS | CHAR(4) | Sociedad | 1000 |
| WERKS | CHAR(4) | Centro | 1000 |
| VBUKR | CHAR(4) | Sociedad de facturacion | |
| TXJCD | CHAR(15) | Codigo de jurisdiccion fiscal | |
| OBJNR | CHAR(22) | Numero de objeto (status) | PR00000042 |
| PSPHI | NUMC(8) | WBS superior (propio PSPNR) | |

**Nota:** `OBJNR` = 'PR' + PSPNR (zero-padded) para proyectos

### 1.2 PRPS — Elementos WBS

**Descripcion:** Tabla de elementos WBS. Un registro por cada nodo de la estructura WBS.

| Campo | Tipo | Descripcion | Ejemplo |
|-------|------|-------------|---------|
| PSPNR | NUMC(8) | Numero interno WBS | 00000043 |
| POSID | CHAR(24) | ID WBS (externo) | INV-2024-PLANTA-01.001 |
| POST1 | CHAR(40) | Descripcion | Ingenieria Civil |
| PSPHI | NUMC(8) | Proyecto padre (PROJ.PSPNR) | 00000042 |
| PSPRI | NUMC(8) | WBS padre (jerarquia) | 00000042 |
| STUFE | NUMC(2) | Nivel jerarquico | 02 |
| VERNA | CHAR(12) | Responsable WBS | |
| ERDAT | DATS | Fecha creacion | |
| FAKKZ | CHAR(1) | Indicador elemento facturacion | X |
| PRAJI | CHAR(1) | Indicador elemento presupuesto | X |
| BELKZ | CHAR(1) | Indicador elemento planificacion | X |
| BUKRS | CHAR(4) | Sociedad | 1000 |
| KOSTL | CHAR(10) | Centro de coste | 41000 |
| LSTAR | CHAR(6) | Tipo de actividad | |
| PLFAZ | DATS | Fecha inicio plan | |
| PLSEZ | DATS | Fecha fin plan | |
| ASTAZ | DATS | Fecha inicio real | |
| ASTEZ | DATS | Fecha fin real | |
| OBJNR | CHAR(22) | Numero objeto (status) | WBS00000043 |
| PSPRI2 | NUMC(8) | WBS nivel superior en jerarquia | |
| PROFIT_CTR | CHAR(10) | Centro de beneficio | |

**Campos de control:**
| Campo | Descripcion |
|-------|-------------|
| FAKKZ | X = Elemento de facturacion (puede facturar a cliente) |
| PRAJI | X = Elemento de presupuesto (lleva presupuesto) |
| BELKZ | X = Elemento de planificacion de costes |

### 1.3 PRHI — Jerarquia de Proyecto

**Descripcion:** Tabla de jerarquia (padre-hijo de WBS). Permite navegar la estructura.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| UP | NUMC(8) | Nodo padre (PSPNR del WBS superior) |
| HIPOS | NUMC(8) | Nodo hijo (PSPNR del WBS hijo) |
| STUFE | NUMC(2) | Nivel del hijo |

**Consulta jerarquia completa:**
```sql
-- Obtener todos los WBS hijos de un proyecto
SELECT prhi.HIPOS, prps.POSID, prps.POST1, prps.STUFE
FROM PRHI
JOIN PRPS ON PRHI.HIPOS = PRPS.PSPNR
WHERE PRHI.UP = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
ORDER BY PRPS.STUFE, PRPS.POSID
```

---

## 2. Tablas de Redes y Actividades

### 2.1 AUFK — Cabecera de Orden (Redes)

**Descripcion:** Cabecera de ordenes de produccion/proyecto. Las redes PS son un tipo de orden.

| Campo | Tipo | Descripcion | Ejemplo |
|-------|------|-------------|---------|
| AUFNR | CHAR(12) | Numero de orden/red | 000900000001 |
| AUART | CHAR(4) | Tipo de orden | PS01 |
| AUTYP | NUMC(2) | Clase de orden (20=red PS) | 20 |
| WERKS | CHAR(4) | Centro | 1000 |
| BUKRS | CHAR(4) | Sociedad | 1000 |
| PSPEL | NUMC(8) | WBS asignado (PRPS.PSPNR) | 00000043 |
| ERDAT | DATS | Fecha creacion | |
| GLTRP | DATS | Fecha fin planificada | |
| GSTRP | DATS | Fecha inicio planificada | |
| OBJNR | CHAR(22) | Numero objeto (status) | OR000900000001 |
| KOSTL | CHAR(10) | Centro de coste | |
| IDAT1 | DATS | Fecha clave 1 (personalizable) | |

### 2.2 AFKO — Cabecera de Orden de Fabricacion (Redes)

**Descripcion:** Datos de planificacion/programacion de la red.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| AUFNR | CHAR(12) | Numero de orden |
| NETID | CHAR(12) | ID de red PS |
| GSTRS | DATS | Fecha inicio programada |
| GETRS | DATS | Fecha fin programada |
| FTRMS | DATS | Fecha fin programada (red) |
| DAUER | QUAN | Duracion total |
| DAUNE | UNIT | Unidad de duracion |

### 2.3 AFVC — Operaciones/Actividades de Red

**Descripcion:** Actividades de la red de proyecto.

| Campo | Tipo | Descripcion | Ejemplo |
|-------|------|-------------|---------|
| AUFPL | NUMC(10) | Numero plan de actividades | |
| APLZL | NUMC(8) | Contador actividad | |
| AUFNR | CHAR(12) | Numero de orden | |
| VORNR | CHAR(4) | Numero de operacion | 0010 |
| LTXA1 | CHAR(40) | Descripcion actividad | Excavacion cimentacion |
| STEUS | CHAR(4) | Clave de control | PS01 |
| ARBID | NUMC(8) | Centro de trabajo (interno) | |
| WERKS | CHAR(4) | Centro | 1000 |
| PSPNR | NUMC(8) | WBS asignado | |
| OBJNR | CHAR(22) | Numero objeto (status) | |
| NWART | CHAR(1) | Tipo actividad (0=interna,1=ext,2=coste) | 0 |

### 2.4 AFVV — Valores de Actividad (Tiempos y Cantidades)

**Descripcion:** Datos de tiempo y capacidad de actividades.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| AUFPL | NUMC(10) | Numero plan |
| APLZL | NUMC(8) | Contador |
| VGW01 | QUAN | Tiempo de ejecucion |
| VGE01 | UNIT | Unidad de tiempo |
| VGW02 | QUAN | Tiempo de preparacion |
| MGVRG | QUAN | Cantidad de operacion |
| MEINH | UNIT | Unidad de medida |
| GLTRS | DATS | Fecha inicio programada |
| GETRS | DATS | Fecha fin programada |
| ISDD | DATS | Fecha inicio real |
| IEDD | DATS | Fecha fin real |

---

## 3. Tablas de Costes y Presupuesto

### 3.1 RPSCO — Totales de Costes PS

**Descripcion:** Tabla de totales (totalizaciones) de costes y valores de planificacion. Equivalente al "resumen" de ACDOCA para PS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| OBJNR | CHAR(22) | Numero de objeto (WBS/red) |
| WRTTP | CHAR(2) | Tipo de valor (ver tabla abajo) |
| GJAHR | NUMC(4) | Ejercicio |
| VERSN | CHAR(3) | Version |
| KSTAR | CHAR(10) | Elemento de coste |
| POPER | NUMC(3) | Periodo |
| WKBTR | CURR | Importe en moneda objeto |
| TWAER | CUKY | Moneda |

**Tipos de valor WRTTP:**
| Valor | Descripcion |
|-------|-------------|
| 01 | Plan total (distribuido anualmente) |
| 04 | Plan periodico |
| 10 | Real |
| 20 | Real estadistico |
| 40 | Compromisos totales |
| 41 | Compromisos pedidos |
| 43 | Compromisos contratos |
| 60 | Presupuesto original |
| 61 | Presupuesto suplementario |
| 65 | Presupuesto devuelto |
| 66 | Presupuesto transferido |

### 3.2 BPGE — Presupuesto Global (Total)

**Descripcion:** Presupuesto total del proyecto (no periodizado).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| OBJNR | CHAR(22) | Numero de objeto |
| VORGA | CHAR(4) | Clase de valor presupuesto |
| WRTTP | CHAR(2) | Tipo de valor |
| GJAHR | NUMC(4) | Ejercicio |
| VERSN | CHAR(3) | Version |
| WLGES | CURR | Importe total |
| WLIBFR | CURR | Importe liberado |
| WTWAER | CUKY | Moneda |

**Valores VORGA:**
| Codigo | Descripcion |
|--------|-------------|
| KOBU | Presupuesto original |
| KONS | Suplemento de presupuesto |
| KONR | Devolucion de presupuesto |
| KONT | Transferencia de presupuesto |

### 3.3 BPJA — Presupuesto Anual

**Descripcion:** Presupuesto desglosado por ejercicio.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| OBJNR | CHAR(22) | Numero de objeto |
| VORGA | CHAR(4) | Clase valor presupuesto |
| WRTTP | CHAR(2) | Tipo de valor |
| GJAHR | NUMC(4) | Ejercicio |
| WLGES | CURR | Importe del ejercicio |
| WLIBFR | CURR | Importe liberado |

---

## 4. Tablas de Status

### 4.1 JEST — Status Individual de Objeto

**Descripcion:** Status activos de cada objeto (WBS, red, actividad). Un registro por status activo.

| Campo | Tipo | Descripcion | Ejemplo |
|-------|------|-------------|---------|
| OBJNR | CHAR(22) | Numero de objeto | WBS00000043 |
| STAT | CHAR(5) | Status (prefijo E=sistema, I=usuario) | E0001 |
| INACT | CHAR(1) | Inactivo (espacio=activo, X=inactivo) | |
| CHGNR | NUMC(5) | Numero de cambio | |

**Status de sistema (prefijo E):**
| STAT | Descripcion |
|------|-------------|
| E0001 | CRTD — Creado |
| E0002 | REL — Liberado |
| E0003 | CNF — Confirmado parcialmente |
| E0004 | TECO — Cierre tecnico |
| E0005 | CLSD — Cerrado |
| E0006 | DLTD — Marcado para borrado |
| E0007 | LKD — Bloqueado |

**Status de usuario (prefijo I):**
Son definidos por el cliente. Ejemplo: `I0001` = Pendiente aprobacion.

**Consulta status:**
```sql
-- Obtener status activos de un WBS
SELECT j.OBJNR, j.STAT, tj.TXT04, tj.TXT30
FROM JEST AS j
JOIN TJ02T AS tj ON j.STAT = tj.ISTAT
    AND tj.SPRAS = 'S'
WHERE j.OBJNR = 'WBS00000043'
    AND j.INACT = ''
```

### 4.2 TJ02T — Textos de Status

| Campo | Descripcion |
|-------|-------------|
| ISTAT | Codigo status interno |
| SPRAS | Idioma |
| TXT04 | Abreviatura 4 char |
| TXT30 | Descripcion larga |

### 4.3 JSTO — Perfil de Status de Objeto

| Campo | Descripcion |
|-------|-------------|
| OBJNR | Numero de objeto |
| STSMA | Perfil de status de usuario asignado |
| STONR | Status inicial |

---

## 5. Tablas de Materiales y Componentes

### 5.1 RESB — Reservas/Necesidades de Componentes

**Descripcion:** Componentes de material asignados a actividades de red.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| RSNUM | NUMC(10) | Numero de reserva |
| RSPOS | NUMC(4) | Posicion de reserva |
| AUFNR | CHAR(12) | Numero de orden (red) |
| MATNR | CHAR(18) | Material |
| WERKS | CHAR(4) | Centro |
| BDMNG | QUAN | Cantidad necesaria |
| ENTNR | NUMC(8) | Numero de actividad |
| PSPNR | NUMC(8) | WBS element |
| BDTER | DATS | Fecha de necesidad |
| LGORT | CHAR(4) | Almacen |
| SOBKZ | CHAR(1) | Indicador stock especial (Q=proyecto) |

### 5.2 Stock de Proyecto

**Indicador stock especial:** `Q` = Stock de proyecto (Project Stock)
- Stock valorado asignado especificamente al proyecto/WBS
- No intercambiable con stock normal
- Movimientos: 221 (entrada a proyecto), 222 (devolucion), 261 (consumo)

---

## 6. CDS Views Principales

### 6.1 Views de Datos Maestros

| CDS View | Tabla base | Descripcion |
|----------|-----------|-------------|
| `I_Project` | PROJ | Proyecto con datos adicionales |
| `I_WBSElement` | PRPS | WBS con datos calculados |
| `I_WBSElementBasic` | PRPS | WBS datos basicos |
| `I_ProjectHierarchy` | PRHI | Jerarquia proyecto |
| `I_ProjectVersion` | AUFK + PRPS | Versiones de proyecto |
| `I_ProjectByProcessingStatus` | PROJ + JEST | Proyectos por status |
| `I_WBSElementByProcessingStatus` | PRPS + JEST | WBS por status |
| `I_ProjectOrder` | AUFK | Ordenes/redes de proyecto |

### 6.2 Views de Costes

| CDS View | Descripcion |
|----------|-------------|
| `I_ProjectActualCost` | Costes reales agregados por proyecto |
| `I_WBSActualCostByPeriod` | Costes reales WBS por periodo |
| `I_ProjectBudget` | Presupuesto del proyecto |
| `I_ProjectBudgetDistrib` | Distribucion del presupuesto |
| `I_ProjectCommitment` | Compromisos del proyecto |
| `I_ProjectPeriodCost` | Costes por periodo |
| `C_ProjectPlanVsActual` | Plan vs Real (para Fiori) |
| `C_WBSElementPlanVsActual` | Plan vs Real WBS (para Fiori) |
| `C_ProjectBudgetAvailability` | Disponibilidad presupuestaria |

### 6.3 Definicion I_WBSElement

```abap
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'WBS Element'
@ObjectModel.resultSet.sizeCategory: #XL
@ObjectModel.usageType:{serviceQuality: #A, dataClass: #MASTER}
define view entity I_WBSElement
  as select from prps
  association [1..1] to I_Project as _Project
    on $projection.ProjectInternalID = _Project.ProjectInternalID
{
  key prps.pspnr                as WBSElementInternalID,
  prps.posid                    as WBSElement,
  prps.post1                    as WBSDescription,
  prps.psphi                    as ProjectInternalID,
  prps.stufe                    as HierarchyLevel,
  prps.fakkz                    as IsBillingElement,
  prps.praji                    as IsBudgetElement,
  prps.belkz                    as IsPlanningElement,
  prps.bukrs                    as CompanyCode,
  prps.werks                    as Plant,
  prps.plfaz                    as PlannedStartDate,
  prps.plsez                    as PlannedEndDate,
  prps.astaz                    as ActualStartDate,
  prps.astez                    as ActualEndDate,
  prps.objnr                    as ObjectNumber,
  prps.profit_ctr               as ProfitCenter,
  _Project
}
```

---

## 7. Diferencias ECC vs S/4HANA

### 7.1 Tablas Eliminadas o Modificadas

| ECC | S/4HANA | Observacion |
|-----|---------|-------------|
| COSP | Eliminada | Datos en ACDOCA |
| COSS | Eliminada | Datos en ACDOCA |
| COBK | Eliminada | Datos en ACDOCA |
| COEP | Eliminada | Datos en ACDOCA |
| RPSCO | Mantenida | Tabla de totales (sigue existiendo) |
| BPGE | Mantenida | Presupuesto global |
| BPJA | Mantenida | Presupuesto anual |
| PROJ | Mantenida | Sin cambios mayores |
| PRPS | Mantenida | Nuevos campos S/4 |
| AFKO | Mantenida | Algunos campos deprecados |
| AFVC | Mantenida | Sin cambios mayores |
| JEST | Mantenida | Sin cambios |

### 7.2 Tabla ACDOCA en S/4HANA

**Descripcion:** Universal Journal — almacena TODOS los movimientos de valor en una sola tabla.

**Campos PS relevantes en ACDOCA:**
| Campo | Descripcion |
|-------|-------------|
| PSPNR | WBS Element (interno) |
| PS_PSP_PNR | WBS Element (pedidos/MM) |
| AUFNR | Numero de orden (red) |
| PROJK | Tipo de proyecto |
| PRCTR | Centro de beneficio |
| RBUKRS | Sociedad |
| GJAHR | Ejercicio |
| POPER | Periodo |
| KSTAR | Elemento de coste |
| HSL | Importe moneda local |
| WSL | Importe moneda transaccion |
| BEKNZ | Indicador debito/credito |
| AWTYP | Tipo de referencia (BKPF, MKPF, etc.) |
| AWKEY | Clave de referencia |

### 7.3 Impacto en Custom Reports

**Antes (ECC) — Consulta costes:**
```sql
SELECT * FROM COSP WHERE OBJNR = 'WBS00000043'  -- YA NO FUNCIONA
SELECT * FROM COSS WHERE OBJNR = 'WBS00000043'  -- YA NO FUNCIONA
```

**Ahora (S/4HANA) — Consulta costes:**
```sql
SELECT SUM(HSL) FROM ACDOCA
WHERE PSPNR = '00000043'
  AND GJAHR = '2024'
  AND RBUKRS = '1000'
```

**Alternativa recomendada:** Usar CDS Views (I_ProjectActualCost, C_ProjectPlanVsActual) en lugar de ACDOCA directamente.

### 7.4 Nuevas Tablas/Campos en S/4HANA 2023

| Objeto | Descripcion | Novedad |
|--------|-------------|---------|
| I_CommercialProject | Commercial Project Management | Nuevo en S/4 |
| I_ProjTaskCollaborator | Colaboradores en tareas | Nuevo |
| PRPS.PROFIT_CTR | Centro de beneficio en WBS | Nuevo campo |
| PRPS.SEGMENT | Segmento FI en WBS | Nuevo campo |
| AUFK.IDAT3 | Fecha personalizable adicional | Nuevo campo |

---

## 8. Universal Journal y PS

### 8.1 Flujo de Contabilizacion en S/4HANA

```
Documento de origen (FI/MM/HR/PS)
        ↓
    ACDOCA (Universal Journal)
        ↓
    RPSCO (actualizacion totales PS)
        ↓
    BPGE/BPJA (si es presupuesto)
```

### 8.2 Tipos de Documento en ACDOCA para PS

| AWTYP | Descripcion | Origen |
|-------|-------------|--------|
| BKPF | Documento FI | FI postings |
| MKPF | Documento material | Movimientos MM |
| CATS | Confirmacion tiempo | CATS/HR |
| COFC | Liquidacion | Settlement run |
| COPA | CO-PA posting | Reconocimiento ingresos |
| PS_ORDER | Orden PS | Confirmaciones directas |

### 8.3 Reconciliacion de Saldos PS

Para verificar la consistencia de datos:
```
Transaccion: KSB1 → filtrar por PSPNR
Transaccion: CJI3 → Items reales WBS
Transaccion: CJI5 → Items reales redes
```

Comparar con saldos en RPSCO (WRTTP='10') para validar.

---

## 9. Guia de Consultas Tipicas

### 9.1 Obtener Todos los WBS de un Proyecto

```sql
SELECT
    prps.PSPNR,
    prps.POSID,
    prps.POST1,
    prps.STUFE,
    prps.FAKKZ,
    prps.PRAJI,
    prps.BELKZ,
    prps.PLFAZ,
    prps.PLSEZ
FROM PRPS
WHERE PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
ORDER BY POSID
```

### 9.2 Status de Todos los WBS

```sql
SELECT
    prps.POSID,
    prps.POST1,
    jest.STAT,
    tj02t.TXT04,
    tj02t.TXT30
FROM PRPS
JOIN JEST ON PRPS.OBJNR = JEST.OBJNR AND JEST.INACT = ''
JOIN TJ02T ON JEST.STAT = TJ02T.ISTAT AND TJ02T.SPRAS = 'S'
WHERE PRPS.PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
ORDER BY PRPS.POSID, JEST.STAT
```

### 9.3 Actividades de Red por Proyecto

```sql
SELECT
    afko.AUFNR,
    afvc.VORNR,
    afvc.LTXA1,
    afvc.STEUS,
    afvc.NWART,
    afvv.VGW01,
    afvv.VGE01,
    afvv.GLTRS,
    afvv.GETRS,
    prps.POSID
FROM AFKO
JOIN AUFK ON AFKO.AUFNR = AUFK.AUFNR
JOIN PRPS ON AUFK.PSPEL = PRPS.PSPNR
JOIN AFVC ON AFKO.AUFPL = AFVC.AUFPL
JOIN AFVV ON AFVC.AUFPL = AFVV.AUFPL AND AFVC.APLZL = AFVV.APLZL
WHERE PRPS.PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
ORDER BY PRPS.POSID, AFKO.AUFNR, AFVC.VORNR
```

### 9.4 Presupuesto vs Real Completo

```sql
SELECT
    prps.POSID,
    prps.POST1,
    bpge.WLGES AS TotalBudget,
    bpge.WLIBFR AS ReleasedBudget,
    COALESCE(actual.ActualCost, 0) AS ActualCost,
    COALESCE(commit.Commitment, 0) AS Commitment,
    bpge.WLIBFR
        - COALESCE(actual.ActualCost, 0)
        - COALESCE(commit.Commitment, 0) AS Available,
    CASE WHEN bpge.WLIBFR > 0
        THEN (COALESCE(actual.ActualCost,0) / bpge.WLIBFR) * 100
        ELSE 0
    END AS BudgetUsedPct
FROM PRPS
LEFT JOIN BPGE ON PRPS.OBJNR = BPGE.OBJNR
    AND BPGE.VORGA = 'KOBU'
LEFT JOIN (
    SELECT PSPNR, SUM(HSL) AS ActualCost
    FROM ACDOCA WHERE GJAHR = '2024' AND PSPNR <> ''
    GROUP BY PSPNR
) AS actual ON PRPS.PSPNR = actual.PSPNR
LEFT JOIN (
    SELECT OBJNR, SUM(WKBTR) AS Commitment
    FROM RPSCO WHERE WRTTP = '40'
    GROUP BY OBJNR
) AS commit ON PRPS.OBJNR = commit.OBJNR
WHERE PRPS.PSPHI = (SELECT PSPNR FROM PROJ WHERE PSPID = 'INV-2024-001')
    AND PRPS.PRAJI = 'X'   -- Solo elementos de presupuesto
ORDER BY PRPS.POSID
```

---

## Referencia Rapida de Tablas

| Tabla | Contenido | Join principal |
|-------|-----------|----------------|
| PROJ | Cabecera proyecto | PSPNR |
| PRPS | WBS elements | PSPNR (WBS), PSPHI (proyecto padre) |
| PRHI | Jerarquia WBS | UP (padre), HIPOS (hijo) |
| AUFK | Cabecera orden/red | AUFNR, PSPEL→PRPS.PSPNR |
| AFKO | Datos programacion red | AUFNR |
| AFVC | Actividades de red | AUFPL |
| AFVV | Valores actividades | AUFPL+APLZL |
| JEST | Status activos | OBJNR |
| TJ02T | Textos status | ISTAT |
| BPGE | Presupuesto global | OBJNR |
| BPJA | Presupuesto anual | OBJNR+GJAHR |
| RPSCO | Totales costes PS | OBJNR+WRTTP |
| RESB | Reservas material | AUFNR (red) |
| ACDOCA | Documentos universales | PSPNR, AUFNR |

---

*Referencia: SAP S/4HANA 2023 | Data Dictionary PS*
*Nota: Las tablas COSP/COSS/COEP/COBK de ECC fueron eliminadas. Usar ACDOCA.*
