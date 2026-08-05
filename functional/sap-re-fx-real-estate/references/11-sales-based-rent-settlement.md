# Renta Variable por Ventas — Sales-Based Rent Settlement (SAP RE-FX)

## 1. Introducción

En contratos de **retail** (locales dentro de centros comerciales, tiendas ancla, franquicias), es
común pactar un componente de renta variable calculado como porcentaje de las ventas reales del
inquilino, además o en lugar de una renta fija. Este proceso requiere capturar reportes de venta
periódicos y liquidar la renta variable resultante, de forma análoga en estructura a la liquidación
de gastos comunes pero con una fuente de dato externa al sistema (las ventas del inquilino).

---

## 2. Estructuras Contractuales Comunes

- **Renta puramente variable**: toda la renta es un % de ventas — poco común, normalmente reservado
  a inquilinos de muy bajo riesgo o acuerdos estratégicos específicos
- **Renta mínima garantizada (Minimum Guaranteed Rent) + variable**: el patrón más frecuente — el
  inquilino paga un piso fijo, y adicionalmente un % de ventas cuando estas superan un umbral
  (breakpoint) pactado
- **Escalones de porcentaje (tiered percentage)**: el % aplicado puede variar según tramos de venta
  (ej. 5% sobre los primeros $X, 3% sobre el excedente)

---

## 3. Flujo del Proceso

```
1. Definir la condición de renta variable en el contrato: % aplicable, umbral (breakpoint), tramos si aplica
2. El inquilino reporta sus ventas del periodo (mensual/trimestral según contrato)
3. Captura del reporte de ventas en el sistema (manual o vía integración/interfaz)
4. Cálculo de la renta variable: (ventas reportadas - umbral) × % pactado (o según fórmula de tramos)
5. Comparación contra la renta mínima garantizada ya facturada en el periodo
6. Generación de la facturación adicional (si la variable supera la mínima) o confirmación de que la mínima cubre el periodo
7. Contabilización de la partida FI-AR correspondiente
```

---

## 4. Captura de Ventas del Inquilino

El reporte de ventas es información que se origina **fuera del sistema RE-FX** (el punto de venta
del inquilino, no del arrendador) y debe capturarse mediante:

- Carga manual por el gestor de portafolio, basado en reportes enviados por el inquilino
  (frecuentemente exigidos contractualmente con periodicidad definida)
- Integración/interfaz si el contrato exige reporte electrónico directo (menos común, depende de la
  sofisticación del acuerdo y del inquilino)

**Riesgo funcional:** la falta de disciplina en la captura oportuna de ventas es la causa más común
de que la liquidación de renta variable se retrase respecto al calendario esperado — no es un
problema técnico del sistema sino de proceso de negocio.

---

## 5. Auditoría de Ventas Reportadas

Muchos contratos de renta variable incluyen una cláusula de **derecho de auditoría** del arrendador
sobre los libros de venta del inquilino, para verificar la exactitud de lo reportado. Este es un
proceso de negocio externo al sistema, pero el arrendador debe poder reconstruir fácilmente el
historial de ventas reportadas y los cálculos de renta variable resultantes ante una eventual
auditoría o disputa — razón adicional para mantener trazabilidad completa de cada reporte de venta
capturado.

---

## 6. Consultas MCP Útiles (GetSqlQuery)

### Condición de renta variable por ventas de un contrato

```sql
SELECT vertrag, kschl, kbetr, datab, datbi
FROM vicncnd
WHERE vertrag = '{contrato}'
  AND kschl = '{tipo_condicion_renta_variable}'
```

### Comparación renta mínima facturada vs variable calculada del periodo (conceptual)

```sql
-- Requiere combinar la condición de renta mínima (VICNCND) con el detalle de ventas capturado
-- y el resultado de la liquidación de renta variable (tabla específica del proceso, confirmar en el sistema real)
SELECT vertrag, kschl, kbetr
FROM vicncnd
WHERE vertrag = '{contrato}'
  AND kschl IN ('{tipo_condicion_renta_minima}', '{tipo_condicion_renta_variable}')
```

---

## 7. Errores Frecuentes

| Situación | Causa probable |
|---|---|
| Renta variable no se calculó para el periodo | Reporte de ventas del inquilino no capturado a tiempo |
| Monto calculado no coincide con lo esperado | Umbral o tramos de porcentaje mal parametrizados en la condición |
| Disputa del inquilino sobre el monto exigido | Falta de trazabilidad clara del cálculo, o ventas reportadas cuestionadas por el inquilino |
| Renta variable facturada por debajo de la mínima garantizada | Error en la lógica de comparación entre mínima y variable — la mínima siempre debe prevalecer si es mayor |

---

## 8. Buenas Prácticas

1. **Establecer un calendario disciplinado de solicitud y captura de reportes de venta**, con
   seguimiento activo de inquilinos morosos en el reporte (no solo en el pago).

2. **Documentar la fórmula exacta de cálculo por contrato** (umbral, tramos, periodicidad) de forma
   accesible para auditoría, no solo en el contrato legal original.

3. **Validar siempre que la renta facturada sea el máximo entre mínima garantizada y variable
   calculada** — nunca facturar por debajo de la mínima pactada.

4. **Conservar el historial completo de reportes de venta capturados** durante todo el periodo de
   retención contractual/legal aplicable, para soportar el derecho de auditoría del arrendador.
