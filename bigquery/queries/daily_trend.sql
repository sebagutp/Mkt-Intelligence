-- ============================================================
-- daily_trend.sql
-- Daily time series for spend, conversions, and derived metrics
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
--             @channel STRING (optional, NULL = all channels)
-- Uses SAFE_DIVIDE for all derived metrics
-- ============================================================

SELECT
  metric_date,
  SUM(spend) AS spend,
  SUM(conversions) AS conversions,
  SUM(conversion_value) AS conversion_value,
  SUM(impressions) AS impressions,
  SUM(clicks) AS clicks,

  -- Derived (SAFE_DIVIDE)
  SAFE_DIVIDE(SUM(spend), SUM(conversions)) AS cpa,
  SAFE_DIVIDE(SUM(conversion_value), SUM(spend)) AS roas,
  SAFE_DIVIDE(SUM(clicks), SUM(impressions)) * 100 AS ctr,
  SAFE_DIVIDE(SUM(spend), SUM(clicks)) AS cpc

FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
WHERE tenant_id = @tenant_id
  AND metric_date BETWEEN @date_from AND @date_to
  AND (@channel IS NULL OR channel = @channel)
GROUP BY metric_date
ORDER BY metric_date ASC;
