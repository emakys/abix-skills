# Planificacion de Costes e Ingresos — SAP PS S/4HANA 2023

## 1. Concepto de Planificacion de Costes en PS

La planificacion de costes en PS permite estimar los recursos y costes necesarios para ejecutar un proyecto antes de su inicio. Es diferente del presupuesto (aprobacion formal) y de los costes reales (lo que se gasta). La planificacion es la base para el control de desviaciones y la toma de decisiones.

### Niveles de Planificacion en PS

| Nivel | Descripcion | Herramienta |
|---|---|---|
| Planificacion jerarquica WBS | Importes directos en cada WBS | CJ40 |
| Planificacion detallada actividad | Horas y materiales por actividad de red | CN20N / AFVV |
| Easy Cost Planning | Planificacion basada en posiciones de coste | CJR2 |
| Unit Costing | Calculo de coste unitario | CJ43 |
| Planificacion de ingresos | Ingresos esperados por WBS | CJ42 |

---

## 2. Planificacion Manual en WBS (CJ40)

La planificacion manual permite introducir importes de coste directamente en los elementos WBS, desglosados por clase de coste y periodo.

### Transaccion CJ40 — Planificacion de Costes en WBS

```
CJ40 → Ingresar numero de proyecto → Enter
Seleccionar version de plan y ejercicio
Para cada WBS: introducir importes por clase de coste
Guardar
```

### Tipos de Planificacion en CJ40

| Tipo | Descripcion |
|---|---|
| Total | Importe total del proyecto (sin desglose anual) |
| Anual | Desglose por ejercicio fiscal |
| Mensual | Desglose por periodo dentro del ejercicio |

### Ventajas de la Planificacion Jerarquica

- Rapida de introducir para proyectos con muchos WBS
- No requiere redes ni actividades definidas
- Util en fases tempranas del proyecto (estimacion conceptual)
- Permite el control presupuesto vs plan sin detallar actividades

---

## 3. Versiones de Plan

Las versiones de plan permiten mantener multiples escenarios de planificacion simultaneamente (base, optimista, pesimista, revision trimestral, etc.).

### Version 0 — Plan Activo

La version 0 es la version de plan activa que se usa por defecto para comparaciones con costes reales y presupuesto.

### Configuracion de Versiones

```
SPRO → Project System → Costes → Planificacion de Costes →
Definir Versiones de Plan
Transaccion: OKEV (compartido con WBS masking)
O bien: OKP1 / OKEQ para versiones CO en general
```

### Copiar Plan entre Versiones

```
Transaccion: CJ9B — Copiar plan de proyecto
1. Seleccionar proyecto origen y version origen
2. Seleccionar version destino
3. Ejecutar
Util para crear escenarios alternativos sin perder el plan base
```

### Tabla COSP — Costes Plan (vista de compatibilidad ECC)

En S/4HANA, los costes de plan de PS se almacenan en ACDOCA con WRTTP = '01'. COSP es una vista de compatibilidad que sigue disponible pero se lee de ACDOCA.

| Campo | Descripcion |
|---|---|
| OBJNR | Numero de objeto (WBS) |
| GJAHR | Ejercicio |
| VERSN | Version de plan |
| WRTTP | Tipo de valor (01=plan) |
| KSTAR | Clase de coste |
| BEKNZ | Indicador (debito/credito) |
| WKGxxx | Importes por periodo (WKG001..WKG016) |

---

## 4. Planificacion Detallada de Actividades de Red

Cuando se usan redes y actividades, la planificacion de costes se realiza a nivel de actividad individual.

### Componentes del Coste de Actividad

```
Actividad interna:
Coste = Horas plan (VGW01-06) × Tarifa tipo actividad CO

Actividad externa:
Coste = Precio externo plan × Cantidad

Actividad de coste:
Coste = Importe directo en clase de coste
```

### Calculo Automatico de Costes de Red

```
Transaccion: CJ9E (Calculo de costes de red)
O bien desde CJ20N: menu Actividades → Calcular costes
```

El sistema calcula automaticamente los costes planificados para cada actividad basandose en las tarifas de los tipos de actividad CO y las horas planificadas.

---

## 5. Easy Cost Planning (ECP)

Easy Cost Planning es una herramienta de planificacion simplificada que permite crear planes de coste estructurados basados en posiciones de coste (items de planificacion) sin necesidad de redes complejas.

### Transaccion CJR2 — Easy Cost Planning

```
CJR2 → Seleccionar WBS o proyecto
Crear posiciones de coste:
  - Descripcion
  - Clase de coste
  - Centro de coste o tipo actividad
  - Cantidad y unidad
  - Tarifa o precio
Sistema calcula importe automaticamente
Guardar → valores en ACDOCA WRTTP=01
```

### Ventajas de Easy Cost Planning

- Mas intuitivo que CJ40 para usuarios no expertos CO
- Permite mezclar actividades, materiales y costes directos
- Genera desglose detallado de la estructura de costes
- Exportable a Excel para revision fuera del sistema
- Compatible con plantillas de posiciones de coste estandar

---

## 6. Unit Costing (Calculo de Coste Unitario)

Unit Costing permite calcular el coste de un proyecto usando la logica del calculo de costes de producto, pero aplicado a proyectos.

### Transaccion CJ43 — Unit Costing para WBS

```
CJ43 → Seleccionar elemento WBS
Crear posiciones de unit cost:
  - Materiales (con lista de materiales)
  - Operaciones (con horas de trabajo)
  - Costes adicionales (overhead)
Calcular → sistema genera el coste total
Transferir al plan del proyecto
```

---

## 7. Planificacion de Ingresos (CJ42)

Ademas de costes, PS permite planificar los ingresos esperados del proyecto. Esto es fundamental para proyectos de cliente (proyectos orientados a resultados).

### Transaccion CJ42 — Planificacion de Ingresos WBS

```
CJ42 → Numero de proyecto → Enter
Para cada WBS de facturacion: introducir ingreso plan
Desglosado por clase de ingresos y periodo
Guardar
```

### Clases de Ingresos en PS

En PS, los ingresos se planifican en clases de coste de tipo 11 (ingresos). Las clases de ingreso estandar usadas en PS incluyen:

| Clase | Descripcion tipica |
|---|---|
| 800xxx | Ingresos por ventas de proyecto |
| 810xxx | Ingresos por servicios |
| 820xxx | Ingresos por materiales vendidos |

### Planificacion Integrada PS-SD

Para proyectos vinculados a pedidos de venta SD, los ingresos planificados en SD (posiciones del pedido) se pueden transferir automaticamente a la planificacion de ingresos PS:

```
CJ42 → Transferir desde SD
O bien configurar derivacion automatica al crear el pedido de venta con referencia WBS
```

---

## 8. Planificacion Jerarquica vs Planificacion Detallada

### Comparacion

| Criterio | Jerarquica (CJ40) | Detallada (Red) | Easy Cost Planning |
|---|---|---|---|
| Requiere redes | No | Si | No |
| Nivel de detalle | Bajo | Alto | Medio |
| Tiempo de entrada | Rapido | Lento | Medio |
| Fase del proyecto | Conceptual | Ejecucion | Pre-ejecucion |
| Integracion capacidad | No | Si | Parcial |
| Base para confirmaciones | No | Si | No |

### Estrategia Recomendada

```
Fase conceptual → CJ40 (plan global por clase de coste)
Fase de diseño → Easy Cost Planning (posiciones detalladas)
Fase de ejecucion → Planificacion en actividades de red
```

---

## 9. Planificacion en ACDOCA (S/4HANA)

En S/4HANA, todos los valores de planificacion de proyectos se almacenan en ACDOCA con el campo WRTTP distinguiendo plan de real.

### Campos ACDOCA para Planificacion PS

| Campo | Descripcion |
|---|---|
| RLDNR | Ledger ('0L' = ledger principal) |
| RRCTY | Tipo de registro ('1' = plan, '0' = real) |
| WRTTP | Tipo de valor ('01' = plan) |
| VERSN | Version de plan ('000', '001'...) |
| PSPNR | Numero interno del WBS |
| KSTAR | Clase de coste |
| GJAHR | Ejercicio |
| POPER | Periodo |
| HSL | Importe en moneda local |
| KSL | Importe en moneda controlling |

```sql
-- Planificacion de costes por WBS y clase de coste
SELECT p.POSID, a.KSTAR, a.GJAHR, a.POPER,
       SUM(a.HSL) AS PLAN_MONEDA_LOCAL
FROM ACDOCA a
INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
WHERE a.RLDNR = '0L'
  AND a.RRCTY = '1'    -- plan
  AND a.WRTTP = '01'   -- planificacion de costes
  AND a.VERSN = '000'
  AND a.GJAHR = '2024'
  AND p.PBUKR = '1000'
GROUP BY p.POSID, a.KSTAR, a.GJAHR, a.POPER
ORDER BY p.POSID, a.KSTAR, a.POPER
```

---

## 10. Analisis Plan vs Real

### Transacciones de Comparacion

| Transaccion | Descripcion |
|---|---|
| CJI4 | Partidas individuales de costes |
| S_ALR_87013532 | Plan vs real por proyecto |
| S_ALR_87013533 | Control de costes del proyecto |
| CJ40 | Vista plan con comparacion real |
| CNS41 | Estructura proyecto con costes |

### Calculo de Desviacion

```
Desviacion = Coste Real - Coste Plan
% Desviacion = (Real - Plan) / Plan × 100
```

---

## 11. Consultas SQL/MCP

```javascript
// Plan vs real consolidado por WBS
GetSqlQuery({
  query: `SELECT p.POSID, p.POST1,
                 SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END) AS PLAN,
                 SUM(CASE WHEN a.RRCTY = '0' THEN a.HSL ELSE 0 END) AS REAL,
                 SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END) -
                 SUM(CASE WHEN a.RRCTY = '0' THEN a.HSL ELSE 0 END) AS DESVIACION
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.GJAHR = '2024'
            AND a.WRTTP IN ('01','04')
            AND a.VERSN = '000'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, p.POST1
          HAVING SUM(a.HSL) <> 0
          ORDER BY p.POSID`
})

// Planificacion de ingresos vs real
GetSqlQuery({
  query: `SELECT p.POSID, a.KSTAR,
                 SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END) AS INGRESO_PLAN,
                 SUM(CASE WHEN a.RRCTY = '0' THEN a.HSL ELSE 0 END) AS INGRESO_REAL
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.GJAHR = '2024'
            AND a.KSTAR LIKE '8%'  -- clases de ingreso
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, a.KSTAR
          ORDER BY p.POSID`
})
```

---

## 12. Mejores Practicas de Planificacion de Costes

1. **Una version como baseline**: Congelar la version 0 como plan baseline al inicio del proyecto. Usar versiones adicionales para revisiones periódicas del plan.

2. **Planificacion por clase de coste**: Siempre planificar por clase de coste, no solo totales. Facilita el analisis de desviaciones por tipo de recurso.

3. **Desglose temporal (mensual)**: Distribuir el plan mensualmente permite comparar avance real vs plan por periodo y detectar desviaciones temprano.

4. **Sincronizar plan y presupuesto**: Aunque son distintos, el plan debe ser coherente con el presupuesto. Si el plan supera el presupuesto, hay que revisar el alcance o solicitar suplemento.

5. **Actualizar el plan en cada fase**: El plan debe reflejar siempre la mejor estimacion actual. Un plan obsoleto no tiene valor de control.

6. **Easy Cost Planning para proyectos de servicio**: ECP es especialmente util en proyectos de servicios donde los costes son principalmente horas de consultores/tecnicos. Permite plantillas reutilizables.
