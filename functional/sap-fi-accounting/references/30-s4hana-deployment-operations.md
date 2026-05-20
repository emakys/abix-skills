# S/4HANA 2023 — Deployment & Operations FI

## Transport Management para FI Customizing

### Objetos transportables FI

| Area | Objetos tipicos | Orden tipo |
|------|----------------|-----------|
| Chart of Accounts | SKA1, T077S, account groups | Workbench |
| Company Code config | T001 settings, T001B periods | Customizing |
| Document Types | T003, number ranges NRIV | Customizing |
| Posting Keys | TBSL, field status T004 | Customizing |
| Payment Program | T042*, FBZP config | Customizing |
| Dunning | T047* | Customizing |
| Tax | T007A/B, FTXP | Customizing |
| Asset Accounting | T093*, ANKA, T090*, T095* | Customizing |
| Automatic Postings | T030 (OBYC/OB40) | Customizing |
| GL Account Master | SKA1/SKB1 | Workbench |
| FSV | Financial statement version | Customizing |
| Validations/Substitutions | GGB1/GGB4 rules | Workbench |

### Secuencia de transporte recomendada

```
1. Org structure (T001, chart of accounts)
2. Basic config (doc types, posting keys, field status)
3. GL accounts (chart of accounts level first, then company code)
4. Tax config (procedure, codes, account assignment)
5. Automatic postings (OBYC, OB40)
6. Payment config (FBZP)
7. Asset Accounting (dep areas, classes, keys)
8. Dunning config
9. Bank config
10. Validations/Substitutions
11. Custom developments (BAdIs, reports)
```

### Number Ranges — Consideracion especial

```
Number ranges (FBN1, NRIV) NO se transportan por defecto.
Opciones:
  1. Transporte manual: SNRO → Object → Transport
  2. Crear en cada sistema manualmente
  3. Script ABAP para inicializar

CRITICO: No transportar intervalos que ya tienen documentos asignados
→ Solo transportar la definicion, no el current number
```

## Feature Toggles / Business Functions

```
S/4HANA 2023 — Features relevantes FI:

SFW5 (Switch Framework) activaciones:
  FIN_GL_CI_1    → New GL functions
  FIN_AA_CI_1    → New Asset Accounting
  FIN_FSCM_CR    → Credit Management (UKM)
  FIN_FSCM_CLM   → Collections Management
  FIN_FSCM_DM    → Dispute Management
  LOG_MM_CI_1    → Invoice Verification enhancements
  FIN_ACC_ACDOCA → Universal Journal (always on in S/4)

Fiori Feature Flags:
  /UI2/FLP → Manage Launchpad Settings → feature toggles
```

## Test Script — Record-to-Report (R2R)

```
Escenario E2E de prueba para FI:

1. MASTER DATA
   [ ] Crear/verificar GL accounts (FS00)
   [ ] Crear/verificar BP vendor (BP, role FLVN00)
   [ ] Crear/verificar BP customer (BP, role FLCU00)
   [ ] Crear/verificar asset master (AS01)
   [ ] Verificar periodos abiertos (OB52)

2. TRANSACTIONAL POSTING
   [ ] GL manual posting (FB50) → verificar ACDOCA
   [ ] Vendor invoice (FB60) → verificar AR recon account
   [ ] Customer invoice (FB70) → verificar AP recon account
   [ ] Asset acquisition (ABZON) → verificar ACDOCA KOART='A'
   [ ] Down payment vendor (F-48) → verificar special GL
   [ ] Down payment customer (F-29) → verificar special GL

3. PAYMENTS & CLEARING
   [ ] Payment run (F110) → proposal + payment
   [ ] Manual payment customer (F-28)
   [ ] Clear vendor down payment (F-54)
   [ ] Clear customer down payment (F-39)
   [ ] Verify clearing docs (AUGDT populated in ACDOCA)

4. BANK
   [ ] Import bank statement (FF_5)
   [ ] Post bank statement → verify auto-matching
   [ ] Reconcile bank GL vs statement

5. PERIOD CLOSE
   [ ] Foreign currency valuation (FAGL_FCV)
   [ ] Depreciation run (AFAB)
   [ ] GR/IR reclassification (F.19)
   [ ] Accrual posting (FBS1) + reversal (F.81)
   [ ] Recurring doc execution (F.14)
   [ ] Close period (OB52)

6. YEAR-END
   [ ] Balance carryforward GL (FAGLGVTR)
   [ ] Balance carryforward AP/AR (F.07)
   [ ] Asset year-end close (AJAB)
   [ ] Fiscal year change (AJRW)
   [ ] Verify retained earnings

7. REPORTING
   [ ] Trial balance (FAGLB03 / F3736 Fiori)
   [ ] Financial statements (S_ALR_78012547 / F0706)
   [ ] Vendor line items (FBL1N / F0717A)
   [ ] Customer line items (FBL5N / F0717B)
   [ ] Asset explorer (AW01N / F2403)
```

## Regression Checklist — Post-Transport

```
Verificaciones despues de transportar config FI:

General:
  [ ] Periodos abiertos correctos (OB52)
  [ ] Document types available (OBA7)
  [ ] Number ranges assigned and available (FBN1)
  [ ] Field status groups correct (OBC4)
  [ ] Tolerance groups defined (OBA0)

GL:
  [ ] GL accounts exist in target (FS00)
  [ ] Account groups correct (OBD4)
  [ ] Retained earnings account (OB53)

AP/AR:
  [ ] Reconciliation accounts assigned
  [ ] Payment terms available (OBB8)
  [ ] Payment methods configured (FBZP)
  [ ] Dunning procedure assigned

Tax:
  [ ] Tax codes active (FTXP)
  [ ] Tax accounts assigned (OB40)
  [ ] WHT types/codes (OBWI)

AA:
  [ ] Depreciation areas active (OADB)
  [ ] Asset classes available (OAOA)
  [ ] Account determination (AO90)
  [ ] Depreciation keys (AFAMA)

Auto-postings:
  [ ] OBYC accounts verified
  [ ] OB40 accounts verified
  [ ] OB09 FX accounts verified
```

## Monitoring & Batch Jobs

### Jobs periodicos FI

| Job | Programa | Frecuencia | Descripcion |
|-----|----------|-----------|-------------|
| Depreciation run | RAPOST2000 (AFAB) | Mensual | Post depreciation |
| FX valuation | FAGL_FCV | Mensual/diario | Foreign currency revaluation |
| Payment run | SAPF110V | Diario/semanal | Automatic payments |
| Dunning run | SAPF150 | Semanal/mensual | Dunning letters |
| Bank statement | RFEBKA00 | Diario | Import & post EBS |
| Recurring entries | SAPF120 (F.14) | Mensual | Execute recurring docs |
| Accrual reversal | SAPF100 (F.81) | Mensual | Reverse accruals |
| GR/IR reclass | F.19 | Mensual | Reclassify GR/IR |
| Balance carryforward | FAGLGVTR | Anual | GL balance forward |
| Interest calculation | SAPF_INTRST (F.52) | Mensual | Interest on items |
| Correspondence | RFKORD00 | Diario | Account statements |

### Transacciones de monitoreo

| TCode | Proposito |
|-------|-----------|
| SM37 | Job monitor (verify batch jobs) |
| SM21 | System log (errors) |
| SLG1 | Application log (posting errors) |
| ST22 | ABAP dumps |
| FAGLB03 | GL balance verification |
| FBL1N/FBL3N/FBL5N | Line item verification |
| F.03 | GL reconciliation |
| F.04 | Subledger-GL comparison |
| ABST2 | Reconciliation AA-GL |
| AW01N | Asset verification |

## Situation Handling — Alertas FI

```
Situaciones predefinidas para FI:

- Journal Entry Needs Approval
- Payment Run Failed
- Overdue Receivables Threshold Exceeded
- Bank Statement Import Error
- FX Valuation Differences Above Threshold
- Depreciation Run Not Executed
- Period Not Closed on Schedule
- Intercompany Reconciliation Mismatch

Config: SPRO → Cross-Application → Situation Handling →
  Define Situation Types → Assign Anchor Objects
```

## ECC → S/4HANA Migration — Impacto FI

| Componente ECC | Cambio S/4 | Accion migracion |
|---------------|-----------|-----------------|
| BSEG (tabla real) | Vista sobre ACDOCA | Migrar custom reports |
| GLT0/KNC1-3/LFC1-3 | Eliminadas | Reports usar ACDOCA |
| Classic AA (ANLC/ANLP) | New AA en ACDOCA | RASFIN_MIGRATION |
| KNA1/LFA1 standalone | BP obligatorio | CVI + BUPA_MIGRATION |
| FD32 credit | UKM | Migrar limites credito |
| EC-PCA | ACDOCA PRCTR | No accion (automatico) |
| Special Purpose Ledger | Extension ledger | Redisenar |
| CO-PA costing-based | Account-based COPA | Migrar operative concern |
| Classic GL | New GL (ACDOCA) | Automatico con migration |
| FBCJ Cash Journal | Enhanced CM | Migrar cash journal config |

### Custom code adaptation

```
Herramientas:
  SYCM: Custom Code Migration Worklist
  ATC: ABAP Test Cockpit (check simplification DB)
  /UI2/FIORI_CONTENT: Fiori content check

Patrones de cambio mas comunes:
  1. SELECT FROM BSEG → SELECT FROM ACDOCA
  2. SELECT FROM GLT0 → Aggregate FROM ACDOCA
  3. SELECT FROM BSIS/BSAS → ACDOCA WHERE KOART='S'
  4. KNA1-KUNNR → BUT000-PARTNER (via BP)
  5. LFA1-LIFNR → BUT000-PARTNER (via BP)
  6. ANLC fields → ACDOCA WHERE KOART='A'
```
