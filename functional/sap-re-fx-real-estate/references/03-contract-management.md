# Gestión de Contratos — SAP RE-FX (Lease-out y Lease-in)

## 1. Introducción

El contrato (`RECN`, tabla `VICNCN`) es la pieza central que conecta el portafolio físico de
objetos inmobiliarios con los Business Partners, define la vigencia de la relación comercial y
alimenta todos los procesos posteriores: facturación periódica, ajuste de renta, liquidación de
gastos comunes y, en lease-in, el reconocimiento IFRS 16.

---

## 2. Tipos de Contrato

- **Lease-out (arrendamiento saliente)**: la empresa arrienda un inmueble propio a un tercero
  (inquilino). Genera ingreso. El inquilino se modela como Business Partner con rol AR (deudor)
- **Lease-in (arrendamiento entrante)**: la empresa arrienda un inmueble de un tercero
  (arrendador externo). Genera gasto y dispara la lógica IFRS 16. El arrendador externo se modela
  como Business Partner con rol AP (acreedor)
- **Contrato general (Other Contracts)**: contratos que no encajan estrictamente en el patrón
  lease-out/lease-in pero requieren gestión estructurada dentro de RE-FX — por ejemplo, contratos
  de servicios asociados al inmueble, o en algunas implementaciones, escenarios de **WEG
  (Wohnungseigentümergemeinschaft — comunidad/asociación de propietarios)** cuando el cliente
  administra propiedades bajo régimen de copropiedad y necesita modelar la relación entre la
  asociación y los propietarios individuales

**Tabla:** `VICNCN` — cabecera del contrato (vigencia, tipo, sociedad, objetos vinculados)

---

## 3. Ciclo de Vida del Contrato

```
Borrador (creación) → Oferta/Negociación (opcional) → Activo/Liberado → Vigente → Próximo a vencer → Finalizado/Vencido
                                                              │
                                                              └── Prórroga / Renovación (nuevo periodo de vigencia)
                                                              └── Rescisión anticipada (terminación antes de VENDDAT original)
```

- **VBEGDAT / VENDDAT**: fecha de inicio y fin de vigencia del contrato
- Un contrato puede tener **plazo indefinido** con condiciones de preaviso, o **plazo fijo** con
  fecha de terminación conocida desde el inicio
- La renovación no siempre modifica el mismo registro — según el diseño, puede generarse un nuevo
  periodo de vigencia sobre el mismo contrato o un contrato de continuación vinculado

---

## 4. Objetos Vinculados al Contrato

Un contrato puede vincular **uno o varios Rental Objects** (ej. un inquilino que arrienda varias
oficinas en el mismo edificio bajo un único contrato consolidado). La asignación objeto-contrato
tiene su propia vigencia, que normalmente coincide con la del contrato pero puede diferir si se
agregan o liberan objetos durante la vida del contrato (ej. expansión o reducción de espacio
arrendado).

---

## 5. Socios del Contrato (Partners)

- **Inquilino (Tenant, lease-out)** o **Arrendador externo (lease-in)**: el partner principal,
  contraparte comercial del contrato
- **Garante (Guarantor)**: partner adicional que respalda el cumplimiento financiero del inquilino,
  relevante para evaluación de riesgo crediticio en lease-out
- Todos se modelan como **Business Partner** con el rol correspondiente (AR para inquilino, AP
  para arrendador externo)

**Tabla:** `VICNCNP` (orientativo) — socios del contrato con su rol y vigencia

---

## 6. Contrato Lease-in e IFRS 16

Un contrato lease-in requiere, además de los datos comerciales estándar, la **clasificación
contable IFRS 16 / ASC 842**:

- Clasificación del arrendamiento (bajo IFRS 16, prácticamente todos los lease-in de largo plazo se
  reconocen en balance, salvo las excepciones de corto plazo o bajo valor — ver `07-lease-in-ifrs16.md`)
- Tasa de descuento aplicable (tasa incremental de financiamiento del arrendatario, u otra según
  política contable del cliente)
- Componentes no-lease del contrato (servicios incluidos que deben separarse del componente de
  arrendamiento puro, si el estándar contable lo exige y el cliente no aplica la exención práctica
  de no separarlos)

Esta parametrización dispara, en la contabilización inicial, la generación automática del activo
por derecho de uso (ROU) y el pasivo por arrendamiento — ver `07-lease-in-ifrs16.md` para el
detalle completo.

---

## 7. Consultas MCP Útiles (GetSqlQuery)

### Contratos vigentes de una sociedad a la fecha actual

```sql
SELECT vertrag, vertnr, verttyp, vbegdat, venddat, bukrs
FROM vicncn
WHERE bukrs = '{sociedad}'
  AND vbegdat <= CURRENT_DATE
  AND venddat >= CURRENT_DATE
```

### Contratos próximos a vencer (siguientes 90 días)

```sql
SELECT vertrag, vertnr, venddat
FROM vicncn
WHERE venddat BETWEEN CURRENT_DATE AND CURRENT_DATE + 90
ORDER BY venddat
```

### Socios de un contrato específico

```sql
SELECT vertrag, partner, parvw, datab, datbi
FROM vicncnp
WHERE vertrag = '{contrato}'
```

---

## 8. Validaciones al Mantener un Contrato

| Validación | Por qué importa |
|---|---|
| Vigencia del contrato cubre la vigencia de sus condiciones | Evita facturación sin condición válida en la fecha |
| Todos los Rental Objects vinculados existen y no están duplicados en otro contrato activo | Previene doble asignación (mismo objeto en dos contratos vigentes simultáneos) |
| Business Partner con rol AR/AP completo antes de activar el contrato | La facturación periódica requiere ese rol para generar la partida FI |
| Clasificación IFRS 16 completa en contratos lease-in | Sin ella, no se genera el ROU asset y el gasto queda mal reconocido contablemente |

---

## 9. Buenas Prácticas

1. **No reutilizar un contrato existente para representar una relación comercial completamente
   distinta** (ej. nuevo inquilino tras la salida del anterior) — crear un contrato nuevo preserva
   la trazabilidad histórica.

2. **Documentar claramente la fecha efectiva de cualquier expansión/reducción de espacio** dentro
   de un contrato existente, con la vigencia correcta en la asignación objeto-contrato.

3. **Completar la clasificación IFRS 16 en el momento de crear el contrato lease-in**, no como
   actividad posterior — evita contabilizaciones provisionales que luego requieren corrección.

4. **Revisar contratos próximos a vencer con antelación suficiente** (ver reporte del punto 7) para
   dar tiempo a negociar renovación o gestionar la salida del inquilino/objeto.
