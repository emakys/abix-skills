# Movimientos de Mercancias en Produccion

## Movimientos principales PP

| Mov. | Descripcion | Efecto stock | Efecto CO |
|------|-------------|-------------|-----------|
| 101 | Entrada mercancias producto (GR) | +Stock PT | Abono orden prod |
| 102 | Anulacion GR producto | -Stock PT | Cargo orden prod |
| 261 | Salida mercancias componentes (GI) | -Stock comp | Cargo orden prod |
| 262 | Anulacion GI componentes | +Stock comp | Abono orden prod |
| 531 | GI by-product (subproducto) | +Stock subprod | Abono orden |
| 532 | Anulacion by-product | -Stock subprod | Cargo orden |

## Tabla de movimientos — S/4HANA

### MATDOC (S/4HANA)
```sql
SELECT MBLNR, MJAHR, ZEESSION, BWART, MATNR, WERKS, LGORT,
       MENGE, MEINS, AUFNR, DMBTR, WAERS, BUDAT, CPUDT
FROM MATDOC
WHERE AUFNR = '{orden}'
ORDER BY CPUDT, MBLNR
```

### MKPF + MSEG (ECC — legacy)
```sql
-- Cabecera
SELECT MBLNR, MJAHR, BUDAT, CPUDT, USNAM FROM MKPF WHERE MBLNR = '{doc}'
-- Posiciones
SELECT MBLNR, MJAHR, ZEESSION, BWART, MATNR, WERKS, LGORT, MENGE, AUFNR
FROM MSEG WHERE MBLNR = '{doc}' AND MJAHR = '{year}'
```

## GI — Salida de mercancias (261)

### Manual (MIGO)
1. MIGO → Goods Issue → Order
2. Seleccionar orden produccion
3. Sistema propone componentes de RESB (reservas)
4. Confirmar cantidades y almacen
5. Contabilizar

### Backflush automatico
- Se ejecuta durante confirmacion (CO11N/CO15)
- Componentes con indicador backflush (RESB-XWAOK = 'X')
- Cantidad consumida = (Qty confirmada / Qty base BOM) × Qty componente BOM
- Componentes asignados a la operacion confirmada

### Configuracion backflush
- **Por componente BOM**: CS02 → posicion → indicador backflush
- **Por material**: MARC-RGEKZ (indicador backflush)
- **Por puesto de trabajo**: CRHD → indicador backflush
- **Prioridad**: Componente BOM > Material > Puesto trabajo

## GR — Entrada de mercancias (101)

### Manual (MIGO)
1. MIGO → Goods Receipt → Order
2. Indicar orden produccion
3. Cantidad recibida
4. Almacen destino (AFPO-LGORT o input manual)
5. Contabilizar

### Automatica con CO15
- Confirmacion CO15 genera GR automaticamente
- Cantidad GR = cantidad confirmada (yield)

### Valoracion
- Producto se valora a precio estandar (MBEW-STPRS)
- Diferencia entre coste real acumulado y valor estandar → varianza (en cierre)

## COGI — Errores de movimientos automaticos

Cuando un movimiento automatico (backflush) falla, se registra en COGI para reprocesamiento manual.

### Causas frecuentes COGI
| Causa | Descripcion | Solucion |
|-------|-------------|----------|
| Sin stock | Stock insuficiente para GI | Ajustar stock o transferir |
| Sin lote | Material con gestion lotes sin lote asignado | Asignar lote en COGI |
| Sin almacen | Almacen no definido | Indicar almacen |
| Material bloqueado | Material en control calidad | Liberar o decision de uso |

### Reprocesamiento COGI
1. COGI → seleccionar errores
2. Corregir datos (stock, lote, almacen)
3. Reprocesar → genera movimiento pendiente
4. Verificar exito

```sql
-- Errores COGI pendientes
SELECT AUFNR, MATNR, WERKS, LGORT, BWART, ERFMG, GRUND
FROM COGI
WHERE AUFNR = '{orden}'
```

## Reservas — RESB

La orden de produccion genera reservas automaticas para cada componente BOM.

```sql
SELECT RSNUM, RSPOS, MATNR, BDMNG, ENMNG, ERFMG,
       WERKS, LGORT, BWART, VORNR, XWAOK, KZEAR, XLOEK
FROM RESB
WHERE AUFNR = '{orden}'
```

| Campo | Descripcion |
|-------|-------------|
| BDMNG | Cantidad necesaria |
| ENMNG | Cantidad retirada |
| XWAOK | Indicador backflush |
| KZEAR | Completamente retirado |
| XLOEK | Posicion borrada |

## Impacto contable

### GI 261 (consumo componentes)
```
Debe: Consumo produccion (clase coste) → Orden produccion
Haber: Stock material (BSX)
```

### GR 101 (entrada producto terminado)
```
Debe: Stock material (BSX) — a precio estandar
Haber: Produccion (GBB-AUF) → Orden produccion
```

### Varianza (al cierre)
```
Coste real acumulado en orden - Entregas a estandar = Varianza
→ Settlement (CO88) → cuentas varianza
```

## Consultas MCP diagnostico

```sql
-- Movimientos de una orden (S/4)
SELECT BWART, MATNR, MENGE, MEINS, BUDAT, MBLNR
FROM MATDOC WHERE AUFNR = '{orden}' ORDER BY BUDAT

-- Componentes con pendiente de retiro
SELECT RSPOS, MATNR, BDMNG, ENMNG, (BDMNG - ENMNG) AS PENDIENTE, XWAOK
FROM RESB WHERE AUFNR = '{orden}' AND KZEAR = '' AND XLOEK = ''

-- Stock disponible de componente
SELECT LGORT, LABST, INSME, SPEME FROM MARD
WHERE MATNR = '{componente}' AND WERKS = '{centro}'
```
