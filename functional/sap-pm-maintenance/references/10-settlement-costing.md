# Liquidacion y Costes de Mantenimiento

## Concepto

La orden PM es un objeto CO que acumula costes reales (materiales, mano de obra, servicios externos). La liquidacion transfiere estos costes al receptor final (centro de coste, activo fijo, WBS element).

## Tipos de Coste en Orden PM

| Tipo | Origen | Ejemplo |
|------|--------|---------|
| Material | Salida mercancias (mov 261) | Repuestos, consumibles |
| Mano obra interna | Confirmaciones (IW41/42) | Horas tecnico x tarifa puesto trabajo |
| Servicios externos | Entrada servicios (ML81N) | Contratistas, especialistas |
| Overhead/Recargo | Calculo automatico CO | Costes indirectos aplicados |

## Regla de Liquidacion (COBRB)

### Receptores posibles
| Receptor | Uso | Ejemplo |
|----------|-----|---------|
| Centro de coste | Mantenimiento operativo normal | CC 1000-MAINT |
| Activo fijo | Mejora/capitalizacion del equipo | Activo 000000012345 |
| WBS element | Mantenimiento dentro de proyecto | WBS T-1000.01 |
| Otra orden | Consolidar costes en orden padre | Orden PM10 parada |
| Cuenta GL | Imputar directamente a cuenta | Cuenta 631000 |

### Configurar regla
1. IW32 → Detalle → Liquidacion
2. Definir receptor + porcentaje (puede ser 100% a un receptor o distribuido)
3. Obligatorio antes de TECO/cierre

## Liquidacion

### Individual (KO88)
- Una orden a la vez
- Verificar costes antes de liquidar

### Colectiva (KO8G)
- Seleccion por centro, tipo orden, grupo planificador, periodo
- Ejecutar mensualmente como parte del cierre de periodo CO

### Proceso
```
1. Orden con costes acumulados
   |
2. Verificar regla de liquidacion (IW32 → Liquidacion)
   |
3. KO88 / KO8G → ejecutar liquidacion
   |
4. Costes transferidos al receptor
   |   → Si CC: gasto en centro de coste
   |   → Si activo: capitalizacion (AuC o directo)
   |   → Si WBS: coste en proyecto
   |
5. Documento CO generado (verificable en KSB1/KOB1)
```

## Analisis de Costes

### Por orden
```
GetSqlQuery("SELECT RACCT,SUM(HSL) as TOTAL FROM ACDOCA WHERE AUFNR='{orden}' AND GJAHR='{year}' AND RLDNR='0L' GROUP BY RACCT")
```

### Por equipo
```
GetSqlQuery("SELECT AFIH.EQUNR,ACDOCA.RACCT,SUM(ACDOCA.HSL) as TOTAL FROM ACDOCA JOIN AFIH ON ACDOCA.AUFNR=AFIH.AUFNR WHERE AFIH.EQUNR='{equipo}' AND ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AFIH.EQUNR,ACDOCA.RACCT")
```

### Por ubicacion tecnica
```
GetSqlQuery("SELECT AFIH.TPLNR,SUM(ACDOCA.HSL) as TOTAL FROM ACDOCA JOIN AFIH ON ACDOCA.AUFNR=AFIH.AUFNR WHERE AFIH.TPLNR LIKE '{ubicacion}%' AND ACDOCA.GJAHR='{year}' AND ACDOCA.RLDNR='0L' GROUP BY AFIH.TPLNR")
```

### Presupuesto de orden PM
- IW32 → Costes → Presupuesto
- Planificar costes estimados por clase de coste
- Comparar plan vs real: IW67

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| KO88 | Liquidacion individual |
| KO8G | Liquidacion colectiva |
| IW66 | Analisis costes orden PM |
| IW67 | Plan vs Real orden PM |
| KSB1 | Partidas individuales CC (post-liquidacion) |
| KOB1 | Partidas individuales orden |

## Mejores Practicas

1. **Regla de liquidacion antes de liberar** — definir receptor al crear la orden
2. **Liquidacion mensual** — KO8G en cierre de periodo, antes de cierre CO
3. **Separar correctivo de preventivo** — tipos de orden distintos para analisis de costes
4. **Capitalizacion solo cuando aplica** — mejoras que extienden vida util, no reparaciones normales
5. **Reconciliar** — verificar que costes liquidados cuadran con costes acumulados
