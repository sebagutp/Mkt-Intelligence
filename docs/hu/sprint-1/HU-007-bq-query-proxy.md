# HU-007: BQ Query Proxy

**Sprint**: 1 — Primer Pipeline E2E (Semana 2)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (BigQuery client), HU-002 (queries pre-armadas)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function proxy seguro que recibe nombre de query + params del frontend, ejecuta queries pre-armadas en BigQuery del tenant, y retorna resultados JSON. Valida JWT, determina dataset del tenant desde DB, nunca acepta SQL arbitrario.

## Criterios de aceptación

- [ ] Edge Function `bq-query` recibe nombre de query + params, ejecuta en BigQuery del tenant, retorna resultados
- [ ] Valida JWT de Supabase (solo usuarios autenticados)
- [ ] Determina dataset del tenant desde la DB (no del request)
- [ ] Queries pre-armadas, no acepta SQL arbitrario
- [ ] Cache header de 5 min

## Prompt para Claude Code

```
Lee CLAUDE.md, especialmente reglas de seguridad de BigQuery.

Crea supabase/functions/bq-query/index.ts:

1. Verificar auth: extraer JWT del header Authorization, validar con supabase.auth.getUser()
2. Obtener tenant: llamar supabase.rpc('get_my_tenant') para obtener bq_project_id y bq_dataset
3. Parsear request: { query_name: string, params?: Record<string, string> }
4. Map de queries pre-armadas (NO SQL arbitrario):
   - overview_kpis(days): channel, spend, clicks, conversions, revenue, cpa, roas agrupado por canal
   - daily_trend(days): metric_date, channel, spend, conversions, cpa, roas por día
   - top_campaigns(days, limit): mejores campañas por ROAS
   - channel_detail(channel, days): todas las campañas de un canal con métricas
   - anomalies(): CPA spikes vs media 7 días
   - spend_distribution(days): spend por canal para donut chart

5. Instanciar BigQueryClient con credentials del tenant
6. Ejecutar query, retornar JSON
7. Headers: Cache-Control max-age=300, Content-Type application/json

IMPORTANTE: los params solo pueden ser 'days' (número), 'channel' (string validada contra lista), 'limit' (número). Sanitizar todo. Nunca concatenar strings del usuario directo en SQL.
```

## Archivos a crear/modificar

- `supabase/functions/bq-query/index.ts`

## Estimación

~2-3 horas con Claude Code
