# HU-013: Paneles drill-down por canal

**Sprint**: 2 — Canales Restantes (Semana 3)
**Track**: B (Frontend)
**Dependencias**: HU-008 (Overview panel y hooks base), HU-007 (proxy)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Vistas de drill-down específicas por canal. Cada canal muestra tabla de campañas con columnas relevantes, chart de tendencia y KPIs específicos. El componente ChannelPanel es genérico y adapta contenido según el tipo de canal.

## Criterios de aceptación

- [ ] `/channel/google_ads` muestra campaigns de Google Ads con métricas detalladas
- [ ] `/channel/meta_ads` muestra campaigns de Meta con breakdowns
- [ ] `/channel/ga4` muestra sources/mediums con traffic data
- [ ] `/channel/email` muestra campaigns de email con open/click rates
- [ ] `/channel/linkedin` muestra ads vs orgánico
- [ ] Cada vista tiene tabla + chart específico del canal

## Prompt para Claude Code

```
Lee CLAUDE.md. El ChannelPanel es genérico pero adapta su contenido según el canal.

1. Crea src/hooks/useChannelDetail.ts: llama a bq-query con query_name='channel_detail', params={channel, days}. Retorna lista de campañas con métricas.

2. Crea src/hooks/useCampaigns.ts: llama a query 'top_campaigns'. Retorna top/bottom campañas.

3. Crea src/panels/ChannelPanel.tsx: componente genérico que recibe channel type y renderiza:
   - KPI cards del canal: spend total, conversions, CPA, ROAS (o métricas específicas)
   - Chart de tendencia del canal (últimos N días)
   - Tabla de campañas con columnas según canal:
     * Google Ads: campaign, impressions, clicks, CTR, CPC, conversions, CPA, ROAS
     * Meta Ads: campaign, spend, impressions, reach, clicks, CTR, conversions, ROAS, frequency
     * GA4: source/medium, sessions, users, bounce rate, conversions, pages/session
     * Email: campaign, sent, opens, open rate, clicks, CTR, bounces, unsubs
     * LinkedIn: campaign, impressions, clicks, CTR, spend, conversions, leads, CPL

4. Crea src/components/shared/ChannelIcon.tsx: iconos SVG simples por canal. Colores por canal en constantes.

5. Actualiza ChannelDetailPage.tsx: lee :type de route params, pasa a ChannelPanel.

Tabla sorteable, responsive (scroll horizontal en mobile). Loading skeletons.
```

## Archivos a crear/modificar

- `src/hooks/useChannelDetail.ts`
- `src/hooks/useCampaigns.ts`
- `src/components/panels/ChannelPanel.tsx`
- `src/components/shared/ChannelIcon.tsx`
- `src/pages/ChannelDetailPage.tsx`

## Estimación

~4-5 horas con Claude Code
