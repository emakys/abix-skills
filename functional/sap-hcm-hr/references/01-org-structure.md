# Estructura Organizativa HR

## Jerarquia de Objetos Organizativos

```
Cliente SAP
└── Sociedad (Bukrs) — tabla T001
    └── Area de Personal (Werks) — tabla T001P
        └── Subdivision de Personal (Btrtl) — tabla T001P campo BTRTL
            └── Grupo de Empleados (Persg) — tabla T501
                └── Subgrupo de Empleados (Persk) — tabla T503
                    └── Area de Nomina (Abkrs) — tabla T549A
```

## Objetos Clave y Tablas

### Area de Personal (Personnel Area)
- Tabla: T001P (campo WERKS = area de personal, no confundir con centro logistico)
- Representa una unidad geografica o legal dentro de una sociedad
- Ejemplo: "SEDE CENTRAL", "PLANTA NORTE", "OFICINA MADRID"
- Relacion con FI: una sociedad puede tener multiples areas de personal
- Campo MOLGA (Country Grouping) se deriva del area de personal → determina esquema de nomina

### Subdivision de Personal (Personnel Subarea)
- Tabla: T001P (campo BTRTL, combinado con WERKS forma la clave)
- Subdivision logica dentro del area de personal
- Hereda MOLGA del area de personal padre
- Controla: calendarios de trabajo, convenios colectivos, parametros de nomina locales
- Tabla T001P-TARIFV: tipo de convenio colectivo asignado
- Tabla T001P-TRFGB: area de convenio colectivo

### Grupo de Empleados (Employee Group)
- Tabla: T501 (campo PERSG)
- Clasificacion de alto nivel: Activo, Pensionista, Externo, Becario
- Controla elegibilidad de prestaciones y reglas de nomina
- Tabla T501T: textos del grupo de empleados

### Subgrupo de Empleados (Employee Subgroup)
- Tabla: T503 (campo PERSK, combinado con PERSG)
- Subdivision dentro del grupo: Empleado mensual, Horario, Directivo, Temporal
- Tabla T503T: textos del subgrupo
- Controla: esquema de tiempo (T503-ZEINH), agrupacion de convenio (T503-TRFKZ)
- Agrupacion para areas de nomina: T503K

### Area de Nomina (Payroll Area)
- Tabla: T549A (campo ABKRS)
- Define la periodicidad de calculo: mensual, quincenal, semanal
- Campo T549A-PABRP: periodo de nomina actual
- Campo T549A-PABRJ: anno de nomina actual
- Control de periodos: tabla T549Q (periodos de nomina con fechas inicio/fin)

## Country Grouping (MOLGA)

El MOLGA determina:
- Esquema de nomina aplicable (tabla T549A-MANDT no, sino view V_001P_B)
- Infotipos especificos de pais disponibles (IT0045 Spain, IT0077 USA, etc.)
- Tablas de customizing especificas de pais (prefijo del pais)

Valores MOLGA comunes:
| MOLGA | Pais |
|-------|------|
| 01 | Alemania |
| 02 | Suiza |
| 03 | Austria |
| 04 | Espana |
| 08 | Gran Bretana |
| 10 | USA |
| 17 | Mexico |
| 24 | Argentina |
| 35 | Colombia |

## Relacion con Estructura FI

```
Mandante
├── Sociedad FI (T001-BUKRS) ←→ Area de Personal (T001P-BUKRS)
│   ├── Plan de cuentas (T001-KTOPL)
│   ├── Moneda de sociedad (T001-WAERS)
│   └── Areas de Personal vinculadas via T001P-BUKRS
│
└── Controlling Area (TKA01-KOKRS)
    └── Centro de Coste → asignado al empleado en IT0001-KOSTL
        └── Postings nomina via RPCIPE00 → tabla ACDOCA (S/4HANA)
```

Campos de integracion FI/CO en Infotipo 0001:
- BUKRS: Sociedad
- KOSTL: Centro de coste
- WERKS: Area de personal (≠ centro logistico MM)
- VDSK1: Subdivision organizativa CO-PA

## Gestion Organizacional (OM) — Objetos Relacionados

Tabla principal: HRP1000 (objetos), HRP1001 (relaciones)

Tipos de objeto clave:
| Tipo | Descripcion | Ejemplo |
|------|-------------|---------|
| O | Unidad Organizativa | Departamento RRHH |
| S | Posicion | Gerente de RRHH |
| C | Categoria de Puesto | Gerente |
| P | Persona | Empleado individual |
| US | Usuario | Usuario SAP vinculado |

Relaciones clave (tabla HRP1001, campo RSIGN/RELAT):
- A/B 003: Pertenece a / Incluye (jerarquia OU)
- A/B 008: Titular de / Ocupado por (S→P)
- A/B 007: Descripcion de / Descrito por (S→C)

## Queries MCP Recomendadas

### Leer estructura de areas de personal
```
Tool: ExecuteQuery / ReadTable
Tabla: T001P
Campos: WERKS, BUTXT, BUKRS, BTRTL, BTEXT, MOLGA, TARIFV, TRFGB
Filtro: BUKRS = '<sociedad>'
```

### Leer grupos y subgrupos de empleados
```
Tool: ReadTable
Tabla: T503
Campos: PERSG, PERSK, PTEXT
Sin filtro para ver todos
```

### Leer areas de nomina y periodos actuales
```
Tool: ReadTable
Tabla: T549A
Campos: ABKRS, ATEXT, PABRP, PABRJ, PERMO
```

### Leer infotipo 0001 (Asignacion Organizativa) de un empleado
```
Tool: GetHrMasterData o ReadTable PA0001
Campos clave: PERNR, BUKRS, WERKS, BTRTL, PERSG, PERSK, ABKRS, KOSTL, PLANS, ORGEH
```

### Consultar objetos OM (unidades organizativas)
```
Tool: ReadTable HRP1000
Campos: PLVAR, OTYPE, OBJID, BEGDA, ENDDA, SHORT, STEXT
Filtro: OTYPE = 'O' AND PLVAR = '01' AND ENDDA >= SY-DATUM
```

## Customizing Critico (SPRO)

Ruta: SPRO → Gestion de Personal → Estructura de la Empresa

- Crear Areas de Personal: T001P
- Asignar Areas de Personal a Sociedades FI: vinculo T001P-BUKRS
- Crear Subdivisiones de Personal: extension de T001P con BTRTL
- Definir Grupos de Empleados: T501
- Definir Subgrupos de Empleados: T503
- Asignar Subgrupos a Grupos: T503 con campo PERSG
- Definir Areas de Nomina: T549A con periodicidad
- Asignar Agrupaciones de Pais: derivada de T001P → MOLGA

## Novedades S/4HANA 2023

- Postings de nomina directamente en ACDOCA (Universal Journal) via RPCIPE00 con documento contable simplificado
- Fiori apps para mantenimiento de estructura organizativa: "Manage Organizational Units"
- Integracion con SuccessFactors Employee Central: replicacion bidireccional de estructura OM via SAP Integration Suite
- Business Partner (BP) como objeto central: empleados como BP con rol FLVN01 (empleado)
