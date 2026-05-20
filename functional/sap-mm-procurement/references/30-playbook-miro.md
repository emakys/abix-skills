# SAP MM — Playbook de Troubleshooting MIRO / Logistics Invoice Verification

## Objetivo

Diagnosticar errores en MIRO, MRBR, facturas bloqueadas, tolerancias, GR/IR y determinacion de cuentas.

---

# Sintomas comunes

- No permite contabilizar factura.
- Factura queda bloqueada.
- Diferencia de precio o cantidad.
- Error de determinacion de cuentas.
- No encuentra entrada de mercancias.
- PO no disponible para facturar.
- Mensajes M8* o MR*.

---

# Flujo de diagnostico

## 1. Identificar datos base

Pedir o extraer:

- Sociedad.
- Proveedor/BP.
- Pedido de compra.
- Ejercicio.
- Documento de factura.
- Mensaje SAP exacto.
- Moneda e importe.

## 2. Revisar PO e historial

```sql
SELECT * FROM EKKO WHERE EBELN = '<PO>';
SELECT * FROM EKPO WHERE EBELN = '<PO>';
SELECT * FROM EKBE WHERE EBELN = '<PO>' ORDER BY EBELP, VGABE, BUDAT;
```

Validar:

- PO liberado.
- Indicador GR-based IV.
- Entrada de mercancias existente.
- Cantidad recibida vs facturada.
- Reversos 102/122.
- Historial EKBE coherente.

## 3. Revisar factura

```sql
SELECT * FROM RBKP WHERE BELNR = '<INV_DOC>' AND GJAHR = '<YEAR>';
SELECT * FROM RSEG WHERE BELNR = '<INV_DOC>' AND GJAHR = '<YEAR>';
```

Validar:

- Estado de bloqueo.
- Clave de bloqueo.
- Diferencia de precio.
- Diferencia de cantidad.
- Referencia a PO/item.

## 4. Revisar tolerancias

SPRO:

```text
Materials Management → Logistics Invoice Verification → Incoming Invoice → Set Tolerance Limits
```

TCode:

```text
OMR6
```

Tablas:

```sql
SELECT * FROM T169G WHERE BUKRS = '<BUKRS>';
```

Claves comunes:

| Clave | Uso |
|---|---|
| PP | Price variance |
| DQ | Quantity variance |
| DW | Quantity variance when GR quantity = zero |
| BD | Small differences automatically accepted |
| VP | Moving average price variance |
| BR | Percentage OPUn variance |

## 5. Revisar determinacion de cuentas

Si el error es M8 580 o similar:

SPRO/TCode:

```text
OBYC
```

Tablas:

```sql
SELECT * FROM T030 WHERE KTOPL = '<CHART_OF_ACCOUNTS>';
```

Claves relevantes:

| Clave | Uso |
|---|---|
| WRX | GR/IR clearing |
| BSX | Inventory posting |
| PRD | Price differences |
| GBB | Offsetting entry inventory posting |
| FRE | Freight clearing |

Validar:

- Plan de cuentas.
- Area de valoracion.
- Valuation grouping code.
- Clase de valoracion.
- Categoria de cuenta.

---

# Diagnostico por mensaje

| Mensaje | Causa raiz probable | Evidencia | Solucion |
|---|---|---|---|
| M8 351 | Tolerancia excedida | RSEG/EKBE/T169G | Revisar OMR6 o corregir factura/GR |
| M8 580 | Cuenta no determinada | EKPO/MARC/T030 | Configurar OBYC |
| MR 020 | Factura bloqueada | RBKP/RSEG | Liberar MRBR o corregir diferencia |
| M8 147 | PO sin GR esperado | EKBE/EKPO | Verificar GR-based IV y entrada 101 |
| M8 504 | Diferencia no permitida | RBKP/RSEG/T169G | Ajustar tolerancia o datos factura |

---

# Causas raiz frecuentes

## Caso A — No hay entrada de mercancias

Evidencia:

- EKBE no tiene VGABE = 1.
- EKPO tiene GR-based IV activo.

Accion:

1. Contabilizar GR en MIGO.
2. Reintentar MIRO.
3. Si no debe exigir GR, revisar indicador GR-based IV en PO/info record/material.

## Caso B — Diferencia de precio

Evidencia:

- Valor factura > valor PO/GR.
- Clave PP excedida en OMR6.

Accion:

1. Validar precio PO.
2. Validar condiciones PB00, freight, impuestos.
3. Corregir factura o PO si procede.
4. Ajustar OMR6 solo si es politica de negocio.

## Caso C — Diferencia de cantidad

Evidencia:

- Cantidad facturada > cantidad recibida.
- EKBE muestra GR menor o reversado.

Accion:

1. Contabilizar entrada faltante.
2. Corregir cantidad factura.
3. Revisar tolerancia DQ/DW.

## Caso D — Falta cuenta GR/IR

Evidencia:

- Mensaje M8 580.
- T030 sin WRX para combinacion.

Accion:

1. Revisar OBYC clave WRX.
2. Validar clase de valoracion del material.
3. Validar valuation grouping code.
4. Transportar configuracion.

---

# Respuesta tipo

```markdown
## Diagnostico MIRO
La causa raiz probable es <causa>. El bloqueo/error se origina en <tolerancia/cuenta/historial>.

## Evidencia
- PO:
- EKBE:
- RBKP/RSEG:
- Tolerancia OMR6:
- OBYC/T030:

## Solucion
1.
2.
3.

## Validacion
- Reintentar MIRO.
- Verificar RBKP/RSEG.
- Si queda bloqueada, revisar MRBR.

## Impacto
- FI: afecta GR/IR, diferencias de precio, cuentas automaticas.
- MM: afecta historial de pedido EKBE.
```
