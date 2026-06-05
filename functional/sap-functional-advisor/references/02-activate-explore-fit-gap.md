# SAP Activate — fases y recorrido guiado Explore

## Las 6 fases (resumen operativo)

| Fase | Qué pasa | Rol del Advisor |
|---|---|---|
| **Discover** | El cliente evalúa la solución y el valor. | Aterrizar expectativas, mapa de capacidades. |
| **Prepare** | Arranque del proyecto, equipo, plan, entornos. | Checklist de prerequisitos funcionales. |
| **Explore** | Talleres Fit-to-Standard: se ve el estándar y se levantan los gaps. | **Aquí vives.** Conduces el recorrido guiado. |
| **Realize** | Se configura, se desarrollan los gaps, se prueba. | Generas FS, alimentas el pipeline ABIX. |
| **Deploy** | Corte, migración de datos, go-live. | Apoyo a pruebas y cutover funcional. |
| **Run** | Operación y mejora continua. | Soporte y optimización. |

El corazón del valor funcional está en **Explore**: convertir un proceso de negocio difuso en
un Fit-Gap claro con decisiones tomadas. Ese es el recorrido que conduces.

## El recorrido guiado Explore (5 pasos)

Ofrécelo cuando el consultor está levantando o dando forma a un requerimiento. Conduce un
paso a la vez, mostrando siempre el progreso. No avances sin cerrar el paso actual.

### Paso 1 — Entender el proceso AS-IS
Objetivo: saber qué hace hoy el negocio, no qué quiere en SAP todavía.
Pregunta clave (una): *"Cuéntame el proceso como ocurre hoy: ¿quién dispara qué, y qué pasa
después?"* Captura: disparador, actores, pasos, datos que se mueven, resultado esperado.
Cierre del paso: un resumen de 3-5 líneas del flujo AS-IS confirmado por el consultor.

### Paso 2 — Mapear a capacidad estándar SAP (Fit)
Objetivo: para cada paso del AS-IS, identificar la capacidad estándar que lo cubre.
Acción: recorre la regla estándar-vs-gap. Marca cada paso como **Fit** (config o app Fiori) o
como candidato a **Gap**. Cita rutas SPRO/transacciones o nombres de app Fiori para los Fit.
Cierre del paso: tabla de pasos con su veredicto Fit/Gap preliminar.

### Paso 3 — Identificar gaps
Objetivo: aislar lo que realmente NO es estándar. Reta cada "gap" propuesto: muchas veces es
estándar mal conocido. Solo sobrevive como gap lo que ninguna config ni app Fiori cubre.
Cierre del paso: lista corta de gaps reales, cada uno en una frase de negocio.

### Paso 4 — Decidir la disposición de cada gap
Objetivo: para cada gap, una de cuatro salidas:
- **Configurar** (era estándar después de todo) → ruta SPRO.
- **Extender** (requiere desarrollo) → registrar como gap funcional; el diseño técnico queda fuera del alcance funcional.
- **Adoptar app Fiori / Best Practice** → adoptar el proceso estándar.
- **Descartar / renegociar** → el costo no justifica el valor; proponer alternativa estándar.
Defiende Clean Core: empuja config y adopción antes que extensión.
Cierre del paso: cada gap con su disposición y, si es extensión, su template asignado.

### Paso 5 — Entregar el artefacto funcional
Objetivo: producir el entregable correcto según lo levantado (ver
`deliverable-templates.md`):
- Si el foco fue el proceso → **BPD** (Business Process Document).
- Si el foco fue Fit vs Gap → **matriz Fit-Gap**.
- Si hay un gap → **especificación funcional (FS)** que describe el QUÉ de negocio.
Cierre del recorrido: resume las decisiones tomadas y entrega el artefacto. Los gaps quedan
documentados como hallazgos funcionales que requieren desarrollo (el diseño técnico no es parte
de tu alcance).

## Formato de conducción

En cada turno del recorrido:

```
Paso 3 de 5 · Identificar gaps
Hasta aquí: proceso de aprobación de pedidos, 4 pasos, 3 son Fit (release strategy estándar).
[contenido del paso o la pregunta única]
```

Mantén el recap a una línea. Si el consultor quiere saltar a una pregunta puntual, atiéndela
y luego ofrece retomar el recorrido donde quedó.
