# Guía de Kickoff — Cómo iniciar el desarrollo con Claude Code

## Antes de abrir cualquier terminal

### Paso 0: Estructura del repositorio

Crea un repo Git y copia los archivos de documentación:

```bash
mkdir mih && cd mih
git init

# Copiar CLAUDE.md a la raíz (Claude Code lo lee automáticamente)
cp /ruta/a/CLAUDE.md ./CLAUDE.md

# Crear .claude/skills/ para que Claude Code los reconozca
mkdir -p .claude/skills

# Copiar los skills (Claude Code los lee de .claude/ automáticamente)
cp /ruta/a/skills/SKILL-track-a-backend-etl.md .claude/skills/
cp /ruta/a/skills/SKILL-track-b-frontend.md .claude/skills/
cp /ruta/a/skills/SKILL-track-c-infra-devops.md .claude/skills/
cp /ruta/a/skills/SKILL-growth-marketing.md .claude/skills/
cp /ruta/a/skills/SKILL-meta-ads.md .claude/skills/
cp /ruta/a/skills/SKILL-google-ads.md .claude/skills/
cp /ruta/a/skills/SKILL-google-analytics-4.md .claude/skills/
cp /ruta/a/skills/SKILL-email-marketing.md .claude/skills/

# Copiar HUs como referencia (NO en .claude/, son para consulta manual)
cp -r /ruta/a/hu/ ./docs/hu/

git add -A && git commit -m "Initial project documentation"
```

### Paso 1: CLAUDE.md ya está listo

Claude Code lee `CLAUDE.md` automáticamente en la raíz del proyecto. No necesitas hacer nada extra. Este archivo es tu "system prompt" permanente.

### Paso 2: Verificar que el entorno tiene las herramientas

```bash
node --version    # >= 18.x
npm --version     # >= 9.x
npx --version     # incluido con npm
```

---

## Estrategia de terminales

### Cuántas terminales abrir

```
┌─────────────────────────────────────────────────────┐
│                                                      │
│   Terminal 1          Terminal 2          Terminal 3  │
│   Track A             Track B             Track C    │
│   Backend/ETL         Frontend            Infra      │
│                                                      │
│   HU-004 → HU-007    HU-003              HU-001     │
│   HU-009 → HU-012    HU-008              HU-002     │
│   HU-015, HU-020     HU-013 → HU-014    HU-017     │
│                       HU-016, HU-018     HU-021     │
│                       HU-019                         │
│                                                      │
└─────────────────────────────────────────────────────┘
```

**Sprint 0 solo necesita 1-2 terminales** (HU-001 y HU-002 son infra, HU-003 es frontend). No abras las 3 desde el día 1.

---

## Prompts de inicio por sprint

### SPRINT 0 — Día 1

#### Terminal 3 (Infra) — HU-001: Scaffold

```
Lee CLAUDE.md completo. Tu rol es Track C (Infra/DevOps).

Ejecuta HU-001: Scaffold del proyecto completo.

Crea la estructura de carpetas exacta según la sección "Estructura del proyecto" de CLAUDE.md. Inicializa:

1. Root: package.json con workspaces, tsconfig base strict
2. apps/dashboard: Vite + React + TypeScript. Instala: react-router-dom, @supabase/supabase-js, @tanstack/react-query, recharts, tailwindcss, autoprefixer, postcss, date-fns, lucide-react. Configura tailwind con dark mode 'class'. Crea index.css con Tailwind imports + CSS vars (--brand-primary, --brand-accent).
3. Crea todos los archivos placeholder con exports vacíos para types/, lib/, providers/, hooks/, components/ según estructura
4. supabase/: config.toml básico
5. bigquery/schemas/: archivos SQL placeholder
6. provisioning/: client-template.env y provision.sh skeleton

Asegúrate que `cd apps/dashboard && npm run dev` funcione mostrando "MIH - Setup Complete".
```

**Cuando termine**, verifica con:
```
Ejecuta `cd apps/dashboard && npm run dev` y confirma que compila sin errores. Luego ejecuta `npx tsc --noEmit` para verificar que TypeScript no tiene errores.
```

#### Terminal 3 (Infra) — HU-002: SQL (después de HU-001)

```
Lee CLAUDE.md, secciones de BigQuery y Supabase.

Ejecuta HU-002: Setup de migrations y schemas.

1. Crea las 3 migrations de Supabase:
   - 20260323000001_core_tables.sql: tenants, tenant_users, tenant_channels, api_credentials, sync_logs, dashboard_configs, alert_rules
   - 20260323000002_rls_policies.sql: RLS en todas las tablas, auth.user_tenant_ids()
   - 20260323000003_functions.sql: get_my_tenant(), log_sync(), get_last_sync_date()

2. Crea 3 schemas BigQuery con placeholders {{PROJECT_ID}} y {{DATASET}}:
   - marketing_metrics: PARTITION BY metric_date, CLUSTER BY channel
   - campaign_details: CLUSTER BY channel
   - channel_daily_summary

3. Crea 6 queries pre-armadas en bigquery/queries/:
   overview_kpis, daily_trend, top_campaigns, channel_detail, anomaly_detection, spend_distribution

Todos los SQL deben usar SAFE_DIVIDE() y require_partition_filter.
```

### SPRINT 0 — Día 2

#### Terminal 2 (Frontend) — HU-003: Auth + Layout

```
Lee CLAUDE.md, secciones de providers, layout, y reglas de frontend.

Ejecuta HU-003: Auth, TenantProvider, Layout base.

1. src/lib/supabase.ts: cliente singleton con VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY
2. src/providers/AuthProvider.tsx: session, user, signIn, signOut con onAuthStateChange
3. src/providers/TenantProvider.tsx: carga tenant via supabase.rpc('get_my_tenant'), aplica CSS vars de branding, favicon, title
4. src/providers/QueryProvider.tsx: React Query con staleTime 5min, refetchOnWindowFocus false
5. src/components/layout/AppLayout.tsx: Sidebar colapsable + Header + Content con Outlet
6. src/components/layout/Sidebar.tsx: nav items con lucide-react icons, canales dinámicos
7. src/pages/LoginPage.tsx: email + password, centrado, limpio
8. src/router.tsx: React Router con RequireAuth wrapper
9. src/App.tsx: QueryProvider > AuthProvider > TenantProvider > RouterProvider

Tailwind dark mode, mobile responsive. Loading skeletons (nunca spinners).
```

---

### SPRINT 1 — Día 3

#### Terminal 1 (Backend) — HU-004: Shared ETL

```
Lee CLAUDE.md, reglas de Edge Functions. Lee también el skill SKILL-growth-marketing.md para entender el schema NormalizedRow y las reglas de normalización.

Ejecuta HU-004: Shared ETL modules.

1. supabase/functions/_shared/types.ts: NormalizedRow (todos los campos de marketing_metrics), SyncResult, Credentials
2. supabase/functions/_shared/bigquery-client.ts: clase BigQueryClient con JWT auth via crypto.subtle, insertRows (batch 500, insertId para dedup), query
3. supabase/functions/_shared/connector-base.ts: ConnectorBase abstracta con execute(), fetchWithRetry (3 intentos, backoff 1→2→4s), métodos abstractos fetchData() y normalize(), logging via supabase.rpc('log_sync')
4. supabase/functions/_shared/credential-manager.ts: lee de api_credentials por channel_id

Deno APIs. Imports con URLs de esm.sh. TypeScript estricto.
```

### SPRINT 1 — Día 4 (PARALELO)

#### Terminal 1 (Backend) — HU-005 + HU-006

```
Lee CLAUDE.md y _shared/connector-base.ts que acabamos de crear.
Lee el skill SKILL-google-ads.md para entender GAQL, SearchStream y normalización de cost_micros.

Ejecuta HU-005: Conector Google Ads.

Clase GoogleAdsConnector extends ConnectorBase. Usa GAQL via SearchStream. Normaliza cost_micros / 1_000_000. Dedup key. serve() handler.

Cuando termines HU-005, ejecuta HU-006: Conector GA4.

Clase GA4Connector extends ConnectorBase. Lee el skill SKILL-google-analytics-4.md. Usa Data API v1 runReport con Service Account JWT. Normaliza fecha "20260323" → "2026-03-23". sessions → impressions mapping. spend = 0.
```

#### Terminal 2 (Frontend) — HU-008

```
Lee CLAUDE.md, reglas de hooks y charts. Lee el skill SKILL-growth-marketing.md para entender los KPIs del Overview.

Ejecuta HU-008: Panel Overview.

1. src/lib/bigquery.ts: función bqQuery() que llama a supabase.functions.invoke('bq-query')
2. src/hooks/useBigQuery.ts, useOverview.ts: hooks con React Query, staleTime 5min
3. Componentes de charts:
   - KPICard.tsx: número grande + trend arrow (▲/▼) con % de cambio
   - SpendTrendChart.tsx: Recharts LineChart, dual axis (spend + conversions)
   - ChannelDonut.tsx: PieChart con labels de % y nombre
   - CampaignTable.tsx: tabla sorteable por columna
4. DateRangePicker.tsx: presets 7d, 30d, 90d, MTD, QTD
5. OverviewPanel.tsx: compone todo. Grid responsive.

Usa mock data mientras el backend no esté listo. Después conectamos.
```

---

## Reglas de operación durante el desarrollo

### 1. Un prompt = una HU

No mezcles HUs en un solo prompt. Si una HU es grande, puedes dividirla en 2 prompts, pero nunca combinar 2 HUs en 1.

### 2. Verificación al final de cada HU

Después de que Claude Code termine una HU, siempre pide:

```
Verifica lo que acabas de crear:
1. Ejecuta `npx tsc --noEmit` (TypeScript sin errores)
2. Confirma que cada archivo nuevo tiene sus imports correctos
3. Lista los archivos creados/modificados
```

### 3. Contexto se degrada — cuándo iniciar nueva sesión

Si llevas >15-20 prompts en una sesión de Claude Code, el contexto se degrada. Señales:
- Empieza a olvidar convenciones de CLAUDE.md
- Repite errores que ya corrigió
- Genera código que no sigue los patterns del proyecto

**Solución**: inicia nueva sesión. Claude Code releerá CLAUDE.md automáticamente.

### 4. Prompt de continuación al iniciar nueva sesión

Si necesitas continuar donde quedaste:

```
Lee CLAUDE.md. Estamos en Sprint X, trabajando en Track Y.
Ya completamos: [lista de HUs terminadas].
Ahora ejecuta HU-XXX: [nombre].
Revisa los archivos existentes en [ruta] antes de empezar para entender el contexto.
```

### 5. Branches por sprint

```bash
git checkout -b sprint-0/scaffold    # HU-001, HU-002
git checkout -b sprint-0/frontend    # HU-003
git checkout -b sprint-1/backend     # HU-004 a HU-007
git checkout -b sprint-1/frontend    # HU-008
# etc.
```

Merge a `main` al final de cada sprint, después de verificar.

### 6. Mock data para desacoplar frontend y backend

El frontend (Terminal 2) NO debe esperar al backend. Usa este pattern:

```typescript
// En desarrollo: mock data
// En producción: data real via proxy
const USE_MOCK = !import.meta.env.VITE_SUPABASE_URL;

export function useOverviewKPIs(days: number) {
  return useQuery({
    queryKey: ['overview-kpis', days],
    queryFn: () => USE_MOCK ? getMockKPIs(days) : bqQuery('overview_kpis', { days }),
    staleTime: 5 * 60 * 1000,
  });
}
```

---

## Checklist pre-inicio

- [ ] Node.js >= 18 instalado
- [ ] Git inicializado
- [ ] CLAUDE.md en la raíz del repo
- [ ] Skills copiados a .claude/skills/
- [ ] Supabase CLI instalado (`npm install -g supabase`)
- [ ] Cuenta de Supabase creada (para HU-002 en adelante)
- [ ] GCP project creado (para BigQuery, puede esperar a Sprint 1)
- [ ] Editor abierto en el directorio del proyecto

---

## Orden recomendado de las primeras 48 horas

```
Hora 0    → Crear repo, copiar docs, verificar entorno
Hora 0.5  → Terminal 3: HU-001 (scaffold)
Hora 3    → Terminal 3: HU-002 (SQL)  [en paralelo si quieres]
Hora 5    → Commit Sprint 0 parcial
Hora 5    → Terminal 2: HU-003 (auth + layout)
Hora 9    → Commit Sprint 0 completo. Merge a main.
Hora 9    → Terminal 1: HU-004 (shared ETL)
Hora 12   → Terminal 1: HU-005 (Google Ads) + Terminal 2: HU-008 (Overview con mock data)
Hora 15   → Terminal 1: HU-006 (GA4)
Hora 17   → Terminal 1: HU-007 (proxy) → Conectar frontend a data real
Hora 18   → Commit Sprint 1. Merge a main.
```

En ~18 horas de trabajo efectivo con Claude Code tienes el primer pipeline E2E funcionando.
