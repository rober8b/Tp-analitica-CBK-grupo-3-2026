# Tp analitica CBK grupo 3 2026

**Materia**: Analítica Digital — UCEMA 2026  
**Grupo 3**: Ivan Charczuk, Robertino Barbuto, Sofia Martinez Luque  
**Tema**: Riesgo Operacional (CBK) e Impacto en Margen

## Descripción

Análisis completo del riesgo operacional por Chargebacks (CBK) en la plataforma Olist, aplicando Python, SQL y Tableau para identificar patrones, cuantificar el impacto financiero y proponer estrategias de mitigación.

## Preguntas Clave

1. ¿Cuál es el costo financiero real del CBK? ¿Cuánto perdemos por mes?
2. ¿Qué factores predicen un CBK? (categoría, cuotas, precio, región, seller)
3. ¿Hay sellers o regiones con tasa de disputa anormalmente alta?
4. ¿Si reducimos CBK en 50%, cuánto mejora el profit total?

## Estructura del Repo

```
/
├── modulo1_eda_cbk.ipynb       # Python: exploración y visualizaciones
├── modulo2_queries_cbk.sql     # SQL: queries estratégicas (BigQuery)
├── exports_tableau/            # CSVs exportados de SQL para Tableau
│   ├── export_cbk_mensual.csv
│   ├── export_cbk_categoria.csv
│   ├── export_cbk_cuotas.csv
│   ├── export_cbk_region.csv
│   └── export_sellers_riesgo.csv
├── img/                        # Gráficos generados en Python
└── Data_Dictionary_ESTUDIANTES.md
```

## Dashboards Interactivos

- **Dashboard 1 — Mapa de Riesgo CBK**: https://raw.githubusercontent.com/rober8b/Tp-analitica-CBK-grupo-3-2026/main/dashboard1_riesgo_cbk.html
  - Análisis de CBK por categoría de producto
  - Distribución de pérdidas por categoría
  - Visualización interactiva de riesgo operacional

- **Dashboard 2 — Predictores y Evolución**: https://raw.githubusercontent.com/rober8b/Tp-analitica-CBK-grupo-3-2026/main/dashboard2_predictores_evolucion.html
  - Evolución temporal de CBK (2016-2018)
  - CBK rate por número de cuotas de pago
  - Top 10 sellers con mayor riesgo de chargeback
  - Escenario de impacto: reducción del 50% en CBK

## Datos

Los datasets (`olist_order_items_enriched.csv` y relacionados) no están en el repo por su tamaño. Disponibles en la carpeta compartida del aula.
