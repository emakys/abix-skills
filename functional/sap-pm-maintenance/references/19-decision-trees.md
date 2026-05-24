# Arboles de Decision PM

## 1. Tipo de Orden PM

```
¿Que tipo de trabajo?
├── Equipo parado / fallo → PM01 Correctivo
├── Trabajo programado periodico → PM02 Preventivo
├── Diagnostico / revision sin reparacion → PM03 Inspeccion
├── Overhaul de componente reutilizable → PM04 Reacondicionamiento
├── Instrumento de medicion con trazabilidad → PM05 Calibracion
├── Basado en lecturas/condicion (IoT) → PM06 Predictivo
└── Parada mayor planificada → PM10 Turnaround
```

## 2. Aviso vs Orden

```
¿Se necesita ejecutar trabajo?
├── NO → Solo registrar hallazgo
│   └── Crear aviso (IW21) — M1/M2/M3
│       └── Codificar dano/causa → estadistica → cerrar
├── SI → ¿Requiere planificacion?
│   ├── SI → Crear aviso + generar orden
│   │   └── IW21 → boton "Crear orden" → planificar → liberar
│   └── NO (urgente) → Crear orden directa (IW31)
│       └── Liberar inmediato → ejecutar → confirmar
```

## 3. Preventivo vs Correctivo vs Predictivo

```
¿Cuando se interviene?
├── ANTES de la falla (programado) → PREVENTIVO
│   ├── ¿Basado en que?
│   │   ├── Calendario (cada X dias/meses) → Tiempo
│   │   ├── Uso (cada X horas/km) → Rendimiento (contador)
│   │   └── Mediciones (umbral superado) → Condicion
│   └── → Plan de mantenimiento IP01
├── DESPUES de la falla → CORRECTIVO
│   └── Aviso M1 + Orden PM01
└── PREDICCION de falla (analytics/IoT) → PREDICTIVO
    └── Orden PM06 basada en tendencias
```

## 4. Ubicacion Tecnica vs Equipo

```
¿El objeto se mueve?
├── NO → Es una posicion fija
│   └── UBICACION TECNICA (IL01)
│       └── Ejemplo: sala de bombas, linea 3, subestacion electrica
├── SI → Es un objeto individual movil
│   └── EQUIPO (IE01)
│       └── Ejemplo: bomba P-101, motor M-205, valvula V-300
└── AMBOS → Equipo instalado EN ubicacion
    └── IL01 (posicion) + IE01 (equipo) + IE4N (instalar)
```

## 5. Estrategia de Mantenimiento

```
¿Cuantos niveles de mantenimiento?
├── UNO solo (una frecuencia) → Plan ciclo unico
│   └── IP01 sin estrategia
├── MULTIPLES niveles → Estrategia con paquetes
│   └── ¿Basado en?
│       ├── Tiempo → IP11 paquetes en dias/meses
│       │   └── Ej: trimestral (90d) + semestral (180d) + anual (365d)
│       ├── Rendimiento → IP11 paquetes en unidades
│       │   └── Ej: cada 500h + 2000h + 8000h
│       └── Combinacion → IP11 ambos tipos
│           └── El primero que se cumpla dispara
```

## 6. Metodo de Liquidacion

```
¿Que tipo de trabajo es?
├── Mantenimiento operativo normal
│   └── Liquidar a CENTRO DE COSTE (CC del area)
├── Mejora / inversion (CAPEX)
│   └── Liquidar a ACTIVO FIJO (AuC o directo)
├── Dentro de un proyecto
│   └── Liquidar a WBS ELEMENT (PS)
├── Sub-orden de parada mayor
│   └── Liquidar a ORDEN PADRE (PM10)
└── Garantia (recuperar costes)
    └── Liquidar a CC + registrar claim BGM
```

## 7. Catalogo de Danos

```
¿Que tipo de falla?
├── Mecanica
│   ├── Rotura → codigo B-ROTURA
│   ├── Desgaste → codigo B-DESGASTE
│   ├── Vibracion excesiva → codigo B-VIBRACION
│   └── Desalineacion → codigo B-DESALIN
├── Electrica
│   ├── Cortocircuito → codigo B-CORTO
│   ├── Sobrecarga → codigo B-SOBRECARGA
│   └── Falla aislamiento → codigo B-AISLAM
├── Instrumentacion
│   ├── Descalibracion → codigo B-CALIBRA
│   └── Senal erratica → codigo B-SENAL
└── Otros
    ├── Fuga → codigo B-FUGA
    ├── Corrosion → codigo B-CORROSION
    └── Contaminacion → codigo B-CONTAM
```

## 8. Flujo Completo de Averia

```
1. Operador detecta falla
   |
2. ¿Equipo parado?
   ├── SI → Aviso M1 (averia) prioridad 1-2
   │   └── Notificar a planificador INMEDIATO
   └── NO → Aviso M2/M3 prioridad 3-4
       └── Cola de trabajo planificado
   |
3. Planificador evalua
   ├── ¿Se puede reparar con recursos internos?
   │   ├── SI → Orden PM01 con operaciones internas
   │   └── NO → Orden PM01 con servicio externo (PM03)
   |
4. ¿Hay repuestos en stock?
   ├── SI → Reserva material en orden
   └── NO → Solicitud pedido urgente (ME51N)
   |
5. Liberar orden → ejecutar → confirmar
   |
6. ¿Reparacion exitosa?
   ├── SI → Confirmar final → TECO → liquidar
   └── NO → Nueva operacion o nueva orden
   |
7. Cerrar aviso con codificacion completa (dano+causa+accion)
```

## 9. Tipo de Confirmacion

```
¿Cuantas operaciones confirmar?
├── UNA operacion → IW41 Confirmacion individual
├── VARIAS operaciones de UNA orden → IW42 Confirmacion colectiva
├── VARIAS ordenes/operaciones → IW47 Con seleccion
└── Horas en multiples ordenes por dia → CATS
    └── Usado en equipos grandes con muchas ordenes diarias
```
