#!/usr/bin/env bash
set -euo pipefail

# 03-deploy-functions.sh
# Deploys all Supabase Edge Functions for the client.
# Expects SUPABASE_PROJECT_REF from client .env.

if [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
  echo "  ✗ SUPABASE_PROJECT_REF is required"
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FUNCTIONS_DIR="${PROJECT_ROOT}/supabase/functions"

# List of Edge Functions to deploy
FUNCTIONS=(
  "bq-query"
  "sync-ga4"
  "sync-google-ads"
  "sync-meta-ads"
  "sync-email"
  "sync-linkedin"
  "sync-orchestrator"
  "sync-webhook"
  "token-refresh"
  "alert-dispatcher"
)

echo "  → Linking to project ${SUPABASE_PROJECT_REF}..."
cd "$PROJECT_ROOT"
npx supabase link --project-ref "$SUPABASE_PROJECT_REF" 2>/dev/null || true

for fn in "${FUNCTIONS[@]}"; do
  if [ -d "${FUNCTIONS_DIR}/${fn}" ]; then
    echo "  → Deploying ${fn}..."
    npx supabase functions deploy "$fn" --no-verify-jwt 2>&1 | tail -1
  else
    echo "  ⚠ Skipping ${fn} (directory not found)"
  fi
done

echo "  ✓ Edge Functions deployment complete"
