# Ausencias y Contingentes

## Tipos de Ausencia (T554S)

### Configuracion Principal
- Tabla T554S — definicion de tipos de ausencia
- Campos clave: AWART (clave tipo), ATEXT (descripcion), COTAP (clase de ausencia)
- Agrupacion por area de personal / subarea (T554T)
- Clase de ausencia: 1=deduccion sueldo, 2=sin deduccion, 3=enfermedad, etc.

### Tipos de Ausencia Estandar
- **Vacaciones** (URLA) — deduccion de contingente de vacaciones
- **Enfermedad** (KRANK) — clase de ausencia enfermedad, notificacion continuacion pago
- **Personal** (PERS) — dias personales sin impacto nomina
- **Maternidad/Paternidad** (MAT/PAT) — proteccion legal, reglas especiales
- **Lactancia** — horas parciales, calculo especial
- **Permiso sin sueldo** — suspension relacion laboral parcial

### Parametros Importantes por Tipo
- Clase de contingente a deducir (T554S-COTAP)
- Regla de recuento asociada (T554S-ANZHL)
- Relevancia para continuacion de pago (Lohnfortzahlung)
- Impacto en nomina: dias calendario vs. laborales

## Contingentes de Ausencia (T556A, T556B)

### T556A — Tipos de Contingente de Ausencia
- Definicion de cada tipo de contingente (vacaciones, asuntos propios, etc.)
- Campos: KTART (clave), KTEXT (descripcion), unidad (horas/dias)
- Tiempo de validez: por ano civil, ano vacacional o indefinido
- Maximo acumulable y reglas de caducidad

### T556B — Reglas de Derecho (Entitlement Rules)
- Definicion de cuantos dias/horas corresponden segun criterios
- Criterios: grupo de empleados, nivel salarial, antiguedad, jornada
- Integracion con caracteristica QUOMO — metodo de calculo
- Calculo proporcional para altas/bajas en el ano

### Calculo de Derechos
- Metodo proporcional: dias completos * (dias trabajados / dias totales periodo)
- Metodo por niveles: tramos de antiguedad (1-5 anos: 22 dias, 6-10: 25 dias, etc.)
- Redondeo: comercial, hacia arriba, hacia abajo (T556B)
- Transferencia de saldo ano anterior (reglas de caducidad)

## Reglas de Generacion (T556C)

### Configuracion de Generacion
- T556C — reglas de generacion de contingentes
- Vinculacion: tipo de contingente ↔ regla de generacion ↔ regla de recuento
- Momento de generacion: inicio de periodo, al tomar ausencia, periodicamente
- Programa RPTQTA00 — ejecucion de generacion masiva

### Tipos de Generacion
- **Generacion al inicio del ano** — carga completa el 1 de enero
- **Generacion acumulativa** — incremento mensual/trimestral
- **Generacion al vencimiento** — al cumplir requisito (ej. ano de servicio)
- **Generacion manual** — via IT2006 directamente

### Parametros de Generacion en T556C
- Regla de recuento base (T556C → T556E)
- Clase de generacion: automatica, manual, mixta
- Tolerancia para redondeado
- Validez del contingente generado (inicio/fin)

## Reglas de Deduccion (T556R)

### Configuracion de Deduccion
- T556R — reglas de deduccion de contingentes
- Vinculacion entre tipo de ausencia y tipo de contingente a deducir
- Prioridad de deduccion cuando hay multiples contingentes
- Deduccion parcial vs. deduccion total

### Logica de Deduccion
- Al registrar IT2001 (ausencia) → verificacion de contingente en IT2006
- Deduccion automatica del saldo disponible
- Gestion de saldo negativo (permitido/no permitido)
- Cola de deduccion: contingente mas antiguo primero

### Colisiones y Prioridades
- Verificacion de solapamiento con otros registros IT2001
- Prioridad entre tipos de ausencia coincidentes
- Reglas de resolucion de conflicto (T554C)
- Mensajes de warning vs. error en colision

## Resumen de Contingentes (PT_BAL00)

### Informe PT_BAL00
- Transaccion: PT_BAL00 o via SE38
- Muestra saldos de contingentes por empleado
- Parametros: periodo de validez, tipo de contingente, area de personal
- Salida: lista con saldo inicial, tomado, pendiente, caducado

### Otros Informes de Contingentes
- RPTABS20 — lista de ausencias por periodo
- RPTLEA40 — informe de baja por enfermedad
- RPTQTA10 — informacion de contingentes (detalle por empleado)
- PT50 — transaccion de resumen de tiempos (incluye contingentes)

## Infotipo IT2001 — Ausencias

### Estructura IT2001
- PERNR — numero de personal
- BEGDA/ENDDA — fecha inicio/fin ausencia
- AWART — tipo de ausencia
- ABWTG — dias de ausencia (calculados)
- STDAZ — horas de ausencia

### Registro de Ausencias
- Transaccion PA30 → IT2001
- Verificacion automatica de contingente disponible
- Calculo automatico de dias segun regla de recuento
- Creacion automatica de deduccion en IT2006

### Subtipos y Variantes
- Ausencias de dia completo vs. horas parciales
- Ausencias en multiples paises (grupos de pais)
- Ausencias retroactivas — impacto en nomina ya ejecutada
- Modificacion y cancelacion de ausencias

## Infotipo IT2006 — Contingentes de Ausencia

### Estructura IT2006
- KTART — tipo de contingente
- BEGDA/ENDDA — validez del contingente
- ANZHL — cantidad total del contingente
- REZAN — cantidad deducida (tomada)
- Saldo = ANZHL - REZAN (calculado dinamicamente)

### Gestion de Contingentes
- Transaccion PT60 o PA30 → IT2006
- Creacion manual de contingentes extraordinarios
- Ajuste manual de saldos (con autorizacion)
- Transferencia de saldo entre periodos de validez

### Caducidad de Contingentes
- Fecha fin de validez → saldo caducado automaticamente
- Reglas de caducidad en T556A
- Informe de contingentes por caducar (RPTQTA10)
- Transferencia parcial de saldo al nuevo periodo

## RPTQTA00 — Generacion de Contingentes

### Ejecucion
- Programa RPTQTA00 — generacion masiva de contingentes
- Transaccion PT_QTA00
- Parametros: fecha de generacion, tipo contingente, seleccion empleados
- Modo simulacion vs. actualizacion real

### Proceso de Generacion
1. Seleccion de empleados segun criterios
2. Lectura de regla de generacion (T556C)
3. Calculo de derecho segun T556B y antiguedad
4. Creacion/actualizacion de IT2006
5. Log de generacion con resultados por empleado

### Generacion Automatica en Nomina
- Integration con esquema de nomina (funcion QUOTA en time schema)
- Generacion durante evaluacion de tiempos
- Sincronizacion con ciclo de nomina mensual

## Reglas de Recuento (T556E / Counting Rules)

### Definicion
- T556E — reglas de recuento de dias de ausencia
- Determina como contar dias: calendario, laborables, segun horario
- Impacto en deduccion de contingente y en nomina

### Tipos de Recuento
- **Dias calendario** — todos los dias del periodo
- **Dias laborables** — segun horario de trabajo (IT0007)
- **Dias planificados** — segun turno/horario planificado
- **Horas** — cuando el contingente esta en horas

### Factores de Recuento
- Multiplicador para dias festivos dentro de ausencia
- Tratamiento de fines de semana
- Dias minimos y maximos por ausencia
- Redondeo de fracciones de dia

## Verificacion de Colisiones

### Tipos de Colision
- Dos ausencias en las mismas fechas (mismo empleado)
- Ausencia solapando con IT2003 (sustituciones)
- Ausencia solapando con IT2004 (disponibilidad)
- Ausencia solapando con IT0082 (ausencia adicional)

### Tabla T554C — Colisiones
- Definicion de pares de infotipos que pueden coexistir
- Accion ante colision: error, warning, override automatico
- Prioridad entre registros en conflicto

### Proceso de Validacion
- Verificacion al guardar IT2001
- Mensaje de error/warning en PA30
- Posibilidad de bypass con autorizacion especial (P_ORGIN_CON)

## Consultas MCP para Ausencias y Contingentes

```
-- Leer ausencias de un empleado en un periodo
ReadHrInfotype → IT2001, PERNR, BEGDA, ENDDA

-- Consultar saldo de contingentes actual
ReadHrInfotype → IT2006, PERNR con validez actual

-- Ver tipos de ausencia configurados
ReadTableEntries → T554S con MOABW y LGART

-- Verificar reglas de generacion de contingentes
ReadTableEntries → T556C (reglas de generacion)

-- Consultar reglas de deduccion
ReadTableEntries → T556R (tipos ausencia → contingente)

-- Ejecutar informe de saldos de contingentes
ExecuteReport → PT_BAL00 con seleccion de empleados

-- Generar contingentes masivamente (simulacion)
ExecuteReport → RPTQTA00 en modo test
```

### Tools MCP Relevantes
- `ReadHrInfotype` — IT2001, IT2006 (ausencias y contingentes)
- `ReadTableEntries` — T554S, T556A, T556B, T556C, T556R, T556E
- `ExecuteReport` — RPTQTA00, PT_BAL00, RPTABS20
- `SearchObject` — busqueda de programas de ausencias
- `GetFunctionGroup` — funciones de calculo de contingentes
