# Escenarios MTS / MTO / ETO

## Make-to-Stock (MTS)

Produccion contra stock. Se fabrica basado en pronostico/PIR, sin referencia a pedido de venta.

### Configuracion MTS

| Campo MARC | Valor | Descripcion |
|------------|-------|-------------|
| DISMM | PD | MRP determinista |
| BESKZ | E | Fabricacion propia |
| STRGR | 10 | MTS with planning (PIR consumidas por pedidos) |
| STRGR | 11 | MTS net requirements (PIR no consumidas) |
| STRGR | 40 | Planning with final assembly |

### Flujo MTS

```
1. MD61 → Crear PIR (necesidades independientes)
2. MD01 → MRP → genera ordenes previsionales
3. CO41 → Convertir a ordenes produccion
4. Produccion → GI/Confirmacion/GR
5. Stock disponible para pedidos venta
```

### Consumption (consumo de PIR por pedidos venta)

| VRMOD | Modo | Descripcion |
|-------|------|-------------|
| 1 | Backward | Pedido consume PIR pasadas primero |
| 2 | Forward | Pedido consume PIR futuras primero |
| 3 | Backward-Forward | Intenta backward, luego forward |
| 4 | Forward-Backward | Intenta forward, luego backward |

- VINT1: Periodo backward (dias)
- VINT2: Periodo forward (dias)

## Make-to-Order (MTO)

Produccion contra pedido de venta individual. Cada orden de produccion esta vinculada a un pedido.

### Configuracion MTO individual

| Campo MARC | Valor | Descripcion |
|------------|-------|-------------|
| DISMM | PD | MRP determinista |
| BESKZ | E | Fabricacion propia |
| STRGR | 20 | Make-to-order |
| SOBSL | — | Sin special procurement |

### Flujo MTO

```
1. VA01 → Pedido de venta (posicion con material MTO)
2. MD01/MD02 → MRP genera previsional con KDAUF/KDPOS
3. CO40 → Convertir a orden produccion (vinculada a pedido)
4. Produccion → componentes pueden ser stock comun
5. GR → stock individual (individual customer stock)
6. VL01N → Entrega desde stock individual del pedido
```

### Campos MTO en orden produccion

| Tabla | Campo | Descripcion |
|-------|-------|-------------|
| AFPO | KDAUF | Numero pedido venta |
| AFPO | KDPOS | Posicion pedido venta |
| RESB | KDAUF | Pedido (si componentes tambien MTO) |

```sql
-- Ordenes produccion MTO
SELECT A.AUFNR, A.PLNBEZ, P.KDAUF, P.KDPOS, A.GAMNG, A.GSTRP
FROM AFKO A
INNER JOIN AFPO P ON A.AUFNR = P.AUFNR
WHERE P.KDAUF <> '' AND A.WERKS = '{centro}'
```

## Make-to-Order con planning (Strategy 50)

Combina MTO con planificacion individual:
- Cada pedido genera su propia corrida MRP
- Stock segregado por pedido (segment)
- Componentes pueden ser stock comun o individual

## Planning with Final Assembly (Strategy 40)

- Semielaborados se planifican contra PIR (MTS)
- Producto final se produce contra pedido (MTO)
- Combina lo mejor de ambos mundos

```
PIR → MRP componentes/semielaborados → Stock semielaborados
                                                ↓
Pedido venta → MRP producto final → Orden produccion final → Consume semielaborados
```

## Engineer-to-Order (ETO)

- Cada pedido requiere ingenieria/diseno especifico
- BOM y routing se crean/modifican por proyecto
- Usa WBS elements (PS) o order BOM individual
- Strategy group: 25 o 82

### Order BOM
- BOM individual por orden de produccion
- Permite modificar componentes sin afectar BOM general
- Se crea en CO02 → BOM order

## Configuracion SPRO

```
SPRO > Production > MRP > Master Data > Independent Requirements
  → Define Strategy Group
  → Define Strategy
  → Assignment of MRP Groups

SPRO > Production > MRP > Planning > MRP Calculation
  → Consumption Mode
```

## ATP (Available to Promise) en PP

| Tipo verificacion | Contra | Uso |
|-------------------|--------|-----|
| Contra stock | MARD-LABST | Solo stock disponible |
| Contra stock + recepciones | Stock + OC + OP | Incluye supply futuro |
| Contra plan produccion | Stock + PIR + OP | MTS completo |
| Contra capacidad | Capacidad puestos | Solo si finite scheduling |

- MTVFP (availability check group) controla que se verifica
- Configurar en SPRO > Sales > Availability Check

## Consultas MCP diagnostico

```sql
-- Strategy group de un material
SELECT MATNR, WERKS, STRGR, VRMOD, VINT1, VINT2 FROM MARC
WHERE MATNR = '{material}' AND WERKS = '{centro}'

-- PIR activas
SELECT MATNR, WERKS, PDATU, GESSION FROM PBIM
WHERE MATNR = '{material}' AND WERKS = '{centro}' AND VERSB = '00'

-- Ordenes MTO de un pedido
SELECT A.AUFNR, A.PLNBEZ, A.GAMNG, P.KDAUF, P.KDPOS
FROM AFKO A INNER JOIN AFPO P ON A.AUFNR = P.AUFNR
WHERE P.KDAUF = '{pedido}'
```
