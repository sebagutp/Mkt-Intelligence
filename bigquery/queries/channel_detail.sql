-- ============================================================
-- channel_detail.sql
-- Drill-down metrics for a specific channel
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
--             @channel STRING
-- Uses SAFE_DIVIDE for all derived metrics
-- ============================================================

WITH current_period AS (
  SELECT
    metric_date,
    source_campaign_id,
    campaign_name,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(spend) AS spend,
    SUM(conversions) AS conversions,
    SUM(conversion_value) AS conversion_value
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND channel = @channel
    AND metric_date BETWEEN @date_from AND @date_to
  GROUP BY metric_date, source_campaign_id, campaign_name
),

channel_totals AS (
  SELECT
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    SUM(conversion_value) AS total_conversion_value
  FROM current_period
),

previous_totals AS (
  SELECT
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    SUM(conversion_value) AS total_conversion_value
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND channel = @channel
    AND metric_date BETWEEN
      DATE_SUB(@date_from, INTERVAL DATE_DIFF(@date_to, @date_from, DAY) + 1 DAY)
      AND DATE_SUB(@date_from, INTERVAL 1 DAY)
)

SELECT
  -- Channel totals
  c.total_spend,
  c.total_conversions,
  c.total_conversion_value,
  c.total_impressions,
  c.total_clicks,

  -- Derived (SAFE_DIVIDE)
  SAFE_DIVIDE(c.total_spend, c.total_conversions) AS cpa,
  SAFE_DIVIDE(c.total_conversion_value, c.total_spend) AS roas,
  SAFE_DIVIDE(c.total_clicks, c.total_impressions) * 100 AS ctr,
  SAFE_DIVIDE(c.total_spend, c.total_clicks) AS cpc,
  SAFE_DIVIDE(c.total_spend, c.total_impressions) * 1000 AS cpm,

  -- Deltas vs previous (SAFE_DIVIDE)
  SAFE_DIVIDE(c.total_spend - p.total_spend, ABS(p.total_spend)) * 100 AS spend_delta_pct,
  SAFE_DIVIDE(c.total_conversions - p.total_conversions, ABS(p.total_conversions)) * 100 AS conversions_delta_pct,
  SAFE_DIVIDE(
    SAFE_DIVIDE(c.total_spend, c.total_conversions) - SAFE_DIVIDE(p.total_spend, p.total_conversions),
    ABS(SAFE_DIVIDE(p.total_spend, p.total_conversions))
  ) * 100 AS cpa_delta_pct,
  SAFE_DIVIDE(
    SAFE_DIVIDE(c.total_conversion_value, c.total_spend) - SAFE_DIVIDE(p.total_conversion_value, p.total_spend),
    ABS(SAFE_DIVIDE(p.total_conversion_value, p.total_spend))
  ) * 100 AS roas_delta_pct

FROM channel_totals c
CROSS JOIN previous_totals p;
