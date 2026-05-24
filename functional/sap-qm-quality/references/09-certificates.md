# Certificados de Calidad

## Concepto

Los certificados de calidad (CoA/CoC) documentan los resultados de inspeccion de un material. Se envian al cliente con la entrega o se requieren del proveedor con la recepcion.

## Tipos de certificado

| Tipo | Descripcion | Direccion |
|------|-------------|-----------|
| CoA | Certificate of Analysis | Outbound (a cliente) |
| CoC | Certificate of Conformity | Outbound (a cliente) |
| Inbound | Certificado del proveedor | Inbound (de proveedor) |

## Certificados outbound (a cliente)

### Perfil de certificado — QC21

```sql
SELECT ZESSION, KUESSION, MATNR, WERKS FROM QCPR
WHERE MATNR = '{material}' AND WERKS = '{centro}'
```

El perfil define:
- Que datos incluir (MICs, resultados, lote, lote inspeccion)
- Formato de salida (SAPScript, SmartForms, Adobe Forms)
- Trigger (manual, automatico con entrega)

### Creacion

| TCode | Descripcion |
|-------|-------------|
| QC21 | Crear perfil certificado |
| QC22 | Modificar perfil |
| QC23 | Visualizar perfil |
| QC31 | Crear certificado |
| QC32 | Modificar certificado |
| QC33 | Visualizar certificado |

### Generacion automatica con entrega SD

1. Material con perfil certificado activo
2. Al crear entrega (VL01N), sistema verifica si requiere certificado
3. Lote de inspeccion tipo 14 puede generarse
4. Certificado se imprime con output del delivery

### Configuracion
```
SPRO > Quality Management > Quality Certificates
├── Define Certificate Profiles
├── Define Certificate Categories
├── Assign Certificate Categories to Inspection Types
└── Define Output Determination for Certificates
```

## Certificados inbound (de proveedor)

### Registro — QC51

| TCode | Descripcion |
|-------|-------------|
| QC51 | Registrar certificado entrante |
| QC52 | Modificar |
| QC53 | Visualizar |

### Flujo inbound
1. Proveedor envia certificado (fisico o electronico)
2. QC51 → registrar contra pedido/material/lote
3. Puede vincular con lote de inspeccion tipo 01
4. Resultados del certificado pueden registrarse como resultados de inspeccion

## Datos del certificado

| Dato | Fuente |
|------|--------|
| Material/batch | Lote de inspeccion |
| Resultados MIC | QASR/QASE |
| Decision empleo | QAVE |
| Especificaciones | Plan inspeccion (PLMK) |
| Informacion proveedor | LFA1/EKKO |
| Informacion cliente | KNA1/VBAK |

## Normas de certificado

| Norma | Tipo | Contenido |
|-------|------|-----------|
| EN 10204 2.1 | Declaracion | Conformidad sin datos test |
| EN 10204 2.2 | Test report | Datos de prueba del fabricante |
| EN 10204 3.1 | Inspection certificate | Datos verificados por inspector |
| EN 10204 3.2 | Third party | Verificado por tercero independiente |

## Consultas MCP

```sql
-- Perfiles de certificado activos
SELECT ZESSION, KUESSION, MATNR, WERKS FROM QCPR
WHERE WERKS = '{centro}'

-- Certificados generados
SELECT ZESSION, MATNR, CHARG, ERDAT FROM QCVD
WHERE WERKS = '{centro}' AND ERDAT BETWEEN '{ini}' AND '{fin}'
```
