# Estructura Organizativa SD

## Jerarquia

```
Mandante (Client)
+-- Area control credito (Credit Control Area) [T014]
+-- Sociedad (Company Code) [T001]
|   +-- Org. ventas (Sales Organization) [TVKO]
|       +-- Canal distribucion (Distribution Channel) [TVTW]
|       +-- Sector / Division [TSPA]
|       = Area de ventas = Org + Canal + Sector
|           +-- Oficina ventas (Sales Office) [TVKBZ]
|           |   +-- Grupo vendedores (Sales Group) [TVKGR]
|           +-- Puesto expedicion (Shipping Point) [TVSTZ]
|               (asignado a Centro/Planta)
```

## Concepto clave: Area de Ventas

```
Area de ventas = Org ventas + Canal distribucion + Sector

Es la combinacion que determina:
  - Datos maestros del cliente (KNVV)
  - Datos maestros del material (MVKE)
  - Condiciones de precio
  - Determinacion de cuenta (VKOA)
  - Reports y estadisticas

Ejemplo:
  Org ventas: 1000 (Mexico)
  Canal: 10 (Venta directa) / 20 (Distribuidor)
  Sector: 01 (Materiales) / 02 (Servicios)
  → 4 areas de ventas posibles
```

## Asignaciones clave

| Asignacion | Tabla | Transaccion | Obligatoria |
|------------|-------|-------------|:-----------:|
| Org ventas → Sociedad | TVKO-BUKRS | SPRO/OVX3 | Si |
| Org ventas → Canal distribucion | TVKOV | SPRO/VOR1 | Si |
| Org ventas → Sector | TVKOS | SPRO/VOR2 | Si |
| Puesto expedicion → Centro | VSTEL→WERKS | SPRO/OVXD | Si |
| Centro → Sociedad | T001K | OX18 | Si (de MM) |
| Area credito → Sociedad | T001-KKBER | OB38 | Si (si usa credito) |
| Org ventas → Oficina ventas | TVKBZ | SPRO | Opcional |
| Oficina ventas → Grupo vendedores | TVKGR | SPRO | Opcional |

## Puesto de expedicion (Shipping Point)

```
Determina DESDE DONDE se envia la mercancia.
Se asigna al CENTRO (planta), no a la org ventas.

Determinacion automatica en el pedido:
  Condicion expedicion (MVKE-VSBED) + Grupo carga (MARA-LADGR) + Centro → Shipping Point

Config: SPRO → SD → Shipping → Basic Shipping Functions →
  Shipping Point Determination → Assign Shipping Points (OVLK)
```

## Queries MCP

```sql
-- Estructura completa del cliente
SELECT TVKO.VKORG, TVKOT.VTEXT, TVKO.BUKRS, T001.BUTXT
FROM TVKO
JOIN TVKOT ON TVKO.VKORG = TVKOT.VKORG AND TVKOT.SPRAS = 'E'
JOIN T001 ON TVKO.BUKRS = T001.BUKRS

-- Canales por org ventas
SELECT TVKOV.VKORG, TVKOV.VTWEG, TVTWT.VTEXT
FROM TVKOV
JOIN TVTWT ON TVKOV.VTWEG = TVTWT.VTWEG AND TVTWT.SPRAS = 'E'
WHERE TVKOV.VKORG = '{org}'

-- Sectores por org ventas
SELECT TVKOS.VKORG, TVKOS.SPART, TSPAT.VTEXT
FROM TVKOS
JOIN TSPAT ON TVKOS.SPART = TSPAT.SPART AND TSPAT.SPRAS = 'E'
WHERE TVKOS.VKORG = '{org}'

-- Puestos expedicion por centro
SELECT VSTEL, VTEXT FROM TVSTT WHERE SPRAS = 'E'

-- Areas de ventas activas con clientes
SELECT VKORG, VTWEG, SPART, COUNT(*) as NUM_CLIENTES
FROM KNVV GROUP BY VKORG, VTWEG, SPART ORDER BY NUM_CLIENTES DESC

-- Oficinas de ventas
SELECT VKBUR, BEZEI FROM TVKBT WHERE SPRAS = 'E'
```

## Decisiones de diseno

### Org ventas: una o varias por sociedad
- **1 org ventas = 1 sociedad**: Simple, recomendado para una empresa
- **N org ventas = 1 sociedad**: Multiples lineas de negocio independientes
- **1 org ventas = N sociedades**: Intercompany, venta centralizada cross-company
- **Org ventas referenciada**: hereda datos maestros de otra org (comparte precios, materiales)

### Canales de distribucion
| Canal | Uso tipico |
|-------|-----------|
| 10 | Venta directa a cliente final |
| 20 | Venta a distribuidores/mayoristas |
| 30 | Venta online / e-commerce |
| 40 | Intercompany |
| 50 | Exportacion |

### Canal/Sector de referencia
```
Evita duplicar datos maestros para cada combinacion canal+sector.
Ejemplo:
  Canal 10 (directo) → referencia a canal 10 (datos propios)
  Canal 20 (distribuidor) → referencia a canal 10 (comparte datos)

Config: SPRO → SD → Master Data → Define Common Distribution Channels/Divisions
Efecto: material extendido en canal 10 se ve automaticamente en canal 20
```
