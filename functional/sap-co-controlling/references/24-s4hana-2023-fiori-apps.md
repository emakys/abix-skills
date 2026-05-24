# S/4HANA 2023 — Fiori Apps CO

Catalogo de Fiori apps para Controlling en S/4HANA 2023.
Fuente: SAP Fiori Apps Reference Library (fioriappslibrary.hana.ondemand.com)

## Cost Center Accounting

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F0998 | Manage Cost Centers | Transactional | KS01/KS02 |
| F3066 | Display Cost Center Costs | Analytical | S_ALR_87013611 |
| F2723 | Cost Center — Plan/Actual | Analytical | S_ALR_87013611 |
| F3814 | Display Cost Center Line Items | Analytical | KSB1 |
| F0842 | Manage Cost Rates | Transactional | KP26 |
| F2003 | Manage Activity Types | Transactional | KL01 |
| F4108 | Manage Statistical Key Figures | Transactional | KK01 |
| F1489 | Post Reposting of Costs | Transactional | KB61 |
| F4580 | Manage Allocations | Transactional | KSV1/KSU1 |
| F2234 | Manage Overhead Rates | Transactional | KZS2 |

## Profit Center Accounting

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F0999 | Manage Profit Centers | Transactional | KE51/KE52 |
| F3737 | Profit Center — Actual | Analytical | S_ALR_87013620 |
| F3738 | Profit Center — Plan/Actual | Analytical | S_ALR_87013620 |
| F3264 | Profit Center Group — Actual | Analytical | S_ALR_87013620 |

## Internal Orders

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F1599 | Manage Internal Orders | Transactional | KO01/KO02 |
| F1603 | Internal Order — Plan/Actual | Analytical | S_ALR_87012993 |
| F1604 | Internal Order — Budget/Actual | Analytical | S_ALR_87012996 |

## CO-PA / Margin Analysis

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F5765 | Profitability Analysis | Analytical | KE30 |
| F5889 | Margin Analysis | Analytical | — (nuevo) |
| F4012 | Contribution Margin | Analytical | — (nuevo) |
| F5891 | Margin Analysis — Drilldown | Analytical | — (nuevo) |
| F6085 | Manage Profitability Segments | Transactional | KE4 |

## Product Costing

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F0710 | Manage Product Cost Estimates | Transactional | CK11N |
| F0711 | Display Cost Estimate | Analytical | CK13N |
| F2839 | Material Price Analysis | Analytical | CKM3N |
| F3601 | Display Costing Run | Transactional | CK40N |

## Universal Journal / Line Items

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F2709 | Display Line Items | Analytical | KSB1/KOB1/FBL3N |
| F0706 | Journal Entries | Transactional | FB50 |

## Period Close

| App ID | Nombre | Tipo | TCode equiv |
|--------|--------|------|-------------|
| F1596 | Schedule Period-End Closing | Transactional | — |
| F4804 | Monitor Period-End Closing | Monitoring | — |
| F3602 | Close Material Ledger | Transactional | CKMLCP |

## Semantic Objects

| Semantic Object | Accion | App |
|----------------|--------|-----|
| CostCenter | manage | F0998 |
| CostCenter | displayActual | F3066 |
| ProfitCenter | manage | F0999 |
| InternalOrder | manage | F1599 |
| CostEstimate | manage | F0710 |
| JournalEntry | displayLineItems | F2709 |
| ProfitabilityAnalysis | analyze | F5765 |
| MarginAnalysis | analyze | F5889 |
