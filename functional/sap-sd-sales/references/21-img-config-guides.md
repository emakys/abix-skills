# Guias de Configuracion IMG — SD paso a paso

Referencia completa de las configuraciones mas importantes del modulo SD en SPRO (IMG). Cada guia incluye ruta exacta, campos clave con descripcion, valores recomendados y tips practicos.

---

## Guia 1: Configurar Tipo de Documento de Venta (VOV8)

### Ruta SPRO
SPRO → Sales and Distribution → Sales → Sales Documents → Sales Document Header → Define Sales Document Types

### Transaccion directa
VOV8

### Procedimiento paso a paso

**Paso 1 — Copiar tipo estandar OR**
1. Entrar a VOV8
2. Seleccionar OR (Standard Order) en la lista
3. Click en "Copy As" (F6)
4. Ingresar nuevo tipo Z, por ejemplo: ZOR
5. Confirmar el copiado de entradas dependientes

**Paso 2 — Campos del header del documento**

| Campo | Nombre tecnico | Descripcion | Valor recomendado |
|-------|---------------|-------------|-------------------|
| Sales doc type | AUART | Identificador del tipo | ZOR |
| Document category | AUTYP | Categoria del documento | C (Order) |
| Number range internal | NUMKI | Rango para numeracion interna | VN (01-0099999999) |
| Number range external | NUMKE | Rango para numeracion externa | Vacio si no aplica |
| Item number increment | POSEX_INCR | Incremento posicion: 10 o 100 | 10 |
| Sub-item increment | UEPOS_INCR | Incremento sub-posicion | 10 |
| SD document category | VBTYP | Tipo de transaccion interna | C |
| Sales order block | LIFSK | Bloqueo de entrega default | Vacio |
| Billing block | FAKSK | Bloqueo de factura default | Vacio |

**Paso 3 — Campos de entrega y facturacion**

| Campo | Nombre tecnico | Descripcion | Valor recomendado |
|-------|---------------|-------------|-------------------|
| Delivery type | LFART | Tipo de entrega asociado | LF (Standard Delivery) |
| Delivery block | LIFSK | Bloqueo entrega automatico | Vacio |
| Shipping conditions | VSBED | Condicion de envio | Vacio (toma de cliente) |
| Immediate delivery | SOFORT | Crear entrega al guardar | Vacio normalmente |
| Billing type | FKART | Tipo de factura | F2 |
| Inter-company billing | FKART_IL | Factura intercompany | IV si aplica |

**Paso 4 — Determinacion de precios**

| Campo | Nombre tecnico | Descripcion | Valor recomendado |
|-------|---------------|-------------|-------------------|
| Document pricing proc | KALKS | Proc. de precios del doc | A (Standard) |
| Cust. pricing proc | Campo cliente KTGRS | Grupo pricing cliente | - |
| Pricing procedure | Resultado OVKK | Esquema asignado | RVAA01 |

**Paso 5 — Procedimientos de completitud y socios**

| Campo | Nombre tecnico | Descripcion | Valor recomendado |
|-------|---------------|-------------|-------------------|
| Incompletion procedure | UVALL | Procedimiento incompletitud | 10 (Standard order) |
| Partner determ. proc | PARVW | Procedimiento socios negocio | TA |
| Transaction group | TRVOG | Grupo de transaccion | 0 (Sales orders) |
| Screen sequence group | ABRUF_STK | Grupo de secuencia pantalla | AU |
| Status profile | STSMA | Perfil de estado | Vacio |

**Paso 6 — Campos de propuesta y control**

| Campo | Nombre tecnico | Descripcion | Valor recomendado |
|-------|---------------|-------------|-------------------|
| Proposal for deliv date | ABRUF_STK | Propuesta fecha entrega | Vacio |
| Lead time in days | BEART | Tiempo proceso | Segun logistica |
| Purchase order required | BSARK | PO obligatorio | Segun regla negocio |
| Outline agreement message | KTEXT | Mensaje acuerdo marco | Vacio |

### Tips
- Siempre copiar de OR para heredar configuraciones dependientes (categorias de posicion, etc.)
- El campo KALKS (doc pricing procedure) combinado con el de cliente y canal determina el esquema de precios (configurar en OVKK)
- Incompletion procedure 10 es el estandar para ordenes de venta; revisar campos obligatorios en OVA2
- Asegurarse de asignar number range en VN01 antes de usar el tipo

---

## Guia 2: Configurar Categoria de Posicion (VOV7)

### Ruta SPRO
SPRO → Sales and Distribution → Sales → Sales Documents → Sales Document Item → Define Item Categories

### Transaccion directa
VOV7

### Procedimiento paso a paso

**Paso 1 — Copiar categoria estandar TAN**
1. Entrar a VOV7
2. Seleccionar TAN (Standard Item) como base
3. F6 para copiar, asignar nombre tipo ZTAN
4. Ajustar campos segun comportamiento requerido

**Paso 2 — Control de facturacion**

| Campo | Nombre tecnico | Descripcion | Valor |
|-------|---------------|-------------|-------|
| Billing relevance | FKREL | Relevancia para factura | A = Delivery-related billing |
| | | | B = Order-related billing |
| | | | C = Not billing relevant |
| | | | F = Order-related (invoice correction) |
| | | | G = Order-related (pro-forma) |
| | | | I = Order-related (intercompany) |
| Billing plan type | FPLART | Plan de facturacion | Vacio salvo contratos milestone |
| Invoice correction | REKRS | Tipo correccion factura | Vacio |

**Paso 3 — Control de precios**

| Campo | Nombre tecnico | Descripcion | Valor |
|-------|---------------|-------------|-------|
| Pricing | PREIS | Determinacion de precios | X = Pricing active |
| | | | Vacio = No pricing |
| Statistical value | STATH | Valor estadistico | Vacio normalmente |
| Revenue recognition | RRREL | Reconocimiento de ingresos | Segun IFRS15 si aplica |

**Paso 4 — Control de entrega y produccion**

| Campo | Nombre tecnico | Descripcion | Valor |
|-------|---------------|-------------|-------|
| Delivery relevance | LFREL | Relevante para entrega | X = relevant |
| Sched. line allowed | KBBEF | Permite lineas de programa | X = si |
| Weight/Volume relevant | RADAU | Relevante peso/volumen | X = si |
| Special stock | SOBKZ | Stock especial | E = Make-to-order (MTO) |
| | | | W = Consignment |
| | | | Vacio = Standard |
| Returns | RRTYP | Posicion de devolucion | Segun proceso |

**Paso 5 — Control de negocio**

| Campo | Nombre tecnico | Descripcion | Valor |
|-------|---------------|-------------|-------|
| Business item | STKKZ | Item de negocio | X = si |
| Profit center determ. | PC_SCOPE | Determinacion profit center | Segun FI-CO requerido |
| Cost relevance | KOSTA | Relevancia de costos | X = si aplica |
| Configurable item | KZKFG | Posicion configurable | X para variant config |
| Structure scope | STRSCO | Alcance de estructura BOM | Segun MTO/Assembly |

**Paso 6 — Asignacion en VOV4**
SPRO → ... → Assign Item Categories
Combinacion: Sales doc type + Item category group + Usage + Higher-level item cat → Item category
Ejemplo: ZOR + NORM + (vacio) + (vacio) → ZTAN

### Tips
- Billing relevance A es el mas comun: factura se crea despues de la entrega
- Para servicios o articulos sin stock usar billing relevance B (factura desde pedido)
- Special stock E activa la planificacion MTO con numero de pedido en el segmento de stock
- En S/4HANA 1709+ el campo revenue recognition se integra con RAR (Revenue Accounting)

---

## Guia 3: Configurar Esquema de Precios (V/08 + OVKK)

### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Pricing → Pricing Control

### Transacciones involucradas
V/06 → V/07 → V/05 → V/08 → OVKK

### Procedimiento paso a paso

**Paso 1 — Crear tabla de condiciones (V/06)**
1. V/06 → crear tabla, ejemplo: tabla 901
2. Campos tipicos: Sales org, Distribution channel, Customer, Material
3. Generar tabla → se crea estructura KOMG/KONH

**Paso 2 — Crear secuencia de acceso (V/07)**
1. V/07 → nueva secuencia, ejemplo: ZA01
2. Agregar tablas en orden de especificidad (de mas especifico a mas general):
   - Paso 10: tabla cliente/material
   - Paso 20: tabla material/precio lista
   - Paso 30: tabla material

**Paso 3 — Crear tipos de condicion (V/05)**

| Tipo | Clase | Categoria calculo | Secuencia acceso | Descripcion |
|------|-------|------------------|-----------------|-------------|
| PR00 | A (Prices) | C (Qty) | PR00 | Precio base |
| K004 | A (Discount) | A (%) | K004 | Descuento material |
| K005 | A (Discount) | A (%) | K005 | Descuento cliente/material |
| K007 | A (Discount) | A (%) | K007 | Descuento grupo cliente |
| MWST | D (Tax) | D (Tax %) | MWST | IVA/Tax |
| SKTO | A (Discount) | A (%) | SKTO | Cash discount |

Campos clave al definir tipos de condicion:
- Condition class: A=Prices, B=Surcharges/discounts, C=Expense reimbursement, D=Taxes
- Calculation type: A=Percentage, B=Fixed amount, C=Quantity, G=Formula
- Condition category: para clasificar (precio, descuento, flete, impuesto)
- Accruals: para contabilizar devengamiento

**Paso 4 — Crear esquema de pricing (V/08)**

Ejemplo esquema RVAA01 standard:

| Paso | Counter | Tipo cond | Descripcion | De | A | Mandat | Estadist | SubTot |
|------|---------|-----------|-------------|----|----|--------|----------|--------|
| 10 | 0 | PR00 | Precio base | | | X | | 1 |
| 15 | 0 | | Gross Value | | | | X | 1 |
| 20 | 0 | K004 | Desc. material | | | | | |
| 25 | 0 | K005 | Desc. cte/mat | | | | | |
| 30 | 0 | K007 | Desc. grupo cte | | | | | |
| 100 | 0 | | Net Value I | 10 | 30 | | X | 2 |
| 200 | 0 | MWST | Tax | | | | | |
| 900 | 0 | | Total | | | | X | |

Opciones de subtotal (campo SubTot):
- 1 = Gross value → campo KZWI1
- 2 = Net value → campo KZWI2
- 3 = Rebate basis → campo KZWI3
- 6 = Cost → campo KZWI6

**Paso 5 — Asignar esquema a combinacion (OVKK)**

OVKK crea combinacion: Sales org + Dist ch + Division + Doc pricing proc + Customer pricing proc → Pricing procedure

| Campo | Ejemplo |
|-------|---------|
| Sales org | 1000 |
| Dist ch | 10 |
| Division | 00 |
| Doc pricing proc (KALKS) | A (desde VOV8) |
| Customer pricing proc (KTGRS) | 1 (desde KNA1/KNVV) |
| Pricing procedure | RVAA01 |

**Registros de condicion (VK11/VK12/VK13)**
VK11: crear registro de condicion para PR00
- Ingresar combinacion de campos (cliente + material) y precio con validez de fecha
- Moneda, UMB (unidad medida base), escalas opcionales

### Tips
- El orden de acceso en V/07 es critico: primero especifico, luego general
- Requirement routines (campo REQ en V/08) permiten activar condicion solo si se cumple condicion ABAP
- Alternative calculation type (AltCTy) permite calculo custom via rutina ABAP (formula)
- Exclusion groups evitan que multiples descuentos se apliquen simultaneamente

---

## Guia 4: Configurar Determinacion de Shipping Point (OVLK)

### Ruta SPRO
SPRO → Logistics Execution → Shipping → Basic Shipping Functions → Shipping Point and Goods Receiving Point Determination → Assign Shipping Points

### Transaccion directa
OVLK

### Logica de determinacion
El shipping point se determina por la combinacion de 3 factores:
1. **Shipping condition** (VSBED): del maestro de cliente (KNVV) o del tipo de documento
2. **Loading group** (LADGR): del maestro de material (MARA/MARC)
3. **Plant** (WERKS): del pedido de venta (determinado por reglas de planta)

### Procedimiento paso a paso

**Paso 1 — Definir shipping points (OVXB)**
SPRO → LE → Shipping → Basic Shipping Functions → Shipping Points → Define Shipping Points
- Crear shipping point: 1000
- Asignar factoría (factory calendar), zona horaria, direccion
- Campos: calendario de trabajo, tiempos de procesamiento default

**Paso 2 — Asignar shipping point a planta (OVXC)**
SPRO → LE → Shipping → Basic Shipping Functions → Shipping Points → Assign Shipping Points to Plants
- Combinacion: planta 1000 → shipping point 1000

**Paso 3 — Definir shipping conditions**
Se configuran en:
- Maestro de cliente (KNVV → campo VSBED)
- Tipo de documento de venta (VOV8 → campo VSBED si aplica default)

Valores tipicos:
| VSBED | Descripcion |
|-------|-------------|
| 01 | Standard |
| 02 | Express |
| 03 | Overnight |
| 10 | Pick up (cliente recoge) |

**Paso 4 — Definir loading groups**
SPRO → SD → Basic Functions → Taxes → Define Tax Relevancy of Master Records
(En realidad: Logistics Execution → Shipping → Deliveries → Define Loading Groups)
- Asignar a material en MM01 → Plant Data/Storage 2 → campo Loading group

Valores tipicos:
| LADGR | Descripcion |
|-------|-------------|
| 0001 | Manual |
| 0002 | Forklift |
| 0003 | Crane |

**Paso 5 — Configurar matriz de determinacion (OVLK)**
OVLK muestra tabla con combinaciones:
Shipping condition + Loading group + Plant → Shipping point propuesto + Shipping point manual

Ejemplo de configuracion:

| Ship. Cond | Loading Grp | Plant | Ship. Point |
|-----------|-------------|-------|-------------|
| 01 | 0001 | 1000 | 1000 |
| 01 | 0002 | 1000 | 1000 |
| 02 | 0001 | 1000 | 1001 |
| 02 | 0002 | 1000 | 1001 |
| 10 | * | 1000 | 1002 |

**Paso 6 — Verificar en pedido de venta**
VA01 → crear pedido → en posicion, campo shipping point debe determinarse automaticamente.
Si no determina: revisar maestro cliente (VSBED), maestro material (LADGR), y tabla OVLK.

### Tablas relevantes
| Tabla | Descripcion |
|-------|-------------|
| TVST | Shipping points |
| T001W | Plants |
| TVSB | Shipping conditions |
| TVLA | Loading groups |
| TROU | Shipping point determination matrix |

### Tips
- Si hay multiples shipping points propuestos para la misma combinacion, el sistema toma el primero
- El shipping point puede modificarse manualmente en el pedido si esta permitido
- En S/4HANA, revisar tambien la configuracion de Advanced Shipping and Receiving (ASR) si esta activo
- La planta en el pedido se determina primero (desde cliente, material, reglas custom) y luego el shipping point

---

## Guia 5: Configurar Determinacion de Output (NACE)

### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Output Control → Output Determination

### Transaccion directa
NACE

### Procedimiento paso a paso

**Paso 1 — Seleccionar aplicacion en NACE**
NACE muestra las aplicaciones SD:
| App | Descripcion |
|-----|-------------|
| V1 | Sales |
| V2 | Shipping |
| V3 | Billing |
| V4 | Handling Units |

**Paso 2 — Definir tipos de output**
NACE → seleccionar V1 → Output Types → New Entries o copiar existente

Tipos de output estandar SD:
| Output | App | Descripcion | Medium tipico |
|--------|-----|-------------|---------------|
| BA00 | V1 | Order confirmation | 1=Print, 5=Email |
| BA01 | V1 | Inquiry confirmation | 1=Print |
| AN00 | V1 | Quotation | 1=Print, 5=Email |
| LD00 | V2 | Delivery note | 1=Print |
| WA00 | V2 | Goods issue slip | 1=Print |
| RD00 | V3 | Invoice | 1=Print, 5=Email, 6=EDI |
| RD03 | V3 | Pro-forma invoice | 1=Print |
| RD04 | V3 | Credit memo | 1=Print |

Campos clave al definir output type:
| Campo | Descripcion | Valores |
|-------|-------------|---------|
| Access sequence | De donde determinar partner/condicion | BA00, LD00, etc. |
| Access to conditions | Buscar en registros condicion | X si aplica |
| Multiple issuing | Permitir re-envio | Segun necesidad |
| Partner function | Funcion socio para enviar | SP (Sold-to), SH (Ship-to) |
| Processing routines | Programa y formulario | Ver paso 5 |
| Archiving | Si archivar al procesar | X para documentos legales |

**Paso 3 — Configurar medium y timing**

Medium (canal de transmision):
| Codigo | Medium |
|--------|--------|
| 1 | Print (spool) |
| 2 | Fax |
| 3 | Telex |
| 4 | ABAP program |
| 5 | Email |
| 6 | EDI (via ALE) |
| 7 | Simple Mail |
| 8 | Special function |

Timing (cuando procesar):
| Codigo | Timing |
|--------|--------|
| 1 | Send immediately when saving the application |
| 2 | Send with the next processing run |
| 3 | Send externally |
| 4 | Send with periodically scheduled job |

**Paso 4 — Crear access sequences para output**
NACE → V1 → Access Sequences → copiar BA00 o crear nueva
- Tabla 1: sales org + distribution channel + sales doc type
- Tabla 2: sales org + distribution channel
- Tabla 3: sales org

**Paso 5 — Asignar processing routines**
NACE → V1 → Output Types → seleccionar BA00 → Processing routines

| Medium | Program | Form routine / SmartForm / PDF |
|--------|---------|-------------------------------|
| 1 (Print) | RVADOR01 | RVORDER01 (SAPscript) |
| 1 (Print) | RVADOR01 | LB_BIL_INVOICE (SmartForm) |
| 5 (Email) | RVADOR01 | - (usar con clase de email) |

Para SmartForms propios:
- Program: Z_SD_OUTPUT_PROGRAM
- Form name: Z_SD_INVOICE_SMARTFORM

Para Adobe Forms:
- Usar funcion FP_FUNCTION_MODULE_NAME en el programa

**Paso 6 — Crear condition records**
VV11 (sales), VV21 (shipping), VV31 (billing) → crear registros de condicion para output

Ejemplo para BA00:
- Combinacion: sales org 1000 → output BA00, medium 1 (print), timing 4 (periodico)
- O por tipo documento: ZOR → BA00, medium 5 (email), partner SP

**Paso 7 — Asignar procedimiento de output a tipo de documento**
SPRO → SD → Basic Functions → Output Control → Assign Output Determination Procedures
- V1: asignar procedure a sales doc type (VOV8 via config)
- V2: asignar procedure a delivery type
- V3: asignar procedure a billing type

### Tips
- Para email, configurar tambien SAPconnect (SCOT) con servidor SMTP
- NACE → V1 → Output Types → Email/Fax tab: configurar sender email y reply-to
- En S/4HANA 1709+: considerar migrar a Output Management 2.0 basado en BRF+
- VL71 para reprocesar outputs de entrega, VF31 para facturas
- Tabla NAST guarda el status de cada output (campo VSTAT: 0=pendiente, 1=OK, 2=error)

---

## Guia 6: Configurar Determinacion de Cuentas (VKOA)

### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Account Assignment/Costing → Revenue Account Determination → Assign G/L Accounts

### Transaccion directa
VKOA

### Logica de determinacion
La cuenta GL se determina por la combinacion de:
- Chart of accounts (plan de cuentas)
- Sales organization
- Account assignment group (customer) - KTGRD en KNVV
- Account assignment group (material) - KTGRM en MARA
- Account key - desde esquema de pricing (ERL, ERS, ERF, etc.)

### Procedimiento paso a paso

**Paso 1 — Definir account keys en esquema de pricing (V/08)**
En el esquema de pricing, cada condicion tiene un account key:
| Account Key | Descripcion | Uso tipico |
|-------------|-------------|------------|
| ERL | Revenue | Precio base PR00 |
| ERS | Sales deduction | Descuentos K004, K005 |
| ERF | Freight revenue | Condicion de flete HD00 |
| ERB | Rebate accruals | Condiciones de rebate |
| MWS | Tax | MWST |
| SKT | Cash discount | SKTO |
| EVV | Sales cost | Costo del material |

**Paso 2 — Definir grupos de asignacion de cuenta**

Para clientes (KTGRD) — OVK8:
| KTGRD | Descripcion |
|-------|-------------|
| 01 | Domestic customers |
| 02 | Export customers |
| 03 | Intercompany |

Para materiales (KTGRM) — OVK9:
| KTGRM | Descripcion |
|-------|-------------|
| 01 | Trading goods |
| 02 | Finished products |
| 03 | Services |

**Paso 3 — Asignar en maestros**
- Cliente: XD02/VD02 → Sales Area Data → Billing tab → Acct assgmt grp (KTGRD)
- Material: MM02 → Sales: Sales Org. 2 → Acct assgmt grp (KTGRM)

**Paso 4 — Crear tabla de condiciones para account determination**
OV/RN: crear condition tables para account determination
Tablas estandar disponibles:
| Tabla | Campos |
|-------|--------|
| 1 | Application + Condition type + Chart of acc + Sales org + AcctGrpCust + AcctGrpMat |
| 2 | Application + Condition type + Chart of acc + Sales org + AcctGrpCust |
| 3 | Application + Condition type + Chart of acc + Sales org |

**Paso 5 — Asignar cuentas GL en VKOA**

VKOA → seleccionar condition type (p.ej. KOFI para FI posting):
Combinacion → GL account:

| Chart of Accts | SOrg | KTGRD | KTGRM | AcctKey | GL Account |
|----------------|------|-------|-------|---------|------------|
| INT | 1000 | 01 | 01 | ERL | 800000 |
| INT | 1000 | 01 | 02 | ERL | 800100 |
| INT | 1000 | 02 | 01 | ERL | 800200 |
| INT | 1000 | 01 | 01 | ERS | 810000 |
| INT | 1000 | 01 | 01 | MWS | 175000 |

**Paso 6 — Verificar en factura**
VF01/VF02 → crear/modificar factura → ir a Accounting tab de la posicion → ver cuenta determinada.
Para simular sin crear: usar VF02 → Environment → Account Determination Analysis.

### Queries para verificacion
```sql
-- Ver asignaciones de cuentas SD
SELECT KAPPL, KVEWE, KOTABNR, KOZGF, VKORG, KTGRD, KTGRM, SAKN1
FROM VKOA
WHERE KAPPL = 'V' AND VKORG = '1000'

-- Verificar cuenta de cliente
SELECT KUNNR, VKORG, KTGRD FROM KNVV
WHERE KUNNR = '0000001000'

-- Verificar cuenta de material
SELECT MATNR, KTGRM FROM MVKE
WHERE MATNR = '000000000000000001'
```

### Tips
- La transaccion de analisis VKOA-log es: VF02 → Goto → Account Determination Log
- Si la cuenta no determina: verificar KTGRD en cliente, KTGRM en material, y asignacion en VKOA
- Para COGS (costo de ventas): usar account key EVV con cuenta de costo separada
- En S/4HANA con Universal Journal, las cuentas SD alimentan directamente ACDOCA

---

## Guia 7: Configurar Credit Management (OB45 + FD32 + OVA8)

### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Credit Management/Risk Management → Credit Management

### Transacciones involucradas
OB45 → OB38 → FD32 → OVA8 → VKM1/VKM4/VKM5

### Procedimiento paso a paso

**Paso 1 — Crear credit control area (OB45)**
SPRO → Financial Accounting → Accounts Receivable → Credit Management → Credit Control Account → Define Credit Control Areas
- Crear area de control de credito: 1000
- Currency: moneda del area
- Update: 12 (con entregas y facturas) o 15 (solo facturas)
- Fiscal year variant: K4
- Risk category default: si no hay registro FD32

| Campo | Descripcion | Valor |
|-------|-------------|-------|
| Credit control area | Identificador | 1000 |
| Currency | Moneda del limite | USD |
| Update | Que documentos actualizar | 12 |
| Fiscal year variant | Para vencimientos | K4 |
| Max. exchange rate diff | Diferencia max % | 0 |

**Paso 2 — Asignar company code (OB38)**
SPRO → FI → AR → Credit Management → Assign Credit Control Areas
- Sociedad (company code) 1000 → Credit control area 1000
- Tambien en OB38: permitir multiples credit control areas si aplica

**Paso 3 — Asignar credit control area a sales area**
SPRO → SD → Basic Functions → Credit Management → Assign Credit Control Areas to Sales Areas (o desde empresa)
- Sales org 1000 → Credit control area 1000

**Paso 4 — Mantener limite de credito por cliente (FD32)**
FD32 → ingresar cliente + credit control area
| Tab | Campo | Descripcion |
|-----|-------|-------------|
| Overview | Credit limit | Limite total en moneda |
| Overview | Credit exposure | Exposicion actual (calculada) |
| Status | Risk category | 001=Low, 002=Medium, 003=High |
| Status | Block indicator | X = bloqueado manualmente |
| Partial payments | Payment history | Ver record de pagos |

**Paso 5 — Configurar control automatico de credito (OVA8)**
OVA8: automatische Kreditkontrolle
Combinacion clave: Credit control area + Risk category + Credit group

Credit groups tipicos:
| Grupo | Descripcion |
|-------|-------------|
| 01 | Sales documents |
| 02 | Delivery documents |
| 03 | Goods issue |

Asignar credit groups en:
- VOV8 (sales doc type) → campo credit group
- OVAD (delivery type) → campo credit group
- OVA7 (item category) → campo credit relevance

Configuracion en OVA8 por combinacion:

| Campo | Descripcion | Valor tipico |
|-------|-------------|-------------|
| Reaction | A=warning, B=error, C=background check | B |
| Status/Block | Bloquear si excede | X |
| Check credit limit | Verificar limite | X |
| Open orders | Incluir pedidos abiertos | X |
| Open deliveries | Incluir entregas abiertas | X |
| Open billing | Incluir facturas pendientes | X |
| Days in arrears | Dias mora maximos | 30 |
| Oldest open item | Verificar item mas antiguo | X |
| Max document value | Limite por documento | Segun politica |

**Paso 6 — Liberar documentos bloqueados**
| Transaccion | Descripcion |
|-------------|-------------|
| VKM1 | Blocked SD documents (para liberar) |
| VKM2 | Released SD documents |
| VKM3 | All SD documents con status credito |
| VKM4 | Blocked orders (solo ordenes) |
| VKM5 | Blocked deliveries (solo entregas) |
| F.28 | Recontabilizar credit exposure |

### Tips
- En S/4HANA 1809+: disponible SAP Credit Management (FSCM) con funcionalidades avanzadas
- FSCM reemplaza el credit management clasico; configuracion diferente en SPRO → Financial Supply Chain Management
- Siempre testear con cliente de prueba antes de activar en produccion
- El campo Update en OB45 afecta el performance: Update 12 es mas completo pero mas lento
- Analisis de credito: F.31 (credit overview report)

---

## Guia 8: Configurar Partner Determination (VOPA)

### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Partner Determination

### Transaccion directa
VOPA

### Funciones de socio SD estandar
| Func | Descripcion | Tabla |
|------|-------------|-------|
| SP | Sold-to party (Interlocutor pedido) | KNVP |
| SH | Ship-to party (Destinatario mercancias) | KNVP |
| BP | Bill-to party (Destinatario factura) | KNVP |
| PY | Payer (Pagador) | KNVP |
| SA | Sales employee | PA/HR |
| VE | Sales representative | PA/HR |
| RE | Contact person | KNVK |
| AZ | Carrier | LFA1 |

### Procedimiento paso a paso

**Paso 1 — Definir funciones de socio**
VOPA → Partner Functions → New Entries
| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| Partner function | Codigo 2 caracteres | ZE (custom engineer) |
| Description | Descripcion | Technical Engineer |
| Partner type | KU=customer, LI=vendor, PE=person | KU |
| Usage | Uso general | Vacio |

**Paso 2 — Crear procedimiento de determinacion**
VOPA → Partner Determination Procedures → New Entries
- Codigo: TA (estandar sales) o ZTA (custom)
- Descripcion: Sales Order Partner Procedure

**Paso 3 — Asignar funciones al procedimiento**
VOPA → Partner Determination Procedures → seleccionar TA → Partner Functions in Procedure

| Func | Descripcion | Mandatorio | No modificable | Fuente det. |
|------|-------------|-----------|---------------|-------------|
| SP | Sold-to party | X | X | Manual/maestro |
| SH | Ship-to party | X | | Desde SP (KNVP) |
| BP | Bill-to party | X | | Desde SP (KNVP) |
| PY | Payer | X | | Desde SP (KNVP) |
| SA | Sales employee | | | Desde user |

**Paso 4 — Asignar procedimiento**
VOPA permite asignar procedimientos a diferentes niveles:

Para clientes (account groups):
VOPA → Account Groups → Assign Partner Determination Procedure
- Account group 0001 (soldto) → procedure TA

Para tipos de documento:
VOPA → Sales Document Header → Assign Partner Determination Procedures
- ZOR → procedure TA

Para tipos de entrega:
VOPA → Deliveries → Assign Partner Determination Procedures to Delivery Types
- LF → procedure LA

Para tipos de factura:
VOPA → Billing Documents → Assign Partner Determination Procedures to Billing Types
- F2 → procedure FA

**Paso 5 — Configurar en maestro de cliente**
XD02/VD02 → Sales Area → Partners tab
Ingresar socios para SP → SH, BP, PY (si diferentes al SP)
- KNVP tabla: kunnr + vkorg + vtweg + spart + parvw → kunn2 (socio)

**Paso 6 — Verificar en documento**
VA02 → Header → Partners tab: ver todos los socios determinados
Posicion → Goto → Partners: socios a nivel de posicion

### Tips
- Si SP=SH=BP=PY el sistema copia automaticamente; solo ingresar socios si son diferentes
- Partner determination procedure se puede configurar diferente a nivel header vs item
- Para socios de organizaciones (empleados, vendedores) revisar configuracion en HR/PA
- En S/4HANA con Business Partner (BP): los socios se gestionan en transaction BP (no XD01 separado)
- KNVP es la tabla de socios de cliente por area de ventas; consultar para verificar configuracion

---

## Referencias Rapidas

### Transacciones IMG mas usadas en SD

| Transaccion | Descripcion |
|-------------|-------------|
| VOV8 | Sales document types |
| VOV7 | Item categories |
| VOV6 | Schedule line categories |
| VOV4 | Item category assignment |
| VOV5 | Schedule line assignment |
| VOPA | Partner determination |
| V/08 | Pricing procedures |
| V/07 | Access sequences |
| V/06 | Condition tables |
| V/05 | Condition types |
| OVKK | Pricing procedure assignment |
| OVLK | Shipping point determination |
| NACE | Output determination |
| VKOA | Account assignment |
| OVA8 | Credit management |
| OVA2 | Incompletion procedures |
| OVF1 | Copy control (order to delivery) |
| VTFA | Copy control (order to billing) |
| VTFL | Copy control (delivery to billing) |

### Queries MCP para verificacion de customizing

```sql
-- Ver tipos de documento de venta
SELECT AUART, BEZEI, VBTYP, NUMKI, LFART, FKART, KALKS
FROM TVAK INNER JOIN TVAKT ON TVAK.AUART = TVAKT.AUART
WHERE TVAKT.SPRAS = 'E'

-- Ver categorias de posicion
SELECT PSTYV, BEZEI, FKREL, PREIS, LFREL
FROM TVAP INNER JOIN TVAPT ON TVAP.PSTYV = TVAPT.PSTYV
WHERE TVAPT.SPRAS = 'E'

-- Ver procedimientos de pricing asignados
SELECT VKORG, VTWEG, SPART, KDKLS, KKBER, KALSM
FROM TVKK

-- Ver output types por aplicacion
SELECT KAPPL, KSCHL, VTEXT, NACHA FROM TNAV
WHERE KAPPL = 'V1'

-- Ver account assignments SD
SELECT KAPPL, KVEWE, VKORG, KTGRD, KTGRM, SAKN1
FROM VKOA WHERE KAPPL = 'V'
```
