# Errores Comunes SD — Diagnostico con MCP

Referencia de los errores mas frecuentes en SD (VA01, VL01N, VF01, VK11, XD01) con queries MCP para diagnosticar la causa raiz y la solucion correcta.

---

## Errores en Pedido de Venta (VA01 / VA02)

---

### ERROR 01 — "Item category could not be determined"
**Mensaje:** Categoria de posicion no se pudo determinar (V1 073 / V1 074)

**Causa:** La tabla T184 no tiene una entrada valida para la combinacion de tipo de documento de venta + grupo de categoria de material (del campo MTPOS_MARA del material) + uso + categoria de posicion de nivel superior.

**Diagnostico MCP:**
```sql
-- Ver que grupo de categoria de material tiene el material
SELECT MATNR, MTPOS_MARA FROM MARA WHERE MATNR = '{material}'

-- Buscar entradas en T184 para ese tipo de doc y grupo
SELECT PSTYV_V, MTPOS, PMATN, PSTAT, PSTYV
FROM T184
WHERE PSTYV_V = '{tipo_doc}'
  AND MTPOS = '{item_cat_group}'
ORDER BY PSTYV_V, MTPOS, PMATN, PSTAT

-- Ver tipos de categoria de posicion existentes
SELECT PSTYV, BEZEI FROM TVAP WHERE SPRAS = 'S'

-- Ver grupos de categoria de material configurados
SELECT MTPOS, BEZEI FROM T184G WHERE SPRAS = 'S'
```

**Solucion:** Crear entrada en T184 via VOV4 (asignacion de categoria de posicion) con la combinacion correcta de tipo de documento + grupo de categoria de material.

---

### ERROR 02 — "Schedule line category could not be determined"
**Mensaje:** No se puede determinar la categoria de linea de reparto (V1 626)

**Causa:** La tabla T188 no tiene entrada para la combinacion de categoria de posicion + tipo MRP del material.

**Diagnostico MCP:**
```sql
-- Ver tipo MRP del material en la planta
SELECT MATNR, WERKS, DISMM FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{planta}'

-- Buscar entradas en T188 para esa categoria de posicion
SELECT PSTYV, DISMM, ETTYP, ETTYP_MAN
FROM T188
WHERE PSTYV = '{item_cat}'
ORDER BY PSTYV, DISMM

-- Si DISMM esta vacio, verificar si existe entrada con DISMM en blanco
SELECT PSTYV, DISMM, ETTYP FROM T188
WHERE PSTYV = '{item_cat}' AND DISMM = ''
```

**Solucion:** Crear entrada en T188 (VOV5 - asignacion de categoria de linea de reparto) con la combinacion de categoria de posicion + tipo MRP.

---

### ERROR 03 — "Material not maintained for sales organization / distribution channel"
**Mensaje:** Material {X} no esta mantenido para la organizacion de ventas {Y} (V1 023)

**Causa:** El material no tiene la vista de ventas extendida para esa combinacion de org. ventas + canal de distribucion (tabla MVKE).

**Diagnostico MCP:**
```sql
-- Verificar vistas de ventas del material
SELECT MATNR, VKORG, VTWEG, MTPOS_MARA, KONDM, MVGR1, MVGR2
FROM MVKE
WHERE MATNR = '{material}'
ORDER BY VKORG, VTWEG

-- Verificar vista de organizacion de ventas (MVKE requiere ambas)
SELECT MATNR, VKORG, VTWEG, VERPR, SKTOF
FROM MVKE
WHERE MATNR = '{material}' AND VKORG = '{org}' AND VTWEG = '{canal}'

-- Ver si el material existe en MARA (nivel cliente)
SELECT MATNR, MBRSH, MTART, MEINS FROM MARA WHERE MATNR = '{material}'
```

**Solucion:** Extender el material (MM01 o MM50) para la org. de ventas y canal de distribucion requeridos, completando las vistas Ventas: Datos de Org. de Ventas 1 y 2.

---

### ERROR 04 — "Pricing procedure could not be determined"
**Mensaje:** Procedimiento de calculo de precio no se pudo determinar (VP 100)

**Causa:** No existe entrada en T683V para la combinacion de organizacion de ventas + canal de distribucion + sector + clase de documento de venta + tipo de cliente de precios + procedimiento de precios del cliente.

**Diagnostico MCP:**
```sql
-- Ver procedimiento de pricing del cliente (KALSM en KNVV)
SELECT KUNNR, VKORG, VTWEG, KALKS
FROM KNVV
WHERE KUNNR = '{cliente}' AND VKORG = '{org}' AND VTWEG = '{canal}'

-- Ver clase de documento del tipo de pedido (KALSM en TVAK)
SELECT AUART, KALSM, AUART_RABE FROM TVAK WHERE AUART = '{tipo_doc}'

-- Verificar entradas en T683V (determinacion de esquema de precios)
SELECT VKORG, VTWEG, SPART, KALSM, KALKS, KVEWE
FROM T683V
WHERE VKORG = '{org}' AND VTWEG = '{canal}'
ORDER BY SPART, KALSM, KALKS

-- Ver esquemas de calculo de precio disponibles
SELECT KVEWE, KAPPL, KALSM, BEZEI FROM T683S WHERE KVEWE = 'A' AND SPRAS = 'S'
```

**Solucion:** Configurar en OVKK (Fijar esquema de calculo del precio) la combinacion de org. ventas + canal + sector + clase de doc + proc. precios cliente → esquema de calculo.

---

### ERROR 05 — "Incompletion log — mandatory fields missing"
**Mensaje:** El documento tiene datos incompletos (VB 030)

**Causa:** Campos definidos como obligatorios en el log de incompletitud (T185/T185A) no tienen valor.

**Diagnostico MCP:**
```sql
-- Ver campos de incompletitud configurados para el tipo de documento
SELECT AUART, FIELDNAME, DATAFIELD, LVORM, GRUPP
FROM T185 WHERE AUART = '{tipo_doc}'

-- Ver campos incompletos del pedido especifico
SELECT VBELN, POSNR, FCODE, GRUPP
FROM VBUV WHERE VBELN = '{pedido}'
ORDER BY POSNR, GRUPP

-- Ver que campos de incompletitud existen globalmente en SD
SELECT FIELDNAME, DATAFIELD, TABNAME, LVORM
FROM TVUV WHERE SPRAS = 'S'
```

**Solucion:** Completar los campos indicados en el log (Extras > Log de incompletitud en VA02). Si el campo no deberia ser obligatorio, revisar customizing en OVA2 (Definir grupos de incompletitud) y OVA0 (Asignar campos).

---

### ERROR 06 — "Credit limit exceeded / Credit block"
**Mensaje:** Pedido bloqueado por control de credito (F1 000 / F1 001)

**Causa:** El credito disponible del cliente en el area de credito es insuficiente para el valor del pedido.

**Diagnostico MCP:**
```sql
-- Ver estado de bloqueo del pedido
SELECT VBELN, AUART, KUNNR, NETWR, WAERK, CMGST, LIFSK, FAKSK
FROM VBAK WHERE VBELN = '{pedido}'
-- CMGST: ' '=sin verificar, 'A'=ok, 'B'=aviso, 'C'=bloqueado

-- Ver limite y exposicion de credito del cliente
SELECT KUNNR, KKBER, KLIMK, SKFOR, SSOBL, SDFLT, CPDKY, CTLPC
FROM KNKK
WHERE KUNNR = '{cliente}' AND KKBER = '{area_credito}'

-- Ver area de credito asignada al cliente
SELECT KUNNR, BUKRS, KKBER FROM KNB1
WHERE KUNNR = '{cliente}' AND BUKRS = '{sociedad}'

-- Ver parametros de control de credito del tipo de pedido
SELECT AUART, CMGST, GUOBD FROM TVAK WHERE AUART = '{tipo_doc}'

-- Ver exposicion actual vs limite
SELECT KUNNR, KKBER, KNKLI, KLIMK, SKFOR, SSOBL
FROM KNKK WHERE KUNNR = '{cliente}'
```

**Solucion:** Liberar el pedido con VKM3 (liberacion individual) o VKM5 (liberacion masiva). Para aumentar limite: FD32 (modificar limite de credito del cliente).

---

### ERROR 07 — "Partner function {XX} is mandatory but not assigned"
**Mensaje:** La funcion de interlocutor {SH/PY/BP} es obligatoria (V1 322)

**Causa:** El esquema de interlocutores del tipo de pedido exige una funcion de socio que no esta en los datos maestros del cliente.

**Diagnostico MCP:**
```sql
-- Ver socios del cliente para esa org de ventas
SELECT KUNNR, VKORG, VTWEG, SPART, PARVW, KUNN2
FROM KNVP
WHERE KUNNR = '{cliente}' AND VKORG = '{org}' AND VTWEG = '{canal}'
ORDER BY PARVW

-- Ver esquema de interlocutores del tipo de documento
SELECT AUART, PARVW, DEFFI, NREIN, KNNOT
FROM TVAP_PARVW WHERE AUART = '{tipo_doc}'
-- (o ver en TVAK el campo PARVW_SCH y luego T184P)

-- Ver esquema de interlocutores asignado al tipo de pedido
SELECT AUART, PSHIP FROM TVAK WHERE AUART = '{tipo_doc}'

-- Ver funciones de socio requeridas en el esquema
SELECT PARVW, PERES, NREIN FROM T185P WHERE PSHIP = '{esquema}'

-- Ver descripcion de funciones de socio
SELECT PARVW, VTEXT FROM TPAR WHERE SPRAS = 'S' AND PARVW IN ('AG','WE','RE','RG','VE','SP')
```

**Solucion:** Agregar el socio faltante en los datos maestros del cliente (XD02 > Funciones de interlocutor) o en el pedido directamente si el esquema lo permite.

---

### ERROR 08 — "Output type could not be determined"
**Mensaje:** No se determino tipo de mensaje / output (V4 001)

**Causa:** No existe registro de condicion en la tabla de output (NAST/TNAPR) para la combinacion del documento.

**Diagnostico MCP:**
```sql
-- Ver registros de output del documento
SELECT KAPPL, OBJKY, KSCHL, VKORG, NACHA, SPRAS, NDPRO, VSTAT
FROM NAST WHERE KAPPL = 'V1' AND OBJKY = '{pedido}'

-- Ver esquema de output del tipo de pedido
SELECT AUART, NACHA FROM TVAK WHERE AUART = '{tipo_doc}'

-- Ver condiciones de output configuradas (tabla A900 tipicamente)
SELECT MANDT, KAPPL, KSCHL, VKORG, KUNNR, NACHA
FROM A900
WHERE KAPPL = 'V1' AND VKORG = '{org}'

-- Ver tipos de output disponibles para documentos de venta
SELECT KSCHL, VTEXT FROM TNAPT
WHERE KAPPL = 'V1' AND SPRAS = 'S'
ORDER BY KSCHL
```

**Solucion:** Crear registro de condicion de output en VV11 (tipo de mensaje BA00 u otro) para la combinacion correcta de org. de ventas + cliente o global.

---

### ERROR 09 — "Document type {XX} not defined / not allowed for sales area"
**Mensaje:** El tipo de documento de venta no esta permitido para el area de ventas (V1 501)

**Causa:** El tipo de pedido no esta asignado a la combinacion de org. ventas + canal + sector en TVAK o en la tabla de asignacion TVBO.

**Diagnostico MCP:**
```sql
-- Ver asignacion de tipos de doc a areas de ventas
SELECT VKORG, VTWEG, SPART, AUART
FROM TVBO
WHERE VKORG = '{org}' AND VTWEG = '{canal}' AND SPART = '{sector}'
ORDER BY AUART

-- Ver datos del tipo de documento
SELECT AUART, BEZEI, AUTYP, NUMKI, KALSM
FROM TVAK WHERE AUART = '{tipo_doc}'
  AND SPRAS = 'S'

-- Confirmar que el area de ventas existe
SELECT VKORG, VTWEG, SPART
FROM TVKWZ
WHERE VKORG = '{org}' AND VTWEG = '{canal}' AND SPART = '{sector}'
```

**Solucion:** Asignar el tipo de documento al area de ventas en OVAZ (Asignar tipos de pedido de venta a areas de ventas).

---

### ERROR 10 — "Delivery block active on order"
**Mensaje:** Pedido tiene bloqueo de entrega (V1 806)

**Causa:** El campo LIFSK (bloqueo de entrega) en VBAK tiene un valor configurado.

**Diagnostico MCP:**
```sql
-- Ver bloqueos del pedido
SELECT VBELN, AUART, KUNNR, LIFSK, FAKSK, CMGST, UVALL
FROM VBAK WHERE VBELN = '{pedido}'

-- Ver bloqueos a nivel posicion
SELECT VBELN, POSNR, MATNR, LIFSK AS POSNR_LIFSK, FAKSP
FROM VBAP WHERE VBELN = '{pedido}'

-- Ver descripcion de los tipos de bloqueo de entrega
SELECT LIFSP, VTEXT FROM TVL WHERE SPRAS = 'S'

-- Ver historial de cambios del bloqueo
SELECT CDHDR.OBJECTID, CDPOS.FNAME, CDPOS.VALUE_OLD, CDPOS.VALUE_NEW,
       CDHDR.USERNAME, CDHDR.UDATE
FROM CDHDR INNER JOIN CDPOS ON CDHDR.CHANGENR = CDPOS.CHANGENR
WHERE CDHDR.OBJECTCLAS = 'VERKBELEG'
  AND CDHDR.OBJECTID = '{pedido}'
  AND CDPOS.FNAME = 'LIFSK'
```

**Solucion:** Eliminar el bloqueo de entrega en VA02 > cabecera > expedicion > bloqueo, o usar VKM3/VOV5 si es un bloqueo de credito.

---

## Errores en Entrega (VL01N / VL02N)

---

### ERROR 11 — "No items selected for delivery / No open quantities"
**Mensaje:** No hay posiciones seleccionadas para la entrega (VL 080 / VL 095)

**Causa:** Las posiciones del pedido no tienen cantidad abierta (ya entregadas, bloqueadas o con fecha futura fuera del horizonte).

**Diagnostico MCP:**
```sql
-- Ver cantidades del pedido vs entregadas
SELECT VBELN, POSNR, MATNR, KWMENG, KBMENG, ABGRU, UEPOS
FROM VBAP WHERE VBELN = '{pedido}'
-- KWMENG = cantidad pedida, KBMENG = cantidad confirmada, ABGRU = motivo de rechazo

-- Ver cantidades en repartos (fuente de cantidad abierta)
SELECT VBELN, POSNR, ETENR, ETTYP, EDATU, WMENG, BMENG, LMENG
FROM VBEP
WHERE VBELN = '{pedido}'
ORDER BY POSNR, ETENR
-- WMENG=pedida, BMENG=confirmada, LMENG=entregada

-- Ver flujo de documentos (cuanto ya fue entregado)
SELECT VBELV, POSNV, VBELN, POSNN, VBTYP_N, RFMNG
FROM VBFA
WHERE VBELV = '{pedido}' AND VBTYP_N IN ('J', 'T')
-- J=entrega salida, T=entrega entrada

-- Ver bloqueo de entrega en posiciones
SELECT VBELN, POSNR, LIFSK FROM VBAP
WHERE VBELN = '{pedido}' AND LIFSK <> ''
```

**Solucion:** Verificar que el reparto tenga fechas dentro del horizonte de entrega, que no haya motivo de rechazo (ABGRU) y que la cantidad confirmada sea mayor que la entregada.

---

### ERROR 12 — "Shipping point could not be determined"
**Mensaje:** Punto de expedicion no se puede determinar (VL 008)

**Causa:** La tabla TVSBT no tiene una entrada para la combinacion de condicion de expedicion (del cliente) + grupo de carga (del material) + planta.

**Diagnostico MCP:**
```sql
-- Ver condicion de expedicion del cliente
SELECT KUNNR, VKORG, VSBED FROM KNVV
WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Ver grupo de carga del material
SELECT MATNR, LADGR FROM MARA WHERE MATNR = '{material}'

-- Ver determinacion de punto de expedicion configurada
SELECT VSBED, LADGR, WERKS, VSTEL
FROM TVSBT
WHERE VSBED = '{cond_exp}' AND LADGR = '{grp_carga}' AND WERKS = '{planta}'

-- Si no hay entrada especifica, buscar con combinaciones vacias
SELECT VSBED, LADGR, WERKS, VSTEL FROM TVSBT
WHERE WERKS = '{planta}'
ORDER BY VSBED, LADGR

-- Ver puntos de expedicion existentes
SELECT VSTEL, VTEXT FROM TVST WHERE SPRAS = 'S'
```

**Solucion:** Configurar determinacion de punto de expedicion en OVL2 (Asignar puntos de expedicion) para la combinacion de condicion de expedicion + grupo de carga + planta.

---

### ERROR 13 — "PGI error — insufficient stock"
**Mensaje:** No hay stock suficiente para el goods issue (M7 096 / M7 022)

**Causa:** El stock disponible en el almacen/ubicacion es menor que la cantidad de picking.

**Diagnostico MCP:**
```sql
-- Ver stock disponible en almacen
SELECT MATNR, WERKS, LGORT, LABST, INSME, SPEME, EINME, UMLME
FROM MARD
WHERE MATNR = '{material}' AND WERKS = '{planta}'
-- LABST=libre utilizacion, INSME=inspeccion calidad, SPEME=bloqueado

-- Ver stock total de la empresa
SELECT MATNR, MANDT, LBKUM, SALK3, SALKV
FROM MBEW WHERE MATNR = '{material}' AND BWKEY = '{planta}'

-- Ver movimientos recientes del material
SELECT MBLNR, MJAHR, ZEILE, BWART, MENGE, MEINS, LGORT, UNAME, BUDAT
FROM MSEG
WHERE MATNR = '{material}' AND WERKS = '{planta}'
ORDER BY MBLNR DESC, MJAHR DESC
-- Usar TOP/FETCH FIRST 20 ROWS para limitar

-- Ver reservas activas que bloquean stock
SELECT RSNUM, RSPOS, MATNR, WERKS, LGORT, BDMNG, ENMNG, BWART
FROM RESB
WHERE MATNR = '{material}' AND WERKS = '{planta}' AND XLOEK = ''
```

**Solucion:** Verificar stock con MMBE. Si el stock es correcto en el sistema pero el error persiste, revisar reservas o considerar reposting via MIGO.

---

### ERROR 14 — "Route could not be determined"
**Mensaje:** No se pudo determinar la ruta (VL 012)

**Causa:** Falta configuracion de determinacion de ruta (zona de expedicion del punto de salida + zona de transporte del cliente + condicion de transporte + grupo de transporte del material).

**Diagnostico MCP:**
```sql
-- Ver zona de transporte del cliente destinatario
SELECT KUNNR, LZONE FROM KNA1 WHERE KUNNR = '{cliente}'

-- Ver grupo de transporte del material
SELECT MATNR, TRAGR FROM MARA WHERE MATNR = '{material}'

-- Ver condicion de transporte del cliente
SELECT KUNNR, VKORG, VSBED FROM KNVV WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Ver tabla de determinacion de rutas
SELECT ALAND, REGIO, LZONE, VSBED, TRAGR, ROUTE
FROM T687D
WHERE LZONE = '{zona_transporte}' AND VSBED = '{cond_exp}'

-- Ver rutas configuradas
SELECT ROUTE, BEZEI FROM TVRO WHERE SPRAS = 'S'
```

---

### ERROR 15 — "Transfer order not created / Warehouse Management error"
**Mensaje:** No se puede crear la orden de traslado (L9 001)

**Causa:** El material/almacen no esta configurado en WM, o falta customizing de tipo de almacen.

**Diagnostico MCP:**
```sql
-- Ver si el material tiene datos de almacen
SELECT MATNR, LGNUM, LGTYP, LGPLA, LGPLA_BESTAND
FROM MLGN WHERE MATNR = '{material}'

-- Ver configuracion de almacen de la entrega
SELECT VBELN, LGNUM, LGNUM_K FROM LIKP WHERE VBELN = '{entrega}'

-- Ver ubicaciones disponibles en el almacen
SELECT LGNUM, LGTYP, LGPLA, BESTME, LPTYP
FROM LGPLA WHERE LGNUM = '{almacen}' AND LGTYP = '{tipo_almacen}'
ORDER BY LGPLA

-- Ver ordenes de traslado existentes para la entrega
SELECT TANUM, LGNUM, TAQUI, VBELN, VSTEL
FROM LTAP WHERE VBELN = '{entrega}'
```

---

## Errores en Factura (VF01 / VF02)

---

### ERROR 16 — "Account could not be determined" (VKOA / Revenue Account Determination)
**Mensaje:** No se puede determinar la cuenta de mayor (VK 018 / VK 019)

**Causa:** Falta configuracion en VKOA (determinacion de cuentas) para la combinacion de: plan de cuentas + aplicacion (V) + tipo de cuenta + org. ventas + grupo de cuentas del cliente + grupo de cuentas del material + tipo de condicion.

**Diagnostico MCP:**
```sql
-- Ver grupo de cuentas del cliente (campo KTGRD en KNVV)
SELECT KUNNR, VKORG, VTWEG, KTGRD
FROM KNVV WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Ver grupo de cuentas del material (campo KTGRM en MVKE)
SELECT MATNR, VKORG, VTWEG, KTGRM
FROM MVKE WHERE MATNR = '{material}' AND VKORG = '{org}'

-- Verificar entradas en VKOA para el plan de cuentas
SELECT KTOPL, KVEWE, KAPPL, KSCHL, VKORG, KTGRD, KTGRM, SAKN1, SAKN2
FROM VKOA
WHERE KTOPL = '{plan_cuentas}' AND KVEWE = 'E' AND VKORG = '{org}'
ORDER BY KSCHL, KTGRD, KTGRM

-- Ver el plan de cuentas de la sociedad
SELECT BUKRS, KTOPL FROM T001 WHERE BUKRS = '{sociedad}'

-- Ver condiciones de precio de la posicion de factura
SELECT KNUMV, KPOSN, KSCHL, KWERT, KBETR
FROM KONV WHERE KNUMV = '{numero_cond}' AND KSCHL = 'KOFI'
```

**Solucion:** Configurar en VKOA (Vinculacion de cuentas de mayor) la combinacion correcta, asignando una cuenta de ingresos para cada combinacion de grupos de cuenta.

---

### ERROR 17 — "Billing block active / Documento tiene bloqueo de facturacion"
**Mensaje:** El pedido o entrega tiene bloqueo de facturacion (VF 067)

**Causa:** El campo FAKSK (bloqueo de facturacion en cabecera) o FAKSP (en posicion) tiene valor.

**Diagnostico MCP:**
```sql
-- Ver bloqueos de factura en el pedido origen
SELECT VBELN, AUART, KUNNR, FAKSK AS BLOQUEO_FACT_CAB
FROM VBAK WHERE VBELN = '{pedido}'

-- Ver bloqueos de factura en posiciones del pedido
SELECT VBELN, POSNR, MATNR, FAKSP AS BLOQUEO_FACT_POS
FROM VBAP WHERE VBELN = '{pedido}' AND FAKSP <> ''

-- Ver descripcion de tipos de bloqueo de factura
SELECT FAKSP, VTEXT FROM TVFS WHERE SPRAS = 'S'

-- Ver entregas con bloqueo de facturacion
SELECT VBELN, KUNNR, FKDAT, FAKSK
FROM LIKP WHERE FAKSK <> '' AND VSTEL = '{punto_exp}'
```

**Solucion:** Eliminar el bloqueo en VA02 (cabecera > facturacion) o en VL02N. Si el bloqueo es por credito, liberarlo en VKM3.

---

### ERROR 18 — "Document already completely billed"
**Mensaje:** El documento ya esta completamente facturado (VF 033)

**Causa:** Toda la cantidad de la entrega o pedido ya tiene un documento de factura en el flujo de documentos (VBFA).

**Diagnostico MCP:**
```sql
-- Ver facturas creadas para la entrega
SELECT VBELV, POSNN AS POSNV_FAC, VBELN AS FACTURA, POSNN, VBTYP_N, RFMNG
FROM VBFA
WHERE VBELV = '{entrega}' AND VBTYP_N IN ('M', 'N', 'O', 'P')
-- M=factura, N=nota credito, O=nota debito, P=factura proforma

-- Ver estado de facturacion de la entrega
SELECT VBELN, FKSTA, FKSTO, LFGSK
FROM LIKP WHERE VBELN = '{entrega}'
-- FKSTA: ' '=no facturada, 'A'=parcial, 'C'=completa

-- Ver cantidad facturada vs entregada por posicion
SELECT P.VBELN, P.POSNR, P.MATNR, P.LFIMG AS CANT_ENTREGADA,
       SUM(F.RFMNG) AS CANT_FACTURADA
FROM LIPS P
LEFT JOIN VBFA F ON F.VBELV = P.VBELN AND F.POSNV = P.POSNR AND F.VBTYP_N = 'M'
WHERE P.VBELN = '{entrega}'
GROUP BY P.VBELN, P.POSNR, P.MATNR, P.LFIMG
```

---

### ERROR 19 — "Payer not determined / Customer master data incomplete"
**Mensaje:** No se pudo determinar el pagador (VF 024)

**Causa:** No existe funcion de socio RG (pagador) en los socios del documento.

**Diagnostico MCP:**
```sql
-- Ver socios actuales del pedido/entrega
SELECT VBELN, POSNR, PARVW, KUNNR, LIFNR
FROM VBPA
WHERE VBELN = '{documento}' AND PARVW = 'RG'

-- Ver socios en datos maestros del cliente
SELECT KUNNR, VKORG, VTWEG, SPART, PARVW, KUNN2
FROM KNVP
WHERE KUNNR = '{cliente}' AND VKORG = '{org}' AND PARVW = 'RG'

-- Si no tiene RG, probablemente sea el mismo cliente
SELECT KUNNR, NAME1, KTOKD FROM KNA1 WHERE KUNNR = '{cliente}'
```

**Solucion:** Agregar la funcion de socio RG (pagador) en los datos maestros del cliente (XD02) o directamente en el pedido.

---

### ERROR 20 — "Tax code could not be determined / Missing tax condition"
**Mensaje:** No se determino el codigo de impuesto (FF 800 / VK 095)

**Causa:** Falta configuracion en la determinacion de impuestos: registros de condicion MWST vacuos o sin entrada para el pais + clase de impuesto del cliente/material.

**Diagnostico MCP:**
```sql
-- Ver clase de impuesto del cliente (TAXKD)
SELECT KUNNR, ALAND, TAXKD FROM KNVI WHERE KUNNR = '{cliente}'

-- Ver clase de impuesto del material (TAXM1)
SELECT MATNR, ALAND, TAXM1 FROM TAXCOM
-- O directamente en la vista de ventas del material:
SELECT MATNR, MWSKZ FROM MVKE WHERE MATNR = '{material}' AND VKORG = '{org}'

-- Ver registros de condicion de impuesto (tabla A003 o similar)
SELECT KAPPL, KSCHL, VKORG, KUNNR, MATNR, MWSKZ
FROM A003
WHERE KAPPL = 'TX' AND KSCHL = 'MWST' AND VKORG = '{org}'

-- Ver codigos de impuesto configurados en FI
SELECT MWSKZ, TEXT1 FROM T007S WHERE SPRAS = 'S' AND KALSM = 'TAXD'
```

**Solucion:** Crear registros de condicion MWST en VK11 o verificar que el cliente y el material tengan la clase de impuesto correcta en sus datos maestros.

---

## Errores de Pricing / Condiciones

---

### ERROR 21 — "Condition record not found for condition type {XXXX}"
**Mensaje:** No se encontro registro de condicion (VK 036)

**Causa:** No existe un registro de condicion valido (fecha, org. ventas, cliente/material) para el tipo de condicion en la tabla de acceso correspondiente.

**Diagnostico MCP:**
```sql
-- Identificar la tabla de acceso del tipo de condicion
SELECT KSCHL, KVEWE, KAPPL, TXTKZ FROM T685 WHERE KSCHL = '{tipo_cond}'
SELECT KSCHL, STAFFEL, ZUSCH FROM T685A WHERE KSCHL = '{tipo_cond}'

-- Ver tabla de condicion asignada (ej: A304 para PR00 con vkorg+vtweg+matnr)
-- El nombre de la tabla se construye como A + numero de tabla en T682I
SELECT KSCHL, KOTAB FROM T682I
WHERE KSCHL = '{tipo_cond}' AND KAPPL = 'V'
ORDER BY ZAUFN

-- Verificar registros en la tabla de condicion especifica (ej A304)
SELECT KAPPL, KSCHL, VKORG, VTWEG, MATNR, KBETR, KONWA, DATAB, DATBI
FROM A304
WHERE KSCHL = '{tipo_cond}' AND VKORG = '{org}'
  AND MATNR = '{material}'

-- Ver condiciones del documento actual
SELECT KNUMV, KPOSN, KSCHL, KBETR, KWERT, KSTAT, KNTYP
FROM KONV WHERE KNUMV = '{numero_cond}' AND KSCHL = '{tipo_cond}'
-- KSTAT: ' '=activa, 'D'=estadistica, 'S'=simulacion
```

**Solucion:** Crear registro de condicion en VK11 con los datos correctos (precio, validez, escala si aplica).

---

### ERROR 22 — "Condition type {XXXX} not in pricing procedure"
**Mensaje:** El tipo de condicion no esta en el procedimiento de calculo de precios (VK 046)

**Causa:** El tipo de condicion que se intenta agregar manualmente no existe en el esquema de calculo asignado al pedido.

**Diagnostico MCP:**
```sql
-- Ver tipos de condicion en el esquema de calculo del pedido
SELECT T.KALSM, T.STUNR, T.KSCHL, T.KRECH, T.KBASB, T.KINAK
FROM T683S T
WHERE T.KALSM = '{esquema_precio}' AND T.KVEWE = 'A'
ORDER BY T.STUNR

-- Ver el esquema asignado al pedido
SELECT VBELN, KALSM FROM VBAK WHERE VBELN = '{pedido}'

-- Ver todos los tipos de condicion del procedimiento con descripcion
SELECT P.STUNR, P.KSCHL, T.VTEXT
FROM T683S P
INNER JOIN T685T T ON P.KSCHL = T.KSCHL AND T.SPRAS = 'S' AND T.KAPPL = P.KAPPL
WHERE P.KALSM = '{esquema}' AND P.KVEWE = 'A'
ORDER BY P.STUNR
```

---

## Errores de Disponibilidad (ATP)

---

### ERROR 23 — "Confirmed quantity is zero / ATP check failed"
**Mensaje:** Cantidad confirmada es cero — sin stock disponible (V1 801)

**Causa:** El ATP (Available to Promise) no encontro stock suficiente para la fecha de entrega requerida.

**Diagnostico MCP:**
```sql
-- Ver resultado de la verificacion de disponibilidad en el reparto
SELECT VBELN, POSNR, ETENR, EDATU, WMENG, BMENG, LMENG
FROM VBEP WHERE VBELN = '{pedido}' AND BMENG = 0

-- Ver configuracion de verificacion de disponibilidad del material
SELECT MATNR, WERKS, MTVFP, ATPKZ, DISMM
FROM MARC WHERE MATNR = '{material}' AND WERKS = '{planta}'
-- MTVFP: tipo de verificacion de disponibilidad, ATPKZ: indicador ATP

-- Ver stock actual y proyectado (tabla MD04 equivalente en DB)
SELECT MATNR, WERKS, LGORT, LABST FROM MARD
WHERE MATNR = '{material}' AND WERKS = '{planta}'

-- Ver ordenes abiertas que consumen stock
SELECT VBELN, POSNR, MATNR, WERKS, WMENG, BMENG
FROM VBEP
WHERE MATNR = '{material}' AND WERKS = '{planta}'
  AND WMENG > LMENG AND EDATU >= '{hoy}'
ORDER BY EDATU
```

**Solucion:** Verificar stock en MMBE, usar MD04 para ver el cuadro de disponibilidad completo. Considerar cambiar fecha de entrega o modificar la clase de verificacion ATP.

---

### ERROR 24 — "Plant not determined for item"
**Mensaje:** No se pudo determinar la planta para la posicion (VB 136 / V1 039)

**Causa:** No existe determinacion de planta para el cliente/material. La planta no esta en los datos maestros del cliente o en el material.

**Diagnostico MCP:**
```sql
-- Ver planta en datos de cliente para la org de ventas
SELECT KUNNR, VKORG, VTWEG, SPART, VSTEL, LGORT
FROM KNVV WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Ver planta por defecto en datos de material
SELECT MATNR, WERKS, PLIFZ, MMSTA FROM MARC WHERE MATNR = '{material}'

-- Ver asignacion de planta a org de ventas
SELECT VKORG, WERKS FROM TVKWZ WHERE VKORG = '{org}'

-- Ver si el material existe en esa planta
SELECT MATNR, WERKS, MMSTA FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{planta}'
```

---

## Errores en Datos Maestros

---

### ERROR 25 — "Customer not found in sales area"
**Mensaje:** El cliente no esta extendido para el area de ventas (V1 010)

**Causa:** El cliente existe en KNA1 pero no tiene la extension de ventas en KNVV para la combinacion de org. ventas + canal + sector.

**Diagnostico MCP:**
```sql
-- Verificar datos generales del cliente
SELECT KUNNR, NAME1, LAND1, ORT01, KTOKD FROM KNA1 WHERE KUNNR = '{cliente}'

-- Ver en que areas de ventas esta extendido el cliente
SELECT KUNNR, VKORG, VTWEG, SPART, KDGRP, BZIRK, KZAZU
FROM KNVV WHERE KUNNR = '{cliente}'
ORDER BY VKORG, VTWEG, SPART

-- Ver clases de cuenta de cliente disponibles
SELECT KTOKD, TXT30 FROM TSAD3 WHERE SPRAS = 'S'
```

**Solucion:** Extender el cliente al area de ventas con XD01 (ventas) o VD01 solo datos de ventas, completando los datos obligatorios.

---

### ERROR 26 — "Material status restricts order / Material blocked for sales"
**Mensaje:** El material tiene un status que impide la venta (VL 222 / V1 307)

**Causa:** El campo MMSTA (status general del material) o los campos de status en la vista de ventas impiden la creacion del pedido.

**Diagnostico MCP:**
```sql
-- Ver status del material a nivel general
SELECT MATNR, MMSTA, MMSTD, MSTAV, MSTDE FROM MARA
WHERE MATNR = '{material}'

-- Ver status del material en la planta
SELECT MATNR, WERKS, MMSTA, MMSTD FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{planta}'

-- Ver status de la vista de ventas
SELECT MATNR, VKORG, VTWEG, VMSTA, VMSTD FROM MVKE
WHERE MATNR = '{material}' AND VKORG = '{org}'

-- Ver que movimientos bloquea cada status
SELECT MMSTA, AKTION, TEXT1 FROM T141T
WHERE MMSTA = '{status}' AND SPRAS = 'S'
```

**Solucion:** Cambiar el status del material en MM02 si el bloqueo no es intencional, o usar el material correcto.

---

## Errores en Customizing / Configuracion

---

### ERROR 27 — "Copy control: data could not be copied"
**Mensaje:** Los datos no se pudieron copiar al documento destino (V2 203)

**Causa:** El customizing de copy control (VTLA, VTLL, VTFF segun el flujo) tiene una rutina de copia que rechaza los datos o falta la entrada para el par de tipos de documento origen-destino.

**Diagnostico MCP:**
```sql
-- Ver copy control de pedido a entrega (VTLA)
SELECT VBTYP_V, VBTYP_N, AUART, LFART, POSNN, DATFQ, VBKLA
FROM VTLA
WHERE AUART = '{tipo_pedido}' AND LFART = '{tipo_entrega}'

-- Ver copy control de entrega a factura (VTFL)
SELECT VBTYP_V, VBTYP_N, LFART, FKART, FKDAT, REKRI, VBKLN
FROM VTFL
WHERE LFART = '{tipo_entrega}' AND FKART = '{tipo_factura}'

-- Ver copy control de pedido a factura directa (VTFA)
SELECT VBTYP_V, AUART, FKART, VBKLA
FROM VTFA
WHERE AUART = '{tipo_pedido}' AND FKART = '{tipo_factura}'

-- Ver rutinas de copia configuradas
SELECT DDTEXT FROM TFTIT
WHERE FUNCNAME LIKE 'RV_COPY%' AND SPRAS = 'S'
```

---

### ERROR 28 — "Number range not defined for document type"
**Mensaje:** El rango de numeracion no esta definido para el tipo de documento (VN 001)

**Causa:** El tipo de pedido/entrega/factura tiene asignado un rango de numeracion que no existe o no tiene numeros disponibles.

**Diagnostico MCP:**
```sql
-- Ver rango de numeracion asignado al tipo de pedido
SELECT AUART, NUMKI FROM TVAK WHERE AUART = '{tipo_doc}'

-- Ver el objeto de rango de numeracion para pedidos de venta
-- Objeto: VERK_BELEG para pedidos, LIKP para entregas, VBRK para facturas
SELECT NRIV_OBJECT, NRIV_NRRANGES
FROM NRIV WHERE OBJECT = 'SD_VBELN' AND NRRANGENR = '{rango}'

-- Ver numeros disponibles en el rango
SELECT OBJECT, NRRANGENR, FROMNUMBER, TONUMBER, NRLEVEL, PERCENTAGE
FROM NRIV WHERE OBJECT = 'SD_VBELN' AND NRRANGENR = '{rango}'
```

**Solucion:** Verificar en SNRO o VN01 que el rango de numeracion tenga numeros disponibles y este asignado correctamente.

---

## Referencia Rapida — Tablas de Diagnostico SD

| Tabla | Contenido | Query tipico |
|-------|-----------|--------------|
| VBAK | Cabecera de pedido de venta | WHERE VBELN = '{pedido}' |
| VBAP | Posiciones de pedido de venta | WHERE VBELN = '{pedido}' ORDER BY POSNR |
| VBEP | Repartos del pedido | WHERE VBELN = '{pedido}' ORDER BY POSNR, ETENR |
| VBPA | Socios del documento de venta | WHERE VBELN = '{pedido}' |
| VBFA | Flujo de documentos | WHERE VBELV = '{doc}' OR VBELN = '{doc}' |
| LIKP | Cabecera de entrega | WHERE VBELN = '{entrega}' |
| LIPS | Posiciones de entrega | WHERE VBELN = '{entrega}' ORDER BY POSNR |
| VBRK | Cabecera de factura | WHERE VBELN = '{factura}' |
| VBRP | Posiciones de factura | WHERE VBELN = '{factura}' ORDER BY POSNR |
| KONV | Condiciones de precio del doc | WHERE KNUMV = '{num_cond}' |
| KNVV | Datos de ventas del cliente | WHERE KUNNR = '{cte}' AND VKORG = '{org}' |
| MVKE | Datos de ventas del material | WHERE MATNR = '{mat}' AND VKORG = '{org}' |
| MARD | Stock por almacen/ubicacion | WHERE MATNR = '{mat}' AND WERKS = '{planta}' |
| KNKK | Datos de credito del cliente | WHERE KUNNR = '{cte}' AND KKBER = '{area}' |
| NAST | Registro de mensajes/output | WHERE KAPPL = 'V1' AND OBJKY = '{pedido}' |
| T184 | Determinacion categoria posicion | WHERE PSTYV_V = '{doc}' AND MTPOS = '{grp}' |
| T683V | Determinacion esquema de precios | WHERE VKORG = '{org}' AND VTWEG = '{canal}' |
| VKOA | Determinacion de cuentas | WHERE KTOPL = '{plan}' AND VKORG = '{org}' |
| TVSBT | Determinacion punto expedicion | WHERE VSBED = '{cond}' AND WERKS = '{planta}' |
| VBUV | Log de incompletitud | WHERE VBELN = '{pedido}' |
