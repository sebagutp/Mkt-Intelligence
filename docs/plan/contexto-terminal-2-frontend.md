# Contexto Terminal 2 — Track B: Frontend

> Pega esto al inicio de cada sesión de Claude Code para esta terminal.

## Tu rol

Eres el desarrollador frontend. Trabajas en la React SPA (Vite + TypeScript + TailwindCSS + Recharts) que muestra el dashboard de marketing analytics. Tu código vive en `apps/dashboard/src/`.

## Reglas críticas (de CLAUDE.md)

1. Componentes de charts son genéricos: reciben `data` tipada, NO saben de BigQuery
2. Toda data via hooks de `hooks/`. Los hooks llaman a `lib/bigquery.ts`
3. `lib/bigquery.ts` NUNCA ejecuta SQL. Solo llama al proxy `bq-query` via `supabase.functions.invoke()`
4. Colores de branding via CSS vars `--brand-primary`, `--brand-accent`. NO hardcodear
5. Dark mode: `dark:` variants de Tailwind. Probar ambos.
6. Mobile first. Breakpoints: sm:640, md:768, lg:1024
7. Loading: siempre Skeleton, NUNCA spinner. Usar `LoadingSkeleton.tsx`
8. Empty state: siempre `EmptyState.tsx` con guía de acción
9. React Query: `staleTime: 5 * 60 * 1000`, `refetchOnWindowFocus: false`
10. TypeScript estricto. NO `any`. Tipos en `src/types/`.
11. Un componente por archivo. Max 200 líneas.
12. Imports con `@/` alias.

## Estructura clave

```
apps/dashboard/src/
  lib/
    supabase.ts         ← Cliente singleton
    bigquery.ts         ← bqQuery() via proxy
    constants.ts        ← Channel types, presets, colors
    utils.ts            ← Formatters (currency, %, dates)
  types/
    tenant.ts, metrics.ts, campaign.ts, sync.ts
  providers/
    AuthProvider.tsx, TenantProvider.tsx, QueryProvider.tsx
  hooks/
    useAuth, useTenant, useBigQuery, useOverview,
    useChannelDetail, useCampaigns, useAnomalies, useSyncStatus
  components/
    layout/    → AppLayout, Sidebar, Header, MobileNav
    panels/    → OverviewPanel, ChannelPanel, InsightsPanel, ReportsPanel
    charts/    → KPICard, SpendTrendChart, ChannelDonut, CampaignTable, Sparkline
    insights/  → AnomalyCard, BudgetPacing, TopBottomList
    shared/    → DateRangePicker, ChannelFilter, ExportButton, LoadingSkeleton, EmptyState, StatusBadge, ChannelIcon
  pages/
    LoginPage, DashboardPage, ChannelDetailPage, InsightsPage, ReportsPage, SettingsPage
  router.tsx
```

## KPIs del Overview (para referencia)

1. **Total Spend** — Suma spend todos los canales. Formato: $X,XXX.XX
2. **Total Conversions** — Suma conversiones. Formato: X,XXX
3. **Blended CPA** — spend / conversions. Formato: $X.XX
4. **Blended ROAS** — conversion_value / spend. Formato: X.XXx

## Polaridad de métricas (para trend arrows)

```
spend: 'negative'        ← más = peor (arrow roja si sube)
conversions: 'positive'  ← más = mejor (arrow verde si sube)
ctr: 'positive'
cpc: 'negative'
cpa: 'negative'          ← CPA más bajo = mejor
roas: 'positive'         ← ROAS más alto = mejor
```

## Pattern de mock data (para desarrollo sin backend)

```typescript
const USE_MOCK = !import.meta.env.VITE_SUPABASE_URL;

export function useOverviewKPIs(days: number) {
  return useQuery({
    queryKey: ['overview-kpis', days],
    queryFn: () => USE_MOCK ? getMockKPIs(days) : bqQuery('overview_kpis', { days }),
    staleTime: 5 * 60 * 1000,
  });
}
```
