#!/usr/bin/env bash
# apply-research-schema — apply pgvector schema to OUR Supabase (not client).
# Requires OURS_DATABASE_URL or pass SQL manually in Supabase dashboard.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCHEMA="$ROOT/scripts/research-memory/schema.sql"

if [[ -f "$ROOT/.env" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue
    export "$line"
  done < "$ROOT/.env"
fi

DB_URL="${OURS_DATABASE_URL:-${RESEARCH_DATABASE_URL:-}}"

if [[ -z "$DB_URL" && -n "${DB_PASS:-}" ]]; then
  OUR_REF="${OURS_SUPABASE_REF:-srjtsuqhcusvtgegwcpo}"
  OUR_REGION="${OURS_SUPABASE_REGION:-ap-southeast-1}"
  DB_URL="postgresql://postgres.${OUR_REF}:${DB_PASS}@aws-0-${OUR_REGION}.pooler.supabase.com:5432/postgres"
fi

echo "=== apply-research-schema ==="
echo ">> Target: OUR Supabase (srjtsuqhcusvtgegwcpo) — NOT client fiezodastotdurqyshih"
echo ">> SQL: $SCHEMA"

if [[ -z "$DB_URL" ]]; then
  echo ""
  echo "OURS_DATABASE_URL not set. Apply manually:"
  echo "  1. Open https://supabase.com/dashboard/project/srjtsuqhcusvtgegwcpo/sql/new"
  echo "  2. Paste contents of scripts/research-memory/schema.sql"
  echo "  3. Run"
  exit 0
fi

psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$SCHEMA"
echo ">> Schema applied."
