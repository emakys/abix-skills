# Ubicaciones Técnicas (Functional Locations) — SAP PM S/4HANA 2023

## 1. Concepto

Una **ubicación técnica** (UT) es un lugar en el sistema técnico de una empresa donde se puede instalar un objeto (equipo). Representa la estructura funcional del sistema técnico: la planta, sus sistemas, subsistemas y puntos de instalación.

Características fundamentales:
- Estructura **jerárquica** con relaciones padre-hijo.
- Las UTs son **permanentes** — no desaparecen cuando se desinstala el equipo.
- Permiten registrar historial de mantenimiento independientemente del equipo instalado.
- Heredan datos organizativos de la UT padre (centro, CC, profit center, etc.).
- Se pueden asignar planes de mantenimiento directamente a la UT.

**Diferencia clave con Equipos:** La UT representa el lugar; el equipo representa el objeto instalado en ese lugar. Un equipo puede moverse; la UT es fija.

---

## 2. Jerarquía de Ubicaciones Técnicas

La jerarquía refleja la descomposición funcional del activo:

```
PLANTA-01                          (Nivel 0 — Planta)
├── PLANTA-01-SIS1                 (Nivel 1 — Sistema principal)
│   ├── PLANTA-01-SIS1-SUB1       (Nivel 2 — Subsistema)
│   │   ├── PLANTA-01-SIS1-SUB1-001  (Nivel 3 — Punto de instalación)
│   │   └── PLANTA-01-SIS1-SUB1-002  (Nivel 3 — Punto de instalación)
│   └── PLANTA-01-SIS1-SUB2
└── PLANTA-01-SIS2
```

La profundidad máxima depende de la **máscara de edición** configurada.

### Herencia de datos en la jerarquía

Cuando se cambia un dato organizativo en un nodo padre, SAP puede propagar el cambio a todos los nodos hijo. Los datos que se heredan incluyen:
- Centro de emplazamiento
- Centro de planificación
- Grupo planificador
- Puesto de trabajo responsable
- Centro de coste
- Profit Center

---

## 3. Indicadores de Estructura

Los indicadores de estructura controlan cómo se interpreta la clave de la UT:

| Indicador | Descripción                                    |
|-----------|------------------------------------------------|
| 0         | Sin jerarquía (UT plana, no se admiten hijos)  |
| 1         | Jerarquía, con máscara de edición definida     |

Para usar jerarquías con máscara de edición, el indicador de estructura debe ser **1**.

**SPRO:** IMG → PM → Datos maestros técnicos → Ubicaciones técnicas → Definir categorías de UTs

---

## 4. Máscara de Edición (Edit Mask)

La máscara de edición define el formato de la clave de la UT y determina automáticamente la relación padre-hijo. Es uno de los parámetros más críticos porque **no se puede cambiar fácilmente** una vez que existen UTs con datos.

### Ejemplo de máscara

```
Máscara: AAAA-AAA-AAA-AA
Ejemplo de clave: PLAN-ELE-TRF-01
```

| Segmento | Longitud | Separador | Nivel |
|----------|----------|-----------|-------|
| PLAN     | 4        | -         | 0     |
| ELE      | 3        | -         | 1     |
| TRF      | 3        | -         | 2     |
| 01       | 2        | (fin)     | 3     |

SAP determina automáticamente que `PLAN-ELE-TRF-01` es hijo de `PLAN-ELE-TRF`, que a su vez es hijo de `PLAN-ELE`, etc.

### Configuración de la máscara

**Transacción:** IL11 (definir máscara de edición de UT)

**SPRO:** IMG → PM → Datos maestros técnicos → Ubicaciones técnicas → Definir máscara de edición de UTs

Parámetros de la máscara:
- Caracteres permitidos (A = alfanumérico, N = numérico)
- Separadores (-, /, ., espacio)
- Longitud de cada segmento
- Número de niveles de jerarquía

---

## 5. Creación de Ubicaciones Técnicas

**Transacción:** IL01 (crear), IL02 (modificar), IL03 (visualizar)

**Fiori App:** F1621 — Create Functional Location, F1622 — Manage Functional Locations

### Datos de Cabecera (Pestaña General)

| Campo          | Descripción                              | Obligatorio |
|----------------|------------------------------------------|-------------|
| TPLNR          | Clave de ubicación técnica               | Sí          |
| PLTXT          | Descripción                              | Sí          |
| TPLKZ          | Categoría de UT                          | Sí          |
| INGRP          | Grupo planificador                       | Recomendado |
| IWERK          | Centro planificación mantenimiento       | Sí          |
| SWERK          | Centro ejecutor                          | Sí          |
| ARBPL          | Puesto de trabajo responsable            | Recomendado |

### Datos Organizativos (Pestaña Organización)

| Campo  | Descripción                   |
|--------|-------------------------------|
| KOSTL  | Centro de coste               |
| BUKRS  | Sociedad                      |
| PRCTR  | Profit Center                 |
| GSBER  | Área de negocio               |
| KOKRS  | Área de controlling           |

### Datos de Localización (Pestaña Estructura)

| Campo   | Descripción                             |
|---------|-----------------------------------------|
| TPLMA   | UT padre en la jerarquía                |
| ERDAT   | Fecha creación                          |
| IEQUI   | Indicador: UT permite equipo instalado  |

---

## 6. Datos de Referencia

Las UTs pueden configurarse con datos de referencia que se heredan al crear sub-UTs. Esto facilita la creación masiva de estructuras similares.

### Categorías de UT

Cada UT se crea bajo una **categoría** que define:
- Qué vistas/pestañas están disponibles
- Qué campos son obligatorios
- La clase de objeto para clasificación

**SPRO:** IMG → PM → Datos maestros técnicos → Ubicaciones técnicas → Definir categorías de UTs

Categorías estándar:
- M — Posición de mantenimiento general
- I — Posición de instrumentación
- E — Posición eléctrica

---

## 7. Clasificación de Ubicaciones Técnicas

Las UTs se pueden clasificar usando el sistema de clasificación estándar de SAP para:
- Búsquedas avanzadas por atributos técnicos.
- Agrupación de UTs similares.
- Integración con SAP IAM (Intelligent Asset Management).

**Transacción:** IL02 → Pestaña Clasificación (o desde IL01 al crear)

La clasificación usa el objeto `FL` (Functional Location).

---

## 8. Indicadores de Mantenimiento

Los indicadores de mantenimiento controlan qué tipo de mantenimiento está activo para una UT:

| Indicador | Descripción                                      |
|-----------|--------------------------------------------------|
| IPLKZ=1   | UT incluida en mantenimiento preventivo          |
| IPLKZ=2   | UT excluida del mantenimiento preventivo         |
| INACT     | UT inactiva (no aparece en listas de trabajo)    |

**Ubicación en la pantalla:** IL02 → Datos generales → Indicadores de mantenimiento

---

## 9. Instalación y Desinstalación de Equipos

Una de las funciones clave de la UT es ser el punto de instalación de equipos. La historia de qué equipos han estado instalados en cada UT se registra automáticamente.

### Instalar equipo en UT

1. Ir al equipo (IE02) → Pestaña Localización
2. Ingresar la UT en el campo `TPLNR`
3. SAP registra la fecha de instalación en la tabla `EQUZ`

### Desinstalar equipo

**Transacción:** IE4N (desinstalación directa) o desde IE02 → borrar UT + fecha

**Historial de instalaciones:** IE03 → Datos del equipo → Historial de instalaciones

---

## 10. Vistas de la Ubicación Técnica

### Pestaña General
- Descripción y categoría
- Indicadores de mantenimiento
- Tipo de objeto PM
- Información de garantía

### Pestaña Localización
- Dirección física
- País, región, población
- Coordenadas GPS (S/4HANA — campo COORDS)

### Pestaña Organización
- Centro, CPM, grupo planificador
- Centro de coste, profit center
- Puesto de trabajo responsable
- Sociedad, área de negocio

### Pestaña Estructura
- UT padre
- UTs hijas (visualización de jerarquía)
- Equipos instalados actualmente

### Pestaña Clasificación
- Clase asignada
- Características y valores

---

## 11. Tablas de Base de Datos — Ubicaciones Técnicas

### IFLOT — Datos Maestros de Ubicaciones Técnicas

| Campo  | Descripción                           |
|--------|---------------------------------------|
| TPLNR  | Clave de ubicación técnica            |
| TPLKZ  | Categoría de UT                       |
| IWERK  | Centro de planificación mantenimiento |
| SWERK  | Centro ejecutor                       |
| INGRP  | Grupo planificador                    |
| ARBPL  | Puesto de trabajo                     |
| ERDAT  | Fecha de creación                     |
| INACT  | Indicador UT inactiva                 |

### IFLOS — Textos de Ubicaciones Técnicas

| Campo  | Descripción                   |
|--------|-------------------------------|
| TPLNR  | Clave de ubicación técnica    |
| SPRAS  | Idioma                        |
| PLTXT  | Descripción de la UT          |

### ILOA — Datos de Cuenta de UT y Equipo

Contiene los datos organizativos asignados a UTs y equipos (CC, profit center, etc.).

| Campo  | Descripción                   |
|--------|-------------------------------|
| ILOAN  | Número interno ILOA           |
| TPLNR  | Clave UT (si aplica)          |
| EQUNR  | Número de equipo (si aplica)  |
| KOSTL  | Centro de coste               |
| PRCTR  | Profit Center                 |
| BUKRS  | Sociedad                      |
| GSBER  | Área de negocio               |
| KOKRS  | Área de controlling           |

### Relación entre tablas

```
IFLOT (datos maestros UT)
  ├── IFLOS (descripciones/textos)
  ├── ILOA  (datos organizativos, via ILOAN)
  └── EQUZ  (equipos instalados — link UT↔EQUI)
```

---

## 12. Consultas MCP — GetSqlQuery

### Obtener todas las UTs activas de un centro

```sql
SELECT a.tplnr, b.pltxt, a.iwerk, a.swerk, a.ingrp, a.arbpl, a.erdat
FROM iflot a
INNER JOIN iflos b ON a.tplnr = b.tplnr AND b.spras = 'S'
WHERE a.swerk = '1000'
  AND a.inact = ' '
ORDER BY a.tplnr
```

### Obtener datos organizativos de UTs (CC, Profit Center)

```sql
SELECT a.tplnr, b.pltxt, c.kostl, c.prctr, c.bukrs, c.gsber
FROM iflot a
INNER JOIN iflos b ON a.tplnr = b.tplnr AND b.spras = 'S'
INNER JOIN iloa c ON a.iloan = c.iloan
WHERE a.swerk = '1000'
ORDER BY a.tplnr
```

### Obtener jerarquía de UTs (nivel 1 y 2)

```sql
SELECT tplnr, pltxt, tplma, tpln2
FROM iflot
LEFT JOIN iflos ON iflot.tplnr = iflos.tplnr AND iflos.spras = 'S'
WHERE swerk = '1000'
  AND LENGTH(tplnr) <= 12
ORDER BY tplnr
```

### Obtener UTs con equipos instalados actualmente

```sql
SELECT a.tplnr, b.pltxt, c.equnr, d.eqktx
FROM iflot a
INNER JOIN iflos b ON a.tplnr = b.tplnr AND b.spras = 'S'
INNER JOIN equz c ON a.tplnr = c.tplnr AND c.datbi = '99991231'
INNER JOIN eqkt d ON c.equnr = d.equnr AND d.spras = 'S'
WHERE a.swerk = '1000'
ORDER BY a.tplnr
```

### Contar avisos por UT en el último año

```sql
SELECT a.tplnr, b.pltxt, COUNT(q.qmnum) AS num_avisos
FROM iflot a
INNER JOIN iflos b ON a.tplnr = b.tplnr AND b.spras = 'S'
LEFT JOIN qmel q ON a.tplnr = q.tplnr
  AND q.qmdat >= ADD_MONTHS(CURRENT_DATE, -12)
WHERE a.swerk = '1000'
GROUP BY a.tplnr, b.pltxt
ORDER BY num_avisos DESC
```

---

## 13. Fiori Apps — Ubicaciones Técnicas

| App ID  | Nombre                                          | Descripción                              |
|---------|-------------------------------------------------|------------------------------------------|
| F1621   | Create Functional Location                       | Crear UT nueva                           |
| F1622   | Manage Functional Locations                      | Buscar, visualizar y editar UTs          |
| F3352   | Functional Location Structure                    | Visualizar jerarquía de UTs              |
| F2140   | Equipment and Technical Objects                  | Vista integrada equipos y UTs            |
| F1646   | Maintenance Object Where-Used List               | Uso de UT en órdenes y planes            |

---

## 14. Configuración SPRO — Resumen

| Actividad                                    | Ruta SPRO / Transacción        |
|----------------------------------------------|--------------------------------|
| Definir categorías de UT                     | SPRO → PM → Datos maestros → UTs → Categorías |
| Definir máscara de edición                   | IL11                           |
| Definir indicadores de mantenimiento         | SPRO → PM → Datos maestros → UTs → Indicadores |
| Definir usos de objetos técnicos             | SPRO → PM → Datos maestros → Uso del objeto |
| Configurar herencia de datos                 | SPRO → PM → Datos maestros → UTs → Herencia |

---

## 15. Buenas Prácticas

1. **Diseñar la jerarquía antes de crear la máscara:** La máscara de edición es difícil de cambiar una vez en producción. Planificar todos los niveles necesarios desde el inicio.

2. **No profundizar innecesariamente:** 3-4 niveles son suficientes para la mayoría de industrias. Más niveles aumentan la complejidad de mantenimiento de datos maestros.

3. **Separar UT de equipos:** Las UTs deben representar posiciones funcionales permanentes. Los equipos se instalan y desinstalan. Mezclar ambos conceptos en el mismo nivel jerárquico es un error frecuente.

4. **Heredar CC y Profit Center:** Configurar la herencia para que los datos organizativos se propaguen automáticamente desde la UT raíz. Reduce errores de imputación de costes.

5. **Categorías diferenciadas por tipo de activo:** Usar categorías distintas para instalaciones eléctricas, mecánicas, instrumentación, etc. Facilita reportes por tipo de activo.

6. **Nomenclatura consistente:** Definir una convención de nombres clara y documentarla. Ejemplo: `{PLANTA}-{SISTEMA}-{SUBSISTEMA}-{POSICION}`.

7. **Activar clasificación:** Aunque no sea obligatoria, la clasificación de UTs permite búsquedas avanzadas y es base para analytics en SAP IAM.
