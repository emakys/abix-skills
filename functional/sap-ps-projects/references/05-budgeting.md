# Presupuesto y Control de Disponibilidad — SAP PS S/4HANA 2023

## 1. Concepto de Presupuesto en PS

El presupuesto en SAP PS es el techo de gasto aprobado para un proyecto o elemento WBS. A diferencia de la planificacion de costes (que es un escenario "que pasaria si"), el presupuesto es el valor formalmente aprobado y controlado. El sistema puede bloquear imputaciones que superen el presupuesto disponible mediante el Control de Disponibilidad (Availability Control).

### Ciclo de Vida del Presupuesto

```
Presupuesto Original (CJ30)
    → Suplemento (CJ36)         [aumenta presupuesto]
    → Devolucion (CJ35)         [reduce presupuesto]
    → Transferencia (CJ34)      [mueve entre WBS]
    → Bloqueo (CJ32)            [bloquea uso]
    → Desbloqueo (CJ33)         [libera bloqueo]
```

---

## 2. Tipos de Presupuesto (WRTTP)

El tipo de presupuesto (Value Type / Tipo de Valor) diferencia los distintos valores de presupuesto almacenados en el sistema.

### Tipos de Valor PS

| WRTTP | Descripcion |
|---|---|
| 41 | Presupuesto original (Budget original) |
| 42 | Presupuesto actual (Original + suplementos - devoluciones) |
| 43 | Transferencias de presupuesto |
| 44 | Suplementos de presupuesto |
| 45 | Devoluciones de presupuesto |
| 46 | Bloqueo de presupuesto |
| 01 | Costes plan (planificacion de costes) |
| 04 | Costes reales |

---

## 3. Presupuesto Original (CJ30)

### Transaccion CJ30 — Gestionar Presupuesto de Proyecto

```
CJ30 → Ingresar numero de proyecto → Enter
La pantalla muestra la estructura WBS con columnas de presupuesto
Para cada WBS: introducir el presupuesto aprobado
Guardar → el sistema graba en BPGE/BPJA
```

### Estructura del Presupuesto

El presupuesto puede asignarse a distintos niveles de la jerarquia WBS:

```
Proyecto (total)
├── WBS.1 - Fase 1 [presupuesto: 500.000 EUR]
│   ├── WBS.1.1 - Diseño [100.000 EUR]
│   ├── WBS.1.2 - Construccion [300.000 EUR]
│   └── WBS.1.3 - Pruebas [100.000 EUR]
└── WBS.2 - Fase 2 [presupuesto: 300.000 EUR]
```

### Nivel de Control del Presupuesto

Configurable en el perfil de presupuesto:

| Nivel | Descripcion |
|---|---|
| Proyecto | Control sobre el total del proyecto |
| WBS de nivel superior | Control en WBS de nivel 1 |
| Cada WBS | Control individual por elemento WBS |
| WBS operativos | Solo en WBS marcados como operativos |

---

## 4. Suplemento de Presupuesto (CJ36)

Cuando el presupuesto aprobado no es suficiente, se puede solicitar un suplemento que aumenta el presupuesto disponible.

### Transaccion CJ36 — Suplemento de Presupuesto

```
CJ36 → Numero de proyecto → Enter
Introducir el importe del suplemento en el WBS correspondiente
Guardar → WRTTP 44 se graba en BPGE/BPJA
El presupuesto actual (WRTTP 42) se actualiza automaticamente
```

### Flujo de Aprobacion (Recomendado)

En proyectos con gobierno estricto, el suplemento debe pasar por un proceso de aprobacion antes de ejecutarse en SAP. Esto se puede implementar con:
- Workflow SAP (sin customizing estandar, requiere desarrollo)
- Proceso manual fuera de SAP + aprobacion en SAP
- Nota de solicitud en CJ02 antes de ejecutar CJ36

---

## 5. Devolucion de Presupuesto (CJ35)

La devolucion reduce el presupuesto disponible, devolviendo capacidad de gasto al nivel superior o a otro proyecto.

### Transaccion CJ35 — Devolucion de Presupuesto

```
CJ35 → Numero de proyecto → Enter
Introducir el importe a devolver (negativo automaticamente)
Guardar → WRTTP 45 en BPGE/BPJA
```

**Uso tipico:** Al cerrar un proyecto con remanente de presupuesto, devolver el excedente para liberarlo a nivel de programa de inversion.

---

## 6. Transferencia de Presupuesto (CJ34)

La transferencia mueve presupuesto entre elementos WBS dentro del mismo proyecto o entre proyectos.

### Transaccion CJ34 — Transferencia de Presupuesto

```
CJ34 → Seleccionar origen y destino
Introducir importe de transferencia
Guardar → WRTTP 43 en ambos WBS (origen negativo, destino positivo)
```

### Restricciones de Transferencia

- El presupuesto no puede quedar negativo en el WBS origen
- El nivel jerarquico del control de disponibilidad determina si la transferencia es posible
- Se puede transferir entre proyectos distintos (si el perfil lo permite)

---

## 7. Control de Disponibilidad (Availability Control)

El control de disponibilidad bloquea o advierte cuando los costes comprometidos + reales superan el presupuesto disponible.

### Tipos de Verificacion

| Tipo | Descripcion |
|---|---|
| Advertencia | Avisa pero permite continuar |
| Error | Bloquea la imputacion hasta que se libere presupuesto |
| Error con mail | Bloquea + notifica al responsable del proyecto |

### Momento de Verificacion

El control de disponibilidad se activa en distintos momentos segun la configuracion:

| Momento | Descripcion |
|---|---|
| Solicitud de pedido | Al crear SolPed con imputacion a WBS |
| Pedido de compras | Al crear el pedido |
| Entrada de mercancias | Al hacer el MIGO |
| Verificacion factura | Al registrar MIRO |
| Asiento manual | Al contabilizar FB50/FB60 |
| Confirmacion actividad | Al confirmar horas en CN27 |

### Configuracion del Perfil de Presupuesto

```
SPRO → Project System → Costes → Presupuesto →
Definir Perfil de Presupuesto para Proyectos
Transaccion: OPS9
```

### Tolerancias del Control de Disponibilidad

```
SPRO → Project System → Costes → Presupuesto →
Definir Tolerancias para Control de Disponibilidad
Transaccion: OPSU
```

| Campo | Descripcion |
|---|---|
| Limite de utilizacion | % del presupuesto que genera advertencia |
| Accion al superar limite | Advertencia / Error / Error+mail |
| Incluir plan | Si el plan se cuenta como compromiso |
| Incluir compromisos | Si las SolPed/pedidos cuentan como gasto |

### Activacion del Control de Disponibilidad

El control de disponibilidad se activa a nivel de WBS con el indicador en el perfil de presupuesto. Se activa automaticamente al asignar presupuesto (CJ30).

```
Condicion de activacion:
PRPS-IMKEY (perfil de presupuesto) debe estar configurado
Presupuesto > 0 en el WBS
```

---

## 8. Tablas de Presupuesto

### Tabla BPGE — Presupuesto Global de Proyecto

BPGE almacena el presupuesto total (sin desglose por periodo/ano) para el proyecto y sus WBS.

| Campo | Tipo | Descripcion |
|---|---|---|
| OBJNR | CHAR(22) | Numero de objeto (del WBS/proyecto) |
| WRTTP | CHAR(2) | Tipo de presupuesto (41,42,44,45...) |
| VERSN | CHAR(3) | Version |
| WTGES | CURR | Importe total en moneda objeto |
| WKGES | CURR | Importe total en moneda controlling |

```sql
-- Presupuesto actual por WBS
SELECT p.POSID, p.POST1,
       b.WRTTP,
       b.WTGES AS PRESUPUESTO_MONEDA_PROY,
       b.WKGES AS PRESUPUESTO_MONEDA_CO
FROM BPGE b
INNER JOIN PRPS p ON p.OBJNR = b.OBJNR
WHERE b.WRTTP = '42'  -- Presupuesto actual
  AND b.VERSN = '0'
  AND p.PBUKR = '1000'
ORDER BY p.POSID
```

### Tabla BPJA — Presupuesto por Ejercicio

BPJA desglosa el presupuesto por ejercicio fiscal. Permite distribucion temporal del presupuesto.

| Campo | Tipo | Descripcion |
|---|---|---|
| OBJNR | CHAR(22) | Numero de objeto |
| WRTTP | CHAR(2) | Tipo de valor |
| VERSN | CHAR(3) | Version |
| GJAHR | NUMC(4) | Ejercicio fiscal |
| WTJHR | CURR | Importe anual en moneda objeto |
| WKJHR | CURR | Importe anual en moneda controlling |

```sql
-- Distribucion anual del presupuesto
SELECT p.POSID,
       b.GJAHR AS EJERCICIO,
       b.WRTTP,
       b.WKJHR AS PRESUPUESTO_ANUAL
FROM BPJA b
INNER JOIN PRPS p ON p.OBJNR = b.OBJNR
WHERE b.WRTTP IN ('41','42')
  AND b.VERSN = '0'
  AND p.POSID LIKE 'MI-PROY-%'
ORDER BY p.POSID, b.GJAHR
```

### Tabla BPBK — Documentos de Presupuesto (Cabecera)

BPBK almacena los documentos de cambio de presupuesto (suplementos, devoluciones, transferencias).

| Campo | Descripcion |
|---|---|
| BELNR | Numero de documento presupuestario |
| BLART | Clase de documento |
| BUDAT | Fecha de contabilizacion |
| USNAM | Usuario que realizó el cambio |
| WRTTP | Tipo de valor |

---

## 9. Programas de Inversion (IM — Investment Management)

En proyectos de inversion, el presupuesto PS puede estar vinculado a un Programa de Inversion (IM). El IM controla el presupuesto de forma superior y lo asigna a los proyectos.

### Jerarquia IM-PS

```
Programa de Inversion (IM)
    └── Medida de Inversion (IM01)    ← vinculada al Proyecto PS
            └── Proyecto PS
                    └── WBS elementos
```

### Configuracion SPRO IM

```
SPRO → Investment Management → Programas de Inversion →
Definir Perfil de Programa
Transaccion: OIB8
```

### Transacciones IM

| Transaccion | Descripcion |
|---|---|
| IM01 | Crear programa de inversion |
| IM11 | Crear posicion del programa |
| IM35 | Presupuesto del programa |
| IM52 | Asignar proyecto a posicion IM |
| IM61 | Control presupuestario IM |

---

## 10. Reportes de Presupuesto

| Transaccion | Descripcion |
|---|---|
| CJ31 | Resumen de presupuesto |
| CJ38 | Diferencia plan/presupuesto |
| S_ALR_87013558 | Informe de presupuesto del proyecto |
| S_ALR_87013533 | Control de costes con presupuesto |
| CJI3 | Partidas individuales de presupuesto |
| CNS41 | Estructura de proyecto con costes y presupuesto |

---

## 11. Fiori Apps de Presupuesto

| App ID | Descripcion |
|---|---|
| F2390 | Monitor Project Budgets |
| F3065 | Budget Planning for Projects |
| F4380 | Project Budget Overview |

---

## 12. Consultas SQL/MCP de Presupuesto

```javascript
// Resumen presupuesto vs real por proyecto
GetSqlQuery({
  query: `SELECT p.POSID, p.POST1,
                 bg.WTGES AS PRESUPUESTO,
                 SUM(a.HSL) AS COSTE_REAL,
                 bg.WTGES - SUM(COALESCE(a.HSL,0)) AS DISPONIBLE
          FROM PRPS p
          LEFT JOIN BPGE bg ON bg.OBJNR = p.OBJNR
                            AND bg.WRTTP = '42' AND bg.VERSN = '0'
          LEFT JOIN ACDOCA a ON a.PSPNR = p.PSPNR
                             AND a.RLDNR = '0L'
                             AND a.GJAHR = '2024'
          WHERE p.PBUKR = '1000'
            AND p.PRFLA = 'X'
          GROUP BY p.POSID, p.POST1, bg.WTGES
          ORDER BY p.POSID`
})

// Documentos de cambio de presupuesto (suplementos/devoluciones)
GetSqlQuery({
  query: `SELECT bk.BELNR, bk.BLART, bk.BUDAT, bk.USNAM,
                 bp.OBJNR, bp.WRTTP, bp.WTGES
          FROM BPBK bk
          INNER JOIN BPBP bp ON bp.BELNR = bk.BELNR
          WHERE bk.WRTTP IN ('44','45','43')
            AND bk.BUDAT >= '20240101'
          ORDER BY bk.BUDAT DESC`
})

// Estado del control de disponibilidad
GetSqlQuery({
  query: `SELECT p.POSID,
                 bg.WTGES AS PRESUPUESTO,
                 co.WTGES AS COMPROMETIDO,
                 re.WTGES AS REAL,
                 bg.WTGES - COALESCE(co.WTGES,0) - COALESCE(re.WTGES,0)
                   AS DISPONIBLE
          FROM PRPS p
          LEFT JOIN BPGE bg ON bg.OBJNR = p.OBJNR AND bg.WRTTP = '42'
          LEFT JOIN BPGE co ON co.OBJNR = p.OBJNR AND co.WRTTP = '21'
          LEFT JOIN BPGE re ON re.OBJNR = p.OBJNR AND re.WRTTP = '04'
          WHERE p.PRFLA = 'X' AND p.PBUKR = '1000'
          ORDER BY p.POSID`
})
```

---

## 13. Mejores Practicas de Presupuesto PS

1. **Control a nivel WBS operativo**: Configurar el control de disponibilidad en el nivel mas detallado (WBS operativos) para mayor precision y control.

2. **Distincion plan vs presupuesto**: El plan es una estimacion; el presupuesto es la aprobacion formal. Ambos pueden coexistir y compararse. El control de disponibilidad usa el presupuesto, no el plan.

3. **Bloquear presupuesto al cerrar WBS**: Cuando un WBS se marca TECO, bloquear su presupuesto remanente (CJ32) para evitar imputaciones no autorizadas.

4. **Trazabilidad de cambios**: Toda modificacion de presupuesto (suplemento, devolucion, transferencia) genera un documento en BPBK con usuario y fecha. Mantener una politica de texto obligatorio en los documentos.

5. **Presupuesto por ejercicio (BPJA)**: Para proyectos plurianuales, distribuir el presupuesto por ejercicio para facilitar el cierre fiscal y el reporting anual.

6. **Integracion IM para proyectos de inversion**: En empresas con carteras de proyectos de inversion, vincular siempre los proyectos PS a posiciones del Programa de Inversion para control centralizado.
