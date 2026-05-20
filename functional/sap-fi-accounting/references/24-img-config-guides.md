# IMG Configuration Guides — FI

## Overview

Step-by-step SPRO configuration paths for key Financial Accounting areas in S/4HANA. Each guide includes the SPRO navigation path, affected tables, recommended sequence, and dependencies. All paths assume S/4HANA 2023 or later.

---

## Guide 1: New Company Code Setup

### SPRO Path
```
SAP Customizing Implementation Guide >
  Enterprise Structure > Definition > Financial Accounting >
    Define Company Code (OX02)
```

### Configuration Sequence

| Step | TCode | Action | Table | Dependencies |
|------|-------|--------|-------|--------------|
| 1 | OX02 | Define company code (4-char) | T001 | Client configured |
| 2 | OX15 | Assign company code to company | T880/T001 | Company defined (OX15) |
| 3 | OBR2 | Assign chart of accounts | T001-KTOPL | Chart of accounts exists |
| 4 | OB62 | Assign fiscal year variant | T001-PERIV | FY variant defined (OB29) |
| 5 | OBY6 | Enter global parameters (currencies, etc.) | T001 | Country, currency maintained |
| 6 | OB52 | Open posting periods | T001B | FY variant assigned |
| 7 | OBA0 | Define tolerance groups for GL accounts | T043 | Company code exists |
| 8 | OBA4 | Define tolerance groups for employees | T043T | Company code exists |
| 9 | OB57 | Assign field status variant | T001-BUKRS | FSV defined (OBC4) |
| 10 | OBY1 | Assign company code to credit control area | T001-KKBER | Credit control area defined |
| 11 | FS00 | Create minimum GL accounts | SKA1/SKB1 | CoA + company code assigned |
| 12 | OB53 | Define retained earnings account | T030-HKONT | GL account created |
| 13 | FI12 | Create house bank + bank accounts | T012/T012K | Bank master exists |
| 14 | OBA7 | Verify document types | T003 | Number ranges assigned (FBN1) |
| 15 | FBN1 | Define number ranges for documents | NRIV | Document types verified |

### Minimum GL Accounts to Create

| Account | Type | Category | Purpose |
|---------|------|----------|---------|
| 100000 | BS | Bank | Main bank account |
| 110000 | BS | AR Recon | Customer reconciliation |
| 160000 | BS | AP Recon | Vendor reconciliation |
| 200000 | BS | Fixed Assets | Asset reconciliation |
| 300000 | BS | Equity | Share capital |
| 390000 | BS | Equity | Retained earnings (OB53) |
| 400000 | P&L | Revenue | Sales revenue |
| 500000 | P&L | COGS | Cost of goods sold |
| 600000 | P&L | Expense | Operating expenses |
| 700000 | P&L | Other | Interest income/expense |

---

## Guide 2: Automatic Payment Program (FBZP)

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Accounts Receivable and Accounts Payable >
    Business Transactions > Outgoing Payments > Automatic Outgoing Payments >
      Payment Program Configuration (FBZP)
```

### Configuration Steps

| Step | FBZP Tab | Action | Table | Details |
|------|----------|--------|-------|---------|
| 1 | All company codes | Define paying company code | T042 | Set paying cc, payment methods, min amounts |
| 2 | Paying company codes | Set sending/paying cc | T042A | Minimum amount for payment, forms |
| 3 | Pmnt methods in country | Define T/C/W per country | T042Z | Transfer (T), Check (C), Wire (W) |
| 4 | Pmnt methods in co.code | Assign methods to cc | T042E | Amounts, bank determination, forms |
| 5 | Bank determination | Rank banks per method | T042B/T042C | Priority, amounts, charges |
| 6 | House banks | Verify bank config | T012/T012K | Bank ID, account ID |

### Payment Method Configuration Matrix

| Method | Country | Type | Min Amount | Max Amount | Typical Use |
|--------|---------|------|------------|------------|-------------|
| T | US | Transfer | 0.01 | 999,999,999 | ACH/Wire transfer |
| C | US | Check | 0.01 | 999,999,999 | Paper checks |
| W | US | Wire | 10,000 | 999,999,999 | International wire |
| T | DE | Transfer | 0.01 | 999,999,999 | SEPA transfer |
| S | DE | SEPA DD | 0.01 | 999,999,999 | SEPA direct debit |

### Supporting Configuration

| TCode | Purpose | When |
|-------|---------|------|
| OB40 | Cash discount accounts (SKE/SKT) | Before first payment run |
| FI12 | House bank + account IDs | Before FBZP bank determination |
| FBN1 | Number ranges for payment docs | Before first payment run |
| OBPM4 | Payment medium formats (DME) | Before generating payment files |
| F110 | Execute payment run | Testing |

---

## Guide 3: Dunning Configuration (FBMP)

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Accounts Receivable and Accounts Payable >
    Business Transactions > Dunning >
      Dunning Procedure (FBMP)
```

### Configuration Steps

| Step | Action | Details |
|------|--------|---------|
| 1 | Define dunning procedure | Procedure ID (4-char), description |
| 2 | Set dunning levels | Typically 1-4 levels |
| 3 | Set days in arrears | Per level: 14, 28, 42, 56 days |
| 4 | Set dunning charges | Fixed amounts or percentage per level |
| 5 | Set interest rates | Annual rate for overdue calculation |
| 6 | Assign dunning texts/forms | SAP Script or Smart Form per level |
| 7 | Define minimum amounts | Minimum overdue amount to trigger |
| 8 | Assign to customers (KNB1) | Dunning procedure + dunning recipient |

### Dunning Level Matrix

| Level | Days Overdue | Charge | Interest | Action |
|-------|-------------|--------|----------|--------|
| 1 | 14 | 0.00 | 0% | Friendly reminder |
| 2 | 28 | 5.00 | 0% | Second reminder with charge |
| 3 | 42 | 15.00 | 8% | Formal demand, interest |
| 4 | 56 | 25.00 | 12% | Final notice, legal warning |

### Execution (F150)

| Phase | Mode | Description |
|-------|------|-------------|
| 1 | Proposal | Select overdue items, calculate levels |
| 2 | Review | Check proposal list, modify if needed |
| 3 | Print | Generate dunning notices |
| 4 | Post | Post dunning charges/interest (if configured) |

---

## Guide 4: Asset Accounting Configuration

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Asset Accounting
```

### Configuration Sequence

| Step | TCode | Action | Table | Dependencies |
|------|-------|--------|-------|--------------|
| 1 | OADB | Define depreciation areas | T093B | Chart of depreciation |
| 2 | OAOA | Define asset classes | ANKT/ANLA | Number ranges, screen layout |
| 3 | AO90 | Account determination per class/area | T095/T095B | GL accounts created |
| 4 | AFAMA | Define depreciation keys | T093C/ANLB | Methods (LINA, DEGR, etc.) |
| 5 | OAYR | Fiscal year for asset accounting | — | Fiscal year variant |
| 6 | OAAQ | Assign chart of depreciation to co.code | T093 | Chart exists |
| 7 | SM30/ANKA | Asset class number ranges | NRIV | Before creating assets |
| 8 | AS01 | Create test asset | ANLA/ANLB | All above complete |
| 9 | ABZON | Post test acquisition | ANEK/ANEP | Test asset created |
| 10 | AFAB | Run test depreciation | ANLC/ANLP | Acquisition posted |

### Common Depreciation Keys

| Key | Method | Description | Typical Use |
|-----|--------|-------------|-------------|
| LINA | Straight-line (automatic) | Even distribution over useful life | Buildings, furniture |
| LINR | Straight-line (remaining) | Recalculates from remaining value | After revaluation |
| DEGR | Declining balance | Higher depreciation early years | Machinery, vehicles |
| GWG | Low-value asset | Full depreciation year 1 | Small equipment |
| 0000 | No depreciation | Manual only | Land, art |

### Account Determination (AO90)

| Transaction Type | Typical Account | Description |
|-----------------|-----------------|-------------|
| Acquisition (debit) | 200000 | Asset BS account |
| Accumulated depreciation | 209000 | Contra-asset account |
| Depreciation expense | 680000 | P&L depreciation |
| Gain on disposal | 710000 | P&L income |
| Loss on disposal | 720000 | P&L expense |
| Revenue from disposal | 410000 | Revenue account |

---

## Guide 5: Electronic Bank Statement

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Bank Accounting >
    Business Transactions > Payment Transactions >
      Electronic Bank Statement
```

### Configuration Steps

| Step | Action | Table | Details |
|------|--------|-------|---------|
| 1 | FI12: Define house bank + account | T012/T012K | Bank key, account ID, GL mapping |
| 2 | Define external transaction types | T028A | Map bank codes to SAP types |
| 3 | Define posting rules | T028B/T028D | Account assignment per transaction |
| 4 | Define interpretation algorithms | FEBKO/FEBEP | Auto-matching rules |
| 5 | Define account symbols | T028O | GL account shortcuts for posting |
| 6 | Test import | FEBA_BANK_STATEMENT | Import MT940/BAI2/CAMT.053 |
| 7 | Post statement | FF_5 | Process and post to GL |

### External Transaction Type Mapping

| Bank Code | SAP Ext. Type | Description | Posting Rule |
|-----------|--------------|-------------|-------------|
| TRF+ | 001 | Incoming transfer | Debit bank, credit clearing |
| TRF- | 002 | Outgoing transfer | Credit bank, debit clearing |
| CHK | 003 | Check clearing | Credit bank, debit check clearing |
| INT+ | 004 | Interest received | Debit bank, credit interest income |
| INT- | 005 | Interest paid | Credit bank, debit interest expense |
| FEE | 006 | Bank fees | Credit bank, debit bank charges |

---

## Guide 6: Tax Configuration

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Financial Accounting Global Settings >
    Tax on Sales/Purchases >
      Calculation > Define Tax Codes (FTXP)
```

### Configuration Steps

| Step | TCode | Action | Table |
|------|-------|--------|-------|
| 1 | OBYZ | Assign tax procedure to country | T005-KALSM |
| 2 | OBCL | Assign country to calculation procedure | T005 |
| 3 | FTXP | Create tax codes (input V*, output A*) | T007A/T007S |
| 4 | OB40 | Assign GL accounts to tax codes | T030K |
| 5 | OBWI | Extended withholding tax (if needed) | T059Z |
| 6 | Test: FB60/FB70 with tax code | — | Verify tax line posted |

### Common Tax Code Setup

| Code | Type | Rate | Description | GL Account |
|------|------|------|-------------|------------|
| V0 | Input | 0% | Tax exempt input | 154000 |
| V1 | Input | 19% | Standard input tax | 154000 |
| V2 | Input | 7% | Reduced input tax | 154000 |
| A0 | Output | 0% | Tax exempt output | 175000 |
| A1 | Output | 19% | Standard output tax | 175000 |
| A2 | Output | 7% | Reduced output tax | 175000 |

---

## Guide 7: Document Splitting (S/4HANA)

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > General Ledger Accounting >
    Business Transactions > Document Splitting
```

### Configuration Steps

| Step | Action | Details |
|------|--------|---------|
| 1 | Activate document splitting | Classify GL accounts, activate for company code |
| 2 | Define document splitting characteristics | Profit center, segment, business area |
| 3 | Define splitting method (0000000012 standard) | Business transaction variants |
| 4 | Define splitting rules per account | Assign splitting rule per GL account |
| 5 | Define zero-balance clearing account | For balancing entries |
| 6 | Activate inheritance | For items without direct assignment |
| 7 | Test: FB50 with cost center/profit center | Verify segment populated |

### Splitting Rule Types

| Rule | Description | Example |
|------|-------------|---------|
| Derive from leading item | Copy characteristics from revenue/expense line | Tax line inherits from expense |
| Proportional distribution | Split based on amounts of leading items | Payment across cost centers |
| Zero balance | Create additional lines to balance | Segment balancing |

### MCP SQL — Verify Document Splitting

```sql
-- Check if documents have proper segment/profit center splitting
SELECT a.BELNR, a.BUZEI, a.RACCT, a.KOART, a.PRCTR, a.SEGMENT,
       a.DMBTR, a.SHKZG
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.BELNR = '{document_number}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR = '0L'
ORDER BY a.BUZEI
```

---

## Guide 8: Parallel Accounting (Multi-Ledger)

### SPRO Path
```
SAP Customizing Implementation Guide >
  Financial Accounting > Financial Accounting Global Settings >
    Ledgers > Ledger > Define Ledgers (FINSC_LEDGER)
```

### Configuration Steps

| Step | TCode | Action | Table |
|------|-------|--------|-------|
| 1 | FINSC_LEDGER | Define ledgers | FINSC_LEDGER |
| 2 | Assign accounting principles | FINSC_LD_CMP | Map GAAP to ledger |
| 3 | Define ledger groups | FINSC_LEDGER | For posting control |
| 4 | Define doc types for ledger posting | T003 | Ledger group on doc type |
| 5 | Create ledger-specific GL accounts | FS00 | If valuation differs |
| 6 | Assign depreciation areas to ledgers | OADB | Asset valuation per GAAP |

### Standard Ledger Setup

| Ledger | Type | Accounting Principle | Description |
|--------|------|---------------------|-------------|
| 0L | Leading | LOCAL_GAAP | Local GAAP (mandatory) |
| 2L | Non-leading | IFRS | International Financial Reporting |
| 3L | Non-leading | TAX_GAAP | Tax accounting |
| 4L | Non-leading | US_GAAP | US GAAP (if needed) |

### MCP SQL — Compare Balances Across Ledgers

```sql
-- Balance comparison between leading and IFRS ledger
SELECT a.RACCT,
       SUM(CASE WHEN a.RLDNR = '0L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END
           ELSE 0 END) AS BALANCE_LOCAL,
       SUM(CASE WHEN a.RLDNR = '2L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END
           ELSE 0 END) AS BALANCE_IFRS,
       SUM(CASE WHEN a.RLDNR = '0L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END
           ELSE 0 END) -
       SUM(CASE WHEN a.RLDNR = '2L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END
           ELSE 0 END) AS DIFFERENCE
FROM ACDOCA AS a
WHERE a.BUKRS = '{company_code}'
  AND a.GJAHR = '{fiscal_year}'
  AND a.RLDNR IN ('0L', '2L')
GROUP BY a.RACCT
HAVING ABS(SUM(CASE WHEN a.RLDNR = '0L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END ELSE 0 END) -
       SUM(CASE WHEN a.RLDNR = '2L' THEN
           CASE WHEN a.SHKZG = 'S' THEN a.DMBTR ELSE -a.DMBTR END ELSE 0 END)) > 0.01
ORDER BY a.RACCT
```

---

## Quick Reference — Key Configuration Tables

| Table | Description | Key TCode |
|-------|-------------|-----------|
| T001 | Company codes | OX02 |
| T001B | Posting period control | OB52 |
| T003 | Document types | OBA7 |
| T007A | Tax codes | FTXP |
| T009 | Fiscal year variants | OB29 |
| T012 | House banks | FI12 |
| T028B | Bank statement posting rules | SPRO |
| T030 | Account determination | OB40 |
| T042 | Payment program config | FBZP |
| T043 | Tolerance groups | OBA0 |
| T074 | Special GL indicators | OBYR |
| T093 | Chart of depreciation | OADB |
| NRIV | Number ranges | FBN1 |
| FINSC_LEDGER | Ledger definitions | FINSC_LEDGER |
