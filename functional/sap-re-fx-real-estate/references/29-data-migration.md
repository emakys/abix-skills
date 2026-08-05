# Migración de Datos — SAP RE-FX

## 1. Alcance de una Migración RE-FX

Una migración a un nuevo sistema (implementación nueva, migración ECC/RE clásico → S/4HANA RE-FX, o
consolidación de landscape) debe cubrir, como mínimo:

- Jerarquía completa de objetos inmobiliarios (Business Entity → Property → Building → Rental
  Object → Architectural Object)
- Contratos vigentes con su histórico de condiciones (`VICNCN`/`VICNCND`)
- Business Partners de inquilinos, arrendadores externos y garantes, con sus roles completos
- Grupos de Participación y su composición vigente para liquidación de gastos comunes
- Para contratos lease-in bajo IFRS 16: saldo de pasivo por arrendamiento y ROU asset ya
  reconocidos en el sistema legado, con continuidad del plan de amortización
- Histórico de liquidaciones de gastos comunes si se requiere continuidad de reporting/auditoría —
  decisión de negocio: migrar histórico completo vs solo saldos de apertura

## 2. Migración desde RE Clásico (no RE-FX) — Consideración Especial

Si el sistema origen usa el **RE clásico** (jerarquía rígida, no GPO), la migración a RE-FX no es
un simple mapeo campo a campo: requiere **remodelar la estructura de datos** hacia la arquitectura
de objetos de propósito general con vistas de uso. Este es un esfuerzo de diseño significativo, no
solo de ejecución técnica de migración.

## 3. Decisión Clave: Migrar Histórico Completo vs Saldos de Apertura

- **Histórico completo**: preserva capacidad de auditoría y reporting comparativo, especialmente
  relevante para liquidaciones de gastos comunes que pueden ser objeto de disputa retroactiva con
  inquilinos, pero es más costoso de migrar (volumen y validación)
- **Solo saldos de apertura**: más simple y rápido, pero el histórico detallado queda disponible
  solo consultando el sistema legado durante el periodo de retención requerido (contractual o
  regulatorio, considerando también plazos de auditoría fiscal aplicables a documentos inmobiliarios)

## 4. Migración de Contratos Lease-in con IFRS 16 ya Reconocido

Caso particularmente sensible: si el cliente ya reconocía IFRS 16 en el sistema legado (nativamente
en RE-FX, o mediante un proceso manual/herramienta externa antes de adoptar la funcionalidad
embebida), la migración del **saldo de apertura del pasivo y del ROU asset** debe hacerse con
precisión — un error aquí distorsiona directamente el balance de apertura del nuevo sistema, con
implicancias de auditoría financiera.

## 5. Orden Recomendado de Migración

```
1. Sociedades y Áreas de Controlling (prerrequisito estándar CO/FI)
2. Business Partners de inquilinos/arrendadores/garantes con roles completos
3. Jerarquía de objetos inmobiliarios (Business Entity → Property → Building → Rental Object → Architectural Object)
4. Grupos de Participación y su composición vigente
5. Contratos con su histórico de condiciones completo
6. (Si aplica) Saldo de apertura de pasivo por arrendamiento y ROU asset (lease-in con IFRS 16)
7. (Si aplica) Histórico de liquidaciones de gastos comunes para continuidad de reporting
8. Saldos de apertura de cuentas por cobrar de inquilinos / por pagar a arrendadores externos
```

## 6. Validaciones Críticas Post-Migración

| Validación | Por qué |
|---|---|
| Superficie de cada Rental Object migrada coincide con el legado | Base de renta por m² y de todo el prorrateo de gastos comunes |
| Vigencias de condiciones sin huecos ni solapamientos | Mismo riesgo que en mantenimiento manual, amplificado por volumen de migración |
| Suma de factores de cada Grupo de Participación consistente con el legado | Error aquí invalida cualquier liquidación futura sobre esa unidad |
| Saldo de pasivo/ROU asset migrado coincide con el saldo del legado a la fecha de corte | Crítico para el balance de apertura, riesgo de auditoría financiera si no cuadra |
| Reconciliación de saldos de apertura de inquilinos/arrendadores vs el legado | Evita arrastrar diferencias no explicadas al nuevo sistema desde el día uno |

## 7. Pruebas Recomendadas

1. Ejecutar una facturación periódica de prueba en el sistema nuevo sobre un contrato migrado, y
   comparar el resultado contra el histórico real del mismo periodo en el legado
2. Ejecutar una liquidación de gastos comunes de prueba sobre una Unidad de Liquidación migrada,
   comparando contra un periodo ya cerrado en el legado, para validar que el Grupo de Participación
   migró correctamente
3. Para lease-in con IFRS 16, validar que el plan de amortización proyectado desde el saldo migrado
   coincide con el plan original del contrato desde su reconocimiento inicial

## 8. Buenas Prácticas

1. Involucrar al equipo de FI/Accounting en la validación del saldo de apertura de pasivo/ROU
   asset migrado — es una decisión con implicancias de cumplimiento contable, no solo técnicas.
2. Documentar y comunicar a los inquilinos (cuando el cambio de sistema afecte el formato de
   correspondencia/facturación) cualquier cambio relevante en el proceso de facturación o
   liquidación resultante de la migración.
3. Mantener el sistema legado accesible (aunque sea solo lectura) durante toda la ventana de
   retención documental/fiscal aplicable a los documentos inmobiliarios migrados.
