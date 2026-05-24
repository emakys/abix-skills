# Puntos de Medida y Contadores

## Concepto

Los puntos de medida registran valores cuantitativos del equipo (temperatura, presion, vibracion). Los contadores registran valores acumulativos (horas operacion, km, ciclos). Ambos alimentan el mantenimiento basado en condicion y rendimiento.

## Punto de Medida vs Contador

| Aspecto | Punto de Medida | Contador |
|---------|----------------|----------|
| Valor | Instantaneo (temperatura actual) | Acumulativo (horas totales) |
| Tendencia | Sube y baja | Solo sube (o reset) |
| Uso | Condicion-based maintenance | Performance-based maintenance |
| Ejemplo | 85°C, 4.2 mm/s vibracion | 12,500 horas, 85,000 km |

## Estructura

### Punto de Medida (IMPTT)
| Campo | Descripcion |
|-------|-------------|
| POINT | Numero punto medida |
| PESSION | Posicion |
| PSORT | Campo ordenacion |
| EQUNR | Equipo |
| TPLNR | Ubicacion tecnica |
| ATNAM | Caracteristica (ej: TEMPERATURA, VIBRACION) |
| MESSION | Unidad medida (°C, mm/s, bar) |
| DECIM | Decimales |
| MDESSION | Descripcion |
| COUNTERI | Indicador contador (X = es contador) |

### Documento de Medicion (IMRG)
| Campo | Descripcion |
|-------|-------------|
| MDOCM | Numero documento medicion |
| POINT | Punto de medida |
| READG | Valor de lectura |
| RECDU | Valor diferencia (para contadores) |
| IDATE | Fecha medicion |
| ITIME | Hora medicion |
| CODGR | Grupo codigo valoracion |
| CESSION | Codigo valoracion |

## Limites y Umbrales

Configurar en el punto de medida para alertas automaticas:
- **Limite superior**: valor maximo aceptable
- **Limite inferior**: valor minimo aceptable
- **Accion al exceder**: generar aviso de mantenimiento automaticamente

## Queries MCP

```
-- Puntos de medida de un equipo
GetSqlQuery("SELECT POINT,PSORT,ATNAM,MESSION,MDESSION,COUNTERI FROM IMPTT WHERE EQUNR='{equipo}'")

-- Ultimas lecturas de un punto
GetSqlQuery("SELECT MDOCM,READG,RECDU,IDATE,ITIME FROM IMRG WHERE POINT='{punto}' ORDER BY IDATE DESC,ITIME DESC")

-- Contadores de un equipo
GetSqlQuery("SELECT POINT,ATNAM,MESSION FROM IMPTT WHERE EQUNR='{equipo}' AND COUNTERI='X'")

-- Valor actual de contador
GetSqlQuery("SELECT READG,IDATE FROM IMRG WHERE POINT='{punto}' ORDER BY IDATE DESC LIMIT 1")
```

## Transacciones

| TCode | Descripcion |
|-------|-------------|
| IK01 | Crear punto de medida |
| IK02 | Modificar punto de medida |
| IK03 | Visualizar punto de medida |
| IK07 | Lista puntos de medida |
| IK11 | Crear documento medicion |
| IK12 | Modificar documento medicion |
| IK17 | Lista documentos medicion |
| IK08 | Reemplazar punto medida |

## Mejores Practicas

1. **Definir unidades claras** — coherencia en todas las mediciones del mismo tipo
2. **Frecuencia de lectura** — mas frecuente para equipos criticos
3. **Contadores con diferencia** — verificar que el valor nuevo > anterior (evitar errores)
4. **Limites realistas** — basados en datos del fabricante + experiencia operativa
5. **Integrar con planes** — contadores alimentan planes basados en rendimiento (IP01)
