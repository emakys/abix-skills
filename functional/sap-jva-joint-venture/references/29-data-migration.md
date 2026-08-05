# Migración de Datos — SAP JVA

## 1. Alcance de una Migración JVA

Una migración a un nuevo sistema (implementación nueva, migración ECC → S/4HANA, o consolidación
de landscape) que incluya JVA debe cubrir, como mínimo:

- Maestro de Ventures (`T8J1`)
- Equity Groups con su histórico de vigencias (`T8J2` y detalle de partners/%)
- Catálogo de Recovery Indicators (`T8J3`) y su comportamiento parametrizado
- Atributo JV en los objetos CO existentes (centro de coste, orden, WBS)
- Histórico de cutback/billing si se requiere continuidad de reporting (`GJUBI`/`GJHIST`) —
  decisión de negocio: migrar histórico completo vs solo saldos de apertura

## 2. Decisión Clave: Migrar Histórico Completo vs Saldos de Apertura

- **Histórico completo**: preserva la capacidad de auditoría y reporting comparativo año contra
  año dentro del nuevo sistema, pero es significativamente más costoso de migrar (volumen y
  validación de `GJUBI` por periodo)
- **Solo saldos de apertura**: más simple y rápido, pero el histórico detallado queda disponible
  solo consultando el sistema legado (debe mantenerse accesible por el periodo de retención
  requerido, contractual o regulatorio)

La decisión debe tomarse considerando los plazos de auditoría de partner vigentes en los JOAs
activos — si un partner aún puede auditar periodos que quedarían solo en el sistema legado, ese
sistema debe permanecer disponible (aunque sea en modo solo lectura) durante toda esa ventana.

## 3. Orden Recomendado de Migración

```
1. Sociedades y Áreas de Controlling (prerrequisito estándar CO/FI)
2. Ventures (T8J1)
3. Equity Groups con vigencias históricas completas (T8J2 + detalle de partners)
4. Recovery Indicators y su customizing de comportamiento (T8J3)
5. Objetos CO (centro de coste/orden/WBS) con atributo JV asignado
6. (Si aplica) Histórico de GJUBI/GJHIST para continuidad de reporting
7. Saldos de apertura de cuentas por cobrar de partners (si no se migra el histórico detallado)
```

## 4. Validaciones Críticas Post-Migración

| Validación | Por qué |
|---|---|
| Suma de % de cada Equity Group migrado = 100% | Error de migración aquí invalida cualquier cutback futuro sobre ese venture |
| Vigencias de Equity Group sin huecos ni solapamientos | Mismo riesgo que en mantenimiento manual, amplificado por volumen de migración |
| Atributo JV de objetos CO migrados coincide con el legado | Verificar objeto por objeto en una muestra representativa, no solo el conteo total |
| Reconciliación de saldos de apertura de partners vs el legado | Evita arrastrar diferencias no explicadas al nuevo sistema desde el día uno |

## 5. Pruebas Recomendadas

1. Ejecutar un cutback de prueba en el sistema nuevo sobre un venture migrado, usando datos de un
   periodo ya cerrado en el legado, y comparar el resultado (`GJUBI`) contra el resultado histórico
   real de ese mismo periodo en el legado — es la prueba de aceptación más contundente de que la
   migración de maestros fue correcta
2. Validar la generación de billing (JIB) de prueba contra al menos un partner de cada tipo
   (operador/no-operador) para confirmar que la integración FI-AR también migró correctamente

## 6. Buenas Prácticas

1. Involucrar al equipo de auditoría/control interno en la definición del alcance de migración de
   histórico — es una decisión con implicancias de cumplimiento, no solo técnicas.
2. Documentar y comunicar a los partners (cuando el proceso de gobierno del JOA lo requiera) el
   cambio de sistema y cualquier cambio en el formato de statement resultante.
3. Mantener el sistema legado accesible (aunque sea solo lectura) durante toda la ventana de
   auditoría contractual vigente al momento de la migración.
