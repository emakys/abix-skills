# Integracion Cross-Module SAP PS

## Introduccion

SAP PS es uno de los modulos con mayor integracion en el sistema SAP. Los proyectos generan flujos de datos con practicamente todos los modulos funcionales. Esta referencia documenta las integraciones clave, los puntos de sincronizacion, los flujos de datos y los documentos que se generan en cada modulo como resultado de las operaciones de PS.

---

## 1. PS ↔ CO (Controlling)

### 1.1 Costes de Proyecto en CO

PS y CO estan profundamente integrados. En SAP S/4HANA 2023, todos los costes de proyecto fluyen al **Universal Journal (ACDOCA)** con dimension de objeto PS.

```
FLUJO DE COSTES PS → CO

Proyecto / WBS (PS)
    |
    ├── Costes primarios (de FI: facturas, CC)
    |       → Clase de coste tipo 1 (primaria)
    |       → Tabla ACDOCA, campo PS_PSP_PNR
    |
    ├── Costes secundarios (de CO: imputacion actividad, overhead)
    |       → Clase de coste tipo 3 (interna)
    |       → Confirmacion de actividad de red → cargo a WBS
    |
    ├── Overhead calculado (CJ44 / CJA1)
    |       → Esquema de calculo (KALSM) aplica % sobre costes directos
    |       → Cargo adicional al WBS con clase de coste de overhead
    |
    └── COSP / COSS (resumen CO) + ACDOCA (documento individual)
```

### 1.2 Objetos CO en PS

Cada elemento WBS crea automaticamente un **objeto CO** en la contabilidad de costes:

| Objeto PS | Objeto CO | Descripcion |
|-----------|-----------|-------------|
| Elemento WBS | PSP (Project WBS) | Portador de costes de proyecto |
| Red de trabajo | ORD (Orden CO) | La red es tecnicamente una orden CO tipo PS |
| Actividad externa | ORD | Suborden de la red |

### 1.3 Liquidacion PS → CO

El proceso de liquidacion (CJ88) transfiere costes desde el WBS a receptores CO:

```
LIQUIDACION WBS → RECEPTORES CO

WBS (saldo de costes)
    |
    ├── → Centro de Coste (KST)
    |     Tabla: COSP del CC receptor
    |     Documento: Documento CO liquidacion
    |
    ├── → Orden CO Interna (IOR)
    |     Para proyectos de mantenimiento o mejora
    |
    ├── → Elemento de Resultado (CO-PA)
    |     Analisis de rentabilidad por proyecto
    |     Campo PA: Proyecto, Cliente, Producto
    |
    └── → WBS padre / otro WBS
          Liquidacion dentro del mismo proyecto
          Para consolidar en WBS de nivel superior
```

**Tablas implicadas:**
- `COBRB` — Reglas de liquidacion
- `ACDOCA` — Documentos de liquidacion (S/4HANA)
- `COSP` — Resumen de costes del objeto receptor

### 1.4 Claves de Asentamiento CO-PS

| Clave | Descripcion | Tipo |
|-------|-------------|------|
| ANL | Liquidacion a activo fijo | AuC |
| KOS | Liquidacion a CC | CC |
| ORD | Liquidacion a orden CO | Orden |
| PSP | Liquidacion a WBS | WBS |
| GL | Liquidacion a cuenta GL | GL |
| PAO | Liquidacion a CO-PA | PA |

### 1.5 Calculo de Overhead en PS

El overhead (gastos generales) se calcula periodicamente sobre los costes directos del proyecto:

```
CJ44 / CJA1 (Overhead Calculation)
    |
    ├── Leer costes directos del WBS (clase de coste primaria)
    ├── Aplicar tasa de overhead del esquema de calculo
    ├── Crear cargo adicional al WBS (clase de coste de overhead)
    └── Contabilizar automaticamente en ACDOCA
```

**Configuracion SPRO:**
```
Controlling > Product Cost Controlling > Cost Object Controlling
> Product Cost by Order > Period-End Closing > Overhead
> Define Costing Sheets (Esquemas de calculo)
```

**Query MCP - Overhead calculado por proyecto:**
```sql
SELECT p.posid, p.post1, c.kstar, ck.ktext,
       SUM(c.wkg001+c.wkg002+c.wkg003+c.wkg004+c.wkg005+c.wkg006+
           c.wkg007+c.wkg008+c.wkg009+c.wkg010+c.wkg011+c.wkg012) AS overhead
FROM prps p
INNER JOIN cosp c ON c.objnr = CONCAT('PR', p.pspnr)
INNER JOIN csku ck ON ck.kstar = c.kstar AND ck.kokrs = '1000'
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND c.wrttp = '11' AND c.gjahr = '2024'
  AND SUBSTRING(c.kstar,1,1) = '9'  -- Clases de coste de overhead suelen empezar por 9
GROUP BY p.posid, p.post1, c.kstar, ck.ktext
```

---

## 2. PS ↔ FI (Financial Accounting)

### 2.1 Activo en Curso (AuC - Asset Under Construction)

Para proyectos capitalizables, los costes se capitalizan progresivamente en un AuC:

```
FLUJO PS → FI (CAPITALIZACION)

Factura proveedor (FB60 / MIRO)
    |
    ├── Posicion con imputacion WBS (elemento de cuenta)
    └── → Cargo al WBS (coste real en CO/PS)

MENSUAL: CJ88 (Liquidacion periodica)
    |
    └── WBS → AuC (Activo en Curso)
              Documento FI: Cuenta activo AuC DEBE
                            Cuenta puente de liquidacion HABER
              Tabla ANLC (valores de activo)

AL FINALIZAR: AIAB + AIBU (Distribucion AuC → Activo Definitivo)
    |
    └── AuC → Activo definitivo (bien terminado)
              Empieza depreciacion normal
              Tabla ANLC del activo definitivo
```

**Configuracion SPRO cuentas:**
```
Financial Accounting > Asset Accounting > Integration with GL
> Additional Account Assignment Objects > Assign Account Assignment Objects to Depreciation Areas
```

### 2.2 Documentos FI generados por PS

| Operacion PS | Documento FI generado |
|-------------|----------------------|
| Liquidacion WBS → AuC | Documento ANLA (activo) |
| Liquidacion WBS → GL | Documento FI (BKPF/BSEG) |
| Overhead de proyecto | Documento CO sin FI (si es solo CO) |
| Confirmacion de actividad (tarifas) | Documento CO + FI (si clase primaria) |
| Analisis de resultados (POC) | Documento FI con provisiones WIP |

### 2.3 WIP (Work In Progress) en PS

Para proyectos de servicio con reconocimiento de ingresos, el **Trabajo en Proceso (WIP)** se calcula con KKA2 y se contabiliza en FI:

```
CALCULO WIP (KKA2)

Ingresos reconocidos = Ingresos Totales * % Avance (POC)
Costes reconocidos = Costes Totales * % Avance
WIP = Costes Incurridos - Costes Reconocidos

SI WIP > 0 (hay mas costes que ingresos):
    → Debito cuenta WIP (Activo en balance)
    → Credito cuenta de cargo WIP (P&L)

SI WIP < 0 (proyecto sobrefinanciado):
    → Debito cuenta Provision (P&L)
    → Credito Provision por perdida (Pasivo)
```

**Tablas:** `KEKO` (costes de produccion), `ACDOCA` (documentos WIP)

### 2.4 Contabilizacion Directa FI → WBS

Cualquier documento FI puede imputarse directamente a un WBS:

- **FB01:** Contabilizacion manual con campo WBS
- **FB60:** Factura de proveedor con posicion WBS
- **F-02:** Contabilizacion de reclasificacion con WBS

**Campos FI relevantes:**
| Campo | Tabla | Descripcion |
|-------|-------|-------------|
| PS_PSP_PNR | BSEG | Numero interno WBS (imputacion) |
| PROJN | BSEG | Numero de red (si aplica) |

---

## 3. PS ↔ MM (Materials Management)

### 3.1 Procurement con WBS

El flujo de aprovisionamiento completo puede vincularse a proyectos:

```
FLUJO P2P CON WBS

MRP / Necesidad detectada
    |
    ├── Componente de red (RESB) con necesidad
    └── → Solicitud de Pedido (EBAN/EBKN)
              Campo: PS_PSP_PNR
              Campo: NPLNR (numero de red si aplica)
              |
              └── Pedido de Compras (EKKO/EKPO/EKKN)
                      Campo: PS_PSP_PNR en posicion
                      Tipo imputacion: P (proyecto WBS) o N (red)
                      |
                      └── Entrada de Mercancias (MATDOC/MSEG)
                              Movimiento: 101
                              Campo: PS_PSP_PNR
                              → Stock de proyecto (tipo Q) si aplica
                              → Coste real al WBS
                              |
                              └── Factura de Proveedor (MIRO)
                                      Documento FI en ACDOCA
                                      Coste real contabilizado al WBS
```

### 3.2 Tipos de Imputacion de Pedido para PS

| Tipo Imputacion | Codigo | Receptor |
|----------------|--------|----------|
| Proyecto WBS | P | WBS elemento de cuenta |
| Red / Actividad | N | Numero de red + actividad |
| Centro de Coste | K | Centro de coste (sin PS) |
| Activo | A | Numero de activo fijo |

### 3.3 Stock de Proyecto (Stock Especial Q)

```
GESTION STOCK DE PROYECTO

Entrada al Stock de Proyecto:
    Mov. 101 (EM de pedido) → Stock Q + numero WBS
    Mov. 411 Q → Transferencia de stock normal a stock proyecto

Consumo del Stock de Proyecto:
    Mov. 221 → Salida a proyecto (cargo coste real al WBS)
    Mov. 261 → Salida para actividad de red
    Mov. 412 Q → Devolucion a stock normal

Visibilidad:
    MMBE → Stock especial Q por WBS
    MB54 → Lista de stock de proyecto por proyecto
```

### 3.4 MRP para Proyectos

El MRP genera necesidades basandose en los componentes de red:

```
FLUJO MRP ORIENTADO A PROYECTO

Componente de red (CN22)
    |-- Indicador MRP = 1 (activo)
    |-- Fecha de necesidad (de programacion de actividad)
    |
    └── MD01 / MD41 (Planificacion de Necesidades)
            |
            └── Propuesta de aprovisionamiento
                    |
                    ├── Material en stock → Reserva cubierta
                    └── Material sin stock → Solicitud de Pedido
                            Fecha pedido = Fecha necesidad - Lead time
```

### 3.5 Tablas Clave PS-MM

| Tabla | Descripcion | Campos PS |
|-------|-------------|-----------|
| RESB | Reservas de material | PS_PSP_PNR, AUFNR (red) |
| EKKN | Imputacion de pedido | PS_PSP_PNR, NPLNR, AUFNR |
| MATDOC | Documentos de material (S/4) | PS_PSP_PNR, PROJK (stock Q) |
| MKPF/MSEG | Doc. material (clasico) | PS_PSP_PNR, PROJK |

**Query MCP - Pedidos y entregas por proyecto:**
```sql
SELECT e.ebeln, e.ebelp, e.txz01, e.menge AS qty_pedido,
       EM.menge AS qty_entregada, e.netpr AS precio,
       p.posid AS wbs
FROM ekpo e
INNER JOIN ekkn k ON k.ebeln = e.ebeln AND k.ebelp = e.ebelp
INNER JOIN prps p ON p.pspnr = k.ps_psp_pnr
LEFT JOIN (
    SELECT ebeln, ebelp, SUM(menge) AS menge
    FROM matdoc WHERE bwart = '101' GROUP BY ebeln, ebelp
) EM ON EM.ebeln = e.ebeln AND EM.ebelp = e.ebelp
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
  AND e.loekz <> 'L'
ORDER BY e.ebeln, e.ebelp
```

---

## 4. PS ↔ SD (Sales & Distribution)

### 4.1 Vinculacion Pedido de Cliente — Proyecto

Un proyecto puede estar vinculado a un pedido de cliente SD para:
- Milestone Billing (facturacion por hitos)
- Resource-Related Billing (facturacion por costes reales)
- Control de ingresos planificados

```
FLUJO PS ↔ SD

Pedido de Cliente (SD - VA01)
    |
    ├── Posicion con elemento WBS asignado
    |       → Campo VBAP-PS_PSP_PNR
    |       → Control ingresos planificados en WBS
    |
    └── Hito de facturacion en Red PS (CN30)
            |
            └── Al alcanzar hito → marcar en CN31
                    |
                    └── VBOF → Actualiza condicion de pago en pedido
                            |
                            └── VF01/VF04 → Factura SD
                                    |
                                    └── Ingreso reconocido en WBS (via KKA2)
```

### 4.2 Resource-Related Billing (Facturacion por Recursos)

```
DP90 - RESOURCE-RELATED BILLING

Costes reales del WBS (ACDOCA)
    |
    ├── DP90: Selecciona costes facturables del periodo
    |           - Por clase de coste configurable
    |           - Con precio de venta (diferente al coste)
    |
    ├── Propuesta de facturacion → revision del usuario
    |
    ├── DP91: Genera solicitud de facturacion SD
    |           → Documento SD (posicion de pedido tipo billing request)
    |
    └── VF01: Genera factura definitiva al cliente
```

### 4.3 Milestone Billing

```
FLUJO MILESTONE BILLING

1. Crear hito en red (CN30)
   - Tipo: Hito de facturacion
   - Importe o % del total
   - Fecha planificada

2. Vincular hito al pedido SD (VA02)
   - Posicion de pedido tipo "M" (milestone)
   - Division de facturacion: fecha = fecha hito

3. Alcanzar hito fisicamente
   - CN31: Marcar como alcanzado + fecha real

4. VBOF: Actualizar SD con nueva fecha
   - Ajusta la programacion de facturacion

5. VF04: Generar factura
   - La posicion ahora esta disponible para facturar
```

### 4.4 Tablas Clave PS-SD

| Tabla | Descripcion | Campos PS |
|-------|-------------|-----------|
| VBAP | Posicion de pedido cliente | PS_PSP_PNR |
| VBKD | Datos comerciales del pedido | - |
| FPLT | Plan de facturacion | MLNR (numero hito) |
| MLST | Hitos de red | AUFNR, VORNR |

---

## 5. PS ↔ PM (Plant Maintenance)

### 5.1 Ordenes de Mantenimiento vinculadas a Proyecto

Para proyectos de mantenimiento mayor o paradas de planta, las **Ordenes de Mantenimiento (PM)** se vinculan a WBS de PS:

```
FLUJO PS ↔ PM

WBS del Proyecto de Mantenimiento
    |
    └── Orden PM (IW31 / IW32)
            |-- Campo: WBS Element (PS_PSP_PNR en AUFK)
            |-- Los costes de la orden PM se imputan al WBS PS
            |
            ├── Piezas de repuesto → Reservas de material con WBS
            ├── Mano de obra técnica → Confirmaciones de PM con WBS
            └── Servicios externos → Pedidos de compra con WBS
                    |
                    └── Liquidacion PM → WBS
                            WBS → CC Mantenimiento (CJ88)
```

### 5.2 Datos de la Integracion PM-PS

| Campo en PM | Tabla PM | Descripcion |
|-------------|----------|-------------|
| PS_PSP_PNR | AUFK | WBS asignado a la orden PM |
| AUFNR | AUFK | Numero de orden PM |

### 5.3 Objetos Tecnicos y WBS

Para proyectos de revision de equipos:
- Equipo (EQUI) → vinculado al Objeto Tecnico de PM
- WBS → vinculado a la Orden PM del equipo
- Historial de costes de mantenimiento → trazable via WBS

### 5.4 Confirmaciones en Ordenes PM con WBS

Las confirmaciones de mano de obra en ordenes PM (IW41) generan costes en el WBS vinculado:
```
IW41 (Confirmacion PM)
    → AUFK (orden PM) → PS_PSP_PNR (WBS)
    → Clase de coste de mano de obra (KP26)
    → Coste real en WBS via ACDOCA
```

---

## 6. PS ↔ HR (Human Resources)

### 6.1 CATS (Cross-Application Time Sheet)

**CATS** es la interfaz principal entre HR/tiempo y PS. Permite a los empleados registrar horas trabajadas asignadas a proyectos:

```
FLUJO CATS → PS

Empleado registra horas (CAT2)
    |-- Fecha y horas por dia
    |-- Centro de coste del empleado
    |-- WBS o red/actividad de destino
    |
    └── CATA (Transferencia CATS)
            |
            ├── → Confirmacion de actividad de red (CN25)
            |         Horas reales en la actividad
            |
            ├── → Imputacion CO al WBS
            |         Clase de coste de mano de obra
            |         Tarifa de la actividad de proceso (KP26)
            |
            └── → Nomina HR (si CATS integrado con Payroll)
                      Verificacion de horas por trabajador
```

### 6.2 Recursos en Redes PS (HR Integration)

Las redes PS pueden planificar **recursos humanos** vinculados a maestros de HR:

```
Actividad de red (CN22)
    |
    └── Recurso humano asignado (dato de planificacion)
            |-- Numero de personal (PERNR de HR)
            |-- Horas planificadas
            |-- Tarifa planificada (de KP26 o de la posicion HR)
            |
            └── CATS: Empleado confirma horas reales
                    → Automaticamente a la actividad de red
```

### 6.3 Determinacion de Tarifas de Hora

La tarifa que se aplica al cargar horas a un WBS viene de:
1. **Puesto de trabajo / Centro de trabajo** (CR01): Tarifa estandar
2. **Actividad de proceso** (KP26): Tarifa planificada por CC y actividad
3. **Tarifa real del periodo**: Calculada al final del periodo en KSS1

```
CARGO DE HORA A WBS

    Horas confirmadas * Tarifa de actividad = Coste

    Ejemplo:
    10 horas * 85 EUR/hora = 850 EUR
    → Debito WBS (clase de coste de mano de obra)
    → Credito CC del empleado (liquidacion interna)
```

### 6.4 Tablas Clave PS-HR

| Tabla | Descripcion |
|-------|-------------|
| CATSDB | Base de datos CATS (registros de tiempo) |
| CATSP | Posiciones de tiempo CATS |
| PERNR | Datos del personal (HR) |
| CRCO | Asignacion de puestos de trabajo a CC |

---

## 7. Diagrama de Flujo Integrado Completo

```
                        +-----------+
                        |  CLIENTE  |
                        +-----------+
                             |
                    SD: Pedido de Cliente
                    (VA01, con WBS asignado)
                             |
                    +--------+---------+
                    |    PROYECTO PS   |
                    |  WBS + Red+Acts  |
                    +--------+---------+
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
    +----------+      +----------+       +-----------+
    |    MM    |      |    FI    |       |    HR     |
    |Pedidos   |      |Facturas  |       |CATS Horas |
    |Stock Q   |      |AuC/Activ |       |Nomina     |
    |MRP       |      |WIP/RA    |       |Recursos   |
    +----------+      +----------+       +-----------+
          |                  |                  |
          +------------------+------------------+
                             |
                    +--------+---------+
                    |       CO         |
                    |  ACDOCA/COSP     |
                    |  Costes WBS      |
                    |  Overhead        |
                    |  Liquidacion     |
                    +--------+---------+
                             |
          +------------------+------------------+
          |                  |                  |
          v                  v                  v
    +----------+      +----------+       +-----------+
    |  FI-AA   |      |   CO-PA  |       |    PM     |
    |  Activos |      | Rentab.  |       |Ord.Mant.  |
    |  Deprec. |      | por Proy |       |Objetos T. |
    +----------+      +----------+       +-----------+
          |
          v
    +----------+
    |    SD    |
    | Factura  |
    | Hitos    |
    | DP90     |
    +----------+
```

---

## 8. Tabla de Documentos por Integracion

| Integracion | Transaccion | Tabla Origen | Tabla Destino |
|-------------|-------------|--------------|---------------|
| PS → CO | CJ88 (liq.) | COBRB | ACDOCA, COSP |
| PS → FI-AA | CJ88 + AIBU | COBRB | ANLC, ACDOCA |
| PS → FI (WIP) | KKA2 | COSP | ACDOCA, BKPF |
| PS → SD (hito) | CN31 + VF04 | MLST, FPLT | VBRK, VBRP |
| PS → SD (DP90) | DP90 + VF01 | ACDOCA | VBRK, VBRP |
| MM → PS | ME21N, MIGO | EKKN, MATDOC | COSP, ACDOCA |
| HR (CATS) → PS | CATA | CATSDB | ACDOCA, COSP |
| PM → PS | IW32 (asignar WBS) | AUFK | ACDOCA, COSP |

---

## 9. Puntos de Sincronizacion Criticos

### 9.1 Cierre de Periodo (Secuencia PS)

```
Orden recomendada para cierre de periodo en PS:

1. Cerrar periodos de logistica (MM, SD) para postings directos
2. Ejecutar MRP final (MD01)
3. Calcular overhead de proyecto (CJ44 / CJA1)
4. Ejecutar Analisis de Resultados (KKA2) - solo proyectos SD
5. Liquidar proyectos (CJ88) en modo periodico
6. Verificar saldos por WBS (S_ALR_87013532)
7. Cerrar periodo CO (OKP1)
8. Ejecutar proceso de cierre FI (F.16, etc.)
```

### 9.2 Reconciliacion PS-FI

En S/4HANA con Universal Journal (ACDOCA), PS y FI comparten el mismo documento, eliminando la necesidad de reconciliacion. Sin embargo, se deben verificar:

```sql
-- Verificar coherencia ACDOCA vs COSP para un WBS
SELECT p.posid,
       SUM(a.hsl) AS suma_acdoca,
       c.cosp_total
FROM prps p
INNER JOIN acdoca a ON a.ps_psp_pnr = p.pspnr AND a.gjahr = '2024'
LEFT JOIN (
    SELECT objnr, SUM(wkg001+wkg002+wkg003+wkg004+wkg005+wkg006+
                       wkg007+wkg008+wkg009+wkg010+wkg011+wkg012) AS cosp_total
    FROM cosp WHERE wrttp = '11' AND gjahr = '2024' AND versn = '000'
    GROUP BY objnr
) c ON c.objnr = CONCAT('PR', p.pspnr)
WHERE p.psphi = (SELECT pspnr FROM proj WHERE pspid = 'P-2024-001' AND vernr = '00')
GROUP BY p.posid, c.cosp_total
```

---

## 10. Configuracion de Integracion en SPRO

### 10.1 PS-CO

```
Controlling > General Controlling > Organization > Maintain Controlling Area
→ Activar PS para la sociedad CO

Project System > Costs > Planned Costs > Networks
→ Asignar tipos de actividad y tarifas

Project System > Costs > Settlement
→ Definir tipos de liquidacion y claves de asentamiento
```

### 10.2 PS-FI-AA (Activos)

```
Financial Accounting > Asset Accounting > Integration with General Ledger
→ Definir cuentas de AuC

Project System > Costs > Settlement
→ Perfil de asentamiento con receptores tipo 'A' (AuC)
```

### 10.3 PS-MM

```
Project System > Material > Settings for Material Planning
→ Parametros de planificacion de materiales para redes

Project System > Material > Stock Management
→ Cuentas para stock de proyecto
```

### 10.4 PS-SD

```
Project System > Revenues and Earnings
→ Definir claves de analisis de resultados

Sales and Distribution > Billing > Billing Plans
→ Configurar planes de facturacion por hitos (Milestone Plans)

Project System > Revenues and Earnings > Resource-Related Billing
→ Configurar DP90 (Dynamic Item Processor)
```

### 10.5 PS-HR (CATS)

```
Cross-Application Components > Time Sheet (CATS)
→ Configurar perfil CATS con destinos PS (WBS, red, actividad)

Human Capital Management > Time Management > CATS
→ Definir workflow de aprobacion de hojas de tiempo

Project System > Structures > Operative Structures > Network
> Settings for Activities > Define Default Values
→ Vincular tipos de actividad HR a actividades de red PS
```

---

## 11. Buenas Practicas de Integracion

1. **Definir la estructura WBS antes de cualquier integracion** — Las tablas de otros modulos (EKKN, BSEG, CATSDB) almacenan el numero interno del WBS, que no cambia. Cambios en la clave WBS despues de postings pueden causar inconsistencias.

2. **Alinear periodos contables FI/CO/PS** — El cierre de periodo debe coordinarse entre modulos. PS no puede liquidar si el periodo CO esta cerrado.

3. **Verificar imputacion correcta en pedidos MM** — El tipo de imputacion (P para WBS, N para red) determina el stock y el flujo contable. Un error aqui es dificil de corregir.

4. **CATS requiere aprobacion antes de transferir** — Implementar el workflow de aprobacion de CATS para evitar transferir horas incorrectas al WBS.

5. **Coordinar hitos SD con el equipo de proyecto** — Los hitos de facturacion deben marcarse como alcanzados con la aprobacion del cliente, no automaticamente.

6. **Liquidar antes de cerrar FI** — La liquidacion de WBS (CJ88) debe ejecutarse antes de cerrar el periodo FI para que los documentos queden en el periodo correcto.

7. **Reconciliar PM-PS mensualmente** — Verificar que todos los costes de ordenes PM vinculadas a WBS esten correctamente liquidados al proyecto.

8. **Usar ACDOCA para reporting integrado** — En S/4HANA, ACDOCA permite consultas unificadas de costes de proyecto con dimensiones FI, CO, MM y SD en un solo query.
