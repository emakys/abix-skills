# Datos Maestros SD

## Customer Master / Business Partner

### Niveles del cliente
```
Nivel 1: General (mandante) → KNA1 / BUT000
  Nombre, direccion, idioma, pais, industria

Nivel 2: Sociedad (company code) → KNB1
  Cuenta asociada, condiciones pago, dunning

Nivel 3: Area de ventas (sales area) → KNVV
  Org ventas + Canal + Sector
  Condiciones pago, incoterms, grupo precios, moneda, condicion expedicion
```

### ECC vs S/4HANA
| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Transaccion | VD01/XD01 | BP |
| Tabla general | KNA1 | BUT000 (KNA1=compatibility view) |
| Tabla sociedad | KNB1 | Se mantiene via CVI |
| Tabla area ventas | KNVV | Se mantiene via CVI |
| Tabla partners | KNVP | Se mantiene |
| Grupo cuenta | KNA1-KTOKD | BUT000-BU_GROUP |
| CVI | No existe | Sincroniza BP <-> Customer |

### Tabla KNVV — Campos clave (Area de ventas)
| Campo | Descripcion | Impacto |
|-------|-------------|---------|
| BZIRK | Zona de ventas | Asignacion vendedor |
| KDGRP | Grupo de clientes | Pricing, reporting |
| KONDA | Grupo precios del cliente | Condiciones de precio |
| KALKS | Esquema calculo cliente | Pricing |
| WAERS | Moneda | Moneda del pedido |
| ZTERM | Condicion de pago | Vencimiento |
| INCO1/INCO2 | Incoterms | Responsabilidad envio |
| VWERK | Centro suministrador | Default en pedido |
| VSBED | Condicion expedicion | Determina shipping point |
| KZAZU | Order combination | Agrupar pedidos en entrega |
| AUFSD | Bloqueo pedido | Bloquea creacion pedido |
| LIFSD | Bloqueo entrega | Bloquea entrega |
| FAKSD | Bloqueo facturacion | Bloquea factura |
| VKBUR | Oficina ventas | Default |
| VKGRP | Grupo vendedores | Default |
| VERSG | Grupo estadisticas | LIS/Analytics |

### Queries MCP
```sql
-- Cliente completo con area de ventas
SELECT KNA1.KUNNR, KNA1.NAME1, KNA1.LAND1, KNA1.KTOKD,
       KNVV.VKORG, KNVV.VTWEG, KNVV.SPART,
       KNVV.KDGRP, KNVV.KONDA, KNVV.WAERS, KNVV.ZTERM, KNVV.INCO1,
       KNVV.VWERK, KNVV.VSBED, KNVV.AUFSD, KNVV.LIFSD, KNVV.FAKSD
FROM KNA1
JOIN KNVV ON KNA1.KUNNR = KNVV.KUNNR
WHERE KNA1.KUNNR = '{cliente}'

-- Cliente sin area de ventas (error comun)
SELECT KUNNR, NAME1 FROM KNA1
WHERE KUNNR NOT IN (SELECT KUNNR FROM KNVV WHERE VKORG = '{org}' AND VTWEG = '{canal}' AND SPART = '{sector}')

-- Partner functions del cliente
SELECT KUNNR, PARVW, KUNN2, DEFPA FROM KNVP
WHERE KUNNR = '{cliente}' AND VKORG = '{org}'

-- Verificar BP sync (S/4)
SELECT PARTNER, KUNNR FROM CVIS_CUST_LINK WHERE KUNNR = '{cliente}'
```

## Material Master — Vistas de ventas

### Vista Ventas: Org ventas (MVKE)
| Campo | Descripcion | Impacto |
|-------|-------------|---------|
| VKORG | Org ventas | Clave |
| VTWEG | Canal distribucion | Clave |
| KONDM | Grupo material pricing | Condiciones precio |
| KTGRM | Grupo imputacion material | Determinacion cuenta (VKOA) |
| MVGR1-5 | Grupos material 1-5 | Pricing, reporting |
| PRODH | Jerarquia de producto | Pricing, analytics |
| VMSTA | Status distribucion | Bloqueo ventas |
| VSBED | Condicion expedicion | Shipping point determination |

### Vista Ventas: General/Centro
| Campo | Descripcion | Tabla |
|-------|-------------|-------|
| MARA-SPART | Sector del material | Determinacion sector |
| MARA-MTPOS_MARA | Grupo tipo posicion | Item category determination |
| MARA-LADGR | Grupo de carga | Shipping point determination |
| MARC-MVGR1 | Grupo transporte | Route determination |

### Queries MCP
```sql
-- Material con vista ventas
SELECT MARA.MATNR, MAKT.MAKTX, MVKE.VKORG, MVKE.VTWEG,
       MVKE.KONDM, MVKE.KTGRM, MVKE.PRODH, MVKE.VMSTA,
       MARA.MTPOS_MARA, MARA.SPART
FROM MARA
JOIN MAKT ON MARA.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'E'
LEFT JOIN MVKE ON MARA.MATNR = MVKE.MATNR
WHERE MARA.MATNR = '{material}'

-- Materiales sin vista ventas en una org
SELECT MARA.MATNR, MAKT.MAKTX FROM MARA
JOIN MAKT ON MARA.MATNR = MAKT.MATNR AND MAKT.SPRAS = 'E'
WHERE MARA.MTART IN ('FERT','HAWA','DIEN')
AND MARA.MATNR NOT IN (SELECT MATNR FROM MVKE WHERE VKORG = '{org}' AND VTWEG = '{canal}')
```

## Customer-Material Info Record (VD51/VD52/VD53)

```
Asignacion especifica de datos entre un cliente y un material:
  - Numero de material del cliente (referencia cruzada)
  - Descripcion del material segun el cliente
  - Centro suministrador default
  - Tolerancias de entrega

Tabla: KNMT
Config util para: EDI, remisiones con numero del cliente, defaults

Query MCP:
  GetSqlQuery("SELECT KUNNR, VKORG, VTWEG, MATNR, KDMAT, POSTX FROM KNMT WHERE KUNNR='{cl}'")
```

## Customer Hierarchy (VDH1/VDH2)

```
Jerarquia de clientes para pricing:
  Grupo corporativo → Region → Sucursal
  Permite condiciones de precio a nivel jerarquia

Tablas: KNVH (jerarquia), KNVHM (asignacion materiales)
Uso: condiciones de precio con jerarquia de cliente (secuencia acceso)
```
