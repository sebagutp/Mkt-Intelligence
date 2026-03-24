# Skill: Google Analytics 4 — Data API, Eventos y Normalización

## Contexto

Este skill contiene el conocimiento de dominio para construir el conector de GA4 (HU-006) y el panel drill-down (HU-013). Cubre la GA4 Data API v1, modelo de eventos, dimensiones y métricas, y cómo normalizar al schema de MIH.

**HUs relacionadas**: HU-006, HU-013, HU-014

---

## Modelo de datos de GA4

### Diferencias clave vs Universal Analytics

| Concepto | Universal Analytics | GA4 |
|----------|-------------------|-----|
| Modelo | Sessions + Pageviews | Events (todo es un evento) |
| Users | Total Users | Active Users (por defecto) |
| Goals | Goals + Ecommerce | Conversions (eventos marcados) |
| Vistas | Views (profiles) | Data Streams |
| Property ID | UA-XXXXXX-X | Numeric (ej: 123456789) |

### Eventos automáticos relevantes

| Evento | Qué mide | Disponible por defecto |
|--------|----------|------------------------|
| `session_start` | Inicio de sesión | Sí |
| `first_visit` | Primera visita del usuario | Sí |
| `page_view` | Vista de página | Sí |
| `scroll` | Scroll >90% de la página | Sí (enhanced measurement) |
| `click` | Click en links salientes | Sí (enhanced measurement) |
| `file_download` | Descarga de archivo | Sí (enhanced measurement) |
| `form_start` | Inicio de formulario | Sí (enhanced measurement) |
| `form_submit` | Envío de formulario | Sí (enhanced measurement) |
| `purchase` | Compra ecommerce | Requiere implementación |
| `generate_lead` | Generación de lead | Requiere implementación |
| `sign_up` | Registro de usuario | Requiere implementación |

---

## GA4 Data API v1 — Referencia

### Autenticación

GA4 Data API soporta **Service Account** (no necesita OAuth de usuario):

```typescript
// Usar el mismo Service Account JSON que BigQuery
// Scope necesario: https://www.googleapis.com/auth/analytics.readonly

const jwt = await generateJWT(serviceAccountJson, {
  scope: 'https://www.googleapis.com/auth/analytics.readonly',
  audience: 'https://oauth2.googleapis.com/token',
});

const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST',
  body: new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  }),
});
```

### Endpoint: runReport

```
POST https://analyticsdata.googleapis.com/v1beta/properties/{propertyId}:runReport
```

**propertyId**: numeric, sin prefijo (ej: `123456789`).

### Request body para MIH

```json
{
  "dateRanges": [
    {
      "startDate": "2026-03-01",
      "endDate": "2026-03-23"
    }
  ],
  "dimensions": [
    {"name": "date"},
    {"name": "sessionSource"},
    {"name": "sessionMedium"},
    {"name": "sessionCampaignName"}
  ],
  "metrics": [
    {"name": "sessions"},
    {"name": "totalUsers"},
    {"name": "newUsers"},
    {"name": "bounceRate"},
    {"name": "averageSessionDuration"},
    {"name": "conversions"},
    {"name": "screenPageViews"},
    {"name": "engagedSessions"},
    {"name": "engagementRate"},
    {"name": "eventCount"},
    {"name": "ecommercePurchases"},
    {"name": "purchaseRevenue"}
  ],
  "dimensionFilter": {
    "notExpression": {
      "filter": {
        "fieldName": "sessionSource",
        "stringFilter": {
          "value": "(not set)"
        }
      }
    }
  },
  "orderBys": [
    {
      "dimension": {"dimensionName": "date"},
      "desc": false
    }
  ],
  "limit": 10000,
  "offset": 0
}
```

### Response structure

```json
{
  "dimensionHeaders": [
    {"name": "date"},
    {"name": "sessionSource"},
    {"name": "sessionMedium"},
    {"name": "sessionCampaignName"}
  ],
  "metricHeaders": [
    {"name": "sessions", "type": "TYPE_INTEGER"},
    {"name": "totalUsers", "type": "TYPE_INTEGER"},
    {"name": "newUsers", "type": "TYPE_INTEGER"},
    {"name": "bounceRate", "type": "TYPE_FLOAT"},
    {"name": "averageSessionDuration", "type": "TYPE_FLOAT"},
    {"name": "conversions", "type": "TYPE_INTEGER"},
    {"name": "screenPageViews", "type": "TYPE_INTEGER"},
    {"name": "engagedSessions", "type": "TYPE_INTEGER"},
    {"name": "engagementRate", "type": "TYPE_FLOAT"},
    {"name": "eventCount", "type": "TYPE_INTEGER"},
    {"name": "ecommercePurchases", "type": "TYPE_INTEGER"},
    {"name": "purchaseRevenue", "type": "TYPE_FLOAT"}
  ],
  "rows": [
    {
      "dimensionValues": [
        {"value": "20260323"},
        {"value": "google"},
        {"value": "cpc"},
        {"value": "brand_campaign"}
      ],
      "metricValues": [
        {"value": "1234"},
        {"value": "987"},
        {"value": "543"},
        {"value": "0.3245"},
        {"value": "145.67"},
        {"value": "45"},
        {"value": "3456"},
        {"value": "834"},
        {"value": "0.676"},
        {"value": "8765"},
        {"value": "12"},
        {"value": "2340.50"}
      ]
    }
  ],
  "rowCount": 1523,
  "metadata": {
    "currencyCode": "USD",
    "timeZone": "America/Santiago"
  }
}
```

### Paginación

Si `rowCount` > `limit` (10000), hacer requests adicionales incrementando `offset`:

```typescript
let offset = 0;
const limit = 10000;
const allRows: GA4Row[] = [];

while (true) {
  const response = await fetchReport({ ...body, limit, offset });
  allRows.push(...response.rows);

  if (allRows.length >= response.rowCount || response.rows.length === 0) {
    break;
  }
  offset += limit;
}
```

---

## Normalización a MIH

### El reto de GA4

GA4 es fundamentalmente diferente a los canales de paid ads:
- **No tiene spend** (es un tracker, no una plataforma de ads)
- **Granularidad**: cada combinación source/medium/campaign/date es una row
- **Conversiones**: son eventos marcados como conversion, no necessarily purchases

### Mapping al schema unificado

```typescript
function normalizeGA4Row(row: GA4Row): NormalizedRow {
  const date = row.dimensionValues[0].value; // "20260323"
  const source = row.dimensionValues[1].value;
  const medium = row.dimensionValues[2].value;
  const campaignName = row.dimensionValues[3].value;

  const sessions = parseInt(row.metricValues[0].value);
  const totalUsers = parseInt(row.metricValues[1].value);
  const newUsers = parseInt(row.metricValues[2].value);
  const bounceRate = parseFloat(row.metricValues[3].value);
  const avgSessionDuration = parseFloat(row.metricValues[4].value);
  const conversions = parseInt(row.metricValues[5].value);
  const pageViews = parseInt(row.metricValues[6].value);
  const engagedSessions = parseInt(row.metricValues[7].value);
  const engagementRate = parseFloat(row.metricValues[8].value);
  const eventCount = parseInt(row.metricValues[9].value);
  const purchases = parseInt(row.metricValues[10].value);
  const revenue = parseFloat(row.metricValues[11].value);

  // Formatear fecha de "20260323" a "2026-03-23"
  const formattedDate = `${date.slice(0,4)}-${date.slice(4,6)}-${date.slice(6,8)}`;

  return {
    tenant_id: tenantId,
    channel: 'ga4',
    metric_date: formattedDate,
    source_campaign_id: `${source}/${medium}`,  // Composición unique
    campaign_name: campaignName || `${source} / ${medium}`,

    // Mapping conceptual al funnel
    impressions: sessions,        // Sessions ≈ "impresiones" del sitio
    clicks: engagedSessions,      // Engaged sessions ≈ "clicks" de interés
    spend: 0,                     // GA4 no tiene spend
    conversions: conversions,
    conversion_value: revenue,

    // Métricas calculadas
    ctr: safeDivide(engagedSessions, sessions) * 100,  // Engagement rate como proxy de CTR
    cpc: 0,                       // No hay spend
    cpa: 0,                       // No hay spend
    roas: 0,                      // No hay spend

    extra_metrics: {
      source,
      medium,
      total_users: totalUsers,
      new_users: newUsers,
      bounce_rate: bounceRate,
      avg_session_duration: avgSessionDuration,
      page_views: pageViews,
      engagement_rate: engagementRate,
      event_count: eventCount,
      ecommerce_purchases: purchases,
      pages_per_session: safeDivide(pageViews, sessions),
    },
  };
}
```

### Notas sobre la normalización

1. **sessions → impressions**: Es un mapping conceptual imperfecto pero útil para el funnel unificado. En el drill-down de GA4, mostrar "Sessions" directamente.
2. **spend = 0**: GA4 no reporta spend. El spend de Google Ads viene del conector de Google Ads.
3. **source_campaign_id = "source/medium"**: Es el identificador más útil en GA4 para agrupar tráfico.
4. **Fecha**: GA4 retorna fechas como "20260323" (sin separadores). Convertir a "2026-03-23".
5. **bounceRate**: GA4 ya lo reporta como decimal (0.3245 = 32.45%). Guardar como float, formatear en UI.

---

## Métricas específicas para panel drill-down de GA4

### Columnas de la tabla

| Columna | Source | Formato | Notas |
|---------|--------|---------|-------|
| Source / Medium | campaign_name | text | "google / cpc", "facebook / paid" |
| Campaign | extra_metrics → nombre real si existe | text | — |
| Sessions | impressions (mapped) | X,XXX | — |
| Users | extra_metrics.total_users | X,XXX | — |
| New Users | extra_metrics.new_users | X,XXX | — |
| Bounce Rate | extra_metrics.bounce_rate | XX.X% | Color: <40% green, 40-60% amber, >60% red |
| Engagement Rate | extra_metrics.engagement_rate | XX.X% | Inverso de bounce rate conceptualmente |
| Pages/Session | extra_metrics.pages_per_session | X.X | — |
| Avg. Duration | extra_metrics.avg_session_duration | Xm Xs | Formatear seconds a min:sec |
| Conversions | conversions | X,XXX | — |
| Revenue | conversion_value | $X,XXX | Solo si ecommerce |

### KPI cards del canal GA4

1. **Sessions** — Total del período
2. **Users** — Total usuarios únicos
3. **Engagement Rate** — Promedio (equivalente moderno de bounce rate)
4. **Conversions** — Total eventos de conversión
5. **Revenue** — Total ecommerce revenue (si disponible)
6. **Pages/Session** — Promedio

### Señales de alerta específicas

| Señal | Condición | Causa probable | Acción |
|-------|-----------|----------------|--------|
| Traffic drop | Sessions < 60% del promedio 7d | Tracking roto, SEO penalty, server down | Verificar GA4 tag, check site |
| Bounce rate spike | Bounce rate > 1.5x promedio | Landing page rota o irrelevante | Revisar landing pages top |
| Zero conversions | Sessions > 100 y conv = 0 por 48h | Conversion tracking roto | Verificar eventos de conversión en GA4 |
| New Users drop | New users < 50% del promedio | Canales de adquisición fallando | Revisar paid + organic sources |

---

## Dimensiones útiles para futuras expansiones

| Dimensión | Uso | Nivel de detalle |
|-----------|-----|-----------------|
| `sessionSource` | De dónde viene el tráfico | Alto — úsalo |
| `sessionMedium` | Tipo de tráfico (cpc, organic, email) | Alto — úsalo |
| `sessionCampaignName` | Nombre de campaña UTM | Alto — úsalo |
| `country` | País del usuario | Medio — futuro |
| `city` | Ciudad | Bajo — futuro |
| `deviceCategory` | desktop/mobile/tablet | Medio — futuro |
| `browser` | Chrome/Safari/etc. | Bajo |
| `landingPage` | URL de entrada | Medio — futuro |
| `pagePath` | Todas las páginas | Bajo (mucha data) |
| `eventName` | Nombre del evento | Bajo (requiere query aparte) |

### Recomendación v1

Solo usar `date`, `sessionSource`, `sessionMedium`, `sessionCampaignName`. Suficiente para dashboard ejecutivo. Agregar device y country en v2.

---

## Quotas y Limits de GA4 Data API

| Recurso | Límite | Notas |
|---------|--------|-------|
| Requests per day | 200,000 | Más que suficiente |
| Requests per minute per project | 2,000 | Muy generoso |
| Requests per minute per property | 10 | Este es el real limit |
| Rows per response | 250,000 max | Paginar con offset |
| Dimensions per request | 9 max | — |
| Metrics per request | 10 max | Hacer 2 requests si necesitas más |
| Date range | 60 months max | — |

### Estrategia de sync

- 1 request por día de sync (si < 10K rows)
- Si el property tiene muchos source/medium combos, puede necesitar 2+ pages
- Delay de 6s entre requests al mismo property (para respetar 10 RPM)
- Sync diario: solo el día anterior (no range largo)
- Backfill: iterar día por día con delay

---

## Source/Medium más comunes

| source / medium | Qué es | Canal en MIH |
|-----------------|--------|-------------|
| google / cpc | Google Ads paid | Overlap con google_ads |
| google / organic | Búsqueda orgánica Google | ga4 (orgánico) |
| facebook / paid | Meta Ads | Overlap con meta_ads |
| facebook / referral | Links orgánicos de Facebook | ga4 (orgánico) |
| direct / (none) | Tráfico directo | ga4 |
| email / email | Email marketing | Overlap con email |
| linkedin / paid | LinkedIn Ads | Overlap con linkedin_ads |
| (not set) / (not set) | Sin atribución | ga4 (filtrar en normalización) |

### Manejo de overlaps

GA4 trackea TODO el tráfico, incluyendo el que viene de canales paid. Esto causa overlap con los conectores de Google Ads y Meta Ads. Enfoque de MIH:

1. **En el Overview cross-channel**: usar conversiones de GA4 para el blended CPA (evita double-counting)
2. **En el drill-down de GA4**: mostrar TODO el tráfico (paid + organic + direct)
3. **Disclaimer en UI**: "GA4 data includes traffic from all sources including paid channels"
