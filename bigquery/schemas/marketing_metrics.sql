-- ============================================================
-- BigQuery schema: marketing_metrics
-- Main normalized metrics table
-- Matches NormalizedRow from SKILL-growth-marketing.md
-- Partitioned by metric_date, clustered by channel + tenant
-- ============================================================

CREATE TABLE IF NOT EXISTS `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics` (
  -- Identity
  tenant_id STRING NOT NULL,
  channel STRING NOT NULL,              -- google_ads | meta_ads | ga4 | email | linkedin_ads | linkedin_organic
  source_campaign_id STRING NOT NULL,   -- Original platform campaign ID
  campaign_name STRING,
  metric_date DATE NOT NULL,

  -- Funnel metrics (raw)
  impressions INT64 NOT NULL DEFAULT 0,
  clicks INT64 NOT NULL DEFAULT 0,
  spend FLOAT64 NOT NULL DEFAULT 0.0,           -- Always USD, 2 decimals. 0 for organic.
  conversions FLOAT64 NOT NULL DEFAULT 0.0,
  conversion_value FLOAT64 NOT NULL DEFAULT 0.0, -- Revenue attributed. 0 if unavailable.

  -- Channel-specific metrics (flexible)
  extra_metrics JSON,                   -- email_opens, email_sends, reach, etc.

  -- Metadata
  inserted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY metric_date
CLUSTER BY channel, tenant_id
OPTIONS (
  require_partition_filter = TRUE,
  description = 'MIH normalized marketing metrics. Dedup key: channel__source_campaign_id__metric_date'
);
