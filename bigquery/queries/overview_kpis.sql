-- ============================================================
-- overview_kpis.sql
-- Cross-channel KPIs for the Overview panel
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
-- Uses SAFE_DIVIDE for all derived metrics
-- ============================================================

WITH current_period AS (
  SELECT
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    SUM(conversion_value) AS total_conversion_value,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND metric_date BETWEEN @date_from AND @date_to
),

previous_period AS (
  SELECT
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    SUM(conversion_value) AS total_conversion_value,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND metric_date BETWEEN
      DATE_SUB(@date_from, INTERVAL DATE_DIFF(@date_to, @date_from, DAY) + 1 DAY)
      AND DATE_SUB(@date_from, INTERVAL 1 DAY)
)

SELECT
  -- Current period KPIs
  c.total_spend,
  c.total_conversions,
  c.total_conversion_value,
  c.total_impressions,
  c.total_clicks,

  -- Derived KPIs (SAFE_DIVIDE)
  SAFE_DIVIDE(c.total_spend, c.total_conversions) AS blended_cpa,
  SAFE_DIVIDE(c.total_conversion_value, c.total_spend) AS blended_roas,
  SAFE_DIVIDE(c.total_clicks, c.total_impressions) * 100 AS blended_ctr,
  SAFE_DIVIDE(c.total_spend, c.total_clicks) AS blended_cpc,
  SAFE_DIVIDE(c.total_spend, c.total_impressions) * 1000 AS blended_cpm,

  -- Deltas vs previous period (%)
  SAFE_DIVIDE(c.total_spend - p.total_spend, ABS(p.total_spend)) * 100 AS spend_delta_pct,
  SAFE_DIVIDE(c.total_conversions - p.total_conversions, ABS(p.total_conversions)) * 100 AS conversions_delta_pct,
  SAFE_DIVIDE(c.total_conversion_value - p.total_conversion_value, ABS(p.total_conversion_value)) * 100 AS revenue_delta_pct,
  SAFE_DIVIDE(
    SAFE_DIVIDE(c.total_spend, c.total_conversions) - SAFE_DIVIDE(p.total_spend, p.total_conversions),
    ABS(SAFE_DIVIDE(p.total_spend, p.total_conversions))
  ) * 100 AS cpa_delta_pct,
  SAFE_DIVIDE(
    SAFE_DIVIDE(c.total_conversion_value, c.total_spend) - SAFE_DIVIDE(p.total_conversion_value, p.total_spend),
    ABS(SAFE_DIVIDE(p.total_conversion_value, p.total_spend))
  ) * 100 AS roas_delta_pct

FROM current_period c
CROSS JOIN previous_period p;
