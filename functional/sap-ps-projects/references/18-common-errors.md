# Errores Frecuentes en SAP PS

## Introduccion

Catalogo de errores comunes en SAP PS organizados por area funcional, con codigo de error, texto, causa raiz, solucion paso a paso y queries de diagnostico MCP donde aplique.

---

## 1. Errores de Definicion de Proyecto (CJ)

### CJ001 — "El proyecto ya existe"
**Mensaje:** Proyecto XXXX ya existe en el sistema.
**Area:** CJ01
**Causa:** Se intenta crear un proyecto con una clave que ya esta en uso.
**Solucion:**
1. Verificar en `SE16N` → tabla `PROJ` → campo `PSPID` si existe.
2. Si existe pero esta marcado para borrado, usar `CJ9D` para eliminarlo primero o elegir clave diferente.
3. Revisar politica de numeracion de proyectos para evitar duplicados.

```sql
SELECT pspid, post1, erdat, ernam FROM proj WHERE pspid LIKE 'P-2024-%' ORDER BY pspid
```

---

### CJ002 — "Datos obligatorios incompletos en WBS"
**Mensaje:** El campo XXXX del elemento WBS es obligatorio.
**Area:** CJ01, CJ02, CJ11
**Causa:** Faltan datos requeridos por el perfil de proyecto (sociedad, tipo de proyecto, fecha, etc.).
**Solucion:**
1. Verificar el perfil de proyecto asignado (campo `PRPRF` en `PRPS`).
2. En SPRO revisar que campos son obligatorios en el perfil de WBS.
3. Completar todos los campos marcados con asterisco en CJ02.

---

### CJ003 — "No se puede liberar WBS — status incorrecto"
**Mensaje:** El elemento XXXX no puede liberarse en el status actual.
**Area:** CJ02, CJ26
**Causa:** El WBS tiene datos incompletos o su padre no esta en el status correcto.
**Solucion:**
1. Verificar que el WBS padre este en status REL antes que los hijos.
2. Comprobar que el WBS tiene centro de coste asignado (si es elemento de cuenta).
3. Revisar si hay un BAdI/Exit activo que bloquea la liberacion.
4. Verificar autorizacion: objeto `C_PRPS_ATV` con ACTVT='02'.

---

### CJ004 — "El elemento WBS tiene imputaciones — no se puede borrar"
**Mensaje:** El elemento WBS XXXX tiene partidas contabilizadas. No se puede borrar.
**Area:** CJ02, CJ12
**Causa:** El WBS tiene costes reales, reservas o documentos asignados.
**Solucion:**
1. Liquidar primero todos los costes del WBS a un receptor.
2. Cancelar reservas abiertas en MB22/MB25.
3. Cerrar pedidos asignados al WBS.
4. Solo marcar para borrado (DLFL), no intentar eliminar fisicamente si hay historial.

```sql
-- Diagnostico: Costes reales del WBS
SELECT kstar, SUM(wkg001+wkg002+wkg003+wkg004+wkg005+wkg006+
                   wkg007+wkg008+wkg009+wkg010+wkg011+wkg012) AS total
FROM cosp
WHERE objnr = (SELECT CONCAT('PR', pspnr) FROM prps WHERE posid = 'P-2024-001.1')
  AND wrttp = '11' AND gjahr = '2024'
GROUP BY kstar
```

---

### CJ005 — "Fechas del WBS fuera del rango del proyecto"
**Mensaje:** La fecha de inicio/fin del elemento WBS supera las fechas del proyecto.
**Area:** CJ02, CJ12
**Causa:** Las fechas de un WBS hijo son anteriores/posteriores a las del proyecto cabecera.
**Solucion:**
1. Corregir las fechas del WBS hijo dentro del rango del proyecto.
2. O ampliar las fechas del proyecto padre en CJ02.
3. Desactivar la validacion de fechas en el perfil de WBS si no es requerida.

---

## 2. Errores de Presupuesto (CJ3x)

### BUDG001 — "Presupuesto insuficiente — mensaje de error"
**Mensaje:** El documento supera el presupuesto disponible del WBS XXXX.
**Area:** Al crear pedidos, contabilizar facturas, confirmar actividades.
**Causa:** El compromiso o coste real supera el presupuesto liberado del WBS.
**Solucion:**
1. Verificar saldo disponible en `CJ30` / `S_ALR_87013558`.
2. Solicitar suplemento de presupuesto (`CJ32`).
3. Traspasar presupuesto de otro WBS con saldo (`CJ34`).
4. Verificar si el control es advertencia (W) o error (E) en el perfil de presupuesto.

```sql
-- Saldo disponible de presupuesto
SELECT p.posid, b.gktrp AS presupuesto, b.frtrp AS liberado, b.waers
FROM prps p INNER JOIN bpge b ON b.pspnr = p.pspnr
WHERE p.posid = 'P-2024-001.1' AND b.gjahr = '2024'
```

---

### BUDG002 — "No se puede liberar mas de lo presupuestado"
**Mensaje:** El importe a liberar supera el presupuesto disponible.
**Area:** CJ36
**Causa:** Se intenta liberar mas presupuesto del que fue originalmente asignado.
**Solucion:**
1. Verificar presupuesto original en CJ30/CJ31.
2. Crear suplemento (CJ32) antes de intentar liberar mas.
3. Revisar si el importe de liberacion es correcto.

---

### BUDG003 — "No existe presupuesto para el periodo"
**Mensaje:** No existe definicion de presupuesto para el ejercicio XXXX.
**Area:** CJ36, CJ30
**Causa:** El ejercicio no tiene presupuesto asignado o el perfil de presupuesto no permite ese ejercicio.
**Solucion:**
1. Verificar en BPGE si existe registro para ese ejercicio.
2. Asignar presupuesto para ese ejercicio en CJ30.
3. Si es multi-anio, verificar la configuracion del perfil de presupuesto.

---

### BUDG004 — "Control de disponibilidad desactivado para WBS"
**Mensaje:** No se puede verificar disponibilidad — control no activo.
**Area:** Al crear documentos de coste
**Causa:** El elemento WBS no tiene BELKZ='X' (no es elemento de cuenta) o el perfil no tiene control activo.
**Solucion:**
1. En CJ12 → verificar que el WBS tiene activado "Elemento de cuenta".
2. Revisar perfil de presupuesto en SPRO → si tiene activo el control de disponibilidad.
3. Ejecutar CJBV para actualizar los saldos de control.

---

## 3. Errores de Redes y Actividades (CN)

### CN001 — "Actividad no confirmable — status red incorrecto"
**Mensaje:** La actividad XXXX no puede confirmarse. Red no liberada.
**Area:** CN25, CN27
**Causa:** La red padre no esta en status REL.
**Solucion:**
1. Liberar la red: `CN22` → Editar → Liberar, o desde `CJ20N`.
2. Verificar que la actividad tampoco este en status TECO.
3. Verificar que el WBS al que pertenece la red este tambien en REL.

```sql
SELECT j.stat, CASE j.stat WHEN 'I0002' THEN 'REL' WHEN 'I0001' THEN 'CREA'
                            WHEN 'I0009' THEN 'TECO' ELSE j.stat END AS status
FROM netz n
INNER JOIN jest j ON j.objnr = CONCAT('OR', n.aufnr)
WHERE n.aufnr = '000004000123' AND j.inact <> 'X'
```

---

### CN002 — "No se puede programar — red sin actividades"
**Mensaje:** La red no tiene actividades definidas. No se puede programar.
**Area:** CN72, CJ29
**Causa:** La red existe pero no tiene actividades (VORG).
**Solucion:**
1. Agregar actividades en CN22.
2. O eliminar la red vacia si no es necesaria.

---

### CN003 — "Fecha de actividad fuera del horizonte de red"
**Mensaje:** La fecha de la actividad supera el horizonte definido.
**Area:** CN21, CN22, CN72
**Causa:** Las fechas de inicio/fin de la actividad estan fuera del rango de la red.
**Solucion:**
1. Ampliar las fechas de la red primero.
2. Corregir las fechas de la actividad.
3. Verificar parametros de tolerancia en T399D.

---

### CN004 — "Componente de material no disponible"
**Mensaje:** El material XXXX no tiene stock disponible para la fecha requerida.
**Area:** CN49, confirmacion de actividad
**Causa:** Falta stock del material planificado como componente de la actividad.
**Solucion:**
1. Verificar disponibilidad en `MD04` o `MMBE`.
2. Crear pedido urgente si es necesario.
3. Ajustar la fecha de necesidad del componente si hay stock futuro.
4. Verificar si hay reservas duplicadas que consuman el stock.

---

### CN005 — "Clave de control no permite confirmacion"
**Mensaje:** La clave de control de la actividad no permite confirmaciones.
**Area:** CN25
**Causa:** La clave de control (STEUS) de la actividad tiene el indicador de confirmacion desactivado.
**Solucion:**
1. Verificar la clave de control en T438A: campo KZAVA.
2. Cambiar la clave de control de la actividad en CN22.
3. O usar una clave de control diferente que permita confirmaciones.

```sql
SELECT steus, ltext, kzava FROM t438a WHERE spras = 'S' ORDER BY steus
```

---

### CN006 — "Relacion entre actividades crea ciclo"
**Mensaje:** La relacion definida crea una dependencia ciclica. No permitido.
**Area:** CN22 (relaciones), CN72
**Causa:** Se intenta crear una relacion FS/SS/SF/FF que genera un ciclo cerrado.
**Solucion:**
1. Revisar el diagrama de red para identificar el ciclo.
2. Eliminar la relacion que genera el ciclo.
3. Reestructurar la logica de dependencias.

---

## 4. Errores de Liquidacion (CJ88, KO88)

### LIQ001 — "No existe regla de liquidacion para WBS"
**Mensaje:** El WBS XXXX no tiene reglas de liquidacion definidas.
**Area:** CJ88, CJ8G
**Causa:** No se crearon reglas de liquidacion en CJ04 para ese WBS.
**Solucion:**
1. Ir a CJ04 y crear la regla de liquidacion.
2. Definir receptor (AuC, CC, GL, WBS padre).
3. Asignar porcentaje (100% si es un solo receptor).
4. Grabar y volver a ejecutar CJ88.

```sql
-- Verificar si existe regla de liquidacion
SELECT objnr, lfdnr, empfg, prozs, beknz FROM cobrb
WHERE objnr = (SELECT CONCAT('PR', pspnr) FROM prps WHERE posid = 'P-2024-001.1')
```

---

### LIQ002 — "Receptor de liquidacion no existe o es invalido"
**Mensaje:** El receptor XXXX de la regla de liquidacion no existe.
**Area:** CJ88, CJ04
**Causa:** El WBS, CC, activo o GL definido como receptor no existe o fue eliminado.
**Solucion:**
1. Verificar que el receptor existe en el sistema.
2. Actualizar la regla de liquidacion con un receptor valido (CJ04).
3. Si es un activo: verificar en AS03 que el activo existe y no esta archivado.

---

### LIQ003 — "El WBS aun tiene saldo — no se puede cerrar (CLSD)"
**Mensaje:** El elemento WBS XXXX tiene saldo de costes. Liquidar antes de cerrar.
**Area:** Cierre de WBS (CLSD)
**Causa:** Quedan costes no liquidados en el WBS despues de la liquidacion.
**Solucion:**
1. Ejecutar CJI3 para ver que costes quedan sin liquidar.
2. Volver a ejecutar CJ88 en modo "Liquidacion Total".
3. Verificar que el periodo este abierto para CO.
4. Si hay costes en periodos cerrados, abrir periodo y reliquidar.

```sql
-- Saldo pendiente de liquidacion (costes reales)
SELECT SUM(wkg001+wkg002+wkg003+wkg004+wkg005+wkg006+
           wkg007+wkg008+wkg009+wkg010+wkg011+wkg012) AS saldo_real
FROM cosp
WHERE objnr = (SELECT CONCAT('PR', pspnr) FROM prps WHERE posid = 'P-2024-001.1')
  AND wrttp = '11' AND gjahr = '2024' AND versn = '000'
```

---

### LIQ004 — "Periodo de CO cerrado — no se puede liquidar"
**Mensaje:** El periodo XXXX/YYYY esta cerrado para imputaciones en CO.
**Area:** CJ88, KO88
**Causa:** El periodo contable de CO no esta abierto para nuevas contabilizaciones.
**Solucion:**
1. Verificar periodos abiertos en OKP1 (CO) o OB52 (FI).
2. Abrir el periodo necesario (requiere autorizacion).
3. Ejecutar la liquidacion en el periodo correcto.
4. Si el periodo no se puede abrir, usar la funcion de liquidacion en periodo siguiente.

---

### LIQ005 — "Porcentajes de liquidacion no suman 100%"
**Mensaje:** Los porcentajes de las reglas de liquidacion no suman 100%.
**Area:** CJ04, CJ88
**Causa:** Las reglas de liquidacion definidas no totalizan el 100% del coste.
**Solucion:**
1. Abrir CJ04 y revisar todas las reglas activas.
2. Ajustar los porcentajes para que sumen exactamente 100%.
3. Si hay reglas con fechas de validez, verificar que la suma sea correcta para el periodo actual.

---

## 5. Errores de Status

### STS001 — "No se puede completar tecnicamente — pedidos abiertos"
**Mensaje:** El WBS/Red XXXX tiene documentos de aprovisionamiento abiertos.
**Area:** TECO (CJ02, CJCO)
**Causa:** Existen pedidos, solicitudes o reservas sin completar asignados al WBS.
**Solucion:**
1. Listar pedidos abiertos: `ME2J` con filtro por WBS.
2. Cerrar posiciones de pedido completadas pero no cerradas (ME22N → Indicador entrega completa).
3. Cancelar posiciones no necesarias.
4. Para reservas: cancelar en MB22 o verificar si se pueden ignorar.

```sql
-- Pedidos abiertos asignados al WBS
SELECT e.ebeln, e.ebelp, e.txz01, e.menge, e.wemng, e.netpr
FROM ekbe e
INNER JOIN ekkn k ON k.ebeln = e.ebeln AND k.ebelp = e.ebelp
INNER JOIN prps p ON p.pspnr = k.ps_psp_pnr
WHERE p.posid LIKE 'P-2024-001%'
  AND e.bewtp = 'E' -- Solo entradas de mercancia
  AND (e.menge - e.wemng) > 0 -- Con cantidad pendiente
```

---

### STS002 — "Transicion de status no permitida"
**Mensaje:** No se puede pasar de XXXX a YYYY para este objeto.
**Area:** Cambio de status en CJ02, BS02
**Causa:** El perfil de status de usuario no permite la transicion directa entre esos dos status.
**Solucion:**
1. Revisar el perfil de status en BS02 para ver las transiciones permitidas.
2. Puede ser necesario pasar por un status intermedio.
3. Si la transicion deberia ser posible, modificar el perfil en BS02.

---

### STS003 — "Status TECO no se puede revertir — hay liquidaciones"
**Mensaje:** El status TECO no puede revertirse porque existen liquidaciones posteriores.
**Area:** Revertir TECO en CJ02
**Causa:** Tras el TECO se ejecutaron liquidaciones, y SAP impide reabrir.
**Solucion:**
1. Cancelar las liquidaciones en KO88 modo "Cancelar".
2. Luego revertir el TECO en CJ02.
3. En algunos casos es necesario abrir periodos CO ya cerrados.
4. Evaluar si es mas conveniente crear un nuevo WBS en lugar de revertir.

---

## 6. Errores de Costes y Plan (CJ40, CJ42)

### COST001 — "La version de plan esta bloqueada"
**Mensaje:** La version de plan XXXX esta bloqueada para modificaciones.
**Area:** CJ40, CJ42
**Causa:** La version de plan fue bloqueada explicitamente o es una version de solo lectura.
**Solucion:**
1. Usar la version operativa (000) o crear una version nueva.
2. Si la version debe desbloquearse, ir a OKP1 o a la administracion de versiones CO.
3. Verificar en SPRO → CO → Versiones de Plan si la version esta abierta para el ejercicio.

---

### COST002 — "No se puede planificar — elemento WBS no es elemento de cuenta"
**Mensaje:** El elemento WBS XXXX no es un elemento de cuenta. No se permite planificacion directa.
**Area:** CJ40
**Causa:** El WBS es un elemento resumen (no tiene BELKZ='X') y la planificacion directa esta restringida.
**Solucion:**
1. Cambiar el WBS a elemento de cuenta en CJ12 (activar indicador BELKZ).
2. O planificar en los WBS hijos que si son elementos de cuenta.
3. Revisar la jerarquia de WBS para ver donde se permite planificar.

---

### COST003 — "Clase de coste no permitida en plan de proyecto"
**Mensaje:** La clase de coste XXXX no esta permitida para imputacion en PS.
**Area:** CJ40, CJ42
**Causa:** La clase de coste no esta configurada para imputacion en proyectos (tipo de orden PS).
**Solucion:**
1. Verificar en KA02 que la clase de coste tiene el tipo correcto.
2. En SPRO → CO → Clases de coste verificar que el tipo de orden PS esta habilitado.
3. Si es clase de coste primaria, verificar que existe la cuenta GL correspondiente.

---

## 7. Errores de Fechas y Programacion

### SCHED001 — "No se puede programar — no hay calendario definido"
**Mensaje:** El centro XXXX no tiene calendario de fabrica asignado.
**Area:** CN72, CJ29
**Causa:** El centro de planificacion no tiene calendario asignado en los parametros PS.
**Solucion:**
1. En SPRO → PS → Parametros por centro: asignar calendario.
2. O asignar el calendario directamente en la red (CN21/CN22).
3. Crear/verificar calendario en SCAL si no existe.

---

### SCHED002 — "Duración negativa de actividad"
**Mensaje:** La duracion calculada de la actividad XXXX es negativa.
**Area:** CN72
**Causa:** La fecha de inicio calculada es posterior a la fecha de fin fijada manualmente.
**Solucion:**
1. Revisar las fechas de la actividad en CN22.
2. Eliminar las fechas fijas si no son necesarias (liberarlas para el scheduling).
3. Ajustar la duracion de la actividad para que sea consistente.

---

### SCHED003 — "Holgura negativa — ruta critica sobrepasada"
**Mensaje:** El margen libre de la actividad XXXX es negativo. Proyecto en retraso.
**Area:** CNS41 (diagrama Gantt), CN72
**Causa:** Las fechas actuales del proyecto implican que la fecha de fin del proyecto se superara.
**Solucion:**
1. Revisar actividades en ruta critica (CNS41 → ruta critica marcada en rojo).
2. Reducir duración de actividades criticas (fast-tracking o crashing).
3. Revisar si se pueden paralelizar actividades secuenciales.
4. Actualizar la fecha de fin del proyecto si es necesario.

---

## 8. Errores de MRP y Material

### MRP001 — "Componente de red sin maestro de materiales"
**Mensaje:** El material XXXX no existe en el maestro de materiales del centro.
**Area:** CN22 (asignacion de componentes)
**Causa:** El material no esta creado para ese centro especifico.
**Solucion:**
1. Crear el maestro de materiales para ese centro: MM01.
2. O extender el material al centro: MM01 → Extender vistas.
3. Verificar que el tipo de material es correcto (no un material de servicios puro).

---

### MRP002 — "Stock de proyecto negativo"
**Mensaje:** El stock de proyecto del WBS XXXX es negativo.
**Area:** MB54, MMBE
**Causa:** Se realizaron salidas de stock (Mov. 221) por mas cantidad que la disponible.
**Solucion:**
1. Verificar movimientos en MATDOC o historial MB51.
2. Identificar el movimiento incorrecto y crear documento de correccion.
3. Entrada de stock de ajuste (Mov. 501 o 411Q) para normalizar.
4. Revisar autorizaciones de movimientos de stock.

---

### MRP003 — "Solicitud de pedido automatica bloqueada"
**Mensaje:** No se puede crear solicitud automatica para componente XXXX.
**Area:** MD01, MD41
**Causa:** El material tiene bloqueo de compras o el WBS esta en status que impide creacion de SoPed.
**Solucion:**
1. Verificar maestro de materiales: bloqueos en MM03 → vista Compras.
2. Verificar status del WBS: debe estar en REL.
3. Verificar que el indicador MRP del componente de red es correcto (no 0).

---

## 9. Errores de Facturacion (SD-PS)

### SD001 — "WBS no es elemento de facturacion"
**Mensaje:** El WBS XXXX no esta configurado como elemento de facturacion.
**Area:** DP90, VA01 con WBS
**Causa:** Para usar milestone billing o resource-related billing, el WBS debe ser elemento de facturacion.
**Solucion:**
1. En CJ12: activar indicador "Elemento de facturacion" (campo FAKKZ).
2. Verificar que el WBS tiene pedido de ventas asignado.
3. Asegurarse que la organizacion de ventas esta configurada para el proyecto.

---

### SD002 — "Hito de facturacion no alcanzado"
**Mensaje:** No se puede facturar el hito XXXX — no esta marcado como alcanzado.
**Area:** VF01, VF04 (milestone billing)
**Causa:** El hito de facturacion no tiene la fecha real registrada o el porcentaje de avance requerido.
**Solucion:**
1. Marcar el hito como alcanzado en CN31: activar campo "Alcanzado" y agregar fecha real.
2. Ejecutar VBOF (actualizar documentos de facturacion en SD).
3. Luego ejecutar VF04 para generar la factura.

---

## 10. Errores de Analisis de Resultados (KKA)

### RA001 — "Clave de analisis de resultados no asignada"
**Mensaje:** El WBS XXXX no tiene clave de analisis de resultados.
**Area:** KKA1, KKA2
**Causa:** No se asigno la clave de RA al WBS o al tipo de proyecto en customizing.
**Solucion:**
1. En CJ12: asignar la clave de analisis de resultados al WBS.
2. O en SPRO → PS → Ingresos → Definir clave RA por tipo de proyecto.
3. Ejecutar KKA2 nuevamente.

---

### RA002 — "Metodo de analisis de resultados genera error matematico"
**Mensaje:** El calculo del analisis de resultados produce valores inconsistentes (divisor cero).
**Area:** KKA1, KKA2
**Causa:** El metodo de RA requiere un plan de costes o ingresos que es cero.
**Solucion:**
1. Verificar que hay plan de costes en CJ40/CJ42.
2. Verificar que hay plan de ingresos en el WBS.
3. Cambiar el metodo de RA en customizing si el proyecto no tiene plan de ingresos.

---

## 11. Errores de Autorizacion

### AUTH001 — "Sin autorizacion para contabilizar en WBS"
**Mensaje:** Usuario no autorizado para objeto C_PROJ_KOK con sociedad XXXX.
**Area:** Cualquier transaccion PS
**Causa:** El usuario no tiene asignado el rol con acceso a la sociedad del proyecto.
**Solucion:**
1. Ejecutar SU53 justo despues del error para ver el objeto de autorizacion faltante.
2. Contactar al administrador de seguridad para asignar el rol correcto.
3. Verificar que el usuario esta asignado al centro/sociedad correctos en HR si aplica.

---

### AUTH002 — "Sin autorizacion para modificar presupuesto"
**Mensaje:** Accion no autorizada: Presupuestar (BUDG) para proyecto XXXX.
**Area:** CJ30, CJ32
**Causa:** Falta el objeto de autorizacion C_PRPS_BDG o C_PROJ_KOK.
**Solucion:**
1. SU53 para identificar objeto faltante.
2. Verificar rol SAP_PS_PROJECT_CONTROLLER asignado.
3. Solicitar ampliacion de autorizaciones al equipo de seguridad.

---

## 12. Tabla Resumen de Errores Frecuentes

| Cod. Ref. | Area | Descripcion | Trans. Afectada | Solucion Rapida |
|-----------|------|-------------|-----------------|-----------------|
| CJ001 | WBS | Proyecto ya existe | CJ01 | Verificar PROJ, usar otra clave |
| CJ002 | WBS | Datos obligatorios incompletos | CJ01/CJ02 | Completar campos del perfil |
| CJ003 | WBS | No se puede liberar | CJ26 | Liberar padre primero, verificar datos |
| CJ004 | WBS | WBS con imputaciones - no borrar | CJ02 | Liquidar, cancelar reservas |
| CJ005 | WBS | Fechas fuera de rango proyecto | CJ12 | Corregir fechas o ampliar proyecto |
| BUDG001 | Presupuesto | Presupuesto insuficiente | Postings | CJ32 suplemento o CJ34 traspaso |
| BUDG002 | Presupuesto | Liberar mas de lo presupuestado | CJ36 | CJ32 primero, luego CJ36 |
| BUDG003 | Presupuesto | Sin presupuesto en periodo | CJ30 | Asignar presupuesto en CJ30 |
| BUDG004 | Presupuesto | Control desactivado | Varios | BELKZ activo + perfil correcto |
| CN001 | Red | Red no liberada | CN25 | Liberar red en CN22 |
| CN002 | Red | Red sin actividades | CN72 | Agregar actividades en CN22 |
| CN003 | Red | Fechas fuera horizonte | CN22 | Ajustar fechas de actividad/red |
| CN004 | Red | Material no disponible | CN49 | MD04, crear pedido urgente |
| CN005 | Red | Clave control sin confirmacion | CN25 | Cambiar clave control en CN22 |
| CN006 | Red | Ciclo en dependencias | CN22 | Revisar y corregir relaciones |
| LIQ001 | Liquidacion | Sin regla de liquidacion | CJ88 | Crear reglas en CJ04 |
| LIQ002 | Liquidacion | Receptor invalido | CJ88 | Actualizar receptor en CJ04 |
| LIQ003 | Liquidacion | Saldo pendiente | CLSD | CJ88 modo total |
| LIQ004 | Liquidacion | Periodo CO cerrado | CJ88 | OKP1 abrir periodo |
| LIQ005 | Liquidacion | Porcentajes != 100% | CJ04 | Ajustar porcentajes |
| STS001 | Status | Pedidos abiertos para TECO | CJCO | Cerrar pedidos en ME22N |
| STS002 | Status | Transicion no permitida | CJ02 | Revisar perfil BS02 |
| STS003 | Status | TECO irreversible con liquidacion | CJ02 | Cancelar liquidaciones primero |
| COST001 | Costes | Version plan bloqueada | CJ40 | Usar version 000 o abrir version |
| COST002 | Costes | WBS no es elemento de cuenta | CJ40 | Activar BELKZ en CJ12 |
| COST003 | Costes | Clase coste no permitida | CJ42 | Verificar tipo en KA02 |
| SCHED001 | Fechas | Sin calendario | CN72 | Asignar calendario en SPRO |
| SCHED002 | Fechas | Duracion negativa | CN72 | Corregir fechas en CN22 |
| SCHED003 | Fechas | Holgura negativa | CNS41 | Revisar ruta critica |
| MRP001 | Material | Material sin maestro | CN22 | MM01 extender a centro |
| MRP002 | Material | Stock proyecto negativo | MB54 | Mov. ajuste 411Q |
| MRP003 | Material | SoPed bloqueada | MD01 | Desbloquear material o WBS |
| SD001 | SD | WBS sin facturacion | DP90 | Activar FAKKZ en CJ12 |
| SD002 | SD | Hito no alcanzado | VF04 | Marcar hito en CN31 |
| RA001 | RA | Sin clave analisis | KKA2 | Asignar clave RA en CJ12 |
| RA002 | RA | Error matematico RA | KKA2 | Verificar plan costes/ingresos |
| AUTH001 | Auth | Sin autorizacion WBS | Varios | SU53 → solicitar rol |
| AUTH002 | Auth | Sin autorizacion presupuesto | CJ30 | SU53 → C_PRPS_BDG |
