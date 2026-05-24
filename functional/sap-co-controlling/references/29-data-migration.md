# Migracion de Datos CO

## Objetos de migracion CO

| Objeto | Herramienta | BAPI/Programa |
|--------|-------------|---------------|
| Centros de coste | Migration Cockpit / LSMW | BAPI_COSTCENTER_CREATEMULTIPLE |
| Profit centers | Migration Cockpit / LSMW | BAPI_PROFITCENTER_CREATE |
| Ordenes internas | Migration Cockpit / LSMW | BAPI_INTERNALORDER_CREATE |
| Clases de actividad | LSMW / BDC | KL01 (BDC recording) |
| Cifras estadisticas | LSMW / BDC | KK01 (BDC recording) |
| Saldos CC (plan) | KP97 / upload file | Formato plan upload |
| Jerarquias CC/PC | Programa custom | SET_INSERT_NODE FM |
| Precios material | LSMW | MR21/CK11N |

## Orden de migracion

```
1. Area de controlling (OKKP) — config, no migracion
2. Clases de coste secundarias (KA06) — si ECC
3. Centros de coste (KS01/BAPI)
4. Jerarquias CC (OKEON)
5. Profit centers (KE51/BAPI)
6. Jerarquias PC (KCH1)
7. Ordenes internas (KO01/BAPI)
8. Clases de actividad (KL01)
9. Cifras estadisticas (KK01)
10. Tarifas plan (KP26)
11. Datos plan CC (KP06)
12. Presupuestos ordenes (KO22)
13. Saldos apertura (saldos FI arrastran CO)
```

## Validacion post-migracion

```sql
-- Verificar CC migrados
SELECT COUNT(*) FROM CSKS WHERE KOKRS = '{area}'

-- Verificar PC migrados
SELECT COUNT(*) FROM CEPC WHERE KOKRS = '{area}'

-- Verificar ordenes migradas
SELECT COUNT(*) FROM AUFK WHERE BUKRS = '{sociedad}' AND AUTYP = '01'

-- Verificar todos los CC tienen PC
SELECT KOSTL FROM CSKS
WHERE KOKRS = '{area}' AND DATBI >= '{hoy}' AND PRCTR = ''
```

## Consideraciones S/4HANA

| Aspecto | Nota |
|---------|------|
| Clases coste primarias | No migrar — se derivan de cuentas GL |
| Tablas de totales | No existen en S/4 — ACDOCA |
| CO-PA clasico | Migrar a account-based si posible |
| Material Ledger | Siempre activo — verificar precios MBEW |
| Saldos historicos | Migrar via GL balance opening — CO se deriva |
