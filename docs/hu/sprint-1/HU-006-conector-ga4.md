# HU-006: Conector GA4

**Sprint**: 1 — Primer Pipeline E2E (Semana 2)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (ConnectorBase debe existir)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que extrae sessions, users y conversions de GA4 por día usando la Data API v1 (runReport), normaliza al schema unificado e inserta en BigQuery.

## Criterios de aceptación

- [ ] Edge Function `sync-ga4` extrae sessions, users, conversions por día
- [ ] Usa GA4 Data API v1 (runReport)
- [ ] Normaliza a NormalizedRow
- [ ] Funciona con Service Account auth (no OAuth user)

## Prompt para Claude Code

```
Lee CLAUDE.md y _shared/connector-base.ts.

Crea supabase/functions/sync-ga4/index.ts:

1. Clase GA4Connector extends ConnectorBase
2. fetchData():
   - Auth: usa el mismo Service Account JSON que BigQuery para generar JWT con scope analytics.readonly
   - POST a https://analyticsdata.googleapis.com/v1beta/properties/{propertyId}:runReport
   - Body: dateRanges: [{startDate, endDate}], dimensions: [date, sessionSource, sessionMedium], metrics: [sessions, totalUsers, newUsers, bounceRate, averageSessionDuration, conversions, screenPageViews]
   - Manejar paginación con offset si hay más de 10K rows

3. normalize(): GA4 no tiene spend (es orgánico/referral), así que spend=0 para GA4. Mapear sessions→impressions (conceptualmente, para el schema unificado), conversions→conversions. extra_metrics: source, medium, bounce_rate, avg_session_duration, new_users, page_views.

4. serve() handler: mismo patrón que Google Ads.

Nota: GA4 agrupa por source/medium, así que cada combinación source-medium-date es una row. El source_campaign_id será "{source}/{medium}".
```

## Archivos a crear/modificar

- `supabase/functions/sync-ga4/index.ts`

## Estimación

~2-3 horas con Claude Code
