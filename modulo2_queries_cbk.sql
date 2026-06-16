-- ============================================================
-- Módulo 2: Análisis SQL — Riesgo Operacional (CBK)
-- Grupo 3 | Analítica Digital UCEMA 2026
-- Ivan Charczuk, Robertino Barbuto, Sofia Martinez Luque
-- Plataforma: BigQuery (SQL standard)
-- ============================================================


-- ============================================================
-- QUERY 1: Costo total y mensual del CBK
-- Exportar como: exports_tableau/export_cbk_mensual.csv
-- ============================================================
WITH cbk_mensual AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp)) AS mes,
    COUNT(*)                                                AS total_cbk,
    ROUND(SUM(-(i.overhead_cost + i.freight_value)), 2)    AS perdida_total_usd,
    ROUND(AVG(-(i.overhead_cost + i.freight_value)), 2)    AS perdida_promedio_usd
  FROM `proyecto.dataset.olist_order_items_enriched` i
  JOIN `proyecto.dataset.olist_orders_dataset`       o USING (order_id)
  WHERE i.cbk = 1
  GROUP BY 1
)
SELECT
  mes,
  total_cbk,
  perdida_total_usd,
  perdida_promedio_usd,
  SUM(perdida_total_usd) OVER (ORDER BY mes) AS perdida_acumulada_usd
FROM cbk_mensual
ORDER BY mes;


-- ============================================================
-- QUERY 2: CBK rate y pérdida por categoría de producto
-- Exportar como: exports_tableau/export_cbk_categoria.csv
-- ============================================================
SELECT
  product_category_name,
  COUNT(*)                                                                                 AS total_ordenes,
  SUM(cbk)                                                                                 AS total_cbk,
  ROUND(AVG(cbk) * 100, 2)                                                                 AS cbk_rate_pct,
  ROUND(SUM(CASE WHEN cbk = 1 THEN -(overhead_cost + freight_value) ELSE 0 END), 2)       AS perdida_total_usd,
  ROUND(AVG(CASE WHEN cbk = 1 THEN -(overhead_cost + freight_value) END), 2)              AS perdida_promedio_usd,
  ROUND(AVG(price), 2)                                                                     AS precio_promedio
FROM `proyecto.dataset.olist_order_items_enriched`
GROUP BY 1
HAVING COUNT(*) > 100
ORDER BY cbk_rate_pct DESC;


-- ============================================================
-- QUERY 3: Top 20 sellers con mayor tasa de CBK
-- Usa RANK() como window function
-- Exportar como: exports_tableau/export_sellers_riesgo.csv
-- ============================================================
WITH seller_stats AS (
  SELECT
    i.seller_id,
    s.segment,
    s.industry,
    s.entity_type,
    COUNT(*)                                                                          AS total_ordenes,
    SUM(i.cbk)                                                                        AS total_cbk,
    ROUND(AVG(i.cbk) * 100, 2)                                                        AS cbk_rate_pct,
    ROUND(SUM(CASE WHEN i.cbk=1 THEN -(i.overhead_cost+i.freight_value) ELSE 0 END), 2) AS perdida_total,
    RANK() OVER (ORDER BY AVG(i.cbk) DESC)                                            AS ranking_riesgo
  FROM `proyecto.dataset.olist_order_items_enriched`  i
  LEFT JOIN `proyecto.dataset.olist_sellers_enriched` s USING (seller_id)
  GROUP BY 1, 2, 3, 4
  HAVING COUNT(*) >= 20
)
SELECT *
FROM seller_stats
WHERE ranking_riesgo <= 20
ORDER BY ranking_riesgo;


-- ============================================================
-- QUERY 4: CBK rate por número de cuotas de pago
-- Exportar como: exports_tableau/export_cbk_cuotas.csv
-- ============================================================
SELECT
  payment_installments,
  COUNT(*)                          AS total_ordenes,
  SUM(cbk)                          AS cbk_count,
  ROUND(AVG(cbk) * 100, 2)          AS cbk_rate_pct,
  ROUND(AVG(price), 2)              AS precio_promedio,
  ROUND(AVG(freight_value), 2)      AS freight_promedio
FROM `proyecto.dataset.olist_order_items_enriched`
GROUP BY 1
ORDER BY 1;


-- ============================================================
-- QUERY 5: CBK rate y pérdida por región (estado del cliente)
-- Para usar en el MAPA de Tableau
-- Exportar como: exports_tableau/export_cbk_region.csv
-- ============================================================
SELECT
  c.customer_state,
  COUNT(*)                                                                                    AS total_ordenes,
  SUM(i.cbk)                                                                                  AS total_cbk,
  ROUND(AVG(i.cbk) * 100, 2)                                                                  AS cbk_rate_pct,
  ROUND(SUM(CASE WHEN i.cbk=1 THEN -(i.overhead_cost+i.freight_value) ELSE 0 END), 2)        AS perdida_region_usd,
  ROUND(AVG(i.price), 2)                                                                      AS precio_promedio
FROM `proyecto.dataset.olist_order_items_enriched`  i
JOIN `proyecto.dataset.olist_orders_dataset`        o USING (order_id)
JOIN `proyecto.dataset.olist_customers_dataset`     c ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY cbk_rate_pct DESC;


-- ============================================================
-- QUERY 6: Escenario — impacto si reducimos CBK en 50%
-- Este número va al Executive Summary del deck
-- ============================================================
WITH base AS (
  SELECT
    ROUND(SUM(profit), 2)                                                                   AS profit_actual,
    ROUND(SUM(CASE WHEN cbk=1 THEN -(overhead_cost+freight_value) ELSE 0 END), 2)          AS perdida_cbk_total,
    COUNT(CASE WHEN cbk=1 THEN 1 END)                                                       AS ordenes_cbk,
    COUNT(*)                                                                                AS total_ordenes,
    ROUND(AVG(cbk) * 100, 2)                                                                AS cbk_rate_actual_pct
  FROM `proyecto.dataset.olist_order_items_enriched`
)
SELECT
  profit_actual,
  perdida_cbk_total,
  cbk_rate_actual_pct,
  ordenes_cbk,
  total_ordenes,
  ROUND(perdida_cbk_total * -0.5, 2)                              AS ahorro_reduccion_50pct,
  ROUND(profit_actual + (perdida_cbk_total * -0.5), 2)           AS profit_escenario_50pct,
  ROUND((perdida_cbk_total * -0.5 / profit_actual) * 100, 1)     AS mejora_profit_pct
FROM base;
