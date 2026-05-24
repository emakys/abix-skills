# Facturacion e Ingresos — SAP PS S/4HANA 2023

## 1. Concepto de Facturacion en Proyectos PS

La facturacion en SAP PS (Project System) se aplica a proyectos orientados a cliente, donde la empresa ejecuta un proyecto y factura al cliente por el avance o por entregables especificos. La integracion PS-SD (Sales & Distribution) es el nucleo de este proceso.

### Modelos de Facturacion en PS

| Modelo | Descripcion | Mecanismo |
|---|---|---|
| Milestone Billing | Facturacion por hitos de entrega | Hitos de red → billing plan SD |
| Resource-Related Billing | Facturacion por recursos consumidos | DP91 → SD |
| Fixed Price Billing | Precio fijo acordado por contrato | Posicion SD con importe fijo |
| Time & Material | Tiempo y materiales reales | CATS + compras → DP91 |
| Advance Billing | Facturacion anticipada | Billing plan SD con fechas |

---

## 2. Integracion PS → SD

### Estructura de la Integracion

```
Pedido de Venta SD (VA01)
    └── Posicion SD
            └── WBS asignado (PRPS-FAKKZ = X)
                    └── Billing Plan (FPLT)
                            └── Hito de red (AFMG)
                            └── Factura SD (VF01)
```

### Asignacion WBS-Pedido de Venta

```
VA01 → Crear pedido de venta
Posicion → ficha "Datos cuenta":
  - WBS (Elemento PS): POSID del elemento WBS
  - El WBS debe tener indicador de facturacion (FAKKZ = X)
Guardar → el pedido de venta queda vinculado al proyecto
```

### Flujo de Facturacion

```
1. Crear pedido venta con referencia WBS (VA01)
2. Definir billing plan (plan de facturacion) en la posicion SD
3. Vincular posiciones del billing plan a hitos de red
4. Ejecutar el proyecto (actividades de red)
5. Confirmar hitos (CN27) → activa posicion billing plan
6. Crear factura SD (VF01 / VF04)
7. Ingreso contabilizado en la cuenta de resultados
```

---

## 3. Indicador de Facturacion WBS (FAKKZ)

Solo los WBS con el indicador de facturacion activo pueden asignarse a posiciones de pedidos de venta y participar en la facturacion.

### Tabla PRPS — Campo FAKKZ

| FAKKZ | Descripcion |
|---|---|
| X | WBS con indicador de facturacion activo |
| Vacio | WBS no facturable (no aparece en SD) |

### Configuracion

```
CJ20N → WBS → ficha "Datos basicos" → Indicador de facturacion
O bien al crear el WBS en CJ11
```

---

## 4. Plan de Facturacion (Billing Plan — FPLT)

El billing plan define cuando y cuanto se factura al cliente. Se vincula a la posicion del pedido de venta SD.

### Tabla FPLT — Plan de Facturacion

| Campo | Tipo | Descripcion |
|---|---|---|
| FPLT | CHAR(10) | Numero de plan de facturacion |
| FPLNR | NUMC(10) | Numero interno del plan |
| FPLTR | NUMC(6) | Posicion en el plan |
| FKDAT | DATS(8) | Fecha de facturacion |
| FAKSP | CHAR(2) | Bloqueo de facturacion |
| ABDAT | DATS(8) | Fecha de liquidacion |
| FAKWR | CURR | Importe de la posicion |
| MSCHL | CHAR(1) | Clave de hito (milestone key) |
| FPART | CHAR(1) | Indicador de liquidacion parcial |
| VRELT | CHAR(1) | Tipo de relacion con hito |

```sql
-- Plan de facturacion por pedido de venta
SELECT f.VBELN, f.POSNR,
       p.FPLTR AS POSICION,
       p.FKDAT AS FECHA_FACTURACION,
       p.FAKWR AS IMPORTE,
       p.FAKSP AS BLOQUEO,
       p.MSCHL AS CLAVE_HITO
FROM VBAK f
INNER JOIN FPLT p ON p.FPLNR = f.FPLNR
WHERE f.VBELN = '0000012345'
ORDER BY p.FPLTR
```

---

## 5. Milestone Billing — Facturacion por Hitos

La facturacion por hitos (Milestone Billing) vincula posiciones del billing plan a hitos de red. Al confirmar el hito, se activa la posicion del billing plan para facturacion.

### Proceso de Configuracion

```
1. Crear hito en actividad de red (CN20N → actividad → hitos)
2. Asignar clave de hito (MSCHL) al hito de red (AFMG-DPROG)
3. En billing plan SD: crear posicion con la misma clave de hito
4. Al confirmar hito (CN27): sistema activa posicion billing plan
5. VF04 → lista de posiciones facturables → crear factura
```

### Campos Clave del Hito (AFMG)

| Campo | Descripcion |
|---|---|
| MEILNR | Numero de hito |
| MLNAM | Nombre del hito |
| MLDAT | Fecha del hito (plan) |
| FKDAT | Fecha de facturacion |
| DPROG | Programa de facturacion (billing plan key) |
| MLKTR | Indicador de confirmacion del hito |

### Confirmacion de Hito y Facturacion

```
CN27 → confirmar actividad con hito
Sistema detecta que la actividad tiene hito vinculado a billing plan
→ desbloquea posicion del billing plan en SD
→ VF04 muestra la posicion como facturable
→ VF01 → crear factura
→ Ingreso en ACDOCA con referencia al WBS
```

---

## 6. Resource-Related Billing (DP91)

La facturacion basada en recursos permite facturar al cliente segun los costes reales incurridos en el proyecto (tiempo, materiales, gastos).

### Transaccion DP91 — Facturacion por Recursos

```
DP91 → Seleccionar pedido de venta o WBS
Sistema analiza:
  - Horas confirmadas (AFRU) → convertidas en posiciones de facturacion
  - Materiales consumidos (RESB/MSEG) → posiciones de material
  - Gastos generales → posiciones de gasto
Genera solicitud de facturacion (DRQ)
DRQ → VF04 → Factura SD
```

### Configuracion DIP (Dynamic Item Processor)

El DIP perfil (Dynamic Item Processor Profile) controla como los costes reales del proyecto se convierten en posiciones de facturacion para DP91.

```
SPRO → Project System → Facturacion →
Definir Perfil DIP
Transaccion: ODP1
```

| Parametro DIP | Descripcion |
|---|---|
| Origen de dato | CATS, Confirmaciones red, Materiales, Gastos |
| Material de facturacion | Material SD que se usa para facturar |
| Valor de facturacion | Coste real, precio de lista, tarifa especial |
| Agrupacion | Como agrupar posiciones (por clase coste, material, etc.) |

---

## 7. Reconocimiento de Ingresos (Revenue Recognition)

El reconocimiento de ingresos aplica las normas contables (IFRS 15 / GAAP) para reconocer los ingresos de proyectos a largo plazo. En SAP, se implementa via el modulo de Resultados de Proyecto (PS-CO).

### Transacciones de Reconocimiento de Ingresos

| Transaccion | Descripcion |
|---|---|
| CJ45 | Calculo de resultados individual |
| CJ46 | Calculo de resultados colectivo |
| CJ47 | Calculo de resultados colectivo (batch) |
| KKAJ | Calculo de resultados (alternativa) |

### Metodos de Reconocimiento

| Metodo | Descripcion | Norma |
|---|---|---|
| Coste-coste (POC) | % de avance = % coste real / coste total | IFRS 15 |
| Hitos | Ingreso reconocido al confirmar hito | IFRS 15 |
| Metodo completado | Ingreso solo al finalizar proyecto | GAAP conservador |
| Metodo de ventas | Ingreso = facturacion real | Simplificado |

### Porcentaje de Completitud (POC)

```
POC = Coste Real / Coste Total Estimado × 100

Ingreso Reconocible = Ingreso Total Contrato × POC
Ingreso Diferido = Ingreso Total - Ingreso Reconocible
```

---

## 8. Analisis de Resultados del Proyecto (KKA1)

El analisis de resultados muestra el estado economico del proyecto: ingresos reconocidos, costes, WIP, reservas.

### Transaccion KKA1 — Analisis de Resultados Individual

```
KKA1 → Ingresar numero de orden de proyecto o WBS
Seleccionar: Periodo, Ejercicio, Version
Ejecutar → muestra:
  - Ingresos planificados
  - Ingresos facturados
  - Costes planificados
  - Costes reales
  - WIP (Work in Process)
  - Resultado del periodo
```

### Transaccion KKA2 — Analisis de Resultados Colectivo

```
KKA2 → Seleccionar rango de proyectos / sociedad / area CO
Ejecutar → informe consolidado de resultados
```

---

## 9. Billing Elements y Facturacion por Posicion WBS

Los "billing elements" son los WBS configurados como receptores de facturacion (FAKKZ = X). Pueden tener planes de facturacion independientes.

### Configuracion del WBS Facturable

```
WBS debe tener:
  PRPS-FAKKZ = 'X'  (indicador de facturacion)
  PRPS-PBUKR = sociedad facturadora
  Responsable SD asignado (opcional pero recomendado)
```

### Relacion WBS Facturable y Pedido SD

Una posicion de pedido SD puede estar asignada a un WBS facturable. Esto determina:
- A que proyecto se imputan los ingresos de la factura
- Que WBS activa las posiciones del billing plan al confirmar hitos
- Donde se registra el reconocimiento de ingresos

---

## 10. Tabla PRPS — Campos de Facturacion

| Campo | Descripcion |
|---|---|
| FAKKZ | Indicador de facturacion (X = facturable) |
| ABGSL | Clase de liquidacion (para regla de liquidacion a SD) |
| AKSTL | Centro de coste para facturacion interna |
| PRCTR | Centro de beneficio (relevante para P&L) |

---

## 11. Cierre de Periodo — Ciclo de Facturacion

### Proceso Mensual para Proyectos PS-SD

```
1. CJ45/KKAJ    → Calcular WIP y reconocimiento de ingresos
2. KKA1         → Verificar resultados por proyecto
3. VF04         → Lista de posiciones facturables activas
4. VF01         → Crear facturas SD
5. CJ88/CJ8G   → Liquidar proyectos (costes → receptores)
6. KO88         → Liquidar ordenes relacionadas
7. Cierre FI    → Cerrar periodo contable
```

---

## 12. Consultas SQL/MCP de Facturacion

```javascript
// Pedidos de venta con referencia a proyectos PS
GetSqlQuery({
  query: `SELECT v.VBELN, v.POSNR,
                 v.MATNR, v.KWMENG AS CANTIDAD,
                 v.PSPNR AS WBS_INTERNO,
                 p.POSID AS WBS,
                 v.NETWR AS VALOR_NETO
          FROM VBAP v
          INNER JOIN PRPS p ON p.PSPNR = v.PSPNR
          WHERE v.VBTYP = 'C'  -- pedido de venta
            AND v.PSPNR IS NOT NULL
          ORDER BY v.VBELN, v.POSNR`
})

// Plan de facturacion con estado de hitos
GetSqlQuery({
  query: `SELECT f.VBELN, f.POSNR,
                 fp.FPLTR, fp.FKDAT,
                 fp.FAKWR AS IMPORTE_PLAN,
                 fp.FAKSP AS BLOQUEO,
                 fp.MSCHL AS CLAVE_HITO,
                 m.MLNAM AS NOMBRE_HITO,
                 m.MLKTR AS CONFIRMADO
          FROM VBAP f
          INNER JOIN FPLT fp ON fp.FPLNR = f.FPLNR
          LEFT JOIN AFMG m ON m.DPROG = fp.MSCHL
          WHERE f.PSPNR IS NOT NULL
            AND fp.FAKWR > 0
          ORDER BY f.VBELN, fp.FPLTR`
})

// Ingresos facturados por proyecto
GetSqlQuery({
  query: `SELECT p.POSID, a.KSTAR, a.GJAHR, a.POPER,
                 SUM(a.HSL) AS INGRESO_REAL
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.RRCTY = '0'
            AND a.KSTAR LIKE '8%'  -- clases de ingreso
            AND a.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, a.KSTAR, a.GJAHR, a.POPER
          ORDER BY p.POSID, a.POPER`
})

// WBS con indicador de facturacion activo
GetSqlQuery({
  query: `SELECT w.POSID, w.POST1, w.FAKKZ,
                 w.PRCTR, w.PBUKR
          FROM PRPS w
          WHERE w.FAKKZ = 'X'
            AND w.PBUKR = '1000'
          ORDER BY w.POSID`
})
```

---

## 13. Fiori Apps de Facturacion e Ingresos

| App ID | Descripcion |
|---|---|
| F2389 | Project Cockpit (vision integrada) |
| F3099 | Project Billing Overview |
| F4102 | Revenue Recognition for Projects |
| VF04 | Maintain Billing Due List |

---

## 14. Mejores Practicas de Facturacion PS

1. **Alinear hitos con entregables contractuales**: Los hitos del billing plan deben coincidir exactamente con los entregables definidos en el contrato con el cliente. Evitar hitos tecnicos sin valor contractual.

2. **FAKKZ solo en WBS hoja**: Activar el indicador de facturacion solo en los WBS de nivel mas bajo (operativos). Los WBS de agrupacion no deben ser facturables directamente.

3. **Billing plan inmutable post-firma**: Una vez firmado el contrato, el billing plan no debe modificarse sin aprobacion formal. Los cambios en importes o fechas impactan la contabilidad de ingresos.

4. **Reconocimiento de ingresos automatico**: Configurar el calculo automatico de CJ45 en el cierre de periodo (batch job). El reconocimiento manual es propenso a errores y olvidos.

5. **Separar WBS de coste de WBS de facturacion**: En proyectos complejos, tener WBS dedicados a imputar costes (operativos) y WBS separados para facturacion (billing elements) facilita el control y el reporting.

6. **DP91 para T&M**: En contratos Time & Material, configurar correctamente el perfil DIP para que DP91 capture todos los costes incurridos. Omitir tipos de coste en el perfil DIP genera subfacturacion.
