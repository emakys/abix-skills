# Arboles de Decision — MM Procurement

## 1. Tipo de aprovisionamiento

```
Que se necesita comprar?
|
+-- Material fisico
|   +-- Es para produccion (materia prima)?
|   |   +-- SI -> MRP activo (DISMM=PD/VB)
|   |   |   +-- Punto pedido -> VB (stock seguridad + consumo)
|   |   |   +-- Planificacion -> PD (MPS/MRP con forecast)
|   |   +-- NO -> MRP manual o sin MRP
|   |       +-- Material recurrente -> Solicitud pedido manual (ME51N)
|   |       +-- Material puntual -> Pedido directo (ME21N)
|   |
|   +-- Es para reventa?
|   |   +-- SI -> Tipo material HAWA, MRP activo
|   |   +-- Compra bajo pedido -> Sin stock, imputacion a pedido SD
|   |
|   +-- Es consignacion?
|   |   +-- SI -> Tipo posicion K, proveedor mantiene stock
|   |   +-- Liquidacion periodica MRKO
|   |
|   +-- Es subcontratacion?
|       +-- SI -> Tipo posicion L, provision componentes
|       +-- Controlar consumo componentes ME2O
|
+-- Servicio
|   +-- Servicio puntual -> Pedido con cat. posicion D + hoja servicio ML81N
|   +-- Servicio recurrente -> Contrato marco MK + pedido con referencia
|   +-- Servicio profesional -> Pedido con imputacion K (centro coste)
|
+-- Activo fijo
    +-- Pedido con imputacion A (activo fijo)
    +-- ANLN1 (numero activo) obligatorio en posicion
```

## 2. Tipo de documento de compra

```
Que relacion comercial?
|
+-- Compra puntual -> NB (Pedido estandar)
|
+-- Acuerdo a largo plazo con cantidad/importe tope?
|   +-- Con entregas programadas -> LP (Plan de entregas)
|   +-- Sin entregas fijas -> MK (Contrato marco)
|   +-- Con pedidos abiertos -> FO (Framework order)
|
+-- Traslado entre centros propios?
|   +-- SI -> UB (Stock Transfer Order)
|   +-- Con entrega SD -> NB + tipo posicion 7
|
+-- Pedido de devolucion?
    +-- RE (Devolucion a proveedor)
```

## 3. Release strategy (estrategia de liberacion)

```
Que criterios de aprobacion?
|
+-- Solo por valor
|   +-- < $5,000 -> Sin aprobacion
|   +-- $5,000-$25,000 -> 1 aprobador (jefe compras)
|   +-- $25,000-$100,000 -> 2 aprobadores (jefe + gerente)
|   +-- > $100,000 -> 3 aprobadores (jefe + gerente + director)
|
+-- Por valor + tipo material
|   +-- Material productivo -> Limites mas bajos (mas control)
|   +-- Material no productivo -> Limites mas altos (menos control)
|   +-- Servicios -> Aprobacion extra (compliance)
|
+-- Por valor + centro
|   +-- Centros criticos (produccion) -> Mas niveles
|   +-- Centros administrativos -> Menos niveles
|
+-- Configuracion:
    +-- T16FC: Grupos de liberacion (agrupan criterios)
    +-- T16FD: Codigos de liberacion (aprobadores)
    +-- T16FS: Estrategias (combinan grupo + condiciones)
    +-- Clasificacion: Caracteristicas = campos PO (valor, tipo doc, etc)
```

## 4. Valoracion de inventario

```
Que industria/necesidad?
|
+-- Manufactura
|   +-- Produccion en serie -> Precio estandar (S)
|   |   Ventaja: costes de produccion estables, desviaciones visibles
|   |
|   +-- Produccion por proyecto -> Precio promedio movil (V)
|       Ventaja: refleja coste real por lote
|
+-- Retail / Distribucion
|   +-- Precio promedio movil (V)
|   +-- Refleja precio real de compra
|
+-- Farmaceutica / Quimica
|   +-- Split valuation por lote
|   +-- Cada lote tiene su propio precio
|   +-- Config: OMWC (split valuation)
|
+-- Regla general:
    +-- Precio fluctua mucho -> V (promedio movil)
    +-- Precio estable/calculado -> S (estandar)
    +-- Necesita valorar por lote -> Split valuation
```

## 5. Determinacion de cuentas (OBYC)

```
Que tipo de movimiento?
|
+-- GR vs PO (101)
|   +-- D: BSX (cuenta stock) | C: WRX (cuenta GR/IR clearing)
|   +-- Si precio estandar: PRD (diferencia precio)
|
+-- Consumo a centro coste (201)
|   +-- D: GBB-VBR (consumo) | C: BSX (stock)
|
+-- Consumo a orden (261)
|   +-- D: GBB-AUF (orden produccion) | C: BSX (stock)
|
+-- Traslado entre centros (301)
|   +-- D: BSX destino | C: BSX origen
|
+-- Devolucion proveedor (122)
|   +-- D: WRX (GR/IR clearing) | C: BSX (stock)
|
+-- Para configurar OBYC necesitas:
    +-- Plan de cuentas (KTOPL de T001)
    +-- Grupo de valoracion (BKLAS de MBEW)
    +-- Clave de transaccion (BSX, WRX, GBB, etc)
```

## 6. Condiciones de pago

```
Que terminos de pago?
|
+-- Pago inmediato -> ZB00 (neto inmediato)
|
+-- Pago con plazo
|   +-- 30 dias neto -> ZN30
|   +-- 60 dias neto -> ZN60
|   +-- 90 dias neto -> ZN90
|
+-- Pago con descuento pronto pago
|   +-- 2% 10 dias, neto 30 -> Z210
|   +-- 3% 15 dias, neto 45 -> Z315
|
+-- Pago por letra de cambio -> ZWxx (con draft)
|
+-- Config: OBB8 (definir condiciones pago)
```

## 7. Esquema de precios (pricing)

```
Que condiciones de precio necesita?
|
+-- Precio base
|   +-- PB00: Precio bruto info record
|   +-- PBXX: Precio bruto pedido (manual)
|
+-- Descuentos
|   +-- RA00: Descuento % header
|   +-- RA01: Descuento % posicion
|   +-- RB00: Descuento absoluto
|
+-- Recargos/Fletes
|   +-- FRA1: Flete % sobre valor
|   +-- FRB1: Flete absoluto
|   +-- ZOA1: Seguro
|
+-- Impuestos
|   +-- NAVS: IVA no deducible
|   +-- MWST: IVA standard
|
+-- Esquema estandar: RM0000 (compras domesticas)
+-- Config: M/06 (esquemas) + M/07 (secuencias acceso)
```

## 8. Cuando usar MRP vs manual

```
Criterios para activar MRP:
|
+-- Volumen alto de materiales (>100) -> MRP obligatorio
+-- Demanda dependiente (produccion) -> MRP con BOM
+-- Lead times largos -> MRP con safety stock
+-- Demanda estacional -> MRP con forecast
|
Criterios para NO usar MRP:
|
+-- Compras esporadicas -> Solicitud manual
+-- Servicios -> Pedido directo
+-- Materiales unicos (proyectos) -> Pedido directo
+-- Menos de 20 materiales -> Manual es suficiente
|
Tipos MRP:
+-- VB: Punto de pedido (cuando stock < punto pedido)
+-- PD: MRP planificado (con PIR/forecast)
+-- VV: Punto pedido automatico (sistema calcula)
+-- ND: Sin MRP (no genera propuestas)
```
