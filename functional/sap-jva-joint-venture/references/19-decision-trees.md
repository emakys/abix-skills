# Árboles de Decisión — SAP JVA

## 1. ¿Cómo asignar el atributo JV a un objeto CO?

```
¿El objeto CO pertenece 100% a un único venture, siempre?
├── SÍ → Asignar Venture/Equity Group/Recovery Indicator en el MAESTRO del objeto (patrón recomendado)
└── NO (compartido entre ventures, o depende de cuenta/fecha/tipo de documento)
      → Usar SUSTITUCIÓN JVA (GGB1) con condiciones que discriminen el venture/RI correcto por línea
      → Asegurar que exista un campo/referencia en la línea que permita esa discriminación
            (si no existe, es un gap de diseño a resolver ANTES de seguir contabilizando)
```

## 2. ¿Qué Recovery Indicator usar?

```
¿El costo debe distribuirse entre partners según el JOA?
├── NO → Recovery Indicator "non-billable" (queda 100% en el operador)
└── SÍ
      ¿Además debe disparar recargo de gastos generales (overhead)?
      ├── SÍ → Recovery Indicator "billable + overhead-applicable"
      └── NO → Recovery Indicator "billable" estándar
      ¿Es una operación con partners no-consintientes (non-consent)?
      └── SÍ → usar Equity Group/Recovery Indicator DEDICADO a esa operación,
               nunca el Equity Group general del venture
```

## 3. ¿Cash Call o esperar al cutback normal?

```
¿La actividad es de monto significativo y requiere financiamiento anticipado (ej. AFE de perforación)?
├── SÍ → Emitir Cash Call vinculado al AFE, reconciliar contra el cutback real al cierre
└── NO → Dejar que el costo fluya por el ciclo normal de cutback mensual, sin anticipo
```

## 4. ¿Reabrir un periodo cerrado o hacer ajuste de periodo corriente?

```
¿El error se detectó ANTES de emitir billing (JIB) de ese periodo?
├── SÍ → Puede evaluarse revertir y re-ejecutar el cutback del mismo periodo
└── NO (billing ya emitido)
      ¿El impacto es material y el partner debe ser notificado formalmente?
      ├── SÍ → Ajuste de periodo anterior en el cutback del periodo CORRIENTE,
               identificado explícitamente como "prior period adjustment"
      └── NO → Evaluar corrección en el próximo ciclo regular, documentando el hallazgo
```

## 5. ¿Cómo modelar un AFE?

```
¿La actividad es de duración/complejidad significativa (ej. perforación de pozo, multi-fase)?
├── SÍ → Modelar como proyecto PS con WBS jerárquico
│         (presupuesto por fase, disponibilidad presupuestaria, atributo JV heredado)
└── NO (actividad puntual, monto menor)
      → Modelar como orden interna con presupuesto (KO22)
```

## 6. ¿Cómo tratar un farm-in/farm-out?

```
¿Cambió la composición de partners o su % de participación?
├── SÍ → Crear NUEVO periodo de Equity Group con VALFR = fecha efectiva del cambio
│         Cerrar el periodo anterior con VALTO = día previo
│         Verificar alta de Business Partner si es un partner nuevo (farm-in)
└── Adicionalmente, ¿hay carried interest pactado?
      └── SÍ → Requiere Recovery Indicator/Equity Group dedicado para el periodo de carry,
               distinto del reparto estándar
```

## 7. ¿El incidente es de JVA o de Production Accounting?

```
¿El reclamo es sobre el REPARTO DE COSTO entre partners?
├── SÍ → Alcance JVA (cutback, billing, recovery indicator)
└── NO (es sobre cantidad física producida/vendida, balanceo de producción, royalties)
      → Fuera del alcance de JVA — redirigir al equipo/herramienta de production accounting
        o al equipo fiscal/legal correspondiente
```
