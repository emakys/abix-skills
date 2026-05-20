# Tablas de Customizing FI — S/4HANA

## General Ledger — Company Code & Chart of Accounts

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T001 | Company codes | OBR2 / OX02 | BUKRS, BUTXT, ORT01, LAND1, WAERS, KTOPL |
| T001B | Permitted posting periods | OB52 | RPTS, BKONT, FRPE1, BIPE1 |
| T004 | Chart of accounts | OB13 | KTOPL, KTPLT, XBILK |
| T004T | CoA description | OB13 | KTOPL, SPRAS, KTPLT |
| T009 | Fiscal year variant | OB29 | PERIV, ANPTS, XKALE |
| T009B | Fiscal year periods | OB29 | PERIV, BDATJ, BUMON, PESSION |
| T010O | Posting period variant assign | OB37 | BUKRS, PERIV |
| T043 | Tolerance groups GL users | OBA0 | BUKRS, HTEFG, DTOLP |
| T043G | Tolerance groups GL accounts | OBA0 | BUKRS, HTEFG |

### MCP SQL — Company Code Configuration

```sql
-- Configuracion de sociedades
SELECT BUKRS, BUTXT, ORT01, LAND1, WAERS, KTOPL,
       PERIV, KKBER, RCOMP
FROM T001
ORDER BY BUKRS
```

### MCP SQL — Current Open Posting Periods

```sql
-- Periodos de contabilizacion abiertos
SELECT RPTS, BKONT, VONBR, BISBR,
       FRPE1, BIPE1, FRBU1, BIBU1,
       FRPE2, BIPE2, FRBU2, BIBU2
FROM T001B
WHERE RPTS = '{posting_period_variant}'
ORDER BY BKONT
```

## GL Account Master

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| SKA1 | GL master (CoA level) | FS00 | KTOPL, SAKNR, BILKT, GVTYP, KTOKS |
| SKAT | GL account descriptions | FS00 | SPRAS, KTOPL, SAKNR, TXT20, TXT50 |
| SKB1 | GL master (CoCd level) | FS00 | BUKRS, SAKNR, MWSKZ, WAESSION, XOPVW |
| T077S | GL account groups | OBD4 | KTOPL, KTOGR, BEGRU |
| FAGL_011PC | Profit center assignment GL | 3KEH | RRCTY, RACCT, PRCTR |
| FAGL_011ZC | Segment assignment | — | RRCTY, RACCT, SEGMENT |

### MCP SQL — Chart of Accounts Listing

```sql
-- Listado de cuentas del plan de cuentas
SELECT A.SAKNR, B.TXT20, B.TXT50,
       A.BILKT, A.GVTYP, A.KTOKS, A.XBILK
FROM SKA1 AS A
INNER JOIN SKAT AS B ON A.KTOPL = B.KTOPL AND A.SAKNR = B.SAKNR
WHERE A.KTOPL = '{chart_of_accounts}'
  AND B.SPRAS = 'E'
ORDER BY A.SAKNR
```

## Accounts Payable — Vendor Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T077K | Vendor account groups | OBD3 | KTOGR, NUMKR, BEGRU |
| T052 | Payment terms | OBB8 | ZTERM, ZTAGG, ZTAG1, ZPR01 |
| T052U | Payment terms descriptions | OBB8 | SPRAS, ZTERM, TEXT1 |
| T042 | Payment program: CoCd config | FBZP | BUKRS, LTEFG |
| T042A | Payment program: paying CoCd | FBZP | BUKRS, HTEFG |
| T042B | Payment program: banks | FBZP | BUKRS, HBKID |
| T042C | Payment program: payment methods CoCd | FBZP | BUKRS, ZLSCH |
| T042D | Payment program: payment methods general | FBZP | LAND1, ZLSCH |
| T042E | Payment program: bank determination | FBZP | BUKRS, HBKID, RZESSION |
| T042I | Payment program: available amounts | FBZP | BUKRS, HBKID, DTAVL |
| T042Z | Payment methods per CoCd | FBZP | BUKRS, ZLSCH |
| T059Z | Withholding tax types | OBWI / OBW0 | LAND1, WITHT |
| T059P | Withholding tax codes | OBWI / OBW1 | LAND1, WITHT, WT_WITHCD |

### MCP SQL — Payment Terms Lookup

```sql
-- Condiciones de pago configuradas
SELECT A.ZTERM, B.TEXT1,
       A.ZTAGG AS NET_DAYS,
       A.ZTAG1 AS DISC_DAYS_1,
       A.ZPR01 AS DISC_PCT_1,
       A.ZTAG2 AS DISC_DAYS_2,
       A.ZPR02 AS DISC_PCT_2
FROM T052 AS A
INNER JOIN T052U AS B ON A.ZTERM = B.ZTERM
WHERE B.SPRAS = 'E'
ORDER BY A.ZTERM
```

### MCP SQL — Payment Methods Configuration

```sql
-- Metodos de pago configurados por sociedad
SELECT A.BUKRS, A.ZLSCH, B.TEXT1,
       A.XRECH, A.XINTZ
FROM T042C AS A
INNER JOIN T042D AS B ON A.ZLSCH = B.ZLSCH
WHERE A.BUKRS = '{company_code}'
ORDER BY A.ZLSCH
```

## Accounts Receivable — Customer Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T077D | Customer account groups | OBD2 | KTOGR, NUMKR, BEGRU |
| T047 | Dunning procedure header | FBMP | MAHNA, MESSION |
| T047A | Dunning levels | FBMP | MAHNA, MAHNS, TAVAR |
| T047B | Dunning charges | FBMP | MAHNA, MAHNS, WAERS, MAHNB |
| T047C | Dunning texts | FBMP | MAHNA, MAHNS, SPRAS |
| T047E | Dunning per company code | FBMP | MAHNA, BUKRS |
| T056 | Interest calculation: header | OB46 | BUKRS, FESSION |
| T056A | Interest rates | OB46 | BUKRS, FESSION, DATAB |
| T056R | Interest reference rates | OB46 | RESSION, DATAB |

### MCP SQL — Dunning Procedure Details

```sql
-- Detalle de procedimiento de reclamacion
SELECT A.MAHNA, A.MAHNS,
       A.TAVAR AS DAYS_IN_ARREARS,
       B.MAHNB AS DUNNING_CHARGE,
       B.WAERS AS CURRENCY
FROM T047A AS A
LEFT JOIN T047B AS B ON A.MAHNA = B.MAHNA AND A.MAHNS = B.MAHNS
WHERE A.MAHNA = '{dunning_procedure}'
ORDER BY A.MAHNS
```

## Asset Accounting

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T093 | Depreciation areas: real | OADB | BUKRS, AFESSION |
| T093C | Depreciation areas: derived | OADB | BUKRS, AFESSION |
| ANKA | Asset classes: master | OAOA | ANLKL, KTOGR |
| ANKT | Asset class descriptions | OAOA | SPRAS, ANLKL, TXKA1 |
| ANKAZ | Asset class: depreciation area | OAOA | ANLKL, AFESSION, AFESSION_D |
| T090 | Depreciation key: header | AFAMA | AFESSION, AFASL |
| T090A | Depreciation key: levels | AFAMA | AFESSION, AFASL, ANLUE |
| T090NAA | Depreciation key: new | AFAMA | AFESSION, AFASL |
| T095 | Account determination AA | AO90 | KTOGR, AFESSION, KONTO |
| T095B | Account determination details | AO90 | KTOGR, AFESSION, KONTTYP |

### MCP SQL — Asset Class Configuration

```sql
-- Clases de activo con cuentas de determinacion
SELECT A.ANLKL, B.TXKA1 AS DESCRIPTION,
       A.KTOGR AS ACCOUNT_DETERM,
       C.KONTO AS GL_ACCOUNT,
       C.KONTTYP AS ACCOUNT_TYPE
FROM ANKA AS A
INNER JOIN ANKT AS B ON A.ANLKL = B.ANLKL AND B.SPRAS = 'E'
LEFT JOIN T095B AS C ON A.KTOGR = C.KTOGR
ORDER BY A.ANLKL
```

## Tax Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T007A | Tax keys (codes) | FTXP | KALSM, MWSKZ, MWART |
| T007B | Tax rates per code | FTXP | KALSM, MWSKZ, DATAB, KBETR |
| T007S | Tax code descriptions | FTXP | SPRAS, KALSM, MWSKZ, TEXT1 |
| T007V | Tax code per country | OBQ1 | LAND1, MESSION |
| A003 | Tax condition records | VK11 | AESSION, MWSKZ, KBETR |
| T030K | Tax account determination | OB40 | KTOPL, KTOSL, MWSKZ, KONTS |

### MCP SQL — Tax Code Rates

```sql
-- Tipos impositivos configurados
SELECT A.KALSM, A.MWSKZ, B.TEXT1,
       A.MWART AS TAX_TYPE,
       C.KBETR / 10 AS TAX_RATE_PCT
FROM T007A AS A
INNER JOIN T007S AS B ON A.KALSM = B.KALSM AND A.MWSKZ = B.MWSKZ AND B.SPRAS = 'E'
LEFT JOIN T007B AS C ON A.KALSM = C.KALSM AND A.MWSKZ = C.MWSKZ
WHERE A.KALSM = '{tax_procedure}'
ORDER BY A.MWSKZ
```

## Document Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T003 | Document types | OBA7 | BLART, NUMKR, KOESSION |
| T003T | Document type descriptions | OBA7 | SPRAS, BLART, LTEXT |
| TBSL | Posting keys | OB41 | BSCHL, KOART, SHKZG |
| TBSLT | Posting key descriptions | OB41 | SPRAS, BSCHL, LTEXT |
| T074 | Special GL indicators | OBYR | KOART, UMSKZ, UESSION |
| T074T | Special GL indicator texts | OBYR | SPRAS, KOART, UMSKZ |

### MCP SQL — Document Types

```sql
-- Tipos de documento configurados
SELECT A.BLART, B.LTEXT,
       A.NUMKR AS NUMBER_RANGE,
       A.KOESSION,
       A.STESSION
FROM T003 AS A
INNER JOIN T003T AS B ON A.BLART = B.BLART AND B.SPRAS = 'E'
ORDER BY A.BLART
```

### MCP SQL — Posting Keys

```sql
-- Claves de contabilizacion
SELECT A.BSCHL, B.LTEXT,
       A.KOART AS ACCOUNT_TYPE,
       A.SHKZG AS DEBIT_CREDIT,
       A.XNEGP AS NEGATIVE_POSTING
FROM TBSL AS A
INNER JOIN TBSLT AS B ON A.BSCHL = B.BSCHL AND B.SPRAS = 'E'
ORDER BY A.BSCHL
```

## Bank Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T012 | House banks | FI12 | BUKRS, HBKID, BANKS, BANKL |
| T012K | House bank accounts | FI12 | BUKRS, HBKID, HKTID, UKONT |
| T012T | House bank texts | FI12 | BUKRS, HBKID, SPRAS |
| BNKA | Bank master records | FI01 | BANKS, BANKL, BANKA |
| T028B | EBS transaction types | OT83 | TRESSION, VORESSION |
| T028D | Bank statement trans codes | OT83 | BUKRS, TRESSION |

### MCP SQL — House Bank Configuration

```sql
-- Bancos propios configurados
SELECT A.BUKRS, A.HBKID, C.BESSION AS BANK_NAME,
       B.HKTID AS ACCOUNT_ID, B.UKONT AS GL_ACCOUNT,
       A.BANKL AS BANK_KEY, A.BANKS AS BANK_COUNTRY
FROM T012 AS A
INNER JOIN T012K AS B ON A.BUKRS = B.BUKRS AND A.HBKID = B.HBKID
LEFT JOIN BNKA AS C ON A.BANKS = C.BANKS AND A.BANKL = C.BANKL
WHERE A.BUKRS = '{company_code}'
ORDER BY A.HBKID
```

## Automatic Account Determination

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T030 | Standard auto postings | OB40 | KTOPL, KTOSL, UMSKZ, KONTS |
| T030R | Auto posting rules | OBYC | KTOPL, KTOSL, BWMOD |
| T030K | Tax accounts | OB40 | KTOPL, KTOSL, MWSKZ, KONTS |
| T030B | Auto posting: bank subaccts | — | BUKRS, HKONT, UHKT1 |
| T030H | Posting rules: valuation diff | — | KTOPL, KTOSL |

### Key Transaction Keys (KTOSL)

| KTOSL | Descripcion | SPRO Path |
|-------|-------------|-----------|
| BSX | Inventory posting | OBYC |
| GBB | Offsetting entry inventory | OBYC |
| WRX | GR/IR clearing | OBYC |
| PRD | Price differences | OBYC |
| KDM | Exchange rate differences (expense) | OB09 |
| KDF | Exchange rate differences (valuation) | OBA1 |
| AUM | Asset transfer posting | AO90 |
| ANL | Asset acquisition: offsetting | AO90 |

### MCP SQL — Automatic Account Assignments

```sql
-- Determinacion automatica de cuentas
SELECT KTOPL, KTOSL, UMSKZ, KONTS,
       BWMOD, KOMOK
FROM T030
WHERE KTOPL = '{chart_of_accounts}'
ORDER BY KTOSL, UMSKZ
```

## Withholding Tax Configuration

| Table | Descripcion | SPRO Path / Tcode | Key Fields |
|-------|-------------|-------------------|------------|
| T059Z | Withholding tax types | OBW0 | LAND1, WITHT |
| T059P | Withholding tax codes | OBW1 | LAND1, WITHT, WT_WITHCD |
| T059Q | WHT rates | OBW1 | LAND1, WITHT, WT_WITHCD, DATAB |

### MCP SQL — Withholding Tax Codes

```sql
-- Codigos de retencion configurados
SELECT A.LAND1, A.WITHT, A.WT_WITHCD,
       B.WT_QSSHH AS WHT_RATE,
       B.WT_MESSION AS MIN_AMOUNT,
       B.DATAB AS VALID_FROM
FROM T059P AS A
INNER JOIN T059Q AS B ON A.LAND1 = B.LAND1 AND A.WITHT = B.WITHT
                       AND A.WT_WITHCD = B.WT_WITHCD
WHERE A.LAND1 = '{country}'
ORDER BY A.WITHT, A.WT_WITHCD
```

## Quick Reference — SPRO Navigation Paths

| Area | SPRO Path |
|------|-----------|
| Company Code | Enterprise Structure > Definition > Financial Accounting > Define Company Code |
| Chart of Accounts | Financial Accounting > General Ledger > Master Data > G/L Accounts > Preparations > Edit Chart of Accounts List |
| Fiscal Year | Financial Accounting > Financial Accounting Global Settings > Fiscal Year > Maintain Fiscal Year Variant |
| Posting Periods | Financial Accounting > Financial Accounting Global Settings > Document > Posting Periods |
| Document Types | Financial Accounting > Financial Accounting Global Settings > Document > Document Types |
| Payment Program | Financial Accounting > Accounts Payable > Business Transactions > Outgoing Payments > Automatic > Payment Program |
| Dunning | Financial Accounting > Accounts Receivable > Business Transactions > Dunning |
| Asset Config | Financial Accounting > Asset Accounting > Organizational Structures |
| Tax Procedure | Financial Accounting > Financial Accounting Global Settings > Tax on Sales/Purchases > Basic Settings |
| Bank Accounting | Financial Accounting > Bank Accounting > Bank Accounts |
| Auto Acct Determ | Financial Accounting > Financial Accounting Global Settings > Default Values > Automatic Account Assignment |
