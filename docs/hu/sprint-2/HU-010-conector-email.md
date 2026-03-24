# HU-010: Conector Email (multi-provider)

**Sprint**: 2 — Canales Restantes (Semana 3)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (ConnectorBase)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function router que delega a sub-conectores según el provider configurado del canal. Implementa sub-conectores para Mailchimp, Webhook (Apps Script), y CSV.

## Criterios de aceptación

- [ ] Router que delega a sub-conector según `config.provider` del canal
- [ ] Sub-conector Mailchimp implementado (GET /reports)
- [ ] Sub-conector Webhook implementado (recibe POST con métricas)
- [ ] Sub-conector CSV implementado (parsea CSV con formato estándar)

## Prompt para Claude Code

```
Lee CLAUDE.md. El conector de email es especial: es un router que delega según el provider.

Crea supabase/functions/sync-email/index.ts:

1. serve() handler que lee config del canal desde Supabase para obtener provider
2. Switch por provider:
   - 'mailchimp': instanciar MailchimpConnector
   - 'brevo': instanciar BrevoConnector
   - 'webhook': instanciar WebhookConnector
   - 'csv': instanciar CSVConnector

3. MailchimpConnector extends ConnectorBase:
   - fetchData(): GET https://{dc}.api.mailchimp.com/3.0/reports con API key auth (Basic). dc viene del API key (último segmento después del guión). Paginación con offset+count.
   - normalize(): emails_sent→impressions, unique_opens→clicks, spend=0. extra_metrics: {open_rate, click_rate, unsubscribe_count, bounce_count, subject_line, list_id}

4. WebhookConnector (para clientes con Apps Script o custom):
   - No hace fetch. Lee el body del request que ya trae las métricas.
   - Formato esperado: { campaigns: [{name, date, sent, opens, clicks, bounces, unsubs}] }
   - Normaliza e inserta.

5. CSVConnector:
   - Lee file del body (base64 o text)
   - Parsea CSV con columnas: date, campaign_name, sent, opens, clicks, bounces, unsubscribes
   - Normaliza e inserta.

Cada sub-conector sigue las mismas reglas: extiende ConnectorBase, usa retry, log_sync, etc.
```

## Archivos a crear/modificar

- `supabase/functions/sync-email/index.ts`

## Estimación

~3-4 horas con Claude Code
