# Modelo de Datos S/4HANA 2023 — PM

## Tablas Principales

### Objetos Tecnicos
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| EQUI | Equipos (maestro) | EQUNR, EQTYP, EQART, HERST, SWERK, TPLNR, KOSTL |
| EQKT | Textos equipo | EQUNR, SPRAS, EQKTX |
| EQUZ | Asignacion temporal equipo | EQUNR, DATBI, HESSION |
| IFLOT | Ubicaciones tecnicas | TPLNR, FLTYP, IWERK, SWERK, KOSTL |
| IFLOS | Textos ubicacion | TPLNR, SPRAS, PLTXT |
| ILOA | Asignacion objeto → ubicacion | ILOAN, TPLNR, EQUNR |

### Avisos
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| QMEL | Cabecera aviso | QMNUM, QMART, EQUNR, TPLNR, IWERK |
| QMFE | Items dano | QMNUM, FESSION, FEGRP, FECOD |
| QMUR | Causas | QMNUM, URESSION, URGRP, UESSION |
| QMSM | Actividades/medidas | QMNUM, MESSION, MNGRP, MNCOD |
| QMIH | Datos PM del aviso | QMNUM, EQUNR, TPLNR |

### Ordenes
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| AUFK | Cabecera orden (general) | AUFNR, AUART, OBJNR, KOSTV |
| AFIH | Cabecera PM orden | AUFNR, EQUNR, TPLNR, INGRP, QMNUM |
| AFKO | Cabecera produccion/PM | AUFNR, AUFPL, GSTRP, GLTRP |
| AFVC | Operaciones | AUFPL, APLZL, VORNR, LTXA1, ARBID |
| AFVV | Valores operacion | AUFPL, APLZL, VGW01-VGW06 |
| AFRU | Confirmaciones | RUESSION, AUFNR, VORNR, ISDD |
| RESB | Reservas material | RSNUM, AUFNR, MATNR, BDMNG |

### Planes de Mantenimiento
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| MPLA | Plan mantenimiento | WARPL, STESSION |
| MPOS | Posiciones plan | WARPL, POINT, EQUNR, TPLNR |
| MHIS | Historial llamadas | WARPL, LESSION, AUFNR |

### Mediciones
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| IMPTT | Puntos de medida | POINT, EQUNR, ATNAM |
| IMRG | Documentos medicion | MDOCM, POINT, READG, IDATE |

### Status
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| JEST | Status actuales | OBJNR, STAT, INACT |
| JSTO | Perfil status | OBJNR, STSMA |

### Costes (S/4HANA)
| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| ACDOCA | Universal Journal | AUFNR, RACCT, HSL, BUDAT |
| MATDOC | Documentos material (reemplaza MSEG) | MBLNR, AUFNR, MATNR |

## CDS Views Principales

| CDS View | Descripcion |
|----------|-------------|
| I_MaintenanceOrder | Orden PM (interfaz) |
| I_MaintenanceNotification | Aviso PM |
| I_Equipment | Equipo |
| I_FunctionalLocation | Ubicacion tecnica |
| I_MaintenancePlan | Plan mantenimiento |
| C_MaintOrderCostAnalysis | Analisis costes orden (consumo) |

## Diferencias ECC vs S/4HANA

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Costes | COSP, COSS, COEP | ACDOCA (Universal Journal) |
| Movimientos material | MKPF + MSEG | MATDOC |
| Reporting | Report Painter, PMIS | CDS + Fiori + PMIS |
| UI | SAP GUI | Fiori (GUI como fallback) |
| APIs | BAPIs | BAPIs + OData + RAP |

## Queries MCP Modelo de Datos

```
-- Relacion equipo → ubicacion → ordenes → costes
GetSqlQuery("SELECT E.EQUNR,E.TPLNR,A.AUFNR,A.AUART,SUM(D.HSL) as COSTES FROM EQUI E JOIN AFIH F ON E.EQUNR=F.EQUNR JOIN AUFK A ON F.AUFNR=A.AUFNR LEFT JOIN ACDOCA D ON A.AUFNR=D.AUFNR AND D.GJAHR='{year}' AND D.RLDNR='0L' WHERE E.SWERK='{centro}' GROUP BY E.EQUNR,E.TPLNR,A.AUFNR,A.AUART")
```
