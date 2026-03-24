# HU-003: Auth + Tenant Provider + Layout base

**Sprint**: 0 — Scaffold + Infra Base (Semana 1)
**Track**: B (Frontend)
**Dependencies**: HU-001 (scaffold debe existir primero)
**Consola sugerida**: Terminal 1 (Frontend)

---

## Descripción

Implementar autenticación con Supabase Auth, TenantProvider que carga config y aplica branding dinámico, y el layout base del dashboard (Sidebar + Header + routing protegido).

## Criterios de aceptación

- [ ] Login page funcional con Supabase Auth (email/password)
- [ ] TenantProvider carga config del tenant y aplica branding (CSS vars, favicon, title)
- [ ] AppLayout con Sidebar + Header renderiza correctamente
- [ ] Ruta protegida: si no hay sesión, redirect a login
- [ ] Dark mode funciona

## Prompt para Claude Code

```
Lee CLAUDE.md, sección de providers y layout.

1. Crea src/lib/supabase.ts: inicializa cliente Supabase con env vars VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY

2. Crea src/providers/AuthProvider.tsx: context con session, user, signIn, signOut. Usa supabase.auth.onAuthStateChange para mantener sesión reactiva.

3. Crea src/providers/TenantProvider.tsx: después de auth, llama supabase.rpc('get_my_tenant'). Guarda TenantConfig en context. Aplica branding: CSS variables en document.documentElement, favicon, document.title. Mientras carga, muestra LoadingSkeleton.

4. Crea src/providers/QueryProvider.tsx: React Query client con defaultOptions: staleTime 5min, refetchOnWindowFocus false.

5. Crea src/components/layout/AppLayout.tsx: Sidebar izquierda (colapsable en mobile) con nav items: Overview, Channels (submenu por canal activo), Insights, Reports, Settings. Header con logo del tenant, nombre del producto, avatar del usuario con dropdown de logout. Content area con Outlet de React Router.

6. Crea src/components/layout/Sidebar.tsx: items con iconos de lucide-react. Highlight item activo. Mostrar canales del tenant dinámicamente desde TenantProvider.

7. Crea src/pages/LoginPage.tsx: form con email + password. Estilo limpio, centrado, logo del tenant si está disponible.

8. Crea src/router.tsx: React Router con rutas protegidas (RequireAuth wrapper). / → Dashboard, /channel/:type → ChannelDetail, /insights, /reports, /settings, /login.

9. Crea src/App.tsx: monta providers en orden: QueryProvider > AuthProvider > TenantProvider > RouterProvider.

Usa Tailwind para todo el styling. Dark mode con dark: variants. Mobile responsive.
```

## Archivos a crear/modificar

- `src/lib/supabase.ts`
- `src/providers/AuthProvider.tsx`
- `src/providers/TenantProvider.tsx`
- `src/providers/QueryProvider.tsx`
- `src/components/layout/AppLayout.tsx`
- `src/components/layout/Sidebar.tsx`
- `src/components/layout/Header.tsx`
- `src/components/layout/MobileNav.tsx`
- `src/pages/LoginPage.tsx`
- `src/router.tsx`
- `src/App.tsx`

## Estimación

~3-4 horas con Claude Code
