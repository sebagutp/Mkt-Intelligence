# Skill: Growth Marketing — Métricas Cross-Channel y Framework de Análisis

## Contexto

Este skill define el framework de métricas y análisis que usa MIH para consolidar data de múltiples canales de marketing en un solo dashboard. Es el "cerebro" conceptual del producto: qué medir, cómo normalizar, y qué insights generar.

**Aplica a**: Todos los paneles, todas las queries de BigQuery, toda normalización de data.

---

## Funnel de marketing unificado

MIH normaliza todos los canales a un funnel común:

```
Awareness          →  Engagement        →  Conversion         →  Revenue
(Impressions)         (Clicks)             (Conversions)         (Conversion Value)

Métricas:             Métricas:            Métricas:             Métricas:
- Impressions         - Clicks             - Conversions         - Revenue / Conv. Value
- Reach               - CTR                - Conv. Rate          - ROAS
- CPM                 - CPC                - CPA                 - LTV (si disponible)
- Frequency           - Engagement Rate    - Cost per Lead       - AOV
- Share of Voice      - Bounce Rate        - Lead Quality        - MER (Marketing Eff. Ratio)
```

### Mapping por canal al funnel

| Canal | Awareness | Engagement | Conversion | Revenue |
|-------|-----------|------------|------------|---------|
| Google Ads | impressions | clicks, CTR | conversions | conversion_value, ROAS |
| Meta Ads | impressions, reach | clicks, CTR | actions[purchase/lead] | action_values[purchase] |
| GA4 | sessions, pageviews | engaged_sessions, bounce_rate | conversions (eventos) | ecommerce_revenue |
| Email | emails_sent (≈reach) | opens, clicks | clicks (≈conv proxy) | revenue_attributed |
| LinkedIn Ads | impressions | clicks, CTR | conversions, leads | costPerLead |
| LinkedIn Org. | impressionCount | clicks, likes, shares | followers (≈soft conv) | N/A |

---

## KPIs primarios del dashboard

### Overview (cross-channel)

1. **Total Spend** — Suma de spend de todos los canales pagados. Formato: moneda con 2 decimales.
2. **Total Conversions** — Suma de conversiones normalizadas. Cuidado: no double-count si GA4 y Google Ads reportan la misma conversión.
3. **Blended CPA** — `SAFE_DIVIDE(total_spend, total_conversions)`. El KPI más importante para eficiencia.
4. **Blended ROAS** — `SAFE_DIVIDE(total_conversion_value, total_spend)`. Benchmark: >3x es bueno, >5x es excelente.
5. **MER (Marketing Efficiency Ratio)** — `SAFE_DIVIDE(total_revenue, total_marketing_spend)`. Incluye canales orgánicos. Visión holística.

### Por canal (drill-down)

6. **Channel Spend Share** — `SAFE_DIVIDE(channel_spend, total_spend) * 100`. Para donut chart.
7. **Channel CPA** — CPA específico del canal vs blended. Si channel CPA > blended CPA × 1.3, es candidato a optimización.
8. **Channel ROAS** — ROAS específico. Si < 1.0, el canal pierde dinero en atribución directa.
9. **Budget Pacing** — `SAFE_DIVIDE(mtd_spend, monthly_budget) * 100`. Verde <100%, amarillo 100-110%, rojo >110%.
10. **Trend vs período anterior** — Delta % de cada métrica vs mismo período anterior. Flechas verdes/rojas.

---

## Normalización de datos

### Schema unificado (NormalizedRow)

Cada conector DEBE mapear su data a este schema:

```typescript
interface NormalizedRow {
  tenant_id: string;
  channel: ChannelType;           // 'google_ads' | 'meta_ads' | 'ga4' | 'email' | 'linkedin_ads' | 'linkedin_organic'
  metric_date: string;            // 'YYYY-MM-DD'
  source_campaign_id: string;     // ID original de la plataforma
  campaign_name: string;

  // Métricas del funnel (normalizadas)
  impressions: number;            // Awareness
  clicks: number;                 // Engagement
  spend: number;                  // En USD, 2 decimales. 0 para canales orgánicos.
  conversions: number;            // Conversion events
  conversion_value: number;       // Revenue atribuido. 0 si no disponible.

  // Métricas calculadas (derivadas de las anteriores)
  ctr: number;                    // SAFE_DIVIDE(clicks, impressions) * 100
  cpc: number;                    // SAFE_DIVIDE(spend, clicks)
  cpa: number;                    // SAFE_DIVIDE(spend, conversions)
  roas: number;                   // SAFE_DIVIDE(conversion_value, spend)

  // Métricas específicas del canal (JSON)
  extra_metrics: Record<string, unknown>;
}
```

### Reglas de normalización

1. **Spend siempre en USD**: Si la API reporta en micros (Google Ads), dividir por 1,000,000. Si reporta en otra moneda, convertir.
2. **Conversiones = acciones de valor**: No contar todos los eventos. Solo: purchase, lead, complete_registration, sign_up, add_to_cart (configurables por tenant).
3. **CTR, CPC, CPA, ROAS siempre con SAFE_DIVIDE**: Nunca división directa. Si denominador = 0, resultado = 0.
4. **Dedup key**: `{channel}__{source_campaign_id}__{metric_date}`. BigQuery usa insertId para dedup automático.
5. **Canales orgánicos**: spend = 0, CPC = 0, CPA = 0, ROAS = ∞ (reportar como "N/A" en UI).
6. **Email mapping**: emails_sent → impressions, opens → (no mapea directo), clicks → clicks. El email tiene su propio set de métricas en extra_metrics.

---

## Detección de anomalías

### Algoritmo

Para cada canal + métrica, comparar el valor del último día vs promedio de ventana de 7 días:

```sql
pct_change = SAFE_DIVIDE(
  ABS(today_value - avg_7d),
  avg_7d
) * 100
```

### Thresholds

| Severidad | % Change | Color | Acción |
|-----------|----------|-------|--------|
| Normal | < 20% | — | No mostrar |
| Warning | 20-40% | Amber | Mostrar card informativa |
| Critical | > 40% | Red | Mostrar card + disparar alerta |

### Métricas a monitorear

- **CPA spike**: CPA subió >20% vs 7d avg → posible fatiga de audiencia o bid inflation
- **CTR drop**: CTR bajó >20% → posible fatiga creativa o audiencia saturada
- **ROAS caída**: ROAS bajó >30% → revenue tracking roto o cambio en mix de conversiones
- **Spend overrun**: MTD spend > budget × (día_del_mes / días_totales) × 1.1 → pacing issue
- **Zero conversions**: Canal con spend > $50 y 0 conversiones en últimas 24h → tracking roto o pausa

### Contexto para el usuario

Cada anomalía debe incluir:
- Qué pasó (métrica + valor + cambio %)
- Cuándo (fecha o rango)
- Comparación (vs promedio de qué período)
- Posible causa (texto predefinido por tipo de anomalía)
- Acción sugerida (texto predefinido)

---

## Comparación de períodos

### Períodos estándar

| Preset | Current | Previous | Uso |
|--------|---------|----------|-----|
| Last 7 days | Últimos 7 días | 7 días anteriores | Quick check semanal |
| Last 30 days | Últimos 30 días | 30 días anteriores | Revisión mensual |
| MTD | 1ro del mes → hoy | Mismo rango del mes anterior | Budget pacing |
| QTD | 1ro del quarter → hoy | Mismo rango del quarter anterior | Planning |
| Custom | Rango seleccionado | Mismo # días inmediatamente antes | Ad hoc |

### Cálculo de delta

```
delta_pct = SAFE_DIVIDE(current - previous, ABS(previous)) * 100
```

- Delta positivo en spend = rojo (gastamos más)
- Delta positivo en conversions = verde (más conversiones)
- Delta positivo en CPA = rojo (más caro)
- Delta positivo en ROAS = verde (más eficiente)
- Delta positivo en CTR = verde (mejor engagement)

La polaridad depende de la métrica. Definir en constantes:

```typescript
const METRIC_POLARITY: Record<string, 'positive' | 'negative'> = {
  spend: 'negative',        // más spend = peor (a igualdad de resultado)
  conversions: 'positive',
  conversion_value: 'positive',
  ctr: 'positive',
  cpc: 'negative',
  cpa: 'negative',          // CPA más bajo = mejor
  roas: 'positive',         // ROAS más alto = mejor
  impressions: 'positive',
  clicks: 'positive',
};
```

---

## Budget pacing

### Fórmula

```
expected_spend_today = monthly_budget × (day_of_month / days_in_month)
actual_spend_mtd = SUM(spend) WHERE month = current_month
pacing_pct = SAFE_DIVIDE(actual_spend_mtd, expected_spend_today) * 100
```

### Estados de pacing

| Estado | Condición | Color | Mensaje |
|--------|-----------|-------|---------|
| Under-pacing | < 85% | Blue | "Underspending — ${diff} below target" |
| On track | 85-110% | Green | "On track" |
| Slightly over | 110-130% | Amber | "Slightly overpacing — consider reducing bids" |
| Over budget | > 130% | Red | "Significantly overpacing — action required" |

---

## Atribución y double-counting

### El problema

GA4, Google Ads y Meta Ads pueden reportar la misma conversión. Un usuario clickea un ad de Google, luego un ad de Meta, y convierte → ambas plataformas se atribuyen la conversión.

### Enfoque de MIH (v1)

**No intentar deduplicar cross-channel.** Razones:
1. Cada plataforma usa su propio modelo de atribución
2. Dedup requiere data a nivel usuario (no disponible en APIs agregadas)
3. El blended CPA/ROAS ya absorbe el efecto

**Lo que SÍ hacemos:**
- Mostrar "Platform-reported" como disclaimer en métricas por canal
- El blended CPA usa spend total real ÷ conversiones de GA4 (fuente más neutral)
- Opción futura: MER (Marketing Efficiency Ratio) = revenue total / spend total, sin importar atribución

### Disclaimer en UI

En el panel Overview, junto a "Total Conversions":
> "Conversions are platform-reported and may include overlap between channels. Blended CPA uses total spend ÷ primary conversion source."

---

## Segmentos de tiempo

### Granularidad de data

- **ETL**: siempre sync por día (metric_date = DATE)
- **Dashboard**: agrupa según vista (diario, semanal, mensual)
- **Queries de BQ**: siempre filtro de fecha. Nunca full table scan.

### Retención de data

- BigQuery free tier: 10GB. A ~1KB por row, ~10M rows.
- Estimado: 50 campañas × 5 canales × 365 días = ~91K rows/año. Estamos bien.
- Política: mantener 2 años de data. Después, agregar a monthly summaries.

---

## Glosario de métricas

| Métrica | Definición | Fórmula | Benchmark |
|---------|-----------|---------|-----------|
| CPA | Cost Per Acquisition | spend / conversions | Varía por industria. B2B SaaS: $50-200 |
| ROAS | Return on Ad Spend | conversion_value / spend | >3x bueno, >5x excelente |
| CTR | Click-Through Rate | clicks / impressions × 100 | Search: 3-5%, Display: 0.5-1%, Social: 1-2% |
| CPC | Cost Per Click | spend / clicks | Search: $1-5, Display: $0.50-2, Social: $0.50-3 |
| CPM | Cost Per Mille | spend / impressions × 1000 | Display: $2-10, Social: $5-15, LinkedIn: $8-30 |
| MER | Marketing Efficiency Ratio | total_revenue / total_spend | >3x es saludable |
| CVR | Conversion Rate | conversions / clicks × 100 | E-comm: 2-3%, B2B: 5-10% |
| AOV | Average Order Value | total_revenue / total_orders | Varía enormemente |
| LTV | Lifetime Value | revenue_per_customer × avg_lifetime | LTV/CPA > 3x es ideal |
| Frequency | Promedio de veces que un usuario ve un ad | impressions / reach | <3 ideal, >5 fatiga |
