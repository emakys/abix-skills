# Tablas de Customizing y Datos — SAP JVA

## 1. Maestro y Customizing JVA

| Tabla (orientativa) | Descripción | Notas |
|---|---|---|
| `T8J1` | Maestro de Ventures | Clave, nombre, indicador de operador, moneda |
| `T8J2` | Equity Groups por Venture (cabecera, con vigencia) | `VALFR`/`VALTO` clave para reparto histórico |
| `T8J2P` (orientativo) | Detalle de partners y % dentro de un Equity Group | **Confirmar nombre exacto en el sistema real** — puede variar por release/parche |
| `T8J3` | Catálogo de Recovery Indicators | Código + descripción; comportamiento asociado vive en customizing adicional |
| `GJUBI` | Líneas de detalle de cutback/billing por partner | Tabla transaccional central para reporting JVA |
| `GJHIST` | Historial de corridas de cutback (estado por venture/periodo) | Control de re-ejecuciones |

## 2. Tablas Estándar CO/FI Extendidas con Atributo JV

| Tabla | Uso en JVA |
|---|---|
| `CSKS` | Centro de coste — campos extendidos `VENTURE`/`EGRUP`/`RECIND` (orientativos) |
| `AUFK` | Orden interna — mismos campos extendidos cuando la orden es JV-relevante |
| `PRPS` | Elemento WBS — atributo JV cuando el proyecto/AFE es compartido |
| `ACDOCA` | Universal Journal — línea de detalle real; en S/4HANA puede contener campos custom/append con el atributo JV heredado del objeto CO |

## 3. Tablas Estándar de Referencia (No Exclusivas de JVA)

| Tabla | Uso |
|---|---|
| `T001` | Sociedades |
| `TKA02` | Sociedad → Área de Controlling |
| `T100` | Textos de mensajes (diagnóstico de errores) |
| `LFA1`/Business Partner | Maestro de partner cuando se modela como acreedor/BP |

## 4. Nota sobre Nombres de Tabla No Confirmados

Varias tablas de detalle de JVA (especialmente las de % de partner dentro de Equity Group, y las
específicas de cash calls) tienen nombres que **varían entre releases y niveles de parche**. Antes
de construir un reporte productivo o un desarrollo custom sobre una tabla no confirmada en esta
guía con 100% de certeza, verifica con `SE11`/`GetWhereUsed` en el sistema real del cliente.

## 5. Consultas MCP de Referencia Rápida

```sql
-- Ventures
SELECT venture, vname, opind, waers FROM t8j1

-- Equity Groups de un venture
SELECT venture, egrup, valfr, valto FROM t8j2 WHERE venture = '{venture}'

-- Recovery Indicators
SELECT recind, ritxt FROM t8j3

-- Detalle de cutback/billing
SELECT venture, egrup, recind, partner, belnr, gjahr, wkgbtr FROM gjubi WHERE venture = '{venture}'

-- Historial de corridas
SELECT venture, gjahr, monat, runid, status FROM gjhist WHERE venture = '{venture}'
```
