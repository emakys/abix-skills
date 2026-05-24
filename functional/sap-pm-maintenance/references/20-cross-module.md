# Integracion Cross-Module PM

## PM ↔ CO (Controlling)

### Flujo de costes
```
Orden PM (objeto CO)
  → Materiales (mov 261) → coste material al orden
  → Confirmaciones → coste mano obra al orden
  → Servicios externos → coste servicio al orden
  → Overhead (CO43) → recargo costes indirectos
  |
Liquidacion (KO88)
  → Centro de coste (gasto operativo)
  → Activo fijo (capitalizacion)
  → WBS element (proyecto)
```

### Puntos de integracion
- Orden PM tiene area de controlling y centro de coste responsable
- Regla de liquidacion obligatoria para cierre
- Liquidacion mensual como parte del cierre CO (KO8G)
- Plan vs Real: IW67 / KOB1

## PM ↔ FI-AA (Asset Accounting)

### Equipo = Activo fijo
- Equipo (IE01) puede vincularse a activo fijo (EQUI-ANLNR)
- Costes de mejora/capitalizacion liquidan al activo → incrementa valor
- AuC (Asset under Construction): acumular costes → capitalizar al completar

### Flujo de capitalizacion
```
Orden PM tipo inversion
  → Acumula costes (material + MO + servicios)
  → Liquidar a activo fijo (AIAB/AIBU)
  → Incrementa valor libro del activo
  → Deprecacion recalculada
```

## PM ↔ MM (Materials Management)

### Repuestos y consumibles
```
Planificacion: RESB (reserva de material)
  → Orden PM operacion → componente material
  |
Ejecucion: MIGO / MB1A
  → Salida mercancias (mov 261) → imputa coste a orden PM
  → Devolucion (mov 262) → reversa coste
  |
Compras urgentes:
  → ME51N solicitud pedido → ME21N pedido → MIGO EM
  → Factura: MIRO → coste a orden PM
```

### Servicios externos
```
Operacion PM con clave PM03 (externa)
  → Genera solicitud pedido automatica
  → ME21N pedido de servicio
  → ML81N entrada de servicios
  → MIRO verificacion factura
  → Coste imputado a orden PM
```

### BOM de mantenimiento
- IB01: BOM de equipo con repuestos tipicos
- Al crear orden → copia componentes del BOM automaticamente

## PM ↔ PP (Production Planning)

### Impacto en produccion
- Paradas PM afectan disponibilidad de centro de trabajo PP
- Ordenes PM10 (turnaround) requieren coordinacion con planificacion produccion
- Puesto de trabajo compartido entre PM y PP

### Centro de trabajo
- IR01/IR02 (PM) comparte con CR01/CR02 (PP)
- Capacidad de recurso compartida entre ordenes PM y ordenes produccion

## PM ↔ PS (Project System)

### Mantenimiento en proyectos
```
Proyecto PS (CJ20N)
  └── WBS element operativo
      └── Orden PM asignada a WBS
          → Costes PM acumulan en proyecto
          → Liquidacion: CJ88 (proyecto) o KO88 (orden PM)
```

- Ordenes PM pueden imputar costes a WBS elements
- Paradas mayores (PM10) frecuentemente gestionadas como proyectos PS
- Presupuesto PS controla gasto de mantenimiento en el proyecto

## PM ↔ QM (Quality Management)

### Inspecciones y calidad
- Avisos QM (Q1/Q2/Q3) pueden generar ordenes PM
- Resultados de inspeccion QM pueden disparar mantenimiento correctivo
- Calibracion (PM05) integrada con gestion de instrumentos QM

### Flujo QM → PM
```
Inspeccion QM (QA01)
  → Resultado fuera de especificacion
  → Aviso QM (QM01) → genera aviso PM (IW21)
  → Orden PM para reparacion/ajuste
```

## PM ↔ HR (Human Resources)

### Confirmaciones y tiempo
- CATS (Cross-Application Time Sheet): registro de horas trabajadas
- Horas CATS imputan costes de personal a ordenes PM
- Integracion con nomina para calculo de horas extra en mantenimiento

## Secuencia de Cierre de Periodo

```
1. Confirmar operaciones pendientes (IW42)
2. Registrar servicios externos (ML81N)
3. Contabilizar salidas mercancias pendientes (MIGO)
4. Cierre tecnico ordenes completadas (IW32 → TECO)
5. Calculo overhead/recargos (CO43) — si aplica
6. Liquidacion ordenes PM (KO8G)
7. Cierre comercial (CLSD) — ordenes liquidadas
```
