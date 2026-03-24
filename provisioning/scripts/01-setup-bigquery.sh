#!/usr/bin/env bash
set -euo pipefail

# 01-setup-bigquery.sh
# Creates BigQuery dataset + tables for a new MIH client.
# Expects env vars from client .env (sourced by provision.sh).
# Idempotent: uses IF NOT EXISTS for all objects.

echo "  → Authenticating with GCP service account..."
if [ -n "${BQ_SERVICE_ACCOUNT_KEY_FILE:-}" ] && [ -f "$BQ_SERVICE_ACCOUNT_KEY_FILE" ]; then
  gcloud auth activate-service-account --key-file="$BQ_SERVICE_ACCOUNT_KEY_FILE" --quiet
else
  echo "  ⚠ No BQ_SERVICE_ACCOUNT_KEY_FILE set — using current gcloud auth"
fi

gcloud config set project "$GCP_PROJECT_ID" --quiet

echo "  → Creating dataset ${BQ_DATASET} (location: ${BQ_LOCATION:-US})..."
bq --location="${BQ_LOCATION:-US}" mk \
  --dataset \
  --default_table_expiration=0 \
  --description="MIH marketing data for ${CLIENT_NAME}" \
  "${GCP_PROJECT_ID}:${BQ_DATASET}" 2>/dev/null || echo "  ℹ Dataset already exists"

SCHEMA_DIR="$(cd "$(dirname "$0")/../.." && pwd)/bigquery/schemas"

for schema_file in "$SCHEMA_DIR"/*.sql; do
  table_name=$(basename "$schema_file" .sql)
  echo "  → Creating table ${table_name}..."

  # Replace placeholders with actual project/dataset values
  sql=$(sed \
    -e "s|{{PROJECT_ID}}|${GCP_PROJECT_ID}|g" \
    -e "s|{{DATASET}}|${BQ_DATASET}|g" \
    "$schema_file")

  bq query \
    --use_legacy_sql=false \
    --nouse_cache \
    "$sql" 2>/dev/null || echo "  ℹ Table ${table_name} already exists"
done

echo "  ✓ BigQuery setup complete"
