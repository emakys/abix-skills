# Determinacion de Textos y Gestion de Output SD

Referencia completa para la configuracion y uso de textos en documentos SD y el sistema de output management (NACE). Incluye queries MCP para analisis y troubleshooting.

---

## Parte 1: Text Determination (Determinacion de Textos)

### Concepto General

Los textos en documentos SD permiten agregar informacion adicional (notas, instrucciones, condiciones comerciales) que se imprimen en formularios, se transfieren a otros documentos o se usan internamente. La determinacion de textos controla de donde se copian estos textos y en que orden se buscan las fuentes.

Los textos se almacenan en las tablas STXH (header) y STXL (lines) del modulo de texto de SAP (SO10/STXEDIT).

### Objetos de Texto SD

Los objetos de texto agrupan los textos por tipo de documento:

| Objeto | Nivel | Documento | Descripcion |
|--------|-------|-----------|-------------|
| VBBK | Header | Pedido de venta | Sales order header texts |
| VBBP | Item | Pedido de venta | Sales order item texts |
| VBLK | Header | Entrega | Delivery header texts |
| VBLP | Item | Entrega | Delivery item texts |
| VBFK | Header | Factura | Billing document header texts |
| VBFP | Item | Factura | Billing document item texts |
| KVAK | Header | Oferta | Quotation header texts |
| KVAP | Item | Oferta | Quotation item texts |
| KNA1T | - | Maestro cliente | Customer master texts |
| MVKE | - | Maestro material | Material sales texts |

### Text IDs Tipicos SD

Cada objeto de texto tiene definidos sus text IDs (que tipo de texto es):

| Text ID | Descripcion | Objeto tipico |
|---------|-------------|---------------|
| 0001 | Material note / Nota de material | VBBP, VBLP |
| 0002 | Internal note / Nota interna | VBBK, VBBP |
| 0003 | Order note / Nota de pedido | VBBK |
| 0004 | Delivery note text / Instrucciones entrega | VBLK |
| 0005 | Invoice note / Nota de factura | VBFK |
| 0006 | Packing instruction / Instrucciones embalaje | VBLP |
| Z001 | Custom text 1 | Segun config |
| Zxxx | Custom texts | Segun necesidad |

### Procedimiento de Determinacion de Textos — Configuracion (VOTXN)

#### Ruta SPRO
SPRO → Sales and Distribution → Basic Functions → Text Control → Define Text Determination Procedures

#### Transaccion directa
VOTXN

#### Paso a paso

**Paso 1 — Definir Text IDs**
VOTXN → seleccionar objeto (p.ej. VBBK) → Text IDs → New Entries
- Text ID: codigo de 4 chars (0001, 0002, Z001)
- Description: nombre del texto
- Text object: vinculado a objeto padre

**Paso 2 — Crear Access Sequence para textos**
VOTXN → Access Sequences → New Entries
La secuencia de acceso define de donde copiar el texto (en orden de prioridad):
| Acceso | Fuente | Descripcion |
|--------|--------|-------------|
| 1 | Documento precedente | Copiar desde pedido anterior |
| 2 | Maestro de cliente | KNA1T / KNVVT (texto de cliente) |
| 3 | Maestro de material | MVKET (texto de material de ventas) |
| 4 | Texto estandar SO10 | Texto general del sistema |

Rutinas de acceso (ABAP):
- Rutina 1: desde documento precedente
- Rutina 2: desde maestro de material
- Rutina 3: desde maestro de cliente

**Paso 3 — Crear Procedimiento de Determinacion de Textos**
VOTXN → Text Determination Procedures → New Entries
- Codigo: A (header), B (item), o custom Z
- Asignar objeto

**Paso 4 — Asignar Text IDs al Procedimiento**
VOTXN → seleccionar procedimiento → Text IDs in Text Determination Procedure
| Campo | Descripcion | Valor |
|-------|-------------|-------|
| Text ID | ID del texto | 0001 |
| Access sequence | Como determinar fuente | ZA01 |
| Mandatory | Obligatorio completar | Segun necesidad |
| Dublication | Permitir duplicar | X si necesario |
| Reference text | Texto por referencia (link) | X si no copiar sino referenciar |

**Paso 5 — Asignar Procedimiento al Tipo de Documento**
Para pedidos de venta: VOV8 → campo "Text determination procedure" (header y item separados)
Para entregas: SPRO → LE → Shipping → ... → Text Control
Para facturas: SPRO → SD → Billing → ... → Text Control

### Copia de Textos entre Documentos (Copy Control)

La copia de textos entre etapas del proceso (pedido → entrega → factura) se configura en el copy control:

**SPRO → SD → Sales → Maintain Copy Control for Sales Documents (VTAA, VTAF, VTLA, VTFA, VTFL)**

En el copy control a nivel de header e item existe el campo "Copy texts" o "Text copying rules":
| Valor | Comportamiento |
|-------|---------------|
| A | Copiar textos del documento origen |
| B | Referenciar textos (link, no duplicar) |
| Vacio | No copiar textos |

Flujo tipico de textos:
```
Maestro cliente (KNA1T)
       ↓
Oferta (KVAK/KVAP)
       ↓ copy control
Pedido venta (VBBK/VBBP)
       ↓ copy control
Entrega (VBLK/VBLP)
       ↓ copy control
Factura (VBFK/VBFP)
```

### Configuracion de Textos de Maestros

**Textos en maestro de cliente (KNA1T):**
XD02 → Extras → Texts
- Los textos se almacenan con objeto KNA1T y text ID configurado

**Textos en maestro de material (MAKT, MVKET):**
MM02 → Sales text (tab)
- El texto de ventas se copia al pedido segun access sequence

**Textos estandar (SO10):**
SO10: mantener textos estandar reutilizables
- Se puede referenciar en access sequence de textos

---

## Parte 2: Output Management (NACE)

### Concepto General

El output management SD controla la emision de formularios y documentos (confirmaciones de pedido, albaranes, facturas, etc.) a clientes, proveedores y otros socios. Determina automaticamente que output generar, en que medio (print, email, EDI) y cuando.

### Application Areas SD

| App | Descripcion | Documentos |
|-----|-------------|-----------|
| V1 | Sales | Pedidos (VA01), Ofertas (VA21), Contratos (VA41) |
| V2 | Shipping | Entregas (VL01N), listas de picking |
| V3 | Billing | Facturas (VF01), Notas credito, Pro-formas |
| V4 | Handling Units | Documentos de unidades de manejo |

### Output Types Principales SD

| Output | App | Descripcion | Medium tipico | Funcion socio |
|--------|-----|-------------|---------------|---------------|
| BA00 | V1 | Order confirmation / Confirmacion pedido | 1 Print, 5 Email | SP (Sold-to) |
| BA01 | V1 | Order acknowledgement | 1 Print | SP |
| AN00 | V1 | Quotation / Oferta | 1 Print, 5 Email | SP |
| KO00 | V1 | Contract / Contrato | 1 Print | SP |
| LD00 | V2 | Delivery note / Albaran | 1 Print | SH (Ship-to) |
| PL00 | V2 | Picking list / Lista picking | 1 Print | - |
| WA00 | V2 | Goods issue slip / Salida mercancías | 1 Print | - |
| GP00 | V2 | Dangerous goods notice | 1 Print | - |
| RD00 | V3 | Invoice / Factura | 1 Print, 5 Email, 6 EDI | BP (Bill-to) |
| RD03 | V3 | Pro-forma invoice | 1 Print | SP |
| RD04 | V3 | Credit memo / Nota credito | 1 Print, 5 Email | BP |
| RD05 | V3 | Debit memo / Nota debito | 1 Print, 5 Email | BP |

### Medios de Transmision (Medium)

| Codigo | Medium | Descripcion | Configuracion |
|--------|--------|-------------|---------------|
| 1 | Print | Spool SAP | Impresora en SP01 |
| 2 | Fax | Fax via SAPconnect | SCOT configurado |
| 3 | Telex | Telex (obsoleto) | - |
| 4 | ABAP program | Programa custom | Solo en backend |
| 5 | Email | Email via SAPconnect | SCOT + SMTP |
| 6 | EDI | Electronic Data Interchange | ALE/IDOCs configurado |
| 7 | Simple mail | SAP office mail interno | Usuarios SAP |
| 8 | Special function | Funcion especial | Exit custom |

### Timing de Procesamiento

| Codigo | Timing | Descripcion |
|--------|--------|-------------|
| 1 | Send immediately | Al guardar el documento (sincrono) |
| 2 | Send on request | Solo cuando usuario ejecuta manualmente |
| 3 | Send externally | Para EDI, procesamiento externo |
| 4 | Send via job | Procesamiento batch periodico (recomendado para produccion) |

### Processing Routines por Tipo de Formulario

**SAPscript (clasico, obsoleto en S/4HANA):**
| Output | Program | Form |
|--------|---------|------|
| BA00 | RVADOR01 | RVORDER01 |
| LD00 | RVSEND01 | RVDELNOTE |
| RD00 | RVADIN01 | RVDELNOTE |

**SmartForms:**
| Output | Program | SmartForm name |
|--------|---------|---------------|
| RD00 | RD_PRINT_FISC_DOC | LB_BIL_INVOICE |
| LD00 | - | WS_DELIVERY_NOTE_01 |

**Adobe Forms (ADS — recomendado S/4HANA):**
- Program: programa Z que llama FP_JOB_OPEN y FP_FUNCTION_MODULE_NAME
- Form name: nombre del formulario Adobe
- Requiere Adobe Document Services (ADS) configurado

**Custom SmartForms:**
```abap
PROGRAM: Z_SD_OUTPUT_PROGRAM
FORM: Z_SD_INVOICE_SMARTFORM

" En el programa, la rutina principal llama:
CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
  EXPORTING
    formname = 'Z_SD_INVOICE_SMARTFORM'
  IMPORTING
    fm_name  = lv_fm_name.
```

### Condition Records para Output

Los condition records determinan que output se genera para que combinacion de datos.

| Transaccion | App | Accion |
|-------------|-----|--------|
| VV11 | V1 | Crear condition record output de ventas |
| VV12 | V1 | Modificar condition record output ventas |
| VV13 | V1 | Mostrar condition record output ventas |
| VV21 | V2 | Crear condition record output entregas |
| VV22 | V2 | Modificar |
| VV23 | V2 | Mostrar |
| VV31 | V3 | Crear condition record output facturas |
| VV32 | V3 | Modificar |
| VV33 | V3 | Mostrar |

Ejemplo de condition record para BA00:
- Key: Sales org 1000 + Sales doc type ZOR
- Output: BA00, Medium: 5 (Email), Timing: 4 (batch job)
- Partner function: SP

### Reprocesamiento de Outputs

| Transaccion | Descripcion | Cuando usar |
|-------------|-------------|-------------|
| VA02 | Modificar pedido → outputs en header/item | Agregar/reprocesar output individual |
| VL02N | Modificar entrega → outputs | Reprocesar albaran |
| VF02 | Modificar factura → outputs | Reprocesar factura |
| VL71 | Output re-processing: deliveries | Reprocesar masivo entregas |
| VF31 | Output re-processing: billing | Reprocesar masivo facturas |
| VD71 | Re-processing sales outputs | Reprocesar masivo ventas |
| NAST | Ver tabla de outputs | Consulta directa DB |
| SP01 | Spool management | Ver cola de impresion |

### Tabla NAST — Status de Output

NAST es la tabla central donde SAP registra cada output y su estado de procesamiento.

| Campo | Tipo | Descripcion | Valores |
|-------|------|-------------|---------|
| MANDT | CLNT | Mandante | - |
| KAPPL | CHAR(2) | Aplicacion | V1, V2, V3, V4 |
| OBJKY | CHAR(30) | Object key (numero documento) | Ej: 0000012345 |
| KSCHL | CHAR(4) | Output type | BA00, LD00, RD00 |
| SPRAS | LANG | Idioma | E, D, S |
| PARNR | CHAR(10) | Numero socio | Numero cliente |
| PARVW | CHAR(2) | Funcion socio | SP, SH, BP |
| NACHA | CHAR(1) | Medium | 1, 2, 5, 6 |
| VSTAT | CHAR(1) | Processing status | 0=Pendiente, 1=OK, 2=Error |
| LDANZ | INT4 | Numero de intentos | - |
| ERDAT | DATS | Fecha creacion | - |
| ERUHR | TIMS | Hora creacion | - |
| USNAM | CHAR(12) | Usuario | - |
| NAST_AENDE | CHAR(1) | Modificado | X |
| PRDAT | DATS | Fecha procesamiento | - |
| PRUHR | TIMS | Hora procesamiento | - |

### S/4HANA Output Management 2.0

A partir de S/4HANA 1709, SAP introdujo el nuevo Output Management basado en BRF+ (Business Rules Framework+):

**Diferencias clave vs NACE clasico:**
| Aspecto | NACE clasico | Output Management 2.0 |
|---------|-------------|----------------------|
| Configuracion | IMG + condition records | Fiori Apps + BRF+ |
| Templates | SAPscript/SmartForms | Adobe Forms + HTML email |
| Reglas | Condition tables | BRF+ decision tables |
| Email | Via SAPconnect | Via BCS (Business Communication Services) |
| Monitoreo | SP01 + NAST | App "Manage Output" |
| API | N/A | Output Control API |

**Fiori Apps para Output Management 2.0:**
- Manage Output (F2390): configurar y reprocesar outputs
- Configure Output Channel (F2391): definir canales de salida
- Output Parameter Determination (F2392): configurar reglas BRF+

**Activacion en S/4HANA:**
- Business Function: SD_OUTPUT_MANAGEMENT_01
- Requiere configuracion adicional en SPRO → Cross-Application Components → Output Management

### IDOCs para SD (Intercambio Electronico)

Los IDOCs son el mecanismo estandar para EDI en SAP. En SD se usan para intercambio con socios comerciales.

| IDOC type | Descripcion | Direccion | Output type |
|-----------|-------------|-----------|-------------|
| ORDERS05 | Purchase order / Sales order | Inbound (recepcion) | - |
| ORDRSP | Order response / Confirmacion | Outbound (envio) | BA00 con medium 6 |
| DESADV | Despatch advice / Aviso expedicion | Outbound | LD00 con medium 6 |
| RECADV | Receiving advice / Acuse recepcion | Inbound | - |
| INVOIC02 | Invoice / Factura | Outbound | RD00 con medium 6 |
| REMADV | Remittance advice / Aviso pago | Inbound | - |
| SHPMNT05 | Shipment document | Outbound | - |
| ORDERS01 | Simplified orders | Outbound/Inbound | - |

**Configuracion EDI basica:**
1. WE20: definir partner profile (EDI partner)
2. WE30: verificar IDOC types
3. BD64: distribucion modelo (si usa ALE)
4. WE19: test y simulacion de IDOCs
5. WE05/WE07: monitor IDOCs

---

## Parte 3: Queries MCP para Text y Output Management

### Queries para Output (NAST)

```sql
-- Status de output de un documento especifico
SELECT KAPPL, OBJKY, KSCHL, SPRAS, PARNR, PARVW, NACHA, VSTAT, ERDAT, PRDAT
FROM NAST
WHERE OBJKY = '{numero_documento}'

-- Outputs pendientes de procesamiento (backlog)
SELECT KAPPL, OBJKY, KSCHL, VSTAT, ERDAT, PRUHR
FROM NAST
WHERE VSTAT = '0'
  AND KAPPL IN ('V1', 'V2', 'V3')
ORDER BY ERDAT

-- Outputs con error para analisis
SELECT KAPPL, OBJKY, KSCHL, VSTAT, LDANZ, ERDAT
FROM NAST
WHERE VSTAT = '2'
  AND KAPPL IN ('V1', 'V2', 'V3')
  AND ERDAT = '{fecha_YYYYMMDD}'

-- Outputs de facturas del dia (para verificar envio)
SELECT N.OBJKY, N.KSCHL, N.NACHA, N.VSTAT, N.PARNR, N.ERDAT
FROM NAST N
WHERE N.KAPPL = 'V3'
  AND N.KSCHL = 'RD00'
  AND N.ERDAT = '{fecha_YYYYMMDD}'

-- Volumen de outputs por tipo en el mes
SELECT KAPPL, KSCHL, NACHA, VSTAT, COUNT(*) AS CANTIDAD
FROM NAST
WHERE ERDAT BETWEEN '{fecha_inicio}' AND '{fecha_fin}'
  AND KAPPL IN ('V1', 'V2', 'V3')
GROUP BY KAPPL, KSCHL, NACHA, VSTAT
ORDER BY KAPPL, KSCHL

-- Outputs de un cliente especifico
SELECT N.KAPPL, N.OBJKY, N.KSCHL, N.NACHA, N.VSTAT, N.PARNR
FROM NAST N
WHERE N.PARNR = '{numero_cliente}'
  AND N.KAPPL IN ('V1', 'V2', 'V3')
ORDER BY N.ERDAT DESC

-- Verificar output email (medium 5) para facturas
SELECT N.OBJKY, N.PARNR, N.NACHA, N.VSTAT, N.ERDAT
FROM NAST N
WHERE N.KAPPL = 'V3'
  AND N.NACHA = '5'
  AND N.VSTAT <> '1'
  AND N.ERDAT >= '{fecha_YYYYMMDD}'
```

### Queries para Textos de Documentos (STXH/STXL)

```sql
-- Textos de un pedido de venta especifico (header)
SELECT TDOBJECT, TDNAME, TDID, TDSPRAS, TDTITLE
FROM STXH
WHERE TDOBJECT = 'VBBK'
  AND TDNAME LIKE '{numero_pedido}%'

-- Textos de posicion de pedido
SELECT TDOBJECT, TDNAME, TDID, TDSPRAS
FROM STXH
WHERE TDOBJECT = 'VBBP'
  AND TDNAME LIKE '{numero_pedido}%'

-- Textos de factura
SELECT TDOBJECT, TDNAME, TDID, TDSPRAS
FROM STXH
WHERE TDOBJECT = 'VBFK'
  AND TDNAME LIKE '{numero_factura}%'

-- Verificar si existe texto especifico en documento
SELECT COUNT(*) AS EXISTE
FROM STXH
WHERE TDOBJECT = 'VBBK'
  AND TDNAME = '{numero_pedido}'
  AND TDID = '0001'
  AND TDSPRAS = 'S'

-- Textos en maestro de cliente
SELECT TDOBJECT, TDNAME, TDID, TDSPRAS
FROM STXH
WHERE TDOBJECT = 'KNA1T'
  AND TDNAME LIKE '{numero_cliente}%'

-- Contenido de un texto (lineas)
SELECT TDFORMAT, TDLINE
FROM STXL
WHERE RELID = 'TX'
  AND TDOBJECT = 'VBBK'
  AND TDNAME = '{numero_pedido}'
  AND TDID = '0001'
  AND TDSPRAS = 'S'
ORDER BY TDSEQ
```

### Queries para Condition Records de Output (NACH tables)

```sql
-- Ver condition records de output para ventas (tabla NACH)
SELECT KAPPL, KSCHL, KOTABNR, VAKEY, NACHA, VSZTP, SPRAS
FROM NACH
WHERE KAPPL = 'V1'
  AND KSCHL = 'BA00'

-- Ver access sequence de output type
SELECT KAPPL, KSCHL, NAUPA
FROM TNAV
WHERE KAPPL = 'V1'

-- Condition record output para tipo de documento de venta
SELECT *
FROM KONH
WHERE KAPPL = 'V1'
  AND KSCHL = 'BA00'
  AND DATBI >= SY-DATUM

-- Ver procedimientos de determinacion de textos
SELECT TXPRO, SPRAS, BZREP
FROM TTXPO INNER JOIN TTXPOT ON TTXPO.TXPRO = TTXPOT.TXPRO
WHERE TTXPOT.SPRAS = 'S'

-- Ver text IDs configurados por objeto
SELECT TDOBJECT, TDID, SPRAS, DDTEXT
FROM TTXIDT
WHERE TDOBJECT = 'VBBK'
  AND SPRAS = 'S'
```

### Queries para IDOCs (Monitoreo EDI)

```sql
-- IDOCs de salida pendientes (status 30 = listo para enviar)
SELECT DOCNUM, DIRECT, IDOCTP, MESTYP, STDMES, SNDPRT, SNDPRN, RCVPRT, RCVPRN, STATUS, CREDAT
FROM EDIDC
WHERE DIRECT = '2'
  AND STATUS = '30'
ORDER BY CREDAT DESC

-- IDOCs con error de envio
SELECT DOCNUM, DIRECT, IDOCTP, MESTYP, STATUS, CREDAT, UPDDAT
FROM EDIDC
WHERE STATUS IN ('02', '04', '26')
  AND CREDAT >= '{fecha_YYYYMMDD}'

-- IDOCs de facturas enviados exitosamente
SELECT DOCNUM, DIRECT, IDOCTP, MESTYP, RCVPRN, STATUS, CREDAT
FROM EDIDC
WHERE IDOCTP = 'INVOIC02'
  AND DIRECT = '2'
  AND STATUS = '03'
  AND CREDAT = '{fecha_YYYYMMDD}'

-- Status codes IDOC relevantes
-- 01 = IDOC generado
-- 02 = Error enviando IDOC
-- 03 = IDOC enviado correctamente
-- 04 = Error en control del IDOC
-- 12 = IDOC recibido correctamente (inbound)
-- 30 = IDOC listo para transferencia
-- 51 = Error procesando IDOC inbound

-- Mensajes de error de un IDOC
SELECT LOGNO, LOGMSGNO, MSGTY, MSGID, MSGNO, MSGV1, MSGV2
FROM EDIDS
WHERE DOCNUM = '{numero_idoc}'
  AND LOGNO = ( SELECT MAX(LOGNO) FROM EDIDS WHERE DOCNUM = '{numero_idoc}' )
ORDER BY LOGMSGNO
```

---

## Parte 4: Troubleshooting

### Problemas Comunes de Output

**Problema: Output no se genera automaticamente**
Posibles causas y verificacion:
1. No hay condition record → VV13/VV23/VV33: verificar si existe registro valido
2. Output procedure no asignado → VOV8/tipo entrega/tipo factura: verificar procedimiento
3. Timing = 2 (manual) → el usuario debe disparar manualmente desde el documento
4. Partner no determinado → revisar partner determination procedure (VOPA)
5. Texto NAST ya existe con status 1 → el output ya se proceso antes

**Problema: Output con error (VSTAT=2)**
1. VF02 → Extras → Output → seleccionar → Log: ver mensaje de error detallado
2. SP01: si medium=1, ver si hay error en spool
3. SCOT: si medium=5, verificar configuracion SMTP y colas de envio
4. SM58: ver errores en transactional RFC (para IDOCs)

**Problema: Email no se envia (medium=5)**
1. SCOT → Work Area Settings → verificar servidor SMTP configurado
2. SOST: ver cola de envio SAPconnect
3. SO50: ver configuracion de reglas SAPconnect
4. Verificar direccion email en maestro de cliente (KNA1T / VD02 → Communication)
5. Autorización: usuario que ejecuta el job debe tener S_OC_SEND

**Problema: Texto no se copia al siguiente documento**
1. Verificar copy control (VTAA, VTFA, VTFL, VTLA): campo "Text" debe estar configurado
2. Verificar access sequence en text determination procedure (VOTXN)
3. Verificar que el texto existe en el documento origen (transaccion VA02/VL02N → Extras → Texts)

### Tablas de Referencia

| Tabla | Descripcion |
|-------|-------------|
| NAST | Output message status per document |
| STXH | Text header (metadata) |
| STXL | Text lines (content) |
| NACH | Output condition records header |
| KONH | General condition record header |
| KONP | General condition record item |
| TNAV | Output types definition |
| TNAPR | Output processing routines |
| EDIDC | IDOC control record |
| EDIDS | IDOC status records |
| EDID4 | IDOC data records |
| TTXPO | Text determination procedures |
| TTXID | Text ID definition |

### Transacciones de Diagnostico

| Transaccion | Descripcion |
|-------------|-------------|
| NAST | Ver tabla directamente |
| SCOT | SAPconnect administration |
| SOST | SAPconnect outbox |
| SP01 | Spool monitor |
| WE05 | IDOC monitor (inbound) |
| WE07 | IDOC monitor (outbound) |
| WE19 | IDOC test tool |
| BD87 | IDOC reprocessing |
| SLG1 | Application log (buscar errores output) |
