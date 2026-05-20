# Asset Accounting (FI-AA)

## Resumen

La contabilidad de activos fijos (FI-AA) en S/4HANA se integra nativamente en ACDOCA, eliminando las tablas clasicas de totales (ANLC, ANLP). Soporta valoracion paralela nativa con multiples areas de depreciacion (libro, fiscal, IFRS, costes). Los procesos principales incluyen: gestion de datos maestros, adquisiciones, transferencias, retiros, depreciacion periodica y cierre de ejercicio.

---

## Cambios en S/4HANA — New Asset Accounting

| Aspecto | ECC (Clasico) | S/4HANA (Nuevo) |
|---------|---------------|-----------------|
| Tabla de valores | ANLC (totales anuales) | ACDOCA (linea por linea) |
| Tabla de movimientos | ANLP (periodicos) | ACDOCA |
| Cabecera documento | ANEK | ACDOCA (AWTYP = 'ANLA') |
| Valoracion paralela | Delta posting (area 01 base) | Cada area postea independiente |
| Ledger | Un solo ledger | Multi-ledger nativo |
| Real-time | Batch en depreciacion | Real-time integration |

### Tablas que siguen activas en S/4HANA

| Tabla | Descripcion | Uso |
|-------|-------------|-----|
| ANLA | Datos maestros de activos | Maestro general |
| ANLB | Terminos de depreciacion | Parametros por area |
| ANLZ | Asignaciones temporales | Centro coste, orden, etc. |
| ANLT | Textos de activos | Descripciones |
| ANLH | Historial de activos | Datos historicos maestro |
| ANEK | Cabecera doc AA (legacy) | Vista de compatibilidad |

---

## Datos Maestros de Activos

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| AS01 | Crear activo fijo |
| AS02 | Modificar activo fijo |
| AS03 | Visualizar activo fijo |
| AS04 | Bloquear activo |
| AS05 | Eliminar activo |
| AS91 | Crear activo con valores (legacy transfer) |
| AS21 | Crear sub-activo |

### Estructura del Maestro

| Pestana | Campos Principales |
|---------|-------------------|
| General | Clase activo, descripcion, nro serie, cantidad |
| Imputacion | Centro coste, orden interna, elemento PEP, centro beneficio |
| Contabilizacion | Area depreciacion, fecha capitalizacion |
| Dependiente tiempo | Centro coste variable, area empresarial |
| Origen | Proveedor, fabricante, pais origen |
| Seguros | Valor asegurado, poliza |

---

## Clases de Activo (OAOA)

### SPRO Path
```
SPRO → Gestion financiera → Contabilidad de activos fijos →
  Estructuras organizativas → Clases de activo →
  Definir clases de activo (OAOA)
```

### Clases Tipicas

| Clase | Descripcion | Vida Util Tipica |
|-------|-------------|-----------------|
| 1000 | Terrenos | Sin depreciacion |
| 2000 | Edificios | 20-50 anos |
| 3000 | Maquinaria | 8-15 anos |
| 3100 | Equipo de produccion | 5-10 anos |
| 4000 | Vehiculos | 4-8 anos |
| 5000 | Mobiliario | 5-10 anos |
| 6000 | Equipo informatico | 3-5 anos |
| 7000 | Activos intangibles | 3-10 anos |
| 8000 | Activos en construccion (AuC) | Sin depreciacion |
| 9000 | Activos de bajo valor (GWG) | Inmediata |

---

## Determinacion de Cuentas (AO90)

### SPRO Path
```
SPRO → Gestion financiera → Contabilidad de activos fijos →
  Determinacion de cuentas → Asignar cuentas (AO90)
```

### Cuentas por Clase de Activo

| Tipo Cuenta | Descripcion | Ejemplo |
|-------------|-------------|---------|
| Adquisicion | Cuenta de activo al adquirir | 1400000 |
| Amortizacion acumulada | Contra-cuenta de depreciacion | 1409000 |
| Gasto depreciacion | Gasto en PyG | 6100000 |
| Ganancia por retiro | Ingreso al vender > valor neto | 7600000 |
| Perdida por retiro | Gasto al vender < valor neto | 6700000 |
| Compensacion adquisicion | Contrapartida de adquisicion | 1400090 |
| Revalorizacion | Cuenta de ajuste por revaluacion | 1405000 |

---

## Areas de Depreciacion

| Area | Descripcion | Ledger | Uso |
|------|-------------|--------|-----|
| 01 | Libro (leading) | 0L | Valoracion contable principal |
| 02 | Fiscal / Tax | — | Depreciacion fiscal (acelerada) |
| 03 | Grupo / Consolidacion | — | Consolidacion corporativa |
| 10 | Costes | — | Depreciacion a centros de coste |
| 15 | IFRS | 2L | Normas internacionales |
| 20 | Valoracion local IFRS | — | Ajustes locales IFRS |
| 30 | Gestion interna | — | Reporting interno |

### SPRO Path
```
SPRO → Gestion financiera → Contabilidad de activos fijos →
  Valoracion → Areas de depreciacion → Definir areas de depreciacion
```

---

## Claves y Metodos de Depreciacion

### Claves Estandar (AFAMA)

| Clave | Metodo | Descripcion |
|-------|--------|-------------|
| LINA | Lineal | Depreciacion lineal sobre vida util |
| DG10 | Degresivo 10% | Declining balance 10% |
| DG15 | Degresivo 15% | Declining balance 15% |
| DG20 | Degresivo 20% | Declining balance 20% |
| GWG | Inmediata | 100% en primer ano (bajo valor) |
| 0000 | Sin depreciacion | Terrenos, AuC |
| LINM | Lineal manual | Con control manual de periodos |
| UNIT | Unidad produccion | Basado en unidades producidas |

### SPRO Path
```
SPRO → Gestion financiera → Contabilidad de activos fijos →
  Valoracion → Depreciacion → Metodos de depreciacion →
  Claves de depreciacion → Definir (AFAMA)
```

---

## Transacciones de Activos

### Adquisicion

| Transaccion | Descripcion |
|-------------|-------------|
| ABZON | Adquisicion externa sin proveedor |
| AB01 | Adquisicion con proveedor (integrada) |
| F-90 | Adquisicion via FI (factura proveedor) |
| ABNAN | Post-capitalizacion |
| AB08 | Anulacion de adquisicion |

### Transferencia

| Transaccion | Descripcion |
|-------------|-------------|
| ABUMN | Transferencia dentro de sociedad |
| ABT1N | Transferencia entre sociedades |

### Retiro / Baja

| Transaccion | Descripcion |
|-------------|-------------|
| ABAON | Retiro con ingreso (venta) |
| ABN1 | Desguace (scrapping sin ingreso) |
| ABAVN | Retiro parcial |
| AB08 | Anulacion de retiro |

### Revalorizacion

| Transaccion | Descripcion |
|-------------|-------------|
| ABAW | Revalorizacion |
| ABZU | Saneamiento / write-up |

---

## Ejecucion de Depreciacion (AFAB)

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| AFAB | Ejecutar depreciacion periodica |
| AFAR | Recalcular depreciacion |
| AFBP | Contabilizar depreciacion planificada |
| AFBN | Contabilizar depreciacion no planificada |

### Flujo AFAB

```
AFAB → Seleccionar sociedad y periodo
  → Modo test (verificar sin contabilizar)
  → Modo productivo (genera documentos)
    → Un documento por activo y area
    → Debito: gasto depreciacion (PyG)
    → Credito: amortizacion acumulada (Balance)
```

### Parametros AFAB

| Campo | Descripcion |
|-------|-------------|
| Sociedad | Sociedad a ejecutar |
| Ejercicio | Ano fiscal |
| Periodo | Periodo de contabilizacion |
| Motivo ejecucion | 01=planificada, 02=no planificada, 03=repeat |
| Modo test | X = solo simulacion |

---

## Asset Explorer (AW01N)

| Seccion | Informacion |
|---------|-------------|
| Valores planificados | Depreciacion planificada por periodo |
| Valores contabilizados | Movimientos reales |
| Comparacion | Plan vs real por area |
| Parametros | Vida util, clave depreciacion, fecha inicio |

---

## Cierre de Ejercicio FI-AA

| Transaccion | Descripcion | Momento |
|-------------|-------------|---------|
| AJAB | Cierre de ejercicio AA | Despues de periodo 12 |
| AJRW | Cambio de ejercicio fiscal | Inicio nuevo ano |
| OAAR | Recalculo de areas | Si hubo cambios de parametros |
| ASKB | Comparacion valores activos | Verificacion antes de cierre |

---

## Consultas MCP

```sql
-- Valor en libros de activos (neto) por clase
SELECT A.ANLKL, A.TXT50,
       SUM(CASE WHEN C.ESSION IN ('100','110','150') THEN C.HSL ELSE 0 END) AS ADQUISICION,
       SUM(CASE WHEN C.ESSION IN ('200','250') THEN C.HSL ELSE 0 END) AS DEPRECIACION,
       SUM(C.HSL) AS VALOR_NETO
FROM ANLA AS A
  INNER JOIN ACDOCA AS C ON C.RBUKRS = A.BUKRS
    AND C.ANLN1 = A.ANLN1 AND C.ANLN2 = A.ANLN2
WHERE A.BUKRS = '{company_code}'
  AND C.BUDAT <= '{key_date}'
  AND C.RLDNR = '0L'
GROUP BY A.ANLKL, A.TXT50
ORDER BY A.ANLKL

-- Movimientos de activos en un periodo
SELECT ANLN1, ANLN2, BELNR, BUDAT, BWART,
       HSL, RHCUR, BLART, SGTXT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND ANLN1 <> ''
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND RLDNR = '0L'
ORDER BY ANLN1, BUDAT

-- Depreciacion contabilizada por periodo
SELECT POPER, RACCT,
       SUM(HSL) AS DEP_TOTAL,
       COUNT(DISTINCT ANLN1) AS NUM_ACTIVOS
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND ANLN1 <> ''
  AND BLART = 'AF'
  AND GJAHR = '{fiscal_year}'
  AND RLDNR = '0L'
GROUP BY POPER, RACCT
ORDER BY POPER

-- Historial de adquisiciones
SELECT ANLN1, ANLN2, BELNR, BUDAT,
       HSL, RHCUR, LIFNR, SGTXT
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND ANLN1 BETWEEN '{asset_from}' AND '{asset_to}'
  AND BLART IN ('AA', 'AN')
  AND RLDNR = '0L'
ORDER BY ANLN1, BUDAT
```

---

## Errores Comunes

| Error | Causa | Solucion |
|-------|-------|----------|
| Periodo no abierto para AA | Periodo contable cerrado para tipo activo | Abrir periodo en OB52 (tipo A) |
| Area de depreciacion no coincide | Area no definida para la clase de activo | Verificar config clase en OAOA |
| Cambio vida util no recalcula | Falta ejecucion AFAR despues del cambio | Ejecutar AFAR para recalcular |
| Depreciacion ya ejecutada para periodo | AFAB ya corrio para ese periodo | Usar motivo 03 (repeat) |
| Error en retiro: valor residual | Valor de retiro mayor que valor neto | Verificar valor neto en AW01N |
| Activo bloqueado | Marca de borrado o bloqueo activo | Verificar AS02 → datos generales |
| Transfer posting error | Areas con valores diferentes | Verificar todas las areas antes de ABUMN |
