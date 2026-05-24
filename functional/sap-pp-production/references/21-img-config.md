# Guias IMG (SPRO) — PP

## Estructura SPRO PP

```
SPRO > Production
├── Basic Data
│   ├── Material
│   ├── Bill of Material
│   ├── Routing
│   └── Work Center
├── Material Requirements Planning (MRP)
│   ├── Master Data
│   ├── Planning
│   ├── Lot Size
│   └── Availability Check
├── Shop Floor Control
│   ├── Master Data
│   ├── Order
│   ├── Operations
│   ├── Goods Movements
│   └── Confirmation
├── Capacity Planning
├── Repetitive Manufacturing
├── Production Planning for Process Industries (PP-PI)
└── Demand Management
```

## Basic Data

### BOM Configuration
```
SPRO > Production > Basic Data > Bill of Material
├── General Data
│   ├── Define BOM Usage (T416)
│   ├── Define Item Categories (T415)
│   └── Define BOM Status (T417)
├── Default Values
│   └── Define Defaults for BOM Explosion
└── Engineering Change Management
    └── Define Change Types
```

### Routing Configuration
```
SPRO > Production > Basic Data > Work Scheduling
├── Routing
│   ├── Define Control Keys (T430)
│   ├── Define Standard Value Keys
│   ├── Scheduling Formulas (TC24)
│   └── Operation Default Values
├── General Data
│   ├── Define Task List Types
│   └── Define Status
└── Work Center
    ├── Define Capacity Categories
    ├── Define Available Capacity Versions
    └── Define Factory Calendar Assignment
```

## MRP Configuration

### Master Data MRP
```
SPRO > Production > MRP > Master Data
├── Define MRP Groups (T439A)
├── Define MRP Controllers (T024D)
├── Define Special Procurement Types
├── Define MRP Areas (T460A)
└── Independent Requirements
    ├── Define Strategy Groups
    ├── Define Planning Strategy
    └── Define Consumption Parameters
```

### Planning
```
SPRO > Production > MRP > Planning
├── MRP Calculation
│   ├── Define Scope of Planning (NETCH/NEUPL/NETPL)
│   ├── Define Planning Calendar
│   └── Define Exception Messages
├── Scheduling
│   ├── Define Scheduling Type
│   ├── Define Floats (T436A)
│   └── Define Interoperation Times
├── Lot Size
│   ├── Define Lot-Sizing Procedures (T457E)
│   └── Define Rounding Profile
└── Availability Check
    ├── Define Checking Groups
    ├── Define Checking Rules
    └── Define Scope of Check
```

## Shop Floor Control

### Order Configuration
```
SPRO > Production > Shop Floor Control > Master Data > Order
├── Define Order Types (T003O)
│   → PP01 (Prod), PP02 (Process), PP03 (Rework)
├── Define Number Ranges (NRIV)
├── Define Order Type-Dependent Parameters
│   ├── Scheduling Type
│   ├── Costing
│   ├── Availability Check
│   ├── BOM Explosion
│   └── Capacity Requirements
├── Define Settlement Profile
├── Define Results Analysis Key (WIP)
└── Define Production Scheduler Groups (T024F)
```

### Confirmation
```
SPRO > Production > Shop Floor Control > Operations > Confirmation
├── Define Confirmation Parameters (T496A)
│   ├── Final Confirmation
│   ├── Automatic GR
│   ├── Backflush
│   └── Milestone
├── Define Scrap Reasons (T430)
├── Define Deviation Reasons
└── Define Confirmation Variants
```

### Goods Movements
```
SPRO > Production > Shop Floor Control > Goods Movements
├── Define Movement Types for Production
│   ├── 101 — GR from production
│   ├── 261 — GI for production order
│   ├── 531 — By-product receipt
│   └── Custom movement types
├── Define Backflush Control
└── Automatic Account Determination (OBYC)
    ├── GBB-AUF — Production settlement
    ├── BSX — Stock changes
    └── PRD — Price differences
```

## Capacity Planning
```
SPRO > Production > Capacity Planning
├── Define Available Capacity
│   ├── Capacity Categories
│   ├── Shift Sequences
│   └── Factory Calendar
├── Define Capacity Evaluation
│   ├── Evaluation Profiles
│   └── Period Patterns
└── Define Leveling
    ├── Strategy for Leveling
    └── Finite Scheduling Parameters
```

## Repetitive Manufacturing
```
SPRO > Production > Repetitive Manufacturing
├── Define Repetitive Manufacturing Profiles
├── Define Backflush Control
├── Define Reporting Points
├── Define Cost Collectors
└── Define Planning Table Profiles
```

## Demand Management
```
SPRO > Production > Demand Management
├── Define Planned Independent Requirements
│   ├── Requirement Types
│   └── Versions
├── Define Strategy Groups
├── Define Consumption
│   ├── Consumption Mode (backward/forward)
│   └── Consumption Periods
└── Define Availability Check for PIR
```

## Paths mas usados (acceso rapido)

| Necesidad | Path SPRO |
|-----------|-----------|
| Tipo orden produccion | Prod > Shop Floor > Master Data > Order > Define Order Types |
| Parametros MRP | Prod > MRP > Planning > MRP Calculation |
| Claves control routing | Prod > Basic Data > Work Scheduling > Routing > Control Keys |
| Confirmacion | Prod > Shop Floor > Operations > Confirmation |
| Tamano lote | Prod > MRP > Lot Size |
| Strategy groups | Prod > MRP > Master Data > Independent Requirements |
| Disponibilidad | Prod > MRP > Availability Check |
| Calendario fabrica | Logistics General > Factory Calendar |
