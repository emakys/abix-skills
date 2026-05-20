---
name: sap-clean-core
description: >
  Skill sobre la estrategia Clean Core de SAP y el modelo de extensibilidad A-B-C-D
  (agosto 2025). Úsalo SIEMPRE que el usuario pregunte sobre: clean core SAP,
  niveles A/B/C/D de extensibilidad, ABAP Cloud development model, APIs liberadas
  (released APIs), APIs clásicas (classic APIs), objetos internos SAP, objetos
  noAPI, cloudification repository, ATC (ABAP Test Cockpit), variantes de check
  CLOUD_READINESS / S4HANA_READINESS, objectReleaseInfo JSON, Simplification Database
  (SYCM), código custom en S/4HANA, upgrade readiness, código Z en S/4HANA,
  BAPI como clean core, desarrollo ABAP en BTP, tier 1/2/3 (modelo antiguo),
  extensibilidad on-stack vs side-by-side, SAP BTP ABAP environment, ABAP language
  version, wrapper de APIs clásicas, SAP Note 3565942, transformación de código ECC
  a S/4HANA, o cualquier pregunta sobre qué está permitido desarrollar en SAP
  S/4HANA Cloud Private Edition u on-premise sin romper la upgrade-safety.
  Aplica aunque el usuario no mencione "clean core" explícitamente.
---

# SAP Clean Core — Modelo de Extensibilidad A-B-C-D

Estrategia oficial SAP publicada en agosto 2025. Reemplaza el modelo de 3 tiers (Tier 1/2/3)
con un modelo de 4 niveles más pragmático y gradual.
Fuente oficial: https://sap.github.io/abap-atc-cr-cv-s4hc (Cloudification Repository Viewer)
Repositorio GitHub: https://github.com/SAP/abap-atc-cr-cv-s4hc

---

## 1. Por qué Clean Core

El problema del modelo anterior (3 tiers):
- Clasificación binaria "limpio vs no limpio" — demasiado rígida
- Todo el código classic ABAP era "Tier 3 = sucio", aunque algunos frameworks clásicos
  (ALV, SmartForms, Customer Exits) son estables y no representan riesgo real de upgrade
- No reflejaba la realidad: muchas empresas tienen millones de líneas de ABAP clásico
  que no pueden refactorizar de golpe

El objetivo de Clean Core sigue siendo el mismo: **desacoplar las extensiones del núcleo SAP**
para que los upgrades sean predecibles, seguros y más baratos. El modelo A-D hace ese
objetivo alcanzable de forma incremental.

---

## 2. El modelo A-B-C-D — los 4 niveles

### Nivel A — Totalmente conforme (Clean Core puro)
**Definición:** Solo usa APIs liberadas oficialmente por SAP con contrato de estabilidad formal.

**Dos modalidades:**
- **Side-by-side en BTP:** apps en SAP BTP usando pro-code (ABAP Cloud, Java, JS) o
  low-code (SAP Build Apps, Process Automation). Totalmente desacoplado del sistema ERP.
- **On-stack con ABAP Cloud:** desarrollo dentro de S/4HANA usando lenguaje ABAP for
  Cloud Development — solo puede acceder a Released APIs.

**ATC result:** Sin findings. Pasa limpio CLOUD_READINESS.

**Características:**
- Garantía SAP de estabilidad entre upgrades
- APIs encontradas en SAP Business Accelerator Hub y Cloudification Repository
- Compatible con S/4HANA Cloud Public Edition (máxima portabilidad)
- Sintaxis ABAP restringida: no `SELECT *` en tablas SAP, no acceso a objetos no liberados

**Cuándo usar:** Todos los desarrollos nuevos — esta es la meta.

---

### Nivel B — APIs clásicas documentadas (Conditionally Clean)
**Definición:** Usa Classic APIs — objetos SAP clásicos nominados por expertos SAP como
upgrade-estables, aunque sin contrato formal de estabilidad.

**Incluye (ejemplos):**
- BAPIs documentadas como classic API en el Cloudification Repository
- IDocs estándar SAP
- Customer Exits y Enhancement Spots reconocidos
- ABAP List Viewer (ALV)
- SmartForms, SAPScript (todavía en Nivel B)
- Classic Workflow
- Web Dynpro ABAP

**ATC result:** Mensajes informativos (Priority 3 / info). NO bloquea transport.

**Características:**
- Generalmente upgrade-estables — SAP los gestiona para no romperlos
- No tienen contrato formal, pero sí compromiso de estabilidad por parte de SAP
- Listados en `objectClassifications_SAP.json` en el repositorio GitHub (campo: `classicAPI`)
- Ruta de mejora: buscar Released API equivalente y migrar a Nivel A con el tiempo

**Cuándo usar:** Cuando no hay Released API equivalente disponible, o para código existente
estable que no justifica refactorización inmediata.

---

### Nivel C — Objetos internos SAP (Conditionally Clean con riesgo)
**Definición:** Accede a objetos SAP internos que NO están en el Cloudification Repository
como Released API ni Classic API. Sin garantía de estabilidad.

**Incluye:**
- Acceso directo a tablas transparentes SAP (SELECT sobre MARA, BKPF, etc.) no liberadas
- Clases, function modules, métodos SAP sin clasificación en el repositorio
- Frameworks como TAANA, GOS (Gestión Objeto de Servicio), ADK (archiving), ILM
- Cualquier objeto SAP cuyo estado en el Cloudification Repository sea "internal object"

**ATC result:** Warnings (Priority 2). No siempre bloquea, pero señala riesgo.

**Mecanismo de gestión:** Simplification Database (SDB) — changelog de objetos SAP
que permite saber ANTES de un upgrade si algún objeto usado en código Z va a cambiar.
- Transacción: `SYCM` → Menú Simplification Database → Show Information
- SAP Note: 2241080 (actualización SDB)

**Cuándo usar:** Solo cuando no existe alternativa (Nivel A o B). Debe estar en
un **roadmap de remediación documentado** — no como arquitectura permanente.

---

### Nivel D — No clean core (Non-compliant)
**Definición:** Usa técnicas o objetos explícitamente no recomendados por SAP.

**Incluye:**
- **Modificaciones** a objetos SAP estándar (modificación de programas, includes SAP)
- **Implicit Enhancements** — enhancements insertados en código SAP sin punto explícito
- **Write access a tablas SAP** — UPDATE/INSERT/DELETE sobre tablas del sistema
- Objetos marcados como `noAPI` en el Cloudification Repository
- Acceso a estructuras de datos SAP internas no documentadas

**ATC result:** Errors (Priority 1). Puede **bloquear el transport**.

**Impacto:**
- Alto riesgo de rotura en cada upgrade
- SAP Support no garantiza ayuda cuando falla código Level D
- Genera deuda técnica severa y creciente
- En auditorías RISE with SAP o migración a cloud: bloquea el proceso

**Qué hacer:** Prioridad máxima de remediación. Refactorizar hacia A o B.
Si es imposible a corto plazo: exemption en ATC + governance estricta + timeline de retiro.

---

## 3. Clasificación de objetos en el Cloudification Repository

El repositorio GitHub contiene los archivos JSON con el estado de cada objeto SAP:

### Archivos principales

| Archivo | Aplica para | URL |
|---------|------------|-----|
| `objectReleaseInfoLatest.json` | SAP Cloud ERP (Public) | `https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfoLatest.json` |
| `objectReleaseInfo_PCELatest.json` | S/4HANA Cloud Private (último) | `https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfo_PCELatest.json` |
| `objectReleaseInfo_PCE2025.json` | S/4HANA PCE release 2025 | `...src/objectReleaseInfo_PCE2025.json` |
| `objectReleaseInfo_PCE2023_3.json` | S/4HANA PCE 2023 FPS03 | `...src/objectReleaseInfo_PCE2023_3.json` |
| `objectClassifications_SAP.json` | Nuevo formato (Note 3565942) | `...src/objectClassifications_SAP.json` |

### Estados de un objeto en el repositorio

| Estado | Nivel resultante | ATC |
|--------|-----------------|-----|
| **Released API** | A | Sin finding |
| **Classic API** | B | Info (P3) |
| **Internal Object** | C | Warning (P2) |
| **Not to be Released** + successor | C→A (migrar al sucesor) | Warning (P2) |
| **noAPI** | D | Error (P1) |

> Un objeto puede aparecer en múltiples estados simultáneamente. Ejemplo: si aparece
> como Classic API Y Released API → prevalece Released → Nivel A.
> Si aparece Classic API Y Not to be Released → prevalece Classic → Nivel B.

### Viewer interactivo
https://sap.github.io/abap-atc-cr-cv-s4hc — buscar un objeto por nombre y ver su estado
por release (requiere JavaScript en el browser).

---

## 4. ATC — ABAP Test Cockpit

### Variantes de check para Clean Core

| Variante | Uso | Disponible desde |
|----------|-----|-----------------|
| `CLOUD_READINESS` | Check estándar de cloud readiness | Todas las versiones S/4HANA |
| `S4HANA_READINESS` | Detecta patrones ECC obsoletos | S/4HANA on-premise |
| `ABAP_CLEAN_CORE_DEVELOPMENT` | Entornos BTP ABAP | SAP BTP ABAP Env. |
| Custom variant (Clean Core) | Combina checks A/B/C/D | Desde Note 3565942 |

### SAP Notes clave para ATC Clean Core

| Note | Descripción |
|------|-------------|
| **3565942** | Nueva check "Usage of APIs" y "Allowed Enhancement Technologies" — habilita modelo A-D |
| **3449860** | Soporte Classic APIs en ATC check "Usage of Released APIs" |
| **3284711** | ATC Check para repositorio GitHub (Cloudification Repository) |
| **3377462** | Fix error en ATC Check |
| **3507814** | Soporte objetos propios liberados |
| **3582797** | SSL Handshake fix para acceso GitHub desde S/4 |
| **2241080** | Actualización Simplification Database (SYCM) |

### Configurar ATC para S/4HANA PCE (on-premise)
```
1. Implementar Note 3565942 (nueva check)
2. En ADT (Eclipse): ATC → Manage Check Variants → New variant
3. Activar check: "Clean Core" → "Usage of APIs"
4. En atributos del check: URL del JSON según tu release:
   https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/src/objectReleaseInfo_PCELatest.json
5. Activar check: "Allowed Enhancement Technologies"
6. Ejecutar ATC sobre paquetes de código custom (Z*)
```

### Interpretar resultados ATC → Nivel Clean Core

```
Sin findings       → Nivel A  ✅ Clean core puro
Priority 3 (Info)  → Nivel B  ℹ️ Classic API — monitorear
Priority 2 (Warn)  → Nivel C  ⚠️ Objeto interno — roadmap de remediación
Priority 1 (Error) → Nivel D  ❌ No clean — acción inmediata requerida
```

---

## 5. Estrategia de decisión — qué nivel usar

### Árbol de decisión para código nuevo

```
¿Existe Released API para la funcionalidad?
  SÍ → Nivel A (usar ABAP Cloud / BTP)
  NO ↓
¿Existe Classic API estable en el repositorio?
  SÍ → Nivel B (aceptable con governance)
  NO ↓
¿Es un caso de negocio crítico sin alternativa?
  SÍ → Nivel C temporal + roadmap documentado + monitoreo SYCM
  NO → Rediseñar la solución / esperar API liberada
¿Involucra modificación SAP o write a tabla SAP?
  SÍ → Nivel D → RECHAZAR / buscar alternativa
```

### Principio BTP-First
Antes de escribir cualquier extensión, evaluar:
1. ¿Puede resolverse con Key User Extensibility? (Custom Fields, Business Rules, UI Adaptation)
2. ¿Puede desarrollarse side-by-side en BTP? (SAP Build, CAP, ABAP Cloud en BTP)
3. Si debe ser on-stack: ¿ABAP Cloud con Released APIs? (Nivel A)
4. Si ninguna anterior: Classic APIs (Nivel B) con governance

---

## 6. Wrappers — puente entre ABAP Cloud y APIs clásicas

Cuando una funcionalidad solo existe como Classic API (Nivel B) y se necesita desde
código ABAP Cloud (Nivel A), se usa el patrón **wrapper**:

```
ABAP Cloud (Nivel A)
    ↓ llama a
Wrapper Class/IF (Nivel B) — componente de software tipo ABAP Classic
    ↓ llama a
Classic API (BAPI, FM, etc.)
```

**Herramienta:** https://github.com/SAP-samples/tier2-rfc-proxy (wrapper generator)
**Documentación:** SAP Community blog "How to generate a wrapper for Function Modules/BAPIs in Tier 2"

**Cuándo crear wrapper:**
- El BAPI/FM existe como Classic API en el repositorio (Nivel B)
- Se necesita desde un contexto ABAP Cloud
- Se crea en un software component tipo ABAP Classic separado
- El wrapper expone una interfaz limpia que el Nivel A puede consumir

---

## 7. Software Components — organización del desarrollo

En S/4HANA Cloud Private Edition, los software components se clasifican como:

| Tipo | Lenguaje ABAP | Nivel resultante |
|------|-------------|-----------------|
| **ABAP Cloud** | ABAP for Cloud Development | A |
| **ABAP Classic** | All ABAP (clásico) | B, C o D según APIs usadas |

```
Transacción: RSMAINTAIN_SWCOMPONENTS (desde ABAP Platform 2022)
→ Crear software component
→ Asignar tipo: ABAP Cloud o ABAP Classic
→ Asignar transportabilidad
```

**Roles de desarrollador por nivel:**
```
PFCG → copiar rol SAP_BC_ABAP_DEVELOPER_5
Objeto autorización: S_ABPLNGVS
  Valor "ABAP For Cloud Development" → developer Nivel A únicamente
  Valor "All activities"             → developer Niveles B/C/D
```

---

## 8. Transformation roadmap — código ECC / legacy

Para sistemas con gran volumen de código ABAP clásico:

### Clasificar el portfolio actual
```
1. Ejecutar ATC con variante CLOUD_READINESS + S4HANA_READINESS sobre todos los Z*
2. Agrupar findings por nivel A/B/C/D
3. Priorizar por impacto en negocio + frecuencia de cambio
```

### Estrategia de remediación por nivel
| Nivel actual | Acción recomendada |
|-------------|-------------------|
| **D** | Prioridad máxima: eliminar modificaciones, reemplazar con Extension Points / Released APIs, o retirar si no se usa |
| **C** | Roadmap documentado: monitorear con SYCM, migrar a B o A cuando exista API disponible; tratar como tiempo-limitado |
| **B** | Aceptable. Buscar equivalente Released API para migración gradual a A |
| **A** | Mantener. Es el estado objetivo |

### Herramientas de soporte
- **SYCM** → Simplification Database: changelog de objetos SAP (detecta cambios antes del upgrade)
- **SLIN** → Syntax check extendido ABAP
- **SAP Joule para Developers** → IA asistida para transformación de código ABAP clásico a ABAP Cloud
- **RISE with SAP Methodology Dashboard** → métricas de adopción Clean Core en tiempo real
- **SAP Business Accelerator Hub** → catálogo de Released APIs disponibles por módulo

---

## 9. Tablas resumen rápido

### Tecnologías por nivel

| Tecnología | Nivel |
|-----------|-------|
| ABAP Cloud + Released API (on-stack) | A |
| SAP Build Apps / Process Automation (BTP) | A |
| CAP (Cloud Application Programming, BTP) | A |
| BAPI (Classic API en repositorio) | B |
| IDoc estándar SAP | B |
| Customer Exit / Enhancement Spot SAP | B |
| ALV (ABAP List Viewer) | B |
| SmartForms / SAPScript | B |
| Classic Workflow | B |
| Web Dynpro ABAP | B |
| SELECT directo sobre tablas SAP no liberadas | C |
| Function Modules SAP sin clasificar | C |
| GOS, ADK, ILM, TAANA | C |
| Modificación de objetos SAP | D |
| Implicit Enhancements | D |
| UPDATE/INSERT sobre tablas SAP | D |
| Objetos marcados noAPI | D |

### Errores comunes al clasificar

| Error | Realidad |
|-------|---------|
| "Los BAPIs son siempre Nivel A" | ❌ BAPIs son Nivel B (Classic API), no Released APIs |
| "Classic ABAP = siempre Nivel D" | ❌ Classic ABAP puede ser B o C según los objetos usados |
| "ATC sin findings = código perfecto" | ⚠️ ATC solo verifica lo que está en el repositorio; revisa también patrones de diseño |
| "Wrapper = Nivel A automáticamente" | ❌ El wrapper en sí es Nivel B; el código que LO LLAMA desde ABAP Cloud es A |
| "SELECT sobre tabla SAP = siempre Nivel D" | ❌ Depende del estado de la tabla en el repositorio; puede ser B o C |

---

## 10. Governance y métricas Clean Core

### KPIs sugeridos por SAP

| KPI | Qué medir |
|-----|----------|
| % código en Nivel A | Meta: aumentar con cada sprint |
| % código en Nivel D | Meta: 0% — prioridad absoluta de reducción |
| Volumen exemptions ATC | Si crece sin revisión → señal de governance drift |
| Objetos C sin roadmap documentado | Todos deben tener plan de remediación |
| Tiempo de upgrade post-remediación | Benchmark: antes vs después de clean core |

### Proceso de governance recomendado
```
Todo objeto nuevo → clasificar nivel en el momento del diseño
Si Nivel C o D   → aprobación arquitecto + documentación de alternativas evaluadas
                 → timeline de retiro o migración
Revisión mensual → ATC automático en CI/CD + reporte de tendencias
Antes de upgrade → SYCM check de todos los objetos C usados en código Z
```

---

*Fuentes: SAP Clean Core Extensibility Whitepaper (agosto 2025), SAP Community Blog "ABAP Extensibility Guide – Clean Core for SAP S/4HANA Cloud" (enero 2026), SAP News Center "How to Extend SAP S/4HANA Cloud the Right Way" (agosto 2025), GitHub SAP/abap-atc-cr-cv-s4hc (repositorio oficial), SAP Learning Hub "Practicing Clean Core Extensibility", SAP Note 3565942, SAP Note 3449860, SAP Community Blog "Object Release State in Cloudification Repository Viewer" (marzo 2026)*
