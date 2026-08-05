# Árboles de Decisión — SAP RE-FX

## 1. ¿Business Entity, Property, Building o Rental Object?

```
¿Es la unidad efectivamente arrendable, la que se vincula al contrato?
├── SÍ → Rental Object
└── NO
      ¿Es la edificación física?
      ├── SÍ → Building
      └── NO
            ¿Es el terreno físico (con o sin edificación)?
            ├── SÍ → Property
            └── NO (es la unidad de gestión de más alto nivel del portafolio)
                  → Business Entity
```

## 2. ¿Lease-out o Lease-in?

```
¿La empresa es propietaria y arrienda a un tercero (genera ingreso)?
├── SÍ → Lease-out (inquilino = BP con rol AR)
└── NO (la empresa arrienda de un tercero, genera gasto)
      → Lease-in (arrendador externo = BP con rol AP)
      → Evaluar clasificación IFRS 16 obligatoriamente (ver árbol §6)
```

## 3. ¿Qué método de ajuste de renta usar?

```
¿El contrato pacta incrementos ya definidos en fechas fijas desde la firma?
├── SÍ → Renta escalonada (graduated)
└── NO
      ¿Se vincula a un índice de precios publicado?
      ├── SÍ → Ajuste por índice (CPI)
      └── NO
            ¿Depende de comparación con rentas de mercado (regulación de renta residencial)?
            ├── SÍ → Renta comparativa/benchmark
            └── NO
                  ¿Depende de las ventas del inquilino (retail)?
                  ├── SÍ → Renta variable por ventas (ver también renta mínima garantizada)
                  └── NO → Ajuste libre (manual, caso a caso)
```

## 4. ¿Qué factor de reparto usar en el Grupo de Participación?

```
¿El gasto tiene medición individual real por unidad (submetering)?
├── SÍ → Factor por consumo medido (validar si hay regulación local obligatoria, ej. HeizkostenV)
└── NO
      ¿El gasto varía naturalmente con el tamaño del espacio?
      ├── SÍ → Factor por superficie (m²) — el más común
      └── NO (gasto fijo independiente del tamaño)
            → Factor por unidad (partes iguales)
```

## 5. ¿Cómo tratar el costo de un objeto vacante en la liquidación?

```
¿La política del arrendador/contrato exige redistribuir el costo de vacancia entre inquilinos ocupados?
├── SÍ (y permitido por jurisdicción/regulación) → Redistribuir proporcionalmente
└── NO (patrón más común y recomendado)
      → El costo de vacancia queda a cargo del propietario/operador,
        contabilizado explícitamente, excluido del reparto entre inquilinos ocupados
```

## 6. ¿El contrato lease-in requiere reconocimiento completo IFRS 16 (ROU + pasivo)?

```
¿El plazo del arrendamiento es ≤ 12 meses y sin opción de compra?
├── SÍ → Posible excepción de corto plazo (según política contable del cliente)
└── NO
      ¿El activo subyacente califica como "bajo valor" según el umbral de materialidad del cliente?
      ├── SÍ → Posible excepción de bajo valor
      └── NO → Reconocimiento completo obligatorio: generar ROU asset + pasivo por arrendamiento
```

## 7. ¿Reprocesar la liquidación de gastos comunes o ajustar en el próximo ciclo?

```
¿El error se detectó ANTES de notificar la liquidación al inquilino?
├── SÍ → Corregir y re-ejecutar la liquidación del mismo periodo
└── NO (ya notificada)
      ¿El impacto es material?
      ├── SÍ → Ajuste explícito en la liquidación del periodo CORRIENTE, identificado como corrección de periodo anterior, con comunicación formal al inquilino
      └── NO → Evaluar corrección en el próximo ciclo regular, documentando el hallazgo
```

## 8. ¿El incidente es de RE-FX o de otro módulo?

```
¿El reclamo es sobre el objeto inmobiliario, contrato, condiciones, renta, gastos comunes o IFRS 16 del arrendamiento?
├── SÍ → Alcance RE-FX
└── NO
      ¿Es sobre mantenimiento físico del inmueble (reparaciones, instalaciones)?
      ├── SÍ → Alcance PM (objeto técnico compartido)
      └── NO (es sobre financiamiento/valoración general del inmueble no ligado al contrato)
            → Alcance FI-AA — redirigir al equipo correspondiente
```
