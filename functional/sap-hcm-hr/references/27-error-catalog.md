# Catalogo de Errores HCM

## Indice por Submodulo

- [Errores de Administracion de Personal (PA)](#errores-pa)
- [Errores de Gestion Organizativa (OM)](#errores-om)
- [Errores de Gestion de Tiempos (TM)](#errores-tm)
- [Errores de Nomina (PY)](#errores-py)
- [Errores de Beneficios (BEN)](#errores-ben)
- [Errores de Autorizaciones (HR Auth)](#errores-auth)

---

## Errores PA — Administracion de Personal {#errores-pa}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 1 | PG | 005 | El empleado &1 no existe en la fecha &2 | El PERNR no tiene ningun infotipo activo en esa fecha (posiblemente dato historico) | Verificar fechas de vigencia en PA20. Comprobar infotipo 0000 activo. | PA20 |
| 2 | PG | 057 | No esta permitida la operacion &1 para el tipo de objeto &2 | Se intenta operar sobre un infotipo que no esta configurado para ese objeto | Verificar T582A (infotipos permitidos por subarea de personal) | SPRO > Gestion Personal > Administracion > Infotipos > Infotipos por subarea |
| 3 | PA | 101 | Datos de tiempo de trabajo no encontrados para el empleado | Infotipo 0007 (Tiempo de Trabajo) sin registro valido en el periodo | Crear/extender infotipo 0007 en PA30. Verificar que el horario existe en T508A. | PA30, PT01 |
| 4 | PA | 309 | El area de nomina no permite calculo para el periodo indicado | El area de nomina tiene el periodo cerrado o bloqueado | Verificar estado del periodo en PA03. Reabrir periodo si es necesario. | PA03 |
| 5 | PA | 201 | La clase retributiva &1 no es valida para el area/subarea &2/&3 | La clase retributiva no esta asignada al grupo de empleados/subgrupo correcto | SPRO: Administracion de Retribuciones > Asignacion de tablas de retribucion | SPRO |
| 6 | PA | 134 | El numero de personal &1 ya existe | Intento de crear PERNR que ya existe (carga duplicada) | Verificar con PA20 si el empleado ya existe. Limpiar carga duplicada. | PA20 |
| 7 | PA | 417 | Constraint de tiempo violado en infotipo &1 | Se intenta insertar registro que se solapa con uno existente (TC1 o TC2) | En PA30, usar modo de modificacion. Borrar registro anterior si es incorrecto. | PA30 |
| 8 | PG | 111 | El grupo de empleados &1 no existe | El EE Group del infotipo 0001 no esta customizado | Crear grupo de empleados en T501 o corregir dato de carga. | SPRO > Gestion Personal > Administracion > Datos Organizativos > Grupo de empleados |
| 9 | PG | 112 | El subgrupo de empleados &1/&2 no existe | EE Subgroup no existe o no esta asignado al grupo correcto | Verificar T503K y la asignacion grupo/subgrupo. | SPRO > Gestion Personal > Subgrupo de empleados |
| 10 | PA | 512 | No se puede borrar el infotipo &1 porque tiene registros dependientes | El infotipo tiene relaciones con otros objetos (ej. 0001 tiene posicion ocupada en OM) | Desligar primero las dependencias (liberar posicion en OM, borrar infotipos dependientes). | PPOME, PA30 |

---

## Errores OM — Gestion Organizativa {#errores-om}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 11 | HR | 300 | El objeto &1 &2 no existe | Objeto OM (O, S, C, P) no existe o fecha fuera de vigencia | Verificar en PPOME o con tabla HRP1000. Crear objeto si falta. | PPOME, PO10 (O), PO13 (S) |
| 12 | PP | 001 | La posicion &1 ya esta ocupada | Intento de asignar empleado a posicion ya ocupada (relacion A008) | Verificar ocupacion en PPOME. Liberar posicion o usar otra. | PPOME |
| 13 | HR | 301 | La relacion &1 entre objetos &2 y &3 no es permitida | Tipo de relacion invalida entre los tipos de objeto | Verificar tabla T778V (relaciones permitidas por tipo de objeto). | SPRO > Gestion Organizativa > Relaciones |
| 14 | HR | 350 | El plan organizativo &1 no existe | Plan de organization (PLVAR) referenciado no existe | Verificar T77S0 (parametro PLOGI PLVAR) y que exista en T770. | SPRO > Gestion Organizativa > Estructura > Plan de organizacion |
| 15 | HR | 355 | Bucle detectado en la jerarquia de unidades organizativas | Unidad Org apunta a si misma o crea ciclo en el arbol | Corregir relacion A002 con PPOME para romper el ciclo. | PPOME |
| 16 | PP | 012 | La vacante de la posicion &1 esta cerrada | La posicion tiene flag de vacante = NO | Abrir vacante en infotipo 1007 de la posicion (PO13 > Infotipo 1007). | PO13 |
| 17 | HR | 320 | Fecha de inicio &1 anterior a la fecha de validez del objeto | Intento de crear relacion con fecha anterior a la creacion del objeto OM | Ajustar fecha de inicio de la relacion o cambiar la fecha de inicio del objeto. | PPOME |

---

## Errores TM — Gestion de Tiempos {#errores-tm}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 18 | PT | 001 | No existe un horario de trabajo para el empleado &1 en &2 | Infotipo 0007 sin registro o horario asignado incorrecto | Crear/corregir infotipo 0007. Verificar que el horario existe en T508A. | PA30, PT01 |
| 19 | PT | 205 | El tipo de ausencia &1 no esta permitido para el subgrupo &2 | Tipo de ausencia no configurado para el grupo/subgrupo de empleados | SPRO: Permisos de ausencia por agrupacion de empleados (T554C). | SPRO > Gestion de Tiempos > Ausencias > Permisos de ausencia |
| 20 | PT | 415 | La ausencia supera el balance disponible de &1 dias | El empleado no tiene saldo suficiente de vacaciones (infotipo 2006) | Verificar saldo en infotipo 2006. Ajustar si es necesario con autorizacion de RRHH. | PA30 (IT2006) |
| 21 | PT | 032 | El registro de tiempo &1 se solapa con el infotipo &2 | Registro de tiempo duplicado o solapado en el mismo periodo | Borrar o ajustar el registro conflictivo en PA30/CAT2. | PA30, CAT2 |
| 22 | PT | 301 | El grupo de cuotas de ausencia &1 no existe | Tabla de cuotas de ausencia no configurada para el agrupacion | SPRO: Cuotas de ausencia > Tipos de cuota > Definir grupos. | SPRO > Gestion de Tiempos > Cuotas de ausencia |
| 23 | PT | 510 | Error en esquema de evaluacion de tiempos &1 | El esquema TM (PE01) tiene un error de configuracion o PCR invalida | Revisar log de evaluacion de tiempos (PT60 log). Verificar esquema en PE01. | PE01, PT60 |
| 24 | PT | 604 | El periodo de calculo de tiempos &1 esta cerrado | El periodo de tiempos ya fue cerrado para calculo | Reabrir periodo en administracion de periodos si es justificado, o registrar ajuste manual. | PT66 |

---

## Errores PY — Nomina {#errores-py}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 25 | PY | 019 | El empleado &1 no tiene concepto de nomina &2 | El wagetipe requerido no esta generado para el empleado en el calculo | Verificar asignacion de wagetype en infotipo 0008/0014/0015. Revisar PCR de calculo. | PE02, PA30 |
| 26 | PY | 089 | Error en la funcion de esquema &1, regla &2: &3 | Error de configuracion en PCR de nomina (division por cero, valor nulo, etc.) | Activar log de nomina (PE51). Reproducir con simulacion empleado especifico. Revisar PE02. | PE01, PE02, PE51 |
| 27 | PY | 110 | El area de nomina &1 no tiene periodo de nomina abierto | No se ha abierto el periodo corriente de nomina | Ir a PA03: abrir siguiente periodo para el area de nomina. | PA03 |
| 28 | RP | 001 | El programa de nomina &1 no puede ejecutarse en modo real — existen errores | Existen empleados en estado de error de la corrida anterior sin resolver | Resolver errores en PE51 individualmente. Luego reejecutar. | PC00_Mxx_CALC, PE51 |
| 29 | PY | 045 | No existen datos de retribucion para el empleado &1 en el periodo &2 | Infotipo 0008 sin registro activo en el periodo de nomina | Crear registro IT0008 para el periodo en cuestion. Verificar fechas de vigencia. | PA30 |
| 30 | PY | 201 | La cuenta contable &1 no esta asignada para el concepto de nomina &2 | Falta asignacion de cuenta GL para el wagetype en el customizing FI-PY | SPRO: Nomina > Integracion con FI > Asignacion de cuentas por simbolo de cuenta. | SPRO |
| 31 | PY | 167 | El resultado de nomina del empleado &1 no puede retroactarse — excede limite | El empleado tiene retroactividad que supera el limite configurado | Verificar limite de retroactividad en T549R. Ampliar limite o tramitar ajuste manual. | T549R |
| 32 | PY | 302 | Datos bancarios no encontrados para el empleado &1 | Infotipo 0009 sin registro activo | Crear infotipo 0009 con los datos bancarios del empleado. | PA30 (IT0009) |
| 33 | PY | 510 | Error de posting FI: documento contable no generado para el periodo &1 | Periodo contable cerrado en FI o error de asignacion de cuenta | Verificar periodo FI en OB52. Revisar log de posting (PC00_Mxx_CIPE). | OB52, PC00_Mxx_CIPE |
| 34 | PY | 088 | Valor de base de calculo de impuesto negativo para empleado &1 | Descuentos superan ingresos brutos — base imponible negativa | Revisar conceptos de nomina del empleado. Verificar conceptos de deduccion. | PE51 (log nomina), PA30 |

---

## Errores BEN — Beneficios {#errores-ben}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 35 | HRBEN | 001 | El empleado &1 no es elegible para el plan de beneficios &2 | Reglas de elegibilidad no satisfechas (agrupacion, tipo emp., etc.) | Verificar reglas de elegibilidad en SPRO > Beneficios > Elegibilidad. Comprobar BAdI HRBEN00_ELIGY. | SPRO > Beneficios |
| 36 | HRBEN | 045 | Periodo de inscripcion &1 cerrado | Intento de inscribir fuera del periodo de open enrollment | Verificar fechas del periodo de inscripcion. Solo RRHH puede inscribir fuera del periodo. | HRBEN_ENROLL |
| 37 | HRBEN | 102 | Cobertura del plan &1 supera el maximo permitido | El importe de cobertura seleccionado excede el limite del plan | Verificar tabla de opciones de cobertura en customizing del plan. | SPRO > Beneficios > Planes |

---

## Errores Auth — Autorizaciones HR {#errores-auth}

| # | Clase | Num | Texto del Mensaje | Causa Tipica | Resolucion | SPRO / TX |
|---|-------|-----|-------------------|--------------|------------|-----------|
| 38 | HR | 001 | No esta autorizado para el infotipo &1, subtipo &2 | Objeto de autorizacion P_ORGIN o P_ORGINCON sin el infotipo necesario | Agregar infotipo al perfil en SU01/PFCG. Verificar con SU53 que objeto falta. | SU53, PFCG |
| 39 | HR | 002 | No esta autorizado para el empleado &1 | El empleado pertenece a un area de personal o unidad org fuera del perimetro del usuario | Ampliar perimetro organizativo en objeto P_ORGIN (VDSK1 / PERSA / BTRTL). | PFCG (objeto P_ORGIN) |
| 40 | HR | 003 | Acceso denegado al dato de nomina — nivel de sensibilidad &1 | El infotipo tiene nivel de sensibilidad y el usuario no tiene el nivel requerido | Asignar nivel de sensibilidad correcto en objeto P_NNNNN en perfil. | PFCG |

---

## Guia de Diagnostico Rapido

### Flujo para Errores de Nomina

```
Error en PC00_Mxx_CALC
        │
        ▼
Ir a PE51 (log de nomina individual)
        │
        ├── Error en funcion/regla → PE01/PE02 (esquema/PCR)
        ├── Dato maestro faltante → PA30 (infotipo del empleado)
        ├── Customizing incompleto → SPRO (segun texto del error)
        └── Error FI → OB52 (periodo) / SPRO (asignacion de cuentas)
```

### Flujo para Errores de Infotipo en PA30

```
Error al grabar infotipo
        │
        ├── "No autorizado" → SU53 → PFCG
        ├── "Constraint de tiempo" → Verificar registros existentes, ajustar fechas
        ├── "Valor no existe" → Verificar tablas de customizing (T5xx)
        └── "Posicion ocupada" → PPOME (liberar o reasignar posicion)
```

### Codigos de Retorno BAPI HR_INFOTYPE_OPERATION

| TYPE | Significado | Accion |
|------|-------------|--------|
| S | Success | Continuar, hacer COMMIT |
| W | Warning | Evaluar mensaje, posiblemente continuar |
| E | Error | NO hacer COMMIT. Registrar en log de errores. |
| I | Information | Ignorar o registrar en log informativo |

### Transacciones de Diagnostico HCM

| TX | Uso |
|----|-----|
| PE51 | Log de nomina — ver detalle de calculo por empleado |
| PT60 | Log de evaluacion de tiempos |
| SU53 | Ultimo fallo de autorizacion del usuario actual |
| SM13 | Actualizaciones pendientes (registros en modo update) |
| PA20 | Visualizar infotipos de empleado (sin cambios) |
| PPOME | Visualizar y editar estructura organizativa |
| PA03 | Administracion de areas de nomina (periodos, estado) |
| SE16N | Visualizar tablas HCM directamente (PA0001, HRP1000, etc.) |
| PE04 | Operaciones y funciones de nomina (documentacion interna) |
