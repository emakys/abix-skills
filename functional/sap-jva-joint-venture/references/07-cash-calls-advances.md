# Cash Calls — Anticipos de Fondos a Partners (SAP JVA)

## 1. Introducción

Un **Cash Call** es una solicitud de fondos que el operador emite a los partners **antes** de
incurrir en el gasto, típicamente para operaciones de alto monto o alta incertidumbre de timing
(perforación de un pozo, campaña de facilidades, un AFE grande). A diferencia del cutback — que
distribuye el costo **real ya incurrido** — el cash call es una **estimación** que luego se
reconcilia contra el resultado real del cutback del mismo periodo/actividad.

---

## 2. Por Qué Existen los Cash Calls

El operador no debería financiar con su propio flujo de caja actividades que, por contrato,
pertenecen proporcionalmente a todos los partners. Para actividades de monto significativo, se
solicita el dinero por adelantado:

1. Se estima el gasto esperado para el periodo/actividad (según el AFE aprobado)
2. Se calcula la porción de cada partner según su % de Equity Group
3. Se emite la solicitud de cash call a cada partner no-operador
4. Los partners transfieren los fondos antes o durante la ejecución del trabajo
5. Al cierre del periodo, el cutback determina el costo real; el cash call recibido se aplica como
   anticipo contra ese resultado

---

## 3. Reconciliación Cash Call vs Costo Real (Cutback)

Al finalizar el periodo:

- Si el costo real (cutback) es **mayor** que el cash call recibido → se genera un billing
  adicional por la diferencia
- Si el costo real es **menor** → el excedente queda como saldo a favor del partner (se aplica a
  futuros cash calls, o se devuelve según la política del venture)

Esta reconciliación es una de las razones por las que el proceso de cierre JVA debe mantener
trazabilidad clara entre cash calls emitidos y el resultado de cutback del mismo periodo/AFE — sin
esa trazabilidad, la reconciliación se vuelve un ejercicio manual propenso a error.

---

## 4. Relación con AFE

Los cash calls suelen dispararse a nivel de **AFE (Authorization for Expenditure)**, no a nivel de
venture completo — es común que un venture tenga actividad rutinaria (facturada vía cutback
normal, sin cash call) y, en paralelo, un AFE específico de gran monto que sí requiere
financiamiento anticipado vía cash call. Ver `09-afe-budgeting.md`.

---

## 5. Contabilización de un Cash Call

Cuando se recibe el pago de un cash call, se contabiliza como un **anticipo/pasivo** frente al
partner (el operador recibió dinero que aún no corresponde a un costo reconocido). Solo cuando el
cutback confirma el costo real, ese anticipo se "consume" y se reclasifica contra el resultado
real distribuido.

**Importante:** un cash call NO debe contabilizarse directamente como ingreso ni como reducción de
costo — es un pasivo (obligación de rendir cuentas) hasta que el cutback lo justifique.

---

## 6. Cash Calls y Non-Operador

Desde la perspectiva del partner no-operador, el cash call representa una salida de caja que debe
registrar como anticipo en su propia contabilidad, a reconciliar contra el statement de billing que
reciba posteriormente del operador. Este flujo vive fuera del sistema del operador (en el sistema
del partner), por lo que JVA solo modela el lado del operador — emisión de la solicitud y
reconciliación contra su propio cutback.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

Nota: el detalle de cash calls (montos solicitados, fecha, estado de cobro) suele vivir en tablas
específicas del proceso de cash call de JVA, cuyo nombre exacto conviene confirmar en el sistema
real antes de construir reportes; a nivel de impacto contable puede rastrearse el anticipo en las
cuentas de reconciliación del partner:

```sql
-- Saldo de anticipos (cash calls) pendientes de aplicar por partner, vía cuenta de reconciliación FI
GetSqlQuery("SELECT racct, rbukrs, sum(hsl) as saldo FROM acdoca WHERE racct = '{cuenta_anticipos_partner}' AND rbukrs = '{sociedad}' AND gjahr = '{year}' GROUP BY racct, rbukrs")
```

---

## 8. Errores Frecuentes en Cash Calls

| Error | Causa | Fix |
|---|---|---|
| Cash call no reconciliado contra cutback | Falta de vínculo explícito entre el cash call y el AFE/periodo del cutback | Establecer y documentar el criterio de vínculo (AFE, referencia de proyecto) antes del ciclo de cierre |
| Partner disputa el monto del cash call | Estimación del AFE desactualizada respecto al gasto real proyectado | Revisar y actualizar la proyección de gasto del AFE antes de emitir el siguiente cash call |
| Cash call contabilizado como costo en vez de anticipo | Error de mapeo contable en la contabilización del cobro | Corregir la cuenta de contrapartida usada; debe ser una cuenta de pasivo/anticipo |

---

## 9. Buenas Prácticas

1. **Vincular cada cash call explícitamente a un AFE o a un periodo de cutback** — sin esa
   trazabilidad, la reconciliación de fin de periodo se vuelve una reconstrucción manual costosa.

2. **Comunicar cash calls con la anticipación pactada en el JOA** — la mayoría de los acuerdos
   fijan un plazo mínimo de notificación (ej. 15-30 días) antes de que el partner deba transferir
   los fondos.

3. **Reconciliar cash calls contra cutback en cada cierre**, no acumular reconciliaciones
   pendientes de varios periodos — el riesgo de descuadre crece de forma no lineal con el tiempo
   sin reconciliar.

4. **Mantener un reporte de exposición de cash calls pendientes de reconciliación** como parte del
   set estándar de reporting de cierre JVA (ver `22-reporting.md`).
