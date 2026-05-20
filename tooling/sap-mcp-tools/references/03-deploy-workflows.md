# Workflows de Deploy — MCP Tools

## Deploy de Clase ABAP

```
1. SearchObject(query="ZCL_EXAMPLE", object_type="CLAS")
   → Si existe: usar Update. Si no: usar Create.

2. CreateClass(class_name="ZCL_EXAMPLE", package="ZDEV", transport_request="S4DK900123",
               description="Clase ejemplo")

3. UpdateClassSource(class_name="ZCL_EXAMPLE", transport_request="S4DK900123",
                     source="CLASS zcl_example DEFINITION PUBLIC...\nENDCLASS.\nCLASS zcl_example IMPLEMENTATION.\nENDCLASS.")

4. CheckClass(class_name="ZCL_EXAMPLE")
   → Verificar que no hay errores de sintaxis

5. ActivateClass(class_name="ZCL_EXAMPLE")
   → Lock automatico, activa, unlock
```

## Deploy de CDS View

```
1. SearchObject(query="ZI_MATERIAL", object_type="DDLS")

2. CreateView(view_name="ZI_MATERIAL", package="ZDEV", transport_request="S4DK900123",
              source="@AbapCatalog.viewEnhancementCategory: [#NONE]\ndefine view entity ZI_Material...")

3. CheckView(view_name="ZI_MATERIAL")

4. ActivateView(view_name="ZI_MATERIAL")
```

## Deploy RAP Completo (orden estricto)

IMPORTANTE: Respetar el orden. Activar dependencias antes que dependientes.

```
Paso 1: Tablas base
  CreateTable(table_name="ZMAT_D") → tabla de datos
  CreateTable(table_name="ZMAT_DD") → tabla draft (si aplica)
  ActivateTable(table_name="ZMAT_D")
  ActivateTable(table_name="ZMAT_DD")

Paso 2: CDS Interface
  CreateView(view_name="ZI_MATERIAL", source="define root view entity ZI_Material as select from zmat_d...")
  ActivateView(view_name="ZI_MATERIAL")

Paso 3: BDEF Interface
  CreateBehaviorDefinition(bdef_name="ZI_MATERIAL", source="managed implementation in class zcl_bp_i_material unique;...")
  ActivateBehaviorDefinition(bdef_name="ZI_MATERIAL")

Paso 4: Behavior Pool (clase)
  CreateClass(class_name="ZCL_BP_I_MATERIAL")
  UpdateClassSource(class_name="ZCL_BP_I_MATERIAL", source="CLASS zcl_bp_i_material DEFINITION...")
  ActivateClass(class_name="ZCL_BP_I_MATERIAL")

Paso 5: CDS Consumption (projection)
  CreateView(view_name="ZC_MATERIAL", source="define root view entity ZC_Material as projection on ZI_Material...")
  ActivateView(view_name="ZC_MATERIAL")

Paso 6: BDEF Consumption
  CreateBehaviorDefinition(bdef_name="ZC_MATERIAL", source="projection;...")
  ActivateBehaviorDefinition(bdef_name="ZC_MATERIAL")

Paso 7: Metadata Extension
  CreateMetadataExtension(extension_name="ZC_MATERIAL", source="@Metadata.layer: #CONSUMER\nannotate entity ZC_Material with...")
  ActivateMetadataExtension(extension_name="ZC_MATERIAL")

Paso 8: Service Definition
  CreateServiceDefinition(srvd_name="ZUI_MATERIAL", source="@EndUserText.label: 'Material Service'\ndefine service ZUI_Material { expose ZC_Material as Material; }")
  ActivateServiceDefinition(srvd_name="ZUI_MATERIAL")

Paso 9: Service Binding
  CreateServiceBinding(srvb_name="ZUI_MATERIAL_O4", ...)
  ActivateServiceBinding(srvb_name="ZUI_MATERIAL_O4")
  PublishServiceBinding(srvb_name="ZUI_MATERIAL_O4")
```

## Deploy de Function Module

```
1. CreateFunctionGroup(function_group="ZFUGR_EXAMPLE", package="ZDEV", transport_request="...")
   → Solo si el FUGR no existe

2. CreateFunctionModule(function_module="Z_FM_EXAMPLE", function_group="ZFUGR_EXAMPLE",
                        transport_request="...", description="...")

3. UpdateFunctionModule(function_module="Z_FM_EXAMPLE", source="FUNCTION z_fm_example.\n*...\nENDFUNCTION.",
                        transport_request="...")

4. ActivateFunctionModule(function_module="Z_FM_EXAMPLE")
```

## Actualizar Objeto Existente

```
1. SearchObject(query="ZCL_EXAMPLE") → confirmar que existe
2. ReadClass(class_name="ZCL_EXAMPLE") → leer version actual (opcional, para diff)
3. UpdateClassSource(class_name="ZCL_EXAMPLE", source="...", transport_request="...")
4. CheckClass(class_name="ZCL_EXAMPLE")
5. ActivateClass(class_name="ZCL_EXAMPLE")
```

## Publicar Servicio OData

```
1. ActivateServiceBinding(srvb_name="ZUI_MATERIAL_O4")
2. PublishServiceBinding(srvb_name="ZUI_MATERIAL_O4")
   → Registra el servicio en el gateway
3. GetServiceBindingStatus(srvb_name="ZUI_MATERIAL_O4")
   → Verifica que esta publicado
```

## Eliminar Objeto (con analisis de impacto)

```
1. GetObjectDeletionAnalysis(object_name="ZCL_OLD", object_type="CLAS")
   → Muestra dependencias que se romperian
2. WhereUsed(object_name="ZCL_OLD") → confirmar que no se usa
3. DeleteClass(class_name="ZCL_OLD", transport_request="...")
```
