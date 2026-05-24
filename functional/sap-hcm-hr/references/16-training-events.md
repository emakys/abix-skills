# Training & Event Management (TEM)

## Descripción General

Training & Event Management (TEM) es el módulo de SAP HCM que gestiona la formación corporativa: catálogo de eventos, programación, inscripción de participantes, recursos y costos. En S/4HANA 2023 coexiste con SAP Learning Solution (LSO) y puede integrarse con SuccessFactors Learning.

---

## Catálogo de Eventos de Negocio

### Jerarquía del Catálogo
```
Business Event Group (tipo D)
  └── Business Event Type (tipo E)
        └── Business Event (tipo I, instancia programada)
```

### Transacciones Principales PE*
| Transacción | Descripción |
|-------------|-------------|
| PE00 | Menu dinámico TEM (acceso general) |
| PE01 | Catálogo de eventos de negocio |
| PE02 | Tipos de recursos |
| PE03 | Catálogo de programas de desarrollo |
| PE04 | Funciones y operaciones (Customizing TEM) |
| LSO_PVCT | Catálogo de cursos LSO |

### Tipos de Evento (Event Types — Infotipo 1021)
- **Evento estándar**: clase presencial con fecha/lugar fijos
- **Evento abierto**: sin fecha fija, inscripción bajo demanda
- **Evento de correspondencia**: aprendizaje por correo/autoestudio
- **Evento web (LSO)**: e-learning con contenido SCORM/AICC

### Grupos de Eventos (Business Event Groups)
Agrupan tipos relacionados (ej. "Formación Técnica SAP", "Liderazgo", "Compliance").
Se crean en la estructura organizativa de PD con el tipo de objeto `BG`.

---

## Menús Dinámicos (PV00–PV14)

Los menús dinámicos son la interfaz principal de TEM para gestión operativa:

| Transacción | Función |
|-------------|---------|
| PV00 | Menu general de TEM |
| PV01 | Crear evento de negocio (instancia) |
| PV02 | Cambiar evento de negocio |
| PV03 | Mostrar evento de negocio |
| PV04 | Gestión de reservas (booking) |
| PV05 | Pre-reservas (waitlist) |
| PV06 | Cancelar reserva |
| PV07 | Reubicar participante |
| PV08 | Marcar asistencia/ausencia |
| PV09 | Seguimiento de correspondencia |
| PV10 | Valoración de actividades |
| PV11 | Facturación interna (cost transfer) |
| PV12 | Imprimir materiales del evento |
| PV13 | Gestión de listas de espera |
| PV14 | Cerrar evento de negocio |

---

## Gestión de Recursos

### Tipos de Recursos
1. **Salas y localizaciones** (tipo de objeto `L`): capacidad, equipamiento fijo, ubicación
2. **Instructores** (tipo de objeto `I` o `P`): internos (empleados) o externos
3. **Materiales y equipamiento** (tipo de objeto `E`): proyectores, ordenadores, manuales

### Asignación de Recursos al Evento
- Infotipo 1028 (Resource Requirements) en el tipo de evento: define necesidades estándar
- Infotipo 1029 (Resource Reservation) en la instancia: reserva concreta con fechas/horas
- Verificación de disponibilidad automática al programar el evento

### Gestión de Salas
```
Customizing: SPRO > Training and Event Management > Resources > Room Reservations
Tabla: T77TEM_ROOM
Verificación conflictos: automática al grabar instancia de evento
```

---

## Gestión de Participantes (Attendee Management)

### Flujo de Inscripción
```
Pre-reserva (waitlist) → Reserva confirmada → Asistencia marcada → Evento cerrado → Calificaciones otorgadas
```

### Tipos de Participantes
- **Empleados** (tipo P): integración directa con PA
- **Candidatos** (tipo AP): desde Recruitment
- **Personas de contacto externas** (tipo CP): clientes o proveedores
- **Clientes** (tipo G): para formación externa con facturación

### Infotipos de Participante Relevantes
| Infotipo | Descripción |
|----------|-------------|
| 0019 | Monitoring of Tasks (seguimiento formación obligatoria) |
| 0024 | Qualifications (resultado de formación) |

### Límites de Capacidad
- Capacidad mínima: número mínimo para que el evento se celebre
- Capacidad óptima: número ideal
- Capacidad máxima: tope de inscripción (activa lista de espera automáticamente)

---

## Seguimiento de Asistencia

### Marcado de Asistencia
- Transacción **PV08**: marca asistencia/ausencia por participante
- Estados posibles: Attended, Absent, Partial attendance
- Integración con Time Management: ausencias justificadas por formación

### Cierre del Evento (PV14)
Al cerrar un evento:
1. Se consolida la asistencia
2. Se otorgan calificaciones automáticamente (si configurado)
3. Se transfieren costos (si configurado cost transfer)
4. Se genera correspondencia de confirmación/certificado

---

## Costos y Facturación

### Tipos de Costos TEM
- **Costos internos**: asignados a centro de costo del participante o del organizador
- **Costos externos**: facturación a clientes externos (integración con SD)

### Configuración de Precios
```
SPRO > TEM > Costs and Fees > Define Price Proposals
Tabla: T77TEM_PRICE
```

### Transferencia de Costos Internos (PV11)
- Genera documentos CO: abono al centro de costo formación, cargo al del participante
- Requiere integración activa con CO-CCA
- Precio por participante o precio total del evento prorrateado

### Facturación Externa (integración SD)
- Crea orden de ventas SD por cada participante externo
- Requiere SD configurado con tipos de documento específicos TEM
- Transacción: **PV10** (valoración de actividades)

---

## Integración con PD (Qualifications)

### Calificaciones Automáticas Post-Formación
Al cerrar un evento, TEM puede otorgar calificaciones al infotipo 0024 del empleado:

```
Customizing: Infotipo 1028 en Event Type > Qualifications Awarded
Catálogo de cualificaciones: PPOC_OLD o Org Management
```

### Perfiles de Cualificación
- Definidos en PD con tipo de objeto `Q` (Qualification) y `QK` (Qualification Group)
- Match con perfiles de posición para identificar gaps de formación
- Training Needs Analysis: compara perfil requerido vs. perfil actual del empleado

---

## Learning Solution (LSO)

### Arquitectura LSO en S/4HANA 2023
- LSO amplía TEM con capacidades e-learning
- **Content Player**: reproduce SCORM 1.2, SCORM 2004, AICC
- **Virtual Learning Room**: integración con herramientas de webinar
- **Curriculum**: agrupación de cursos con secuencia obligatoria

### Transacciones LSO
| Transacción | Descripción |
|-------------|-------------|
| LSO_PVCT | Catálogo de cursos |
| LSO_RHXSREPOI | Informes de participación |
| LSO_RHXSREPOM | Informes por gestor |
| LSOCP | Content Player (acceso alumno) |

### Objetos LSO
- **Course** (tipo `C`): equivalente al Business Event Type en TEM
- **Course Group** (tipo `CG`): equivalente al Business Event Group
- **Curriculum** (tipo `CU`): agrupación secuencial de cursos

---

## Comparativa TEM vs. SuccessFactors Learning

| Aspecto | SAP TEM/LSO (on-premise) | SuccessFactors Learning |
|---------|--------------------------|------------------------|
| Despliegue | On-premise / S/4HANA | Cloud (SaaS) |
| Catálogo | Jerárquico (grupos/tipos/instancias) | Flexible, ítems/currículos |
| E-learning | LSO Content Player (SCORM) | LMS completo, xAPI, AICC |
| Mobile | Limitado (Fiori básico) | App nativa iOS/Android |
| Social Learning | No nativo | Integrado |
| Compliance | Básico (certificaciones) | Avanzado (tracks regulatorios) |
| Reporting | SAP Query/BW | People Analytics integrado |
| Integración HCM | Nativa (infotipo 0024) | Via Integration Center/MDF |
| Total Cost | Incluido en licencia HCM | Licencia adicional por usuario |

### Escenario de Coexistencia
En S/4HANA 2023 con Employee Central, es posible:
- Mantener TEM para formación presencial operativa
- Usar SuccessFactors Learning para catálogo e-learning y compliance
- Sincronizar empleados via SAP Integration Suite

---

## Queries y Reporting TEM

### Informes Estándar
| Programa/Transacción | Descripción |
|----------------------|-------------|
| RHXTEALA | Lista de participantes por evento |
| RHXTEANS | Análisis de necesidades de formación |
| RHXTEATT | Seguimiento de asistencia |
| RHXTECST | Análisis de costos de formación |
| RHXTEWAI | Lista de espera por tipo de evento |
| S_PH9_46000172 | Estadísticas de participación |

### Consultas MCP para TEM (S/4HANA)
```abap
" Buscar eventos de formación activos
SearchObject: type=E (Business Event Type), status=Active

" Ver participantes de un evento
GetObjectSource: object_type=I, object_name={event_id}

" Consultar calificaciones de empleado post-formación
ReadInfotype: infotype=0024, pernr={employee_id}
```

### SAP Query Recomendada
```
Área funcional: HR-HRTEM (Training Events)
Campos clave: Event Type, Dates, Capacity, Bookings, Attendees, Status, Cost
Join: Business Event ↔ Attendees ↔ Cost Data
```

---

## Customizing Clave TEM

```
SPRO > Personnel Management > Training and Event Management
├── Basic Settings
│   ├── Maintain Number Ranges
│   └── Set Up Business Event Groups and Types
├── Resources
│   ├── Define Resource Types
│   └── Set Up Room Reservations
├── Attendance
│   ├── Define Attendance Statuses
│   └── Set Up Correspondence
├── Costs and Fees
│   ├── Define Cost Items
│   ├── Define Price Proposals
│   └── Set Up Internal Activity Allocation
└── Integration
    ├── Qualifications Integration (IT0024)
    └── Time Management Integration
```
