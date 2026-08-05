# Modelo de Datos S/4HANA — SAP RE-FX

## 1. ACDOCA como Tabla Única (Universal Journal)

En S/4HANA, FI y CO comparten la tabla única `ACDOCA` (Universal Journal). RE-FX no reemplaza este
modelo: la contabilización periódica de renta, gastos comunes y — en lease-in — la amortización del
pasivo por arrendamiento y del activo ROU, todas aterrizan en `ACDOCA` como cualquier otra
contabilización estándar de FI/CO.

## 2. Tablas Propias de RE-FX que Persisten en S/4HANA

Las tablas específicas de RE-FX (jerarquía de objetos GPO: `VIBDBE`/`VIBDPR`/`VIBDGB`/`VIBDOB`/
`VIBDIO`; contrato y condiciones: `VICNCN`/`VICNCND`) **persisten** como tablas propias del módulo
— no son tablas de totales redundantes con `ACDOCA`, sino el maestro de datos y la definición de
condiciones contractuales que no tiene equivalente en el Universal Journal. `ACDOCA` refleja el
**resultado contable** de aplicar esas condiciones (documentos de facturación periódica), no las
condiciones en sí.

## 3. Business Partner como Modelo Único de Socio de Negocio

Consistente con la simplificación general de S/4HANA (Customer/Vendor Integration — CVI), RE-FX no
mantiene un maestro de "inquilino" separado: el inquilino, arrendador externo y garante son todos
Business Partner con el rol correspondiente (AR/AP). Esto simplifica el análisis cruzado —
un mismo BP puede ser inquilino en un portafolio y, en otro contexto, proveedor de servicios de
mantenimiento del mismo inmueble, con un único maestro consolidado.

## 4. ROU Asset en el Modelo de Activos Fijos

El activo por derecho de uso (ROU, IFRS 16) se modela como un activo fijo estándar en `ANLA`, con
clase de activo dedicada — no requiere una tabla separada fuera del modelo estándar de FI-AA. Su
particularidad es de **negocio y customizing** (plazo del arrendamiento como base de amortización,
pasivo asociado siempre presente), no de modelo de datos técnico distinto.

## 5. Impacto de ACDOCA en Reporting RE-FX

La disponibilidad de todas las dimensiones (cuenta, centro de coste, centro de beneficio, activo
fijo, segmento) en una única tabla facilita construir reportes que combinen ingreso por renta,
costo operativo del inmueble y depreciación/amortización, sin los joins múltiples que requerían
las tablas de totales clásicas en ECC.

## 6. Consideración para Sistemas ECC

Si el sistema es ECC (RE clásico o RE-FX sobre ECC), las consultas de costo/ingreso deben adaptarse
a las tablas de totales clásicas (`COSP`/`COSS` para totales CO, `BSEG`/`BSID`/`BSAD` para partidas
FI) en vez de `ACDOCA`. Las tablas propias de RE-FX (jerarquía GPO, contrato, condiciones) se
mantienen conceptualmente iguales en ambos releases, ya que son específicas del módulo y no forman
parte de la simplificación FI/CO del Universal Journal.

## 7. Buenas Prácticas

1. No tratar las tablas GPO/contrato como redundantes o reemplazables por `ACDOCA` — son
   complementarias: unas definen la relación contractual, la otra refleja su ejecución contable.
2. Aprovechar el modelo unificado de Business Partner para construir reportes 360° del inquilino,
   combinando su rol como arrendatario con cualquier otro rol que tenga en el sistema.
3. Al migrar de ECC a S/4HANA, validar explícitamente el mapeo de reportes financieros que antes
   usaban tablas de totales clásicas hacia `ACDOCA`.
