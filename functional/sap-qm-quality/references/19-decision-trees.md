# Arboles de Decision QM

## 1. Tipo de inspeccion a activar

```
¿De donde viene el material?
├── Compra (proveedor) → Tipo 01 (GR from vendor)
│   └── ¿Requiere inspeccion en origen? → Tipo 10 (source inspection)
├── Produccion → ¿Durante o despues?
│   ├── Durante → Tipo 03 (in-process)
│   └── Despues (GR) → Tipo 04 (final inspection)
├── Transferencia entre centros → Tipo 08
├── Devolucion de cliente → Tipo 12
├── Periodica (shelf life) → Tipo 09 (recurring)
├── Para certificado → Tipo 14
└── Ad-hoc / auditoria → Tipo 89 (manual) o Tipo 06 (audit)
```

## 2. Plan de inspeccion vs Material specification

```
¿Como definir las pruebas?
├── ¿Pruebas complejas con multiples operaciones?
│   └── SI → Inspection plan (QP01)
│       └── Operaciones + MICs + sampling
├── ¿Pruebas simples, pocas MICs?
│   └── SI → Material specification
│       └── MICs directamente en maestro material
├── ¿Usar routing PP existente?
│   └── SI → Task list reference (routing con MICs)
└── ¿Sin plan, solo UD?
    └── SI → Inspection without plan (config en QMAT)
```

## 3. Resultado de decision de empleo

```
Resultados de inspeccion
├── Todo OK → UD Accept (A)
│   └── Stock QI → libre (321)
├── Todo FAIL → UD Reject (R)
│   ├── ¿Devolver a proveedor? → Return (122)
│   ├── ¿Scrap? → Scrap (551)
│   └── ¿Bloquear? → Blocked stock (322)
├── Parcial → UD con split
│   ├── Qty buena → libre (321)
│   └── Qty mala → bloqueada (322)
└── Condicional → UD Accept conditional (AC)
    └── Stock libre + aviso automatico
```

## 4. Tipo de aviso de calidad

```
¿Quien detecta el problema?
├── Interno (produccion, almacen) → Q1 (internal problem)
├── Cliente lo reporta → Q2 (customer complaint)
├── Proveedor es la causa → Q3 (vendor complaint)
├── Hallazgo de auditoria → Q4 (audit finding)
└── General → QM (generic notification)
```

## 5. Dynamic modification — que nivel aplicar

```
¿Historial de calidad del material/proveedor?
├── Nuevo (sin historial) → Tightened (100% o muestra grande)
├── N lotes buenos → Normal (AQL estandar)
├── N+M lotes buenos → Reduced (muestra pequena)
├── Excelente historial → Skip lot (sin inspeccion)
├── 1 lote malo → Volver a Normal
└── 2+ lotes malos → Tightened
```

## 6. MIC cuantitativa vs cualitativa

```
¿Que tipo de resultado?
├── Numero medible → Cuantitativa
│   ├── Con tolerancias → target ± tolerancia
│   ├── Solo minimo → lower spec limit
│   ├── Solo maximo → upper spec limit
│   └── ¿SPC? → Configurar control chart type
└── Atributo/visual → Cualitativa
    ├── Pass/Fail → Catalogo simple
    ├── Multiples opciones → Catalogo con codigos
    └── ¿Accepted/Rejected? → Valoracion por codigo
```

## 7. Sampling — cuanto inspeccionar

```
¿Cuantas muestras?
├── Todo → 100% inspection
├── Cantidad fija → Fixed sample (siempre N piezas)
├── Porcentaje → % del lote
├── Estadistico → Sampling scheme
│   ├── AQL Level I → Menos muestras
│   ├── AQL Level II → Normal (mas comun)
│   └── AQL Level III → Mas muestras
└── Cero → Skip lot (dynamic modification)
```

## 8. Certificado — cuando generar

```
¿Se necesita certificado de calidad?
├── Cliente lo requiere → Perfil certificado (QC21)
│   ├── ¿Automatico con entrega? → Output determination
│   └── ¿Manual? → QC31
├── Proveedor debe enviar → Inbound certificate (QC51)
│   ├── ¿Obligatorio para GR? → Config procurement key
│   └── ¿Opcional? → Registro manual
└── No requiere → Sin configuracion
```

## 9. Follow-up action en UD

```
¿Que hacer despues de la decision?
├── Accept → Stock posting (321)
├── Reject → ¿Que follow-up?
│   ├── Crear aviso Q3 automatico → Config UD code
│   ├── Bloquear proveedor → Vendor evaluation threshold
│   ├── Devolucion → Return delivery
│   └── Solo bloquear stock → Stock posting (322)
├── Actualizar quality score → Siempre (si configurado)
├── Actualizar batch classification → Si batch management
└── Actualizar vendor evaluation → Si tipo 01
```

## 10. Integracion QM con otros modulos

```
¿Que modulo esta involucrado?
├── MM (compras)
│   ├── GR → tipo 01 → inspeccion → UD → stock
│   ├── Vendor evaluation → quality score
│   └── Procurement key → QI control
├── PP (produccion)
│   ├── Confirmacion → tipo 03 (in-process)
│   ├── GR produccion → tipo 04 (final)
│   └── Scrap → impacto orden produccion
├── SD (ventas)
│   ├── Certificado con entrega
│   ├── Devolucion → tipo 12
│   └── ATP vs stock QI
├── PM (mantenimiento)
│   └── Calibracion equipos
└── CO (controlling)
    └── Costes no calidad via ordenes CO
```
