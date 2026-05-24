# Integracion Cross-Module CO

## CO <> FI (Financial Accounting)

En S/4HANA, CO y FI comparten ACDOCA. Ya no existe reconciliacion FI-CO.

| Aspecto | ECC | S/4HANA |
|---------|-----|---------|
| Tablas CO | COEP, COSS, COSP | ACDOCA |
| Reconciliacion | Necesaria (KALC) | Eliminada |
| Cost element | Creacion separada (KA01) | = Cuenta GL |

### Flujos FI → CO

| Evento FI | Impacto CO |
|-----------|-----------|
| Factura proveedor (MIRO) | Coste en CC/orden via OBYC |
| Factura cliente (VF01) | Revenue en CO-PA |
| Asiento manual (FB50) | Si tiene CC/orden → linea CO |
| Nomina (PC00) | Distribucion a CC |
| Depreciacion (AFAB) | Coste en CC del activo |

### Flujos CO → FI

| Evento CO | Impacto FI |
|-----------|-----------|
| Settlement (KO88) | Doc FI tipo AB |
| WIP calculation (KKAO) | Doc FI en cuentas WIP |
| ML revaluation (CKMLCP) | Doc FI ajuste inventario |

---

## CO <> MM (Materials Management)

### Determinacion de cuentas (OBYC → CO)

| Evento MM | Cuenta OBYC | Objeto CO |
|-----------|-------------|-----------|
| GR con PO (101) | BSX/WRX | CC o orden de la posicion PO |
| Consumo a CC (201) | GBB/VBR | CC destino |
| Consumo a orden (261) | GBB/AUF | Orden produccion |
| Diferencia precio | PRD | CC del material |

### Imputacion CO en pedido de compra

| Campo EKPO | Descripcion | Impacto CO |
|------------|-------------|-----------|
| KOSTL | Centro de coste | Receptor CC |
| AUFNR | Orden | Receptor orden |
| PS_PSP_PNR | Elemento PEP | Receptor WBS |
| KNTTP | Categoria imputacion | K=CC, F=orden, P=proyecto |

---

## CO <> SD (Sales & Distribution)

### CO-PA — Transfer desde billing

| Evento SD | Impacto CO-PA |
|-----------|--------------|
| Facturacion (VF01) | Revenue + COGS en segmento PA |
| Abono (credit memo) | Reduccion revenue |
| Rebate settlement | Ajuste PA |

---

## CO <> PP (Production Planning)

| Evento PP | Impacto CO |
|-----------|-----------|
| Consumo material (backflush) | Coste material en orden PP |
| Confirmacion actividad (CO11N) | Coste mano obra en orden PP |
| Overhead (CO43) | Recargo indirecto |
| WIP (KKAO) | Valoracion trabajo en curso |
| Variance (KKS1) | Desviaciones plan vs real |
| Settlement (CO88) | Liquidacion a stock o CO-PA |

---

## CO <> HR / PM / PS

| Evento | Impacto CO |
|--------|-----------|
| Nomina HR | Coste a CC del empleado |
| Orden PM — materiales/servicios | Coste en orden PM |
| PM settlement (KO88) | A CC o activo |
| WBS posting PS | Acumula en elemento PEP |
| PS settlement (CJ88) | A activo (capitalizacion) |

---

## Tabla resumen — Config integracion

| Integracion | Config clave | TCode |
|-------------|-------------|-------|
| CO ↔ FI | Automatica en S/4 (ACDOCA) | — |
| CO ← MM | Imputacion CO en PO | ME21N |
| CO ← MM | Determinacion cuentas | OBYC |
| CO ← SD | Transfer CO-PA | KE28/KEU5 |
| CO ← SD | Determinacion cuentas revenue | VKOA |
| CO ← PP | Confirmaciones + settlement | CO88 |
| CO ← HR | Mapping wage type → CC | SPRO payroll |
| CO ← PM | Settlement ordenes PM | KO88 |
| CO ← PS | Settlement proyectos | CJ88 |
