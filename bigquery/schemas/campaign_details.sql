-- ============================================================
-- BigQuery schema: campaign_details
-- Campaign metadata synced from each platform
-- Not partitioned (small table), clustered for fast lookups
-- ============================================================

CREATE TABLE IF NOT EXISTS `{{PROJECT_ID}}.{{DATASET}}.campaign_details` (
  tenant_id STRING NOT NULL,
  channel STRING NOT NULL,
  source_campaign_id STRING NOT NULL,
  campaign_name STRING,
  status STRING,                  -- ENABLED, PAUSED, REMOVED, etc.
  budget_amount FLOAT64,          -- Monthly/daily budget in USD
  budget_type STRING,             -- DAILY, LIFETIME, MONTHLY
  start_date DATE,
  end_date DATE,
  targeting_info JSON,            -- Audiences, geo, demographics
  extra JSON,                     -- Platform-specific metadata
  last_synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY channel, tenant_id
OPTIONS (
  description = 'Campaign metadata from each ad platform'
);
