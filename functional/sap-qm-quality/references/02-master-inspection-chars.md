# Caracteristicas de Inspeccion Maestras (MIC)

## Concepto

Las Master Inspection Characteristics (MIC) son las pruebas/mediciones individuales que se aplican a un material. Pueden ser cuantitativas (medicion numerica) o cualitativas (atributo/visual).

## Tabla principal — QPMK

```sql
SELECT MKMNR, KUESSION, MKVERSION, WERESSION, ART,
       STESSION, VERWMKVERSION
FROM QPMK
WHERE MKMNR = '{mic_number}'
```

| Campo | Descripcion |
|-------|-------------|
| MKMNR | Numero MIC |
| KUESSION | Texto corto MIC |
| MKVERSION | Version |
| ART | Tipo (quantitative/qualitative) |
| STESSION | Status (1=released) |

## Tipos de MIC

### Cuantitativa (Quantitative)
- Resultado numerico con tolerancias
- Limites: LSL (lower spec limit), USL (upper spec limit)
- Target value (valor nominal)
- Unidad de medida

### Cualitativa (Qualitative)
- Resultado por catalogo de codigos (pass/fail, colores, grados)
- Referencia a catalogo (QPCT)
- Valoracion: accepted/rejected segun codigo seleccionado

## Campos clave MIC cuantitativa

| Campo | Descripcion |
|-------|-------------|
| SOLLWERT | Target value (valor nominal) |
| TOLERANZOB | Tolerancia superior |
| TOLERANZUN | Tolerancia inferior |
| MASSEINHSW | Unidad de medida |
| STESSION | Decimal places |
| QPMK-VERWMKVERSION | Control chart type (SPC) |

## Campos clave MIC cualitativa

| Campo | Descripcion |
|-------|-------------|
| KATALOGART | Tipo catalogo (codigos resultado) |
| AUESSION | Selected set (grupo codigos) |
| KATVERSION | Version catalogo |

## Transacciones MIC

| TCode | Descripcion |
|-------|-------------|
| QS21 | Crear MIC |
| QS22 | Modificar MIC |
| QS23 | Visualizar MIC |
| QS24 | Listar MICs |
| QS28 | Sustitucion masiva |
| QS29 | Where-used MIC |

## MIC por planta vs general

| Nivel | Descripcion |
|-------|-------------|
| General (mandante) | MIC disponible en todas las plantas |
| Por planta | MIC con parametros especificos por centro |

```sql
-- MICs de un centro
SELECT MKMNR, KUESSION, WERESSION FROM QPMK
WHERE WERESSION = '{centro}' OR WERESSION = ''
ORDER BY MKMNR
```

## Metodos de inspeccion — QS31

Metodos vinculados a MICs que definen COMO realizar la prueba.

| TCode | Descripcion |
|-------|-------------|
| QS31 | Crear metodo inspeccion |
| QS32 | Modificar metodo |
| QS33 | Visualizar metodo |

```sql
SELECT PMETHODE, KUESSION FROM QPMM WHERE PMETHODE = '{metodo}'
```

## Relacion MIC → Plan inspeccion

```
MIC (QS21) — "Que medir"
     ↓
Metodo (QS31) — "Como medir"
     ↓
Plan inspeccion (QP01) — "Cuando y cuanto medir"
     └── Operacion → MIC asignada con:
         - Sampling procedure
         - Limites especificos (pueden override MIC)
         - Metodo especifico
```

## Consultas MCP diagnostico

```sql
-- MIC por material (via plan inspeccion)
SELECT P.VESSION, P.MERESSION, P.VERWESSION
FROM PLPO P
INNER JOIN PLKO K ON P.PLNNR = K.PLNNR AND P.PLNTY = K.PLNTY
WHERE K.MATNR = '{material}' AND K.WERKS = '{centro}' AND K.PLNTY = 'Q'

-- Buscar MIC por texto
SELECT MKMNR, KUESSION FROM QPMK WHERE KUESSION LIKE '%{texto}%'
```
