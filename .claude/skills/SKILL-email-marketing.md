# Skill: Email Marketing — Métricas, Providers y Normalización

## Contexto

Este skill contiene el conocimiento de dominio para construir el conector de Email multi-provider (HU-010) y el panel drill-down de Email (HU-013). Cubre las APIs de Mailchimp, Brevo, el formato webhook, métricas de email, y normalización.

**HUs relacionadas**: HU-010, HU-013, HU-014

---

## Métricas fundamentales de Email Marketing

### Funnel de email

```
Sent → Delivered → Opened → Clicked → Converted → Unsubscribed/Bounced
```

| Métrica | Fórmula | Benchmark | Qué indica |
|---------|---------|-----------|------------|
| **Delivery Rate** | delivered / sent × 100 | >95% | Calidad de la lista y reputación del sender |
| **Open Rate** | opens / delivered × 100 | 20-30% | Efectividad del subject line y sender name |
| **Click Rate (CTR)** | clicks / delivered × 100 | 2-5% | Relevancia del contenido y CTA |
| **Click-to-Open Rate (CTOR)** | clicks / opens × 100 | 10-20% | Calidad del contenido para quienes abren |
| **Unsubscribe Rate** | unsubs / delivered × 100 | <0.5% | Fatiga de audiencia o contenido irrelevante |
| **Bounce Rate** | bounces / sent × 100 | <3% | Calidad de la lista (hard) o problemas técnicos (soft) |
| **Spam Complaint Rate** | complaints / delivered × 100 | <0.1% | Si >0.1%, riesgo de blacklist |
| **Conversion Rate** | conversions / clicks × 100 | 2-10% | Efectividad del landing post-click |
| **Revenue per Email** | revenue / sent | $0.05-0.50 | ROI directo del canal |

### Nota sobre Open Rate post-iOS 15

Apple Mail Privacy Protection (desde Sep 2021) pre-carga imágenes de tracking, inflando open rates. Implicación para MIH:
- **Open rate** es cada vez menos confiable como métrica
- **Click rate** es la métrica de engagement más confiable
- Mostrar disclaimer en UI: "Open rates may be inflated due to Apple Mail Privacy Protection"
- Considerar CTOR como métrica alternativa

---

## Normalización al schema de MIH

### Mapping conceptual

Email marketing es fundamentalmente diferente a paid ads. No tiene "impressions" ni "spend" en el sentido tradicional. Mapping:

```typescript
function normalizeEmailRow(row: EmailCampaignData): NormalizedRow {
  return {
    tenant_id: tenantId,
    channel: 'email',
    metric_date: row.send_date,                    // Fecha de envío
    source_campaign_id: row.campaign_id,
    campaign_name: row.campaign_name || row.subject_line,

    // Mapping al funnel unificado
    impressions: row.emails_sent,                   // Sent ≈ "reach"
    clicks: row.clicks,                             // Clicks directos
    spend: 0,                                       // Email generalmente no tiene spend directo
    conversions: row.clicks,                        // En email, clicks ≈ conversions (proxy)
    conversion_value: row.revenue || 0,             // Si hay tracking de revenue

    // Métricas calculadas
    ctr: safeDivide(row.clicks, row.emails_sent) * 100,  // Click rate
    cpc: 0,                                         // No hay spend
    cpa: 0,                                         // No hay spend
    roas: 0,                                        // No hay spend

    extra_metrics: {
      emails_sent: row.emails_sent,
      delivered: row.delivered,
      opens: row.opens,
      unique_opens: row.unique_opens,
      unique_clicks: row.unique_clicks,
      open_rate: safeDivide(row.opens, row.delivered) * 100,
      click_rate: safeDivide(row.clicks, row.delivered) * 100,
      ctor: safeDivide(row.clicks, row.opens) * 100,
      bounces: row.bounces,
      hard_bounces: row.hard_bounces,
      soft_bounces: row.soft_bounces,
      unsubscribes: row.unsubscribes,
      unsubscribe_rate: safeDivide(row.unsubscribes, row.delivered) * 100,
      bounce_rate: safeDivide(row.bounces, row.emails_sent) * 100,
      delivery_rate: safeDivide(row.delivered, row.emails_sent) * 100,
      subject_line: row.subject_line,
      list_id: row.list_id,
      list_name: row.list_name,
    },
  };
}
```

### Notas sobre conversiones en email

**clicks = conversions** es un proxy razonable para v1 porque:
1. La mayoría de plataformas de email no trackean conversiones post-click
2. El click en email = intención de acción
3. Para clientes con ecommerce, se puede override con revenue data

En v2: integrar con GA4 para atribución cross-channel (utm_source=email → conversion en GA4).

---

## Provider: Mailchimp

### API: Reports endpoint

```
GET https://{dc}.api.mailchimp.com/3.0/reports
```

- **Auth**: `Authorization: Basic {base64(apikey:API_KEY)}` o `apikey {API_KEY}`
- **dc**: último segmento del API key después del guión (ej: key `abc123-us21` → dc = `us21`)
- **Paginación**: `?count=100&offset=0` → incrementar offset

### Response structure

```json
{
  "reports": [
    {
      "id": "abc123def4",
      "campaign_title": "Newsletter Marzo 2026",
      "subject_line": "Las mejores ofertas de la semana",
      "type": "regular",
      "send_time": "2026-03-20T14:00:00+00:00",
      "emails_sent": 5420,
      "unsubscribed": 12,
      "bounces": {
        "hard_bounces": 3,
        "soft_bounces": 15,
        "syntax_errors": 0
      },
      "opens": {
        "opens_total": 2345,
        "unique_opens": 1876,
        "open_rate": 0.3459
      },
      "clicks": {
        "clicks_total": 456,
        "unique_clicks": 312,
        "click_rate": 0.0575,
        "last_click": "2026-03-21T09:23:00+00:00"
      },
      "list_id": "abc123",
      "list_name": "Newsletter Principal",
      "list_is_active": true
    }
  ],
  "total_items": 156
}
```

### Normalización Mailchimp → MIH

```typescript
function normalizeMailchimpReport(report: MailchimpReport): EmailCampaignData {
  return {
    campaign_id: report.id,
    campaign_name: report.campaign_title,
    subject_line: report.subject_line,
    send_date: report.send_time.split('T')[0],  // "2026-03-20"
    emails_sent: report.emails_sent,
    delivered: report.emails_sent - report.bounces.hard_bounces - report.bounces.soft_bounces,
    opens: report.opens.opens_total,
    unique_opens: report.opens.unique_opens,
    clicks: report.clicks.clicks_total,
    unique_clicks: report.clicks.unique_clicks,
    bounces: report.bounces.hard_bounces + report.bounces.soft_bounces,
    hard_bounces: report.bounces.hard_bounces,
    soft_bounces: report.bounces.soft_bounces,
    unsubscribes: report.unsubscribed,
    list_id: report.list_id,
    list_name: report.list_name,
    revenue: 0,  // Mailchimp reports tiene revenue en endpoint separado
  };
}
```

### Rate Limits de Mailchimp

- **10 concurrent connections** per API key
- **Max 10 requests/second**
- HTTP 429 con `Retry-After` header
- En la práctica, el endpoint de reports es liviano. 1 request trae hasta 1000 reports.

---

## Provider: Brevo (ex-SendinBlue)

### API: Transactional + Campaign reports

```
GET https://api.brevo.com/v3/emailCampaigns?status=sent&limit=50&offset=0
```

- **Auth**: `api-key: {API_KEY}` (header)
- **Paginación**: `limit` + `offset`

### Campos relevantes

```json
{
  "campaigns": [
    {
      "id": 123,
      "name": "Campaign Name",
      "subject": "Subject Line",
      "sentDate": "2026-03-20T14:00:00.000Z",
      "statistics": {
        "globalStats": {
          "sent": 5000,
          "delivered": 4850,
          "hardBounces": 50,
          "softBounces": 100,
          "uniqueClicks": 250,
          "clickers": 220,
          "complaints": 2,
          "uniqueOpens": 1500,
          "trackableOpens": 1800,
          "unsubscriptions": 10
        }
      }
    }
  ],
  "count": 45
}
```

---

## Provider: Webhook (Apps Script / Custom)

### Formato esperado por MIH

Para clientes que usan Google Apps Script u otro sistema custom, MIH acepta un POST con este formato:

```json
{
  "api_key": "webhook_secret_key",
  "campaigns": [
    {
      "name": "Newsletter Semanal",
      "date": "2026-03-20",
      "sent": 5000,
      "delivered": 4850,
      "opens": 1800,
      "unique_opens": 1500,
      "clicks": 300,
      "unique_clicks": 250,
      "bounces": 150,
      "hard_bounces": 50,
      "soft_bounces": 100,
      "unsubscribes": 10,
      "revenue": 0
    }
  ]
}
```

### Validación del webhook

```typescript
function validateWebhookPayload(body: unknown): WebhookPayload {
  if (!body || typeof body !== 'object') throw new Error('Invalid payload');
  const payload = body as Record<string, unknown>;

  if (!payload.api_key || typeof payload.api_key !== 'string') {
    throw new Error('Missing or invalid api_key');
  }

  if (!Array.isArray(payload.campaigns) || payload.campaigns.length === 0) {
    throw new Error('Missing or empty campaigns array');
  }

  // Validar cada campaign tiene los campos mínimos
  for (const campaign of payload.campaigns) {
    const required = ['name', 'date', 'sent'];
    for (const field of required) {
      if (!(field in campaign)) {
        throw new Error(`Campaign missing required field: ${field}`);
      }
    }
  }

  return payload as WebhookPayload;
}
```

### Google Apps Script ejemplo (para docs del cliente)

```javascript
// Script que envía datos de email a MIH
function sendToMIH() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Campaigns');
  const data = sheet.getDataRange().getValues();
  const headers = data[0];

  const campaigns = data.slice(1).map(row => ({
    name: row[0],
    date: Utilities.formatDate(row[1], 'UTC', 'yyyy-MM-dd'),
    sent: row[2],
    opens: row[3],
    clicks: row[4],
    bounces: row[5],
    unsubscribes: row[6]
  }));

  const response = UrlFetchApp.fetch('https://xxx.supabase.co/functions/v1/sync-email', {
    method: 'POST',
    contentType: 'application/json',
    payload: JSON.stringify({
      api_key: 'your_webhook_secret',
      campaigns: campaigns
    })
  });

  Logger.log(response.getResponseCode());
}
```

---

## Provider: CSV Import

### Formato CSV esperado

```csv
date,campaign_name,sent,delivered,opens,unique_opens,clicks,unique_clicks,bounces,unsubscribes
2026-03-20,Newsletter Marzo,5000,4850,1800,1500,300,250,150,10
2026-03-15,Promo Spring Sale,3200,3100,1200,980,200,170,100,5
```

### Parsing

```typescript
function parseCSV(csvText: string): EmailCampaignData[] {
  const lines = csvText.trim().split('\n');
  const headers = lines[0].split(',').map(h => h.trim());

  return lines.slice(1).map(line => {
    const values = line.split(',').map(v => v.trim());
    const row: Record<string, string> = {};
    headers.forEach((h, i) => { row[h] = values[i]; });

    return {
      campaign_id: `csv_${row.date}_${row.campaign_name.replace(/\s+/g, '_')}`,
      campaign_name: row.campaign_name,
      subject_line: row.campaign_name,
      send_date: row.date,
      emails_sent: parseInt(row.sent || '0'),
      delivered: parseInt(row.delivered || row.sent || '0'),
      opens: parseInt(row.opens || '0'),
      unique_opens: parseInt(row.unique_opens || row.opens || '0'),
      clicks: parseInt(row.clicks || '0'),
      unique_clicks: parseInt(row.unique_clicks || row.clicks || '0'),
      bounces: parseInt(row.bounces || '0'),
      hard_bounces: 0,
      soft_bounces: parseInt(row.bounces || '0'),
      unsubscribes: parseInt(row.unsubscribes || '0'),
      list_id: 'csv_import',
      list_name: 'CSV Import',
      revenue: parseFloat(row.revenue || '0'),
    };
  });
}
```

---

## Métricas específicas para panel drill-down de Email

### Columnas de la tabla de campañas

| Columna | Source | Formato | Color coding |
|---------|--------|---------|-------------|
| Campaign | campaign_name | text | — |
| Subject | extra_metrics.subject_line | text truncado (50 chars) | — |
| Sent | extra_metrics.emails_sent | X,XXX | — |
| Delivered | extra_metrics.delivered | X,XXX | — |
| Open Rate | extra_metrics.open_rate | XX.X% | >30% green, 15-30% neutral, <15% red |
| Click Rate | extra_metrics.click_rate | X.XX% | >5% green, 2-5% neutral, <2% red |
| CTOR | extra_metrics.ctor | XX.X% | >15% green, 8-15% neutral, <8% red |
| Bounces | extra_metrics.bounces | X,XXX | — |
| Unsubs | extra_metrics.unsubscribes | X,XXX | >1% red |
| Bounce Rate | extra_metrics.bounce_rate | X.X% | <2% green, 2-5% amber, >5% red |

### KPI cards del canal Email

1. **Campaigns Sent** — Count de campañas en el período
2. **Total Emails** — Suma de emails enviados
3. **Avg. Open Rate** — Promedio ponderado por volumen
4. **Avg. Click Rate** — Promedio ponderado
5. **Avg. CTOR** — Click-to-Open Rate
6. **Total Unsubscribes** — Suma de unsubs. Rojo si rate > 0.5%

### Señales de alerta específicas

| Señal | Condición | Causa probable | Acción |
|-------|-----------|----------------|--------|
| Delivery rate drop | Delivery < 90% | Problema de reputación o lista sucia | Limpiar lista, verificar SPF/DKIM |
| Open rate crash | Open rate < 50% del promedio | Subject line débil o sender reputation | A/B test subjects, revisar sender score |
| Unsubscribe spike | Unsub rate > 1% en un envío | Contenido irrelevante o frecuencia alta | Revisar segmentación y frecuencia |
| Bounce spike | Bounce rate > 5% | Lista vieja o importación mala | Limpiar lista, verificar emails |
| Spam complaints | Complaints > 0.1% | Riesgo de blacklist | URGENTE: pausar envíos, revisar opt-in |

---

## Deliverability — Conceptos para el dashboard

### Score de salud del canal

Para el panel de Insights, calcular un "Email Health Score" basado en:

```typescript
function calculateEmailHealthScore(metrics: EmailMetrics): number {
  let score = 100;

  // Delivery rate (peso: 30%)
  if (metrics.delivery_rate < 95) score -= (95 - metrics.delivery_rate) * 1.0;
  if (metrics.delivery_rate < 90) score -= 10; // Penalty extra

  // Bounce rate (peso: 20%)
  if (metrics.bounce_rate > 3) score -= (metrics.bounce_rate - 3) * 3;
  if (metrics.bounce_rate > 5) score -= 10;

  // Unsubscribe rate (peso: 20%)
  if (metrics.unsubscribe_rate > 0.5) score -= (metrics.unsubscribe_rate - 0.5) * 10;
  if (metrics.unsubscribe_rate > 1) score -= 15;

  // Open rate trend (peso: 15%)
  if (metrics.open_rate < 15) score -= 10;

  // Click rate (peso: 15%)
  if (metrics.click_rate < 1) score -= 10;

  return Math.max(0, Math.min(100, Math.round(score)));
}
// 80-100: Excellent, 60-79: Good, 40-59: Needs attention, <40: Critical
```

Este score se puede mostrar como un gauge o badge en el canal de email.