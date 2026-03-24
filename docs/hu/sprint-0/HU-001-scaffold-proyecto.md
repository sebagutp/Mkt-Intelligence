# HU-001: Scaffold del proyecto completo

**Sprint**: 0 — Scaffold + Infra Base (Semana 1)
**Track**: C (Infra/DevOps)
**Dependencias**: Ninguna (primera HU)
**Consola sugerida**: Terminal 1 (Infra)

---

## Descripción

Inicializar el monorepo completo con toda la estructura de carpetas según CLAUDE.md. Configurar Vite + React + TypeScript + TailwindCSS en el dashboard. Crear todos los archivos placeholder.

## Criterios de aceptación

- [ ] Monorepo con estructura de carpetas según CLAUDE.md
- [ ] `apps/dashboard/` con Vite + React + TS + Tailwind configurado
- [ ] `supabase/` con config.toml inicializado
- [ ] `bigquery/` con SQL schemas listos
- [ ] `provisioning/` con template de .env
- [ ] `npm run dev` levanta el frontend sin errores

## Prompt para Claude Code

```
Lee CLAUDE.md completo. Crea la estructura de carpetas exacta del proyecto según la sección "Estructura del proyecto". Inicializa:

1. Root: package.json con workspaces, tsconfig base
2. apps/dashboard: npm create vite@latest con React + TypeScript. Instala dependencias: react-router-dom, @supabase/supabase-js, @tanstack/react-query, recharts, tailwindcss, autoprefixer, postcss, date-fns, lucide-react. Configura tailwind con dark mode 'class'. Crea index.css con imports de Tailwind + CSS variables de branding (--brand-primary, --brand-accent)
3. Crea todos los archivos vacíos (con exports placeholder) para types/, lib/, providers/, hooks/, components/ según la estructura
4. supabase/: crea config.toml básico
5. bigquery/schemas/: copia los 3 SQL files de marketing_metrics, campaign_details, channel_daily_summary
6. provisioning/: crea client-template.env y provision.sh skeleton

Asegúrate que npm run dev funcione sin errores mostrando una página "MIH - Setup Complete".
```

## Archivos a crear/modificar

- `package.json` (root)
- `tsconfig.json` (root)
- `apps/dashboard/*` (scaffold completo)
- `supabase/config.toml`
- `bigquery/schemas/*.sql`
- `provisioning/config/client-template.env`
- `provisioning/provision.sh`

## Estimación

~2-3 horas con Claude Code
