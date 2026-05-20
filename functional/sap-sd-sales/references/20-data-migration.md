# Migracion de Datos SD

## Objetos a migrar en SD

### 1. Datos maestros

#### Clientes → Business Partner (BP)
En S/4HANA, el maestro de clientes vive en Business Partner (BP). La migracion usa CVI (Customer-Vendor Integration) para sincronizar ambos mundos.

**Tablas origen (ECC/legacy):**
| Tabla | Contenido |
|-------|-----------|
| KNA1 | Datos generales cliente |
| KNB1 | Datos por sociedad (credito, recon account) |
| KNVV | Datos de area de ventas (condiciones de pago, grupo cliente, etc.) |
| KNVP | Funciones de socio por area de ventas |
| KNVK | Personas de contacto |
| KNKK | Datos de credito (limite, grupo de riesgo) |
| KNMT | Customer-material info records |

**Tablas destino (S/4HANA):**
| Tabla | Contenido |
|-------|-----------|
| BUT000 | BP datos generales |
| BUT020 | BP direcciones |
| BUT100 | BP por rol (FLCU00 = FI customer, FLCU01 = Sales) |
| KNA1 | Mantenida por CVI (lectura legacy) |
| KNVV | Mantenida via BP rol FLCU01 |

**Template LTMC:** "Business Partner - Customer"

**Campos criticos a mapear:**
- Account group (KTOKD) → BP grouping (BP group)
- Sales area: VKORG + VTWEG + SPART en KNVV
- Partner functions: KNVP-PARVW (AG, RE, RG, WE → SP, BP, PY, SH en BP)
- Credit limit: KNKK-KLIMK → BP credit segment
- Reconciliation account: KNB1-AKONT
- Payment terms: KNB1-ZTERM / KNVV-ZTERM

**CVI — Customer-Vendor Integration:**
- Activo en S/4HANA por defecto
- Al crear/modificar BP, CVI actualiza KNA1/KNB1 automaticamente y viceversa
- Transaction BP — BP cockpit
- Tabla de sincronizacion: FSBP_FICA_CUST (mapeo BP-Customer)

#### Customer-Material Info Records (KNMT)
- Template LTMC disponible: "Customer-Material Info Record"
- Campos: KUNNR, VKORG, VTWEG, MATNR, KDMAT (numero material cliente), VKBUR
- Transaction VD51/VD52

#### Condiciones de precio (pricing conditions)
- Tablas: KONH (header condicion), KONP (items condicion), KONV (condicion en doc — NO migrar)
- Template LTMC: "Sales Pricing Conditions"
- Alternativa: LSMW con transaccion VK11 o programa RVPRICOH
- Campos clave: KSCHL (tipo condicion), tabla de condicion, access sequence

---

### 2. Documentos abiertos

#### Pedidos de venta abiertos
Solo migrar pedidos que aun tienen items sin facturar y sin cerrar completamente.

**Metodos de migracion:**
1. **LTMC template "Sales Order"** — recomendado para S/4HANA
2. **BAPI_SALESORDER_CREATEFROMDAT2** — programacion custom
3. **BAPI_SALESORDER_SIMULATE** — para validar antes de crear

**Campos minimos requeridos:**
```
ORDER_HEADER_IN:
  DOC_TYPE    = tipo pedido (ZOR, OR, etc.)
  SALES_ORG   = organizacion de ventas
  DISTR_CHAN  = canal de distribucion
  DIVISION    = division
  PURCH_DATE  = fecha pedido original

ORDER_PARTNERS (tabla):
  PARTN_ROLE = 'AG' + PARTN_NUMB = sold-to
  PARTN_ROLE = 'WE' + PARTN_NUMB = ship-to

ORDER_ITEMS_IN (tabla):
  ITM_NUMBER  = numero posicion
  MATERIAL    = material
  REQ_QTY     = cantidad
  REQ_DATE    = fecha entrega requerida

ORDER_CONDITIONS_IN (tabla):  -- si se copia precio
  ITM_NUMBER  = posicion
  COND_TYPE   = 'PR00'
  COND_VALUE  = precio unitario
  CURRENCY    = moneda
```

**Consideraciones pricing:**
- Opcion A: Copiar precio del sistema origen (pasar condicion PR00 manual)
- Opcion B: Re-determinar precio (no pasar condiciones, dejar que el sistema las calcule)
- Opcion B recomendada si condiciones maestras ya fueron migradas

**Campos especiales para referencia de documento origen:**
- VBKD-BSTNK — Purchase order number del cliente (referencia PO cliente)
- VBAK-VBELN_VORGAENGER — campo no estandar; usar texto cabecera para guardar ID origen

#### Entregas pendientes
Generalmente NO se migran. En su lugar:
1. Migrar el pedido abierto con cantidad pendiente de entrega
2. Despues del go-live, crear entregas nuevas desde los pedidos migrados
3. Excepcion: si entrega ya fue picking-confirmada en el almacen origen

#### Facturas (billing documents)
NO se migran como documentos SD. Las facturas historicas se migran como:
- Documentos FI directamente (F-02 o LTMC "Financial Documents")
- Informes de ventas historicos via BW/datasource

#### Saldos abiertos AR (cuentas por cobrar)
- NO via SD — migrar directamente en FI
- LTMC template: "Financial Documents" o "Customer Open Items"
- Fecha de valor = fecha go-live
- Importante: cuadrar total AR migrado con balance sheet

---

## LTMC — SAP S/4HANA Migration Cockpit

### Templates SD disponibles
| Template ID | Objeto | Tablas principales destino |
|-------------|--------|---------------------------|
| Business Partner - Customer | BP + Customer master | BUT000, KNA1, KNB1, KNVV |
| Customer-Material Info Record | KNMT | KNMT |
| Sales Pricing Conditions | Condiciones precio | KONH, KONP |
| Sales Order | Pedidos de venta | VBAK, VBAP, VBKD, VBEP |
| Credit Master | Datos de credito cliente | KNKK |

### Flujo LTMC
```
1. LTMC → Create Project → seleccionar template
2. Download template Excel/XML
3. Rellenar datos en template
4. Upload al migration cockpit
5. Simulate → verificar errores
6. Execute → crear registros
7. Review migration results
```

### Transaction: /n/LTMC o S/4HANA Migration Cockpit (Fiori)

---

## LSMW — Legacy System Migration Workbench

Disponible pero **deprecated en S/4HANA**. Usar solo para migraciones puntuales o cuando no existe template LTMC.

**Metodos soportados:**
| Metodo | Uso tipico | Riesgo |
|--------|------------|--------|
| Batch Input | Transacciones clasicas (VA01, VK11) | Alto — dependiente de pantallas |
| Direct Input | Insercion directa tablas (solo SD limitado) | Medio |
| BAPI | Llamadas BAPI estandar | Bajo — recomendado |
| IDOC | Carga via IDocs | Bajo |

**Transaccion:** LSMW

---

## Validacion post-migracion

### Clientes migrados
```sql
-- Contar clientes creados en fecha de migracion
SELECT COUNT(*) AS TOTAL_CLIENTES
FROM KNA1
WHERE ERDAT = '{fecha_migracion}'

-- Clientes sin datos de area de ventas (posible error CVI)
SELECT K.KUNNR, K.NAME1, K.KTOKD
FROM KNA1 AS K
WHERE K.ERDAT = '{fecha_migracion}'
  AND NOT EXISTS (
    SELECT 1 FROM KNVV AS V
    WHERE V.KUNNR = K.KUNNR
      AND V.VKORG = '{vkorg}'
  )

-- Business Partners creados y vinculados a cliente
SELECT B.PARTNER, B.BU_TYPE, B.BU_GROUP, B.NAME_ORG1, B.CRDAT
FROM BUT000 AS B
WHERE B.CRDAT = '{fecha_migracion}'
  AND B.BU_TYPE = '2'
ORDER BY B.PARTNER
```

### Pedidos migrados
```sql
-- Pedidos creados en go-live
SELECT VBELN, AUART, VKORG, VTWEG, SPART, KUNNR, NETWR, WAERK, ERDAT
FROM VBAK
WHERE ERDAT = '{fecha_migracion}'
ORDER BY ERDAT DESC

-- Verificar que todos los pedidos tienen posiciones
SELECT V.VBELN, V.AUART, COUNT(P.POSNR) AS NUM_POSICIONES, SUM(P.NETWR) AS VALOR
FROM VBAK AS V
LEFT JOIN VBAP AS P ON V.VBELN = P.VBELN AND P.ABGRU = ''
WHERE V.ERDAT = '{fecha_migracion}'
GROUP BY V.VBELN, V.AUART
HAVING COUNT(P.POSNR) = 0  -- pedidos sin posiciones = error
```

### Condiciones de precio migradas
```sql
-- Contar condiciones por tipo
SELECT KSCHL, DATAB, DATBI, COUNT(*) AS REGISTROS
FROM KONH
WHERE ERDAT = '{fecha_migracion}'
GROUP BY KSCHL, DATAB, DATBI
ORDER BY KSCHL

-- Verificar items de condicion
SELECT H.KSCHL, H.KNUMH, COUNT(P.KOPOS) AS NUM_ITEMS
FROM KONH AS H
JOIN KONP AS P ON H.KNUMH = P.KNUMH
WHERE H.ERDAT = '{fecha_migracion}'
GROUP BY H.KSCHL, H.KNUMH
```

### Funciones de socio migradas
```sql
-- Verificar partner functions en pedidos migrados
SELECT V.VBELN, P.PARVW, P.KUNNR, P.ADRNR
FROM VBAK AS V
JOIN VBPA AS P ON V.VBELN = P.VBELN AND P.POSNR = '000000'
WHERE V.ERDAT = '{fecha_migracion}'
  AND P.PARVW IN ('AG', 'RE', 'RG', 'WE')
ORDER BY V.VBELN, P.PARVW

-- Detectar pedidos sin sold-to (WE faltante es critico)
SELECT DISTINCT VBELN FROM VBAK
WHERE ERDAT = '{fecha_migracion}'
  AND VBELN NOT IN (
    SELECT VBELN FROM VBPA
    WHERE POSNR = '000000' AND PARVW = 'AG'
  )
```

### Datos de credito
```sql
-- Limites de credito migrados por cliente y area de credito
SELECT KUNNR, KKBER, KLIMK, WAERS, CTLPC, ERDAT
FROM KNKK
WHERE ERDAT = '{fecha_migracion}'
ORDER BY KUNNR

-- Clientes sin datos de credito (si se esperaban)
SELECT K.KUNNR, K.NAME1
FROM KNA1 AS K
WHERE K.ERDAT = '{fecha_migracion}'
  AND NOT EXISTS (
    SELECT 1 FROM KNKK WHERE KUNNR = K.KUNNR AND KKBER = '{area_credito}'
  )
```

### Cuadre financiero AR
```sql
-- Saldo total AR migrado por sociedad
SELECT BUKRS, SUM(DMBTR) AS TOTAL_AR, WAERS
FROM BSID
WHERE AUGBL = ''
  AND BLDAT = '{fecha_go_live}'
GROUP BY BUKRS, WAERS

-- Comparar con balance cargado en FI
-- (debe coincidir con saldo de cuenta reconciliacion en FAGLB03)
```

---

## Errores comunes en migracion SD

| Error | Causa probable | Solucion |
|-------|----------------|----------|
| BP ya existe con mismo nombre/tax number | Duplicado en CVI o datos origen con duplicados | Verificar mapping previo; usar FSBP_FICA_CUST para ver existentes |
| "Falta area de ventas" al crear pedido | KNVV no migrado o datos incompletos | Completar datos KNVV via VD02 antes de migrar pedidos |
| Pricing error en pedido (PR00 no encontrado) | Condiciones de precio no migradas o fuera de vigencia | Verificar DATAB/DATBI en KONH; migrar condiciones primero |
| "Partner not defined" en pedido | KNVP no migrado correctamente | Verificar BP roles y funciones de socio |
| BAPI retorna warning pero no error, pedido no creado | Datos insuficientes o inconsistencia silenciosa | Activar BAPI_SALESORDER_SIMULATE primero y revisar RETURN |
| Delivery block automatico en pedido migrado | Limite de credito excedido al crear | Revisar KNKK-KLIMK; ajustar limite o crear pedido con bloqueo temporal |
| Material no disponible en planta del pedido | Maestro de materiales no extendido a planta/area venta | MM01 extension primero |
| "Incompletion log" en pedido | Campos obligatorios segun schema de incompletitud | Revisar OVA2; ajustar schema o completar campos |
| Error CVI: BP no se sincroniza con KNA1 | CVI no activo o customizing incompleto | Verificar SPRO → CVI → Customer Integration |

---

## Checklist de migracion SD

### Pre-migracion
- [ ] Inventario completo de objetos a migrar (clientes, condiciones, pedidos abiertos)
- [ ] Mapeo de campos origen → destino documentado
- [ ] Customizing de S/4HANA completado y transportado a PRD:
  - Account groups de clientes
  - Sales organizations, distribution channels, divisions
  - Sales order types
  - Pricing procedures y condition types
  - Partner determination schemas
  - Incompletion procedures
  - Credit management areas
- [ ] BPs / numero range de clientes configurado y sin solapamiento con origen
- [ ] Maestro de materiales extendido a todas las plantas y areas de ventas necesarias
- [ ] Cuentas GL de reconciliacion configuradas en FI
- [ ] Pruebas en sistema de migracion (DEV/QA) completadas
- [ ] Resultado de pruebas validado con usuarios clave
- [ ] Estrategia de rollback definida y probada
- [ ] Ventana de migracion acordada (downtime)

### Orden de ejecucion de objetos
```
1. Business Partners (clientes) — sin dependencias internas
2. Customer-material info records — dependen de BP + material
3. Condiciones de precio — dependen de BP, material, sales area
4. Datos de credito (KNKK) — dependen de BP
5. Pedidos de venta abiertos — dependen de todo lo anterior
6. Saldos AR abiertos (en FI) — paralelo o posterior a pedidos
```

### Durante la migracion
- [ ] Sistema en modo mantenimiento (usuarios bloqueados)
- [ ] Log de cada paso guardado con timestamps
- [ ] Validaciones automaticas ejecutadas tras cada carga
- [ ] Responsable SAP SD disponible en sala
- [ ] Responsable FI/CO disponible para cuadre financiero
- [ ] Contacto con SAP Support activo (si contrato lo permite)

### Post-migracion — Validacion funcional
- [ ] Crear pedido de prueba manual (VA01) en S/4HANA — confirmar sin errores
- [ ] Verificar determinacion de precios en pedido de prueba
- [ ] Crear entrega (VL01N) desde pedido migrado
- [ ] Post Goods Issue (VL02N) exitoso
- [ ] Facturacion (VF01) y liberacion a contabilidad exitosa
- [ ] Verificar documento FI generado (BKPF/ACDOCA)
- [ ] Verificar partida abierta en BSID/FBL5N
- [ ] Spot-check 10% de clientes migrados (datos generales + ventas + credito)
- [ ] Spot-check condiciones de precio en VA01 (simulation pricing)
- [ ] Cuadre: saldo AR migrado = saldo contable en cuenta reconciliacion
- [ ] Usuarios clave realizan smoke test en PRD

### Herramientas de apoyo post-go-live
- **FBL5N** — Customer line items (verificar AR open items)
- **VD03** — Display customer master (verificar datos SD)
- **VK13** — Display pricing conditions
- **VA03** — Display sales order (verificar pedidos migrados)
- **FAGLB03** — G/L balances (cuadre cuentas reconciliacion)
- **SM13** — Update records (identificar errores en actualizacion asincrona)
- **SLG1** — Application log (errores de migracion LTMC)

---

## Herramientas de migracion — Comparativa

| Herramienta | Complejidad | Velocidad | Trazabilidad | Recomendado para |
|-------------|-------------|-----------|--------------|-----------------|
| LTMC | Baja-Media | Alta | Alta | Proyectos S/4HANA estandar |
| BAPI custom | Alta | Media | Media | Logica de negocio compleja |
| LSMW Batch Input | Alta | Baja | Media | Legado / casos especiales |
| LSMW BAPI | Media | Media | Media | Migraciones puntuales |
| IDocs | Alta | Alta | Alta | Interfaces con sistemas externos |
| BDC (Batch Data Communication) | Alta | Baja | Baja | Ultima opcion |

---

## Estrategia big bang vs. faseada

### Big bang
- Todo en una sola noche/fin de semana
- Menor complejidad de gestion
- Mayor riesgo: si algo falla, rollback total
- Recomendado para empresas pequeñas o perimetros SD limitados

### Faseada por sociedad / org de ventas
- Primero sociedad piloto, luego rollout
- Requiere coexistencia temporal de sistemas
- Mejor control de riesgos
- Recomendado para grupos multinacionales

### Datos a tiempo real (replicacion continua)
- Herramientas: SAP LT Replication Server (SLT), CPI, o terceros
- Minimiza downtime
- Complejidad muy alta
- Solo justificado en migraciones de mas de 1 millon de registros
