# Tablas de Customizing y Datos — SAP RE-FX

## 1. Jerarquía de Objetos Inmobiliarios (GPO)

| Tabla (orientativa) | Descripción | Notas |
|---|---|---|
| `VIBDBE` | Business Entity (maestro) | Clave, nombre, sociedad |
| `VIBDPR` | Property (terreno) | Vinculada a Business Entity |
| `VIBDGB` | Building (edificio) | Vinculada a Property |
| `VIBDOB` | Rental Object (unidad de renta/terreno/espacio) | Vinculada a Building/Property; incluye superficie, tipo de uso |
| `VIBDIO` | Architectural Object (medición de superficie) | Vinculado a Rental Object |

**Confirmar nombres exactos de campo en el sistema real** — son consistentes conceptualmente entre
releases, pero la implementación técnica exacta (vistas vs tablas base, campos de extensión) puede
variar.

## 2. Contratos y Condiciones

| Tabla | Descripción | Notas |
|---|---|---|
| `VICNCN` | Cabecera de contrato (lease-out, lease-in, general) | Vigencia, tipo, sociedad |
| `VICNCND` | Condiciones del contrato (renta, gastos comunes, depósito) | Reutiliza técnica de condiciones tipo pricing |
| `VICNCNP` (orientativo) | Socios del contrato (inquilino, garante, arrendador externo) | Confirmar nombre exacto en el sistema real |

## 3. Liquidación de Gastos Comunes

| Tabla (orientativa) | Descripción | Notas |
|---|---|---|
| `VISCABRKR` (orientativo) | Historial/estado de corridas de liquidación | Confirmar nombre real — varía por release |
| Detalle de Grupo de Participación (nombre orientativo) | Miembros y factores de reparto | Confirmar tabla exacta con `GetWhereUsed`/`SE11` |

## 4. Customizing General RE-FX (Familia TIVxx)

| Área | Tabla (familia) |
|---|---|
| Tipos de contrato | `TIVVT` (orientativo) |
| Tipos de uso de Rental Object | `TIV05` (orientativo) |
| Perfiles y parámetros generales RE-FX | `TIVxx` (varias vistas de customizing) |
| Tipos de condición (reutiliza técnica pricing) | `T685T` (`KAPPL='RE'`) |

## 5. Tablas Estándar de Referencia (No Exclusivas de RE-FX)

| Tabla | Uso |
|---|---|
| `T001` | Sociedades |
| `TKA02` | Sociedad → Área de Controlling |
| `T100` | Textos de mensajes (diagnóstico de errores) |
| `ANLA` | Maestro de activos fijos (inmuebles propios y ROU assets) |
| `ACDOCA` | Universal Journal — contabilización periódica de renta/gastos comunes |
| Business Partner (tablas centrales BP) | Inquilinos, arrendadores externos, garantes |

## 6. Nota sobre Nombres de Tabla No Confirmados

Varias tablas de detalle de RE-FX (especialmente las de historial de corridas de liquidación de
gastos comunes, y las de detalle de Grupo de Participación) tienen nombres que **pueden variar
entre releases y niveles de parche**. Antes de construir un reporte productivo o desarrollo custom
sobre una tabla no confirmada con 100% de certeza en esta guía, verificar con `SE11`/`GetWhereUsed`
en el sistema real del cliente.

## 7. Consultas MCP de Referencia Rápida

```sql
-- Business Entities
SELECT swenr, swename, bukrs FROM vibdbe

-- Rental Objects de un Building
SELECT meinh, mebez, nutza, qmnut FROM vibdob WHERE gebaeude = '{building}'

-- Contratos vigentes
SELECT vertrag, vertnr, verttyp, vbegdat, venddat FROM vicncn WHERE bukrs = '{sociedad}'

-- Condiciones de un contrato
SELECT vertrag, kschl, kbetr, waers, zeinh, datab, datbi FROM vicncnd WHERE vertrag = '{contrato}'

-- Tipos de condición configurados
SELECT kschl, vtext FROM t685t WHERE spras = 'S' AND kappl = 'RE'
```
