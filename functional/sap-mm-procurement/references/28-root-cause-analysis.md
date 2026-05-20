# SAP MM — Root Cause Analysis Framework

## Objetivo

Convertir cualquier pregunta o incidente MM en un diagnostico funcional estructurado, con causa raiz probable, evidencia, impacto y accion correctiva.

---

# Principio rector

No responder solo con teoria. Ante errores o comportamientos inesperados, seguir este flujo:

```text
Sintoma -> Proceso -> Documento -> Datos maestros -> Customizing -> Codigo/Mensaje -> Causa raiz -> Solucion -> Validacion
```

---

# Plantilla obligatoria de diagnostico

## 1. Sintoma

Identificar:

- Transaccion o app: ME21N, ME22N, ME28, MIGO, MIRO, MRBR, ME51N, ME5A.
- Mensaje SAP: clase + numero, por ejemplo M8 351, M7 032, ME 083.
- Documento: PR, PO, material document, invoice document.
- Objeto maestro: material, proveedor/BP, centro, sociedad, org compras.

## 2. Proceso MM afectado

Clasificar el incidente:

| Proceso | Indicadores |
|---|---|
| PR | EBAN, ME51N, liberacion solicitud |
| PO | EKKO, EKPO, ME21N, ME22N, ME29N |
| GR | MATDOC, MIGO, movimiento 101/102/122 |
| IV | RBKP, RSEG, MIRO, MRBR, M8/MR |
| Stock | MARD, MCHB, MMBE, MB52 |
| Pricing | KONV/PRCD_ELEMENTS, condiciones PB00, FRA1 |
| Release | FRGKE, FRGZU, T16F* |
| Account Determination | OBYC, T030, BSX/WRX/GBB/PRD |

## 3. Evidencia minima

### Si es pedido de compra

Consultar:

```sql
SELECT * FROM EKKO WHERE EBELN = '<PO>';
SELECT * FROM EKPO WHERE EBELN = '<PO>';
SELECT * FROM EKBE WHERE EBELN = '<PO>';
```

### Si es entrada de mercancias

S/4HANA:

```sql
SELECT * FROM MATDOC WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
```

ECC fallback:

```sql
SELECT * FROM MKPF WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
SELECT * FROM MSEG WHERE MBLNR = '<MAT_DOC>' AND MJAHR = '<YEAR>';
```

### Si es factura logistica

```sql
SELECT * FROM RBKP WHERE BELNR = '<INV_DOC>' AND GJAHR = '<YEAR>';
SELECT * FROM RSEG WHERE BELNR = '<INV_DOC>' AND GJAHR = '<YEAR>';
```

### Si es mensaje SAP

```sql
SELECT * FROM T100
 WHERE ARBGB = '<MSG_CLASS>'
   AND MSGNR = '<MSG_NUMBER>'
   AND SPRSL = 'E';
```

## 4. Causas raiz frecuentes por dominio

### Datos maestros

- Material no extendido a centro.
- Proveedor/BP no extendido a sociedad u organizacion de compras.
- Info record inexistente o incompleto.
- Source list obligatorio sin fuente valida.
- Material con vista de compras o contabilidad incompleta.

### Customizing

- Tipo de documento sin rango de numeros.
- Categoria de posicion no permitida.
- Tipo de movimiento bloqueado o mal configurado.
- Tolerancias MIRO incompletas.
- Determinacion de cuentas OBYC incompleta.
- Release strategy sin clasificacion correcta.

### Documento

- PO no liberado.
- GR no realizado o reversado.
- Cantidad facturada supera cantidad recibida.
- Historial EKBE inconsistente.
- Factura bloqueada por precio, cantidad o fecha.

### Integracion FI/CO

- Cuenta GR/IR no determinada.
- Centro de costo inexistente o bloqueado.
- Sociedad/centro sin asignacion correcta.
- Area de valoracion o clase de valoracion sin cuenta.

## 5. Niveles de confianza

Al responder, clasificar la conclusion:

| Nivel | Uso |
|---|---|
| Confirmado | Hay evidencia directa en tablas/customizing |
| Muy probable | Coincide con sintomas y reglas SAP |
| Posible | Requiere revisar mas datos |
| No concluyente | Falta documento, mensaje o customizing |

## 6. Formato recomendado de respuesta

```markdown
## Diagnostico
El proceso afectado es <proceso>. La causa raiz mas probable es <causa>.

## Evidencia
- Tabla/documento:
- Customizing:
- Mensaje SAP:

## Accion correctiva
1. Ir a <TCode/SPRO>.
2. Revisar <campo/valor>.
3. Corregir <configuracion/dato maestro/documento>.

## Validacion
- Reprocesar <transaccion/app>.
- Verificar <tabla/campo>.

## Impacto
- FI:
- CO:
- Logistica:
```

---

# Decision rapida por mensaje

| Mensaje | Causa raiz probable | Primer chequeo |
|---|---|---|
| M8* | Tolerancias, GR/IR, factura | RBKP/RSEG/EKBE/OMR6 |
| MR* | Bloqueo factura o LIV | RBKP/RSEG/MRBR |
| M7* | Movimiento mercancias | MATDOC/EKPO/OMJJ |
| ME* | Compras/documento PO | EKKO/EKPO/T161/T163 |
| 06* | Purchasing/customizing | T161/T163/T16F* |
| KI* | CO/imputacion | CSKS/CO object |
| F5* | FI/accounting | T030/ACDOCA |

---

# Regla de oro

Nunca recomendar cambiar customizing sin advertir:

- Que puede afectar otros documentos.
- Que debe probarse en QA.
- Que debe revisarse transporte.
- Que puede tener impacto FI/CO.
