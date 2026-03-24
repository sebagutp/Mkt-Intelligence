# CLAUDE.md — Marketing Intelligence Hub (MIH)

## Instrucciones para Claude Code

### Skills disponibles (en .claude/skills/)

Este proyecto tiene skills de dominio que DEBES leer antes de implementar funcionalidad relacionada:

- **SKILL-growth-marketing.md** → Léelo antes de trabajar en KPIs, normalización, anomalías, o cualquier lógica de métricas. Define el funnel unificado, polaridad de métricas, y reglas de SAFE_DIVIDE.
- **SKILL-google-ads.md** → Léelo antes de HU-005. Contiene GAQL syntax, SearchStream parsing, conversión de cost_micros.
- **SKILL-meta-ads.md** → Léelo antes de HU-009. Contiene Graph API Insights, parsing del array `actions`, y rate limits.
- **SKILL-google-analytics-4.md** → Léelo antes de HU-006. Contiene Data API v1, formato de fecha, y mapping sessions→impressions.
- **SKILL-email-marketing.md** → Léelo antes de HU-010. Contiene APIs de Mailchimp/Brevo, formato webhook, y parsing CSV.
- **SKILL-track-a-backend-etl.md** → Reglas del track Backend/ETL.
- **SKILL-track-b-frontend.md** → Reglas del track Frontend.
- **SKILL-track-c-infra-devops.md** → Reglas del track Infra/DevOps.

### Documentación de HUs (en docs/hu/)

Cada Historia de Usuario está en `docs/hu/sprint-X/HU-XXX-nombre.md`. Contiene criterios de aceptación, prompt detallado, y archivos a crear. Léela antes de implementar.

### Workflow por HU

1. Lee esta CLAUDE.md (ya lo hiciste si estás leyendo esto)
2. Lee el skill de dominio relevante en `.claude/skills/`
3. Lee la HU específica en `docs/hu/sprint-X/`
4. Implementa siguiendo las reglas de abajo
5. Verifica con `npx tsc --noEmit` al terminar

---

## Qué es este proyecto

Dashboard white-label de marketing analytics. Consolida data de Google Analytics, Google Ads, Meta Ads, Email Marketing y LinkedIn en un solo lugar. Modelo de negocio: código nuestro, infra del cliente. Cada cliente entrega su email, se le crea Google Cloud + Supabase en su cuenta, se deploya el sistema y se cobra servicio mensual.

## Arquitectura

```
Clientes de marketing    →    Edge Functions (ETL)    →    BigQuery (warehouse)
(GA4, Google Ads,              Supabase Edge Functions       Free tier: 10GB + 1TB/mes
 Meta Ads, Email,              Deno/TypeScript               Un dataset por cliente
 LinkedIn)                     Retry + rate limits

                                                       →    Supabase (operacional)
                                                             Auth, config, credentials,
                                                             sync logs, branding
                                                       
BigQuery + Supabase    →    React SPA (dashboard)
                            Vite + TailwindCSS + Recharts
                            Multi-tenant, white-label
                            Static hosting (Vercel/CF)
```

## Stack técnico

| Componente | Tecnología | Notas |
|-----------|-----------|-------|
| Frontend | React 18 + Vite + TypeScript | SPA, no SSR |
| Styling | TailwindCSS 3 | Dark mode con `dark:` variant. CSS vars para branding |
| Charts | Recharts | Declarativo, React-nativo. Alternativa: Chart.js si necesitas más control |
| State/Cache | TanStack React Query v5 | Cache de 5 min para queries de BQ. staleTime: 300000 |
| Auth | Supabase Auth | Email/password + magic link. JWT para identificar tenant |
| Backend DB | Supabase PostgreSQL | Solo data operacional: tenants, users, credentials, logs, config |
| Data Warehouse | Google BigQuery (free tier) | Data analítica: métricas de marketing. Particionado por fecha |
| ETL | Supabase Edge Functions (Deno) | Un conector por canal. Todos extienden ConnectorBase |
| Scheduling | pg_cron en Supabase | Cron diario escalonado por canal |
| Hosting | Vercel o Cloudflare Pages | Static site. Env vars por cliente |

## Estructura del proyecto

```
mih/
├── CLAUDE.md                           ← Este archivo
├── README.md
├── package.json
├── tsconfig.json
│
├── apps/
│   └── dashboard/                      ← React SPA
│       ├── index.html
│       ├── package.json
│       ├── vite.config.ts
│       ├── tailwind.config.js
│       ├── postcss.config.js
│       ├── tsconfig.json
│       ├── public/
│       │   └── favicon.svg
│       └── src/
│           ├── main.tsx
│           ├── App.tsx
│           ├── index.css                ← Tailwind imports + CSS vars de branding
│           │
│           ├── lib/
│           │   ├── supabase.ts          ← Cliente Supabase (singleton)
│           │   ├── bigquery.ts          ← Funciones para llamar al proxy bq-query
│           │   ├── constants.ts         ← Channel types, date presets, plan limits
│           │   └── utils.ts             ← Formatters (currency, %, dates), helpers
│           │
│           ├── types/
│           │   ├── tenant.ts            ← Tenant, Branding, TenantChannel, Plan
│           │   ├── metrics.ts           ← NormalizedMetric, ChannelSummary, KPIs
│           │   ├── campaign.ts          ← Campaign, CampaignDetail
│           │   └── sync.ts             ← SyncLog, SyncStatus
│           │
│           ├── providers/
│           │   ├── AuthProvider.tsx      ← Supabase auth context
│           │   ├── TenantProvider.tsx    ← Carga tenant config + aplica branding
│           │   └── QueryProvider.tsx     ← React Query client provider
│           │
│           ├── hooks/
│           │   ├── useAuth.ts
│           │   ├── useTenant.ts
│           │   ├── useBigQuery.ts       ← Hook genérico para queries al proxy
│           │   ├── useOverview.ts       ← KPIs, daily trend, spend distribution
│           │   ├── useChannelDetail.ts  ← Drill-down por canal
│           │   ├── useCampaigns.ts      ← Top/bottom campaigns
│           │   ├── useAnomalies.ts      ← Anomaly detection results
│           │   └── useSyncStatus.ts     ← Estado de syncs (Supabase realtime)
│           │
│           ├── components/
│           │   ├── layout/
│           │   │   ├── AppLayout.tsx     ← Sidebar + Header + Content area
│           │   │   ├── Sidebar.tsx       ← Nav: Overview, Channels, Insights, Reports, Settings
│           │   │   ├── Header.tsx        ← Logo (branding), user menu, date range picker
│           │   │   └── MobileNav.tsx     ← Bottom nav para mobile
│           │   │
│           │   ├── panels/
│           │   │   ├── OverviewPanel.tsx  ← KPI cards + spend chart + donut + tabla resumen
│           │   │   ├── ChannelPanel.tsx   ← Vista drill-down genérica por canal
│           │   │   ├── InsightsPanel.tsx  ← Anomalies + pacing + top/bottom
│           │   │   └── ReportsPanel.tsx   ← Date picker + export + comparación períodos
│           │   │
│           │   ├── charts/
│           │   │   ├── KPICard.tsx        ← Número grande + label + trend arrow
│           │   │   ├── SpendTrendChart.tsx ← Line chart: spend + conversions por día
│           │   │   ├── ChannelDonut.tsx    ← Pie/donut: distribución spend por canal
│           │   │   ├── CampaignTable.tsx   ← Tabla con sparklines por campaña
│           │   │   ├── ComparisonBar.tsx   ← Barras comparativas (este período vs anterior)
│           │   │   └── Sparkline.tsx       ← Mini line chart inline para tablas
│           │   │
│           │   ├── insights/
│           │   │   ├── AnomalyCard.tsx     ← Card de alerta: CPA spike, CTR drop, etc.
│           │   │   ├── BudgetPacing.tsx    ← Barra de progreso spend vs budget
│           │   │   └── TopBottomList.tsx   ← Top 5 / Bottom 5 campañas
│           │   │
│           │   └── shared/
│           │       ├── DateRangePicker.tsx ← Presets (7d, 30d, MTD, QTD) + custom
│           │       ├── ChannelFilter.tsx   ← Multi-select de canales
│           │       ├── ExportButton.tsx    ← PDF/CSV export
│           │       ├── LoadingSkeleton.tsx
│           │       ├── EmptyState.tsx      ← Zero-state con guía de setup
│           │       ├── StatusBadge.tsx     ← Verde/amarillo/rojo
│           │       └── ChannelIcon.tsx     ← Iconos por canal (GA4, Ads, Meta, etc.)
│           │
│           ├── pages/
│           │   ├── LoginPage.tsx
│           │   ├── DashboardPage.tsx       ← Wrapper: OverviewPanel
│           │   ├── ChannelDetailPage.tsx   ← Wrapper: ChannelPanel con route param
│           │   ├── InsightsPage.tsx        ← Wrapper: InsightsPanel
│           │   ├── ReportsPage.tsx         ← Wrapper: ReportsPanel
│           │   └── SettingsPage.tsx        ← Channels, alerts, users, branding preview
│           │
│           └── router.tsx                  ← React Router con auth guard
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 20260323000001_core_tables.sql
│   │   ├── 20260323000002_rls_policies.sql
│   │   └── 20260323000003_functions.sql
│   │
│   └── functions/
│       ├── _shared/
│       │   ├── bigquery-client.ts       ← Auth JWT + insertRows + query
│       │   ├── connector-base.ts        ← Clase abstracta: retry, normalize, log
│       │   ├── credential-manager.ts    ← Lee credentials de Supabase
│       │   ├── normalizer.ts            ← Helpers de normalización
│       │   └── types.ts                 ← Tipos compartidos entre funciones
│       │
│       ├── sync-ga4/index.ts
│       ├── sync-google-ads/index.ts
│       ├── sync-meta-ads/index.ts
│       ├── sync-email/index.ts          ← Router: delega a sub-conector según provider
│       ├── sync-linkedin/index.ts
│       ├── sync-orchestrator/index.ts   ← Dispara todos los syncs de un tenant
│       ├── sync-webhook/index.ts        ← Endpoint POST para syncs on-demand
│       ├── bq-query/index.ts            ← Proxy seguro: queries pre-armadas a BigQuery
│       ├── token-refresh/index.ts       ← Renueva OAuth tokens pre-expiry
│       └── alert-dispatcher/index.ts    ← Envía alertas a Slack/email
│
├── bigquery/
│   ├── schemas/
│   │   ├── marketing_metrics.sql
│   │   ├── campaign_details.sql
│   │   └── channel_daily_summary.sql
│   └── queries/
│       ├── overview_kpis.sql
│       ├── daily_trend.sql
│       ├── top_campaigns.sql
│       ├── channel_detail.sql
│       ├── anomaly_detection.sql
│       └── spend_distribution.sql
│
├── provisioning/
│   ├── provision.sh                     ← Script maestro: setup completo de nuevo cliente
│   ├── config/
│   │   └── client-template.env          ← Template de variables
│   ├── scripts/
│   │   ├── 01-setup-bigquery.sh
│   │   ├── 02-setup-supabase.sh
│   │   ├── 03-deploy-functions.sh
│   │   ├── 04-register-tenant.sh
│   │   ├── 05-deploy-frontend.sh
│   │   └── 06-test-connections.sh
│   └── clients/                         ← .env por cliente (GITIGNORED)
│       └── .gitkeep
│
└── docs/
    ├── setup-guide.md
    ├── adding-a-channel.md
    ├── adding-a-client.md
    ├── api-reference.md
    └── onboarding-checklist.md
```

## Reglas de desarrollo

### Generales
1. TypeScript estricto en todo el proyecto. `strict: true` en tsconfig.
2. NO usar `any`. Definir tipos en `src/types/`.
3. Archivos en kebab-case. Componentes React en PascalCase.
4. Un componente por archivo. Max 200 líneas por archivo — si crece, splitear.
5. Imports absolutos con `@/` alias apuntando a `src/`.

### Frontend
6. Componentes de charts son genéricos: reciben `data` tipada, no saben de BigQuery.
7. Toda data del dashboard viene via hooks de `hooks/`. Los hooks llaman a `lib/bigquery.ts`.
8. `lib/bigquery.ts` NUNCA ejecuta SQL directo a BigQuery. Solo llama al proxy `bq-query` via `supabase.functions.invoke()`.
9. Colores de branding via CSS variables `--brand-primary` y `--brand-accent`. NO hardcodear colores del tenant.
10. Dark mode: usar `dark:` variants de Tailwind. Probar ambos modos.
11. Mobile first. Breakpoints: `sm:640px`, `md:768px`, `lg:1024px`.
12. Loading states: siempre Skeleton, nunca spinner. Usar `LoadingSkeleton.tsx`.
13. Empty states: siempre `EmptyState.tsx` con guía de acción, nunca pantalla vacía.
14. React Query: `staleTime: 5 * 60 * 1000` para queries de BQ. `refetchOnWindowFocus: false`.

### Edge Functions (ETL)
15. TODOS los conectores extienden `ConnectorBase` de `_shared/connector-base.ts`.
16. Retry exponencial: 3 intentos, backoff 1s → 2s → 4s. Ya implementado en la base class.
17. Rate limits: respetar headers de cada API. No paralelizar requests dentro de un conector.
18. Credenciales NUNCA en código. Solo desde `api_credentials` de Supabase (encriptadas).
19. Logs de sync SIEMPRE via `log_sync()` RPC. Nunca INSERT directo.
20. Cada conector maneja su propia normalización a `NormalizedRow`.
21. Dedup key = `channel__campaign_id__date`. BigQuery usa `insertId` para dedup.

### BigQuery
22. TODA query debe incluir filtro de fecha (`WHERE metric_date BETWEEN...`). La tabla tiene `require_partition_filter = true`.
23. Queries pre-armadas en `bq-query/index.ts`. NO aceptar SQL arbitrario del frontend.
24. Parámetros de queries: solo `days`, `channel`, `limit`. Nunca concatenar strings del usuario en SQL.
25. Usar `SAFE_DIVIDE()` para evitar division by zero en métricas calculadas.

### Supabase
26. RLS en TODAS las tablas con `tenant_id`. Función helper: `auth.user_tenant_ids()`.
27. Migrations numeradas con timestamp: `YYYYMMDDHHMMSS_nombre.sql`.
28. Service role key solo en Edge Functions (server-side). NUNCA en frontend.
29. Anon key en frontend. RLS protege los datos.

### Seguridad
30. El proxy `bq-query` valida JWT de Supabase antes de ejecutar cualquier query.
31. El proxy determina el `bq_dataset` del tenant desde la DB, no desde el request del frontend.
32. No exponer BQ credentials en el frontend. Todo va via Edge Function proxy.
33. CORS configurado solo para dominios del tenant.

## Comandos

```bash
# Desarrollo
cd apps/dashboard && npm run dev          # Frontend dev server (Vite)
supabase start                            # Supabase local
supabase functions serve                  # Edge Functions local
supabase functions serve sync-ga4 --env-file ./supabase/.env.local  # Una función específica

# Deploy
supabase db push                          # Aplicar migrations
supabase functions deploy                 # Deploy todas las Edge Functions
supabase functions deploy bq-query        # Deploy una función específica
cd apps/dashboard && npm run build        # Build frontend

# Provisioning
./provisioning/provision.sh provisioning/clients/nombre.env  # Setup nuevo cliente

# Testing
cd apps/dashboard && npm run test         # Unit tests
supabase functions serve sync-ga4 --debug # Debug una función
```

## Convenciones de nombres

```
Archivos:       kebab-case          (overview-panel.tsx, sync-google-ads.ts)
Componentes:    PascalCase          (OverviewPanel, KPICard)
Hooks:          camelCase con use   (useOverview, useBigQuery)
Funciones:      camelCase           (formatCurrency, calculateROAS)
Tipos:          PascalCase          (TenantConfig, NormalizedRow)
Constantes:     UPPER_SNAKE         (MAX_CHANNELS, SYNC_INTERVAL)
CSS vars:       --brand-primary     (kebab-case con -- prefix)
BQ tables:      snake_case          (marketing_metrics, campaign_details)
Supabase tables: snake_case         (tenant_channels, sync_logs)
Edge Functions: kebab-case          (sync-google-ads, bq-query)
SQL:            UPPER CASE          (SELECT, WHERE, GROUP BY)
```

## Variables de entorno

```bash
# Frontend (.env.local)
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...

# Edge Functions (.env.local)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
BQ_PROJECT_ID=mih-client-prod
BQ_DATASET=mih_datawalt
BQ_SERVICE_ACCOUNT_JSON='{...}'
GOOGLE_OAUTH_CLIENT_ID=xxx
GOOGLE_OAUTH_CLIENT_SECRET=xxx
GOOGLE_ADS_DEV_TOKEN=xxx
```

## Dependencias principales

```json
{
  "dependencies": {
    "react": "^18.3",
    "react-dom": "^18.3",
    "react-router-dom": "^6.26",
    "@supabase/supabase-js": "^2.45",
    "@tanstack/react-query": "^5.56",
    "recharts": "^2.12",
    "tailwindcss": "^3.4",
    "date-fns": "^3.6",
    "lucide-react": "^0.441"
  },
  "devDependencies": {
    "typescript": "^5.5",
    "vite": "^5.4",
    "@types/react": "^18.3",
    "autoprefixer": "^10.4",
    "postcss": "^8.4"
  }
}
```

## Contexto adicional

- El primer cliente es Datawalt (nuestro propio producto).
- Email marketing de Datawalt usa Google Apps Script (estrategia B: webhook push).
- El sistema es white-label: código nuestro, infra del cliente. $0 costo para nosotros.
- Pricing: $149-399/mes por cliente.
- Prioridad: que funcione E2E con data real antes de pulir UI.

## Estado actual del proyecto

> Actualizar esta sección al completar cada sprint.

| Sprint | Estado | HUs completadas |
|--------|--------|-----------------|
| 0 — Scaffold + Infra | ✅ Completo | HU-001, HU-002, HU-003 |
| 1 — Pipeline E2E | ✅ Completo | HU-004 a HU-008 |
| 2 — Canales restantes | ✅ Completo | HU-009 a HU-012 |
| 3 — Intelligence | ✅ Completo | HU-013 a HU-016 |
| 4 — White-label | ✅ Completo | HU-017 (provisioning), HU-018 (branding) |
| 5 — Polish + Deploy | ✅ Completo | HU-019 (export/reports), HU-020 (token refresh), HU-021 (deploy docs) |
