# HU-002: Setup BigQuery + Supabase para Datawalt

**Sprint**: 0 — Scaffold + Infra Base (Semana 1)
**Track**: C (Infra/DevOps)
**Dependencias**: Ninguna (puede ejecutarse en paralelo con HU-001)
**Consola sugerida**: Terminal 2 (SQL/Infra)

---

## Descripción

Crear las migrations de Supabase (tablas core, RLS, funciones), los schemas de BigQuery con particionamiento, y las queries pre-armadas para el proxy.

## Criterios de aceptación

- [ ] BigQuery dataset `mih_datawalt` creado con las 3 tablas
- [ ] Supabase migrations ejecutadas (tablas core + RLS + funciones)
- [ ] Service Account de GCP generado y guardado
- [ ] .env de Datawalt llenado

## Prompt para Claude Code

```
Lee CLAUDE.md y los archivos en bigquery/schemas/ y supabase/migrations/.

1. Crea las 3 migrations de Supabase según el plan:
   - 20260323000001_core_tables.sql: tablas tenants, tenant_users, tenant_channels, api_credentials, sync_logs, dashboard_configs, alert_rules con todos los índices
   - 20260323000002_rls_policies.sql: RLS en todas las tablas, función auth.user_tenant_ids(), policies de aislamiento por tenant
   - 20260323000003_functions.sql: get_my_tenant(), log_sync(), get_last_sync_date()

2. Crea los 3 schemas de BigQuery con placeholders {{PROJECT_ID}} y {{DATASET}}:
   - marketing_metrics con PARTITION BY metric_date, CLUSTER BY channel
   - campaign_details con CLUSTER BY channel
   - channel_daily_summary como materialized view

3. Crea bigquery/queries/ con los 6 SQL files de queries pre-armadas: overview_kpis, daily_trend, top_campaigns, channel_detail, anomaly_detection, spend_distribution

Todos los SQL deben usar SAFE_DIVIDE() y require_partition_filter.
```

## Archivos a crear/modificar

- `supabase/migrations/20260323000001_core_tables.sql`
- `supabase/migrations/20260323000002_rls_policies.sql`
- `supabase/migrations/20260323000003_functions.sql`
- `bigquery/schemas/marketing_metrics.sql`
- `bigquery/schemas/campaign_details.sql`
- `bigquery/schemas/channel_daily_summary.sql`
- `bigquery/queries/*.sql` (6 archivos)

## Estimación

~2-3 horas con Claude Code
