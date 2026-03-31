#!/usr/bin/env bash
set -euo pipefail

# cloud-eyes: Deploy to Fly.io
# Usage: ./scripts/deploy-fly.sh [token]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

TOKEN="${1:-$(openssl rand -hex 24)}"
APP_NAME="cloud-eyes"

echo "============================================"
echo "  cloud-eyes - Fly.io Deployment"
echo "============================================"
echo ""

# Check for flyctl
if ! command -v flyctl &> /dev/null; then
    echo "[ERROR] flyctl is not installed."
    echo "Install it: curl -L https://fly.io/install.sh | sh"
    exit 1
fi

# Check if logged in
if ! flyctl auth whoami &> /dev/null; then
    echo "[ERROR] Not logged in to Fly.io."
    echo "Run: flyctl auth login"
    exit 1
fi

cd "$PROJECT_DIR"

echo "[1/4] Creating Fly app..."
flyctl apps create "$APP_NAME" --machines 2>/dev/null || echo "  App '$APP_NAME' already exists, continuing..."

echo "[2/4] Setting token secret..."
echo "$TOKEN" | flyctl secrets set TOKEN="$TOKEN" --app "$APP_NAME"

echo "[3/4] Deploying..."
flyctl deploy --app "$APP_NAME" --ha=false

echo "[4/4] Getting deployment info..."
APP_URL=$(flyctl info --app "$APP_NAME" -j 2>/dev/null | grep -o '"Hostname":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "$APP_NAME.fly.dev")

echo ""
echo "============================================"
echo "  Deployment complete!"
echo "============================================"
echo ""
echo "  App URL:       https://$APP_URL"
echo "  WebSocket URL: wss://$APP_URL?token=$TOKEN"
echo "  Health check:  https://$APP_URL/config?token=$TOKEN"
echo ""
echo "  MCP config (add to .mcp.json):"
echo ""
echo "  {"
echo "    \"mcpServers\": {"
echo "      \"cloud-eyes\": {"
echo "        \"command\": \"npx\","
echo "        \"args\": [\"-y\", \"@playwright/mcp@latest\", \"--cdp-endpoint\", \"wss://$APP_URL?token=$TOKEN\"]"
echo "      }"
echo "    }"
echo "  }"
echo ""
echo "  Token: $TOKEN"
echo "  (save this - you will need it to connect)"
echo "============================================"
