# Payroll — Avanzado

## Off-Cycle Payroll

El off-cycle payroll permite ejecutar nóminas fuera del ciclo regular para casos como pagos anticipados, correcciones urgentes o bonificaciones extraordinarias. Se ejecuta mediante la transacción PC00_M99_CALC con el indicador off-cycle activado. Los tipos de off-cycle más comunes son:

- **Bonus run**: pago de bonificaciones puntuales sin afectar el ciclo regular
- **Advance payment**: anticipo de sueldo, se descuenta en la nómina regular siguiente
- **Manual payment**: pagos manuales que deben registrarse en el sistema

## Bonus Runs

Los bonus runs son ejecuciones de nómina específicas para el pago de incentivos, comisiones o gratificaciones. Se configuran con un reason type diferenciado y pueden incluir solo ciertos wage types. El sistema genera resultados separados que se consolidan en el posting a FI.

## Garnishments / Embargos (IT0195)

El infotipo 0195 gestiona los embargos de salario (garnishments). Permite registrar:

- Tipo de embargo (child support, tax levy, creditor garnishment)
- Importe fijo o porcentaje del salario disponible
- Prioridad cuando existen múltiples embargos simultáneos
- Fechas de inicio y fin del embargo
- Datos del acreedor o entidad beneficiaria

El esquema de nómina calcula automáticamente el importe embargable respetando el mínimo inembargable según la legislación local (MOLGA).

## Tax Calculation

El cálculo de impuestos en HCM se realiza mediante funciones del esquema de nómina específicas por país (MOLGA). En S/4HANA 2023:

- Las tablas de tramos impositivos se mantienen en T510J / T510E según el país
- El wage type /101 acumula la base imponible
- Las funciones TAX* aplican la retención correspondiente
- El resultado se almacena en wage types de tax withholding (ej. /401 en Alemania)
- La integración con el módulo Tax Reporter permite la declaración periódica a las autoridades

## Social Security / Seguridad Social

El cálculo de cuotas a la seguridad social sigue la misma lógica por MOLGA. Los elementos principales son:

- Bases de cotización calculadas por el esquema (wage types /1xx)
- Topes máximos y mínimos de cotización configurados en tablas por país
- Cuotas del empleado y del empleador calculadas y almacenadas por separado
- Integración con IT0077 (Additional Personal Data) e IT0169 (Savings Plans) según el país

## Retroactive Accounting (Cálculo Retroactivo)

El retroactivo es uno de los mecanismos más importantes en HCM. Cuando se modifica un infotipo con fecha en el pasado, el sistema recalcula los períodos afectados automáticamente.

### Earliest Retro Date (Fecha más antigua de retroactivo)

- Definida en IT0003 (Payroll Status) campo "Earliest MD change"
- Limita hasta qué período puede ir el retroactivo
- Se configura a nivel de payroll area en la tabla T549Q
- El parámetro BEGDA del schema controla el límite inferior

### Delta Retro

El retroactivo delta calcula únicamente las diferencias entre el resultado anterior y el nuevo:

- El sistema almacena resultados históricos en los clusters de nómina (B2 para Alemania, etc.)
- La función RETRO del schema identifica los períodos a recalcular
- Los wage types delta (/5xx generalmente) recogen las diferencias
- Estos deltas se incluyen en el período actual para el pago y el posting

## Payroll Journal (PC00_M99_CEDT)

El journal de nómina es el informe estándar para revisar los resultados:

- Transacción: **PC00_M99_CEDT** (internacional) o variantes por país
- Muestra wage types, importes brutos, deducciones y neto por empleado
- Permite comparar períodos actuales con anteriores (retroactivos)
- Filtros por payroll area, período, división, centro
- Exportable a Excel para reconciliación

## DME File — Transferencia Bancaria

El fichero DME (Data Medium Exchange) es el archivo de pago para la transferencia bancaria:

- Se genera con **PC00_M99_CDTA** (o equivalente por país)
- Requiere IT0009 (Bank Details) correctamente configurado en el empleado
- El formato del fichero depende del país: SEPA XML en Europa, ACH en USA, etc.
- La tabla T042Z define los programas de pago por país
- El fichero se transfiere al banco o se carga en FI-AP (Accounts Payable)

## Posting to FI (PC00_M99_CIPE) — Integración con ACDOCA

El proceso de posting transfiere los resultados de nómina al módulo financiero:

- Transacción: **PC00_M99_CIPE** para crear el documento de posting
- En S/4HANA 2023 los asientos van directamente a **ACDOCA** (tabla universal de journal entries)
- El proceso se ejecuta en dos pasos: simulación (sin documento real) y posting real
- Los documentos generados incluyen referencia al período de nómina y payroll area

### Symbolic Accounts (T030)

Los symbolic accounts son la clave de integración entre HCM y FI:

- Tabla **T030** mapea symbolic accounts a cuentas de mayor (G/L accounts)
- Cada wage type se asigna a un symbolic account en la tabla T52EK / OGSYMB
- El symbolic account actúa como capa de abstracción entre nómina y contabilidad
- Permite cambiar cuentas contables sin modificar la configuración de wage types

### Wage Type Posting

El flujo de posting por wage type es:

1. Wage type → Symbolic account (T52EK)
2. Symbolic account → G/L account (T030, dependiente de chart of accounts)
3. G/L account → Documento FI en ACDOCA
4. Objetos de coste (Cost Center, Orden, WBS) tomados de IT0001 / IT0027

## Reconciliación Nómina-FI

La reconciliación entre los totales de nómina y los documentos FI es un proceso crítico de cierre:

- Comparar el payroll journal (PC00_M99_CEDT) con los documentos FI generados
- Verificar que todos los empleados del run tienen posting
- Usar el informe **PC00_M99_RWBKU00** para listar documentos de posting por período
- En S/4HANA 2023 se puede usar el **Financial Closing Cockpit** para automatizar la reconciliación
- Las diferencias pueden originarse por: empleados sin cuenta contable asignada, wage types sin symbolic account, o errores de imputación de centro de coste
