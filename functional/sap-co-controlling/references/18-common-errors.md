# Errores Frecuentes CO

## Clases de mensaje CO

| Clase | Area |
|-------|------|
| KI | Cost center / controlling general |
| KD | Cost elements |
| KO | Internal orders |
| KP | Planning / budgeting |
| KA | Activity types |
| CO | Settlement / general controlling |
| CK | Product costing |
| KE | CO-PA |

## Centro de Coste (KI)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| KI 235 | Cost center does not exist | CC no creado o fuera de validez | KS01 crear o KS02 ampliar DATBI |
| KI 240 | Cost center is locked | CC bloqueado | KS02 desbloquear |
| KI 243 | Cost center is not active | CC con DATBI < fecha posting | KS02 ampliar validez |
| KI 330 | Profit center not maintained | Falta PC en CC | KS02 asignar PRCTR |

## Clases de Coste (KD)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| KD 210 | Account is not a cost element | Cuenta no es clase coste (ECC) | KA01 crear |
| KD 302 | No cost element for account | S/4: OKB9 inactivo | OKB9 activar |

## Ordenes Internas (KO)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| KO 004 | Order does not exist | Numero invalido | KO01 crear |
| KO 014 | Order is not released | Status CRTD | KO02 → Liberar |
| KO 018 | Order is technically completed | Status TECO | KO02 → Reactivar |

## Presupuesto (KP)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| KP 045 | Budget exceeded | Supera presupuesto | KO22/KO24 aumentar |

## Settlement (CO)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| CO 882 | Settlement rule missing | Sin regla liquidacion | KO02 → tab Liquidacion |
| CO 878 | Receiver not valid | Perfil no permite receptor | OKO7 ampliar |
| CO 636 | Settlement not possible | Orden cerrada | Verificar status |
| CO 770 | Percentages don't total 100% | Regla incompleta | KO02 → corregir % |

## Product Costing (CK)

| Msg | Texto | Causa raiz | Fix |
|-----|-------|-----------|-----|
| CK 130 | BOM not found | Sin lista materiales | CS01 crear BOM |
| CK 132 | Routing not found | Sin hoja de ruta | CA01 crear routing |

## Workflow de diagnostico

```
1. Obtener clase+numero del mensaje
2. GetSqlQuery("SELECT TEXT FROM T100 WHERE ARBGB='{clase}' AND MSGNR='{num}' AND SPRSL='E'")
3. GetWhereUsed("{clase}:{num}") → localizar programa
4. ReadProgram/ReadClass → ver condicion IF antes del MESSAGE
5. Queries a tablas maestras (CSKS, AUFK, CEPC, CSKA, ACDOCA)
6. Diagnostico + solucion + impacto cross-module
```
