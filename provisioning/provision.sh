#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MIH — Provision New Client
# Orchestrates the full setup: BigQuery → Supabase → Functions → Tenant → Frontend → Tests
# Usage: ./provisioning/provision.sh provisioning/clients/<name>.env
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "\n${BLUE}[$1/6]${NC} $2"; }
log_ok()   { echo -e "${GREEN}  ✓ $1${NC}"; }
log_warn() { echo -e "${YELLOW}  ⚠ $1${NC}"; }
log_err()  { echo -e "${RED}  ✗ $1${NC}"; }

if [ $# -lt 1 ]; then
  echo "Usage: $0 <client-env-file>"
  echo "  Example: $0 provisioning/clients/datawalt.env"
  exit 1
fi

ENV_FILE="$1"

if [ ! -f "$ENV_FILE" ]; then
  log_err "File $ENV_FILE not found"
  exit 1
fi

# Validate required vars before starting
# shellcheck disable=SC1090
source "$ENV_FILE"

required_vars=(CLIENT_NAME CLIENT_SLUG GCP_PROJECT_ID BQ_DATASET SUPABASE_URL SUPABASE_SERVICE_ROLE_KEY)
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    log_err "Required variable ${var} is not set in ${ENV_FILE}"
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "\n${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  MIH Provisioning: ${CLIENT_NAME}${NC}"
echo -e "${BLUE}  Slug: ${CLIENT_SLUG}${NC}"
echo -e "${BLUE}  Plan: ${PLAN:-starter}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"

START_TIME=$(date +%s)

log_step 1 "Setting up BigQuery..."
bash "$SCRIPT_DIR/scripts/01-setup-bigquery.sh"

log_step 2 "Setting up Supabase database..."
bash "$SCRIPT_DIR/scripts/02-setup-supabase.sh"

log_step 3 "Deploying Edge Functions..."
bash "$SCRIPT_DIR/scripts/03-deploy-functions.sh"

log_step 4 "Registering tenant..."
bash "$SCRIPT_DIR/scripts/04-register-tenant.sh"

log_step 5 "Deploying frontend..."
bash "$SCRIPT_DIR/scripts/05-deploy-frontend.sh"

log_step 6 "Testing connections..."
bash "$SCRIPT_DIR/scripts/06-test-connections.sh"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Provisioning complete for ${CLIENT_NAME}${NC}"
echo -e "${GREEN}  Duration: ${DURATION}s${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "    1. Create admin user: invite ${CLIENT_EMAIL} via Supabase Auth dashboard"
echo "    2. Add OAuth credentials for enabled channels"
echo "    3. Trigger first sync: POST ${SUPABASE_URL}/functions/v1/sync-orchestrator"
echo "    4. Verify data in dashboard: https://${FRONTEND_DOMAIN:-localhost:5173}"
