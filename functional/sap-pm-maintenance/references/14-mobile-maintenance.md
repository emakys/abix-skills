# Mantenimiento Movil y Fiori

## Concepto

SAP Fiori proporciona apps moviles y de escritorio para mantenimiento, permitiendo a tecnicos en campo crear avisos, confirmar ordenes y registrar mediciones desde dispositivos moviles.

## Apps Fiori Principales — S/4HANA 2023

### Transaccionales
| App ID | Nombre | Rol | Descripcion |
|--------|--------|-----|-------------|
| F1580 | Create Maintenance Notification | Tecnico | Crear avisos desde campo |
| F1596 | Manage Maintenance Orders | Planificador | Gestionar ordenes completas |
| F2375 | Maintenance Planner | Planificador | Planificacion grafica de ordenes |
| F2649 | Create Maintenance Order | Tecnico/Planif | Crear ordenes rapido |
| F2626 | Manage Maintenance Notifications | Planificador | Gestion completa avisos |
| F3150 | My Maintenance Notifications | Tecnico | Mis avisos asignados |
| F3151 | My Maintenance Orders | Tecnico | Mis ordenes asignadas |
| F3438 | Confirm Maintenance Order | Tecnico | Confirmar operaciones |

### Analiticas
| App ID | Nombre | Tipo |
|--------|--------|------|
| F3304 | Monitor Maintenance Orders | Analytical |
| F3430 | Maintenance Notification Overview | Analytical |
| F3545 | Maintenance Cost Analysis | Analytical |
| F3303 | Equipment Breakdown Analysis | Analytical |
| F3675 | Maintenance Plan Overview | Analytical |

### Factsheets
| App ID | Nombre | Tipo |
|--------|--------|------|
| F2650 | Equipment | Factsheet |
| F2651 | Functional Location | Factsheet |
| F2652 | Maintenance Order | Factsheet |
| F2653 | Maintenance Notification | Factsheet |

## Escenarios Moviles

### Tecnico en campo
1. Recibe notificacion de orden asignada (F3151)
2. Revisa operaciones y repuestos necesarios
3. Ejecuta trabajo
4. Confirma operaciones con horas reales (F3438)
5. Registra datos tecnicos (dano, causa, accion)
6. Toma fotos/adjuntos si necesario

### Ronda de inspeccion
1. Abre lista de puntos de medida
2. Registra lecturas en cada equipo
3. Si valor fuera de rango → crea aviso M1 directamente

### Reporte de averia
1. Tecnico detecta falla en campo
2. F1580 → Crear aviso M1 con equipo/ubicacion
3. Prioridad + descripcion + foto
4. Se notifica al planificador automaticamente

## Offline

- SAP Mobile Platform / SAP Mobile Services permite modo offline
- Sync automatico cuando hay conectividad
- Critico para plantas sin cobertura WiFi/celular

## Mejores Practicas

1. **Roles claros** — tecnico vs planificador, apps distintas
2. **Catalogos simples** — codigos de dano/causa limitados para uso movil
3. **Barcode/QR** — escanear equipo para identificacion rapida
4. **Fotos** — adjuntar evidencia fotografica al aviso
5. **Capacitacion** — entrenar tecnicos en apps especificas, no en SAP GUI
