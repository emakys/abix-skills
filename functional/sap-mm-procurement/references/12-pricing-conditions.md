# Pricing / Condiciones de Precio en Compras

## Concepto

SAP determina el precio de un pedido mediante un **esquema de calculo** (pricing procedure) que contiene tipos de condicion en secuencia. Cada tipo de condicion busca valores en tablas de condicion usando **secuencias de acceso**.

```
Esquema de calculo (RM0000)
    |
    +-- Paso 1: PB00 (Precio bruto)
    |   +-- Secuencia acceso: Proveedor+Material -> Proveedor+GrupoMat -> Contrato
    |
    +-- Paso 2: RA00 (Descuento %)
    |   +-- Secuencia acceso: Proveedor+Material -> Proveedor
    |
    +-- Paso 3: FRA1 (Flete %)
    |
    +-- Paso 4: NAVS (IVA)
    |
    = TOTAL = PB00 - RA00 + FRA1 + NAVS
```

## Esquemas de calculo estandar

| Esquema | Descripcion | Uso |
|---------|-------------|-----|
| RM0000 | Compras domesticas | El mas comun |
| RM0001 | Compras importacion | Con costes de aduanas |
| RM0002 | Compras con plan entregas | Scheduling agreements |
| RM0003 | Subcontratacion | Con componentes provistos |

### Asignacion de esquema
```
Esquema se determina por: Org compras (T024E-KALSY) + Vendor schema group (LFM1-KALSK)
Config: SPRO → MM → Purchasing → Conditions → Define Price Determination Process
Tablas: T683S (esquemas), T683V (asignacion)
```

## Tipos de condicion estandar

### Precios base
| Tipo | Descripcion | Manual/Auto | Tabla condicion |
|------|-------------|:-----------:|-----------------|
| PB00 | Precio bruto info record | Auto | A017 (prov+mat), A018 (prov+grp mat) |
| PBXX | Precio bruto manual | Manual | — (se introduce en PO) |
| P000 | Precio de contrato | Auto | A016 (contrato) |

### Descuentos
| Tipo | Descripcion | Calculo |
|------|-------------|---------|
| RA00 | Descuento % header | % sobre valor total |
| RA01 | Descuento % posicion | % sobre posicion |
| RB00 | Descuento absoluto | Monto fijo |
| RC00 | Descuento por cantidad | Escalas por cantidad |

### Recargos
| Tipo | Descripcion | Calculo |
|------|-------------|---------|
| FRA1 | Flete porcentual | % sobre valor |
| FRB1 | Flete absoluto | Monto fijo por PO |
| FRC1 | Flete por cantidad | Monto por unidad |
| ZOA1 | Seguro | % o fijo |
| KF00 | Cargo posterior (invoice) | Post-GR adjustment |

### Impuestos
| Tipo | Descripcion |
|------|-------------|
| NAVS | IVA no deducible |
| NAVM | IVA deducible (se descuenta del coste) |
| MWST | IVA estandar (FI) |

## Secuencias de acceso

Determinan en que orden SAP busca el precio:

### Secuencia para PB00 (precio bruto)
```
Paso 1: Tabla A017 → Proveedor + Material + Org compras + Centro
Paso 2: Tabla A018 → Proveedor + Grupo material + Org compras
Paso 3: Tabla A019 → Proveedor + Org compras
(Primera que encuentra = precio usado)
```

### Config
```
Transaccion: M/07 (secuencias acceso)
Transaccion: M/06 (tipos condicion y esquemas)
Transaccion: MEK1/MEK2 (mantener condiciones directamente)
```

## Escalas de precio

| Tipo escala | Ejemplo | Configuracion |
|-------------|---------|---------------|
| Por cantidad | 1-100: $10, 101-500: $9, 500+: $8 | En tipo condicion, flag STAFFL |
| Por valor | <$1000: 5% dto, >$1000: 10% dto | En tipo condicion |
| Temporal | Ene-Mar: $10, Abr-Jun: $9 | Validez en registro condicion |

## Condiciones a nivel Header vs Item

| Nivel | Cuando usar | Ejemplo |
|-------|-------------|---------|
| Header | Aplica a todo el PO | Descuento global 5%, flete total |
| Item | Aplica por posicion | Precio unitario, descuento por material |

```
Header conditions: flag KHERG en tipo condicion
Distribution: KVSL1 (reparticion a posiciones por valor/cantidad/partes iguales)
```

## Queries MCP

```sql
-- Esquema de calculo asignado a la org compras
SELECT EKORG, KALSY FROM T024E WHERE EKORG = '{org_compras}'

-- Esquema del proveedor
SELECT LIFNR, EKORG, KALSK FROM LFM1 WHERE LIFNR = '{proveedor}' AND EKORG = '{org_compras}'

-- Tipos condicion en un esquema
SELECT KVEWE, KAPPL, KALSM, STUNR, KSCHL, KZBZG, KOPTS
FROM T683S WHERE KALSM = 'RM0000' ORDER BY STUNR

-- Condiciones vigentes para proveedor+material
SELECT KNUMH, DATAB, DATBI, LIFNR, MATNR, EKORG, WERKS
FROM A017 WHERE LIFNR = '{prov}' AND MATNR = '{mat}' AND EKORG = '{org}'

-- Valor de una condicion
SELECT KNUMH, KSCHL, KBETR, KONWA, KPEIN, KMEIN, STFKZ
FROM KONP WHERE KNUMH = '{knumh}'
```

## Errores comunes de pricing

| Error | Causa | Fix |
|-------|-------|-----|
| Precio 0 en PO | Sin info record ni condicion manual | ME11 crear o introducir PBXX |
| Condicion no encontrada | Secuencia acceso no match | M/07 revisar secuencia |
| Esquema incorrecto | Mal asignacion org compras/vendor | T024E-KALSY o LFM1-KALSK |
| Descuento no aplica | Tipo condicion inactivo o sin vigencia | MEK2 verificar validity |
| IVA incorrecto | Tax code mal asignado | FTXP revisar codigo impuesto |
