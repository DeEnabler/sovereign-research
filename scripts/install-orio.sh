#!/usr/bin/env bash
# install-orio.sh — clone OrioSearch upstream and start the local stack.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ORIO_DIR="${ORIO_DIR:-$ROOT/oriosearch/upstream}"
OVERLAY="$ROOT/oriosearch"

echo "=== sovereign-research: install OrioSearch ==="

if [[ ! -f "$ORIO_DIR/Dockerfile" ]]; then
  echo ">> Cloning vkfolio/orio-search into $ORIO_DIR"
  mkdir -p "$(dirname "$ORIO_DIR")"
  git clone --depth 1 https://github.com/vkfolio/orio-search.git "$ORIO_DIR"
fi

echo ">> Applying VPS-tuned overlay (memory limits, config mount)"
cp "$OVERLAY/docker-compose.yml" "$ORIO_DIR/docker-compose.vps.yml"
cp "$OVERLAY/config.yaml" "$ORIO_DIR/config.yaml"

cd "$ORIO_DIR"

if docker compose version >/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE="docker-compose"
else
  echo "FAIL: need docker compose or docker-compose" >&2
  exit 1
fi

$COMPOSE -f docker-compose.vps.yml up -d --build

echo ">> Waiting for API..."
for i in $(seq 1 30); do
  if curl -sf --max-time 5 http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo ">> OrioSearch healthy at http://127.0.0.1:8000"
    curl -s http://127.0.0.1:8000/health
    echo ""
    echo ">> Smoke: $ROOT/scripts/smoke.sh"
    exit 0
  fi
  sleep 2
done

echo "WARN: health check timed out — check: docker logs orio-search-api" >&2
exit 1
