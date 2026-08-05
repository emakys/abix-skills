# Ajuste de Renta — Rent Adjustment (SAP RE-FX)

## 1. Introducción

El ajuste de renta (`RERAADJUST` y transacciones relacionadas) es el proceso que recalcula el
importe de la renta base de un contrato conforme a un método pactado contractualmente, generando
un nuevo periodo de vigencia de la condición correspondiente sin destruir el histórico.

---

## 2. Métodos de Ajuste

### 2.1 Ajuste por Índice (Index-based / CPI)

La renta se vincula a un índice de precios publicado (típicamente un índice de inflación general o
sectorial). En cada fecha de revisión pactada, el sistema recalcula la renta aplicando la variación
del índice desde la última revisión (o desde el inicio del contrato).

**Datos requeridos:** índice de referencia mantenido en el sistema con sus valores históricos,
fórmula de aplicación (variación total, variación con tope máximo/mínimo, aplicación parcial de la
variación según lo pactado).

### 2.2 Renta Escalonada (Graduated / Staggered Rent)

Incrementos predefinidos en fechas fijas, acordados desde la firma del contrato — sin depender de
ningún índice externo. Ejemplo: renta de $10.000/mes el primer año, $10.500 el segundo,
$11.000 el tercero, ya pactado en el contrato original.

**Ventaja funcional:** es el método más simple de mantener porque no depende de actualizar un
índice externo — el calendario de incrementos ya está definido de antemano.

### 2.3 Renta Comparativa / de Referencia (Comparative / Benchmark Rent)

El ajuste se basa en la comparación con rentas de mercado de objetos similares, en vez de una
fórmula automática. Es común en jurisdicciones con regulación de renta residencial que exigen
justificar el nuevo monto contra una tabla o índice de referencia de mercado (por ejemplo, el
concepto de **Vergleichsmiete** en el mercado residencial alemán).

**Implicancia funcional:** requiere mantener una base de datos de referencia (tabla de renta
comparativa local o índice publicado por la autoridad correspondiente) y, frecuentemente, límites
legales a la magnitud del incremento permitido en un periodo determinado.

### 2.4 Renta Variable por Ventas (Sales-based / Percentage Rent)

Componente de renta calculado como porcentaje de las ventas reportadas por el inquilino — típico en
contratos de **retail** dentro de centros comerciales. Puede ser:
- **Renta variable pura**: toda la renta es un % de ventas
- **Renta mínima garantizada + variable**: un piso fijo (minimum guaranteed rent) más un
  componente adicional cuando las ventas superan cierto umbral

Requiere que el inquilino reporte periódicamente sus ventas (proceso de negocio externo al sistema,
o integrado vía interfaz), y que el sistema calcule la renta variable sobre esa base — ver
`11-sales-based-rent-settlement.md` para el detalle del proceso de liquidación.

### 2.5 Ajuste Libre (Free Adjustment)

Ajuste manual sin fórmula automática, para renegociaciones puntuales que no encajan en ningún
método estandarizado. El nuevo importe se ingresa directamente como nueva vigencia de la condición.

---

## 3. Flujo General del Proceso de Ajuste

```
1. Identificar contratos con condición de ajuste vencida/próxima a vencer
2. Determinar el método aplicable (leído del contrato — indexado/escalonado/comparativo/variable/libre)
3. Para métodos automáticos (índice, escalonado): ejecutar el cálculo del sistema
4. Para métodos manuales (comparativo, libre): input funcional del gestor de portafolio
5. Generar el nuevo periodo de vigencia de la condición de renta base con el importe recalculado
6. Notificar al inquilino (correspondencia formal, según requerimiento legal/contractual)
7. El nuevo importe aplica en la facturación periódica desde la fecha de vigencia definida
```

---

## 4. Consultas MCP Útiles (GetSqlQuery)

### Contratos con condición de renta próxima a requerir ajuste

```sql
SELECT vertrag, kschl, datbi
FROM vicncnd
WHERE kschl = '{tipo_condicion_renta}'
  AND datbi BETWEEN CURRENT_DATE AND CURRENT_DATE + 60
```

### Histórico de ajustes de un contrato (periodos consecutivos de la misma condición)

```sql
SELECT vertrag, kschl, kbetr, datab, datbi
FROM vicncnd
WHERE vertrag = '{contrato}'
  AND kschl = '{tipo_condicion_renta}'
ORDER BY datab
```

---

## 5. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Ajuste automático no se ejecutó en la fecha esperada | Programación de la corrida no ejecutada, o índice de referencia sin actualizar |
| Nuevo importe calculado no coincide con lo esperado manualmente | Fórmula de aplicación mal parametrizada (ej. no considera tope pactado) |
| Ajuste generó hueco de vigencia en la condición | Fecha de inicio del nuevo periodo mal calculada, no continúa inmediatamente después del periodo anterior |
| Renta variable por ventas no se calculó | Reporte de ventas del inquilino no cargado/integrado para el periodo |

---

## 6. Buenas Prácticas

1. **Mantener el índice de referencia actualizado con antelación a las fechas de ajuste** — un
   índice desactualizado es la causa más común de ajustes que "no salen" en la fecha esperada.

2. **Documentar la fórmula exacta pactada por contrato** (incluyendo topes, aplicación parcial del
   índice, fechas de revisión) — evita depender de memoria institucional al momento de auditar un
   ajuste.

3. **Validar límites legales aplicables antes de aplicar un ajuste comparativo/benchmark** en
   jurisdicciones reguladas — un ajuste que excede el límite legal es un riesgo de disputa y
   potencial sanción, no solo un error de cálculo.

4. **Generar la correspondencia de notificación al inquilino como parte del mismo proceso**, no
   como actividad separada — reduce el riesgo de aplicar un ajuste en el sistema sin la
   notificación formal correspondiente.
