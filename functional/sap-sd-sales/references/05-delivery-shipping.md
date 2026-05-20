# Entrega y Expedicion (Delivery & Shipping)

## Proceso de expedicion

```
Pedido venta (VA01)
    |
    +-- Crear entrega (VL01N o VL10 batch)
    |   LIKP/LIPS creados
    |
    +-- Picking (VL02N o LT03 para WM)
    |   Preparar material fisicamente
    |   Asignar lotes/numeros serie si aplica
    |
    +-- Packing (VL02N tab "Packing")
    |   Asignar a unidades de embalaje (HU)
    |   Opcional pero comun en exportacion
    |
    +-- PGI — Post Goods Issue (VL02N)
    |   Salida de mercancias (tipo movimiento 601)
    |   D: Coste ventas (COGS) | C: Stock
    |   Stock se reduce, doc material generado
    |
    +-- Transporte (VT01N) [opcional]
        Planificacion de transporte, carga de vehiculos
```

## Transacciones principales

### Creacion de entregas
| TCode | Accion |
|-------|--------|
| VL01N | Crear entrega individual (desde pedido) |
| VL02N | Modificar entrega (picking, packing, PGI) |
| VL03N | Visualizar entrega |
| VL10A | Crear entregas desde pedidos (colectivo, por fecha) |
| VL10B | Crear entregas desde pedidos (colectivo, por material) |
| VL10C | Crear entregas desde pedidos (colectivo, por shipping point) |
| VL06O | Monitor de entregas (outbound) |
| VL06I | Monitor de entregas (inbound) |
| VL04 | Procesar entregas en cola |

### Goods Issue (PGI)
| TCode | Accion |
|-------|--------|
| VL02N | PGI individual (boton "Post Goods Issue") |
| VL06G | PGI colectivo |
| VL09 | Cancelar PGI (reversa goods issue) |

### Transporte
| TCode | Accion |
|-------|--------|
| VT01N | Crear transporte |
| VT02N | Modificar transporte |
| VT03N | Visualizar transporte |
| VL06T | Monitor de transportes |

## Tipos de entrega

| Tipo | Nombre | Uso |
|------|--------|-----|
| LF | Entrega estandar | La mas comun |
| NL | Entrega sin referencia | Sin pedido |
| LO | Entrega sin picking | Sin proceso WM |
| NLCC | Entrega STO (intercompany) | Stock transfer |
| LR | Returns delivery | Devolucion del cliente |
| EL | Inbound delivery (proveedor) | Entrada de mercancias |

## Tabla LIKP — Cabecera entrega
| Campo | Descripcion |
|-------|-------------|
| VBELN | Numero entrega |
| LFART | Tipo entrega |
| KUNNR | Destinatario mercancias |
| WADAT_IST | Fecha real salida mercancias |
| WADAT | Fecha planificada salida |
| LDDAT | Fecha carga |
| KODAT | Fecha picking |
| VSTEL | Puesto expedicion |
| ROUTE | Ruta |
| WBSTK | Status PGI (C=PGI done) |
| KOSTK | Status picking (C=complete) |
| TRSPG | Transportation planning status |
| FKSTK | Status facturacion (C=facturado) |

## Tabla LIPS — Posiciones entrega
| Campo | Descripcion |
|-------|-------------|
| POSNR | Posicion entrega |
| MATNR | Material |
| LFIMG | Cantidad entregada (real) |
| VRKME | Unidad venta |
| WERKS | Centro |
| LGORT | Almacen |
| CHARG | Numero de lote |
| VGBEL | Doc referencia (pedido venta) |
| VGPOS | Posicion referencia |
| PSTYV | Categoria posicion |
| PIKMG | Cantidad picked |

## Picking

### Proceso
```
1. Entrega creada (LIKP/LIPS con LFIMG = cantidad a entregar)
2. VL02N → Tab "Picking" → asignar cantidad picking (PIKMG)
   - Manual: introducir cantidad directamente
   - Automatico: crear Transfer Order (LT03 para WM, /SCWM/PRDO para EWM)
3. Si batch management: asignar lote (CHARG)
4. Si serial numbers: asignar numeros serie
5. Status picking: KOSTK = A(no iniciado), B(parcial), C(completo)
```

### Lean WM vs Full WM vs EWM
| Metodo | Cuando usar | Config |
|--------|-------------|--------|
| Sin WM | Almacenes simples | Picking manual en VL02N |
| Lean WM | Almacen con ubicaciones simples | WM sin transfer orders |
| Full WM | Almacen complejo (zonas, estrategias) | Transfer Orders (LT03) |
| EWM | S/4HANA embedded | Warehouse Tasks (/SCWM/) |

## Packing (Handling Units)

```
VL02N → Tab "Packing"

Handling Unit (HU):
  - Material de embalaje (caja, palet, contenedor)
  - Asignar items de la entrega a HUs
  - Peso bruto/neto, volumen, dimensiones
  - Etiquetado (SSCC, barcode)

Tablas: VEKP (HU header), VEPO (HU items)
Config: SPRO → SD → Shipping → Packing → Define Packaging Materials
```

## Post Goods Issue (PGI)

```
VL02N → Boton "Post Goods Issue"

Efectos:
  1. Doc. material generado (tipo movimiento 601)
     D: Coste de ventas (COGS) → GBB-VAX
     C: Stock material → BSX
  2. Stock reducido en MARD
  3. LIKP-WBSTK = 'C' (PGI completado)
  4. Doc. material: MKPF/MSEG (ECC) o MATDOC (S/4)
  5. Entrega lista para facturacion (si FKREL='A' en copia)
  6. Revenue recognition triggered (si configurado)

Reversa PGI: VL09
  Restaura stock, cancela doc material, reabre entrega
```

## Queries MCP

```sql
-- Entregas pendientes de PGI
SELECT LIKP.VBELN, LIKP.LFART, LIKP.KUNNR, LIKP.WADAT, LIKP.VSTEL,
       LIKP.WBSTK, LIKP.KOSTK
FROM LIKP WHERE LIKP.VSTEL = '{shipping_point}'
AND LIKP.WBSTK <> 'C' AND LIKP.LFART = 'LF'
ORDER BY LIKP.WADAT

-- Entregas con picking pendiente
SELECT LIKP.VBELN, LIPS.POSNR, LIPS.MATNR, LIPS.LFIMG, LIPS.PIKMG,
       (LIPS.LFIMG - LIPS.PIKMG) as PENDIENTE_PICK
FROM LIKP JOIN LIPS ON LIKP.VBELN = LIPS.VBELN
WHERE LIKP.KOSTK <> 'C' AND LIKP.VSTEL = '{shipping_point}'

-- Entregas pendientes de facturacion (PGI hecho, no facturado)
SELECT LIKP.VBELN, LIKP.KUNNR, LIKP.WADAT_IST, LIKP.FKSTK
FROM LIKP WHERE LIKP.WBSTK = 'C' AND LIKP.FKSTK <> 'C'
AND LIKP.VSTEL = '{shipping_point}'

-- Flujo de documento: pedido → entrega
SELECT VBELV, POSNV, VBELN, POSNN, VBTYP_N FROM VBFA
WHERE VBELV = '{pedido}' AND VBTYP_N = 'J'
```

## Sobre-entrega y sub-entrega

```
Tolerancias configurables por cliente o material:
  KNVV-UEBTK: Over-delivery tolerance %
  KNVV-UNTDL: Under-delivery tolerance %
  MVKE-UEBTK/UNTDL: A nivel material

Si entrega > pedido + tolerancia → error VL 461
Si entrega < pedido → entrega parcial (LIPS-LFMNG < VBAP-KWMENG)
Entrega parcial: puede cerrarse manualmente (final delivery flag)
```

## Errores comunes shipping

| Error | Causa | Fix |
|-------|-------|-----|
| VL 461 | Cantidad excede pedido + tolerancia | Ajustar cantidad o tolerancia |
| No goods issue possible | Stock insuficiente | Verificar MARD-LABST |
| Shipping point not determined | Config VSBED+LADGR+WERKS falta | OVLK configurar |
| Route not determined | Config pais/zona/shipping point falta | SPRO routes |
| Picking quantity differs | WM transfer order no completo | LT12 confirmar TO |
| Delivery block | LIKP-LIFSK o VBAK-LIFSK activo | Quitar bloqueo |
