# Biblioteca de bloques XFA (autoría ABIX)

Fragmentos listos para copiar al `.sfpf.xdp`. **Todos se verificaron juntos con ADS** (S/4HANA 2023, oct-2026): un XDP con los 10 bloques, 60 filas de datos, 3 páginas.

| Bloque | Dónde va | Datos que espera | Verificado |
|---|---|---|---|
| `01-pagina-maestra-encabezado-pie.xml` | dentro de `<pageSet>` | — (logo en base64 en el `image`) | ✅ |
| `02-recuadro-cabecera-qr-imagen.xml` | cuerpo | `TITULO`, `DOCUMENTO`, `FOTO_B64` | ✅ |
| `03-tabla-multipagina.xml` | cuerpo | `POSICIONES/DATA/{POSNR,DESCRIPCION,IMPORTE}` | ✅ encabezado repetido + filas que crecen |
| `04-rectangulo-total.xml` | cuerpo | `TOTAL` | ✅ |
| `05-bloque-condicionado.xml` | cuerpo | nodo `NOTA/AVISO` (carpeta con condición) | ✅ |
| `06-formatos-fecha-numero.xml` | cuerpo | `FECHA` (YYYY-MM-DD), `MONTO` | ✅ `10/10/2026`, `1.234.567,89` (locale es_ES) |
| `07-marca-de-agua.xml` | `pageArea`, primero | `ES_COPIA` = X | ✅ (es `field`: los `draw` no ejecutan scripts) |
| `08-subtotal-por-pagina.xml` | `pageArea`, sobre el pie | campos `IMPORTE` numéricos en la página | ✅ suma por página = total; oculto en páginas sin filas |
| `09-total-general-formcalc.xml` | cuerpo, tras la tabla | — (suma lo impreso) | ✅ |
| `10-primera-pagina-distinta.xml` | reemplaza `<pageSet>` | — | ✅ primera / siguientes |

## Cómo combinarlos

1. Partir de `../base-documento.sfpf.xdp` (esqueleto completo con `dataDescription` y `connectionSet`).
2. Reemplazar o agregar bloques; **renombrar** los objetos si un bloque se usa más de una vez.
3. Ajustar los `ref` a los nombres del contexto de tu `.sfpf.json` y actualizar `dataDescription`.
4. Pre-validar (`/adobeform prevalidar`) y después probar el runtime real.

## Paleta usada (cámbiala por la del cliente)

Azul `43,124,214` · dorado `217,150,30` · gris filas `242,242,242` · texto suave `120,120,120` · fondo crema `253,246,233`.
