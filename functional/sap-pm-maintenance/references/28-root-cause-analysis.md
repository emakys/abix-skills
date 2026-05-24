# Analisis de Causa Raiz — Metodologia PM

## Framework de Diagnostico (5 pasos)

```
1. IDENTIFICAR → Que equipo, que sintoma, que proceso afectado
2. RECOPILAR → Datos del sistema (status, historial, customizing)
3. ANALIZAR → Comparar contra configuracion esperada
4. DIAGNOSTICAR → Causa raiz + hipotesis alternativas
5. RESOLVER → Accion correctiva + validacion + impacto
```

## Clasificacion de Incidentes

### A — Ordenes de Mantenimiento
- Errores al crear, liberar, confirmar, cerrar
- Queries: AUFK, AFIH, AFKO, AFVC, JEST
```
GetSqlQuery("SELECT AUFNR,AUART,OBJNR FROM AUFK WHERE AUFNR='{orden}'")
GetSqlQuery("SELECT STAT,INACT FROM JEST WHERE OBJNR='{objeto}' AND INACT=''")
GetSqlQuery("SELECT EQUNR,TPLNR,INGRP,QMNUM FROM AFIH WHERE AUFNR='{orden}'")
```

### B — Avisos
- Errores de catalogo, tipo aviso, codificacion
- Queries: QMEL, QMFE, QMUR, TQ80
```
GetSqlQuery("SELECT QMNUM,QMART,EQUNR,TPLNR FROM QMEL WHERE QMNUM='{aviso}'")
GetSqlQuery("SELECT * FROM TQ80 WHERE QMART='{tipo}'")
```

### C — Planes de Mantenimiento
- Planes que no generan ordenes, estrategias incorrectas
- Queries: MPLA, MPOS, MHIS, T351
```
GetSqlQuery("SELECT WARPL,STESSION FROM MPLA WHERE WARPL='{plan}'")
GetSqlQuery("SELECT POINT,EQUNR,TPLNR FROM MPOS WHERE WARPL='{plan}'")
GetSqlQuery("SELECT LESSION,ESSION,AUFNR FROM MHIS WHERE WARPL='{plan}' ORDER BY LESSION DESC")
```

### D — Equipos y Ubicaciones
- Errores de estructura, asignacion organizativa
- Queries: EQUI, IFLOT, ILOA
```
GetSqlQuery("SELECT EQUNR,EQTYP,SWERK,TPLNR,KOSTL FROM EQUI WHERE EQUNR='{equipo}'")
GetSqlQuery("SELECT TPLNR,IWERK,SWERK FROM IFLOT WHERE TPLNR='{ubicacion}'")
```

### E — Costes y Liquidacion
- Errores de liquidacion, costes no contabilizados
- Queries: ACDOCA, COBRB, AUFK
```
GetSqlQuery("SELECT SUM(HSL) FROM ACDOCA WHERE AUFNR='{orden}' AND GJAHR='{year}' AND RLDNR='0L'")
```

## Escenarios Resueltos

### 1. Plan no genera ordenes
**Sintoma**: IP30 no genera ordenes para plan activo
**Diagnostico**:
1. Verificar status plan: MPLA-STESSION = 'A' (activo)
2. Verificar posiciones: MPOS tiene equipo/ubicacion validos
3. Verificar estrategia: T351P tiene paquetes definidos
4. Verificar horizonte: IP02 → parametros → horizonte apertura
**Causa comun**: Horizonte de apertura al 0% o plan sin programar (IP10)
**Fix**: IP10 → programar plan → IP30 con horizonte correcto

### 2. Orden no permite confirmacion
**Sintoma**: IW41 rechaza "Status does not allow"
**Diagnostico**: JEST → verificar status activos del objeto
**Causa comun**: Orden no liberada (falta REL) o ya TECO
**Fix**: IW32 → Funciones → Liberar (si falta REL) o Reactivar (si TECO prematuro)

### 3. Liquidacion falla "receiver not valid"
**Sintoma**: KO88 error "Settlement receiver not valid"
**Diagnostico**: COBRB → verificar regla liquidacion
**Causa comun**: CC receptor bloqueado, activo dado de baja, WBS cerrado
**Fix**: Verificar maestro del receptor, corregir regla de liquidacion

## Patrones Recurrentes

1. **Plan desincronizado** — IP30 ejecutado tarde, acumula llamadas. Solucion: job diario automatico
2. **Equipo sin centro** — EQUI-SWERK vacio impide crear ordenes. Solucion: IE02 asignar centro
3. **Catalogo no asignado** — Tipo aviso sin perfil catalogo. Solucion: SPRO → asignar
4. **Contador no actualizado** — Planes por rendimiento sin lecturas recientes. Solucion: IK11 regular
5. **Doble confirmacion** — Tecnico confirma final y luego quiere agregar horas. Solucion: IW44 cancelar final, reconfirmar
