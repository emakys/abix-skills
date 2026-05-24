# Features (PE03)

## Qué son los Features

Los features (características) son árboles de decisión utilizados en SAP HCM para determinar valores automáticamente en función de los datos organizativos y del empleado. Evitan la necesidad de introducir manualmente valores repetitivos en los infotipos, centralizando la lógica de defaulting en un único punto de mantenimiento.

Un feature evalúa campos de la estructura PERID (datos del empleado) y retorna un valor de retorno (return code) que el sistema utiliza como valor predeterminado o como control de comportamiento.

## Transacción de Mantenimiento: PE03

La transacción **PE03** es el punto central para visualizar y modificar features:

- Permite navegar el árbol de decisión de forma gráfica o en modo texto
- Cada nodo del árbol es una condición sobre un campo de PERID
- Las hojas del árbol contienen el valor de retorno (return code)
- Existe documentación técnica integrada por feature
- Los cambios se transportan como objetos de customizing (clase de transporte SPDD/SPDE o workbench según el caso)

### Estructura del árbol de decisión

```
Feature ABKRS
  └─ MOLGA = 08 (España)
       ├─ WERKS = 1000 → Return: '01' (Área de nómina mensual)
       ├─ WERKS = 2000 → Return: '02' (Área de nómina semanal)
       └─ Default      → Return: '01'
```

## Features Clave en HCM

### ABKRS — Payroll Area (Área de Nómina)

- **Propósito**: Determina el área de nómina (payroll area) que se asigna por defecto en IT0001
- **Campos de decisión habituales**: MOLGA, PERSG, PERSK, WERKS, BTRTL
- **Return code**: Clave del área de nómina (ej. '01', 'M1', 'WK')
- **Impacto**: Define el calendario de nómina, el período de pago y el agrupamiento de empleados para la ejecución de nómina

### LGMST — Wage Type Default (Tipo de Salario por Defecto)

- **Propósito**: Propone el wage type por defecto al crear registros en IT0008 (Basic Pay)
- **Campos de decisión**: MOLGA, PERSG, PERSK, TRFGR (grupo de convenio), TRFST (nivel de convenio)
- **Return code**: Clave del wage type (ej. '1000', 'M001')
- **Impacto**: Agiliza la creación de infotipos de salario asegurando el wage type correcto por colectivo

### PINCH — Infotype Screen (Pantalla de Infotipo)

- **Propósito**: Controla qué pantalla (dynpro) se muestra al abrir determinados infotipos
- **Campos de decisión**: MOLGA, PERSG, PERSK, INFTY (número de infotipo)
- **Return code**: Número de pantalla (ej. '2000', '3000')
- **Impacto**: Permite mostrar campos distintos según el colectivo de empleados, ocultando información no relevante

### SCHKZ — Work Schedule (Horario de Trabajo)

- **Propósito**: Determina la regla de horario de trabajo por defecto en IT0007 (Planned Working Time)
- **Campos de decisión**: MOLGA, PERSG, PERSK, WERKS, BTRTL
- **Return code**: Clave de la regla de horario (ej. 'NORM', 'PART')
- **Impacto**: Asegura que cada empleado recibe el calendario laboral correcto sin intervención manual

### TMSTA — Time Management Status

- **Propósito**: Define el status de gestión de tiempos por defecto en IT0007
- **Return code**:
  - '0' = Sin gestión de tiempos
  - '1' = Gestión de tiempos con evaluación automática
  - '7' = Gestión de tiempos sin evaluación (solo para nómina)
  - '9' = Entrada de tiempos externa
- **Impacto**: Controla si el empleado participa en la evaluación de tiempos (PT60/PT61)

### VESSION — Insurance (Seguro / Previsión Social)

- **Propósito**: Determina el esquema de seguros o previsión social aplicable
- **Return code**: Clave del esquema de seguros por colectivo
- **Impacto**: Usado en la configuración de beneficios (IT0168, IT0169) y cotizaciones sociales

### TARIF — Pay Scale (Estructura de Convenio)

- **Propósito**: Propone los valores de estructura salarial de convenio en IT0008
- **Campos de decisión**: MOLGA, PERSG, PERSK, WERKS
- **Return code**: Combinación de tipo de convenio (TRFAR) y zona de convenio (TRFGB)
- **Impacto**: Garantiza la correcta asignación de tablas salariales de convenio colectivo

## Campos de Decisión Más Utilizados

| Campo | Descripción | Tabla de referencia |
|-------|-------------|---------------------|
| MOLGA | País (Molga) | T005 |
| PERSG | Grupo de empleados | T501 |
| PERSK | Subgrupo de empleados | T503 |
| WERKS | Centro (Plant) | T001P |
| BTRTL | Subdivisión de personal | T001P |
| TRFAR | Tipo de convenio | T510A |
| TRFGB | Zona de convenio | T510G |
| INFTY | Número de infotipo | — |

## Valores de Retorno (Return Codes)

El return code es el valor que devuelve el feature tras recorrer el árbol de decisión. Dependiendo del feature, el return code puede ser:

- Una clave de customizing (ej. área de nómina, horario)
- Un indicador booleano ('X' / ' ')
- Un número de pantalla
- Un código de esquema o variante

Cuando ninguna rama del árbol coincide con los datos del empleado, se utiliza el nodo **Default** (rama sin condición), que debe existir siempre para evitar errores en la determinación.

## Cómo Leer y Modificar un Feature en PE03

1. Ejecutar **PE03** e introducir el nombre del feature (ej. ABKRS)
2. Seleccionar "Visualizar" para revisar el árbol o "Modificar" para editar
3. En el árbol, cada nodo muestra el campo evaluado y los valores posibles
4. Para añadir una rama: posicionarse en un nodo y usar "Insertar nodo"
5. Para cambiar un return code: seleccionar la hoja y modificar el valor
6. Activar los cambios con el botón "Activar" (genera una nueva versión del feature)
7. Transportar mediante orden de transporte de customizing

## Consultas Útiles

- **SE16 / SE16N sobre T52B5**: Lista de todos los features existentes con descripción
- **PE03 con F4**: Búsqueda de features por nombre o descripción
- **Documentación técnica**: En PE03, menú Pasar a → Documentación técnica, muestra los campos de PERID utilizables y el propósito del feature
- **Trace de features**: En el log de nómina (PC00_M99_CALC con log activado) se puede ver qué valor retornó cada feature para un empleado específico
