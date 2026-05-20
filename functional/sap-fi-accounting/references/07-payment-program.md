# Programa de Pagos Automatico (F110)

## Resumen

F110 es la transaccion central para ejecutar pagos automaticos a proveedores y cobros a clientes. El proceso consta de cuatro fases: parametrizacion, propuesta de pago, ejecucion del pago y generacion del medio de pago. La configuracion se realiza en FBZP y abarca sociedades pagadoras, metodos de pago, determinacion bancaria y formatos de medio de pago.

---

## Configuracion FBZP — Estructura General

### SPRO Path
```
SPRO → Gestion financiera → Deudores y acreedores →
  Operaciones empresariales → Pagos automaticos salientes →
  Configurar programa de pagos (FBZP)
```

### Pestanas de Configuracion

| Pestana | Tabla | Contenido |
|---------|-------|-----------|
| Sociedades pagadoras | T042 | Importes minimos, agrupacion, formas de pago |
| Formas de pago por pais | T042Z | Metodos disponibles por pais (cheque, transferencia, etc.) |
| Formas de pago por sociedad | T042Y | Metodos habilitados, importes min/max, monedas |
| Determinacion bancaria | T042B, T042D, T042I | Ranking bancos, cuentas, fecha valor |
| Formatos de medio de pago | T042E | Programas RFFO*, variantes, formatos DME |

---

## Sociedades Pagadoras (T042)

| Campo | Descripcion | Ejemplo |
|-------|-------------|---------|
| BUKRS | Sociedad pagadora | 1000 |
| ZBNKL | Sociedad pagadora central | 1000 (puede pagar por otras) |
| HBKID | Banco propio por defecto | BANK01 |
| MINBT | Importe minimo para pago | 10.00 |
| GRPNO | Agrupacion de pagos | Agrupar por proveedor |

### Pago centralizado
Una sociedad puede pagar en nombre de otras (pago centralizado). Se configura en la pestana de sociedades pagadoras asignando la sociedad pagadora central.

---

## Formas de Pago por Pais (T042Z)

| Campo | Descripcion |
|-------|-------------|
| LAND1 | Pais |
| ZLSCH | Forma de pago (C=cheque, T=transferencia, W=letra) |
| TEXT1 | Descripcion |
| XUNRD | Pagos en redondeo |
| XKOMP | Compensacion permitida |
| ZINME | Importe minimo |
| ZIMXE | Importe maximo |
| XAKTZ | Entrada de letra activa |

### Formas de Pago Tipicas

| Codigo | Descripcion | Pais Tipico |
|--------|-------------|-------------|
| C | Cheque | US, MX, AR |
| T | Transferencia bancaria | DE, ES, todos |
| W | Letra de cambio | ES, IT, FR |
| E | Transferencia SEPA | EU |
| S | Cheque urgente | US |
| U | Transferencia urgente (SWIFT) | Internacional |
| P | Pagare | ES, MX |

---

## Formas de Pago por Sociedad (T042Y)

| Campo | Descripcion |
|-------|-------------|
| BUKRS | Sociedad |
| ZLSCH | Forma de pago |
| ZWELS | Formas de pago permitidas |
| XZALG | Agrupar pagos |
| ZINBT | Importe minimo |
| ZIMXB | Importe maximo |
| XAUSL | Pagos al extranjero |

---

## Determinacion Bancaria (T042B / T042D / T042I)

### Logica de Seleccion de Banco

```
Documento a pagar
  → Forma de pago del documento / proveedor
    → Bancos propios disponibles para esa forma de pago
      → Ranking de bancos (T042B)
        → Verificacion de disponibilidad (T042D)
          → Cuenta bancaria seleccionada (T042I)
```

### Tablas de Determinacion

| Tabla | Contenido | Campos Clave |
|-------|-----------|--------------|
| T042B | Ranking de bancos | BUKRS, ZLSCH, HBKID, RANKG |
| T042D | Cuentas disponibles | BUKRS, HBKID, HKTID, WAESSION |
| T042I | Seleccion por importe | BUKRS, ZLSCH, BETEFROM, BETETO, HBKID |

### SPRO Path — Bancos Propios
```
SPRO → Gestion financiera → Contabilidad bancaria →
  Cuentas bancarias → Definir bancos propios (FI12)
```

---

## Flujo de Ejecucion F110

### Fase 1: Parametros

| Campo | Descripcion |
|-------|-------------|
| Fecha de ejecucion | Fecha del proceso de pago |
| Identificacion | ID unico de la ejecucion (alfanumerico) |
| Sociedades | Sociedades a incluir |
| Formas de pago | Metodos a utilizar |
| Fecha siguiente pago | Fecha limite de vencimiento |
| Cuentas de proveedor/cliente | Rango o seleccion individual |

### Fase 2: Propuesta de Pago

```
F110 → Propuesta → Ejecutar propuesta
  → Sistema analiza partidas abiertas
  → Aplica reglas de vencimiento
  → Selecciona metodo de pago
  → Genera lista de propuesta
```

**Verificaciones automaticas:**
- Fecha de vencimiento vs fecha siguiente pago
- Importe minimo de pago
- Bloqueos de pago (documento, proveedor)
- Datos bancarios del proveedor
- Disponibilidad de fondos en banco propio

### Fase 3: Ejecucion del Pago

```
F110 → Ejecucion del pago → Ejecutar inmediatamente
  → Contabiliza documentos de pago (clase ZP)
  → Compensa partidas abiertas del proveedor
  → Genera registros en REGUH / REGUP
```

### Fase 4: Medio de Pago / Impresion

```
F110 → Impresion → Ejecutar impresion
  → Genera cheques (PAYR)
  → Genera fichero bancario (DME)
  → Genera aviso de pago
```

---

## Determinacion de Fecha de Vencimiento

```
Fecha base (BSEG-ZFBDT)
  + Condiciones de pago (T052)
    → Descuento 1: BSEG-ZFBDT + ZBD1T dias
    → Descuento 2: BSEG-ZFBDT + ZBD2T dias
    → Neto:        BSEG-ZFBDT + ZBD3T dias
```

| Campo BSEG | Descripcion |
|-------------|-------------|
| ZFBDT | Fecha base para calculo de vencimiento |
| ZTERM | Condiciones de pago |
| ZBD1T | Dias para descuento 1 |
| ZBD1P | Porcentaje descuento 1 |
| ZBD2T | Dias para descuento 2 |
| ZBD2P | Porcentaje descuento 2 |
| ZBD3T | Dias para pago neto |
| ZLSPR | Bloqueo de pago |

---

## Bloqueos de Pago

### Nivel Documento (BSEG-ZLSPR)

| Clave | Descripcion |
|-------|-------------|
| (vacio) | Sin bloqueo |
| A | Bloqueo temporal |
| B | Error en factura |
| R | Factura en revision |
| * | Bloqueado libre definicion |

### Nivel Proveedor (LFB1-ZAHLS)

| Campo | Descripcion |
|-------|-------------|
| ZAHLS | Bloqueo central de pago |
| ZWELS | Formas de pago permitidas |
| LNRZB | Proveedor alternativo de pago |

---

## Tablas Principales

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| REGUH | Cabecera de pago (programa pagos) | LAUFD, LAUFI, ZBUKR, LIFNR, VBLNR |
| REGUP | Posiciones de pago | LAUFD, LAUFI, ZBUKR, LIFNR, BELNR |
| PAYR | Registro de cheques | ZBUKR, HBKID, HKTID, CHECF, CHECT |
| T042 | Config sociedad pagadora | BUKRS |
| T042Y | Formas pago por sociedad | BUKRS, ZLSCH |
| T042Z | Formas pago por pais | LAND1, ZLSCH |
| T042B | Ranking bancos | BUKRS, ZLSCH, HBKID |
| T042D | Cuentas bancarias disponibles | BUKRS, HBKID, HKTID |
| T042I | Seleccion por importe | BUKRS, ZLSCH |
| T042E | Formatos medio de pago | BUKRS, ZLSCH |

---

## Consultas MCP

```sql
-- Pagos pendientes por proveedor (partidas abiertas)
SELECT RBUKRS, RACCT, LIFNR, BELNR, BUZEI,
       BUDAT, ZFBDT, HSL, RHCUR, ZLSPR, ZTERM
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND KOART = 'K'
  AND AUGBL = ''
  AND BUDAT <= '{key_date}'
ORDER BY LIFNR, ZFBDT

-- Historial de pagos ejecutados (documentos clase ZP)
SELECT RBUKRS, BELNR, BUDAT, LIFNR, RACCT,
       HSL, RHCUR, BLART, XREF1
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND BLART = 'ZP'
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
ORDER BY BUDAT DESC, BELNR

-- Verificar ejecuciones F110
SELECT LAUFD, LAUFI, ZBUKR, XVORL,
       COUNT(*) AS NUM_PAGOS,
       SUM(RWBTR) AS TOTAL_PAGADO
FROM REGUH
WHERE ZBUKR = '{company_code}'
  AND LAUFD BETWEEN '{date_from}' AND '{date_to}'
GROUP BY LAUFD, LAUFI, ZBUKR, XVORL
ORDER BY LAUFD DESC

-- Detalle de propuesta de pago
SELECT H.LAUFD, H.LAUFI, H.LIFNR, H.VBLNR,
       P.BELNR, P.BUZEI, P.DMSHB
FROM REGUH AS H
  INNER JOIN REGUP AS P ON H.LAUFD = P.LAUFD
    AND H.LAUFI = P.LAUFI AND H.LIFNR = P.LIFNR
WHERE H.ZBUKR = '{company_code}'
  AND H.LAUFD = '{run_date}'
  AND H.LAUFI = '{run_id}'
ORDER BY H.LIFNR, P.BELNR
```

---

## Payment Medium Workbench (OBPM1)

### SPRO Path
```
SPRO → Gestion financiera → Deudores y acreedores →
  Operaciones empresariales → Pagos automaticos salientes →
  Medio de pago → Workbench medio de pago (OBPM1)
```

| Transaccion | Descripcion |
|-------------|-------------|
| OBPM1 | Configurar formatos PMW |
| OBPM2 | Asignar formato a forma de pago |
| OBPM3 | Variantes de seleccion |

---

## DME — Data Medium Exchange

| Transaccion | Descripcion |
|-------------|-------------|
| DMEE | Arbol de formato DME |
| FDTA | Administracion DME |
| F110 (impresion) | Genera fichero DME |

---

## Errores Comunes

| Error | Causa | Solucion |
|-------|-------|----------|
| No se encontraron partidas para pago | Fecha vencimiento posterior a fecha siguiente pago | Ajustar parametros F110 |
| Datos bancarios del proveedor incompletos | Falta banco/cuenta en maestro proveedor | Mantener XK02 → datos bancarios |
| Forma de pago no permitida | Forma pago no configurada en T042Y para la sociedad | Configurar FBZP |
| Importe por debajo del minimo | Importe menor que ZINBT en T042Y | Ajustar minimo o agrupar pagos |
| Banco propio sin fondos suficientes | Limite de banco excedido | Ajustar disponibilidad en T042D |
| Propuesta ya existe | Ejecucion duplicada con mismo ID | Borrar propuesta anterior o usar otro ID |
| Error en generacion de cheques | Rango de numeros de cheque agotado | Mantener rango en FCHI |
