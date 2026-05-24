# Fabricacion Repetitiva (Repetitive Manufacturing)

## Concepto

Fabricacion repetitiva es un modelo simplificado para produccion en serie/alto volumen donde no se requieren ordenes de produccion individuales. La planificacion se basa en ordenes previsionales y la ejecucion en backflush por periodo.

## Diferencias vs Orden de Produccion

| Aspecto | Orden Produccion | Repetitive Manufacturing |
|---------|-------------------|--------------------------|
| Documento | Orden (AUFNR) | Orden previsional (PLNUM) |
| Liberacion | Explicita (REL) | No necesaria |
| Confirmacion | CO11N/CO15 | MFBF (backflush) |
| Coste | Por orden individual | Por periodo/linea |
| Complejidad | Alta | Baja |
| Volumen | Bajo-medio | Alto |
| Variabilidad | Alta | Baja |

## Prerequisitos

1. Material con perfil fabricacion repetitiva (MARC-SESSION)
2. Version de fabricacion activa (MKAL)
3. Linea de produccion (puesto trabajo tipo 007)
4. BOM y routing asignados via version fabricacion
5. Rate routing (PLNTY = 'S') recomendado

## Configuracion material — MARC

| Campo | Descripcion | Valor |
|-------|-------------|-------|
| SESSION | Perfil repetitive manufacturing | 0001 (estandar) |
| BESKZ | Tipo aprovisionamiento | E |
| DISMM | Tipo MRP | PD |
| STRGR | Strategy group | 10 o 40 |

## Lineas de produccion

- Puesto de trabajo con tipo capacidad 007
- Representa una linea de produccion completa
- Multiples productos pueden compartir linea
- Takt time define ritmo de produccion

## Flujo Repetitive Manufacturing

```
1. Planificacion demanda (MD61 → PIR)
2. MRP (MD01) → genera ordenes previsionales
3. MF50 → tabla de planificacion (asignar a linea)
4. MFBF → backflush (consumo + produccion)
5. MF42N → lista backflush masivo
6. Cierre periodo → WIP/Varianza
```

## MF50 — Tabla de planificacion

Vista grafica para asignar ordenes previsionales a lineas de produccion:
- Eje horizontal: tiempo (dias/semanas)
- Eje vertical: lineas de produccion
- Drag & drop de cantidades

## MFBF — Backflush

Registra en un solo paso:
1. Entrada de mercancias producto (mov. 131)
2. Salida de mercancias componentes (mov. 261)
3. Confirmacion de actividades

### Movimientos REM

| Mov. | Descripcion |
|------|-------------|
| 131 | GR produccion repetitiva |
| 132 | Anulacion GR repetitiva |
| 261 | GI componentes (backflush) |
| 262 | Anulacion GI componentes |

## MF42N — Backflush masivo

Para procesar multiples materiales/lineas en un solo paso.

## Costes en Repetitive Manufacturing

- No hay ordenes de produccion → costes se acumulan por **cost collector**
- Product cost collector = orden CO especial para acumular costes
- Se crea automaticamente o con KKF6N
- Varianzas se calculan por periodo, no por orden individual

### Transacciones coste REM

| TCode | Descripcion |
|-------|-------------|
| KKF6N | Crear product cost collector |
| KKPHM | Asignacion de materiales |
| KKAO | Calculo WIP |
| KKS1 | Calculo varianzas |
| CO88 | Settlement |

## Reporting REM

| TCode | Descripcion |
|-------|-------------|
| MF12 | Lista de backflush |
| MF13 | Evaluacion REM |
| MFAP | Evaluacion planificacion |
| MF26 | Lista pull list |

## Consultas MCP

```sql
-- Materiales con perfil REM
SELECT MATNR, WERKS, SESSION, BESKZ FROM MARC
WHERE WERKS = '{centro}' AND SESSION <> ''

-- Versiones fabricacion para REM
SELECT MATNR, VEESSION, STLAL, PLNNR, PLNAL, ADESSION, BDESSION
FROM MKAL WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Product cost collectors
SELECT AUFNR, PLNBEZ, WERKS FROM AFKO
WHERE PLNBEZ = '{material}' AND WERKS = '{centro}' AND AUART = 'RM01'
```
