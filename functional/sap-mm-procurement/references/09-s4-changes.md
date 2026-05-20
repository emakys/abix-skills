# Simplifications ECC -> S/4HANA — Modulo MM

## Cambios criticos

### Business Partner (BP) reemplaza Vendor
| ECC | S/4HANA | Impacto |
|-----|---------|---------|
| MK01/XK01 crear vendor | BP (transaccion unica) | Obligatorio |
| LFA1 (datos generales) | BUT000 + BUT020 | Tabla cambia |
| LFB1 (datos sociedad) | BUT0BK + roles BP | Estructura cambia |
| LFM1 (datos compras) | Se mantiene via CVI | Compatibilidad |
| LIFNR = numero vendor | LIFNR = BP number | Sincronizados via CVI |

**Customer Vendor Integration (CVI)**: sincroniza BP <-> Vendor/Customer automaticamente.

### Material Ledger obligatorio
| ECC | S/4HANA |
|-----|---------|
| ML opcional | ML **obligatorio** |
| Valoracion solo plan cuentas | Valoracion multi-moneda |
| MBEW (precio) | ACDOCA (actual costing) |

### Tablas simplificadas/eliminadas
| Tabla ECC | S/4HANA | Nota |
|-----------|---------|------|
| MKPF + MSEG | MATDOC | Tabla unica doc. material |
| EKBE | EKBE (se mantiene) + MATDOC | Dual |
| BSEG | ACDOCA | Universal Journal |
| MCHB (lotes) | MCHB se mantiene | Con extensiones |
| MBEW | MBEW se mantiene | + ACDOCA para actuals |

### Transacciones obsoletas
| ECC | S/4HANA equivalente | Nota |
|-----|---------------------|------|
| MB01 (GR clasico) | MIGO | MB01 desactivada |
| MB11 (mov. clasico) | MIGO | Redirigida |
| MB1A/MB1B/MB1C | MIGO | Consolidadas |
| MK01/MK02/MK03 | BP | Vendor via BP |
| XK01/XK02/XK03 | BP | Vendor+Customer via BP |
| F-43 (factura FI) | — | Se usa MIRO para logistica |

### Funcionalidades nuevas S/4HANA
| Feature | Descripcion | Relevancia |
|---------|-------------|-----------|
| Fiori Apps MM | Apps nativas para PO, PR, GR, Stock | UX moderna |
| Central Purchasing | Compras centralizadas cross-system | Multi-backend |
| Predictive MRP | MRP con machine learning | Planificacion inteligente |
| Purchase Contract Management | Gestion avanzada contratos | Legal compliance |
| Supplier Evaluation | Evaluacion proveedores integrada | Quality management |

### Fiori Apps principales MM
| App ID | Nombre | Equivalente clasico |
|--------|--------|-------------------|
| F0842A | Manage Purchase Orders | ME21N/ME22N/ME23N |
| F0843 | Manage Purchase Requisitions | ME51N/ME52N/ME53N |
| F1234 | Post Goods Receipt | MIGO (101) |
| F0859 | Create Supplier Invoice | MIRO |
| F0861 | Monitor Purchase Order Items | ME2M/ME2L |
| F2685 | Manage Stock | MB52/MMBE |
| F1804 | Manage Business Partner | BP |
| F2735 | Display Purchasing Document | ME23N |

### APIs OData S/4HANA
| API | Uso |
|-----|-----|
| API_PURCHASEORDER_PROCESS_SRV | CRUD pedidos compra |
| API_PURCHASEREQ_PROCESS_SRV | CRUD solicitudes pedido |
| API_MATERIAL_DOCUMENT_SRV | Documentos material |
| API_SUPPLIERINVOICE_PROCESS_SRV | Facturas proveedor |
| API_PRODUCT_SRV | Materiales |
| API_BUSINESS_PARTNER | Business Partner |
| API_MATERIAL_STOCK_SRV | Stock material |

## Checklist migracion MM ECC -> S/4

1. [ ] CVI (Customer Vendor Integration) configurada y sincronizada
2. [ ] Material Ledger activado en todos los centros
3. [ ] Transacciones clasicas redirigidas (MB01->MIGO, MK01->BP)
4. [ ] Custom code adaptado (user exits -> BAdIs, tablas legacy -> nuevas)
5. [ ] Fiori apps desplegadas y roles asignados
6. [ ] Reports Z adaptados a nuevas tablas (MATDOC, ACDOCA)
7. [ ] Interfaces ajustadas (IDocs, APIs nuevas OData)
8. [ ] Campos Z migrados a extensiones (append structures -> CDS extend)
9. [ ] Pruebas de regresion proceso P2P completo
