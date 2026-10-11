# 01 — Arquitectura y tecnologías de formularios PDF en SAP

## Componentes

```
Programa / salida (NAST, BRF+, OData, job)
   │  datos ABAP
   ▼
Módulo generado /1BCDWB/SM…  ← SFPF (contexto + layout) ← SFPI (interfaz)
   │  XML de datos (contexto aplanado) + plantilla XDP
   ▼
ADS — Adobe Document Services (AS Java on-premise, o Forms Service by Adobe en BTP)
   │  render
   ▼
PDF · PDL (PCL / PostScript / ZPL) · spool · correo · archivo
```

- **SFPI (interfaz):** contrato de datos. Parámetros (import/export/tables/excepciones), datos globales, tipos locales, field-symbols, **código de inicialización** (ABAP que corre antes del render, con entradas y salidas declaradas) y **referencias de moneda/cantidad**.
- **SFPF (formulario):** contexto + layout. El contexto decide qué viaja a ADS; lo que no está en el contexto no existe para el layout.
- **Módulo generado:** se regenera al activar. Siempre resolver el nombre con `FP_FUNCTION_MODULE_NAME`; **nunca** hardcodear `/1BCDWB/SM00001234` (cambia entre sistemas).
- **ADS:** renderiza. Lo usan también la carga en SFP (`set_new_layout_id` → `copy_template`), la activación de layouts XFA y la vista previa. ✅

## Tipos de interfaz (SFPI)

| Tipo | Cuándo |
|---|---|
| **Basada en diccionario ABAP** (la normal) | Formularios Z/estándar on-premise. Lo que genera `/adobeform` |
| Basada en esquema XML | Datos que ya vienen como XML (integraciones) |
| Compatible con Smart Forms | Resultado de migrar un Smart Form |

## Formularios basados en fragmentos (S/4HANA output management)

- La fuente de datos es un **modelo Gateway (OData)** — el *form data provider* — en lugar de una interfaz ABAP. SAP los llama "cloud-ready".
- **Formulario maestro** (`SOMU_FORM_MASTER_A4`, `SOMU_FORM_MASTER_LETTER`, interfaz `SOMU_DEFAULT_INTERFACE`) con contenido estático (logo, remitente, pie, datos bancarios) en **fragmentos** con nombres fijos definidos por SAP (p. ej. `Portrait_OutboundLetter`). Si no se respetan los nombres, la composición falla.
- **Plantilla de contenido**: el documento en sí, que referencia un fragmento del maestro.
- Metadatos en la app Fiori **Maintain Form Templates**; layout en LiveCycle Designer (≥ 10.4).
- Los fragmentos **no** se soportan en formularios basados en diccionario (SFP clásico).
- Detalle de configuración: `06-gestion-salidas-s4.md`.

## Modelo ABAP Cloud

- Datos: vistas CDS + **service definition** → `cl_fp_fdp_services=>get_instance( iv_service_definition, iv_root_node )` → `get_xsd( )` y `read_to_xml( keys )`.
- Render: `cl_fp_ads_util=>render_pdf( iv_xml_data, iv_xdp_layout, iv_locale )` → `ev_pdf`, `ev_pages`. También `render_4_pq` para PDL de cola de impresión.
- La plantilla XDP vive en el **template store** de Forms Service by Adobe (BTP), gestionada por REST.
- On-premise S/4HANA 2023 también tiene `CL_FP_ADS_UTIL` y `CL_FP_FDP_SERVICES` ✅ — útil para renderizar un XDP sin SFPF (ABIX lo usa para la pre-validación).

## Migración desde Smart Forms

- SMARTFORMS → Utilidades → Migración → Interactive Form → Exportar. Genera SFPI + SFPF **inactivos**.
- **No migra:** hojas de portada, líneas de programa ligadas a eventos de página (página 1, salto), formatos XSF/XDF/HTML, condiciones dentro de plantillas que afectan celdas, caracteres SAP (`<123>`), formato de texto fuera del subset XHTML de Adobe, direcciones formateadas, bordes/sombreado ajustados a la altura de fila.
- Tablas antiguas (4.6C) migran solo como bucles. Con "Tablas y bucles" puede dar TIME-OUT (nota 2376051). Diferencias funcionales: nota 1009567.
- **No hay migración desde SAPscript.**
- En la práctica el resultado es un borrador: la lógica de página y las tablas complejas se rehacen. Suele convenir rediseñar con la plantilla base.

## Formularios de impresión vs interactivos

| | Impresión | Interactivo |
|---|---|---|
| Uso | Documentos de salida (factura, constancia, etiqueta) | El usuario rellena (online con Web Dynpro / offline por correo) |
| Licencia | Incluida para impresión | Interactivos y algunos códigos de barras 2D dinámicos requieren licencia/usage rights |
| Layout | Estático o dinámico | Requiere ZCI para Web Dynpro |
| Ver | este directorio | `09-formularios-interactivos.md` |
