#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# backup-db.sh
# - Creates a timestamped pg_dump backup into database/backups/
# - Uses Docker exec to run pg_dump inside the container
# ------------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load env
if [[ -f "${ROOT_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
elif [[ -f "${ROOT_DIR}/.env.example" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env.example"
else
  echo "ERROR: No .env or .env.example found at repo root."
  exit 1
fi

POSTGRES_DB="${POSTGRES_DB:-edgy}"
POSTGRES_USER="${POSTGRES_USER:-edgy}"
POSTGRES_HOST="${POSTGRES_HOST:-edgy-postgres}"

PG_SERVICE="${PG_SERVICE:-postgres}"
PG_CONTAINER="${PG_CONTAINER:-}"

BACKUP_DIR="${ROOT_DIR}/database/backups"
mkdir -p "$BACKUP_DIR"

STAMP="$(date -u +"%Y%m%dT%H%M%SZ")"
OUT_FILE="${BACKUP_DIR}/${POSTGRES_DB}_${STAMP}.dump"

pick_container() {
  if [[ -n "${PG_CONTAINER}" ]]; then
    echo "${PG_CONTAINER}"
    return 0
  fi

  if docker compose ps -q "${PG_SERVICE}" >/dev/null 2>&1; then
    local cid
    cid="$(docker compose ps -q "${PG_SERVICE}" | head -n 1)"
    if [[ -n "$cid" ]]; then
      echo "$cid"
      return 0
    fi
  fi

  if docker ps --format '{{.Names}}' | grep -qx "${POSTGRES_HOST}"; then
    echo "${POSTGRES_HOST}"
    return 0
  fi

  echo ""
  return 1
}

CID="$(pick_container || true)"
if [[ -z "$CID" ]]; then
  echo "ERROR: Could not find Postgres container."
  exit 1
fi

echo "Using Postgres container: ${CID}"
echo "Creating backup: ${OUT_FILE}"

# Custom format dump (compressed, best for restores)
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-}" "$CID" \
  pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -F c \
  > "${OUT_FILE}"

echo "✅ Backup saved: ${OUT_FILE}"
echo "Tip: restore with:"
echo "  scripts/restore-db.sh ${OUT_FILE}"
