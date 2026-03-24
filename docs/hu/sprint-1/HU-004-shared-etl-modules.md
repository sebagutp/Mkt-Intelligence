# HU-004: Shared ETL modules

**Sprint**: 1 — Primer Pipeline E2E (Semana 2)
**Track**: A (Backend/ETL)
**Dependencias**: HU-002 (schemas de BigQuery y Supabase deben existir)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Crear los módulos compartidos del ETL: BigQuery client con auth JWT, ConnectorBase abstracto con retry exponencial y logging, tipos compartidos, y credential manager.

## Criterios de aceptación

- [ ] `_shared/bigquery-client.ts` autentica con Service Account y puede insertar rows + ejecutar queries
- [ ] `_shared/connector-base.ts` implementa el patrón completo: get creds → get date range → fetch → normalize → insert → log
- [ ] `_shared/types.ts` define NormalizedRow, SyncResult, Credentials
- [ ] Tests manuales: insertar una row de prueba en BigQuery y leerla de vuelta

## Prompt para Claude Code

```
Lee CLAUDE.md, especialmente las reglas de Edge Functions.

1. Crea supabase/functions/_shared/types.ts con interfaces: NormalizedRow (todos los campos de marketing_metrics), SyncResult (success, rowsSynced, durationMs, error?), Credentials (encrypted_value, refresh_token, metadata, expires_at).

2. Crea supabase/functions/_shared/bigquery-client.ts: clase BigQueryClient con constructor(projectId, dataset, serviceAccountJson). Métodos:
   - getAccessToken(): genera JWT con la private key del Service Account, intercambia por access token con Google OAuth. Cache del token hasta expiry.
   - insertRows(table, rows): POST a BigQuery insertAll API. Usa row._dedup_key como insertId. Batch de 500 rows. Manejo de errores insertErrors.
   - query(sql, maxResults): POST a BigQuery queries API. Retorna rows parseadas.
   Helper privados: pemToBuffer, bufferToBase64url para crypto.subtle.

3. Crea supabase/functions/_shared/connector-base.ts: clase abstracta ConnectorBase con:
   - Constructor: recibe tenantId, channelId, config (urls + keys)
   - execute(): método principal que orquesta todo el flujo
   - fetchWithRetry(): retry exponencial 3 intentos
   - Métodos abstractos: fetchData(), normalize()
   - Helpers: dedupKey(), uuid(), supabase client
   - Logging: llama a supabase.rpc('log_sync') siempre (success o error)

4. Crea supabase/functions/_shared/credential-manager.ts: lee credentials de api_credentials table por channel_id.

Usa Deno APIs (crypto.subtle, fetch). Todos los imports con URLs de esm.sh.
```

## Archivos a crear/modificar

- `supabase/functions/_shared/types.ts`
- `supabase/functions/_shared/bigquery-client.ts`
- `supabase/functions/_shared/connector-base.ts`
- `supabase/functions/_shared/credential-manager.ts`
- `supabase/functions/_shared/normalizer.ts`

## Estimación

~3-4 horas con Claude Code
