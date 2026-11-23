#!/usr/bin/env bash
# PostgreSQL logical backup for Mgl ID.
# Usage: DATABASE_URL=ecto://… ./priv/scripts/backup_pg.sh [outdir]
set -euo pipefail

OUT_DIR="${1:-./backups}"
mkdir -p "$OUT_DIR"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required (ecto:// or postgres://)" >&2
  exit 1
fi

# Normalize ecto:// → postgres:// for pg_dump
PG_URL="${DATABASE_URL/ecto:\/\//postgres:\/\/}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="${OUT_DIR}/mgl_id_${STAMP}.dump"

echo "Backing up to ${FILE}"
pg_dump --format=custom --no-owner --no-acl "$PG_URL" --file="$FILE"
echo "OK ${FILE}"
ls -lh "$FILE"
