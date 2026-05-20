# Arboles de Decision SD — Guia de Determinacion

## Como usar este documento

Cada arbol de decision refleja la logica que SAP ejecuta AUTOMATICAMENTE en el pedido,
entrega o factura. Entender la secuencia evita errores de configuracion y facilita
el diagnostico cuando algo falla.

---

## 1. Seleccion de Tipo de Pedido (Order Type)

```
PREGUNTA: que operacion comercial necesito procesar?

¿Es una venta estandar con entrega y factura?
  SI → ¿Con referencia a contrato?
          SI → VA: Pedido de contrato (release order from contract)
          NO → OR: Pedido estandar (Standard Order)

¿Es entrega inmediata con cobro en el acto (mostrador)?
  SI → BV: Venta directa (Cash Sale)
          (delivery + factura generados automaticamente)

¿Es entrega urgente sin demora?
  SI → SO: Pedido urgente (Rush Order)
          (delivery inmediata, factura mas tarde)

¿Es sin cargo (regalo, muestra)?
  SI → FD: Entrega gratuita (Free of Charge Delivery)
          (relevancia facturacion = C → sin documento FI)

¿Es devolucion de mercancia del cliente?
  SI → RE: Pedido de devolucion (Returns)
          (requiere AUGRU: motivo devolucion)

¿Es ajuste de precio a favor del cliente (correccion baja)?
  SI → CR: Solicitud de abono (Credit Memo Request)
          → factura de abono G2

¿Es ajuste de precio a cargo del cliente (correccion alta)?
  SI → DR: Solicitud de cargo (Debit Memo Request)
          → factura de cargo L2

¿Es pedido intercompañia (venta entre org ventas propias)?
  SI → IVAU / IVA: Inter-company billing order (segun customizing)

¿Es transferencia de stock entre centros (STO)?
  SI → UB (One-step) o NB (Two-step, via Purchasing)

¿Tiene lista de materiales BOM?
  SI → OR pero con categoria de posicion TAP (phantom)/TAQ/TAPS
```

### Tabla resumen de tipos de pedido estandar

| Tipo | Descripcion           | Delivery | Billing | Escenario tipico             |
|------|-----------------------|:--------:|:-------:|------------------------------|
| OR   | Pedido estandar       | Si       | F2      | Venta normal B2B/B2C         |
| SO   | Pedido urgente        | Si (inm.)| F2      | Cliente necesita hoy         |
| BV   | Venta directa         | Si (auto)| BV      | Mostrador / punto de venta   |
| FD   | Entrega gratuita      | Si       | —       | Muestras, regalos            |
| CR   | Solicitud abono       | No       | G2      | Precio cobrado de mas        |
| DR   | Solicitud cargo       | No       | L2      | Precio cobrado de menos      |
| RE   | Devolucion            | Si (LR)  | RE      | Mercancia devuelta           |
| VA   | Pedido de contrato    | Si       | F2      | Release de contrato marco    |

Config: SPRO → SD → Sales → Sales Documents → Sales Document Header → Define Sales Document Types (VOV8)

---

## 2. Determinacion de Categoria de Posicion (Item Category)

```
Logica SAP: tabla T184
Clave = Tipo de pedido + Grupo categ. posicion (MTPOS_MARA) + Uso + Cat. pos. nivel superior

PASO 1: Identificar tipo de pedido
  OR / CR / DR / RE / FD / SO / BV...

PASO 2: Leer grupo categoria posicion del material (MVKE-MTPOS o MARA-MTPOS_MARA)
  NORM = material estandar
  LEIS = servicio
  DIEN = servicio (variante)
  BANS = terceros (tercero directo)
  BANC = terceros individual
  TAB  = orden individual de compra
  ERLA = cabecera de paquete/bundle

PASO 3: Aplicar logica T184
  Tipo pedido + Grupo cat. pos. → Categoria posicion

PASO 4: Si hay posicion de nivel superior (BOM/paquete)
  Se agrega la cat. pos. nivel superior para determinar cat. posicion del componente

Resultado:

  OR  + NORM       → TAN  (Normal item)
  OR  + LEIS       → TAD  (Servicio)
  OR  + BANS       → TAS  (Tercero directo — genera PR)
  OR  + BANC       → TAB  (Orden individual de compra)
  OR  + ERLA (hdr) → TAQ  (Bundle header, no facturable)
  OR  + NORM + TAQ → TAE  (Componente de bundle)
  RE  + NORM       → REN  (Posicion devolucion estandar)
  CR  + NORM       → G2N  (Abono estandar)
  DR  + NORM       → L2N  (Cargo estandar)
  FD  + NORM       → KLN  (Entrega gratuita)
  BV  + NORM       → BVN  (Venta directa)
  SO  + NORM       → SNN  (Pedido urgente)
```

### Atributos clave de la categoria de posicion

| Campo        | Significado                           | Impacto                      |
|--------------|---------------------------------------|------------------------------|
| PSTYV        | Relevancia entrega (A/B/X/espacio)    | Se genera delivery o no      |
| FKREL        | Relevancia facturacion (A/B/C/D/G)    | Se genera factura o no       |
| SHKZG        | Posicion estadistica                  | No genera movimiento stock   |
| PRSFD        | Determinacion precio (X/espacio)      | Pricing activo o no          |
| KZABS        | Relevancia propuesta cantidad         | Propone qty de pedido        |

Config: SPRO → SD → Sales → Sales Documents → Sales Item → Define Item Categories (VOV7)
Asignacion: SPRO → VOV4 (Assign Item Categories)

---

## 3. Determinacion de Categoria de Division (Schedule Line Category)

```
Logica SAP: tabla T188
Clave = Categoria de posicion + Tipo MRP (MRP type del material en el centro)

PASO 1: Tomar categoria de posicion (ej: TAN)

PASO 2: Leer tipo MRP del material-centro (MARC-DISMM)
  ND = sin planificacion
  PD = MRP clasico
  VB = Punto de reorden
  VM = Reabastecimiento automatico

PASO 3: Cruzar en T184S (asignacion cat.pos → cat.division)

Resultados tipicos:

  TAN + PD  → CP (relevancia MRP, verificacion disponib.)
  TAN + ND  → CN (sin MRP, verificacion disponib. simple)
  TAN + VB  → CB (reabastecimiento automatico)
  TAS + PD  → CS (terceros: genera PR automaticamente)
  TAB + PD  → CB (individual PO: genera PR)
  KLN + ND  → D0 (entrega gratuita: sin movimiento stock)
  REN + —   → DN (devolucion: GR movimiento 651)

CAMPOS CLAVE de la categoria de division:
  ETTYP (relevancia MRP): A=MRP, B=consumo, D=sin movimiento
  FXKBF (relevancia entrega): A=entrega relevante, espacio=no
  ABART (tipo de necesidad): 1=pedido cliente, 2=previsional
  MPBEZ (clase necesidad independiente)
  PRKNG (relevancia verificacion disponibilidad)
```

### Impacto en el flujo de documentos

| Cat.Div. | MRP | ATP | PR generada | GI en entrega |
|----------|:---:|:---:|:-----------:|:-------------:|
| CP       | Si  | Si  | No          | Si (261)      |
| CN       | No  | Si  | No          | Si (601)      |
| CS       | —   | No  | Si          | No (vendor)   |
| CB       | Si  | Si  | Si (indiv.) | Si            |
| D0       | No  | No  | No          | No            |

Config: SPRO → SD → Sales → Sales Documents → Schedule Lines → Define Schedule Line Categories (VOV6)
Asignacion: SPRO → VOV5 (Assign Schedule Line Categories)

---

## 4. Determinacion de Tipo de Entrega (Delivery Type)

```
La entrega se genera desde el pedido. El tipo de entrega se determina por:

CRITERIO PRINCIPAL: tipo de pedido de ventas → mapeado en TVLK (config OVLP)

  OR  → LF  (Outbound delivery estandar)
  RE  → LR  (Return delivery — flujo inverso)
  NL  → NL  (Reposicion consignacion)
  BV  → BV  (Delivery venta directa — auto-generada)
  SO  → LF  (misma que OR)
  FD  → LF  (entrega gratuita — mismo tipo fisico)
  STO → NLCC/NLC (inter-company) o NL (intra-company)

CRITERIO SECUNDARIO: condicion de expedicion del cliente (KNVV-VSBED)
  Influye en: puesto de expedicion, ruta, modalidad transporte
  NO cambia el tipo de entrega, pero si la ruta y el shipping point

CRITERIO EXCEPCIONAL: planta de expedicion diferente a planta del pedido
  → puede activar NCC (cross-company delivery)

REGLA: un pedido puede generar MULTIPLES entregas
  - Si hay posiciones con diferente shipping point → entrega separada por SP
  - Si hay posiciones con diferente fecha → entrega separada por fecha (si config lo permite)
```

Config: SPRO → LE → Shipping → Deliveries → Define Delivery Types (OVLK)
Asignacion pedido→entrega: SPRO → Copy Control → Sales Order to Delivery (VTLA)

---

## 5. Determinacion de Tipo de Factura (Billing Type)

```
La factura se determina desde el documento origen. Logica: copy control VTFL (delivery→billing)
o VTFF (billing→billing) o VTFA (sales order→billing).

DESDE ENTREGA (VTFL):
  LF (delivery estandar)  → F2 (factura estandar cliente)
  LR (return delivery)    → RE (nota credito por devolucion)
  NL (reposicion consig.) → (sin factura, es movimiento interno)
  BV (delivery cash sale) → BV (factura venta directa)
  LF + intercompany plant → IV (intercompany invoice)

DESDE PEDIDO SIN ENTREGA (VTFA — order-related billing):
  CR (solicitud abono)   → G2 (abono / credit memo)
  DR (solicitud cargo)   → L2 (cargo / debit memo)
  FD (entrega gratuita)  → (ninguna — billing relevance = C)
  OR con servicios (TAD) → F2 (order-related si FKREL=B)

REGLA DE PRECEDENCIA:
  1. Tipo factura definido en copy control (campo FKART en VTFL/VTFA)
  2. Si vacio → sistema busca en VOV7 (item category) billing type
  3. Default del sistema: F2

CASOS ESPECIALES:
  Rebates activos        → BO (rebate settlement billing)
  Pro-forma invoice      → F5 (desde pedido) / F8 (desde entrega)
  Factura periodica      → FV (periodic billing)
  Factura de anticipo    → FAZ (down payment request)
  Liquidacion anticipo   → FAS (down payment clearing)
```

Config: SPRO → SD → Billing → Billing Documents → Define Billing Types (VOFA)
Copy control entrega→factura: VTFL | Pedido→Factura: VTFA | Factura→Factura: VTFF

---

## 6. Determinacion de Esquema de Calculo (Pricing Procedure)

```
Logica SAP: tabla T683V
Clave = Org ventas + Canal distribucion + Sector + Procedimiento doc (KDKFZ) + Procedimiento cliente (KONDA)

PASO 1: Org ventas del pedido (ej: 1000)

PASO 2: Canal distribucion del pedido (ej: 10)

PASO 3: Division/sector del pedido (ej: 01)

PASO 4: Procedimiento del documento
  Viene del tipo de pedido (VOV8, campo KALVG)
  Ej: OR → A (estandar)

PASO 5: Procedimiento del cliente
  Viene del registro maestro de cliente (KNVV-KONDA)
  Ej: cliente estandar → 1

PASO 6: Cruzar los 5 campos en T683V
  1000 + 10 + 01 + A + 1 → RVAA01 (esquema estandar)

DIAGRAMA:
  Tipo pedido (VOV8) ──→ Proc.Documento (A/B/C)
                                      |
  Cliente (KNVV) ────────→ Proc.Cliente (1/2/3)
                                      |
  Org.ventas + Canal + Sector ─────────────→ ESQUEMA (T683V)
                                               (RVAA01, RVAB01, etc.)
```

Config: SPRO → SD → Basic Functions → Pricing → Pricing Control → Define and Assign Pricing Procedures (OVKK)

### Diagnostico cuando el precio no aparece

```
1. VK13 → verificar si existe registro de condicion para el material/cliente
2. V/LD → analizar esquema de calculo aplicado al pedido
3. VA02 → posicion → condiciones → boton "Analysis" (lupa verde)
4. Verificar: ¿el condition type esta en el pricing procedure? (V/08)
5. Verificar: ¿la access sequence busca en la tabla correcta? (V/07)
6. Verificar: ¿existe tabla de condicion para esa combinacion de campos? (V/03)
```

---

## 7. Determinacion de Puesto de Expedicion (Shipping Point)

```
Logica SAP: tabla TVSTZ
Clave = Condicion expedicion + Grupo de carga + Centro (planta)

PASO 1: Condicion de expedicion (Shipping Condition)
  Fuente 1: KNVV-VSBED (registro cliente en area ventas)
  Fuente 2: TVAK-VSBED (tipo de pedido, si lo sobreescribe)
  Ej: 01=estandar, 02=urgente, 10=recogida cliente

PASO 2: Grupo de carga (Loading Group)
  Fuente: MARA-LADGR (maestro material, datos ventas general)
  Ej: 0001=grua, 0002=paleta, 0003=manual

PASO 3: Centro de suministro (Delivering Plant)
  Fuente 1: MARC-VTBFK (propuesta en material-centro)
  Fuente 2: KNVV-WERKS (propuesta en cliente-area ventas)
  Fuente 3: Manual en el pedido

PASO 4: SAP cruza los 3 campos en TVSTZ
  ShipCond=01 + LoadGroup=0001 + Plant=1000 → SP=1000

IMPORTANTE:
  Un shipping point debe estar ASIGNADO al centro (TVSTZ)
  Si no hay propuesta automatica → campo queda vacio y bloquea entrega
  Se puede sobreescribir manualmente en la posicion del pedido

DIAGNOSTICO:
  Si shipping point no se determina:
    1. Verificar MARC-VTBFK (planta suministro en material)
    2. Verificar MARA-LADGR (grupo carga en material)
    3. Verificar KNVV-VSBED (cond. expedicion en cliente)
    4. Verificar TVSTZ: SPRO → LE → Shipping → Basic Shipping Functions
       → Shipping Point and GI Criteria Determination → Assign Shipping Points
```

---

## 8. Devolucion vs Abono vs Cargo — Arbol de Decision

```
PREGUNTA: el cliente reclama. ¿Que tipo de documento proceso?

¿La mercancia ha sido enviada y el cliente la devuelve fisicamente?
  SI → DEVOLUCION (RE)
       - Crea pedido RE con referencia a F2 original
       - Genera entrega de devolucion (LR)
       - GR de devolucion: movimiento 651 (bloqueado calidad) o 653 (libre)
       - Factura RE (nota credito por devolucion)
       - Impacto contable: reversa ingreso, deshace COGS

¿El precio fue cobrado de mas y NO hay devolucion fisica?
  SI → ABONO (CR → G2)
       - Crea solicitud abono CR con referencia a F2
       - NO genera entrega
       - Genera factura G2 (credit memo)
       - Impacto contable: reversa parcial del ingreso

¿El precio fue cobrado de menos y se debe cobrar diferencia?
  SI → CARGO (DR → L2)
       - Crea solicitud cargo DR con referencia a F2
       - NO genera entrega
       - Genera factura L2 (debit memo)
       - Impacto contable: ingreso adicional

¿Es error total en la factura (factura incorrecta)?
  SI → ¿Tiene entrega?
          CON entrega → Cancelar F2 con VF11 → crea S1 (cancel billing)
                       → Corregir en el pedido → nueva factura F2
          SIN entrega → Abono G2 por monto total + nuevo DR correcto

¿Es devolucion + ajuste de precio?
  SI → RE (por la devolucion fisica) + CR separado (por diferencia de precio)
       No intentar manejar ambos en un solo documento

FLUJO DE APROBACION tipico (config workflow):
  CR/DR creado → bloqueo de facturacion (FAKSP) → aprobacion supervisor
  → desbloqueo → factura G2/L2
```

---

## 9. Entrega Gratuita vs Siguiente Entrega Gratuita

```
PREGUNTA: debo enviar mercancia sin cargo. ¿Que tipo de pedido?

¿Es un regalo/muestra sin ninguna referencia previa?
  SI → FD: Free of Charge Delivery
       - Tipo pedido FD, categoria posicion KLN
       - Relevancia facturacion = C (sin factura FI)
       - Stock se reduce con GI en la entrega
       - Sin ingreso contable (se carga directamente a centro de coste o cuenta gasto)
       - Puede tener pricing VPRS para valoracion del coste

¿Es compensacion por un pedido anterior (sustitucion de mercancia defectuosa)?
  SI → Opcion A: RE (devolucion fisica) + FD (nueva entrega gratuita)
       Opcion B: Siguiente entrega gratuita con referencia a pedido original
       - Crea FD con referencia al pedido original OR
       - Copy control copia referencias de documento
       - Mantiene trazabilidad del motivo

¿Es parte de un contrato de mantenimiento o garantia?
  SI → Evaluar: ¿hay modulo CS (Customer Service) activo?
          SI → Usar service order + resource-related billing (DPRA)
          NO → FD simplificado

DISTINCION CONTABLE:
  FD normal       → GI al coste (sin ingreso)
  RE + devolucion → GR reversa el COGS original + nuevo GI en nueva entrega
```

---

## 10. Terceros vs Normal vs Consignacion

```
PREGUNTA: ¿como se gestiona el stock en esta venta?

¿El stock es propio y esta en el almacen?
  SI → NORMAL (OR + TAN)
       - ATP verifica stock propio en el centro
       - GI desde almacen propio (movimiento 601)
       - Entrega LF + factura F2

¿El proveedor envia directamente al cliente (no pasa por tu almacen)?
  SI → TERCEROS (OR + TAS)
       - PR generada automaticamente desde la division (CS)
       - Compras convierte PR en PO al proveedor
       - Proveedor entrega directamente al cliente
       - GR en PO (movimiento 101) pero con indicador "no stock" (sin ingreso fisico)
       - Confirmacion de entrega del proveedor → factura al cliente
       Variante: TAB (Individual PO) — GR real en almacen, luego GI al cliente

¿El stock esta en las instalaciones del cliente (consignacion)?
  SI → ¿Que operacion?
          Llenar el almacen del cliente:
            NF: Consignment Fill-Up (reposicion, sin factura)
            → Mueve stock de libre a consignacion (movimiento 631)
          Cliente usa el stock:
            CI: Consignment Issue (factura al usar)
            → Reduce stock consignacion (movimiento 633)
            → Genera factura F2
          Cliente devuelve stock no usado:
            CONR: Consignment Return (devolucion a propio)
            → Mueve de consignacion a libre (movimiento 634)
          Retirar stock no vendido:
            CP: Consignment Pickup (pickup por empresa)
            → Mueve de consignacion a libre propio (movimiento 632)

DECISION POR TIPO DE NEGOCIO:
  Distribuidor con alto volumen    → Consignacion (CI para facturar al consumo)
  Proveedor directo disponible     → Terceros (TAS)
  Gestion propia del inventario    → Normal (TAN)
  Produccion bajo pedido cliente   → MTO (TAK, stock especial E)
```

---

## 11. Determinacion de Textos (Header vs Item)

```
Logica SAP: modulo de determinacion de textos (TN) — tabla TTXID

NIVEL CABECERA del pedido:
  Texto 0001 (texto interno/nota interna)
  Texto 0002 (texto para entrega)
  Texto 0003 (texto para factura)
  Fuentes: manual, copia del cliente (KNVV-TEXT), default del tipo pedido

NIVEL POSICION del pedido:
  Texto 0001 (descripcion posicion)
  Texto GRUN (motivo)
  Fuentes: manual, copia del material (MVKE, MARA), del cliente

PROPAGACION de textos:
  Pedido → Entrega: via copy control (VTLA — campo TEKSTID)
  Pedido → Factura: via copy control (VTFA/VTFL — campo TEKSTID)

DETERMINACION AUTOMATICA:
  SAP busca textos en este orden:
    1. Maestro de cliente (idioma del destinatario)
    2. Maestro de material (idioma del pedido)
    3. Default definido en customizing

REGLA IDIOMA:
  Textos de ventas al cliente: idioma del sold-to party (KUNNR)
  Textos internos: idioma del sistema o del usuario

DIAGNOSTICO si texto no aparece en factura:
  1. Verificar que el text ID esta configurado en la rutina de copia (VTFL)
  2. Verificar que el texto existe en el idioma correcto (SE16 → STXH)
  3. Verificar que el formulario SAPscript/Smartform lee ese text ID
```

---

## 12. Resumen Visual: Flujo de Determinaciones en un Pedido

```
ENTRADA: VA01 — crear pedido

  [1] Tipo de pedido ingresado por usuario (ej: OR)
         |
         v
  [2] Procedimiento documento (de VOV8) + Proc.cliente (de KNVV)
         + Org ventas + Canal + Sector
         → PRICING PROCEDURE (T683V)
         |
         v
  [3] Material ingresado → Grupo cat.pos. (MARA-MTPOS_MARA)
         + Tipo pedido → ITEM CATEGORY (T184)
         |
         v
  [4] Item category + MRP type (MARC-DISMM)
         → SCHEDULE LINE CATEGORY (T184S)
         |
         v
  [5] Shipping condition (KNVV) + Loading group (MARA) + Plant
         → SHIPPING POINT (TVSTZ)
         |
         v
  [6] Pricing procedure + condition types
         → ACCESS SEQUENCES → CONDITION RECORDS
         → PRECIO / DESCUENTOS / IMPUESTOS
         |
         v
  [7] Guardar pedido → verificacion disponibilidad (ATP)
         |
         v
  SALIDA: Pedido confirmado con precios, fechas, shipping point
```

---

## Queries MCP para Diagnostico de Determinaciones

```sql
-- Item categories por tipo de pedido
SELECT AUART, MTPOS, DPCON, PSTYV
FROM T184
WHERE AUART = '{order_type}'
ORDER BY MTPOS

-- Schedule line categories
SELECT PSTYV, DISMM, ETTYP
FROM T184S
WHERE PSTYV = '{item_category}'

-- Pricing procedure determination
SELECT VKORG, VTWEG, SPART, KDKFZ, KONDA, KALSM
FROM T683V
WHERE VKORG = '{sales_org}'

-- Shipping point determination config
SELECT VSBED, LADGR, WERKS, VSTEL
FROM TVSTZ
WHERE WERKS = '{plant}'

-- Copy control pedido → entrega
SELECT VBTYP_N, VBTYP_V, AUART, LFART
FROM TVAK
WHERE VBTYP_N = 'J'  -- J = delivery

-- Copy control entrega → factura (VTFL)
SELECT VBTYP_V, VBTYP_N, LFART, FKART
FROM VTFL
WHERE LFART = '{delivery_type}'

-- Verificar item category en un pedido real
SELECT VBELN, POSNR, MATNR, PSTYV, ETTYP
FROM VBAP
WHERE VBELN = '{order_number}'

-- Schedule lines de un pedido
SELECT VBELN, POSNR, ETENR, ETTYP, EDATU, WMENG, BMENG
FROM VBEP
WHERE VBELN = '{order_number}'
```
