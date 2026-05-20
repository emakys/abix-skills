# Bank Accounting (FI-BL)

## Resumen

La contabilidad bancaria en SAP FI abarca la configuracion de bancos propios, procesamiento de extractos bancarios (manuales y electronicos), conciliacion bancaria, gestion de caja y tesoreria. En S/4HANA se incorporan apps Fiori para gestion avanzada de cuentas bancarias (Bank Account Management) y Advanced Payment Management.

---

## Bancos Propios — Configuracion (FI12)

### Estructura de Datos

```
Banco propio (House Bank)
  ├── Clave banco (HBKID): identificador interno
  ├── Banco pais (BANKL): clave del banco en directorio
  ├── Cuentas bancarias (HKTID):
  │     ├── Numero de cuenta bancaria
  │     ├── Cuenta de mayor asociada (GL)
  │     ├── Moneda
  │     └── Datos de control
  └── Datos de comunicacion
```

### Tablas de Bancos Propios

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T012 | Bancos propios | BUKRS, HBKID, BANKL, BANKS |
| T012K | Cuentas bancarias | BUKRS, HBKID, HKTID, BANKN, HKONT |
| T012T | Textos bancos propios | BUKRS, HBKID, SPRAS, TEXT1 |
| BNKA | Directorio de bancos | BANKS, BANKL, BANKA, SWIFT |
| T012A | Asignacion banco → GL | BUKRS, HBKID, HKTID, HKONT |

### SPRO Path — Bancos Propios
```
SPRO → Gestion financiera → Contabilidad bancaria →
  Cuentas bancarias →
  Definir bancos propios (FI12)
```

---

## Extracto Bancario Manual (FF67 / FF63)

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| FF67 | Contabilizar extracto bancario manual |
| FF63 | Crear extracto bancario manual |
| FF68 | Visualizar extracto bancario |

### Flujo Manual

```
FF63: Crear extracto
  → Ingresar banco propio + cuenta
  → Ingresar saldo inicial y final
  → Registrar posiciones (cobros, pagos, comisiones)
  → Asignar cuentas de mayor / interlocutores
FF67: Contabilizar
  → Genera documentos FI para cada posicion
  → Compensa partidas abiertas si aplica
```

---

## Extracto Bancario Electronico (EBS)

### Formatos Soportados

| Formato | Descripcion | Region |
|---------|-------------|--------|
| MT940 | SWIFT statement | Internacional |
| CAMT.053 | ISO 20022 statement | Europa, global |
| BAI2 | Bank Administration Institute | USA, Canada |
| AUSZUG | Formato aleman | Alemania |
| CNAB240 | Formato brasileno | Brasil |

### Transacciones EBS

| Transaccion | Descripcion |
|-------------|-------------|
| FF_5 | Importar y contabilizar extracto electronico |
| FF.5 | Importar extracto electronico (antiguo) |
| FEBA | Visualizar extractos electronicos |
| FEBAN | Contabilizar extractos post-procesamiento |
| FEB_FILE_UPLOAD | Subir archivo de extracto |

### SPRO Path — EBS
```
SPRO → Gestion financiera → Contabilidad bancaria →
  Operaciones empresariales → Extracto de cuentas electronico →
  Parametrizaciones globales → Definir parametrizaciones globales
```

---

## Procesamiento de Extracto Bancario — Reglas de Contabilizacion

### Estructura de Configuracion

```
Codigo de transaccion externo (banco)
  → Mapping a codigo interno SAP (T028B)
    → Regla de contabilizacion (T028D)
      → Determinacion de cuenta
        → Algoritmo de interpretacion
          → Contabilizacion automatica o manual
```

### Tablas de Reglas

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| T028B | Codigos de transaccion externos | BUKRS, ANESSION, BESSION |
| T028D | Reglas de contabilizacion | BUKRS, BESSION, UMESSION |
| T028G | Algoritmos de interpretacion | BUKRS, ALGKEY |
| T028R | Reglas de busqueda | BUKRS, ALGKEY, STEP |

### Algoritmos de Interpretacion (Search Strategies)

| Estrategia | Descripcion |
|------------|-------------|
| Referencia de factura | Busca numero de factura en nota del banco |
| Numero de cliente/proveedor | Identifica interlocutor por numero |
| Importe exacto | Busca partida abierta con importe identico |
| Referencia de pago | Busca por referencia de pago (KIDNO) |
| Texto libre | Analiza texto de la transaccion bancaria |

### SPRO Path — Reglas de Contabilizacion
```
SPRO → Gestion financiera → Contabilidad bancaria →
  Operaciones empresariales → Extracto de cuentas electronico →
  Definir codigos de transaccion externa a reglas de contabilizacion
```

---

## Conciliacion Bancaria

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| FBKP | Configuracion conciliacion bancaria |
| FF67 | Post-procesamiento manual |
| FEBAN | Contabilizar partidas pendientes |
| J3RFKONTAB | Conciliacion bancaria manual |

### Tipos de Conciliacion

| Tipo | Descripcion | Metodo |
|------|-------------|--------|
| Automatica | El EBS compensa durante import | Algoritmos de interpretacion |
| Semi-automatica | Propuesta con confirmacion manual | FEBAN + revision |
| Manual | Asignacion uno a uno | FF67 / J3RFKONTAB |

```sql
-- MCP Query: Partidas bancarias no conciliadas
SELECT RBUKRS, RACCT, BELNR, BUZEI,
       BUDAT, HSL, RHCUR, SGTXT, ZUESSION
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{bank_gl_account}'
  AND AUGBL = ''
  AND BUDAT <= '{key_date}'
ORDER BY BUDAT DESC
```

---

## Cash Management (Gestion de Tesoreria)

### Transacciones Principales

| Transaccion | Descripcion |
|-------------|-------------|
| FF7A | Posicion de tesoreria (Cash Position) |
| FF7B | Prevision de liquidez (Liquidity Forecast) |
| FF7C | Informe concentrado tesoreria |
| FLQC | Consulta de liquidez |

### Configuracion

```
SPRO → Gestion financiera → Contabilidad bancaria →
  Operaciones empresariales → Cash Management →
  Definir niveles de agrupacion tesoreria
```

| Concepto | Descripcion |
|----------|-------------|
| Nivel de agrupacion | Agrupa cuentas bancarias para reporting |
| Origen de datos | FI (partidas), MM (pedidos), SD (pedidos venta) |
| Horizonte de planificacion | Dias/semanas para prevision |

---

## Lockbox (Procesamiento de Cobros — USA)

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| FLB2 | Importar fichero lockbox |
| FLB1 | Contabilizar lockbox |
| FLB3 | Visualizar datos lockbox |
| FLBP | Post-procesamiento lockbox |

### Formato BAI2

```
01,BANKID,COMPANYID,FILEDATE
02,BANKACCOUNT,STATUS,...
03,ACCOUNTNO,CURRENCYCODE,...
16,DETAIL_RECORD,...
49,ACCOUNTTRAILER,...
98,GROUPTRAILER,...
99,FILETRAILER,...
```

### SPRO Path
```
SPRO → Gestion financiera → Deudores y acreedores →
  Operaciones empresariales → Cobros automaticos entrantes →
  Lockbox → Definir bancos propios para lockbox
```

---

## Cash Journal (Diario de Caja) — FBCJ

### Transacciones

| Transaccion | Descripcion |
|-------------|-------------|
| FBCJ | Diario de caja |
| OY17 | Asignar rangos numeros al diario |

### Configuracion

| Paso | SPRO Path |
|------|-----------|
| Definir diarios | SPRO → FI → Contabilidad bancaria → Cash Journal → Definir |
| Tipos de operacion | SPRO → FI → Contabilidad bancaria → Cash Journal → Crear tipos |
| Rangos numeros | OY17 |

---

## Tablas de Extracto Bancario

| Tabla | Descripcion | Campos Clave |
|-------|-------------|--------------|
| FEBKO | Cabecera extracto bancario | BUKRS, HBKID, HKTID, AESSION |
| FEBEP | Posiciones extracto bancario | BUKRS, HBKID, HKTID, AESSION, KUESSION |
| FEBCL | Items compensados | BUKRS, HBKID, AESSION, BELNR |
| FDES | Cabecera extracto (nuevo) | BUKRS, BANKACC, STATNO |
| FDEI | Posiciones extracto (nuevo) | BUKRS, BANKACC, STATNO, ITEM |

---

## Consultas MCP

```sql
-- Saldo de cuentas bancarias GL
SELECT RBUKRS, RACCT, RHCUR,
       SUM(HSL) AS SALDO_HSL,
       SUM(TSL) AS SALDO_TSL
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT IN ('{bank_account_1}', '{bank_account_2}')
  AND BUDAT <= '{key_date}'
  AND RLDNR = '0L'
GROUP BY RBUKRS, RACCT, RHCUR

-- Movimientos bancarios del periodo
SELECT RBUKRS, RACCT, BELNR, BUZEI, BUDAT,
       HSL, RHCUR, BLART, SGTXT, LIFNR, KUNNR
FROM ACDOCA
WHERE RBUKRS = '{company_code}'
  AND RACCT = '{bank_gl_account}'
  AND BUDAT BETWEEN '{date_from}' AND '{date_to}'
  AND RLDNR = '0L'
ORDER BY BUDAT, BELNR

-- Extractos importados por periodo
SELECT BUKRS, HBKID, HKTID, AESSION, ESESSION,
       ANESSION, ENDESSION, WAESSION
FROM FEBKO
WHERE BUKRS = '{company_code}'
  AND ESESSION BETWEEN '{date_from}' AND '{date_to}'
ORDER BY ESESSION DESC
```

---

## S/4HANA — Apps Fiori Bancarias

| App ID | Nombre | Descripcion |
|--------|--------|-------------|
| F1485 | Bank Account Management | Gestion centralizada de cuentas bancarias |
| F2782 | Cash Management Overview | Vista general de tesoreria |
| F0766 | Monitor Bank Statements | Monitoreo de extractos bancarios |
| F2896 | Manage Bank Statements | Gestion avanzada de extractos |
| F5726 | Advanced Payment Management | Gestion avanzada de pagos |

---

## Errores Comunes

| Error | Causa | Solucion |
|-------|-------|----------|
| Extracto no importa | Formato no coincide con mapping | Verificar T028B codigos transaccion |
| Partidas no se compensan automaticamente | Algoritmo no encuentra referencia | Revisar T028G/T028R estrategias |
| Saldo extracto no cuadra con GL | Partidas manuales no registradas | Conciliar via FEBAN |
| Banco propio no aparece en F110 | Falta configuracion T042B ranking | Configurar FBZP determinacion bancaria |
| Error en importacion CAMT.053 | Version XML incompatible | Verificar nota SAP y formato version |
