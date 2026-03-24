# HU-017: Provisioning scripts

**Sprint**: 4 — White-label + Multi-tenant (Semana 5)
**Track**: C (Infra/DevOps)
**Dependencias**: HU-002 (schemas), HU-001 (estructura)
**Consola sugerida**: Terminal 3 (Infra)

---

## Descripción

Scripts de provisioning automatizado para onboarding de nuevos clientes. Crea BigQuery dataset + tablas, ejecuta migrations de Supabase, registra tenant con branding, y verifica conexiones.

## Criterios de aceptación

- [ ] `provision.sh` ejecuta setup completo de nuevo cliente
- [ ] Crea BigQuery dataset + tablas
- [ ] Ejecuta Supabase migrations
- [ ] Registra tenant con branding
- [ ] Test de conexión

## Prompt para Claude Code

```
Lee CLAUDE.md y la sección de provisioning.

1. Crea provisioning/config/client-template.env con todas las variables documentadas: CLIENT_NAME, CLIENT_SLUG, GCP_PROJECT_ID, BQ_DATASET, SUPABASE_URL, SUPABASE keys, credenciales de canales (ENABLE_GA4, GA4_PROPERTY_ID, etc.), branding (BRAND_PRIMARY_COLOR, etc.), PLAN, FRONTEND_DOMAIN.

2. Crea provisioning/scripts/01-setup-bigquery.sh: auth con service account, bq mk dataset, ejecutar SQL files con sed para reemplazar placeholders.

3. Crea provisioning/scripts/02-setup-supabase.sh: psql contra SUPABASE_DB_URL, ejecutar migrations.

4. Crea provisioning/scripts/04-register-tenant.sh: curl POST a Supabase REST API para insertar en tenants + tenant_channels habilitados.

5. Crea provisioning/scripts/06-test-connections.sh: verificar que BigQuery responde, Supabase responde, tenant existe.

6. Crea provisioning/provision.sh: orquestador que source el .env y ejecuta los scripts en orden con output bonito.

Scripts deben ser idempotentes (no fallar si se corren 2 veces).
```

## Archivos a crear/modificar

- `provisioning/config/client-template.env`
- `provisioning/scripts/01-setup-bigquery.sh`
- `provisioning/scripts/02-setup-supabase.sh`
- `provisioning/scripts/04-register-tenant.sh`
- `provisioning/scripts/06-test-connections.sh`
- `provisioning/provision.sh`

## Estimación

~3-4 horas con Claude Code
