# Dunning (Cobranza/Reclamacion) FI — S/4HANA

## Overview

Dunning is the process of sending payment reminders to customers with overdue invoices. SAP supports multi-level dunning with escalating severity, charges, and interest.

## Dunning Procedure Configuration (FBMP)

SPRO Path: `Financial Accounting > Accounts Receivable > Business Transactions > Dunning > Dunning Procedure`

### Procedure Header

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| Dunning procedure | 4-char ID | 0001 |
| Number of dunning levels | 1-9 | 4 |
| Dunning interval (days) | Min days between runs | 14 |
| Reference dunning procedure | Copy from | — |
| Line items grace days | At document level | 3 |
| Min days in arrears (account) | Minimum to start dunning | 5 |

### Dunning Levels Configuration

| Level | Days in Arrears | Description | Action |
|-------|----------------|-------------|--------|
| 1 | 14 | Friendly reminder | Letter |
| 2 | 30 | First warning | Letter + charges |
| 3 | 60 | Strong warning | Letter + interest + charges |
| 4 | 90 | Final notice / Legal | Legal collection letter |

### Level Detail Parameters

| Parameter | Descripcion |
|-----------|-------------|
| Days in arrears | Minimum overdue days for this level |
| Calculate interest | Y/N per level |
| Interest rate | Annual rate (e.g., 12%) |
| Dunning charges | Fixed amount per currency |
| Minimum amount for dunning | Below this = skip |
| Minimum percentage | % of total overdue |
| Print all items | Include non-overdue items |
| Payment deadline | Days given to pay after dunning date |

## Dunning Charges and Interest

SPRO Path: `Financial Accounting > Accounts Receivable > Business Transactions > Dunning > Dunning Procedure > Define Dunning Procedure > Charges`

| Parameter | Descripcion |
|-----------|-------------|
| Currency | Charge per currency |
| Charge per level | Fixed fee (e.g., Level 2 = 25 EUR, Level 3 = 50 EUR) |
| Interest indicator | Link to interest config (OB46) |
| Interest calc type | P = arrears, S = penal |
| Interest rate | Annual % |

### MCP SQL — Dunning Charges Configuration

```sql
-- Configuracion de cargos por nivel de reclamacion
SELECT MAHNA, MAHNS, WAESSION, MAHNB
FROM T047B
WHERE MAHNA = '{dunning_procedure}'
ORDER BY MAHNS
```

## Dunning Areas

Optional segmentation for decentralized dunning within a company code.

SPRO Path: `Financial Accounting > Accounts Receivable > Business Transactions > Dunning > Dunning Areas`

- Useful when different departments handle collections
- Each area can have separate dunning letters and contacts
- Assigned at document or customer level

## Dunning Run Execution (F150)

### Process Flow

```
F150 → Parameters → Schedule → Proposal → Review/Edit → Print/Send

Step 1: PARAMETERS
  - Dunning date (run date)
  - Company code(s)
  - Customer range (from/to)
  - Dunning procedure filter (optional)

Step 2: SCHEDULE
  - Immediate or background job

Step 3: PROPOSAL (automatic)
  - System calculates dunning level per customer/item
  - Considers: days in arrears, min amounts, grace days, blocks

Step 4: REVIEW/EDIT
  - Change dunning level manually
  - Block individual items
  - Add/remove customers

Step 5: PRINT
  - Classic: SAPF150D program
  - S/4HANA: BRF+ based forms, Adobe Forms, email
  - Output: SAPscript/Smartforms/Adobe Forms
```

### Dunning Selection Logic

```
For each customer open item:
  1. Calculate days_overdue = dunning_date - net_due_date
  2. Apply grace days (procedure + document level)
  3. Determine dunning level based on days_overdue thresholds
  4. Check: item amount >= minimum amount for level
  5. Check: no dunning block on item (MANSP) or customer (KNB1-MANSP)
  6. Check: interval since last dunning >= dunning interval
  7. Highest level across all items = account dunning level
```

## Dunning Block (MANSP)

| Level | Where | Field | Tcode |
|-------|-------|-------|-------|
| Document | BSID/BSAD | MANSP | FB02 |
| Customer master | KNB1 | MANSP | XD02/FD02/BP |
| Company code level | KNB1 | MANSP per CoCd | XD02 |

Block reasons defined in SPRO: `Dunning > Dunning Procedure > Define Dunning Block Reasons`

Common block codes: `A` = disputed, `B` = legal, `C` = promise to pay, `Z` = manual hold.

## Customer Master — Dunning Fields

### KNB1 (Company Code Level)

| Campo | Descripcion |
|-------|-------------|
| MAHNA | Dunning procedure assigned |
| BUSAB | Accounting clerk |
| MANSP | Dunning block |
| GMVDT | Last dunning date |

### KNB5 (Dunning History per Company Code)

| Campo | Descripcion |
|-------|-------------|
| KUNNR | Customer number |
| BUKRS | Company code |
| MESSION | Dunning area |
| MAHNA | Dunning procedure |
| MAHNS | Current dunning level |
| MADAT | Last dunning date |
| MESSION | Dunning run ID |

### MCP SQL — Customer Dunning Setup

```sql
-- Configuracion de reclamacion por cliente
SELECT A.KUNNR, A.BUKRS, A.MAHNA, A.BUSAB, A.MANSP,
       B.MAHNS AS CURRENT_LEVEL, B.MADAT AS LAST_DUNNING_DATE
FROM KNB1 AS A
LEFT JOIN KNB5 AS B ON A.KUNNR = B.KUNNR AND A.BUKRS = B.BUKRS
WHERE A.BUKRS = '{company_code}'
  AND A.MAHNA <> ''
ORDER BY B.MAHNS DESC, A.KUNNR
```

## Document-Level vs Account-Level Dunning

| Aspecto | Document Level | Account Level |
|---------|---------------|---------------|
| Granularity | Per invoice | Per customer |
| Dunning level | Max of all items | Overall customer |
| Use case | Specific item follow-up | General customer pressure |
| Configuration | Default in most procedures | Alternative |

## Key Tables

| Table | Descripcion | Campos clave |
|-------|-------------|--------------|
| T047 | Dunning procedure header | MAHNA, MAHNT (text) |
| T047A | Dunning levels | MAHNA, MAHNS, TAVAR |
| T047B | Dunning charges | MAHNA, MAHNS, WAERS, MAHNB |
| T047C | Dunning texts | MAHNA, MAHNS, SPRAS |
| T047E | Dunning procedure per CoCd | MAHNA, BUKRS |
| KNB5 | Customer dunning data | KUNNR, BUKRS, MAHNS, MADAT |
| BSID | Customer open items | MANSP, MANST (dunning level) |
| BSAD | Customer cleared items | MANSP, MANST |
| ACDOCA | Universal journal | Unified line items |

### MCP SQL — Overdue Items by Customer

```sql
-- Partidas vencidas por cliente con dias de atraso
SELECT KUNNR, RACCT, BELNR, BUZEI,
       BUDAT, NETDT, HSL, RWCUR,
       DATEDIFF(CURRENT_DATE, NETDT) AS DAYS_OVERDUE
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND KOART = 'D'
  AND AUGDT = '00000000'
  AND NETDT < CURRENT_DATE
  AND HSL > 0
ORDER BY KUNNR, DAYS_OVERDUE DESC
```

### MCP SQL — Dunning Level Distribution

```sql
-- Distribucion de niveles de reclamacion
SELECT MAHNS AS DUNNING_LEVEL,
       COUNT(DISTINCT KUNNR) AS NUM_CUSTOMERS,
       SUM(HSL) AS TOTAL_AMOUNT
FROM ACDOCA
WHERE RCOMP = '{company_code}'
  AND KOART = 'D'
  AND AUGDT = '00000000'
  AND MANST > '0'
GROUP BY MAHNS
ORDER BY MAHNS
```

### MCP SQL — Customers Never Dunned

```sql
-- Clientes con partidas vencidas sin reclamacion
SELECT A.KUNNR, A.BUKRS, A.MAHNA,
       COUNT(*) AS OPEN_ITEMS,
       SUM(B.HSL) AS TOTAL_OVERDUE
FROM KNB1 AS A
INNER JOIN ACDOCA AS B ON A.KUNNR = B.KUNNR AND A.BUKRS = B.RCOMP
WHERE A.BUKRS = '{company_code}'
  AND B.KOART = 'D'
  AND B.AUGDT = '00000000'
  AND B.NETDT < CURRENT_DATE
  AND A.MAHNA = ''
GROUP BY A.KUNNR, A.BUKRS, A.MAHNA
ORDER BY TOTAL_OVERDUE DESC
```

## Common Errors and Solutions

| Error | Causa | Solucion |
|-------|-------|----------|
| Customer not selected | No dunning procedure in KNB1 | Assign MAHNA via FD02/BP |
| "Minimum amount not reached" | Total overdue < minimum | Lower minimum in T047A or wait |
| "Dunning block active" | MANSP set on item or customer | Remove block in FB02 or FD02 |
| Wrong dunning level | Grace days too generous | Adjust in FBMP |
| No output generated | Forms not assigned | Configure print params in FBMP |
| "Interval not yet reached" | Last run too recent | Wait or change interval in FBMP |
| Items missing | Special GL items excluded | Include in FBMP special GL tab |
| Email not sent | No email in customer master | Maintain email in BP/XD02 |

## S/4HANA — Collections Management (FSCM)

| Feature | Descripcion |
|---------|-------------|
| Collections Worklist | Fiori app F2371 — prioritized list |
| Promise to Pay | Record payment commitments |
| Dispute Management | FSCM-DM: track disputed items |
| Customer Contact | Log calls, emails, notes |
| Resubmission | Automatic follow-up scheduling |
| Strategy | Rule-based prioritization |
| Integration | Links to classic dunning (F150) |

SPRO Path: `Financial Supply Chain Management > Collections Management`

## Diagnostic — Dunning Run Analysis

```
1. Check customer has dunning procedure: FD02 → Company Code → Correspondence
2. Check open items exist: FBL5N → customer → open items
3. Verify no dunning block: FB02 on each document → MANSP field
4. Check last dunning date: KNB5 table → MADAT
5. Verify minimum amounts: T047B → MAHNB per level
6. Check forms assignment: FBMP → Print parameters
7. Review proposal log: F150 → Display log
```
