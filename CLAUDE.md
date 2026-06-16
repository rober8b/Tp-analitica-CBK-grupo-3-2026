# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

UCEMA — Analítica Digital (2026). Educational data analysis project using an enriched Olist (Brazilian e-commerce) dataset. The goal is to analyze profitability, costs, and business decisions across ~112,647 order-item records.

## Datasets

All data files are CSVs. Join keys: `order_id`, `seller_id`, `product_id`, `customer_id`.

| File | Role |
|------|------|
| `olist_order_items_enriched.csv` | Primary dataset — P&L per order item (112,647 rows) |
| `olist_sellers_enriched.csv` | Sellers with demographics, industry, and performance segment |
| `olist_customers_enriched.csv` | Customers with demographics and behavior |
| `olist_orders_dataset.csv` | Order-level timestamps and status |
| `olist_products_dataset.csv` | Product catalog |
| `olist_customers_dataset.csv` | Customer geography (original) |
| `olist_sellers_dataset.csv` | Seller geography (original) |

## Business Logic (P&L)

**Revenue:**
```
tpv = tpv_base + financing_revenue + shipping_revenue
```

**Financing revenue** (charged to customer when paying in installments):
```
financing_revenue = payment_value × (financing_cost_rate + 1.2pp)
```
Financing cost rates: 1x=0%, 2x=1.5%, 3x=3.2%, 6x=15%, 12x=45%

**Shipping revenue:**
```
shipping_revenue = freight_value × 2.7%
```

**Profit (no chargeback):**
```
profit = tpv - cogs - overhead_cost - payment_processing_cost - financing_cost - discount - freight_value
```

**Profit (CBK = 1, chargeback):**
```
profit = -(overhead_cost + freight_value)
```
CBK orders always lose money — Olist refunds the customer but already paid freight and overhead.

**Key cost parameters:**
- COGS: ~42% of `price`
- Overhead: ~$1.50/order (fixed)
- Payment processing: 2.5% of `payment_value`
- Discounts by category: electronics ~12%, computing ~10%, fashion ~7%, home/bath ~5%

## Analysis Goals

1. Profit promedio por categoría de producto
2. ¿Las órdenes en cuotas son más rentables?
3. Diferencias en descuentos entre categorías y estrategia óptima
4. Impacto del CBK en rentabilidad
5. Correlación entre precio del producto y profit
6. Profit/pérdida por estado de la orden (`delivered`, `shipped`, `canceled`, etc.)
7. ¿El overhead fijo tiene sentido o debería variar?
