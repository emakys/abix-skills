# Guía de Configuración IMG — SAP RE-FX

## 1. Ruta General en SPRO

```
SPRO → IMG → Flexible Real Estate Management
```

(Este es el nodo propio de RE-FX en el árbol IMG, a diferencia de módulos de industria que cuelgan
de Financial Accounting. Confirmar el árbol detallado navegando `SPRO` en el sistema del cliente,
ya que la profundidad de submenús puede variar según el release.)

## 2. Bloques de Configuración Principales

### 2.1 Estructura Organizativa

- Asignación Sociedad ↔ Área de Controlling (estándar CO/FI, prerrequisito)
- Activación de RE-FX para la sociedad correspondiente
- Definición de vistas de uso (usage views) disponibles

### 2.2 Objetos Inmobiliarios (GPO)

- Perfiles de numeración para Business Entity, Property, Building, Rental Object
- Tipos de uso de Rental Object (oficina, retail, industrial, residencial)
- Configuración de estándares de medición de superficie (Architectural Object)

### 2.3 Contratos

- Tipos de contrato (lease-out, lease-in, general/otros)
- Perfiles de numeración de contrato
- Reglas de determinación de cuenta contable para la contabilización periódica

### 2.4 Condiciones

- Tipos de condición (renta base, adelanto gastos comunes, depósito, indexación, renta variable)
- Determinación de impuesto por tipo de condición/uso

### 2.5 Ajuste de Renta

- Configuración de métodos de ajuste (índice, escalonado, comparativo, variable por ventas, libre)
- Mantenimiento de índices de referencia (valores históricos para ajuste por CPI)

### 2.6 Liquidación de Gastos Comunes

- Definición de Unidades de Liquidación
- Definición de Grupos de Participación y sus factores de reparto
- Configuración del tratamiento de vacancia dentro del reparto
- Si aplica, configuración de reglas de submetering/split fijo-variable para calefacción

### 2.7 IFRS 16 (Lease-in)

- Configuración de clase(s) de activo ROU en FI-AA
- Parametrización de tasa de descuento y metodología de plazo del arrendamiento
- Umbrales de excepción (corto plazo, bajo valor) según política contable del cliente

## 3. Prerrequisitos de Otros Módulos

| Prerrequisito | Módulo | Por qué |
|---|---|---|
| Área de Controlling activa | CO | RE-FX puede asignar objetos de renta a centro de coste/beneficio |
| Business Partner con roles FI-AR/AP configurados | FI | Necesario para generar partidas de facturación periódica y liquidación |
| Determinación de cuentas configurada | FI (OBYC y análogos) | El ingreso/gasto de renta debe clasificarse correctamente antes de contabilizar |
| Clase(s) de activo ROU definidas | FI-AA | Prerrequisito obligatorio antes de activar el primer contrato lease-in |

## 4. Checklist de Puesta en Marcha de un Nuevo Portafolio/Business Entity

1. Activar RE-FX para la sociedad correspondiente
2. Crear la Business Entity y su jerarquía de objetos (Property → Building → Rental Object)
3. Confirmar tipo de uso y superficie de cada Rental Object
4. Definir/confirmar tipos de contrato y de condición a usar
5. Configurar Unidades de Liquidación y Grupos de Participación si el portafolio incluye
   liquidación de gastos comunes
6. Confirmar clase de activo ROU configurada si habrá contratos lease-in
7. Validar determinación de cuenta e impuesto para los tipos de condición del portafolio
8. Ejecutar un contrato de prueba de punta a punta (creación, condición, facturación periódica)
   antes de ir a producción

## 5. Buenas Prácticas de Configuración

1. Involucrar al equipo de Accounting Policy en la definición de umbrales y metodología IFRS 16
   antes de configurar clases de activo ROU — son decisiones contables, no puramente técnicas.
2. Validar la consistencia de la jerarquía de objetos (sin huecos, sin duplicados) inmediatamente
   después de su carga inicial, no esperar al primer contrato para descubrir errores.
3. Documentar el criterio de diseño de cada Grupo de Participación con su justificación de negocio,
   especialmente el tratamiento de vacancia y de gastos con submetering.
