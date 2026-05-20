# Scenarios Especiales MM

## 1. Consignacion (Consignment) — End to End

### Concepto
El proveedor deposita material en nuestro almacen. Solo pagamos cuando lo consumimos.
El stock pertenece al proveedor hasta el consumo.

### Flujo completo
```
1. Info record tipo consignacion (ME11)
   EINE-KZKON = 'X' (consignment flag)
   Precio de consignacion en condicion

2. Pedido con tipo posicion K (ME21N)
   EKPO-PSTYP = '2' (consignment)
   Sin precio en PO (viene del info record)

3. Entrada mercancias (MIGO, TM 101 K)
   Stock va a "consignacion" (MKOL), NO a MARD
   Sin asiento contable (stock del proveedor)

4. Consumo / Transfer to own stock (MIGO, TM 411 K→E)
   Traslado de consignacion a stock propio
   Asiento: D: Stock, C: Obligacion consignacion

5. Liquidacion periodica (MRKO)
   Genera factura automatica por consumos del periodo
   Asiento: D: Obligacion consignacion, C: AP proveedor
```

### Queries MCP
```sql
-- Stock consignacion actual
SELECT MATNR, WERKS, LGORT, LIFNR, SLABS, SINSM FROM MKOL
WHERE WERKS = '{centro}'

-- Info records de consignacion
SELECT EINA.INFNR, EINA.MATNR, EINA.LIFNR, EINE.KZKON
FROM EINA JOIN EINE ON EINA.INFNR = EINE.INFNR
WHERE EINE.KZKON = 'X' AND EINE.EKORG = '{org}'
```

## 2. Subcontratacion (Subcontracting) — End to End

### Concepto
Enviamos materias primas al proveedor, que las procesa y nos devuelve producto terminado/semielaborado.

### Flujo completo
```
1. BOM de subcontratacion
   CS01 → BOM para el material subcontratado
   Componentes = materias primas que enviamos

2. Pedido con tipo posicion L (ME21N)
   EKPO-PSTYP = '3' (subcontracting)
   Sistema muestra componentes automaticamente (de BOM)

3. Provision de componentes (ME2O → MIGO TM 541)
   Salida de componentes al proveedor
   Stock pasa a "stock en proveedor" (MSLB)
   D: Stock proveedor, C: Stock almacen

4. Entrada mercancias producto terminado (MIGO TM 101)
   GR del producto procesado
   Consumo automatico de componentes (TM 543)
   D: Stock producto, C: GR/IR + consumo componentes

5. Factura (MIRO)
   Solo por el servicio de procesamiento
   D: GR/IR, C: AP proveedor

6. Monitoreo componentes (ME2O)
   Control de stock de componentes en el proveedor
```

### Queries MCP
```sql
-- Stock en proveedor (subcontratacion)
SELECT MATNR, WERKS, LIFNR, SLABS FROM MSLB
WHERE WERKS = '{centro}'

-- POs de subcontratacion pendientes
SELECT EKKO.EBELN, EKPO.EBELP, EKPO.MATNR, EKPO.MENGE, EKPO.WEMNG
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKPO.PSTYP = '3' AND EKPO.ELIKZ = '' AND EKKO.EKORG = '{org}'
```

## 3. Service Procurement (ML81N) — End to End

### Flujo completo
```
1. Service Master (AC01)
   Crear servicios como maestros reutilizables
   Tabla: ASMD (service master general), ASMDT (textos)

2. Pedido con tipo posicion D (ME21N)
   EKPO-PSTYP = '9' (service)
   Tab "Services" → definir lineas de servicio, cantidades, precios
   Alternativa: usar "Service specifications" (ML01)

3. Hoja de entrada de servicios / SES (ML81N)
   Proveedor realiza servicio → registrar aceptacion
   Aprobacion del SES (si hay release procedure)

4. Factura (MIRO)
   Con referencia al PO + SES aprobado

No hay entrada de mercancias fisica
La SES sustituye a la GR
```

### Queries MCP
```sql
-- POs de servicio pendientes de SES
SELECT EKKO.EBELN, EKPO.EBELP, EKPO.TXZ01, EKPO.NETWR
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKPO.PSTYP = '9' AND EKPO.REPOS = 'X' AND EKPO.ELIKZ = ''

-- SES registradas
SELECT LBLNI, EBELN, EBELP, KTEXT1, LWERT FROM ESSR
WHERE EBELN = '{po}'
```

## 4. Limit / Blanket Purchase Order

### Concepto
PO con un importe limite sin cantidades fijas. Se usa para compras recurrentes menores (materiales de oficina, mantenimiento).

### Config
```
ME21N → Tipo posicion B (Limit)
  - Sin material (solo texto)
  - Categoria imputacion obligatoria (K, F, etc.)
  - Tab "Limits": Expected value, Overall limit
  - GR se registra por monto (no cantidad)

Alternativa: PO con indicador "value contract" y monto global
```

## 5. Returns to Vendor (Devolucion)

### Flujo
```
1. Crear PO de devolucion (ME21N)
   Tipo documento: Return (RE) o PO normal con ref. a GR original

2. Salida de mercancias al proveedor (MIGO TM 122)
   Reference: PO de devolucion o PO original
   D: GR/IR clearing, C: Stock

3. Nota de credito del proveedor (MIRO)
   Tipo: Credit memo
   D: AP vendor, C: GR/IR clearing

Alternativa sin PO: MIGO TM 161 (con referencia al doc material del GR original)
```

## 6. Pipeline Settlement

### Concepto
Material suministrado continuamente (agua, gas, electricidad). No hay pedido ni GR individuales.

### Flujo
```
1. Material con tipo posicion Pipeline
   Info record con precio pipeline

2. Consumo directo (sin GR)
   TM 201 (consumo) directo sin PO
   O: TM especial para pipeline

3. Liquidacion periodica
   MRKO o programa de liquidacion
   Basado en consumos del periodo vs contadores
```

## 7. Third-Party (Triangular)

### Concepto
Cliente nos pide un material → nosotros pedimos al proveedor → proveedor envia directo al cliente.

### Flujo
```
1. Pedido de venta (VA01)
   Material con tipo posicion TAS (third-party)

2. Solicitud pedido automatica
   MRP genera PR automaticamente

3. PO al proveedor (ME21N, desde PR)
   Direccion de entrega = cliente final

4. Factura al cliente (VF01)
   Cuando proveedor confirma envio

5. GR estadistico (MIGO)
   Sin movimiento de stock (solo estadistico)

6. Factura del proveedor (MIRO)
   Contra nuestro PO

No hay stock en nuestro almacen
```

## 8. Framework Order / Contrato Abierto

### Concepto
Acuerdo a largo plazo con un proveedor por un importe/cantidad global. Los pedidos individuales se generan contra el contrato.

### Flujo
```
1. Crear contrato (ME31K)
   Tipo: MK (quantity contract) o WK (value contract)
   Validez: 1 ano tipicamente
   Importe/cantidad global

2. Pedidos contra contrato (ME21N)
   Referencia al contrato
   Cantidad/valor se descuenta del contrato

3. Monitor de contratos (ME3M, ME3L)
   Seguimiento de utilizacion vs tope

4. Renovacion / Cierre
   ME32K modificar validez o crear nuevo

Tablas: EKKO (BSTYP='K' para contrato), EKPO
```

## 9. Evaluated Receipt Settlement (ERS) ampliado

### Config completa
```
1. Proveedor
   LFM1-XERSY = 'X' (ERS flag) en org compras
   LFM1-XERSR = 'X' (ERS con GR-based IV)

2. Info record
   EINE con precio fijo (condicion PB00)

3. PO
   EKPO-XERSY = 'X' (hereda del proveedor)
   EKPO-WEBRE = 'X' (GR-based IV)

4. GR (MIGO 101)
   Registrar normalmente

5. MRRL (Liquidacion automatica)
   Ejecutar periodicamente (diario/semanal)
   Genera facturas automaticas = GR * precio info record
   Sin intervencion manual
```

## 10. Automatic PO Generation from PR

### Flujo
```
ME59N → Conversion automatica de PR a PO

Prerequisitos:
  - PR tiene proveedor asignado (EBAN-FLIEF)
  - PR liberada (EBAN-FRGKZ = '2')
  - Source of supply definida (source list o info record)
  - Config agrupacion: agrupar PRs del mismo proveedor en 1 PO

Config: SPRO → MM → Purchasing → PO →
  Automatic Generation of POs → Set Up Automatic PO Generation
```

### Queries MCP
```sql
-- PRs listas para conversion automatica
SELECT BANFN, BNFPO, MATNR, MENGE, FLIEF, EKORG, WERKS, FRGKZ
FROM EBAN
WHERE EBELN = '' AND FRGKZ = '2' AND LOEKZ = ''
AND EKORG = '{org}' AND WERKS = '{centro}'
ORDER BY FLIEF, MATNR
```
