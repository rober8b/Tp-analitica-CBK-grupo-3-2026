# Data Dictionary — Dataset Olist Enriquecido

**Materia**: Analítica Digital
**Período**: 2026
**Audiencia**: Estudiantes

---

## Introducción

Este documento describe las columnas del dataset enriquecido que usarán durante la cursada. El dataset contiene órdenes de e-commerce con información de productos, pagos, envíos y una estructura completa de P&L (Profit & Loss).

**Nota**: El dataset fue enriquecido con métricas financieras realistas para que puedan analizar rentabilidad, costos y decisiones de negocio.

---

## Estructura del Dataset

El dataset principal es: `olist_order_items_enriched.csv`

Contiene **112,647 registros** de items de órdenes (**98,665 órdenes únicas**), cada uno con información de:
- Identificadores de la orden y el producto
- Información de envío
- Precios e ingresos
- Costos desglosados
- Cálculo de profit

---

## Columnas

### A. Identificadores

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `order_id` | string | Identificador único de la orden. Múltiples items pueden pertenecer a la misma orden. |
| `order_item_id` | int | Número secuencial del item dentro de una orden (1, 2, 3, etc.). |
| `product_id` | string | Identificador único del producto. |
| `seller_id` | string | Identificador único del vendedor que provee el producto. |

---

### B. Información de la Orden

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `order_status` | string | Estado actual de la orden. Valores posibles: `delivered`, `shipped`, `processing`, `canceled`, `unavailable`. |
| `shipping_limit_date` | datetime | Fecha límite en que el vendedor debe enviar el producto. |
| `payment_installments` | int | Número de cuotas en que pagó el cliente (1, 2, 3, 6, 12). |

---

### C. Ingresos (TPV y componentes)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `price` | float | Precio base del producto (en USD o local). Es lo que cobra Olist por el producto. |
| `payment_value` | float | Monto total que pagó el cliente en la orden. Es la suma de todos los items y formas de pago. |
| `tpv_base` | float | TPV base = ingreso de producto (con descuento) + envío. Mismo valor en `order_payments.tpv`. |
| `financing_revenue` | float | Ingreso adicional que cobra Olist por permitir pago en cuotas. Ver sección "Lógica de Financing" abajo. |
| `shipping_revenue` | float | Ingreso adicional que cobra Olist por el servicio de envío. Ver sección "Lógica de Envío" abajo. |
| `tpv` | float | TPV Total = `tpv_base` + `financing_revenue` + `shipping_revenue`. Ingreso bruto de Olist por esta orden. |

---

### D. Costos (desglose)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `cogs` | float | Cost of Goods Sold. Costo de compra/adquisición del producto. ~42% del precio. |
| `overhead_cost` | float | Costos no transaccionales: hosting, customer service, infraestructura, etc. ~$1.50 por orden. |
| `payment_processing_cost` | float | Comisión de procesamiento de pagos. 2.5% del `payment_value`. |
| `financing_cost` | float | Costo financiero de permitir cuotas. Depende del número de cuotas (ver tabla abajo). |
| `discount` | float | Descuento aplicado al cliente en esta orden. Varía por categoría de producto (~5-12%). |
| `freight_value` | float | Costo de envío. Lo que Olist paga al transportista. Incluido en `tpv` si hay envío. |
| `has_shipping` | int | Bandera: 1 = hay envío, 0 = no hay envío (ej. productos descargables, servicios). |

---

### E. Análisis de Riesgo (CBK)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `cbk` | int | Chargeback flag: 1 = hay CBK, 0 = no hay CBK. Ver sección "Lógica de CBK" abajo. |
| `status_cbk` | string | Descripción del CBK: "CBK" si `cbk=1`, null si no hay. |

---

### F. Resultado (Profit)

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `profit` | float | Ganancia neta = `tpv` - todos los costos. Si hay CBK, la fórmula cambia (ver sección "Lógica de CBK"). |

---

### G. Información del Producto

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `product_category_name` | string | Categoría del producto (ej. "eletronicos", "cama_mesa_banho", "bebes"). |
| `product_weight_g` | float | Peso del producto en gramos. Relevante para decisiones de envío y logística. |

---

## Lógicas de Negocio

### Financing Revenue (Ingresos por Financiamiento)

Cuando un cliente paga en cuotas, Olist cobra un costo financiero adicional.

**Costo de financing por cuotas:**
| Cuotas | Financing Cost |
|--------|------------------|
| 1x | 0% |
| 2x | 1.5% |
| 3x | 3.2% |
| 6x | 15% |
| 12x | 45% |

**Ingreso de financing:**
Olist no absorbe todo el costo. Cobra un surcharge al cliente que cubre el costo + un margen.

```
financing_revenue = payment_value × (financing_cost% + 1.2pp)
```

Ejemplo: Pago de $100 en 3 cuotas
- Financing cost: $100 × 3.2% = $3.20
- Financing revenue: $100 × 4.4% = $4.40
- El cliente paga $104.40 en lugar de $100
- Olist: recibe $4.40 de revenue, paga $3.20 de costo, ganancia neta = $1.20

---

### Shipping Revenue (Ingresos por Envío)

Olist cobra al cliente por el envío, pero también incurre en costo.

**Cálculo:**
```
shipping_revenue = freight_value × 2.7%
```

El 2.7% es:
- 2.5% para cubrir el costo operativo
- +0.2% de margen para Olist

Ejemplo: Envío que cuesta $10
- Shipping revenue: $10 × 2.7% = $0.27
- Olist gana $0.27 por ese envío

---

### Descuentos

Olist ofrece descuentos a clientes para incentivar compras. Los descuentos varían por categoría de producto.

**Descuentos típicos:**
- Electrónica: ~12%
- Informática: ~10%
- Ropa/moda: ~7%
- Cama/baño: ~5%
- Otros: ~5%

**Nota**: Los descuentos tienen variabilidad. Algunos clientes pagan más, otros menos, dentro de cada categoría.

**Impacto en profit:**
```
profit = tpv - cogs - overhead - payment_processing - financing_cost - descuento - freight
```

Un descuento mayor reduce el profit.

---

### Costo de Envío (Freight)

Olist paga a transportistas por llevar los productos.

**Qué es `freight_value`:**
- Lo que Olist paga al transportista para enviar la orden
- Se resta del profit (es un costo)
- PERO se suma al TPV en forma de `shipping_revenue` (porque se cobra al cliente)

**¿Quién paga el envío?**
- El cliente paga un monto por envío
- Olist paga al transportista `freight_value`
- La diferencia es margen de Olist

---

### CBK (Chargeback)

Un **chargeback** ocurre cuando el cliente disputa el pago con su banco/tarjeta de crédito.

**Consecuencias del CBK:**

Olist debe devolver el dinero al cliente:
- Devuelve: `payment_value` completo
- Devuelve: COGS (costo del producto)
- Devuelve: `payment_processing_cost` (comisión)
- Devuelve: `financing_cost` (si pagó en cuotas)

**Pero Olist mantiene (pierde dinero):**
- `overhead_cost` — ya se gastó en infraestructura
- `freight_value` — ya se pagó al transportista
- `shipping_revenue` se pierde (no se cobra)

**Resultado en CBK:**
```
profit_cbk = -(overhead_cost + freight_value)
```

El profit es **siempre negativo** en un CBK porque se pierden costos sin recuperar ingresos.

---

### Profit (Ganancia)

**Sin CBK:**
```
profit = tpv - cogs - overhead_cost - payment_processing_cost - financing_cost - discount - freight_value
```

**Con CBK:**
```
profit = -(overhead_cost + freight_value)
```

**Interpretación:**
- `profit > 0`: Olist ganó dinero con esta orden
- `profit < 0`: Olist perdió dinero (ej. CBK, descuentos muy altos, costos inesperados)
- `profit ≈ 0`: Orden marginal, sin ganancia significativa

---

## Ejemplos Prácticos

### Ejemplo 1: Orden simple (sin cuotas, con envío)
```
price = $50
payment_installments = 1

INGRESOS:
  tpv_base = $50
  financing_revenue = $0 (1x = sin financing)
  shipping_revenue = $1.35 (freight_value=$50 × 2.7%)
  tpv = $51.35

COSTOS:
  cogs = $21 (42% de $50)
  overhead_cost = $1.50
  payment_processing_cost = $1.25 (2.5% de $50)
  financing_cost = $0
  discount = $3 (6% típico)
  freight_value = $50

PROFIT = $51.35 - $21 - $1.50 - $1.25 - $0 - $3 - $50 = -$25.40
```
*Interpretación: Esta orden pierde dinero. El freight es muy alto relativo al precio.*

### Ejemplo 2: Orden en cuotas (6x)
```
price = $200
payment_installments = 6

INGRESOS:
  tpv_base = $200
  financing_cost = 15% → financing_revenue = $200 × (15% + 1.2%) = $32.4
  shipping_revenue = $1.35 (asumiendo freight=$50)
  tpv = $233.75

COSTOS:
  cogs = $84
  overhead_cost = $1.50
  payment_processing_cost = $5 (2.5%)
  financing_cost = $30 (15% de $200)
  discount = $15 (7.5% típico)
  freight_value = $50

PROFIT = $233.75 - $84 - $1.50 - $5 - $30 - $15 - $50 = $48.25
```
*Interpretación: El financing (cuotas) agregó ingresos que hacen la orden rentable.*

### Ejemplo 3: CBK (Chargeback)
```
Cualquier orden con cbk = 1:

PROFIT = -(overhead_cost + freight_value)
PROFIT = -($1.50 + $50) = -$51.50
```
*Interpretación: Olist perdió $51.50 (overhead + costo de envío) porque no pudo recuperar nada del cliente.*

---

## Preguntas para Explorar

1. ¿Cuál es el profit promedio por categoría de producto?
2. ¿Las órdenes con múltiples cuotas son más rentables?
3. ¿Hay diferencias en descuentos entre categorías? ¿Cuál es la estrategia óptima?
4. ¿Cuál es el impacto del CBK en rentabilidad?
5. ¿Hay correlación entre precio del producto y profit?
6. ¿Qué estados de orden (`delivered`, `shipped`, etc.) tienen mejor/peor profit?
7. ¿El overhead_cost fijo tiene sentido? ¿Debería variar?

---

---

## Dataset: Sellers Enriquecido

### Archivo: `olist_sellers_enriched.csv`

Este dataset contiene **3,095 vendedores** con información demográfica, industria y antigüedad.

### Columnas

#### A. Identificadores

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `seller_id` | string | Identificador único del vendedor (clave para JOIN con order_items). |
| `seller_zip_code_prefix` | int | Código postal del vendedor (ubicación). |
| `seller_city` | string | Ciudad donde opera el vendedor. |
| `seller_state` | string | Estado/provincia del vendedor. |

#### B. Información de Entidad

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `entity_type` | string | Tipo de entidad: `PF` (Persona Física) o `PJ` (Persona Jurídica). |
| `name` | string | Nombre del vendedor (nombre completo si PF, nombre de empresa si PJ). |
| `name_pf` | string | Nombre si es Persona Física (ej. "Juan García López"), NULL si es PJ. |
| `name_pj` | string | Nombre si es Persona Jurídica (ej. "TecnoMart"), NULL si es PF. |

#### C. Datos Demográficos

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `gender` | string | Género del vendedor: `M` (Masculino) o `F` (Femenino). Solo para Persona Física. NULL para PJ. |
| `age` | float | Edad del vendedor (años). Rango: 22-65. Solo para Persona Física. NULL para PJ. |

#### D. Clasificación

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `industry` | string | Industria/sector del vendedor basado en lo que vende (ej. "Electrónica y Tecnología", "Moda y Vestuario"). |
| `segment` | string | Segmentación de rendimiento: `Platinum` (top 25%), `Gold` (25-50%), `Silver` (50-75%), `Bronze` (bottom 25%). |

#### E. Temporalidad

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `account_age_days` | int | Antigüedad en la plataforma (días desde la primera orden). |
| `first_order_date` | datetime | Fecha de la primera orden del vendedor. |
| `last_order_date` | datetime | Fecha de la última orden del vendedor. |

---

### Nota sobre Sellers

Los vendedores pueden ser:
- **Personas Físicas (PF)**: Emprendedores individuales (66% del dataset)
- **Personas Jurídicas (PJ)**: Empresas registradas (34% del dataset)

Los nombres de empresas (PJ) fueron asignados coherentemente según su industria. Por ejemplo:
- Vendedores de electrónica: "TecnoMart", "ElectroLatino"
- Vendedores de muebles: "MueblesLatino", "DecorMax"
- Vendedores de deportes: "DeportMax", "FitnessBrasil"

---

## Archivos Relacionados

- `olist_order_items_enriched.csv` — Dataset principal enriquecido (órdenes con P&L)
- `olist_sellers_enriched.csv` — Información de vendedores (demográfica e industria)
- `olist_customers_enriched.csv` — Información de clientes (demográfica y comportamiento)
- `olist_orders_dataset.csv` — Info de órdenes (timestamps, status)
- `olist_products_dataset.csv` — Catálogo de productos
- `olist_customers_dataset.csv` — Geografía de clientes
- `olist_sellers_dataset.csv` — Geografía de vendedores (original)
