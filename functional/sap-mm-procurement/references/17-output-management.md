# Output Management / Mensajes de Compras

## Concepto

Output management controla como se envia/imprime un documento de compras al proveedor:
impresion, fax, email, EDI/IDoc.

## Configuracion via NACE

```
NACE → Seleccionar aplicacion:
  EF = Purchase Order
  EA = Purchase Requisition (scheduling agreement)
  EB = Contracts

Cada aplicacion tiene:
  - Tipos de mensaje (NEU=nuevo, MAH=reminder, AB=rejection)
  - Medio de transmision (1=print, 2=fax, 5=external send, 7=email, 8=special function)
  - Programa de impresion + formulario
```

## Tipos de mensaje estandar (PO)

| Tipo | Descripcion | Cuando se envia |
|------|-------------|-----------------|
| NEU | Pedido nuevo | Al crear PO (liberada) |
| MAHNPO | Recordatorio entrega | Cuando pasa fecha entrega |
| AUFB | Confirmacion pedido | Al recibir confirmacion prov. |
| LPET | Reminder plan entregas | Scheduling agreement |
| AB | Rechazo | Cancelacion/rechazo PO |

## Medios de transmision

| Medio | Codigo | Config necesaria |
|-------|--------|-----------------|
| Impresion | 1 | Impresora LOCL o SAPD |
| Fax | 2 | SAPconnect (SCOT) |
| EDI/IDoc | 6 | Puerto EDI + partner profile (WE20) |
| Email | 7 | SAPconnect SMTP (SCOT) |
| XML/Output Channel | 8 | Special function |

## Config paso a paso para email

```
1. SCOT → Configurar nodo SMTP
   - Default domain, server SMTP

2. NACE → EF → NEU
   - Medio: 5 (External send) o 7 (email)
   - Programa: SAPFM06P (estandar)
   - Formulario: MEDRUCK (SmartForms) o ZMM_PO_FORM (custom)

3. Partner function en proveedor
   LFA1 → Communication → Email address
   O: WYT3 → Partner function VN (vendor)

4. Condicion de determinacion
   SPRO → MM → Purchasing → Messages → Output Determination
   Tipo doc + org compras → tipo mensaje + medio

5. ME22N → Tab "Messages"
   Verificar que mensaje NEU esta propuesto
   Processing status: 0=no procesado, 1=exitoso, 2=error
```

## Formularios

### SmartForms (recomendado)
```
SMARTFORMS → Formulario: MEDRUCK (estandar PO)
Programa driver: SAPFM06P

Datos disponibles en el formulario:
  - EKKO: cabecera PO
  - EKPO: posiciones
  - EKET: scheduling lines
  - LFA1: datos proveedor
  - T001W: datos centro
  - Textos de cabecera y posicion
```

### Adobe Forms (S/4HANA)
```
SFP → Formulario + Interface
Programa driver: custom (ABAP con cl_fp)
Ventaja: formato PDF profesional, firma digital
```

## Queries MCP

```sql
-- Mensajes de un PO
SELECT EBELN, CMFPNR, NAESSION, PESSION, NAESSION2, LDEST, AESSION
FROM NAST WHERE OBJKY LIKE '{po}%' AND KAPESSION = 'EF'
-- NAESSION=tipo msg, VSTAT=processing status (0/1/2)

-- Config de output por tipo doc
SELECT KAPPL, NAESSION, LDEST, DIMESSION FROM T166C
WHERE KAPPL = 'EF' AND BSART = '{tipo_doc}'

-- Formulario asignado al tipo de mensaje
SELECT KAPPL, NAESSION, MEDIUM, PGNAM, DLNID FROM TNAPR
WHERE KAPPL = 'EF' AND NAESSION = 'NEU'
```

## Errores comunes

| Error | Causa | Fix |
|-------|-------|-----|
| Mensaje no se genera | Condicion output no determinada | NACE revisar condicion |
| Email no llega | SCOT mal configurado | SCOT → verificar nodo SMTP |
| Status rojo (2) | Error en formulario o destino | SOST verificar cola de envio |
| Formulario vacio | Datos no pasados al form | Depurar programa driver |
| PO se imprime en blanco | Formulario incorrecto | NACE → verificar formulario asignado |
