# Estrategias de Extracción de Stock (Picking)

## Concepto

La estrategia de extracción determina desde qué bin y en qué orden se toma el stock cuando se crea una Warehouse Task de salida. El objetivo es optimizar el recorrido, respetar reglas de rotación y garantizar la calidad del stock entregado.

## Tabla de Configuración: /SCWM/T332

Tabla de estrategias de extracción por storage type y tipo de proceso.

```
Campos clave:
- LGNUM   : Número de almacén
- LGTYP   : Storage type
- AUSLART : Tipo de proceso de salida
- LSTRAT  : Estrategia de extracción (código)
- SORTF   : Criterio de ordenamiento de bins candidatos
```

## Tipos de Estrategia de Extracción

### F — FIFO (First In, First Out)
- Se extrae primero el stock con fecha de entrada más antigua.
- El sistema usa la fecha de posting en EWM como referencia.
- Uso: materiales con riesgo de obsolescencia, componentes electrónicos.
- Configuración: activar campo de fecha de goods receipt en categoría de stock.

### L — LIFO (Last In, First Out)
- Se extrae primero el stock más reciente.
- Uso: almacenamiento en bloque donde el acceso al stock antiguo es físicamente difícil (ej. apilado de pallets).
- No recomendado para productos con caducidad.

### E — FEFO (First Expired, First Out)
- Se extrae primero el stock con fecha de caducidad más próxima.
- Requiere gestión por lotes con campo SLED (Shelf Life Expiration Date) activo.
- El sistema consulta tabla `/SCWM/QUAN` + datos de lote para obtener la fecha de caducidad.
- Uso: industria farmacéutica, alimentaria, cosmética, química.

### P — Primero Cantidades Parciales (Partial Quantities First)
- Se extrae primero de bins que tienen cantidad parcial (no pallets completos).
- Consolida el stock residual antes de abrir nuevas unidades.
- Optimiza el uso del espacio de almacenamiento.
- Uso: almacenes con alta variación de cantidades por bin.

### N — Bin Fijo (Fixed Bin Removal)
- La extracción siempre proviene del bin fijo asignado al material.
- Compatible con estrategia de putaway F (Fixed Bin).
- Garantiza que el picking siempre ocurra en la ubicación conocida por el operario.

### S — Menor Cantidad Restante (Smallest Remaining Quantity)
- Se extrae del bin con menor cantidad de stock.
- Vacía bins más rápido, liberando espacio.
- Uso: almacenes con reposición frecuente y espacio limitado.

### Z — Estrategia Custom (via BAdI)
- Implementación propia vía BAdI `/SCWM/EX_STORE_LSTRAT_OUT`.
- Permite combinar múltiples criterios propietarios.

## Reglas de Clasificación de Cantidades (Quantity Classification)

El sistema clasifica la cantidad requerida para determinar si se puede satisfacer desde un solo bin o requiere múltiples bins:

- **Cantidad exacta:** el bin tiene exactamente la cantidad solicitada.
- **Cantidad mayor:** el bin tiene más del solicitado (requiere split del bin).
- **Cantidad menor:** el bin tiene menos (requiere picking de múltiples bins).

Configuración de picking multi-bin en `/SCWM/QURULE` — Warehouse Order Creation Rules.

## Extracción desde Múltiples Bins

Cuando un bin no tiene suficiente stock para satisfacer la demanda completa:

1. El sistema selecciona el primer bin según la estrategia configurada.
2. Crea una WT con toda la cantidad disponible en ese bin.
3. Continúa con el siguiente bin candidato.
4. Repite hasta completar la cantidad requerida.

Límite configurable de bins por WT o por WO.

## Pick Point (Punto de Picking)

El pick point es un bin de picking activo asociado a un bin de reserva.

- El picking ocurre siempre en el pick point (bin de acceso fácil, bajo nivel).
- El bin de reserva alimenta al pick point via reabastecimiento.
- Configuración en `/SCWM/QLBIN` — relación pick point ↔ bin de reserva.

### Determinación del Pick Point
1. Sistema verifica si el material tiene pick point asignado.
2. Si el pick point tiene stock suficiente → picking del pick point.
3. Si el pick point está vacío o insuficiente → reabastecimiento automático + espera, o picking directo del bin de reserva (según configuración).

## FEFO con Gestión de Vida Útil (/SCWM/ Batch SLED)

Para estrategia FEFO, la integración con lotes es crítica:

```
Tablas involucradas:
- MCH1  : Datos de lote a nivel cliente
- MCHA  : Datos de lote a nivel planta
- /SCWM/AQUA : Stock cuantificado en EWM con referencia a lote
```

Configuración necesaria:
1. Activar gestión por lotes en maestro de materiales (clase de valoración con lotes).
2. Configurar SLED (Shelf Life Expiration Date) en clase de lote.
3. Activar verificación de vida útil mínima en la expedición (MHDRST en planta).
4. En EWM: estrategia de extracción E + campo de clasificación SLED en `/SCWM/T332`.

El sistema ordena los bins candidatos por fecha de caducidad ascendente → el stock más próximo a vencer sale primero.

## Secuencia de Búsqueda de Storage Types para Extracción

Análoga a la de putaway pero en sentido inverso (salida):

Configuración en `/SCWM/T332T` — Storage Type Search Sequence for Removal:

```
Paso 1: Pick points / bins de picking activo (acceso directo)
Paso 2: Storage type de estantería estándar
Paso 3: Storage type de bloque / reserva
```

El sistema intenta satisfacer la demanda desde el storage type de menor esfuerzo primero.

## Reglas de Ordenamiento (Sort Rules)

Dentro de una estrategia, los bins candidatos se ordenan por criterios adicionales:

| Criterio | Descripción |
|----------|-------------|
| Número de bin | Secuencia alfanumérica (optimiza ruta de picking) |
| Fecha de entrada | FIFO temporal |
| Fecha de caducidad | FEFO |
| Cantidad disponible | Mayor o menor stock primero |
| Distancia al staging | Minimiza recorrido total |
| Peso | Optimiza carga del recurso |

Configuración del campo `SORTF` en `/SCWM/T332`.

## Árbol de Decisión para Elección de Estrategia

```
¿El material tiene fecha de caducidad (SLED)?
├── SÍ → Estrategia E (FEFO)
└── NO → ¿Se requiere rotación estricta por antigüedad?
          ├── SÍ → Estrategia F (FIFO)
          └── NO → ¿Es almacenamiento en bloque con acceso LIFO físico?
                    ├── SÍ → Estrategia L (LIFO)
                    └── NO → ¿Hay pick points definidos?
                              ├── SÍ → Estrategia N (Fixed Bin / Pick Point)
                              └── NO → ¿Se quiere consolidar stock residual?
                                        ├── SÍ → Estrategia P (Partial First)
                                        └── NO → Estrategia S (Smallest Qty)
```

## Consultas MCP relevantes

```
// Estrategias de extracción configuradas en el almacén
ReadTable: /SCWM/T332 WHERE LGNUM = 'ZW01'

// Stock disponible ordenado por fecha de entrada (FIFO)
ReadTable: /SCWM/AQUA WHERE LGNUM = 'ZW01' AND MATNR = 'MAT-001' ORDER BY PSTNG_DATE ASCENDING

// Stock con fecha de caducidad (FEFO)
ReadTable: /SCWM/AQUA WHERE LGNUM = 'ZW01' AND MATNR = 'MAT-001' ORDER BY VFDAT ASCENDING

// Pick points asignados a un material
ReadTable: /SCWM/QLBIN WHERE LGNUM = 'ZW01' AND MATNR = 'MAT-001' AND QLBINTY = 'PICKP'

// Secuencia de storage types para extracción
ReadTable: /SCWM/T332T WHERE LGNUM = 'ZW01' AND PROCTY = 'PTOUT'

// Bins con cantidades parciales de un material (estrategia P)
ReadTable: /SCWM/AQUA WHERE LGNUM = 'ZW01' AND MATNR = 'MAT-001' AND QUAN < MAXQUAN
```

## Notas de implementación S/4HANA 2023

- BAdI `/SCWM/EX_STORE_LSTRAT_OUT` para estrategia de extracción custom completa.
- BAdI `/SCWM/EX_BIN_SEL_STRAT` para control del ordenamiento de bins candidatos.
- En S/4HANA 2023 con EWM embedded, la verificación SLED se realiza en tiempo real durante la creación de WT.
- La integración con SAP QM puede bloquear stock en "Inspection" — el picking solo toma stock en categoría "Unrestricted".
- Para almacenes con alta automatización, las estrategias se combinan con el módulo de Resource Management para asignar rutas óptimas a AGVs.
- Verificar que `VFDAT` (fecha de vencimiento) esté configurada como criterio de clasificación de lote en el customizing de batch management.
