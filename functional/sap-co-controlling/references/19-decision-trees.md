# Arboles de Decision CO

## Donde imputar un coste?

```
¿El coste es recurrente y operativo?
├── SI: ¿Pertenece a un area funcional especifica?
│   ├── SI → Centro de coste (KS01)
│   └── NO → CC general + Distribucion/Assessment a receptores
├── NO: ¿Es un proyecto con inicio y fin?
│   ├── SI: ¿Es CAPEX (inversion capitalizable)?
│   │   ├── SI → Orden inversion tipo 0200 (liquida a activo fijo)
│   │   └── NO: ¿Es complejo con fases?
│   │       ├── SI → Proyecto PS (WBS elements)
│   │       └── NO → Orden interna real tipo 0100
│   └── NO: ¿Es un servicio interno entre areas?
│       ├── SI → Actividad interna (KB21N)
│       └── NO → Consultar con controller
```

## Que tipo de orden usar?

```
¿Cual es el proposito?
├── Gasto operativo no recurrente → Tipo 0100 (Overhead)
├── Inversion capitalizable (CAPEX) → Tipo 0200 (Inversion)
│   Liquida a: activo fijo
├── Periodificacion / accrual → Tipo 0300
├── Trabajo con ingreso interno → Tipo 0400
├── Mantenimiento → Orden PM (AUFTYP 30)
├── Produccion → Orden PP (AUFTYP 10)
```

## Distribucion vs Assessment?

```
¿El receptor necesita ver detalle por clase de coste?
├── SI → Distribucion (KSV5)
│   Mantiene clases de coste primarias originales
├── NO → Assessment (KSU5)
│   Usa clase coste secundaria (42)
│
¿Hay clases de coste secundarias involucradas?
├── SI → Assessment (distribucion no puede repartir secundarias)
└── NO → Cualquiera de los dos
```

## Precio estandar vs promedio movil?

```
¿El material es de produccion propia?
├── SI → Precio estandar (S) basado en BOM + Routing
├── NO: ¿El precio de compra fluctua mucho?
│   ├── SI → Precio promedio movil (V)
│   └── NO → Precio estandar (S) tambien valido
│
¿Material Ledger activo? (obligatorio en S/4)
└── SI → Ambos se revaluan a actual cost al cierre (CKMLCP)
```

## Que reporte CO usar?

```
¿Que quiero analizar?
├── Costes de un centro de coste → S_ALR_87013611 / Fiori F3066
├── Plan vs Real de CC → S_ALR_87013611 / Fiori F2723
├── Costes de una orden → KOB1 / Fiori F2709
├── Rentabilidad por cliente/producto → KE30 / Fiori F5765
├── Margen de contribucion → Fiori F5889
├── P&L por profit center → S_ALR_87013620 / Fiori F3737
├── Coste de producto → CK13N / Fiori F0711
├── Material Ledger / precio real → CKM3N / Fiori F2839
```

## Que hacer si el cierre CO falla?

```
¿En que paso fallo?
├── Distribucion/Assessment → CC emisor tiene saldo? Ciclo definido?
├── Overhead → Costing sheet asignada? Base tiene valores?
├── WIP → Orden con status TECO/DLV? Clave WIP asignada?
├── Desviaciones → Calculo coste estandar existe?
├── Settlement → Regla definida? Receptor valido? % suman 100?
├── Material Ledger → Materiales costeados? Periodo anterior cerrado?
```
