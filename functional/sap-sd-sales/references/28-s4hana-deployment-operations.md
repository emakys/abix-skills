# S/4HANA 2023 — Deployment y Operaciones SD

## Transporte de Customizing SD

### Objetos transportables
```
Configuracion SD que se transporta via TR (STMS):

Estructura organizativa: org ventas, canales, sectores, areas ventas
Tipos de documento: TVAK (pedido), TVLK (entrega), TVFK (factura)
Item categories: TVEP, TVEPZ (determinacion)
Schedule line categories: T188
Pricing: T683S (asignacion), T685 (cond types), T682 (access seq), T683 (procedures)
Copy control: VTAA, VTLA, VTFL, VTFF (por tipo doc origen/destino)
Partner determination: T014 (procedures), asignaciones
Output determination: NACE config (output types, access sequences)
Account determination: VKOA
Credit management: OVA8 (automatic credit control)
Texts: VOTXN config
```

### Landscape tipico
```
DEV (desarrollo) → QAS (calidad) → PRD (produccion)
     |                  |                |
  Customizing      Tests integr.    Operacion
  Desarrollo       UAT             Go-live
  Unit tests       Regression

Transporte: TR en DEV → liberar → importar QAS → tests → importar PRD
STMS: Transport Management System
SE09/SE10: Transport Organizer
```

### Mejores practicas de transporte SD
```
1. Un TR por funcionalidad (no mezclar pricing con delivery config)
2. Orden de transporte:
   - Primero: estructura organizativa
   - Segundo: datos maestros config (cond types, item cats)
   - Tercero: determinaciones (pricing proc, partner, output)
   - Cuarto: copy control
   - Quinto: account determination
3. Verificar dependencias antes de liberar
4. NUNCA transportar datos maestros de cliente/material (solo config)
5. CTS+ para Fiori catalogs/groups
```

## Feature Toggles y Business Functions

### Business Functions SD
| Business Function | Descripcion | SFW5 |
|-------------------|-------------|------|
| SD_01 | Sales Order Processing Enhancements | SFW5 |
| SD_02 | Billing Enhancements | SFW5 |
| SD_NEXT_GEN | Next Generation Sales | SFW5 |
| LOG_SD_CI_1 | SD Customer Integration | SFW5 |
| DIMP_SD | SD Industry Extensions | SFW5 |

### Activacion
```
SFW5: Switch Framework
  → Seleccionar business function
  → Verificar dependencias
  → Activar (irreversible en produccion)
  → Regenerar objetos dependientes

Nota: en S/4HANA muchas funciones estan activas por default
```

## Testing SD Configuration

### Test Script OTC Completo
```
Paso 1: Crear pedido (VA01)
  - Tipo: OR, Sold-to: test customer, Material: test material
  - Verificar: pricing OK, ATP confirmado, partners determinados
  - Verificar: incompletion log limpio

Paso 2: Crear entrega (VL01N)
  - Desde pedido del paso 1
  - Verificar: shipping point correcto, picking completado
  - PGI: verificar movimiento 601, stock reducido

Paso 3: Crear factura (VF01)
  - Desde entrega del paso 2
  - Verificar: pricing copiado/recalculado correctamente
  - Verificar: release to accounting OK (BELNR generado)
  - Verificar: cuenta revenue correcta (VKOA)

Paso 4: Verificar flujo documental
  - VA03 → Environment → Document Flow
  - VBFA: pedido → entrega → factura

Paso 5: Verificar FI
  - VF03 → Accounting document
  - Verificar: AR + Revenue + Tax correcto
```

### Checklist de Regression Tests
```
[ ] Pedido estandar (OR) → entrega → factura
[ ] Devolucion (RE) → entrega devolucion → credito
[ ] Nota credito (CR) → G2
[ ] Cash sale (BV)
[ ] Third-party (TAS)
[ ] Free of charge (FD)
[ ] Pricing: todos los tipos de condicion activos
[ ] ATP: confirmacion completa y parcial
[ ] Credit check: bloqueo y liberacion
[ ] Output: confirmacion pedido, nota entrega, factura
[ ] Partners: determinacion automatica correcta
[ ] Incompletion log: campos obligatorios correctos
[ ] Copy control: datos copiados correctamente
[ ] Account determination: cuentas FI correctas
```

## Monitorizacion Operaciones SD

### Transacciones de monitoreo diario
| TCode | Que monitorear | Frecuencia |
|-------|---------------|------------|
| V.02 | Pedidos incompletos | Diario |
| V.14 | Pedidos bloqueados (delivery/billing block) | Diario |
| VKM1 | Pedidos bloqueados por credito | Diario |
| VL06O | Entregas pendientes de PGI | Diario |
| VF04 | Facturas pendientes (billing due list) | Diario |
| VFX3 | Facturas bloqueadas | Diario |
| SP01 | Spool (outputs pendientes) | Diario |
| SM21 | System log (errores) | Diario |
| SLG1 | Application log (errores billing) | Diario |

### Jobs Batch SD
| Job/Programa | Funcion | Frecuencia tipica |
|-------------|---------|-------------------|
| RSNAST00 | Procesar outputs pendientes | Cada 15 min |
| RV60SBAT | Billing background (VF06) | Diario nocturno |
| RVKRED77 | Re-check credito automatico | Cada hora |
| SD_COLLECTIVE_RUN | Procesamiento colectivo | Segun volumen |
| RVAUFSLN | Reorg lista pedidos | Semanal |
| VL10 background | Creacion entregas masiva | Diario |

### Alertas y Situation Handling (S/4HANA)
```
Configurar alertas automaticas para:
  - Pedidos vencidos sin entrega (> X dias)
  - Entregas sin PGI (> X dias)
  - Facturas con error contabilizacion
  - Credito excedido > X%
  - Devoluciones anormales (> X% del revenue)

App Fiori: "My Situation" / "Situation Handling"
Config: SPRO → Cross-Application → Situation Handling
```

## Migracion ECC → S/4HANA SD

### Diferencias principales
```
1. Business Partner obligatorio (BP reemplaza VD01/XD01)
   - CVI sync automatico BP ↔ Customer
   - VD01/VD02 redirigen a BP transaction

2. MATDOC reemplaza MKPF+MSEG para PGI
   - Compatibilidad: MSEG view sigue funcionando
   - Nuevo: acceso via MATDOC para mejor performance

3. ACDOCA reemplaza BSEG para docs FI de billing
   - Compatibilidad: BSEG view disponible
   - Nuevo: single journal entry en ACDOCA

4. Output Management 2.0 (BRF+ based)
   - Clasico NACE sigue funcionando
   - Nuevo: BRF+ para reglas complejas

5. Fiori reemplaza SAP GUI para operaciones diarias
   - Transacciones VA01/VL01N/VF01 siguen disponibles
   - Fiori apps recomendadas para usuarios finales
```

### Custom Code Adaptation
```
ATC (ABAP Test Cockpit) checks para SD:
  - Usar MATDOC en vez de MSEG para GI queries
  - Usar ACDOCA en vez de BSEG para FI queries
  - Verificar acceso a BP tables
  - Eliminar referencias a tablas eliminadas (VBUK, VBUP integrados en VBAK/VBAP)

Simplification list items relevantes SD:
  - VBUK campos movidos a VBAK (GBSTK, LFSTK, FKSTK, etc.)
  - VBUP campos movidos a VBAP (GBSTA, LFSTA, FKSTA, etc.)
  - MSEG → MATDOC
  - BSEG → ACDOCA
```

### Queries MCP para verificar migracion
```sql
-- Verificar que VBUK/VBUP no se usan (deben leer de VBAK/VBAP)
-- En S/4HANA estos son compatibility views

-- Status del pedido directo de VBAK (sin VBUK)
SELECT VBELN, GBSTK, LFSTK, FKSTK FROM VBAK WHERE VBELN = '{pedido}'

-- Status posicion directo de VBAP (sin VBUP)
SELECT VBELN, POSNR, GBSTA, LFSTA, FKSTA FROM VBAP WHERE VBELN = '{pedido}'

-- PGI en MATDOC (no MSEG)
SELECT MBLNR, MJAHR, BWART, MATNR, MENGE, VBELN_IM FROM MATDOC
WHERE VBELN_IM = '{delivery}' AND BWART = '601'

-- Doc FI de factura en ACDOCA (no BSEG)
SELECT BELNR, BUZEI, HKONT, DMBTR, WRBTR FROM ACDOCA
WHERE AWTYP = 'VBRK' AND AWKEY = '{factura}'
```
