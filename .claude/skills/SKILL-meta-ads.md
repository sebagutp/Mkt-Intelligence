# Skill: Meta Ads — Graph API, Métricas y Normalización

## Contexto

Este skill contiene el conocimiento de dominio necesario para construir el conector de Meta Ads (HU-009) y el panel drill-down de Meta (parte de HU-013). Cubre la Graph API Insights, estructura de datos, métricas relevantes, y cómo normalizar al schema de MIH.

**HUs relacionadas**: HU-009, HU-013, HU-014, HU-020

---

## Arquitectura de Meta Ads

### Jerarquía de objetos

```
Ad Account (act_123456789)
  └── Campaign (objetivo: awareness, traffic, conversions, etc.)
       └── Ad Set (audiencia, placement, budget, schedule)
            └── Ad (creative: imagen/video + copy + CTA)
```

MIH extrae a nivel **Campaign** con granularidad diaria. Razón: balance entre detalle y volumen de data.

### Autenticación

- **System User Token** (long-lived): para integraciones server-to-server. Dura ~60 días.
- **Token exchange**: antes de expirar, POST a `/{token}/extend` para renovar.
- Header: `Authorization: Bearer {access_token}` o param `?access_token={token}`
- **Permisos necesarios**: `ads_read`, `ads_management` (para read), `business_management`

---

## API Insights — Referencia completa

### Endpoint

```
GET https://graph.facebook.com/v19.0/{ad_account_id}/insights
```

### Parámetros esenciales

| Param | Valor | Notas |
|-------|-------|-------|
| `fields` | Ver lista abajo | Campos a retornar |
| `level` | `campaign` | Nivel de agregación |
| `time_range` | `{"since":"2026-03-01","until":"2026-03-23"}` | Rango de fechas (JSON string) |
| `time_increment` | `1` | Granularidad: 1 = daily, 7 = weekly, `monthly` |
| `limit` | `500` | Rows por página (max 500 para insights) |
| `filtering` | `[{"field":"campaign.effective_status","operator":"IN","value":["ACTIVE","PAUSED"]}]` | Filtros opcionales |

### Campos recomendados (fields)

```
campaign_id,
campaign_name,
objective,
impressions,
clicks,
spend,
reach,
frequency,
ctr,
cpc,
cpm,
actions,
action_values,
cost_per_action_type,
video_avg_time_watched_actions,
outbound_clicks,
quality_ranking,
engagement_rate_ranking,
conversion_rate_ranking
```

### Paginación

La respuesta incluye `paging.next`. Loop hasta que `paging.next` sea null:

```typescript
let url = `https://graph.facebook.com/v19.0/${adAccountId}/insights?${params}`;
const allRows: MetaInsightRow[] = [];

while (url) {
  const response = await fetchWithRetry(url);
  const data = await response.json();

  if (data.error) {
    throw new Error(`Meta API Error: ${data.error.message} (code: ${data.error.code})`);
  }

  allRows.push(...(data.data || []));
  url = data.paging?.next || null;
}
```

### Rate Limits

- **Account-level**: ~200 calls/hour por ad account (varía según tier)
- **BM-level**: depende del tier del Business Manager
- Headers de respuesta: `x-business-use-case-usage` (JSON con % uso)
- **Estrategia**: si usage > 75%, esperar 60s antes del siguiente request
- Meta retorna HTTP 429 cuando se excede. Retry con backoff exponencial.

---

## Estructura de respuesta

### Row básica

```json
{
  "campaign_id": "23851234567890",
  "campaign_name": "Prospecting - LAL 1%",
  "date_start": "2026-03-23",
  "date_stop": "2026-03-23",
  "impressions": "15234",
  "clicks": "234",
  "spend": "45.67",
  "reach": "12100",
  "frequency": "1.26",
  "ctr": "1.536",
  "cpc": "0.195",
  "cpm": "2.997",
  "actions": [
    {"action_type": "link_click", "value": "198"},
    {"action_type": "landing_page_view", "value": "156"},
    {"action_type": "lead", "value": "12"},
    {"action_type": "purchase", "value": "3"},
    {"action_type": "page_engagement", "value": "45"},
    {"action_type": "post_engagement", "value": "38"}
  ],
  "action_values": [
    {"action_type": "purchase", "value": "287.50"},
    {"action_type": "lead", "value": "0"}
  ],
  "cost_per_action_type": [
    {"action_type": "link_click", "value": "0.231"},
    {"action_type": "lead", "value": "3.806"},
    {"action_type": "purchase", "value": "15.223"}
  ]
}
```

### El array `actions` — CRÍTICO

`actions` es un array de objetos `{action_type, value}`. Los action_types relevantes para conversiones:

| action_type | Qué es | ¿Contar como conversión? |
|-------------|--------|--------------------------|
| `purchase` | Compra completada | Sí — primaria |
| `lead` | Lead generado | Sí — primaria |
| `complete_registration` | Registro completado | Sí — primaria |
| `add_to_cart` | Agregado al carrito | Opcional (micro-conversión) |
| `initiate_checkout` | Inicio de checkout | Opcional (micro-conversión) |
| `link_click` | Click en link | No — es engagement |
| `landing_page_view` | Vista de landing | No — es engagement |
| `page_engagement` | Engagement general | No |
| `post_engagement` | Engagement en post | No |
| `video_view` | Vista de video (3s) | No |
| `onsite_conversion.messaging_first_reply` | Primer mensaje | Depende del negocio |

### Normalización a MIH

```typescript
function normalizeMetaRow(row: MetaInsightRow): NormalizedRow {
  const CONVERSION_TYPES = ['purchase', 'lead', 'complete_registration'];

  // Extraer conversiones del array actions
  const conversions = (row.actions || [])
    .filter(a => CONVERSION_TYPES.includes(a.action_type))
    .reduce((sum, a) => sum + parseFloat(a.value), 0);

  // Extraer revenue del array action_values
  const conversionValue = (row.action_values || [])
    .filter(a => a.action_type === 'purchase')
    .reduce((sum, a) => sum + parseFloat(a.value), 0);

  const spend = parseFloat(row.spend || '0');
  const impressions = parseInt(row.impressions || '0', 10);
  const clicks = parseInt(row.clicks || '0', 10);

  return {
    tenant_id: tenantId,
    channel: 'meta_ads',
    metric_date: row.date_start,
    source_campaign_id: row.campaign_id,
    campaign_name: row.campaign_name,
    impressions,
    clicks,
    spend,
    conversions,
    conversion_value: conversionValue,
    ctr: safeDivide(clicks, impressions) * 100,
    cpc: safeDivide(spend, clicks),
    cpa: safeDivide(spend, conversions),
    roas: safeDivide(conversionValue, spend),
    extra_metrics: {
      reach: parseInt(row.reach || '0', 10),
      frequency: parseFloat(row.frequency || '0'),
      cpm: parseFloat(row.cpm || '0'),
      objective: row.objective,
      all_actions: row.actions,
      quality_ranking: row.quality_ranking,
      engagement_rate_ranking: row.engagement_rate_ranking,
      conversion_rate_ranking: row.conversion_rate_ranking,
    },
  };
}
```

---

## Métricas específicas de Meta para el panel drill-down

### Columnas de la tabla de campañas

| Columna | Source | Formato | Sorteable |
|---------|--------|---------|-----------|
| Campaign | campaign_name | text | Sí |
| Objective | objective (extra_metrics) | badge | Sí |
| Spend | spend | $X,XXX.XX | Sí |
| Impressions | impressions | X,XXX | Sí |
| Reach | extra_metrics.reach | X,XXX | Sí |
| Clicks | clicks | X,XXX | Sí |
| CTR | ctr | X.XX% | Sí |
| Conversions | conversions | X,XXX | Sí |
| CPA | cpa | $X.XX | Sí |
| ROAS | roas | X.XXx | Sí |
| Frequency | extra_metrics.frequency | X.XX | Sí |
| Quality | extra_metrics.quality_ranking | badge color | Sí |

### KPI cards del canal Meta

1. **Spend** — Total spend del período
2. **Conversions** — Total conversiones (purchase + lead + registration)
3. **CPA** — Cost per acquisition
4. **ROAS** — Return on ad spend
5. **Reach** — Usuarios únicos alcanzados (de extra_metrics)
6. **Frequency** — Promedio de frequency (de extra_metrics). Alerta si > 3.5

### Señales de alerta específicas de Meta

| Señal | Condición | Causa probable | Acción sugerida |
|-------|-----------|----------------|-----------------|
| Fatiga de audiencia | frequency > 3.5 y CTR bajando | Misma audiencia viendo ads repetidamente | Rotar creativos o ampliar audiencia |
| Quality score bajo | quality_ranking = 'BELOW_AVERAGE_35' | Ad no resuena con audiencia | Revisar creativos y copy |
| CPM spike | CPM > 2x promedio 7d | Competencia alta o audiencia saturada | Revisar bids, probar audiencias nuevas |
| Learning Limited | delivery = 'LEARNING_LIMITED' | Ad set no obtiene suficientes conversiones | Ampliar audiencia o subir budget |

---

## Errores comunes de la API

| Error Code | Mensaje | Solución |
|------------|---------|----------|
| 100 | Invalid parameter | Verificar formato de time_range (JSON string) |
| 190 | Invalid OAuth token | Token expirado. Ejecutar token refresh. |
| 17 | User request limit reached | Rate limit. Esperar 60s y retry. |
| 2 | Temporary issue | Error transitorio de Meta. Retry con backoff. |
| 10 | Permission denied | Verificar permisos del System User en el BM |
| 2635 | Async report timeout | Rango de fechas muy amplio. Dividir en chunks de 7 días. |

### Manejo de errores en el conector

```typescript
if (data.error) {
  const { code, message, error_subcode } = data.error;

  if (code === 190) {
    // Token expirado — intentar refresh
    await this.refreshToken();
    return this.fetchData(); // Reintentar
  }

  if (code === 17 || code === 4) {
    // Rate limit — esperar y retry (manejado por ConnectorBase)
    throw new RetryableError(`Rate limited: ${message}`);
  }

  if (code === 2) {
    // Error transitorio — retry automático de ConnectorBase
    throw new RetryableError(`Meta transient error: ${message}`);
  }

  // Error no recuperable
  throw new Error(`Meta API Error [${code}]: ${message}`);
}
```

---

## Benchmarks de Meta Ads por industria

| Industria | CTR | CPC | CPM | CVR | CPA |
|-----------|-----|-----|-----|-----|-----|
| E-commerce | 1.0-1.5% | $0.50-1.50 | $8-15 | 2-4% | $15-40 |
| B2B / SaaS | 0.5-1.0% | $1.50-4.00 | $15-30 | 5-10% | $30-100 |
| Real Estate | 0.8-1.2% | $1.00-2.50 | $10-20 | 3-7% | $20-60 |
| Education | 0.8-1.3% | $0.80-2.00 | $8-18 | 4-8% | $15-50 |
| Health/Fitness | 1.0-1.5% | $0.60-1.80 | $7-14 | 3-6% | $15-45 |

Estos benchmarks son útiles para el panel de Insights: si el CPA de un cliente está 2x arriba del benchmark de su industria, es una señal clara.
