import { serve } from 'https://deno.land/std@0.208.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const GOOGLE_OAUTH_CLIENT_ID = Deno.env.get('GOOGLE_OAUTH_CLIENT_ID') ?? '';
const GOOGLE_OAUTH_CLIENT_SECRET = Deno.env.get('GOOGLE_OAUTH_CLIENT_SECRET') ?? '';

// How far ahead to refresh tokens (7 days)
const REFRESH_WINDOW_DAYS = 7;
// Stale sync threshold (36 hours)
const STALE_SYNC_HOURS = 36;

interface Credential {
  id: string;
  tenant_id: string;
  channel: string;
  credential_type: string;
  refresh_token: string | null;
  token_expires_at: string | null;
  extra: Record<string, string>;
}

interface RefreshResult {
  credential_id: string;
  channel: string;
  success: boolean;
  error?: string;
}

async function refreshGoogleToken(credential: Credential): Promise<{ access_token: string; expires_in: number }> {
  if (!credential.refresh_token) {
    throw new Error('No refresh_token available');
  }

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: GOOGLE_OAUTH_CLIENT_ID,
      client_secret: GOOGLE_OAUTH_CLIENT_SECRET,
      refresh_token: credential.refresh_token,
      grant_type: 'refresh_token',
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Google token refresh failed (${response.status}): ${body}`);
  }

  return response.json();
}

async function refreshMetaToken(credential: Credential): Promise<{ access_token: string; expires_in: number }> {
  const currentToken = credential.extra?.access_token ?? '';
  if (!currentToken) {
    throw new Error('No current access_token for Meta long-lived exchange');
  }

  const metaAppId = Deno.env.get('META_APP_ID') ?? credential.extra?.app_id ?? '';
  const metaAppSecret = Deno.env.get('META_APP_SECRET') ?? credential.extra?.app_secret ?? '';

  const params = new URLSearchParams({
    grant_type: 'fb_exchange_token',
    client_id: metaAppId,
    client_secret: metaAppSecret,
    fb_exchange_token: currentToken,
  });

  const response = await fetch(`https://graph.facebook.com/v19.0/oauth/access_token?${params}`);

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Meta token exchange failed (${response.status}): ${body}`);
  }

  return response.json();
}

async function refreshLinkedInToken(credential: Credential): Promise<{ access_token: string; expires_in: number }> {
  if (!credential.refresh_token) {
    throw new Error('No refresh_token available for LinkedIn');
  }

  const linkedInClientId = Deno.env.get('LINKEDIN_CLIENT_ID') ?? credential.extra?.client_id ?? '';
  const linkedInClientSecret = Deno.env.get('LINKEDIN_CLIENT_SECRET') ?? credential.extra?.client_secret ?? '';

  const response = await fetch('https://www.linkedin.com/oauth/v2/accessToken', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: credential.refresh_token,
      client_id: linkedInClientId,
      client_secret: linkedInClientSecret,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`LinkedIn token refresh failed (${response.status}): ${body}`);
  }

  return response.json();
}

async function refreshCredential(credential: Credential): Promise<RefreshResult> {
  try {
    let result: { access_token: string; expires_in: number };

    switch (credential.channel) {
      case 'ga4':
      case 'google_ads':
        result = await refreshGoogleToken(credential);
        break;
      case 'meta_ads':
        result = await refreshMetaToken(credential);
        break;
      case 'linkedin_ads':
      case 'linkedin_organic':
        result = await refreshLinkedInToken(credential);
        break;
      default:
        return { credential_id: credential.id, channel: credential.channel, success: true };
    }

    const expiresAt = new Date(Date.now() + result.expires_in * 1000).toISOString();

    const { error } = await supabase
      .from('api_credentials')
      .update({
        access_token: result.access_token,
        token_expires_at: expiresAt,
        extra: { ...credential.extra, access_token: result.access_token },
      })
      .eq('id', credential.id);

    if (error) throw new Error(`DB update failed: ${error.message}`);

    return { credential_id: credential.id, channel: credential.channel, success: true };
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return { credential_id: credential.id, channel: credential.channel, success: false, error: message };
  }
}

async function runHealthChecks(): Promise<{ stale_channels: Array<{ tenant_id: string; channel: string; last_success: string | null }> }> {
  const cutoff = new Date(Date.now() - STALE_SYNC_HOURS * 60 * 60 * 1000).toISOString();

  // Find enabled channels with no recent successful sync
  const { data: channels } = await supabase
    .from('tenant_channels')
    .select('tenant_id, channel')
    .eq('is_enabled', true);

  if (!channels || channels.length === 0) {
    return { stale_channels: [] };
  }

  const stale: Array<{ tenant_id: string; channel: string; last_success: string | null }> = [];

  for (const ch of channels) {
    const { data: logs } = await supabase
      .from('sync_logs')
      .select('started_at')
      .eq('tenant_id', ch.tenant_id)
      .eq('channel', ch.channel)
      .eq('status', 'success')
      .gte('started_at', cutoff)
      .limit(1);

    if (!logs || logs.length === 0) {
      // Get the last success date for context
      const { data: lastLog } = await supabase
        .from('sync_logs')
        .select('started_at')
        .eq('tenant_id', ch.tenant_id)
        .eq('channel', ch.channel)
        .eq('status', 'success')
        .order('started_at', { ascending: false })
        .limit(1);

      stale.push({
        tenant_id: ch.tenant_id,
        channel: ch.channel,
        last_success: lastLog?.[0]?.started_at ?? null,
      });
    }
  }

  return { stale_channels: stale };
}

serve(async (req) => {
  try {
    // Allow both GET (cron) and POST (manual trigger)
    if (req.method !== 'GET' && req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    console.log('Token refresh started');

    // ── Step 1: Find credentials expiring within REFRESH_WINDOW_DAYS ──
    const windowDate = new Date(Date.now() + REFRESH_WINDOW_DAYS * 24 * 60 * 60 * 1000).toISOString();

    const { data: expiringCredentials, error: queryError } = await supabase
      .from('api_credentials')
      .select('id, tenant_id, channel, credential_type, refresh_token, token_expires_at, extra')
      .eq('credential_type', 'oauth2')
      .not('token_expires_at', 'is', null)
      .lt('token_expires_at', windowDate);

    if (queryError) {
      throw new Error(`Query failed: ${queryError.message}`);
    }

    const credentials = (expiringCredentials ?? []) as Credential[];
    console.log(`Found ${credentials.length} credentials to refresh`);

    // ── Step 2: Refresh each credential sequentially (respect rate limits) ──
    const results: RefreshResult[] = [];
    for (const cred of credentials) {
      const result = await refreshCredential(cred);
      results.push(result);
      console.log(`${result.channel} (${result.credential_id}): ${result.success ? 'OK' : result.error}`);
    }

    // ── Step 3: Health checks ──
    const healthCheck = await runHealthChecks();
    if (healthCheck.stale_channels.length > 0) {
      console.warn(`Stale channels (no success in ${STALE_SYNC_HOURS}h):`, healthCheck.stale_channels);

      // Trigger alert-dispatcher for stale channels
      for (const stale of healthCheck.stale_channels) {
        await supabase.functions.invoke('alert-dispatcher', {
          body: {
            type: 'stale_sync',
            tenant_id: stale.tenant_id,
            channel: stale.channel,
            last_success: stale.last_success,
          },
        }).catch(err => console.error('Alert dispatch failed:', err));
      }
    }

    const refreshed = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;

    const summary = {
      refreshed,
      failed,
      stale_channels: healthCheck.stale_channels.length,
      details: results,
    };

    console.log(`Token refresh complete: ${refreshed} refreshed, ${failed} failed, ${healthCheck.stale_channels.length} stale channels`);

    return new Response(JSON.stringify(summary), {
      headers: { 'Content-Type': 'application/json' },
      status: failed > 0 && refreshed === 0 ? 500 : 200,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('Token refresh error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
