# HU-018: Settings de branding + preview

**Sprint**: 4 — White-label + Multi-tenant (Semana 5)
**Track**: B (Frontend)
**Dependencias**: HU-003 (TenantProvider), HU-016 (Settings page)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Sección de branding en Settings que permite a admins personalizar colores, logo y nombre del producto con preview en tiempo real. Solo visible para usuarios con rol admin.

## Criterios de aceptación

- [ ] En Settings, sección "Branding" muestra config actual
- [ ] Preview live: cambiar color y ver efecto inmediato
- [ ] Solo admins pueden editar branding
- [ ] Guardar actualiza Supabase y re-aplica CSS vars

## Prompt para Claude Code

```
Lee CLAUDE.md.

Actualiza SettingsPage.tsx con sección "Branding" (solo visible si role=admin):

1. Form con campos: Product Name (text), Logo URL (text+preview img), Primary Color (color picker), Accent Color (color picker), Support Email (text)

2. Preview: mientras el usuario cambia valores, aplicar en tiempo real via CSS vars en document.documentElement. Mostrar un mini-preview del sidebar con los colores.

3. Save: PATCH a supabase tenants.branding JSONB. Mostrar toast de confirmación.

4. Reset: botón para volver a valores guardados (descartar cambios).

Usar form state local, no React Query mutations para el preview live. Solo guardar cuando el usuario hace click en Save.
```

## Archivos a crear/modificar

- `src/pages/SettingsPage.tsx`

## Estimación

~2-3 horas con Claude Code
