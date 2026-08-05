# Guía de Configuración IMG — SAP JVA

## 1. Ruta General en SPRO

```
SPRO → IMG → Financial Accounting (New) → Joint Venture Accounting
```

(La ruta exacta puede variar según si JVA está instalado como componente clásico add-on o
embebido; en algunos landscapes aparece bajo un nodo propio de industria — "Oil & Gas" / "Joint
Venture Accounting" — en vez de colgar de Financial Accounting. Confirmar el árbol real navegando
`SPRO` en el sistema del cliente antes de documentar procedimientos formales.)

## 2. Bloques de Configuración Principales

### 2.1 Estructura Organizativa

- Asignación Sociedad ↔ Área de Controlling (estándar CO, prerrequisito)
- Activación de JVA para la sociedad/área de controlling correspondiente

### 2.2 Master Data JVA

- Definir Ventures (`T8J1`)
- Definir Equity Groups y su vigencia (`T8J2`)
- Mantener partners y % de participación dentro de cada Equity Group

### 2.3 Recovery Indicators

- Definir el catálogo de Recovery Indicators (`T8J3`)
- Configurar el comportamiento de cada Recovery Indicator (billable/non-billable,
  overhead-applicable, estadístico)

### 2.4 Cutback

- Definir Cutback Groups
- Parametrizar reglas de la corrida de cutback (redondeo, tolerancias, alcance por defecto)

### 2.5 Overhead Recovery

- Definir tasas de overhead por venture/fase (perforación vs producción, si aplica)
- Configurar topes contractuales (caps) si el JOA los exige

### 2.6 Billing (JIB)

- Configurar el formato/layout de statement
- Vincular la generación de billing con la determinación de cuenta de reconciliación FI-AR del
  partner

### 2.7 Sustitución JVA

- `GGB1` → definir reglas de sustitución para derivar/sobrescribir Venture/Equity Group/Recovery
  Indicator a nivel de línea cuando el maestro del objeto CO no es suficiente

## 3. Prerrequisitos de Otros Módulos

| Prerrequisito | Módulo | Por qué |
|---|---|---|
| Área de Controlling activa | CO | JVA opera sobre objetos CO existentes |
| Centros de coste/órdenes/WBS creados | CO/PS | Deben existir antes de poder marcarlos JV-relevantes |
| Business Partner de cada partner dado de alta | FI (AR/AP) | Necesario para generar JIB |
| Determinación de cuentas configurada | FI (OBYC y análogos) | El costo debe llegar correctamente clasificado antes de que JVA lo reparta |

## 4. Checklist de Puesta en Marcha de un Nuevo Venture

1. Crear el Venture (`T8J1`) con indicador de operador correcto
2. Crear el/los Equity Group(s) con vigencia y % de partners sumando 100%
3. Confirmar que todos los partners tienen Business Partner completo (datos bancarios, cuenta de
   reconciliación)
4. Definir/confirmar los Recovery Indicators a usar (reutilizar del catálogo global si aplica)
5. Marcar los objetos CO del venture (centro de coste/orden/WBS) con Venture/Equity
   Group/Recovery Indicator por defecto
6. Configurar sustituciones JVA si hay objetos CO compartidos entre ventures
7. Configurar tasa de overhead si el JOA la contempla
8. Ejecutar un cutback de prueba con datos de un periodo simulado antes de ir a producción

## 5. Buenas Prácticas de Configuración

1. Versionar y documentar cada configuración de Recovery Indicator con su propósito de negocio.
2. Validar la suma de % de cada Equity Group inmediatamente después de mantenerlo, no esperar al
   cutback para descubrir el error.
3. Involucrar al equipo legal/contractual en la definición de tasas de overhead y reglas de
   non-consent — son cláusulas del JOA, no decisiones puramente técnicas.
