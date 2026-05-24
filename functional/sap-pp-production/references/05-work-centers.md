# Puestos de Trabajo (Work Centers)

## Tablas

| Tabla | Descripcion |
|-------|-------------|
| CRHD | Cabecera puesto de trabajo |
| CRCO | Asignacion centro de coste |
| CRTX | Textos puesto de trabajo |
| KAKO | Cabecera capacidad |
| TC24 | Formulas scheduling |
| T006 | Unidades de medida |

## CRHD — Cabecera

```sql
SELECT OBJID, OBJTY, ARBPL, WERKS, VERWE, KAPESSION,
       PLANV, PESSION, LOESSION
FROM CRHD
WHERE ARBPL = '{puesto}' AND WERKS = '{centro}'
```

| Campo | Descripcion |
|-------|-------------|
| OBJID | ID objeto (clave interna) |
| OBJTY | Tipo objeto (A=puesto trabajo, D=recurso PP-PI) |
| ARBPL | Codigo puesto de trabajo |
| WERKS | Centro |
| VERWE | Tipo capacidad (001=work center, 002=capacity) |
| KAPESSION | Tipo capacidad responsable |
| PLANV | Clave planificador capacidad |

## Categorias de puesto de trabajo

| Categoria | Codigo | Uso |
|-----------|--------|-----|
| Maquina | 0001 | Centro de mecanizado, linea |
| Mano de obra | 0002 | Personal produccion |
| Puesto produccion | 0003 | Combinacion maquina + persona |
| Planta | 0004 | Centro como recurso |

## Datos de capacidad — KAKO

```sql
SELECT OBJID, KAPESSION, ENDDA, BEGDA, AESSION, KESSION,
       ANESSION, OFESSION, PAUSE, NUESSION
FROM KAKO
WHERE OBJID = '{objid}'
```

| Campo | Descripcion |
|-------|-------------|
| KAPESSION | Tipo capacidad |
| AESSION | Hora inicio |
| KESSION | Hora fin |
| PAUSE | Pausa (minutos) |
| NUESSION | Factor utilizacion (%) |
| ANESSION | Numero recursos |

### Capacidad disponible

```
Capacidad diaria = (Hora fin - Hora inicio - Pausa) × Numero recursos × Factor utilizacion
Ejemplo: (16:00 - 08:00 - 0:30) × 2 × 90% = 7.5h × 2 × 0.9 = 13.5 horas
```

## Asignacion centro de coste — CRCO

```sql
SELECT OBJID, KOSTL, LSTAR, KOKRS, BEGDA, ENDDA
FROM CRCO
WHERE OBJID = '{objid}'
```

| Campo | Descripcion |
|-------|-------------|
| KOSTL | Centro de coste |
| LSTAR | Clase de actividad |
| KOKRS | Area de controlling |

- Vincula puesto de trabajo con CO para valoracion
- Tarifa de clase de actividad × tiempo operacion = coste operacion
- Multiples asignaciones para diferentes clases de actividad (setup, machine, labor)

## Formulas de scheduling

Las formulas determinan como se calcula la duracion de una operacion.

| Formula | Calculo tipico |
|---------|----------------|
| SAP001 | Setup + (Machine × Qty / Base qty) |
| SAP002 | Setup + Machine + Labor |
| SAP003 | Setup + MAX(Machine, Labor) × Qty |

### Valores estandar en routing (PLPO)

| Valor | Uso tipico |
|-------|------------|
| VGW01 | Setup time |
| VGW02 | Machine time |
| VGW03 | Labor time |
| VGW04 | Valor 4 (user-defined) |
| VGW05 | Valor 5 (user-defined) |
| VGW06 | Valor 6 (user-defined) |

## Jerarquia de puestos de trabajo

```
Linea de produccion (capacity)
├── Puesto trabajo 1 (work center)
│   ├── Maquina A
│   └── Maquina B
└── Puesto trabajo 2 (work center)
    └── Maquina C
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| CR01 | Crear puesto de trabajo |
| CR02 | Modificar puesto de trabajo |
| CR03 | Visualizar puesto de trabajo |
| CR05 | Lista puestos de trabajo |
| CR06 | Modificacion masiva |
| CR07 | Evaluacion capacidades |
| CR60 | Display capacidad puesto |

## Consultas MCP diagnostico

```sql
-- Puesto de trabajo con capacidad
SELECT H.ARBPL, H.WERKS, H.OBJID, K.AESSION, K.KESSION, K.NUESSION, K.ANESSION
FROM CRHD H
INNER JOIN KAKO K ON H.OBJID = K.OBJID
WHERE H.ARBPL = '{puesto}' AND H.WERKS = '{centro}'

-- Asignacion CC y clase actividad
SELECT H.ARBPL, C.KOSTL, C.LSTAR, C.KOKRS
FROM CRHD H
INNER JOIN CRCO C ON H.OBJID = C.OBJID
WHERE H.ARBPL = '{puesto}' AND H.WERKS = '{centro}'

-- Todos los puestos de un centro
SELECT ARBPL, OBJID, VERWE FROM CRHD WHERE WERKS = '{centro}' AND OBJTY = 'A'
```
