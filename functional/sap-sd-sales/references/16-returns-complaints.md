# Devoluciones y Reclamaciones SD

## Tipos de documentos de reclamacion

| Tipo Doc | TCode Creacion | Descripcion | Categoria Item | Tipo Factura | Efecto FI |
|----------|---------------|-------------|----------------|--------------|-----------|
| RE | VA01 | Return Order (pedido devolucion) | REN | RE | Reversa de revenue |
| LR | VL01N | Return Delivery (entrega devolucion) | — | — | GR mvt 651/653 |
| CR | VA01 | Credit Memo Request (nota credito) | G2N | G2 | D: Revenue / C: AR |
| DR | VA01 | Debit Memo Request (nota debito) | L2N | L2 | D: AR / C: Revenue |
| FD | VA01 | Free of Charge Subsequent (reposicion) | TANN | — | Solo GI, sin revenue |
| KA | VA01 | Consignment Pickup | — | — | mvt 632 |
| RK | VA01 | Invoice Correction Request | — | RK | Correccion factura |

### Flujo contable por tipo

```
RE (devolucion) → LR (entrega dev) → mvt 651 → RE billing (reversa ingreso)
  Asiento: D: Ingreso por ventas / C: Cuenta devolucion clientes

CR (nota credito) → G2 (credit memo)
  Asiento: D: Revenue (reversa) / C: AR (reduce deuda cliente)

DR (nota debito) → L2 (debit memo)
  Asiento: D: AR (aumenta deuda) / C: Revenue (ingreso adicional)

FD (envio gratuito) → entrega normal → GI mvt 601
  Asiento: D: Costo merc vendida / C: Inventario  (sin revenue)
```

---

## Proceso de devolucion completo (RE → LR → RE billing)

### Paso 1: Crear pedido de devolucion VA01

```
VA01 → Tipo de pedido: RE
  - Con referencia: VBAK-VGBEL = pedido original / VBRK-VBELN = factura original
  - Sin referencia: ingresar datos manualmente
  Campos obligatorios:
    VBAK-AUGRU  Razon de reclamacion (header)
    VBAK-VKORG  Org. de ventas
    VBAK-VTWEG  Canal de distribucion
    VBAK-SPART  Division
    VBAP-MATNR  Material
    VBAP-KWMENG Cantidad a devolver (negativa internamente)
    VBAP-WERKS  Centro (destino de la devolucion)
```

### Paso 2: Bloqueo de facturacion (opcional, segun config)

```
VA02 → modificar pedido → Bloqueo de facturacion: '08' (verificacion devolucion)
  Se libera en VKM1 (lista de bloqueos de credito)
  o automaticamente al confirmar GR
```

### Paso 3: Crear entrega de devolucion VL01N

```
VL01N → Tipo entrega: LR
  - Punto de expedicion: segun customizing
  - Referencia al pedido RE
  Campos relevantes LIKP:
    LFART = 'LR'   Tipo entrega devolucion
    KUNNR           Cliente origen devolucion
    WERKS           Centro destino
  Verificar: LIKP-WBSTK (estado GR) debe quedar 'C' tras confirmacion
```

### Paso 4: Entrada de mercancias VL02N o MIGO

```
VL02N → Registrar entrada mercancias (boton GI en entrega devolucion)
  o bien:
MIGO → A01 (entrada mercancias) → R10 (entrega) → referencia a entrega LR

Movimientos de mercancias:
  651 → Devolucion a stock libre (calidad OK)
  653 → Devolucion a stock bloqueado (calidad KO, inspeccion QM)
  655 → Devolucion a stock QM (si QM activo)

Tablas afectadas:
  MKPF / MSEG   Documento material / posiciones
  MARD          Stock por almacen
  MSKA          Stock bloqueado
```

### Paso 5: Factura de devolucion VF01

```
VF01 → Tipo factura: RE
  Asiento contable reversa:
    D: Cuenta de ingresos (reversa del ingreso original)
    C: Cuenta de deudores (reduce AR del cliente)
  Genera documento FI en tabla BKPF/BSEG
  Actualiza VBRK-FKSTO = ' ' (no anulada)
```

---

## Proceso de nota de credito (CR → G2)

### Paso 1: Crear solicitud de nota de credito VA01

```
VA01 → Tipo: CR
  Con referencia a factura original (recomendado):
    Menu superior: Pedido → Crear con referencia → a Factura
    Copia automatica de datos: cliente, material, precio, condiciones

  Campos clave:
    VBAK-KUNNR    Cliente
    VBAP-MATNR    Material (o cuenta de mayor para nota de credito libre)
    VBAP-KBETR    Importe (puede ser menor al original)
    VBAK-BLCKD    Bloqueo de facturacion (si requiere aprobacion)
```

### Paso 2: Aprobacion (workflow, si configurado)

```
Nota credito puede requerir aprobacion segun tolerancia:
  SWI2_FREQ     Ver instancias de workflow activas
  SWI1          Bandeja de entrada workflow
  SWDD          Definicion de workflow (config)

  Liberacion en VA02 → quitar bloqueo facturacion campo BLCKD
```

### Paso 3: Crear nota de credito VF01

```
VF01 → Tipo factura: G2
  Asiento: D: Cuenta ingresos (reduce revenue)
           C: Cuenta deudores (reduce deuda cliente)

  El cliente puede compensar con facturas pendientes en F-32 o F-44
```

---

## Proceso de nota de debito (DR → L2)

```
VA01 → Tipo: DR (cargo adicional al cliente)
  Casos de uso:
    - Error en precio (cobro insuficiente)
    - Cargos adicionales (flete, seguro omitido)
    - Penalizaciones contractuales

VF01 → Tipo factura: L2
  Asiento: D: Cuenta deudores (aumenta deuda)
           C: Cuenta ingresos (ingreso adicional)
```

---

## Copy Control — Configuracion SPRO

### VTFA: Pedido a Pedido (para devoluciones con referencia)

```
SPRO → SD → Ventas → Determinar categoria documento → Copy Control
  VTFA: Pedido de ventas → Pedido de ventas
    OR → RE  (pedido estandar a devolucion)
    F2 → CR  (factura a solicitud nota credito)
    F2 → DR  (factura a solicitud nota debito)

  Rutinas de copia relevantes:
    Rutina cabecera: 001 (copia datos cabecera)
    Rutina posicion: 001 (copia datos posicion)
    VBTYP destino: B (RE), B (CR), B (DR)
```

### VTLA: Entrega a Entrega (devolucion)

```
VTLA: Pedido de ventas → Entrega
  RE → LR  (devolucion → entrega devolucion)
  Tipo entrega: LR
  Rutina de copia: 003
```

### VTFL: Entrega a Factura

```
VTFL: Entrega → Factura
  LR → RE  (entrega devolucion → factura devolucion)
  Tipo factura: RE
  Determinacion cuenta: rutina 004 (reversa)
```

---

## Tablas principales de devoluciones y reclamaciones

| Tabla | Descripcion | Campos clave |
|-------|-------------|-------------|
| VBAK | Cabecera pedido ventas | VBELN, AUART (RE/CR/DR), AUGRU, VGBEL |
| VBAP | Posiciones pedido ventas | VBELN, POSNR, ABGRU (razon rechazo) |
| LIKP | Cabecera entrega | VBELN, LFART (LR), WBSTK |
| LIPS | Posiciones entrega | VBELN, POSNR, MATNR, LGORT |
| VBRK | Cabecera factura | VBELN, FKART (RE/G2/L2), FKSTO |
| VBRP | Posiciones factura | VBELN, POSNR, MATNR, NETWR |
| VBFA | Flujo de documentos | VBELV, VBELN, VBTYP_N, VBTYP_V |
| MKPF | Cabecera doc material | MBLNR, BUDAT, BKTXT |
| MSEG | Posiciones doc material | MBLNR, ZEILE, BWART (651/653), VBELN |
| BKPF | Cabecera doc FI | BELNR, BUKRS, BUDAT |
| BSEG | Posiciones doc FI | BELNR, BUZEI, KOART, DMBTR |

### Campos relevantes en VBAK para reclamaciones

```
VBAK-AUGRU   Razon de reclamacion (header) — tabla TVAUG
VBAK-VGBEL   Documento de referencia (pedido original)
VBAK-VGPOS   Posicion del documento de referencia
VBAK-BSTNK   Numero pedido cliente (puede usarse para referencia externa)
VBAP-ABGRU   Razon de rechazo de posicion — tabla TVAG (bloquea facturacion)
VBAP-GRPOS   Motivo de reclamacion a nivel posicion
```

---

## Razones de reclamacion y rechazo — Customizing

### VOV8: Tipos de documentos de ventas

```
SPRO → SD → Ventas → Documentos de ventas → Cabecera → Definir tipos doc ventas
  RE: Return Order
    - Tipo entrega: LR
    - Tipo factura: RE
    - Verificacion credito: D (bloqueo devolucion)
    - Bloqueo facturacion: puede activarse por defecto
  CR: Credit Memo Request
    - Sin entrega
    - Tipo factura: G2
    - Bloqueo facturacion: 08 (frecuente para aprobacion)
  DR: Debit Memo Request
    - Sin entrega
    - Tipo factura: L2
```

### VOV9: Razones de rechazo de posicion

```
SPRO → SD → Ventas → Documentos de ventas → Posicion → Definir razones de rechazo
  Tabla TVAG:
    01  Competencia
    02  Precio
    03  Plazo de entrega
    10  Duplicado
    40  Cancelado por cliente
  Efecto: posicion con ABGRU = excluida de entrega y facturacion
```

### Razones de reclamacion (AUGRU)

```
SPRO → SD → Ventas → Documentos de ventas → Cabecera → Definir razones de reclamacion
  Tabla TVAUG:
    01  Producto defectuoso
    02  Error en pedido
    03  Error en entrega
    04  Mercancia no solicitada
    05  Precio incorrecto
    06  Dano en transporte
```

### Movement Types en devolucion

```
Tcode OMJJ para configurar movement types:
  651  Return from customer (to unrestricted stock)
         GR a stock libre — calidad OK
  653  Return from customer (to blocked stock)
         GR a stock bloqueado — pendiente inspeccion
  655  Return from customer (to QM stock)
         Solo con QM activo

  Diferencia con devolucion intercompany:
  657  Return from customer (STO intercompany)
```

---

## Queries MCP — Analisis de devoluciones

### Devoluciones por periodo y organizacion

```sql
SELECT
  VBAK.VBELN,
  VBAK.AUART,
  VBAK.KUNNR,
  KNA1.NAME1,
  VBAK.NETWR,
  VBAK.WAERK,
  VBAK.AUGRU,
  TVAUG.BEZEI AS RAZON_RECLAMACION,
  VBAK.ERDAT,
  VBAK.VKORG,
  VBAK.VGBEL AS DOC_REFERENCIA
FROM VBAK
  INNER JOIN KNA1 ON KNA1.KUNNR = VBAK.KUNNR
  LEFT JOIN TVAUG ON TVAUG.AUGRU = VBAK.AUGRU AND TVAUG.SPRAS = 'S'
WHERE
  VBAK.AUART IN ('RE', 'CR', 'DR')
  AND VBAK.VKORG = '{org_ventas}'
  AND VBAK.ERDAT BETWEEN '{fecha_desde}' AND '{fecha_hasta}'
ORDER BY VBAK.ERDAT DESC
```

### Entregas de devolucion pendientes de GR

```sql
SELECT
  LIKP.VBELN AS ENTREGA,
  LIKP.LFART,
  LIKP.KUNNR,
  KNA1.NAME1,
  LIKP.LFDAT AS FECHA_ENTREGA,
  LIKP.WBSTK AS ESTADO_GR,
  LIPS.MATNR,
  LIPS.LFIMG AS CANTIDAD_PENDIENTE,
  LIPS.VGBEL AS PEDIDO_REF
FROM LIKP
  INNER JOIN LIPS ON LIPS.VBELN = LIKP.VBELN
  INNER JOIN KNA1 ON KNA1.KUNNR = LIKP.KUNNR
WHERE
  LIKP.LFART = 'LR'
  AND LIKP.WBSTK <> 'C'
  AND LIKP.LGORT IS NOT NULL
ORDER BY LIKP.LFDAT ASC
```

### Notas de credito pendientes de facturacion

```sql
SELECT
  VBAK.VBELN,
  VBAK.AUART,
  VBAK.KUNNR,
  KNA1.NAME1,
  VBAK.NETWR,
  VBAK.WAERK,
  VBAK.ERDAT,
  VBAK.VGBEL AS FACTURA_ORIGEN
FROM VBAK
  INNER JOIN KNA1 ON KNA1.KUNNR = VBAK.KUNNR
WHERE
  VBAK.AUART = 'CR'
  AND VBAK.GBSTK <> 'C'
  AND NOT EXISTS (
    SELECT 1 FROM VBFA
    WHERE VBFA.VBELV = VBAK.VBELN
      AND VBFA.VBTYP_N = 'M'
  )
ORDER BY VBAK.ERDAT ASC
```

### Analisis de razones de devolucion (para reporting)

```sql
SELECT
  VBAK.AUGRU,
  TVAUG.BEZEI AS DESCRIPCION,
  COUNT(*) AS CANTIDAD_DEVOLUCIONES,
  SUM(VBAK.NETWR) AS VALOR_TOTAL,
  AVG(VBAK.NETWR) AS VALOR_PROMEDIO,
  VBAK.VKORG
FROM VBAK
  LEFT JOIN TVAUG ON TVAUG.AUGRU = VBAK.AUGRU AND TVAUG.SPRAS = 'S'
WHERE
  VBAK.AUART = 'RE'
  AND VBAK.VKORG = '{org_ventas}'
  AND VBAK.ERDAT BETWEEN '{fecha_desde}' AND '{fecha_hasta}'
GROUP BY VBAK.AUGRU, TVAUG.BEZEI, VBAK.VKORG
ORDER BY VALOR_TOTAL DESC
```

### Devolucion con GR completada pero sin factura de reversa

```sql
SELECT
  LIKP.VBELN AS ENTREGA_DEV,
  LIKP.KUNNR,
  LIKP.LFDAT,
  VBAK.VBELN AS PEDIDO_RE,
  VBAK.NETWR
FROM LIKP
  INNER JOIN VBFA F1 ON F1.VBELN = LIKP.VBELN AND F1.VBTYP_V = 'J'
  INNER JOIN VBAK ON VBAK.VBELN = F1.VBELV
WHERE
  LIKP.LFART = 'LR'
  AND LIKP.WBSTK = 'C'
  AND NOT EXISTS (
    SELECT 1 FROM VBFA F2
    WHERE F2.VBELV = LIKP.VBELN
      AND F2.VBTYP_N = 'M'
  )
```

### Flujo completo de devolucion (documento a documento)

```sql
SELECT
  VBFA.VBELV AS DOC_ORIGEN,
  VBFA.POSNN AS POS_ORIGEN,
  VBFA.VBTYP_V AS TIPO_ORIGEN,
  VBFA.VBELN AS DOC_DESTINO,
  VBFA.POSNV AS POS_DESTINO,
  VBFA.VBTYP_N AS TIPO_DESTINO,
  VBFA.RFMNG AS CANTIDAD,
  VBFA.RFWRT AS VALOR
FROM VBFA
WHERE VBFA.VBELV = '{numero_pedido_RE}'
   OR VBFA.VBELN = '{numero_pedido_RE}'
ORDER BY VBFA.VBTYP_N
```

---

## Errores comunes y solucion

### Error: "Motivo de reclamacion obligatorio"

```
Causa: AUGRU vacio cuando el tipo de doc lo requiere
Solucion:
  - Ingresar AUGRU en cabecera del pedido RE/CR/DR
  - O desactivar obligatoriedad en VOV8 (campo "Reclamac. oblig.")
  - Tabla de razones: SPRO → TVAUG
```

### Error: "La nota de credito supera el valor original"

```
Causa: Nota credito CR por mayor valor que la factura de referencia
Solucion:
  - Verificar campo VBAP-KBETR (valor a creditar)
  - Config en SPRO → Parametros de credito
  - Reducir importe al valor maximo permitido
  - O autorizar mediante VKM1 (gestion credito)
```

### Error: "Entrega de devolucion sin referencia valida"

```
Causa: LR creada sin referencia a pedido RE valido, o pedido cancelado
Solucion:
  - VL01N debe referenciar pedido RE existente y abierto
  - Verificar VBAK-GBSTK del pedido RE (no debe ser 'C' completado)
  - Si pedido rechazado (ABGRU), debe eliminarse ABGRU primero
```

### Error: "Movimiento 651 no permitido para material"

```
Causa: Material tiene gestion de lotes obligatoria y no se informo lote
Solucion:
  - En VL02N informar LIPS-CHARG (numero de lote)
  - O material tiene restriccion de movimientos en MM03
  - Verificar tabla T156 para configuracion de movement types
```

### Error: "Documento de referencia no encontrado en copia"

```
Causa: VTFA mal configurado o no existe rutina de copia OR→RE
Solucion:
  - VTFA: verificar que existe entrada OR → RE (o F2 → CR)
  - Verificar campo "Copia de posicion" no sea espacios
  - Consultar SM30 tabla VTFA directamente
```

### Error: "Bloqueo de facturacion activo en pedido devolucion"

```
Causa: VOV8 para RE tiene bloqueo de facturacion activado por defecto
Solucion (opciones):
  1. Liberar manualmente en VA02 → quitar campo bloqueo
  2. VKM1 → lista bloqueos credito → liberar
  3. SPRO → VOV8 → RE → desactivar bloqueo facturacion por defecto
  4. Workflow automatico que libera tras GR completado
```

---

## Tablas de customizing relevantes

| TCode/Tabla | Descripcion |
|-------------|-------------|
| VOV8 | Tipos de documentos de ventas (RE, CR, DR, FD) |
| VOV9 | Razones de rechazo de posicion (TVAG) |
| TVAUG | Razones de reclamacion de cabecera |
| VTFA | Copy control pedido → pedido |
| VTLA | Copy control pedido → entrega |
| VTFL | Copy control entrega → factura |
| OMJJ | Configuracion de movement types (651, 653) |
| SWDD | Definicion de workflows de aprobacion |
| VKM1 | Lista de bloqueos de credito (liberacion) |
| VF05N | Lista de documentos de facturacion pendientes |
| VL06O | Monitor de entregas pendientes de GR |

---

## KPIs tipicos de reclamaciones

```
Tasa de devolucion = (Valor RE / Valor OR) * 100   -> objetivo < 2%
Tiempo proceso devolucion = fecha GR - fecha RE     -> objetivo < 5 dias
Notas credito pendientes = COUNT(CR sin G2)         -> objetivo < 10
Razon principal devolucion = TOP AUGRU por valor    -> para accion correctiva

Query tasa de devolucion por cliente:
SELECT
  VBAK.KUNNR,
  KNA1.NAME1,
  SUM(CASE WHEN VBAK.AUART = 'OR' THEN VBAK.NETWR ELSE 0 END) AS VENTAS,
  SUM(CASE WHEN VBAK.AUART = 'RE' THEN VBAK.NETWR ELSE 0 END) AS DEVOLUCIONES,
  (SUM(CASE WHEN AUART='RE' THEN NETWR ELSE 0 END) /
   NULLIF(SUM(CASE WHEN AUART='OR' THEN NETWR ELSE 0 END),0)) * 100 AS TASA_DEV
FROM VBAK INNER JOIN KNA1 ON KNA1.KUNNR = VBAK.KUNNR
WHERE VBAK.VKORG = '{org}' AND VBAK.ERDAT BETWEEN '{desde}' AND '{hasta}'
GROUP BY VBAK.KUNNR, KNA1.NAME1
ORDER BY TASA_DEV DESC
```
