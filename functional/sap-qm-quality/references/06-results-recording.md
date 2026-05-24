# Registro de Resultados

## Concepto

El registro de resultados captura los valores medidos/observados para cada MIC del lote de inspeccion. Puede ser cuantitativo (numeros) o cualitativo (codigos de catalogo).

## Tablas de resultados

| Tabla | Descripcion |
|-------|-------------|
| QASR | Resultados por operacion/MIC (summary) |
| QASE | Resultados individuales (single values) |
| QAMR | Master record resultados |
| QAMV | Valores individuales resultados |

## QASR — Resultados resumen

```sql
SELECT PRUESSION, VESSION, MEESSION, VERWESSION,
       MITESSION, STDESSION, MAXESSION, MINESSION,
       VESSION, LOESSION, NESSION
FROM QASR
WHERE PRUESSION = '{lote}'
```

| Campo | Descripcion |
|-------|-------------|
| PRUESSION | Lote inspeccion |
| VESSION | Operacion |
| MEESSION | MIC number |
| MITESSION | Valor medio |
| STDESSION | Desviacion estandar |
| MAXESSION | Valor maximo |
| MINESSION | Valor minimo |
| LOESSION | Numero de muestras |
| NESSION | Numero de defectos |

## QASE — Valores individuales

```sql
SELECT PRUESSION, VESSION, MEESSION, PROESSION,
       MEESSION, CODGRUPPE, CODE
FROM QASE
WHERE PRUESSION = '{lote}'
ORDER BY VESSION, MEESSION, PROESSION
```

| Campo | Descripcion |
|-------|-------------|
| PROESSION | Numero de muestra |
| MEESSION | Valor medido (cuantitativo) |
| CODGRUPPE | Grupo codigo (cualitativo) |
| CODE | Codigo resultado (cualitativo) |

## Transacciones de registro

| TCode | Descripcion |
|-------|-------------|
| QE01 | Registrar resultados (por operacion) |
| QE02 | Modificar resultados |
| QE03 | Visualizar resultados |
| QE11 | Registrar resultados (por MIC) |
| QE51N | Registrar resultados (nuevo — recomendado) |
| QE71 | Registrar resultados (colectivo) |

## QE51N — Interfaz recomendada

Vista unica que muestra todas las MICs del lote:
- Columnas: MIC, target, tolerancias, resultado, valoracion
- Colores: verde (OK), rojo (fuera tolerancia), gris (pendiente)
- Permite registrar single values o summarized results
- Boton "Accept" confirma los resultados

## Valoracion automatica

### Cuantitativa
```
Si MINESSION <= resultado <= MAXESSION → Accepted
Si resultado < MINESSION o resultado > MAXESSION → Rejected
```

### Cualitativa
- Cada codigo del catalogo tiene indicador accepted/rejected
- Sistema valora automaticamente segun codigo seleccionado

## Confirmacion de resultados

| Nivel | Descripcion |
|-------|-------------|
| No confirmado | Resultados ingresados pero no validados |
| Parcialmente confirmado | Algunas MICs confirmadas |
| Completamente confirmado | Todas las MICs confirmadas |

- Confirmacion habilita la decision de empleo (UD)
- Sin confirmacion → no se puede hacer UD

## Registro de defectos — QF01

Defectos encontrados durante la inspeccion:

| TCode | Descripcion |
|-------|-------------|
| QF01 | Registrar defectos |
| QF02 | Modificar defectos |
| QF03 | Visualizar defectos |

```sql
-- Defectos registrados
SELECT PRUESSION, FEESSION, FESSION, FEESSION,
       OTESSION, OESSION
FROM QAMR
WHERE PRUESSION = '{lote}'
```

## Puntos de inspeccion (Inspection Points)

Para inspeccion en proceso (tipo 03), se pueden definir puntos de inspeccion:
- Por cantidad (cada N piezas)
- Por tiempo (cada N minutos/horas)
- Por lote parcial (cada sub-lote)
- Permite SPC (control charts) con datos en tiempo real

## Consultas MCP diagnostico

```sql
-- Resultados de un lote
SELECT VESSION, MEESSION, MITESSION, STDESSION, LOESSION, NESSION
FROM QASR WHERE PRUESSION = '{lote}' ORDER BY VESSION, MEESSION

-- Valores individuales
SELECT VESSION, MEESSION, PROESSION, MEESSION, CODE
FROM QASE WHERE PRUESSION = '{lote}' ORDER BY VESSION, MEESSION, PROESSION

-- Lotes sin resultados (pendientes)
SELECT PRUESSION, MATNR, WERKS, ART, ERDAT
FROM QALS
WHERE WERKS = '{centro}' AND STAT NOT LIKE '%RREC%' AND STAT NOT LIKE '%UD%'
AND STAT NOT LIKE '%CANC%'
ORDER BY ERDAT
```
