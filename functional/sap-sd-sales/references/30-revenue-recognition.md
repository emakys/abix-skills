# Revenue Recognition y Facturacion Avanzada SD

## Concepto

Revenue recognition determina CUANDO se reconoce el ingreso contablemente.
No siempre coincide con la fecha de facturacion.

```
Escenarios:
  A) Entrega = Revenue (estandar: factura post-entrega)
  B) Milestone billing (proyecto: revenue por hito cumplido)
  C) Periodic billing (suscripcion: revenue mensual)
  D) Deferred revenue (cobro anticipado, revenue diferido)
  E) Resource-related billing (por horas/esfuerzo)
```

## Billing Plans (Planes de Facturacion)

### Concepto
Un billing plan define CUANDO y CUANTO se factura de un pedido.
Se configura a nivel de posicion del pedido (VBKD-FPLNR).

### Tipos de billing plan
| Tipo | Descripcion | Uso |
|------|-------------|-----|
| 01 | Periodic billing | Suscripciones, rentas, servicios recurrentes |
| 02 | Milestone billing | Proyectos, hitos de avance |

### Config Periodic Billing (01)
```
VOV8: tipo doc ZS (servicio) → billing plan type 01
VOV7: item category TAO → billing plan type 01, billing relevance I

Ejemplo: Contrato servicio anual $12,000
  Billing plan:
    01.01 — $1,000 (Enero)
    01.02 — $1,000 (Febrero)
    ...
    01.12 — $1,000 (Diciembre)

Cada mes VF04 procesa la fecha vencida → genera factura F2 por $1,000
```

### Config Milestone Billing (02)
```
VOV8: tipo doc ZP (proyecto) → billing plan type 02
VOV7: item category TAP → billing plan type 02, billing relevance I

Ejemplo: Proyecto implementacion $100,000
  Billing plan:
    Hito 1: Blueprint completo — 20% ($20,000) — fecha estimada
    Hito 2: Realizacion completa — 40% ($40,000)
    Hito 3: Go-live — 30% ($30,000)
    Hito 4: Soporte post-live — 10% ($10,000)

  Cada hito se marca como "alcanzado" → VF04 genera factura
  Milestone status: Not reached / Reached / Blocked
```

### Tablas billing plan
| Tabla | Contenido |
|-------|-----------|
| FPLA | Header del billing plan |
| FPLNR | Link en VBKD (posicion del pedido) |
| FPLT | Dates/milestones del plan |
| FPLT-FKDAT | Fecha facturacion planificada |
| FPLT-FAKWR | Monto a facturar |
| FPLT-FKSAF | Status (A=not reached, B=blocked, C=reached) |

### Queries MCP billing plans
```sql
-- Billing plans pendientes de facturacion
SELECT FPLA.FPLNR, FPLT.FKDAT, FPLT.FAKWR, FPLT.FKSAF, FPLT.AFDAT
FROM FPLA JOIN FPLT ON FPLA.FPLNR = FPLT.FPLNR
WHERE FPLT.FKSAF <> 'C' AND FPLT.FKDAT <= '{hoy}'

-- Billing plan de un pedido
SELECT VBKD.VBELN, VBKD.POSNR, VBKD.FPLNR,
       FPLT.FKDAT, FPLT.FAKWR, FPLT.FKSAF
FROM VBKD JOIN FPLA ON VBKD.FPLNR = FPLA.FPLNR
JOIN FPLT ON FPLA.FPLNR = FPLT.FPLNR
WHERE VBKD.VBELN = '{pedido}'
ORDER BY FPLT.FKDAT

-- Milestones alcanzados vs pendientes
SELECT FKSAF, COUNT(*) as NUM, SUM(FAKWR) as VALOR
FROM FPLT WHERE FPLNR IN (
  SELECT FPLNR FROM VBKD WHERE VBELN = '{pedido}'
) GROUP BY FKSAF
```

## Down Payment Processing (Anticipos)

### Proceso
```
1. VA01: Pedido normal (OR) con posicion para anticipo
   - O crear pedido tipo FAZ (down payment request)

2. VF01: Factura pro-forma o down payment request
   - Tipo factura: FAZ (down payment request)
   - Genera: solicitud de anticipo (no es factura real)

3. F-29: Cobro del anticipo en FI
   - Posting: D: Banco, C: Anticipo recibido (special GL indicator A)
   - Anticipo queda como partida especial del cliente

4. VA01 + VL01N + VF01: Proceso normal de venta
   - Factura final F2 por el total

5. F-39: Compensacion del anticipo contra factura final
   - Clear: anticipo vs factura
   - Resultado neto: cliente solo paga la diferencia
```

### Config anticipos
```
SPRO → SD → Billing → Down Payment Processing:
  - Special GL indicator: A (down payment)
  - Account determination: cuentas de anticipo separadas
  - Billing type: FAZ

Reconciliation account: anticipo usa cuenta especial (no AR normal)
Indicador GL especial: A → cuenta 195000 (anticipos recibidos)
```

## Revenue Recognition Clasico (VF44)

### Tipos de reconocimiento
| Tipo | Reconocimiento | Ejemplo |
|------|---------------|---------|
| Time-based | Proporcional al tiempo | Licencia anual |
| Service-based | Al completar servicio | Consultoria |
| Milestone-based | Por hito alcanzado | Proyecto |
| Delivery-based | Al entregar (default) | Venta producto |

### Config
```
SPRO → SD → Billing → Revenue Recognition:
  - Define revenue recognition types
  - Assign to material types
  - Define posting rules

VF44: Revenue recognition processing
  - Procesa ingresos diferidos
  - Genera postings de reconocimiento

Tablas: VBREVE (items rev recognition)
```

### Asientos tipicos revenue diferido
```
Al facturar (ingreso diferido):
  D: 140000 AR cliente              $12,000
  C: 270000 Ingreso diferido        $12,000

Reconocimiento mensual (VF44):
  D: 270000 Ingreso diferido         $1,000
  C: 800000 Ingreso por ventas       $1,000
  (× 12 meses)
```

## Event-Based Revenue Recognition (S/4HANA)

### IFRS 15 / ASC 606 Compliance
```
S/4HANA Revenue Accounting (RAR):
  - 5 pasos de IFRS 15:
    1. Identificar contrato
    2. Identificar obligaciones de desempeno
    3. Determinar precio de transaccion
    4. Asignar precio a obligaciones
    5. Reconocer ingreso al satisfacer obligaciones

  Transaction: FARR_* (Revenue Accounting)
  Config: SPRO → Financial Accounting → Revenue Accounting

  Integracion con SD:
    - Factura SD trigger → evento en RAR
    - RAR determina reconocimiento segun reglas IFRS 15
    - Posting automatico en FI
```

## Resource-Related Billing (DPRA)

### Concepto
Facturacion basada en recursos consumidos (horas, materiales).
Tipico en servicios, mantenimiento, proyectos.

```
Flujo:
  1. Service order (PM) o Project (PS) registra tiempo/material
  2. DPRA (Dynamic Item Processor): selecciona items para billing
  3. VF01: genera factura basada en recursos consumidos
  4. Pricing: por hora, por material, tarifa por tipo recurso

Config:
  - SPRO → SD → Billing → Resource-Related Billing
  - DIP (Dynamic Item Processor) profile
  - Source: CO internal order, PS WBS element, PM service order
```

## Intercompany Billing

### Proceso
```
Org ventas 1000 (vende) → Planta de org 2000 (entrega)

Dos facturas:
  1. F2: Factura al cliente (org 1000 → cliente)
     D: AR cliente     C: Revenue org 1000

  2. IV: Factura intercompany (org 2000 → org 1000)
     En org 2000: D: Interco AR, C: Interco Revenue
     En org 1000: D: COGS/Interco expense, C: Interco AP

Config:
  SPRO → SD → Billing → Intercompany Billing:
    - Assign plants to sales orgs (internal)
    - Define internal customer (org 2000 es "cliente" interno de org 1000)
    - IV pricing procedure (precio interno entre orgs)
    - VTFL copy control para IV
```

## Queries MCP avanzadas

```sql
-- Facturas con billing plan (periodicas/milestone)
SELECT VBRK.VBELN, VBRK.FKART, VBRK.NETWR, VBRK.FKDAT,
       VBRP.AUBEL, VBKD.FPLNR
FROM VBRK JOIN VBRP ON VBRK.VBELN = VBRP.VBELN
JOIN VBKD ON VBRP.AUBEL = VBKD.VBELN AND VBRP.AUPOS = VBKD.POSNR
WHERE VBKD.FPLNR <> '' AND VBRK.VKORG = '{org}'

-- Anticipos pendientes de clearing
-- (partidas abiertas con GL indicator especial)
SELECT KUNNR, BELNR, DMBTR, UMSKZ FROM BSID
WHERE UMSKZ = 'A' AND AUGDT = '00000000' AND BUKRS = '{sociedad}'

-- Revenue diferido pendiente de reconocimiento
SELECT VBELN, POSNR, NETWR, ERDAT FROM VBREVE
WHERE RVSTA <> 'C' -- no completamente reconocido

-- Intercompany billing pendiente
SELECT LIKP.VBELN, LIKP.VSTEL, LIKP.VKORG FROM LIKP
WHERE LIKP.VKORG <> (SELECT VKORG FROM T001W WHERE WERKS = LIKP.WERKS FETCH FIRST 1 ROW ONLY)
AND NOT EXISTS (SELECT 1 FROM VBFA WHERE VBFA.VBELV = LIKP.VBELN AND VBFA.VBTYP_N = 'P')
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| Billing plan date not reached | Fecha milestone futura | Esperar o adelantar fecha |
| Milestone not reached | Status FKSAF <> C | Marcar milestone como alcanzado |
| Down payment not cleared | F-39 no ejecutado | Ejecutar clearing manual |
| Revenue recognition error | Config VF44 incompleta | Revisar tipos y cuentas |
| Intercompany: internal customer missing | Falta asignacion planta→org interna | SPRO config |
| Periodic billing: no items selected | Fecha billing plan no coincide con VF04 run | Verificar fechas en FPLT |
