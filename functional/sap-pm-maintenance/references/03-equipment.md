# Equipos (Equipment Master) — SAP PM S/4HANA 2023

## 1. Concepto

Un **equipo** en SAP PM es un objeto técnico individual que puede ser mantenido de forma independiente. Representa una unidad física concreta: una bomba, un motor, un vehículo, un instrumento de medición, etc.

Características fundamentales:
- Tiene un número único en el sistema (EQUNR).
- Puede instalarse y desinstalarse en ubicaciones técnicas.
- Acumula historial de mantenimiento, costes y mediciones a lo largo de su vida útil.
- Puede vincularse a un **activo fijo** de FI-AA para contabilización.
- Admite clasificación, BOM, planes de mantenimiento y puntos de medida propios.
- En S/4HANA, se integra con SAP Intelligent Asset Management (IAM) y Asset Central.

---

## 2. Categorías de Equipo

La **categoría de equipo** controla qué vistas y campos están disponibles en el maestro de equipo.

### Categorías Estándar

| Categoría | Descripción                        | Uso Típico                               |
|-----------|------------------------------------|------------------------------------------|
| M         | Máquina / Equipo de producción     | Bombas, motores, compresores             |
| P         | Equipo de planta genérico          | Equipos industriales generales           |
| Q         | Equipo de QM (calibración)         | Instrumentos de medición y calibración   |
| R         | Vehículo / Flota                   | Camiones, vehículos de planta            |
| E         | Equipo eléctrico                   | Paneles, transformadores, cables         |
| I         | Instrumentación                    | Sensores, transmisores, analizadores     |
| L         | Línea de comunicación              | Redes, cableado de datos                 |

### Configuración de Categorías

**SPRO:** IMG → PM → Datos maestros técnicos → Equipos → Definir categorías de equipos

Parámetros por categoría:
- Vistas disponibles (General, Organización, Estructura, Clasificación, etc.)
- Campos obligatorios
- Rango de números
- Tipos de objeto técnico permitidos

---

## 3. Creación del Equipo

**Transacción:** IE01 (crear), IE02 (modificar), IE03 (visualizar)

**Fiori Apps:**
- F1613 — Create Equipment
- F1614 — Manage Equipment
- F2140 — Equipment and Technical Objects (vista integrada)

### Datos de Cabecera

| Campo   | Descripción                               | Obligatorio |
|---------|-------------------------------------------|-------------|
| EQUNR   | Número de equipo (externo o automático)   | Sí          |
| EQTYP   | Categoría de equipo                       | Sí          |
| EQKTX   | Descripción del equipo                    | Sí          |
| MATNR   | Material del equipo (referencia MM)       | No          |
| SERGE   | Número de serie                           | Opcional    |
| HERST   | Fabricante                                | Recomendado |
| HERLD   | País del fabricante                       | Opcional    |
| TYPBZ   | Modelo/Tipo del fabricante                | Recomendado |
| BAUJJ   | Año de construcción                       | Recomendado |
| BAUMM   | Mes de construcción                       | Opcional    |

---

## 4. Vistas del Maestro de Equipo

### 4.1 Pestaña General

Contiene los datos técnicos básicos:
- Descripción completa
- Categoría y tipo de objeto técnico
- Fabricante, modelo, año de construcción
- Garantía del equipo (fecha inicio/fin, tipo de garantía)
- Indicadores de mantenimiento
- Puesto de trabajo responsable

**Indicadores de mantenimiento:**
- `IPLKZ`: Indicador de planificación preventiva (activo/inactivo)
- `INACT`: Equipo inactivo (excluido de listados de trabajo)

### 4.2 Pestaña Localización

| Campo  | Descripción                              |
|--------|------------------------------------------|
| TPLNR  | Ubicación técnica donde está instalado   |
| SWERK  | Centro de emplazamiento                  |
| IWERK  | Centro de planificación mantenimiento    |
| INGRP  | Grupo planificador responsable           |
| ARBPL  | Puesto de trabajo responsable            |
| RAUMN  | Sala / Localización dentro del edificio  |
| STORT  | Localización de almacenamiento           |

### 4.3 Pestaña Organización

| Campo  | Descripción                   |
|--------|-------------------------------|
| BUKRS  | Sociedad                      |
| KOSTL  | Centro de coste               |
| PRCTR  | Profit Center                 |
| GSBER  | Área de negocio               |
| ANLN1  | Número de activo fijo (FI-AA) |
| ANLN2  | Subposición de activo fijo    |
| KOKRS  | Área de controlling           |

### 4.4 Pestaña Estructura

Muestra la posición del equipo en la jerarquía:
- UT superior donde está instalado
- Equipos superiores/inferiores (jerarquía de equipos)
- Sub-equipos instalados en este equipo

### 4.5 Pestaña Clasificación

Permite asignar clases y características para búsqueda avanzada.

Objeto de clasificación: `E` (Equipment)

### 4.6 Pestaña Número de Serie

Para equipos con número de serie gestionados:

| Campo  | Descripción                             |
|--------|-----------------------------------------|
| MATNR  | Material al que pertenece el número de serie |
| SERNR  | Número de serie                         |
| SERGE  | Perfil de número de serie               |

La gestión de número de serie vincula el equipo con el módulo MM (Gestión de Materiales) y permite rastrear movimientos de inventario.

### 4.7 Pestaña Garantía

| Campo   | Descripción                          |
|---------|--------------------------------------|
| GWLDT   | Fecha inicio garantía                |
| GWLEN   | Fecha fin garantía                   |
| GWLNR   | Tipo de garantía                     |
| HERSTGWL| Garantía del fabricante              |

---

## 5. Jerarquía de Equipos

Los equipos pueden estructurarse en una jerarquía padre-hijo independiente de la jerarquía de UTs. Esto es útil para conjuntos complejos donde el conjunto y sus componentes son individualmente mantenibles.

Ejemplo:
```
TURBO-001 (Turbocompresor completo)
├── COMP-001 (Compresor)
├── MOTOR-001 (Motor de accionamiento)
└── LUBE-001 (Sistema de lubricación)
    ├── BOMBA-001 (Bomba de aceite)
    └── FILTRO-001 (Filtro de aceite)
```

La jerarquía se gestiona desde la pestaña **Estructura** del equipo.

**Tabla:** `EQUZ` — campo `HEQNR` (número de equipo superior)

---

## 6. Instalación y Desinstalación en Ubicación Técnica

### Instalar un equipo

1. IE02 → Pestaña Localización → Ingresar TPLNR
2. SAP crea un registro en `EQUZ` con la fecha de instalación
3. El equipo hereda los datos organizativos de la UT (si está configurado así)

Alternativamente desde la UT: IL02 → Pestaña Estructura → Instalar equipo

### Desinstalar un equipo

**Transacción:** IE4N — Desinstalar equipo de UT

Proceso:
1. Seleccionar equipo
2. Ingresar fecha de desinstalación
3. Opcionalmente especificar nuevo emplazamiento (almacén, planta diferente)

**Historial de instalaciones:** IE03 → Historial de instalaciones

---

## 7. BOM de Equipo (Bill of Materials)

Los equipos pueden tener una **lista de materiales** asociada que define los repuestos y componentes que los componen.

**Transacción:** IB01 (crear BOM de equipo), IB02 (modificar), IB03 (visualizar)

Uso en órdenes PM:
- Al crear una orden PM para un equipo con BOM, los componentes se proponen automáticamente (si está configurado).
- Facilita la planificación de repuestos necesarios.

**Tabla:** `MAST` (cabecera de lista de materiales), `STPO` (posiciones)

El uso del BOM para PM es **uso 4** (Plant Maintenance).

---

## 8. Vinculación con Activo Fijo (FI-AA)

La integración PM-FI/AA permite vincular un equipo de mantenimiento con su correspondiente activo contable.

### Campos de vinculación

| Campo en EQUI | Descripción               |
|---------------|---------------------------|
| ANLN1         | Número principal de activo|
| ANLN2         | Subposición de activo     |
| BUKRS         | Sociedad del activo       |

### Modos de vinculación

| Modo | Descripción                                                |
|------|------------------------------------------------------------|
| 0    | Sin vinculación (equipo PM sin activo fijo)                |
| 1    | Equipo PM sin activo fijo asignado (master data separados) |
| 2    | Equipo creado desde activo fijo (sincronización parcial)   |
| 3    | Equipo y activo fijo totalmente sincronizados              |

**SPRO:** IMG → PM → Datos maestros técnicos → Equipos → Definir enlace equipo-activo fijo

### Flujo de datos con modo sincronización completa (modo 3)

Al crear un activo fijo en FI-AA, SAP puede crear automáticamente el equipo PM correspondiente y mantenerlos sincronizados. Los cambios de valor (adiciones, retiros) se reflejan en ambos.

---

## 9. Tablas de Base de Datos — Equipos

### EQUI — Datos Maestros del Equipo

| Campo   | Descripción                          |
|---------|--------------------------------------|
| EQUNR   | Número de equipo                     |
| EQTYP   | Categoría de equipo                  |
| MATNR   | Material de referencia               |
| HERST   | Fabricante                           |
| TYPBZ   | Tipo/Modelo                          |
| BAUJJ   | Año construcción                     |
| SERGE   | Número de serie                      |
| INAKT   | Indicador equipo inactivo            |
| ERDAT   | Fecha de creación                    |

### EQKT — Textos del Equipo

| Campo   | Descripción                    |
|---------|--------------------------------|
| EQUNR   | Número de equipo               |
| SPRAS   | Idioma                         |
| EQKTX   | Descripción del equipo         |

### EQUZ — Datos de Instalación del Equipo

Registra la historia de instalaciones en UTs.

| Campo   | Descripción                          |
|---------|--------------------------------------|
| EQUNR   | Número de equipo                     |
| DATBI   | Fecha fin validez (99991231 = actual)|
| DATAB   | Fecha inicio validez (instalación)   |
| TPLNR   | UT donde está/estuvo instalado       |
| HEQNR   | Equipo superior (jerarquía)          |
| IWERK   | CPM                                  |
| SWERK   | Centro ejecutor                      |

### EQST — Status del Equipo

| Campo   | Descripción                     |
|---------|---------------------------------|
| EQUNR   | Número de equipo                |
| STSMA   | Perfil de status                |
| ESTAT   | Status del sistema activo       |
| ANWST   | Status del usuario activo       |

### ILOA — Datos Organizativos de Equipo/UT

(Tabla compartida con ubicaciones técnicas — ver referencia 02)

---

## 10. Consultas MCP — GetSqlQuery

### Listar todos los equipos de un centro con descripción y UT

```sql
SELECT a.equnr, b.eqktx, a.eqtyp, c.tplnr, a.iwerk, a.ingrp
FROM equi a
INNER JOIN eqkt b ON a.equnr = b.equnr AND b.spras = 'S'
LEFT JOIN equz c ON a.equnr = c.equnr AND c.datbi = '99991231'
WHERE a.swerk = '1000'
  AND a.inakt = ' '
ORDER BY a.equnr
```

### Obtener equipos vinculados a activo fijo

```sql
SELECT a.equnr, b.eqktx, d.anln1, d.anln2, d.bukrs
FROM equi a
INNER JOIN eqkt b ON a.equnr = b.equnr AND b.spras = 'S'
INNER JOIN iloa d ON a.iloan = d.iloan
WHERE d.anln1 IS NOT NULL
  AND a.swerk = '1000'
ORDER BY d.anln1
```

### Obtener historial de instalaciones de un equipo

```sql
SELECT equnr, tplnr, datab, datbi, iwerk, swerk
FROM equz
WHERE equnr = '000000000010000001'
ORDER BY datab DESC
```

### Equipos sin mantenimiento en los últimos 12 meses (potencial activo huérfano)

```sql
SELECT a.equnr, b.eqktx, a.swerk, MAX(q.qmdat) AS ultimo_aviso
FROM equi a
INNER JOIN eqkt b ON a.equnr = b.equnr AND b.spras = 'S'
LEFT JOIN qmel q ON a.equnr = q.equnr
WHERE a.swerk = '1000'
  AND a.inakt = ' '
GROUP BY a.equnr, b.eqktx, a.swerk
HAVING MAX(q.qmdat) < ADD_MONTHS(CURRENT_DATE, -12)
   OR MAX(q.qmdat) IS NULL
ORDER BY ultimo_aviso NULLS FIRST
```

### Equipos por fabricante y modelo

```sql
SELECT a.herst, a.typbz, COUNT(*) AS cantidad
FROM equi a
WHERE a.swerk = '1000'
  AND a.inakt = ' '
GROUP BY a.herst, a.typbz
ORDER BY cantidad DESC
```

---

## 11. Número de Serie y Gestión de Stocks

Cuando un equipo tiene número de serie vinculado a un material MM, se integra con el proceso de Gestión de Stocks:

- El movimiento de mercancías 101 (entrada de GR) puede crear automáticamente un equipo PM si el material tiene perfil de número de serie PM.
- La venta de un equipo puede desinstalar automáticamente el equipo PM de la UT.

**Configuración:** SPRO → MM → Gestión de Inventario → Configuración movimientos → Perfil número de serie → Categoría de equipo

**Transacción:** MIGO (movimiento de mercancías) — pestaña Número de Serie

---

## 12. Fiori Apps — Equipos

| App ID  | Nombre                                     | Descripción                              |
|---------|--------------------------------------------|------------------------------------------|
| F1613   | Create Equipment                            | Crear equipo nuevo                       |
| F1614   | Manage Equipment                            | Buscar y editar equipos                  |
| F1615   | Equipment Hierarchy                         | Visualizar jerarquía de equipos          |
| F2140   | Equipment and Technical Objects             | Vista integrada UT + Equipos             |
| F3484   | Equipment 360°                              | Vista 360° con historial, costes, KPIs   |
| F1646   | Maintenance Object Where-Used               | Dónde se usa un equipo                   |
| F2229   | Install/Dismantle Equipment                 | Gestión de instalaciones/desinstalaciones|

---

## 13. Configuración SPRO — Resumen Equipos

| Actividad                                    | Ruta SPRO / Transacción          |
|----------------------------------------------|----------------------------------|
| Definir categorías de equipos                | SPRO → PM → Datos maestros → Equipos → Categorías |
| Definir rangos de números de equipos         | IE0N                             |
| Configurar vistas por categoría              | SPRO → PM → Datos maestros → Equipos → Vistas de usuario |
| Enlace equipo — activo fijo                  | SPRO → PM → Datos maestros → Equipos → Enlace equipo-activo |
| Perfil número de serie                       | SPRO → MM → Gestión stocks → Número de serie |

---

## 14. Buenas Prácticas — Equipos

1. **Usar categorías de equipo coherentes:** Definir categorías que reflejen la naturaleza técnica del activo (mecánico, eléctrico, instrumento). Facilita filtrado y reporte.

2. **Siempre vincular equipo a UT:** Los equipos "flotantes" (sin UT) dificultan la gestión de planes de mantenimiento por posición y el análisis de costes por ubicación.

3. **Completar datos del fabricante:** Modelo, fabricante y año de construcción son esenciales para análisis de vida útil y MTBF por modelo.

4. **Vincular a activo fijo cuando corresponda:** Para activos de alto valor, la sincronización PM-FI/AA asegura coherencia entre el valor contable y el estado técnico del activo.

5. **Gestionar número de serie para equipos críticos:** Permite trazar el equipo a través de compras, instalaciones, reparaciones y bajas. Integra PM con MM y SD.

6. **No crear equipos para objetos desechables:** Los consumibles o repuestos que no requieren historial individual deben gestionarse solo como materiales MM, no como equipos PM.

7. **BOM de equipo para activos complejos:** Definir el BOM de repuestos críticos facilita la planificación de materiales en órdenes PM y reduce el tiempo de diagnóstico.
