# 06 — Gestión de salidas en S/4HANA

## Dos mundos

| | NAST / NACE (clásico) | Output control S/4HANA (BRF+) |
|---|---|---|
| Determinación | Técnica de condiciones (NACE, tipos de mensaje) | Reglas BRF+ en **OPD** (Output Parameter Determination) |
| Formularios | SAPscript, Smart Forms, Adobe | Solo **Adobe** (con fragmentos y formulario maestro) |
| Programa | Programa de impresión con `ENTRY` (RSNAST00) | Lo provee el framework; los datos vienen del **form data provider** |
| Mantenimiento | SPRO/NACE | SPRO + apps Fiori (Maintain Form Templates, OPD) |

Muchos procesos de S/4HANA on-premise siguen pudiendo usar NAST (según aplicación y configuración). Antes de diseñar, confirma qué framework usa el documento en el sistema del cliente.

## Output control BRF+ — configuración (SPRO → Componentes multiaplicación → Output Control)

1. Ajustes del repositorio de almacenamiento (KPRO para guardar los PDF).
2. Activación del tipo de objeto de aplicación.
3. Definir tipos de salida.
4. Asignar canales (impresión, correo, XML, IDoc).
5. **Reglas para determinar el formulario maestro** (por sociedad, organización de ventas, país remitente, canal…). Un parámetro vacío coincide con todo.
6. **Asignar plantillas de formulario** al tipo de salida.
7. Asignar plantillas de correo.
8. **Reglas de negocio de determinación de parámetros (OPD)**: tipo de salida, receptor, impresora, plantilla de formulario, relevancia. El paso "plantilla de formulario" devuelve UNA plantilla (nombre + idioma).

Prerrequisitos técnicos: bgRFC (nota 2292571), ADS operativo, KPRO. Cada solicitud de salida deja log en **SLG1**.

## Formularios maestros y fragmentos

- **Formulario maestro** (`SOMU_FORM_MASTER_A4`, `SOMU_FORM_MASTER_LETTER` ✅ existen en S/4 2023; interfaz `SOMU_DEFAULT_INTERFACE` ✅): contenido estático común (logo, remitente, pie, datos bancarios) en **fragmentos** = variantes de layout con nombres definidos por SAP.
- **Plantilla de contenido**: el documento; referencia un fragmento del maestro.
- Logos y textos del maestro se asignan por ID (SE78/SO10) en la configuración de reglas del maestro.
- Maestro propio on-premise: descargar `SOMU_FORM_MASTER_A4` en SFP, editarlo en LiveCycle, crear `Z…` con interfaz `SOMU_DEFAULT_INTERFACE` y subir el XDP. Mantener los nombres de fragmento.
- Traducción de formularios con fragmentos: ver blog SAP "Language translations for Adobe forms with fragments".

## Form data provider (plantillas basadas en Gateway)

- La interfaz de datos es un **servicio OData** (form data provider); un callback lo llama, recibe los datos como XML y los pasa al layout.
- SAP entrega los proveedores: lo habitual es **copiar la plantilla estándar** y, si hace falta, ampliar el servicio estándar (nota 2292646) en lugar de crear uno nuevo.
- Al subir una plantilla modificada, mantener la **misma fuente de datos**; en Cloud solo se pueden usar fuentes de datos entregadas por SAP.
- Descargar una plantilla desde Maintain Form Templates da un zip con XSD (fuente de datos) + plantilla maestra + plantilla de contenido.

## Cuándo NO usar `/adobeform` (SFP clásico)

- Documento estándar gestionado por output control BRF+ → copiar y adaptar la **plantilla estándar con fragmentos** (layout en LiveCycle), no crear un SFP basado en interfaz ABAP.
- S/4HANA Cloud Public Edition → solo plantillas con fuente de datos SAP; sin SFP.

`/adobeform` encaja en: formularios Z llamados por programa propio (constancias, certificados, reportes, etiquetas), o como interfaz/contexto de un formulario NAST.
