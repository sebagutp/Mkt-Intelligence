#!/usr/bin/env bash
set -euo pipefail

# 05-deploy-frontend.sh
# Builds and deploys the dashboard frontend.
# Supports Vercel and Cloudflare Pages.

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DASHBOARD_DIR="${PROJECT_ROOT}/apps/dashboard"

if [ ! -d "$DASHBOARD_DIR" ]; then
  echo "  ✗ Dashboard directory not found at ${DASHBOARD_DIR}"
  exit 1
fi

cd "$DASHBOARD_DIR"

# Write frontend env file
echo "  → Writing .env.production..."
cat > .env.production <<ENVEOF
VITE_SUPABASE_URL=${SUPABASE_URL}
VITE_SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
ENVEOF

echo "  → Installing dependencies..."
npm ci --silent

echo "  → Building dashboard..."
npm run build

PLATFORM="${FRONTEND_PLATFORM:-vercel}"

case "$PLATFORM" in
  vercel)
    echo "  → Deploying to Vercel..."
    if command -v vercel &> /dev/null; then
      vercel --prod --yes 2>&1 | tail -3
      if [ -n "${FRONTEND_DOMAIN:-}" ]; then
        echo "  ℹ Remember to configure custom domain '${FRONTEND_DOMAIN}' in Vercel dashboard"
      fi
    else
      echo "  ⚠ Vercel CLI not found. Install with: npm i -g vercel"
      echo "  ℹ Build output is ready in ${DASHBOARD_DIR}/dist/"
      exit 1
    fi
    ;;
  cloudflare)
    echo "  → Deploying to Cloudflare Pages..."
    if command -v wrangler &> /dev/null; then
      wrangler pages deploy dist --project-name="mih-${CLIENT_SLUG}" 2>&1 | tail -3
    else
      echo "  ⚠ Wrangler CLI not found. Install with: npm i -g wrangler"
      echo "  ℹ Build output is ready in ${DASHBOARD_DIR}/dist/"
      exit 1
    fi
    ;;
  *)
    echo "  ⚠ Unknown platform '${PLATFORM}'. Build output is in ${DASHBOARD_DIR}/dist/"
    ;;
esac

echo "  ✓ Frontend deployment complete"
