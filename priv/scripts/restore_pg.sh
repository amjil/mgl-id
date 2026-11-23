#!/usr/bin/env bash
# Restore a pg_dump custom-format backup into a target database.
# Usage: DATABASE_URL=… ./priv/scripts/restore_pg.sh backups/mgl_id_….dump
set -euo pipefail

DUMP="${1:-}"
if [[ -z "$DUMP" || ! -f "$DUMP" ]]; then
  echo "Usage: $0 path/to/backup.dump" >&2
  exit 1
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required" >&2
  exit 1
fi

PG_URL="${DATABASE_URL/ecto:\/\//postgres:\/\/}"

echo "WARNING: this drops objects in the target database before restore."
read -r -p "Type RESTORE to continue: " confirm
[[ "$confirm" == "RESTORE" ]] || { echo "Aborted"; exit 1; }

pg_restore --clean --if-exists --no-owner --no-acl --dbname="$PG_URL" "$DUMP"
echo "Restore finished. Run release migrate if schema needs newer migrations."
