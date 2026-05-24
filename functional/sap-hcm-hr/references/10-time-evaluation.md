# Evaluacion de Tiempos

## Esquemas de Evaluacion de Tiempos

### Esquemas Principales
- **TM00** — Esquema estandar para evaluacion de tiempos con registro de entradas/salidas
- **TM04** — Esquema para tiempos sin registro de terminales (solo ausencias/asistencias)
- Subschemas: TM01 (evaluacion diaria), TM02 (saldo mensual), TM03 (horas extras)
- Configuracion en T500L (esquemas de evaluacion)

### Personalizacion de Esquemas
- Transaccion PE01 — editor de esquemas de evaluacion
- Reglas de calculo (PE02) — logica de evaluacion por dia
- Funciones y operaciones de tiempo: TIMTP, CUMBT, ACTIO, GEN, PVHLT

## Tipos de Tiempos (Time Types)

### Definicion y Estructura
- Tipos de tiempo = acumuladores (balances) para resultados intermedios
- Configuracion en T555A (tipos de tiempo)
- Ejemplos: 0001 Tiempo de presencia, 0005 Horas extras, 0010 Ausencias planificadas
- Agrupacion por moschema (T555Z)

### Balances Principales
- Saldo de horas trabajadas vs. planificadas
- Balance de horas extras acumuladas
- Saldo de contingentes de ausencia restantes
- Horas nocturnas y en fin de semana

## Generacion de Pares de Tiempos

### Proceso de Formacion de Pares
- Registros IT2011 (entrada/salida) → pares de tiempo
- Funcion PPAIR — genera pares desde registros de terminal
- Funcion PTIP — evalua pares contra turno planificado
- Tolerancias de redondeo configurables (T508A)

### Evaluacion contra Turno
- Comparacion con horario diario planificado (IT0007)
- Calculo de diferencias: llegadas tarde, salidas anticipadas
- Tiempos de pausa automaticos (T550P)
- Reglas de redondeo de tiempo (T508A, T508B)

## Calculo de Horas Extras

### Reglas de Horas Extras
- Definicion de umbrales: diario, semanal, mensual
- Funcion QUOTA — verificacion de contingentes
- Funcion HRS — procesamiento de horas
- Tipos de salario de tiempo (Time Wage Types) para pago adicional

### Autorizacion de Horas Extras
- IT2005 Horas extras — registro manual de autorizacion
- Campos: fecha, horas autorizadas, tipo de compensacion
- Compensacion en tiempo libre vs. pago monetario
- Integracion con nomina via tipos de salario

## Primas Nocturnas y de Fin de Semana

### Configuracion de Primas
- T510S — definicion de tipos de prima
- Reglas de evaluacion de tiempo nocturno (22:00-06:00 tipico)
- Primas de fin de semana (sabado/domingo diferenciadas)
- Primas en festivos (calendario factoria T513S)

### Generacion de Tipos de Salario de Tiempo
- Funcion TPROG — genera tipos de salario desde tipos de tiempo
- T510J — tabla de generacion de tipos de salario
- Transferencia a nomina: cluster PC (resultados de nomina)
- IT2010 tipos de salario de tiempo — override manual

## Tipos de Salario de Tiempo (Time Wage Types)

### Estructura
- Nomenclatura: /0xx series para tiempo
- T512W — definicion de tipos de salario
- Caracteristicas TARIF, LGMST — valoracion tarifaria
- Clases de procesamiento para nomina (Abrechungsklassen)

### Generacion Automatica
- Desde esquema de evaluacion → cluster B2 (tipos de salario)
- Regla de generacion en PE02
- Tipos de salario de horas extras: /0OT, /0OW, etc.
- Transferencia a WPBP para valoracion en nomina

## Infotipos Clave de Tiempo

### IT2005 — Horas Extras
- Subtipos por tipo de compensacion (pago/tiempo libre)
- Campos: fecha inicio/fin, horas, razon
- Autorizacion previa o posterior al hecho
- Validacion contra turno planificado

### IT2006 — Contingentes de Ausencia
- Saldo disponible por tipo de contingente
- Campos: tipo contingente, validez, saldo, deducido
- Generacion automatica via RPTQTA00
- Transferencia desde evaluacion de tiempos

### IT2007 — Contingentes de Asistencia
- Registro de contingentes positivos (horas banco)
- Subtipos por tipo de contingente de asistencia
- Compensacion de horas extras como banco de horas
- Deduccion via absencias posteriores

## Cluster B1 — Resultados de Evaluacion de Tiempos

### Estructura del Cluster
- Almacenamiento en PCL1 (base datos cluster tiempo)
- Tablas internas: ZES (pares), ZL (tipos de salario), C1 (tipos de tiempo)
- Acceso via IMPORT FROM DATABASE PCL1(B1)
- Informe RPCLSTB1 — visualizacion de cluster B1

### Contenido Principal
- ZES — pares de tiempo evaluados con estado
- ZL — tipos de salario de tiempo generados
- SALDO — saldos de tipos de tiempo al final de periodo
- FEHLER — errores de evaluacion

## Informe RPTIME00

### Ejecucion de Evaluacion de Tiempos
- Transaccion PT60 — evaluacion de tiempos (online)
- RPTIME00 — programa batch de evaluacion
- Parametros: periodo, esquema, modo (simulacion/real)
- Procesamiento paralelo por area de personal

### Parametros Importantes
- Forzar re-evaluacion de periodos anteriores
- Evaluacion en segundo plano para grandes volumenes
- Log de mensajes: informativo, advertencia, error
- Integracion con nomina (bloqueo de periodos)

## Log de Errores TEVEN

### Tabla TEVEN — Errores de Evaluacion
- Registro de errores por empleado y fecha
- Tipos de error: datos faltantes, colisiones, inconsistencias
- Transaccion PT_ERL00 — lista de errores de evaluacion
- Correcion de errores → re-evaluacion necesaria

### Errores Comunes
- Turno no encontrado para dia evaluado
- Par de tiempo sin cierre (entrada sin salida)
- Tipo de tiempo no configurado en esquema
- Contingente agotado para deduccion

## Integracion con Terminales de Registro

### Subsistema de Comunicacion de Datos (BDE)
- Interfaz con terminales de tiempo (Siemens, Kaba, etc.)
- Funcion CC1 — procesamiento de datos de terminal
- IT2011 — registro de entradas/salidas desde terminal
- RPTEDT00 — transferencia de datos de terminales

### Proceso de Transferencia
- Lectura de datos brutos desde terminal
- Validacion y conversion a IT2011
- Manejo de errores de comunicacion
- Confirmacion de transferencia exitosa

## Consultas MCP para Evaluacion de Tiempos

```
-- Leer infotipo de horas extras de un empleado
GetObjectSource → IT2005 para PERNR especifico

-- Verificar resultados cluster B1
ReadTableEntries → PCL1 con RELID='B1', SRTFD=PERNR+PERIOD

-- Consultar errores de evaluacion
ReadTableEntries → TEVEN con PERNR y EVDATE

-- Ver tipos de tiempo configurados
ReadTableEntries → T555A con MOABW (moschema)

-- Contingentes de asistencia actuales
ReadTableEntries → T556A para tipo contingente

-- Log de evaluacion tiempo real
ExecuteReport → RPTIME00 con parametros periodo
```

### Tools MCP Relevantes
- `ReadHrInfotype` — lectura de infotipos HR (IT2005, IT2007, IT2011)
- `ReadTableEntries` — consulta tablas customizing (T555A, T510J, TEVEN)
- `ExecuteReport` — ejecucion de RPTIME00, PT_BAL00
- `GetObjectSource` — codigo fuente de reglas PE02
- `SearchObject` — busqueda de esquemas TM00/TM04
