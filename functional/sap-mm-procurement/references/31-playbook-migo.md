# SAP MM — Playbook de Troubleshooting MIGO / Goods Movement

## Objetivo

Diagnosticar errores en MIGO, entradas de mercancias, salidas, reversos, movimientos 101/102/122/201/261/311/501 y mensajes M7*.

---

# Sintomas comunes

- No permite contabilizar entrada de mercancias.
- Material no existe en centro.
- Stock insuficiente.
- Tipo de movimiento no permitido.
- No determina cuenta contable.
- Diferencia entre PO y GR.
- Error de lote, almacen o QM.

---

# Flujo de diagnostico

## 1. Identificar escenario

Clasificar movimiento:

| Movimiento | Escenario |
|---|---|
| 101 | GR contra PO / orden |
| 102 | Reverso GR |
| 122 | Devolucion a proveedor |
| 201 | Salida a centro de costo |
| 261 | Consumo a orden |
| 311 | Transferencia almacen a almacen |
| 501 | Entrada sin PO |
| 543 | Consumo componente subcontratacion |

## 2. Revisar material y centro

```sql
SELECT * FROM MARA WHERE MATNR = '<MATNR>';
SELECT * FROM MARC WHERE MATNR = '<MATNR>' AND WERKS = '<WERKS>';
SELECT * FROM MARD WHERE MATNR = '<MATNR>' AND WERKS = '<WERKS>' AND LGORT = '<LGORT>';
```

Validar:

- Material existe.
- Material extendido a centro.
- Almacen valido.
- Vista de compras/contabilidad activa cuando aplique.
- Unidad de medida.
- Lote obligatorio.

## 3. Revisar PO si movimiento es 101/102/122

```sql
SELECT * FROM EKKO WHERE EBELN = '<PO>';
SELECT * FROM EKPO WHERE EBELN = '<PO>';
SELECT * FROM EKBE WHERE EBELN = '<PO>';
```

Validar:

- PO liberado.
- Item no borrado/bloqueado.
- Cantidad pendiente.
- Indicadores GR/IR.
- Historial de reversos.

## 4. Revisar documento material

S/4HANA:

```sql
SELECT * FROM MATDOC WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
```

ECC fallback:

```sql
SELECT * FROM MKPF WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
SELECT * FROM MSEG WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
```

## 5. Revisar customizing tipo de movimiento

SPRO:

```text
Materials Management → Inventory Management and Physical Inventory → Movement Types → Copy, Change Movement Types
```

TCode:

```text
OMJJ
```

Tablas:

```sql
SELECT * FROM T156 WHERE BWART = '<BWART>';
SELECT * FROM T156X WHERE BWART = '<BWART>';
```

Validar:

- Movimiento permitido.
- Actualizacion cantidad/valor.
- Reverso permitido.
- Dependencia con stock especial.
- String de contabilizacion.

## 6. Revisar determinacion de cuentas

TCode:

```text
OBYC
```

Tablas:

```sql
SELECT * FROM T030 WHERE KTOPL = '<CHART_OF_ACCOUNTS>';
```

Claves comunes:

| Clave | Uso |
|---|---|
| BSX | Stock inventory posting |
| WRX | GR/IR clearing |
| GBB | Offsetting entry |
| PRD | Price difference |
| KON | Consignment liabilities |

---

# Diagnostico por mensaje

| Mensaje | Causa raiz probable | Primer chequeo | Solucion |
|---|---|---|---|
| M7 060 | Material no extendido al centro | MARC | Ampliar material MM01/MM02 |
| M7 021 | Stock insuficiente | MARD/MATDOC | Revisar stock, lote, almacen |
| M7 022 | Movimiento no permitido | T156/OMJJ | Ajustar/customizing o usar movimiento correcto |
| M7 032 | Info record/fuente faltante segun contexto | EINA/EINE/EORD | Crear fuente suministro |
| M7 309 | Documento no puede reversarse | MATDOC/EKBE | Revisar documento original y reversos |
| M8 580 | Cuenta no determinada en GR | T030/OBYC | Configurar cuenta automatica |

---

# Causas raiz frecuentes

## Caso A — Material no extendido al centro

Evidencia:

- Existe en MARA.
- No existe en MARC para WERKS.

Accion:

1. Ampliar material a centro en MM01/MM02.
2. Completar vistas obligatorias.
3. Reintentar MIGO.

## Caso B — Stock insuficiente

Evidencia:

- MARD muestra stock menor al requerido.
- Puede existir stock en otro almacen/lote/status.

Accion:

1. Revisar MMBE/MB52.
2. Validar lote y stock especial.
3. Corregir almacen/lote o hacer traslado.

## Caso C — PO no permite GR

Evidencia:

- EKPO-ELIKZ entrega final.
- Item borrado o bloqueado.
- PO sin liberacion.
- Cantidad abierta cero.

Accion:

1. Revisar ME23N historial.
2. Reabrir/corregir PO si procede.
3. Liberar PO si aplica.

## Caso D — Error contable al hacer GR

Evidencia:

- Mensaje de FI/MM account determination.
- T030 sin combinacion.

Accion:

1. Revisar OBYC.
2. Validar clase de valoracion material.
3. Validar area de valoracion y valuation grouping code.

---

# Respuesta tipo

```markdown
## Diagnostico MIGO
El error ocurre en el movimiento <BWART>. La causa raiz probable es <causa>.

## Evidencia
- Material/centro:
- PO/historial:
- Stock:
- Customizing OMJJ:
- OBYC:

## Solucion
1.
2.
3.

## Validacion
- Reintentar MIGO.
- Verificar MATDOC.
- Verificar EKBE si hay PO.
- Verificar FI document si contabiliza valor.

## Impacto
- MM: stock y historial de pedido.
- FI: inventario, GR/IR, diferencias.
- QM/WM/EWM: inspeccion y movimientos de almacen si aplica.
```
