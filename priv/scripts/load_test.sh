#!/usr/bin/env bash
# Lightweight readiness/login pressure smoke (not a full soak).
# Requires: curl, optional hey (go install github.com/rakyll/hey@latest)
# Usage: BASE_URL=https://id.amjil.net ./priv/scripts/load_test.sh
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:4000}"
N="${N:-200}"
C="${C:-20}"

echo "== health/ready =="
curl -fsS "${BASE_URL}/health/ready" | head -c 400
echo

echo "== discovery =="
curl -fsS "${BASE_URL}/.well-known/openid-configuration" | head -c 200
echo "…"

if command -v hey >/dev/null 2>&1; then
  echo "== hey GET /health/live (${N} req, ${C} concurrent) =="
  hey -n "$N" -c "$C" "${BASE_URL}/health/live"
  echo "== hey GET /.well-known/jwks.json =="
  hey -n "$N" -c "$C" "${BASE_URL}/.well-known/jwks.json"
else
  echo "hey not installed; falling back to sequential curl loop"
  for _ in $(seq 1 50); do
    curl -fsS -o /dev/null -w "%{http_code}\n" "${BASE_URL}/health/live"
  done | sort | uniq -c
fi

echo "Done. Review latency/error rates before go-live."
