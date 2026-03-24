# HU-021: Deploy producción Datawalt

**Sprint**: 5 — Polish + Reports + Deploy (Semana 6)
**Track**: C (Infra/DevOps)
**Dependencias**: TODAS las HUs anteriores
**Consola sugerida**: Terminal 3 (Infra)

---

## Descripción

Checklist y documentación para el deploy a producción del primer cliente (Datawalt). Incluye validación de data, deploy de frontend a Vercel, Edge Functions a Supabase, configuración DNS, y monitoring post-deploy.

## Criterios de aceptación

- [ ] Frontend deployado en Vercel/CF Pages
- [ ] Edge Functions deployadas en Supabase producción
- [ ] DNS configurado para analytics.datawalt.com
- [ ] Cron jobs activos
- [ ] Data real fluyendo de los 5 canales
- [ ] Todos los KPIs validados vs plataformas originales

## Prompt para Claude Code

```
Esto es más un checklist que código. Documentar en docs/deploy-production.md:

1. Pre-deploy checks:
   - [ ] Todos los tests pasan
   - [ ] Data de últimos 7 días validada vs GA4, Google Ads, Meta Ads originales (±5% tolerance)
   - [ ] Branding de Datawalt configurado correctamente
   - [ ] Todos los OAuth tokens activos y con refresh configurado

2. Deploy steps:
   - [ ] supabase db push (migrations a producción)
   - [ ] supabase functions deploy (todas las Edge Functions)
   - [ ] npm run build en apps/dashboard
   - [ ] Deploy static build a Vercel: vercel --prod
   - [ ] Configurar custom domain en Vercel
   - [ ] DNS: CNAME analytics.datawalt.com → cname.vercel-dns.com
   - [ ] Verificar SSL/HTTPS funciona
   - [ ] Activar cron jobs en Supabase dashboard
   - [ ] Trigger primer sync manual completo
   - [ ] Verificar data en dashboard

3. Post-deploy monitoring:
   - [ ] Verificar sync logs diarios por 3 días
   - [ ] Verificar alertas llegan a Slack
   - [ ] Verificar token refresh funciona
```

## Archivos a crear/modificar

- `docs/deploy-production.md`

## Estimación

~2-3 horas con Claude Code
