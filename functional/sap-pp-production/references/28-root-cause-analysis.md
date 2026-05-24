# Root Cause Analysis Framework — PP

## Principio rector

```
Sintoma → Proceso PP → Datos maestros → Customizing → Codigo/Mensaje → Causa raiz → Solucion → Validacion
```

## Plantilla de diagnostico

### 1. Sintoma

Identificar:
- Transaccion/app: CO01, CO02, CO11N, CO15, MD01, MD04, MIGO, COGI, CS01, CA01
- Mensaje SAP: clase + numero (CO 045, CF 010, M7 032, PP 060, 61 325)
- Objeto: orden produccion, material, BOM, routing, puesto trabajo

### 2. Proceso PP afectado

| Proceso | Indicadores |
|---------|-------------|
| MRP | MD01/MD04, ordenes previsionales, PIR |
| Orden produccion | CO01/CO02, AFKO, status JEST |
| BOM | CS01/CS02, STKO/STPO, explosion |
| Routing | CA01/CA02, PLKO/PLPO, operaciones |
| Work center | CR01/CR02, CRHD, capacidad |
| Confirmacion | CO11N/CO15, AFRU, tiempos |
| Goods movement | MIGO, MATDOC, backflush |
| Disponibilidad | ATP, RESB, stock |
| Capacidad | CM01, carga vs disponible |
| Cierre | KKAO, KKS1, CO88 |

### 3. Evidencia minima

#### Material-centro
```sql
SELECT MATNR, WERKS, DISMM, DISPO, DISLS, BESKZ, SOBSL, DZEIT, PLIFZ, STRGR
FROM MARC WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

#### Orden produccion
```sql
SELECT AUFNR, AUART, PLNBEZ, GAMNG, GSTRP, GLTRP, STLNR, PLNNR
FROM AFKO WHERE AUFNR = '{orden}'

SELECT OBJNR, STAT, INACT FROM JEST
WHERE OBJNR = 'OR{orden}' AND INACT = ''
```

#### BOM
```sql
SELECT MATNR, WERKS, STLNR, STLAL FROM MAST
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND STLAN = '1'
```

#### Routing
```sql
SELECT PLNTY, PLNNR, PLNAL, STATU FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = 'N'
```

#### Version fabricacion
```sql
SELECT VEESSION, STLAL, PLNNR, PLNAL, MDESSION FROM MKAL
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

#### Stock
```sql
SELECT LGORT, LABST, INSME, SPEME FROM MARD
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

#### Mensaje SAP
```sql
SELECT TEXT FROM T100 WHERE ARBGB = '{clase}' AND MSGNR = '{num}' AND SPRSL = 'E'
```

### 4. Arbol de causas por area

#### BOM/Routing no encontrado
```
BOM not found (CO 049)?
├── MAST vacio → CS01 crear BOM
├── STLAN ≠ 1 (uso produccion) → CS02 verificar uso
├── STKO-LOESSION = 'X' (borrada) → CS01 recrear
├── Validez temporal → CS02 extender DAESSION/ANESSION
└── Centro incorrecto → verificar MAST-WERKS

Routing not found (CO 050)?
├── PLKO vacio → CA01 crear routing
├── PLKO-STATU = '4' (deleted) → CA01 recrear
├── PLKO-LOESSION = 'X' (borrada) → verificar
└── Rango tamano lote no aplica → CA02 ajustar LOESSION/ANESSION
```

#### MRP no genera propuestas
```
MRP sin resultado?
├── MARC-DISMM = 'ND' → cambiar a PD
├── MARC-DISPO vacio → asignar planificador
├── Sin necesidades (PIR/pedidos) → MD61 crear PIR
├── Stock cubre necesidades → verificar MD04
├── Material bloqueado/eliminado → MARC status
└── Area MRP incorrecta → verificar T460A
```

#### Confirmacion falla
```
Error en confirmacion?
├── CF 010 (yield > qty) → tolerancia MARC-UEESSION
├── CF 015 (ya confirmada) → CO13 si error, o verificar
├── Sin puesto trabajo → AFVC-ARBID → CRHD
├── Sin CC/actividad → CRCO → verificar asignacion
├── Operacion bloqueada → JEST status operacion
└── COGI backflush → stock insuficiente → MARD
```

### 5. Niveles de confianza

| Nivel | Criterio |
|-------|----------|
| Confirmado | Evidencia directa en tablas |
| Muy probable | Coincide con sintomas y reglas SAP |
| Posible | Requiere mas datos para confirmar |
| No concluyente | Falta informacion critica |

### 6. Formato de respuesta

```
## Diagnostico
- Proceso:
- Mensaje:
- Causa raiz probable:

## Evidencia
- Tabla/documento:
- Customizing:

## Solucion
1.
2.
3.

## Validacion
-

## Impacto
- MM / CO / SD / QM:
```

## Decision rapida por mensaje

| Prefijo | Area | Primer chequeo |
|---------|------|----------------|
| CO 0** | Orden produccion | AFKO, MARC, STKO, PLKO, MKAL |
| CF 0** | Confirmacion | AFRU, AFVC, CRCO, CRHD |
| M7 0** | Movimiento material | MARD, MATDOC, periodo MM |
| PP 0** | MRP / planificacion | MARC (DISMM, DISPO) |
| 61 *** | Disponibilidad | MARD, RESB, ATP config |
| COGI | Backflush error | Stock, lote, almacen |

## Regla de oro PP

Nunca recomendar cambios en:
- Tipo MRP, strategy group, lot size → sin entender impacto en MRP run completo
- Routing/BOM → sin verificar version fabricacion activa
- Customizing confirmacion → sin probar en QA
- Tolerancias → sin aprobar con produccion
