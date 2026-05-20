# Errores Comunes MM — Diagnostico y Solucion

## Metodologia de diagnostico

```
1. Obtener clase mensaje + numero:  GetSqlQuery("SELECT * FROM T100 WHERE ARBGB='{clase}' AND MSGNR='{num}'")
2. Encontrar programa fuente:       GetWhereUsed("{clase} {num}")  o  SearchObject("{programa}")
3. Leer codigo:                     ReadProgram("{programa}")  buscar MESSAGE...{num}
4. Verificar datos:                 GetSqlQuery en tablas relacionadas
5. Dar solucion:                    Transaccion + pasos + impacto
```

## Errores de Pedido de Compra (ME21N/ME22N)

### M7 032 — No purchasing info record exists
- **Causa**: Falta info record para proveedor + material
- **Programa**: SAPLME07
- **Verificar**: `SELECT * FROM EINA WHERE MATNR='{mat}' AND LIFNR='{prov}'`
- **Config**: `SELECT INFKZ FROM T161 WHERE BSART='{tipo}'` (INFKZ=X -> obligatorio)
- **Fix A**: ME11 crear info record
- **Fix B**: Cambiar T161-INFKZ a ' ' (no recomendado)

### M7 052 — Vendor not extended to purchasing org
- **Causa**: Proveedor no tiene datos en la org compras
- **Verificar**: `SELECT * FROM LFM1 WHERE LIFNR='{prov}' AND EKORG='{org}'`
- **Fix**: MK01 (ECC) o BP (S/4) extender proveedor a org compras

### M7 060 — Material not maintained in plant
- **Causa**: Material sin vista de compras/MRP en el centro
- **Verificar**: `SELECT * FROM MARC WHERE MATNR='{mat}' AND WERKS='{centro}'`
- **Fix**: MM01 ampliar material al centro (vistas Compras + MRP)

### ME 206 — Purchase order still to be released
- **Causa**: PO requiere aprobacion y no ha sido liberada
- **Verificar**: `SELECT FRGSX,FRGKE,FRGZU FROM EKKO WHERE EBELN='{po}'`
- **Config**: `SELECT * FROM T16FS WHERE FRGSX='{strategy}'`
- **Fix**: ME28/ME29N liberar pedido

### M7 055 — Source of supply could not be determined
- **Causa**: Sin fuente de suministro valida (source list/info record/contrato)
- **Verificar**: `SELECT * FROM EORD WHERE MATNR='{mat}' AND WERKS='{centro}'`
- **Config**: `SELECT SRCLIST FROM T161 WHERE BSART='{tipo}'`
- **Fix A**: ME01 crear source list
- **Fix B**: ME11 crear info record
- **Fix C**: Desactivar requerimiento en T161-SRCLIST

### ME 013 — Item category not allowed for this document type
- **Causa**: Combinacion tipo doc + categoria posicion no permitida
- **Config**: `SELECT * FROM T163 WHERE PSTYP='{pstyp}'`
- **Fix**: Revisar T163/OMEC config de categorias permitidas

## Errores de Entrada de Mercancias (MIGO)

### M7 060 — Material not maintained in plant (en GR)
- **Causa**: Mismo que en PO pero al registrar GR
- **Fix**: MM01 ampliar material al centro

### 06 024 — Movement type not allowed
- **Causa**: Tipo movimiento no configurado para la operacion
- **Config**: `SELECT * FROM T156 WHERE BWART='{tm}'`
- **Fix**: OMJJ revisar configuracion del tipo movimiento

### M8 580 — Automatic account determination not possible
- **Causa**: Falta configuracion de cuentas automaticas (OBYC)
- **Config**: `SELECT * FROM T030 WHERE KTOPL='{plan}' AND KTOSL='BSX'`
- **Verificar**: `SELECT BKLAS FROM MBEW WHERE MATNR='{mat}' AND BWKEY='{centro}'`
- **Fix**: OBYC asignar cuenta para la combinacion KTOSL + BKLAS

### M7 154 — Negative stock not allowed
- **Causa**: Stock resultante seria negativo y no esta permitido
- **Verificar**: `SELECT LABST FROM MARD WHERE MATNR='{mat}' AND WERKS='{c}' AND LGORT='{a}'`
- **Config**: OMJJ -> tipo movimiento -> permitir stock negativo (no recomendado)
- **Fix**: Corregir secuencia de movimientos o ajustar stock

### M8 351 — Tolerance exceeded for price variance
- **Causa**: Diferencia entre precio PO y precio GR
- **Config**: `SELECT * FROM T169G WHERE BUKRS='{soc}'`
- **Fix**: OMR6 ajustar tolerancias o corregir precio

## Errores de Verificacion Facturas (MIRO)

### MR 020 — Invoice blocked
- **Causa**: Varianza precio/cantidad excede tolerancia
- **Verificar**: `SELECT ZLSPR FROM RBKP WHERE BELNR='{factura}'`
- **Fix**: MRBR liberar factura o corregir diferencia

### MR 011 — GR quantity insufficient
- **Causa**: Cantidad facturada > cantidad recibida
- **Verificar**: `SELECT WEMNG,REMNG FROM EKPO WHERE EBELN='{po}' AND EBELP='{pos}'`
- **Fix**: Registrar GR faltante (MIGO) o ajustar factura

### MR 521 — No goods receipt for this PO item
- **Causa**: No hay entrada de mercancias registrada
- **Verificar**: `SELECT * FROM EKBE WHERE EBELN='{po}' AND EBELP='{pos}' AND VGABE='1'`
- **Fix**: MIGO registrar GR primero

### M8 147 — Tax code invalid
- **Causa**: Codigo impuesto no valido para el pais/sociedad
- **Config**: `SELECT * FROM A003 WHERE APTS='{tax_code}'`
- **Fix**: FTXP revisar/crear codigo impuesto

## Errores de MRP (MD01/MD02)

### MD 205 — MRP type not maintained
- **Causa**: Material sin tipo MRP en el centro
- **Verificar**: `SELECT DISMM FROM MARC WHERE MATNR='{mat}' AND WERKS='{centro}'`
- **Fix**: MM02 -> MRP1 -> asignar tipo MRP (VB, PD, VV, etc)

### MD 045 — MRP controller not defined
- **Causa**: Falta planificador MRP en el centro
- **Verificar**: `SELECT DISPO FROM MARC WHERE MATNR='{mat}' AND WERKS='{centro}'`
- **Config**: `SELECT * FROM T024D WHERE WERKS='{centro}'`
- **Fix**: MM02 -> MRP1 -> asignar planificador

## Template de diagnostico para chat

Cuando el usuario reporte un error, seguir este patron:

```
1. "Dame la clase y numero del mensaje (ej: M7 032)"
2. Consultar T100 -> texto exacto
3. Identificar transaccion y operacion
4. Consultar tablas de datos maestros relevantes
5. Consultar customizing relacionado
6. Si es necesario, leer codigo fuente del programa
7. Dar solucion con pasos concretos
8. Advertir impacto cross-module si aplica
```
