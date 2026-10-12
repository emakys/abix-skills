# 07 · BRF+ dentro de S/4HANA

Las aplicaciones estándar se entregan con almacenamiento **sistema** (`FDT_ADMN_0000S`); cuáles hay depende de la versión y de los componentes instalados. Para ver las del sistema actual: `SELECT name FROM fdt_admn_0000s WHERE object_type = 'AP' AND deleted = ' '`. Las apps **del cliente** (Z/Y, OPD importadas) están casi siempre en `FDT_ADMN_0000` (mandante).

## Output management (OPD) — el caso más común ✅

Reemplaza a la técnica de condiciones (NAST) para la mayoría de documentos en S/4HANA: facturación SD (desde 1511), pedido de ventas, **pedido de compras (obligatorio desde 1511)**, contratos y planes de entrega, movimientos de mercancías, liquidación de contratos de condiciones, etc. Customizing: *Componentes multiaplicación → Control de salida → Definir reglas de negocio para determinación de salida* — transacción **`OPD`** ✅.

### Estructura real

- **Registro objeto → reglas**: `APOC_I_BRF` (entregado por SAP; ~67 objetos de aplicación en S/4 2023, p. ej. `BILLING_DOCUMENT`, `PURCHASE_ORDER`, `SALES_DOCUMENT`, `GOODS_MOVEMENT`, `MAINTENANCE_ORDER`, `PHYSICAL_INVENTORY`, `SUPPLIER_SETTLEMENT`, …) con el ID de la aplicación BRF+ y de sus **8 funciones**. `APOC_C_BRF` = override del cliente (suele estar vacía) ✅.
- Cada objeto tiene una aplicación (p. ej. `OPD_MM_GOODS_MOVEMENT`) creada al importar el XML que SAP entrega, normalmente en el **mandante** (`FDT_ADMN_0000`) ✅.
- Las 8 funciones (modo evento, cada una con su set `RS_*` → regla `RU_PROCESS_DT_*` → tabla `DT_*`) ✅:

| Función | Tabla | Decide |
|---|---|---|
| `FU_OUTPUT_TYPE` | `DT_OUTPUT_TYPE` | Qué tipos de salida (y momento de envío) |
| `FU_OUTPUT_RELEVANCE` | `DT_OUTPUT_RELEVANCE` | Si el tipo es relevante |
| `FU_RECEIVER` | `DT_RECEIVER` | Roles receptores |
| `FU_CHANNEL` | `DT_CHANNEL` | Canal por rol (PRINT / EMAIL / EDI / XML) |
| `FU_PRINTER` | `DT_PRINTER` | Cola de impresión y copias |
| `FU_EMAIL_SETTINGS` | `DT_EMAIL_SETTINGS` | Plantilla de correo y remitente |
| `FU_EMAIL_RECEIVER` | `DT_EMAIL_RECEIVER` | Destinatarios de correo |
| `FU_FORM_TEMPLATE` | `DT_FORM_TEMPLATE` | **Formulario** (Adobe/fragmentos) por canal, país, idioma, versión |

- Contexto: objetos de datos con los campos del documento (para movimientos de mercancías: `INVENTORYTRANSACTIONTYPE`, `OPERATIONISPRINTED`, `PRINTINGOFDOCUMENTITEM`, `VERSIONFORPRINTINGSLIP`, `QUANTITYDEBITCREDITCODE`, …), llenados desde una **vista CDS de parámetros** del objeto (movimientos: `V_MMIM_DDL_OM_PARAM`) ✅. Para otro objeto, busca el campo en `DD03ND` (`fieldname = '<NOMBRE_DEL_OBJETO_DE_DATOS>'`) para hallar su vista.
- Resultado real: **`APOC_D_OR_ROOT`** (solicitud de salida por documento, `APPL_OBJECT_TYPE`/`APPL_OBJECT_ID`) y **`APOC_D_OR_ITEM`** (tipo de salida, canal, formulario, cola, copias, estado) ✅.
- App estándar de prueba: `SAP_OPD_APOC_TO` (objeto `APOC_SD_TEST_OBJECT`) ✅.

### Diagnóstico "¿por qué salió / no salió?" (solo lectura, cualquier sistema) ✅

1. `APOC_D_OR_ITEM` del documento: qué decidió SAP.
2. Contexto real: vista de parámetros del objeto filtrada por el documento.
3. Tablas `DT_*` reconstruidas por SQL (`05`).
4. Evaluar fila por fila según la propiedad de la tabla (`FDT_EXPR_0240`): **primera coincidencia** en la mayoría, pero `DT_OUTPUT_TYPE`, `DT_RECEIVER`, `DT_CHANNEL` y `DT_EMAIL_RECEIVER` son ***multiple match*** → cuentan **todas** las filas que coinciden (por eso un documento puede generar varias salidas o varios receptores). En una tabla de primera coincidencia sin fila que coincida → BRF+ lanza "No match found for the given context (DT_…)" y no hay salida de ese tipo (ninguna tabla OPD revisada tiene `ALLOW_NO_MATCH`).

Verificado en un QAS real: la predicción coincidió 100 % con lo registrado (entrada de mercancías y salida a subcontratista, incluida una posición sin salida porque no marcaba impresión).

## Otros usos confirmados

| Área | Dónde | Notas |
|---|---|---|
| **MDG** | Validaciones y derivaciones — app web `USMD_RULE` ✅, `MDGIMG` ✅ → *Calidad de datos → Definir reglas de validación y derivación* | Funciones por modelo (p. ej. check/derive por entidad); alternativa BAdI `USMD_RULE_SERVICE`; DQM como evolución |
| **Gestión de crédito (FSCM)** | App de sistema `UKM_RULES` ✅ | Reglas de scoring/límite |
| **Revenue accounting (RAR)** | Plantillas `FARR_AP_PROCESS_TEMPLATE`, `FARR_AP_SD_PROCESS_TEMPLATE`, `FARR_AP_CA_PROCESS_TEMPLATE`, `FARR_AP_CRM_…`, `FARR_POB_STATUS_TEMPLATE` ✅ | Se copian a una app del cliente para el procesamiento de entrada |
| **Reportes legales (ACR / SRF)** | Decenas de apps por país: IVA, SAF-T, flujos de caja, retenciones (`*_VAT_DCL`, `SAF_T_*`, `SRF_*`, `FIWT*`…) ✅ | Formato y lógica de declaraciones |
| **EWM** | Labor Management (`/SCWM/LM_LA_SYS`, `/SCWM/LM_ELS_SYS`, `/SCWM/LM_PFD_SYS`) y tiempos de transporte (`/SCWM/TDC_SYS`) ✅ | No en ubicación/extracción/olas (ver skill `sap-ewm-warehouse`) |
| **TM** | Condiciones de TM (origen "tabla de decisión BRF+") | Determinación de transportista, etc. |
| **GRC Access Control** | Selección de set de reglas de riesgo; agentes en workflow MSMP | |
| **FI-CA / PSCD** | Casos BPEM (tipo de expresión `BPEM_CASE`) ✅ | Muy usado en sector público/impuestos (Tax and Revenue Management) con apps del cliente |
| **QM, IS-U, CRM S/4, seguros (ICL)** | `QM_CATALOG_PROFILE_TEMPLATE`, `INSPPLANFIELDCTRL`, `ISU_MKT_FINANCIAL_HEALTH_SCORE`, `CRMS4_SOM_*`, expresiones `ICL_*` ✅ | |

## Patrón para el cliente

Casi siempre SAP entrega una **plantilla** (app de sistema) y el cliente trabaja en una **copia** o en una app importada en su mandante. Al diagnosticar: mira primero `FDT_ADMN_0000` (lo del cliente), después `…0000S` (lo de SAP).
