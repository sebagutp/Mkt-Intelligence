-- ============================================================
-- Migration 001: Core tables for MIH
-- ============================================================

-- Enum types
CREATE TYPE channel_type AS ENUM (
  'google_ads',
  'meta_ads',
  'ga4',
  'email',
  'linkedin_ads',
  'linkedin_organic'
);

CREATE TYPE sync_status AS ENUM (
  'pending',
  'running',
  'success',
  'partial',
  'error'
);

CREATE TYPE plan_tier AS ENUM (
  'starter',
  'professional',
  'enterprise'
);

CREATE TYPE alert_severity AS ENUM (
  'warning',
  'critical'
);

-- ============================================================
-- tenants: One row per client organization
-- ============================================================
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  plan plan_tier NOT NULL DEFAULT 'starter',
  bq_project_id TEXT NOT NULL,
  bq_dataset TEXT NOT NULL,
  monthly_budget NUMERIC(12,2) DEFAULT 0,
  timezone TEXT NOT NULL DEFAULT 'America/Santiago',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tenants_slug ON tenants (slug);

-- ============================================================
-- tenant_users: Maps auth.users → tenants (M:N)
-- ============================================================
CREATE TABLE tenant_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('owner', 'admin', 'viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, user_id)
);

CREATE INDEX idx_tenant_users_user ON tenant_users (user_id);
CREATE INDEX idx_tenant_users_tenant ON tenant_users (tenant_id);

-- ============================================================
-- tenant_channels: Which channels a tenant has enabled
-- ============================================================
CREATE TABLE tenant_channels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  channel channel_type NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  config JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, channel)
);

CREATE INDEX idx_tenant_channels_tenant ON tenant_channels (tenant_id);

-- ============================================================
-- api_credentials: Encrypted OAuth tokens and API keys
-- ============================================================
CREATE TABLE api_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  channel channel_type NOT NULL,
  credential_type TEXT NOT NULL CHECK (credential_type IN ('oauth2', 'api_key', 'service_account')),
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  extra JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, channel)
);

CREATE INDEX idx_api_credentials_tenant ON api_credentials (tenant_id);
CREATE INDEX idx_api_credentials_expiry ON api_credentials (token_expires_at)
  WHERE token_expires_at IS NOT NULL;

-- ============================================================
-- sync_logs: ETL execution history
-- ============================================================
CREATE TABLE sync_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  channel channel_type NOT NULL,
  status sync_status NOT NULL DEFAULT 'pending',
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  rows_synced INT NOT NULL DEFAULT 0,
  date_from DATE,
  date_to DATE,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_sync_logs_tenant_channel ON sync_logs (tenant_id, channel);
CREATE INDEX idx_sync_logs_started ON sync_logs (started_at DESC);
CREATE INDEX idx_sync_logs_status ON sync_logs (status)
  WHERE status IN ('pending', 'running');

-- ============================================================
-- dashboard_configs: Branding + UI settings per tenant
-- ============================================================
CREATE TABLE dashboard_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE UNIQUE,
  brand_primary TEXT NOT NULL DEFAULT '#2563eb',
  brand_accent TEXT NOT NULL DEFAULT '#f59e0b',
  logo_url TEXT,
  favicon_url TEXT,
  company_name TEXT,
  custom_domain TEXT,
  config JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- alert_rules: Anomaly detection configuration per tenant
-- ============================================================
CREATE TABLE alert_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  channel channel_type,
  metric TEXT NOT NULL,
  threshold_pct NUMERIC(5,2) NOT NULL DEFAULT 20.0,
  severity alert_severity NOT NULL DEFAULT 'warning',
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  notify_slack BOOLEAN NOT NULL DEFAULT FALSE,
  notify_email BOOLEAN NOT NULL DEFAULT TRUE,
  slack_webhook_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_alert_rules_tenant ON alert_rules (tenant_id);

-- ============================================================
-- updated_at trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER set_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON tenant_channels
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON api_credentials
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON dashboard_configs
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

CREATE TRIGGER set_updated_at BEFORE UPDATE ON alert_rules
  FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
