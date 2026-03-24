-- ============================================================
-- spend_distribution.sql
-- Spend share per channel (for donut chart)
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
-- Uses SAFE_DIVIDE to calculate percentage share
-- ============================================================

WITH channel_spend AS (
  SELECT
    channel,
    SUM(spend) AS channel_spend,
    SUM(conversions) AS channel_conversions,
    SUM(conversion_value) AS channel_conversion_value
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND metric_date BETWEEN @date_from AND @date_to
  GROUP BY channel
),

total AS (
  SELECT SUM(channel_spend) AS total_spend
  FROM channel_spend
)

SELECT
  cs.channel,
  cs.channel_spend AS spend,
  cs.channel_conversions AS conversions,
  cs.channel_conversion_value AS conversion_value,

  -- Share of total spend (SAFE_DIVIDE)
  SAFE_DIVIDE(cs.channel_spend, t.total_spend) * 100 AS spend_share_pct,

  -- Channel-level derived metrics (SAFE_DIVIDE)
  SAFE_DIVIDE(cs.channel_spend, cs.channel_conversions) AS cpa,
  SAFE_DIVIDE(cs.channel_conversion_value, cs.channel_spend) AS roas

FROM channel_spend cs
CROSS JOIN total t
ORDER BY cs.channel_spend DESC;
