# HU-011: Conector LinkedIn

**Sprint**: 2 — Canales Restantes (Semana 3)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (ConnectorBase)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que extrae métricas de LinkedIn Ads (Marketing API) y contenido Orgánico (Organization API). Maneja OAuth 2.0 three-legged flow con token refresh. Combina ambas fuentes en el schema normalizado.

## Criterios de aceptación

- [ ] Extrae métricas de Ads (Marketing API) y Orgánico (Organization API)
- [ ] Maneja OAuth 2.0 three-legged flow con token refresh
- [ ] Combina ambas fuentes en el schema normalizado

## Prompt para Claude Code

```
Lee CLAUDE.md y _shared/connector-base.ts.

Crea supabase/functions/sync-linkedin/index.ts:

1. Clase LinkedInConnector extends ConnectorBase
2. fetchData(): Dos llamadas paralelas:

   a) Ads: GET https://api.linkedin.com/v2/adAnalyticsV2
      - Params: q=analytics, dateRange.start/end, timeGranularity=DAILY, pivot=CAMPAIGN
      - Fields: impressions, clicks, costInLocalCurrency, externalWebsiteConversions, leads
      - Auth: Bearer token (OAuth2 refresh)

   b) Orgánico: GET https://api.linkedin.com/v2/organizationalEntityShareStatistics
      - Params: organizationalEntity=urn:li:organization:{orgId}, timeIntervals.timeRange.start/end
      - Fields: totalShareStatistics (impressionCount, clickCount, likeCount, shareCount, commentCount, followerCount)

3. normalize():
   - Ads rows: channel='linkedin_ads', spend=costInLocalCurrency, conversions=externalWebsiteConversions+leads
   - Orgánico rows: channel='linkedin_organic', spend=0, impressions=impressionCount, clicks=clickCount
   - extra_metrics: para ads {leads, cost_per_lead}, para orgánico {likes, shares, comments, followers}

4. Token refresh: POST https://www.linkedin.com/oauth/v2/accessToken con grant_type=refresh_token.

Nota: LinkedIn rate limits son bajos (100/día para algunos endpoints). Agregar 500ms delay entre requests.
```

## Archivos a crear/modificar

- `supabase/functions/sync-linkedin/index.ts`

## Estimación

~2-3 horas con Claude Code
