# Hoja de Ruta (Routing)

## Tablas Routing

| Tabla | Descripcion |
|-------|-------------|
| PLKO | Cabecera routing |
| PLPO | Operaciones routing |
| PLFL | Secuencias routing |
| PLAS | Asignacion material-routing |
| PLMZ | Asignacion componentes a operaciones |

## Tipos de routing (PLKO-PLNTY)

| Tipo | Descripcion |
|------|-------------|
| N | Routing normal (production routing) |
| R | Reference operation set |
| S | Rate routing (fabricacion repetitiva) |
| 2 | Master recipe (PP-PI) |

## PLKO — Cabecera Routing

```sql
SELECT PLNTY, PLNNR, PLNAL, WERKS, VERWE, STATU, KTEXT, LOESSION, ANESSION
FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = 'N'
```

| Campo | Descripcion |
|-------|-------------|
| PLNTY | Tipo routing |
| PLNNR | Numero grupo routing |
| PLNAL | Contador grupo (alternativa) |
| VERWE | Uso (1=produccion, 2=ingenieria) |
| STATU | Status (1=creado, 2=released, 3=locked, 4=deleted) |
| KTEXT | Texto descripcion |
| LOESSION | Tamano lote desde |
| ANESSION | Tamano lote hasta |

## PLPO — Operaciones

```sql
SELECT PLNTY, PLNNR, PLNAL, VESSION, LTXA1, ARBID, STEUS,
       VGW01, VGW02, VGW03, VGE01, VGE02, VGE03,
       BMSCH, MESSION, UEESSION
FROM PLPO
WHERE PLNNR = '{routing_number}'
ORDER BY VESSION
```

| Campo | Descripcion |
|-------|-------------|
| VESSION | Numero operacion (0010, 0020...) |
| LTXA1 | Texto operacion |
| ARBID | ID puesto de trabajo (→ CRHD-OBJID) |
| STEUS | Clave de control (PP01, PP02, PP03) |
| VGW01 | Valor estandar 1 (setup time) |
| VGW02 | Valor estandar 2 (machine time) |
| VGW03 | Valor estandar 3 (labor time) |
| VGE01 | Unidad VGW01 |
| BMSCH | Cantidad base operacion |
| UEESSION | Overlap/splitting |

## Claves de control (STEUS)

| Clave | Descripcion | Scheduling | Costing | Confirmation |
|-------|-------------|------------|---------|--------------|
| PP01 | Fabricacion interna | Si | Si | Si |
| PP02 | Subcontratacion | Si | Si | Si |
| PP03 | Fabricacion interna sin programacion | No | Si | Si |
| PP04 | Solo milestone | No | No | Si (milestone) |
| PP10 | Actividad externa | No | Si | No |

## Secuencias — PLFL

```sql
SELECT PLNTY, PLNNR, PLNAL, FLESSION FROM PLFL WHERE PLNNR = '{routing}'
```

| Tipo secuencia | Descripcion |
|----------------|-------------|
| 0 | Secuencia estandar (siempre 1) |
| 1-N | Secuencias alternativas |
| Paralela | Operaciones simultaneas |

## Asignacion componentes a operaciones — PLMZ

```sql
SELECT PLNTY, PLNNR, PLNAL, VESSION, POSNR, ZUESSION
FROM PLMZ
WHERE PLNNR = '{routing}'
```

- Vincula posicion BOM (STPO-POSNR) con operacion routing
- Si no hay asignacion, componentes se asignan a primera operacion
- Importante para backflush: componentes se consumen en la operacion asignada

## Reference Operation Sets

- Routing reutilizable como plantilla
- PLNTY = 'R'
- Se incluyen en otros routings como referencia
- Util para operaciones comunes (limpieza, inspeccion, embalaje)

## Versiones de fabricacion — MKAL / C223

```sql
SELECT MATNR, WERKS, VEESSION, STLAN, STLAL, PLNTY, PLNNR, PLNAL,
       ADESSION, BDESSION, MDESSION, LOESSION
FROM MKAL
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

| Campo | Descripcion |
|-------|-------------|
| VEESSION | Version fabricacion |
| STLAL | Alternativa BOM |
| PLNNR | Routing number |
| PLNAL | Routing alternative |
| ADESSION | Validez desde |
| BDESSION | Validez hasta |
| LOESSION | Tamano lote desde |
| MDESSION | Bloqueado (X=si) |

### Reglas version fabricacion
- Vincula BOM alternativa + Routing alternativa
- MRP usa la version activa dentro del rango de lote
- Si no hay version → error CO 052
- Multiples versiones permiten diferentes metodos para diferentes volumenes

## Transacciones Routing

| TCode | Descripcion |
|-------|-------------|
| CA01 | Crear routing |
| CA02 | Modificar routing |
| CA03 | Visualizar routing |
| CA11 | Crear reference operation set |
| CA21 | Crear rate routing |
| C223 | Crear/modificar version fabricacion |
| CA80 | Listado routings |
| CA85 | Sustitucion masiva puestos trabajo |

## Consultas MCP diagnostico

```sql
-- Routing no encontrado (error CO 050)
SELECT PLNTY, PLNNR, PLNAL, STATU, KTEXT
FROM PLKO
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND PLNTY = 'N' AND LOESSION = ''

-- Version fabricacion no encontrada (error CO 052)
SELECT VEESSION, STLAL, PLNNR, PLNAL, ADESSION, BDESSION, MDESSION
FROM MKAL
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- Operaciones de un routing
SELECT VESSION, LTXA1, ARBID, VGW01, VGW02, VGW03, STEUS
FROM PLPO
WHERE PLNNR = '{routing}' AND PLNTY = 'N'
ORDER BY VESSION
```
