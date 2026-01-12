#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# init-db.sh
# - Waits for Postgres in Docker to be ready
# - Creates DB (if needed)
# - Applies database/schema/*.sql in lexical order
# ------------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load env (.env preferred, fallback to .env.example)
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

# Defaults (if not set)
POSTGRES_DB="${POSTGRES_DB:-edgy}"
POSTGRES_USER="${POSTGRES_USER:-edgy}"
POSTGRES_HOST="${POSTGRES_HOST:-edgy-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

# You can use either a compose service name or a container name.
# Prefer service name "postgres" (as in docker-compose.edge.yml)
PG_SERVICE="${PG_SERVICE:-postgres}"
PG_CONTAINER="${PG_CONTAINER:-}"

SCHEMA_DIR="${ROOT_DIR}/database/schema"

if [[ ! -d "$SCHEMA_DIR" ]]; then
  echo "ERROR: Schema directory not found: $SCHEMA_DIR"
  exit 1
fi

# Helper: choose container to exec into
pick_container() {
  if [[ -n "${PG_CONTAINER}" ]]; then
    echo "${PG_CONTAINER}"
    return 0
  fi

  # Try docker compose service
  if docker compose ps -q "${PG_SERVICE}" >/dev/null 2>&1; then
    local cid
    cid="$(docker compose ps -q "${PG_SERVICE}" | head -n 1)"
    if [[ -n "$cid" ]]; then
      echo "$cid"
      return 0
    fi
  fi

  # Fallback: by hostname as container name
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
  echo "Tried: docker compose service '${PG_SERVICE}', container '${POSTGRES_HOST}', or PG_CONTAINER env var."
  exit 1
fi

echo "Using Postgres container: ${CID}"

# Wait for readiness
echo "Waiting for Postgres to be ready..."
for i in {1..60}; do
  if docker exec -e PGPASSWORD="${POSTGRES_PASSWORD:-}" "$CID" pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; then
    echo "Postgres is ready."
    break
  fi
  sleep 1
  if [[ "$i" -eq 60 ]]; then
    echo "ERROR: Postgres did not become ready in time."
    exit 1
  fi
done

# Apply schema files in lexical order
echo "Applying schema from: ${SCHEMA_DIR}"
mapfile -t files < <(find "$SCHEMA_DIR" -maxdepth 1 -type f -name "*.sql" | sort)

if [[ "${#files[@]}" -eq 0 ]]; then
  echo "WARNING: No .sql files found in ${SCHEMA_DIR}"
  exit 0
fi

for fp in "${files[@]}"; do
  bn="$(basename "$fp")"
  echo " -> Applying ${bn}"
  docker exec -i -e PGPASSWORD="${POSTGRES_PASSWORD:-}" "$CID" \
    psql -v ON_ERROR_STOP=1 \
         -U "${POSTGRES_USER}" \
         -d "${POSTGRES_DB}" \
         < "$fp"
done

echo "✅ init-db complete."
