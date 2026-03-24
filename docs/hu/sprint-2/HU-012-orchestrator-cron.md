# HU-012: Orchestrator + Cron scheduling

**Sprint**: 2 — Canales Restantes (Semana 3)
**Track**: A (Backend/ETL)
**Dependencias**: HU-005, HU-006, HU-009, HU-010, HU-011 (conectores deben existir)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function orquestador que ejecuta todos los syncs activos de todos los tenants de forma secuencial. Incluye webhook para syncs on-demand y configuración de pg_cron.

## Criterios de aceptación

- [ ] `sync-orchestrator` ejecuta todos los syncs activos de todos los tenants
- [ ] Secuencial por canal, con 2s de espera entre cada uno
- [ ] Log de resultados agregado
- [ ] Cron configurado en Supabase (diario escalonado)

## Prompt para Claude Code

```
Lee CLAUDE.md.

1. Crea supabase/functions/sync-orchestrator/index.ts:
   - Query: todos los tenant_channels activos con sus tenants activos
   - Map channel_type → function name
   - Loop secuencial: invoke cada function con tenant_id + channel_id
   - 2s delay entre cada uno
   - Colecta resultados, retorna resumen

2. Crea supabase/functions/sync-webhook/index.ts:
   - Endpoint POST para trigger manual desde el dashboard
   - Recibe: {tenant_id, channel_id?} (si no channel_id, sync all del tenant)
   - Valida auth JWT
   - Invoca las funciones correspondientes
   - Retorna resultados

3. Documenta cómo configurar pg_cron en Supabase para:
   - 06:00 UTC: orchestrator (sync diario)
   - Cada 12h: token-refresh (renovar OAuth tokens)
```

## Archivos a crear/modificar

- `supabase/functions/sync-orchestrator/index.ts`
- `supabase/functions/sync-webhook/index.ts`

## Estimación

~2-3 horas con Claude Code
