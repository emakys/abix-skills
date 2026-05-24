# Physical Inventory (PI) — Inventario Fisico

## Concepto General

El **Inventario Fisico (Physical Inventory)** en EWM es el proceso de contar fisicamente el stock en el almacen y reconciliarlo con el stock registrado en el sistema. En S/4HANA 2023, EWM gestiona el inventario a nivel de **bin (ubicacion)**, mientras que el inventario contable se sincroniza con MM-IM a traves de interfaces definidas.

El inventario fisico en EWM opera de forma independiente al inventario de MM: se crea un documento de PI en EWM, se cuenta el stock en el bin, y las diferencias se transfieren a MM para el ajuste contable.

Transaccion principal: `/SCWM/PI` o Fiori app "Manage Physical Inventory"

## Tipos de Inventario Fisico

### 1. Inventario Anual (Annual Inventory)
- Conteo de todos los bins del almacen en un momento especifico
- Obligatorio en muchos paises (cierre de ejercicio fiscal)
- Proceso: bloqueo masivo de bins → conteo → diferencias → ajuste
- Alto impacto operativo: puede requerir paro de operaciones

### 2. Inventario Periodico (Periodic Inventory)
- Division del almacen en zonas contadas en periodos definidos (semanal, mensual)
- Cada zona se cuenta completamente en su periodo
- Menor impacto que el anual, pero cubre todo el almacen en el ciclo

### 3. Conteo Ciclico (Cycle Counting)
- Conteo continuo basado en clasificacion ABC/XYZ del material
- Materiales A: mayor frecuencia de conteo (ej. cada mes)
- Materiales B: frecuencia media (ej. cada trimestre)
- Materiales C: menor frecuencia (ej. anual)
- Configuracion de clases de conteo ciclico en `/SCWM/CC_CLASS`

### 4. Inventario de Stock Bajo/Cero (Low/Zero Stock)
- Activado automaticamente cuando un bin llega a stock cero o muy bajo
- Aprovecha el momento en que el bin esta vacio para verificar
- Configuracion: activar indicador en storage type o bin
- Muy eficiente: no requiere bloqueo, el bin ya esta vacio

### 5. Inventario Ad-hoc (Spot Check)
- Conteo manual de un bin especifico en cualquier momento
- Util para investigar discrepancias detectadas durante operacion
- Sin planificacion previa, creacion directa del documento PI
- Transaccion: `/SCWM/PI` > Create PI Document

### 6. Inventario Continuo (Continuous Inventory)
- Conteo permanente distribuido en el tiempo
- Cada bin se cuenta al menos una vez en el periodo fiscal
- Sistema asigna bins para contar segun reglas de prioridad
- Elimina la necesidad de inventario anual masivo

## Proceso de Inventario Fisico

### Paso 1: Creacion del Documento PI
- Transaccion: `/SCWM/PI` > Create
- Seleccion de scope: warehouse number, storage type, section, bin, material
- El documento PI (/SCWM/IVDOC) registra el stock esperado al momento de creacion
- Estado inicial: "Created"

Tabla cabecera: `/SCWM/IVDOC`
Tabla items: `/SCWM/IVDOCI`

### Paso 2: Bloqueo de Bins
- Al crear el doc PI, los bins afectados quedan bloqueados para movimientos
- Tipos de bloqueo: bloqueo total (in + out), solo salidas, solo entradas
- Configuracion del bloqueo en tipo de storage o a nivel de bin
- El bloqueo se libera automaticamente al cerrar el documento PI

### Paso 3: Impresion de Lista de Conteo
- Lista fisica con bins, materiales y espacio para anotar cantidad contada
- En RF/Fiori: la lista aparece en el dispositivo del operario
- Opcion de "blind count": la cantidad esperada NO se muestra al contador
- Blind count evita que el operario simplemente confirme el sistema

### Paso 4: Registro del Conteo
- El operario registra la cantidad fisica encontrada
- En RF: scan del bin → scan del material → ingreso de cantidad
- En Fiori: app "Count Physical Inventory"
- Estado del documento: "Counted"

### Paso 5: Reconteo (Recount)
- Si la diferencia supera la tolerancia configurada, se genera reconteo automatico
- Un segundo operario (diferente al primero) realiza el reconteo
- Hasta N reconteos configurables antes de forzar decision manual
- Estado: "Recounted"

### Paso 6: Aprobacion de Diferencias
- Diferencias dentro de tolerancia: se aprueban automaticamente
- Diferencias fuera de tolerancia: requieren aprobacion manual de supervisor
- Grupos de tolerancia: porcentaje y/o valor absoluto
- Transaccion de aprobacion: `/SCWM/PI` > Approve Differences

### Paso 7: Contabilizacion de Diferencias
- Una vez aprobadas, las diferencias se transfieren a MM-IM
- EWM ajusta el stock en el bin
- MM crea movimiento contable (tipo de movimiento 701/702 u otro segun config)
- Estado final del documento PI: "Posted"

## Documento de Inventario (/SCWM/IVDOC)

Campos principales del documento:
- `LGNUM`: Warehouse number
- `IVDOC`: Numero de documento PI
- `IVTYP`: Tipo de inventario (anual, ciclico, ad-hoc...)
- `LGPLA`: Bin (ubicacion) afectado
- `MATNR`: Material
- `SOLLME`: Cantidad esperada (system quantity)
- `ISTME`: Cantidad contada (counted quantity)
- `DIFFME`: Diferencia
- `STATUS`: Estado del documento

## Analisis ABC para Cycle Counting

La clasificacion ABC determina la frecuencia de conteo:

```
Clase A: Materiales de alto valor o alta rotacion
  → Contar mensualmente (12 veces/año)

Clase B: Materiales de valor/rotacion media
  → Contar trimestralmente (4 veces/año)

Clase C: Materiales de bajo valor o baja rotacion
  → Contar anualmente (1 vez/año)
```

Configuracion: `/SCWM/CC_CLASS` (Cycle Counting Classes)
Asignacion: por material, por storage type, o combinacion

El sistema calcula automaticamente la fecha del proximo conteo basandose en la clase asignada y la fecha del ultimo conteo.

## Grupos de Tolerancia

Los grupos de tolerancia definen cuando una diferencia es aceptable sin aprobacion manual:

| Campo | Descripcion |
|-------|-------------|
| Tolerancia % | Porcentaje de diferencia permitido |
| Tolerancia absoluta | Valor absoluto de diferencia permitido |
| Aplicacion | Por material, categoria de valoracion, o global |

Configuracion: IMG > EWM > Physical Inventory > Define Tolerance Groups

## PI con RF y Fiori

### RF (Radio Frequency / Escaner portatil)
- Funcion RF: Inventory (accesible desde menu RF principal)
- Flujo: Login → Warehouse → PI Document → Scan bin → Scan material → Quantity
- Soporte de blind count en configuracion de perfil RF

### Fiori Apps para PI
- "Manage Physical Inventory" (planificacion y monitoreo)
- "Count Physical Inventory" (ejecucion de conteo)
- "Approve Physical Inventory Differences" (aprobacion)
- Disponibles en S/4HANA 2023 con Fiori Launchpad EWM

## Tablas Principales

| Tabla | Descripcion |
|-------|-------------|
| `/SCWM/IVDOC` | Cabecera documentos PI |
| `/SCWM/IVDOCI` | Items documentos PI |
| `/SCWM/IVDOC_H` | Historial de cambios PI |
| `/SCWM/CC_CLASS` | Clases de cycle counting |
| `/SCWM/IVTOL` | Grupos de tolerancia PI |
| `/SCWM/LGPLA` | Master data de bins (incluye indicador PI) |

## Consultas MCP Recomendadas

```
-- Explorar objetos de PI en namespace /SCWM/
SearchObject: tipo FUGR, nombre "/SCWM/PI*" → function groups de PI
SearchObject: tipo CLAS, nombre "/SCWM/CL_PI*" → clases de PI
ReadClass: /SCWM/CL_PI_DOC → logica principal de documentos PI
GetFunctionGroup: /SCWM/PI_CORE → funciones core de PI

-- Ver configuracion
SearchObject: tipo TABL, nombre "/SCWM/IVDOC" → estructura de tabla
GetObjectSource: via ADT URI para /SCWM/PI_TOOLS
```

## Configuracion IMG

```
IMG > Extended Warehouse Management
  > Physical Inventory
    > Define Physical Inventory Types
    > Define Tolerance Groups
    > Define Cycle Counting Classes
    > Assign Cycle Counting Classes to Materials
    > Configure Bin Blocking During PI
    > Set Up Approval Workflow for Differences
    > Define PI Document Number Ranges
```

## Mejores Practicas S/4HANA 2023

- Usar cycle counting para reducir impacto del inventario anual
- Activar low/zero stock inventory en todos los storage types activos
- Configurar blind count en RF para conteos criticos (sin sesgo del sistema)
- Definir grupos de tolerancia diferenciados por categoria de material
- Automatizar aprobacion de diferencias menores con BAdI `/SCWM/EX_PI_POST`
- Monitorear KPI de precision de inventario (inventory accuracy %) en Warehouse Monitor
