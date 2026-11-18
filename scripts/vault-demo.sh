#!/usr/bin/env bash
# Demo of centralized secret provisioning with a dev-mode Vault.
# Never use dev mode or the root token outside local experimentation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export VAULT_ADDR="${VAULT_ADDR:-http://127.0.0.1:8200}"
ROOT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-root}"

vault_exec() {
  local token="$1"
  shift
  docker exec -i \
    -e VAULT_ADDR="$VAULT_ADDR" \
    -e VAULT_TOKEN="$token" \
    pygoat-vault vault "$@"
}

echo "### Vault dev server"
docker compose --profile vault up -d --wait vault
docker compose ps vault
vault_exec "$ROOT_TOKEN" status

echo
echo "### seed secret/pygoat (values are not printed)"
KEY="${VAULT_DEMO_SECRET_KEY:-$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')}"
DB_URL="${VAULT_DEMO_DATABASE_URL:-sqlite:///db.sqlite3}"
vault_exec "$ROOT_TOKEN" kv put secret/pygoat \
  DJANGO_SECRET_KEY="$KEY" DATABASE_URL="$DB_URL" >/dev/null
KEY_FP="$(printf '%s' "$KEY" | sha256sum | cut -c1-12)"
echo "seeded DJANGO_SECRET_KEY sha256_12=$KEY_FP"

echo
echo "### read-only policy"
vault_exec "$ROOT_TOKEN" policy write pygoat-read - < policies/pygoat-read.hcl
vault_exec "$ROOT_TOKEN" policy read pygoat-read

echo
echo "### scoped token (1h TTL)"
READ_TOKEN="$(vault_exec "$ROOT_TOKEN" token create -policy=pygoat-read -ttl=1h -field=token)"
vault_exec "$READ_TOKEN" token lookup | grep -E '^(display_name|policies|renewable|ttl|creation_ttl)' || true

run_app() {
  env -u DJANGO_SECRET_KEY -u DATABASE_URL \
    VAULT_ADDR="$VAULT_ADDR" VAULT_TOKEN="$READ_TOKEN" "$@"
}

echo
echo '$ .venv/bin/python manage.py check   # VAULT_ADDR + read-only token only'
run_app .venv/bin/python manage.py check
echo
echo '$ .venv/bin/python scripts/secret_probe.py'
run_app .venv/bin/python scripts/secret_probe.py

echo
echo "### negative: read-only token attempts a write"
set +e
out="$(vault_exec "$READ_TOKEN" kv put secret/pygoat DJANGO_SECRET_KEY=denied 2>&1)"
rc=$?
set -e
printf '%s\n' "$out" | tail -4
echo "write exit=$rc (expected non-zero)"

echo
echo "Vault is still running. Stop it with: docker compose --profile vault rm -sf vault"
