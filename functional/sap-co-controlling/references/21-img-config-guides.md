# Guias de Configuracion IMG — CO

## Estructura Organizativa

| Paso | SPRO Path | TCode | Tabla |
|------|-----------|-------|-------|
| 1 | Controlling > Organizacion > Actualizar area controlling | OKKP | TKA01 |
| 2 | Controlling > Organizacion > Asignar sociedad a area CO | OX19 | TKA02 |

## Contabilidad Centros de Coste

| Paso | SPRO Path | TCode | Tabla |
|------|-----------|-------|-------|
| 1 | CO > CC Accounting > Master Data > Cost Center Categories | OKIZ | TKOSA |
| 2 | CO > CC Accounting > Master Data > Standard Hierarchy | OKEON | SETHEADER |
| 3 | CO > CC Accounting > Master Data > Activity Types | KL01 | CSLA |
| 4 | CO > CC Accounting > Master Data > Statistical Key Figures | KK01 | TCA01 |
| 5 | CO > CC Accounting > Planning > Define Versions | OKEQ | TKA09 |
| 6 | CO > CC Accounting > Period-End Closing > Distribution | KSV1 | — |
| 7 | CO > CC Accounting > Period-End Closing > Assessment | KSU1 | — |

## Ordenes CO

| Paso | SPRO Path | TCode | Tabla |
|------|-----------|-------|-------|
| 1 | CO > Internal Orders > Master Data > Define Order Types | KOT2 | T003O |
| 2 | CO > Internal Orders > Master Data > Define Number Ranges | KONK | NRIV |
| 3 | CO > Internal Orders > Budgeting > Define Budget Profile | — | — |
| 4 | CO > Internal Orders > Budgeting > Define Tolerances | OKTZ | — |
| 5 | CO > Internal Orders > Actual Postings > Define Settlement Profile | OKO7 | — |

## Product Cost Controlling

| Paso | SPRO Path | TCode | Tabla |
|------|-----------|-------|-------|
| 1 | CO > Product Cost Controlling > Product Cost Planning > Costing Variant | OKKN | — |
| 2 | CO > Product Cost Controlling > Product Cost Planning > Costing Sheet | KZS2 | — |
| 3 | CO > Product Cost Controlling > Cost Object Controlling > Variance Variants | OKV1 | — |
| 4 | CO > Product Cost Controlling > Cost Object Controlling > WIP Valuation | OKG1 | — |
| 5 | CO > Product Cost Controlling > Actual Costing/ML > Activate ML | CKMSTART | — |

## CO-PA

| Paso | SPRO Path | TCode | Tabla |
|------|-----------|-------|-------|
| 1 | CO > Profitability Analysis > Structures > Define Operating Concern | KEA0 | TKEB* |
| 2 | CO > Profitability Analysis > Structures > Define Characteristics | KEA5 | — |
| 3 | CO > Profitability Analysis > Flows of Actual Values > Activate CO-PA | KEKE | — |
| 4 | CO > Profitability Analysis > Flows of Actual Values > Define Derivation | KEDR | — |
