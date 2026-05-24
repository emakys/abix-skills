# Organizational Management (OM)

## Tipos de Objeto

| Tipo | Descripción         | Ejemplo           |
|------|---------------------|-------------------|
| O    | Unidad Organizativa | Departamento RRHH |
| S    | Posición            | Analista Nómina   |
| C    | Cargo (Job)         | Analista          |
| P    | Persona             | Empleado          |
| K    | Centro de Coste     | CC-1000           |

Los objetos se crean y mantienen con versión de plan (PLVAR), normalmente **01** (plan activo).

## Relaciones (Infotipo 1001)

| Relación | Dirección A (de → a) | Dirección B (de → a inverso) | Uso típico                        |
|----------|----------------------|------------------------------|-----------------------------------|
| 002      | Pertenece a          | Incorpora                    | O → O (jerarquía org.)            |
| 003      | Pertenece a          | Comprende                    | S → O (posición en unidad org.)   |
| 007      | Descrito por         | Describe                     | S → C (posición vinculada a cargo)|
| 008      | Titular de           | Titular es                   | P → S (empleado ocupa posición)   |
| 012      | Gestiona             | Es gestionado por            | S → O (jefe de unidad)            |

Las relaciones tienen **vigencia temporal** (fecha inicio / fecha fin). Dirección A = relación activa, Dirección B = relación pasiva (inversa).

## Versión de Plan (PLVAR)

- Campo clave de todas las tablas OM.
- **01**: Plan activo (productivo).
- **02+**: Planes de simulación / reorganización.
- Configuración en T77S0 (PLOGI PLVAR).

## Tablas Principales

| Tabla   | Contenido                                               |
|---------|---------------------------------------------------------|
| HRP1000 | Datos maestros de objeto (nombre, abreviatura, vigencia)|
| HRP1001 | Relaciones entre objetos (infotipo 1001)                |
| T77S0   | Parámetros globales OM (PLOGI ORGA, PLVAR, etc.)        |
| T778O   | Rutas de evaluación definidas                           |

## Transacciones Clave

| TCode  | Descripción                                        |
|--------|----------------------------------------------------|
| PPOME  | Mantenimiento de estructura org. (interfaz árbol)  |
| PPOSE  | Mantenimiento de estructura org. alternativa       |
| PO10   | Mantenimiento de unidad organizativa               |
| PO13   | Mantenimiento de posición                          |
| PO03   | Mantenimiento de cargo (job)                       |
| S_AHR_61016494 | Report de estructura org.                  |

## Rutas de Evaluación (T778O)

Las rutas de evaluación definen cómo navegar el árbol OM para reportes e integración.

Ejemplos estándar:

| Ruta   | Descripción                                      |
|--------|--------------------------------------------------|
| ORGA   | O → O → S → P (jerarquía completa)               |
| SBESX  | S → P (posición a titular)                       |
| B002   | O → O (unidades subordinadas)                    |

Se usan en reportes (RHORGXX) y en la integración PA-OM.

## Integración PA-OM

Activada mediante el parámetro **PLOGI ORGA** en T77S0 (valor: X).

Cuando está activa:
- Al contratar un empleado en PA (IT0000/IT0001), el sistema busca la posición (IT0001 campo PLANS) en OM.
- Hereda automáticamente: unidad org. (ORGEH), centro de coste (KOSTL), cargo (STELL), responsable.
- Cambios en OM (p.ej. reasignación de posición a otro CC) pueden desencadenar delimitación en IT0001.

Infotipos afectados por integración:
- IT0001 (Asignación Org.)
- IT0007 (Horario de Trabajo Teórico) — hereda desde posición/unidad si está configurado.

## Consultas vía MCP (SAP ADT)

Para consultar o leer objetos OM desde ABAP en S/4HANA 2023:

```abap
" Leer nombre de unidad organizativa desde HRP1000
SELECT SINGLE short_text
  FROM hrp1000
  WHERE plvar = '01'
    AND otype = 'O'
    AND objid = @lv_org_unit
    AND begda <= @sy-datum
    AND endda >= @sy-datum
  INTO @DATA(lv_org_name).
```

Herramienta MCP recomendada: `ExecuteReport` con RHORGXX para estructuras, o `RunQuery` sobre HRP1000/HRP1001.

Para leer relaciones (p.ej. titular de una posición):

```abap
SELECT SINGLE sobid
  FROM hrp1001
  WHERE plvar = '01'
    AND otype = 'S'
    AND objid = @lv_position
    AND rsign = 'B'
    AND relat = '008'
    AND begda <= @sy-datum
    AND endda >= @sy-datum
  INTO @DATA(lv_person_id).
```

## Notas S/4HANA 2023

- La integración con **Employee Central (SF EC)** replica la estructura OM vía middleware (BTP Integration Suite).
- En implementaciones cloud (SAP BTP ABAP Environment), OM se gestiona desde **SAP SuccessFactors** y se replica a S/4HANA. El acceso directo a HRP* puede estar restringido.
- Transacción **PPOME** sigue siendo el estándar en S/4HANA on-premise 2023.
- Para reporting avanzado usar **SAP Analytics Cloud (SAC)** con modelos basados en CDS views de OM (p.ej. `I_OrgUnit`, `I_Position`).
