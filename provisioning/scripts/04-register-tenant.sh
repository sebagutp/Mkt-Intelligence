#!/usr/bin/env bash
set -euo pipefail

# 04-register-tenant.sh
# Registers a new tenant in Supabase with branding + enabled channels.
# Idempotent: checks if tenant slug already exists before inserting.

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then
  echo "  ✗ SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required"
  exit 1
fi

API="${SUPABASE_URL}/rest/v1"
AUTH_HEADER="apikey: ${SUPABASE_SERVICE_ROLE_KEY}"
ROLE_HEADER="Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}"
CONTENT_TYPE="Content-Type: application/json"
PREFER="Prefer: return=representation"

# Check if tenant already exists
echo "  → Checking if tenant '${CLIENT_SLUG}' exists..."
existing=$(curl -s -o /dev/null -w "%{http_code}" \
  "${API}/tenants?slug=eq.${CLIENT_SLUG}&select=id" \
  -H "$AUTH_HEADER" -H "$ROLE_HEADER")

if [ "$existing" = "200" ]; then
  existing_body=$(curl -s \
    "${API}/tenants?slug=eq.${CLIENT_SLUG}&select=id" \
    -H "$AUTH_HEADER" -H "$ROLE_HEADER")

  if [ "$existing_body" != "[]" ]; then
    TENANT_ID=$(echo "$existing_body" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo "  ℹ Tenant already exists (id: ${TENANT_ID}), updating..."

    # Update existing tenant
    curl -s -o /dev/null -X PATCH \
      "${API}/tenants?slug=eq.${CLIENT_SLUG}" \
      -H "$AUTH_HEADER" -H "$ROLE_HEADER" -H "$CONTENT_TYPE" \
      -d "{
        \"name\": \"${CLIENT_NAME}\",
        \"plan\": \"${PLAN:-starter}\",
        \"bq_project_id\": \"${GCP_PROJECT_ID}\",
        \"bq_dataset\": \"${BQ_DATASET}\",
        \"monthly_budget\": ${MONTHLY_BUDGET:-0},
        \"timezone\": \"${CLIENT_TIMEZONE:-America/Santiago}\"
      }"
  fi
fi

if [ -z "${TENANT_ID:-}" ]; then
  echo "  → Creating tenant '${CLIENT_NAME}'..."
  response=$(curl -s \
    "${API}/tenants" \
    -H "$AUTH_HEADER" -H "$ROLE_HEADER" -H "$CONTENT_TYPE" -H "$PREFER" \
    -d "{
      \"name\": \"${CLIENT_NAME}\",
      \"slug\": \"${CLIENT_SLUG}\",
      \"plan\": \"${PLAN:-starter}\",
      \"bq_project_id\": \"${GCP_PROJECT_ID}\",
      \"bq_dataset\": \"${BQ_DATASET}\",
      \"monthly_budget\": ${MONTHLY_BUDGET:-0},
      \"timezone\": \"${CLIENT_TIMEZONE:-America/Santiago}\"
    }")

  TENANT_ID=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

  if [ -z "$TENANT_ID" ]; then
    echo "  ✗ Failed to create tenant. Response: ${response}"
    exit 1
  fi

  echo "  ✓ Tenant created (id: ${TENANT_ID})"
fi

# ── Upsert dashboard_configs (branding) ────────────────────────────────────
echo "  → Setting up branding..."
curl -s -o /dev/null -X POST \
  "${API}/dashboard_configs" \
  -H "$AUTH_HEADER" -H "$ROLE_HEADER" -H "$CONTENT_TYPE" \
  -H "Prefer: resolution=merge-duplicates" \
  -d "{
    \"tenant_id\": \"${TENANT_ID}\",
    \"brand_primary\": \"${BRAND_PRIMARY_COLOR:-#2563eb}\",
    \"brand_accent\": \"${BRAND_ACCENT_COLOR:-#f59e0b}\",
    \"logo_url\": \"${BRAND_LOGO_URL:-}\",
    \"company_name\": \"${BRAND_COMPANY_NAME:-${CLIENT_NAME}}\",
    \"custom_domain\": \"${FRONTEND_DOMAIN:-}\"
  }"

# ── Register enabled channels ──────────────────────────────────────────────
echo "  → Registering channels..."

register_channel() {
  local channel="$1"
  local enabled="$2"
  local config="$3"

  curl -s -o /dev/null -X POST \
    "${API}/tenant_channels" \
    -H "$AUTH_HEADER" -H "$ROLE_HEADER" -H "$CONTENT_TYPE" \
    -H "Prefer: resolution=merge-duplicates" \
    -d "{
      \"tenant_id\": \"${TENANT_ID}\",
      \"channel\": \"${channel}\",
      \"is_enabled\": ${enabled},
      \"config\": ${config}
    }"

  local status_icon="✓"
  [ "$enabled" = "false" ] && status_icon="○"
  echo "    ${status_icon} ${channel} (enabled: ${enabled})"
}

register_channel "ga4" "${ENABLE_GA4:-false}" \
  "{\"property_id\": \"${GA4_PROPERTY_ID:-}\"}"

register_channel "google_ads" "${ENABLE_GOOGLE_ADS:-false}" \
  "{\"customer_id\": \"${GOOGLE_ADS_CUSTOMER_ID:-}\"}"

register_channel "meta_ads" "${ENABLE_META_ADS:-false}" \
  "{\"ad_account_id\": \"${META_AD_ACCOUNT_ID:-}\"}"

register_channel "email" "${ENABLE_EMAIL:-false}" \
  "{\"provider\": \"${EMAIL_PROVIDER:-}\"}"

register_channel "linkedin_ads" "${ENABLE_LINKEDIN:-false}" \
  "{\"organization_id\": \"${LINKEDIN_ORGANIZATION_ID:-}\"}"

echo "  ✓ Tenant registration complete (id: ${TENANT_ID})"
