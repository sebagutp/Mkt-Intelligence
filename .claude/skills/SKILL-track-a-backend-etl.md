# Skill: Track A — Backend/ETL (Supabase Edge Functions + BigQuery)

## Contexto

Este skill aplica a todas las HUs del Track A: desarrollo de Edge Functions en Deno/TypeScript que extraen data de APIs de marketing, normalizan al schema unificado e insertan en BigQuery. Incluye el proxy de queries y el sistema de alertas.

**HUs cubiertas**: HU-004, HU-005, HU-006, HU-007, HU-009, HU-010, HU-011, HU-012, HU-015, HU-020

---

## Reglas obligatorias

### Arquitectura de conectores

1. **TODOS los conectores DEBEN extender `ConnectorBase`** de `_shared/connector-base.ts`. No crear conectores standalone.
2. El flujo siempre es: `get creds → get date range → fetch → normalize → insert → log`
3. Cada conector implementa solo 2 métodos abstractos: `fetchData()` y `normalize()`
4. El `serve()` handler siempre sigue el mismo patrón:
   ```typescript
   Deno.serve(async (req) => {
     const { tenant_id, channel_id } = await req.json();
     const connector = new XxxConnector(tenant_id, channel_id, config);
     const result = await connector.execute();
     return new Response(JSON.stringify(result), {
       headers: { 'Content-Type': 'application/json' }
     });
   });
   ```

### Retry y rate limits

5. **Retry exponencial**: 3 intentos, backoff 1s → 2s → 4s. Ya implementado en ConnectorBase, NO reimplementar.
6. **Rate limits**: respetar headers de cada API. NO paralelizar requests dentro de un conector.
7. LinkedIn tiene rate limits muy bajos (100/día). Agregar 500ms delay entre requests.

### Normalización

8. Toda data se normaliza a `NormalizedRow` (schema de `marketing_metrics`).
9. **Dedup key** = `channel__campaign_id__date`. BigQuery usa `insertId` para dedup.
10. Usar `SAFE_DIVIDE()` o divisiones seguras (check divisor !== 0) para métricas calculadas (CPA, ROAS, CTR, CPC).
11. Campos de dinero: siempre en USD. Google Ads usa `cost_micros / 1_000_000`. Meta usa `parseFloat(spend)`.

### Credenciales y seguridad

12. Credenciales NUNCA en código. Solo desde `api_credentials` de Supabase (encriptadas).
13. Leer credenciales via `CredentialManager` de `_shared/credential-manager.ts`.
14. OAuth tokens: refresh antes de usar si `expires_at < now() + 5min`.
15. Service Account JSON para BigQuery + GA4 (mismo key).

### BigQuery

16. Insertar en batches de 500 rows máximo.
17. Usar `insertId` = dedup key para evitar duplicados.
18. TODA query a BigQuery DEBE incluir filtro de fecha (`WHERE metric_date BETWEEN...`).
19. El proxy `bq-query` NUNCA acepta SQL arbitrario. Solo queries pre-armadas con params sanitizados.
20. Params permitidos: `days` (número), `channel` (string validada contra lista), `limit` (número).

### Logging

21. **SIEMPRE** logear resultado de sync via `supabase.rpc('log_sync')`. Nunca INSERT directo.
22. Log tanto success como error. Incluir: `rows_synced`, `duration_ms`, `error_message`.

### Deno específico

23. Usar Deno APIs nativas: `crypto.subtle` para JWT signing, `fetch` para HTTP.
24. Imports desde `esm.sh` para dependencias externas.
25. NO usar Node.js APIs (fs, path, etc.).
26. TypeScript estricto. NO usar `any`.

---

## Patrones de código

### Estructura de un conector nuevo

```
supabase/functions/sync-{channel}/index.ts    ← Único archivo
```

### Template de conector

```typescript
import { ConnectorBase } from '../_shared/connector-base.ts';
import { NormalizedRow } from '../_shared/types.ts';

class XxxConnector extends ConnectorBase {
  async fetchData(): Promise<RawApiResponse[]> {
    // 1. Refresh token si necesario
    // 2. Hacer request(s) a la API
    // 3. Manejar paginación
    // 4. Retornar raw data
  }

  normalize(rawData: RawApiResponse[]): NormalizedRow[] {
    return rawData.map(row => ({
      tenant_id: this.tenantId,
      channel: 'channel_name',
      metric_date: row.date,
      source_campaign_id: row.campaign_id,
      campaign_name: row.campaign_name,
      impressions: row.impressions,
      clicks: row.clicks,
      spend: row.spend, // Siempre en USD
      conversions: row.conversions,
      conversion_value: row.conversion_value,
      ctr: safeDivide(row.clicks, row.impressions),
      cpc: safeDivide(row.spend, row.clicks),
      cpa: safeDivide(row.spend, row.conversions),
      roas: safeDivide(row.conversion_value, row.spend),
      extra_metrics: { /* métricas específicas del canal */ },
      _dedup_key: `channel_name__${row.campaign_id}__${row.date}`,
    }));
  }
}
```

### Proxy de queries (bq-query)

```typescript
// Map de queries permitidas — NUNCA SQL dinámico
const QUERIES: Record<string, (params: Params) => string> = {
  overview_kpis: (p) => `SELECT ... WHERE metric_date >= DATE_SUB(CURRENT_DATE(), INTERVAL ${parseInt(p.days)} DAY)`,
  // ...
};
```

---

## Checklist pre-PR para Track A

- [ ] Conector extiende ConnectorBase
- [ ] fetchData() maneja paginación completa
- [ ] normalize() produce NormalizedRow válidos
- [ ] Dedup key correcto (channel__campaign_id__date)
- [ ] Divisiones seguras (no division by zero)
- [ ] Credenciales leídas de Supabase, no hardcodeadas
- [ ] Log de sync registrado (success y error)
- [ ] Rate limits respetados
- [ ] Batches de ≤500 rows para BigQuery insert
- [ ] TypeScript estricto, sin `any`
