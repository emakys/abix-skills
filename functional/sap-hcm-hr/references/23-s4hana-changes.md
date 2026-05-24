# Cambios en S/4HANA para HCM

## Posicionamiento de HCM on-premise en S/4HANA

SAP HCM se preserva en S/4HANA como solución on-premise compatible. No es una solución cloud-native rediseñada: el núcleo funcional (PA, OM, TM, PY) se mantiene con las mismas transacciones y configuración de ECC, pero con mejoras técnicas y de integración relevantes.

**Estrategia oficial de SAP:**
- **Corto/mediano plazo**: HCM on-premise en S/4HANA (camino de clientes con inversión local)
- **Largo plazo**: migración a **SuccessFactors** (HXM cloud) como dirección estratégica
- **Coexistencia soportada**: S/4HANA HCM + SuccessFactors via integración (side-by-side)
- Mantenimiento garantizado hasta al menos 2040 para HCM on-premise

## Posteo de Nómina a ACDOCA (Universal Journal)

### Cambio Arquitectónico Clave
En ECC, los documentos contables de nómina se grababan en **BSEG** (tabla de posiciones FI). En S/4HANA, el posteo va directamente a **ACDOCA** (Universal Journal).

| Aspecto | ECC | S/4HANA 2023 |
|---|---|---|
| Tabla de posteo | BSEG + BKPF | ACDOCA |
| Dimensiones CO | Tablas CO separadas | Integradas en ACDOCA |
| Centro de costo | COEP + COSS | ACDOCA (campo KOSTL) |
| Orden interno | COEP | ACDOCA (campo AUFNR) |
| Centro de beneficio | GLPCA | ACDOCA (campo PRCTR) |
| Reconciliación FI-CO | Proceso de reconciliación | Eliminado (fuente única) |

### Implicaciones Técnicas
```abap
" Lectura de posteos de nómina en S/4HANA
SELECT * FROM acdoca
  WHERE rldnr = '0L'        " Ledger principal
    AND rbukrs = @bukrs
    AND gjahr = @gjahr
    AND blart = 'LO'        " Tipo de documento nómina
    AND pernr IS NOT INITIAL " Solo líneas con número de personal
  INTO TABLE @DATA(lt_payroll_postings).

" En ECC era:
" SELECT * FROM bseg WHERE bukrs... blart = 'LO'
```

### Configuración de Posteo (sin cambio)
- Transacción **OBYU**: definir variante de posteo simbólico
- Transacción **PC00_M99_CIPE**: ejecución del posteo de nómina
- Simbólicos de cuenta: tabla **T52EK** (sin cambios en S/4HANA)
- División de costos de nómina (PC00_M99_CIPE): igual, pero resultado en ACDOCA

## Fiori Apps Reemplazando WebDynpro ESS/MSS

### Transición de Plataforma UI
| Tecnología | Estado en S/4HANA |
|---|---|
| ITS-based ESS (SAP GUI en browser) | **Deprecado** |
| WebDynpro ESS/MSS (EP/NetWeaver Portal) | **Legado**, sin nuevas inversiones |
| Fiori Launchpad ESS/MSS | **Estrategia actual** |

### Apps Fiori Principales (ver referencia 24-fiori-apps.md para detalle)
- Solicitud y aprobación de ausencias (F1844/F1845)
- Visualización de recibos de sueldo (F1797)
- Registro de tiempos (F2740)
- Datos maestros de empleado (F0711/F1569)
- People Profile unificado (F3041)
- Manager Self-Service Overview (F0396)

### Configuración Requerida para Fiori HR
1. Activar **Business Function** HCM_ESS_WDA_1 / HCM_MSS_LM_DELTA_1
2. Configurar **Fiori Launchpad** (transacción /UI2/FLPD_CONF)
3. Asignar **roles Fiori** a usuarios (SAP_FLP_ADMIN, roles específicos de app)
4. Activar **OData services** correspondientes (transacción /IWFND/MAINT_SERVICE)
5. Configurar **reglas de workflow** para aprobaciones (BRF+ o reglas HR)

## Nuevas Vistas CDS Analíticas

### Arquitectura Analítica HR en S/4HANA
S/4HANA introduce vistas CDS con anotaciones analíticas para reemplazar los InfoCubes y DataSources BW tradicionales:

```abap
" Vista analítica de empleados (entregada por SAP)
@Analytics.dataCategory: #CUBE
@Analytics.query: true
define view C_HCMHeadcountQuery
  as select from I_HCMEmployee
{
  @AnalyticsDetails.query.display: #KEY_TEXT
  EmployeeNumber,
  @Aggregation.default: #COUNT_DISTINCT
  _0001.PersonnelArea,
  _0001.PersonnelSubArea,
  cast(1 as abap.int4) as Headcount
}
```

### DataSources Estándar HR para Embedded Analytics
| DataSource | Contenido |
|---|---|
| 0HR_PA_0 | Datos maestros PA (IT0001-0008) |
| 0HR_PY_PP_1 | Resultados de nómina por período |
| 0HR_PT_1 | Datos de tiempo (IT2001/2002) |
| 0HR_OM_1 | Datos organizacionales (PCH) |

## Integración Business Partner (BP) para Empleados

### Nuevo Modelo en S/4HANA
En S/4HANA, los empleados se sincronizan automáticamente con el objeto **Business Partner** (tabla BUT000):

- **Activación**: transacción PIBPUPD o automática al grabar IT0001/IT0006
- **Rol BP**: empleado asignado a rol FLVN00 (Employee) y opcionalmente CR000 (Contact Person)
- **Sincronización**: datos de IT0002 (nombre), IT0006 (dirección) → BP
- **Uso**: portal de autoservicio, integración con otros módulos (SD para vendedores-empleados)

```abap
" Lectura de BP asociado a empleado
SELECT SINGLE partner FROM but0bk
  WHERE pernr = @lv_pernr
  INTO @DATA(lv_bp_number).

" O vía tabla de mapeo
SELECT SINGLE bu_partner FROM hrp1001
  WHERE otype = 'P'
    AND objid = @lv_pernr
    AND rsign = 'A'
    AND relat = '209'  " Relación P-BP
  INTO @DATA(lv_partner).
```

### Implicaciones de Configuración
- Número de BP puede diferir del número de empleado (PERNR)
- Asegurar activación de **BAdI** HRBAS00_BP_SYNC para sincronización
- Campos custom en IT006 → mapeados a dirección BP via BAdI

## Modelo de Datos Simplificado para Reporting

### Eliminación de Tablas Redundantes
| Tabla ECC | Estado S/4HANA | Reemplazo |
|---|---|---|
| BSEG (posteo nómina) | No usada para HCM | ACDOCA |
| GLPCA (profit center) | Eliminada | ACDOCA |
| COEP (CO line items) | Eliminada | ACDOCA |
| GLT0 (balance totals) | Eliminada | ACDOCA |

### Acceso a Datos HR en S/4HANA
```abap
" Datos maestros: sin cambio estructural
SELECT * FROM pa0001 WHERE pernr = @lv_pernr.

" Resultados nómina: sin cambio (cluster PCL2)
" Acceder via FM HR_READ_PAYROLL_RESULT

" Posteos contables: ahora en ACDOCA
SELECT * FROM acdoca WHERE pernr = @lv_pernr.

" Datos org: sin cambio (HRP1000/HRP1001)
SELECT * FROM hrp1000 WHERE otype = 'O' AND objid = @lv_org.
```

## Deprecación de ESS/MSS Clásico (ITS-Based)

### Tecnologías Afectadas
- **SAP Employee Self-Service ITS**: acceso vía browser a transacciones SAP GUI (modo Enjoy) — **sin soporte en S/4HANA**
- **WebDynpro ABAP ESS**: aplicaciones Employee Self-Service en NetWeaver Portal — **modo legado, sin nuevas funciones**
- **MSS Business Package para NetWeaver Portal**: paquetes de Manager Self-Service — **modo legado**

### Camino de Migración Recomendado
1. Inventario de servicios ESS/MSS en uso
2. Mapeo a apps Fiori equivalentes (SAP Fiori Apps Library: fioriappslibrary.hana.ondemand.com)
3. Configurar Fiori Launchpad como punto de entrada unificado
4. Ajustar roles y autorizaciones (Fiori usa PFCG + catálogos Fiori)
5. Migrar customizaciones (reglas de aprobación, notificaciones) a BRF+ o Workflow moderno

## SAP GUI — Transacciones Aún Requeridas

A pesar de la estrategia Fiori, muchas operaciones HCM siguen requiriendo SAP GUI en S/4HANA 2023:

| Area | Transacciones SAP GUI Aún Necesarias |
|---|---|
| Nómina | PC00_M*, PUOC_99, PC_PAYRESULT |
| Configuración PA | PA30, PA40, PA70, PRMD |
| Customizing HCM | SPRO (toda la configuración) |
| Esquemas nómina | PE01, PE02 |
| Formularios nómina | PE51 |
| Time Evaluation | PT60, PT_CLSTB2 |
| Administración masiva | PA71, LSMW |

**Recomendación**: mantener acceso SAP GUI para usuarios de RRHH operativos y todos los usuarios de configuración/soporte.

## SuccessFactors como Estrategia Cloud

### Modelo de Integración Side-by-Side
```
S/4HANA (Core Financiero + Logístico)
    ↕ Integración vía CPI (Cloud Platform Integration)
SuccessFactors (HCM Cloud)
    - Employee Central (datos maestros HR cloud)
    - Recruiting / Onboarding
    - Performance & Goals
    - Learning
    - Compensation
```

### Alcance de Integración Estándar (SAP preentregado)
| Proceso | Dirección |
|---|---|
| Datos maestros empleado | SuccessFactors EC → S/4HANA PA |
| Centro de costo / estructura org | S/4HANA → SuccessFactors |
| Posteo nómina (si PY en S/4) | S/4HANA PY → S/4HANA FI |
| Nómina cloud (Employee Central Payroll) | Basado en S/4HANA PY hosteado por SAP |

### Consideraciones para Clientes Actuales
- **Employee Central Payroll**: nómina SuccessFactors basada en motor SAP PY (mismo esquema, en cloud SAP)
- **Migración gradual posible**: mantener PY on-premise + migrar reclutamiento/performance a SF primero
- **Punto de partida**: SAP Readiness Check para HCM identifica qué objetos custom son compatibles
