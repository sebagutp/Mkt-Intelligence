# HU-020: Token refresh + health checks

**Sprint**: 5 — Polish + Reports + Deploy (Semana 6)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (credential manager), HU-012 (cron)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que renueva OAuth tokens antes de expirar (Google, Meta, LinkedIn) y realiza health checks de todos los canales para detectar credentials inválidas.

## Criterios de aceptación

- [ ] Edge Function `token-refresh` renueva OAuth tokens antes de que expiren
- [ ] Cron cada 12h
- [ ] Log de tokens renovados
- [ ] Health check: verifica que todos los canales tienen credentials válidas

## Prompt para Claude Code

```
Lee CLAUDE.md.

Crea supabase/functions/token-refresh/index.ts:

1. Query: todas las api_credentials con expires_at < now() + 7 days
2. Por cada credential que va a expirar:
   - Si Google (Ads/GA4): POST a https://oauth2.googleapis.com/token con refresh_token
   - Si Meta: POST a https://graph.facebook.com/v19.0/oauth/access_token para exchange long-lived
   - Si LinkedIn: POST a https://www.linkedin.com/oauth/v2/accessToken con refresh_token
3. Actualizar encrypted_value y expires_at en api_credentials
4. Log resultado

Health check adicional: query sync_logs, si algún canal no tiene success en últimas 36h, alertar.
```

## Archivos a crear/modificar

- `supabase/functions/token-refresh/index.ts`

## Estimación

~2-3 horas con Claude Code
