# Entrada de Mercancias (Goods Receipt)

## Transacciones principales
| TCode | Accion | Tipo movimiento |
|-------|--------|-----------------|
| MIGO | Goods Receipt vs PO | 101 |
| MIGO | GR vs Production Order | 101 |
| MIGO | GR sin referencia | 501 |
| MIGO | Devolucion al proveedor | 122 |
| MIGO | Cancelacion GR | 102 |
| MB52 | Stock por almacen | — |
| MMBE | Resumen stock material | — |
| MB51 | Lista doc. material | — |
| MB5B | Stock a fecha | — |

## Tipos de movimiento clave
| TM | Descripcion | Efecto stock | Efecto contable |
|----|-------------|-------------|-----------------|
| 101 | GR vs PO | +Libre utilizacion | D: Stock, C: GR/IR |
| 102 | Cancel GR vs PO | -Libre utilizacion | Reverso |
| 103 | GR en calidad | +Calidad | D: Stock calidad, C: GR/IR |
| 105 | GR a libre desde calidad | +Libre, -Calidad | Traspaso |
| 122 | Devolucion proveedor | -Libre utilizacion | D: GR/IR, C: Stock |
| 161 | Devolucion al proveedor (ref GR) | -Libre | Reverso |
| 201 | Consumo a centro coste | -Libre | D: Consumo, C: Stock |
| 261 | Consumo a orden produccion | -Libre | D: Orden, C: Stock |
| 301 | Traslado centro a centro | -Origen, +Destino | Transfer posting |
| 311 | Traslado almacen a almacen | -Origen, +Destino | Sin efecto FI |
| 501 | GR sin PO (sin referencia) | +Libre | D: Stock, C: varios |
| 551 | Desguace / scrapping | -Libre | D: Perdida, C: Stock |
| 561 | Entrada por inventario | +Libre | D: Stock, C: Diferencia inv. |
| 601 | Salida por entrega SD | -Libre | D: Coste ventas, C: Stock |

## Tablas de documentos de material
| Tabla | Contenido |
|-------|-----------|
| MKPF | Cabecera doc. material (fecha, usuario, texto) |
| MSEG | Posiciones doc. material (material, cantidad, TM, centro, almacen) |
| MATDOC | Tabla unificada S/4HANA (reemplaza MKPF+MSEG) |

## Queries MCP
```sql
-- Documento de material completo
SELECT MKPF.MBLNR, MKPF.BUDAT, MKPF.USNAM,
       MSEG.ZEILE, MSEG.BWART, MSEG.MATNR, MSEG.WERKS, MSEG.LGORT,
       MSEG.MENGE, MSEG.MEINS, MSEG.EBELN, MSEG.EBELP
FROM MKPF JOIN MSEG ON MKPF.MBLNR = MSEG.MBLNR AND MKPF.MJAHR = MSEG.MJAHR
WHERE MKPF.MBLNR = '{doc_material}'

-- Movimientos de un material en un periodo
SELECT MBLNR, BUDAT, BWART, MENGE, WERKS, LGORT, EBELN
FROM MSEG WHERE MATNR = '{material}' AND BUDAT BETWEEN '{desde}' AND '{hasta}'

-- Stock actual por centro y almacen
SELECT MATNR, WERKS, LGORT, LABST, INSME, SPEME, RETME
FROM MARD WHERE MATNR = '{material}' AND WERKS = '{centro}'
-- LABST=libre, INSME=calidad, SPEME=bloqueado, RETME=devolucion
```

## Determinacion automatica de cuentas (OBYC)

Cuando se registra un GR, SAP determina cuentas automaticamente:

| Clave | Descripcion | Tipico |
|-------|-------------|--------|
| BSX | Stock material | Cuenta de inventario |
| WRX | GR/IR clearing | Cuenta transitoria GR/IR |
| PRD | Diferencia de precio | Solo precio estandar (S) |
| GBB-VBR | Consumo general | Consumo a centro coste |
| GBB-AUF | Consumo a orden | Consumo a orden de produccion |
| KON | Consignacion | Obligacion consignacion |

### Queries para verificar
```sql
-- Cuentas configuradas en OBYC
SELECT KTOPL, BWMOD, KTOSL, KONTS FROM T030
WHERE KTOPL = '{plan_cuentas}' AND KTOSL IN ('BSX','WRX','PRD','GBB')

-- Grupo valoracion del material (necesario para OBYC)
SELECT MATNR, BKLAS FROM MBEW WHERE MATNR = '{material}' AND BWKEY = '{centro}'
```

## Errores comunes en GR

| Error | Causa | Fix |
|-------|-------|-----|
| M7 060 | Material no extendido al centro | MM01 ampliar al centro |
| 06 024 | Tipo movimiento no permitido | OMJJ config |
| M8 580 | Sin determinacion cuenta | OBYC asignar cuentas |
| M7 032 | Sin info record (si es requerido) | ME11 crear |
| M7 154 | Stock negativo no permitido | OMJJ o corregir stock |
| M8 351 | Tolerancia precio excedida | OMR6 ajustar |
