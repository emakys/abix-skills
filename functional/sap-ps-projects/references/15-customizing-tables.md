# Tablas de Customizing SAP PS

## Introduccion

Esta referencia cataloga las principales tablas de customizing del modulo SAP PS (Project System), organizadas por area funcional. Incluye los campos clave, descripcion y ejemplos de consultas MCP para diagnostico y analisis.

**Nota:** Las tablas de customizing se consultan normalmente via SE16/SE16N en entornos de desarrollo. En produccion, solo deben modificarse a traves de SPRO.

---

## 1. Perfiles de Proyecto

### T001P - Perfil de Proyecto (Project Profile)

**Descripcion:** Define los parametros por defecto para cada tipo de proyecto.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MANDT | CLNT | Mandante |
| PSPID | CHAR24 | Clave del perfil de proyecto |
| LTEXT | CHAR40 | Descripcion |
| PROJT | CHAR2 | Tipo de proyecto |
| STATV | CHAR8 | Perfil de status WBS |
| NETPF | CHAR6 | Perfil de red por defecto |
| PGPRO | CHAR4 | Perfil de avance |
| BUDPF | CHAR6 | Perfil de presupuesto |
| VBUKR | CHAR4 | Sociedad |
| GSBER | CHAR4 | Area de negocio |
| PRCTR | CHAR10 | Centro de beneficio |
| TXJCD | CHAR15 | Jurisdiccion fiscal |
| ZSCHL | CHAR4 | Clave de liquidacion |
| ABKRS | CHAR4 | Tipo de liquidacion |

**Query MCP:**
```sql
SELECT pspid, ltext, projt, statv, netpf, pgpro, budpf, vbukr
FROM t001p
WHERE mandt = '100'
ORDER BY pspid
```

### PRPS_PRART - Tipos de Elemento WBS

**Descripcion:** Define los tipos de elemento WBS disponibles en el sistema.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PRART | CHAR2 | Clave del tipo WBS |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |

---

## 2. Tipos de Proyecto

### T_TYPE_PS - Tipos de Proyecto PS

**Descripcion:** Clasificacion de proyectos (capital, opex, servicio, I+D, etc.).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PROJT | CHAR2 | Clave tipo de proyecto |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion del tipo |
| BUDPF | CHAR6 | Perfil de presupuesto asignado |
| STATV | CHAR8 | Perfil de status asignado |

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Work Breakdown Structure
> Define Project Types
```

---

## 3. Perfiles de WBS (Perfil de Elemento WBS)

### T8PW - Perfil de Posicion WBS

**Descripcion:** Parametros de control para elementos WBS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PRPRF | CHAR4 | Clave del perfil WBS |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion del perfil |
| BELKZ | CHAR1 | Elemento de cuenta por defecto |
| PSWBS | CHAR1 | Elemento resumen por defecto |
| STATV | CHAR8 | Perfil de status por defecto |
| PSPID | CHAR24 | Proyecto por defecto |

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Work Breakdown Structure
> Define WBS Element Profile
```

---

## 4. Perfiles de Red

### T_NETPF - Perfil de Red

**Descripcion:** Parametros de control para redes de trabajo.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| NETPF | CHAR6 | Clave del perfil de red |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |
| AUFART | CHAR4 | Tipo de orden (PP01, PM01, etc.) |
| KALAID | CHAR6 | Variante de calculo de costes |
| KALSM | CHAR6 | Esquema de calculo |
| RESRV | CHAR1 | Crear reserva al REL |
| MGPRO | CHAR1 | Indicador MRP para componentes |
| STATV | CHAR8 | Perfil de status de red |
| PGPRO | CHAR4 | Perfil de avance red |

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Network
> Settings for Networks > Define Network Profile
```

### T_ATYP - Tipos de Actividad de Red

**Descripcion:** Define los tipos de actividades (internamente procesadas, externamente, generales, hitos).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| VGTYP | CHAR1 | Tipo: I=interno, E=externo, G=general, M=hito |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |

---

## 5. Claves de Control (Control Keys)

### T438A - Claves de Control de Actividad

**Descripcion:** Define el comportamiento de cada actividad de red (si permite confirmacion, si es a precio estandar, si genera documentos CO, etc.).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| STEUS | CHAR4 | Clave de control |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |
| IKOFI | CHAR1 | Imputacion CO activa |
| KZTRK | CHAR1 | Calculo costes en confirmacion |
| KZMRP | CHAR1 | Relevante para planificacion |
| KZAVA | CHAR1 | Confirmacion obligatoria |
| KZPRT | CHAR1 | Crear solicitud automatica |
| KZMAI | CHAR1 | Indicador de hito |

**Claves de control tipicas en PS:**

| Clave | Uso |
|-------|-----|
| PS01 | Actividad interna sin confirmacion |
| PS02 | Actividad interna con confirmacion |
| PS03 | Actividad externa (servicios) |
| PS04 | Hito |
| PS05 | Actividad general (costes directos) |

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Network
> Settings for Activities > Define Control Keys
```

**Query MCP:**
```sql
SELECT steus, ltext, ikofi, kztrk, kzmrp, kzava, kzprt, kzmai
FROM t438a
WHERE spras = 'S'
ORDER BY steus
```

---

## 6. Perfiles de Presupuesto

### T_BUDPF - Perfil de Presupuesto

**Descripcion:** Parametros que controlan como se gestiona el presupuesto en los proyectos.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| BUDPF | CHAR6 | Clave del perfil de presupuesto |
| LTEXT | CHAR40 | Descripcion |
| KKBPR | CHAR1 | Presupuesto por anio |
| KKPUP | CHAR1 | Actualizar presupuesto a niveles superiores |
| TOLPR | DEC | Porcentaje tolerancia para advertencias |
| TOLFE | DEC | Porcentaje tolerancia para errores |
| KKEXT | CHAR1 | Presupuesto como maximo (no sobrepasar) |
| BUDCH | CHAR1 | Cambios de presupuesto requieren aprobacion |

**Tolerancias de presupuesto:**
- TOLPR < x < TOLFE: Warning (mensaje amarillo)
- x >= TOLFE: Error (bloquea la operacion)
- x <= 0: Sin restriccion de presupuesto

**Ruta SPRO:**
```
Project System > Costs > Budget > Define Budget Profile
```

### T_AVTY - Tipos de Disponibilidad para Control de Presupuesto

**Descripcion:** Que tipos de valores se consideran en el control de disponibilidad presupuestaria.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| AVTYP | CHAR2 | Tipo de disponibilidad |
| WRTTP | CHAR2 | Tipo de valor (04=plan, 11=real, 21=compromiso) |
| LTEXT | CHAR40 | Descripcion |

---

## 7. Status de Sistema y Usuario

### TJ02 - Status de Sistema (Solo Lectura)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| ISTAT | CHAR5 | Codigo interno (I0001-I9999) |
| STATV | CHAR4 | Abreviatura (CREA, REL, TECO...) |
| ESTAT | CHAR1 | Tipo: S=sistema |
| ECANC | CHAR1 | Cancelable |

**Query MCP:**
```sql
SELECT istat, statv FROM tj02 WHERE estat = 'S' ORDER BY istat
```

### TJ30 - Perfiles de Status de Usuario (Cabecera)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| STSMA | CHAR8 | Clave perfil de status |
| SPRAS | LANG | Idioma |
| STEXT | CHAR40 | Descripcion |

### TJ32 - Status de Usuario (Detalle)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| STSMA | CHAR8 | Perfil de status |
| ESTAT | CHAR4 | Clave status usuario |
| TXT04 | CHAR4 | Abreviatura |
| TXT30 | CHAR30 | Descripcion |
| INITU | CHAR1 | Status inicial |
| POSTI | NUMC3 | Posicion secuencia |

---

## 8. Determinacion de Cuentas

### T030 - Cuentas GL para Tipos de Movimiento PS

**Descripcion:** Determinacion de cuentas contables para contabilizaciones automaticas en PS/MM.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| KTOPL | CHAR4 | Plan de cuentas |
| BKLA | CHAR4 | Clave de operacion (BSX, WRX, GBB...) |
| KMOD | CHAR4 | Modificador de cuenta |
| KOART | CHAR1 | Tipo cuenta (S=GL) |
| KONTS | CHAR10 | Cuenta GL |

**Ruta SPRO (OBYC):**
```
Financial Accounting > General Ledger > Business Transactions
> Automatic Account Determination > Configure G/L Account Determination (OBYC)
```

### TKKB - Clases de Coste para Control Presupuestario

**Descripcion:** Define que clases de coste se suman para el control de disponibilidad de presupuesto.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| KOSTL | CHAR10 | Clase de coste |
| KKBUK | CHAR1 | Relevante para control presupuesto |

---

## 9. Rangos de Numeracion

### NRIV - Intervalos de Numeracion

**Descripcion:** Rangos de numeracion para proyectos, redes, etc.

**Objetos relevantes PS:**

| Objeto | Descripcion |
|--------|-------------|
| 04 | Proyectos (PSPID) |
| 05 | Redes de trabajo |
| 06 | Ordenes de trabajo (actividades externas) |
| 25 | Elementos WBS (internos) |

**Transaccion:** SNRO (administrar rangos) o directamente en SPRO.

**Ruta SPRO:**
```
Project System > Structures > Operative Structures
> Define Number Ranges for Projects/Networks
```

---

## 10. Tolerancias de Fechas

### T399D - Parametros de Programacion de Red

**Descripcion:** Tolerancias y parametros para la programacion (scheduling) de redes.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| NETPF | CHAR6 | Perfil de red |
| TERML | NUMC3 | Tolerancia inicio (dias) |
| TERME | NUMC3 | Tolerancia fin (dias) |
| TSCHD | CHAR1 | Tipo de programacion (F=foward, B=backward) |
| KALID | CHAR2 | Calendario fabrica |

**Ruta SPRO:**
```
Project System > Dates > Scheduling > Define Scheduling Parameters for Networks
```

---

## 11. Perfiles de Avance

### EVPROFIL - Perfil de Avance (Progress Profile)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PGPRO | CHAR4 | Clave del perfil |
| LTEXT | CHAR40 | Descripcion |
| PGMTH | CHAR2 | Metodo medicion por defecto |
| PGBAS | CHAR1 | Base calculo (C=coste, D=duracion) |
| PGANM | CHAR1 | Calculo automatico (X=si) |
| PGAGG | CHAR1 | Tipo agregacion (C=coste, D=duracion, M=manual) |
| PGVER | NUMC2 | Version de avance por defecto |
| VERSN | NUMC3 | Version plan para calculo PV |

---

## 12. Liquidacion

### OKZP - Reglas de Liquidacion Automatica por Tipo de Receptor

**Descripcion:** Define los tipos de receptor validos para liquidacion de proyectos.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| ABKRS | CHAR4 | Tipo de liquidacion |
| KOART | CHAR1 | Tipo de receptor: A=activo, G=GL, K=CC, C=orden |
| ZSCHL | CHAR4 | Clave de asentamiento |
| POSIT | NUMC3 | Posicion en regla |

### OKZPK - Parametros de Tipo de Liquidacion

**Descripcion:** Parametros principales del tipo de liquidacion.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| ABKRS | CHAR4 | Clave del tipo de liquidacion |
| LTEXT | CHAR40 | Descripcion |
| PERSL | CHAR1 | Basado en periodos |
| KZAUS | CHAR1 | Liquidacion de saldo |
| ALART | CHAR1 | Tipo de asentamiento (P=periodic, F=full) |

**Ruta SPRO:**
```
Project System > Costs > Settlement > Define Settlement Profile
```

### T8PSS - Claves de Asentamiento

**Descripcion:** Claves que definen como se distribuyen los costes en la liquidacion.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| ZSCHL | CHAR4 | Clave de asentamiento |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |
| KZVER | CHAR1 | Porcentaje / Equivalente / Cantidad |
| PRZKL | CHAR1 | Clave de porcentaje |

---

## 13. Overhead / Gastos Generales

### KZK2 - Esquema de Calculo de Overhead

**Descripcion:** Esquemas de calculo de gastos generales aplicables a proyectos.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| KALSM | CHAR6 | Esquema de calculo |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |
| KOART | CHAR1 | Tipo de orden (PS, PP, etc.) |

**Ruta SPRO:**
```
Controlling > Product Cost Controlling > Cost Object Controlling
> Product Cost by Order > Period-End Closing > Overhead > Define Overhead Schemas
```

---

## 14. Clases de Coste para PS

### CSKB - Maestro de Clases de Coste (Centro Control. Beneficio)

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| KTOPL | CHAR4 | Plan de cuentas |
| KSTAR | CHAR10 | Clase de coste |
| DATBI | DATS | Valido hasta |
| DATAB | DATS | Valido desde |
| KATYP | CHAR1 | Tipo: 1=primaria, 3=interna, 4=resultado |
| KOKRS | CHAR4 | Sociedad CO |

**Query MCP - Clases de coste tipo primario relevantes para PS:**
```sql
SELECT kstar, SUBSTRING(datab,1,4) AS anio_ini,
       katyp,
       CASE katyp WHEN '1' THEN 'Primaria' WHEN '3' THEN 'Interna' ELSE 'Otro' END AS tipo
FROM cskb
WHERE kokrs = '1000'
  AND katyp IN ('1', '3')
  AND datbi >= '99991231'
ORDER BY kstar
```

---

## 15. Categorias de WBS

### T_PRART - Categoria de WBS (WBS Category)

**Descripcion:** Tipos o categorias de elemento WBS para clasificacion interna.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PRART | CHAR2 | Clave categoria |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |
| BELKZ | CHAR1 | Siempre elemento de cuenta |
| PLKZ | CHAR1 | Siempre elemento resumen |

---

## 16. Codigos de Red

### T405 - Codigos de Red

**Descripcion:** Catalogo de codigos de red reutilizables (network codes).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| NETCO | CHAR12 | Codigo de red |
| NETPF | CHAR6 | Perfil de red |
| WERKS | CHAR4 | Centro |
| LTEXT | CHAR40 | Descripcion |
| AUFART | CHAR4 | Tipo de orden |

**Ruta SPRO:**
```
Project System > Structures > Operative Structures > Network
> Settings for Networks > Define Standard Networks
```

---

## 17. Parametros de Centro para PS

### T096P - Parametros PS por Centro

**Descripcion:** Parametros especificos de PS por centro de planificacion.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| WERKS | CHAR4 | Centro |
| NETPF | CHAR6 | Perfil de red por defecto |
| PRFID | CHAR6 | Perfil de WBS por defecto |
| PGPRO | CHAR4 | Perfil de avance por defecto |
| BUDPF | CHAR6 | Perfil de presupuesto por defecto |
| KALID | CHAR2 | Calendario de fabrica |
| AUFART | CHAR4 | Tipo de orden por defecto |

---

## 18. Tipos de Hito

### CN_MILESTONE_TYPE - Tipos de Hito

**Descripcion:** Clasifica los hitos por su funcion (inicio, fin, revision, entrega, pago, etc.).

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| MLTYS | CHAR1 | Clave tipo: A=general, B=facturacion, F=control |
| SPRAS | LANG | Idioma |
| LTEXT | CHAR40 | Descripcion |

---

## 19. Categorias de Clases de Coste PS

### TKA02 - Categorias de Clase de Coste

**Descripcion:** Agrupa las clases de coste por categoria para informes PS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| KOKRS | CHAR4 | Sociedad CO |
| KSTAR | CHAR10 | Clase de coste |
| KOSAR | CHAR1 | Categoria: 1=salarios, 2=materiales, etc. |
| DATBI | DATS | Valido hasta |

---

## 20. Tablas de Control de Periodos

### T001B - Periodos Contables Abiertos

**Descripcion:** Controla que periodos estan abiertos para contabilizacion en CO/PS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| BUKRS | CHAR4 | Sociedad |
| RRCTY | CHAR1 | Tipo registro: A=AA, K=cliente, S=proveedor |
| POPER | NUMC2 | Periodo abierto desde |
| PERIV | NUMC2 | Periodo abierto hasta |
| RYEAR | NUMC4 | Ejercicio |

---

## 21. Tabla Resumen de Perfiles PS

| Tabla | Descripcion | Trans. Modificacion |
|-------|-------------|---------------------|
| T001P | Perfil de proyecto | SPRO → CJ Define Project Profile |
| T8PW | Perfil WBS | SPRO → Define WBS Element Profile |
| T_NETPF | Perfil de red | SPRO → Define Network Profile |
| T438A | Clave de control actividad | SPRO → Define Control Keys |
| T_BUDPF | Perfil de presupuesto | SPRO → Define Budget Profile |
| EVPROFIL | Perfil de avance | SPRO → Define Progress Profile |
| TJ30/TJ32 | Perfil status usuario | BS02 |
| OKZPK | Tipo de liquidacion | SPRO → Define Settlement Profile |
| T8PSS | Clave de asentamiento | SPRO → Define Settlement Key |
| NRIV | Rangos numeracion | SNRO |
| T096P | Parametros PS por centro | SPRO → PS Plant Parameters |
| T399D | Parametros scheduling | SPRO → Define Scheduling Parameters |

---

## 22. Tablas de Integracion PS-CO

### COBRB - Reglas de Liquidacion en CO

**Descripcion:** Las reglas de liquidacion de proyectos y WBS se almacenan en esta tabla.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| OBJNR | CHAR22 | Numero objeto CO del WBS |
| LFDNR | NUMC3 | Numero secuencial de regla |
| EMPFG | CHAR22 | Receptor (AUF, KOS, PSP, ANL...) |
| PROZS | DEC | Porcentaje de liquidacion |
| BEKNZ | CHAR1 | Indicador: F=full, P=periodo, A=asentamiento |
| DATAB | DATS | Valido desde |
| DATBI | DATS | Valido hasta |
| ZSCHL | CHAR4 | Clave de asentamiento |
| KOSTL | CHAR10 | CC receptor (si tipo K) |
| AUFNR | CHAR12 | Orden CO receptora |
| PS_PSP_PNR | NUMC8 | WBS receptor |

**Query MCP - Reglas de liquidacion de WBS de un proyecto:**
```sql
SELECT p.posid, c.lfdnr, c.empfg, c.prozs, c.beknz, c.zschl,
       c.datab, c.datbi
FROM prps p
INNER JOIN cobrb c ON c.objnr = CONCAT('PR', p.pspnr)
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
ORDER BY p.posid, c.lfdnr
```

---

## 23. Tablas de Presupuesto

### BPGE - Presupuesto Global de WBS (Anual)

**Descripcion:** Almacena el presupuesto asignado a cada elemento WBS por ejercicio.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PSPNR | NUMC8 | Numero WBS |
| GJAHR | NUMC4 | Ejercicio |
| GKTRP | CURR | Presupuesto total (original + suplementos) |
| BKTRP | CURR | Presupuesto original |
| NKTRP | CURR | Suplementos de presupuesto |
| RKTRP | CURR | Devoluciones de presupuesto |
| FRTRP | CURR | Liberacion de presupuesto |
| WAERS | CUKY | Moneda |

**Query MCP - Presupuesto vs. disponible por WBS:**
```sql
SELECT p.posid, p.post1,
       b.gjahr,
       b.gktrp AS presupuesto_total,
       b.frtrp AS presupuesto_liberado,
       b.waers
FROM prps p
INNER JOIN bpge b ON b.pspnr = p.pspnr
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND b.gjahr = '2024'
ORDER BY p.posid
```

### BPJA - Presupuesto Anual de WBS (Por Periodo)

**Descripcion:** Distribucion mensual del presupuesto de WBS.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| PSPNR | NUMC8 | Numero WBS |
| GJAHR | NUMC4 | Ejercicio |
| PERIO | NUMC2 | Periodo (01-12) |
| GKTRP | CURR | Presupuesto del periodo |
| WAERS | CUKY | Moneda |

---

## 24. Tablas de Costes de Proyecto

### COSP - Costes Totales por Objeto CO

**Descripcion:** Costes planificados y reales por objeto CO, clase de coste y periodo.

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| OBJNR | CHAR22 | Numero objeto CO |
| GJAHR | NUMC4 | Ejercicio |
| VERSN | NUMC3 | Version de plan |
| KSTAR | CHAR10 | Clase de coste |
| WRTTP | CHAR2 | Tipo valor (04=plan, 11=real, 40=comprometido) |
| PERIO | NUMC2 | Periodo |
| WKG001-WKG016 | CURR | Valores por periodo (1-12 + especiales) |
| WAERS | CUKY | Moneda |

**Query MCP - Costes reales YTD por clase de coste de un WBS:**
```sql
SELECT c.kstar, ck.ktext, SUM(c.wkg001 + c.wkg002 + c.wkg003 + c.wkg004 +
       c.wkg005 + c.wkg006 + c.wkg007 + c.wkg008 +
       c.wkg009 + c.wkg010 + c.wkg011 + c.wkg012) AS total_real
FROM cosp c
INNER JOIN csku ck ON ck.kstar = c.kstar AND ck.kokrs = '1000' AND ck.datbi = '99991231'
WHERE c.objnr = (SELECT CONCAT('PR', pspnr) FROM prps WHERE posid = 'P-2024-001.1.1' AND vernr = '00')
  AND c.gjahr = '2024'
  AND c.versn = '000'
  AND c.wrttp = '11'
GROUP BY c.kstar, ck.ktext
ORDER BY total_real DESC
```

---

## 25. Tablas de Informacion Complementaria

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| PROJ | Cabecera de proyecto | PSPNR, PSPID, VERNR |
| PRPS | Elementos WBS | PSPNR, POSID, PSPHI, VERNR |
| PRTE | Fechas de WBS | PSPNR, TERMK (tipo fecha) |
| NETZ | Cabecera de red | AUFNR, PSPNR |
| VORG | Actividades de red | AUFNR, VORNR, STEUS |
| MSPT | Hitos | AUFNR, VORNR (actividad hito) |
| RPSCO | Totales de costes planificados WBS | OBJNR, WRTTP |
| EVPR | Registros de avance | PSPNR, PGVER, DATUM |
| EVPO | Valores EVM calculados | PSPNR, GJAHR |
| PRVER | Versiones de proyecto | PSPID, VERNR |
| JSTO | Status objetos (cabecera) | OBJNR, STSMA |
| JEST | Status activos por objeto | OBJNR, STAT, INACT |
| COBRB | Reglas de liquidacion CO | OBJNR, EMPFG |
| BPGE | Presupuesto WBS global | PSPNR, GJAHR |
| BPJA | Presupuesto WBS por periodo | PSPNR, GJAHR, PERIO |
| COSP | Costes totales CO | OBJNR, GJAHR, VERSN, KSTAR |
| COSS | Costes secundarios CO | OBJNR, GJAHR, VERSN |
| RESB | Reservas de material | RSNUM, PS_PSP_PNR |
| MATDOC | Documentos de material (S/4) | MBLNR, PS_PSP_PNR |
| ACDOCA | Diario universal (S/4) | BELNR, PS_PSP_PNR |

---

## 26. Query de Diagnostico Integral

**Query MCP - Estado completo de un proyecto:**
```sql
-- Resumen de proyecto con costes, presupuesto y status
SELECT
    pro.pspid AS proyecto,
    pro.post1 AS descripcion,
    pro.vbukr AS sociedad,
    pro.erdat AS fecha_creacion,
    SUM(CASE WHEN j.stat = 'I0002' AND j.inact <> 'X' THEN 1 ELSE 0 END) AS wbs_liberados,
    SUM(CASE WHEN j.stat = 'I0009' AND j.inact <> 'X' THEN 1 ELSE 0 END) AS wbs_teco,
    COUNT(p.pspnr) AS total_wbs
FROM proj pro
INNER JOIN prps p ON p.psphi = pro.pspnr AND p.vernr = '00'
LEFT JOIN jest j ON j.objnr = CONCAT('PR', p.pspnr)
WHERE pro.pspid LIKE 'P-2024-%'
  AND pro.vernr = '00'
GROUP BY pro.pspid, pro.post1, pro.vbukr, pro.erdat
ORDER BY pro.pspid
```
