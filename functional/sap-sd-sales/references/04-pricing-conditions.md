# Pricing SD — Condiciones de Precio

## Concepto

SD Pricing es MUCHO mas complejo que MM Pricing. Un esquema de calculo de ventas puede tener
50+ pasos con precios base, descuentos, recargos, fletes, impuestos, costes y margenes.

```
Esquema de calculo (Pricing Procedure)
    |
    +-- PR00 Precio bruto (base)
    +-- K004 Descuento por material
    +-- K005 Descuento por cliente
    +-- K007 Descuento por cliente+material
    +-- KA00 Descuento % manual
    +-- KF00 Flete
    +-- MWST Impuesto (IVA)
    +-- SKTO Descuento pronto pago
    +-- VPRS Coste material (para margen)
    = NETWR (valor neto)
    = Margen = NETWR - VPRS
```

## Elementos del pricing

### 1. Condition Type (Tipo de condicion)
```
Define QUE es la condicion: precio, descuento, recargo, impuesto, coste.

Config: V/06 (crear/modificar tipos condicion)

Atributos clave:
  - Clase condicion: A=descuento, B=precio, C=cargo, D=impuesto
  - Tipo calculo: %=porcentaje, A=monto, B=monto fijo, C=cantidad
  - Manual/automatico
  - Con/sin escalas
  - Header/item level
  - +/- (sumando o restando)
```

### Tipos condicion estandar SD
| Tipo | Descripcion | Clase | Calculo | Auto/Manual |
|------|-------------|-------|---------|:-----------:|
| PR00 | Precio base | B | Monto | Auto |
| PR01 | Precio bruto (manual) | B | Monto | Manual |
| K004 | Dto. material | A | % | Auto |
| K005 | Dto. cliente | A | % | Auto |
| K007 | Dto. cliente+material | A | % o monto | Auto |
| K020 | Dto. grupo precio+material | A | % | Auto |
| KA00 | Dto. % manual header | A | % | Manual |
| KF00 | Flete % | C | % | Auto |
| KF01 | Flete por cantidad | C | Por cantidad | Auto |
| MWST | Impuesto (IVA) | D | % | Auto |
| SKTO | Descuento pronto pago | A | % | Auto |
| VPRS | Coste material (stat.) | — | Interno | Auto |
| PI01 | Intercompany price | B | Monto | Auto |
| BO01 | Rebate (bonificacion) | A | % | Auto |
| HB00 | Rebate % por cliente | A | % | Auto |
| EK01 | Cash discount (deduction) | A | % | Auto |

### 2. Access Sequence (Secuencia de acceso)
```
Define DONDE buscar el valor de la condicion (en que orden de tablas).

Config: V/07 (crear/modificar secuencias acceso)

Ejemplo secuencia para K007 (dto cliente+material):
  Paso 1: Tabla A305 → Cliente + Material + Org ventas
  Paso 2: Tabla A304 → Cliente + Grupo material + Org ventas
  Paso 3: Tabla A303 → Grupo precio cliente + Material + Org ventas
  (Primera tabla que tenga valor = se usa)
```

### 3. Condition Table (Tabla de condicion)
```
Define la CLAVE de busqueda: que combinacion de campos determina el precio.

Config: V/03 (crear tablas condicion)

Tablas estandar SD:
  A004: Material + Org ventas + Canal
  A005: Cliente + Material + Org ventas
  A006: Grupo precio material + Org ventas
  A007: Grupo precio cliente + Grupo precio material + Org ventas
  A304: Cliente + Grupo material
  A305: Cliente + Material
  A900-A999: Custom (tablas Z)
```

### 4. Pricing Procedure (Esquema de calculo)
```
Define la SECUENCIA de tipos condicion y como se calculan.

Config: V/08 (crear/modificar esquemas)

Esquemas estandar:
  RVAA01: Ventas domesticas estandar
  RVAB01: Ventas exportacion
  RVAA03: Intercompany
```

### Campos del esquema (cada paso)
| Campo | Descripcion |
|-------|-------------|
| Step | Numero de paso |
| Counter | Sub-paso |
| CTyp | Tipo condicion (PR00, K007...) |
| From | Paso base para calculo % |
| To | Paso destino |
| Manual | Obligatorio/opcional/manual |
| Required | Obligatorio para grabar |
| Statistical | Solo informativo, no suma al total |
| SubTotal | Acumula en campo (1-6) para formulas |
| Requirement | Rutina de requirement (condicion para ejecutar) |
| AltCBV | Formula alternativa de calculo |
| AltCond | Tipo condicion alternativo |
| AccKey | Clave determinacion cuenta (ERL, ERS, etc.) |
| Accruals | Provision (para rebates) |

### Determinacion del esquema de calculo
```
Esquema = Org ventas (TVKO-KALKS) + Esquema cliente (KNVV-KALKS) + Esquema doc (TVAK-KALKS)

Config: SPRO → SD → Basic Functions → Pricing → Pricing Control →
  Define and Assign Pricing Procedures (OVKK)

Ejemplo:
  Org ventas KALKS = A + Cliente KALKS = 1 + Doc type KALKS = 1
  = OVKK busca combinacion A + 1 + 1 → Esquema RVAA01
```

## Mantener condiciones de precio

### Transacciones
| TCode | Accion | Nivel |
|-------|--------|-------|
| VK11 | Crear condicion | Individual |
| VK12 | Modificar condicion | Individual |
| VK13 | Visualizar condicion | Individual |
| VK31 | Crear condicion (rango) | Masivo |
| VK32 | Modificar condicion (rango) | Masivo |
| VK33 | Visualizar condicion (rango) | Masivo |
| V/LD | Pricing Report | Analisis |
| MEK1/MEK2 | Condiciones de compra | (MM, no SD) |

## Escalas de precio

```
Tipo escala en el tipo condicion:
  - Por cantidad: 1-100=$10, 101-500=$9, 501+=$8
  - Por valor: <$10k=5%dto, $10k-$50k=8%, >$50k=12%
  - Por peso/volumen: custom

Config: en el tipo condicion → Scale basis + Scale type
```

## Formulas y Requirements (rutinas ABAP)

```
Requirements: condiciones para que un paso se ejecute
  Rutina 2: Solo si el item es relevante para pricing
  Rutina 11: Solo exportacion
  Rutina 24: Solo si hay descuento pronto pago
  Custom: VOFM → Requirements → crear rutina Z

Formulas: calculo alternativo del valor
  Rutina 1: Cantidad * precio
  Rutina 2: Valor fijo
  Custom: VOFM → Formulas → crear rutina Z
```

## Queries MCP

```sql
-- Esquema pricing asignado
SELECT TVKO.VKORG, TVKO.KALSM FROM TVKO WHERE VKORG = '{org}'
SELECT KALKS FROM KNVV WHERE KUNNR = '{cl}' AND VKORG = '{org}'
SELECT KALKS FROM TVAK WHERE AUART = '{tipo_doc}'

-- Tipos condicion en un esquema
SELECT STUNR, ZAESSION, KSCHL, KVSL1, KOPTS, KSTAT, KRECH
FROM T683S WHERE KVEWE = 'A' AND KAPPL = 'V' AND KALSM = 'RVAA01'
ORDER BY STUNR

-- Condiciones vigentes para un material
SELECT KNUMH, DATAB, DATBI, KSCHL, VKORG, VTWEG, MATNR
FROM A004 WHERE VKORG = '{org}' AND VTWEG = '{canal}' AND MATNR = '{mat}'
AND DATBI >= '{hoy}'

-- Condiciones por cliente+material
SELECT KNUMH, DATAB, DATBI, KSCHL, KUNNR, MATNR
FROM A305 WHERE KUNNR = '{cl}' AND MATNR = '{mat}'

-- Valor de una condicion
SELECT KNUMH, KSCHL, KBETR, KONWA, KPEIN, KMEIN, STFKZ
FROM KONP WHERE KNUMH = '{knumh}'

-- Condiciones de un pedido especifico
SELECT KPOSN, STUNR, KSCHL, KBETR, KWERT, WAERS, KRECH, KSTAT
FROM KONV WHERE KNUMV = '{knumv}'
ORDER BY KPOSN, STUNR
```

## Errores comunes pricing

| Error | Causa | Fix |
|-------|-------|-----|
| Precio 0 | Sin condicion PR00 para ese material/org | VK11 crear |
| "Mandatory condition missing" | Condicion obligatoria en esquema | Crear condicion o quitar Required |
| Descuento no aplica | Secuencia acceso no matchea | V/07 revisar |
| IVA incorrecto | Tax code mal en cliente o material | VD02 o MM02 |
| Esquema no determinado | Combinacion KALKS no existe | OVKK verificar |
| Precio manual no editable | Tipo condicion sin flag Manual | V/06 activar |
