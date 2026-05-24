# Arboles de Decision SAP PS

## Introduccion

Los arboles de decision ayudan a elegir la configuracion correcta para los principales parametros de SAP PS. Cada arbol guia al consultor o usuario a traves de preguntas clave para llegar a la opcion mas adecuada segun las caracteristicas del proyecto.

---

## 1. Tipo de Proyecto (Project Type)

```
¿Cual es el proposito principal del proyecto?
│
├── CONSTRUIR un activo fisico (edificio, planta, infraestructura)
│   ├── ¿Se capitaliza el activo al finalizar?
│   │   ├── SI → Tipo: CAPITAL (CAPEX)
│   │   │         Liquidacion: WBS → Activo en Curso (AuC) → Activo Definitivo
│   │   │         Parametros: Clave RA con capitalizacion, receptores AuC
│   │   │
│   │   └── NO → Tipo: OPEX / INFRAESTRUCTURA
│   │             Liquidacion: WBS → Centro de Coste / GL
│   │
├── DESARROLLAR software o sistema
│   ├── ¿Se activa como activo intangible?
│   │   ├── SI → Tipo: TI-CAPITAL (IAS 38)
│   │   │         Como capital pero activo intangible
│   │   │
│   │   └── NO → Tipo: TI-OPEX
│   │             Liquidacion: WBS → CC de TI
│   │
├── PRESTAR un servicio a un cliente (con facturacion)
│   ├── ¿Hay contrato de precio fijo?
│   │   ├── SI → Tipo: SERVICIO PRECIO FIJO
│   │   │         Liquidacion: Analisis de Resultados POC
│   │   │         SD: Milestone Billing o Factura parcial segun avance
│   │   │
│   │   └── NO → Tipo: SERVICIO TIME & MATERIAL
│   │             Liquidacion: Resource-Related Billing (DP90)
│   │             SD: Facturacion por costes reales
│   │
├── INVESTIGACION y Desarrollo (I+D)
│   ├── ¿Fase de investigacion pura?
│   │   └── SI → Tipo: I+D-INVESTIGACION
│   │             OPEX, costes a resultados
│   │
│   ├── ¿Fase de desarrollo activable?
│   │   └── SI → Tipo: I+D-DESARROLLO
│   │             CAPEX, activo intangible
│   │
└── MANTENIMIENTO mayor o parada de planta
    └── Tipo: MANTENIMIENTO-PROYECTO
          Integracion con PM (ordenes mantenimiento)
          Liquidacion: WBS → CC de Mantenimiento
```

---

## 2. WBS Operativo vs. Estadistico

```
¿Cual debe ser la funcion del elemento WBS?
│
├── ¿Necesita RECIBIR costes reales directamente?
│   (postings de FI, MM, HR, confirmaciones)
│   │
│   └── SI → WBS OPERATIVO (Elemento de Cuenta, BELKZ = X)
│             Imputacion directa de costes reales
│             Presupuesto propio (control de disponibilidad)
│             Liquidacion directa a receptor
│             → Usar en: WBS hojas del arbol (ultimo nivel con costes)
│
├── ¿Solo AGREGA costes de WBS hijos?
│   (sin costes directos propios)
│   │
│   └── SI → WBS RESUMEN (Elemento no cuenta, BELKZ = espacio)
│             No recibe postings directos
│             El presupuesto se define en el hijo o se agrega del hijo
│             Sirve para reportar y agrupar
│             → Usar en: WBS de niveles superiores (fases, entregables)
│
├── ¿Solo necesita ESTRUCTURA jerarquica para informes?
│   (sin control presupuestario, sin costes directos)
│   │
│   └── SI → WBS ESTADISTICO
│             Campo: Indicador estadistico activo
│             Los costes se imputan "de paso" (no se quedan alli)
│             No hay liquidacion propia
│             → Usar en: Jerarquia de reporte, estructura organizativa
│
└── ¿Necesita FACTURAR al cliente?
    │
    └── SI → WBS DE FACTURACION (FAKKZ = X)
              Solo los WBS con este indicador pueden ser
              elementos de facturacion en SD
              Puede ser ademas operativo (BELKZ + FAKKZ)
```

---

## 3. Tipo de Presupuesto

```
¿Como se define el presupuesto del proyecto?
│
├── ¿Se gestiona el presupuesto a nivel de proyecto TOTAL?
│   (sin desglose por anio)
│   │
│   └── SI → Presupuesto GLOBAL (BPGE)
│             Un unico importe para toda la vida del proyecto
│             Perfil: KKBPR = espacio (sin distribucion anual)
│             Ventaja: Simple, menos administracion
│             Desventaja: Sin control por ejercicio
│
├── ¿Se necesita control presupuestario por EJERCICIO FISCAL?
│   │
│   └── SI → Presupuesto ANUAL (BPJA)
│             Se define un importe por ejercicio
│             Perfil: KKBPR = X (con distribucion anual)
│             Ventaja: Alineado con cierre fiscal
│             Desventaja: Mas complejo de administrar
│
├── ¿El presupuesto puede SOBREPASARSE con advertencia?
│   │
│   ├── SI, con ADVERTENCIA → Tolerancia en perfil presupuesto
│   │                          TOLPR% < gasto → Warning (W)
│   │                          TOLFE% < gasto → Error (E)
│   │                          El usuario puede ignorar la advertencia
│   │
│   └── NO, bloqueo ESTRICTO → Sin tolerancia o tolerancia 0%
│                               Cualquier exceso genera error
│                               El usuario no puede continuar
│
└── ¿El presupuesto se controla a nivel de WBS HOJA o NIVEL SUPERIOR?
    │
    ├── Nivel HOJA → Cada WBS elemento de cuenta tiene su presupuesto
    │                Control granular
    │                Requiere mas mantenimiento
    │
    └── Nivel SUPERIOR → El presupuesto se define en el WBS padre
                          Los hijos no tienen presupuesto propio
                          Se controla el total, no el detalle
```

---

## 4. Metodo de Liquidacion

```
¿Donde van los costes del proyecto al final?
│
├── ¿El proyecto CONSTRUYE un activo fijo?
│   │
│   └── SI → CAPITALIZAR (liquidar a activo)
│             Paso 1: WBS → Activo en Curso (AuC) durante el proyecto
│                     Regla: Receptor tipo 'A' (Activo), clave BSX
│             Paso 2: Al cierre: AuC → Activo Definitivo (AIAB/AIBU)
│             Clase de liquidacion: tipo FUL (total) o PER (periodico)
│
├── ¿El proyecto genera INGRESOS (proyecto de servicio/producto)?
│   │
│   ├── ¿Precio FIJO acordado con cliente?
│   │   └── SI → ANALISIS DE RESULTADOS (POC Method)
│   │             KKA1/KKA2 calcula Ingresos POC = Ingresos * % avance
│   │             Liquidacion: WBS → CO-PA (resultado)
│   │             Clave RA con metodo de completion
│   │
│   └── ¿Time & Material (costes reales → factura)?
│       └── SI → RESOURCE-RELATED BILLING (DP90)
│                 Los costes reales generan automaticamente una factura SD
│                 No hay liquidacion clasica de WBS
│                 Los costes se "consumen" via billing document
│
├── ¿El proyecto es INTERNO (centro de coste interno)?
│   │
│   └── SI → LIQUIDAR A CENTRO DE COSTE
│             Regla: Receptor tipo 'K' (CC)
│             Periodico o al final
│             Los costes del proyecto pasan a ser costes del CC
│
├── ¿El proyecto es un PROYECTO ESTADISTICO?
│   │
│   └── SI → SIN LIQUIDACION o liquidacion solo tecnica
│             Los costes ya estan en el CC imputador
│             WBS estadistico no tiene costes propios a liquidar
│
└── ¿El proyecto tiene MULTIPLES TIPOS DE COSTES?
    │
    └── SI → LIQUIDACION MIXTA (split)
              Reglas multiples por clave de liquidacion:
              - 70% → AuC (costes capitalizables)
              - 30% → CC (costes operativos)
              Requiere clases de coste separadas
```

---

## 5. Tipo de Red (Network Type)

```
¿Que tipo de trabajo representa la red?
│
├── ¿Trabajo INTERNO (recursos propios de la empresa)?
│   │
│   └── SI → Red INTERNA (tipo de orden PP01 u equivalente)
│             Actividades con horas de trabajo internas
│             Vinculada a puestos de trabajo / centros de coste
│             Confirmacion de horas via CN25 o CATS
│             Clave control: PS02 (con confirmacion)
│
├── ¿Trabajo EXTERNO (subcontratado / proveedor)?
│   │
│   └── SI → Red EXTERNA (actividades externas)
│             Actividades con tipo E (externo)
│             Genera pedido de compras automaticamente al liberar
│             Clave control: PS03 (externa)
│             Receptor de factura: la actividad, no un CC
│
├── ¿HITOS de control del proyecto?
│   │
│   └── SI → Actividades HITO (tipo M)
│             Clave control: PS04 (hito)
│             Sin trabajo, solo fecha
│             Puede disparar facturacion SD (Milestone Billing)
│             Puede tener % de avance para EVM
│
├── ¿Actividades GENERALES (costes directos sin trabajo)?
│   │
│   └── SI → Actividades GENERALES (tipo G)
│             Para gastos directos: viajes, materiales varios
│             Clave control: PS05
│             Sin confirmacion de horas, solo registro de costes
│
└── ¿Se necesita red o es suficiente con WBS?
    │
    ├── Proyecto SIMPLE (solo costes agregados, sin programacion detallada)
    │   → Solo WBS, sin red
    │   → Presupuesto y costes a nivel WBS
    │
    └── Proyecto COMPLEJO (programacion Gantt, dependencias, recursos)
        → WBS + Red obligatorio
        → Programacion via CN72
        → Disponibilidad de recursos via CNS46
```

---

## 6. Clave de Control de Actividad

```
¿Que tipo de actividad necesitas definir?
│
├── ¿La actividad PRODUCE trabajo con horas?
│   ├── ¿Requiere CONFIRMACION de horas?
│   │   └── SI → Clave PS02 (actividad interna confirmable)
│   │             KZAVA = X (confirmacion requerida)
│   │             Genera costes via tarifas de actividad (KP26)
│   │
│   └── NO (solo planificacion, sin confirmacion)
│       └── Clave PS01 (actividad interna sin confirmacion)
│           KZAVA = espacio
│           Los costes se cargan manualmente
│
├── ¿La actividad genera PEDIDO DE COMPRAS (subcontratada)?
│   └── → Clave PS03 (actividad externa)
│         KZTRK = X (crear pedido automatico)
│         KZPRT = X (solicitud automatica)
│
├── ¿La actividad es un HITO de control?
│   └── → Clave PS04 (hito)
│         KZMAI = X
│         No genera costes propios
│         Opcionalmente vinculado a SD billing
│
├── ¿La actividad tiene costes DIRECTOS (sin horas)?
│   └── → Clave PS05 (actividad general)
│         Para gastos directos como viajes, dietas, etc.
│         Sin confirmacion de trabajo
│
└── ¿La actividad requiere APROBACION especial antes de ejecutar?
    └── → Clave personalizada Z con transaccion de negocio bloqueada
          Hasta que se apruebe, la clave bloquea confirmaciones
```

---

## 7. Milestone Billing vs. Resource-Related Billing

```
¿Como se factura el proyecto al cliente?
│
├── ¿Hay HITOS predefinidos en el contrato con montos fijos?
│   │
│   └── SI → MILESTONE BILLING (Facturacion por Hitos)
│             Proceso:
│             1. Definir hitos en red de proyecto (CN30)
│                Con campo: "Hito de facturacion" activado
│             2. Vincular hitos al pedido de cliente SD (VA02)
│                Posicion en VA01 con tipo de division de facturacion M
│             3. Cuando hito se alcanza → marcar como alcanzado (CN31)
│             4. VBOF actualiza el pedido de cliente
│             5. VF01/VF04 genera la factura
│             Ventaja: Alineado con entregas, independiente de costes reales
│             Desventaja: Requiere gestion activa de hitos
│
├── ¿Se factura segun COSTES REALES incurridos (T&M)?
│   │
│   └── SI → RESOURCE-RELATED BILLING (Facturacion por Recursos)
│             Proceso:
│             1. Se incurren costes reales en el proyecto (WBS)
│             2. DP90: Consulta costes reales y crea solicitud de facturacion
│             3. El usuario revisa y ajusta la propuesta
│             4. DP91: Genera el documento de facturacion
│             5. VF01: Factura al cliente
│             Ventaja: Facturacion directa de costes reales
│             Desventaja: Complejidad en determinacion de precios
│
├── ¿Se factura un porcentaje segun el AVANCE del proyecto?
│   │
│   └── SI → ANALISIS DE RESULTADOS + facturacion parcial
│             - Ingresos reconocidos via KKA1/KKA2 con metodo POC
│             - Facturacion: puede ser anticipos o parciales manuales
│             - Diferencia facturas emitidas vs. ingresos reconocidos = WIP
│             Uso tipico: Proyectos de larga duracion con IFRS 15
│
└── ¿El proyecto es INTERNO (sin facturacion a cliente)?
    └── → Sin facturacion SD
          Liquidacion a CC o AuC directamente
          Informes internos de costes via CJI3 / S_ALR_87013532
```

---

## 8. Analisis de Resultados (Revenue Recognition)

```
¿Se debe reconocer ingresos en PS?
│
├── ¿El proyecto TIENE pedido de cliente SD vinculado?
│   │
│   ├── SI → Revenue recognition posible
│   │
│   └── NO → Sin Analisis de Resultados
│             Solo control de costes internos
│
├── ¿Metodo de reconocimiento de ingresos?
│   │
│   ├── Porcentaje de Completacion (POC / IFRS 15)
│   │   └── Clave RA: Metodo 05 o 07
│   │         EV = (Costes Incurridos / Costes Totales Estimados) * Ingresos Totales
│   │         O bien: EV = % Avance Fisico * Ingresos Totales
│   │
│   ├── Ingresos en la Entrega (Completed Contract)
│   │   └── Clave RA: Metodo 01
│   │         Sin ingresos hasta el hito final
│   │         Todo el ingreso al cerrar el proyecto
│   │
│   └── Revenue = Billing (Ingresos = Facturas emitidas)
│       └── Clave RA: Metodo 02
│             Se reconocen exactamente lo que se ha facturado
│             WIP = Costes incurridos - Costes de ventas reconocidos
│
└── ¿El proyecto tiene PERDIDAS previstas (Loss at Completion)?
    │
    ├── SI → Provisionar perdida anticipada (provision por riesgo)
    │         KKA1/KKA2 calcula y contabiliza la provision
    │         Cuenta de gasto de provision + cuenta de balance
    │
    └── NO → Reconocimiento normal de resultados
```

---

## 9. Programacion de Proyecto

```
¿Como se debe programar el proyecto?
│
├── ¿Hay una FECHA LIMITE fija de entrega?
│   │
│   └── SI → BACKWARD SCHEDULING (desde la fecha fin hacia atras)
│             SAP calcula la fecha de inicio necesaria
│             Configuracion: TSCHD = 'B' en perfil de red
│             Muestra la fecha de inicio minima necesaria
│
├── ¿La fecha de INICIO esta fija y se calcula la fecha fin?
│   │
│   └── SI → FORWARD SCHEDULING (desde inicio hacia adelante)
│             SAP calcula la fecha de fin posible
│             Configuracion: TSCHD = 'F' en perfil de red
│
├── ¿Existen DEPENDENCIAS entre actividades?
│   │
│   ├── SI, SIMPLES (una actividad debe terminar para empezar otra)
│   │   └── Relacion FS (Finish-to-Start)
│   │       La mas comun, es el default
│   │
│   ├── SI, OVERLAPPING (se solapan parcialmente)
│   │   └── Relacion FS con Lag negativo
│   │       O relacion SS (Start-to-Start) con lag positivo
│   │
│   └── NO (actividades independientes)
│       → Actividades paralelas sin relacion
│         Todas comienzan en la fecha de inicio de la red
│
└── ¿Se necesita NIVELACION de recursos?
    │
    ├── SI → Configurar capacidades en puestos de trabajo (CR01)
    │         CNS46 para ver sobrecarga de capacidad
    │         CN72 con nivelacion automatica
    │
    └── NO → Solo scheduling por fechas, sin considerar recursos
              Mas rapido, menos preciso
```

---

## 10. Stock de Proyecto vs. Consumo Directo

```
¿Como gestionar el material del proyecto?
│
├── ¿El material es MUY ESPECIFICO del proyecto?
│   (no puede usarse en otro proyecto)
│   │
│   └── SI → STOCK DE PROYECTO INDIVIDUAL (tipo especial Q)
│             Material separado fisicamente del stock normal
│             Visible en MMBE como stock especial Q + numero WBS
│             Proceso: Pedido con WBS → Mov. 101 → Stock Q → Mov. 221
│             Ventaja: Trazabilidad completa
│             Desventaja: Mas complejo de gestionar
│
├── ¿El material esta en stock GENERAL y se consume desde ahi?
│   │
│   └── SI → CONSUMO DESDE STOCK NORMAL
│             Reserva con WBS (MB21, Mov. 281)
│             MIGO Mov. 261 o 281 para salida con imputacion WBS
│             Ventaja: Simple
│             Desventaja: Sin separacion fisica
│
├── ¿El material se COMPRA exclusivamente para este proyecto?
│   │
│   └── SI → PEDIDO DIRECTO CON WBS (sin stock)
│             Pedido con imputacion WBS (tipo K o P)
│             No pasa por almacen: va directo a coste del WBS
│             Mov. 101 solo contra el WBS, no a stock
│             Ventaja: Sin gestion de stock
│             Mejor para: servicios, materiales de consumo directo
│
└── ¿El material requiere NUMERO DE SERIE vinculado al proyecto?
    │
    └── SI → STOCK DE PROYECTO + NUMERO DE SERIE
              Combinacion de gestion de lotes + stock Q
              Trazabilidad completa item por item
              Uso: Equipos industriales, instrumentos, etc.
```

---

## 11. Cierre de Proyecto

```
¿Como se cierra correctamente un proyecto?
│
├── PASO 1: ¿Todas las actividades estan confirmadas?
│   ├── NO → Confirmar actividades pendientes (CN25)
│   │         O cancelar actividades no ejecutadas
│   └── SI → Continuar
│
├── PASO 2: ¿Hay pedidos/solicitudes abiertas?
│   ├── SI → Cerrar pedidos (ME22N) o eliminar si no proceden
│   └── NO → Continuar
│
├── PASO 3: ¿Hay stock de proyecto pendiente?
│   ├── SI → Devolver al almacen (Mov. 412Q) o dar de baja (Mov. 221)
│   └── NO → Continuar
│
├── PASO 4: ¿Se ha ejecutado el Analisis de Resultados final?
│   ├── Aplica (proyecto con ingresos) → KKA2 en periodo final
│   └── No aplica (proyecto interno) → Omitir
│
├── PASO 5: ¿Se ha calculado el Overhead final?
│   ├── Aplica → CJ44 / CJA1
│   └── No aplica → Omitir
│
├── PASO 6: ¿Liquidacion total ejecutada?
│   ├── NO → CJ88 modo "Liquidacion total" hasta saldo 0
│   └── SI → Continuar
│
├── PASO 7: Cambiar status a TECO
│   └── CJ02 → Editar → Status → Completar tecnicamente
│             O CJCO para masivo
│
├── PASO 8: Verificar saldo = 0 en todos los WBS
│   └── S_ALR_87013532 o CJI3 — no debe haber saldo
│
└── PASO 9: Status CLSD (Cerrar)
    └── CJ02 → Editar → Status → Cerrar
              Irreversible en produccion
              Archivar documentacion del proyecto
```

---

## 12. Seleccion de Perfil de Proyecto

```
¿Que perfil de proyecto asignar?
│
├── ¿Proyecto de INGENIERIA (EPC, construccion, infraestructura)?
│   └── Perfil: PEPC o PCAP
│               Red compleja, scheduling critico, CAPEX
│               Liquidacion a AuC
│               Control de disponibilidad estricto
│
├── ¿Proyecto de SERVICIOS (consulting, IT, mantenimiento)?
│   └── Perfil: PSER o PSVC
│               WBS simple, facturacion SD activa
│               Resource-Related Billing o Milestone Billing
│               Sin liquidacion a AuC
│
├── ¿Proyecto de I+D?
│   └── Perfil: PIDE o PRND
│               Analisis de resultados especifico para I+D
│               Posible split OPEX/CAPEX durante el proyecto
│               Reglas de capitalizacion selectiva
│
├── ¿Proyecto de MANTENIMIENTO MAYOR (parada, overhaul)?
│   └── Perfil: PMNT
│               Integracion PM obligatoria
│               WBS vinculado a objetos tecnicos
│               Liquidacion a CC de mantenimiento
│
└── ¿Proyecto SIMPLE (sin red, sin programacion detallada)?
    └── Perfil: PSIM o PGEN
              Solo WBS, sin red obligatoria
              Presupuesto global
              Liquidacion directa a CC
```
