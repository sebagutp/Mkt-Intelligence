# HU-005: Conector Google Ads

**Sprint**: 1 — Primer Pipeline E2E (Semana 2)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (ConnectorBase debe existir)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que extrae data de campañas de Google Ads por día usando GAQL via SearchStream, normaliza a NormalizedRow e inserta en BigQuery.

## Criterios de aceptación

- [ ] Edge Function `sync-google-ads` extrae data de campaña por día
- [ ] Usa GAQL via SearchStream
- [ ] Normaliza a NormalizedRow (cost_micros → USD, etc.)
- [ ] Inserta en BigQuery correctamente
- [ ] Log de sync registrado en Supabase

## Prompt para Claude Code

```
Lee CLAUDE.md y _shared/connector-base.ts.

Crea supabase/functions/sync-google-ads/index.ts:

1. Clase GoogleAdsConnector extends ConnectorBase
2. fetchData():
   - Refresh OAuth token via Google OAuth endpoint
   - GAQL query: SELECT campaign.id, campaign.name, campaign.status, segments.date, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value, metrics.ctr, metrics.average_cpc, campaign.advertising_channel_type FROM campaign WHERE segments.date BETWEEN '{startDate}' AND '{endDate}' AND campaign.status != 'REMOVED'
   - POST a https://googleads.googleapis.com/v23/customers/{customerId}/googleAds:searchStream
   - Headers: Authorization Bearer, developer-token, login-customer-id (MCC)
   - Manejo de paginación (SearchStream retorna batches)

3. normalize(): mapea response a NormalizedRow. cost_micros / 1_000_000 → spend. Calcular ctr, cpc, cpa, roas. extra_metrics: channel_type, status, avg_cpc.

4. serve() handler: recibe {tenant_id, channel_id} en body, instancia el conector, ejecuta, retorna resultado.

Sigue las reglas: retry automático de ConnectorBase, dedup key, SAFE math para divisiones.
```

## Archivos a crear/modificar

- `supabase/functions/sync-google-ads/index.ts`

## Estimación

~2-3 horas con Claude Code
