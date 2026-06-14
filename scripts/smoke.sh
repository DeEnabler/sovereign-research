#!/usr/bin/env bash
# smoke.sh — verify OrioSearch + harness scripts.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIO_URL="${ORIOSEARCH_URL:-${TAVILY_BASE_URL:-http://127.0.0.1:8000}}"
ORIO_URL="${ORIO_URL%/}"

export PATH="$ROOT/bin:$PATH"
export ORIOSEARCH_URL="$ORIO_URL"
export TAVILY_BASE_URL="$ORIO_URL"
export TAVILY_API_KEY="${TAVILY_API_KEY:-local}"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "=== sovereign-research smoke ==="
echo ">> API: $ORIO_URL"

curl -sf --max-time 10 "$ORIO_URL/health" | grep -qiE 'ok|healthy|status' \
  && pass "health" || fail "health"

curl -sf --max-time 30 -X POST "$ORIO_URL/search" \
  -H "Content-Type: application/json" \
  -d '{"api_key":"local","query":"open source AI agents","max_results":2}' \
  | grep -q '"results"' && pass "/search" || fail "/search"

WS_OUT=$(web-search "sovereign search smoke" --max 2 2>&1) || true
echo "$WS_OUT" | grep -q '>>' && pass "web-search harness" || fail "web-search harness"

echo "=== smoke done ==="
