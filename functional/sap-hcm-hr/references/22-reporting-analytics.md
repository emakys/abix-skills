# Reporting y Analytics HR

## Reportes Estándar SAP HCM

### Administración de Personal (PA)
- **RPPHCE00** — Headcount Report: listado de empleados activos con infotipos 0000/0001/0002. Parámetros clave: fecha clave, área de personal, subárea, grupo/subgrupo de empleados.
- **RHSTRU00** — Estructura Organizacional: visualización jerárquica de unidades org, puestos y titulares. Soporta variantes de evaluación y horizontes de tiempo.
- **RPLMIT00** — Lista de cumpleaños: empleados con fecha de nacimiento en rango (IT0002-GBDAT). Útil para comunicaciones internas.
- **RPLMIT10** — Lista de aniversarios: fecha de ingreso (IT0041 o IT0000-BEGDA). Configurable por tipo de fecha.
- **RPABST20** — Resumen de ausencias por tipo y período (IT2001). Comparativo entre períodos.
- **RPTABS20** — Saldos de tiempos: cuotas de ausencia acumuladas vs. consumidas (IT2006).

### Reportes de Nómina (PY)
- **PC00_M99_CEDT** — Diario de nómina (Payroll Journal): detalle de resultados por empleado con saldos de tipos de salario. Principal reporte de auditoría de nómina.
- **PC00_M99_REMUNERATION** — Recibo de sueldo (Remuneration Statement): genera el comprobante de pago individual. Configurable por forma de recibo (PE51).
- **H99_DISPLAY_PAYRESULT** — Wage Type Reporter: análisis ad-hoc de resultados de nómina por tipo de salario, período y área de nómina. Accede a tablas RT, CRT, WPBP de clúster PCL2.
- **PC00_M99_CWTR** — Resumen de tipos de salario: totales acumulados por área de nómina.
- **PC00_M99_DKON** — Cuenta individual: historial de liquidaciones por empleado.
- **RPCALC0** — Log de cálculo de nómina: trazabilidad paso a paso del esquema de nómina.

### Sistema de Información HR (HIS)
Transacción **S_PH0_48000450** (HR Information System):
- Acceso integrado a todos los reportes HR clasificados por infotipo
- Navegación por módulo: PA, OM, PY, TM, PD
- Permite lanzar reportes con selección preconfigurada
- Reportes favoritos por usuario

## Ad Hoc Query — SQ01

### Bases de Datos Lógicas HR
| Base de Datos | Uso Principal | Tablas Clave |
|---|---|---|
| **PNP** | Datos de empleados (PA) | PA0001, PA0002, PA0006, PA0008 |
| **PNPCE** | PNP con soporte concurrente (S/4HANA) | Reemplaza PNP para payroll concurrente |
| **PCH** | Objetos OM (O, S, C, G, Q) | HRP1000, HRP1001 |

### Configuración de Queries (SQ01)
1. Definir área de usuario (transacción SQ03) o área estándar
2. Crear grupo de usuarios (SQ03) y asignar usuarios
3. Definir InfoSet (SQ02): seleccionar base de datos lógica + campos de infotipos
4. Crear Query (SQ01): seleccionar campos, definir selección, ordenamiento y visualización
5. Ejecutar en modo ALV o descarga a Excel

### SAP Query — Grupos Funcionales
- **Grupo de usuarios**: agrupación de usuarios con acceso compartido a queries
- **InfoSet**: define la fuente de datos (BD lógica + joins adicionales)
- **Query**: combinación de InfoSet con layout de presentación
- Transporte: SQ02/SQ01 con tabla AQDT/AQST

## CDS Analytical Views en S/4HANA

### Vistas Analíticas Estándar HR
```abap
" Headcount y estructura
C_EmployeeHCM           " Vista de empleados con atributos HR
I_HCMEmployeeTimeData   " Datos de tiempo
C_HCMPayrollResult      " Resultados de nómina en ACDOCA

" Posteo a libro mayor universal
I_GLAccountLineItemRawHCM  " Líneas HCM en Universal Journal
```

### Embedded Analytics HR
- **Overview Pages (OVP)**: F3041 People Profile con KPIs en tiempo real
- **Smart Business Cockpits**: headcount trend, attrition rate, time-to-hire
- **SAP Analytics Cloud (SAC)**: conectado a CDS views vía OData, reportes predefinidos de HR
- Activación: transacción **SBIW** para DataSources HCM + replicación BW/SAC

### Puntos de Extensión Analytics
```abap
" Extension CDS para campos custom en reporting
@AbapCatalog.sqlViewName: 'ZXHCMEMP'
@Analytics.dataCategory: #DIMENSION
define view Z_HCMEmployee_Ext
  as select from C_EmployeeHCM
  association to ZHR_CUSTOM_T as _Custom on ...
{
  key EmployeeNumber,
  _Custom.ZZCustomField1
}
```

## Queries MCP para Reporting HR

### Herramientas MCP Relevantes
Usando `@mcp-abap-adt/core` para desarrollo de reportes:

```
" Leer programa de reporte estándar
GetObjectSource: object_type=PROG, object_name=RPPHCE00

" Buscar queries existentes
SearchObject: object_type=AQQU, search_string=HR*

" Leer InfoSet
GetObjectSource: object_type=AQSG, object_name=<infoset>

" Verificar variantes de selección
ReadTable: table_name=VARID, fields=[REPORT, VARIANT], where=REPORT = 'RPPHCE00'
```

### Desarrollo de Reportes Custom
```abap
" Reporte ALV usando base de datos lógica PNP
REPORT ZRPH_HEADCOUNT_CUSTOM.

INFOTYPES: 0000, 0001, 0002.

START-OF-SELECTION.
  GET PERNR.
    READ INFOTYPE 0001 FIELDS BUKRS WERKS ORGEH.
    READ INFOTYPE 0002 FIELDS VORNA NACHN GBDAT.
    COLLECT wa_output INTO lt_output.

END-OF-SELECTION.
  " Display ALV
  lo_alv->set_table_for_first_display( lt_output ).
```

## Mejores Practicas de Reporting HR

1. **Autorización de datos**: siempre usar objecto P_ORGIN/P_ORGINCON para proteger datos sensibles en reportes
2. **Performance**: preferir CDS views sobre SELECT directos a tablas PA*, usar índices de cluster PCL2
3. **Consistencia de datos**: ejecutar reportes de nómina sobre resultados de corrida productiva (ABKRS), no de simulación
4. **Auditoría**: PC00_M99_CEDT como fuente oficial para conciliación contable
5. **Exportación**: preferir ALV con descarga a Excel o integración directa con SAP Analytics Cloud
