# Arboles de Decision PP

## 1. Tipo de produccion

```
¿Producto estandar con demanda estable?
├── SI → ¿Volumen alto, poca variacion?
│   ├── SI → Repetitive Manufacturing (MFBF)
│   └── NO → Orden produccion discreta (CO01)
└── NO → ¿Industria de proceso (quimica, farma, alimentos)?
    ├── SI → Orden de proceso PP-PI (COR1)
    └── NO → ¿Ingenieria por proyecto?
        ├── SI → Engineer-to-Order (PS + PP)
        └── NO → Orden produccion discreta (CO01)
```

## 2. Estrategia MTS vs MTO

```
¿Se produce contra pronostico o contra pedido?
├── Pronostico (MTS) → ¿Se consume PIR con pedidos?
│   ├── SI → Strategy 10 (MTS with consumption)
│   │   └── ¿Solo componentes planificados, final assembly por pedido?
│   │       ├── SI → Strategy 40 (Planning with final assembly)
│   │       └── NO → Strategy 10
│   └── NO → Strategy 11 (MTS gross requirements)
├── Pedido (MTO) → ¿Stock individual por pedido?
│   ├── SI → Strategy 20 (Make-to-order individual)
│   └── NO → ¿Planificacion individual por pedido?
│       ├── SI → Strategy 50 (Planning individual customer)
│       └── NO → Strategy 20
└── Combinado → Strategy 40 (componentes MTS + final MTO)
```

## 3. Tipo MRP (DISMM)

```
¿Se requiere planificacion?
├── NO → ND (sin planificacion)
├── SI → ¿Basada en demanda (pedidos/PIR)?
│   ├── SI → PD (MRP determinista)
│   └── NO → ¿Basada en consumo historico?
│       ├── SI → ¿Pronostico automatico?
│       │   ├── SI → VB (Reorder point automatico)
│       │   └── NO → VM (Reorder point manual)
│       └── NO → ¿Combinacion demanda + consumo?
│           ├── SI → V1 o V2
│           └── NO → PD
```

## 4. Tamano de lote (DISLS)

```
¿Cuanto producir por corrida?
├── Exactamente la necesidad → EX (lote exacto)
├── Cantidad fija siempre → FX (lote fijo, BSTFE)
├── Agrupar por periodo → ¿Que periodo?
│   ├── Dia → TB (diario)
│   ├── Semana → WB (semanal)
│   └── Mes → MB (mensual)
├── Optimizar costes → ¿Setup alto?
│   ├── SI → SP (periodo optimo — equilibra setup vs almacenamiento)
│   └── NO → SM (costo minimo por unidad)
└── Dividir si excede maximo → HB (lote fijo + split)
```

## 5. Tipo de confirmacion

```
¿Como confirmar la produccion?
├── ¿Operacion por operacion?
│   ├── SI → CO11N (confirmacion individual)
│   └── NO → ¿Confirmar solo al final?
│       ├── SI → ¿Con GR automatica?
│       │   ├── SI → CO15 (confirmacion + GR)
│       │   └── NO → CO11N en ultima operacion (final confirmation)
│       └── NO → ¿Milestone?
│           ├── SI → Configurar milestone en routing
│           └── NO → CO11N por operacion
├── ¿Repetitive manufacturing?
│   └── SI → MFBF (backflush)
├── ¿Anular confirmacion?
│   └── SI → CO13
```

## 6. Backflush vs GI manual

```
¿Como retirar componentes?
├── ¿Componentes caros/criticos que requieren control?
│   ├── SI → GI manual (MIGO 261) antes de producir
│   └── NO → ¿Produccion rapida/alto volumen?
│       ├── SI → Backflush automatico en confirmacion
│       │   └── Configurar: RESB-XWAOK o MARC-RGEKZ o CRHD backflush
│       └── NO → GI manual recomendado
├── ¿Mezcla de componentes?
│   └── SI → Algunos backflush + otros manual
│       └── CS02 → indicador backflush solo en componentes apropiados
```

## 7. Scheduling strategy

```
¿Como programar las ordenes?
├── ¿Precision necesaria?
│   ├── Baja → Basic dates scheduling (solo lead time MARC-DZEIT)
│   └── Alta → Lead time scheduling (operaciones routing)
├── ¿Direccion?
│   ├── Fecha entrega fija → Backward scheduling
│   ├── Material disponible, iniciar ya → Forward scheduling
│   └── Operacion critica como referencia → Midpoint scheduling
├── ¿Capacidad finita?
│   ├── SI → Finite scheduling (requiere PP/DS o APO)
│   └── NO → Infinite scheduling (default MRP)
```

## 8. BOM: una vs multiples alternativas

```
¿Variaciones del producto?
├── Un solo metodo → Una BOM (STLAL=1), un routing
├── Variaciones por volumen → Multiples alternativas
│   ├── Lote pequeno → Version 1 (BOM alt 1 + Routing alt 1)
│   └── Lote grande → Version 2 (BOM alt 2 + Routing alt 2)
├── Variaciones por materia prima → Alternativas BOM
│   ├── Proveedor A → BOM alt 1
│   └── Proveedor B → BOM alt 2
├── Variaciones estacionales → Alternativas con validez temporal
└── Vincular con version fabricacion (C223)
```

## 9. Disponibilidad: cuando verificar

```
¿Verificar disponibilidad componentes?
├── Al crear orden → Verificacion individual (ATP)
├── Al liberar orden → Obligatorio en algunas configuraciones
│   ├── ¿Que incluir?
│   │   ├── Solo stock → Grupo verificacion basico
│   │   ├── Stock + recepciones → Grupo extendido
│   │   └── Stock + recepciones + transferencias → Grupo completo
├── Verificacion colectiva → CO24 (lista faltantes)
├── ¿Falta material?
│   ├── Esperar → No liberar orden
│   ├── Producir parcial → Liberar con disponibilidad parcial
│   └── Buscar alternativa → Componente alternativo en BOM
```

## 10. Cierre de orden

```
¿Orden completada?
├── ¿Toda la cantidad entregada?
│   ├── SI → Status DLV automatico
│   └── NO → ¿Produccion adicional prevista?
│       ├── SI → Mantener abierta (REL/PCNF)
│       └── NO → ¿Cerrar con under-delivery?
│           ├── SI → TECO (cierre tecnico)
│           └── NO → Completar produccion
├── ¿Cierre contable?
│   ├── KKAO (WIP) → KKS1 (varianzas) → CO88 (settlement)
│   └── Despues: TECO → eventualmente CLSD
```
