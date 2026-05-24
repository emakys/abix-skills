# Acciones de Personal

## Que es una Accion de Personal

Una accion de personal (Personnel Action) es un evento que modifica el estado o datos de un empleado de forma coordinada, actualizando multiples infotipos en una secuencia predefinida. Se ejecutan desde la transaccion PA40 y generan un registro en IT0000.

## Tipos de Accion Estandar (Tabla T588M)

### Acciones Principales

| Codigo | Tipo de Accion | Descripcion | IT0000-MASSN |
|--------|----------------|-------------|--------------|
| 01 | Hiring (Contratacion) | Alta de nuevo empleado | 01 |
| 02 | Organizational Change | Cambio de posicion/departamento | 02 |
| 03 | Leaving (Baja) | Salida del empleado | 03 |
| 04 | Reentry (Reingreso) | Vuelta de un empleado dado de baja | 04 |
| 05 | Retirement (Jubilacion) | Jubilacion del empleado | 05 |
| 06 | Data Change | Cambio de datos maestros | 06 |
| 07 | Pay Scale Change | Cambio de nivel salarial | 07 |
| 08 | Transfer (Traslado) | Cambio de area de personal o sociedad | 08 |
| 09 | Maternity/Paternity Leave | Excedencia por maternidad/paternidad | 09 |
| 12 | Leave of Absence | Excedencia voluntaria | 12 |
| 22 | Temporary Assignment | Asignacion temporal | 22 |

### Estados de Empleado tras la Accion (PA0000-STAT2)
- 0: Inactivo (nunca activo, pendiente de inicio)
- 1: Retirado / Jubilado
- 2: Salida (baja activa)
- 3: Activo (estado normal de trabajo)

## Transaccion PA40 — Proceso de Ejecucion

### Flujo de Ejecucion PA40
```
1. Entrar PA40
   ├── Introducir numero de empleado (PERNR) o dejar en blanco para crear nuevo
   ├── Seleccionar tipo de accion (MASSN) de la lista disponible
   └── Introducir fecha de inicio de la accion

2. SAP determina el infogrupo asignado a la accion (T588M → T588Z)

3. Presentar infotipos en secuencia definida
   ├── IT0000 — Accion (siempre primero, automatico)
   ├── IT0001 — Asignacion Organizativa
   ├── IT0002 — Datos Personales (solo en alta)
   ├── IT0006 — Direccion (solo en alta)
   ├── ... (segun customizing del infogrupo)
   └── Confirmacion final

4. SAP graba todos los infotipos de forma atomica
   └── Si hay error en cualquier infotipo → rollback de todos
```

### Numero de Personal en Alta
- Asignacion interna: PA40 asigna PERNR automaticamente (rango definido en T750X)
- Asignacion externa: el usuario introduce el PERNR manualmente
- Rango de numeros: tabla T750X, tipo de numero HRNUMBER

## Customizing de Acciones

### Tabla T588M — Tipos de Accion
Ruta SPRO: Gestion de Personal → Administracion de Personal → Procedimientos de Accion → Definir tipos de accion

Campos clave de T588M:
- MASSN: Codigo de tipo de accion (ej. '01')
- MTEXT: Descripcion del tipo
- MASSG: Motivos de accion permitidos (via tabla T530)
- STATV: Estado antes de la accion (STAT2 esperado)
- STATU: Estado despues de la accion (STAT2 resultante)
- IGMOD: Infogrupo asignado (clave a T588Z)

### Tabla T530 — Motivos de Accion (Reasons for Actions)
- Cada tipo de accion tiene uno o varios motivos posibles
- Campo IT0000-MASSG contiene el motivo seleccionado
- Ejemplos para tipo 03 (Baja):
  - 01: Despido procedente
  - 02: Dimision voluntaria
  - 03: Fin de contrato temporal
  - 10: Jubilacion anticipada

### Tabla T588Z — Infotipos por Accion (Menu Rapido / Infogroup)
Ruta SPRO: Definir infogrupos

Esta tabla define QUE infotipos se presentan en PA40 y en QUE ORDEN para cada accion:
- IGMOD: Codigo del infogrupo (vinculado desde T588M)
- INFTY: Numero de infotipo a presentar
- SUBTY: Subtipo obligatorio (si aplica, sino blanco)
- DISP: Indicador de presentacion:
  - ' ': Presentar siempre
  - 'P': Presentar solo si existe registro previo
  - 'N': No presentar (oculto pero procesado)
- SPRSL: Idioma

Ejemplo de infogrupo para accion 01 (Contratacion):
```
IGMOD | INFTY | Descripcion           | DISP
------+-------+-----------------------+------
HI001 | 0000  | Acciones              | (auto)
HI001 | 0001  | Asignacion Org.       | obligatorio
HI001 | 0002  | Datos Personales      | obligatorio
HI001 | 0006  | Direccion             | obligatorio
HI001 | 0007  | Tiempo Trabajo Prev.  | obligatorio
HI001 | 0008  | Retribucion Basica    | obligatorio
HI001 | 0009  | Cuenta Bancaria       | P
HI001 | 0016  | Contrato              | obligatorio
HI001 | 0105  | Comunicacion (email)  | P
```

## Features de Nomina para Acciones

### Feature MASSN — Tipo de Accion por Defecto
- Determina el tipo de accion que aparece preseleccionado en PA40
- Estructura del arbol de decision: MOLGA → PERSG → PERSK → valor MASSN
- Se edita con transaccion PE03
- Nombre del feature: MASSN

### Feature MASSG — Motivo de Accion por Defecto
- Determina el motivo de accion preseleccionado
- Misma estructura de arbol que MASSN
- Util para empresas con un motivo de baja predominante
- Nombre del feature: MASSG

### Como Editar un Feature (PE03)
```
1. PE03 → introducir nombre del feature (ej. MASSN)
2. Editar → arbol de decision con condiciones
3. Ramas: IF MOLGA = '04' (Espana) → valor = '01' (alta)
4. Activar el feature tras modificar
5. Verificar con F5 (Test del feature) introduciendo valores de prueba
```

## Infogrupos — Detalle Tecnico

### Concepto
Un infogrupo (Infogroup) es una secuencia ordenada de infotipos asociada a una accion. Permite que al ejecutar PA40, SAP presente los infotipos necesarios en el orden correcto.

### Asignacion Accion → Infogrupo
```
T588M (Accion: MASSN='01') → campo IGMOD → T588Z (Infogrupo: secuencia de infotipos)
```

### Infogrupos por Pais
SAP entrega infogrupos estandar con prefijo del MOLGA:
- Alemania: D* (ej. D101 para contratacion alemana)
- Espana: E* o configuracion de cliente
- Internacional: P* o I*

### Agregar Infotipo a una Accion Existente
```
SPRO → Gestion de Personal → Administracion de Personal
     → Procedimientos de Accion → Definir infogrupos
     → Seleccionar infogrupo de la accion
     → Insertar nueva linea con el infotipo, subtipo y secuencia
```

## Acciones Especiales

### Accion de Cambio Organizativo (02)
Afecta principalmente IT0001. Campos tipicamente modificados:
- Nuevo ORGEH (unidad organizativa)
- Nueva PLANS (posicion)
- Nuevo KOSTL (centro de coste)
- Puede implicar cambio de WERKS, BTRTL, PERSK si hay diferencia contractual

### Accion de Baja (03)
- Cambia STAT2 de IT0000 a '2' (Salida)
- IT0001 se delimita a la fecha de baja
- Fecha de baja = ultimo dia de trabajo o dia siguiente segun customizing
- Genera infotipo IT0000 con MASSN='03' y MASSG=motivo de baja
- Nomina del mes de baja se calcula parcialmente (pro-rata via feature ABKRS)

### Accion de Reingreso (04)
- Requiere que el empleado exista con STAT2 = '2' (Salida)
- Reabre el PERNR con nuevos registros de infotipo
- Historial anterior se conserva (registros cerrados por ENDDA)
- Nuevo numero de contrato puede asignarse en IT0016

## Programas ABAP Relacionados con Acciones

| Programa | Descripcion |
|----------|-------------|
| RPAACT00 | Listado de acciones de personal (informe) |
| RPUCHECK | Verificacion de consistencia de datos maestros |
| RPITRF00 | Transferencia masiva de empleados entre areas |
| RPCALC00 | Calculo de nomina (usa datos de acciones para limites de periodo) |

## Queries MCP para Acciones y Customizing

### Leer todos los tipos de accion configurados
```
Tool: ReadTable
Tabla: T588M
Campos: MASSN, MTEXT, STATV, STATU, IGMOD
Sin filtro o filtrar por SPRSL = 'S' (idioma espanol)
```

### Leer motivos de accion disponibles para un tipo
```
Tool: ReadTable
Tabla: T530
Campos: MASSN, MASSG, MGTXT
Filtro: MASSN = '03' (ej. motivos de baja)
```

### Leer infotipos de un infogrupo (secuencia de accion)
```
Tool: ReadTable
Tabla: T588Z
Campos: IGMOD, INFTY, SUBTY, DISP
Filtro: IGMOD = '<codigo_infogrupo>'
Ordenar: INFTY ASC
```

### Consultar historial de acciones de un empleado
```
Tool: ReadTable
Tabla: PA0000
Campos: PERNR, MASSN, MASSG, BEGDA, ENDDA, STAT2
Filtro: PERNR = '<numero_empleado>'
Ordenar: BEGDA DESC
```

### Consultar todas las bajas en un periodo
```
Tool: ReadTable
Tabla: PA0000
Campos: PERNR, MASSN, MASSG, BEGDA
Filtro: MASSN = '03' AND BEGDA BETWEEN '<fecha_inicio>' AND '<fecha_fin>'
```

### Verificar feature MASSN/MASSG
```
Tool: ReadTable
Tabla: T549D (valores de features compilados)
Campos: FMLA, MOLGA, PERSG, PERSK, RESLT
Filtro: FMLA = 'MASSN'
Nota: mejor usar PE03 para visualizacion grafica del arbol
```

### Contar empleados activos por area de personal
```
Tool: ReadTable
Tabla: PA0001
Campos: WERKS, COUNT(PERNR)
Filtro: ENDDA = '99991231' + JOIN PA0000 WHERE STAT2 = '3'
(combinar con PA0000 para filtrar solo activos)
```

### Leer rango de numeros de personal
```
Tool: ReadTable
Tabla: T750X
Campos: NRART, NRLVW, NRSNR (rango siguiente disponible)
Filtro: NRART = 'HRNUMBER'
```

## Flujo de Contratacion Completo (Accion 01)

```
PA40 → Tipo Accion: 01 Contratacion → Fecha: DD.MM.YYYY
│
├── IT0000: MASSN=01, STAT2=3 (Activo) → GRABAR
├── IT0001: BUKRS, WERKS, BTRTL, PERSG, PERSK, ABKRS, KOSTL, ORGEH, PLANS → GRABAR
├── IT0002: Nombre, Apellidos, DNI/NIE, Fecha nac., Sexo, Nacionalidad → GRABAR
├── IT0006: Calle, Ciudad, CP, Pais (subtipo 1=Permanente) → GRABAR
├── IT0007: Horario (SCHKZ), % empleo (EMPCT) → GRABAR
├── IT0008: Nivel salarial (TRFGR/TRFST) + conceptos + importes → GRABAR
├── IT0009: IBAN, BIC, banco (subtipo 0=Principal) → GRABAR
├── IT0016: Tipo contrato (ANSVH), inicio/fin, periodo prueba → GRABAR
└── IT0105: Email corporativo (subtipo 0010) → GRABAR

Resultado: empleado activo en SAP con PERNR asignado
```

## Novedades S/4HANA 2023

- Fiori app "Hire an Employee" reemplaza PA40 para procesos estandar de contratacion
- HR Administrative Services (HAS): flujos de aprobacion para acciones criticas (baja, traslado)
- Personnel Actions via API OData: `/sap/opu/odata/sap/HCM_EMPLOYEE_SRV` para integracion con SuccessFactors
- Intelligent HR: sugerencia automatica de tipo de accion basada en el contexto del proceso
- Integracion con SAP Signature Management (DocuSign/Adobe Sign) para contratos digitales
- Position Management mejorado: control de vacantes y sucesion integrado con accion de cambio org.
