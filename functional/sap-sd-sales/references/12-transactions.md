# Transacciones SD — Referencia Completa

## Pedidos de Cliente (Sales Orders)

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VA01 | Crear pedido de cliente | SAPMV45A | V_VBAK_AAT |
| VA02 | Modificar pedido | SAPMV45A | V_VBAK_AAT |
| VA03 | Visualizar pedido | SAPMV45A | V_VBAK_AAT |
| VA05 | Lista pedidos por cliente/material | RVAUFSLN | V_VBAK_AAT |
| VA05N | Lista pedidos (Enjoy) | SAPMV45A | V_VBAK_AAT |
| VA07 | Comparar pedido con compras | RVAUFSO7 | V_VBAK_AAT |
| VA08 | Comparar pedido con contrato | RVAUFSO8 | V_VBAK_AAT |
| VA14L | Lista ped. bloqueados entrega | RVAUFSBL | V_VBAK_VKO |
| VA15 | Consulta pedidos | RVAUFSLN | V_VBAK_AAT |
| VA88 | Cierre periodico pedidos | RVAUFSK2 | V_VBAK_AAT |

## Ofertas (Quotations)

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VA11 | Crear oferta | SAPMV45A | V_VBAK_AAT |
| VA12 | Modificar oferta | SAPMV45A | V_VBAK_AAT |
| VA13 | Visualizar oferta | SAPMV45A | V_VBAK_AAT |
| VA15 | Lista de ofertas | RVAUFSLN | V_VBAK_AAT |

## Solicitudes de Oferta (Inquiry)

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VA21 | Crear solicitud de oferta | SAPMV45A |
| VA22 | Modificar solicitud de oferta | SAPMV45A |
| VA23 | Visualizar solicitud de oferta | SAPMV45A |
| VA25 | Lista solicitudes de oferta | RVAUFSLN |

## Contratos Marco (Contracts)

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VA41 | Crear contrato | SAPMV45A | V_VBAK_AAT |
| VA42 | Modificar contrato | SAPMV45A | V_VBAK_AAT |
| VA43 | Visualizar contrato | SAPMV45A | V_VBAK_AAT |
| VA45 | Lista contratos | RVAUFSLN | V_VBAK_AAT |

## Planes de Entregas (Scheduling Agreements)

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VA31 | Crear plan de entregas | SAPMV45A |
| VA32 | Modificar plan de entregas | SAPMV45A |
| VA33 | Visualizar plan de entregas | SAPMV45A |
| VA35 | Lista planes de entregas | RVAUFSLN |

## Pedidos de Terceros / Especiales

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VA51 | Crear posicion de pedido | SAPMV45A |
| VA52 | Modificar posicion de pedido | SAPMV45A |
| VA53 | Visualizar posicion de pedido | SAPMV45A |

---

## Entregas (Delivery)

### Creacion y Modificacion
| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VL01N | Crear entrega salida (Enjoy) | SAPMV50A | V_LIKP_VST |
| VL02N | Modificar entrega salida | SAPMV50A | V_LIKP_VST |
| VL03N | Visualizar entrega salida | SAPMV50A | V_LIKP_VST |
| VL09 | Cancelar salida de mercancias | SAPMV50A | V_LIKP_VST |
| VL10A | Crear entregas desde pedidos (worklist) | RVSDLPOL | V_LIKP_VST |
| VL10B | Crear entregas por pedido compras | RVSDLPOL | V_LIKP_VST |
| VL10C | Crear entregas por proyecto | RVSDLPOL | V_LIKP_VST |
| VL10D | Crear entregas desde contratos | RVSDLPOL | V_LIKP_VST |
| VL10E | Crear entregas (OrdRef individual) | RVSDLPOL | V_LIKP_VST |
| VL10G | Entregas por punto expedicion | RVSDLPOL | V_LIKP_VST |
| VL10H | Entregas por transportista | RVSDLPOL | V_LIKP_VST |

### Monitor de Entregas
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VL06O | Monitor salidas pendientes | RVSDLMON |
| VL06G | Monitor goods issue pendientes | RVSDLMON |
| VL06P | Monitor picking pendiente | RVSDLMON |
| VL06C | Monitor confirmar picking | RVSDLMON |
| VL06T | Monitor transferencias warehouse | RVSDLMON |
| VL06I | Monitor entregas entrada | RVSDLMON |

### Entregas Entrada (Inbound)
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VL31N | Crear entrega entrada | SAPMV50A |
| VL32N | Modificar entrega entrada | SAPMV50A |
| VL33N | Visualizar entrega entrada | SAPMV50A |

---

## Facturacion (Billing)

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VF01 | Crear factura | SAPMV60A | V_VBRK_FKA |
| VF02 | Modificar factura | SAPMV60A | V_VBRK_FKA |
| VF03 | Visualizar factura | SAPMV60A | V_VBRK_FKA |
| VF04 | Lista de trabajo facturas | RV60SBAT | V_VBRK_FKA |
| VF05 | Lista facturas | RVIVAUFT | V_VBRK_FKA |
| VF05N | Lista facturas (Enjoy) | RVIVAUFN | V_VBRK_FKA |
| VF06 | Proceso batch de facturacion | RV60SBAT | V_VBRK_FKA |
| VF11 | Cancelar factura | SAPMV60A | V_VBRK_FKA |
| VF21 | Crear factura consignacion | SAPMV60A | V_VBRK_FKA |
| VF26 | Transferir factura a FI | SAPMV60A | |
| VF31 | Output de facturacion | RV60NFOR | V_VBRK_FKA |
| VF44 | Facturacion de avance | RVFKMI20 | |
| VF46 | Actualizar datos factura avance | SAPMV60A | |
| VFX3 | Bloqueo de facturacion | RVFKBLK0 | |
| V.23 | Facturacion colectiva | RV60SBAT | |

---

## Precios y Condiciones

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VK11 | Crear condicion de precio | SAPMV13A | V_KONH_VKP |
| VK12 | Modificar condicion | SAPMV13A | V_KONH_VKP |
| VK13 | Visualizar condicion | SAPMV13A | V_KONH_VKP |
| VK14 | Crear condicion con referencia | SAPMV13A | V_KONH_VKP |
| VK31 | Crear condicion (lista) | SAPMV13A | V_KONH_VKP |
| VK32 | Modificar condicion (lista) | SAPMV13A | V_KONH_VKP |
| VK33 | Visualizar condicion (lista) | SAPMV13A | V_KONH_VKP |
| V/06 | Definir tipos de condicion | SAPMV12A | S_DEVELOP |
| V/07 | Definir secuencias de acceso | SAPMV12A | S_DEVELOP |
| V/08 | Definir esquemas calculo | SAPMV12A | S_DEVELOP |
| V/I2 | Actualizar precios en masa | RV14MCHG | V_KONH_VKP |
| VKOA | Asig. cuentas revenue (det.cuentas) | SAPMV13A | |

---

## Control de Copia (Copy Control)

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| VTAA | Copia pedido→pedido | OR a RE, ZOR a ZOR |
| VTLA | Copia pedido→entrega | OR a LF |
| VTFL | Copia entrega→factura | LF a F2 |
| VTFF | Copia factura→factura | F2 a G2, F2 a S1 |
| VTAF | Copia factura→pedido | F2 a RE (devoluciones) |
| VTFA | Copia pedido→factura | OR a F2 (factura directa) |

### Queries para control de copia
```sql
-- Control copia pedido a entrega
SELECT KAPPL, QUALF, FOLLW, DATBF, DATAF
FROM TVCPA
WHERE KAPPL = 'M' AND QUALF = '{tipo_pedido}' AND FOLLW = '{tipo_entrega}'

-- Control copia entrega a factura
SELECT KAPPL, QUALF, FOLLW, DATBF, DATAF
FROM TVCPA
WHERE KAPPL = 'J' AND QUALF = '{tipo_entrega}' AND FOLLW = '{tipo_factura}'
```

---

## Credito (Credit Management)

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VKM1 | Bloqueados — pedidos credito | RVKRED01 | V_VBAK_AAT |
| VKM2 | Liberados — pedidos credito | RVKRED02 | V_VBAK_AAT |
| VKM3 | Pedidos para revision credito | RVKRED03 | V_VBAK_AAT |
| VKM4 | Entregas bloqueadas credito | RVKRED04 | V_LIKP_VST |
| VKM5 | Pedidos y entregas credito | RVKRED05 | V_VBAK_AAT |
| FD32 | Datos credito cliente (FI-AR) | SAPMF02D | F_KNA1_BEK |
| OVA8 | Config credit management | SAPMF02G | S_DEVELOP |
| F.31 | Evaluacion riesgo de credito | RFKRED00 | |
| F.32 | Actualizar limite credito | RFKRED30 | |
| FCV3 | Early warning credit | RFKREDPR | |

```sql
-- Estado credito de un cliente
SELECT KUNNR, KNKLI, KLIMK, SKFOR, SSOBL, DSAUFT
FROM KNKK
WHERE KUNNR = '{cliente}' AND KKBER = '{area_credito}'

-- Pedidos bloqueados por credito
SELECT VBELN, KUNNR, AUART, CMGST
FROM VBAK
WHERE CMGST IN ('B', 'D')
AND VKORG = '{org_ventas}'
AND ERDAT >= '{fecha}'
```

---

## Transporte y Expedicion

| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| VT01N | Crear transporte | SAPMVT01 | V_TRKPF_VLN |
| VT02N | Modificar transporte | SAPMVT01 | V_TRKPF_VLN |
| VT03N | Visualizar transporte | SAPMVT01 | V_TRKPF_VLN |
| VT04 | Monitor de transportes | RVTMONI0 | V_TRKPF_VLN |
| VLSP | Registro de salida de mercancias | SAPMV50A | V_LIKP_VST |
| VL71 | Output de entrega | RVADDE00 | |

---

## Determinacion de Mensajes / Output

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| NACE | Configuracion de mensajes (per app) | SAPMV13N |
| VV11 | Crear condicion output pedido | SAPMV13A |
| VV12 | Modificar condicion output pedido | SAPMV13A |
| VV13 | Visualizar condicion output pedido | SAPMV13A |
| VV21 | Crear condicion output entrega | SAPMV13A |
| VV22 | Modificar condicion output entrega | SAPMV13A |
| VV23 | Visualizar condicion output entrega | SAPMV13A |
| VV31 | Crear condicion output factura | SAPMV13A |
| VV32 | Modificar condicion output factura | SAPMV13A |
| VV33 | Visualizar condicion output factura | SAPMV13A |

```sql
-- Condiciones output de pedido (tabla NACH o NAST)
SELECT KAPPL, KSCHL, SPRAS, NACHA, LDEST
FROM NAST
WHERE KAPPL = 'V1' AND OBJKY = '{pedido}'

-- Config output types
SELECT KSCHL, VTEXT, NACHA, LDEST
FROM TNAPR WHERE KAPPL = 'V1' AND SPRAS = 'E'
```

---

## Reportes y Analisis

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VA05 | Lista de pedidos | RVAUFSLN |
| VL06O | Monitor entregas pendientes | RVSDLMON |
| VF05 | Lista de facturas | RVIVAUFT |
| V.02 | Pedidos pendientes entrega | RVAUFSVO |
| V.03 | Pedidos en backlog | RVAUFSRU |
| V.15 | Lista pedidos bloqueados | RVAUFSBL |
| V.23 | Facturacion colectiva | RV60SBAT |
| SD01 | Cockpit SD — analisis | RSDSD001 |
| MC+* | Sistema Informacion Ventas (SIS) | MC* |
| MCTA | Analisis SIS por material | RMCS0000 |
| MCTC | Analisis SIS por cliente | RMCS0000 |
| MCTE | Analisis SIS por org ventas | RMCS0000 |
| S_ALR_87012186 | Analisis cuentas de deudores | RFITEMAR |
| VKM5 | Revision credito pedidos+entregas | RVKRED05 |

---

## Customizing / Configuracion

| TCode | Descripcion | Programa | Tabla afectada |
|-------|-------------|----------|----------------|
| VOV8 | Definir tipos de pedido | SAPMV45A | TVAK |
| VOV7 | Definir categorias de posicion | SAPMV45A | TVEP |
| VOV5 | Asig. cat.pos. (det.automatica) | SAPMV45A | T184 |
| VOV6 | Definir categorias linea reparto | SAPMV45A | TVEZ |
| VOV4 | Asig. cat.lin.reparto (det.auto) | SAPMV45A | T188 |
| OVLK | Definir tipos de entrega | SAPMV50A | TVLK |
| OVLP | Asig. cat.pos.entrega (det.auto) | SAPMV50A | T184L |
| VOFA | Definir tipos de factura | SAPMV60A | TVFK |
| OVA8 | Config credit management | — | TVKRE |
| OVKK | Det. esquema calculo | SAPMV12A | T683V |
| VOPA | Determ. interlocutores | SAPMV13A | TPAUM |
| OVZG | Motivos de rechazo | — | TVAG |
| OVX5 | Org ventas→sociedad FI | — | TVKO |
| OVL2 | Asig.centro→punto expedicion | — | T001W |
| OVR1 | Definir rutas | — | TROD |
| OVR2 | Determinar rutas | — | TRODF |
| VKOA | Determinar cuentas revenue | SAPMV13A | KOFI |
| V/06 | Tipos de condicion precio | SAPMV12A | T685 |
| V/07 | Secuencias de acceso | SAPMV12A | T682 |
| V/08 | Esquemas de calculo | SAPMV12A | T683 |

---

## Programas de Fondo / Batch

| TCode | Descripcion | Programa |
|-------|-------------|----------|
| VF06 | Facturacion background | RV60SBAT |
| VL10A | Creacion entregas background | RVSDLPOL |
| V_V2 | Reorganizacion listas necesidades | RV60SBAT |
| VD31 | Crear condiciones cliente masivo | RVMASSVK |

---

## Herramientas Tecnicas / Analisis

| TCode | Descripcion | Uso |
|-------|-------------|-----|
| SE16N | Explorar tablas SD | VBAK, VBAP, LIKP, LIPS, VBRK, VBRP |
| VA44 | Actualizar pedidos incompletoss | SAPMV45A |
| V/LD | Actualizar precios en pedidos | RVPREPRI |
| SDORDER_DEL | Borrado pedidos test | SDORDER_DEL |
| RV_INVOICE_CREATE | FM facturacion | Funcion FM directo |
| OVA7 | Exclusion combinaciones ped+mat | — |

```sql
-- Flujo completo de un pedido (donde esta en el proceso)
SELECT VB.VBELN, VB.AUART, VB.KUNNR, VB.VKORG,
       VP.POSNR, VP.MATNR, VP.KWMENG,
       VP.LFSTA AS EST_ENTREGA, VP.FKSTA AS EST_FACTURA,
       VP.ABGRS AS RECHAZADO
FROM VBAK VB JOIN VBAP VP ON VB.VBELN = VP.VBELN
WHERE VB.VBELN = '{pedido}'

-- Documentos SD asociados a un pedido (flujo documental)
SELECT VBELN, POSNN, VBTYP_N AS TIPO_SUCESOR, BELNR
FROM VBFA
WHERE VBELV = '{pedido}' AND VBTYP_V = 'C'
ORDER BY VBTYP_N

-- Pedidos pendientes de facturar
SELECT VB.VBELN, VB.KUNNR, VB.AUDAT, VP.MATNR,
       VP.KWMENG, VP.FKSTA, VP.ABGRS
FROM VBAK VB JOIN VBAP VP ON VB.VBELN = VP.VBELN
WHERE VB.VKORG = '{org}'
AND VP.FKSTA NOT IN ('C')   -- C = completamente facturado
AND VP.ABGRS = ' '          -- no rechazado
AND VB.AUDAT >= '{fecha}'
ORDER BY VB.KUNNR, VB.VBELN
```
