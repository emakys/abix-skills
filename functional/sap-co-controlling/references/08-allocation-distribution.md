# Distribucion y Reparto (Allocation)

## Tipos de asignacion de costes en CO

| Metodo | TCode | Clase coste | Detalle al receptor |
|--------|-------|-------------|---------------------|
| Distribucion | KSV5 | Primaria (original) | SI — ve clases de coste originales |
| Assessment (Reparto) | KSU5 | Secundaria (42) | NO — ve solo el total |
| Actividad interna | KB21N | Secundaria (43) | SI — por clase actividad |
| Recontabilizacion | KB61 | Primaria (original) | SI |
| Overhead | CO43/KGI2 | Secundaria (41) | NO |

## Ciclos de distribucion/assessment

Un ciclo define: emisor(es) → receptor(es) → base de reparto → clase(s) de coste.

### Estructura del ciclo

```
Ciclo: ZALLOC01
|
+-- Segmento 1: IT costes a todas las areas
|   Emisor: CC 1000-IT
|   Receptor: Grupo CC PROD + ADMIN
|   Base reparto: Cifra estadistica (headcount)
|   Clases coste: 400000-499999
|
+-- Segmento 2: Alquiler a centros
|   Emisor: CC 1000-RENT
|   Receptor: Grupo CC ALL
|   Base reparto: Cifra estadistica (m2)
|   Clases coste: 472000
```

### Bases de reparto (Tracing factors)

| Base | Descripcion | Ejemplo |
|------|-------------|---------|
| Cifra estadistica (fija) | Valor fijo por receptor | Headcount, m2 |
| Cifra estadistica (real) | Valor real contabilizado | Kwh consumidos |
| Porcentaje fijo | % definido manualmente | 30/70 split |
| Cuotas fijas | Importes fijos | 1000/2000/3000 |

### Orden de ejecucion en cierre

```
1. Recontabilizaciones manuales (KB61)
2. Distribucion (KSV5) — reparte primarios
3. Assessment (KSU5) — reparte secundarios
4. Actividades internas — valoracion real
5. Overhead (CO43) — recargos indirectos
6. Settlement (KO88) — liquidacion ordenes
```

### Transacciones principales

| TCode | Descripcion |
|-------|-------------|
| KSV1/KSV2 | Crear/Modificar ciclo distribucion |
| KSV5 | Ejecutar distribucion |
| KSU1/KSU2 | Crear/Modificar ciclo assessment |
| KSU5 | Ejecutar assessment |
| KB61 | Recontabilizar lineas CO |
