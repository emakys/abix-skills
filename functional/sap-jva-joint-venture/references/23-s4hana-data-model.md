# Modelo de Datos S/4HANA — SAP JVA

## 1. ACDOCA como Tabla Única (Universal Journal)

En S/4HANA, FI y CO comparten la tabla única `ACDOCA` (Universal Journal). JVA no reemplaza este
modelo: los objetos CO JV-relevantes (centro de coste, orden, WBS) contabilizan sus líneas en
`ACDOCA` exactamente igual que cualquier otro objeto CO — la diferencia es que, cuando el objeto
tiene atributo JV, esa línea es candidata a ser procesada por el cutback.

## 2. Cómo se Refleja el Atributo JV en el Universal Journal

El atributo JV (`VENTURE`/`EGRUP`/`RECIND`) se hereda del objeto CO de imputación (o de la
sustitución JVA aplicada en el momento de contabilizar) y puede quedar disponible como campos
adicionales/append en `ACDOCA` según el diseño de la implementación — esto permite hacer analítica
directa sobre `ACDOCA` filtrando por venture, sin necesariamente pasar siempre por `GJUBI`. La
disponibilidad exacta de estos campos como columnas nativas o como append depende del release y de
si JVA está activado como embebido en S/4HANA o como componente clásico integrado — no asumir
automáticamente que existen sin confirmarlo en el Data Dictionary del sistema real.

## 3. Tablas Propias de JVA que Persisten en S/4HANA

A diferencia de las tablas de totales CO clásicas (`COSP`/`COSS`/`COEP`), que fueron eliminadas en
S/4HANA en favor de `ACDOCA`, las tablas específicas de JVA (`T8J1`, `T8J2`, `T8J3`, `GJUBI`,
`GJHIST`) **sí persisten** como tablas propias del módulo — no son tablas de totales redundantes
con `ACDOCA`, sino el resultado específico del proceso de cutback/billing, que no tiene equivalente
directo en el Universal Journal.

## 4. Relación entre GJUBI y ACDOCA

`GJUBI` no es una copia de `ACDOCA`: es el resultado del cálculo de cutback aplicado sobre las
líneas relevantes de `ACDOCA` (u otras fuentes de costo real). La reconciliación entre ambas
tablas (ver `10-settlement-closing.md` §3) es, precisamente, la validación de que ese cálculo no
"perdió" ni "duplicó" costo en el proceso.

## 5. Impacto de ACDOCA en Reporting JVA

La disponibilidad de todas las dimensiones (cuenta, centro de coste, orden, WBS, profit center,
segmento) en una única tabla facilita construir reportes que combinen la vista contable estándar
con el atributo JV, sin necesidad de los joins múltiples que requerían las tablas de totales
clásicas en ECC.

## 6. Consideración para Sistemas ECC / IS-OIL Clásico

Si el sistema es ECC con JVA sobre IS-OIL clásico (no S/4HANA), las consultas de costo 100% deben
adaptarse a las tablas de totales clásicas (`COSP`/`COSS` para totales, `COEP` para partidas
individuales) en vez de `ACDOCA`, aunque las tablas propias de JVA (`T8J1`/`T8J2`/`T8J3`/`GJUBI`/
`GJHIST`) se mantienen conceptualmente iguales en ambos releases.

## 7. Buenas Prácticas

1. Confirmar en el Data Dictionary del sistema real si `ACDOCA` tiene los campos de atributo JV
   disponibles nativamente antes de diseñar reportes que dependan de ellos.
2. No tratar `GJUBI` como redundante o reemplazable por `ACDOCA` — son complementarias, cada una
   responde una pregunta distinta (costo real vs costo distribuido).
3. Al migrar de ECC/IS-OIL clásico a S/4HANA, validar explícitamente el mapeo de reportes que
   antes usaban tablas de totales clásicas.
