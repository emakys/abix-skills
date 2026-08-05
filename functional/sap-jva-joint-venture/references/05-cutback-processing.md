# Cutback Processing — Corazón Transaccional de SAP JVA

## 1. Introducción

El **Cutback** es el proceso que toma los costos contabilizados al 100% en los libros del operador
(porque en la operación diaria del venture, el operador paga las facturas y contabiliza el gasto
completo) y los "recorta" (cut back) distribuyéndolos entre todos los partners del venture según su
% de participación en el Equity Group vigente. Es el proceso batch central de JVA, análogo en
importancia al cierre de periodo en CO.

---

## 2. Por Qué Existe el Cutback (Contexto de Negocio)

En un Joint Operating Agreement, el operador es quien gestiona la relación con proveedores, recibe
facturas y paga. Sería operacionalmente inviable que cada factura se dividiera y pagara
proporcionalmente por cada partner por separado. En su lugar:

1. El operador contabiliza el 100% del gasto en su propia contabilidad (booking)
2. Periódicamente (normalmente mensual), se ejecuta el cutback: el sistema calcula cuánto le
   corresponde a cada partner según su % de Equity Group
3. Se genera un registro de esa distribución (tabla `GJUBI`) que alimenta el Joint Interest Billing
4. El operador solo termina reteniendo, contablemente, su propio % de participación; el resto se
   convierte en una cuenta por cobrar contra los demás partners

---

## 3. Transacción Principal: GJ04 (Cutback Processing)

`GJ04` ejecuta la corrida de cutback para un venture (o Cutback Group) y periodo determinados.

**Parámetros típicos de la corrida:**
- Venture o Cutback Group a procesar
- Periodo/año fiscal
- Modo de ejecución: prueba (test run, sin contabilizar) vs producción (posting real)
- Alcance de objetos CO a incluir

**Salida:**
- Líneas de detalle en `GJUBI` con el desglose por partner, según el Recovery Indicator de cada
  línea origen
- Actualización de `GJHIST` con el estado de la corrida (para control de re-ejecuciones)

---

## 4. Qué Hace el Cutback, Línea por Línea

Para cada línea de costo/ingreso JV-relevante del periodo:

1. Identifica el Venture, Equity Group y Recovery Indicator de la línea
2. Resuelve el Equity Group vigente en la fecha efectiva de la línea
3. Según el comportamiento del Recovery Indicator:
   - Si es billable: calcula el monto correspondiente a cada partner (monto total × % de
     participación)
   - Si es non-billable: no genera distribución, la línea queda documentada pero sin reparto
   - Si es overhead-applicable: además del reparto normal, calcula el recargo de gastos generales
     configurado para ese venture/tipo
4. Escribe una línea `GJUBI` por cada combinación (línea origen × partner) resultante

---

## 5. Modo Prueba vs Modo Producción

**Siempre** ejecutar primero en modo de prueba (test run) antes de la corrida definitiva. El modo
de prueba permite:
- Verificar que todos los objetos CO esperados tienen atributo JV completo
- Detectar líneas sin Equity Group vigente (huecos de vigencia)
- Revisar el monto total distribuido vs el monto 100% booked (deben cuadrar, salvo líneas
  non-billable deliberadas)

Solo después de validar el resultado de prueba se ejecuta el run de producción, que contabiliza y
queda registrado en `GJHIST`.

---

## 6. Reversión y Re-ejecución

Si se detecta un error después de una corrida de producción (RI mal parametrizado, Equity Group
incorrecto), normalmente es necesario **revertir** la corrida de cutback de ese periodo antes de
poder re-ejecutarla con la corrección aplicada. La reversión debe evaluarse con cuidado si ya se
generó Joint Interest Billing a partir de ese cutback — revertir después de facturar implica
también anular/ajustar la factura ya emitida (ver `06-joint-interest-billing.md`).

**Regla operativa:** nunca re-ejecutar un cutback de producción sobre un periodo ya procesado sin
antes revisar `GJHIST` para confirmar el estado y sin coordinar con el equipo de billing.

---

## 7. Cutback Group — Orquestación de Corridas

Cuando un venture tiene múltiples sub-áreas de costo con necesidades de procesamiento distintas
(por ejemplo, distinta frecuencia de cierre, distinto responsable de aprobación), se agrupan en
Cutback Groups para poder correr el cutback de forma independiente y controlada por grupo, en vez
de forzar una única corrida monolítica para todo el venture.

---

## 8. Consultas MCP Útiles (GetSqlQuery)

### Historial de corridas de cutback de un venture

```sql
SELECT venture, gjahr, monat, runid, status
FROM gjhist
WHERE venture = '{venture}'
ORDER BY gjahr DESC, monat DESC
```

### Detalle de líneas distribuidas por partner en un periodo

```sql
SELECT partner, recind, sum(wkgbtr) as monto
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
GROUP BY partner, recind
ORDER BY partner
```

### Conciliación: costo 100% booked vs total distribuido en GJUBI

```sql
-- Costo 100% en ACDOCA para los objetos CO del venture
SELECT sum(hsl) as costo_100
FROM acdoca
WHERE rbukrs = '{sociedad}'
  AND gjahr = '{year}'
  AND rldnr = '0L'
  -- filtrar por objetos CO del venture según csks/aufk

-- Total distribuido en GJUBI
SELECT sum(wkgbtr) as total_distribuido
FROM gjubi
WHERE venture = '{venture}'
  AND gjahr = '{year}'
```

---

## 9. Errores Frecuentes en Cutback

| Error | Causa | Fix |
|---|---|---|
| Cutback ya procesado para el periodo | Doble ejecución de `GJ04` en producción sobre el mismo periodo | Revisar `GJHIST`; revertir antes de re-ejecutar |
| Diferencia entre costo 100% y total distribuido | Líneas sin Equity Group vigente, o RI non-billable no esperado | Revisar líneas excluidas una por una, corregir vigencia/RI |
| Corrida no incluye un objeto CO esperado | Objeto no está en el Cutback Group procesado, o carece de atributo JV | Verificar asignación de Cutback Group y atributo JV del objeto |
| Montos con diferencia de redondeo entre partners | Reparto proporcional con decimales; requiere regla de redondeo consistente | Validar configuración de tolerancia/redondeo del cutback |

---

## 10. Buenas Prácticas

1. **Ejecutar siempre en modo prueba primero**, sin excepción, incluso en cierres rutinarios ya
   validados en periodos anteriores — la composición de partners y objetos CO puede cambiar mes a
   mes.

2. **Cerrar el periodo JVA solo después de confirmar que el cutback de producción corrió sin
   pendientes** — cerrar prematuramente obliga a reapertura, con el riesgo de control interno que
   eso implica.

3. **Documentar cada re-ejecución de cutback** (motivo, quién autorizó, impacto en billing ya
   emitido) — es evidencia estándar solicitada en auditorías de partner.

4. **Coordinar la fecha de corrida de cutback con el cierre de MM/FI del periodo** — un documento
   de compra o factura que llega después de la corrida de cutback queda fuera de ese ciclo y se
   arrastra al periodo siguiente.
