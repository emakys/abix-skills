# Errores Frecuentes PM

## Ordenes de Mantenimiento

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| IW 024 | Equipment does not exist | Equipo no existe o dado de baja | IE01 crear o IE02 reactivar |
| IW 061 | Functional location does not exist | Ubicacion tecnica no valida | IL01 crear |
| IW 069 | Order type not allowed for plant | Tipo orden no permitido en centro | SPRO → PM → Order types → asignar a centro |
| IW 072 | Settlement rule missing | Sin regla de liquidacion | IW32 → Detalle → Liquidacion |
| IW 128 | Status does not allow operation | Status TECO/CLSD activo | IW32 reactivar |
| IW 154 | Planning plant not maintained | Centro planificacion no definido | T001W verificar SWERK/IWERK |
| IW 156 | Planner group not found | Grupo planificador no existe | OIP1 crear grupo |
| IW 201 | Work center does not exist | Puesto trabajo no existe en centro | IR01 crear |
| IW 222 | Control key not found | Clave control invalida | SPRO → PM → claves control |
| IW 305 | Maintenance plant missing | Centro mantto no asignado al equipo | IE02 asignar centro |

## Equipos

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| IH 068 | Equipment is locked | Equipo bloqueado | IE02 desbloquear |
| IH 080 | Equipment category invalid | Categoria equipo no valida | SPRO → PM → categorias equipo |
| IH 152 | Serial number already exists | Numero serie duplicado | Verificar unicidad o permitir duplicados |
| IH 200 | Installation not possible | No hay ubicacion tecnica valida | IL01 crear ubicacion |
| IH 301 | Equipment already installed | Equipo ya instalado en otra ubicacion | IE4N desinstalar primero |

## Avisos

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| IQ 100 | Catalog profile missing | Perfil catalogo no asignado | SPRO → PM → Avisos → Catalogo |
| IQ 115 | Code group not found | Grupo de codigos no existe | QS41 crear |
| IQ 200 | Notification type not found | Tipo aviso no existe | OIQA crear tipo |
| IQ 250 | Priority not maintained | Prioridad no definida | SPRO → PM → prioridades |
| IQ 301 | Notification already completed | Aviso ya cerrado | IW22 → reabrir si necesario |

## Planes de Mantenimiento

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| IP 021 | No call object for plan | Plan sin posicion valida | IP02 → verificar posiciones |
| IP 031 | Strategy not found | Estrategia no existe | IP11 crear estrategia |
| IP 040 | Maintenance plan inactive | Plan inactivo | IP02 → activar |
| IP 055 | Cycle set not found | Set de ciclos no definido | IP02 → definir ciclos |
| IP 070 | Task list not found | Hoja ruta referenciada no existe | IA01/IA11 crear |
| IP 082 | Counter not found | Contador no existe | IK01 crear punto medida/contador |

## Confirmaciones

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| CN 224 | Activity cannot be confirmed | Operacion no liberada | IW32 liberar orden/operacion |
| RU 001 | Confirmation already exists | Confirmacion duplicada | Verificar IW49 |
| RU 100 | Final confirmation already posted | Ya hay confirmacion final | IW44 cancelar si error |
| RU 201 | Work center not found | Puesto trabajo no existe | IR01 crear |

## Liquidacion

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| CO 882 | Settlement rule missing | Sin regla liquidacion | IW32/KO02 crear regla |
| CO 888 | Settlement receiver not valid | Receptor invalido (CC/activo) | Verificar maestro receptor |
| KO 130 | Order already settled | Orden ya liquidada en periodo | Verificar periodo contable |
| KO 204 | No costs to settle | Sin costes acumulados | Verificar ACDOCA |

## Movimientos de Material

| Error | Texto | Causa | Fix |
|-------|-------|-------|-----|
| M7 021 | Material not available | Stock insuficiente | Verificar MM03/MMBE |
| M7 032 | Order not released | Orden no liberada para EM | IW32 liberar |
| M7 050 | Reservation not found | Reserva no existe o ya consumida | Verificar IW72 |

## Queries MCP para Diagnostico

```
-- Buscar texto de mensaje
GetSqlQuery("SELECT TEXT FROM T100 WHERE ARBGB='{clase}' AND MSGNR='{num}' AND SPRSL='E'")

-- Status de un objeto
GetSqlQuery("SELECT STAT,INACT FROM JEST WHERE OBJNR='{objeto}' AND INACT=''")

-- Verificar equipo
GetSqlQuery("SELECT EQUNR,EQTYP,SWERK,TPLNR FROM EQUI WHERE EQUNR='{equipo}'")

-- Verificar ubicacion
GetSqlQuery("SELECT TPLNR,IWERK,SWERK FROM IFLOT WHERE TPLNR='{ubicacion}'")
```
