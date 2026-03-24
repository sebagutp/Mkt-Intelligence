# HU-009: Conector Meta Ads

**Sprint**: 2 — Canales Restantes (Semana 3)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (ConnectorBase)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que extrae data de campañas de Meta Ads por día via Graph API Insights endpoint. Maneja paginación, normaliza actions array a conversions y action_values a conversion_value.

## Criterios de aceptación

- [ ] Extrae data de campañas por día via Insights API
- [ ] Maneja paginación de Graph API
- [ ] Normaliza: actions array → conversions, action_values → conversion_value
- [ ] extra_metrics: reach, frequency, cpm

## Prompt para Claude Code

```
Lee CLAUDE.md y _shared/connector-base.ts.

Crea supabase/functions/sync-meta-ads/index.ts:

1. Clase MetaAdsConnector extends ConnectorBase
2. fetchData():
   - Access token desde credentials (System User long-lived token)
   - GET https://graph.facebook.com/v19.0/{adAccountId}/insights
   - Params: fields=campaign_id,campaign_name,impressions,clicks,spend,reach,actions,action_values,ctr,cpc,cpm,frequency  level=campaign  time_range={"since":startDate,"until":endDate}  time_increment=1  limit=500
   - Paginación: seguir data.paging.next hasta null
   - Error handling: si data.error, throw con message

3. normalize():
   - spend: parseFloat(row.spend)
   - conversions: filtrar row.actions por action_type in ['lead','complete_registration','purchase'], sumar values
   - conversion_value: filtrar row.action_values por action_type='purchase', sumar values
   - extra_metrics: {reach, frequency, cpm, all_actions: row.actions}

4. serve() handler estándar.
```

## Archivos a crear/modificar

- `supabase/functions/sync-meta-ads/index.ts`

## Estimación

~2-3 horas con Claude Code
