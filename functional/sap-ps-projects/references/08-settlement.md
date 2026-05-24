# Liquidacion de Proyectos — SAP PS S/4HANA 2023

## 1. Concepto de Liquidacion en PS

La liquidacion (Settlement) es el proceso por el que los costes acumulados en un proyecto (WBS, red, actividades) se transfieren a objetos receptores definitivos: activos fijos, centros de coste, cuentas de mayor, otros WBS u ordenes internas.

### Por que es necesaria la Liquidacion

Los elementos WBS y redes son objetos CO temporales que acumulan costes durante el proyecto. Al finalizar el proyecto (o periodicamente), estos costes deben:

1. **Capitalizarse** en Activos Fijos (proyectos de inversion → AuC → AF definitivo)
2. **Distribuirse** a centros de coste beneficiarios (proyectos de overhead)
3. **Liquidarse en resultados** (proyectos de cliente → CO-PA, cuenta de resultados)
4. **Transferirse** a otros objetos CO (WBS padre, ordenes internas)

---

## 2. Regla de Liquidacion

La regla de liquidacion define los receptores y los porcentajes de distribucion de los costes.

### Componentes de la Regla de Liquidacion

| Campo | Descripcion |
|---|---|
| Tipo de receptor | CC (centro coste), AUC (activo en curso), GL (cuenta G/L), WBS, ORD (orden) |
| Receptor | Numero del objeto receptor |
| Tipo de liquidacion | FUL (completa), PER (periodica) |
| Porcentaje / Importe | % de los costes a liquidar al receptor |
| Clase de liquidacion | Permite distintos receptores por clase de coste |
| Periodo de validez | Desde/hasta que fecha aplica la regla |

### Tipos de Liquidacion

| Tipo | Codigo | Descripcion |
|---|---|---|
| Liquidacion completa | FUL | Liquida todos los costes del periodo + acumulados |
| Liquidacion periodica | PER | Liquida solo los costes del periodo actual |

Para proyectos de inversion con AuC, se usa PER (periodica) durante la ejecucion y FUL al capitalizacion final.

---

## 3. Tipos de Receptor de Liquidacion

### 3.1 Activo en Curso (AuC — Asset Under Construction)

Receptor tipico para proyectos de inversion. Los costes se acumulan en un activo en curso (AuC) hasta que el proyecto finaliza y se capitaliza como activo fijo definitivo.

```
WBS → Liquidacion periodica → AuC (activo en curso)
                              ↓ (al finalizar proyecto)
                              AF definitivo (maquinaria, instalacion, etc.)
```

### 3.2 Centro de Coste

Para proyectos de overhead o de mejora. Los costes del proyecto se distribuyen a los centros de coste beneficiarios.

```
WBS → Liquidacion → Centro de Coste 1000 (80%)
                  → Centro de Coste 2000 (20%)
```

### 3.3 Cuenta de Mayor (GL)

Liquidacion directa a cuentas de resultado o balance. Comun en proyectos de I+D donde los costes se activan como intangibles.

### 3.4 Elemento WBS

Liquidacion entre WBS del mismo proyecto o de proyectos diferentes. Permite consolidar costes en un WBS padre.

### 3.5 Orden Interna (CO)

Transferencia de costes a una orden interna CO para su gestion o redistribucion posterior.

### 3.6 CO-PA (Contabilidad de Resultados)

Para proyectos de cliente, la liquidacion puede ir a CO-PA con caracteristicas como cliente, producto, segmento de mercado.

---

## 4. Perfil de Liquidacion

El perfil de liquidacion controla los parametros de la regla de liquidacion.

### Configuracion SPRO

```
SPRO → Project System → Costes → Liquidacion →
Definir Perfil de Liquidacion
Transaccion: OKO7 (o via menu PS)
```

### Parametros del Perfil de Liquidacion

| Parametro | Descripcion |
|---|---|
| Tipo receptor por defecto | CC, AUC, GL, etc. |
| Tipos receptor permitidos | Lista de receptores validos |
| Tipo de documento | Clase del documento FI generado |
| Cuenta de ajuste | Cuenta de paso para la liquidacion |
| 100% obligatorio | Si los porcentajes deben sumar 100% |
| Precio de liquidacion | A precio real o plan |

---

## 5. Creacion de la Regla de Liquidacion

### Acceso a la Regla de Liquidacion

```
CJ20N → seleccionar WBS → menu Editar → Regla de liquidacion
O bien: CJK2 (directamente en la regla de liquidacion)
```

### Ejemplo de Regla de Liquidacion

```
WBS: CONS-2024-001.1 (Construccion)
Regla:
  Receptor 1: AuC-001 (Activo en Curso)  |  Tipo: PER  |  Porcentaje: 100%
  Periodo validez: 01.2024 - 12.2024

WBS: CONS-2024-001.2 (Estudios I+D)
Regla:
  Receptor 1: CC-5000 (Centro I+D)  |  Tipo: PER  |  Porcentaje: 70%
  Receptor 2: GL-800001 (Gasto I+D)  |  Tipo: PER  |  Porcentaje: 30%
```

---

## 6. Liquidacion Individual (CJ88)

### Transaccion CJ88 — Liquidar Proyecto Individual

```
CJ88 → Ingresar numero de proyecto
Parametros:
  - Periodo de liquidacion y ejercicio
  - Modo: test (simulacion) o real
  - Tipo: periodica o final
  - Reconciliacion con FI

Pasos:
1. Ejecutar en modo TEST primero
2. Verificar los importes a liquidar
3. Ejecutar en modo REAL
4. Verificar documentos generados (CO + FI)
```

### Resultado de la Liquidacion

```
Antes:  WBS tiene 50.000 EUR de costes reales
Regla:  100% → AuC-001

Despues de liquidar:
  WBS: 0 EUR (costes enviados al receptor)
  AuC: +50.000 EUR (costes recibidos del WBS)
  Documento CO: KJ tipo (liquidacion interna)
  Documento FI: si cruza sociedad o es a AF (asiento contable)
```

---

## 7. Liquidacion Colectiva (CJ8G)

Para liquidar multiples proyectos en un solo paso, tipicamente en el cierre de periodo.

### Transaccion CJ8G — Liquidacion Colectiva

```
CJ8G → Seleccionar criterios:
  - Sociedad
  - Area de controlling
  - Rango de proyectos o WBS
  - Periodo y ejercicio
  - Tipo de liquidacion

Ejecutar en background para grandes volumenes
Verificar log de errores
```

---

## 8. Workflow AuC — Activo en Curso a Activo Fijo

El proceso completo para proyectos de capitalizacion (inversion en activos fijos) tiene dos fases:

### Fase 1: Liquidacion Periodica → AuC (durante el proyecto)

```
Periodo 1: CJ88/CJ8G → WBS → AuC        [costes mes 1]
Periodo 2: CJ88/CJ8G → WBS → AuC        [costes mes 2]
...
Periodo N: CJ88/CJ8G → WBS → AuC        [costes mes N]
```

### Fase 2: Capitalizacion AuC → Activo Fijo (al finalizar)

```
Transaccion AIAB → Asignar lineas AuC a activos fijos definitivos
                   (que elementos del AuC van a que activo fijo)

Transaccion AIBU → Capitalizacion (contabilizar el traspaso)
                   AuC → Activo Fijo definitivo
                   Genera asiento AM (Activos Fijos)
```

### Configuracion AuC

```
SPRO → Asset Accounting → Activo en Curso →
Definir clases de activo AuC
Enlace PS-AA: en WBS asignar clase de activo AuC
```

---

## 9. Tabla AUFK — Datos Maestros de Orden (Red / WBS como Orden)

| Campo | Descripcion |
|---|---|
| AUFNR | Numero de red/orden |
| AUTYP | Tipo (20=PS, 10=PP, 30=PM) |
| KOSTL | Centro de coste receptor |
| AUFNR_REF | Orden de referencia |

### Tabla COBRB — Regla de Liquidacion

La tabla COBRB almacena las reglas de liquidacion de todos los objetos CO (WBS, ordenes, redes).

| Campo | Tipo | Descripcion |
|---|---|---|
| OBJNR | CHAR(22) | Numero de objeto del emisor (WBS/red) |
| BUREC | NUMC(3) | Numero de regla (001, 002...) |
| KONTY | CHAR(2) | Tipo de receptor (KS=CC, AUC=AuC, PSP=WBS...) |
| RECID | CHAR(22) | Receptor: numero de objeto del receptor |
| PROZS | DEC(5,2) | Porcentaje de liquidacion |
| LSTAR | CHAR(6) | Clase de liquidacion |
| BTYPS | CHAR(2) | Tipo de liquidacion (PER, FUL) |
| DATAB | DATS | Fecha inicio validez |
| DATBI | DATS | Fecha fin validez |

```sql
-- Reglas de liquidacion por proyecto
SELECT w.POSID, c.BUREC,
       c.KONTY AS TIPO_RECEPTOR,
       c.RECID AS RECEPTOR,
       c.PROZS AS PORCENTAJE,
       c.BTYPS AS TIPO_LIQ,
       c.DATAB, c.DATBI
FROM COBRB c
INNER JOIN PRPS w ON w.OBJNR = c.OBJNR
WHERE w.PBUKR = '1000'
  AND w.PSPNR IN (SELECT PSPNR FROM PRHI WHERE PSPNR = 'NUM_PROYECTO')
ORDER BY w.POSID, c.BUREC
```

---

## 10. Estructura de Liquidacion

La estructura de liquidacion permite mapear clases de coste del emisor a clases de coste del receptor. Util cuando el receptor es un activo fijo con clases de coste diferenciadas.

### Configuracion SPRO

```
SPRO → Project System → Costes → Liquidacion →
Definir Estructura de Liquidacion
Transaccion: OK06
```

---

## 11. Liquidacion Periodica vs Final

| Criterio | Periodica | Final |
|---|---|---|
| Cuando | Cada cierre de mes | Al finalizar el proyecto |
| Que se liquida | Solo costes del periodo actual | Todos los costes pendientes |
| Estado WBS | REL (en ejecucion) | TECO o CLSD |
| Saldo WBS | Queda en 0 despues de cada periodo | 0 definitivo |
| Uso tipico | AuC en proyectos largos | Cierre definitivo |

---

## 12. Errores Comunes en Liquidacion

| Error | Causa | Solucion |
|---|---|---|
| No hay regla de liquidacion | WBS sin receptor definido | CJK2 → crear regla |
| Porcentajes no suman 100% | Regla incompleta | Revisar y completar porcentajes |
| Receptor bloqueado | AuC o CC bloqueado | Desbloquear receptor |
| Periodo ya cerrado | Intento de liquidar en periodo cerrado | Abrir periodo CO o usar periodo siguiente |
| WBS sin costes | Nada que liquidar (informativo) | Normal, no es error |
| Cuenta no configurada | Cuenta de ajuste no definida | OKO7 → verificar perfil liquidacion |

---

## 13. Reportes de Liquidacion

| Transaccion | Descripcion |
|---|---|
| CJI3 | Partidas individuales (ver documentos de liquidacion) |
| KO8G | Lista de liquidaciones ejecutadas |
| S_ALR_87013558 | Liquidacion del proyecto |
| GR55 | Report Painter para analisis de liquidacion |

---

## 14. Consultas SQL/MCP

```javascript
// Costes liquidados vs pendientes por WBS
GetSqlQuery({
  query: `SELECT p.POSID,
                 SUM(CASE WHEN a.VRGNG = 'KOAO' THEN a.HSL ELSE 0 END)
                   AS LIQUIDADO,
                 SUM(CASE WHEN a.VRGNG <> 'KOAO' THEN a.HSL ELSE 0 END)
                   AS PENDIENTE
          FROM ACDOCA a
          INNER JOIN PRPS p ON p.PSPNR = a.PSPNR
          WHERE a.RLDNR = '0L'
            AND a.RRCTY = '0'
            AND a.GJAHR = '2024'
            AND p.PBUKR = '1000'
          GROUP BY p.POSID
          ORDER BY p.POSID`
})

// Reglas de liquidacion activas
GetSqlQuery({
  query: `SELECT w.POSID, c.KONTY, c.RECID,
                 c.PROZS, c.BTYPS, c.DATAB, c.DATBI
          FROM COBRB c
          INNER JOIN PRPS w ON w.OBJNR = c.OBJNR
          WHERE w.PBUKR = '1000'
            AND (c.DATBI >= CURRENT_DATE OR c.DATBI = '00000000')
          ORDER BY w.POSID, c.BUREC`
})
```

---

## 15. Mejores Practicas de Liquidacion

1. **Definir reglas antes de la liberacion**: Configurar las reglas de liquidacion (CJK2) antes de liberar el WBS para que queden activas desde el inicio del proyecto.

2. **Prueba antes de liquidar**: Siempre ejecutar CJ88 en modo TEST primero. Verificar los importes antes de ejecutar en modo real.

3. **Liquidacion mensual para AuC**: En proyectos de inversion, liquidar periodicamente (mensual) al AuC para que el balance refleje el valor real del activo en curso.

4. **TECO antes de liquidacion final**: Marcar el WBS como TECO antes de la liquidacion final. Esto cierra el objeto para nuevas imputaciones y facilita el cierre del proyecto.

5. **Estructura de liquidacion para activos complejos**: Cuando el proyecto genera varios tipos de activos (edificio, maquinaria, instalacion), usar estructura de liquidacion para asignar cada clase de coste al activo correspondiente.

6. **Documentar las reglas**: Toda regla de liquidacion debe tener texto explicativo. En auditorias, las reglas sin documentacion generan observaciones.
