-- ============================================================
-- Migration 003: RPC functions
-- ============================================================

-- ============================================================
-- get_my_tenant(): Returns the tenant config for the current user
-- Used by TenantProvider on app load
-- ============================================================
CREATE OR REPLACE FUNCTION get_my_tenant()
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  plan plan_tier,
  bq_project_id TEXT,
  bq_dataset TEXT,
  monthly_budget NUMERIC,
  timezone TEXT,
  brand_primary TEXT,
  brand_accent TEXT,
  logo_url TEXT,
  company_name TEXT,
  channels JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.name,
    t.slug,
    t.plan,
    t.bq_project_id,
    t.bq_dataset,
    t.monthly_budget,
    t.timezone,
    COALESCE(dc.brand_primary, '#2563eb'),
    COALESCE(dc.brand_accent, '#f59e0b'),
    dc.logo_url,
    dc.company_name,
    COALESCE(
      (
        SELECT jsonb_agg(jsonb_build_object(
          'channel', tc.channel,
          'is_enabled', tc.is_enabled,
          'config', tc.config
        ))
        FROM tenant_channels tc
        WHERE tc.tenant_id = t.id
      ),
      '[]'::JSONB
    )
  FROM tenants t
  LEFT JOIN dashboard_configs dc ON dc.tenant_id = t.id
  WHERE t.id IN (SELECT auth.user_tenant_ids())
    AND t.is_active = TRUE
  LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ============================================================
-- log_sync(): Insert a sync log entry (called by Edge Functions)
-- Uses service_role, not subject to RLS
-- ============================================================
CREATE OR REPLACE FUNCTION log_sync(
  p_tenant_id UUID,
  p_channel channel_type,
  p_status sync_status,
  p_rows_synced INT DEFAULT 0,
  p_date_from DATE DEFAULT NULL,
  p_date_to DATE DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO sync_logs (
    tenant_id,
    channel,
    status,
    rows_synced,
    date_from,
    date_to,
    error_message,
    metadata,
    started_at,
    finished_at
  ) VALUES (
    p_tenant_id,
    p_channel,
    p_status,
    p_rows_synced,
    p_date_from,
    p_date_to,
    p_error_message,
    p_metadata,
    now(),
    CASE WHEN p_status IN ('success', 'partial', 'error') THEN now() ELSE NULL END
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- get_last_sync_date(): Returns the last successful sync date
-- for a tenant + channel. Used by connectors to know where to
-- resume (incremental sync).
-- ============================================================
CREATE OR REPLACE FUNCTION get_last_sync_date(
  p_tenant_id UUID,
  p_channel channel_type
)
RETURNS DATE AS $$
DECLARE
  v_last_date DATE;
BEGIN
  SELECT date_to INTO v_last_date
  FROM sync_logs
  WHERE tenant_id = p_tenant_id
    AND channel = p_channel
    AND status IN ('success', 'partial')
  ORDER BY started_at DESC
  LIMIT 1;

  -- Default: 30 days back if no prior sync
  RETURN COALESCE(v_last_date, CURRENT_DATE - INTERVAL '30 days');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;
