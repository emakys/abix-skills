# 09 · El comando `/brf` de ABIX

Cómo trabaja ABIX con BRF+ y qué esperar de cada subcomando. Todo ✅ verificado en S/4HANA 2023 (oct-2026).

## Subcomandos

| Comando | Escribe en SAP | Sistema |
|---|---|---|
| `/brf leer <app\|función>` / `/brf leer Z*` | No (solo SQL) | Cualquiera, incluido productivo |
| `/brf diagnosticar <OBJETO> <documento>` | No | Cualquiera |
| `/brf comparar <app>` | No | Cualquiera |
| `/brf excel exportar\|importar` | No | — |
| `/brf crear <regla>` / `/brf modificar <app> <cambio>` | No (escribe la definición en el workspace) | — |
| **Simular ▶** / `/brf simular [app]` | No en BRF+ (una clase auxiliar en `$TMP`) | Donde se pueda ejecutar una clase |
| **Desplegar ▶** / `/brf desplegar [app]` | **Sí** | Modificable, no productivo |

## La definición `{app}.brf.json`

Por **nombres** (los GUID los resuelve ABIX). `objetosDatos` (texto/numero/booleano, `ddic`, `ddicEstructura`), `tablasDecision` (condiciones en notación corta: `= X`, `<> X`, `> n`, `<= n`, `entre a y b`, `en [a, b]`, `vacío`, `no vacío`, `CP Z*`; fila final comodín), `expresiones` (`constante`, `formula` con NOMBRES de objetos, `case`), `funciones` (funcional con `expresion`, o evento con `setsReglas` → reglas con UNA condición y acciones `asignarExpresion`/`asignarValor`/`asignarObjeto`), `casosPrueba` (contexto con valores o filas reales `{ "fuente": TABLA, "clave": {…} }` + `esperado`). `/brf leer` produce el mismo formato (ida y vuelta), con `_origen.sistema` = `SID/mandante`.

## Simular sin grabar

ABIX no genera ABAP por aplicación: una **clase intérprete genérica** recibe la definición como líneas de datos, construye todo en la aplicación temporal `GC_APPLICATION_TMP`, activa SIN `save` y corre los casos. En BRF+ no queda nada (verificado contando `FDT_ADMN_0000` antes y después). Detalles que resuelve solo: enciende reglas y sets (nacen apagados), activa función y sets por separado, copia filas DDIC solo por componentes elementales (`ELEMENT_TIMEPOINT`), compara resultados numéricos por valor (`119.00` = `119`).

## Desplegar

- **App nueva** → por API: crea la aplicación (`$TMP` = local; si no, customizing/sistema en el paquete del workspace), construye, activa, `save` con la orden y corre los casos sobre lo grabado.
- **App existente** → **ida y vuelta XML**: export (respaldo `{app}.brf.before.xml` en el workspace) → regenera en el XML las tablas de decisión cambiadas (`TABLE_DATA`, vacía `PACKED`, ajusta `ROW_COUNT`) → `import_xml` **simulado** → si limpio, real con la orden → casos. v1: sobre apps existentes solo cambios de **filas**; cambios de estructura se rechazan con la lista de diferencias.
- Gates: nunca apps de sistema entregadas por SAP; apps nuevas con nombre Z/Y; tipo de orden en `E070` (customizing → `W`, sistema → `K`, no liberada).

## Trampas encontradas al construirlo

- `save( iv_transport_request = '' )` falla con *"The transport request is initial"*: pasa la orden solo si existe (`save( )` sin parámetro en apps locales).
- Re-subir una clase auxiliar con fuente **idéntica** a la activa: el tool `UpdateClass` del MCP lo reporta como *"Activation … failed: activationExecuted=false"* (SAP no tiene nada que activar). Solución: un comentario con la hora DENTRO de la definición (tras `ENDCLASS` lo descarta ADT al partir la clase en secciones).
- La salida de una clase classrun con un export grande supera fácilmente 200 KB: no truncarla.
- El orden de las filas cambia el resultado: al agregar una fila, ponla ANTES de las más generales que la cubrirían (la simulación lo detecta: caso que espera la fila nueva y obtiene la anterior).

## Comparar sistemas

ABIX se conecta a un sistema a la vez: la foto de `/brf leer` (con `SID/mandante`, SID desde `TADIR` `PGMID='HEAD'` `OBJECT='SYST'` → `SRCSYSTEM`) se compara contra el sistema conectado: objetos, funciones, sets/reglas (encendido, condición, acciones, posición) y tablas fila por fila **y en orden** (las mismas filas en otro orden pueden decidir distinto). Ejemplo real: la misma OPD de movimientos con impresora `LP01` en DEV y `ZPDF` en QAS.

## Excel

Una hoja por tabla de decisión (columnas fijas, `→ RESULTADO`, filas en notación corta) + hoja LEEME. Importar reemplaza las filas en la definición (comparación canónica: `EQ CO` = `= CO`) y avisa filas debajo del comodín; nunca escribe en SAP — después, Simular ▶ y Desplegar ▶ (a diferencia del Excel del workbench, que reemplaza la tabla en SAP sin probarla).
