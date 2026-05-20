# Inventario y Gestion de Stock

## Tipos de stock

| Tipo | Campo MARD | Descripcion | Disponible para uso |
|------|-----------|-------------|:-------------------:|
| Libre utilizacion | LABST | Stock normal disponible | Si |
| En calidad | INSME | Pendiente inspeccion QM | No |
| Bloqueado | SPEME | Retenido manualmente | No |
| En transito | TRAME | Entre centros (STO) | No |
| En devolucion | RETME | Pendiente devolucion prov. | No |

## Stock especial

| Tipo | Codigo | Descripcion | Tabla |
|------|--------|-------------|-------|
| Consignacion (vendor) | K | Stock del proveedor en nuestro almacen | MKOL |
| Subcontratacion | O | Componentes en casa del proveedor | MSLB |
| Pipeline | — | Suministro continuo (agua, gas) | — |
| Stock en transito | T | Material entre centros | MSKU |
| Stock proyecto | Q | Asignado a proyecto WBS | MSPR |
| Stock pedido cliente | E | Reservado para pedido SD | MSKA |

### Queries MCP
```sql
-- Stock completo de un material
SELECT MATNR, WERKS, LGORT, LABST, INSME, SPEME, RETME
FROM MARD WHERE MATNR = '{material}'

-- Stock total por centro (sin almacen)
SELECT MATNR, WERKS, LABST, INSME, SPEME
FROM MARC WHERE MATNR = '{material}'

-- Consignacion
SELECT MATNR, WERKS, LGORT, LIFNR, SLABS, SINSM, SSPER
FROM MKOL WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Stock en transito
SELECT MATNR, WERKS, TRAME FROM MARC WHERE MATNR = '{material}'

-- Stock de subcontratacion
SELECT MATNR, WERKS, LIFNR, SLABS FROM MSLB
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

## Gestion de Lotes (Batch Management)

### Activacion
```
SPRO → Logistics General → Batch Management →
  Specify Batch Level: mandante, centro, o material

Nivel centro (recomendado): cada centro tiene sus propios lotes
Nivel mandante: lote unico across centros
```

### Tablas
| Tabla | Contenido |
|-------|-----------|
| MCHA | Lotes por material y centro |
| MCH1 | Datos generales del lote |
| MCHB | Stock por lote y almacen |
| MCHBH | Historico stock por lote |

### Clasificacion de lotes
- Cada lote se clasifica con caracteristicas (fecha produccion, origen, calidad)
- Batch determination automatica en GR, GI, PO (via strategy type)
- Config: SPRO → Logistics → Batch Management → Batch Determination

### Queries MCP
```sql
-- Lotes de un material
SELECT MATNR, WERKS, CHARG, ERSDA, HSDAT, VFDAT, ZUESSION
FROM MCHA WHERE MATNR = '{material}' AND WERKS = '{centro}'
-- HSDAT=fecha fabricacion, VFDAT=fecha vencimiento

-- Stock por lote
SELECT MATNR, WERKS, LGORT, CHARG, CLABS, CINSM, CSPER
FROM MCHB WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

## Numeros de Serie

### Activacion
```
Material master (MM02) → General/Plant → Serial number profile
Perfil de numero de serie: determina CUANDO se requiere (en GR, GI, o ambos)
```

### Perfiles estandar
| Perfil | Cuando pide numero serie |
|--------|-------------------------|
| 0001 | Siempre (GR + GI) |
| 0002 | Solo en GI (salida) |
| 0003 | Solo en GR (entrada) |
| Z001 | Custom |

### Tablas
| Tabla | Contenido |
|-------|-----------|
| EQUI | Datos del equipo (si se crea equipo) |
| SER01 | Numeros de serie en doc entrega |
| SER03 | Numeros de serie en doc material |
| SERI | Numeros de serie header |

## Inventario Fisico (Physical Inventory)

### Proceso completo
```
1. MI01 → Crear documento de inventario
   (seleccionar centro, almacen, fecha, materiales)

2. MI04 → Entrar recuento (cantidades contadas)
   (opcion: doble recuento si hay discrepancia)

3. MI20 → Lista de diferencias
   (revisar variaciones vs stock sistema)

4. MI07 → Contabilizar diferencias
   (genera tipo movimiento 701/702)
   TM 701 = diferencia positiva (encontramos mas)
   TM 702 = diferencia negativa (falta stock)
```

### Transacciones completas
| TCode | Accion |
|-------|--------|
| MI01 | Crear doc inventario |
| MI02 | Modificar doc inventario |
| MI03 | Visualizar doc inventario |
| MI04 | Entrar recuento |
| MI05 | Modificar recuento |
| MI06 | Lista docs inventario |
| MI07 | Contabilizar diferencias |
| MI08 | Crear doc inv. con datos previos |
| MI09 | Entrar recuento sin referencia doc |
| MI10 | Crear doc inv. por lote |
| MI11 | Recuento por lote |
| MI20 | Lista de diferencias |
| MI21 | Imprimir doc inventario |
| MI31 | Crear doc inv. para vendor consignacion |
| MI33 | Visualizar doc inv. consignacion |
| MI34 | Entrar recuento consignacion |
| MI37 | Contabilizar dif. consignacion |
| MI39 | Lista docs inv. consignacion |
| MI40 | Lista dif. consignacion |
| MIDO | Inventario ciclico |

### Tipos de inventario
| Tipo | Descripcion | Cuando usar |
|------|-------------|-------------|
| Periodico | Una vez al ano (fin fiscal) | Obligatorio legal |
| Continuo | Durante el ano, materiales rotativos | Grandes almacenes |
| Ciclico | Frecuencia por valor ABC | Best practice |
| Muestreo | % aleatorio del stock | Auditorias intermedias |

### Tablas
| Tabla | Contenido |
|-------|-----------|
| IKPF | Cabecera doc inventario |
| ISEG | Posiciones doc inventario |

### Queries MCP
```sql
-- Documentos de inventario abiertos
SELECT IBLNR, GJAHR, WERKS, LGORT, BLDAT, GIESSION
FROM IKPF WHERE WERKS = '{centro}' AND XSTAT = ''

-- Diferencias encontradas
SELECT IKPF.IBLNR, ISEG.ZEESSION, ISEG.MATNR, ISEG.MENGE, ISEG.ERFMG, ISEG.DIFFERENZ
FROM IKPF JOIN ISEG ON IKPF.IBLNR = ISEG.IBLNR AND IKPF.GJAHR = ISEG.GJAHR
WHERE IKPF.WERKS = '{centro}' AND ISEG.DIFFERENZ <> 0
```

## Reservas (MB21)

```
MB21 → Crear reserva manual
MB22 → Modificar reserva
MB23 → Visualizar reserva
MB24 → Lista de reservas
MB25 → Reservas por material (pendientes)

Tabla: RKPF (cabecera) + RESB (posiciones)
Tipo movimiento: 201 (consumo), 261 (orden produccion), 301 (traslado)
```

## Valoracion Split (Split Valuation)

Permite valorar un mismo material con diferentes precios segun categoria:

```
Ejemplo: Material ACERO
  Categoria "NACIONAL":  Precio $100/kg
  Categoria "IMPORTADO": Precio $150/kg

Config: OMWC → Activar split valuation
Material: MM02 → Contabilidad → Tipo valoracion

Tablas: MBEW (un registro por categoria de valoracion)
```
