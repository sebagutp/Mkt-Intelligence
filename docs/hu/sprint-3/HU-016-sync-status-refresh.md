# HU-016: Sync status + manual refresh

**Sprint**: 3 — Intelligence (Semana 4)
**Track**: B (Frontend)
**Dependencias**: HU-012 (sync-webhook), HU-003 (Settings page)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Sección en Settings que muestra el estado de sincronización de cada canal con badges de estado, timestamps, y botones para trigger manual de sync.

## Criterios de aceptación

- [ ] En Settings, sección "Data Sources" muestra estado de cada canal
- [ ] Badge verde/amarillo/rojo por último sync status
- [ ] Timestamp de último sync
- [ ] Botón "Sync now" que triggerea sync manual

## Prompt para Claude Code

```
Lee CLAUDE.md.

1. Crea src/hooks/useSyncStatus.ts: query a tenant_channels con last_sync_at y last_sync_status. Usar Supabase realtime para actualizaciones live.

2. Actualiza SettingsPage.tsx con sección "Data Sources":
   - Lista de canales del tenant
   - Por cada canal: icono, nombre, StatusBadge (green=success, amber=running, red=error), timestamp "Last sync: 2h ago"
   - Botón "Sync now" por canal que llama a supabase.functions.invoke('sync-webhook', {body: {tenant_id, channel_id}})
   - Botón "Sync all" que llama sin channel_id
   - Mostrar spinner mientras el sync corre

3. Crea src/components/shared/StatusBadge.tsx: pill con dot colored + texto. Props: status ('success'|'error'|'running'|'partial'), size.
```

## Archivos a crear/modificar

- `src/hooks/useSyncStatus.ts`
- `src/components/shared/StatusBadge.tsx`
- `src/pages/SettingsPage.tsx`

## Estimación

~2-3 horas con Claude Code
