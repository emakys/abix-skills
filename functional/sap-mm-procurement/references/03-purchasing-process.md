# Proceso de Compras (Purchasing)

## Flujo estandar P2P

```
Necesidad -> Sol.Pedido -> Pedido -> Entrada Merc. -> Factura -> Pago
  (MRP)      (ME51N)      (ME21N)    (MIGO 101)      (MIRO)    (F110)
             EBAN         EKKO/EKPO  MKPF/MSEG       RBKP/RSEG  BSEG
```

## Solicitud de Pedido (Purchase Requisition)

### Transacciones
| TCode | Accion | Notas |
|-------|--------|-------|
| ME51N | Crear | Manual o referencia otra SolPed |
| ME52N | Modificar | Cambiar cantidad, proveedor, datos |
| ME53N | Visualizar | Solo lectura |
| ME54N | Liberar individual | Aprobacion |
| ME55 | Liberar colectiva | Aprobacion masiva |
| ME5A | Lista solicitudes | Reporting |
| ME56 | Asignar fuente | Asignar proveedor a SolPed |
| ME57 | Asignar y generar PO | Convertir SolPed en PO |

### Tabla EBAN — Campos clave
| Campo | Descripcion | Relevancia |
|-------|-------------|-----------|
| BANFN | Numero solicitud | Clave |
| BNFPO | Posicion | Clave |
| BSART | Tipo documento | Config T161 |
| MATNR | Material | Dato maestro |
| MENGE | Cantidad | Operativo |
| FRGST | Estado liberacion | Workflow |
| FRGKZ | Indicador liberacion | Final/parcial |
| EBELN | Pedido generado | Trazabilidad |

## Pedido de Compra (Purchase Order)

### Transacciones
| TCode | Accion | Notas |
|-------|--------|-------|
| ME21N | Crear | La mas usada |
| ME22N | Modificar | Con historial de cambios |
| ME23N | Visualizar | |
| ME27 | Crear con referencia | Desde SolPed, contrato, etc |
| ME28 | Liberar | Individual |
| ME29N | Liberar (Enjoy) | Version Enjoy |
| ME2M | Por material | Reporting |
| ME2N | Por numero PO | Reporting |
| ME2L | Por proveedor | Reporting |
| ME9F | Imprimir/enviar | Output (NACE) |

### Tabla EKKO — Cabecera PO
| Campo | Descripcion | Diagnostico |
|-------|-------------|------------|
| EBELN | Numero pedido | Clave |
| BUKRS | Sociedad | Asignacion contable |
| BSART | Tipo documento | Config T161 |
| BSTYP | Categoria doc | F=PO, K=Contrato, L=Plan entregas |
| LIFNR | Proveedor | Dato maestro |
| EKORG | Org compras | Estructura org |
| EKGRP | Grupo compra | Responsable |
| WAERS | Moneda | |
| FRGSX | Release strategy | T16FS |
| FRGKE | Release indicator | Estado aprobacion |
| FRGZU | Release status | Estado completo |

### Tabla EKPO — Posiciones PO
| Campo | Descripcion | Diagnostico |
|-------|-------------|------------|
| EBELP | Numero posicion | Clave |
| MATNR | Material | Obligatorio o texto |
| TXZ01 | Texto breve | Si no hay material |
| MENGE | Cantidad pedida | |
| MEINS | Unidad medida | |
| NETPR | Precio neto | |
| PEINH | Unidad precio | Por cuantas unidades |
| PSTYP | Tipo posicion | 0=normal, 2=consignacion, 3=subcontratacion |
| KNTTP | Categoria imputacion | K=centro coste, F=orden, P=proyecto |
| WERKS | Centro | Destino |
| LGORT | Almacen | Destino |
| WEPOS | Ind. entrada mercancias | X=requiere GR |
| REPOS | Ind. entrada factura | X=requiere IR |

### Queries MCP para diagnostico
```sql
-- Pedidos pendientes de entrada de mercancias
SELECT EKKO.EBELN, EKPO.EBELP, EKPO.MATNR, EKPO.MENGE, EKPO.WEMNG,
       (EKPO.MENGE - EKPO.WEMNG) AS PENDIENTE
FROM EKKO JOIN EKPO ON EKKO.EBELN = EKPO.EBELN
WHERE EKKO.LIFNR = '{proveedor}' AND EKPO.ELIKZ = '' AND EKPO.WEMNG < EKPO.MENGE

-- Pedidos bloqueados sin liberar
SELECT EBELN, LIFNR, BSART, FRGSX, FRGKE, FRGZU
FROM EKKO WHERE FRGZU <> '' AND PROCSTAT <> '05'
AND EKORG = '{org_compras}'

-- Historial de un pedido (GR + IR)
SELECT EBELN, EBELP, VGABE, MENGE, DMBTR, BUDAT, BELNR
FROM EKBE WHERE EBELN = '{pedido}'
ORDER BY VGABE, BUDAT
-- VGABE: 1=GR, 2=IR, 3=Downpayment
```

## Categorias de Posicion (PSTYP)

| PSTYP | Nombre | Descripcion | Particularidad |
|-------|--------|-------------|----------------|
| 0/blank | Normal | Compra estandar | GR + IR |
| 1 | Consignacion | Proveedor mantiene stock | Sin factura, liquidacion MRKO |
| 2 | Subcontratacion | Proveedor procesa material | Provision componentes ME2O |
| 3 | Servicio | Hoja entrada servicios | ML81N para aceptar |
| 5 | Material pipeline | Suministro continuo | Sin GR, factura periodica |
| 7 | Stock en transito | Stock transfer order (STO) | Solo entre centros propios |
| 9 | Material proporcionado | Free of charge | Sin valoracion |

## Categorias de Imputacion (KNTTP)

| KNTTP | Nombre | Imputacion a | Obligatorio |
|--------|--------|-------------|:-----------:|
| blank | Stock | Almacen | No |
| K | Centro coste | CO-CCA | KOSTL |
| F | Orden | CO-OPA | AUFNR |
| P | Proyecto WBS | PS | PS_PSP_PNR |
| A | Activo fijo | AA | ANLN1 |
| N | Red (Network) | PS | NPLNR |
| Q | Reserva proyecto | PS | PS_PSP_PNR |
