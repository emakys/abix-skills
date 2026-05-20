# Transacciones MM — Referencia Completa

## Datos Maestros
| TCode | Descripcion | Programa | Auth Object |
|-------|-------------|----------|-------------|
| MM01 | Crear material | SAPLMGMM | M_MATE_BUK |
| MM02 | Modificar material | SAPLMGMM | M_MATE_BUK |
| MM03 | Visualizar material | SAPLMGMM | M_MATE_BUK |
| MM06 | Marcar borrado material | SAPLMGMM | M_MATE_BUK |
| MM17 | Modificacion masiva material | RMMM17MM | M_MATE_BUK |
| MK01 | Crear proveedor (ECC) | SAPMF02K | F_LFA1_BUK |
| XK01 | Crear proveedor central (ECC) | SAPMF02K | F_LFA1_BUK |
| BP | Business Partner (S/4) | BUS_PARTNER | B_BUPA_GRP |
| ME11 | Crear info record | SAPMMM07I | M_RAHM_EKO |
| ME01 | Mantener source list | SAPMM06S | M_BANF_EKO |
| MEQ1 | Mantener quota arrangement | SAPMM06Q | M_RAHM_EKO |

## Solicitud de Pedido
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| ME51N | Crear solicitud pedido | SAPLMEREQ |
| ME52N | Modificar solicitud | SAPLMEREQ |
| ME53N | Visualizar solicitud | SAPLMEREQ |
| ME54N | Liberar individual | SAPLMEREQ |
| ME55 | Liberar colectiva | RM06BRL0 |
| ME56 | Asignar fuente suministro | SAPLMEREQ |
| ME57 | Asignar y generar PO | SAPLMEREQ |
| ME5A | Lista solicitudes pedido | RM06BA00 |
| ME5J | Solicitudes por proyecto | RM06BJ00 |

## Pedido de Compra
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| ME21N | Crear pedido | SAPLMEGUI |
| ME22N | Modificar pedido | SAPLMEGUI |
| ME23N | Visualizar pedido | SAPLMEGUI |
| ME27 | Crear con referencia | SAPLMEGUI |
| ME28 | Liberar pedido | RM06BRL0 |
| ME29N | Liberar (Enjoy) | SAPLMEGUI |
| ME2L | POs por proveedor | RM06EL00 |
| ME2M | POs por material | RM06EM00 |
| ME2N | POs por numero | RM06EN00 |
| ME2C | POs por grupo material | RM06EC00 |
| ME9F | Imprimir/enviar mensajes | RM06NF00 |
| ME80FN | Analisis de compras | RMEAINFO |

## Contratos y Planes de Entrega
| TCode | Descripcion |
|-------|-------------|
| ME31K | Crear contrato |
| ME32K | Modificar contrato |
| ME33K | Visualizar contrato |
| ME35K | Liberar contrato |
| ME31L | Crear plan entregas |
| ME32L | Modificar plan entregas |
| ME38 | Reparticiones plan entregas |

## Entrada de Mercancias
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| MIGO | Goods Movement (universal) | SAPLMIGO |
| MB01 | GR vs PO (clasico) | SAPMM07M |
| MB0A | GR vs PO (Enjoy) | SAPMM07M |
| MB11 | Goods Movement (clasico) | SAPMM07M |
| MB1A | Salida mercancias | SAPMM07M |
| MB1B | Transfer posting | SAPMM07M |
| MB1C | Otros movimientos | SAPMM07M |
| MB31 | GR vs orden produccion | SAPMM07M |
| MB51 | Lista doc material | RM07DOCS |
| MB52 | Stock por almacen | RM07MLBS |
| MMBE | Resumen stock | RMMMBESTN |
| MB5B | Stock a fecha | RM07MMFI |
| MI01 | Crear doc inventario | SAPMM07I |
| MI04 | Entrar recuento inventario | SAPMM07I |
| MI07 | Contabilizar diferencias inv. | SAPMM07I |

## Verificacion de Facturas
| TCode | Descripcion | Programa |
|-------|-------------|----------|
| MIRO | Registrar factura | SAPLMR1M |
| MIR4 | Visualizar factura | SAPLMR1M |
| MIR7 | Factura estacionada | SAPLMR1M |
| MRBR | Liberar facturas bloqueadas | RM08RELEASE |
| MRRL | Liquidacion automatica ERS | RMMR1MRL |
| MRKO | Liquidacion consignacion | RMMR1MKO |
| MR8M | Cancelar factura | SAPLMR1M |
| MR11 | Compensacion GR/IR | RM07MSAL |
| MR11SHOW | Mostrar GR/IR clearing | RM07MSAL |

## Reporting y Analisis
| TCode | Descripcion |
|-------|-------------|
| ME80FN | Analisis general de compras |
| MC$0-MC$G | Analisis SIS (estadisticas) |
| MCBA | Analisis consumo material |
| MCBC | Analisis stock |
| MCBE | Analisis rango cobertura |
| MB5L | Lista de saldos de stock |
| ME2W | POs por centro proveedor |
| S_ALR_87012357 | Saldos proveedores |
