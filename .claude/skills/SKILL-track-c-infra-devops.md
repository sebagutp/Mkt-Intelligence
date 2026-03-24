# Skill: Track C — Infra/DevOps (BigQuery + Supabase + Provisioning)

## Contexto

Este skill aplica a todas las HUs del Track C: setup de infraestructura (BigQuery, Supabase), provisioning automatizado de nuevos clientes, y deploy a producción. Es el track que habilita a los otros dos.

**HUs cubiertas**: HU-001, HU-002, HU-017, HU-021

---

## Reglas obligatorias

### BigQuery

1. **Particionamiento obligatorio**: `marketing_metrics` particionada por `metric_date` con `require_partition_filter = true`.
2. **Clustering**: por `channel` en todas las tablas principales.
3. Schemas con placeholders `{{PROJECT_ID}}` y `{{DATASET}}` para reutilización multi-tenant.
4. TODA query debe incluir filtro de fecha. Sin excepción.
5. Usar `SAFE_DIVIDE()` en todas las métricas calculadas.
6. Free tier: 10GB almacenamiento + 1TB queries/mes. Diseñar queries eficientes.

### Supabase

7. **Migrations numeradas**: `YYYYMMDDHHMMSS_nombre.sql`. Siempre incrementales.
8. **RLS en TODAS las tablas** con `tenant_id`. Función helper: `auth.user_tenant_ids()`.
9. Service role key solo en Edge Functions (server-side). NUNCA en frontend.
10. Anon key en frontend. RLS protege los datos.
11. Funciones RPC: `get_my_tenant()`, `log_sync()`, `get_last_sync_date()`.

### Estructura del proyecto

12. Monorepo con workspaces: `apps/dashboard` como workspace principal.
13. TypeScript estricto en todo el proyecto. `strict: true`.
14. Archivos en kebab-case. Componentes React en PascalCase.
15. Crear TODOS los archivos placeholder según la estructura de CLAUDE.md.

### Provisioning

16. Scripts DEBEN ser **idempotentes** (no fallar si se corren 2 veces).
17. Template `.env` con TODAS las variables documentadas.
18. Flujo: `provision.sh` → scripts numerados en orden → test de conexión.
19. Variables sensibles NUNCA commiteadas. Carpeta `clients/` en `.gitignore`.
20. Cada script hace una sola cosa y la hace bien.

### Deploy

21. Frontend: static build en Vercel o Cloudflare Pages.
22. Edge Functions: `supabase functions deploy`.
23. DNS: CNAME para custom domain del cliente.
24. Cron: `pg_cron` en Supabase para syncs diarios y token refresh.
25. CORS configurado solo para dominios del tenant.

---

## Patrones de código

### Migration de Supabase

```sql
-- supabase/migrations/20260323000001_core_tables.sql

-- Tabla de tenants
CREATE TABLE IF NOT EXISTS public.tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  plan TEXT NOT NULL DEFAULT 'starter',
  bq_project_id TEXT NOT NULL,
  bq_dataset TEXT NOT NULL,
  branding JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Siempre agregar índices para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON public.tenants(slug);
CREATE INDEX IF NOT EXISTS idx_tenants_active ON public.tenants(is_active) WHERE is_active = true;
```

### RLS Policy

```sql
-- supabase/migrations/20260323000002_rls_policies.sql

-- Función helper para obtener tenant_ids del usuario
CREATE OR REPLACE FUNCTION auth.user_tenant_ids()
RETURNS SETOF UUID AS $$
  SELECT tenant_id FROM public.tenant_users
  WHERE user_id = auth.uid() AND is_active = true;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Policy en cada tabla
ALTER TABLE public.tenant_channels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tenant_isolation" ON public.tenant_channels
  FOR ALL USING (tenant_id IN (SELECT auth.user_tenant_ids()));
```

### Schema BigQuery

```sql
-- bigquery/schemas/marketing_metrics.sql
CREATE TABLE IF NOT EXISTS `{{PROJECT_ID}}.{{DATASET}}.marketing_metrics` (
  tenant_id STRING NOT NULL,
  channel STRING NOT NULL,
  metric_date DATE NOT NULL,
  source_campaign_id STRING,
  campaign_name STRING,
  impressions INT64 DEFAULT 0,
  clicks INT64 DEFAULT 0,
  spend FLOAT64 DEFAULT 0.0,
  conversions FLOAT64 DEFAULT 0.0,
  conversion_value FLOAT64 DEFAULT 0.0,
  ctr FLOAT64,
  cpc FLOAT64,
  cpa FLOAT64,
  roas FLOAT64,
  extra_metrics JSON,
  synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY metric_date
CLUSTER BY channel
OPTIONS (
  require_partition_filter = true
);
```

### Script de provisioning

```bash
#!/bin/bash
# provisioning/scripts/01-setup-bigquery.sh
set -euo pipefail

echo "=== Setting up BigQuery dataset: ${BQ_DATASET} ==="

# Idempotente: --exists_ok
bq mk --dataset \
  --description "MIH data for ${CLIENT_NAME}" \
  --location US \
  "${GCP_PROJECT_ID}:${BQ_DATASET}" || true

# Crear tablas con sed para reemplazar placeholders
for schema in bigquery/schemas/*.sql; do
  echo "Creating table from ${schema}..."
  sed -e "s/{{PROJECT_ID}}/${GCP_PROJECT_ID}/g" \
      -e "s/{{DATASET}}/${BQ_DATASET}/g" \
      "${schema}" | bq query --use_legacy_sql=false
done

echo "=== BigQuery setup complete ==="
```

---

## Variables de entorno requeridas

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

# Provisioning (clients/xxx.env)
CLIENT_NAME=Datawalt
CLIENT_SLUG=datawalt
GCP_PROJECT_ID=mih-datawalt-prod
BQ_DATASET=mih_datawalt
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_DB_URL=postgresql://...
BRAND_PRIMARY_COLOR=#2563EB
BRAND_ACCENT_COLOR=#7C3AED
PLAN=pro
FRONTEND_DOMAIN=analytics.datawalt.com
```

---

## Checklist pre-PR para Track C

- [ ] Migrations numeradas con timestamp correcto
- [ ] RLS habilitado en toda tabla nueva con tenant_id
- [ ] BigQuery schemas con PARTITION + CLUSTER
- [ ] Placeholders {{PROJECT_ID}}/{{DATASET}} en schemas
- [ ] Scripts de provisioning son idempotentes
- [ ] Variables sensibles no committeadas
- [ ] `npm run dev` funciona sin errores tras scaffold
- [ ] Test de conexión pasa (BigQuery + Supabase)
