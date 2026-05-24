# SAP CO — Root Cause Analysis Framework

## Principio rector

```
Sintoma → Proceso CO → Objeto CO → Datos maestros → Customizing → Codigo/Mensaje → Causa raiz → Solucion → Validacion
```

## Plantilla obligatoria de diagnostico

### 1. Sintoma

Identificar:
- Transaccion o app: KS01, KO01, KP06, KO88, CO88, KB21N, CK11N, KE30
- Mensaje SAP: clase + numero (KI 235, KO 004, CO 882, KP 045)
- Objeto CO: centro coste, orden, profit center, clase actividad

### 2. Proceso CO afectado

| Proceso | Indicadores |
|---------|-------------|
| Master data CC | CSKS, KS01/KS02, jerarquia |
| Master data PC | CEPC, KE51/KE52 |
| Master data Orden | AUFK, KO01/KO02, status |
| Planning | KP06, KP26, KPF6, version |
| Actual posting | KB21N, KB61, actividades |
| Allocation | KSV5, KSU5, ciclos |
| Settlement | KO88, CO88, regla liquidacion |
| Product costing | CK11N, CK40N, variante costing |
| CO-PA | KE30, KEPM, derivacion |
| Period close | Secuencia cierre, dependencias |

### 3. Evidencia minima

#### Centro de coste
```sql
SELECT * FROM CSKS WHERE KOKRS = '{area}' AND KOSTL = '{cc}';
```

#### Orden interna
```sql
SELECT AUFNR, AUART, BUKRS, KOSTV, PRCTR FROM AUFK WHERE AUFNR = '{orden}';
SELECT OBJNR, STAT, INACT FROM JEST WHERE OBJNR = 'OR{orden}' AND INACT = '';
SELECT * FROM COBRB WHERE AUFNR = '{orden}';
```

#### Mensaje SAP
```sql
SELECT TEXT FROM T100 WHERE ARBGB = '{clase}' AND MSGNR = '{num}' AND SPRSL = 'E';
```

### 4. Causas raiz frecuentes

#### Datos maestros
- CC/PC fuera de validez (DATBI < fecha posting)
- Orden no liberada (status CRTD)
- Clase actividad sin tarifa
- Profit center no asignado

#### Customizing
- Tipo orden sin rango numeros
- Perfil liquidacion no permite receptor
- Version plan no definida
- Costing sheet sin base/rate/credit

### 5. Niveles de confianza

| Nivel | Uso |
|-------|-----|
| Confirmado | Evidencia directa en tablas |
| Muy probable | Coincide con sintomas y reglas SAP |
| Posible | Requiere mas datos |
| No concluyente | Falta informacion |

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
- FI / MM / SD / PP:
```

## Decision rapida por mensaje

| Mensaje | Causa raiz probable | Primer chequeo |
|---------|-------------------|----------------|
| KI* | Centro de coste | CSKS (validez, status) |
| KD* | Clase de coste | CSKA/SKA1 (tipo, validez) |
| KO* | Orden interna | AUFK/JEST (status, tipo) |
| KP* | Planificacion/presupuesto | TKA09/AUFK |
| KA* | Clase de actividad | CSLA (validez, tarifa) |
| CO* | Settlement | COBRB (regla liquidacion) |
| CK* | Product costing | KEKO/MBEW |

## Regla de oro

Nunca recomendar cambiar customizing CO sin advertir:
- Que puede afectar la secuencia de cierre
- Que debe probarse en QA
- Que debe revisarse transporte
- Que puede tener impacto FI, MM, SD
