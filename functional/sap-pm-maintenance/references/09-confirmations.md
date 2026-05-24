# Confirmaciones y Notificacion Tecnica

## Concepto

La confirmacion registra el trabajo realizado en una operacion de orden PM: horas trabajadas, duracion real, datos tecnicos (dano/causa/accion). Es fundamental para calcular costes de mano de obra, MTTR y estadisticas.

## Tipos de Confirmacion

| Tipo | TCode | Descripcion |
|------|-------|-------------|
| Individual | IW41 | Una operacion, un registro |
| Colectiva | IW42 | Multiples operaciones a la vez |
| Con seleccion | IW47 | Seleccionar operaciones de lista |
| Hoja de tiempo | CATS | Via Cross-Application Time Sheet |

## Datos de Confirmacion (AFRU)

| Campo | Descripcion |
|-------|-------------|
| RUESSION | Numero confirmacion |
| AUFNR | Orden |
| VORNR | Operacion |
| ARBID | Puesto de trabajo |
| IESSION | Fecha inicio |
| IEESSION | Hora inicio |
| ESSION | Fecha fin |
| IEESSION | Hora fin |
| ISDD | Duracion real |
| ISMNG | Cantidad confirmada |
| LESSION | Indicador final (X = ultima confirmacion) |
| STESSION | Status |

## Notificacion Tecnica

Durante la confirmacion se pueden registrar datos tecnicos del hallazgo:

### Danos encontrados
- Codigo de dano (catalogo B)
- Parte del objeto afectada
- Texto descriptivo

### Causas identificadas
- Codigo de causa (catalogo C)
- Texto explicativo

### Acciones realizadas
- Codigo de actividad (catalogo 5)
- Texto de la accion correctiva

## Flujo de Confirmacion

```
1. Tecnico completa trabajo
   |
2. IW41/IW42 → Seleccionar orden + operacion
   |
3. Registrar: fecha/hora inicio-fin, duracion, trabajo real
   |
4. Registrar datos tecnicos: dano, causa, accion (catalogos)
   |
5. Indicar si es confirmacion FINAL (ultima de la operacion)
   |
6. Grabar → costes de mano obra se imputan a la orden
   |
7. Si todas las operaciones confirmadas finales → orden status CNF
```

## Confirmacion Parcial vs Final

- **Parcial**: trabajo en progreso, operacion sigue abierta. Se pueden agregar mas confirmaciones
- **Final**: ultima confirmacion de la operacion. Marca la operacion como completada
- La orden pasa a CNF (confirmada) cuando TODAS las operaciones tienen confirmacion final

## Integracion CATS (Cross-Application Time Sheet)

- CATS permite registrar horas de trabajo en multiples ordenes PM desde una interfaz unificada
- Usado cuando personal trabaja en varias ordenes por dia
- Config: SPRO → PM → Maintenance Orders → Confirmation → CATS integration

## Queries MCP

```
-- Confirmaciones de una orden
GetSqlQuery("SELECT RUESSION,VORNR,IESSION,ESSION,ISDD,ISMNG,LESSION FROM AFRU WHERE AUFNR='{orden}'")

-- Horas totales confirmadas
GetSqlQuery("SELECT AUFNR,SUM(ISDD) as HORAS_TOTAL FROM AFRU WHERE AUFNR='{orden}' GROUP BY AUFNR")

-- Confirmaciones de un tecnico (puesto trabajo)
GetSqlQuery("SELECT AUFNR,VORNR,IESSION,ISDD FROM AFRU WHERE ARBID='{puesto}' AND IESSION >= '{desde}'")
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IW41 | Confirmacion individual |
| IW42 | Confirmacion colectiva |
| IW44 | Cancelar confirmacion |
| IW45 | Visualizar confirmacion |
| IW47 | Confirmacion con seleccion |
| IW49 | Lista confirmaciones |

## Mejores Practicas

1. **Confirmar el mismo dia** — datos frescos, tiempos precisos
2. **Siempre registrar datos tecnicos** — dano, causa y accion son la base de MTBF/MTTR
3. **Confirmacion final solo cuando se completa** — no marcar final prematuramente
4. **Usar CATS para equipos grandes** — mas eficiente que IW41 individual
5. **Verificar costes** — la confirmacion genera costes de mano de obra automaticamente
