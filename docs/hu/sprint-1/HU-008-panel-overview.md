# HU-008: Panel Overview con data real

**Sprint**: 1 — Primer Pipeline E2E (Semana 2)
**Track**: B (Frontend)
**Dependencias**: HU-003 (layout base), HU-007 (proxy debe existir para conectar)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Construir el panel principal del dashboard: KPI cards (Spend, Conversions, CPA, ROAS), gráfico de tendencia diaria, donut de distribución por canal, tabla resumen y date range picker. Todo conectado a data real via el proxy bq-query.

## Criterios de aceptación

- [ ] KPI cards muestran: Total Spend, Total Conversions, Blended CPA, Blended ROAS
- [ ] Gráfico de líneas: spend + conversions por día (últimos 30 días)
- [ ] Donut chart: distribución de spend por canal
- [ ] Tabla resumen por canal con métricas clave
- [ ] Date range picker funciona (7d, 30d, 90d, MTD)
- [ ] Loading skeletons mientras carga

## Prompt para Claude Code

```
Lee CLAUDE.md, especialmente la sección de hooks y charts.

1. Crea src/lib/bigquery.ts: función bqQuery(queryName, params?) que llama a supabase.functions.invoke('bq-query', {body: {query_name, params}}). Transforma response de BigQuery (schema.fields + rows[].f[].v) a array de objetos tipados.

2. Crea hooks:
   - src/hooks/useBigQuery.ts: hook genérico useQuery wrapper
   - src/hooks/useOverview.ts: exporta useOverviewKPIs(days), useDailyTrend(days), useSpendDistribution(days). Cada uno usa useQuery con queryKey y staleTime de 5min.

3. Crea componentes de charts:
   - KPICard.tsx: número grande, label arriba en gris, flecha de trend (▲ verde o ▼ rojo) con % de cambio. Props: label, value, previousValue, format ('currency'|'number'|'percent')
   - SpendTrendChart.tsx: Recharts LineChart responsive. Dos líneas: spend (azul), conversions (verde). Eje X: fechas. Eje Y doble: USD izq, conversiones der. Tooltip custom.
   - ChannelDonut.tsx: Recharts PieChart con label customizada mostrando % y nombre del canal. Colores por canal (constantes).
   - CampaignTable.tsx: tabla con columnas: canal (icono+nombre), spend, conversions, CPA, ROAS. Sorteable por columna.

4. Crea src/components/shared/DateRangePicker.tsx: botones de presets (7d, 30d, 90d, MTD, QTD) + selector custom. Emite onChange con days.

5. Crea src/panels/OverviewPanel.tsx: compone KPICards (grid 4 cols), SpendTrendChart, ChannelDonut + CampaignTable side by side (md: 2 cols).

6. Conecta DashboardPage.tsx para renderizar OverviewPanel.

Mobile responsive. Skeletons en cada sección mientras carga. Si no hay data, EmptyState con mensaje "Conecta tu primer canal en Settings".
```

## Archivos a crear/modificar

- `src/lib/bigquery.ts`
- `src/hooks/useBigQuery.ts`
- `src/hooks/useOverview.ts`
- `src/components/charts/KPICard.tsx`
- `src/components/charts/SpendTrendChart.tsx`
- `src/components/charts/ChannelDonut.tsx`
- `src/components/charts/CampaignTable.tsx`
- `src/components/shared/DateRangePicker.tsx`
- `src/components/panels/OverviewPanel.tsx`
- `src/pages/DashboardPage.tsx`

## Estimación

~4-5 horas con Claude Code
