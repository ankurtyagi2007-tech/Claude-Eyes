#!/usr/bin/env bash
set -euo pipefail

# cloud-eyes: End-to-end visual audit test
# Takes screenshots at 3 viewports and saves them locally
#
# Usage: ./scripts/test-visual-audit.sh [target-url] [browser-url] [token]
# Example: ./scripts/test-visual-audit.sh https://onlyexit.ai https://cloud-eyes.fly.dev my-token
# Example: ./scripts/test-visual-audit.sh https://onlyexit.ai http://localhost:3000 local-dev-token

TARGET_URL="${1:-https://onlyexit.ai}"
BROWSER_URL="${2:-http://localhost:3000}"
TOKEN="${3:-local-dev-token}"

# Strip trailing slashes
BROWSER_URL="${BROWSER_URL%/}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="./audit-results/${TIMESTAMP}"

echo "============================================"
echo "  cloud-eyes - Visual Audit Test"
echo "============================================"
echo ""
echo "  Target URL:  $TARGET_URL"
echo "  Browser URL: $BROWSER_URL"
echo "  Output:      $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

# Define viewports
declare -A VIEWPORTS
VIEWPORTS=(
    ["mobile"]='{"width":375,"height":812}'
    ["tablet"]='{"width":768,"height":1024}'
    ["desktop"]='{"width":1440,"height":900}'
)

PASSED=0
FAILED=0

for VIEWPORT_NAME in mobile tablet desktop; do
    VIEWPORT_JSON="${VIEWPORTS[$VIEWPORT_NAME]}"
    OUTPUT_FILE="$OUTPUT_DIR/${VIEWPORT_NAME}.png"

    echo "[$VIEWPORT_NAME] Taking screenshot at $VIEWPORT_JSON..."

    HTTP_CODE=$(curl -s -o "$OUTPUT_FILE" -w "%{http_code}" \
        -X POST "$BROWSER_URL/screenshot?token=$TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"url\":\"$TARGET_URL\",\"viewport\":$VIEWPORT_JSON,\"gotoOptions\":{\"waitUntil\":\"networkidle2\",\"timeout\":30000}}" \
        --max-time 45 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] && [ -s "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
        echo "  OK - Saved to $OUTPUT_FILE ($FILE_SIZE bytes)"
        PASSED=$((PASSED + 1))
    else
        echo "  FAIL - HTTP $HTTP_CODE"
        rm -f "$OUTPUT_FILE"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "============================================"
echo "  Audit Test Results"
echo "============================================"
echo ""
echo "  Target:  $TARGET_URL"
echo "  Passed:  $PASSED/3"
echo "  Failed:  $FAILED/3"
echo "  Output:  $OUTPUT_DIR/"
echo ""

if [ "$PASSED" -eq 3 ]; then
    echo "  All screenshots captured successfully."
    echo "  Open the files in $OUTPUT_DIR/ to review."
    echo "============================================"
    exit 0
else
    echo "  Some screenshots failed. Check your browser"
    echo "  deployment and try again."
    echo "============================================"
    exit 1
fi
