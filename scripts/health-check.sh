#!/usr/bin/env bash
set -euo pipefail

# cloud-eyes: Health check for cloud browser
# Usage: ./scripts/health-check.sh <browser-url> <token>
# Example: ./scripts/health-check.sh https://cloud-eyes.fly.dev my-secret-token
# Example: ./scripts/health-check.sh http://localhost:3000 local-dev-token

BROWSER_URL="${1:?Usage: health-check.sh <browser-url> <token>}"
TOKEN="${2:?Usage: health-check.sh <browser-url> <token>}"

# Strip trailing slash
BROWSER_URL="${BROWSER_URL%/}"

echo "============================================"
echo "  cloud-eyes - Health Check"
echo "============================================"
echo ""
echo "  Target: $BROWSER_URL"
echo ""

# Test 1: Config endpoint
echo "[1/3] Checking /config endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BROWSER_URL/config?token=$TOKEN" --max-time 10 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "  OK - /config returned 200"
else
    echo "  FAIL - /config returned $HTTP_CODE"
    if [ "$HTTP_CODE" = "000" ]; then
        echo "  Could not connect. Is the browser running?"
    elif [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "403" ]; then
        echo "  Authentication failed. Check your token."
    fi
    exit 1
fi

# Test 2: Config details
echo "[2/3] Fetching browser config..."
CONFIG=$(curl -s "$BROWSER_URL/config?token=$TOKEN" --max-time 10 2>/dev/null)
if [ -n "$CONFIG" ]; then
    echo "  OK - Config received"
    echo "  $CONFIG" | head -c 500
    echo ""
else
    echo "  WARNING - Config endpoint returned empty response"
fi

# Test 3: Screenshot endpoint (quick test with small viewport)
echo "[3/3] Testing screenshot capability..."
SCREENSHOT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BROWSER_URL/screenshot?token=$TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"url":"https://example.com","viewport":{"width":320,"height":240}}' \
    --max-time 30 2>/dev/null || echo "000")

if [ "$SCREENSHOT_RESPONSE" = "200" ]; then
    echo "  OK - Screenshot endpoint working"
else
    echo "  WARNING - Screenshot endpoint returned $SCREENSHOT_RESPONSE"
    echo "  The browser is running but screenshots may need additional config."
fi

echo ""
echo "============================================"
echo "  Health check passed!"
echo "============================================"
echo ""
echo "  WebSocket URL: ${BROWSER_URL/http/ws}?token=$TOKEN"
echo "  (use this in your MCP config)"
echo "============================================"
