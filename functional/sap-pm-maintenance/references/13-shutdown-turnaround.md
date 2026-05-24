# Paradas Planificadas (Shutdown / Turnaround) — SAP PM S/4HANA 2023

## 1. Concepto de Parada Mayor

Una **parada planificada** (shutdown, turnaround, overhaul) es la detención programada de una instalación industrial o planta completa para realizar mantenimiento mayor, inspecciones reglamentarias, revisiones de seguridad y mejoras técnicas que no pueden ejecutarse con la instalación en operación.

### Caracteristicas de una Parada Mayor

- **Alcance masivo**: Decenas o cientos de órdenes de trabajo simultáneas
- **Criticidad alta**: Retraso = pérdida de producción enormes
- **Multirecurso**: Personal propio + contratistas + subcontratos especializados
- **Regulatoria**: Inspecciones de organismos oficiales (calderas, recipientes a presión, etc.)
- **Presupuesto elevado**: Millones de euros, requiere aprobación a nivel directivo
- **Duración acotada**: De días a semanas, ventana estrictamente controlada

### Tipos de Parada

| Tipo | Frecuencia | Duración | Alcance |
|---|---|---|---|
| Major Turnaround | 3-5 años | 2-6 semanas | Planta completa |
| Minor Shutdown | 1-2 años | 1-2 semanas | Áreas críticas |
| Planned Outage | Anual | 3-7 días | Equipo específico |
| Emergency Shutdown | No planificado | Variable | Según avería |
| Regulatory Inspection | Según norma | 1-5 días | Equipos reglamentados |

---

## 2. Tipo de Orden PM10 — Parada General

### Configuracion del Tipo de Orden

**Ruta SPRO:**
```
PM → Gestión de órdenes de mantenimiento
  → Funciones y configuración de órdenes
    → Definir tipos de órdenes
```

El tipo **PM10** (parada general) tiene:
- Categoría de orden: **10** (Mantenimiento)
- Perfil de liquidación: Centro de coste + WBS (si integrado con PS)
- Clase de orden especial para filtros en reporting
- Tipo de actividad: SHUTDOWN o TURNAROUND

### Alternativa con PS — Proyecto de Parada

Para paradas mayores con presupuesto elevado, se recomienda integrar con **Project System (PS)**:

```
Proyecto PS (CJ01)
  → WBS Element por área/sistema (CJ11)
    → Red (CN21)
      → Actividades de red
        → Órdenes PM vinculadas a actividades
```

Ventajas de la integración PS:
- Presupuesto centralizado con aprobación formal
- Seguimiento de avance (milestones)
- Cash flow planning de la parada
- Reporting consolidado costes proyecto

---

## 3. Fases de Planificacion de Parada

### Fase 1: Definicion del Alcance (12-18 meses antes)

**Actividades:**
- Identificar todos los trabajos necesarios (PM preventivo + correctivo pendiente + mejoras)
- Revisión de historial de órdenes anteriores (IW39)
- Inspección visual y diagnóstico predictivo
- Requerimientos regulatorios (lista de inspecciones obligatorias)
- Aprobación de presupuesto preliminar

**En SAP:**
```
- Crear Proyecto PS (CJ01) con código de parada: TAR-2024-P1
- Crear WBS por área: CIVIL, MECÁNICA, ELÉCTRICA, INSTRUMENTACIÓN, CALDERAS
- Establecer presupuesto preliminar por WBS (CJ30 - Plan de costes)
```

### Fase 2: Planificacion Detallada (6-12 meses antes)

**Actividades:**
- Crear todas las órdenes PM10 con scope detallado
- Planificar operaciones, materiales y servicios por orden
- Calcular necesidades de mano de obra (horas-hombre)
- Crear solicitudes de pedido para materiales y servicios
- Coordinar con Compras lead times de materiales críticos

**En SAP:**
```
Transacciones:
  IW31/IW36 → Crear órdenes PM10 individuales o masivas
  IP10      → Planificación de mantenimiento (generar desde planes)
  IW38      → Cambio masivo de órdenes (fechas, prioridades)
  MD61      → Planificación de necesidades de materiales
```

### Fase 3: Programacion (2-3 meses antes)

**Actividades:**
- Secuenciar órdenes según dependencias técnicas
- Asignar recursos (puestos de trabajo, contratistas)
- Crear ruta crítica del proyecto
- Reuniones de coordinación con contratistas
- Preparar permisos de trabajo y protocolos de seguridad

**En SAP:**
```
- Red PS (CN21): Actividades en red con dependencias
- CM01: Planificación de capacidades (puestos de trabajo)
- ME21N: Pedidos a proveedores de servicios (categoría D - servicio)
- ML81N: Entrada de servicios (activación contratos)
```

### Fase 4: Preparacion y Pre-Shutdown (1 mes antes)

**Actividades:**
- Recepción de materiales críticos a almacén
- Revisión de lista de órdenes (scope final)
- Entrenamiento de personal
- Simulacros de seguridad
- Verificación de herramientas y equipos especiales
- Freeze del alcance (scope freeze)

**En SAP:**
```
- MB51: Verificar stock de materiales de parada
- IW37: Confirmación de lista de materiales en órdenes
- CM21: Planificación de capacidades detallada
```

### Fase 5: Ejecucion de la Parada

**Actividades diarias:**
- Morning meeting: revisión de progreso y bloqueos
- Actualización de avance por orden (% completado)
- Gestión de órdenes adicionales (scope creep)
- Control de horas y materiales

**En SAP:**
```
IW41/IW42 → Confirmaciones de operaciones (horas reales)
IW32      → Actualización de órdenes
MIGO      → Salidas de material al almacén
ML81N     → Registro de servicios prestados
CJ20N     → Actualización avance PS
```

### Fase 6: Cierre y Puesta en Marcha

**Actividades:**
- Inspecciones de cierre (tightness tests, functional tests)
- Obtención de permisos de puesta en marcha
- Cierre técnico de órdenes
- Documentación de hallazgos para próxima parada
- Devolución de materiales sobrantes al almacén

**En SAP:**
```
IW32  → Cierre técnico de órdenes (TECO)
IW24  → Lista de avisos pendientes (verificar cierre)
KO88  → Liquidar órdenes PM10
CJ88  → Liquidar proyecto PS
MIGO 122 → Devolución materiales sobrantes
```

---

## 4. Gestion de Subcontratos Masivos

### Estructura de Subcontratacion

Para paradas con muchos contratistas:

**Opción A: Pedido de servicio por contratista**
```
ME21N → Tipo de posición D (servicio)
  → Por cada contratista: un pedido con posiciones de servicio
  → Límites de valor por actividad
  → Asignación de responsable SAP por pedido
```

**Opción B: Contrato marco + pedido liberación**
```
ME31K → Contrato marco de servicios de parada
  → Condiciones de precio (tarifa hora técnico, hora oficial, etc.)
  → Validez: durante la parada
ME21N → Pedidos de liberación con referencia al contrato
```

**Opción C: Orden de servicio PM con componente subcontratación**
```
IW31 → Orden PM10
  → Operación de subcontratación (tipo de trabajo: servicios externos)
  → El sistema genera solped automáticamente
  → ML81N para entrada de servicios
```

### Hoja de Entrada de Servicios (ML81N)

```
ML81N:
  → Pedido de servicios: [número]
  → Fecha prestación: [fecha real]
  → Confirmar servicios prestados por línea
  → Adjuntar actas de conformidad (GOS)
```

---

## 5. Permisos de Trabajo y Seguridad

### Gestion de Permisos de Trabajo en SAP

Los **Permisos de Trabajo** (Work Permits, PTW) se gestionan como:

**Documentos de objeto técnico:**
```
IE02 → Equipo → Documentos
  → Tipo documento: ZPT (Permiso de trabajo - personalizado)
  → Adjuntar formulario PDF del permiso
```

**O mediante Checklist en la Orden:**
```
IW32 → Orden PM → Documentos → Listas de verificación
  → Lista: SAFETY_PTW (definida en customizing)
  → Campos: bloqueo energías, atmósfera, permisos firmados
```

### Tipos de Permiso Tipicos

| Permiso | Descripción | Validez |
|---|---|---|
| Trabajo en caliente | Soldadura, corte, llama abierta | Por turno |
| Entrada a espacio confinado | Tanques, pozos, silos | Por entrada |
| Trabajos en altura | >2m de elevación | Por turno |
| Bloqueo/Etiquetado (LOTO) | Aislamiento de energía | Por trabajo |
| Trabajo eléctrico | BT/MT instalaciones | Por turno |

### SPRO — Configuracion de Listas de Verificacion

```
SPRO → PM → Gestión de avisos
  → Listas de verificación
    → Definir tipos de lista
    → Definir posiciones de lista
    → Asignar a tipos de aviso/orden
```

---

## 6. Listas de Verificacion (Checklists) y Milestones

### Checklists en Ordenes PM

```
SPRO → PM → Gestión de órdenes
  → Listas de verificación
    → Definir perfil de lista de verificación
```

Ejemplo de checklist de cierre de parada:
- [ ] Prueba de hermeticidad completada
- [ ] Todos los andamios desmontados
- [ ] Protecciones y resguardos reinstalados
- [ ] Calibración de instrumentos verificada
- [ ] Documentación técnica actualizada
- [ ] Inspección regulatoria aprobada (si aplica)
- [ ] Limpieza de área finalizada

### Milestones en PS (Red de Actividades)

```
CN21 → Red → Milestone
  → Fecha planificada del milestone
  → Vinculado a: inicio producción, finalización área, etc.
  → % de avance automático del proyecto
```

Milestones típicos de una parada:
1. **M01** — Inicio de parada (planta detenida)
2. **M02** — Apertura de equipos completada
3. **M03** — Inspecciones completadas (>80%)
4. **M04** — Trabajos mecánicos cerrados
5. **M05** — Pruebas de presión aprobadas
6. **M06** — Puesta en marcha autorizada
7. **M07** — Producción estable restablecida

---

## 7. Reporting de Parada

### Transacciones de Seguimiento

| Transacción | Descripción |
|---|---|
| IW39 | Lista órdenes: filtrar por tipo PM10 + período parada |
| IW37N | Lista de operaciones: ver avance por operación |
| CM01 | Vista de capacidades: horas planificadas vs. reales |
| S_ALR_87013533 | Análisis plan/real de órdenes PM |
| CJ20N | Cockpit de proyecto PS (avance, costes, fechas) |
| CJE2 | Reporting de proyecto PS |
| FMRP_RHDBUD | Seguimiento presupuesto (si integrado con FM) |

### KPIs de Parada

| KPI | Fórmula | Target |
|---|---|---|
| Cumplimiento de alcance | Órdenes cerradas / Órdenes planificadas | >95% |
| Desviación de duración | (Días reales - Días plan) / Días plan | <5% |
| Desviación de coste | (Coste real - Presupuesto) / Presupuesto | <10% |
| Órdenes adicionales | Órdenes no planificadas / Total órdenes | <15% |
| Accidentes | Número de incidentes de seguridad | 0 |

### Consultas MCP para Reporting de Parada

```sql
-- GetSqlQuery: Resumen de parada - órdenes por estado
SELECT AUART, SYSST AS ESTADO,
       COUNT(*) AS NUM_ORDENES,
       SUM(GAMNG) AS HH_PLANIFICADAS,
       SUM(WKGBTR) AS COSTE_REAL
FROM AUFK T1
LEFT JOIN COSS T2 ON T1.AUFNR = T2.AUFNR
WHERE AUART = 'PM10'
  AND ERDAT BETWEEN '[FECHA_INI]' AND '[FECHA_FIN]'
GROUP BY AUART, SYSST
ORDER BY ESTADO
```

```sql
-- GetSqlQuery: Órdenes sin cerrar al final de la parada
SELECT T1.AUFNR, T1.KTEXT, T1.ERDAT, T1.GSTRS, T1.GLTRS,
       T2.ARBPL AS PUESTO_TRABAJO, T3.WKGBTR AS COSTE_REAL
FROM AUFK T1
INNER JOIN AFKO T2 ON T1.AUFNR = T2.AUFNR
LEFT JOIN COSS T3 ON T1.AUFNR = T3.AUFNR
WHERE T1.AUART = 'PM10'
  AND T1.SYSST NOT IN ('LKZ', 'TABG', 'TABG')
  AND T1.GLTRS < CURRENT_DATE
ORDER BY T1.GLTRS ASC
```

```sql
-- GetSqlQuery: Coste de parada por área (vía WBS PS)
SELECT T1.POSID AS WBS, T1.POST1 AS DESCRIPCION,
       SUM(T2.WTGBTR) AS COSTE_PLAN,
       SUM(T3.WKGBTR) AS COSTE_REAL,
       SUM(T3.WKGBTR) - SUM(T2.WTGBTR) AS DESVIACION
FROM PRPS T1
INNER JOIN COKS T2 ON T1.OBJNR = T2.OBJNR  -- Plan CO
INNER JOIN COSS T3 ON T1.OBJNR = T3.OBJNR  -- Real CO
WHERE T1.PSPNR IN (
    SELECT PSPNR FROM PROJ WHERE PSPID = '[PROYECTO_PARADA]'
)
GROUP BY T1.POSID, T1.POST1
ORDER BY COSTE_REAL DESC
```

---

## 8. Tablas Principales

### AUFK — Cabecera de Orden

```sql
-- Órdenes de parada
SELECT AUFNR, AUART, KTEXT, ERDAT, GSTRS, GLTRS,
       KOSTL, PSPNR, SYSST, AUTYP
FROM AUFK
WHERE AUART = 'PM10'
ORDER BY GSTRS
```

### AFKO — Cabecera de Orden (datos técnicos)

| Campo | Descripción |
|---|---|
| AUFNR | Número de orden |
| ARBPL | Puesto de trabajo responsable |
| AUFPL | Plan de trabajo (red interna) |
| GLTRP | Fecha fin planificada |
| GSTRP | Fecha inicio planificada |
| GMEIN | Unidad de medida cantidad base |
| GAMNG | Cantidad de operación |

### AFVV — Valores de Operacion de Orden

| Campo | Descripción |
|---|---|
| AUFPL | Plan de trabajo |
| APLZL | Contador de actividad |
| VGW01-VGW06 | Valores estándar (horas planificadas) |
| ISM01-ISM06 | Cantidades confirmadas reales |
| ISDD | Fecha inicio real confirmación |
| IEDD | Fecha fin real confirmación |

---

## 9. Integracion con Project System (PS)

### Estructura de Proyecto de Parada

```
Proyecto: TAR-2024-PLANTA1
  WBS: TAR-2024-P1-MECAN    (Mecánica)
    WBS: TAR-2024-P1-MECAN-01  (Área reactores)
    WBS: TAR-2024-P1-MECAN-02  (Área comprensores)
  WBS: TAR-2024-P1-ELECT    (Eléctrica)
  WBS: TAR-2024-P1-INSTR    (Instrumentación)
  WBS: TAR-2024-P1-CIVIL    (Civil)
  WBS: TAR-2024-P1-CALDERAS (Calderas/Recipientes)
```

### Vinculacion Orden PM a WBS

```
IW32 → Orden PM10 → Cabecera → Asignaciones
  → Elemento PEP (WBS): [TAR-2024-P1-MECAN-01]
```

Los costes de la orden PM fluyen automáticamente al WBS → al proyecto.

### Liquidacion PS al Cierre

```
CJ88 → Liquidar proyecto
  → Los costes del WBS se liquidan según regla:
    - A resultado (cuenta P&L si es mantenimiento operativo)
    - O capitalización (activo fijo si mejoras) vía FI-AA
```

---

## 10. Buenas Practicas

1. **Congelar alcance (scope freeze)** 4-6 semanas antes del inicio — no más cambios salvo seguridad crítica
2. **Gestionar el "scope creep"**: todo trabajo adicional requiere aprobación del director de parada
3. **Presupuesto de contingencia**: 10-15% sobre el presupuesto base para imprevistos
4. **Base de datos de lecciones aprendidas**: actualizar después de cada parada para la siguiente
5. **Critical Path Method (CPM)**: usar red PS para identificar y gestionar la ruta crítica
6. **Reuniones diarias de progreso** (30 minutos máximo): todos los supervisores de área
7. **Tracking en tiempo real**: confirmar operaciones en SAP same day — no acumular confirmaciones
8. **Devolución de materiales**: al cierre, devolver al almacén todo material no consumido (MIGO 122)
9. **Archivo digital**: todos los documentos de la parada adjuntos vía GOS en el proyecto PS
