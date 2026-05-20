# Credit Management (Gestion de Credito)

## Concepto

Credit management controla el riesgo crediticio asignando limites de credito a clientes
y bloqueando documentos cuando se exceden.

## Dos versiones en S/4HANA

### Classic Credit Management (FD32)
```
ECC y S/4HANA on-premise:
  - Limite de credito por area de control de credito
  - Verificacion en pedido y/o entrega
  - Bloqueo automatico si excede limite
  - Liberacion manual (VKM1)

Config centralizada en SPRO + FD32
```

### SAP Credit Management (FSCM-CR) — S/4HANA avanzado
```
SAP Credit Management (Financial Supply Chain Management):
  - Scoring de credito automatico
  - Integracion con bureaus de credito externos
  - Reglas de credito flexibles
  - Seguro de credito
  - Workflow de aprobacion

Config: SPRO → Financial Supply Chain Management → Credit Management
Transaccion: UKM_MY_ACCOUNT (monitor de credito)
```

## Classic Credit Management — Config paso a paso

### Paso 1: Area de control de credito (T014)
```
SPRO → Enterprise Structure → Definition → Financial Accounting →
  Define Credit Control Area

OB45: Crear area de control credito
  KKBER: 1000
  Descripcion: "Control credito Mexico"
  Moneda: MXN
  Update: 12 (actualizacion online)

Asignar a sociedad: OB38 (T001-KKBER)
```

### Paso 2: Limite de credito del cliente (FD32)
```
FD32 → Introducir cliente + area credito

Datos:
  - Credit limit: $100,000
  - Risk category: 001 (bajo riesgo) / 002 (medio) / 003 (alto)
  - Credit representative group: 001
  - Internal credit rating: A/B/C/D

SAP calcula automaticamente:
  - Credit exposure = receivables + open orders + open deliveries + special liabilities
  - Credit available = credit limit - credit exposure
  - Utilization % = credit exposure / credit limit * 100
```

### Paso 3: Verificacion automatica (OVA8)
```
SPRO → SD → Basic Functions → Credit Management →
  Automatic Credit Control (OVA8)

Define CUANDO y COMO se verifica:

  Document credit group: sales order (01), delivery (02), goods issue (03)
  Risk category: 001, 002, 003
  Credit control area: 1000

  Checks disponibles:
    A: Static credit limit (simple: exposure vs limit)
    B: Dynamic credit limit (horizon temporal)
    C: Max document value
    D: Max open items value
    E: Oldest open item (dias de retraso)
    F: Next review date
    G: Credit exposure change %

  Reaction:
    A: Warning (aviso, permite grabar)
    B: Error (bloquea documento)
    C: Error + delivery block
    D: Error + delivery block + billing block
```

### Paso 4: Liberacion de documentos bloqueados

```
VKM1: Pedidos bloqueados por credito
VKM2: Entregas bloqueadas por credito
VKM3: Documentos bloqueados (todos)
VKM4: Pedidos bloqueados por credito (con detalle)
VKM5: Liberar entregas automaticamente

Proceso:
  1. Documento se bloquea automaticamente (CMGST en VBAK)
  2. Credit manager revisa en VKM1
  3. Verifica riesgo real del cliente
  4. Libera (quita bloqueo) o rechaza
  5. Puede aumentar limite en FD32 si aplica
```

## Status de credito (VBAK-CMGST)

| Status | Descripcion |
|--------|-------------|
| '' (vacio) | No verificado |
| A | Aprobado automaticamente |
| B | Rechazado (excede limite) |
| C | Aprobado manualmente (liberado) |
| D | Rechazado (riesgo alto) |

## Queries MCP

```sql
-- Limite de credito del cliente
SELECT KUNNR, KKBER, KLIMK, SKFOR, SSOFO, OEESSION
FROM KNKK WHERE KUNNR = '{cliente}' AND KKBER = '{area_credito}'
-- KLIMK=limite, SKFOR=exposure, SSOFO=special liabilities

-- Credit exposure detallada
SELECT KUNNR, KKBER, KLIMK, SKFOR,
       (KLIMK - SKFOR) as DISPONIBLE,
       CASE WHEN KLIMK > 0 THEN (SKFOR / KLIMK * 100) ELSE 0 END as UTILIZACION
FROM KNKK WHERE KKBER = '{area_credito}'
AND SKFOR > KLIMK -- Solo los que exceden

-- Pedidos bloqueados por credito
SELECT VBELN, AUART, KUNNR, NETWR, CMGST, LIFSK FROM VBAK
WHERE CMGST IN ('B','D') AND VKORG = '{org}'

-- Partidas abiertas del cliente (receivables)
SELECT KUNNR, BUKRS, BELNR, BUZEI, DMBTR, ZFBDT, ZBD1T
FROM BSID WHERE KUNNR = '{cliente}' AND BUKRS = '{sociedad}'
-- S/4: usar ACDOCA en vez de BSID

-- Antiguedad de deuda
SELECT KUNNR, BELNR, DMBTR, ZFBDT,
       DATS_DAYS_BETWEEN(ZFBDT, '{hoy}') as DIAS_VENCIDO
FROM BSID WHERE KUNNR = '{cliente}' AND BUKRS = '{sociedad}'
AND AUGDT = '00000000' -- Solo abiertas
ORDER BY ZFBDT
```

## Dunning (Reclamacion de deuda)

```
Transaccion: F150 (dunning run)

Proceso:
  1. F150 → parametros: sociedad, fecha, area dunning
  2. Propuesta de dunning (SAP sugiere nivel para cada cliente)
  3. Revision manual (ajustar niveles)
  4. Imprimir cartas de dunning
  5. Actualizar nivel dunning en maestro cliente

Niveles tipicos:
  1: Recordatorio amable (15 dias)
  2: Segundo aviso (30 dias)
  3: Requerimiento formal (60 dias)
  4: Aviso legal (90 dias)

Config: SPRO → FI → AR → Dunning → Dunning Procedure
Tabla: T047 (procedimiento dunning), T047A (niveles)
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| VW 186 | Credit limit exceeded | VKM1 liberar o FD32 aumentar |
| Credit block on delivery | VBAK-LIFSK = 'Z1' (credit) | VKM2 liberar |
| No credit data maintained | Falta FD32 para el cliente | FD32 crear |
| Credit area not determined | T001-KKBER vacio | OB38 asignar |
| Dynamic check failed | Open items exceden horizonte | Revisar OVA8 config |
