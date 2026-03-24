# Skill: Track B — Frontend (React SPA + Dashboard)

## Contexto

Este skill aplica a todas las HUs del Track B: desarrollo del dashboard React SPA con Vite, TailwindCSS, Recharts, React Query y Supabase Auth. Incluye layout, charts, paneles, insights y settings.

**HUs cubiertas**: HU-003, HU-008, HU-013, HU-014, HU-016, HU-018, HU-019

---

## Reglas obligatorias

### Arquitectura de componentes

1. **Un componente por archivo**. Máximo 200 líneas — si crece, splitear.
2. Archivos en `kebab-case`. Componentes React en `PascalCase`.
3. Imports absolutos con `@/` alias apuntando a `src/`.
4. Componentes de charts son **genéricos**: reciben `data` tipada, NO saben de BigQuery.
5. Toda data del dashboard viene via hooks de `hooks/`. Los hooks llaman a `lib/bigquery.ts`.

### Data fetching

6. `lib/bigquery.ts` NUNCA ejecuta SQL directo a BigQuery. Solo llama al proxy `bq-query` via `supabase.functions.invoke()`.
7. React Query con `staleTime: 5 * 60 * 1000` (5 min) para queries de BQ.
8. `refetchOnWindowFocus: false` como default global.
9. Cada hook exporta funciones con nombres descriptivos: `useOverviewKPIs(days)`, `useDailyTrend(days)`, etc.
10. Query keys deben incluir todos los params: `['overview-kpis', days]`.

### Styling y branding

11. **TailwindCSS para todo**. No CSS modules, no styled-components.
12. Colores de branding via CSS variables `--brand-primary` y `--brand-accent`. NO hardcodear colores del tenant.
13. Dark mode: usar `dark:` variants de Tailwind. Probar ambos modos.
14. **Mobile first**. Breakpoints: `sm:640px`, `md:768px`, `lg:1024px`.

### UX patterns

15. **Loading states**: SIEMPRE Skeleton (`LoadingSkeleton.tsx`), NUNCA spinner (excepto para acciones como sync).
16. **Empty states**: SIEMPRE `EmptyState.tsx` con guía de acción, NUNCA pantalla vacía.
17. Iconos: `lucide-react`. Iconos de canal: `ChannelIcon.tsx` con SVGs simples.
18. Color coding para métricas: verde = bueno (ROAS alto, CPA bajo), rojo = malo, amber = warning.

### Auth y multi-tenant

19. Supabase Auth: email/password + magic link.
20. JWT para identificar tenant. `TenantProvider` carga config y aplica branding.
21. Rutas protegidas con `RequireAuth` wrapper en el router.
22. Anon key en frontend. RLS protege los datos. Service role key NUNCA en frontend.

### TypeScript

23. TypeScript estricto. `strict: true`. NO usar `any`.
24. Tipos en `src/types/`: `tenant.ts`, `metrics.ts`, `campaign.ts`, `sync.ts`.
25. Props de componentes siempre tipadas con interface.

---

## Patrones de código

### Hook de data

```typescript
// src/hooks/useOverview.ts
import { useQuery } from '@tanstack/react-query';
import { bqQuery } from '@/lib/bigquery';
import type { ChannelSummary } from '@/types/metrics';

export function useOverviewKPIs(days: number) {
  return useQuery({
    queryKey: ['overview-kpis', days],
    queryFn: () => bqQuery<ChannelSummary>('overview_kpis', { days: String(days) }),
    staleTime: 5 * 60 * 1000,
  });
}
```

### Componente de chart genérico

```typescript
// src/components/charts/KPICard.tsx
interface KPICardProps {
  label: string;
  value: number;
  previousValue?: number;
  format: 'currency' | 'number' | 'percent';
}

export function KPICard({ label, value, previousValue, format }: KPICardProps) {
  // Componente puro, no sabe de BigQuery
  const formatted = formatValue(value, format);
  const delta = previousValue ? ((value - previousValue) / previousValue) * 100 : null;
  // ...
}
```

### Panel (composición)

```typescript
// src/components/panels/OverviewPanel.tsx
export function OverviewPanel() {
  const [days, setDays] = useState(30);
  const { data: kpis, isLoading: kpisLoading } = useOverviewKPIs(days);
  const { data: trend, isLoading: trendLoading } = useDailyTrend(days);

  return (
    <div className="space-y-6">
      <DateRangePicker value={days} onChange={setDays} />
      {kpisLoading ? <LoadingSkeleton type="kpi-grid" /> : <KPIGrid data={kpis} />}
      {trendLoading ? <LoadingSkeleton type="chart" /> : <SpendTrendChart data={trend} />}
    </div>
  );
}
```

### Responsive layout

```typescript
// Grid patterns
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"> {/* KPI cards */}
<div className="grid grid-cols-1 md:grid-cols-2 gap-6"> {/* Charts side by side */}
<div className="overflow-x-auto"> {/* Tables en mobile */}
```

---

## Estructura de archivos por panel

```
src/
├── hooks/useXxx.ts          ← Data fetching (React Query)
├── components/
│   ├── charts/XxxChart.tsx  ← Componente visual puro
│   ├── panels/XxxPanel.tsx  ← Composición de charts + hooks
│   └── shared/Widget.tsx    ← Componentes reutilizables
└── pages/XxxPage.tsx        ← Wrapper mínimo: layout + panel
```

---

## Checklist pre-PR para Track B

- [ ] Componente < 200 líneas
- [ ] Props tipadas con interface (no `any`)
- [ ] Data via hooks, no directo en componentes
- [ ] Loading skeleton en cada sección
- [ ] Empty state con guía de acción
- [ ] Responsive: funciona en mobile (< 640px)
- [ ] Dark mode: probado con `dark:` variants
- [ ] Branding: usa CSS vars, no colores hardcodeados
- [ ] Imports con `@/` alias
- [ ] No lógica de BigQuery en componentes de charts
