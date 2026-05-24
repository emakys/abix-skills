# Estrategias de Putaway (Ubicación de Entrada)

## Concepto

La estrategia de putaway determina en qué bin se almacenará un producto al ingresar al almacén. EWM evalúa una secuencia de storage types y dentro de cada uno aplica la estrategia configurada para encontrar el bin óptimo.

## Tabla de Configuración: /SCWM/T331

Tabla de estrategias de putaway por storage type y tipo de proceso.

```
Campos clave:
- LGNUM   : Número de almacén
- LGTYP   : Storage type
- EINLART : Tipo de proceso de entrada
- LSTRAT  : Estrategia de putaway (código)
- SORTF   : Criterio de ordenamiento de bins candidatos
```

## Tipos de Estrategia de Putaway

### P — Bin Vacío Siguiente (Next Empty Bin)
- El sistema busca el primer bin vacío disponible.
- Ordenamiento: por número de bin (ascendente por defecto).
- Uso: almacenamiento estático aleatorio, alta rotación.
- Configuración: definir el rango de bins elegibles en el storage type.

### F — Bin Fijo (Fixed Bin)
- El material tiene un bin asignado de forma permanente.
- Configuración en `/SCWM/QLBIN` — asignación material-bin.
- Si el bin fijo está lleno, puede configurarse un bin alternativo o error.
- Uso: almacenes de distribución, materiales con reabastecimiento frecuente.

### B — Almacenamiento en Bloque (Bulk Storage)
- Apilado de pallets del mismo material en filas.
- Maximiza la capacidad volumétrica del almacén.
- El sistema determina la fila y posición dentro del bloque.
- Requiere configuración de coordenadas de bin (fila, columna, nivel).

### A — Adición a Stock (Addition to Existing Stock)
- Ubica el material junto a stock existente del mismo producto.
- Optimiza la consolidación y reduce la fragmentación de stock.
- Requiere que el bin tenga capacidad residual.
- Uso: almacenes con bins de gran capacidad (estanterías de flujo).

### N — Cerca del Picking (Near Pick Point)
- Ubica el stock de reserva cerca del bin de picking activo.
- Reduce el tiempo de reabastecimiento cuando el bin de pick se vacía.
- Requiere definición del bin de picking asociado en `/SCWM/QLBIN`.

### G — Área General (General Area)
- Asignación por sección o área, sin bin específico.
- El sistema selecciona cualquier bin disponible dentro del área.
- Uso: zonas de staging, áreas de overflow.

### C — Cerca del Bin de Almacenamiento Existente
- Ubica el nuevo stock adyacente al stock existente del mismo material.
- Minimiza el recorrido en operaciones de reabastecimiento.

### Z — Estrategia Custom (via BAdI)
- Implementación propia vía BAdI `/SCWM/EX_STORE_LSTRAT`.
- Permite lógica específica del cliente: rotación especial, reglas de negocio propietarias.

## Secuencia de Búsqueda de Storage Types

El sistema evalúa los storage types en orden hasta encontrar bin disponible.

Configuración en `/SCWM/T331T` — Storage Type Search Sequence:

```
Paso 1: Storage Type de alta densidad (ej. estantería drive-in)
Paso 2: Storage Type estándar (ej. estantería convencional)
Paso 3: Storage Type de overflow (ej. área de piso)
```

Para cada storage type en la secuencia:
1. Se verifica si el tipo acepta el material (restricciones de mezcla, peligroso, etc.).
2. Se aplica la estrategia configurada para ese tipo.
3. Si no hay bin disponible, se pasa al siguiente tipo.

## Reglas de Determinación

### Perfil de Almacenamiento (Storage Section)
- Los bins se agrupan en secciones dentro del storage type.
- Configuración en `/SCWM/T320` — Storage Sections.
- Ejemplo: sección A (picking activo), sección B (reserva), sección C (cuarentena).

### Verificación de Capacidad
- EWM verifica que el bin destino tenga capacidad suficiente.
- Métodos de capacidad:
  - **Cantidad máxima:** número máximo de unidades por bin.
  - **Peso máximo:** límite de carga en kg.
  - **Volumen máximo:** capacidad en m³.
  - **Número de HUs:** máximo de unidades de manejo.
- Sin capacidad disponible → siguiente bin candidato.

### Reglas de Mezcla de Stock

Configuración en `/SCWM/T305` — Mixed Storage:

| Regla | Descripción |
|-------|-------------|
| Mezcla permitida | Múltiples materiales en el mismo bin |
| Solo mismo material | Prohibida mezcla de materiales distintos |
| Solo mismo lote | Prohibida mezcla de lotes distintos |
| Solo mismo propietario | Separación por propietario de stock |
| Solo misma categoría de stock | Separación por calidad (libre, bloqueado, control calidad) |

### Reglas para Materiales Peligrosos (Hazmat)
- Materiales con clase de peligro asignada se almacenan en zonas dedicadas.
- Configuración: clase de peligro en maestro de materiales → storage type exclusivo.
- El sistema bloquea el putaway en bins que ya contienen materiales incompatibles.
- Integración con DG Management (Dangerous Goods) de SAP TM/EWM.

### Separación de Lotes (Batch Separation)
- Cada lote de material en un bin separado (configuración en `/SCWM/QUCONT`).
- Estrategia FEFO requiere bins separados por lote con fecha de caducidad.
- Útil en industrias farmacéuticas, alimentarias, químicas.

## Perfil de Estrategia (Strategy Profile)

El perfil agrupa todas las configuraciones de putaway para un warehouse process type:
- Storage type search sequence.
- Estrategia por storage type.
- Reglas de mezcla aplicables.
- Verificaciones de capacidad activas.

Configuración en `/SCWM/PROFS` — Storage Process.

## Árbol de Decisión para Elección de Estrategia

```
¿El material tiene bin fijo?
├── SÍ → Estrategia F (Fixed Bin)
└── NO → ¿Es almacenamiento masivo/bloque?
          ├── SÍ → Estrategia B (Bulk Storage)
          └── NO → ¿Hay stock previo del mismo material?
                    ├── SÍ → Estrategia A (Addition to Stock)
                    └── NO → ¿Debe estar cerca del pick point?
                              ├── SÍ → Estrategia N (Near Pick)
                              └── NO → Estrategia P (Next Empty Bin)
```

## Consultas MCP relevantes

```
// Configuración de estrategias por storage type en almacén
ReadTable: /SCWM/T331 WHERE LGNUM = 'ZW01'

// Bins fijos asignados a un material
ReadTable: /SCWM/QLBIN WHERE LGNUM = 'ZW01' AND MATNR = 'MAT-001'

// Stock actual por bin (para verificar disponibilidad)
ReadTable: /SCWM/QUAKEY WHERE LGNUM = 'ZW01' AND LGTYP = 'F001'

// Restricciones de mezcla por storage type
ReadTable: /SCWM/T305 WHERE LGNUM = 'ZW01' AND LGTYP = 'F001'

// Secuencia de búsqueda de storage types para putaway
ReadTable: /SCWM/T331T WHERE LGNUM = 'ZW01' AND PROCTY = 'PTIN'

// Capacidad configurada por storage type
ReadTable: /SCWM/T301 WHERE LGNUM = 'ZW01' AND LGTYP = 'F001'
```

## Notas de implementación S/4HANA 2023

- BAdI `/SCWM/EX_STORE_LSTRAT` permite implementar estrategia custom completa.
- BAdI `/SCWM/EX_BIN_DETERMINATION` para control granular de determinación de bin.
- En S/4HANA 2023 embedded EWM, la búsqueda de bins es transaccional (sin jobs de reserva de bins).
- Para almacenes con WM integrado (legacy), la migración a EWM implica reconfigurar todas las estrategias en /SCWM/ namespace.
- El campo `LSTRAT` en `/SCWM/T331` acepta los códigos estándar (P, F, B, A, N, G, C) o valores Z para custom.
