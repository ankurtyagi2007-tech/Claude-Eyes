#!/usr/bin/env bash
set -euo pipefail

# cloud-eyes: Deploy the Playwright MCP server to Fly.io
# This is the remote MCP server that browser-based Claude Code connects to.
# It bridges Claude Code to your Browserless cloud browser via HTTP/SSE.
#
# Usage: ./scripts/deploy-mcp-fly.sh <cdp-endpoint>
# Example: ./scripts/deploy-mcp-fly.sh "wss://production-sfo.browserless.io/chromium/playwright?token=YOUR_TOKEN"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CDP_ENDPOINT="${1:?Usage: deploy-mcp-fly.sh <cdp-endpoint>}"
APP_NAME="cloud-eyes-mcp"

echo "============================================"
echo "  cloud-eyes - MCP Server Deployment (Fly.io)"
echo "============================================"
echo ""
echo "  This deploys the Playwright MCP server as a"
echo "  remote HTTP endpoint for browser-based Claude Code."
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

echo "[2/4] Setting CDP endpoint secret..."
flyctl secrets set CDP_ENDPOINT="$CDP_ENDPOINT" --app "$APP_NAME"

echo "[3/4] Deploying MCP server..."
flyctl deploy --app "$APP_NAME" --config fly.mcp.toml --ha=false

echo "[4/4] Getting deployment info..."
APP_URL=$(flyctl info --app "$APP_NAME" -j 2>/dev/null | grep -o '"Hostname":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "$APP_NAME.fly.dev")

echo ""
echo "============================================"
echo "  MCP Server deployed!"
echo "============================================"
echo ""
echo "  MCP Server URL: https://$APP_URL"
echo "  SSE endpoint:   https://$APP_URL/sse"
echo "  MCP endpoint:   https://$APP_URL/mcp"
echo ""
echo "  For Claude Code in the browser:"
echo "  1. Go to claude.ai/code"
echo "  2. Open Settings > Connectors (or Customize)"
echo "  3. Click 'Add custom connector'"
echo "  4. Name:  cloud-eyes"
echo "     URL:   https://$APP_URL/mcp"
echo "  5. Save"
echo ""
echo "  For Claude Code CLI:"
echo "  claude mcp add cloud-eyes --url https://$APP_URL/mcp"
echo ""
echo "============================================"
