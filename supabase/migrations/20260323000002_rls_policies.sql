-- ============================================================
-- Migration 002: RLS policies — tenant isolation
-- ============================================================

-- ============================================================
-- Helper: returns all tenant IDs the current user belongs to
-- ============================================================
CREATE OR REPLACE FUNCTION auth.user_tenant_ids()
RETURNS SETOF UUID AS $$
  SELECT tenant_id
  FROM public.tenant_users
  WHERE user_id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================
-- Enable RLS on all tables
-- ============================================================
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_rules ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- tenants
-- ============================================================
CREATE POLICY "Users can view their own tenants"
  ON tenants FOR SELECT
  USING (id IN (SELECT auth.user_tenant_ids()));

CREATE POLICY "Owners can update their tenant"
  ON tenants FOR UPDATE
  USING (id IN (
    SELECT tenant_id FROM tenant_users
    WHERE user_id = auth.uid() AND role = 'owner'
  ));

-- ============================================================
-- tenant_users
-- ============================================================
CREATE POLICY "Users can view members of their tenants"
  ON tenant_users FOR SELECT
  USING (tenant_id IN (SELECT auth.user_tenant_ids()));

CREATE POLICY "Owners can manage tenant members"
  ON tenant_users FOR ALL
  USING (tenant_id IN (
    SELECT tenant_id FROM tenant_users
    WHERE user_id = auth.uid() AND role = 'owner'
  ));

-- ============================================================
-- tenant_channels
-- ============================================================
CREATE POLICY "Users can view their tenant channels"
  ON tenant_channels FOR SELECT
  USING (tenant_id IN (SELECT auth.user_tenant_ids()));

CREATE POLICY "Admins can manage tenant channels"
  ON tenant_channels FOR ALL
  USING (tenant_id IN (
    SELECT tenant_id FROM tenant_users
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- ============================================================
-- api_credentials
-- No SELECT for frontend — only service role reads these
-- ============================================================
CREATE POLICY "No direct access to credentials"
  ON api_credentials FOR SELECT
  USING (FALSE);

-- ============================================================
-- sync_logs
-- ============================================================
CREATE POLICY "Users can view their tenant sync logs"
  ON sync_logs FOR SELECT
  USING (tenant_id IN (SELECT auth.user_tenant_ids()));

-- ============================================================
-- dashboard_configs
-- ============================================================
CREATE POLICY "Users can view their tenant dashboard config"
  ON dashboard_configs FOR SELECT
  USING (tenant_id IN (SELECT auth.user_tenant_ids()));

CREATE POLICY "Admins can update dashboard config"
  ON dashboard_configs FOR UPDATE
  USING (tenant_id IN (
    SELECT tenant_id FROM tenant_users
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));

-- ============================================================
-- alert_rules
-- ============================================================
CREATE POLICY "Users can view their tenant alert rules"
  ON alert_rules FOR SELECT
  USING (tenant_id IN (SELECT auth.user_tenant_ids()));

CREATE POLICY "Admins can manage alert rules"
  ON alert_rules FOR ALL
  USING (tenant_id IN (
    SELECT tenant_id FROM tenant_users
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  ));
