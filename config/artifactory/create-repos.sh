#!/usr/bin/env bash
# create-repos.sh — Create demo Artifactory repositories using JFrog CLI
#
# This script is called by setup.sh. Can also be run standalone.
#
# Usage: ./config/artifactory/create-repos.sh
#
# Required environment variables:
#   JFROG_URL           — JFrog SaaS URL
#   JFROG_ACCESS_TOKEN  — Admin-scoped access token
#   JFROG_SERVER_ID     — JFrog CLI server ID (default: jfrog-demo)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

JFROG_URL="${JFROG_URL%/}"
JFROG_SERVER_ID="${JFROG_SERVER_ID:-jfrog-demo}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if ! command -v jf &>/dev/null; then
  fail "JFrog CLI (jf) not found. Install from: https://jfrog.com/getcli/"
fi

if [[ -z "${JFROG_URL:-}" ]] || [[ -z "${JFROG_ACCESS_TOKEN:-}" ]]; then
  fail "JFROG_URL and JFROG_ACCESS_TOKEN must be set."
fi

echo "Configuring JFrog CLI..."
jf config add "$JFROG_SERVER_ID" \
  --url "$JFROG_URL" \
  --access-token "$JFROG_ACCESS_TOKEN" \
  --interactive=false \
  --overwrite=true 2>/dev/null || true

if ! jf rt ping --server-id="$JFROG_SERVER_ID" &>/dev/null; then
  fail "JFrog CLI authentication failed. Check JFROG_URL and JFROG_ACCESS_TOKEN."
fi

create_or_skip() {
  local key="$1"
  local template_file="$2"
  local label="$3"
  local status

  if [[ ! -f "$template_file" ]]; then
    fail "Repository template not found: $template_file"
  fi

  status=$(jf rt curl --server-id="$JFROG_SERVER_ID" -sS -o /dev/null -w "%{http_code}" \
    "/api/repositories/$key" 2>/dev/null || echo "000")

  if [[ "$status" == "200" ]]; then
    warn "$label '$key' already exists — skipping"
    return
  fi

  jf rt curl --server-id="$JFROG_SERVER_ID" -sS -f -X PUT \
    -H "Content-Type: application/json" \
    -d @"$template_file" \
    "/api/repositories/$key" >/dev/null
  ok "Created $label: $key"
}

REPO_JSON="$REPO_ROOT/config/artifactory/repos"

echo "Creating JFrog AI Catalog demo repositories..."

create_or_skip "ml-code-review-huggingface-remote" \
  "$REPO_JSON/ml-code-review-huggingface-remote.json" \
  "remote repository"

create_or_skip "ml-code-review-models-local" \
  "$REPO_JSON/ml-code-review-models-local.json" \
  "local repository"

create_or_skip "ml-code-review-virtual" \
  "$REPO_JSON/ml-code-review-virtual.json" \
  "virtual repository"

echo ""
ok "All demo repositories created."
echo ""
echo "Virtual repository URL (developers should use this):"
echo "  $JFROG_URL/artifactory/ml-code-review-virtual/"
echo ""
