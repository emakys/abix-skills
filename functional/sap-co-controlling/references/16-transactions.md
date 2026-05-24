# Transacciones CO — Catalogo Completo

## Datos Maestros

| TCode | Descripcion | Objeto |
|-------|-------------|--------|
| KS01/KS02/KS03 | Crear/Modificar/Visualizar CC | Centro coste |
| KSH1/KSH2/KSH3 | Crear/Modificar/Visualizar grupo CC | Grupo CC |
| OKEON | Actualizar jerarquia estandar CC | Jerarquia CC |
| KE51/KE52/KE53 | Crear/Modificar/Visualizar PC | Profit center |
| KCH1/KCH2/KCH3 | Actualizar jerarquia estandar PC | Jerarquia PC |
| KO01/KO02/KO03 | Crear/Modificar/Visualizar orden | Orden interna |
| KA01/KA02/KA03 | Crear/Modificar/Visualizar clase coste (ECC) | Clase coste |
| KL01/KL02/KL03 | Crear/Modificar/Visualizar clase actividad | Clase actividad |
| KK01/KK02/KK03 | Crear/Modificar/Visualizar cifra estadistica | Cifra estad. |

## Planificacion

| TCode | Descripcion |
|-------|-------------|
| KP06 | Plan costes/ingresos CC |
| KP26 | Plan actividades/tarifas CC |
| KP46 | Plan cifras estadisticas CC |
| KPF6 | Plan costes orden |
| KO22 | Presupuesto orden (original) |
| KO24 | Suplemento presupuesto |
| KEPM | Planificacion CO-PA |
| KP97 | Copiar plan entre versiones |

## Contabilizacion Real

| TCode | Descripcion |
|-------|-------------|
| KB21N | Contabilizar actividad interna |
| KB11N | Recontabilizar costes |
| KB61 | Recontabilizar lineas CO |
| KB31N | Contabilizar cifra estadistica |

## Cierre de Periodo

| TCode | Descripcion | Orden |
|-------|-------------|-------|
| KSV5 | Ejecutar distribucion | 3 |
| KSU5 | Ejecutar assessment | 4 |
| KSPI | Calculo tarifa real | 6 |
| CO43 | Overhead ordenes produccion | 7 |
| KGI2 | Overhead ordenes internas | 8 |
| KKAO | Calculo WIP | 9 |
| KKS1 | Calculo desviaciones | 10 |
| KO88 | Liquidacion ordenes internas | 11 |
| CO88 | Liquidacion ordenes produccion | 12 |
| CKMLCP | Cierre Material Ledger | 13 |
| KEU5 | Transferencia CO-PA | 14 |
| CK40N | Costing run (calculo masivo) | Pre-cierre |
| CK24 | Marcar/Liberar precio estandar | Pre-cierre |

## Reporting

| TCode | Descripcion | Area |
|-------|-------------|------|
| KSB1 | Partidas individuales CC | CC |
| KOB1 | Partidas individuales orden | Orden |
| KE5Z | Partidas individuales CO-PA | CO-PA |
| S_ALR_87013611 | Plan/Real CC | CC |
| S_ALR_87013620 | Plan/Real PC | PC |
| S_ALR_87012993 | Partidas individuales orden | Orden |
| KE30 | Reporte CO-PA | CO-PA |
| CK13N | Visualizar calculo costes | Product costing |
| CKM3N | Cockpit Material Ledger | ML |

## Configuracion

| TCode | Descripcion | Area |
|-------|-------------|------|
| OKKP | Actualizar area controlling | Org |
| OX19 | Asignar sociedad a area CO | Org |
| OKEQ | Definir versiones plan | Planning |
| OKIZ | Categorias CC | CC |
| KOT2 | Tipos de orden | Orden |
| KONK | Rangos numeros ordenes | Orden |
| OKO7 | Perfil liquidacion | Settlement |
| OKB9 | Creacion auto clases coste | Cost element |
| KZS2 | Hoja de recargo | Overhead |
| KEKE | Activar CO-PA | CO-PA |
| KEA0 | Estructura operativa CO-PA | CO-PA |
