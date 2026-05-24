# Guias de Configuracion IMG — SAP Project System

## Indice
1. Acceso al IMG de PS
2. Estructuras de Proyecto
3. Perfiles de Proyecto y WBS
4. Tipos de Red y Actividad
5. Claves de Control
6. Rangos de Numeros
7. Presupuesto y Control de Fondos
8. Liquidacion
9. Status de Sistema y Usuario
10. Programacion
11. Integracion con Otros Modulos
12. Datos Maestros PS
13. Parametros Globales PS

---

## 1. Acceso al IMG de PS

### Ruta Principal
```
SPRO → Project System
```
Transaccion directa: `SPRO` → seleccionar "SAP Reference IMG"

### Alternativa rapida
```
Transaccion: OPS0 (parametros globales PS)
```

---

## 2. Estructuras de Proyecto

### 2.1 Tipos de Proyecto

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Work Breakdown Structure →
  Define Project Types
```
**Tabla:** `T_PROJECT_TYPE` (vista V_T_PROJ_TYPE)
**Transaccion:** `OPSA`

**Campos clave:**
| Campo | Descripcion |
|-------|-------------|
| PSPID_TYPE | Tipo de proyecto |
| DESCRIPTION | Descripcion |
| PROJ_PROFILE | Perfil de proyecto asignado |
| STATUS_SCHEMA | Esquema de status |

**Impacto:** Determina el perfil de proyecto por defecto, esquema de status y configuracion de codificacion. Cada proyecto creado se clasifica por tipo.

---

### 2.2 Perfil de Proyecto (Project Profile)

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Work Breakdown Structure →
  Define Project Profile
```
**Transaccion:** `OPSA` (misma pantalla, tab Profile)
**Tabla:** `T24` (PROJ_PROFILE)

**Parametros del perfil:**
| Parametro | Descripcion | Impacto |
|-----------|-------------|---------|
| Organizational data | CoCd, Area funcional, Centro de beneficio | Herencia a WBS |
| Status profile | Perfil de status usuario | Control de transiciones |
| Network assignment | Tipo de red permitido | Integracion redes |
| Time scheduling | Modo de programacion (red/WBS/manual) | Calculo fechas |
| Cost planning | Perfil de plan de costes | Estructura presupuestaria |
| Budget profile | Perfil de presupuesto | Control disponibilidad |
| Results analysis | Clave de analisis de resultados | Reconocimiento ingresos |
| Settlement profile | Perfil de liquidacion | Destinos liquidacion |

---

### 2.3 Perfil de WBS (WBS Element Profile)

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Work Breakdown Structure →
  Define WBS Element
```
**Transaccion:** `OPSA` → WBS Element

**Configuracion:**
- Control de planificacion de costes (elemento de planificacion)
- Control de facturacion (elemento de facturacion)
- Control de presupuesto (elemento de presupuesto)
- Parametros contables (clase de coste, tipo de actividad)

---

### 2.4 Campo de Proyecto — Mascara de Codificacion

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Work Breakdown Structure →
  Define Coding Mask
```
**Transaccion:** `OPSK`
**Tabla:** `T400A`

**Ejemplo de mascara:**
```
Proyecto: XXXX-XXXX-XXXX-XX
Nivel 1: 4 caracteres (area de negocio)
Nivel 2: 4 caracteres (subarea)
Nivel 3: 4 caracteres (fase)
Nivel 4: 2 caracteres (actividad)
```

**Impacto:** Define la estructura jerarquica de los identificadores WBS. Una vez usada en produccion, NO modificar.

---

### 2.5 Perfil de Red (Network Profile)

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Networks →
  Define Network Type
```
**Transaccion:** `OPUU`

**Tipos de red principales:**
| Tipo | Uso |
|------|-----|
| PS01 | Red de proyecto estandar |
| PS02 | Red de mantenimiento |
| PS03 | Red de servicio |

**Parametros por tipo:**
- Tipo de orden (clase de orden)
- Clase de movimiento de mercancias
- Perfil de red
- Control de programacion

---

## 3. Perfiles de Proyecto

### 3.1 Perfil de Planificacion de Costes

**Ruta SPRO:**
```
Project System → Costs → Planning → Manual Cost Planning in WBS →
  Define Cost Planning Profile
```
**Transaccion:** `OPSB`

**Opciones:**
| Opcion | Descripcion |
|--------|-------------|
| Plan layout | Layout de pantalla para planificacion |
| Integrated planning | Activa integracion con CO-PA |
| Cost element group | Grupo de elementos de coste permitidos |
| Costing variant | Variante de calculo de costes |
| Distribution key | Clave de distribucion temporal |

---

### 3.2 Perfil de Presupuesto

**Ruta SPRO:**
```
Project System → Costs → Budget →
  Define Budget Profile
```
**Transaccion:** `OPS9`
**Tabla:** `T_BUDGET_PROFILE`

**Parametros criticos:**
| Parametro | Descripcion | Impacto |
|-----------|-------------|---------|
| Budget type | Anual / Total | Determina control por anio o total |
| Availability control | Activo / Inactivo | Bloquea/avisa sobre excesos |
| Warning / Error threshold | % umbral de aviso/error | Tolerancias de control |
| Carry forward | Traslado presupuesto anual | Cierre de ejercicio |
| Budget address | Nivel de control (WBS / proyecto) | Granularidad del control |

**Tolerancias de control disponibilidad:**
- Tolerance key: % del presupuesto
- Action: 1=Aviso, 2=Error, 3=Error+Mail

---

### 3.3 Perfil de Liquidacion

**Ruta SPRO:**
```
Project System → Costs → Settlement →
  Maintain Settlement Profile
```
**Transaccion:** `OKO7`

**Destinos de liquidacion:**
| Receptor | Descripcion | Uso tipico |
|----------|-------------|------------|
| CTR | Centro de coste | Gastos operativos |
| G/L | Cuenta del libro mayor | Imputacion directa |
| WBS | Elemento WBS superior | Consolidacion interna |
| FXA | Activo fijo | Capitalizacion |
| ORD | Orden interna | Distribucion costes |
| PSP | Proyecto SAP | Reasignacion proyectos |

---

## 4. Tipos de Red y Actividad

### 4.1 Parametros de Red

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Networks →
  Settings for Networks → Define Network Parameters
```
**Transaccion:** `OPUU`

**Claves de red (Network Profile):**
```
SPRO → Project System → Structures → Networks →
  Settings for Networks → Define Network Profile
```
**Transaccion:** `OPUN`

---

### 4.2 Tipos de Actividad de Red

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Networks →
  Activity → Define Activity Types
```

**Tipos standard:**
| Tipo | Descripcion | Uso |
|------|-------------|-----|
| 0001 | Actividad interna | Imputacion a CCosto o tarea |
| 0002 | Actividad externa | Servicios externos (PR/PO) |
| 0003 | Costes generales | Recargos overhead |
| 0004 | Material (CPT) | Componentes de proyecto |

---

### 4.3 Claves de Control de Actividad

**Ruta SPRO:**
```
Project System → Structures → Operative Structures → Networks →
  Activity → Define Control Key
```
**Transaccion:** `OP5A`
**Tabla:** `T_ACTIVITY_CONTROL_KEY`

**Parametros de clave de control:**
| Campo | Descripcion |
|-------|-------------|
| Print | Impresion en documentos |
| Costing | Calculo de costes activado |
| Time confirmation | Confirmacion de tiempo activada |
| Automatic goods receipt | GR automatico |
| Milestone billing | Facturacion por hito |
| Inspection | Control de calidad activo |
| Scheduling | Incluido en programacion de red |

**Claves de control tipicas:**
| Clave | Uso |
|-------|-----|
| PS01 | Actividad interna con confirmacion |
| PS02 | Actividad externa con pedido |
| PS03 | Actividades de planificacion (sin imputacion) |
| PS04 | Hito (Milestone) |

---

## 5. Rangos de Numeros

### 5.1 Proyectos WBS

**Ruta SPRO:**
```
Project System → Structures → Operative Structures →
  Work Breakdown Structure → Define Number Ranges for WBS
```
**Transaccion:** `OPSK` → Number Range o `SNRO` con objeto `PS_WBS`

### 5.2 Redes de Proyecto

**Ruta SPRO:**
```
Project System → Structures → Operative Structures →
  Networks → Settings for Networks → Define Number Ranges for Networks
```
**Transaccion:** `SNRO` → objeto `AUFNR` (compartido con Ordenes de Produccion)

**Recomendacion:** Usar rangos separados por tipo de orden para facilitar identificacion:
```
Proyectos:    800000000 - 899999999
Redes PS:     900000000 - 999999999
```

### 5.3 Hitos

**Ruta SPRO:**
```
Project System → Structures → Operative Structures →
  Networks → Milestones → Define Number Ranges for Milestones
```
**Tabla:** `T_MILESTONE_NR`

---

## 6. Configuracion de Presupuesto

### 6.1 Control de Disponibilidad

**Ruta SPRO:**
```
Project System → Costs → Budget → Budget Availability Control →
  Define Tolerance Limits
```
**Transaccion:** `OPS9` → Tolerance Limits

**Claves de tolerancia:**
| Clave | Accion | Mensaje |
|-------|--------|---------|
| 1 | Aviso | Warning en transaccion |
| 2 | Error | Bloquea contabilizacion |
| 3 | Error + Mail | Bloquea + notifica responsable |

**Ejemplo de configuracion:**
```
Tolerance key: ++ (todos los grupos de costes)
  85% → Aviso (1)
  100% → Error (2)
  110% → Error + Mail (3)
```

### 6.2 Excepciones al Control de Disponibilidad

**Ruta SPRO:**
```
Project System → Costs → Budget → Budget Availability Control →
  Specify Exempt Cost Elements
```

Elementos de coste exentos del control (tipicamente):
- Amortizaciones (1-161000)
- Reclasificaciones internas

### 6.3 Traslado de Presupuesto (Budget Carryforward)

**Ruta SPRO:**
```
Project System → Costs → Budget → Year-End Closing →
  Define Rules for Budget Carryforward
```
**Transaccion:** `CJ35` (ejecucion del traslado)

**Reglas:**
- Presupuesto disponible restante se traslada al siguiente ejercicio
- Solo si el proyecto tiene status permitido
- Solo elementos WBS con control de presupuesto

---

## 7. Liquidacion (Settlement)

### 7.1 Esquema de Liquidacion

**Ruta SPRO:**
```
Project System → Costs → Settlement →
  Maintain Settlement Profile
```
**Transaccion:** `OKO7`

### 7.2 Estrategia de Liquidacion

**Ruta SPRO:**
```
Project System → Costs → Settlement →
  Define Default Settlement Strategy
```

**Parametros:**
- Clase de receptor por defecto
- % de distribucion por defecto
- Clase de liquidacion

### 7.3 Tipos de Liquidacion

| Tipo | Descripcion |
|------|-------------|
| PER | Periodica (costes del periodo) |
| FUL | Completa (todos los saldos) |

### 7.4 Equivalence Numbers

**Ruta SPRO:**
```
Controlling → Internal Orders → Settlement →
  Maintain Settlement Structures
```
**Transaccion:** `OKO6`

Estructura de liquidacion define:
- Que elementos de coste van a que receptor
- Claves de equivalencia para distribucion proporcional

---

## 8. Status de Sistema y Usuario

### 8.1 Status de Sistema (System Status)

Los status de sistema son predefinidos por SAP y no configurables:
| Status | Descripcion |
|--------|-------------|
| CRTD | Creado |
| REL | Liberado |
| TECO | Cierre tecnico |
| CLSD | Cerrado |
| LKD | Bloqueado |
| DLTD | Marcado para borrado |

**Transiciones de status controladas via:**
```
SPRO → Project System → Structures → Status Management
```

### 8.2 Perfil de Status de Usuario

**Ruta SPRO:**
```
Project System → Structures → Status Management →
  Define User-Defined Status Profile
```
**Transaccion:** `BS02`

**Configuracion del perfil:**
1. Crear perfil de status
2. Definir status individuales (sigla 4 chars + descripcion)
3. Definir transiciones permitidas
4. Asignar autorizaciones por status
5. Definir acciones de negocio bloqueadas/permitidas

**Ejemplo de perfil para proyecto de inversion:**
```
Status 0001: PDTE  → Pendiente aprobacion (inicial)
Status 0002: APRO  → Aprobado (desde PDTE)
Status 0003: EJEQ  → En ejecucion (desde APRO)
Status 0004: SUSP  → Suspendido (desde EJEQ)
Status 0005: COMP  → Completado (desde EJEQ)
Status 0006: CANC  → Cancelado (desde PDTE/APRO)
```

### 8.3 Acciones de Negocio Controladas por Status

**Ruta SPRO:**
```
BS02 → seleccionar status → Business Transaction/Objects
```

**Acciones de negocio PS:**
| Codigo | Descripcion |
|--------|-------------|
| PSPLO | Planificacion de costes en WBS |
| PSBU0 | Aprobacion de presupuesto |
| PSFIN | Confirmacion de actividades |
| PSLIQ | Liquidacion del proyecto |
| PSSVA | Facturacion del proyecto |

---

## 9. Programacion (Scheduling)

### 9.1 Parametros de Programacion

**Ruta SPRO:**
```
Project System → Dates → Scheduling →
  Define Scheduling Parameters for Networks
```
**Transaccion:** `OPUU` → Scheduling

**Parametros:**
| Parametro | Descripcion |
|-----------|-------------|
| Scheduling type | Adelante / Atras / Actual |
| Reduction strategy | Estrategia de reduccion de plazos |
| Scheduling reduction | % reduccion en sobrecarga |
| Factory calendar | Calendario de fabrica |
| Work center | Centro de trabajo por defecto |

### 9.2 Tipos de Programacion

**Ruta SPRO:**
```
Project System → Dates → Scheduling →
  Define Reduction Strategy
```

| Tipo | Descripcion |
|------|-------------|
| 1 | Forward scheduling (desde fecha inicio) |
| 2 | Backward scheduling (desde fecha fin) |
| 3 | Current date (desde hoy) |
| 4 | Only capacity planning date |

### 9.3 Calendarios de Fabrica

**Transaccion:** `SCAL` — Mantenimiento de calendarios

**Impacto PS:**
- Define dias laborables para calculo de duracion
- Afecta calculo de fechas en redes
- Debe sincronizarse con HR para confirmaciones

---

## 10. Integracion con Otros Modulos

### 10.1 Integracion PS-CO (Controlling)

**Ruta SPRO:**
```
Project System → Costs → Automatic and Periodic Allocations →
  Cost Element Allocation → Define Allocation Structure
```

**Parametros clave:**
- Area de valoracion (Valuation area) = Centro logistico
- Variante de ejercicio (Fiscal year variant)
- Moneda del plan

**Integracion con Plan de Costes CO:**
```
SPRO → Controlling → Cost Center Accounting →
  Planning → Define Planning Layout
```

### 10.2 Integracion PS-FI

**Ruta SPRO:**
```
Project System → Costs → Integration with FI →
  Define Account Assignment
```

**Configuracion de cuentas:**
- Compromisos (Commitments) → Cuenta balance
- Costes WIP → Cuenta WIP
- Liquidacion AuC → Cuenta activo en curso

### 10.3 Integracion PS-MM (Materiales)

**Ruta SPRO:**
```
Project System → Material → Define Parameters for Material
  Assignment in Projects
```

**Control de reservas:**
- Clase de movimiento para reservas de proyecto: 221/222
- Clase de movimiento para entregas: 261/262
- Imputacion especial de stock de proyecto (Q)

**Tipos de imputacion de pedidos:**
| Tipo | Descripcion |
|------|-------------|
| P | WBS Element |
| N | Red de proyecto |
| Q | Stock de proyecto |

### 10.4 Integracion PS-SD (Ventas)

**Ruta SPRO:**
```
Project System → Revenue → Sales and Distribution →
  Define Result Analysis Method
```

**Configuracion de reconocimiento de ingresos:**
- Metodo de analisis de resultados (POC, completed contract)
- Cuenta WIP ingresos
- Cuenta ingresos diferidos
- Clave de analisis de resultados (RA Key)

**Transaccion:** `OKG1` — Claves de analisis de resultados

### 10.5 Integracion PS-HR (Recursos Humanos)

**Ruta SPRO:**
```
Project System → Dates → Resource Planning →
  Define Workforce Planning Parameters
```

**Confirmaciones de tiempo:**
- CATS (Cross-Application Time Sheet) → actividades de red
- Clase de actividad para imputacion
- Clave de imputacion HR-CO

### 10.6 Integracion PS-IM (Investment Management)

**Ruta SPRO:**
```
Investment Management → Programs →
  Define Assignment between Programs and Projects
```

**Parametros:**
- Tipo de medida de inversion
- Asignacion de WBS a posicion de programa IM
- Presupuesto IM → Presupuesto PS (transferencia)

---

## 11. Datos Maestros PS

### 11.1 Centros de Trabajo (Work Centers)

**Transaccion:** `CR01` — Crear centro de trabajo
**Tabla:** `CRHD` (cabecera), `CRCA` (capacidades)

**Configuracion relevante para PS:**
```
SPRO → Project System → Structures → Networks →
  Work Centers → Assign Factory Calendar to Work Center
```

### 11.2 Puestos de Trabajo (HR — Personnel Areas)

**Para confirmaciones de tiempo:**
```
SPRO → Cross-Application Components → Time Sheet →
  Set Up Time Sheet → Integration with PS
```

### 11.3 Tipos de Hito

**Ruta SPRO:**
```
Project System → Structures → Operative Structures →
  Networks → Milestones → Define Milestone Categories
```

**Categorias tipicas:**
| Categoria | Uso |
|-----------|-----|
| 1 | Control de fechas (Scheduling) |
| 2 | Facturacion (Billing milestone) |
| 3 | Liberacion de actividades |
| 4 | Aprobacion de fase |

---

## 12. Parametros Globales PS

### 12.1 Transaccion OPS0

**Ruta SPRO:**
```
Project System → Structures → → Set Up Project System Parameters
```
**Transaccion directa:** `OPS0`

**Parametros globales:**
| Parametro | Descripcion | Recomendacion |
|-----------|-------------|---------------|
| Cost object | Objeto de coste (WBS/Network) | WBS para proyectos de inversion |
| Confirmation type | Tipo de confirmacion | Individual o colectiva |
| Actual version | Version de plan real | 000 (standard) |
| Plan version | Version de plan | 000 (standard) |
| Commitment management | Gestion de compromisos | Activar siempre |

### 12.2 Activacion de Gestion de Compromisos

**Ruta SPRO:**
```
Controlling → General Controlling → Production Startup →
  Activate Commitment Management
```
**Importante:** Requiere activacion por sociedad. Afecta pedidos con imputacion PS.

### 12.3 Versiones de Plan

**Ruta SPRO:**
```
Project System → Costs → Planning →
  Define Versions for Project Planning
```
**Tabla:** `PLKO`

**Versiones estandar:**
| Version | Uso |
|---------|-----|
| 0 | Plan operativo (activo) |
| 1 | Presupuesto original |
| 2 | Plan revisado |

---

## 13. Customizing Avanzado

### 13.1 Parametros de Confirmacion

**Ruta SPRO:**
```
Project System → Dates → Confirmations →
  Set Up Confirmations for Networks
```

**Opciones:**
- Confirmacion individual vs colectiva
- Recalculo de costes al confirmar
- Mensaje a Recursos Humanos

### 13.2 Clases de Documento PS

**Ruta SPRO:**
```
Project System → Costs → Actual Costs →
  Define Document Class for PS
```

### 13.3 Perfiles de Seleccion

**Ruta SPRO:**
```
Project System → Structures → Project Information System →
  Define Selection Profiles
```

Permiten preconfigurar criterios de busqueda en el Sistema de Informacion de Proyectos (CN41-CN47).

### 13.4 Perfiles de Resumen (Summarization Profiles)

**Ruta SPRO:**
```
Project System → Structures → Project Information System →
  Summarization → Define Summarization Profiles
```

**Usado en:** S_ALR_87013532, CN41N, reports jerarquicos.

---

## Tabla de Transacciones de Configuracion Rapida

| Transaccion | Descripcion |
|-------------|-------------|
| OPS0 | Parametros globales PS |
| OPSA | Perfiles de proyecto y WBS |
| OPSK | Mascara de codificacion |
| OPS9 | Perfil de presupuesto |
| OKO7 | Perfil de liquidacion |
| OP5A | Claves de control de actividad |
| OPUN | Perfil de red |
| OPUU | Parametros de red y programacion |
| BS02 | Perfil de status de usuario |
| OKG1 | Claves de analisis de resultados |
| SNRO | Rangos de numeros (objetos) |
| SCAL | Calendarios de fabrica |
| CR01 | Crear centro de trabajo |

---

## Orden Recomendado de Configuracion (Proyecto Nuevo)

```
1. OPS0   → Parametros globales
2. OPSK   → Mascara de codificacion
3. OPSA   → Perfil de proyecto
4. OPSA   → Perfil WBS
5. OPS9   → Perfil de presupuesto
6. OKO7   → Perfil de liquidacion
7. BS02   → Perfil de status usuario
8. OPUU   → Parametros de red
9. OP5A   → Claves de control
10. OKG1  → Claves analisis resultados (si aplica SD-PS)
```

---

*Referencia: SAP S/4HANA 2023 | Project System Configuration Guide*
*Transacciones probadas en entorno S/4HANA 2023 FPS01*
