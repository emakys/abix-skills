# CATS — Cross Application Time Sheet

## Vision General de CATS

### Que es CATS
- **Cross-Application Time Sheet** — hoja de tiempos multimodulo de SAP
- Permite registrar horas trabajadas contra objetos de costo de multiples modulos
- Fuente unica de verdad para tiempos en PM, PS, CO, PP y HR
- Disponible en SAP GUI (CAT2/CAT3) y Fiori (My Timesheet)

### Casos de Uso Principales
- Registro de horas contra ordenes de mantenimiento (PM)
- Imputacion de tiempos a proyectos y elementos PEP (PS)
- Confirmacion de operaciones de produccion (PP)
- Asignacion de horas a centros de coste o pedidos internos (CO)
- Calculo de nomina basado en tiempos registrados (HR)

### Arquitectura Multi-Modulo
```
CAT2/CAT3/Fiori
      ↓
   CATSDB (tabla central de tiempos)
      ↓
   CATSBF (buffer de transferencia)
      ↓
  CAT5 → HR (nomina/tiempos)
  CAT6 → CO/PS (centros coste, PEP, pedidos internos)
  CAT7 → PM/PP (confirmaciones de ordenes)
```

## CAT2 — Entrada de Datos de Tiempo

### Transaccion CAT2
- Entrada principal de tiempos en SAP GUI
- Vista de hoja de calculo: filas = objetos receptor, columnas = dias
- Periodo de entrada configurable: semanal, mensual, quincenal
- Perfil CATS determina que campos y modulos son visibles

### Pantalla CAT2 — Campos Principales
- **Empleado (PERNR)** — numero de personal del imputador
- **Fecha** — dia de registro de tiempo
- **Horas** — cantidad de tiempo registrado
- **Actividad** — tipo de actividad (LSTAR en CO, ARBID en PP)
- **Centro de coste** — receptor CO
- **Orden** — orden de mantenimiento PM o produccion PP
- **Elemento PEP** — estructura de proyecto PS
- **Pedido interno** — orden CO

### Flujo de Trabajo en CAT2
1. Empleado accede a CAT2 con su PERNR (o el responsable)
2. Selecciona periodo de registro
3. Introduce horas contra objetos receptores
4. Guarda como borrador (CATSDB, status 10)
5. Libera para aprobacion (status 20) o envia directamente

## CAT3 — Visualizacion y Aprobacion

### Transaccion CAT3
- Vista de aprobacion para responsables
- Lista de hojas de tiempo pendientes de aprobacion
- Aprobacion individual o masiva
- Devolucion con comentario si hay errores

### Estados de CATS
- **10 — Borrador** — guardado, no enviado
- **20 — Liberado** — enviado para aprobacion
- **30 — Aprobado** — listo para transferencia a modulos
- **40 — Rechazado** — devuelto al empleado
- **50 — Transferido** — ya procesado en modulos destino

## Perfiles CATS (T7R_PROFILE / Tabla Customizing)

### Definicion de Perfil
- El perfil CATS controla el comportamiento de CAT2/CAT3
- Asignacion: empleado → perfil via caracteristica TCATS
- Configuracion en SPRO → Cross Application → Time Sheet → Perfiles

### Parametros del Perfil
- **Modulos activos**: HR, CO, PM, PS, PP (combinables)
- **Campos visibles**: cuales campos aparecen en la hoja de tiempos
- **Campos obligatorios**: que debe rellenar el usuario
- **Periodo de entrada**: semanal, mensual, flexible
- **Horizonte de entrada**: cuantos dias hacia atras/adelante permite
- **Workflow de aprobacion**: si requiere aprobacion o transferencia directa

### Perfiles Tipicos por Escenario
- **Perfil HR-ONLY**: solo horas trabajadas para nomina, sin objetos CO/PM
- **Perfil PM-CATS**: horas contra ordenes de mantenimiento con actividad
- **Perfil PS-CATS**: horas contra elementos PEP de proyecto
- **Perfil FULL**: todos los modulos activos, mxima flexibilidad

## Workflow de Aprobacion

### Proceso de Aprobacion Estandar
1. Empleado registra y libera hoja de tiempos (CAT2)
2. Sistema notifica al aprobador (workflow SAP o email)
3. Aprobador revisa en CAT3 o Fiori
4. Aprobacion → status 30, disponible para transferencia
5. Rechazo → empleado recibe notificacion y corrige

### Integracion con SAP Business Workflow
- Tarea estandar TS20000029 — aprobacion de hoja de tiempos
- Agente: responsable directo (IT0001-MANDT jerarquia organizativa)
- Deadline y escalacion configurables
- Notificacion por email via SAPconnect

### Aprobacion Masiva
- RCATSA_MASS_APPROVE — aprobacion masiva por area
- Filtros: por unidad organizativa, centro de coste, proyecto
- Delegacion de aprobacion durante ausencias

## Integracion con PM — Mantenimiento de Planta

### Registro de Horas en Ordenes PM
- Objeto receptor: orden de mantenimiento (AUFNR)
- Actividad de trabajo (ARBID) vinculada a la orden
- Confirmacion de operacion especifica dentro de la orden
- Horas → coste real en la orden PM

### Datos Transferidos a PM
- CAT7 → confirmacion de operacion (IW41/IW42 equivalente)
- Horas reales vs. horas planificadas en la orden
- Actualizacion de status de operacion (CONF)
- Calculo de coste real via valoracion de actividad

### Customizing PM-CATS
- Actividades de trabajo (CR11/CR21) con tasas horarias
- Centro de trabajo → tipo de actividad → tasa de valoracion
- Tipos de orden aceptados en CATS (T001W config)

## Integracion con PS — Proyectos

### Registro de Horas en Proyectos
- Objeto receptor: elemento PEP (POSID) o red/actividad
- Red de proyecto (NETZP) + actividad de red (VORNR)
- Horas → coste real en el proyecto
- Actualizacion de avance del proyecto

### Datos Transferidos a PS
- CAT6 → documento de coste CO contra elemento PEP
- Actualizacion de horas reales en actividad de red
- Calculo de EAC (Estimate At Completion)
- Reportes de avance basados en tiempos CATS

### Customizing PS-CATS
- Tipos de actividad CO para proyectos
- Asignacion empleado → centro de coste emisor
- Claves de distribicion para multi-proyecto

## Integracion con CO — Controlling

### Registro contra Objetos CO
- Centro de coste (KOSTL) + tipo de actividad (LSTAR)
- Pedido interno (AUFNR) — tipo de orden CO
- Proceso de negocio ABC (PRZNR)
- Posicion estadistica

### Datos Transferidos a CO
- CAT6 → confirmacion de actividad CO (KB21N equivalente)
- Documento CO: emisor (empleado/centro coste) → receptor
- Valoracion: horas * tasa de actividad = importe
- Actualizacion de plan vs. real en CO-OM

### Valoracion en CO
- Tipo de actividad con precio planificado (KP26)
- Precio real calculado al final del periodo (KSPI)
- Split de costes: fijo/variable segun tipo actividad
- Liquidacion de costes desde pedidos internos

## Integracion con PP — Produccion

### Confirmaciones de Produccion via CATS
- Objeto receptor: orden de produccion (AUFNR PP)
- Operacion de fabricacion + puesto de trabajo
- Horas configuracion + horas maquina + horas mano de obra
- Cantidad producida y cantidad defectuosa

### Datos Transferidos a PP
- CAT7 → confirmacion de operacion PP (CO11N equivalente)
- Actualizacion de status de orden de produccion
- Calculo de costes reales de produccion
- Reduccion de necesidades de capacidad

## Flujo de Datos: CATSDB → CATSBF → Modulos

### CATSDB — Tabla Central CATS
- Almacenamiento de todos los registros de tiempo CATS
- Campos clave: PERNR, WORKDATE, STATUS, AWART
- Campos de receptor: KOSTL, AUFNR, POSID, LSTAR, ARBID
- Estado del registro: borrador/liberado/aprobado/transferido

### CATSBF — Buffer de Transferencia
- Tabla intermedia antes de transferencia a modulos
- Generada por proceso de aprobacion
- Contiene datos ya validados y enriquecidos
- Punto de entrada para los programas de transferencia

### Tabla CATSCO — Datos CO Enriquecidos
- Extension de CATSDB con datos CO completados
- Valoracion de actividades calculada
- Objeto receptor CO definitivo
- Base para CAT6 (transferencia CO/PS)

## Reports de Transferencia: CAT5/CAT6/CAT7

### CAT5 — Transferencia a Gestion de Tiempos HR
- Programa RCATSHR0 — transferencia de tiempos a HR
- Crea IT2001 (ausencias) o IT2002 (asistencias) automaticamente
- Calcula horas para nomina segun reglas de evaluacion de tiempos
- Actualiza IT2010 (tipos de salario de tiempo)
- Parametros: periodo, area de personal, modo simulacion

### CAT6 — Transferencia a CO/PS
- Programa RCATSCOF — transferencia a Controlling y Proyectos
- Crea confirmaciones de actividad en CO (KB21N)
- Crea imputaciones a elementos PEP en PS
- Actualiza costes reales en pedidos internos y centros de coste
- Valoracion automatica via tipo de actividad

### CAT7 — Transferencia a PM/PP
- Programa RCAPM000 (PM) / RCAPP000 (PP)
- Crea confirmaciones de operacion en PM (IW41)
- Crea confirmaciones en PP (CO11N)
- Actualiza avance de ordenes de mantenimiento y produccion
- Cierre automatico de operaciones segun configuracion

### Ejecucion de Transferencias
- Transacciones: CAT5, CAT6, CAT7 (o via SE38)
- Siempre ejecutar primero en modo simulacion
- Log de transferencia: errores y documentos creados
- Programa de fondo para grandes volumenes (SM36)

## Fiori My Timesheet

### App Fiori para CATS
- App ID: F0860 — My Timesheet
- Disponible en SAP S/4HANA 2020+ (mejorada en 2021/2022/2023)
- Interfaz movil-first para registro de tiempos diario
- Integracion con CATS backend (misma tabla CATSDB)

### Funcionalidades Fiori My Timesheet
- Vista semanal con entrada de horas por dia
- Busqueda de objetos receptores (ordenes, proyectos, centros coste)
- Favoritos y plantillas de entradas frecuentes
- Copia de semana anterior con un click
- Flujo de aprobacion integrado (Manage My Timesheet — aprobador)

### Configuracion Fiori para CATS
- OData service: /sap/opu/odata/sap/CATS_TIMESHEET_SRV
- Rol SAP: SAP_WDA_CATS (GUI) + FIORI_CATS (Fiori)
- Perfil CATS asignado via caracteristica TCATS
- Business Catalog: SAP_CA_BC_TIME_SHEET_PC

### Novedades S/4HANA 2023
- Mejoras en UX de My Timesheet (drag & drop)
- Integracion con Microsoft Teams para aprobaciones
- Soporte de registro de tiempo fuera de linea (offline)
- Analiticas de utilizacion de tiempo en SAP Analytics Cloud

## Consultas MCP para CATS

```
-- Leer registros CATS de un empleado en periodo
ReadTableEntries → CATSDB
  WHERE PERNR = '00001234'
  AND WORKDATE BETWEEN '20240101' AND '20240131'

-- Ver estado de aprobacion de hojas de tiempo
ReadTableEntries → CATSDB
  WHERE STATUS = '20'  -- liberadas pendientes aprobacion
  AND WORKDATE IN periodo

-- Consultar transferencias realizadas a CO
ReadTableEntries → CATSCO
  WHERE PERNR = empleado AND WORKDATE = fecha

-- Verificar perfil CATS asignado
ReadTableEntries → T7R_PROFILE (perfiles CATS)

-- Ver tipos de actividad disponibles para CATS
ReadTableEntries → T7R_FIELD (campos por perfil)

-- Consultar ordenes PM disponibles en CATS
ReadTableEntries → AUFK
  WHERE AUART IN tipos_orden_PM

-- Ejecutar transferencia CATS a CO en simulacion
ExecuteReport → RCATSCOF con modo simulacion

-- Ejecutar transferencia CATS a HR
ExecuteReport → RCATSHR0 con periodo y area personal

-- Ver log de transferencias anteriores
ReadTableEntries → CATSCO WHERE STATUS = '50'
```

### Tools MCP Relevantes
- `ReadTableEntries` — CATSDB, CATSBF, CATSCO, T7R_PROFILE
- `ExecuteReport` — RCATSHR0 (CAT5), RCATSCOF (CAT6), RCAPM000 (CAT7)
- `ReadHrInfotype` — IT2001/IT2002 creados por CAT5
- `GetFunctionGroup` — CATS_* grupos de funciones
- `SearchObject` — busqueda de programas y tablas CATS
- `ReadClass` — clases de negocio CATS (CL_CATS_*)
- `GetInterface` — interfaces de servicio OData CATS
