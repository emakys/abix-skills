# Migracion de Datos HCM

## Secuencia de Migracion Obligatoria

La carga de datos en HCM tiene dependencias estrictas. Cargar fuera de orden produce errores de referencia o datos inconsistentes.

### Fase 1 — Estructura Organizativa (OM)

Cargar primero los objetos de Gestion Organizativa (OM) antes que cualquier empleado:

```
1. O  — Unidades Organizativas     (cabecera del arbol)
2. O→O — Relaciones jerarquicas     (A002/B002)
3. C  — Cargos (Job)               (definicion generica)
4. S  — Posiciones                  (instancias especificas)
5. S→O — Relacion Posicion-Unidad  (A003/B003)
6. S→C — Relacion Posicion-Cargo   (A007/B007)
7. T  — Tipos de Trabajo (Task)    (opcional)
```

**Objetos OM y sus tablas:**

| Objeto | Tipo | Tabla principal |
|--------|------|-----------------|
| Unidad Org | O | HRP1000, HRP1001 |
| Cargo | C | HRP1000, HRP1001 |
| Posicion | S | HRP1000, HRP1001 |
| Persona | P | HRP1000, HRP1001 |
| Tipo Trabajo | T | HRP1000, HRP1001 |

**Relaciones clave en HRP1001:**

| Relacion | Significado |
|----------|-------------|
| A002 | Unidad Org reporta a Unidad Org superior |
| A003 | Posicion pertenece a Unidad Org |
| A007 | Posicion es descrita por Cargo |
| A008 | Posicion ocupada por empleado (Holder) |
| A012 | Posicion tiene tarea asignada |

### Fase 2 — Empleados (PA Infotipos)

Orden obligatorio de carga de infotipos por empleado:

```
0000 → Acciones           (tipo accion, status empleado — PRIMER infotipo obligatorio)
0001 → Asignacion Org     (EE Group, EE Subgroup, Area Personal, Subarea, Posicion)
0002 → Datos Personales   (nombre, fecha nacimiento, genero, estado civil)
0006 → Direcciones        (domicilio — subtipo 1)
0007 → Tiempo de Trabajo  (horario de trabajo planificado, jornada, grupo tiempo)
0008 → Retribucion Basica (clase retributiva, nivel, importe salario base)
0009 → Cuenta Bancaria    (banco, cuenta — para pago de nomina)
--- (a partir de aqui sin orden fijo, segun necesidad) ---
0014 → Conceptos Nomina Recurrentes
0015 → Pagos Adicionales
0021 → Familia/Personas de Referencia
0041 → Especificaciones de Fecha (fecha antiguedad, etc.)
0105 → Opciones de Comunicacion  (email corporativo, usuario sistema)
```

**Regla de oro:** El infotipo 0000 define el estado y tipo de accion del empleado. Sin el, no existe el numero de personal (PERNR) en el sistema.

---

## Herramientas de Migracion

### LSMW — Legacy System Migration Workbench

**Cuando usar LSMW:**
- Migraciones a sistemas SAP on-premise (ECC y S/4HANA)
- Requiere mapeo de campos con lógica de transformacion compleja
- Soporta batch input, BAPIs, IDocs y Direct Input

**Metodos recomendados para HCM en LSMW:**

| Metodo | Cuando usar |
|--------|-------------|
| Batch Input (BDC) | Transacciones PA30/PA40 — mas seguro para infotipos complejos |
| BAPI | `HR_INFOTYPE_OPERATION` — mas rapido, sin interfaz |
| Direct Input | Solo para cargas masivas de OM (programa RHALTD00) |

**Pasos LSMW:**
1. Crear proyecto / subproyecto / objeto
2. Definir fuente (estructura del archivo plano o Excel)
3. Mapear campos fuente → campos SAP
4. Definir reglas de conversion (fechas, codigos, etc.)
5. Leer datos, convertir, mostrar preview
6. Importar (batch input: SM35 para procesar; BAPI: ejecucion directa)

### Migration Cockpit (LTMC) — SAP S/4HANA

**Cuando usar LTMC:**
- Migraciones iniciales en proyectos S/4HANA nuevos (Greenfield)
- Usuarios funcionales sin conocimiento de LSMW
- Aprovecha plantillas predefinidas de SAP para HCM

**Objetos de migracion disponibles en LTMC para HCM:**

| Objeto LTMC | Infotipos que carga |
|-------------|---------------------|
| Employee | 0000, 0001, 0002 |
| Basic Pay | 0008 |
| Recurring Payments | 0014 |
| Additional Payments | 0015 |
| Bank Details | 0009 |
| Org Unit | HRP1000 (O) |
| Position | HRP1000 (S) |

**Limitacion LTMC:** No todos los infotipos tienen plantilla predefinida. Para infotipos sin plantilla, usar LSMW o BAPI.

**Pasos LTMC:**
1. Crear proyecto de migracion → seleccionar objetos
2. Descargar plantilla Excel por objeto
3. Rellenar plantilla con datos del cliente
4. Subir archivo → validar → simular → importar

---

## BAPI HR_INFOTYPE_OPERATION

El BAPI mas importante para carga programatica de infotipos de empleados.

### Firma

```abap
CALL FUNCTION 'HR_INFOTYPE_OPERATION'
  EXPORTING
    infty         = '0008'           " Numero de infotipo
    number        = lv_pernr         " PERNR del empleado
    subtype       = space            " Subtipo (si aplica)
    objectid      = space
    lockindicator = space
    validityend   = lv_endda         " Fecha fin (31.12.9999 = abierto)
    validitybegin = lv_begda         " Fecha inicio
    recordnumber  = space
    record        = ls_p0008         " Estructura del infotipo
    operation     = 'INS'            " INS / MOD / DEL / COP / LIS
    nocommit      = ' '              " X = no hacer COMMIT automatico
  IMPORTING
    return        = ls_return
  CHANGING
    innnn         = ls_p0008.        " Donde nnnn = numero infotipo (ej. in0008)
```

### Operaciones Disponibles

| Operacion | Descripcion |
|-----------|-------------|
| `INS` | Insertar nuevo registro |
| `MOD` | Modificar registro existente |
| `DEL` | Borrar registro |
| `COP` | Copiar registro |
| `LIS` | Listar registros (no es operacion de escritura) |

### Ejemplo — Carga Masiva de Infotipo 0008

```abap
REPORT zmig_infty0008.

DATA: ls_p0008  TYPE p0008,
      ls_return TYPE bapireturn1.

LOOP AT lt_empleados INTO ls_empleado.
  CLEAR ls_p0008.
  ls_p0008-begda = ls_empleado-fecha_inicio.
  ls_p0008-endda = '99991231'.
  ls_p0008-trfar = ls_empleado-clase_retributiva.
  ls_p0008-trfst = ls_empleado-nivel.
  ls_p0008-bet01 = ls_empleado-salario.
  ls_p0008-waers = 'EUR'.

  CALL FUNCTION 'HR_INFOTYPE_OPERATION'
    EXPORTING
      infty         = '0008'
      number        = ls_empleado-pernr
      validityend   = ls_p0008-endda
      validitybegin = ls_p0008-begda
      record        = ls_p0008
      operation     = 'INS'
      nocommit      = 'X'
    IMPORTING
      return        = ls_return
    CHANGING
      in0008        = ls_p0008.

  IF ls_return-type = 'E'.
    " Registrar error en log
    APPEND VALUE #( pernr   = ls_empleado-pernr
                    message = ls_return-message ) TO lt_errores.
  ELSE.
    COMMIT WORK.
  ENDIF.
ENDLOOP.
```

**Buenas practicas:**
- Usar `NOCOMMIT = 'X'` para hacer el COMMIT solo si todos los infotipos de un empleado cargaron correctamente (commit por empleado, no por infotipo)
- Manejar el `TIME_CONSTRAINT` del infotipo — INS puede rechazar si ya existe un registro en el mismo periodo (TC1)
- Comprobar `LS_RETURN-TYPE` (S=Success, E=Error, W=Warning)

---

## Carga Batch Input — RPLCO710

El programa **RPLCO710** (o su sucesor en S/4HANA) genera sesiones de batch input para la transaccion PA40 (Medidas de Personal).

**Cuando usar:**
- Contratacion masiva de empleados nuevos
- Cambios de accion masivos (reubicacion organizativa, cambio de condiciones)

**Parametros:**
- Archivo de entrada: Formato delimitado por tabuladores o longitud fija
- Tipo de accion: Contratacion (01), Reingreso (40), Cambio Organizativo (32), etc.
- Fecha de accion: Fecha de efectividad de la medida

**Procesamiento:**
1. Ejecutar RPLCO710 → genera sesion BDC en SM35
2. SM35 → procesar sesion en modo visible (test) o background
3. Revisar log de sesion para errores

---

## Validaciones Clave Pre-Carga

Antes de iniciar la carga de empleados, verificar que existan en sistema:

### Validaciones de Customizing

| Objeto | Tabla | Transaccion verificacion |
|--------|-------|--------------------------|
| Area de Personal | T500P | PE03 / SM30 |
| Subarea de Personal | T500P + T001P | SPRO |
| Grupo de Empleados | T501 | SPRO |
| Subgrupo de Empleados | T503K | SPRO |
| Clase Retributiva | T510 | SPRO |
| Nivel Retributivo | T510N | SPRO |
| Horario de Trabajo | T508A | PT01 |
| Regla Agrupacion Tiempo | T508 | SPRO |

### Validaciones de Datos Maestros

```
[ ] Todas las Unidades Organizativas existen en OM (infotipo 1000 activo)
[ ] Todas las Posiciones existen en OM y tienen relacion con Unidad Org
[ ] Posiciones no superan la cantidad de vacantes autorizadas
[ ] Clases retributivas son validas para el area/subarea de personal del empleado
[ ] Niveles retributivos existen dentro de las clases retributivas
[ ] Bancos existen en FI (tabla BNKA) si se cargan datos bancarios
[ ] Tipos de accion (Infotipo 0000) configurados en tabla T529A
[ ] Status de accion (infotipo 0000) configurados en T529U
```

### Script de Validacion Previo

```abap
" Verificar que la posicion existe y esta vacante
SELECT SINGLE objid FROM hrp1000
  WHERE otype = 'S'
    AND istat = 1        " Objeto activo
    AND plvar = '01'
    AND begda <= sy-datum
    AND endda >= sy-datum
    AND objid = lv_posicion
  INTO @DATA(lv_existe).

IF sy-subrc <> 0.
  " Error: Posicion no existe o no esta activa
ENDIF.
```

---

## Post-Migracion — Verificaciones Obligatorias

### 1. Simulacion de Nomina

Ejecutar simulacion de nomina (PC00_Mxx_CALC_SIMU, donde xx = pais) para el primer periodo:
- Verificar que todos los empleados migrados entran al calculo
- Revisar log de nomina en PE51 por errores sistematicos
- Comparar importes de nomina contra sistema origen (tolerancia < 1%)

### 2. Verificacion de Headcount

```
Headcount en sistema origen = N empleados activos en fecha de corte
Headcount en SAP (PA20/PA30):
  - Report RPLCO000 (lista de empleados por area)
  - Report H99CWTR0 (count por grupo/subgrupo)
  - S_PH9_46000172 (Ad Hoc Query personalizada)
```

Tolerancia aceptable: 0 diferencias (todos los empleados deben estar).

### 3. Revision del Organigrama

- Transaccion PPOME / PPOCE: Visualizar organigrama cargado
- Verificar jerarquia completa (sin unidades huerfanas)
- Verificar que empleados aparecen en la posicion correcta (Holder — relacion A008)
- Comparar con organigrama del sistema origen

### 4. Verificacion de Autorizaciones

- Ejecutar SU53 con usuario de RRHH para verificar que puede acceder a empleados de su area
- Comprobar perfiles P_ORGIN, P_ORGINCON, P_PERNR activos
- Verificar acceso a infotipos especificos (tabla T582A)

---

## Plan de Cutover HCM

### Cronograma Tipico (Proyecto Go-Live)

```
T - 4 semanas:  Carga completa de OM (Org, Posiciones, Cargos)
T - 3 semanas:  Carga de empleados (datos historicos si aplica)
T - 2 semanas:  Carga de infotipos de tiempo (ausencias historicas para acumulados)
T - 1 semana:   Ciclo de nomina paralela: sistema origen vs SAP
T - 3 dias:     Correccion de diferencias de nomina paralela
T - 1 dia:      Freeze en sistema origen. Ultima sincronizacion de altas/bajas/cambios
T             : Go-Live. Primer nomina en SAP es la real.
T + 1 semana:  Soporte intensivo. Resolver incidencias de primer cierre.
```

### Checklist de Cutover

```
[ ] Nomina paralela ejecutada con diferencias < 1%
[ ] Todos los empleados activos cargados con infotipos 0000-0009
[ ] Acumulados de nomina cargados (infotipo 0011 o via cargas especiales)
[ ] Balances de tiempo cargados (infotipo 2006/2007 para vacaciones)
[ ] Usuarios de RRHH con acceso correcto verificados
[ ] Procesos de alta/baja documentados para el equipo
[ ] Formularios de autorizacion de nomina actualizados
[ ] Contacto de soporte SAP activado para el dia de go-live
[ ] Plan de rollback documentado (solo para primeros 2 dias)
```
