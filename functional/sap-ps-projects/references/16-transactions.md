# Transacciones SAP PS — Catalogo Completo

## Introduccion

Catalogo completo de transacciones del modulo SAP PS (Project System) organizadas por area funcional, con descripcion, modo de acceso y equivalentes Fiori donde aplique. SAP S/4HANA 2023 mantiene todas las transacciones clasicas y agrega apps Fiori para los procesos mas comunes.

---

## 1. Definicion y Gestion de Proyectos (WBS)

### 1.1 Crear y Modificar Proyectos

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ01** | Crear proyecto (WBS) | Crea cabecera y estructura WBS inicial |
| **CJ02** | Modificar proyecto (WBS) | Edicion de proyecto existente con todas las opciones |
| **CJ03** | Visualizar proyecto | Solo lectura |
| **CJ06** | Crear proyecto (formulario simple) | Version simplificada para proyectos basicos |
| **CJ07** | Modificar proyecto (formulario simple) | |
| **CJ08** | Visualizar proyecto (formulario simple) | |
| **CJ11** | Crear elemento WBS | Crear un elemento WBS individual |
| **CJ12** | Modificar elemento WBS | Editar un elemento WBS existente |
| **CJ13** | Visualizar elemento WBS | Solo lectura |
| **CJ20N** | Editor de Proyecto (Project Builder) | Interfaz grafica completa; recomendada para S/4HANA |
| **CJW3** | Modificar proyecto via WBS (tabla) | Vista tabular masiva de WBS |

**Fiori equivalente:**
| App ID | Nombre |
|--------|--------|
| F2375 | Manage Projects |
| F2376 | Create Project |
| F3539 | Project Overview |

### 1.2 Copiar y Versionar Proyectos

| Trans. | Descripcion |
|--------|-------------|
| **CJ9B** | Crear version de proyecto (WBS) |
| **CJ9BS** | Copiar proyecto completo (con redes) |
| **CJ9C** | Copiar red de trabajo a otro proyecto |
| **CJ9CS** | Copiar elemento WBS individual |
| **CJ91** | Crear version proyecto WBS estandar |
| **CJE0** | Comparar versiones de proyecto |
| **CJ9D** | Borrar version de proyecto |

### 1.3 Status de Proyecto

| Trans. | Descripcion |
|--------|-------------|
| **CJ02** | Cambiar status (dentro de la transaccion de modificacion) |
| **CJ20N** | Cambiar status masivo desde Project Builder |
| **CJ26** | Liberar elementos WBS (masivo) |
| **CJCO** | Completar tecnicamente WBS (masivo) |
| **CJ27** | Bloquear/Desbloquear WBS |

---

## 2. Redes y Actividades

### 2.1 Crear y Modificar Redes

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CN21** | Crear red | Crear cabecera de red con actividades |
| **CN22** | Modificar red | Editar red existente + componentes |
| **CN23** | Visualizar red | Solo lectura |
| **CN24** | Crear red estandar (template) | Redes reutilizables como plantilla |
| **CN25** | Confirmar actividades de red | Registro de avance de actividades |
| **CN26** | Cancelar confirmacion | Revertir confirmacion de actividad |
| **CN27** | Confirmacion colectiva de actividades | Masiva para multiples actividades |
| **CN28** | Visualizar confirmaciones | Historial de confirmaciones |
| **CN41** | Proceso guiado de red | Wizard para redes complejas |
| **CJ20N** | Project Builder (incluye redes) | Interfaz unificada proyecto+red |

### 2.2 Hitos

| Trans. | Descripcion |
|--------|-------------|
| **CN30** | Crear hito | Hito en actividad de red |
| **CN31** | Modificar hito | |
| **CN32** | Visualizar hito | |
| **CN33** | Crear hito de facturacion | Hito con impacto en SD billing |

### 2.3 Componentes de Red (Material)

| Trans. | Descripcion |
|--------|-------------|
| **CN22** | Asignar componentes a actividades | Dentro de la modificacion de red |
| **CN49** | Verificar disponibilidad de componentes | Disponibilidad de material en red |
| **CNS43** | Lista de componentes de red | Listado por proyecto/red |

### 2.4 Programacion (Scheduling)

| Trans. | Descripcion |
|--------|-------------|
| **CJ29** | Programar proyecto (WBS) | Forward/backward scheduling a nivel WBS |
| **CN72** | Reprogramar redes | Scheduling de redes de trabajo |
| **CNS41** | Vista de Gantt de red | Diagrama de barras de actividades |
| **CN48** | Diagrama de red (grafico) | Visualizacion en red (AON) |

---

## 3. Presupuesto

### 3.1 Asignacion y Modificacion de Presupuesto

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ30** | Presupuesto original (proyecto) | Asignar presupuesto inicial por WBS |
| **CJ31** | Visualizar presupuesto original | |
| **CJ32** | Suplemento de presupuesto | Incrementar presupuesto aprobado |
| **CJ33** | Devolucion de presupuesto | Reducir presupuesto (devolucion) |
| **CJ34** | Traspasar presupuesto | Mover presupuesto entre WBS |
| **CJ35** | Bloquear/Desbloquear presupuesto | Impedir uso de presupuesto |
| **CJ36** | Liberar presupuesto | Liberar presupuesto (de asignado a disponible) |
| **CJ37** | Visualizar presupuesto (jerarquia) | Vista jerarquica de presupuesto |
| **CJ38** | Plan anual de presupuesto | Distribucion mensual del presupuesto |
| **CJ3A** | Transferir presupuesto entre proyectos | |
| **CJ3B** | Copiar presupuesto de version | Copiar presupuesto de version a operativa |

**Fiori equivalente:**
| App ID | Nombre |
|--------|--------|
| F3125 | Manage Project Budgets |
| F3126 | Budget Transfer |

### 3.2 Control de Disponibilidad Presupuestaria

| Trans. | Descripcion |
|--------|-------------|
| **CJBV** | Actualizar calculo de disponibilidad | Recalcular saldos de disponibilidad |
| **CJBN** | Verificar disponibilidad de presupuesto | Informe de disponibilidad |
| **CJBW** | Configurar calculo de disponibilidad | |

---

## 4. Planificacion de Costes

### 4.1 Plan de Costes en WBS

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ40** | Plan de costes WBS (general) | Planificacion global por WBS |
| **CJ41** | Visualizar plan de costes WBS | Solo lectura |
| **CJ42** | Planificacion detallada de costes | Por clase de coste y periodo |
| **CJ43** | Visualizar planificacion detallada | |
| **CJ44** | Planificacion en base a cantidades | Planificacion con tarifas de actividad |
| **CJ45** | Planificacion manual por WBS (tabla) | Vista tabular para edicion masiva |
| **CJ46** | Planificacion de la demanda | Demanda planificada de recursos |

### 4.2 Plan de Costes en Red

| Trans. | Descripcion |
|--------|-------------|
| **CN50** | Calcular costes de red | Valorar red con tarifas de actividad |
| **CNB1** | Plan de costes de actividad (tabla) | |
| **CNB2** | Visualizar costes planificados de red | |

### 4.3 Copiar Plan de Costes

| Trans. | Descripcion |
|--------|-------------|
| **CJ9F** | Copiar plan de costes (WBS) | De una version a otra |
| **CJN1** | Transferir plan a presupuesto | Convertir plan en presupuesto |

---

## 5. Ejecucion del Proyecto

### 5.1 Registro de Costes Reales

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **FB01** | Contabilizar documento FI con WBS | Imputacion directa WBS |
| **FB60** | Contabilizar factura de proveedor | Con posicion de WBS |
| **MIGO** | Entrada/Salida de mercancias | Mov. 101 (EM pedido), 221 (salida stock proy.) |
| **CAT2** | Hoja de tiempos CATS | Registro de horas con WBS |
| **KB21N** | Contabilizar actividad de proceso | CO-ABC con imputacion WBS |
| **KB31N** | Contabilizar reclasificacion manual | Mover costes entre objetos CO |

### 5.2 Pedidos y Solicitudes con WBS

| Trans. | Descripcion |
|--------|-------------|
| **ME21N** | Crear pedido de compras con WBS | Imputacion WBS en posicion |
| **ME51N** | Crear solicitud de pedido con WBS | |
| **ME2J** | Listar pedidos por proyecto | Pedidos asignados a WBS |
| **ME2N** | Listar pedidos por numero | Con filtro por WBS |
| **IW31** | Crear orden de mantenimiento con WBS | PM integrado con PS |

### 5.3 Confirmaciones y Avance

| Trans. | Descripcion |
|--------|-------------|
| **CN25** | Confirmacion de actividad de red | |
| **CNE1** | Confirmacion de avance WBS individual | |
| **CNE5** | Confirmacion de avance WBS colectivo | |
| **CAT2** | CATS - Confirmacion de tiempos | |

---

## 6. Analisis y Reporting

### 6.1 Informes de Costes PS

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJI3** | Partidas individuales reales proyecto | Informe basico de costes reales por WBS |
| **CJI5** | Partidas individuales plan proyecto | Costes planificados por WBS |
| **CJI8** | Partidas individuales comprometidas | Compromisos abiertos |
| **CJI0** | Partidas individuales: todas | Plan + real + comprometido |
| **S_ALR_87013532** | Analisis jerarquico de proyecto | Informe estandar plan/real/variacion |
| **S_ALR_87013533** | Estado de WBS | Status de todos los elementos |
| **S_ALR_87013558** | Presupuesto vs. real vs. compromiso | Informe de disponibilidad |
| **S_ALR_87013542** | Informe de variaciones | Desviaciones plan vs. real |
| **S_ALR_87013534** | Estructura de costes del proyecto | Por clase de coste |
| **S_ALR_87013543** | Plan actual vs. plan original | Con comparacion de versiones |
| **S_ALR_87013544** | Resumen ejecutivo del proyecto | Vista consolidada |
| **S_ALR_87013545** | Proyectos por responsable | |
| **S_ALR_87013546** | Costes de proyecto por CC imputador | |
| **S_ALR_87013547** | Costes y pagos por proyecto | |

### 6.2 Informes de Avance y EVM

| Trans. | Descripcion |
|--------|-------------|
| **CNE6** | Vista general de avance | Metricas EVM por proyecto |
| **CNE7** | Historial de avance | Evolucion temporal del avance |
| **S_ALR_87013532** | Con version de avance seleccionada | Integra EVM con costes |

### 6.3 Informes de Fechas y Programacion

| Trans. | Descripcion |
|--------|-------------|
| **CJ2D** | Informe de fechas de proyecto | Fechas planificadas vs. reales |
| **CNS41** | Diagrama de Gantt de red | Vista grafica de actividades |
| **CJ2C** | Informe de actividades por periodo | |
| **S_ALR_87013538** | Proyectos con retrasos | Hitos no alcanzados |

### 6.4 Informes de Pedidos y Material

| Trans. | Descripcion |
|--------|-------------|
| **ME2J** | Pedidos por proyecto | |
| **MB25** | Reservas de material por WBS | |
| **MB54** | Stock de proyecto | |
| **CN49** | Disponibilidad de componentes | |

### 6.5 Sistema de Informacion de Proyectos (LIS)

| Trans. | Descripcion |
|--------|-------------|
| **CNS41** | Monitor de informacion de red | |
| **CNS43** | Lista de componentes de red | |
| **CNS44** | Informacion de status de redes | |
| **CNS46** | Informe de capacidades de red | |
| **CJS0** | Sistema de informacion de estructuras | Explorador jerarquico |
| **CJW3** | Vista tabla de WBS masiva | |

---

## 7. Cierre de Periodo y Liquidacion

### 7.1 Calculo de Gastos Generales (Overhead)

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ44** | Calculo de overhead en proyecto | Individual |
| **CJA1** | Calculo masivo de overhead | Por grupo de proyectos |

### 7.2 Reconocimiento de Ingresos (Results Analysis)

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **KKA1** | Analisis de resultados individual | Por WBS o proyecto |
| **KKA2** | Analisis de resultados masivo | Para multiples proyectos |
| **KKA3** | Visualizar analisis de resultados | |
| **KKABT** | Cancelar analisis de resultados | Revertir calculo |
| **KKA4** | Variaciones de produccion | |

### 7.3 Liquidacion

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ88** | Liquidacion de proyecto (masiva) | Liquidar WBS → receptor |
| **CJ8G** | Liquidacion individual de WBS | Un WBS a la vez |
| **CJ9E** | Ver reglas de liquidacion | Consultar reglas sin modificar |
| **CJ04** | Modificar reglas de liquidacion WBS | Definir receptores |
| **KO88** | Liquidacion de ordenes CO | Para redes y actividades ext. |

**Fiori equivalente:**
| App ID | Nombre |
|--------|--------|
| F3127 | Project Settlement |
| F3128 | Manage Settlement Rules |

### 7.4 Cierre de Periodo PS

| Trans. | Descripcion |
|--------|-------------|
| **CJAB** | Activar actualizacion de control | |
| **CJBN** | Verificar disponibilidad de presupuesto | |
| **CJCO** | Completar tecnicamente WBS (masivo) | |
| **CJFM** | Funciones de fin de mes | Wizard de cierre de periodo |

---

## 8. Configuracion de Reglas de Liquidacion

### 8.1 Liquidacion de WBS

| Trans. | Descripcion |
|--------|-------------|
| **CJ04** | Modificar reglas de liquidacion (WBS) | Definir receptores, %, clave asentamiento |
| **CJ05** | Visualizar reglas de liquidacion | |
| **CJ9E** | Ver reglas de liquidacion de proyecto | Vista del proyecto completo |
| **CJAV** | Crear reglas de liquidacion masivas | Propuesta automatica |

---

## 9. Actividades del Activo en Curso (AuC / Assets Under Construction)

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **AS91** | Crear activo en curso (shell) | Para proyectos capitalizables |
| **AS02** | Modificar ficha de activo | |
| **AIAB** | Distribuir AuC a activos finales | Al completar el proyecto |
| **AIBU** | Liquidar AuC a activos definitivos | |
| **CJ88** | Liquidar WBS → AuC | Flujo PS→FI-AA |

---

## 10. Administracion de Claims

| Trans. | Descripcion |
|--------|-------------|
| **CN60** | Crear reclamacion (Claim) | Solo con Claims Management activado |
| **CN61** | Modificar reclamacion | |
| **CN62** | Visualizar reclamacion | |
| **CN65** | Informe de reclamaciones | |

---

## 11. MRP y Planificacion de Material

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **MD01** | MRP global | Incluye necesidades de proyectos |
| **MD02** | MRP individual de material | |
| **MD41** | MRP orientado a proyecto | MRP especifico para componentes de red |
| **MD04** | Lista de necesidades/stocks | Verificar situacion de material |
| **MD07** | Lista de materiales a procesar | |
| **ME57** | Asignar y procesar solicitudes | Convertir solped en pedido |

---

## 12. Gestion Documental y Notas

| Trans. | Descripcion |
|--------|-------------|
| **CJ02** | Adjuntar documentos a proyecto | Dentro de modificacion |
| **CV01N** | Crear documento GED | Gestion electronica de documentos |
| **CV02N** | Modificar documento GED | |
| **CV04N** | Buscar documentos GED | |

---

## 13. Periodos y Calendario

| Trans. | Descripcion |
|--------|-------------|
| **OB29** | Calendario de periodos contables | |
| **SCAL** | Calendario de fabrica (para programacion) | |
| **CJ2A** | Modificar fechas de proyecto | Actualizar fechas de WBS masivamente |
| **CJ2B** | Visualizar fechas de proyecto | |

---

## 14. Integracion SD - Facturacion de Proyectos

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **DP90** | Resource-Related Billing | Crear factura basada en costes reales |
| **DP91** | Actualizar facturacion por recursos | |
| **DP95** | Informacion de facturacion por recursos | |
| **DP96** | Analisis de facturacion por recursos | |
| **VA01** | Crear pedido de ventas con WBS | |
| **VF01** | Crear factura SD | |
| **VF04** | Lista de pedidos a facturar | Para milestone billing |

---

## 15. Transacciones de Administracion PS

| Trans. | Descripcion | Notas |
|--------|-------------|-------|
| **CJ20N** | Project Builder | Centro de trabajo principal PS |
| **CJLD** | Parametros de control CO | Activar PS por sociedad CO |
| **CNC1** | Organizaciones de red estandar | |
| **OPUK** | Parametros generales PS | Configuracion central |
| **CN08** | Reorganizacion de proyectos | Archivado y limpieza |

---

## 16. Equivalentes Fiori Completos

| App Fiori ID | Nombre Fiori | Trans. Clasica Equiv. |
|-------------|--------------|----------------------|
| F2375 | Manage Projects | CJ02, CJ20N |
| F2376 | Create Project | CJ01 |
| F3539 | Project Overview | S_ALR_87013532 |
| F3538 | Confirm Project Progress | CNE1, CNE5 |
| F2390 | Project Progress | CNE6 |
| F3125 | Manage Project Budgets | CJ30, CJ32 |
| F3126 | Budget Transfer | CJ34 |
| F3127 | Project Settlement | CJ88 |
| F3128 | Manage Settlement Rules | CJ04 |
| F2394 | Project Dashboard | S_ALR_87013544 |
| F3540 | Monitor Project Progress | CNE7 |
| F3541 | Project Cost Overview | CJI3, S_ALR_87013532 |
| F3542 | Project Schedule Overview | CJ2D, CNS41 |
| F3543 | Project Procurement Overview | ME2J |
| F2391 | Manage Networks | CN22 |
| F2392 | Confirm Network Activities | CN25, CN27 |
| F2393 | My Projects | Dashboard personal |
| F3544 | Project Staffing | CN22 (recursos) |
| F3545 | Resource Management | CNC6 |

---

## 17. Transacciones de Customizing PS (SPRO)

| Acceso SPRO | Descripcion |
|-------------|-------------|
| `PS → Structures → WBS → Define Project Profile` | Perfiles de proyecto |
| `PS → Structures → WBS → Define Project Types` | Tipos de proyecto |
| `PS → Structures → Network → Define Network Profile` | Perfiles de red |
| `PS → Structures → Network → Define Control Keys` | Claves de control actividad |
| `PS → Costs → Budget → Define Budget Profile` | Perfiles de presupuesto |
| `PS → Progress → Define Progress Profile` | Perfiles de avance |
| `PS → Costs → Settlement → Define Settlement Profile` | Tipos de liquidacion |
| `PS → Costs → Revenues → Define Results Analysis Keys` | Claves analisis resultados |
| `PS → Material → MRP for Projects` | Parametros MRP PS |
| `PS → Dates → Scheduling → Define Scheduling Parameters` | Parametros programacion |

---

## 18. Transacciones de Diagnostico y Soporte

| Trans. | Descripcion |
|--------|-------------|
| **SE16N** | Browser de tablas (PROJ, PRPS, NETZ, VORG, etc.) |
| **CJBV** | Actualizar balances de disponibilidad |
| **CJBN** | Verificar control presupuestario |
| **SM37** | Monitor de trabajos en background |
| **ST22** | Volcado de dump ABAP |
| **SU53** | Analizar autorizaciones |
| **SCMA** | Configurar monitor de costes |

---

## 19. Tabla Resumen por Area Funcional

| Area | Transacciones Clave |
|------|---------------------|
| Crear/Modificar WBS | CJ01, CJ02, CJ20N, CJ11, CJ12 |
| Copiar/Versionar | CJ9BS, CJ91, CJE0 |
| Status | CJ26, CJCO, CJ02 |
| Redes | CN21, CN22, CN25, CN27 |
| Hitos | CN30, CN31 |
| Presupuesto | CJ30, CJ32, CJ34, CJ36 |
| Plan costes | CJ40, CJ42, CJ44, CJ45 |
| Costes reales | CJI3, S_ALR_87013532 |
| Avance/EVM | CNE1, CNE5, CNE6, CNE7 |
| Cierre periodo | CJ44, KKA2, CJ88 |
| Liquidacion | CJ88, CJ8G, CJ04 |
| Material/MRP | CN22, CN49, MD41, MB54 |
| SD Billing | DP90, VF01, VA01 |
| Administracion | CJ20N, OPUK, CJLD |
