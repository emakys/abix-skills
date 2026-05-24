# Programas de Inversiones (IM) y AuC — SAP Project System

## Indice
1. Investment Management — Introduccion
2. Estructura del Programa de Inversiones
3. Transacciones IM Principales
4. Medidas de Inversion
5. Integracion IM-PS (Asignacion WBS)
6. Control Presupuestario IM
7. AuC — Asset under Construction
8. Flujo AuC a Activo Definitivo
9. Capitalizacion y Cuentas
10. Tablas IM Principales
11. Configuracion SPRO
12. Consultas y Reporting IM

---

## 1. Investment Management — Introduccion

### 1.1 Que es Investment Management (IM)

Investment Management es el modulo SAP que gestiona el PORTFOLIO de inversiones de la empresa. Mientras PS gestiona la EJECUCION de proyectos individuales, IM gestiona la PLANIFICACION Y APROBACION de las inversiones a nivel corporativo.

**Relacion IM-PS:**
```
Investment Management (IM)
  = Vision Corporativa de Inversiones
  = Control presupuestario de alto nivel
  = Aprobacion del portfolio

SAP Project System (PS)
  = Ejecucion operativa del proyecto
  = Control de costes detallado
  = Gestion de actividades y recursos

Vinculo: WBS Element ←→ Posicion del Programa IM
```

### 1.2 Cuando Usar IM

| Escenario | Sin IM | Con IM |
|-----------|--------|--------|
| Proyectos operativos simples | X | |
| Proyectos de inversion CAPEX | | X |
| Portfolio de inversiones anual | | X |
| Control presupuesto corporativo | | X |
| Aprobacion de inversiones por Comite | | X |
| Gestion de medidas de inversion | | X |

### 1.3 Conceptos Clave IM

| Concepto | Descripcion |
|----------|-------------|
| Investment Program | Programa de inversiones (arbol jerarquico) |
| Program Position | Posicion del programa (nodo del arbol) |
| Investment Measure | Medida de inversion (WBS o Orden interna) |
| Appropriation Request | Solicitud de inversion |
| Budget Distribution | Distribucion del presupuesto IM a medidas |
| AuC | Activo en Curso (acumula costes hasta capitalizacion) |

---

## 2. Estructura del Programa de Inversiones

### 2.1 Jerarquia del Programa

```
PROGRAMA DE INVERSIONES (Investment Program)
  ├── Posicion 1: CAPEX Infraestructura
  │     ├── Posicion 1.1: Edificios
  │     │     └── Medida: Proyecto PS INV-2024-001 (WBS)
  │     │     └── Medida: Proyecto PS INV-2024-002 (WBS)
  │     └── Posicion 1.2: Maquinaria
  │           └── Medida: Orden Interna OI-2024-001
  └── Posicion 2: CAPEX IT
        └── Posicion 2.1: Hardware
        └── Posicion 2.2: Software
              └── Medida: Proyecto PS INV-2024-003
```

### 2.2 Tipos de Posicion de Programa

| Tipo | Descripcion | Detalle |
|------|-------------|---------|
| Summary position | Solo agrega presupuesto de hijos | No tiene medidas directas |
| Operative position | Puede tener medidas asignadas | Nivel operativo |
| Bottom position | Nivel mas bajo, solo medidas | Posicion hoja |

### 2.3 Variante de Ejercicio

El programa IM opera siempre con ejercicios fiscales:
- Presupuesto por ejercicio (anual)
- Plan por ejercicio
- Traslado de presupuesto entre ejercicios

---

## 3. Transacciones IM Principales

### 3.1 Creacion y Mantenimiento

| Transaccion | Descripcion |
|-------------|-------------|
| `IM01` | Crear programa de inversiones |
| `IM02` | Modificar programa de inversiones |
| `IM03` | Ver programa de inversiones |
| `IM11` | Crear posicion de programa |
| `IM12` | Modificar posicion de programa |
| `IM13` | Ver posicion de programa |
| `IM01N` | Crear programa (nueva interfaz) |
| `IM52` | Crear medida de inversion |
| `IM01AR` | Crear Appropriation Request |

### 3.2 Presupuesto IM

| Transaccion | Descripcion |
|-------------|-------------|
| `IM30` | Planificacion de valores en programa |
| `IM32` | Aprobacion presupuesto original programa |
| `IM35` | Liberacion presupuesto programa |
| `IM38` | Transferencia presupuesto entre posiciones |
| `IM40` | Distribuir presupuesto a medidas |
| `IM42` | Aprobar presupuesto de medida |
| `CJ30` | Aprobar presupuesto PS (desde WBS) |
| `CJ31` | Ver presupuesto PS |

### 3.3 Reporting IM

| Transaccion | Descripcion |
|-------------|-------------|
| `S_ALR_87013558` | Plan/presupuesto/real por programa |
| `S_ALR_87013559` | Presupuesto disponible IM |
| `S_ALR_87013560` | Compromisos por programa |
| `IM23` | Resumen de medidas por posicion |
| `IM40` | Distribucion presupuesto IM |

---

## 4. Medidas de Inversion

### 4.1 Tipos de Medida de Inversion

| Tipo | Objeto SAP | Transaccion | Uso |
|------|-----------|-------------|-----|
| WBS Element | PS WBS | CJ20N | Proyectos grandes |
| Internal Order | CO Order | KO01 | Proyectos pequenos |

### 4.2 Crear Medida como WBS (Proyecto PS)

```
Proceso:
1. CJ01 → Crear proyecto PS
2. CJ20N → en el WBS element:
   → Pestaña "Account Assignment"
   → Campo "Investment measure": X
   → Campo "Appropriation request" (opcional)
3. IM52 → Asignar WBS al programa IM:
   → Seleccionar programa y posicion
   → Asignar WBS como medida
```

**Campos relevantes en PRPS para medida:**
| Campo | Descripcion |
|-------|-------------|
| `IZWEK` | Uso de inversion (Investment measure = X) |
| `IPROJ` | Referencia al programa IM |
| `IPOSI` | Referencia a la posicion del programa |

### 4.3 Appropriation Request (AR)

La AR es el proceso previo a la medida. Permite evaluar y aprobar antes de ejecutar:

```
Ciclo de vida de una inversion:
1. AR creada (idea/solicitud)
2. AR aprobada → se convierte en medida
3. Medida crea WBS o Orden interna
4. Costes se acumulan en el WBS/OI
5. Costes se liquidan a AuC
6. AuC se capitaliza a activo definitivo
```

**Transaccion AR:** `IM01AR` — Crear Appropriation Request

---

## 5. Integracion IM-PS (Asignacion WBS)

### 5.1 Configuracion de la Integracion

**Ruta SPRO:**
```
Investment Management → Master Data →
  Investment Programs → Define Investment Program Types
→ Seleccionar tipo → Asignar "Measure Type": WBS
```

**Asignacion WBS a Posicion IM:**
```
IM52 → Crear medida
  → Seleccionar programa y ejercicio
  → Seleccionar posicion del programa
  → Tipo de medida: WBS Element
  → Seleccionar el WBS element existente
```

### 5.2 Flujo de Presupuesto IM → PS

```
PROGRAMA IM (IM32):
  Aprobar 5,000,000 EUR para Posicion 1.1 Edificios

        ↓ IM40 (Distribucion)

POSICION 1.1 → WBS INV-2024-001:
  Distribuir 3,000,000 EUR

        ↓ IM42 (Aprobacion medida)

WBS INV-2024-001 (PS):
  Presupuesto aprobado: 3,000,000 EUR (BPGE)
  → Control disponibilidad PS activo sobre este importe
```

### 5.3 Sincronizacion de Presupuesto IM-PS

**Regla importante:** Cuando se aprueba presupuesto en IM para una medida WBS, el presupuesto se transfiere automaticamente a PS (BPGE/BPJA).

**Verificar sincronizacion:**
```
IM40 → ver asignaciones y presupuesto
CJ31 → ver presupuesto en WBS
→ Deben coincidir (salvo reajustes directos en PS)
```

---

## 6. Control Presupuestario IM

### 6.1 Niveles de Control

El control de presupuesto IM opera en dos niveles:

**Nivel 1: Control en Posicion del Programa**
- El total de medidas asignadas no puede exceder el presupuesto de la posicion
- Gestionado por IM40 (distribucion)

**Nivel 2: Control en Medida (WBS/OI)**
- Los costes reales + compromisos no pueden exceder el presupuesto de la medida
- Gestionado por el control disponibilidad de PS (OPS9)

### 6.2 Presupuesto Anual vs Total en IM

| Tipo | Descripcion | Campo BPGE |
|------|-------------|------------|
| Overall budget | Presupuesto total del proyecto | WLGES |
| Annual budget | Presupuesto del ejercicio | BPJA.WLGES |
| Released budget | Presupuesto liberado (disponible) | WLIBFR |

**Configuracion:** En IM, el perfil de presupuesto determina si el control es anual o total.

### 6.3 Traspasos de Presupuesto IM

```
IM38 → Traspaso entre posiciones del mismo programa

Ejemplo:
  Posicion A (Maquinaria): 500,000 → 400,000 (-100,000)
  Posicion B (IT):          300,000 → 400,000 (+100,000)

Condicion: Total del programa no cambia
```

---

## 7. AuC — Asset under Construction

### 7.1 Que es un AuC

AuC (Asset under Construction) = Activo en Curso. Es un activo fijo de tipo especial que acumula todos los costes de un proyecto de inversion hasta que el proyecto se completa y el activo entra en servicio.

**Flujo contable:**
```
Ejecucion del proyecto:
  Costes en WBS (PROJ/PRPS) → Cuentas de explotacion

  Liquidacion periodica (CJ8G):
  Cuentas de explotacion → AuC (cuenta activo en curso)

  Al finalizar el proyecto (AIAB/AIBU):
  AuC → Activo definitivo (cuenta activo fijo)

  Desde puesta en servicio:
  Activo definitivo → Amortizacion periodica
```

### 7.2 Clases de Activo para AuC

**Configuracion:**
```
SPRO → Financial Accounting → Asset Accounting →
  Master Data → Asset Classes → Define Asset Classes
→ Crear clase de activo tipo AuC (campo: Asset under Const. = X)
```

**Clases AuC tipicas:**
| Clase | Descripcion | Activo definitivo |
|-------|-------------|-------------------|
| 4000 | AuC General | → Clase 1000 (Edificios) |
| 4001 | AuC Maquinaria | → Clase 2000 (Maquinaria) |
| 4002 | AuC IT | → Clase 3000 (Software) |
| 4003 | AuC Vehiculos | → Clase 2500 (Vehiculos) |

### 7.3 Crear AuC

```
Transaccion: AS01 → Crear activo fijo
  → Clase de activo: 4000 (AuC)
  → Descripcion: "AuC - Proyecto INV-2024-001"
  → Centro de coste (opcional)
  → No se introduce valor (se llena por liquidacion)
```

**Vincular AuC al WBS:**
```
CJ20N → WBS element → Detalles → Activos
  → Asignar numero AuC creado
O: En la regla de liquidacion del WBS:
  → Receptor tipo 'AN' (Fixed Asset)
  → Numero de activo: el AuC
```

---

## 8. Flujo AuC a Activo Definitivo

### 8.1 Proceso Completo

```
FASE 1: EJECUCION DEL PROYECTO
  Facturas de proveedores → WBS
  Nominas imputadas → WBS
  Materiales consumidos → WBS
  Costes de equipos propios → WBS

FASE 2: LIQUIDACION PERIODICA (Mensual)
  CJ8G → Liquidar WBS a AuC
  Contabilizacion: Dr. AuC / Cr. Cuentas explotacion
  El AuC acumula el valor

FASE 3: CIERRE TECNICO DEL PROYECTO
  CJ20N → Status TECO (Cierre tecnico)
  CJ8G → Liquidacion final (tipo FUL)
  Saldo WBS = 0 (todo liquidado a AuC)

FASE 4: CAPITALIZACION
  AIAB → Asignar AuC a activo definitivo
  AIBU → Ejecutar capitalizacion
  Contabilizacion: Dr. Activo definitivo / Cr. AuC

FASE 5: INICIO DE AMORTIZACION
  AFAB → La amortizacion comienza desde fecha de activacion
```

### 8.2 Transaccion AIAB — Asignacion de Activos

**Descripcion:** Asigna el saldo del AuC a uno o varios activos definitivos.

```
AIAB → Seleccionar AuC
  → Ver saldo actual del AuC (total de costes liquidados)
  → "Assign" → seleccionar activo definitivo destino
  → Indicar importe o % a asignar
  → Si multiple activos: distribuir el saldo entre ellos
  → Grabar la asignacion (no contabiliza aun)
```

**Ejemplo de asignacion:**
```
AuC 12345678 (AuC Planta): valor 1,500,000 EUR
  → Activo 23456789 (Estructura edificio):  1,000,000 EUR (67%)
  → Activo 34567890 (Instalaciones):          500,000 EUR (33%)
```

### 8.3 Transaccion AIBU — Capitalizacion

**Descripcion:** Ejecuta la capitalizacion del AuC al activo definitivo.

```
AIBU → Seleccionar AuC con asignacion realizada
  → Verificar la asignacion previa (AIAB)
  → "Execute" → ejecutar la capitalizacion
  → Contabilizacion:
      Dr. Activo definitivo (clase 1000, 2000, etc.)
      Cr. AuC (clase 4000)
  → El AuC queda con saldo 0 (parcial o total)
```

**Parametros importantes:**
| Parametro | Descripcion |
|-----------|-------------|
| Transfer date | Fecha de capitalizacion (inicio amortizacion) |
| Asset value date | Fecha de activacion del activo |
| Document date | Fecha del documento contable |

### 8.4 Configuracion de Cuentas AuC

**Ruta SPRO:**
```
Financial Accounting → Asset Accounting →
  Integration with the General Ledger →
  Define How Depreciation Areas Post to General Ledger

Accounts (AO90):
  - AuC account (account class 4000): cuenta activo en curso
  - Clearing account: cuenta transitoria liquidacion
  - Transfer account: cuenta traspaso a activo
```

**Cuentas tipicas:**
| Cuenta | Descripcion |
|--------|-------------|
| 132000 | Activo en Curso (AuC) |
| 132001 | AuC - Maquinaria |
| 132002 | AuC - IT |
| 190000 | Transitoria de capitalizacion |

---

## 9. Capitalizacion y Cuentas

### 9.1 Documentacion Contable

**Contabilizacion de liquidacion WBS → AuC (mensual):**
```
Periodo: cada mes durante el proyecto

  Dr. 132000 (AuC)            1,250,000
    Cr. 470000 (Liquidacion)             1,250,000

Y simultaneamente:
  Dr. 470000 (Liquidacion)    1,250,000
    Cr. 415000 (Costes proyecto)         1,250,000
```

**Contabilizacion de capitalizacion AuC → Activo (al cierre):**
```
Al finalizar el proyecto (AIBU):

  Dr. 130000 (Edificios/Maquinaria)  1,500,000
    Cr. 132000 (AuC)                           1,500,000
```

### 9.2 Amortizacion del Activo

Una vez capitalizado, el activo comienza a amortizarse:
```
AFAB → Ejecucion de amortizacion periodica (mensual)

  Dr. 681000 (Amortizacion del periodo)
    Cr. 130090 (Amortizacion acumulada Edificios)

Duracion: segun clase de activo y metodo de amortizacion
  - Edificios: 50 anos (2% anual)
  - Maquinaria industrial: 10 anos (10% anual)
  - IT / Software: 3-5 anos
  - Vehiculos: 5 anos
```

### 9.3 Indicadores de Amortizacion en Clase de Activo

```
SPRO → Asset Accounting → Asset Classes → Define Asset Classes
  → Pestaña "Depreciation"
  → Depreciation key: por tipo y metodo (LINEA, DIGITOS, etc.)
  → Useful life: vida util en anos
  → Scrap value: valor residual
```

---

## 10. Tablas IM Principales

### 10.1 IMPR — Programa de Inversiones (Cabecera)

| Campo | Descripcion |
|-------|-------------|
| `PRNAM` | Nombre del programa de inversiones |
| `STUFE` | Nivel jerarquico |
| `GJAHR` | Ejercicio |
| `BUKRS` | Sociedad |
| `PRART` | Tipo de programa |
| `PRTXT` | Descripcion del programa |

### 10.2 IMZO — Posiciones del Programa

| Campo | Descripcion |
|-------|-------------|
| `PRNAM` | Nombre del programa |
| `POSNR` | Numero de posicion |
| `GJAHRV` | Ejercicio de validez |
| `STUFE` | Nivel de la posicion |
| `UP` | Posicion padre |
| `POSIT` | Tipo de posicion |
| `TXT20` | Descripcion corta |

### 10.3 IMZOE — Medidas por Posicion

| Campo | Descripcion |
|-------|-------------|
| `PRNAM` | Nombre del programa |
| `POSNR` | Posicion del programa |
| `GJAHR` | Ejercicio |
| `KONTY` | Tipo de medida (WBS='PSP', Orden='OR') |
| `OBJNR` | Numero de objeto de la medida |
| `PSPNR` | Numero interno WBS (si medida es WBS) |
| `AUFNR` | Numero de orden (si medida es OI) |

### 10.4 IMBUDGET — Presupuesto IM

| Campo | Descripcion |
|-------|-------------|
| `PRNAM` | Programa |
| `POSNR` | Posicion |
| `GJAHR` | Ejercicio |
| `VORGA` | Clase de presupuesto (KOBU, KONS) |
| `WLGES` | Importe total |
| `WLIBFR` | Importe liberado |
| `WTWAER` | Moneda |

### 10.5 Relacion entre Tablas

```
IMPR (programa)
  └── IMZO (posiciones del programa)
        └── IMZOE (medidas asignadas)
              └── PRPS.PSPNR (WBS element de la medida)
                    └── BPGE (presupuesto PS)
                    └── ACDOCA (costes reales PS)
                    └── ANLB (AuC asignado)
```

---

## 11. Configuracion SPRO

### 11.1 Definicion del Tipo de Programa

**Ruta SPRO:**
```
Investment Management → Master Data → Investment Programs →
  Define Investment Program Types
```

**Parametros:**
| Parametro | Descripcion |
|-----------|-------------|
| Program type | Codigo del tipo de programa |
| Description | Descripcion |
| Default measure type | WBS o Orden interna |
| Budget profile | Perfil de presupuesto IM |
| Status schema | Perfil de status del programa |

### 11.2 Perfil de Presupuesto IM

**Ruta SPRO:**
```
Investment Management → Budget →
  Define Budget Profile for Investment Programs
```

**Diferencias con perfil PS:**
- IM puede controlar presupuesto a nivel de posicion del programa
- PS controla a nivel de WBS individual
- El perfil IM puede referenciar al perfil PS de las medidas

### 11.3 Customizing de Liquidacion IM-PS

**Ruta SPRO:**
```
Investment Management → Appropriation Requests →
  Define Settlement Profile for Appropriation Request
```

**Y:**
```
Investment Management → Master Data →
  Define Depreciation Simulation
→ Para proyecciones de amortizacion antes de capitalizar
```

### 11.4 Clases de Activo para AuC

**Ruta SPRO:**
```
Financial Accounting → Asset Accounting →
  Master Data → Asset Classes → Define Asset Classes
→ Campo "Asset under Construction": activar
→ Asset class: 4000 (o Z_AUC)
```

---

## 12. Consultas y Reporting IM

### 12.1 Report Principal S_ALR_87013558

**Descripcion:** Plan/Presupuesto/Real por programa de inversiones.

```
Seleccion:
  Programa:    INV-2024
  Ejercicio:   2024
  Periodo:     001-012
  Moneda:      EUR

Resultado:
  Por posicion del programa:
    - Plan         = plan de costes
    - Budget       = presupuesto aprobado
    - Actual       = costes reales
    - Commitment   = compromisos abiertos
    - Available    = budget - actual - commitment
```

### 12.2 Query: Presupuesto vs Real por Posicion IM

```sql
-- Presupuesto y consumo por posicion del programa IM
SELECT
    imzo.PRNAM                  AS Programa,
    imzo.POSNR                  AS Posicion,
    imzo.TXT20                  AS Descripcion,
    imbudg.WLGES                AS Presupuesto_Total,
    imbudg.WLIBFR               AS Presupuesto_Liberado,
    COALESCE(costes.Real, 0)    AS Costes_Reales,
    imbudg.WLIBFR
        - COALESCE(costes.Real, 0) AS Disponible_IM
FROM IMZO
JOIN IMPR ON IMZO.PRNAM = IMPR.PRNAM
LEFT JOIN IMBUDGET AS imbudg
    ON IMZO.PRNAM = imbudg.PRNAM
    AND IMZO.POSNR = imbudg.POSNR
    AND imbudg.GJAHR = '2024'
    AND imbudg.VORGA = 'KOBU'
LEFT JOIN (
    -- Costes reales de todas las medidas de la posicion
    SELECT imzoe.PRNAM, imzoe.POSNR, SUM(acd.HSL) AS Real
    FROM IMZOE
    JOIN PRPS ON IMZOE.PSPNR = PRPS.PSPNR
    JOIN ACDOCA AS acd ON PRPS.PSPNR = acd.PSPNR
    WHERE acd.GJAHR = '2024' AND acd.PSPNR <> ''
    GROUP BY imzoe.PRNAM, imzoe.POSNR
) AS costes ON IMZO.PRNAM = costes.PRNAM
          AND IMZO.POSNR = costes.POSNR
WHERE IMZO.PRNAM = 'INV-2024'
ORDER BY IMZO.POSNR
```

### 12.3 Query: Medidas por Posicion IM

```sql
-- Todas las medidas (WBS) asignadas a un programa IM
SELECT
    imzoe.PRNAM,
    imzoe.POSNR,
    imzo.TXT20                  AS PosicionDesc,
    prps.POSID                  AS WBSElement,
    prps.POST1                  AS WBSDesc,
    bpge.WLIBFR                 AS Presupuesto_WBS,
    COALESCE(real.CostesReales, 0) AS Costes_Reales,
    tj02t.TXT04                 AS StatusActual
FROM IMZOE
JOIN IMZO ON IMZOE.PRNAM = IMZO.PRNAM AND IMZOE.POSNR = IMZO.POSNR
JOIN PRPS ON IMZOE.PSPNR = PRPS.PSPNR
LEFT JOIN BPGE ON PRPS.OBJNR = BPGE.OBJNR AND BPGE.VORGA = 'KOBU'
LEFT JOIN (
    SELECT PSPNR, SUM(HSL) AS CostesReales
    FROM ACDOCA WHERE GJAHR = '2024' AND PSPNR <> ''
    GROUP BY PSPNR
) AS real ON PRPS.PSPNR = real.PSPNR
LEFT JOIN JEST ON PRPS.OBJNR = JEST.OBJNR
    AND JEST.STAT = 'E0002'  -- Solo status REL
    AND JEST.INACT = ''
LEFT JOIN TJ02T ON JEST.STAT = TJ02T.ISTAT AND TJ02T.SPRAS = 'S'
WHERE IMZOE.PRNAM = 'INV-2024'
    AND IMZOE.GJAHR = '2024'
    AND IMZOE.KONTY = 'PSP'   -- Solo medidas tipo WBS
ORDER BY IMZO.POSNR, PRPS.POSID
```

### 12.4 Query: Estado de AuC por Proyecto

```sql
-- Saldo del AuC y relacion con el proyecto PS
SELECT
    proj.PSPID                  AS Proyecto,
    prps.POSID                  AS WBS,
    anlb.ANLKL                  AS ClaseActivo,
    anla.ANLNR                  AS NumeroAuC,
    anla.TXT50                  AS DescripcionAuC,
    anla.AKTIV                  AS FechaActivacion,
    COALESCE(auc_val.ValorAuC, 0) AS ValorAcumuladoAuC,
    COALESCE(wbs_cost.CostesWBS, 0) AS CostesEnWBS,
    CASE
        WHEN anla.AKTIV > '00000000' THEN 'CAPITALIZADO'
        WHEN COALESCE(auc_val.ValorAuC, 0) > 0 THEN 'EN CURSO'
        ELSE 'VACIO'
    END AS EstadoAuC
FROM PROJ
JOIN PRPS ON PRPS.PSPHI = PROJ.PSPNR
JOIN ANLB ON PRPS.OBJNR = ANLB.OBJNR   " WBS → AuC assignment
JOIN ANLA ON ANLB.ANLNR = ANLA.ANLNR
LEFT JOIN (
    SELECT ANLNR, SUM(NWBTR) AS ValorAuC
    FROM ANLC WHERE GJAHR = '2024'
    GROUP BY ANLNR
) AS auc_val ON ANLA.ANLNR = auc_val.ANLNR
LEFT JOIN (
    SELECT PSPNR, SUM(HSL) AS CostesWBS
    FROM ACDOCA WHERE PSPNR <> '' AND GJAHR = '2024'
    GROUP BY PSPNR
) AS wbs_cost ON PRPS.PSPNR = wbs_cost.PSPNR
WHERE PROJ.PSPID LIKE 'INV-2024%'
ORDER BY PROJ.PSPID, PRPS.POSID
```

---

## Resumen: Flujo Completo IM-PS-AuC-Activo

```
1. PROGRAMA IM (IM01/IM02)
   - Crear estructura jerarquica de inversiones
   - Aprobar presupuesto global (IM32)

2. POSICIONES DEL PROGRAMA (IM11/IM12)
   - Definir categorias de inversion
   - Distribuir presupuesto (IM40)

3. PROYECTO PS (CJ01/CJ20N)
   - Crear proyecto con WBS
   - Asignar como medida IM (IM52)
   - Presupuesto transferido automaticamente

4. EJECUCION (Facturas, nominas, materiales)
   - Costes se acumulan en WBS
   - Control disponibilidad PS activo

5. LIQUIDACION PERIODICA (CJ8G - mensual)
   - WBS → AuC (activo en curso)
   - Cuentas de explotacion se cierran

6. CIERRE PROYECTO
   - TECO → CJ8G final (FUL)
   - WBS saldo = 0

7. CAPITALIZACION (AIAB + AIBU)
   - Asignar AuC a activo definitivo
   - Ejecutar capitalizacion

8. AMORTIZACION (AFAB)
   - Activo definitivo inicia depreciacion
```

---

*Referencia: SAP S/4HANA 2023 | Investment Management Guide*
*Tablas: IMPR, IMZO, IMZOE, BPGE, ANLB, ANLA, ANLC*
*Transacciones clave: IM01-IM52, AIAB, AIBU, AFAB, CJ30-CJ8G*
