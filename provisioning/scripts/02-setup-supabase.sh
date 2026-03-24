#!/usr/bin/env bash
set -euo pipefail

# 02-setup-supabase.sh
# Runs Supabase migrations against the client's Supabase instance.
# Expects SUPABASE_DB_URL from client .env.
# Idempotent: migrations use IF NOT EXISTS / CREATE OR REPLACE.

MIGRATIONS_DIR="$(cd "$(dirname "$0")/../.." && pwd)/supabase/migrations"

if [ -z "${SUPABASE_DB_URL:-}" ]; then
  echo "  ✗ SUPABASE_DB_URL is not set"
  exit 1
fi

echo "  → Testing database connection..."
if ! psql "$SUPABASE_DB_URL" -c "SELECT 1" > /dev/null 2>&1; then
  echo "  ✗ Cannot connect to Supabase database"
  exit 1
fi

echo "  → Creating migrations tracking table if needed..."
psql "$SUPABASE_DB_URL" -c "
  CREATE TABLE IF NOT EXISTS _mih_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
" > /dev/null

for migration_file in "$MIGRATIONS_DIR"/*.sql; do
  filename=$(basename "$migration_file")

  # Skip if already applied
  already_applied=$(psql "$SUPABASE_DB_URL" -tAc \
    "SELECT COUNT(*) FROM _mih_migrations WHERE filename = '${filename}'")

  if [ "$already_applied" -gt 0 ]; then
    echo "  ℹ Skipping ${filename} (already applied)"
    continue
  fi

  echo "  → Applying ${filename}..."
  psql "$SUPABASE_DB_URL" -f "$migration_file"

  psql "$SUPABASE_DB_URL" -c \
    "INSERT INTO _mih_migrations (filename) VALUES ('${filename}')" > /dev/null

  echo "  ✓ Applied ${filename}"
done

echo "  ✓ Supabase migrations complete"
