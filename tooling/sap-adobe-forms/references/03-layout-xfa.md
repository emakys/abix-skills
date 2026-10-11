# 03 — Layout XFA (`{form}.sfpf.xdp`)

## Esqueleto mínimo ✅

```xml
<?xml version="1.0" encoding="utf-8"?>
<xdp:xdp xmlns:xdp="http://ns.adobe.com/xdp/">
 <template xmlns="http://www.xfa.org/schema/xfa-template/2.8/">
  <subform name="data" layout="tb" locale="es_ES" restoreState="auto">   <!-- raíz = raíz de datos de SFP -->
   <pageSet>
    <pageArea name="Pagina" id="Pagina">
     <contentArea x="10mm" y="28mm" w="190mm" h="250mm"/>               <!-- zona donde fluye el cuerpo -->
     <medium stock="a4" short="210mm" long="297mm"/>                     <!-- landscape: orientation="landscape" -->
     <!-- encabezado y pie: draws/fields posicionados FUERA del contentArea; se repiten en cada hoja -->
    </pageArea>
   </pageSet>
   <!-- cuerpo: subforms que fluyen -->
  </subform>
 </template>
 <config xmlns="http://www.xfa.org/schema/xci/2.8/"><present><pdf><version>1.7</version></pdf></present></config>
 <xfa:datasets xmlns:xfa="http://www.xfa.org/schema/xfa-data/1.0/"><xfa:data xfa:dataNode="dataGroup"/>
  <dd:dataDescription xmlns:dd="http://ns.adobe.com/data-description/" dd:name="data"><data>…árbol del contexto…</data></dd:dataDescription>
 </xfa:datasets>
 <connectionSet xmlns="http://www.xfa.org/schema/xfa-connection-set/2.8/">
  <xsdConnection dataDescription="data" name="FORM"><uri/><rootElement>data</rootElement></xsdConnection>
 </connectionSet>
</xdp:xdp>
```

`dataDescription` describe el árbol de datos (bucles con `dd:minOccur="0"`, filas `DATA dd:maxOccur="-1"`). Es lo que LiveCycle muestra en la vista "Datos".

## Data binding ✅

| Caso | Binding |
|---|---|
| Campo raíz | `<bind match="dataRef" ref="$.TITULO"/>` |
| Componente de estructura | `ref="$.CABECERA.NUMERO"` |
| Tabla (bucle) | subform tabla `ref="$.PAGOS"`, fila `ref="DATA[*]"` + `<occur min="0" max="-1"/>`, celdas `ref="$.WRBTR"` |
| Global de la interfaz | igual que un campo (`$.TOTALES`) |
| Sin datos (texto calculado por script) | `<bind match="none"/>` |
| Desde script | `xfa.resolveNode("$record.CABECERA.NUMERO").value` |

Binding implícito (`match="once"`, sin `<bind>`): enlaza por nombre igual. Explícito es más seguro.

## Tipos de subform (`layout`)

| `layout` | Comportamiento |
|---|---|
| `position` | Hijos con `x`/`y` absolutos. Para cajas de cabecera, leaders/trailers, bloques fijos |
| `tb` | Flujo vertical (top-bottom). Para el cuerpo y todo lo que crece |
| `lr-tb` | Flujo horizontal con salto de línea |
| `table` + filas `row` | Tablas: `columnWidths="20mm 80mm 40mm"`; cada fila `layout="row"` con una celda por columna |

Solo los subforms **que fluyen** pueden partirse entre páginas. Un `position` es atómico.

## Paginación

- **Páginas maestras**: varias `pageArea` en el `pageSet`. Control con `<occur min max>` en la `pageArea` (p. ej. primera página distinta: `pageArea` "Primera" `max="1"` + "Siguientes").
- **Pares/impares y dúplex**: `pageSet relation="duplexPaginated"` y `pagePosition`/`oddOrEven` en las `pageArea`. Ver `08-impresion-y-dispositivos.md`.
- **Salto antes/después**: `<breakBefore targetType="pageArea" target="#Pagina"/>` / `<breakAfter targetType="contentArea"/>` dentro del subform (XFA 2.8; evitar el `<break>` antiguo).
- **Salto condicional** (LiveCycle → Objeto → Paginación → Saltos condicionales): en la fila que se repite, FormCalc `$.BELNR ne $.[-1].BELNR` → salto antes a la página siguiente. Ruta de nodo completa. Un `breakAfter` incondicional al final deja una hoja en blanco.
- **No partir un bloque**: `<keep intact="contentArea"/>` (o `pageArea`).
- **Mantener con el siguiente**: `<keep next="contentArea"/>`.

### Tabla que pasa de página con encabezado repetido ✅
```xml
<subform name="Tab" layout="table" columnWidths="28mm 24mm 34mm 38mm" w="124mm">
  <bind match="dataRef" ref="$.PAGOS"/>
  <subform name="Tab_Enc" layout="row">…un draw por columna…</subform>
  <subform name="Tab_Fila" layout="row">
    <occur min="0" max="-1"/><bind match="dataRef" ref="DATA[*]"/>
    …un field por columna…
    <keep intact="contentArea"/><overflow leader="Tab_Enc"/>
  </subform>
</subform>
```
- **Overflow leader** = lo que se repite arriba al continuar; **overflow trailer** = lo que se pone al pie antes de cortar (subtotal / "continúa…"). Leader y trailer: **contenido posicionado y sin binding**, si no se superponen campos o se duplican encabezados.

## Patrones (picture clauses)

| Patrón | Uso |
|---|---|
| `num{z,zzz,zz9.99}` | Separador de miles, 2 decimales |
| `num{z,zzz,zz9.99998888}` | 4 a 8 decimales (`9` fijo, `8` opcional no-cero). Máx. 15 dígitos |
| `num{($zzzz9.99)}` · `num{z,zzz,zz9%}` | Moneda entre paréntesis · porcentaje |
| `date{DD/MM/YYYY}` · `date{DD. MMM YYYY}` · `date{EEEE, D 'de' MMMM 'de' YYYY}` | Fechas (`MMM`/`MMMM`/`EEE`/`EEEE` según locale) |
| `date.short{}` · `date.medium{}` · `date.long{}` | Estilo del locale (cuidado: cambia con el locale del visor en interactivos) |
| Patrón de **datos** `date{YYYY-MM-DD}` | SAP envía fechas `YYYY-MM-DD`; si el patrón de datos no coincide, el campo sale vacío |

Display vs edit vs validation vs data se configuran por separado. Un patrón mal escrito produce un usage error opaco en runtime.
En XDP: `<format><picture>num{z,zzz,zz9.99}</picture></format>` dentro del `field`; patrón de datos en `<bind><picture>…</picture></bind>`.
Por script: `this.format.picture.value = "date{DD/MM/YYYY}";`.
**Recomendación**: si el formato depende del usuario/país, formatea en ABAP (`WRITE … CURRENCY`, `WRITE … DD/MM/YYYY`) y entrega texto.

## Objetos

| Necesito | XFA |
|---|---|
| Texto fijo | `<draw><ui><textEdit/></ui><value><text>…</text></value></draw>` (rich text: `<exData contentType="text/html">`) |
| Campo de datos | `<field access="readOnly"><ui><textEdit/></ui><bind …/></field>` (`numericEdit`, `dateTimeEdit`, `checkButton`) |
| Texto que crece | `multiLine="1"` + `minH`/`maxH` (o `h` ausente en flujo) |
| Línea | `<draw><value><line><edge thickness="0.5mm"><color value="r,g,b"/></edge></line></value></draw>` |
| Rectángulo | `<draw><value><rectangle><edge/><corner radius="2mm"/><fill><color/></fill></rectangle></value></draw>` |
| Borde/fondo de un objeto | `<border><edge …/><corner radius="3mm"/><fill><color value="…"/></fill></border>`; `presence="hidden"` en `edge` para solo fondo |
| Imagen fija | `<draw><value><image contentType="image/png" aspect="fit">BASE64</image></value></draw>` (o `href` a MIME) |
| Imagen dinámica | `<field><ui><imageEdit/></ui><value><image aspect="fit" contentType="image/png"/></value><bind ref="$.LOGO_B64"/></field>` |
| Código de barras/QR | `<field><ui><barcode type="QRCode" moduleWidth="0.8mm" errorCorrectionLevel="1"/></ui><bind …/></field>` |
| Casilla | `<field><ui><checkButton/></ui><items><text>X</text><text/></items></field>` |
| Ocultar | `presence="hidden"` (no ocupa lugar) / `invisible` (ocupa lugar) |

Colores: `value="r,g,b"`. Fuentes: `<font typeface="Arial" size="10pt" weight="bold"><fill><color value="…"/></fill></font>`; alineación `<para hAlign="left|center|right|justify" vAlign="top|middle|bottom"/>`; márgenes internos `<margin topInset=… leftInset=…/>`.

## Códigos de barras

- Soportados: los que lista la **Biblioteca → Barcodes** de LiveCycle Designer (Code 128, Code 39, EAN/UPC, Interleaved 2of5, QR, Data Matrix, PDF417, …). Lo que no está en la biblioteca no se soporta (no hay símbolos propios). ✅ QR verificado.
- **Software** (los dibuja ADS, sirven en cualquier impresora) vs **hardware** (los genera la impresora; solo con impresión directa a dispositivo, en el PDF salen como marcador).
- **GS1-128** no seleccionable; **GS1 DataMatrix** requiere la nota 2289736 (FNC1). Tamaño mínimo de DataMatrix limitado (~0,83 in): si hace falta más chico, generar imagen externa.
- Códigos 2D **dinámicos en interactivos** (Paper Forms Barcode) requieren licencia; los estáticos de impresión no.
- Para impresoras de etiquetas (ZPL) a < 300 dpi los códigos pueden no leerse.

## Fuentes

- ADS solo usa fuentes instaladas en su gestor de fuentes; una fuente nueva hay que instalarla en ADS.
- Embeber fuentes solo si hace falta (`FNTEMB` en el formulario): aumenta el tamaño.
- Para idiomas no latinos (chino, árabe), elegir fuentes que los cubran; RTL requiere además espejar el layout (`07`).
