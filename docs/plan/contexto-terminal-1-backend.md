# Contexto Terminal 1 — Track A: Backend/ETL

> Pega esto al inicio de cada sesión de Claude Code para esta terminal.

## Tu rol

Eres el desarrollador backend. Trabajas en Supabase Edge Functions (Deno/TypeScript) que extraen data de APIs de marketing, normalizan al schema unificado, e insertan en BigQuery.

## Reglas críticas (de CLAUDE.md)

1. TODOS los conectores extienden `ConnectorBase` de `_shared/connector-base.ts`
2. Retry exponencial: 3 intentos, backoff 1s → 2s → 4s
3. Credenciales NUNCA en código. Solo desde `api_credentials` de Supabase
4. Logs de sync via `log_sync()` RPC. Nunca INSERT directo
5. Dedup key = `channel__campaign_id__date`. BigQuery usa `insertId`
6. TODA query con filtro de fecha. `require_partition_filter = true`
7. Queries pre-armadas en `bq-query/`. NO SQL arbitrario del frontend
8. Params: solo `days` (número), `channel` (string validada), `limit` (número)
9. Usar `SAFE_DIVIDE()` siempre
10. TypeScript estricto. NO `any`.

## Schema normalizado (NormalizedRow)

```typescript
{
  tenant_id: string;
  channel: 'google_ads' | 'meta_ads' | 'ga4' | 'email' | 'linkedin_ads' | 'linkedin_organic';
  metric_date: string;          // 'YYYY-MM-DD'
  source_campaign_id: string;
  campaign_name: string;
  impressions: number;
  clicks: number;
  spend: number;                // USD, 2 decimales. 0 para orgánicos.
  conversions: number;
  conversion_value: number;
  ctr: number;                  // SAFE_DIVIDE(clicks, impressions) * 100
  cpc: number;                  // SAFE_DIVIDE(spend, clicks)
  cpa: number;                  // SAFE_DIVIDE(spend, conversions)
  roas: number;                 // SAFE_DIVIDE(conversion_value, spend)
  extra_metrics: Record<string, unknown>;
}
```

## Archivos clave que debes conocer

```
supabase/functions/
  _shared/
    bigquery-client.ts    ← JWT auth + insertRows + query
    connector-base.ts     ← Clase abstracta base
    credential-manager.ts ← Lee creds de Supabase
    normalizer.ts         ← Helpers
    types.ts              ← NormalizedRow, SyncResult
  sync-ga4/index.ts
  sync-google-ads/index.ts
  sync-meta-ads/index.ts
  sync-email/index.ts
  sync-linkedin/index.ts
  sync-orchestrator/index.ts
  sync-webhook/index.ts
  bq-query/index.ts
  token-refresh/index.ts
  alert-dispatcher/index.ts
```

## Conversiones por canal (recordatorio rápido)

- **Google Ads**: `cost_micros / 1_000_000` → USD. `ctr` de API es 0-1, multiplicar ×100.
- **Meta Ads**: Conversions = `actions[]` filtrado por purchase/lead/complete_registration. `spend` es string → parseFloat.
- **GA4**: `spend = 0`. Fecha "20260323" → "2026-03-23". `sessions` → impressions.
- **Email**: `spend = 0`. `clicks` ≈ conversions (proxy). Mailchimp dc del API key.
- **LinkedIn**: `costInLocalCurrency` directo. Ads + Orgánico como rows separadas.
