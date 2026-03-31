#!/usr/bin/env bash
set -euo pipefail

# cloud-eyes: Deploy to Railway
# Usage: ./scripts/deploy-railway.sh [token]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

TOKEN="${1:-$(openssl rand -hex 24)}"

echo "============================================"
echo "  cloud-eyes - Railway Deployment"
echo "============================================"
echo ""

# Check for railway CLI
if ! command -v railway &> /dev/null; then
    echo "[ERROR] Railway CLI is not installed."
    echo "Install it: npm install -g @railway/cli"
    echo "Or: brew install railway"
    exit 1
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "[ERROR] Not logged in to Railway."
    echo "Run: railway login"
    exit 1
fi

cd "$PROJECT_DIR"

echo "[1/4] Initializing Railway project..."
railway init --name cloud-eyes 2>/dev/null || echo "  Project already exists, continuing..."

echo "[2/4] Setting environment variables..."
railway variables set TOKEN="$TOKEN"
railway variables set CONCURRENT=5
railway variables set TIMEOUT=60000

echo "[3/4] Deploying..."
railway up --detach

echo "[4/4] Getting deployment URL..."
RAILWAY_URL=$(railway domain 2>/dev/null || echo "your-app.up.railway.app")

echo ""
echo "============================================"
echo "  Deployment complete!"
echo "============================================"
echo ""
echo "  App URL:       https://$RAILWAY_URL"
echo "  WebSocket URL: wss://$RAILWAY_URL?token=$TOKEN"
echo "  Health check:  https://$RAILWAY_URL/config?token=$TOKEN"
echo ""
echo "  MCP config (add to .mcp.json):"
echo ""
echo "  {"
echo "    \"mcpServers\": {"
echo "      \"cloud-eyes\": {"
echo "        \"command\": \"npx\","
echo "        \"args\": [\"-y\", \"@playwright/mcp@latest\", \"--cdp-endpoint\", \"wss://$RAILWAY_URL?token=$TOKEN\"]"
echo "      }"
echo "    }"
echo "  }"
echo ""
echo "  Token: $TOKEN"
echo "  (save this - you will need it to connect)"
echo "============================================"
