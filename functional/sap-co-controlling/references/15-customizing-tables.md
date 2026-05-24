# Tablas de Customizing CO

## Estructura organizativa

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| TKA01 | Area de controlling | OKKP |
| TKA02 | Sociedad → Area CO | OX19 |
| TKA09 | Versiones de plan | OKEQ |

## Centros de coste

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| CSKS | Datos maestros CC | KS01/KS02/KS03 |
| CSKT | Textos CC | KS01 |
| TKOSA | Categorias CC | OKIZ |
| SETHEADER/SETNODE | Grupos y jerarquias | KSH1/OKEON |

## Centros de beneficio

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| CEPC | Datos maestros PC | KE51/KE52/KE53 |
| CEPCT | Textos PC | KE51 |
| SETHEADER/SETNODE | Grupos y jerarquias | KCH1/KCH5N |

## Ordenes internas

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| AUFK | Datos maestros orden | KO01/KO02/KO03 |
| COBRB | Regla de liquidacion | KO02 |
| T003O / T003OT | Tipos de orden | KOT2 |
| JEST / TJ02 | Status sistema | — |

## Clases de coste / Cuentas

| Tabla | Descripcion | Sistema |
|-------|-------------|---------|
| CSKA | Clases coste secundarias | ECC + S/4 |
| SKA1 / SKB1 | Cuentas GL (= cost elements) | S/4HANA |

## Actividades y cifras estadisticas

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| CSLA / CSLAT | Clases de actividad | KL01 |
| TCA01 / TCA01T | Cifras estadisticas | KK01 |

## Product Costing

| Tabla | Descripcion | TCode |
|-------|-------------|-------|
| KEKO | Cabecera calculo costes | CK13N |
| KEPH | Componentes de coste | CK13N |
| MBEW | Precios material (stock) | MM03 |
| CKMLHD | Cabecera Material Ledger | CKM3N |

## Documentos CO

| Tabla | Descripcion | Sistema |
|-------|-------------|---------|
| ACDOCA | Universal Journal | S/4HANA |
| COBK | Cabecera doc CO | ECC |
| COEP | Posiciones doc CO | ECC |
| COSS | Totales costes secundarios | ECC |
| COSP | Totales costes primarios | ECC |
