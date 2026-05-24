# Errores Frecuentes PP

## Por clase de mensaje

### CO — Production Orders

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| CO 045 | Material not planned in plant | Material sin vista MRP en centro | MM01/MM02 → ampliar vistas MRP 1-4 para el centro |
| CO 049 | BOM not found | Sin lista de materiales para material/centro | CS01 → crear BOM uso 1 (produccion) |
| CO 050 | Routing not found | Sin hoja de ruta para material/centro | CA01 → crear routing |
| CO 052 | Production version not found | Sin version de fabricacion activa | C223 → crear version con BOM+routing |
| CO 053 | No valid BOM for date | BOM fuera de validez temporal | CS02 → verificar/extender validez |
| CO 054 | No valid routing for date | Routing fuera de validez | CA02 → verificar/extender validez |
| CO 078 | Order cannot be released | Faltan datos obligatorios | Completar BOM, routing, verificar disponibilidad |
| CO 080 | Material availability check failed | Componentes no disponibles | MD04 → verificar stock, adelantar compras |
| CO 082 | Capacity overload | Capacidad insuficiente | CM01 → nivelar o aumentar capacidad |
| CO 110 | Order already technically completed | Orden en TECO | CO02 → reactivar si necesario |

### M7 — Material Movements

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| M7 002 | Posting only in periods allowed | Periodo MM cerrado | MMPV → abrir periodo |
| M7 032 | No stock available | Stock insuficiente para GI | Verificar MARD, transferir stock |
| M7 090 | Batch required | Material con gestion lotes sin lote | Indicar lote o configurar determinacion |
| M7 121 | Movement type not allowed | Movimiento no permitido para status | Verificar status orden y tipo movimiento |

### CF — Confirmation

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| CF 010 | Yield exceeds order quantity | Confirmacion > cantidad orden | Verificar tolerancia over-delivery |
| CF 011 | Total scrap exceeds order quantity | Chatarra total > orden | Verificar cantidades |
| CF 015 | Operation already confirmed | Operacion ya confirmada final | CO13 si error, o nueva operacion |
| CF 024 | Missing activity type | Clase actividad no mantenida en puesto | CR02 → verificar asignacion CC/actividad |
| CF 700 | Final confirmation not possible | Componentes pendientes | Retirar componentes primero o forzar |

### PP — Planning

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| PP 060 | MRP type not maintained | Sin tipo MRP en MARC | MM02 → vista MRP1 → indicar DISMM |
| PP 073 | No MRP controller | Sin planificador MRP | MM02 → vista MRP1 → indicar DISPO |
| PP 110 | BOM explosion error | Error al explotar BOM | Verificar BOM (componentes, validez) |
| PP 120 | Scheduling error | Error en programacion | Verificar routing, formulas scheduling |

### 61 — Availability

| Mensaje | Texto | Causa | Solucion |
|---------|-------|-------|----------|
| 61 325 | Availability check failed | Componentes no disponibles | MD04 → verificar, liberar reservas alternativas |
| 61 340 | Required quantity not fully available | Disponibilidad parcial | Aceptar parcial o esperar stock |

### COGI — Automatic GI/GR errors

| Situacion | Causa | Solucion |
|-----------|-------|----------|
| Sin stock para backflush | Stock insuficiente en almacen | MB1A manual, transferir stock, luego COGI reprocesar |
| Sin lote para backflush | Material con batch management | COGI → indicar lote, reprocesar |
| Almacen no determinado | Sin almacen default | COGI → indicar almacen, o MARC-LGPRO |
| Periodo cerrado | Fecha posting en periodo cerrado | COGI → cambiar fecha o abrir periodo |

## Diagnostico rapido por codigo

```
CO 0** → Orden produccion (AFKO, MARC, STKO, PLKO, MKAL)
CF 0** → Confirmacion (AFRU, AFVC, CRCO)
M7 0** → Movimiento material (MARD, MATDOC)
PP 0** → Planificacion/MRP (MARC, PLAF)
61 *** → Disponibilidad (MARD, RESB)
```

## Workflow diagnostico

```
1. Identificar clase mensaje (CO, CF, M7, PP, 61, COGI)
2. T100 → texto exacto
3. GetWhereUsed → programa fuente
4. Leer condicion en codigo
5. Consultar datos relevantes
6. Causa raiz → solucion
```

## Consultas MCP diagnostico

```sql
-- Texto del mensaje
SELECT TEXT FROM T100 WHERE ARBGB = '{clase}' AND MSGNR = '{num}' AND SPRSL = 'E'

-- Verificar datos segun error
-- CO 045: SELECT DISMM FROM MARC WHERE MATNR='{mat}' AND WERKS='{centro}'
-- CO 049: SELECT STLNR FROM MAST WHERE MATNR='{mat}' AND WERKS='{centro}' AND STLAN='1'
-- CO 050: SELECT PLNNR FROM PLKO WHERE MATNR='{mat}' AND WERKS='{centro}' AND PLNTY='N'
-- CO 052: SELECT VEESSION FROM MKAL WHERE MATNR='{mat}' AND WERKS='{centro}'
-- M7 032: SELECT LABST FROM MARD WHERE MATNR='{mat}' AND WERKS='{centro}'
```
