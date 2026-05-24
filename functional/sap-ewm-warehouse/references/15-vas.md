# Value-Added Services (VAS) — Servicios de Valor Agregado

## Concepto General

Los **Value-Added Services (VAS)** en EWM son servicios adicionales realizados sobre las mercancias durante su procesamiento en el almacen, mas alla del simple picking, packing y envio. Representan actividades que agregan valor al producto o a la experiencia del cliente sin modificar el producto en su esencia (eso seria manufactura).

En S/4HANA 2023, EWM gestiona los VAS como **ordenes de servicio de almacen** independientes que se vinculan a deliveries de entrada o salida. El sistema puede determinar automaticamente que VAS aplicar basandose en reglas configuradas.

Los VAS son comunes en:
- Logistica de retail (etiquetado de precio, display packaging)
- Industria farmaceutica (serialization, leaflets)
- Electronica (bundle packs, configuracion)
- Devolucion y reparacion (rework, refurbishment)
- E-commerce (gift wrapping, personalizacion)

Transaccion: `/SCWM/VAS` o Warehouse Monitor > VAS tab

## Tipos de VAS

### 1. Etiquetado (Labeling)
El VAS mas frecuente:
- Impresion y aplicacion de etiquetas de precio
- Etiquetas de origen / pais de fabricacion
- Etiquetas de seguridad / EAS (Electronic Article Surveillance)
- Etiquetas de serialization (SSCC, GS1-128)
- Etiquetas custom del cliente
- Etiquetas de peligrosidad (hazmat)

Resultado: el producto queda listo con el etiquetado correcto para el destino especifico

### 2. Kitting
Creacion de conjuntos a partir de componentes individuales:
- Ejemplo: "starter kit" = producto A + accesorio B + manual C en una caja
- El kitting en EWM es logistico (no modifica el material maestro)
- Se diferencia del kitting de produccion (PP) en que no genera ordenes de fabricacion
- Los componentes se descargan del inventario, el kit resultante se carga

### 3. Ensamblaje Ligero (Assembly / Light Assembly)
Actividades de ensamblaje simples sin ingenieria de produccion:
- Instalacion de piezas estandar (pilas, accesorios)
- Pre-montaje de displays o presentaciones especiales
- Combinacion de productos en packaging especial
- No requiere orden de produccion PP, se gestiona 100% en EWM

### 4. Empaque Regalo (Gift Wrapping)
Para retail y e-commerce:
- Envoltura en papel regalo
- Inclusion de tarjeta personalizada
- Packaging premium (cajas especiales, cintas)
- Configuracion: determinado por indicador en orden de venta

### 5. Control de Calidad (Quality Check)
VAS de verificacion antes del envio:
- Inspeccion visual de producto
- Verificacion de fechas de caducidad
- Conteo de unidades en empaque
- Pruebas funcionales basicas
- Registro del resultado (OK / NOK) en la orden VAS
- Integrado con QM para casos que requieran lote de inspeccion formal

### 6. Rework (Reacondicionamiento)
Para devolucion y productos defectuosos:
- Limpieza y reacondicionamiento de devueltos
- Cambio de embalaje danado
- Reparacion menor de productos
- Re-etiquetado de productos con embalaje incorrecto
- Resultado: producto pasa de "bloqueado" a "libre utilizable"

### 7. Personalizacion (Customization)
Para pedidos especiales:
- Grabado de nombre o mensaje en producto
- Configuracion de software pre-instalado
- Ajuste de parametros segun especificacion del cliente
- Inclusion de accesorios especificos por mercado

## Creacion de Ordenes VAS

### Creacion Automatica
El sistema crea ordenes VAS automaticamente basandose en:
1. Reglas de determinacion de actividades VAS configuradas
2. Condiciones en el delivery (cliente, material, ruta, pais destino)
3. Indicadores en el material master (VAS-relevant)
4. Instrucciones especiales en la orden de venta (SD)

### Creacion Manual
- Via `/SCWM/VAS` > Create VAS Order
- Vinculando al inbound o outbound delivery correspondiente
- Util para requerimientos ad-hoc o excepciones

### Estructura de la Orden VAS
```
VAS Order (cabecera)
  ├── Delivery reference (inbound o outbound)
  ├── Material / HU afectada
  ├── VAS Activity list
  │     ├── Activity 1: Labeling (tipo, cantidad, instrucciones)
  │     ├── Activity 2: Quality Check (criterios)
  │     └── Activity 3: Packing (embalaje destino)
  ├── Work Center asignado
  ├── Tiempo estimado
  └── Estado (Created / In Process / Confirmed)
```

## Determinacion de Actividades VAS

La determinacion define **que VAS aplicar** para cada combinacion de condiciones:

### Condiciones de determinacion (ejemplo):
- Cliente → Etiqueta precio especifica
- Pais de destino → Etiqueta idioma local
- Canal de venta → Empaque regalo (si e-commerce = true)
- Categoria de material → Control calidad (si farmaceutica)

Configuracion: IMG > EWM > Value-Added Services > Activity Determination

Tablas: `/SCWM/VASACT` (actividades), `/SCWM/VASDET` (determinacion)

## Work Centers de VAS

Los VAS se ejecutan en **work centers** especificamente designados dentro del almacen:

- Ubicaciones fisicas equipadas para el tipo de VAS (mesas de etiquetado, zonas de rework)
- Cada work center tiene su capacidad (numero de operarios, throughput)
- El sistema asigna la orden VAS al work center disponible
- Monitorizacion de carga de trabajo por work center en `/SCWM/MON`

Configuracion: `/SCWM/WC` (Work Center Master Data)
Campos clave: warehouse number, work center ID, capacity, VAS types allowed

## Ejecucion y Confirmacion de VAS

### Ejecucion via RF
1. Operario accede al menu VAS en dispositivo RF
2. Escanea la HU o delivery a procesar
3. Sistema muestra lista de actividades VAS a realizar
4. Operario confirma cada actividad completada
5. Registro de tiempo real de ejecucion (para costeo)

### Ejecucion via Fiori
- App "Perform Value-Added Services" (Fiori EWM)
- Lista de ordenes VAS asignadas al operario o work center
- Confirmacion con captura de datos de resultado

### Confirmacion y estado final
- Actividad confirmada → estado "Done"
- Si hay resultado NOK en control calidad → se bloquea la mercancia
- Una vez todas las actividades completadas → orden VAS cierra automaticamente
- El delivery puede continuar su proceso (picking, packing, GI)

## VAS en Proceso Inbound vs Outbound

### VAS en Recepcion (Inbound)
- Se ejecuta despues del goods receipt y antes del putaway
- Ejemplos: inspeccion de calidad, quitar embalaje de transporte, re-etiquetar
- Staging area de inbound se configura como zona de VAS
- El putaway se demora hasta que el VAS esta completo

### VAS en Salida (Outbound)
- Se ejecuta durante el packing / antes del GI
- Ejemplos: etiquetado de destino, gift wrapping, bundle final
- Staging area de outbound o zona de packing especifica
- El GI se bloquea hasta confirmacion de VAS

## Costeo de VAS

En S/4HANA 2023, los costos de VAS pueden ser:

### Captura de costos
- Tiempo de ejecucion: registrado en la confirmacion de VAS
- Material consumido: embalajes, etiquetas → movimiento de inventario
- Tarifa de work center: coste/hora configurada

### Integracion con CO
- Los costos de VAS se cargan a un **orden interno CO** o **centro de coste**
- Repercusion al cliente: via condicion de precio en SD (surcharge por VAS)
- Report de rentabilidad: coste VAS vs facturacion adicional al cliente

## Integracion con Produccion (PP)

Para VAS complejos que requieren PP:
- EWM detecta que el VAS no puede hacerse en almacen (proceso de fabricacion real)
- Se genera una orden de produccion PP desde EWM via integracion
- El material vuelve al almacen como producto transformado
- Muy inusual: solo para casos en que el VAS cambia el material master (nuevo numero de material)

Para kitting logistico (sin cambio de material master): no se necesita PP, EWM lo gestiona solo.

## Tablas Principales

| Tabla | Descripcion |
|-------|-------------|
| `/SCWM/VASORD` | Cabecera ordenes VAS |
| `/SCWM/VASORDI` | Items / actividades de ordenes VAS |
| `/SCWM/VASACT` | Catalogo de actividades VAS |
| `/SCWM/VASDET` | Reglas de determinacion de actividades |
| `/SCWM/WC` | Master data de work centers |
| `/SCWM/WCACT` | Actividades permitidas por work center |
| `/SCWM/VASWC` | Asignacion VAS → Work Center |

## Consultas MCP Recomendadas

```
-- Explorar objetos VAS en EWM
SearchObject: tipo CLAS, nombre "/SCWM/CL_VAS*" → clases de VAS
ReadClass: /SCWM/CL_VAS_CTRL → controlador principal de VAS
SearchObject: tipo FUGR, nombre "/SCWM/VAS*" → function groups

-- Work centers
SearchObject: tipo TABL, nombre "/SCWM/WC" → estructura work center master

-- BAdIs de extension VAS
SearchObject: tipo DEVC, nombre "/SCWM/VAS"
-- BAdI: /SCWM/EX_VAS_DETERMINATION → logica custom de determinacion VAS
-- BAdI: /SCWM/EX_VAS_CONFIRM → logica post-confirmacion VAS

-- Explorar integracion con delivery
GetFunctionGroup: /SCWM/VAS_DLV → funciones de integracion VAS-delivery
```

## Configuracion IMG

```
IMG > Extended Warehouse Management
  > Value-Added Services
    > Activate Value-Added Services
    > Define VAS Activity Types
    > Define VAS Determination Rules
    > Assign VAS to Storage Types / Staging Areas
    > Configure Work Centers for VAS
    > Define VAS Warehouse Process Types
    > Cost Settings for VAS
      > Assign Cost Centers to VAS Activities
      > Define Rates per Work Center
```

## Mejores Practicas S/4HANA 2023

- Modelar los VAS como actividades especificas y granulares (no un VAS generico "especial")
- Configurar la determinacion automatica en lugar de depender de creacion manual para VAS frecuentes
- Dimensionar correctamente los work centers: throughput de VAS puede ser el cuello de botella del almacen
- Usar RF/Fiori en los work centers para captura de tiempo real (no papel)
- Medir KPI de VAS: tiempo medio por actividad, % de ordenes con NOK en quality check, utilizacion de work center
- Para kitting: definir claramente si es logistico (EWM) o productivo (PP) antes de implementar
- Integrar el surcharge VAS en pricing SD para recuperar el costo de servicio al cliente
- Usar BAdI `/SCWM/EX_VAS_DETERMINATION` para reglas complejas que no caben en la configuracion estandar (ej. VAS diferente segun temporada o campana promotora)
