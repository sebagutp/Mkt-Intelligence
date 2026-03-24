#!/usr/bin/env bash
set -euo pipefail

# 06-test-connections.sh
# Verifies BigQuery, Supabase, and tenant registration are working.

PASS=0
FAIL=0

check() {
  local name="$1"
  local result="$2"
  if [ "$result" -eq 0 ]; then
    echo "  ✓ ${name}"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${name}"
    FAIL=$((FAIL + 1))
  fi
}

# ── BigQuery ──────────────────────────────────────────────────────────────
echo "  → Testing BigQuery..."

bq query --use_legacy_sql=false --nouse_cache \
  "SELECT 1 AS test FROM \`${GCP_PROJECT_ID}.${BQ_DATASET}.marketing_metrics\` LIMIT 0" \
  > /dev/null 2>&1
check "BigQuery dataset + marketing_metrics table accessible" $?

bq query --use_legacy_sql=false --nouse_cache \
  "SELECT 1 AS test FROM \`${GCP_PROJECT_ID}.${BQ_DATASET}.campaign_details\` LIMIT 0" \
  > /dev/null 2>&1
check "BigQuery campaign_details table accessible" $?

bq query --use_legacy_sql=false --nouse_cache \
  "SELECT 1 AS test FROM \`${GCP_PROJECT_ID}.${BQ_DATASET}.channel_daily_summary\` LIMIT 0" \
  > /dev/null 2>&1
check "BigQuery channel_daily_summary table accessible" $?

# ── Supabase API ──────────────────────────────────────────────────────────
echo "  → Testing Supabase..."

status=$(curl -s -o /dev/null -w "%{http_code}" \
  "${SUPABASE_URL}/rest/v1/" \
  -H "apikey: ${SUPABASE_ANON_KEY}")
[ "$status" = "200" ] 2>/dev/null
check "Supabase REST API responds (HTTP ${status})" $?

# ── Tenant exists ─────────────────────────────────────────────────────────
echo "  → Testing tenant registration..."

tenant_response=$(curl -s \
  "${SUPABASE_URL}/rest/v1/tenants?slug=eq.${CLIENT_SLUG}&select=id,name,slug" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

echo "$tenant_response" | grep -q "$CLIENT_SLUG" 2>/dev/null
check "Tenant '${CLIENT_SLUG}' exists in database" $?

# ── Dashboard config exists ───────────────────────────────────────────────
branding_response=$(curl -s \
  "${SUPABASE_URL}/rest/v1/dashboard_configs?select=brand_primary&tenant_id=eq.$(echo "$tenant_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}")

echo "$branding_response" | grep -q "brand_primary" 2>/dev/null
check "Dashboard branding config exists" $?

# ── Summary ───────────────────────────────────────────────────────────────
echo ""
echo "  Results: ${PASS} passed, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  echo "  ⚠ Some checks failed. Review the output above."
  exit 1
fi

echo "  ✓ All connection tests passed"
