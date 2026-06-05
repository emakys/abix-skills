# Plantillas de entregables funcionales

El Advisor produce uno de estos según lo que se levantó. Mantén las plantillas cortas y
accionables. Son entregables **funcionales**: describen el QUÉ de negocio, no el CÓMO técnico.

## 1. BPD — Business Process Document

```
# BPD — {nombre del proceso}
Módulo: {FI|CO|MM|SD|PP|QM|PS|PM|HCM|EWM}  ·  Fase: Explore  ·  Fecha: {fecha}

## Disparador
{qué inicia el proceso y quién}

## Flujo AS-IS
1. {paso} — actor — dato que se mueve
2. ...

## Flujo TO-BE (en SAP estándar)
1. {paso} — transacción/app Fiori — config asociada
2. ...

## Reglas de negocio
- {regla}

## Datos maestros involucrados
- {material / cliente / cuenta / centro de costo ...}
```

## 2. Matriz Fit-Gap

```
# Fit-Gap — {alcance}
Módulo(s): {...}  ·  Fecha: {fecha}

| # | Requerimiento | Veredicto | Cómo se cubre | Disposición |
|---|---------------|-----------|---------------|-------------|
| 1 | {req}         | Fit       | Config SPRO: {ruta} | Configurar |
| 2 | {req}         | Fit       | App Fiori: {nombre} | Adoptar |
| 3 | {req}         | Fit       | Best Practice: {proceso} | Adoptar |
| 4 | {req}         | Gap       | — | Requiere desarrollo |
| 5 | {req}         | Gap       | — | Descartar (alternativa estándar: {...}) |

Resumen: {N} Fit, {M} Gaps. Gaps que requieren desarrollo: {lista}.
```

## 3. FS — Especificación Funcional (para un gap)

```
# FS funcional — {nombre del gap}
Módulo(s): {...}  ·  Fecha: {fecha}

## Necesidad de negocio
{una frase: qué problema resuelve y para quién}

## Por qué es un gap (no estándar)
{qué config/app Fiori/Best Practice se evaluó y por qué no aplica}

## Comportamiento funcional esperado
{descripción funcional precisa: entradas, reglas, salidas, criterios de aceptación}

## Datos involucrados
- Maestros y transaccionales relevantes
- Origen y destino de la información (en términos de negocio)

## Impacto cross-módulo
{qué otros módulos se ven afectados; ver matriz de integración}

## Autorizaciones y supuestos
- {quién debe poder ejecutar/ver}
- Supuestos: {...}
```

Regla de oro: el FS funcional debe dejar el QUÉ tan claro que cualquier equipo técnico pueda
diseñar el CÓMO sin reinterpretar la necesidad de negocio. Marca lo no resuelto como
`[PENDIENTE]` para retomarlo.
