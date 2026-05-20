# Verificacion de Facturas (Invoice Verification)

## Transacciones principales
| TCode | Accion |
|-------|--------|
| MIRO | Registrar factura logistica |
| MIR4 | Visualizar factura |
| MIR5 | Visualizar lista facturas |
| MIR6 | Resumen facturas |
| MIR7 | Factura estacionada (park) |
| MRBR | Liberar facturas bloqueadas |
| MRRL | Liquidacion automatica ERS |
| MRKO | Liquidacion consignacion |
| MR8M | Cancelar factura |
| MR11 | Compensacion GR/IR |

## Tipos de factura en MIRO
| Tipo | Descripcion |
|------|-------------|
| Factura | Factura normal del proveedor |
| Nota credito | Abono del proveedor |
| Cargo posterior | Ajuste de precio posterior al GR |
| Abono posterior | Reverso de cargo posterior |
| Factura estacionada | Pendiente de verificacion/aprobacion |

## Proceso de verificacion

```
Factura proveedor
    |
    +-> MIRO: Registrar
    |   |
    |   +-> Verificacion 3-way match:
    |   |   PO (EKPO.NETPR) vs GR (EKBE) vs Factura (RSEG)
    |   |
    |   +-> Dentro de tolerancia?
    |       +-- SI -> Contabilizar -> RBKP/RSEG + BKPF/BSEG
    |       +-- NO -> Bloqueo automatico -> MRBR para liberar
    |
    +-> MRRL: Facturacion automatica (ERS)
    |   Condiciones: proveedor con flag ERS, GR registrado
    |
    +-> MR11: Compensacion GR/IR
        Corrige saldos en cuenta GR/IR transitoria
```

## Tablas de factura logistica
| Tabla | Contenido |
|-------|-----------|
| RBKP | Cabecera factura logistica |
| RSEG | Posiciones factura logistica |
| BKPF | Cabecera doc. contable (asiento FI) |
| BSEG | Posiciones doc. contable |

## Tolerancias (OMR6/OMRM)

| Clave | Descripcion | Ejemplo |
|-------|-------------|---------|
| AN | Monto por posicion | Max 100 USD diferencia |
| AP | Porcentaje por posicion | Max 10% diferencia |
| DW | Tolerancia contenido (cantidad) | Max 5% diferencia cantidad |
| PP | Precio por posicion | Max 5% desviacion precio |
| BD | Diferencia pequeinas | Hasta 10 USD auto-aceptar |
| ST | Tolerancia fecha | Max 5 dias diferencia fecha |

### Queries MCP
```sql
-- Tolerancias configuradas
SELECT BUKRS, WEMTOL, WMTOL, RVTOL FROM T169G WHERE BUKRS = '{sociedad}'

-- Facturas bloqueadas pendientes
SELECT RBKP.BELNR, RBKP.GJAHR, RBKP.LIFNR, RBKP.RMWWR,
       RBKP.ZLSPR, RBKP.ZLSCH
FROM RBKP
WHERE RBKP.BUKRS = '{sociedad}' AND RBKP.ZLSPR <> ''

-- Saldo GR/IR pendiente (cuenta transitoria)
SELECT EBELN, EBELP, VGABE, SUM(DMBTR) as SALDO
FROM EKBE WHERE EBELN = '{pedido}'
GROUP BY EBELN, EBELP, VGABE
-- Comparar VGABE 1 (GR) vs VGABE 2 (IR)
```

## Errores comunes

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| MR 020 | Invoice blocked | Diferencia precio/cantidad | MRBR liberar o corregir |
| MR 011 | GR quantity insufficient | Factura > cantidad GR | Verificar GR o ajustar |
| M8 351 | Price variance | Precio factura != precio PO | Tolerancias OMR6 |
| M8 147 | Tax code error | Codigo impuesto invalido | FTXP revisar |
| MR 521 | No GR for this PO item | No hay entrada mercancias | MIGO registrar GR |
| MR 013 | Amount in LC too large | Monto excede tolerancia | MRBR o ajustar tolerancia |

## ERS (Evaluated Receipt Settlement)

Facturacion automatica basada en GR:
1. Proveedor configurado con flag ERS (LFM1-XERSY)
2. Info record con precio fijo (EINE)
3. GR registrado (tipo 101)
4. MRRL genera factura automatica = GR * precio info record
5. No requiere factura fisica del proveedor

### Query para verificar ERS
```sql
-- Proveedores con ERS activo
SELECT LFM1.LIFNR, LFA1.NAME1, LFM1.EKORG, LFM1.XERSY
FROM LFM1 JOIN LFA1 ON LFM1.LIFNR = LFA1.LIFNR
WHERE LFM1.XERSY = 'X' AND LFM1.EKORG = '{org_compras}'
```
