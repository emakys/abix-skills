# Troubleshooting — MCP Tools Errores Comunes

## Errores de Deploy

### "save operation" (generico)
**Causa:** SAP no da detalles. Puede ser:
- Parametros invalidos pasados al tool (ej: `language` en CreateClass)
- Error de sintaxis en el source code
- Objeto lockeado por otro usuario/proceso
- Paquete no existe o sin autorizacion

**Solucion:**
1. NO pasar parametros que el tool no acepta (ver inputSchema)
2. Hacer `Check*` antes de `Update*` para validar sintaxis
3. Verificar que el transport request es valido
4. Verificar que no hay lock (otro usuario en SE80/Eclipse)

### "Object is locked by user X"
**Causa:** Alguien tiene el objeto abierto en SAP GUI o Eclipse.

**Solucion:**
- Esperar a que el usuario libere el lock
- En emergencia: SM12 para ver/eliminar locks (requiere autorizacion)
- Los tools high-level hacen auto-lock/unlock, pero si falla mid-operation el lock puede quedar

### "Transport request required"
**Causa:** Objeto esta en paquete transportable (no $TMP) y no se paso `transport_request`.

**Solucion:**
- Pasar `transport_request` en todo Create/Update para paquetes != $TMP
- Usar `CreateTransport` si no hay transport disponible
- Verificar con `GetTransportRequests` que hay uno abierto

### "Object already exists"
**Causa:** Se intento `Create*` sobre un objeto que ya existe.

**Solucion:**
- Siempre hacer `SearchObject` primero
- Si existe: usar `Update*` en vez de `Create*`

### "Object does not exist"
**Causa:** Se intento `Update*` o `Read*` sobre objeto inexistente.

**Solucion:**
- Verificar nombre (case-sensitive, UPPERCASE)
- Verificar que se activo correctamente
- Usar `Create*` primero

### "Activation failed"
**Causa:** El objeto tiene dependencias no activadas.

**Solucion:**
- Seguir orden estricto: DOMA → DTEL → TABL → DDLS → BDEF → CLAS → DDLX → SRVD → SRVB
- Activar cada dependencia ANTES de activar el dependiente
- Usar `ActivateObjects` para activar multiples en una llamada

### "Syntax error in line X"
**Causa:** El source code tiene error de sintaxis ABAP/CDS.

**Solucion:**
- Usar `Check*` (CheckClass, CheckView, etc.) ANTES de Activate
- Corregir el source y hacer Update de nuevo
- `GetAbapSemanticAnalysis` da detalles mas ricos del error

## Errores de Conexion

### "401 Unauthorized"
- Verificar usuario/password SAP
- Verificar que el servicio ICF `/sap/bc/adt` esta activo
- Verificar autorizacion `S_ADT_RES`

### "403 Forbidden"
- El usuario no tiene autorizacion para la operacion
- Verificar roles: `SAP_BC_DWB_ABAPDEVELOPER` para desarrollo completo
- En modo readonly (REPO) no se pueden usar tools de escritura

### "404 Not Found"
- El endpoint ADT no existe en este sistema SAP
- Puede ser version de BASIS muy antigua (< 7.50)
- Verificar que el sistema es S/4HANA y no ECC

### "500 Internal Server Error"
- Error interno de SAP — revisar SM21/ST22
- Puede ser timeout en operaciones pesadas
- Reintentar una vez, si persiste es problema del sistema

## Errores Especificos

### DCLS (Access Control) no soportado
`@mcp-abap-adt/core` v6.8.0 NO tiene handlers para DCLS.
- Omitir en deploy automatico
- Crear manualmente en SAP GUI (SE80) o Eclipse

### SRVB PublishServiceBinding falla
- El SRVB debe estar activado ANTES de publicar
- Verificar que el SRVD referenciado existe y esta activo
- Verificar que el binding type es correcto (OData V2 o V4)

### Unit Test timeout
- Los tests CDS pueden ser lentos si acceden datos reales
- Usar `max_time` si disponible
- Verificar con `GetUnitTestStatus` antes de pedir resultado

### Profiler trace no encontrada
- Despues de `RuntimeRunProgramWithProfiling`, la traza tarda unos segundos
- Esperar 2-3 segundos antes de llamar `RuntimeListProfilerTraceFiles`
- El programa debe ejecutarse SIN errores para generar traza

## Tips de Rendimiento

1. **Minimizar llamadas**: Usar `ActivateObjects` para activar varios a la vez
2. **Check antes de Activate**: Evita ciclos de error → corregir → reintentar
3. **Batch deploy**: Crear todos los objetos primero, luego activar en orden
4. **SearchObject con tipo**: `SearchObject(query="ZCL*", object_type="CLAS")` es mas rapido que sin tipo
5. **ReadClass version active**: Usar `version='active'` para leer la version productiva
