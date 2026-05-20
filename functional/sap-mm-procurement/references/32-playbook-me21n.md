# SAP MM — Playbook de Troubleshooting ME21N / Purchase Order

## Objetivo

Diagnosticar errores en creacion/modificacion/liberacion de pedidos de compra: ME21N, ME22N, ME23N, ME28, ME29N, Manage Purchase Orders.

---

# Sintomas comunes

- No permite crear pedido.
- Tipo de documento no permitido.
- Categoria de posicion invalida.
- Proveedor no extendido a organizacion de compras.
- Material no extendido a centro.
- Error en condiciones de precio.
- No determina fuente de aprovisionamiento.
- Estrategia de liberacion no se dispara.
- Pedido no puede liberarse.

---

# Flujo de diagnostico

## 1. Identificar datos base

- Tipo de documento: BSART.
- Sociedad: BUKRS.
- Org compras: EKORG.
- Grupo compras: EKGRP.
- Proveedor/BP: LIFNR/PARTNER.
- Material: MATNR.
- Centro: WERKS.
- Categoria posicion: PSTYP.
- Tipo imputacion: KNTTP.
- Mensaje SAP exacto.

## 2. Revisar cabecera e item PO

```sql
SELECT * FROM EKKO WHERE EBELN = '<PO>';
SELECT * FROM EKPO WHERE EBELN = '<PO>';
```

Campos clave:

| Campo | Significado |
|---|---|
| EKKO-BSART | Tipo documento |
| EKKO-EKORG | Org compras |
| EKKO-EKGRP | Grupo compras |
| EKKO-LIFNR | Proveedor |
| EKKO-FRGKE | Indicador liberacion |
| EKKO-FRGZU | Estado liberacion |
| EKPO-PSTYP | Categoria posicion |
| EKPO-KNTTP | Imputacion |
| EKPO-WERKS | Centro |
| EKPO-LOEKZ | Borrado |

## 3. Revisar proveedor/BP

S/4HANA:

```sql
SELECT * FROM BUT000 WHERE PARTNER = '<BP>';
SELECT * FROM LFA1 WHERE LIFNR = '<VENDOR>';
SELECT * FROM LFM1 WHERE LIFNR = '<VENDOR>' AND EKORG = '<EKORG>';
SELECT * FROM LFB1 WHERE LIFNR = '<VENDOR>' AND BUKRS = '<BUKRS>';
```

Validar:

- BP existe.
- Rol proveedor extendido.
- Extension a sociedad.
- Extension a organizacion de compras.
- Moneda y condiciones de pago.
- Bloqueos.

## 4. Revisar material

```sql
SELECT * FROM MARA WHERE MATNR = '<MATNR>';
SELECT * FROM MARC WHERE MATNR = '<MATNR>' AND WERKS = '<WERKS>';
SELECT * FROM MBEW WHERE MATNR = '<MATNR>' AND BWKEY = '<WERKS_OR_VAL_AREA>';
```

Validar:

- Material extendido al centro.
- Vista compras.
- Vista contabilidad.
- Clase de valoracion.
- Grupo de articulos.

## 5. Revisar source determination

```sql
SELECT * FROM EINA WHERE MATNR = '<MATNR>' AND LIFNR = '<VENDOR>';
SELECT * FROM EINE WHERE INFNR = '<INFNR>' AND EKORG = '<EKORG>';
SELECT * FROM EORD WHERE MATNR = '<MATNR>' AND WERKS = '<WERKS>';
SELECT * FROM EQUK WHERE MATNR = '<MATNR>' AND WERKS = '<WERKS>';
```

Validar:

- Info record.
- Source list obligatorio.
- Quota arrangement.
- Contrato o scheduling agreement.

## 6. Revisar customizing PO

### Tipo de documento

SPRO:

```text
Materials Management → Purchasing → Purchase Order → Define Document Types
```

Tablas:

```sql
SELECT * FROM T161 WHERE BSART = '<BSART>';
```

### Categoria de posicion

```sql
SELECT * FROM T163 WHERE PSTYP = '<PSTYP>';
```

### Tipo de imputacion

TCode:

```text
OME9
```

Tabla:

```sql
SELECT * FROM T163K WHERE KNTTP = '<KNTTP>';
```

## 7. Revisar liberacion

Tablas clasicas:

```sql
SELECT * FROM T16FG;
SELECT * FROM T16FC;
SELECT * FROM T16FD;
SELECT * FROM T16FS;
SELECT * FROM T16FV;
```

Validar:

- Grupo de liberacion.
- Codigo de liberacion.
- Estrategia.
- Caracteristicas/clase.
- Valores de clasificacion.
- Estado FRGKE/FRGZU en EKKO.

Para S/4HANA con Flexible Workflow:

- App: Manage Workflows for Purchase Orders.
- Revisar condiciones del workflow.
- Revisar agentes/responsables.
- Revisar estado en Manage Purchase Orders.

---

# Diagnostico por mensaje

| Mensaje | Causa raiz probable | Evidencia | Solucion |
|---|---|---|---|
| ME 083 | Proveedor no valido/extendido | LFM1/LFB1/BUT000 | Extender BP/proveedor |
| ME 013 | Categoria posicion no permitida | T163/T161 | Ajustar categoria/tipo doc |
| ME 045 | Material no existe o no extendido | MARA/MARC | Ampliar material |
| ME 062 | Fuente suministro no encontrada | EINA/EINE/EORD | Crear info record/source list |
| ME 206 | Pedido no liberado | EKKO/T16F* | Liberar ME28/ME29N o workflow |
| 06 436 | Tipo documento no definido | T161 | Configurar tipo documento |

---

# Causas raiz frecuentes

## Caso A — Proveedor no extendido

Evidencia:

- Existe LFA1/BUT000.
- Falta LFM1 para EKORG.
- Falta LFB1 para BUKRS si hay impacto FI.

Accion:

1. Extender BP a rol proveedor.
2. Completar datos de compras.
3. Completar datos de sociedad.
4. Reintentar ME21N.

## Caso B — Material no extendido

Evidencia:

- Existe MARA.
- Falta MARC para WERKS o MBEW para valoracion.

Accion:

1. Ampliar material en MM01/MM02.
2. Completar compras/contabilidad.
3. Validar grupo de compras y clase valoracion.

## Caso C — No se determina fuente

Evidencia:

- Falta EINA/EINE.
- Source list obligatorio sin EORD valido.

Accion:

1. Crear info record ME11.
2. Crear source list ME01.
3. Validar quota MEQ1 si aplica.

## Caso D — Estrategia no se dispara

Evidencia:

- EKKO-FRGKE/FRGZU vacio o incorrecto.
- Valores de clasificacion no coinciden.

Accion:

1. Revisar OMGQ.
2. Revisar caracteristicas/clase.
3. Validar valores: centro, grupo compras, valor neto, tipo documento.
4. Si usa Flexible Workflow, revisar condiciones de workflow.

---

# Respuesta tipo

```markdown
## Diagnostico ME21N/PO
El problema ocurre en <creacion/modificacion/liberacion>. La causa raiz probable es <causa>.

## Evidencia
- Proveedor/BP:
- Material/centro:
- Customizing documento:
- Source determination:
- Liberacion/workflow:

## Solucion
1.
2.
3.

## Validacion
- Crear/modificar PO nuevamente.
- Verificar EKKO/EKPO.
- Verificar liberacion o workflow.

## Impacto
- MM: disponibilidad de fuente y PO.
- FI/CO: imputacion, cuenta, centro de costo.
- Workflow: aprobadores y auditoria.
```
