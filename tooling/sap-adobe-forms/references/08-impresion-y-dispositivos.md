# 08 — Impresión y dispositivos

## Cómo imprime ADS

ADS convierte el formulario al lenguaje de la impresora (**PDL**: PCL, PostScript, ZPL) usando un **XDC** (descripción XML de la impresora). Cada tipo de dispositivo de SAP que imprima formularios Adobe debe estar asignado a un XDC (tabla `TSP0B`, mantenida con el report **`RSPO0022`** ✅; nota 721005).

## Tipos de dispositivo estándar con XDC (nota 685571)

| Tipo | PDL | Uso |
|---|---|---|
| `POST2` | PostScript | Genérico para cualquier impresora PostScript |
| `HPLJ4` | PCL b/n | Láser HP / compatibles PCL |
| `HP9500` | PCL color | |
| `PDF1` | PDF | Con SAPPDFPRINT en servidor Windows (sin XDC) |
| `AZPL203` / `AZPL300` | ZPL | Etiquetas Zebra a 203 / 300 dpi (`zpl203.xdc` / `zpl300.xdc`) |

Tipo no apto → mensaje **SPADS011** ("tipo de dispositivo no apto para documentos ADS").

## Impresoras Windows / sin PDL

- Los tipos SAPWIN no sirven para Adobe. Usar **SAPPDFPRINT 7.20** + SAPSprint en el servidor Windows, dispositivo `PDF1` con método de acceso `S` (nota 1444342).
- Si la impresora entiende PostScript, `POST2` evita SAPPDFPRINT.

## Etiquetas Zebra (ZPL)

- Diseñar el formulario con el tamaño de la etiqueta (`medium` con `short`/`long` de la etiqueta) y dispositivo `AZPL203`/`AZPL300` según dpi. ADS genera ZPL.
- La impresora debe soportar **ZPL II**. A < 300 dpi los códigos de barras pueden no leerse.
- Un mismo tipo para ZPL nativo y PDF de ADS: asignar el tipo de la impresora (p. ej. `ZLB_ZEB`) al `zpl203.xdc` en RSPO0022.
- No hay "nodos de comando" como en Smart Forms: los comandos de impresora salen del XDC (se puede derivar un XDC propio del estándar de Adobe).
- Códigos de barras **hardware** (los dibuja la impresora) solo en impresión directa a dispositivo; en vista previa se ven como marcador.

## Dúplex

- En el formulario: página maestra → Paginación → *Imprimir en ambas caras*; propiedades del formulario → opciones de impresión PDF.
- Si la impresora igual imprime simple: usar **perfil de trabajo de ADS** (`JOB_PROFILE` = `PDFDuplexLongEdge.xml` / `PDFDuplexShortEdge.xml`, nota 1743567; KBA 1565113).
- Probar la impresora con `FP_TEST_03` / formulario `FP_TEST_03_TABLE_DUPLEX` ✅.
- Mezclar dúplex y simple: dos conjuntos de páginas maestras, o páginas de relleno para la cara trasera. Páginas pares/impares: Paginación → *Impares (frente)* / *Pares*.

## Atributos de spool útiles (`SFPOUTPUTPARAMS`)

`DEST`, `REQNEW`, `REQIMM`, `REQDEL`, `REQFINAL`, `COPIES`, `DATASET`, `SUFFIX1/2`, `TITLE`, `COVTITLE`, `RECEIVER`, `DIVISION`, `LIFETIME`, `AUTHORITY`, `PRINTTICKET`. Ver `05`.

## Volumen alto

- No pensado para cientos de miles de documentos por corrida sin diseño: agrupar (`BUMODE`), paralelizar (`PARALLEL`), ADS dedicado y balanceado (notas 1522165, 1462986). Ver `10`.
