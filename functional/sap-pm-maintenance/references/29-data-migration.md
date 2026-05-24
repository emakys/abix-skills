# Migracion de Datos PM

## Estrategia de Migracion

### Secuencia de Carga
```
1. Ubicaciones tecnicas (IL01 / BAPI_FUNCLOC_CREATE)
2. Equipos (IE01 / BAPI_EQUI_CREATE)
3. BOM de equipo (IB01 / CSAP_MAT_BOM_CREATE)
4. Clasificacion (CL20N / BAPI_OBJCL_CREATE)
5. Puntos de medida (IK01 / BAPI_MEASUR_POINT_CREATE)
6. Hojas de ruta (IA01/IA11 — sin BAPI estandar, usar LSMW/LTMC)
7. Planes de mantenimiento (IP01 / BAPI_ALM_MPLAN_CREATE)
8. Avisos historicos (IW21 / BAPI_ALM_NOTIF_CREATE) — opcional
9. Ordenes historicas (IW31 / BAPI_ALM_ORDER_MAINTAIN) — opcional
```

## Herramientas de Migracion

### S/4HANA Migration Cockpit (LTMC)
- Herramienta recomendada para S/4HANA
- Templates predefinidos para objetos PM
- Carga masiva desde Excel
- Validacion automatica

### LSMW (Legacy System Migration Workbench)
- Clasico pero aun funcional
- Recording o Direct Input
- Para objetos sin template LTMC

### BAPIs para Migracion Programatica

| BAPI | Objeto |
|------|--------|
| BAPI_FUNCLOC_CREATE | Ubicacion tecnica |
| BAPI_EQUI_CREATE | Equipo |
| BAPI_EQUI_CHANGE | Modificar equipo (post-carga) |
| BAPI_ALM_NOTIF_CREATE | Aviso |
| BAPI_ALM_ORDER_MAINTAIN | Orden PM |
| BAPI_ALM_MPLAN_CREATE | Plan mantenimiento |

## Validaciones Pre-Migracion

### Datos maestros
- [ ] Centros de planificacion (T001W-SWERK/IWERK) existen
- [ ] Grupos planificador (T024I) creados
- [ ] Puestos de trabajo (CRHD) creados
- [ ] Catalogos de dano/causa/accion configurados
- [ ] Tipos orden PM definidos y asignados a centro
- [ ] Rangos de numeros configurados

### Datos a migrar
- [ ] Formato de ubicaciones tecnicas consistente con mascara
- [ ] Equipos con centro de planificacion asignado
- [ ] Numeros de serie unicos (si aplica)
- [ ] Fechas de instalacion coherentes
- [ ] Contadores con valor inicial correcto

## Validaciones Post-Migracion

1. Conteo de objetos migrados vs fuente
2. Verificar jerarquias (equipos en ubicaciones correctas)
3. Verificar asignaciones organizativas (centro, CC, PC)
4. Ejecutar IP30 para validar generacion de ordenes
5. Crear orden manual para cada tipo PM → verificar flujo completo

## Tratamiento de Historicos

### Opcion 1: Solo datos maestros
- Migrar ubicaciones + equipos + planes
- NO migrar avisos/ordenes historicos
- Mas rapido, menos riesgo

### Opcion 2: Historico completo
- Migrar todo incluyendo avisos y ordenes cerrados
- Necesario para estadisticas MTBF/MTTR desde dia 1
- Mas complejo, requiere mas validacion

### Opcion 3: Hibrido
- Datos maestros completos
- Solo ultimos 12-24 meses de avisos/ordenes
- Balance entre historial y complejidad

## Cutover Plan

```
Dia -5: Freeze datos PM en sistema legacy
Dia -4: Extraer datos finales
Dia -3: Carga ubicaciones + equipos + BOM
Dia -2: Carga clasificacion + puntos medida + hojas ruta
Dia -1: Carga planes + programacion IP30
Dia  0: GO-LIVE → verificar flujo completo
Dia +1: Verificacion post-go-live + soporte intensivo
```
