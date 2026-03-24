# Skill: Google Ads — GAQL, API SearchStream y Normalización

## Contexto

Este skill contiene el conocimiento de dominio para construir el conector de Google Ads (HU-005) y el panel drill-down (HU-013). Cubre la Google Ads API v17, GAQL (Google Ads Query Language), estructura de datos, y normalización.

**HUs relacionadas**: HU-005, HU-013, HU-014, HU-020

---

## Arquitectura de Google Ads

### Jerarquía de objetos

```
MCC (Manager Account) — opcional, para gestionar múltiples cuentas
  └── Customer Account (ID: 123-456-7890)
       └── Campaign (tipo: Search, Display, Shopping, Video, Performance Max, etc.)
            └── Ad Group (agrupación temática)
                 └── Ad (creative + extensiones)
                      └── Keywords / Audiences / Placements
```

MIH extrae a nivel **Campaign** con segmento de fecha diaria. Razón: métricas agregadas son suficientes para un dashboard ejecutivo.

### Autenticación

1. **OAuth 2.0**: tres-legged flow. Access token expira en 1h. Refresh token para renovar.
2. **Developer Token**: requerido en header. Se obtiene del MCC.
3. **Headers obligatorios**:
   ```
   Authorization: Bearer {access_token}
   developer-token: {dev_token}
   login-customer-id: {mcc_id}  // Solo si se accede vía MCC. Sin guiones.
   ```

### Token refresh

```typescript
const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: credentials.refresh_token,
    client_id: GOOGLE_OAUTH_CLIENT_ID,
    client_secret: GOOGLE_OAUTH_CLIENT_SECRET,
  }),
});
const { access_token, expires_in } = await tokenResponse.json();
```

---

## Google Ads Query Language (GAQL)

### Query para MIH

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.status,
  campaign.advertising_channel_type,
  campaign.bidding_strategy_type,
  segments.date,
  metrics.impressions,
  metrics.clicks,
  metrics.cost_micros,
  metrics.conversions,
  metrics.conversions_value,
  metrics.ctr,
  metrics.average_cpc,
  metrics.average_cpm,
  metrics.cost_per_conversion,
  metrics.conversions_from_interactions_rate,
  metrics.video_views,
  metrics.search_impression_share
FROM campaign
WHERE segments.date BETWEEN '{startDate}' AND '{endDate}'
  AND campaign.status != 'REMOVED'
ORDER BY metrics.cost_micros DESC
```

### Reglas de GAQL

1. **No SELECT ***: debes listar cada campo.
2. **segments.date es obligatorio** en WHERE si lo usas en SELECT.
3. **No puedes mezclar** ciertos segmentos (ej: segments.date + segments.hour).
4. **Métricas siempre con metrics.** prefix: `metrics.impressions`, no `impressions`.
5. **cost_micros**: siempre en micro-unidades (1 USD = 1,000,000 micros).
6. **Strings en GAQL**: usar single quotes `'REMOVED'`, no double quotes.
7. **Dates en GAQL**: formato `'YYYY-MM-DD'`.

### Campos disponibles importantes

| Campo | Tipo | Notas |
|-------|------|-------|
| `metrics.cost_micros` | int64 | Dividir por 1,000,000 para USD |
| `metrics.conversions` | double | Puede ser fraccionario (atribución) |
| `metrics.conversions_value` | double | Valor monetario de conversiones |
| `metrics.ctr` | double | Ya calculado (0.0 a 1.0, NOT %) |
| `metrics.average_cpc` | int64 | En micros. Dividir por 1,000,000 |
| `metrics.average_cpm` | int64 | En micros. Dividir por 1,000,000 |
| `metrics.search_impression_share` | double | 0.0 a 1.0. Solo Search campaigns |
| `metrics.cost_per_conversion` | int64 | En micros |
| `campaign.advertising_channel_type` | enum | SEARCH, DISPLAY, SHOPPING, VIDEO, PERFORMANCE_MAX, etc. |
| `campaign.bidding_strategy_type` | enum | TARGET_CPA, MAXIMIZE_CONVERSIONS, etc. |

---

## API SearchStream

### Endpoint

```
POST https://googleads.googleapis.com/v17/customers/{customerId}/googleAds:searchStream
```

**customerId**: sin guiones (ej: `1234567890`, no `123-456-7890`).

### Request body

```json
{
  "query": "SELECT ... FROM campaign WHERE ..."
}
```

### Response

SearchStream retorna NDJSON (newline-delimited JSON). Cada batch:

```json
{
  "results": [
    {
      "campaign": {
        "resourceName": "customers/1234567890/campaigns/123",
        "id": "123",
        "name": "Search - Brand",
        "status": "ENABLED",
        "advertisingChannelType": "SEARCH",
        "biddingStrategyType": "TARGET_CPA"
      },
      "metrics": {
        "impressions": "5234",
        "clicks": "487",
        "costMicros": "234560000",
        "conversions": 23.5,
        "conversionsValue": 4750.0,
        "ctr": 0.0930,
        "averageCpc": "481647",
        "averageCpm": "44819782",
        "costPerConversion": "9981277",
        "conversionsFromInteractionsRate": 0.0483,
        "searchImpressionShare": 0.65
      },
      "segments": {
        "date": "2026-03-23"
      }
    }
  ],
  "fieldMask": "campaign.id,campaign.name,...",
  "requestId": "xxx"
}
```

### Notas sobre SearchStream vs Search

| Feature | searchStream | search |
|---------|-------------|--------|
| Paginación | No necesaria (streaming) | Sí, con pageToken |
| Response | Batches NDJSON | Single JSON |
| Mejor para | Datasets grandes | Datasets pequeños |
| Timeout | Más robusto | Puede timeout en >10K rows |

**MIH usa SearchStream** porque es más robusto para periodos largos.

### Parsing de SearchStream

```typescript
async function parseSearchStream(response: Response): Promise<GoogleAdsRow[]> {
  const text = await response.text();
  const allResults: GoogleAdsRow[] = [];

  // SearchStream puede retornar múltiples objetos JSON concatenados
  const batches = text.split('\n').filter(line => line.trim());

  for (const batch of batches) {
    try {
      const parsed = JSON.parse(batch);
      if (parsed.results) {
        allResults.push(...parsed.results);
      }
    } catch (e) {
      // Puede ser un batch parcial, continuar
      console.warn('Failed to parse batch:', e);
    }
  }

  return allResults;
}
```

---

## Normalización a MIH

```typescript
function normalizeGoogleAdsRow(row: GoogleAdsRow): NormalizedRow {
  const spend = Number(row.metrics.costMicros) / 1_000_000;
  const impressions = Number(row.metrics.impressions);
  const clicks = Number(row.metrics.clicks);
  const conversions = Number(row.metrics.conversions);
  const conversionValue = Number(row.metrics.conversionsValue);

  return {
    tenant_id: tenantId,
    channel: 'google_ads',
    metric_date: row.segments.date,
    source_campaign_id: row.campaign.id,
    campaign_name: row.campaign.name,
    impressions,
    clicks,
    spend,
    conversions,
    conversion_value: conversionValue,
    ctr: safeDivide(clicks, impressions) * 100,  // Convertir a porcentaje
    cpc: safeDivide(spend, clicks),
    cpa: safeDivide(spend, conversions),
    roas: safeDivide(conversionValue, spend),
    extra_metrics: {
      channel_type: row.campaign.advertisingChannelType,
      status: row.campaign.status,
      bidding_strategy: row.campaign.biddingStrategyType,
      avg_cpc_micros: row.metrics.averageCpc,
      avg_cpm_micros: row.metrics.averageCpm,
      search_impression_share: row.metrics.searchImpressionShare,
      conversion_rate: row.metrics.conversionsFromInteractionsRate,
      cost_per_conversion_micros: row.metrics.costPerConversion,
    },
  };
}
```

### Conversiones IMPORTANTES

| Campo API | Tipo | Conversión | Resultado |
|-----------|------|------------|-----------|
| `costMicros` | string/int64 | `/ 1_000_000` | USD decimal |
| `averageCpc` | string/int64 | `/ 1_000_000` | USD decimal |
| `averageCpm` | string/int64 | `/ 1_000_000` | USD decimal |
| `costPerConversion` | string/int64 | `/ 1_000_000` | USD decimal |
| `impressions` | string | `parseInt()` | integer |
| `clicks` | string | `parseInt()` | integer |
| `conversions` | number | directo | float (puede ser 23.5) |
| `conversionsValue` | number | directo | float USD |
| `ctr` | number | `* 100` | porcentaje (API da 0.093 → 9.3%) |
| `searchImpressionShare` | number | `* 100` | porcentaje |

---

## Métricas específicas para panel drill-down

### Columnas de la tabla de campañas

| Columna | Source | Formato | Notas |
|---------|--------|---------|-------|
| Campaign | campaign_name | text | — |
| Type | extra_metrics.channel_type | badge | SEARCH, DISPLAY, PMAX, etc. |
| Status | extra_metrics.status | badge color | ENABLED=green, PAUSED=amber |
| Impressions | impressions | X,XXX | — |
| Clicks | clicks | X,XXX | — |
| CTR | ctr | X.XX% | — |
| CPC | cpc | $X.XX | — |
| Spend | spend | $X,XXX.XX | — |
| Conversions | conversions | X.X | Puede ser decimal |
| CPA | cpa | $X.XX | — |
| ROAS | roas | X.XXx | — |
| Imp. Share | extra_metrics.search_impression_share | XX% | Solo Search |

### KPI cards del canal Google Ads

1. **Spend** — Total del período
2. **Conversions** — Total conversiones
3. **CPA** — Cost per acquisition (el más importante para paid search)
4. **ROAS** — Return on ad spend
5. **Avg. CPC** — Promedio de cost per click
6. **Impression Share** — Promedio ponderado (solo Search)

### Señales de alerta específicas

| Señal | Condición | Causa probable | Acción |
|-------|-----------|----------------|--------|
| CPA spike | CPA > 2x promedio 7d | Competencia en auction o keyword ineficiente | Revisar search terms, ajustar bids |
| Impression Share caída | IS bajó >15pts | Budget insuficiente o bid rank bajo | Subir budget o mejorar Quality Score |
| CTR drop | CTR < 50% del promedio 7d | Ad copy cansado o keywords irrelevantes | Rotar ads, revisar negative keywords |
| Zero conversions | spend > $100 y conv = 0 | Tracking roto o landing rota | Verificar conversion tracking |
| Cost micros = 0 | Campaña activa sin spend | Campaña pausada o sin presupuesto | Verificar estado y budget |

---

## Campaign types y sus particularidades

| Type | Métricas relevantes | Notas para MIH |
|------|-------------------|----------------|
| SEARCH | IS, avg_position, quality_score | CTR alto es normal (3-8%). CPC más alto. |
| DISPLAY | reach, frequency, viewable_impressions | CTR bajo es normal (0.3-0.8%). CPM-oriented. |
| SHOPPING | product_clicks, benchmark_ctr | Conversions = purchases. ROAS es clave. |
| VIDEO (YouTube) | video_views, view_rate, CPV | Impressions ≠ views. view_rate es key metric. |
| PERFORMANCE_MAX | conversions, conv_value | Black box. Solo métricas agregadas. Sin breakdown por placement. |
| DEMAND_GEN | clicks, conversions | Similar a Display pero para Discover/YouTube/Gmail. |

### Recomendación para UI

Mostrar badge de type en la tabla. Cuando el tipo es PERFORMANCE_MAX, agregar tooltip: "Performance Max campaigns have limited metric breakdowns."

---

## Rate Limits de Google Ads API

- **Quota básica**: 15,000 requests/día por developer token
- **Por customer**: 1,000 requests/día por cuenta
- **SearchStream**: cuenta como 1 request (no importa cuántos batches)
- **Best practice**: una query SearchStream por día de sync = máximo eficiente

### Errores comunes

| Error | gRPC Code | Solución |
|-------|-----------|----------|
| AUTHENTICATION_ERROR | UNAUTHENTICATED | Refresh access token |
| AUTHORIZATION_ERROR | PERMISSION_DENIED | Verificar acceso a la cuenta |
| QUOTA_ERROR | RESOURCE_EXHAUSTED | Rate limited. Retry con backoff. |
| REQUEST_ERROR | INVALID_ARGUMENT | GAQL syntax error. Verificar query. |
| INTERNAL_ERROR | INTERNAL | Error de Google. Retry. |

---

## Benchmarks por campaign type

| Type | CTR | CPC | Conv Rate | CPA |
|------|-----|-----|-----------|-----|
| Search (Brand) | 5-15% | $0.50-2.00 | 8-15% | $5-25 |
| Search (Non-brand) | 2-5% | $1.50-5.00 | 3-7% | $25-80 |
| Display | 0.3-0.8% | $0.30-1.50 | 0.5-2% | $30-100 |
| Shopping | 1-3% | $0.30-1.00 | 2-4% | $15-50 |
| Video (YouTube) | 0.5-1.5% | $0.05-0.30 (CPV) | 1-3% | $20-60 |
| Performance Max | 1-3% | $0.50-3.00 | 3-8% | $20-70 |
