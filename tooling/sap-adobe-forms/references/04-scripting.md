# 04 — Scripting (FormCalc y JavaScript)

**Principio:** la lógica de negocio va en ABAP (inicialización de la interfaz o programa). Los scripts son para **presentación**: numeración, totales por página, ocultar vacíos, formato condicional. ABAP no se ejecuta en el layout.

## FormCalc vs JavaScript

| | FormCalc | JavaScript |
|---|---|---|
| Para | Cálculos simples, sumas, condiciones cortas | Lógica de layout, bucles sobre nodos, funciones reutilizables |
| Rendimiento | Más rápido | Más flexible |
| Reutilización | No hay funciones propias | **Script objects** (variables → objeto de script) |
| Sintaxis | `if (…) then … else … endif` | JS estándar |

Un formulario puede mezclar ambos, pero **un mismo objeto usa un solo lenguaje**. Error típico: código en un lenguaje con el desplegable en el otro.
En el XDP: `<event activity="initialize"><script contentType="application/x-javascript">…</script></event>` (FormCalc: `contentType="application/x-formcalc"`). `calculate` y `validate` van como `<calculate><script>…</script></calculate>`.

## Eventos (impresión)

| Evento | Cuándo / para qué |
|---|---|
| `initialize` | Tras fusionar datos, por cada objeto/instancia. Asignar valores, ocultar según datos |
| `calculate` | Tras el merge, antes de mostrar; el último valor de la expresión es el valor del campo y **pisa el binding** |
| `layout:ready` (`ref="$layout"`) | Cuando el layout está calculado: **numeración de páginas**, totales por página |
| `form:ready`, `validate`, `indexChange` | Avanzados / interactivos |

Un script en un subform que se repite corre **una vez por instancia** (no hace falta bucle).

⚠️ **Los `draw` (texto/imagen/línea fijos) NO ejecutan scripts.** Un objeto que se oculta, se muestra o se calcula por script tiene que ser `field` (con `bind match="none"` si no lleva datos) o el script va en su subform contenedor. Verificado ✅: una marca de agua hecha con `draw` + script no aparece; con `field` sí.

## Recetas

**Ocultar si está vacío** (en el campo, `initialize`, JS) — compara con `null`, no con `""` suelto:
```javascript
if (this.rawValue == null || this.rawValue == "") { this.presence = "hidden"; }
```
FormCalc: `if ($.isNull) then $.presence = "hidden" endif`
`hidden` libera el espacio (lo de abajo sube); `invisible` lo conserva.

**Ocultar según un indicador del contexto:**
```javascript
if (xfa.resolveNode("$record.ES_COPIA").value != "X") { this.presence = "hidden"; }
```

**Página X de Y** (campo en la `pageArea`, `bind match="none"`) ✅:
```javascript
// layout:ready
this.rawValue = "Página " + xfa.layout.page(this) + " de " + xfa.layout.pageCount();
```

**Total general** (FormCalc, `calculate`):
```
Sum(Tabla.Fila[*].WRBTR)
```
`Sum(...)` sin `[*]` toma solo la primera fila; con `[*]` suma todas — pero en TODAS las páginas: no sirve como subtotal por página.

**Subtotal por página** (campo en la página maestra o trailer, `layout:ready`, JS):
```javascript
var pag = xfa.layout.page(this) - 1;                      // pageContent espera índice 0
var campos = xfa.layout.pageContent(pag, "field", false); // false = contenido, true = página maestra
var total = 0;
for (var i = 0; i < campos.length; i++) {
  if (campos.item(i).name == "WRBTR") { total += Number(campos.item(i).rawValue); }
}
this.rawValue = total;
```
Verifica el `-1` en tu versión de ADS; usa `Number()` para no concatenar texto.

**Arrastre (carry forward)**: subtotal de la página anterior + página actual. Patrón: campo "Viene de" en el leader con el acumulado hasta la página anterior, y "Va a" en el trailer con el acumulado hasta la actual; ocultar "Viene de" en la página 1 y en páginas sin filas.

**Copias Original / Copia**: Adobe no tiene "ventana de copias" como Smart Forms. En el programa, llamar al módulo N veces (o `COPIES` del spool) pasando un indicador/título distinto en cada vuelta; en el formulario, un campo con ese título o una marca de agua condicionada.

**Marca de agua** ("BORRADOR", "COPIA"): `draw` grande, color claro, rotado (`rotate="45"`) en la `pageArea`, con `presence` según un indicador.

**Mostrar solo en vista previa**: `xfa.config.present.destination == "pdf"` es verdadero al previsualizar; útil para distinguir preview vs impresión.

**Patrón de formato por script:** `this.format.picture.value = "num{z,zzz,zz9.99}";`

## Depuración

- `xfa.host.messageBox(xfa.event.name + ": " + this.rawValue)` (solo en interactivos/preview con Reader).
- En impresión, volcar a un campo oculto de depuración y hacerlo visible temporalmente.
- Si un script "no hace nada": revisar el lenguaje del desplegable, el evento, y la ruta del nodo (las rutas incluyen los subforms intermedios).
