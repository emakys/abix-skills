# Analisis de Resultados y WIP — SAP PS S/4HANA 2023

## 1. Concepto de Analisis de Resultados en PS

El Analisis de Resultados (Results Analysis / RA) en SAP PS es el proceso contable que calcula y contabiliza el resultado economico de un proyecto en curso. Responde a la pregunta: ¿cuanto ha ganado o perdido la empresa en este proyecto durante el periodo?

### Por que es necesario el Analisis de Resultados

En proyectos a largo plazo (plurianuales), los costes se incurren en periodos distintos a cuando se factura al cliente y se reconoce el ingreso. Las normas contables (IFRS 15, NIC 11, US GAAP ASC 606) exigen reconocer ingresos y costes de forma coherente con el grado de avance del proyecto.

### Objetos del Analisis de Resultados

El analisis de resultados se calcula para:
- Elementos WBS (con indicador operativo)
- Redes de proyecto
- Ordenes de proyecto (si se usan ordenes internas como objetos PS)

---

## 2. Work in Process (WIP)

El WIP (Work in Process / Trabajo en Curso) representa los costes incurridos en el proyecto que aun no se han convertido en ingresos reconocibles. Se contabiliza como un activo en el balance.

### Concepto Contable del WIP

```
Situacion tipica: proyecto en ejecucion

Costes reales incurridos:    100.000 EUR   (en ACDOCA)
Ingresos facturados:          30.000 EUR   (en ACDOCA)
Ingresos reconocibles (POC):  40.000 EUR   (calculado por RA)

WIP = Costes - Ingresos reconocidos = 100.000 - 40.000 = 60.000 EUR
     → Este WIP se contabiliza como activo en el balance
```

### Tipos de WIP en SAP PS

| Tipo | Descripcion | Contabilizacion |
|---|---|---|
| WIP a costes (Costes activados) | Costes del proyecto no cubiertos por ingresos | Debito cuenta WIP / Credito cuenta variacion existencias |
| WIP a ingresos | Ingresos anticipados sobre costes | Menos frecuente |
| Reservas de riesgo | Perdidas estimadas en proyectos deficitarios | Provision en P&L |

---

## 3. Claves de Analisis de Resultados

Las claves de analisis de resultados (RA Keys) determinan que metodo se usa para calcular el WIP y el resultado de cada proyecto.

### Configuracion SPRO

```
SPRO → Project System → Costes → Analisis de Resultados →
Definir Claves de Analisis de Resultados
Transaccion: OKG3
```

### Asignacion de la Clave RA al WBS

```
CJ20N → WBS → ficha "Controlling" → Clave de Analisis de Resultados
O bien en el perfil de presupuesto (OPS9) asignar clave por defecto
```

---

## 4. Metodos de Valoracion del WIP

### 4.1 Metodo Coste-Coste (Cost-to-Cost / POC)

Es el metodo principal para proyectos IFRS 15. El porcentaje de completitud (POC) se calcula como la proporcion de coste real sobre el coste total estimado.

```
POC = Coste Real Acumulado / Coste Total Estimado × 100

Ingreso Reconocible = Valor Contrato × POC
WIP = Coste Real - (Coste Real × Ingreso Contrato / Coste Total)

Ejemplo:
  Coste real:       80.000 EUR
  Coste total est.: 100.000 EUR
  Valor contrato:   150.000 EUR

  POC = 80.000 / 100.000 = 80%
  Ingreso reconocible = 150.000 × 80% = 120.000 EUR
  WIP = 80.000 - (80.000 × 150.000/100.000) = -40.000 (diferido)
```

### 4.2 Metodo Coste-Ingreso

El WIP se calcula como la diferencia entre costes reales e ingresos reales. Mas conservador.

```
WIP = Costes Reales - Ingresos Facturados

Si positivo → WIP activo (costes activados)
Si negativo → Ingresos diferidos (pasivo)
```

### 4.3 Metodo por Cantidad (Units of Delivery)

El reconocimiento de ingresos se basa en unidades entregadas vs unidades totales del proyecto. Util en proyectos de construccion por fases o lotes.

```
POC = Unidades entregadas / Unidades totales del proyecto × 100
Ingreso reconocido = Valor contrato × POC
```

### 4.4 Metodo de Hitos (Milestone)

Los ingresos se reconocen al confirmar hitos especificos del proyecto. Cada hito tiene un porcentaje de completitud asignado.

```
Hito 1 (Diseño): 20% → al confirmar → reconocer 20% del ingreso total
Hito 2 (Prototipo): 50% → al confirmar → reconocer 30% adicional
Hito 3 (Entrega final): 100% → al confirmar → reconocer 30% restante
```

---

## 5. Configuracion del Analisis de Resultados

### Parametros RA en SPRO

```
SPRO → Project System → Costes → Analisis de Resultados →
Definir Metodo de Analisis de Resultados
Transaccion: OKG1
```

### Cuentas Contables del RA

```
SPRO → Project System → Costes → Analisis de Resultados →
Definir Asignacion de Cuentas para Analisis de Resultados
Transaccion: OKG4
```

Las cuentas tipicas del RA incluyen:

| Cuenta | Descripcion |
|---|---|
| Cuenta WIP activo | Activo balance: costes activados del proyecto |
| Cuenta variacion WIP | P&L: variacion del WIP en el periodo |
| Cuenta ingresos diferidos | Pasivo: ingresos facturados no reconocidos |
| Cuenta provision perdidas | P&L: reserva por perdidas estimadas |
| Cuenta costes no liquidables | P&L: costes que no se recuperaran |

---

## 6. Reservas (Reserves)

Las reservas son provisiones contables para riesgos o perdidas estimadas en el proyecto.

### Tipos de Reservas en PS

| Tipo | Descripcion | Impacto |
|---|---|---|
| Reserva de riesgo | Costes adicionales no planificados | P&L negativo |
| Provision por perdidas | Proyecto deficitario (coste > ingreso estimado) | P&L negativo |
| Reserva de garantia | Coste estimado de garantia post-entrega | P&L negativo |

### Calculo Automatico de Provision por Perdidas

Si el sistema detecta que el coste total estimado supera el ingreso del contrato, genera automaticamente una provision por perdidas:

```
Si (Coste Total Estimado > Valor Contrato):
  Perdida Estimada = Coste Total Estimado - Valor Contrato
  → SAP contabiliza provision por perdidas (anticipacion de la perdida)
```

---

## 7. Transacciones de Analisis de Resultados

### KKA1 — Analisis de Resultados Individual

```
KKA1 → Ingresar numero de orden/WBS proyecto
Periodo y ejercicio → Enter
Ejecutar en TEST primero para verificar
Ejecutar REAL → genera documentos CO
```

### KKA2 — Analisis de Resultados Colectivo

```
KKA2 → Sociedad / Area CO / Rango de proyectos
Periodo y ejercicio
Ejecutar en background para grandes volumenes
```

### CJ45 / CJ46 — RA especifico para PS

```
CJ45 → Analisis de resultados individual para WBS
CJ46 → Analisis de resultados colectivo para proyectos
```

### Contabilizacion del WIP

Despues del calculo (KKA1/CJ45), el WIP se contabiliza en FI:

```
Transaccion: KKA9 (contabilizar WIP individual)
             KKAI (contabilizar WIP colectivo)
             CJ9F (contabilizar WIP para PS)
```

### Anulacion del WIP

```
Transaccion: KKA4 (anular RA individual)
             KKAC (anular RA colectivo)
```

La anulacion se usa cuando:
- El proyecto finaliza y el WIP se liquida definitivamente
- Se detecta un error en el calculo
- El proyecto se cancela

---

## 8. Tablas del Analisis de Resultados

### Tabla AUFW — Clave de Analisis de Resultados

| Campo | Descripcion |
|---|---|
| ABGSCHLUESSEL | Clave de RA |
| KTEXT | Descripcion |
| METHODE | Metodo de calculo |
| BEWERTUNG | Metodo de valoracion |

### Tabla KKBP — Datos de RA por Periodo

Almacena los valores calculados del analisis de resultados por periodo.

| Campo | Tipo | Descripcion |
|---|---|---|
| OBJNR | CHAR(22) | Numero de objeto (WBS/orden) |
| GJAHR | NUMC(4) | Ejercicio |
| POPER | NUMC(3) | Periodo |
| VERSN | CHAR(3) | Version |
| VRGNG | CHAR(4) | Tipo de valor (WIP, PROV, etc.) |
| BEKNZ | CHAR(1) | Indicador debito/credito |
| WTGBTR | CURR | Importe en moneda objeto |
| WKGBTR | CURR | Importe en moneda controlling |

### ACDOCA para WIP y RA

En S/4HANA, los asientos del WIP y RA se almacenan en ACDOCA con:

| Campo | Valor | Descripcion |
|---|---|---|
| RRCTY | '0' | Real |
| VRGNG | 'KKAL' | Calculo RA / WIP |
| GKONT | cuenta WIP | Cuenta contable de WIP |

```sql
-- WIP contabilizado por proyecto y periodo
SELECT p.POSID, a.GJAHR, a.POPER,
       a.RACCT AS CUENTA_WIP,
       SUM(a.HSL) AS WIP_MONEDA_LOCAL,
       SUM(a.KSL) AS WIP_MONEDA_CO
FROM ACDOCA a
INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
WHERE a.RLDNR = '0L'
  AND a.RRCTY = '0'
  AND a.VRGNG = 'KKAL'  -- contabilizacion WIP
  AND a.GJAHR = '2024'
  AND p.PBUKR = '1000'
GROUP BY p.POSID, a.GJAHR, a.POPER, a.RACCT
ORDER BY p.POSID, a.POPER
```

---

## 9. Periodicidad y Ciclo de Cierre PS

### Secuencia de Cierre de Periodo para Proyectos

```
Dia 1-5 del mes siguiente:
1. Finalizar confirmaciones del mes cerrado (CN27/CAT5)
2. Finalizar entradas de mercancias y facturas (MIGO/MIRO)
3. Calcular overhead proyectos (CJN1)
4. CJ45/CJ46 → Calcular WIP y RA (TEST)
5. Revisar resultados con jefes de proyecto
6. CJ9F/KKAI → Contabilizar WIP (REAL)
7. KKA9 → Contabilizar RA (REAL)
8. CJ88/CJ8G → Liquidar proyectos
9. Cierre periodo FI (F.16/OB52)
```

---

## 10. Analisis de Resultados en S/4HANA — Universal Journal

### Diferencias vs ECC

En S/4HANA 2023:
- Los valores de RA se almacenan en ACDOCA (Universal Journal) de forma integrada con FI
- No hay separacion entre tablas CO y FI para el WIP
- El ledger de grupo (ledger 0L) unifica todo
- El calculo de RA es mas rapido gracias a HANA (sin agregaciones previas)
- Commercial Project Management (CPM) ofrece RA avanzado con integracion IFRS 15 nativa

### Commercial Project Management (CPM)

CPM es la evolucion de PS para proyectos de cliente en S/4HANA 2023:

```
Funcionalidades adicionales CPM:
- Revenue Recognition nativa IFRS 15 / ASC 606
- Project Billing integrado con SD
- Customer Project Cockpit (Fiori)
- Analisis de rentabilidad en tiempo real (ACDOCA)
- Integracion con SAP S/4HANA Cloud
```

---

## 11. Reportes de Resultados

| Transaccion | Descripcion |
|---|---|
| KKA1 | Analisis de resultados individual |
| KKA2 | Analisis de resultados colectivo |
| KKAO | Informe de RA por orden/WBS |
| S_ALR_87013532 | Plan/Real del proyecto |
| CJI3 | Partidas individuales proyecto |
| GR55 | Report Painter (informes configurables) |

---

## 12. Consultas SQL/MCP de Resultados y WIP

```javascript
// Estado del WIP por proyecto y periodo
GetSqlQuery({
  query: `SELECT p.POSID, a.GJAHR, a.POPER,
                 SUM(CASE WHEN a.KSTAR LIKE '9%' THEN a.HSL ELSE 0 END)
                   AS INGRESOS,
                 SUM(CASE WHEN a.KSTAR NOT LIKE '8%'
                           AND a.KSTAR NOT LIKE '9%' THEN a.HSL ELSE 0 END)
                   AS COSTES,
                 SUM(CASE WHEN a.VRGNG = 'KKAL' THEN a.HSL ELSE 0 END)
                   AS WIP
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.RRCTY = '0'
            AND a.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID, a.GJAHR, a.POPER
          ORDER BY p.POSID, a.POPER`
})

// POC calculado por proyecto (estimacion)
GetSqlQuery({
  query: `SELECT p.POSID, p.POST1,
                 SUM(CASE WHEN a.RRCTY = '0' THEN a.HSL ELSE 0 END)
                   AS COSTE_REAL,
                 SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END)
                   AS COSTE_PLAN,
                 CASE WHEN SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END) > 0
                      THEN ROUND(
                        SUM(CASE WHEN a.RRCTY = '0' THEN a.HSL ELSE 0 END) /
                        SUM(CASE WHEN a.RRCTY = '1' THEN a.HSL ELSE 0 END) * 100, 2)
                      ELSE 0 END AS POC_PORCENTAJE
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.GJAHR = '2024'
            AND a.WRTTP IN ('01','04')
            AND p.PBUKR = '1000'
            AND p.PRFLA = 'X'
          GROUP BY p.POSID, p.POST1
          HAVING SUM(a.HSL) <> 0
          ORDER BY p.POSID`
})

// Provision por perdidas activa en proyectos
GetSqlQuery({
  query: `SELECT p.POSID,
                 SUM(CASE WHEN a.VRGNG = 'PROV' THEN a.HSL ELSE 0 END)
                   AS PROVISION_PERDIDAS
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.RRCTY = '0'
            AND a.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID
          HAVING SUM(CASE WHEN a.VRGNG = 'PROV' THEN a.HSL ELSE 0 END) <> 0
          ORDER BY p.POSID`
})
```

---

## 13. Mejores Practicas de Analisis de Resultados

1. **Definir el metodo RA por tipo de proyecto**: Proyectos de precio fijo → POC coste-coste. Proyectos T&M → metodo por ingresos reales. La eleccion del metodo debe estar documentada y aprobada por contabilidad.

2. **Actualizar la estimacion a completar (ETC)**: El POC solo es correcto si la estimacion de coste total es realista. Revisar mensualmente la estimacion "to-complete" con el jefe de proyecto.

3. **Provisionar perdidas de inmediato**: Si el proyecto se detecta como deficitario (costes superan ingresos esperados), la provision debe contabilizarse en el mismo periodo del descubrimiento. No diferir las malas noticias.

4. **Anular WIP al finalizar el proyecto**: Al liquidar el proyecto definitivamente (CJ88 final), el WIP acumulado debe anularse. Un WIP no anulado al cerrar el proyecto distorsiona el balance.

5. **Reconciliar RA con FI mensualmente**: Verificar que los asientos generados por KKA9/CJ9F coincidan con los saldos de las cuentas WIP en FI. Las discrepancias suelen indicar errores de configuracion de cuentas.

6. **Separar calculo de contabilizacion**: Siempre ejecutar el calculo (KKA1/CJ45) en TEST primero, revisar los importes con el responsable del proyecto y contabilidad, y solo entonces contabilizar (KKA9/CJ9F) en REAL. El orden no se puede invertir una vez contabilizado sin anulacion.
