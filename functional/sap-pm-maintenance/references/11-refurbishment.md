# Reacondicionamiento (Refurbishment) — SAP PM S/4HANA 2023

## 1. Concepto y Alcance

El **Reacondicionamiento** (Refurbishment) es el proceso mediante el cual un componente o pieza de repuesto defectuosa o desgastada se repara y devuelve al stock como pieza reutilizable. Es una funcionalidad clave en SAP Plant Maintenance para optimizar el coste de mantenimiento y gestionar el ciclo de vida de componentes costosos (motores, bombas, válvulas, transmisiones, tarjetas electrónicas, etc.).

### Principios Fundamentales

- El componente **no se desecha**: se devuelve del equipo/ubicación al almacén en estado "a reparar"
- Se abre una **Orden PM04** (tipo estándar de reacondicionamiento)
- El componente se repara, consume materiales y mano de obra
- Al finalizar, reingresa al stock como componente **reparado y valorado**
- Permite rastrear el historial de reparaciones por número de serie

### Diferencias con Mantenimiento Correctivo Normal

| Aspecto | Correctivo (PM01) | Reacondicionamiento (PM04) |
|---|---|---|
| Objeto | Equipo en planta | Componente reutilizable |
| Stock | No afecta stock | Mueve materiales en stock |
| Valoración | Costes a centro coste | Recarga coste al material |
| Serialización | Opcional | Obligatoria (recomendada) |
| Resultado | Equipo reparado in-situ | Pieza reparada vuelve a stock |

---

## 2. Requisitos Previos de Customizing

### 2.1 Tipo de Orden PM04

**Ruta SPRO:**
```
Mantenimiento de planta y servicio al cliente
  → Gestión de órdenes de mantenimiento y servicio
    → Funciones y configuración de órdenes
      → Definir tipos de órdenes
```

El tipo de orden **PM04** debe tener configurado:
- Categoría de orden: **30** (Reacondicionamiento)
- Perfil de liquidación: con regla para **MAT** (material)
- Control de confirmación activo
- Gestión de componentes activa

### 2.2 Perfil de Liquidación para Reacondicionamiento

```
SPRO → PM → Gestión de órdenes → Liquidación
  → Definir perfiles de liquidación
```

El perfil debe permitir:
- Receptor: **MAT** (Número de material)
- Porcentaje: 100%
- Tipo de liquidación: Periódica o Total

### 2.3 Material Reparable

El material debe estar configurado con:
- Tipo de valoración: **S** (precio estándar) o **V** (precio medio variable)
- Tipo de material: **ERSA** (repuestos) o **ROH**
- Gestión por lotes y/o números de serie activada

**Ruta SPRO para valoración:**
```
Gestión de materiales → Valoración e imputación de cuentas
  → Determinación de cuentas → Definir gestión de clases de valoración
```

### 2.4 Clases de Valoración

| Clase Val. | Descripción | Uso Reacond. |
|---|---|---|
| 3000 | Materias primas | No |
| 3040 | Repuestos | Sí (defectuosos) |
| 7900 | Componentes reparables | Sí (recomendado) |
| 7920 | Componentes reparados | Sí (estado reparado) |

---

## 3. Flujo Completo de Reacondicionamiento

### Paso 1: Desmontaje del Componente Defectuoso

**Transacción:** IW31 (Crear orden mantenimiento) o IW41 (Confirmación)

Si el componente está instalado en un equipo, se desmonta mediante:
- Movimiento **601** en la confirmación de la orden de mantenimiento correctivo
- O desmontaje manual vía **IE4N** (Instalación/desmontaje de equipos)

### Paso 2: Devolución al Almacén (Stock Reparable)

**Movimiento de Mercancías:** **653** — Devolución de componente defectuoso a stock

```
Transacción: MIGO
  → Entrada de mercancías → Otros
  → Tipo movimiento: 653
  → Material: [número material reparable]
  → Almacén: [almacén de reparables]
  → Número de serie: [obligatorio si serializado]
```

El material queda en stock con estado de valoración "defectuoso" o en un **tipo de stock especial**.

### Paso 3: Creación de Orden de Reacondicionamiento (PM04)

**Transacción:** IW81 (Crear orden de reacondicionamiento) o IW31 con tipo PM04

```
IW81:
  → Tipo de orden: PM04
  → Material a reacondicionar: [número material]
  → Cantidad: [unidades a reparar]
  → Centro: [centro logístico]
  → Almacén: [donde está el material defectuoso]
  → Número de serie: [si aplica]
```

#### Componentes de la Orden PM04

La orden incluye automáticamente:
1. **Posición de devolución**: Material defectuoso sale del stock (movimiento 261 modificado)
2. **Posiciones de componentes**: Repuestos necesarios para reparar
3. **Posición de entrada**: Material reparado entra al stock al cierre

### Paso 4: Planificación de Trabajos

En la orden PM04, planificar:

**Operaciones:**
- Diagnóstico y desarmado
- Limpieza industrial
- Sustitución de componentes internos
- Ensamblaje
- Pruebas y verificación

**Materiales (Componentes):**
- Sellos, rodamientos, juntas
- Piezas de desgaste internas
- Fluidos y lubricantes

**Servicios Externos:**
- Si parte de la reparación es subcontratada

### Paso 5: Liberación y Ejecución

```
IW32 → Seleccionar orden → Funciones → Liberar (CTRL+F1)
```

Durante la ejecución:
- Confirmar operaciones: **IW41** o **IW42**
- Registrar consumos de material: **MIGO** o desde la propia orden

### Paso 6: Entrada de Mercancías del Componente Reparado

Al completar la reparación, se realiza la **entrada de mercancías del componente reparado**:

**Movimiento:** **101** con referencia a la orden PM04

```
MIGO:
  → Entrada de mercancías → Orden
  → Orden PM04: [número de orden]
  → Tipo movimiento: 101 (automático desde orden)
  → El sistema propone cantidad y valoración
```

**O desde la propia orden:**
```
IW32 → Componentes → Entrada de mercancías final
```

El material reparado entra al stock **libre** con nuevo valor calculado.

### Paso 7: Liquidación de la Orden

Los costes de reparación se liquidan **al material** (no a un centro de coste):

```
KO88 (Liquidar orden individual) o
CO88 (Liquidar órdenes colectivas)
```

La liquidación actualiza el **precio estándar** o el **precio medio variable** del material según la clase de valoración configurada.

---

## 4. Movimientos de Mercancías en Detalle

### Tabla de Movimientos de Reacondicionamiento

| Mvto | Descripción | Dirección | Stock Afectado |
|---|---|---|---|
| 653 | Devolución componente defectuoso | Producción/Planta → Almacén | Aumenta stock defectuoso |
| 261 | Salida componente para reparación (orden) | Almacén → Orden | Reduce stock libre/defectuoso |
| 531 | Entrada subproducto reparado | Orden → Almacén | Aumenta stock libre |
| 101 | Entrada mercancías de orden | Orden → Almacén | Aumenta stock reparado |
| 102 | Anulación entrada mercancías | Almacén → Orden | Reversión |
| 262 | Devolución componente a almacén | Orden → Almacén | Devuelve no consumido |

### Tipos de Stock Especiales

| Tipo Stock | Código | Descripción |
|---|---|---|
| Libre utilización | - | Stock disponible para uso |
| En control de calidad | Q | Pendiente inspección |
| Bloqueado | S | No disponible |
| En almacén de defectuosos | Almacén específico | Defectuosos pendientes reparar |

---

## 5. Serialización en Reacondicionamiento

### Configuración de Número de Serie

**Ruta SPRO:**
```
Logística general → Numeración de serie
  → Definir perfil de numeración de serie
  → Asignar perfil a tipo de material
```

**Perfil de serialización para Refurbishment:**
- Obligatorio en movimientos de material
- Obligatorio en confirmaciones PM
- Obligatorio en instalación/desmontaje de equipos

### Registro del Número de Serie

```
Transacción: IQ01 (Crear número de serie)
  → Material: [número material]
  → Número de serie: [manual o automático]
  → Datos de fabricante, fecha fabricación, garantía
```

### Historial de Reparaciones por Número de Serie

```
Transacción: IQ09 (Historial de números de serie)
  → Material: [número]
  → Número de serie: [específico]
  → Muestra: todos los movimientos, órdenes PM, instalaciones
```

---

## 6. Valoración y Costes

### Cálculo del Nuevo Valor del Material Reparado

```
Valor nuevo = Valor material defectuoso
            + Mano de obra reparación
            + Materiales consumidos
            + Servicios externos
            + Gastos generales (overhead)
```

### Actualización del Precio Estándar

Para materiales con precio estándar (tipo **S**):
1. Liquidación carga diferencia a cuenta de variación de precio
2. El precio estándar NO cambia automáticamente
3. Se requiere **MR21** (Cambio de precio de material) para actualizar

Para materiales con precio medio variable (tipo **V**):
1. Liquidación actualiza el precio medio automáticamente
2. El nuevo precio refleja el coste real de reparación

### Determinación de Cuentas Contables

| Operación | Cuenta Débito | Cuenta Crédito |
|---|---|---|
| Salida material defectuoso | Consumo materiales | Stock materiales |
| Entrada material reparado | Stock materiales | Producción propia |
| Liquidación costes | Stock materiales | Orden PM04 |
| Variación precio | Variación precio | Stock materiales |

---

## 7. Tablas Principales

### EQUI — Maestro de Equipos

```sql
-- Equipos con material reparable asociado
SELECT EQUNR, MATNR, SERGE, SERNR, INBDT, EQTYP
FROM EQUI
WHERE MATNR = '[material_reparable]'
  AND EQTYP = 'M'  -- Tipo equipo = material en stock
```

| Campo | Descripción |
|---|---|
| EQUNR | Número de equipo |
| MATNR | Número de material |
| SERGE | Clase serialización |
| SERNR | Número de serie |
| INBDT | Fecha puesta en servicio |
| EQTYP | Tipo de equipo (M=material) |

### AUFK — Cabecera de Orden

```sql
-- Órdenes de reacondicionamiento PM04
SELECT AUFNR, AUART, OBJNR, ERDAT, AUTYP, KOSTL, LSTAR
FROM AUFK
WHERE AUART = 'PM04'
  AND ERDAT >= '20240101'
ORDER BY ERDAT DESC
```

| Campo | Descripción |
|---|---|
| AUFNR | Número de orden |
| AUART | Tipo de orden (PM04) |
| OBJNR | Número de objeto (para clasificación) |
| ERDAT | Fecha de creación |
| AUTYP | Categoría de orden (30=Reacondicionamiento) |
| KOSTL | Centro de coste |
| LSTAR | Clase de actividad |

### MSEG / MATDOC — Documentos de Material

```sql
-- Movimientos de mercancías de reacondicionamiento
SELECT MBLNR, MJAHR, ZEILE, BWART, MATNR, WERKS, LGORT,
       MENGE, MEINS, AUFNR, SERNR
FROM MSEG
WHERE AUFNR IN (
    SELECT AUFNR FROM AUFK WHERE AUART = 'PM04'
)
  AND BWART IN ('101', '261', '531', '653')
ORDER BY MBLNR DESC
```

| Campo | Descripción |
|---|---|
| MBLNR | Número de documento de material |
| MJAHR | Año del documento |
| BWART | Tipo de movimiento |
| MATNR | Número de material |
| WERKS | Centro |
| LGORT | Almacén |
| MENGE | Cantidad |
| AUFNR | Número de orden (referencia) |
| SERNR | Número de serie |

### QMEL — Avisos de Calidad (si integrado con QM)

```sql
-- Avisos QM relacionados con reacondicionamiento
SELECT QMNUM, QMART, MATNR, SERNR, AUFNR, QMDAT, MNCOD
FROM QMEL
WHERE QMART = 'Q2'  -- Reclamación a proveedor
  AND MATNR = '[material]'
```

### Otras Tablas Relevantes

| Tabla | Descripción | Uso en Refurbishment |
|---|---|---|
| AFKO | Cabecera de orden de producción/PM | Datos planificación orden PM04 |
| AFPO | Posición de orden | Material, cantidad, almacén destino |
| AFRU | Confirmaciones de orden | Operaciones confirmadas |
| RESB | Reservas/necesidades componentes | Componentes planificados en orden |
| ISEG | Historial números de serie | Movimientos del número de serie |
| SER01-SER12 | Serialización por referencia | Documentos con núm. serie |
| MARA | Maestro de materiales general | Tipo material, grupo |
| MARC | Datos de material por centro | Configuración planificación |
| MBEW | Valoración de material | Precio, valor stock |

---

## 8. Queries MCP para Diagnóstico

### Consultar Órdenes PM04 Abiertas

```sql
-- GetSqlQuery: Órdenes reacondicionamiento en curso
SELECT T1.AUFNR, T1.AUART, T2.KTEXT, T1.ERDAT, T1.GSTRS, T1.GLTRS,
       T3.MATNR, T3.GAMNG
FROM AUFK T1
INNER JOIN AUFM T2 ON T1.AUFNR = T2.AUFNR
INNER JOIN AFPO T3 ON T1.AUFNR = T3.AUFNR
WHERE T1.AUART = 'PM04'
  AND T1.SYSST NOT IN ('LKZ', 'TABG')
ORDER BY T1.ERDAT DESC
FETCH FIRST 50 ROWS ONLY
```

### Verificar Movimientos de un Material Reparable

```sql
-- GetSqlQuery: Historial movimientos material reparable
SELECT MBLNR, MJAHR, ZEILE, BUDAT, BWART, MENGE, MEINS,
       WERKS, LGORT, AUFNR, SERNR
FROM MSEG
WHERE MATNR = '[MATERIAL_NUMBER]'
  AND BWART IN ('101', '261', '531', '653', '102', '262')
  AND BUDAT >= '[FECHA_INICIO]'
ORDER BY BUDAT DESC, MBLNR DESC
```

### Stock de Materiales Reparables por Almacén

```sql
-- GetSqlQuery: Stock en almacén de reparables
SELECT T1.MATNR, T2.MAKTX, T1.WERKS, T1.LGORT, T1.LABST,
       T1.UMLME, T1.SPEME, T1.EINME
FROM MARD T1
INNER JOIN MAKT T2 ON T1.MATNR = T2.MATNR AND T2.SPRAS = 'S'
WHERE T1.LGORT = '[ALMACEN_REPARABLES]'
  AND T1.WERKS = '[CENTRO]'
  AND (T1.LABST > 0 OR T1.UMLME > 0)
ORDER BY T1.MATNR
```

---

## 9. Integración con Gestión de Calidad (QM)

### Inspección de Entrada del Componente Reparado

Si se activa QM en la recepción de órdenes PM04:
- Se crea automáticamente un **lote de inspección** al hacer la entrada de mercancías
- El componente queda en **stock en control de calidad** (Q)
- Después de la decisión de uso, pasa a stock libre

**Transacción:** QA11 (Registrar decisión de uso)

### Configuración

```
SPRO → QM → Planificación de calidad
  → Inspección en aprovisionamiento
  → Definir tipos de inspección
  → Tipo 04: Entrada de mercancías de orden PM
```

---

## 10. Reporting y Análisis

### Transacciones de Reporting Refurbishment

| Transacción | Descripción |
|---|---|
| IW39 | Lista de órdenes de mantenimiento (filtrar PM04) |
| IW38 | Cambio masivo de órdenes |
| MB51 | Lista de documentos de material (filtrar movimientos) |
| MB52 | Stocks de almacén por material |
| IQ09 | Historial de números de serie |
| KSB1 | Líneas de coste de orden (análisis costes reparación) |
| S_ALR_87013533 | Comparativo plan/real órdenes PM |

### KPIs de Reacondicionamiento

```sql
-- GetSqlQuery: KPIs Refurbishment - Coste medio reparación por material
SELECT T1.MATNR, T2.MAKTX,
       COUNT(T1.AUFNR) AS NUM_REPARACIONES,
       AVG(T3.WKGBTR) AS COSTE_MEDIO,
       SUM(T3.WKGBTR) AS COSTE_TOTAL
FROM AUFK T1
INNER JOIN MAKT T2 ON T1.OBJNR = T2.MATNR AND T2.SPRAS = 'S'
INNER JOIN COSS T3 ON T1.AUFNR = T3.AUFNR
WHERE T1.AUART = 'PM04'
  AND T1.GJAHR = '[ANIO]'
GROUP BY T1.MATNR, T2.MAKTX
ORDER BY COSTE_TOTAL DESC
```

---

## 11. Buenas Prácticas

1. **Siempre usar números de serie** para componentes reparables costosos — permite trazabilidad completa
2. **Definir almacenes separados** para materiales defectuosos vs reparados vs disponibles
3. **Configurar precio estándar revisado** anualmente basado en costes reales de reparación
4. **Integrar con QM** para inspección de componentes reparados antes de liberar al stock
5. **Límite de reparaciones**: Definir un máximo de ciclos de reparación por número de serie (campo en maestro de equipos o clasificación)
6. **Documentar en orden**: Registrar hallazgos de diagnóstico en texto largo de la orden PM04
7. **Fotografías**: Adjuntar documentos GOS a la orden (antes/después de reparación)

---

## 12. Errores Comunes y Soluciones

| Error | Causa | Solución |
|---|---|---|
| "No se puede liquidar: receptor MAT no definido" | Perfil liquidación sin regla MAT | Revisar SPRO perfil liquidación PM04 |
| "Material no gestionado en serie" | Perfil serialización no asignado | Asignar perfil en customizing material |
| "Movimiento 653 no permitido" | Almacén destino no configurado | Verificar configuración almacén |
| "Error valoración al entrada EM" | Cuenta contable no determinada | Verificar OBYC para movimiento 531 |
| "Cantidad a reacondicionar > stock" | Stock insuficiente en almacén | Verificar stock con MB52 |
