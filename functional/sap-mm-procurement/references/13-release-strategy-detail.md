# Release Strategy — Configuracion Detallada

## Concepto

La release strategy controla la aprobacion de documentos de compras (PO y PR).
Se basa en el sistema de **clasificacion** de SAP (clases + caracteristicas).

```
Documento de compra (PO/PR)
    |
    +-- Clasificacion evalua campos del documento
    |   (valor total, tipo doc, grupo compras, centro, etc.)
    |
    +-- Determina release strategy segun criterios
    |
    +-- Asigna release codes (aprobadores) en secuencia
    |
    +-- Cada aprobador libera con su codigo
    |
    +-- Todos liberados = documento aprobado
```

## Diferencia PO vs PR release

| Aspecto | PO Release | PR Release |
|---------|-----------|-----------|
| Clase | 032 (CEBAN para PR, CE1 para PO) | 032 |
| Objeto | Purchasing document | Purchase requisition |
| Tabla strategy | T16FS | T16FS |
| Transaccion liberar | ME28/ME29N | ME54N/ME55 |
| Efecto | PO no se puede imprimir/enviar sin release | PR no genera PO sin release |

## Configuracion paso a paso

### Paso 1: Crear Caracteristicas (CT04)

Definir que campos del documento se evaluan:

| Caracteristica | Campo evaluado | Tabla/Campo | Valores |
|----------------|---------------|-------------|---------|
| CEBAN_GSWRT | Valor total PO | EKKO-GSWRT | Rango numerico |
| CEBAN_BSART | Tipo documento | EKKO-BSART | NB, FO, UB... |
| CEBAN_EKGRP | Grupo compras | EKKO-EKGRP | 001, 002... |
| CEBAN_WERKS | Centro | EKPO-WERKS | 1000, 2000... |
| CEBAN_EKORG | Org compras | EKKO-EKORG | 1000... |
| CEBAN_KNTTP | Cat. imputacion | EKPO-KNTTP | K, F, P... |
| CEBAN_PSTYP | Tipo posicion | EKPO-PSTYP | 0, 3, 9... |

```
CT04 → Crear caracteristica
  Nombre: Z_MM_PO_VALUE
  Tipo: NUM (numerico) o CHAR (texto)
  Tabla de referencia: CEBAN (PR) o CE1 (PO)
  Campo: GSWRT (valor total)
```

### Paso 2: Crear Clase (CL02)

Agrupar caracteristicas en una clase:

```
CL02 → Crear clase
  Clase: Z_MM_PO_REL
  Tipo clase: 032 (Release strategy for purchasing)
  Caracteristicas:
    - CEBAN_GSWRT (valor)
    - CEBAN_BSART (tipo doc)
    - CEBAN_EKGRP (grupo compras)
```

### Paso 3: Crear Grupos de Liberacion (SPRO)

```
SPRO → MM → Purchasing → Purchase Order → Release Procedure →
  Define Release Procedure for POs →
    Release Groups (T16FC)

Ejemplo:
  Grupo: 01 - "Aprobacion compras estandar"
  Grupo: 02 - "Aprobacion compras CAPEX"
```

### Paso 4: Crear Codigos de Liberacion (SPRO)

```
Misma ruta → Release Codes (T16FD)

Dentro del grupo 01:
  Codigo: JC - "Jefe de Compras"
  Codigo: GF - "Gerente Financiero"
  Codigo: DR - "Director"
```

### Paso 5: Crear Release Strategy (SPRO)

```
Misma ruta → Release Strategies (T16FS)

Strategy: S1 - "PO < $25,000"
  Grupo: 01
  Codigos: JC (solo 1 nivel)
  Release statuses: 1=JC aprueba → Released

Strategy: S2 - "PO $25,000-$100,000"
  Grupo: 01
  Codigos: JC, GF (2 niveles, secuencial)
  Release statuses: 1=JC aprueba, 2=GF aprueba → Released

Strategy: S3 - "PO > $100,000"
  Grupo: 01
  Codigos: JC, GF, DR (3 niveles)
  Release statuses: 1=JC, 2=GF, 3=DR → Released
```

### Paso 6: Clasificacion de Strategies

```
Asignar valores de caracteristicas a cada strategy:

S1: CEBAN_GSWRT = 0 - 24,999.99 | CEBAN_BSART = NB
S2: CEBAN_GSWRT = 25,000 - 99,999.99 | CEBAN_BSART = NB
S3: CEBAN_GSWRT = 100,000 - 999,999,999 | CEBAN_BSART = NB
```

### Paso 7: Release Indicator y Workflow

```
Misma ruta → Release Indicator (T16FB)

Definir que estados son:
  - Sin liberar: no se puede imprimir/enviar
  - Parcialmente liberado: 1 de N aprobadores
  - Completamente liberado: todos aprobaron

Flag "Changeable after release": permite/impide cambios post-release
Flag "Value change resets release": si cambia el valor, vuelve a necesitar release
```

## Ejemplo completo realista

```
Empresa con 3 niveles de aprobacion:

Grupo: 01 (Compras generales)
  Codigos: CP (Comprador), JC (Jefe Compras), GF (Gerente)

Strategies:
  REL1: NB, valor < $5,000 → Sin release (automatico)
  REL2: NB, valor $5,000-$25,000 → CP aprueba
  REL3: NB, valor $25,000-$100,000 → CP + JC aprueban
  REL4: NB, valor > $100,000 → CP + JC + GF aprueban
  REL5: FO (framework), cualquier valor → JC + GF aprueban
  REL6: UB (STO), cualquier valor → CP aprueba

Clasificacion:
  REL1: BSART=NB, GSWRT=0-4999.99
  REL2: BSART=NB, GSWRT=5000-24999.99
  REL3: BSART=NB, GSWRT=25000-99999.99
  REL4: BSART=NB, GSWRT=100000-999999999
  REL5: BSART=FO, GSWRT=0-999999999
  REL6: BSART=UB, GSWRT=0-999999999
```

## Queries MCP para diagnostico

```sql
-- Release strategy de un PO
SELECT EBELN, FRGSX, FRGKE, FRGZU, FRGRL FROM EKKO WHERE EBELN = '{po}'
-- FRGSX=strategy, FRGKE=release indicator, FRGZU=release status, FRGRL=release complete

-- Strategies configuradas
SELECT FRGSX, FRGXT FROM T16FS WHERE SPRAS = 'E'

-- Codigos de release
SELECT FRGCO, FRGCT FROM T16FC WHERE SPRAS = 'E'

-- Prerequisitos de release (quien debe aprobar antes que quien)
SELECT FRGSX, FRGC1, FRGC2 FROM T16FV

-- POs pendientes de liberacion
SELECT EBELN, LIFNR, BSART, GSWRT, WAERS, FRGSX, FRGKE, FRGZU
FROM EKKO WHERE FRGRL = '' AND FRGSX <> '' AND EKORG = '{org}'
ORDER BY GSWRT DESC
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| ME 206 (PO not released) | Falta aprobacion | ME28 liberar |
| No se determina strategy | Clasificacion no matchea | Revisar valores en CL02 |
| Release resetea al cambiar PO | Flag "value change resets" activo | T16FB ajustar indicador |
| Aprobador no puede liberar | Codigo release no asignado al usuario | SU01 o via workflow |
| PO liberada pero no se imprime | Flag "purchasable after release" | T16FB verificar |
