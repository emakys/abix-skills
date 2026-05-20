# Partner Determination (Determinacion de Interlocutores)

## Concepto

Cada documento de ventas necesita identificar QUIEN participa en la transaccion.
SAP determina automaticamente los partners basado en el maestro del cliente.

## Partner Functions estandar

| Funcion | Codigo | Descripcion | Obligatorio |
|---------|--------|-------------|:-----------:|
| Sold-to party | SP (AG) | Quien compra (contrato) | Si |
| Ship-to party | SH (WE) | Donde se entrega | Si |
| Bill-to party | BP (RE) | A quien se factura | Si |
| Payer | PY (RG) | Quien paga | Si |
| Contact person | CP (AP) | Persona de contacto | No |
| Sales employee | PE (VE) | Vendedor responsable | No |
| Forward agent | CA (SP) | Transportista | No |

## Procedimiento de determinacion

```
Config: SPRO → SD → Basic Functions → Partner Determination →
  Set Up Partner Determination

Pasos:
  1. Definir Partner Functions (VOPA)
  2. Definir Partner Determination Procedure
  3. Asignar funciones al procedimiento
  4. Asignar procedimiento a:
     - Account group del cliente (para maestro)
     - Tipo documento de venta (para pedido)
     - Tipo entrega (para entrega)
     - Tipo factura (para factura)
```

### Niveles de partner determination
| Nivel | Tabla | Procedimiento para |
|-------|-------|-------------------|
| Customer master | KNVP | Datos maestros del cliente |
| Sales document header | VBPA | Cabecera pedido venta |
| Sales document item | VBPA | Posicion pedido venta |
| Delivery | VBPA | Entrega |
| Billing | VBPA | Factura |

### Tabla KNVP — Partners en maestro cliente
| Campo | Descripcion |
|-------|-------------|
| KUNNR | Cliente principal (sold-to) |
| VKORG | Org ventas |
| VTWEG | Canal |
| SPART | Sector |
| PARVW | Funcion partner (AG, WE, RE, RG) |
| KUNN2 | Numero del partner (otro cliente) |
| DEFPA | Default (X = usar como default) |

### Tabla VBPA — Partners en documentos
| Campo | Descripcion |
|-------|-------------|
| VBELN | Numero documento |
| POSNR | Posicion (0000 = header) |
| PARVW | Funcion partner |
| KUNNR | Numero cliente partner |
| ADRNR | Numero de direccion |

## Ejemplo tipico

```
Cliente 1000 (Corporativo ABC):
  AG (sold-to):  1000 — Corporativo ABC (el que compra)
  WE (ship-to):  1001 — Sucursal Norte (donde se entrega)
                 1002 — Sucursal Sur
  RE (bill-to):  1003 — Depto Finanzas (a quien se factura)
  RG (payer):    1000 — Corporativo ABC (quien paga)

Al crear pedido VA01 con sold-to 1000:
  SAP auto-determina:
    AG = 1000 (sold-to, siempre el cliente del pedido)
    WE = 1001 (ship-to default, DEFPA='X')
    RE = 1003 (bill-to)
    RG = 1000 (payer)

  Usuario puede cambiar WE a 1002 (otra sucursal) en el pedido
```

## Partner Functions custom

```
VOPA → crear funcion custom:
  Codigo: ZV (Verificador)
  Tipo: KU (cliente) / PE (personal) / AP (contacto)
  Descripcion: "Verificador de calidad"

Asignar al procedimiento de determinacion
Asignar al tipo de documento de venta (VOPA)

En el pedido aparece como tab "Partners" → funcion ZV
```

## Queries MCP

```sql
-- Partners del cliente en maestro
SELECT KUNNR, VKORG, VTWEG, SPART, PARVW, KUNN2, DEFPA
FROM KNVP WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Partners de un pedido
SELECT VBELN, POSNR, PARVW, KUNNR, ADRNR
FROM VBPA WHERE VBELN = '{pedido}'

-- Clientes que son ship-to de otro
SELECT KNVP.KUNNR as SOLDTO, KNVP.KUNN2 as SHIPTO, KNA1.NAME1
FROM KNVP JOIN KNA1 ON KNVP.KUNN2 = KNA1.KUNNR
WHERE KNVP.PARVW = 'WE' AND KNVP.VKORG = '{org}'

-- Verificar si un cliente tiene partners configurados
SELECT PARVW, COUNT(*) as NUM FROM KNVP
WHERE KUNNR = '{cliente}' AND VKORG = '{org}'
GROUP BY PARVW
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| "Partner function SP mandatory" | Falta sold-to | Siempre obligatorio |
| "No ship-to determined" | KNVP sin WE para el cliente | VD02/BP agregar ship-to |
| "Bill-to not maintained" | KNVP sin RE | VD02/BP agregar bill-to |
| "Payer has no FI data" | Payer sin extension sociedad (KNB1) | XD01/BP extender |
| Partner block | Cliente partner tiene bloqueo | Quitar AUFSD/LIFSD |
