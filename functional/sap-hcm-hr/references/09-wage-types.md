# Conceptos de Nómina (Wage Types)

## Tipos de Wage Types

### Wage Types Modelo (/1xx)

Los wage types modelo (también llamados wage types de sistema o técnicos) son creados y mantenidos por SAP. Se identifican por comenzar con `/`:

- **/101**: Base imponible para el impuesto sobre la renta
- **/559**: Importe neto a pagar al empleado
- **/560**: Neto antes de complementos de neto
- **/xxx**: Resultados técnicos intermedios del esquema de nómina

Estos wage types no deben modificarse directamente; sirven como base de cálculo y acumulación en el esquema de nómina.

### Wage Types de Cliente (9xxx / Mxxx)

Los wage types propios de la empresa se crean en el rango del cliente (habitualmente 9000-9999, o con prefijo de país). Se generan copiando un wage type modelo de la tabla T512W:

- **9001**: Salario base mensual
- **9010**: Plus de transporte
- **9020**: Horas extras al 75%
- **M001**: Wage type local (prefijo por país)

La copia garantiza que se hereda la configuración técnica del modelo y solo se ajustan los parámetros específicos.

## Tablas Principales de Wage Types

### T512T — Descripciones de Wage Types

Contiene el texto descriptivo de cada wage type por idioma (SPRSL) y país (MOLGA):

```sql
SELECT LGART, LGTXT FROM T512T
WHERE MOLGA = '08' AND SPRSL = 'S' AND LGART LIKE '9%'
```

### T511 — Wage Types Permitidos por Infotipo

La tabla T511 (vista V_T511) controla en qué infotipos puede usarse cada wage type:

- Infotipo 0008 (Basic Pay): salarios base
- Infotipo 0014 (Recurring Payments): conceptos fijos recurrentes
- Infotipo 0015 (Additional Payments): pagos adicionales puntuales

La permisibilidad se verifica al crear registros de infotipo; si el wage type no está permitido, el sistema muestra un error.

### T539A — Bases de Valoración (Valuation Bases)

Las bases de valoración definen cómo se calculan importes proporcionales o derivados:

- Permite calcular conceptos como un porcentaje de la base salarial
- Se usan en combinación con la valoración indirecta (Indirect Valuation)
- Ejemplo: un plus nocturno = 25% del salario hora, donde el salario hora se define como base de valoración

### T511K — Clases de Procesamiento (Processing Classes)

Las processing classes controlan el comportamiento del wage type dentro del esquema de nómina. Cada processing class tiene especificaciones (valores 0-9 o A-Z) que las funciones del schema leen para decidir cómo tratar el wage type:

| Processing Class | Descripción |
|-----------------|-------------|
| 01 | Relevante para el cálculo de neto |
| 10 | Tipo de cotización a la seguridad social |
| 20 | Relevante para el impuesto |
| 30 | Tratamiento en retroactivo |
| 68 | Relevante para el posting a FI |
| 71 | Acumulación en bases estadísticas |

Para consultar la configuración completa: **SM30 → V_512W_D** (processing classes de wage types).

### T54C2 — Clases de Acumulación (Cumulation Classes)

Las cumulation classes agrupan wage types para la creación de totales y bases:

- Cada wage type puede pertenecer a una o varias cumulation classes (marcadas con 'X')
- Los totales de cumulation class se almacenan en wage types /1xx
- Ejemplo: Cumulation Class 10 agrupa todos los conceptos sujetos a IRPF → acumula en /101
- Se consultan en **SM30 → V_T54C2** o directamente en T54C2

### T510 / T510A — Estructura Salarial de Convenio (Pay Scale Structure)

La estructura de convenio define las tablas salariales:

- **T510**: Grupos y niveles de convenio con importes por wage type
- **T510A**: Tipos de convenio (TRFAR) — identifica el convenio colectivo aplicable
- **T510G**: Zonas de convenio (TRFGB) — área geográfica o sectorial del convenio
- La combinación TRFAR + TRFGB + TRFGR (grupo) + TRFST (nivel) determina el salario de convenio
- Se mantiene con la transacción **PU30** (Pay Scale Groups) o directamente en SM30

## Valoración Indirecta (Indirect Valuation)

La valoración indirecta permite que el importe de un wage type se calcule automáticamente en lugar de introducirse manualmente:

- **Tabla T510**: Importe fijo tomado de la tabla de convenio según el grupo/nivel del empleado
- **T539A**: Importe calculado como porcentaje o fracción de una base de valoración
- Se configura en la vista **V_T539J** (módulo de valoración) y **V_T539A** (bases)
- En IT0008 (Basic Pay), los wage types con valoración indirecta muestran el importe calculado en gris (no editable manualmente)

## Permisibilidad por PS/PK

La permisibilidad de wage types por grupo/subgrupo de empleados (Personnel Subgroup / PS) controla qué wage types puede recibir cada colectivo:

- Vista de mantenimiento: **V_T511_B** (Wage Type Permissibility for each PS and ESG)
- La combinación de Employee Subgroup Grouping (ESG for CAP) y Pay Scale Type determina los wage types disponibles
- Si un wage type no es permisible para el colectivo del empleado, no puede añadirse en los infotipos de nómina

## Características de los Wage Types (Wage Type Characteristics)

Para cada wage type se configuran sus características básicas en la vista **V_T511**:

| Característica | Descripción |
|----------------|-------------|
| Unidad de importe | Moneda, unidades, horas |
| Clase de importe | Fijo, por unidad, por tiempo |
| Signo permitido | Positivo, negativo, ambos |
| Conversión de moneda | Si aplica conversión a moneda de nómina |
| Clase de tiempo | Si el wage type lleva horas/días |

## Consultas MCP Útiles para Wage Types

Con las herramientas MCP de SAP ADT se pueden realizar las siguientes consultas en sistemas conectados:

### Listar wage types activos con descripción
```abap
" Usar ExecuteAbapCode o RunADTQuery para:
SELECT a~lgart, b~lgtxt, a~betrg
  FROM t512w AS a
  INNER JOIN t512t AS b ON a~lgart = b~lgart
    AND b~molga = '08' AND b~sprsl = 'S'
  WHERE a~molga = '08'
  ORDER BY a~lgart
```

### Consultar processing classes de un wage type
```abap
SELECT lgart, klass, specc
  FROM t511k
  WHERE lgart = '9001'
  ORDER BY klass
```

### Verificar cumulation classes
```abap
SELECT lgart, wgtyc, kumkl
  FROM t54c2
  WHERE lgart = '9001'
```

### Consultar bases de valoración
```abap
SELECT * FROM t539a
  WHERE lgart = '9010'
```

### Ver estructura de convenio
```abap
SELECT trfar, trfgb, trfgr, trfst, lgart, betrg
  FROM t510
  WHERE molga = '08'
    AND trfar = 'TV'
    AND endda >= sy-datum
  ORDER BY trfgr, trfst
```

## Flujo de un Wage Type en el Esquema de Nómina

```
IT0008/IT0014/IT0015 (input manual)
        ↓
Wage type entra en la tabla interna IT del schema
        ↓
Funciones del schema (VALEN, AMT, NUM, etc.) calculan importe
        ↓
Processing classes controlan acumulaciones y tratamiento fiscal/SS
        ↓
Cumulation classes acumulan en wage types /1xx (bases)
        ↓
Wage types de resultado almacenados en cluster de nómina (B2, CU, etc.)
        ↓
Symbolic accounts → G/L accounts → Posting ACDOCA
```

## Consejos de Configuración en S/4HANA 2023

- Siempre copiar wage types desde el modelo SAP (T512W) usando **PU30** o la IMG, nunca crear desde cero
- Documentar las processing classes asignadas, especialmente PC68 (posting) y PC20 (impuesto)
- Revisar la permisibilidad en V_T511_B antes de asignar un nuevo wage type a un infotipo
- En sistemas cloud (SAP BTP HCM), algunas tablas de wage types se mantienen a través de **Manage Configuration** en Fiori en lugar de SM30
- Usar el **Wage Type Reporter** (PC00_M99_CWTR) para auditar los wage types activos en los registros de empleados
