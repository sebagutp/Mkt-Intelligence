-- ============================================================
-- anomaly_detection.sql
-- Detect anomalies by comparing latest day vs 7-day avg
-- Parameters: @tenant_id STRING, @date_from DATE, @date_to DATE
-- Thresholds: warning > 20%, critical > 40%
-- Uses SAFE_DIVIDE for all calculations
-- ============================================================

WITH daily_by_channel AS (
  SELECT
    channel,
    metric_date,
    SUM(spend) AS spend,
    SUM(conversions) AS conversions,
    SUM(conversion_value) AS conversion_value,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SAFE_DIVIDE(SUM(clicks), SUM(impressions)) * 100 AS ctr,
    SAFE_DIVIDE(SUM(spend), SUM(conversions)) AS cpa,
    SAFE_DIVIDE(SUM(conversion_value), SUM(spend)) AS roas
  FROM `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics`
  WHERE tenant_id = @tenant_id
    AND metric_date BETWEEN DATE_SUB(@date_to, INTERVAL 8 DAY) AND @date_to
  GROUP BY channel, metric_date
),

latest_day AS (
  SELECT * FROM daily_by_channel
  WHERE metric_date = @date_to
),

avg_7d AS (
  SELECT
    channel,
    AVG(spend) AS avg_spend,
    AVG(conversions) AS avg_conversions,
    AVG(ctr) AS avg_ctr,
    AVG(cpa) AS avg_cpa,
    AVG(roas) AS avg_roas
  FROM daily_by_channel
  WHERE metric_date BETWEEN DATE_SUB(@date_to, INTERVAL 7 DAY) AND DATE_SUB(@date_to, INTERVAL 1 DAY)
  GROUP BY channel
)

SELECT
  l.channel,
  l.metric_date,

  -- CPA anomaly
  l.cpa AS current_cpa,
  a.avg_cpa,
  SAFE_DIVIDE(ABS(l.cpa - a.avg_cpa), a.avg_cpa) * 100 AS cpa_change_pct,
  CASE
    WHEN SAFE_DIVIDE(ABS(l.cpa - a.avg_cpa), a.avg_cpa) * 100 > 40 THEN 'critical'
    WHEN SAFE_DIVIDE(ABS(l.cpa - a.avg_cpa), a.avg_cpa) * 100 > 20 THEN 'warning'
    ELSE 'normal'
  END AS cpa_severity,

  -- CTR anomaly
  l.ctr AS current_ctr,
  a.avg_ctr,
  SAFE_DIVIDE(ABS(l.ctr - a.avg_ctr), a.avg_ctr) * 100 AS ctr_change_pct,
  CASE
    WHEN SAFE_DIVIDE(ABS(l.ctr - a.avg_ctr), a.avg_ctr) * 100 > 40 THEN 'critical'
    WHEN SAFE_DIVIDE(ABS(l.ctr - a.avg_ctr), a.avg_ctr) * 100 > 20 THEN 'warning'
    ELSE 'normal'
  END AS ctr_severity,

  -- ROAS anomaly
  l.roas AS current_roas,
  a.avg_roas,
  SAFE_DIVIDE(ABS(l.roas - a.avg_roas), a.avg_roas) * 100 AS roas_change_pct,
  CASE
    WHEN SAFE_DIVIDE(ABS(l.roas - a.avg_roas), a.avg_roas) * 100 > 40 THEN 'critical'
    WHEN SAFE_DIVIDE(ABS(l.roas - a.avg_roas), a.avg_roas) * 100 > 20 THEN 'warning'
    ELSE 'normal'
  END AS roas_severity,

  -- Spend anomaly
  l.spend AS current_spend,
  a.avg_spend,
  SAFE_DIVIDE(ABS(l.spend - a.avg_spend), a.avg_spend) * 100 AS spend_change_pct,

  -- Zero conversions flag
  CASE
    WHEN l.spend > 50 AND l.conversions = 0 THEN TRUE
    ELSE FALSE
  END AS zero_conversions_alert

FROM latest_day l
JOIN avg_7d a ON l.channel = a.channel
WHERE
  -- Only return rows with at least one anomaly
  SAFE_DIVIDE(ABS(l.cpa - a.avg_cpa), a.avg_cpa) * 100 > 20
  OR SAFE_DIVIDE(ABS(l.ctr - a.avg_ctr), a.avg_ctr) * 100 > 20
  OR SAFE_DIVIDE(ABS(l.roas - a.avg_roas), a.avg_roas) * 100 > 20
  OR (l.spend > 50 AND l.conversions = 0)
ORDER BY
  GREATEST(
    COALESCE(SAFE_DIVIDE(ABS(l.cpa - a.avg_cpa), a.avg_cpa) * 100, 0),
    COALESCE(SAFE_DIVIDE(ABS(l.ctr - a.avg_ctr), a.avg_ctr) * 100, 0),
    COALESCE(SAFE_DIVIDE(ABS(l.roas - a.avg_roas), a.avg_roas) * 100, 0)
  ) DESC;
