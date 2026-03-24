# HU-014: Panel de anomalías y oportunidades

**Sprint**: 3 — Intelligence (Semana 4)
**Track**: B (Frontend)
**Dependencias**: HU-008 (hooks base), HU-007 (proxy con query anomalies)
**Consola sugerida**: Terminal 2 (Frontend)

---

## Descripción

Panel de Insights que muestra anomalías detectadas (CPA spikes, CTR drops), budget pacing por canal, y ranking de top/bottom campañas. Transforma data cruda en inteligencia accionable.

## Criterios de aceptación

- [ ] Cards de anomalías: CPA spike, CTR drop, ROAS caída, con contexto
- [ ] Budget pacing bars: spend actual vs budget mensual por canal
- [ ] Top 5 / Bottom 5 campañas de la semana

## Prompt para Claude Code

```
Lee CLAUDE.md.

1. Crea src/hooks/useAnomalies.ts: llama a bq-query 'anomalies'. Retorna lista de anomalías con channel, metric, value, avg, pct_change.

2. Crea componentes:
   - src/components/insights/AnomalyCard.tsx: card con icono de alerta (amber/red), canal, métrica, valor actual vs promedio, % de cambio. Color coding: >20% change = amber, >40% = red.
   - src/components/insights/BudgetPacing.tsx: barra horizontal por canal. Verde si está on track (<110%), amber si overrun (110-130%), rojo si >130%. Muestra "$X de $Y gastado (Z%)". Budget viene de tenant_channels.config.monthly_budget.
   - src/components/insights/TopBottomList.tsx: dos columnas. Top 5 campañas por ROAS (verde) y Bottom 5 (rojo). Cada item: nombre, canal icon, ROAS value, spend.

3. Crea src/panels/InsightsPanel.tsx: compone las 3 secciones arriba. Header "Oportunidades detectadas" con badge de count.

4. Conecta InsightsPage.tsx.

Diseño: cards limpias, color coding claro. Si no hay anomalías: message positivo "Todo on track esta semana".
```

## Archivos a crear/modificar

- `src/hooks/useAnomalies.ts`
- `src/components/insights/AnomalyCard.tsx`
- `src/components/insights/BudgetPacing.tsx`
- `src/components/insights/TopBottomList.tsx`
- `src/components/panels/InsightsPanel.tsx`
- `src/pages/InsightsPage.tsx`

## Estimación

~3-4 horas con Claude Code
