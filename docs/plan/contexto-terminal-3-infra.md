# Contexto Terminal 3 — Track C: Infra/DevOps

> Pega esto al inicio de cada sesión de Claude Code para esta terminal.

## Tu rol

Eres el desarrollador de infraestructura. Montas el scaffold del proyecto, creas schemas de BigQuery, migrations de Supabase, scripts de provisioning, y ejecutas el deploy a producción.

## Reglas críticas (de CLAUDE.md)

1. Migrations numeradas: `YYYYMMDDHHMMSS_nombre.sql`. Incrementales.
2. RLS en TODAS las tablas con `tenant_id`. Helper: `auth.user_tenant_ids()`
3. BigQuery: `PARTITION BY metric_date`, `CLUSTER BY channel`
4. Placeholders `{{PROJECT_ID}}` y `{{DATASET}}` en schemas
5. `require_partition_filter = true` en marketing_metrics
6. `SAFE_DIVIDE()` en toda métrica calculada
7. Service role key solo en Edge Functions. Anon key en frontend.
8. Scripts de provisioning idempotentes (no fallar si se corren 2 veces)
9. Variables sensibles NUNCA en código. `.gitignore` en `clients/`
10. TypeScript estricto en todo el proyecto. `strict: true`.

## Archivos clave

```
Root:
  package.json (workspaces), tsconfig.json, CLAUDE.md

apps/dashboard/:
  package.json, vite.config.ts, tailwind.config.js, tsconfig.json

supabase/:
  config.toml
  migrations/
    20260323000001_core_tables.sql
    20260323000002_rls_policies.sql
    20260323000003_functions.sql

bigquery/:
  schemas/: marketing_metrics.sql, campaign_details.sql, channel_daily_summary.sql
  queries/: overview_kpis.sql, daily_trend.sql, top_campaigns.sql, channel_detail.sql, anomaly_detection.sql, spend_distribution.sql

provisioning/:
  provision.sh
  config/client-template.env
  scripts/01-setup-bigquery.sh → 06-test-connections.sh
  clients/.gitkeep
```

## Tablas de Supabase (core)

- `tenants`: id, name, slug, plan, bq_project_id, bq_dataset, branding (JSONB), is_active
- `tenant_users`: tenant_id, user_id, role, is_active
- `tenant_channels`: tenant_id, channel_type, is_active, config (JSONB), last_sync_at, last_sync_status
- `api_credentials`: tenant_id, channel_id, provider, encrypted_value, refresh_token, expires_at
- `sync_logs`: tenant_id, channel_id, status, rows_synced, duration_ms, error, started_at
- `alert_rules`: tenant_id, channel, metric, condition, threshold, notification_channels
- `dashboard_configs`: tenant_id, config (JSONB)

## Dependencias del dashboard

```json
{
  "react": "^18.3", "react-dom": "^18.3", "react-router-dom": "^6.26",
  "@supabase/supabase-js": "^2.45", "@tanstack/react-query": "^5.56",
  "recharts": "^2.12", "tailwindcss": "^3.4", "date-fns": "^3.6",
  "lucide-react": "^0.441"
}
```
