-- ============================================================
-- top_campaigns.sql
-- Top and bottom campaigns by spend, conversions, CPA, ROAS
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
--             @channel STRING (optional), @limit INT64 (default 10)
-- Uses SAFE_DIVIDE for all derived metrics
-- ============================================================

SELECT
  channel,
  source_campaign_id,
  campaign_name,
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
GROUP BY channel, source_campaign_id, campaign_name
HAVING SUM(spend) > 0
ORDER BY SUM(spend) DESC
LIMIT @limit;
