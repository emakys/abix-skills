# Handling Units (HU)

## Concepto de Handling Unit

Una **Handling Unit (HU)** es la unidad fisica de embalaje en EWM que representa un contenedor fisico junto con su contenido. Combina informacion de embalaje, contenido, peso, volumen y trazabilidad en un objeto unico identificado por un numero SSCC18 (Serial Shipping Container Code de 18 digitos segun estandar GS1).

Cada HU tiene:
- Identificador unico: SSCC18 o numero interno EWM
- Tipo de material de embalaje (pallet, caja, contenedor)
- Contenido: materiales, cantidades, lotes, numeros de serie
- Atributos fisicos: peso bruto/neto, volumen, dimensiones
- Estado: abierta, cerrada, bloqueada

## Tipos de HU

### Segun material de embalaje
- **Pallet (PALL)**: europallet, US pallet, half pallet
- **Carton (CART)**: caja corrugada, caja de carton
- **Contenedor (CONT)**: ISO 20ft, 40ft, refrigerado
- **Bolsa (BAG)**, **Caja (BOX)**, **Tambor (DRUM)**

### Segun composicion de contenido
- **HU homogenea**: un unico material/lote en su interior
- **HU mixta**: multiples materiales o lotes combinados
- **HU vacia**: material de embalaje sin contenido registrado

### Segun estructura jerarquica
- **HU de nivel superior (outer HU)**: pallet que contiene cajas
- **HU anidada (inner HU)**: caja contenida dentro del pallet
- **HU multinivel**: hasta N niveles de anidamiento soportados

## Datos Maestros

### Tipos de HU (/SCWM/HUT)
Configuracion en: `/SCWM/HUT` o IMG > EWM > Master Data > Handling Units > Define HU Types

Atributos del tipo de HU:
- Material de embalaje asignado
- Peso maximo / Volumen maximo
- Dimensiones maximas (largo, ancho, alto)
- Indicador de apilado (stacking factor)
- Permite contenido mixto: si/no
- Permite HU anidadas: si/no

### Especificaciones de embalaje (/SCWM/PACK_SPEC)
Las **packaging specifications** definen las reglas automaticas para empacar:
- Material → tipo de embalaje → cantidad por HU
- Jerarquia de embalaje (nivel 1, nivel 2...)
- Tolerancia de llenado (fill rate minimo/maximo)
- Instrucciones de apilado y orientacion
- Activacion: por cliente, ruta, warehouse order

Transaccion: `/SCWM/PACK_SPEC`
Tablas: `/SCWM/PACKSPEC`, `/SCWM/PACKSPECI`

## Creacion de HU

### Durante el proceso de empaque (Packing)
1. Apertura de HU: seleccion de tipo de embalaje
2. Asignacion de contenido: scan de materiales o HU internas
3. Verificacion de limites (peso, volumen, cantidad)
4. Cierre de HU: impresion de etiqueta SSCC
5. Anidamiento opcional en HU de nivel superior

Transaccion de empaque: `/SCWM/PACK`
En Fiori: app "Pack Handling Units"

### Durante recepcion (Goods Receipt)
- HU creadas automaticamente al confirmar WT de entrada
- Basadas en packaging spec o entrada manual
- Asociadas al inbound delivery item
- Numero SSCC leido del proveedor o generado internamente

## Movimiento de HU completas

### Putaway de HU completa
- WT generado para mover la HU entera (no contenido individual)
- Bin de destino determinado por storage type search sequence
- Un solo WT mueve toda la HU con su contenido
- Mas eficiente que mover pieza a pieza

### Picking de HU completa
- Full HU pick: se retira la HU completa del bin
- Partial HU pick: se transfiere contenido a nueva HU
- Configuracion en warehouse process type: HU-relevant

### Movimientos ad-hoc de HU
Transaccion: `/SCWM/MON` (Warehouse Monitor) > HU Management
- Mover HU a otro bin
- Transferir contenido entre HU
- Dividir/consolidar HU

## HU en Serialization

Los numeros de serie se gestionan a nivel de HU cuando:
- El material requiere serial number management
- Configuracion: Serial Number Profile asignado al material
- Cada unidad dentro de la HU tiene su serial unico
- Trazabilidad completa: serial → HU → bin → storage type

## Tablas Principales

| Tabla | Descripcion |
|-------|-------------|
| `/SCWM/HUHDR` | Cabecera de HU (numero, tipo, estado, peso, volumen) |
| `/SCWM/HUITEM` | Items de HU (materiales, cantidades, lotes) |
| `/SCWM/HU_HIST` | Historial de movimientos de HU |
| `/SCWM/PACK_SPEC` | Especificaciones de embalaje |
| `/SCWM/PACKSPEC` | Cabecera packaging spec |
| `/SCWM/PACKSPECI` | Items packaging spec |
| `/SCWM/HUHDR_A` | HU archivadas |
| `/SCWM/HUTO` | Tipos de HU (configuracion) |

## Consultas MCP Recomendadas

```
-- Ver HU activas en un almacen
GetWarehouseOrder: buscar HU por bin o storage type

-- Herramientas MCP utiles para HU:
SearchObject: HUTYP (Handling Unit Type)
GetObjectSource: /SCWM/HU_TOOLS (function group utilitario)
ReadClass: ZCL_EWM_HU_* (clases custom de HU)
ReadInterface: ZIF_EWM_HU_* (interfaces de HU)
```

### Queries tipicas via MCP SAP ADT
- `SearchObject` tipo `DOMA` en namespace `/SCWM/` para dominios de estado HU
- `GetFunctionGroup` de `/SCWM/HU_TOOLS` para ver funciones de manipulacion
- `ReadClass` de `/SCWM/CL_HU*` para logica de negocio de HU

## Configuracion Clave en IMG

```
IMG > Extended Warehouse Management
  > Master Data
    > Handling Units
      > Define Handling Unit Types
      > Define Allowed HU Types per Storage Type
      > Packaging Specifications
  > Goods Receipt Process
    > Handling Units in GR
  > Goods Issue Process
    > Handling Units in GI
```

## Mejores Practicas S/4HANA 2023

- Usar SSCC18 estandar GS1 para interoperabilidad con proveedores
- Definir packaging specs para automatizar empaque en salida
- Configurar limites de peso/volumen en tipos de HU para evitar sobrecarga
- Activar HU management solo en storage types que lo requieran (evita overhead)
- Para RF/Fiori scanning: configurar barcode types en HU type settings
