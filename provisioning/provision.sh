#!/usr/bin/env bash
set -euo pipefail

# MIH — Provision new client
# Usage: ./provisioning/provision.sh provisioning/clients/<name>.env

if [ $# -lt 1 ]; then
  echo "Usage: $0 <client-env-file>"
  exit 1
fi

ENV_FILE="$1"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: File $ENV_FILE not found"
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

echo "=== MIH Provisioning: $CLIENT_NAME ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[1/6] Setting up BigQuery..."
bash "$SCRIPT_DIR/scripts/01-setup-bigquery.sh"

echo "[2/6] Setting up Supabase..."
bash "$SCRIPT_DIR/scripts/02-setup-supabase.sh"

echo "[3/6] Deploying Edge Functions..."
bash "$SCRIPT_DIR/scripts/03-deploy-functions.sh"

echo "[4/6] Registering tenant..."
bash "$SCRIPT_DIR/scripts/04-register-tenant.sh"

echo "[5/6] Deploying frontend..."
bash "$SCRIPT_DIR/scripts/05-deploy-frontend.sh"

echo "[6/6] Testing connections..."
bash "$SCRIPT_DIR/scripts/06-test-connections.sh"

echo "=== Provisioning complete for $CLIENT_NAME ==="
