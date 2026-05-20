# Guias de Configuracion IMG — MM Paso a Paso

## 1. Crear tipo de documento de compra custom (ZNB)

```
Ruta: SPRO → Materials Management → Purchasing → Purchase Order →
      Define Document Types

Transaccion directa: OME2

Pasos:
1. Copiar tipo NB (estandar) → ZNB
2. Campos a configurar:
   - Tipo doc: ZNB
   - Texto: "Pedido compra custom"
   - Rango numeros: asignar (NRSN) — usar rango Z
   - Categoria doc (BSTYP): F (purchase order)
   - Item interval: 10 (numeracion posiciones)
   - Update group: 0000 (estadisticas)

3. Campos de control:
   - Info record required (INFKZ): ' ' o 'X'
   - Source list required (SRCLIST): ' ' o 'X'
   - GR-based IV (WEBRE): 'X' (recomendado)
   - Allowed item categories: definir en T163

4. Grabar y transportar
```

## 2. Crear rango de numeros para PO

```
Ruta: SPRO → Materials Management → Purchasing → Purchase Order →
      Define Number Ranges

Transaccion directa: OMH6

Pasos:
1. Seleccionar rango de numeros
2. Crear intervalo:
   - Numero: 01 (o Z1 para custom)
   - De: 4500000000
   - Hasta: 4599999999
   - Externo: ' ' (numeros internos = automaticos)

3. Asignar rango al tipo documento:
   Tipo ZNB → Rango 01 (o Z1)

4. Verificar: crear PO con ZNB → debe asignar numero automatico
```

## 3. Configurar Release Strategy para PO

```
Ruta: SPRO → Materials Management → Purchasing → Purchase Order →
      Release Procedure for Purchase Orders →
      Define Release Procedure for Purchase Orders

Pasos detallados:

PASO 1 — Caracteristicas (CT04)
  Crear: Z_MM_PO_BSART (tipo documento)
    - Tipo dato: CHAR, longitud 4
    - Tabla valores: T161 (o valores fijos NB, ZNB, FO)

  Crear: Z_MM_PO_GSWRT (valor total)
    - Tipo dato: NUM, longitud 15, decimales 2
    - Sin tabla (rango libre)

  Crear: Z_MM_PO_EKORG (org compras)
    - Tipo dato: CHAR, longitud 4
    - Tabla valores: T024E

PASO 2 — Clase (CL02)
  Crear: Z_MM_PO_REL
    - Tipo clase: 032
    - Asignar caracteristicas: Z_MM_PO_BSART, Z_MM_PO_GSWRT, Z_MM_PO_EKORG

PASO 3 — Release Groups (SPRO)
  Crear grupo: 01 "Compras generales"

PASO 4 — Release Codes (SPRO)
  Dentro del grupo 01:
    CP - "Comprador"
    JC - "Jefe Compras"
    GF - "Gerente Financiero"

PASO 5 — Release Strategies (SPRO)
  Crear:
    Z1 - "PO < 25k" → solo CP
    Z2 - "PO 25k-100k" → CP + JC
    Z3 - "PO > 100k" → CP + JC + GF

  Para cada strategy:
    - Asignar grupo de release
    - Asignar codigos (secuencia)
    - Definir prerequisitos (JC requiere CP primero)
    - Release statuses

PASO 6 — Clasificar strategies (CL02 o SPRO)
  Z1: BSART=NB, GSWRT=0-24999.99, EKORG=1000
  Z2: BSART=NB, GSWRT=25000-99999.99, EKORG=1000
  Z3: BSART=NB, GSWRT=100000-999999999, EKORG=1000

PASO 7 — Verificar
  ME21N → crear PO tipo NB, valor $30,000
  → debe asignar strategy Z2
  → ME28 → liberar con codigo CP, luego JC
```

## 4. Configurar determinacion cuentas automaticas (OBYC)

```
Ruta: SPRO → Materials Management → Valuation and Account Assignment →
      Account Determination → Account Determination Without Wizard →
      Configure Automatic Postings

Transaccion directa: OBYC

Pasos:
1. Seleccionar clave de transaccion:
   BSX = Stock material
   WRX = GR/IR clearing
   PRD = Diferencia de precio
   GBB = Offsetting entry (consumo)

2. Para BSX (cuenta de stock):
   - Plan cuentas: CALA (o el del cliente)
   - Clase valoracion: 3000 (materia prima)
   - Cuenta: 300000 (cuenta de inventario)
   - Clase valoracion: 3100 (producto terminado)
   - Cuenta: 310000

3. Para WRX (GR/IR clearing):
   - Cuenta unica: 191000 (sin clase valoracion)

4. Para GBB (consumo):
   - Modificacion valoracion: VBR (consumo general)
   - Cuenta: 400000 (gasto material)
   - Modificacion valoracion: AUF (a orden produccion)
   - Cuenta: 810000

5. Verificar: MIGO → GR vs PO → revisar asiento en FI (FB03)
```

## 5. Configurar tolerancias de factura (OMR6)

```
Ruta: SPRO → Materials Management → Logistics Invoice Verification →
      Invoice Block → Set Tolerance Limits

Transaccion directa: OMR6 (por sociedad) / OMRM (global)

Pasos:
1. Seleccionar sociedad: 1000
2. Definir tolerancias:

   AN (Monto absoluto por item):
     Limite inferior: -100.00
     Limite superior: 100.00
     Moneda: USD

   AP (Porcentaje por item):
     Limite inferior: -5%
     Limite superior: 5%

   DW (Cantidad GR):
     Tolerancia: 5% (diferencia cantidad)

   PP (Precio por item):
     Limite inferior: -10%
     Limite superior: 10%

   BD (Diferencias pequeinas):
     Monto: 10.00 (auto-aceptar si diferencia < 10)

3. Grabar → transportar
4. Verificar: MIRO con diferencia de 3% → debe contabilizar sin bloqueo
             MIRO con diferencia de 12% → debe bloquear
```

## 6. Configurar condiciones de pago (OBB8)

```
Ruta: SPRO → Financial Accounting → AP → Incoming Invoices →
      Maintain Terms of Payment

Transaccion directa: OBB8

Pasos:
1. Crear condicion de pago:
   Clave: Z030
   Descripcion: "30 dias neto"

   Block 1 (dia fijo): vacio
   Day limit: vacio

   Payment terms:
   - Percent: 0 (sin descuento)
   - No. of days: 30
   - Net: 30

2. Con descuento pronto pago:
   Clave: Z210
   Descripcion: "2% 10 dias, neto 30"

   Payment terms:
   - Line 1: Percent=2, No. of days=10
   - Line 2: Percent=0, No. of days=30 (baseline)
   - Net: 30

3. Asignar a proveedor: LFM1 (org compras) o LFB1 (sociedad)
```

## 7. Configurar tipos de movimiento custom (OMJJ)

```
Ruta: SPRO → Materials Management → Inventory Management →
      Movement Types → Copy, Change Movement Types

Transaccion directa: OMJJ

Pasos:
1. Copiar tipo movimiento estandar:
   Copiar 201 → Z01 (consumo custom)

2. Configurar campos:
   - Allowed: GR, GI, Transfer
   - Account modification: VBR (consumo)
   - Quantity update: S (actualizar stock)
   - Value update: V (actualizar valor)
   - Negative stock allowed: ' ' (no)
   - Automatic PO: ' '

3. Asignar cuentas en OBYC para el nuevo TM

4. Verificar: MIGO con TM Z01 → debe funcionar como 201
```

## 8. Configurar grupo de materiales (OMSF)

```
Ruta: SPRO → Logistics General → Material Master →
      Settings for Key Fields → Define Material Groups

Transaccion directa: OMSF

Pasos:
1. Crear grupo:
   - Grupo: Z001
   - Descripcion: "Materias primas metalicas"

2. Asignar a materiales en MM01/MM02 → vista Datos base 1

3. Uso:
   - Reporting (ME2C por grupo material)
   - Release strategy (criterio de liberacion)
   - Pricing (condicion por grupo material A018)
   - Analisis ABC
```

## Queries MCP para verificar configuraciones

```sql
-- Tipos de documento y su config
SELECT BSART, BSTYP, NUMKI, INFKZ, WESSION FROM T161 WHERE BSART LIKE 'Z%'

-- Rangos de numeros para POs
SELECT NRSN, NUMKI FROM T161 WHERE BSART = '{tipo}'

-- Tolerancias configuradas
SELECT BUKRS, TOESSION, UNTGR, OBESSION FROM T169G WHERE BUKRS = '{soc}'

-- Condiciones de pago
SELECT ZTERM, ZTAG1, ZPRZ1, ZTAG2, ZPRZ2, ZTAG3 FROM T052 WHERE ZTERM LIKE 'Z%'

-- Release strategies activas
SELECT FRGSX, FRGXT FROM T16FS WHERE SPRAS = 'E'

-- Cuentas automaticas OBYC
SELECT KTOSL, BKLAS, KONTS FROM T030
WHERE KTOPL = '{plan}' AND KTOSL IN ('BSX','WRX','PRD','GBB')
ORDER BY KTOSL, BKLAS
```
