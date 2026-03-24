-- ============================================================
-- BigQuery schema: channel_daily_summary
-- Pre-aggregated daily summary per channel
-- Materialized by ETL or scheduled query
-- Uses SAFE_DIVIDE for all derived metrics
-- ============================================================

CREATE TABLE IF NOT EXISTS `{{PROJECT_ID}}.{{DATASET}}.channel_daily_summary` (
  tenant_id STRING NOT NULL,
  channel STRING NOT NULL,
  metric_date DATE NOT NULL,

  -- Aggregated raw metrics
  total_impressions INT64 NOT NULL DEFAULT 0,
  total_clicks INT64 NOT NULL DEFAULT 0,
  total_spend FLOAT64 NOT NULL DEFAULT 0.0,
  total_conversions FLOAT64 NOT NULL DEFAULT 0.0,
  total_conversion_value FLOAT64 NOT NULL DEFAULT 0.0,
  campaign_count INT64 NOT NULL DEFAULT 0,

  -- Derived metrics (computed with SAFE_DIVIDE)
  ctr FLOAT64,     -- SAFE_DIVIDE(total_clicks, total_impressions) * 100
  cpc FLOAT64,     -- SAFE_DIVIDE(total_spend, total_clicks)
  cpa FLOAT64,     -- SAFE_DIVIDE(total_spend, total_conversions)
  roas FLOAT64,    -- SAFE_DIVIDE(total_conversion_value, total_spend)

  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY metric_date
CLUSTER BY channel, tenant_id
OPTIONS (
  require_partition_filter = TRUE,
  description = 'Pre-aggregated daily channel summary with SAFE_DIVIDE derived metrics'
);

-- ============================================================
-- Scheduled query to rebuild channel_daily_summary
-- Run this as a BigQuery scheduled query (daily)
-- ============================================================
-- MERGE `{{PROJECT_ID}}.{{DATASET}}.channel_daily_summary` AS target
-- USING (
--   SELECT
--     tenant_id,
--     channel,
--     metric_date,
--     SUM(impressions) AS total_impressions,
--     SUM(clicks) AS total_clicks,
--     SUM(spend) AS total_spend,
--     SUM(conversions) AS total_conversions,
--     SUM(conversion_value) AS total_conversion_value,
--     COUNT(DISTINCT source_campaign_id) AS campaign_count,
--     SAFE_DIVIDE(SUM(clicks), SUM(impressions)) * 100 AS ctr,
--     SAFE_DIVIDE(SUM(spend), SUM(clicks)) AS cpc,
--     SAFE_DIVIDE(SUM(spend), SUM(conversions)) AS cpa,
--     SAFE_DIVIDE(SUM(conversion_value), SUM(spend)) AS roas,
--     CURRENT_TIMESTAMP() AS updated_at
--   FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
--   WHERE metric_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
--   GROUP BY tenant_id, channel, metric_date
-- ) AS source
-- ON target.tenant_id = source.tenant_id
--    AND target.channel = source.channel
--    AND target.metric_date = source.metric_date
-- WHEN MATCHED THEN UPDATE SET
--   total_impressions = source.total_impressions,
--   total_clicks = source.total_clicks,
--   total_spend = source.total_spend,
--   total_conversions = source.total_conversions,
--   total_conversion_value = source.total_conversion_value,
--   campaign_count = source.campaign_count,
--   ctr = source.ctr,
--   cpc = source.cpc,
--   cpa = source.cpa,
--   roas = source.roas,
--   updated_at = source.updated_at
-- WHEN NOT MATCHED THEN INSERT ROW;
