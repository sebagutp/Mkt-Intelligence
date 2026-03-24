# Deploy a Producción — Datawalt

Checklist completo para deploy del primer cliente (Datawalt).

---

## 1. Pre-deploy Checks

- [ ] TypeScript compila sin errores: `cd apps/dashboard && npx tsc --noEmit`
- [ ] Build de frontend exitoso: `npm run build`
- [ ] Data de últimos 7 días validada vs plataformas originales (±5% tolerance):
  - [ ] GA4: comparar sessions/pageviews en BQ vs GA4 dashboard
  - [ ] Google Ads: comparar spend/conversions en BQ vs Google Ads UI
  - [ ] Meta Ads: comparar spend/reach en BQ vs Meta Ads Manager
  - [ ] Email: comparar opens/clicks en BQ vs Mailchimp/Brevo
  - [ ] LinkedIn: comparar impressions/clicks en BQ vs LinkedIn Campaign Manager
- [ ] Branding de Datawalt configurado en `dashboard_configs`
- [ ] Todos los OAuth tokens activos (`token_expires_at > now() + 7 days`)
- [ ] Token refresh Edge Function testeada manualmente
- [ ] Alert rules configuradas para todos los canales

## 2. Supabase Deploy

```bash
# Conectar al proyecto de producción
npx supabase link --project-ref <DATAWALT_PROJECT_REF>

# Aplicar migraciones a producción
npx supabase db push

# Verificar migraciones aplicadas
npx supabase migration list
```

- [ ] Migraciones aplicadas correctamente
- [ ] RLS policies activas en todas las tablas
- [ ] RPCs (`get_my_tenant`, `log_sync`, `get_last_sync_date`) funcionando

## 3. Edge Functions Deploy

```bash
# Deploy todas las Edge Functions
npx supabase functions deploy bq-query
npx supabase functions deploy sync-ga4
npx supabase functions deploy sync-google-ads
npx supabase functions deploy sync-meta-ads
npx supabase functions deploy sync-email
npx supabase functions deploy sync-linkedin
npx supabase functions deploy sync-orchestrator
npx supabase functions deploy sync-webhook
npx supabase functions deploy token-refresh
npx supabase functions deploy alert-dispatcher
```

- [ ] Todas las funciones deployadas sin error
- [ ] Variables de entorno configuradas en Supabase dashboard:
  - `BQ_PROJECT_ID`
  - `BQ_DATASET`
  - `BQ_SERVICE_ACCOUNT_JSON`
  - `GOOGLE_OAUTH_CLIENT_ID`
  - `GOOGLE_OAUTH_CLIENT_SECRET`
  - `GOOGLE_ADS_DEV_TOKEN`
  - `META_APP_ID`
  - `META_APP_SECRET`

## 4. Frontend Deploy (Vercel)

```bash
cd apps/dashboard

# Crear .env.production
cat > .env.production << EOF
VITE_SUPABASE_URL=https://<ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
EOF

# Build
npm run build

# Deploy
vercel --prod
```

- [ ] Build sin errores ni warnings relevantes
- [ ] Deploy exitoso a Vercel
- [ ] URL de preview funciona antes de asignar dominio

## 5. Custom Domain + DNS

```
# En Vercel: Settings → Domains → Add
analytics.datawalt.com

# En DNS del cliente (Cloudflare / Route53 / etc):
CNAME analytics.datawalt.com → cname.vercel-dns.com
```

- [ ] Custom domain configurado en Vercel
- [ ] DNS CNAME apuntando a `cname.vercel-dns.com`
- [ ] SSL/HTTPS automático verificado (Vercel lo genera)
- [ ] Redirect HTTP → HTTPS funcionando

## 6. Cron Jobs (Supabase)

Activar en Supabase Dashboard → Database → Extensions → `pg_cron`:

```sql
-- Sync diario a las 6 AM UTC (escalonado por canal)
SELECT cron.schedule('sync-orchestrator', '0 6 * * *',
  $$SELECT net.http_post(
    'https://<ref>.supabase.co/functions/v1/sync-orchestrator',
    '{}',
    'application/json',
    ARRAY[http_header('Authorization', 'Bearer <service-role-key>')]
  )$$
);

-- Token refresh cada 12h
SELECT cron.schedule('token-refresh', '0 */12 * * *',
  $$SELECT net.http_post(
    'https://<ref>.supabase.co/functions/v1/token-refresh',
    '{}',
    'application/json',
    ARRAY[http_header('Authorization', 'Bearer <service-role-key>')]
  )$$
);
```

- [ ] `pg_cron` extension habilitada
- [ ] `pg_net` extension habilitada (para http_post)
- [ ] Cron de sync-orchestrator activo
- [ ] Cron de token-refresh activo

## 7. Primer Sync Manual

```bash
# Trigger sync completo
curl -X POST \
  "https://<ref>.supabase.co/functions/v1/sync-orchestrator" \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{"full_sync": true}'
```

- [ ] Sync ejecutado sin errores
- [ ] Verificar `sync_logs` en Supabase: todos los canales con status `success`
- [ ] Verificar data en BigQuery: `SELECT COUNT(*) FROM marketing_metrics WHERE metric_date >= CURRENT_DATE - 30`
- [ ] Dashboard muestra data real en Overview

## 8. Crear Usuario Admin

En Supabase Dashboard → Authentication → Users:

1. Invitar usuario con email del admin de Datawalt
2. Asignar a tenant:

```sql
INSERT INTO tenant_users (tenant_id, user_id, role)
VALUES (
  (SELECT id FROM tenants WHERE slug = 'datawalt'),
  (SELECT id FROM auth.users WHERE email = 'admin@datawalt.com'),
  'owner'
);
```

- [ ] Usuario creado y puede hacer login
- [ ] Dashboard carga con branding correcto
- [ ] Todos los canales muestran data

## 9. Post-deploy Monitoring (3 días)

### Día 1
- [ ] Verificar que cron de sync-orchestrator corrió a las 6 AM UTC
- [ ] Verificar `sync_logs`: todos los canales success
- [ ] Verificar data nueva en dashboard (fecha de hoy)
- [ ] Verificar que token-refresh corrió (2 ejecuciones en 24h)

### Día 2
- [ ] Repetir verificaciones del Día 1
- [ ] Comparar métricas de ayer vs plataformas originales (±5%)
- [ ] Verificar alertas si hay anomalías

### Día 3
- [ ] Repetir verificaciones
- [ ] Si todo OK: marcar proyecto como "stable"
- [ ] Entregar acceso al cliente final

## 10. Rollback Plan

Si algo falla crítico:

1. **Frontend**: `vercel rollback` o apuntar DNS a versión anterior
2. **Edge Functions**: `npx supabase functions deploy <fn> --version <prev>`
3. **Database**: restaurar desde backup automático de Supabase (máx 7 días)
4. **BigQuery**: data es append-only, no requiere rollback

## Contactos

| Rol | Quién | Canal |
|-----|-------|-------|
| DevOps | — | — |
| DBA | — | — |
| Cliente (Datawalt) | — | — |
