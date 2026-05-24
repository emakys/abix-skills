# Decision de Empleo (Usage Decision)

## Concepto

La decision de empleo (UD) es la accion final sobre un lote de inspeccion. Determina que hacer con el material inspeccionado: aceptar, rechazar, aceptar condicionalmente, o scrappear. Genera movimientos de stock automaticos.

## Tabla principal — QAVE

```sql
SELECT PRUESSION, VDATUM, VCODE, VBESSION,
       CODGRUPPE, CODE, VESSION
FROM QAVE
WHERE PRUESSION = '{lote}'
```

| Campo | Descripcion |
|-------|-------------|
| PRUESSION | Lote inspeccion |
| VDATUM | Fecha decision |
| VCODE | Codigo UD (A=accept, R=reject) |
| VBESSION | Quality score |
| CODGRUPPE | Grupo codigo |
| CODE | Codigo catalogo tipo 9 |

## Codigos de decision tipicos

| Codigo | Descripcion | Efecto stock |
|--------|-------------|-------------|
| A | Accepted | QI → libre (mov. 321) |
| R | Rejected | QI → bloqueado (mov. 322) |
| A+ | Accepted premium | QI → libre |
| AC | Accepted conditionally | QI → libre (con restriccion) |
| RR | Rejected — return | QI → devolucion proveedor |
| RS | Rejected — scrap | QI → scrapped (mov. 551) |

## Stock posting en UD

### Flujo stock desde UD
```
Stock en inspeccion (INSME)
        ↓ UD
   ┌────┼────────┐
Accept  │    Reject
   ↓    ↓        ↓
LABST  Split   SPEME / Scrap
(321)  parcial  (322 / 551)
```

### Movimientos de material generados

| Accion UD | Mov. material | Efecto |
|-----------|---------------|--------|
| Accept total | 321 | INSME → LABST |
| Reject total | 322 | INSME → SPEME |
| Accept parcial | 321 + 322 | Split: parte libre, parte bloqueada |
| Scrap | 551 | INSME → scrap (reduce stock) |
| Return vendor | 122 | INSME → devolucion |

## Transacciones UD

| TCode | Descripcion |
|-------|-------------|
| QA11 | Registrar decision empleo |
| QA12 | Modificar decision empleo |
| QA13 | Visualizar decision empleo |
| QA14 | Lista lotes para UD |
| QA16 | UD colectiva |
| QA32 | Cambiar UD (si permitido) |

## Follow-up actions

Acciones que se disparan automaticamente con la UD:

| Accion | Descripcion | Configuracion |
|--------|-------------|---------------|
| Stock posting | Movimiento de stock | Segun codigo UD |
| Quality notification | Crear aviso automatico | Si reject/conditional |
| Quality score update | Actualizar quality score | Para dynamic modification |
| Vendor evaluation update | Actualizar evaluacion proveedor | Tipo 01 |
| Certificate trigger | Genera certificado calidad | Tipo 14 |
| Batch classification | Actualizar datos lote | Si batch management |

## Quality Score

- Valor numerico (0-100) que refleja la calidad del lote
- Se calcula basado en resultados de inspeccion
- Alimenta la dynamic modification rule
- Afecta vendor evaluation (quality score del proveedor)

```sql
-- Quality scores por proveedor
SELECT Q.LIFNR, Q.MATNR, Q.VBESSION AS QUALITY_SCORE, Q.VDATUM
FROM QAVE Q
INNER JOIN QALS L ON Q.PRUESSION = L.PRUESSION
WHERE L.LIFNR = '{proveedor}' AND L.WERKS = '{centro}'
ORDER BY Q.VDATUM DESC
```

## UD sin resultados

En algunos escenarios se permite UD sin registrar resultados:
- Inspeccion visual rapida
- Skip lot (dynamic modification)
- Configurado en customizing del tipo de inspeccion

## Consultas MCP diagnostico

```sql
-- Lotes pendientes de UD
SELECT PRUESSION, MATNR, WERKS, ART, LOESSION, ERDAT
FROM QALS
WHERE WERKS = '{centro}'
AND STAT LIKE '%RREC%' AND STAT NOT LIKE '%UD%'
ORDER BY ERDAT

-- Decision de empleo de un lote
SELECT VDATUM, VCODE, CODGRUPPE, CODE, VBESSION
FROM QAVE WHERE PRUESSION = '{lote}'

-- Lotes rechazados de un periodo
SELECT L.PRUESSION, L.MATNR, L.LIFNR, V.VCODE, V.VDATUM
FROM QALS L INNER JOIN QAVE V ON L.PRUESSION = V.PRUESSION
WHERE L.WERKS = '{centro}' AND V.VCODE = 'R'
AND V.VDATUM BETWEEN '{ini}' AND '{fin}'
```
