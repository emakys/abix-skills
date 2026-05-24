# Garantias y Claims — SAP PM S/4HANA 2023

## 1. Concepto de Garantias en SAP PM

La gestión de garantías en SAP Plant Maintenance permite controlar los periodos durante los cuales los fabricantes, proveedores o contratos de servicio cubren los costes de reparación o sustitución de equipos y componentes. Una correcta gestión de garantías evita pagar costes que corresponden a terceros y facilita la recuperación de esos importes.

### Tipos de Garantía

| Tipo | Descripción | Gestión en SAP |
|---|---|---|
| Garantía de fabricante | Cubre defectos de fabricación del equipo | En maestro de equipo |
| Garantía de proveedor | Cubre la pieza o componente adquirido | En maestro de material/equipo |
| Garantía de cliente | Garantía que la empresa otorga a sus clientes | En PM-CS (Service) |
| Garantía de mantenimiento | Cubre trabajos realizados por empresa propia | Contrato de servicio |
| Garantía de componente | Garantía de pieza reparada/reacondicionada | Número de serie |

---

## 2. Configuracion de Garantias

### 2.1 Tipos de Garantia (Customizing)

**Ruta SPRO:**
```
Mantenimiento de planta y servicio al cliente
  → Datos maestros de objetos técnicos
    → Garantías
      → Definir tipos de garantía
```

**Transacción:** BGM0 (Mantenimiento de tipos de garantía)

Campos clave del tipo de garantía:
- **Clave de garantía**: Identificador (ej: MFGR, VEND, INT)
- **Descripción**: Texto descriptivo
- **Tipo counter**: Días, meses, horas de operación, ciclos
- **Inicio garantía**: Fecha compra, fecha instalación, fecha puesta en servicio

### 2.2 Contadores de Garantia

Los contadores determinan cuándo expira la garantía:

| Tipo Counter | Descripción | Ejemplo |
|---|---|---|
| Fecha | Basado en fecha inicio + duración | 24 meses desde instalación |
| Horas | Basado en horas de operación | 4000 horas de funcionamiento |
| Ciclos | Basado en contador de uso | 10000 ciclos de arranque |

### 2.3 Perfil de Garantia

Un perfil de garantía agrupa condiciones estándar:

```
SPRO → PM → Datos maestros
  → Garantías → Definir perfiles de garantía
```

- Permite crear garantías predefinidas para asignar masivamente a equipos del mismo tipo
- Reduce el trabajo de mantenimiento de datos maestros

---

## 3. Maestro de Garantia (BGM1/BGM2/BGM3)

### BGM1 — Crear Garantia

```
Transacción: BGM1
  → Tipo de garantía: [ej: MFGR]
  → Objeto: [equipo o numero serie]
  → Datos temporales:
    - Inicio garantía: [fecha]
    - Duración: [meses/días]
    - Fin garantía: [calculado automáticamente]
  → Fabricante/Proveedor: [proveedor SAP]
  → Condiciones cubiertas:
    - Mano de obra: Sí/No, % cubierto
    - Materiales: Sí/No, % cubierto
    - Transportes: Sí/No
  → Límite máximo cubierto: [importe]
  → Contrato referencia: [número contrato proveedor]
```

### BGM2 — Modificar Garantia

```
Transacción: BGM2
  → Seleccionar garantía existente
  → Modificar fechas, condiciones, importes
  → Registrar extensiones de garantía
```

### BGM3 — Visualizar Garantia

```
Transacción: BGM3
  → Vista de sólo lectura de la garantía
  → Ver historial de claims realizados
  → Ver estado (vigente/expirada)
```

### Tabla BGMK — Cabecera de Garantia

| Campo | Descripción |
|---|---|
| BGMK_GUID | GUID de garantía (clave primaria S/4) |
| BGMK_NR | Número de garantía |
| BGMK_ART | Tipo de garantía |
| BGMK_STAT | Estado (activa/expirada/cancelada) |
| BGMK_DATUM_VON | Fecha inicio |
| BGMK_DATUM_BIS | Fecha fin |
| LIFNR | Proveedor/fabricante |
| MATNR | Material cubierto |
| EQUNR | Número de equipo |
| SERNR | Número de serie |

```sql
-- GetSqlQuery: Garantías activas por equipo
SELECT BGMK_NR, BGMK_ART, BGMK_DATUM_VON, BGMK_DATUM_BIS,
       LIFNR, EQUNR, SERNR, BGMK_STAT
FROM BGMK
WHERE EQUNR = '[EQUIPO]'
  AND BGMK_STAT = '01'  -- Activa
  AND BGMK_DATUM_BIS >= CURRENT_DATE
ORDER BY BGMK_DATUM_BIS
```

### Tabla BGMP — Posiciones de Garantia

| Campo | Descripción |
|---|---|
| BGMK_GUID | GUID cabecera garantía |
| BGMP_POS | Número de posición |
| BGMP_ART | Tipo de cobertura (mano obra, material, etc.) |
| BGMP_PROZ | Porcentaje cubierto |
| BGMP_BETR | Importe máximo cubierto |
| BGMP_WAERS | Moneda |

```sql
-- GetSqlQuery: Condiciones de cobertura por garantía
SELECT T1.BGMK_NR, T1.BGMK_ART, T2.BGMP_POS,
       T2.BGMP_ART, T2.BGMP_PROZ, T2.BGMP_BETR, T2.BGMP_WAERS
FROM BGMK T1
INNER JOIN BGMP T2 ON T1.BGMK_GUID = T2.BGMK_GUID
WHERE T1.BGMK_DATUM_BIS >= CURRENT_DATE
ORDER BY T1.BGMK_NR, T2.BGMP_POS
```

---

## 4. Garantias en Equipos y Componentes

### 4.1 Asignacion de Garantia al Equipo

En el maestro de equipo (IE02), pestaña **Garantía**:

```
IE02 → Equipo → Pestaña "Garantía"
  → Garantía del fabricante: [número garantía]
  → Garantía del vendedor: [número garantía]
  → Verificar solapamientos de fechas
```

**Campos en EQUI relacionados con garantía:**

| Campo EQUI | Descripción |
|---|---|
| GWLDT | Fecha fin de garantía |
| GUDID | GUID de garantía asignada |

```sql
-- GetSqlQuery: Equipos con garantía próxima a expirar (90 días)
SELECT T1.EQUNR, T1.EQKTX, T1.GWLDT, T1.MATNR, T1.SERNR,
       T2.BGMK_ART, T2.LIFNR
FROM EQUI T1
LEFT JOIN BGMK T2 ON T1.EQUNR = T2.EQUNR
WHERE T1.GWLDT BETWEEN CURRENT_DATE AND ADD_DAYS(CURRENT_DATE, 90)
  AND T1.EQASP = ' '  -- No borrado
ORDER BY T1.GWLDT ASC
```

### 4.2 Garantia en Numeros de Serie

Para componentes reparables con número de serie, la garantía se vincula al historial de ese número específico:

```
IQ02 → Número de serie → Datos garantía
  → Inicio garantía: [fecha instalación o reparación]
  → Tipo garantía: [fabricante/reparación]
```

---

## 5. Integracion con Avisos PM

### Verificacion Automatica de Garantia

Al crear un aviso PM (IW21), el sistema verifica automáticamente si el equipo está en garantía:

1. Sistema comprueba fecha actual vs. período de garantía del equipo (EQUI.GWLDT)
2. Si está en garantía: aparece **mensaje de advertencia** o **bloqueo** según config
3. Datos de garantía se muestran en la cabecera del aviso

**Configuración del warning de garantía:**

```
SPRO → PM → Gestión de avisos
  → Verificación de garantía en aviso
  → Definir mensaje (warning W / error E)
```

### Campos de Garantia en Aviso (QMEL)

| Campo | Descripción |
|---|---|
| GWLDT | Fecha fin garantía (heredado del equipo) |
| BGMK_NR | Número de garantía referenciada |
| GARNT | Indicador de garantía activa |

---

## 6. Claim Management — Proceso de Reclamacion

### 6.1 Concepto de Claim

Un **claim** (reclamación de garantía) es el proceso formal de solicitar al fabricante o proveedor el reembolso de costes cubiertos por garantía. SAP PM facilita el seguimiento de estos claims vinculándolos a las órdenes de mantenimiento.

### 6.2 Flujo del Proceso de Claim

```
[Aviso PM detecta equipo en garantía]
          ↓
[Se crea Orden PM con referencia a garantía]
          ↓
[Técnico realiza reparación, registra costes]
          ↓
[Se identifica porción cubierta por garantía]
          ↓
[Se crea documento de claim (reclamación)]
          ↓
[Se envía reclamación al proveedor/fabricante]
          ↓
[Proveedor acepta/rechaza parcial o total]
          ↓
[Se registra crédito en FI (nota de abono)]
          ↓
[Liquidación final: costes netos a centro coste]
```

### 6.3 Registro de Claim en la Orden

En la orden de mantenimiento (IW32):

```
IW32 → Cabecera → Garantía
  → Número de garantía: [BGMKxx]
  → Estado de claim: En preparación / Enviado / Aceptado / Rechazado
  → Importe reclamado: [calculado desde costes reales]
  → Importe aceptado: [confirmado por proveedor]
  → Referencia documento proveedor: [número carta/factura crédito]
```

### 6.4 Determinacion de Costes Cubiertos

**Ejemplo de cálculo:**

```
Costes totales de reparación:
  - Mano de obra:    500 EUR
  - Materiales:     1200 EUR
  - Servicios ext.:  300 EUR
  Total:            2000 EUR

Cobertura de garantía (según BGMP):
  - Mano de obra:   100% → 500 EUR cubiertos
  - Materiales:      80% → 960 EUR cubiertos
  - Servicios:        0% → 0 EUR cubiertos
  Total cubierto:         1460 EUR

Costes a imputar a empresa:   540 EUR
```

---

## 7. Seguimiento y Recuperacion de Costes

### 7.1 Proceso Contable de Recuperacion

Cuando el proveedor acepta el claim y emite nota de abono:

**Opción A: Nota de abono en MM (MIRO)**
```
MIRO → Nota de abono
  → Proveedor: [fabricante]
  → Referencia: número claim
  → Importes negativos (reducen deuda o generan crédito)
```

**Opción B: Documento FI manual (FB65)**
```
FB65 → Nota de abono a proveedor
  → Cuenta de recuperación garantías (imputación especial)
  → Centro de coste o cuenta de resultado
```

### 7.2 Cuentas Contables Recomendadas

| Concepto | Cuenta Sugerida | Descripción |
|---|---|---|
| Provisión claims pendientes | 4xxx | Costes reclamados, pendientes confirmación |
| Ingresos recuperación garantías | 7xxx | Abono del proveedor por garantía |
| Diferencia no cubierta | 4xxx | Coste neto asumido por la empresa |

### 7.3 Informes de Seguimiento

**Transacción IW39** — Lista de órdenes:
- Filtrar por: Garantía = Activa
- Ver costes reales acumulados en órdenes con garantía

**Reporte personalizado (query ABAP/CDS):**

```sql
-- GetSqlQuery: Claims pendientes de recuperación
SELECT T1.AUFNR, T1.AUART, T1.ERDAT, T2.BGMK_NR, T2.BGMK_ART,
       T3.LIFNR, T4.NAME1 AS PROVEEDOR,
       T5.WKGBTR AS COSTE_REAL
FROM AUFK T1
INNER JOIN AUFKWI T2 ON T1.AUFNR = T2.AUFNR  -- Garantía en orden
INNER JOIN BGMK T3 ON T2.BGMK_NR = T3.BGMK_NR
INNER JOIN LFA1 T4 ON T3.LIFNR = T4.LIFNR
INNER JOIN COSS T5 ON T1.AUFNR = T5.AUFNR
WHERE T2.GARNT_STAT = '02'  -- Claim enviado, pendiente respuesta
ORDER BY T5.WKGBTR DESC
```

---

## 8. Garantia en Contratos de Servicio

### Contratos Marco de Garantia

Cuando la garantía viene de un contrato con un proveedor de servicio:

```
Transacción: ME31K (Crear contrato)
  → Tipo contrato: WK (contrato de valor)
  → Condición de garantía: ZG01 (tipo condición personalizada)
  → Validez: Fechas del contrato
```

Vincular contrato a equipos:
```
IE02 → Equipo → Datos del contrato
  → Número de contrato: [ME31K]
  → Posición del contrato
```

### Service Level Agreements (SLA)

Los SLA se pueden modelar como:
- **Categorías de mantenimiento** con tiempo de respuesta definido
- **Prioridades de aviso** con escalado automático
- **Perfil de horizonte de mantenimiento** en planes preventivos

---

## 9. Fiori Apps para Garantias

| App | ID Fiori | Descripción |
|---|---|---|
| Gestionar garantías | F2605 | Crear, modificar, visualizar garantías |
| Monitor de garantías | F2606 | Vista general, garantías por expirar |
| Claims de garantía | F2607 | Seguimiento de reclamaciones activas |
| Equipos en garantía | F3847 | Lista equipos con garantía vigente |

### Configuracion Fiori para Garantias

```
Launchpad Designer → Grupo: Mantenimiento
  → Agregar tiles: F2605, F2606, F2607
  → Roles: SAP_EAM_WRK (Trabajador mantenimiento)
            SAP_EAM_PLN (Planificador)
```

---

## 10. Consultas MCP para Gestion de Garantias

### Equipos sin Garantia Asignada

```sql
-- GetSqlQuery: Equipos nuevos sin garantía (últimos 6 meses)
SELECT EQUNR, EQKTX, MATNR, HERST, HERLD, INBDT
FROM EQUI
WHERE INBDT >= ADD_MONTHS(CURRENT_DATE, -6)
  AND GWLDT IS NULL
  AND EQASP = ' '
ORDER BY INBDT DESC
```

### Garantias Expiradas con Costes Posteriores

```sql
-- GetSqlQuery: Detectar trabajos post-garantía que debían ser cubiertos
SELECT T1.AUFNR, T1.AUART, T1.ERDAT,
       T2.EQUNR, T2.GWLDT,
       T3.WKGBTR AS COSTE_REAL
FROM AUFK T1
INNER JOIN AUFK_EQUI T2 ON T1.AUFNR = T2.AUFNR
INNER JOIN EQUI T2B ON T2.EQUNR = T2B.EQUNR
INNER JOIN COSS T3 ON T1.AUFNR = T3.AUFNR
WHERE T2B.GWLDT < T1.ERDAT
  AND T2B.GWLDT >= ADD_MONTHS(T1.ERDAT, -3)
  AND T3.WKGBTR > 0
ORDER BY T3.WKGBTR DESC
```

### Resumen de Claims por Proveedor

```sql
-- GetSqlQuery: Claims agrupados por fabricante/proveedor
SELECT T3.LIFNR, T4.NAME1,
       COUNT(T1.AUFNR) AS NUM_CLAIMS,
       SUM(T5.WKGBTR) AS COSTE_RECLAMADO
FROM AUFK T1
INNER JOIN AUFKWI T2 ON T1.AUFNR = T2.AUFNR
INNER JOIN BGMK T3 ON T2.BGMK_NR = T3.BGMK_NR
INNER JOIN LFA1 T4 ON T3.LIFNR = T4.LIFNR
INNER JOIN COSS T5 ON T1.AUFNR = T5.AUFNR
WHERE T1.GJAHR = '[ANIO]'
GROUP BY T3.LIFNR, T4.NAME1
ORDER BY COSTE_RECLAMADO DESC
```

---

## 11. Buenas Practicas

1. **Registrar garantía en el momento de la compra/instalación** — No esperar a necesitarla
2. **Usar números de serie** para rastrear garantías a nivel de unidad individual
3. **Definir un responsable** de claims en cada área de mantenimiento
4. **Revisar mensualmente** la lista de garantías próximas a vencer (IW39 + filtro GWLDT)
5. **Documentar claims con evidencias**: fotos, informes de defecto, comunicaciones con proveedor
6. **Integrar con Compras (MM)**: coordinar con el comprador que gestiona la relación con el proveedor
7. **Provisionar claims en FI**: mientras el claim está pendiente, provisionar el importe esperado

---

## 12. Errores y Problemas Frecuentes

| Problema | Causa | Solución |
|---|---|---|
| Garantía no aparece en aviso | GWLDT no actualizado en EQUI | Actualizar IE02 con fecha garantía |
| No se puede crear claim | Tipo garantía sin perfil claim | Configurar en SPRO tipos garantía |
| Claim sin contabilización | Cuenta recuperación no determinada | Revisar configuración cuentas FI |
| Garantía asignada al modelo, no a la unidad | Uso incorrecto: serie vs. equipo | Asignar garantía por SERNR, no solo MATNR |
| Duplicidad de garantías | Garantía fabricante + proveedor ambas activas | Revisar solapamiento en BGM3 |
