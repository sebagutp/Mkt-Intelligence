# HU-015: Sistema de alertas

**Sprint**: 3 — Intelligence (Semana 4)
**Track**: A (Backend/ETL)
**Dependencias**: HU-004 (BigQuery client), HU-012 (orchestrator para trigger post-sync)
**Consola sugerida**: Terminal 1 (Backend)

---

## Descripción

Edge Function que evalúa reglas de alerta configuradas por tenant, ejecuta queries en BigQuery para detectar condiciones, y envía notificaciones via Slack webhook y/o email.

## Criterios de aceptación

- [ ] Edge Function `alert-dispatcher` evalúa reglas de `alert_rules`
- [ ] Envía a Slack webhook y/o email cuando se dispara
- [ ] Se ejecuta post-sync (trigger en sync_logs)

## Prompt para Claude Code

```
Lee CLAUDE.md.

1. Crea supabase/functions/alert-dispatcher/index.ts:
   - Lee alert_rules activas del tenant
   - Para cada regla: ejecuta query en BigQuery para evaluar la condición
   - Si condition met: envía notificación
   - Slack: POST al webhook URL con formatted message (canal, métrica, valor, threshold)
   - Email: usa Supabase built-in email o Resend API
   - Guarda log de alerta enviada

2. Tipos de condiciones soportadas:
   - 'above': metric > threshold (ej: CPA > $50)
   - 'below': metric < threshold (ej: ROAS < 1.0)
   - 'change_pct': |metric - avg_window| / avg_window > threshold (ej: CPA subió >25% vs 7d)

3. Trigger: se ejecuta cuando sync_logs inserta un row con status='success' (via database webhook o invocación desde orchestrator post-sync).
```

## Archivos a crear/modificar

- `supabase/functions/alert-dispatcher/index.ts`

## Estimación

~2-3 horas con Claude Code
